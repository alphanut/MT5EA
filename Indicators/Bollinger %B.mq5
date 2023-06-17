//+------------------------------------------------------------------+
//|                                                     PercentB.mq5 |
//|                                    Copyright 2023, Arnaud Seguin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Arnaud Seguin"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
#property indicator_level1 0
#property indicator_level2 0.5
#property indicator_level3 1
#property indicator_buffers 3
#property indicator_plots   1
//--- plot %B
#property indicator_label1  "%B "
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrLimeGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- input parameters
input int      Period=20;
input double   Deviations=2.0;
input ENUM_APPLIED_PRICE AppliedPrice = PRICE_CLOSE;
//--- indicator buffers
double         RelPosBuffer[];
double         BBUpperBuffer[];
double         BBLowerBuffer[];
int            BB_Handle;
int            _Period_;
double         _Deviations_;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   _Period_ = Period;
   if (_Period_ < 1)
   {
      _Period_ = 20;
      PrintFormat("Incorrect value for input variable Period = %d. Indicator will use value %d for calculations.", _Period_, 20);
   }
   _Deviations_ = Deviations;
   if (_Deviations_ <= 0.0)
   {
      _Deviations_ = 2.0;
      PrintFormat("Incorrect value for input variable Deviations = %g. Indicator will use value %g for calculations.", _Deviations_, 2.0);
   }
//--- indicator buffers mapping
   SetIndexBuffer(0, RelPosBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, BBUpperBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(2, BBLowerBuffer, INDICATOR_CALCULATIONS);
//--- set accuracy
   IndicatorSetInteger(INDICATOR_DIGITS, 2);
//--- sets first bar from what index will be drawn
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, _Period_);
//--- name for DataWindow and indicator subwindow label
   IndicatorSetString(INDICATOR_SHORTNAME,"%B(" + string(_Period_) + ", " + string(_Deviations_) + ")");
//--- retrieve the Bollinger bands indicator
   BB_Handle = iBands(_Symbol, PERIOD_CURRENT, _Period_, 0, _Deviations_, AppliedPrice);
   if (BB_Handle == INVALID_HANDLE)
   {
      Print("Failed to create Bollinger Bands indicator");
      return INIT_FAILED;
   }
//---
   return INIT_SUCCEEDED;
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
   if (rates_total < _Period_)
      return 0;
//--- check if all data calculated 
   int calculated = BarsCalculated(BB_Handle);
   if(calculated < rates_total)
   {
      Print("Not all data of Bollinger bands is calculated (", calculated ," bars). Error ", GetLastError());
      return 0;
   }
//--- we can copy not all data
   int to_copy;
   if(prev_calculated > rates_total || prev_calculated < 0)
      to_copy = rates_total;
   else
   {
      to_copy = rates_total - prev_calculated;
      if(prev_calculated > 0)
      {
//--- last value is always copied
         to_copy++;
      }
   }
//--- checking for stop flag
   if(IsStopped())
      return 0;     
//--- try to copy      
   if (CopyBuffer(BB_Handle, 1, 0, to_copy, BBUpperBuffer) <= 0)
      return 0;
//--- checking for stop flag
   if(IsStopped())
      return 0;     
//--- try to copy      
   if (CopyBuffer(BB_Handle, 2, 0, to_copy, BBLowerBuffer) <= 0)
      return 0;
//--- set the start index
   int start;
   if(prev_calculated == 0)
      start = 0;
   else
      start = prev_calculated - 1;
//--- fill RelPosBuffer
   for (int i = start; i < rates_total && !IsStopped(); ++i)
   {
      double bandsWidth = BBUpperBuffer[i] - BBLowerBuffer[i];
      if (bandsWidth <= 0.0)
         RelPosBuffer[i] = 0.5;
      else
         RelPosBuffer[i] = (close[i] - BBLowerBuffer[i])/bandsWidth;
   }   
//--- return value of prev_calculated for next call
   return rates_total;
}
//+------------------------------------------------------------------+
