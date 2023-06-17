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
#property description "Trailing Stop based on the Bollinger Bands"
#property link      ""

enum ENUM_TRAILING_MODE
{
   TM_ONE_STDDEV,
   TM_HALF_STDDEV,
   TM_MOVING_AVERAGE
};

//+------------------------------------------------------------------+
//| Input variables                                                  |
//+------------------------------------------------------------------+
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT;

sinput string              BB_Settings; // Bollinger Bands Settings
input int                  MA_Period = 20;
input int                  MA_Shift = 0;
input ENUM_APPLIED_PRICE   MA_Applied_Price = PRICE_CLOSE;
input ENUM_TRAILING_MODE   Trailing_Mode = TM_ONE_STDDEV;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   BB_One_StdDev.Create(_Symbol, TimeFrame, MA_Period, MA_Shift, 1, MA_Applied_Price);
   BB_Half_StdDev.Create(_Symbol, TimeFrame, MA_Period, MA_Shift, 0.5, MA_Applied_Price);

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
	BB_One_StdDev.Refresh();
	BB_Half_StdDev.Refresh();
	
	double bb_one_up = BB_One_StdDev.Upper(1);
	double bb_one_low = BB_One_StdDev.Lower(1);
	double bb_half_up = BB_Half_StdDev.Upper(1);
	double bb_half_low = BB_Half_StdDev.Lower(1);
	double mean = BB_One_StdDev.Base(1);
	
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
      	double sl = 0;
      	switch(Trailing_Mode)
      	  {
      	   case  TM_ONE_STDDEV:
      	     sl = posType == POSITION_TYPE_BUY ? bb_one_up : bb_one_low + spread;
      	     break;
      	   case TM_HALF_STDDEV:
      	     sl =  posType == POSITION_TYPE_BUY ? bb_half_up : bb_half_low + spread;
      	        break;
      	   case TM_MOVING_AVERAGE:
      	     sl = posType == POSITION_TYPE_BUY ? mean : mean + spread;
      	     break;
      	  }
      	
   	   Trade.PositionModify(ticket, sl, tp);
   	}
   }
}
//+------------------------------------------------------------------+
