// Trade
#include <Trade\Trade.mqh>
CTrade Trade;

// Price
#include <MyLib\Price.mqh>
CBars Price;

// Timer
#include <MyLib\Timer.mqh>
CTimer Timer;
CNewBar NewBar;

// Indicators 
#include <Indicators\Trend.mqh>
CiBands BB_One_StdDev;
CiBands BB_Half_StdDev;

#include <MyLib\Utils.mqh>

//+------------------------------------------------------------------+
//| Expert information                                               |
//+------------------------------------------------------------------+

#property copyright "Arnaud Seguin"
#property version   "1.0"
#property description "EA based on TTM Squeeze and Bollinger Bands"
#property link      ""

enum ENUM_TRAILING_MODE
{
   TRAILING_BB_ONE_STDDEV,
   TRAILING_BB_HALF_STDDEV,
   TRAILING_BB_MOVING_AVERAGE
};

//+------------------------------------------------------------------+
//| Input variables                                                  |
//+------------------------------------------------------------------+
sinput string Trade_Settings; // Trade Settings
input ENUM_TRAILING_MODE   Trailing_Mode = TRAILING_BB_ONE_STDDEV;
input int NumberOfBreakEventPoints = 100; // Number of points for break even

sinput string              BB_Settings; // Bollinger Bands Settings for the trailing stop
input int                  BB_MA_Period = 20; // Period
input int                  BB_MA_Shift = 0; // Shift
input ENUM_APPLIED_PRICE   BB_MA_Applied_Price = PRICE_CLOSE; // Type Of Price

sinput string              TTM_Squeeze_Settings; // TTM Squeeze Settings
input int                  TTM_BB_Length     = 20;          // Bollinger Bands Period
input double               TTM_BB_Mult       = 2.0;         // Bollinger Bands MultFactor
input int                  TTM_KC_Length     = 20;          // Keltner Channel Period
input double               TTM_KC_Mult       = 1.5;         // Keltner Channel MultFactor
input ENUM_APPLIED_PRICE   TTM_Applied_Price = PRICE_CLOSE; // Type Of Price

sinput string Timer_Settings; 	// Timer Settings
input bool UseTimer = true; // Use Timer
input int StartHour = 10; // Start Hour
input int StartMinute = 0; // Start Minute
input int EndHour = 19; // End Hour
input int EndMinute = 0; // End Minute
input bool UseLocalTime = false; // Use Local Time

