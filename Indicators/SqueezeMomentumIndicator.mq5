//+------------------------------------------------------------------+
//|                                     SqueezeMomentumIndicator.mq5 |
//|                                Copyright 2020, Andrei Novichkov. |
//|                                               http://fxstill.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Andrei Novichkov."
#property description "Translate from Pine: Squeeze Momentum Indicator [LazyBear]"
/*********************************************************************************************************
This is a derivative of John Carter's 
"TTM Squeeze" volatility indicator, as discussed in his book "Mastering the Trade" (chapter 11).

Black crosses on the midline show that the market just entered a squeeze 
( Bollinger Bands are with in Keltner Channel).
This signifies low volatility , market preparing itself for an explosive move (up or down).
Gray crosses signify "Squeeze release".

Mr.Carter suggests waiting till the first gray after a black cross, and taking a position in the 
direction of the momentum (for ex., if momentum value is above zero, go long).
Exit the position when the momentum changes (increase or decrease - signified by a color change).

Mr.Carter uses simple momentum indicator , while I have used a different method (linreg based)
to plot the histogram.

More info:
- Book: Mastering The Trade by John F Carter 
*********************************************************************************************************/
#property link      "http://fxstill.com"
#property version   "1.00"


#property indicator_separate_window

#property indicator_buffers 5
#property indicator_plots   2

#property indicator_label1  "SqueezeMomentum"
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  clrLimeGreen, clrGreen, clrRed, clrMaroon
#property indicator_style1  STYLE_SOLID
#property indicator_width1  3

#property indicator_label2  "SqueezeMomentumLine"
#property indicator_type2   DRAW_COLOR_LINE
#property indicator_color2  clrDodgerBlue, clrBlack, clrViolet
#property indicator_style2  STYLE_SOLID
#property indicator_width2  5

//--- input parameters
input int      lengthBB                 = 20;          // Bollinger Bands Period
input double   multBB                   = 2.0;         // Bollinger Bands MultFactor
input int      lengthKC                 = 20;          // Keltner Channel Period
input double   multKC                   = 1.5;         // Keltner Channel MultFactor
input ENUM_APPLIED_PRICE  applied_price = PRICE_CLOSE; // type of price or handle 


double HistoBuffer[], HistoColorBuffer[], LineBuffer[], LineColorBuffer[];
double values[];
int h_kc, h_bb;

static int MINBAR = MathMax(lengthBB, lengthKC) + 1;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   SetIndexBuffer(0, HistoBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, HistoColorBuffer, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2, LineBuffer, INDICATOR_DATA);
   SetIndexBuffer(3, LineColorBuffer, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(4, values, INDICATOR_CALCULATIONS);
   
   ArraySetAsSeries(HistoBuffer, true);
   ArraySetAsSeries(HistoColorBuffer, true);
   ArraySetAsSeries(LineBuffer, true);
   ArraySetAsSeries(LineColorBuffer, true);
   ArraySetAsSeries(values,  true);
   
   IndicatorSetString(INDICATOR_SHORTNAME, "SQZMOM");
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
   
   h_kc = iCustom(_Symbol, PERIOD_CURRENT, "KeltnerChannel", lengthKC, multKC, false, MODE_SMA, applied_price);
   if (h_kc == INVALID_HANDLE)
   {
      Print("Error while open KeltnerChannel");
      return INIT_FAILED;
   }
   
   h_bb = iBands(_Symbol, PERIOD_CURRENT, lengthBB, 0, multBB, applied_price);
   if (h_bb == INVALID_HANDLE)
   {
      Print("Error while open BollingerBands");
      return INIT_FAILED;
   }
   
   return INIT_SUCCEEDED;
}
  
void OnDeinit(const int reason)
{
   IndicatorRelease(h_kc);
   IndicatorRelease(h_bb);     
}

