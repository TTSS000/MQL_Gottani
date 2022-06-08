//+------------------------------------------------------------------+
//|                                         MTF_ZigZag_Dow_EAVxx.mq5 |
//|                                                 Tislin (ttss000) |
//|                                      https://twitter.com/ttss000 |
//+------------------------------------------------------------------+
// https://www.gogojungle.co.jp/systemtrade/fx/31441?t=1

#property copyright "Tislin (ttss000)"
#property link      "https://twitter.com/ttss000"
#property version   "1.07"
#property strict

input ENUM_TIMEFRAMES TargetPeriod = PERIOD_M30;
input int ZigZagL=96;
//input int ZigZagM=24;
input int ZigZagS=12;
input string memo_b_Force_Direction="最新の足がその方向の足の場合に条件成立とする。";
input  bool b_Force_Direction=true;
input  bool b_Future_Only=true;


input string memo_acc="shikin kanri";
input string memo_acc_symbol0="ex,acc=JPY,sym=xxxJPY,bunshibunnbo=1";
input string memo_acc_symbol1="ex,acc=USD,sym=xxxUSD,bunshibunbo=1";
input string memo_acc_symbol2="ex,acc=JPY,sym=XXXUSD,bunshi=1,bunbo=USDJPY";  // convert to USD
input string memo_acc_symbol3="ex,acc=USD,sym=USDxxx,bunshi=USDxxx,bunbo=1";  // convert to xxx
input string memo_acc_symbol4="ex,acc=EUR,sym=XXXUSD,bunshi=EURUSD,bunbo=1";  // convert to USD
input string memo_acc_symbol5="ex,acc=JPY,sym=XXXHKD,bunshi=USDJPY,bunbo=USDHKD";  // convert to JPY

//input int acc_symbol=1;
input string acc_bunshi="1";
input string acc_bunbo="USDJPY";
//input int acc_symbol=1;
input string memo_lot="0=risk%,0<x fix lot";
input double input_lots=0.1;
input double input_risk_percent=2;
//----- d'Alembert -----
input string memo_d_Alembert="";
input bool bUse_d_Alembert=false;
input double d_Alembert_1st_risk=2.0;
input double d_Alembert_risk_diff=0.2;

input unsigned int bars_cals=20;
input double squeeze_ratio_to_price=0.0012;
input int input_Magic=20220604;
//input double input_Slip_point=10;
input int      HourStart=2;
input int      HourEnd=18;
input double RR_Ratio=1;
input double buffer_ratio=1.02;
input int ma_L_bars = 200;
input int ma_M_bars = 75;
input int BobaPeriod= 20;
input double BobaDeviations= 2.8;
input int input_tp_type=0;
input int input_sl_type=0;
input int input_slip_point=10;
input int ema_renzoku_up_or_down=15;

//--- indicator buffers
double    ZigZagBufferL[];      // main buffer
double    ZigZagBufferM[];      // main buffer
double    ZigZagBufferS[];      // main buffer

int h_Custom_S;
int h_Custom_M;
int h_Custom_L;

double g_riskpercent_d_Alembert = d_Alembert_1st_risk;
double g_riskpercent_d_Alembert_max = 0;

double g_top_S_arr[2];
double g_bottom_S_arr[2];

double g_top_L_arr[2];
double g_bottom_L_arr[2];

double g_top_S_new = 0, g_top_S_prev = 0;
double g_bottom_S_new = 0, g_bottom_S_prev = 0;

double g_top_L_new = 0, g_top_L_prev = 0;
double g_bottom_L_new = 0, g_bottom_L_prev = 0;

double g_top_S_right = 0, g_top_S_left = 0;
double g_bottom_S_right = 0, g_bottom_S_left = 0;

double g_top_L_right = 0, g_top_L_left = 0;
double g_bottom_L_right = 0, g_bottom_L_left = 0;

datetime g_dt_S_DowUpFormed_latest[4];
datetime g_dt_S_DowDownFormed_latest[4];

int g_ishift_S_latest = 0;
int g_ishift_S_latest2 = 0;

int g_ishift_S_Top_arr[2];
int g_ishift_S_Bot_arr[2];

