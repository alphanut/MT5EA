//+------------------------------------------------------------------+
//|                                     Intraday Intensity Index.mq5 |
//|                                    Copyright 2023, Arnaud Seguin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#include <MovingAverages.mqh>
#property copyright "Copyright 2023, Arnaud Seguin"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots   1
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  Blue,Red
#property indicator_width1  2
//--- input parameters
input int      Period = 20;
//--- indicator buffers
double         VolumeBuffer[];
double         MeanBuffer[];
double         HistogramColorBuffer[];
//--- global variables
int            _Period_;
static int     _DefaultPeriod_ = 20;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   _Period_ = Period;
   if (_Period_ < 1)
   {
      PrintFormat("Incorrect value for input variable Period = %d. Indicator will use value %d for calculations.", _Period_, _DefaultPeriod_);
      _Period_ = _DefaultPeriod_;
   }
//--- indicator buffers mapping
   SetIndexBuffer(0, MeanBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, HistogramColorBuffer, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2, VolumeBuffer, INDICATOR_CALCULATIONS);
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
//--- set the start index
   int start;
   if(prev_calculated == 0)
      start = 0;
   else
      start = prev_calculated - 1;
//--- calculate the average volume
   for (int i = start; i < rates_total && !IsStopped(); ++i)
   {
      VolumeBuffer[i] = (high[i] - low[i]) != 0 ? (close[i]*2 - high[i] - low[i])*tick_volume[i]/(high[i] - low[i]) : 1;
   }
   
   SimpleMAOnBuffer(rates_total, prev_calculated, 0, _Period_, VolumeBuffer, MeanBuffer);
   
   for (int i = start; i < rates_total && !IsStopped(); ++i)
   {
      HistogramColorBuffer[i] = MeanBuffer[i] > 0 ? 0 : 1;
   }
   
//--- return value of prev_calculated for next call
   return rates_total;
}
//+------------------------------------------------------------------+
