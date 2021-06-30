//+------------------------------------------------------------------+
//|                                                  RCI_MTF_ALL.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window

#property indicator_buffers 12
#property indicator_plots 3

#property indicator_color1    Red
#property indicator_color2    Blue
#property indicator_color3    Green

#property indicator_level1 0.8
#property indicator_level2 -0.8

#property tester_indicator "RCI"

#define _MAX_MTF_COUNT_  4
#define _OBJ_SEPBAR_PREFIX_ "RCI_MTF_SEPBAR_"
#define _CALC_BUF_INTERVAL_ 50

enum ENUM_TFs
{
   M1=1,
   M5=5,
   M15=15,
   M30=30,
   H1=16385,
   H4=16388,
   D1=16408
};
//+----------------------------------------------+
//|  Indicator input parameters                  |
//+----------------------------------------------+
input ENUM_TFs firstTF=M5;
input ENUM_TFs secondTF=M15;
input ENUM_TFs thirdTF=H1;
input ENUM_TFs fourthTF=H4;
input int      rangeN1=9;
input int      rangeN2=26;
input int      rangeN3=52;
input int      CalculatedBars=0;
input int      Maxrange=60;
input bool     direction=true;
input color    tfSepLineColor=clrDimGray;
input color    tfLabelColor=clrWhite;

//---- buffers
double ExtMapBuffer1[];
double ExtMapBuffer2[];
double ExtMapBuffer3[];
double ExtMapBuffer4[];
double ExtMapBuffer5[];
double ExtMapBuffer6[];
double ExtMapBuffer7[];
double ExtMapBuffer8[];
double ExtMapBuffer9[];
double ExtMapBuffer10[];
double ExtMapBuffer11[];
double ExtMapBuffer12[];

string            _labels[_MAX_MTF_COUNT_];
ENUM_TIMEFRAMES   _periods[_MAX_MTF_COUNT_];

int      _h_RCIs[_MAX_MTF_COUNT_][3] = { 0 };

string shortName;
int    window;
double maxValues[];

int _barsPerTimeFrame=50;
int _barsOffset=0;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   IndicatorSetInteger(INDICATOR_DIGITS,2);  
//--- indicator buffers mapping
   SetIndexBuffer(0, ExtMapBuffer1);
   SetIndexBuffer(1, ExtMapBuffer2);
   SetIndexBuffer(2, ExtMapBuffer3);
   
   PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_LINE);
   PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_LINE);
   PlotIndexSetInteger(2,PLOT_DRAW_TYPE,DRAW_LINE);
   
   shortName="RCI_MTF_ALL";
   IndicatorSetString(INDICATOR_SHORTNAME,shortName);
//---
   ArraySetAsSeries(ExtMapBuffer1,true);
   ArraySetAsSeries(ExtMapBuffer2,true);
   ArraySetAsSeries(ExtMapBuffer3,true);
//---
   _periods[0]=(ENUM_TIMEFRAMES)firstTF; _labels[0]=tf2str(firstTF);
   _periods[1]=(ENUM_TIMEFRAMES)secondTF; _labels[1]=tf2str(secondTF);
   _periods[2]=(ENUM_TIMEFRAMES)thirdTF; _labels[2]=tf2str(thirdTF);
   _periods[3]=(ENUM_TIMEFRAMES)fourthTF; _labels[3]=tf2str(fourthTF);
   
   for (int i=0; i<_MAX_MTF_COUNT_; i++)
     {
      _h_RCIs[i][0]=iCustom(Symbol(),_periods[i],"RCI",rangeN1,CalculatedBars,Maxrange,direction);
      _h_RCIs[i][1]=iCustom(Symbol(),_periods[i],"RCI",rangeN2,CalculatedBars,Maxrange,direction);
      _h_RCIs[i][2]=iCustom(Symbol(),_periods[i],"RCI",rangeN3,CalculatedBars,Maxrange,direction);
      
      if(_h_RCIs[i][0]==INVALID_HANDLE ||
         _h_RCIs[i][1]==INVALID_HANDLE ||
         _h_RCIs[i][2]==INVALID_HANDLE)
        {
         Print("Failed to create indicator!");
         return(INIT_FAILED);
        }
     }     
