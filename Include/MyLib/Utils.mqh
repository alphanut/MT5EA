//+------------------------------------------------------------------+
//| Stop Loss & Take Profit Calculation Functions                    |
//+------------------------------------------------------------------+

double BuyStopLoss(string pSymbol,int pStopPoints, double pOpenPrice = 0)
{
	if(pStopPoints <= 0) return(0);
	
	double openPrice;
	if(pOpenPrice > 0) openPrice = pOpenPrice;
	else openPrice = SymbolInfoDouble(pSymbol,SYMBOL_ASK);
	
	double point = SymbolInfoDouble(pSymbol,SYMBOL_POINT);
	double stopLoss = openPrice - (pStopPoints * point);
	
	long digits = SymbolInfoInteger(pSymbol,SYMBOL_DIGITS);
	stopLoss = NormalizeDouble(stopLoss,(int)digits);
	
	return(stopLoss);
}


double SellStopLoss(string pSymbol,int pStopPoints, double pOpenPrice = 0)
{
	if(pStopPoints <= 0) return(0);
	
	double openPrice;
	if(pOpenPrice > 0) openPrice = pOpenPrice;
	else openPrice = SymbolInfoDouble(pSymbol,SYMBOL_BID);
	
	double point = SymbolInfoDouble(pSymbol,SYMBOL_POINT);
	double stopLoss = openPrice + (pStopPoints * point);
	
	long digits = SymbolInfoInteger(pSymbol,SYMBOL_DIGITS);
	stopLoss = NormalizeDouble(stopLoss,(int)digits);
	
	return(stopLoss);
}


double BuyTakeProfit(string pSymbol,int pProfitPoints, double pOpenPrice = 0)
{
	if(pProfitPoints <= 0) return(0);
	
	double openPrice;
	if(pOpenPrice > 0) openPrice = pOpenPrice;
	else openPrice = SymbolInfoDouble(pSymbol,SYMBOL_ASK);
	
	double point = SymbolInfoDouble(pSymbol,SYMBOL_POINT);
	double takeProfit = openPrice + (pProfitPoints * point);
	
	long digits = SymbolInfoInteger(pSymbol,SYMBOL_DIGITS);
	takeProfit = NormalizeDouble(takeProfit,(int)digits);
	return(takeProfit);
}


double SellTakeProfit(string pSymbol,int pProfitPoints, double pOpenPrice = 0)
{
	if(pProfitPoints <= 0) return(0);
	
	double openPrice;
	if(pOpenPrice > 0) openPrice = pOpenPrice;
	else openPrice = SymbolInfoDouble(pSymbol,SYMBOL_BID);
	
	double point = SymbolInfoDouble(pSymbol,SYMBOL_POINT);
	double takeProfit = openPrice - (pProfitPoints * point);
	
	long digits = SymbolInfoInteger(pSymbol,SYMBOL_DIGITS);
	takeProfit = NormalizeDouble(takeProfit,(int)digits);
	return(takeProfit);
}


//+------------------------------------------------------------------+
//| Stop Level Verification                                          |
//+------------------------------------------------------------------+


// Check stop level (no adjust)
bool CheckAboveStopLevel(string pSymbol, double pPrice, int pPoints = 10)
{
	double currPrice = SymbolInfoDouble(pSymbol,SYMBOL_ASK);
	double point = SymbolInfoDouble(pSymbol,SYMBOL_POINT);
	double stopLevel = SymbolInfoInteger(pSymbol,SYMBOL_TRADE_STOPS_LEVEL) * point;
	double stopPrice = currPrice + stopLevel;
	double addPoints = pPoints * point;
	
	if(pPrice >= stopPrice + addPoints) return(true);
	else return(false);
}


bool CheckBelowStopLevel(string pSymbol, double pPrice, int pPoints = 10)
{
	double currPrice = SymbolInfoDouble(pSymbol,SYMBOL_BID);
	double point = SymbolInfoDouble(pSymbol,SYMBOL_POINT);
	double stopLevel = SymbolInfoInteger(pSymbol,SYMBOL_TRADE_STOPS_LEVEL) * point;
	double stopPrice = currPrice - stopLevel;
	double addPoints = pPoints * point;
	
	if(pPrice <= stopPrice - addPoints) return(true);
	else return(false);
}


// Adjust stop level
double AdjustAboveStopLevel(string pSymbol, double pPrice, int pPoints = 10)
{
	double currPrice = SymbolInfoDouble(pSymbol,SYMBOL_ASK);
	double point = SymbolInfoDouble(pSymbol,SYMBOL_POINT);
	double stopLevel = SymbolInfoInteger(pSymbol,SYMBOL_TRADE_STOPS_LEVEL) * point;
	double stopPrice = currPrice + stopLevel;
	double addPoints = pPoints * point;
	
	if(pPrice > stopPrice + addPoints) return(pPrice);
	else
	{
		double newPrice = stopPrice + addPoints;
		Print("Price adjusted above stop level to "+DoubleToString(newPrice));
		return(newPrice);
	}
}


double AdjustBelowStopLevel(string pSymbol, double pPrice, int pPoints = 10)
{
	double currPrice = SymbolInfoDouble(pSymbol,SYMBOL_BID);
	double point = SymbolInfoDouble(pSymbol,SYMBOL_POINT);
	double stopLevel = SymbolInfoInteger(pSymbol,SYMBOL_TRADE_STOPS_LEVEL) * point;
	double stopPrice = currPrice - stopLevel;
	double addPoints = pPoints * point;
	
	if(pPrice < stopPrice - addPoints) return(pPrice);
	else
	{
		double newPrice = stopPrice - addPoints;
		Print("Price adjusted below stop level to "+DoubleToString(newPrice));
		return(newPrice);
	}
}

string TimeFrameToString(ENUM_TIMEFRAMES t)
{
   switch(t)
     {
      case  PERIOD_CURRENT:
         return "CURRENT";
      case PERIOD_M1:
         return "M1";
      case PERIOD_M5:
         return "M5";
      case PERIOD_M15:
         return "M15";
      case PERIOD_M30:
         return "M30";
      case PERIOD_H1:
         return "H1";
      case PERIOD_H4:
         return "H4";
      case PERIOD_D1:
         return "DAY";
      case PERIOD_W1:
         return "WEEK";
      case PERIOD_MN1:
         return "MONTH";
      default:
         return "UNKNOWN";
        break;
     }
}