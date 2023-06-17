//+------------------------------------------------------------------+
//|                                                   PeakFinder.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   int shoulder = 5;
   int bar1, bar2;
   
   bar1 = FindPeak(MODE_HIGH, shoulder, 0);
   bar2 = FindPeak(MODE_HIGH, shoulder, bar1 + 1);
   
   ObjectDelete(0, "upper");
   ObjectCreate(0, "upper", OBJ_TREND, 0, iTime(Symbol(), Period(), bar2), iHigh(Symbol(), Period(), bar2), iTime(Symbol(), Period(), bar1), iHigh(Symbol(), Period(), bar1));
   ObjectSetInteger(0, "upper", OBJPROP_COLOR, clrBlue);
   ObjectSetInteger(0, "upper", OBJPROP_WIDTH, 3);
   ObjectSetInteger(0, "upper", OBJPROP_RAY_RIGHT, true);
   
   bar1 = FindPeak(MODE_LOW, shoulder, 0);
   bar2 = FindPeak(MODE_LOW, shoulder, bar1 + 1);
   
   ObjectDelete(0, "lower");
   ObjectCreate(0, "lower", OBJ_TREND, 0, iTime(Symbol(), Period(), bar2), iLow(Symbol(), Period(), bar2), iTime(Symbol(), Period(), bar1), iLow(Symbol(), Period(), bar1));
   ObjectSetInteger(0, "lower", OBJPROP_COLOR, clrBlue);
   ObjectSetInteger(0, "lower", OBJPROP_WIDTH, 3);
   ObjectSetInteger(0, "lower", OBJPROP_RAY_RIGHT, true);
}

int FindPeak(int mode, int count, int startBar)
{
   if (mode != MODE_HIGH && mode != MODE_LOW)
      return -1;
   
   int currentBar = startBar;
   int foundBar = FindNextPeak(mode, 2*count + 1, currentBar - count);
   while (foundBar != currentBar)
   {
      currentBar = FindNextPeak(mode, count, currentBar + 1);
      foundBar = FindNextPeak(mode, 2*count + 1, currentBar - count);
   }
   
   return currentBar;
}

int FindNextPeak(int mode, int count, int startBar)
{
   if (startBar < 0)
   {
      count += startBar;
      startBar = 0;
   }
   
   int nextPeak = (mode == MODE_HIGH) ? iHighest(Symbol(), Period(), (ENUM_SERIESMODE)mode, count, startBar) : iLowest(Symbol(), Period(), (ENUM_SERIESMODE)mode, count, startBar);
   
   return nextPeak;
}