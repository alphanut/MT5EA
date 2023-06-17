//+------------------------------------------------------------------+
//|                                                           BB.mq5 |
//|                   Copyright 2009-2020, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "2009-2020, MetaQuotes Software Corp."
#property link        "http://www.mql5.com"
#property description "Bollinger Bands Modified"
#include <MovingAverages.mqh>
//---
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   3
#property indicator_type1   DRAW_LINE
#property indicator_color1  LightSeaGreen
#property indicator_type2   DRAW_LINE
#property indicator_color2  LightSeaGreen
#property indicator_type3   DRAW_LINE
#property indicator_color3  LightSeaGreen
#property indicator_label1  "Bands middle"
#property indicator_label2  "Bands upper"
#property indicator_label3  "Bands lower"
//--- input parametrs
input int     InpBandsPeriod=20;       // Period
input int     InpBandsShift=0;         // Shift
input double  InpBandsDeviations=2.0;  // Deviation
input ENUM_MA_METHOD InpMAMethod=MODE_SMA; // Method
//--- global variables
int           ExtBandsPeriod,ExtBandsShift;
double        ExtBandsDeviations;
int           ExtPlotBegin=0;
//--- indicator buffer
double        ExtMLBuffer[];
double        ExtTLBuffer[];
double        ExtBLBuffer[];
double        ExtStdDevBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- check for input values
   if(InpBandsPeriod<2)
     {
      ExtBandsPeriod=20;
      PrintFormat("Incorrect value for input variable InpBandsPeriod=%d. Indicator will use value=%d for calculations.",InpBandsPeriod,ExtBandsPeriod);
     }
   else
      ExtBandsPeriod=InpBandsPeriod;
   if(InpBandsShift<0)
     {
      ExtBandsShift=0;
      PrintFormat("Incorrect value for input variable InpBandsShift=%d. Indicator will use value=%d for calculations.",InpBandsShift,ExtBandsShift);
     }
   else
      ExtBandsShift=InpBandsShift;
   if(InpBandsDeviations==0.0)
     {
      ExtBandsDeviations=2.0;
      PrintFormat("Incorrect value for input variable InpBandsDeviations=%f. Indicator will use value=%f for calculations.",InpBandsDeviations,ExtBandsDeviations);
     }
   else
      ExtBandsDeviations=InpBandsDeviations;
//--- define buffers
   SetIndexBuffer(0,ExtMLBuffer);
   SetIndexBuffer(1,ExtTLBuffer);
   SetIndexBuffer(2,ExtBLBuffer);
   SetIndexBuffer(3,ExtStdDevBuffer,INDICATOR_CALCULATIONS);
//--- set index labels
   PlotIndexSetString(0,PLOT_LABEL,"Bands("+string(ExtBandsPeriod)+") Middle");
   PlotIndexSetString(1,PLOT_LABEL,"Bands("+string(ExtBandsPeriod)+") Upper");
   PlotIndexSetString(2,PLOT_LABEL,"Bands("+string(ExtBandsPeriod)+") Lower");
//--- indicator name
   IndicatorSetString(INDICATOR_SHORTNAME,"Bollinger Bands");
//--- indexes draw begin settings
   ExtPlotBegin=ExtBandsPeriod-1;
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,ExtBandsPeriod);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,ExtBandsPeriod);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,ExtBandsPeriod);
//--- indexes shift settings
   PlotIndexSetInteger(0,PLOT_SHIFT,ExtBandsShift);
   PlotIndexSetInteger(1,PLOT_SHIFT,ExtBandsShift);
   PlotIndexSetInteger(2,PLOT_SHIFT,ExtBandsShift);
//--- number of digits of indicator value
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
  }
//+------------------------------------------------------------------+
//| Bollinger Bands                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
   if(rates_total<ExtPlotBegin)
      return(0);
//--- indexes draw begin settings, when we've recieved previous begin
   if(ExtPlotBegin!=ExtBandsPeriod+begin)
     {
      ExtPlotBegin=ExtBandsPeriod+begin;
      PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,ExtPlotBegin);
      PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,ExtPlotBegin);
      PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,ExtPlotBegin);
     }
//--- starting calculation
   int pos;
   if(prev_calculated>1)
      pos=prev_calculated-1;
   else
      pos=0;
//--- main cycle
   for(int i=pos; i<rates_total && !IsStopped(); i++)
     {
      //--- middle line
      ExtMLBuffer[i] = (i == 0) ? price[i] : CalculateMA(i, ExtBandsPeriod, ExtMLBuffer[i-1], price, InpMAMethod);
      //--- calculate and write down StdDev
      ExtStdDevBuffer[i] = StdDev_Func(i,price,ExtMLBuffer,ExtBandsPeriod);
      //--- upper line
      ExtTLBuffer[i] = ExtMLBuffer[i] + ExtBandsDeviations*ExtStdDevBuffer[i];
      //--- lower line
      ExtBLBuffer[i] = ExtMLBuffer[i] - ExtBandsDeviations*ExtStdDevBuffer[i];
     }
//--- OnCalculate done. Return new prev_calculated.
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Calculate Standard Deviation                                     |
//+------------------------------------------------------------------+
double StdDev_Func(const int position,const double &price[],const double &ma_price[],const int period)
  {
   double std_dev=0.0;
//--- calcualte StdDev
   if(position>=period)
     {
      for(int i=0; i<period; i++)
         std_dev+=MathPow(price[position-i]-ma_price[position],2.0);
      std_dev=MathSqrt(std_dev/period);
     }
//--- return calculated value
   return(std_dev);
  }
//+------------------------------------------------------------------+
//| Calculate Moving Average                                     |
//+------------------------------------------------------------------+
double CalculateMA(const int position, const int period, const double prev_value, const double &price[], const ENUM_MA_METHOD method)
{
   double ma = 0;
   switch(method)
     {
      case  MODE_EMA :
         ma = (position <= period) ? SimpleMA(position, period, price) : ExponentialMA(position, period, prev_value, price);
         break;
      case MODE_SMMA :
         ma = (position <= period) ? SimpleMA(position, period, price) : SmoothedMA(position, period, prev_value, price);
         break;
      case MODE_LWMA :
         ma = LinearWeightedMA(position, period, price);
         break;
      default :
         ma = SimpleMA(position, period, price);
     }
     
     return ma;     
}
//+------------------------------------------------------------------+