int g_ishift_L_Top_arr[2];
int g_ishift_L_Bot_arr[2];

int g_ishift_S_Top_latest = 0;
int g_ishift_S_Top_prev = 0;
int g_ishift_S_Bot_latest = 0;
int g_ishift_S_Bot_prev = 0;

int g_ishift_S_Top_right = 0;
int g_ishift_S_Top_left = 0;
int g_ishift_S_Bot_right = 0;
int g_ishift_S_Bot_left = 0;


datetime g_dt_L_DowUpFormed_latest[4];
datetime g_dt_L_DowDownFormed_latest[4];

int g_ishift_L_latest = 0;
int g_ishift_L_latest2 = 0;

int g_ishift_L_Top_latest = 0;
int g_ishift_L_Top_prev = 0;
int g_ishift_L_Bot_latest = 0;
int g_ishift_L_Bot_prev = 0;

//int S_direction = 0;
//int L_direction = 0;
//int S_Dow_direction = 0;
//int L_Dow_direction = 0;
int g_visible_bars=0;
int g_first_visible_bar=0;

int g_iLongCount=0;
int g_iShortCount=0;
double g_sl_long;
double g_tp_long;
double g_sl_short;
double g_tp_short;

double g_order_price;
double g_price_diff=0;
double glots=input_lots;

struct WinLoseHist {
  datetime           dt;
  ulong              ticket_num;
  int                WinPlus_Even0_LoseMinus;
};

ulong g_last_ticket=0;
ulong g_prev_ticket=0;

bool g_bBuyFlag=false;
bool g_bSellFlag=false;

bool g_b_S_UpDow=false;
bool g_b_S_DownDow=false;
bool g_b_L_UpDow=false;
bool g_b_L_DownDow=false;

bool g_b_S_UpDow1st=false;
bool g_b_S_DownDow1st=false;
bool g_b_L_UpDow1st=false;
bool g_b_L_DownDow1st=false;

uint vline_count = 0;
// USE osma indicator ?

enum ENUM_STATE {
  STATE_NO_TREND, STATE_UP_TREND,STATE_DOWN_TREND, STATE_ORDER_PLACED_OR_HAVE_POSITION
};

ENUM_STATE g_S_state=STATE_NO_TREND;
ENUM_STATE g_L_state=STATE_NO_TREND;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//--- create timer
  EventSetTimer(60);
  h_Custom_S = iCustom(NULL,TargetPeriod,"ZigZag",ZigZagS,5,3);
//h_Custom_M = iCustom(NULL,PERIOD_CURRENT,"ZigZag",12*2,5,3);
  h_Custom_L = iCustom(NULL,TargetPeriod,"ZigZag",ZigZagL,5,3);

  ArraySetAsSeries(ZigZagBufferS, true);
//ArraySetAsSeries(ZigZagBufferM, true);
  ArraySetAsSeries(ZigZagBufferL, true);

  ArrayInitialize(ZigZagBufferS, EMPTY_VALUE);
  ArrayInitialize(ZigZagBufferL, EMPTY_VALUE);

  ArrayInitialize( g_dt_S_DowUpFormed_latest, 0);
  ArrayInitialize( g_dt_S_DowDownFormed_latest, 0);

  ArrayInitialize( g_dt_L_DowUpFormed_latest, 0);
  ArrayInitialize( g_dt_L_DowDownFormed_latest, 0);

  ArrayInitialize( g_dt_L_DowUpFormed_latest, 0);

  ArrayInitialize( g_top_S_arr, 0);
  ArrayInitialize( g_bottom_S_arr, 0);

  ArrayInitialize( g_ishift_S_Top_arr, 0);
  ArrayInitialize( g_ishift_S_Bot_arr, 0);

//---
  return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//--- destroy timer
  EventKillTimer();

}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
//---
  int limit;
