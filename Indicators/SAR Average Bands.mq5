//+------------------------------------------------------------------+
//|                                     SarAverageBandsIndicator.mq5 |
//|                                    Copyright 2023, Arnaud Seguin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
//--- includes
#include <MyLib\lib_cisnewbar.mqh>
#include <MovingAverages.mqh>
//--- properties
#property copyright "Copyright 2023, Arnaud Seguin"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots   2
//--- plot Up
#property indicator_label1  "Up"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot Down
#property indicator_label2  "Down"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- input parameters
input int      MeanPeriod=20;
input double   SARStep = 0.02;
input double   SARMaximum = 0.2;
//--- indicator buffers (fixed arrays)
double         UpBuffer[];
double         DownBuffer[];
double         SARUpBuffer[];
double         SARDownBuffer[];
double         SARBuffer[];
//-- global variables
int            SAR_Handle;
CisNewBar      newbar_ind;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
//--- indicator buffers mapping
   SetIndexBuffer(0, UpBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, DownBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, SARUpBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(3, SARDownBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(4, SARBuffer, INDICATOR_CALCULATIONS);
   
   SAR_Handle = iSAR(_Symbol, PERIOD_CURRENT, SARStep, SARMaximum);
   if (SAR_Handle == INVALID_HANDLE)
   {
      Print("Failed to create SAR indicator");
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
   if (rates_total < MeanPeriod)
      return 0;
//--- check if all data calculated 
   int calculated = BarsCalculated(SAR_Handle);
   if(calculated < rates_total)
   {
      Print("Not all data of Parabolic SAR is calculated (", calculated ," bars). Error ", GetLastError());
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
   if (CopyBuffer(SAR_Handle, 0, 0, to_copy, SARBuffer) <= 0)
      return 0;
//--- set the start index
   int start;
   if(prev_calculated == 0)
      start = 0;
   else
      start = prev_calculated - 1;
//--- fill SARUpBuffer and SARDownBuffer   
   for(int i = start; i < rates_total && !IsStopped(); i++)
   {
   //--- sometimes the value is not initialized and is equal to the max
      if (SARBuffer[i] == DBL_MAX)
      {
         SARBuffer[i] = i == 0 ? 0.0 : SARBuffer[i-1];
      }
         
      if (SARBuffer[i] >= open[i])
      {
         if (i > 0 && SARUpBuffer[i-1] < 0)
         {
         //--- fill the i-th first value with the first known SAR up value 
            ArrayFill(SARUpBuffer, 0, i, SARBuffer[i]);
         }
         SARUpBuffer[i] = SARBuffer[i];
         
         if (i == 0 || SARDownBuffer[i-1] < 0)
         {
            SARDownBuffer[i] = -1;
         }
         else
         {
         //--- fill the i-th SAR down value with the last known SAR down value
            SARDownBuffer[i] = SARDownBuffer[i-1];
         }
      }
      if (SARBuffer[i] <= open[i])
      {
         if (i > 0 && SARDownBuffer[i-1] < 0)
         {
         //--- fill the i-th first value with the first known SAR down value
            ArrayFill(SARDownBuffer, 0, i, SARBuffer[i]);
         }
         SARDownBuffer[i] = SARBuffer[i];
         
         if (i == 0 || SARUpBuffer[i-1] < 0)
         {
            SARUpBuffer[i] = -1;
         }
         else
         {
         //--- fill the i-th SAR up value with the last known SAR up value
            SARUpBuffer[i] = SARUpBuffer[i-1];
         }
      }
   }
//--- calculate moving averages
SimpleMAOnBuffer(rates_total, prev_calculated, 0, MeanPeriod, SARUpBuffer, UpBuffer);
SimpleMAOnBuffer(rates_total, prev_calculated, 0, MeanPeriod, SARDownBuffer, DownBuffer);
//--- return value of prev_calculated for next call
   return rates_total;
}
//+------------------------------------------------------------------+