void GetValue(const double& high[], const double& low[], const double& close[], int shift)
{
   double bbt[1], bbb[1], kct[1], kcb[1];
   if (CopyBuffer(h_bb, 1,  shift, 1, bbt) <= 0) return;
   if (CopyBuffer(h_bb, 2,  shift, 1, bbb) <= 0) return;
   if (CopyBuffer(h_kc, 0,  shift, 1, kct) <= 0) return;
   if (CopyBuffer(h_kc, 2,  shift, 1, kcb) <= 0) return;
  
   bool sqzOn  = (bbb[0] > kcb[0]) && (bbt[0] < kct[0]);
   bool sqzOff = (bbb[0] < kcb[0]) && (bbt[0] > kct[0]);
   bool noSqz  = (sqzOn == false)  && (sqzOff == false); 
   
   int indh = iHighest(_Symbol, PERIOD_CURRENT, MODE_HIGH, lengthKC, shift); 
   if (indh == -1) return;
   
   int indl = iLowest(_Symbol, PERIOD_CURRENT, MODE_LOW, lengthKC, shift);
   if (indl == -1) return;
          
   double avg = (high[indh] + low[indl]) / 2;
   double sma = (kct[0] + kcb[0]) / 2; // The central line of the Keltner channel is the moving average
   avg = (avg + sma) / 2;
          
   values[shift] = close[shift] - avg;
   
   double momentum = LinearRegression(values, lengthKC, shift);
   HistoBuffer[shift] = momentum;
   
   if (HistoBuffer[shift] > 0)
   {
      if(HistoBuffer[shift] < HistoBuffer[shift + 1])
         HistoColorBuffer[shift] = 1;
   }
   else
   {
      if(HistoBuffer[shift] < HistoBuffer[shift + 1])
         HistoColorBuffer[shift] = 2;
      else
         HistoColorBuffer[shift] = 3;
   }
   
   if (!noSqz)
   {
      LineColorBuffer[shift] = sqzOn ? 1: 2;
   }
}

// Least-squares method: minimize sum(beta*x_i + alpha - y_i)**2 where beta is the slope and alpha the intercept
// array : a time series
// period : the length of histories to use for the calculation
// pos : the index of the current position
double LinearRegression(const double& array[], int period, int pos) {
  
   double sx = 0, sy = 0, sxy = 0, sxx = 0, syy = 0, x = 0, y = 0;
   
   // As it is a time series, we have to do the sum from (shift + period - 1) to shift
   /*  old <----------------------------- last
      y : array(shift+period-1) | ... | array(shift)
      x :           0           | ... | period - 1
   */
   
   for (int i = period - 1; i >= 0; --i)
   {
      x    = period - i - 1;
      y    = array[pos + i];
      sx  += x;
      sy  += y;
      sxx += x * x;
      sxy += x * y;
      syy += y * y;
   }
               
   double slope = (period * sxy - sx * sy) / (period * sxx - sx * sx);
   double intercept = (sy - slope * sx) / period;
                    
   return slope * period + intercept;
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
   if(rates_total <= MINBAR)
      return 0;
      
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low,  true);
   
   int limit = rates_total - prev_calculated;
   if (limit == 0)
   {  // A new tick
      GetValue(high, low, close, 0);
   }
   else if (limit == 1)
   {  // A new bar
      // Calculations on the last closed candle 
      GetValue(high, low, close, 1);
   }
   else if (limit > 1)
   {  // The first call of the indicator, changing the timeframe, loading history
      ArrayInitialize(HistoBuffer, EMPTY_VALUE);
      ArrayInitialize(HistoColorBuffer, 0);
      ArrayInitialize(LineBuffer, 0);
      ArrayInitialize(LineColorBuffer, 0);
      ArrayInitialize(values, 0);
      
      limit = rates_total - MINBAR;
      for(int i = limit; i >= 1 && !IsStopped(); i--){
         GetValue(high, low, close, i);
      }
   }
   
   return rates_total;
}
//+------------------------------------------------------------------+