//int bars_target_period;
  bool bFoundS = false;
  bool bFoundL = false;
  long local_visible_bars=0;
  long local_first_visible_bar=0;
  int local_S_Top_Count=0;
  int local_S_Bot_Count=0;
  int local_L_Top_Count=0;
  int local_L_Bot_Count=0;

  limit = Bars(NULL, TargetPeriod);

  if(100<limit) {
//bars_target_period = Bars(NULL, TargetPeriod);
    CopyBuffer(h_Custom_S, 0, 0, limit, ZigZagBufferS);
//CopyBuffer(h_Custom_M, 0, 0, limit, ZigZagBufferM);
    CopyBuffer(h_Custom_L, 0, 0, limit, ZigZagBufferL);

    g_bBuyFlag=false;
    g_bSellFlag=false;

    g_b_S_UpDow=false;
    g_b_S_DownDow=false;
    g_b_L_UpDow=false;
    g_b_L_DownDow=false;

    g_b_S_UpDow1st=false;
    g_b_S_DownDow1st=false;
    g_b_L_UpDow1st=false;
    g_b_L_DownDow1st=false;

    for(int i=0 ; i<=limit-1 ; i++) {
      // calc from newer bar
      //i_TargetPeriod = iBarShift(NULL, TargetPeriod, iTime(NULL, PERIOD_CURRENT, i), false);
      double ZgL=ZigZagBufferL[i];
      double ZgS=ZigZagBufferS[i];

      // ======================= short term ============================
      // calc short term zigzag first
      bFoundS = false;
      if(local_S_Top_Count < 2 && ZgS!=0 && MathAbs(ZgS - iHigh(NULL, TargetPeriod, i)) < Point()/2 ) {
        // found top
        if(g_top_S_arr[0] == 0) {
          g_top_S_arr[0] = ZgS;
          g_ishift_S_Top_arr[0] = i;
          //Print("found a S top1");
        } else {
          //Print("found a S top2");
          g_ishift_S_Top_arr[1] = g_ishift_S_Top_arr[0];
          g_ishift_S_Top_arr[0] = i;

          g_top_S_arr[1] = g_top_S_arr[0];
          g_top_S_arr[0] = ZgS;
          bFoundS = true;
          //if(i < 300)        Print ("top ishift_Top_prev ishift_Top_latest="+ishift_S_Top_prev+ "    "+ishift_S_Top_latest);
        }
        local_S_Top_Count++;
      }

      if(local_S_Bot_Count < 2 && ZgS!=0 && MathAbs(ZgS - iLow(NULL, TargetPeriod, i)) < Point()/2 ) {
        // found bottom
        //BottomS[n++]=ZgS;
        //bPositionS[n-1]=i;
        //if(n>=10)break;
        if(g_bottom_S_arr[0] == 0) {
          g_bottom_S_arr[0] = ZgS;
          g_ishift_S_Bot_arr[0] = i;

        } else {
          g_ishift_S_Bot_arr[1] = g_ishift_S_Bot_arr[0];
          g_ishift_S_Bot_arr[0] = i;
          g_bottom_S_arr[1] = g_bottom_S_arr[0];
          g_bottom_S_arr[0] = ZgS;
          bFoundS = true;
          //if(i < 300) Print ("bottom ishift_S_Bot_prev ishift_S_Bot_latest="+ishift_S_Bot_prev+ "    "+ishift_S_Bot_latest);
        }
        local_S_Bot_Count++;
      }

      //if(2<=local_S_Top_Count && 2<= local_S_Bot_Count){
      //     // DEBUG
      //     Print("000 S count="+local_S_Top_Count+"  "+local_S_Bot_Count);
      //}

      //-------------------------- found S --------------------------------
      if(bFoundS && 2 <= local_S_Top_Count && 2 <= local_S_Bot_Count) {
        //Print("S count="+local_L_Bot_Count+"  "+local_S_Bot_Count);
        if(g_top_S_arr[0] < g_top_S_arr[1]
            && g_bottom_S_arr[0] < g_bottom_S_arr[1]
            && g_ishift_S_Top_arr[1] < g_ishift_S_Bot_arr[1]  // newer shift is top
          ) {
          // --------------------  up trend short term -----------------------
          // compare time of the bottom
          g_b_S_UpDow=true;
          g_b_S_UpDow1st=false;
          if(g_dt_S_DowUpFormed_latest[0] != iTime(NULL, TargetPeriod, g_ishift_S_Bot_arr[0])) {
            g_dt_S_DowUpFormed_latest[0] = iTime(NULL, TargetPeriod, g_ishift_S_Bot_arr[0]) ;
            g_b_S_UpDow1st=true;
            if(g_S_state != STATE_ORDER_PLACED_OR_HAVE_POSITION) {
              g_S_state=STATE_UP_TREND;
            }
            //Print("S New Up trend at bottom,  target Peri  "+g_dt_S_DowUpFormed_latest[0]+"  "+iTime(NULL, TargetPeriod, i));

            //ObjectCreate(id, name, type, subwin, time, price)
            //ObjectCreate(0, "SU"+IntegerToString(vline_count), OBJ_VLINE, 0, iTime(NULL, PERIOD_CURRENT, 0),0);
            //ObjectSetInteger(0, "SU"+IntegerToString(vline_count), OBJPROP_COLOR, clrBlue);
            //ObjectSetInteger(0, "SU"+IntegerToString(vline_count), OBJPROP_WIDTH, 1);
            //vline_count++;
          }
          //Print("S Up trend");
          //break;
        }
        //if(g_top_S_prev < g_top_S_new && g_bottom_S_prev < g_bottom_S_new) {
        if(g_top_S_arr[0] > g_top_S_arr[1]
            && g_bottom_S_arr[0] > g_bottom_S_arr[1]
            && g_ishift_S_Top_arr[1] > g_ishift_S_Bot_arr[1]  // newer shift is bottom
          ) {
          g_b_S_DownDow=true;
          g_b_S_DownDow1st=false;
          // ------------------------down trend short term ----------------------------------
          if(g_dt_S_DowDownFormed_latest[0] != iTime(NULL, TargetPeriod, g_ishift_S_Top_arr[0])) {
            g_dt_S_DowDownFormed_latest[0] = iTime(NULL, TargetPeriod, g_ishift_S_Top_arr[0]) ;
            if(g_S_state != STATE_ORDER_PLACED_OR_HAVE_POSITION) {
              g_S_state=STATE_DOWN_TREND;
            }
            g_b_S_DownDow1st=true;
            //Print("S New Down trend at top, target peri "+g_dt_S_DowDownFormed_latest[0]+"  "+iTime(NULL, TargetPeriod, i));
            //ObjectCreate(0, "SU"+IntegerToString(vline_count), OBJ_VLINE, 0, iTime(NULL, PERIOD_CURRENT, 0),0);
            //ObjectSetInteger(0, "SU"+IntegerToString(vline_count), OBJPROP_COLOR, clrRed);
            //ObjectSetInteger(0, "SU"+IntegerToString(vline_count), OBJPROP_WIDTH, 1);
            //vline_count++;
          }
        }

        if(!g_b_S_UpDow && !g_b_S_DownDow ) {
          //Print("S No trend");
          g_S_state=STATE_NO_TREND;
          //break;
        }
      }

// ======================= long term ============================
// calc long term zigzag next
      bFoundL = false;
      if(local_L_Top_Count < 2 && ZgL!=0 && MathAbs(ZgL - iHigh(NULL, TargetPeriod, i)) < Point()/2 ) {
        // found top
        if(g_top_L_arr[0] == 0) {
          g_top_L_arr[0] = ZgL;
          g_ishift_L_Top_arr[0] = i;
        } else {
          g_ishift_L_Top_arr[1] = g_ishift_L_Top_arr[0];
          g_ishift_L_Top_arr[0] = i;

          g_top_L_arr[1] = g_top_L_arr[0];
          g_top_L_arr[0] = ZgL;
          bFoundL = true;
          //if(i < 300)        Print ("top ishift_L Top_prev ishift_L Top_latest="+ishift_L_Top_prev+ "    "+ishift_L_Top_latest);
        }
        //TopS[m++]=ZgS;
        //tPositionS[m-1]=i;
        //if(m>=10)break;
        local_L_Top_Count++;
      }

      if(local_L_Bot_Count < 2 && ZgL!=0 && MathAbs(ZgL - iLow(NULL, TargetPeriod, i)) < Point()/2 ) {
        // found bottom
        //BottomS[n++]=ZgS;
        //bPositionS[n-1]=i;
        //if(n>=10)break;
        if(g_bottom_L_arr[0] == 0) {
          g_bottom_L_arr[0] = ZgL;
          g_ishift_L_Bot_arr[0] = i;
        } else {
          g_ishift_L_Bot_arr[1] = g_ishift_L_Bot_arr[0];
          g_ishift_L_Bot_arr[0]= i;
          g_bottom_L_arr[1] = g_bottom_L_arr[0];
          g_bottom_L_arr[0] = ZgL;
          bFoundL = true;
          //if(i < 300) Print ("bottom ishift_L_Bot_prev ishift_L_Bot_latest="+ishift_L_Bot_prev+ "    "+ishift_L_Bot_latest);
        }
        local_L_Bot_Count++;
      }

      //-------------------------- found L --------------------------------
      //if(2<=local_L_Top_Count && 2<= local_L_Bot_Count) {
      //  // DEBUG
      //  Print("001 L count="+local_L_Top_Count+"  "+local_L_Bot_Count);
      //  //break;
      //}

      //if(bFoundS && 2 <= local_S_Top_Count && 2 <= local_S_Bot_Count) {
      //  //Print("S count="+local_L_Bot_Count+"  "+local_S_Bot_Count);
      //  if(g_top_S_arr[0] < g_top_S_arr[1]
      //      && g_bottom_S_arr[0] < g_bottom_S_arr[1]
      //      && g_ishift_S_Top_arr[1] < g_ishift_S_Bot_arr[1]  // newer shift is top
      //      ) {

      if(bFoundL && 2 <= local_L_Top_Count && 2 <= local_L_Bot_Count) {
        //Print("S count="+local_L_Bot_Count+"  "+local_S_Bot_Count);
        if(g_top_L_arr[0] < g_top_L_arr[1]
            && g_bottom_L_arr[0] < g_bottom_L_arr[1]
            && g_ishift_L_Top_arr[1] < g_ishift_L_Bot_arr[1]  // newer shift is top
          ) {
          g_b_L_UpDow=true;
          g_b_L_UpDow1st=false;

          //// compare time of the bottom
          //if(g_dt_S_DowUpFormed_latest[0] != iTime(NULL, TargetPeriod, g_ishift_S_Bot_arr[0])) {
          //  g_dt_S_DowUpFormed_latest[0] = iTime(NULL, TargetPeriod, g_ishift_S_Bot_arr[0]) ;
          //  g_b_S_UpDow=true;
          //  Print("S New Up trend at bottom,  target Peri  "+g_dt_S_DowUpFormed_latest[0]+"  "+iTime(NULL, TargetPeriod, i));

          // --------------------  up trend long term -----------------------
          //// compare time of the bottom
          if(g_dt_L_DowUpFormed_latest[0] != iTime(NULL, TargetPeriod, g_ishift_L_Bot_arr[0])) {
            g_dt_L_DowUpFormed_latest[0] = iTime(NULL, TargetPeriod, g_ishift_L_Bot_arr[0]) ;
            g_b_L_UpDow1st=true;

            if(g_L_state != STATE_ORDER_PLACED_OR_HAVE_POSITION) {
              g_L_state=STATE_UP_TREND;
            }

            //Print("L New Up trend at bottom, target peri "+g_dt_L_DowUpFormed_latest[0]+"  "+iTime(NULL, TargetPeriod, i));
          }
          break;
        }

        //if(g_top_L_prev < g_top_L_new && g_bottom_L_prev < g_bottom_L_new) {
        if(g_top_L_arr[0] > g_top_L_arr[1]
            && g_bottom_L_arr[0] > g_bottom_L_arr[1]
            && g_ishift_L_Top_arr[1] > g_ishift_L_Bot_arr[1]  // newer shift is bottom
          ) {
          g_b_L_DownDow=true;
          g_b_L_DownDow1st=false;
          // ------------------------down trend long term ----------------------------------
          if(g_dt_L_DowDownFormed_latest[0] != iTime(NULL, TargetPeriod, g_ishift_L_Top_arr[0])) {
            g_dt_L_DowDownFormed_latest[0] = iTime(NULL, TargetPeriod, g_ishift_L_Top_arr[0]) ;
            if(g_L_state != STATE_ORDER_PLACED_OR_HAVE_POSITION) {
              g_L_state=STATE_DOWN_TREND;
            }
            g_b_L_DownDow1st=true;
            //Print("L New Down trend at top, target peri "+g_dt_L_DowDownFormed_latest[0]+"  "+iTime(NULL, TargetPeriod, i));
          }
          break;
        }
        if(!g_b_L_UpDow && !g_b_L_DownDow ) {
          //Print("L No trend");
          g_L_state=STATE_NO_TREND;
          break;
        }
      }
    } // for

    if(g_b_S_UpDow 
    //&& g_b_L_UpDow 
    //&& (g_b_S_UpDow1st || g_b_L_UpDow1st)) {
    && g_b_S_UpDow1st
    ) {
      // up trend but 1st time?
      // check last S bottom is the same or not
      g_bBuyFlag=true;
      g_bSellFlag=false;
      //break;
    }
    if(g_b_S_DownDow  
    //&& g_b_L_DownDow 
    //&& (g_b_S_DownDow1st || g_b_L_DownDow1st)
    && g_b_S_DownDow1st
    ) {
      // down trend but 1st time?
      // check last S top the same or not
      g_bBuyFlag=false;
      g_bSellFlag=true;
      //break;
    }

    double Bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
    double Ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);

    CheckPositions();
    if(g_iLongCount==0 && g_bBuyFlag) {
      g_order_price = Ask;
      //g_sl_long = g_order_price-100*Point();
      g_sl_long = g_bottom_S_arr[1];
      //g_tp_long = g_order_price+100*Point();
      g_tp_long = g_order_price+g_order_price-g_sl_long;
      g_price_diff = g_order_price - g_sl_long;
      CalcLots();
      MarketBuy();
      g_S_state=STATE_ORDER_PLACED_OR_HAVE_POSITION;
      g_L_state=STATE_ORDER_PLACED_OR_HAVE_POSITION;

    }
    if(g_iShortCount==0 && g_bSellFlag) {
      g_order_price = Bid;
      //g_sl_short = g_order_price+100*Point();
      g_sl_short = g_top_S_arr[1];
      //g_tp_short = g_order_price-100*Point();
      g_tp_short = g_order_price-(g_sl_short-g_order_price);

      g_price_diff = g_sl_short - g_order_price;
      CalcLots();

      MarketSell();
      g_S_state=STATE_ORDER_PLACED_OR_HAVE_POSITION;
      g_L_state=STATE_ORDER_PLACED_OR_HAVE_POSITION;
    }
  }

}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
//---

}
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
{
//---

}
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{
//---

}
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
{
//---
  double ret=0.0;
//---

//---
  return(ret);
}
//+------------------------------------------------------------------+
//| TesterInit function                                              |
//+------------------------------------------------------------------+
void OnTesterInit()
{
//---

}
//+------------------------------------------------------------------+
//| TesterPass function                                              |
//+------------------------------------------------------------------+
void OnTesterPass()
{
//---

}
//+------------------------------------------------------------------+
//| TesterDeinit function                                            |
//+------------------------------------------------------------------+
void OnTesterDeinit()
{
//---

}
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
//---

}
//+------------------------------------------------------------------+
//| BookEvent function                                               |
//+------------------------------------------------------------------+
void OnBookEvent(const string &symbol)
{
//---

}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
uint MarketBuy(void)
{
  uint ret_code=0;

  MqlTradeRequest request;
  MqlTradeResult  result;

// if(OrderSend(NULL, OP_BUY, lots, order_price, slip_point, 0, 0, NULL, magic, 0, clrNONE)<0){
  ZeroMemory(request);
  ZeroMemory(result);


  switch(input_tp_type) {
  case 0:
    request.tp =0;
    break;
  case 1:
    //request.tp =NormalizeDouble(g_order_price*(1+tp_ratio), Digits());
    break;
  default:
    break;
  }

  switch(input_sl_type) {
  case 0:
    request.sl =0;
    break;
  case 1:
    //request.sl =NormalizeDouble(g_order_price*(1-sl_ratio), Digits());
    break;
  default:
    request.sl =0;
    break;
  }

  request.tp =g_tp_long;
  request.sl =g_sl_long;


  request.action   =TRADE_ACTION_DEAL;        // type of trade operation
//request.action   =TRADE_ACTION_PENDING;        // type of trade operation
//request.position =position_ticket;          // ticket of the position
  request.symbol   =Symbol();          // symbol
  request.volume   =glots;                   // volume of the position
  request.deviation=input_slip_point;                        // allowed deviation from the price
  request.magic    =input_Magic;             // MagicNumber of the position
  request.price=g_order_price;
//request.price=MA_S_Line[1];
  request.type =ORDER_TYPE_BUY;
//request.type =ORDER_TYPE_SELL_LIMIT;
//request.sl =0;
//request.type_filling = ORDER_FILLING_RETURN;
  request.type_filling = ORDER_FILLING_FOK;
  request.type_filling = ORDER_FILLING_IOC;

//OrderSend(request,result);
  if(!OrderSend(request,result)) {
    PrintFormat("OrderSend error %d",GetLastError());  // if unable to send the request, output the error code
    //--- information about the operation
    PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
    ret_code=result.retcode;
  }

  return ret_code;
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
uint MarketSell(void)
{
  uint ret_code=0;
  MqlTradeRequest request;
  MqlTradeResult  result;

// if(OrderSend(NULL, OP_BUY, lots, order_price, slip_point, 0, 0, NULL, magic, 0, clrNONE)<0){

  ZeroMemory(request);
  ZeroMemory(result);

  switch(input_tp_type) {
  case 0:
    request.tp =0;
    break;
  case 1:
    //request.tp =NormalizeDouble(g_order_price*(1-tp_ratio), Digits());
    break;
  default:
    request.tp =0;
    break;
  }

  switch(input_sl_type) {
  case 0:
    request.sl =0;
    break;
  case 1:
    //request.sl =NormalizeDouble(g_order_price*(1+sl_ratio), Digits());
    break;
  default:
    request.sl =0;
    break;
  }

  request.tp =g_tp_short;
  request.sl =g_sl_short;


  request.action   =TRADE_ACTION_DEAL;        // type of trade operation
//request.action   =TRADE_ACTION_PENDING;        // type of trade operation
//request.position =position_ticket;          // ticket of the position
  request.symbol   =Symbol();          // symbol
  request.volume   =glots;                   // volume of the position
  request.deviation=input_slip_point;                        // allowed deviation from the price
  request.magic    =input_Magic;             // MagicNumber of the position
  request.price=g_order_price;
//request.price=MA_S_Line[1];
  request.type =ORDER_TYPE_SELL;
//request.type =ORDER_TYPE_SELL_LIMIT;
//request.sl =0;
//request.type_filling = ORDER_FILLING_RETURN;
  request.type_filling = ORDER_FILLING_FOK;
  request.type_filling = ORDER_FILLING_IOC;

//OrderSend(request,result);
  if(!OrderSend(request,result)) {
    PrintFormat("OrderSend error %d",GetLastError());  // if unable to send the request, output the error code
    //--- information about the operation
    PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
    ret_code =result.retcode;
  }

  return ret_code;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
void CalcLots(void)
{
  double AB;

  double risk_percent = input_risk_percent;
  if(bUse_d_Alembert) {
    CheckWinLoseHistorySort();
    risk_percent=g_riskpercent_d_Alembert;
  }


  AB=AccountInfoDouble(ACCOUNT_EQUITY);
  double tickvalue = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
  double account_value_risk = AB * (risk_percent/100.0);
  double tick_diff = g_price_diff/Point();
  if(0<tick_diff && 0<tickvalue) {
    glots=NormalizeDouble(account_value_risk/(tickvalue*tick_diff), 2);
  }
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void CheckWinLoseHistorySort()
{
// [0]=date, [1]=ticket
  WinLoseHist WinLoseHistArray[];

// receive history for the last 180 days
  HistorySelect(iTime(NULL, TargetPeriod, 0)-3600*24*180, iTime(NULL, TargetPeriod, 0));
  int total_HistoryDeals = HistoryDealsTotal();
//Print("total_HistoryDeals="+total_HistoryDeals);

  ArrayResize(WinLoseHistArray, total_HistoryDeals*sizeof(WinLoseHist));
  int contiguous_lose = 0;
  int last_result=0;

  for(int i_hist = total_HistoryDeals - 1 ; 0 <= i_hist ; i_hist--) {
    WinLoseHistArray[i_hist].ticket_num = HistoryDealGetTicket(i_hist);
    HistoryDealSelect(WinLoseHistArray[i_hist].ticket_num);
    WinLoseHistArray[i_hist].dt=(datetime)HistoryDealGetInteger(WinLoseHistArray[i_hist].ticket_num,DEAL_TIME);
    double d_profit = HistoryDealGetDouble(WinLoseHistArray[i_hist].ticket_num, DEAL_PROFIT);
    if(0<d_profit) {
      WinLoseHistArray[i_hist].WinPlus_Even0_LoseMinus = 1;
      if(last_result==0) {
        last_result=1;
        g_last_ticket=WinLoseHistArray[i_hist].ticket_num;
      }
      break;
    } else if(d_profit<0) {
      WinLoseHistArray[i_hist].WinPlus_Even0_LoseMinus = -1;
      contiguous_lose++;
      if(last_result==0) {
        last_result=-1;
        g_last_ticket=WinLoseHistArray[i_hist].ticket_num;
      }
    } else {
      WinLoseHistArray[i_hist].WinPlus_Even0_LoseMinus = 0;
    }
    //Print("WinLoseHistArray dt WL="+WinLoseHistArray[i_hist].dt+" : "+WinLoseHistArray[i_hist].WinPlus_Even0_LoseMinus);
  }
//Print("lastticket, contiguous_lose,last_result="+last_ticket+" : "+contiguous_lose+" : "+last_result);
//input double d_Alembert_1st_risk=2.0;
//input double d_Alembert_risk_diff=0.2;
//Print("contiguous_lose="+contiguous_lose);
  if(0<last_result && g_prev_ticket != g_last_ticket) {
    g_riskpercent_d_Alembert -= d_Alembert_risk_diff;
    g_prev_ticket = g_last_ticket;
  } else if(last_result<0 && g_prev_ticket != g_last_ticket) {
    g_riskpercent_d_Alembert += d_Alembert_risk_diff;
    g_prev_ticket = g_last_ticket;
  }
//Print("riskpercent_d_Alembert0="+riskpercent_d_Alembert);
  if(g_riskpercent_d_Alembert < d_Alembert_1st_risk) g_riskpercent_d_Alembert = d_Alembert_1st_risk;
//Print("riskpercent_d_Alembert1="+riskpercent_d_Alembert);
  if(g_riskpercent_d_Alembert_max < g_riskpercent_d_Alembert) g_riskpercent_d_Alembert_max = g_riskpercent_d_Alembert;
//Print("riskpercent_d_Alembert_max="+  riskpercent_d_Alembert_max);

}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void CheckPositions(void)
{

  g_iLongCount=0;
  g_iShortCount=0;
  ulong ticket;

  int positions_total = PositionsTotal();
  for(int i = positions_total -1 ; 0 <= i ; i--) {
    ticket = PositionGetTicket(i);
    if(0<ticket) {
      if(PositionSelectByTicket(ticket)) {
        int position_type = (int)PositionGetInteger(POSITION_TYPE);
        if(position_type == POSITION_TYPE_BUY) {
          g_iLongCount++;
          //Print("iLongCount="+iLongCount);
        } else if(position_type == POSITION_TYPE_SELL) {
          g_iShortCount++;
          //Print("iShortCount="+iShortCount);
        }
      }
    }
  }
}
//+------------------------------------------------------------------+
