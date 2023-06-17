//+------------------------------------------------------------------+
//|                                          Bollinger BandWidth.mq5 |
//|                                    Copyright 2023, Arnaud Seguin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Arnaud Seguin"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 6
#property indicator_plots   3
//--- plot BandWidth
#property indicator_label1  "BandWidth(%) "
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrLimeGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

#property indicator_label2  "BandWidthHigh"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

#property indicator_label3  "BandWidthLow"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrRed
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
//--- input parameters
input int      Period=20;
input double   Deviations=2.0;
input int      HighLowRefPeriod=125;
input ENUM_APPLIED_PRICE AppliedPrice = PRICE_CLOSE;
//--- indicator buffers
double         BandWidthBuffer[];
double         BandWidthHighBuffer[];
double         BandWidthLowBuffer[];
double         BBUpperBuffer[];
double         BBLowerBuffer[];
double         BBMiddleBuffer[];
int            BB_Handle;
int            _Period_;
double         _Deviations_;
int            _HighLowRefPeriod_;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   _Period_ = Period;
   if (_Period_ < 1)
   {
      PrintFormat("Incorrect value for input variable Period = %d. Indicator will use value %d for calculations.", _Period_, 20);
      _Period_ = 20;
   }
   _Deviations_ = Deviations;
   if (_Deviations_ <= 0.0)
   {
      PrintFormat("Incorrect value for input variable Deviations = %g. Indicator will use value %g for calculations.", _Deviations_, 2.0);
      _Deviations_ = 2.0;
   }
   _HighLowRefPeriod_ = HighLowRefPeriod;
   if (_HighLowRefPeriod_ < 1)
   {
      PrintFormat("Incorrect value for input variable HighLowRefPeriod = %g. Indicator will use value %g for calculations.", _HighLowRefPeriod_, 125);
      _HighLowRefPeriod_ = 125;
   }
//--- indicator buffers mapping
   SetIndexBuffer(0, BandWidthBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, BandWidthHighBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, BandWidthLowBuffer, INDICATOR_DATA);
   SetIndexBuffer(3, BBUpperBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(4, BBLowerBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(5, BBMiddleBuffer, INDICATOR_CALCULATIONS);
//--- set accuracy
   IndicatorSetInteger(INDICATOR_DIGITS, 2);
//--- sets first bar from what index will be drawn
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, _Period_);
   PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, _HighLowRefPeriod_);
   PlotIndexSetInteger(2, PLOT_DRAW_BEGIN, _HighLowRefPeriod_);
//--- name for DataWindow and indicator subwindow label
   IndicatorSetString(INDICATOR_SHORTNAME,"BandWidth(" + string(_Period_) + ", " + string(_Deviations_) + ", " + string(_HighLowRefPeriod_) + ")");
//--- retrieve the Bollinger bands indicator
   BB_Handle = iBands(_Symbol, PERIOD_CURRENT, _Period_, 0, _Deviations_, AppliedPrice);
   if (BB_Handle == INVALID_HANDLE)
   {
      Print("Failed to create Bollinger Bands indicator");
      return INIT_FAILED;
   }
   
   ArraySetAsSeries(BBUpperBuffer, true);
   ArraySetAsSeries(BBLowerBuffer, true);
   ArraySetAsSeries(BBMiddleBuffer, true);
   ArraySetAsSeries(BandWidthBuffer, true);
   ArraySetAsSeries(BandWidthHighBuffer, true);
   ArraySetAsSeries(BandWidthLowBuffer, true); 
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
   if (rates_total < _HighLowRefPeriod_)
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
   if (CopyBuffer(BB_Handle, 0, 0, to_copy, BBMiddleBuffer) <= 0)
      return 0;
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
//--- fill BandWidthBuffer
   for (int i = 0; i < rates_total - start && !IsStopped(); ++i)
   {
      BandWidthBuffer[i] = (BBUpperBuffer[i] - BBLowerBuffer[i])*100/BBMiddleBuffer[i]; // display in %
   }
//--- fill high and low buffers   
   for (int i = 0; i < rates_total - start && !IsStopped(); ++i)
   {
      int highIdx = ArrayMaximum(BandWidthBuffer, i, _HighLowRefPeriod_);
      BandWidthHighBuffer[i] = BandWidthBuffer[highIdx];
      
      int lowIdx = ArrayMinimum(BandWidthBuffer, i, _HighLowRefPeriod_);
      BandWidthLowBuffer[i] = BandWidthBuffer[lowIdx];
   }
//--- return value of prev_calculated for next call
   return rates_total;
}
//+------------------------------------------------------------------+
