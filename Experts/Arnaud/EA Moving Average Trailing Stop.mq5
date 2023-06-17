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
CiMA MA;

#include <MyLib\Utils.mqh>

//+------------------------------------------------------------------+
//| Expert information                                               |
//+------------------------------------------------------------------+

#property copyright "Arnaud Seguin"
#property version   "1.0"
#property description "Trailing Stop based on the Moving Average"
#property link      ""



//+------------------------------------------------------------------+
//| Input variables                                                  |
//+------------------------------------------------------------------+
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT;

sinput string              MA_Settings; // Moving Average Settings
input int                  MA_Period = 20;
input int                  MA_Shift = 0;
input ENUM_MA_METHOD       MA_Method = MODE_SMA;
input ENUM_APPLIED_PRICE   MA_Applied_Price = PRICE_CLOSE;
input int                  SL_Tolerance_Spreads = 1; // Number of spreads above or below the mean


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   MA.Create(_Symbol, TimeFrame, MA_Period, MA_Shift, MA_Method, MA_Applied_Price);
   Comment("EA Moving Average Trailing Stop Time Frame = " + TimeFrameToString(TimeFrame));

   return INIT_SUCCEEDED;
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Check for new bar
	bool newBar = NewBar.CheckNewBar(_Symbol, TimeFrame);	
	Price.Update(_Symbol, TimeFrame);
	MA.Refresh();
	
	double mean = MA.Main(0);
	
	// Parcourir chaque position
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
      	double tolerance = SL_Tolerance_Spreads * spread;
      	double sl = mean;
      	
      	if (posType == POSITION_TYPE_SELL)
      	{
      	   sl = mean + tolerance;
      	   Print("Stop Loss (" + DoubleToString(sl) + ") = MA (" + DoubleToString(mean) + ") + tolerance (" + DoubleToString(tolerance) + ")");
      	}
      	if (posType == POSITION_TYPE_BUY)
      	{
      	   sl = mean - tolerance;
      	   Print("Stop Loss (" + DoubleToString(sl) + ") = MA (" + DoubleToString(mean) + ") - tolerance (" + DoubleToString(tolerance) + ")");
      	}
      	
   	   Trade.PositionModify(ticket, sl, tp);
   	}
   }
}
//+------------------------------------------------------------------+
