//+------------------------------------------------------------------+
//|                                      SpearmanRankCorrelation.mq5 |
//|                      Copyright © 2007, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
// http://www.infamed.com/stat/s05.html
#property copyright "Copyright © 2007, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"
//---- indicator version
#property version   "1.00"
//---- drawing the indicator in a separate window
#property indicator_separate_window
//---- one buffer is used for the indicator calculation and drawing
#property indicator_buffers 1
//---- only one plot is used
#property indicator_plots   1
//---- drawing the indicator as a line
#property indicator_type1   DRAW_LINE
//---- magenta color is used for the indicator line
#property indicator_color1  Magenta
//---- the indicator line is a continuous curve
#property indicator_style1  STYLE_SOLID
//---- indicator line width is equal to 2
#property indicator_width1  2
//---- minimum and maximum indicator values parameters
#property indicator_minimum -1
#property indicator_maximum +1
//---- the indicator horizontal levels parameters
#property indicator_level1  +0.50
#property indicator_level2   0
#property indicator_level3  -0.50
#property indicator_levelcolor Blue
#property indicator_levelstyle STYLE_DASHDOTDOT

//+----------------------------------------------+
//|  Indicator input parameters                  |
//+----------------------------------------------+
input int  rangeN=14;
input int  CalculatedBars=0;
input int  Maxrange=30;
input bool direction=true;
//+----------------------------------------------+
//---- declaration of a dynamic array that
//---- will be used as an indicator buffer
double ExtLineBuffer[];
//----
double multiply;
double R2[],TrueRanks[];
int    PriceInt[],SortInt[],Maxrange_;
//+------------------------------------------------------------------+
//| calculate  RSP  function                                         |
//+------------------------------------------------------------------+
double SpearmanRankCorrelation(double &Ranks[],int N)
  {
//----
   double res,z2=0.0;

   for(int iii=0; iii<N; iii++) z2+=MathPow(Ranks[iii]-iii-1,2);
   res=1-6*z2/(MathPow(N,3)-N);
//----
   return(res);
  }
//+------------------------------------------------------------------+
//| Ranking array of prices function                                 |
//+------------------------------------------------------------------+
void RankPrices(double &TrueRanks_[],int &InitialArray[])
  {
//----
   int i,k,m,dublicat,counter,etalon;
   double dcounter,averageRank;

   ArrayCopy(SortInt,InitialArray,0,0,WHOLE_ARRAY);

   for(i=0; i<rangeN; i++) TrueRanks_[i]=i+1;

   ArraySort(SortInt);

   for(i=0; i<rangeN-1; i++)
     {
      if(SortInt[i]!=SortInt[i+1]) continue;

      dublicat=SortInt[i];
      k=i+1;
      counter=1;
      averageRank=i+1;

      while(k<rangeN)
        {
         if(SortInt[k]==dublicat)
           {
            counter++;
            averageRank+=k+1;
            k++;
           }
         else
            break;
        }
      dcounter=counter;
      averageRank=averageRank/dcounter;

      for(m=i; m<k; m++)
         TrueRanks_[m]=averageRank;
      i=k;
     }
   for(i=0; i<rangeN; i++)
     {
      etalon=InitialArray[i];
      k=0;
      while(k<rangeN)
        {
         if(etalon==SortInt[k])
           {
            R2[i]=TrueRanks_[k];
            break;
           }
         k++;
        }
     }
//----
   return;
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- memory distribution for variables' arrays   
   ArrayResize(R2,rangeN);
   ArrayResize(PriceInt,rangeN);
   ArrayResize(SortInt,rangeN);
//---- change of the elements indexation in the array of variables
   if(direction) ArraySetAsSeries(SortInt,true);
   ArrayResize(TrueRanks,rangeN);
//---- initialization of variables
   if(Maxrange<=0)
      Maxrange_=10;
   else Maxrange_=Maxrange;
   multiply=MathPow(10,_Digits);
//---- set ExtLineBuffer dynamic array as an indicator buffer
   SetIndexBuffer(0,ExtLineBuffer,INDICATOR_DATA);
//---- performing the shift of beginning of the indicator drawing
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,rangeN);
//---- indexing elements in the buffer as timeseries
   ArraySetAsSeries(ExtLineBuffer,true);
//---- initializations of a variable for the indicator short name
   string shortname;
   if(rangeN>Maxrange_)
      shortname="Decrease rangeN input!";
   else StringConcatenate(shortname,"Spearman(",rangeN,")");
//---- create a label to display in DataWindow
   PlotIndexSetString(0,PLOT_LABEL,shortname);
//---- creation of the name to be displayed in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,2);
//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// number of bars calculated at previous call
                const int begin,          // bars reliable counting beginning index
                const double &price[])    // price array for calculation of the indicator
  {
//---- checking the number of bars to be enough for the calculation
   if(rates_total<rangeN+begin) return(0);

   if(rangeN>Maxrange_) return(0);

//---- declarations of local variables 
   int limit;

//---- calculation of the 'first' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of the indicator calculation
     {
      limit=rates_total-2-rangeN-begin; // starting index for calculation of all bars
      //---- increase the position of the beginning of data by 'begin' bars as a result of calculation using data of another indicator
      if(begin>0) PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,rangeN+begin);
     }
   else
     {
      if(CalculatedBars==0)
         limit=rates_total-prev_calculated;
      else limit=CalculatedBars;
     }

//---- indexing elements in arrays as timeseries  
   ArraySetAsSeries(price,true);

//---- main indicator calculation loop
   for(int bar=limit; bar>=0; bar--)
     {
      for(int k=0; k<rangeN; k++) PriceInt[k]=int(price[bar+k]*multiply);

      RankPrices(TrueRanks,PriceInt);
      ExtLineBuffer[bar]=SpearmanRankCorrelation(R2,rangeN);
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
