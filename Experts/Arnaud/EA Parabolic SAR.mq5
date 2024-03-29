// Trade
#include <Trade\Trade.mqh>
CTrade TradeTP;
CTrade TradeSAR;

// Price
#include <MyLib\Price.mqh>
CBars Price;

// Money management
#include <MyLib\MoneyManagement.mqh>

// Timer
#include <MyLib\Timer.mqh>
CTimer Timer;
CNewBar NewBar;

// Indicators 
#include <Indicators\Trend.mqh>
#include <MyLib\Indicators.mqh>
CiSAR SAR;
CNormalizedTickVolume Volume;

//+------------------------------------------------------------------+
//| Expert information                                               |
//+------------------------------------------------------------------+

#property copyright "Arnaud Seguin"
#property version   "1.02"
#property description ""
#property link      ""



//+------------------------------------------------------------------+
//| Input variables                                                  |
//+------------------------------------------------------------------+
sinput string TradeSettings; // Trade Settings
input ulong Slippage = 3;
input bool TradeOnNewBar = true;
input double FixedVolume = 0.1;
input int TakeProfitInPoints = 200;
input int StopLossInPoints = 200;
input int RiskInPercent = 1;
input bool TP_Strategy = true;
input bool SAR_Strategy = true;

sinput string TI; 	// Timer Settings
input bool UseTimer = false;
input int StartHour = 0;
input int StartMinute = 0;
input int EndHour = 0;
input int EndMinute = 0;
input bool UseLocalTime = false;

sinput string SARSettings; // SAR Settings
input double SARStep = 0.02;
input double SARMax = 0.2;

//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+

ulong tradeTP_MagicNumber = 314159;
ulong tradeSAR_MagicNumber = 271828;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int OnInit()
{
	SAR.Create(_Symbol, _Period, SARStep, SARMax);
	Volume.Create(_Symbol, _Period, 50);
	
	TradeTP.SetExpertMagicNumber(tradeTP_MagicNumber);
	TradeSAR.SetExpertMagicNumber(tradeSAR_MagicNumber);
	
   return 0;
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnTick()
{
	// Check for new bar
	bool newBar = true;
	int barShift = 0;
	
	if(TradeOnNewBar == true) 
	{
		newBar = NewBar.CheckNewBar(_Symbol, _Period);
		barShift = 1;
	}
	
	// Timer
	bool timerOn = true;
	if(UseTimer == true)
	{
		timerOn = Timer.DailyTimer(StartHour, StartMinute, EndHour, EndMinute, UseLocalTime);
	}
	
	// Update prices
	Price.Update(_Symbol, _Period);
	SAR.Refresh();
	Volume.Refresh();
	
	double open = Price.Open();
	double open1 = Price.Open(1);
	double close = Price.Close();
	double close1 = Price.Close(1);
	double close2 = Price.Close(2);
	double sar0 = SAR.Main(0);
	double sar1 = SAR.Main(1);
	double sar2 = SAR.Main(2);
	double volume1 = Volume.NormalizedVolume(1);
	
	// Order placement
	if(newBar == true && timerOn == true)
	{		
		double pointValue = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
		int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
		int positions = PositionsTotal();
		
		// Open buy order
		if(!positions)
		{
		   bool buy = sar0 < open && sar1 < open1 && sar2 > close2 && open1 < sar2 && close1 > sar2 && volume1 > 100;
		   bool sell = sar0 > open && sar1 > open1 && sar2 < close2 && open1 > sar2 && close1 < sar2 && volume1 > 100;
		   if (buy)
		   {
   		   double tradeSize = MoneyManagement(_Symbol, FixedVolume, RiskInPercent, StopLossInPoints);
   			double sl = NormalizeDouble(open - StopLossInPoints * pointValue, digits);
   			double tp = NormalizeDouble(open + TakeProfitInPoints * pointValue, digits);
   			if (TP_Strategy)
   			   TradeTP.Buy(tradeSize, _Symbol, 0, sl, tp);
   			if (SAR_Strategy)
   			   TradeSAR.Buy(tradeSize, _Symbol, 0, sar0);
			}
			else if (sell)
			{
			   double tradeSize = MoneyManagement(_Symbol, FixedVolume, RiskInPercent, StopLossInPoints);
   			double sl = NormalizeDouble(open + StopLossInPoints * pointValue, digits);
   			double tp = NormalizeDouble(open - TakeProfitInPoints * pointValue, digits);
   			if (TP_Strategy)
   			   TradeTP.Sell(tradeSize, _Symbol, 0, sl, tp);
   			if (SAR_Strategy)
   			   TradeSAR.Sell(tradeSize, _Symbol, 0, sar0);
			}
		}
		else
		{
		   for(int i = 0; i < positions; i++)
		   {
		      ulong ticket = PositionGetTicket(i);
		      if (ticket == 0 || !PositionSelectByTicket(ticket))
		         continue;
		         
		      long magic_number = PositionGetInteger(POSITION_MAGIC);
		      if (magic_number == tradeSAR_MagicNumber)
		      {
		         long posType = PositionGetInteger(POSITION_TYPE);
		         double dealPrice = PositionGetDouble(POSITION_PRICE_OPEN);
		         double dealSL = PositionGetDouble(POSITION_SL);
		         
		         if (posType == POSITION_TYPE_BUY)
		         {
		            double profitInPoints = (close - dealPrice) / pointValue;
		            if (profitInPoints > TakeProfitInPoints && sar0 < dealPrice)
		            {
		               TradeSAR.PositionModify(ticket, dealPrice, 0);
		            }
		            else if (sar0 > dealSL)
		            {
		               TradeSAR.PositionModify(ticket, sar0, 0);
		            }
		         }
		         else if (posType == POSITION_TYPE_SELL)
		         {
		            double profitInPoints = (dealPrice - close) / pointValue;
		            if (profitInPoints > TakeProfitInPoints && sar0 > dealPrice)
		            {
		               TradeSAR.PositionModify(ticket, dealPrice, 0);
		            }
		            else if (sar0 < dealSL)
		            {
		               TradeSAR.PositionModify(ticket, sar0, 0);
		            }
		         }
		      }
		   }
		}
	} // Order placement end
}