//---
   int firstVisibleBar=(int)ChartGetInteger(ChartID(),CHART_FIRST_VISIBLE_BAR);
   int barsPerWindow=(int)ChartGetInteger(ChartID(),CHART_VISIBLE_BARS);
   int lastVisibleBar=firstVisibleBar-barsPerWindow+1;   
   //int y=0;
   //ChartTimePriceToXY(ChartID(),0,iTime(NULL,0,lastVisibleBar),0,_firstIndicatorX,y);
//--- enable CHART_EVENT_MOUSE_MOVE messages 
   ChartSetInteger(0,CHART_EVENT_MOUSE_MOVE,1);
   EventSetMillisecondTimer(_CALC_BUF_INTERVAL_); 
//---
   return(INIT_SUCCEEDED);
  }
  
void OnDeinit(const int reason)
  {
   for (int i=0; i<_MAX_MTF_COUNT_; i++)
     {
      IndicatorRelease(_h_RCIs[i][0]);
      IndicatorRelease(_h_RCIs[i][1]);
      IndicatorRelease(_h_RCIs[i][2]);
     }
     
   ObjectsDeleteAll(ChartID(),_OBJ_SEPBAR_PREFIX_,window);  
  }  
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   static bool init = false;
   if(!init)
     {
      init      = true;
      window    = ChartWindowFind(ChartID(),shortName);
     }
     
   CalcIndBufs();
   
   //ChartRedraw();
//--- return value of prev_calculated for next call
   return(rates_total);
  }
  
void OnTimer()
  {
   CalcIndBufs();
  }  
//+------------------------------------------------------------------+
void OnChartEvent(const int id,const long& lparam,const double& dparam,const string& sparam)
  {
   /*if (id==CHARTEVENT_MOUSE_MOVE)
     {
      if((((uint)sparam) & 1) == 1)
      Print("***");
     }*/
   if(/*id==CHARTEVENT_CLICK ||*/ id==CHARTEVENT_CHART_CHANGE)
     {
      CalcIndBufs();
     }  
  }
