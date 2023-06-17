//+------------------------------------------------------------------+
//|                                                   Indicators.mqh |
//|                                    Copyright 2023, Arnaud Seguin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Arnaud Seguin"
#property link      "https://www.mql5.com"

#include <Indicators\Indicator.mqh>

class CNormalizedTickVolume : public CIndicator
{
protected:
   int               m_ma_period;

public:
                     CNormalizedTickVolume(void);
                    ~CNormalizedTickVolume(void);
   //--- methods of access to protected data
   int               MaPeriod(void) const { return m_ma_period; }
   //--- method of creation
   bool              Create(const string symbol,const ENUM_TIMEFRAMES period, const int ma_period);
   //--- methods of access to indicator data
   double            NormalizedVolume(const int index = 0) const;
   //--- method of identifying
   virtual int       Type(void) const { return 01011976; }

protected:
   //--- methods of tuning
   virtual bool      Initialize(const string symbol, const ENUM_TIMEFRAMES period, const int num_params, const MqlParam &params[]);
   bool              Initialize(const string symbol, const ENUM_TIMEFRAMES period, const int ma_period);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CNormalizedTickVolume::CNormalizedTickVolume(void) : m_ma_period(50)
{
}
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CNormalizedTickVolume::~CNormalizedTickVolume(void)
{
}
//+------------------------------------------------------------------+
//| Create the "Average Directional Index" indicator                 |
//+------------------------------------------------------------------+
bool CNormalizedTickVolume::Create(const string symbol, const ENUM_TIMEFRAMES period, const int ma_period)
{
//--- check history
   if(!SetSymbolPeriod(symbol, period))
      return false;
//--- create
   m_handle = iCustom(symbol, period, "Normalized Tick Volume", ma_period);
//--- check result
   if(m_handle == INVALID_HANDLE)
      return false;
//--- indicator successfully created
   if(!Initialize(symbol, period, ma_period))
   {
      //--- initialization failed
      IndicatorRelease(m_handle);
      m_handle = INVALID_HANDLE;
      return false;
   }
//--- ok
   return true;
}
//+------------------------------------------------------------------+
//| Initialize the indicator with universal parameters               |
//+------------------------------------------------------------------+
bool CNormalizedTickVolume::Initialize(const string symbol, const ENUM_TIMEFRAMES period, const int num_params, const MqlParam &params[])
{
   return Initialize(symbol, period, (int)params[0].integer_value);
}
//+------------------------------------------------------------------+
//| Initialize indicator with the special parameters                 |
//+------------------------------------------------------------------+
bool CNormalizedTickVolume::Initialize(const string symbol, const ENUM_TIMEFRAMES period, const int ma_period)
{
   if(CreateBuffers(symbol, period, 3))
   {
      //--- string of status of drawing
      m_name  ="Normalized Tick Volume";
      m_status="("+symbol+","+PeriodDescription()+","+IntegerToString(ma_period)+") H="+IntegerToString(m_handle);
      //--- save settings
      m_ma_period = ma_period;
      //--- create buffers
      ((CIndicatorBuffer*)At(0)).Name("NORMALIZED_VOLUME");
      ((CIndicatorBuffer*)At(1)).Name("AVERAGE_VOLUME");
      ((CIndicatorBuffer*)At(2)).Name("VOLUME");
      //--- ok
      return true;
   }
//--- error
   return false;
}
//+------------------------------------------------------------------+
//| Access to Main buffer of "Average Directional Index"             |
//+------------------------------------------------------------------+
double CNormalizedTickVolume::NormalizedVolume(const int index) const
{
   CIndicatorBuffer *buffer = At(0);
//--- check
   if(buffer == NULL)
      return EMPTY_VALUE;
//---
   return buffer.At(index);
}