//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
int h_ttm_squeeze;
bool BreakEvenTargetHit;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   BB_One_StdDev.Create(_Symbol, PERIOD_CURRENT, BB_MA_Period, BB_MA_Shift, 1, BB_MA_Applied_Price);
   BB_Half_StdDev.Create(_Symbol, PERIOD_CURRENT, BB_MA_Period, BB_MA_Shift, 0.5, BB_MA_Applied_Price);
   
   h_ttm_squeeze = iCustom(_Symbol, PERIOD_CURRENT, "SqueezeMomentumIndicator", TTM_BB_Length, TTM_BB_Mult, TTM_KC_Length, TTM_KC_Mult, TTM_Applied_Price);
   if (h_ttm_squeeze == INVALID_HANDLE)
   {
      Print("Error while opening SqueezeMomentumIndicator");
      return INIT_FAILED;
   }
   
   Trade.SetExpertMagicNumber(18062023); // Date of creation of this EA as magic number :-)

   return INIT_SUCCEEDED;
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   IndicatorRelease(h_ttm_squeeze);
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Timer
	bool timerOn = true;
	if(UseTimer == true)
	{
		timerOn = Timer.DailyTimer(StartHour, StartMinute, EndHour, EndMinute, UseLocalTime);
	}
	
   // Check for new bar
	bool newBar = NewBar.CheckNewBar(_Symbol, PERIOD_CURRENT);
	// Reset the profit and loss of the position
	if (PositionsTotal() == 0)
	   BreakEvenTargetHit = false;
	
	Price.Update(_Symbol, PERIOD_CURRENT);
	BB_One_StdDev.Refresh();
	BB_Half_StdDev.Refresh();
	
	double bb_one_up = BB_One_StdDev.Upper(1);
	double bb_one_low = BB_One_StdDev.Lower(1);
	double bb_half_up = BB_Half_StdDev.Upper(1);
	double bb_half_low = BB_Half_StdDev.Lower(1);
	double mean = BB_One_StdDev.Base(1);
	
	if (newBar && timerOn && !PositionSelect(_Symbol))
	{  // There is no position opened for this symbol
	   double previousClose = Price.Close(1);
	   double squeeze[1], momentum[2];
	   if (!CopyBuffer(h_ttm_squeeze, 3, 1, 1, squeeze)) return; // 
	   if (!CopyBuffer(h_ttm_squeeze, 0, 1, 2, momentum)) return; // momentum[0] contains the (n-2)-th value and momentum[1] contains the (n-1)-th value   
	   
	   bool squeezeOff = squeeze[0] == 2.0;
	   
	   // TODO : add time condition and TTM condition
	   if (squeezeOff && momentum[1] > 0 && momentum[0] < momentum[1] && previousClose > bb_one_up)
	   {
	      if (IsExtremumOfNthLastPrices(Price.High(1), 5, true))
	      {
   	      // Buy
   	      // During the test phase, we use the minimum volume
   	      double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   	      Trade.Buy(min_lot, _Symbol);
	      }
	   }
	   else if (squeezeOff && momentum[1] < 0 && momentum[0] > momentum[1] && previousClose < bb_one_low)
	   {
	      if (IsExtremumOfNthLastPrices(Price.Low(1), 5, false))
	      {
   	      // Sell
   	      // During the test phase, we use the minimum volume
   	      double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   	      Trade.Sell(min_lot, _Symbol);
	      }
	   }
	}
	
	for (int i = PositionsTotal() - 1; i >= 0; --i)
   {
      string posSymbol = PositionGetSymbol(i);
      if (posSymbol != _Symbol)
         continue;
         
      ulong ticket = PositionGetTicket(i);
      if (!PositionSelectByTicket(ticket))
         continue;
         
      long posType = PositionGetInteger(POSITION_TYPE);
      if (posType != POSITION_TYPE_BUY && posType != POSITION_TYPE_SELL)
         continue;
         
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double last = Price.Close(0);
      double pnl = posType == POSITION_TYPE_BUY ? last - openPrice : openPrice - last;
      int pnlInPoint = (int)NormalizeDouble(pnl / Point(), 0);
      if (pnlInPoint >= NumberOfBreakEventPoints)
         BreakEvenTargetHit = true;
	   
	   double posStop = PositionGetDouble(POSITION_SL);	   
	   if(newBar == true || posStop == 0.0)
   	{
   	   double tp = PositionGetDouble(POSITION_TP);
   	   
   	   long spreadPoint = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
      	double pointValue = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      	double spread = spreadPoint * pointValue;
   	   long digits = SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
      	spread = NormalizeDouble(spread, (int)digits);
      	mean = NormalizeDouble(mean, (int)digits);
      	double sl = 0;
      	switch(Trailing_Mode)
      	{
      	   case  TRAILING_BB_ONE_STDDEV:
      	     sl = posType == POSITION_TYPE_BUY ? bb_one_up : bb_one_low + spread;
      	     break;
      	   case TRAILING_BB_HALF_STDDEV:
      	     sl =  posType == POSITION_TYPE_BUY ? bb_half_up : bb_half_low + spread;
      	        break;
      	   case TRAILING_BB_MOVING_AVERAGE:
      	     sl = posType == POSITION_TYPE_BUY ? mean : mean + spread;
      	     break;
      	}
         
         // If the number of points for the break event is hit then the SL is at least the break even
         if (BreakEvenTargetHit)
            sl = posType == POSITION_TYPE_BUY ? MathMax(sl, openPrice) : MathMin(sl, openPrice);
      	
   	   Trade.PositionModify(ticket, sl, tp);
   	}
   }
}
//+------------------------------------------------------------------+

bool IsExtremumOfNthLastPrices(double price, int n, bool max)
{
   for (int i = 1; i <= n; ++i)
   {
      if (max && price < Price.High(i))
         return false;
      else if (!max && price > Price.Low(i))
         return false;
   }
   
   return true;
}
