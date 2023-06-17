//+------------------------------------------------------------------+
//| 									 Expert Advisor Programming - Template |
//|                                                     Andrew Young |
//|                                 http://www.expertadvisorbook.com |
//+------------------------------------------------------------------+

/*
 Creative Commons Attribution-NonCommercial 3.0 Unported
 http://creativecommons.org/licenses/by-nc/3.0/

 You may use this file in your own personal projects. You
 may modify it if necessary. You may even share it, provided
 the copyright above is present. No commercial use permitted. 
*/


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
CiSAR SAR;

#include <MyLib\Utils.mqh>

//+------------------------------------------------------------------+
//| Expert information                                               |
//+------------------------------------------------------------------+

#property copyright "Arnaud Seguin"
#property version   "1.15"
#property description ""
#property link      ""



//+------------------------------------------------------------------+
//| Input variables                                                  |
//+------------------------------------------------------------------+
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT;

sinput string SAR_Settings; // SAR Settings
input double SAR_Step = 0.02;
input double SAR_Max = 0.2;



//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int OnInit()
{
	SAR.Create(_Symbol, TimeFrame, SAR_Step, SAR_Max);
	Comment("EA SAR Trailing Stop Time Frame = " + TimeFrameToString(TimeFrame));
	
   return(0);
}



//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnTick()
{
	// Check for new bar
	bool newBar = NewBar.CheckNewBar(_Symbol, TimeFrame);	
	Price.Update(_Symbol, TimeFrame);
	double open0 = Price.Open();
	
	SAR.Refresh();
	double sar0 = SAR.Main(0);
	
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
      	sar0 = NormalizeDouble(sar0, (int)digits);
      	double sl = sar0;
      	
      	if (posType == POSITION_TYPE_SELL && sl > open0)
      	{
      	   sl = sl + spread;
      	   Print("Stop Loss (" + DoubleToString(sl) + ") = SAR (" + DoubleToString(sar0) + ") + spread (" + DoubleToString(spread) + ")");
      	}
      	if (posType == POSITION_TYPE_BUY && sl < open0)
      	{
      	   Print("Stop Loss (" + DoubleToString(sl) + ") = SAR (" + DoubleToString(sar0) + ")");
      	}
      	
   	   Trade.PositionModify(ticket, sl, tp);
   	}
      
   }
}