//+------------------------------------------------------------------+
void CalcIndBufs()
  {
   for (int i=0;i<_MAX_MTF_COUNT_;i++)
     {
      if(BarsCalculated(_h_RCIs[i][0])<Bars(Symbol(),_periods[i])) return; 
      if(BarsCalculated(_h_RCIs[i][1])<Bars(Symbol(),_periods[i])) return; 
      if(BarsCalculated(_h_RCIs[i][2])<Bars(Symbol(),_periods[i])) return; 
     }
     
   ArrayInitialize(ExtMapBuffer1,EMPTY_VALUE);
   ArrayInitialize(ExtMapBuffer2,EMPTY_VALUE);
   ArrayInitialize(ExtMapBuffer3,EMPTY_VALUE);
   
   //ChartSetInteger(ChartID(),CHART_SHIFT,0,false);
   int firstVisibleBar=(int)ChartGetInteger(ChartID(),CHART_FIRST_VISIBLE_BAR);
   int barsPerWindow=(int)ChartGetInteger(ChartID(),CHART_VISIBLE_BARS);
   int lastVisibleBar=firstVisibleBar-barsPerWindow+1;
   
   _barsPerTimeFrame = (barsPerWindow - 3) / 4;
   _barsOffset = (int)MathMod(barsPerWindow - 3, 4);
   
   //int k=indicatorPosStart==-1?0:indicatorPosStart;
   int k=lastVisibleBar;
   for (int i=0; i<_MAX_MTF_COUNT_; i++,k++)
     {
      double tmpBuf1[], tmpBuf2[], tmpBuf3[];
      ArrayInitialize(tmpBuf1,EMPTY_VALUE);ArraySetAsSeries(tmpBuf1,true);
      ArrayInitialize(tmpBuf2,EMPTY_VALUE);ArraySetAsSeries(tmpBuf2,true);
      ArrayInitialize(tmpBuf3,EMPTY_VALUE);ArraySetAsSeries(tmpBuf3,true);      
      
      datetime curTime = iTime(NULL,0,lastVisibleBar);
      datetime tfCurTime=curTime+(PeriodSeconds()/PeriodSeconds(_periods[i]))*PeriodSeconds(_periods[i]);
      int barshift=iBarShift(NULL,_periods[i],tfCurTime);
      
      int barsPerTimeFrame = _barsPerTimeFrame;
      barsPerTimeFrame += (i == _MAX_MTF_COUNT_ - 1) ? _barsOffset : 0;
      
      bool buf1_Copied=false;
      bool buf2_Copied=false;
      bool buf3_Copied=false;
      if(CopyBuffer(_h_RCIs[i][0],0,barshift,barsPerTimeFrame,tmpBuf1)==barsPerTimeFrame) { buf1_Copied=true; } 
      if(CopyBuffer(_h_RCIs[i][1],0,barshift,barsPerTimeFrame,tmpBuf2)==barsPerTimeFrame) { buf2_Copied=true; } 
      if(CopyBuffer(_h_RCIs[i][2],0,barshift,barsPerTimeFrame,tmpBuf3)==barsPerTimeFrame) { buf3_Copied=true; } 
      
      
      for(int j=0; j<barsPerTimeFrame; j++,k++)
        {
         if(buf1_Copied)
            ExtMapBuffer1[k]=tmpBuf1[j];
         if(buf2_Copied)
            ExtMapBuffer2[k]=tmpBuf2[j];
         if(buf3_Copied)
            ExtMapBuffer3[k]=tmpBuf3[j];
        }
      
      string objName = _OBJ_SEPBAR_PREFIX_ + IntegerToString(i);
      if(ObjectFind(ChartID(),objName)==-1)
         ObjectCreate(ChartID(),objName,OBJ_TREND,window,0,0);         
      ObjectSetInteger(ChartID(),objName,OBJPROP_TIME,myTime(k));
      ObjectSetDouble(ChartID(),objName,OBJPROP_PRICE,1.2);
      ObjectSetInteger(ChartID(),objName,OBJPROP_TIME,1,myTime(k));
      ObjectSetDouble(ChartID(),objName,OBJPROP_PRICE,1,-1.2);
      ObjectSetInteger(ChartID(),objName,OBJPROP_COLOR,tfSepLineColor);
      ObjectSetInteger(ChartID(),objName,OBJPROP_WIDTH,2);
      
      objName = objName + "label";
      if(ObjectFind(ChartID(),objName)==-1)
         ObjectCreate(ChartID(),objName,OBJ_TEXT,window,0,0);
      ObjectSetInteger(ChartID(),objName,OBJPROP_TIME,myTime(k-5));
      ObjectSetDouble(ChartID(),objName,OBJPROP_PRICE,-0.9);
      ObjectSetString(ChartID(),objName,OBJPROP_TEXT,_labels[i]);
      ObjectSetString(ChartID(),objName,OBJPROP_FONT,"Arial");
      ObjectSetInteger(ChartID(),objName,OBJPROP_COLOR,tfLabelColor);
     }
   
   ChartRedraw();  
  }
  
int myTime(int a)
  {
   if(a<0)
      return (int)(iTime(NULL,0,0)+Period()*60*MathAbs(a));
   else
      return (int)(iTime(NULL,0,a));
  }
  
string sTfTable[] = {"M1","M5","M15","M30","H1","H4","D1","W1","MN"};
int    iTfTable[] = {1,5,15,30,16385,16388,16408,32769,49153};

int str2tf(string tfs)
{
   StringToUpper(tfs);
   for (int i=ArraySize(iTfTable)-1; i>=0; i--)
   {
      if (tfs==sTfTable[i] || tfs==""+IntegerToString(iTfTable[i])) 
      {
//         return(MathMax(iTfTable[i],Period()));
         return(iTfTable[i]);
      }
   }
   return(Period());
   
}

string tf2str(int tf)
{
   if(tf==0) tf=Period();
   for (int i=ArraySize(iTfTable)-1; i>=0; i--) 
         if (tf==iTfTable[i]) return(sTfTable[i]);
   return("");
}  