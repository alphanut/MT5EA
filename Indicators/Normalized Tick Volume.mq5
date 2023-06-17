//+------------------------------------------------------------------+
//|                                            Normalized Volume.mq5 |
//|                                    Copyright 2023, Arnaud Seguin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Arnaud Seguin"
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <MovingAverages.mqh>
#property indicator_separate_window
#property indicator_level1 100
#property indicator_levelcolor clrRed
#property indicator_buffers 3
#property indicator_plots   1
#property indicator_type1   DRAW_HISTOGRAM
//--- input parameters
input int      Period=50;
//--- indicator buffers
double         NormalizedVolumeBuffer[];
double         AverageVolumeBuffer[];
double         VolumeBuffer[];
//--- global variables
int            _Period_;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   _Period_ = Period;
   if (_Period_ < 1)
   {
      PrintFormat("Incorrect value for input variable Period = %d. Indicator will use value %d for calculations.", _Period_, 50);
      _Period_ = 50;
   }
//--- indicator buffers mapping
   SetIndexBuffer(0, NormalizedVolumeBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, AverageVolumeBuffer, INDICATOR_CALCULATIONS);
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
      VolumeBuffer[i] = (double)tick_volume[i];
   }
   SimpleMAOnBuffer(rates_total, prev_calculated, 0, _Period_, VolumeBuffer, AverageVolumeBuffer);
//--- fill RelPosBuffer
   for (int i = start; i < rates_total && !IsStopped(); ++i)
   {
      NormalizedVolumeBuffer[i] = AverageVolumeBuffer[i] > 0 ? VolumeBuffer[i]*100/AverageVolumeBuffer[i] : 0.0;
   } 
   
//--- return value of prev_calculated for next call
   return rates_total;
}
//+------------------------------------------------------------------+
