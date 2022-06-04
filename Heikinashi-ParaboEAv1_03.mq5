//+------------------------------------------------------------------+
//|                                       Heikinashi-ParaboEAvxx.mq5 |
//|                                                 Tislin (ttss000) |
//|                                      https://twitter.com/ttss000 |
//+------------------------------------------------------------------+
// Special Thanks to : https://www.youtube.com/watch?v=4d6OCtl7JDQ
#property copyright "Tislin (ttss000)"
#property link      "https://twitter.com/ttss000"
//#property version   "v01"
#property version   "1.03"
#property strict

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
input int ema_renzoku_up_or_down=50;


double gd_buy_stop=0;
double gd_sell_stop=0;
double gd_highest=-1;
double gd_lowest=-1;

bool gbBuyPending=false;
bool gbSellPending=false;
int   giLongCount=0;
int   giShortCount=0;

ulong last_ticket=0;
ulong prev_ticket=0;

double riskpercent_d_Alembert = d_Alembert_1st_risk;
double riskpercent_d_Alembert_max = 0;

struct WinLoseHist {
  datetime           dt;
  ulong              ticket_num;
  int                WinPlus_Even0_LoseMinus;
};

double glots=input_lots;

double gHeikinAshiOBuffer[];
double gHeikinAshiHBuffer[];
double gHeikinAshiLBuffer[];
double gHeikinAshiCBuffer[];
double gParabolicBuffer[];
double gEMABuffer[];

double gBBUpperBuffer[];
double gBBLowerBuffer[];
double gMABufLongTerm[];
double gMABufMiddleTerm[];
double gMABufShortTerm[];

int gh_Heikinashi;
int gh_Parabolic;
int gh_EMA200;

int gh_BB;
int gh_MA_L;
int gh_MA_M;
int gh_MA_S;

int gStatusLong=0;
int gStatusShort=0;
double g_sl_long;
double g_tp_long;
double g_sl_short;
double g_tp_short;

double g_order_price;
double g_price_diff=0;

//+------------------------------------------------------------------+
datetime TimeHour(datetime TargetTime)
{
  MqlDateTime tm;
  TimeToStruct(TargetTime,tm);
  return tm.hour;
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//--- create timer
  EventSetTimer(60);
  gh_Heikinashi=iCustom(NULL,PERIOD_CURRENT,"Examples\\Heiken_Ashi");
  gh_Parabolic = iSAR(NULL, PERIOD_CURRENT, 0.02, 0.2);
  gh_EMA200 =iMA(NULL, PERIOD_CURRENT, 200, 0, MODE_EMA, PRICE_CLOSE);

//gh_BB=iBands(NULL, PERIOD_CURRENT,BobaPeriod,0,BobaDeviations,PRICE_CLOSE);
//gh_MA_L=iMA(NULL, PERIOD_CURRENT, ma_L_bars, 0, MODE_SMA, PRICE_CLOSE);
//gh_MA_M=iMA(NULL, PERIOD_CURRENT, ma_M_bars, 0, MODE_SMA, PRICE_CLOSE);


  ArraySetAsSeries(gHeikinAshiOBuffer, true);
  ArraySetAsSeries(gHeikinAshiHBuffer, true);
  ArraySetAsSeries(gHeikinAshiLBuffer, true);
  ArraySetAsSeries(gHeikinAshiCBuffer, true);
  ArraySetAsSeries(gParabolicBuffer, true);
  ArraySetAsSeries(gEMABuffer, true);

//ArraySetAsSeries(gBBUpperBuffer, true);
//ArraySetAsSeries(gBBLowerBuffer, true);
//ArraySetAsSeries(gMABufLongTerm, true);
//ArraySetAsSeries(gMABufMiddleTerm, true);

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
  if(Bars(NULL, PERIOD_CURRENT)<ema_renzoku_up_or_down+200) return;

  double d_hl_diff=-1;

  int i_highest=-1;
  int i_lowest=-1;
  bool bema_renzoku_up_or_down_Flag = true;

  CopyBuffer(gh_Heikinashi,0,0,4,gHeikinAshiOBuffer);
  CopyBuffer(gh_Heikinashi,1,0,4,gHeikinAshiHBuffer);
  CopyBuffer(gh_Heikinashi,2,0,4,gHeikinAshiLBuffer);
  CopyBuffer(gh_Heikinashi,3,0,4,gHeikinAshiCBuffer);

  CopyBuffer(gh_Parabolic,0,0,2,gParabolicBuffer);

  CopyBuffer(gh_EMA200,0,0,ema_renzoku_up_or_down+4,gEMABuffer);

//CopyBuffer(gh_BB,2,0,2,gBBLowerBuffer);
//CopyBuffer(gh_BB,1,0,2,gBBUpperBuffer);
//CopyBuffer(gh_MA_L,0,0,2,gMABufLongTerm);
//CopyBuffer(gh_MA_M,0,0,2,gMABufMiddleTerm);

// saisho no status wo state 0
// close ga ema yori ue, ema katamuki ue, chokin 3 hon no heikin ashi geraku, saishin no heikin ashi yori prabo ha ue, jouken 1 seiritsu state 1
// joukenn 1 seiritsu go, close ga ema yori ue, parabolic ga shita, heikin ashi joushou jouken 2 seiritsu state 2
// jouken 2 seritsu maeni, heikin ashi ga ema wo shitamawaru to state 0, ema ga shitamuki state 0,
// tsugiashi de hairu, sl ha joukenn 2 seiritsu no
  bema_renzoku_up_or_down_Flag = true;
  if(giLongCount==0) {
    switch (gStatusLong) {
    case 0:
      for(int i = 0 ; i < ema_renzoku_up_or_down ; i++) {
        if(gEMABuffer[i+2] > gEMABuffer[i+1]) {
          bema_renzoku_up_or_down_Flag = false;
        }
      }
      if(gEMABuffer[1] < gHeikinAshiCBuffer[1]
          && bema_renzoku_up_or_down_Flag
          && gHeikinAshiCBuffer[1] < gHeikinAshiOBuffer[1]
          && gHeikinAshiCBuffer[2] < gHeikinAshiOBuffer[2]
          && gHeikinAshiCBuffer[3] < gHeikinAshiOBuffer[3]
          && gHeikinAshiOBuffer[1] < gParabolicBuffer[1]  ) {
        gStatusLong=1;
      }
      break;
    case 1:
      if(gEMABuffer[1] < gHeikinAshiCBuffer[1]
          && gParabolicBuffer[1] < gHeikinAshiCBuffer[1]
          && gHeikinAshiOBuffer[1] < gHeikinAshiCBuffer[1]
          && gHeikinAshiOBuffer[1] <= gHeikinAshiLBuffer[1]
        ) {
        gStatusLong=2;
        g_sl_long = NormalizeDouble(gParabolicBuffer[1], _Digits);
        //g_tp_long = NormalizeDouble(3*iClose(NULL, PERIOD_CURRENT, 1)-2*g_sl_long, _Digits);
        double dic=iClose(NULL, PERIOD_CURRENT, 1);
        g_tp_long = NormalizeDouble(dic+(dic-g_sl_long)*RR_Ratio, _Digits);
        g_price_diff=dic-g_sl_long;
      } else if(gHeikinAshiCBuffer[1] < gEMABuffer[1]
                || gEMABuffer[1] < gEMABuffer[2]) {
        gStatusLong=0;
      }
      break;
    default:
      break;
    }
    if(gStatusLong==2) {
      if(input_lots <= 0 ) CalcLots();
      if(0<MarketBuy()) {
        // error
        gStatusLong=0;
      }
    }
//  if(bars_cals+1 < Bars(NULL, PERIOD_CURRENT)) {
//    //if(HourStart <= hour_now && hour_now < HourEnd) {
//    //}
//  }
  } else {
    gStatusLong=0;
  }


//------------------------ short jouken -------------------------
  bema_renzoku_up_or_down_Flag = true;
  if(giShortCount==0) {
    switch (gStatusShort) {
    case 0:
      for(int i = 0 ; i < ema_renzoku_up_or_down ; i++) {
        if(gEMABuffer[i+2] < gEMABuffer[i+1]) {
          bema_renzoku_up_or_down_Flag = false;
        }
      }
      if(gEMABuffer[1] > gHeikinAshiCBuffer[1]
          && bema_renzoku_up_or_down_Flag
          && gHeikinAshiCBuffer[1] > gHeikinAshiOBuffer[1]
          && gHeikinAshiCBuffer[2] > gHeikinAshiOBuffer[2]
          && gHeikinAshiCBuffer[3] > gHeikinAshiOBuffer[3]
          && gHeikinAshiOBuffer[1] > gParabolicBuffer[1]  ) {
        gStatusShort=1;
      }
      break;
    case 1:
      if(gEMABuffer[1] > gHeikinAshiCBuffer[1]
          && gParabolicBuffer[1] > gHeikinAshiCBuffer[1]
          && gHeikinAshiOBuffer[1] > gHeikinAshiCBuffer[1]
          && gHeikinAshiOBuffer[1] >= gHeikinAshiHBuffer[1]
        ) {
        gStatusShort=2;
        g_sl_short = NormalizeDouble(gParabolicBuffer[1], _Digits);
        //g_tp_short = NormalizeDouble(3*iClose(NULL, PERIOD_CURRENT, 1)-2*g_sl_short, _Digits);
        double dic=iClose(NULL, PERIOD_CURRENT, 1);
        g_tp_short = NormalizeDouble(dic-(g_sl_short-dic)*RR_Ratio, _Digits);
        g_price_diff=g_sl_short-dic;
      } else if(gHeikinAshiCBuffer[1] > gEMABuffer[1]
                || gEMABuffer[1] > gEMABuffer[2]) {
        gStatusShort=0;
      }
      break;
    default:
      break;
    }
    if(gStatusShort==2) {
      if(input_lots <= 0 ) CalcLots();
      if(0<      MarketSell()) {
        gStatusShort=0;

      }
    }
//  if(bars_cals+1 < Bars(NULL, PERIOD_CURRENT)) {
//    //if(HourStart <= hour_now && hour_now < HourEnd) {
//    //}
//  }
  } else {
    gStatusShort=0;
  }



  CheckPositions();
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
void DeletePendingOrders()
{
//int res;
  ulong ticket;

  MqlTradeRequest request;
  MqlTradeResult  result;

  for(int i = OrdersTotal()-1 ; i >= 0 ; i--) {
    ticket = OrderGetTicket(i);

    //OrderSelect(ticket);
    if(!OrderSelect(ticket)) {
      PrintFormat("OrderSend error %d",GetLastError());  // if unable to send the request, output the error code
      //--- information about the operation
      PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
    } else {


      if(OrderGetString(ORDER_SYMBOL) != Symbol() || OrderGetInteger(ORDER_MAGIC) != input_Magic) {
        continue;
      }
      ZeroMemory(request);
      ZeroMemory(result);
      //--- setting the operation parameters
      request.action  =TRADE_ACTION_REMOVE; // type of trade operation
      request.order=ticket;   // ticket of the position
      request.symbol=_Symbol;     // symbol
      request.volume=glots;
      //request.price=Low2;
      //request.stoplimit=in_Slip*10;
      //request.sl      =Low2+100*Point();                // Stop Loss of the position
      //request.tp      =Low2-150*Point();                // Take Profit of the position
      request.magic=input_Magic;         // MagicNumber of the position
      //request.type=ORDER_TYPE_BUY_STOP;
      //OrderSend(request,result);
      if(!OrderSend(request,result)) {
        PrintFormat("OrderSend error %d",GetLastError());  // if unable to send the request, output the error code
        //--- information about the operation
        PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
      }
    }

    gbBuyPending=false;
    gbSellPending=false;
  }
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void CheckPendingOrders()
{
  gbBuyPending=false;
  gbSellPending=false;

//int res;
  ulong ticket;
  for(int i = OrdersTotal()-1 ; i >= 0 ; i--) {
    ticket = OrderGetTicket(i);
    //OrderSelect(ticket);
    if(!OrderSelect(ticket)) {
      PrintFormat("OrderSend error %d",GetLastError());  // if unable to send the request, output the error code
      //--- information about the operation
      //PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
    } else {

      if(OrderGetString(ORDER_SYMBOL) != Symbol() || OrderGetInteger(ORDER_MAGIC) != input_Magic) {
        continue;
      }
      long order_type = OrderGetInteger(ORDER_TYPE);
      if(order_type == ORDER_TYPE_BUY_STOP) {
        gbBuyPending=true;
      } else if(order_type == ORDER_TYPE_SELL_STOP) {
        gbSellPending=true;
      }
    }
  }
}
//+------------------------------------------------------------------+
void ModifyBuyPendingOrders(void)
{
//int res;
  ulong ticket;
  MqlTradeRequest request;
  MqlTradeResult  result;


  for(int i = OrdersTotal()-1 ; i >= 0 ; i--) {
    ticket = OrderGetTicket(i);
    //OrderSelect(ticket);
    if(!OrderSelect(ticket)) {
      PrintFormat("OrderSend error %d",GetLastError());  // if unable to send the request, output the error code
      //--- information about the operation
      PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
    } else {


      if(OrderGetString(ORDER_SYMBOL) != Symbol() || OrderGetInteger(ORDER_MAGIC) != input_Magic) {
        continue;
      }
      long order_type = OrderGetInteger(ORDER_TYPE);
      if(order_type == ORDER_TYPE_BUY_STOP) {
        ZeroMemory(request);
        ZeroMemory(result);
        request.action   =TRADE_ACTION_MODIFY;        // type of trade operation
        request.position =ticket;          // ticket of the position
        request.symbol   =Symbol();          // symbol
        request.volume   =glots;                   // volume of the position
        request.deviation=input_slip_point;
        request.magic    =input_Magic;             // MagicNumber of the position
        request.price=NormalizeDouble(gd_buy_stop, Digits());
        request.type =ORDER_TYPE_BUY_STOP;
        request.sl =NormalizeDouble(gd_lowest, Digits());
        request.tp =NormalizeDouble(gd_buy_stop+(gd_buy_stop-gd_lowest)*RR_Ratio, Digits());
        //OrderSend(request,result);
        if(!OrderSend(request,result)) {
          PrintFormat("OrderSend error %d",GetLastError());  // if unable to send the request, output the error code
          //--- information about the operation
          PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
        }

      }
    }
  }
}
//+------------------------------------------------------------------+
void ModifySellPendingOrders(void)
{
//int res;
  ulong ticket;
  MqlTradeRequest request;
  MqlTradeResult  result;

  for(int i = OrdersTotal()-1 ; i >= 0 ; i--) {
    ticket = OrderGetTicket(i);
    //OrderSelect(ticket);
    if(!OrderSelect(ticket)) {
      PrintFormat("OrderSend error %d",GetLastError());  // if unable to send the request, output the error code
      //--- information about the operation
      PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
    } else {


      if(OrderGetString(ORDER_SYMBOL) != Symbol() || OrderGetInteger(ORDER_MAGIC) != input_Magic) {
        continue;
      }
      long order_type = OrderGetInteger(ORDER_TYPE);
      if(order_type == ORDER_TYPE_SELL_STOP) {
        ZeroMemory(request);
        ZeroMemory(result);
        request.action   =TRADE_ACTION_MODIFY;        // type of trade operation
        request.position =ticket;          // ticket of the position
        request.symbol   =Symbol();          // symbol
        request.volume   =glots;                   // volume of the position
        request.deviation=input_slip_point;
        request.magic    =input_Magic;             // MagicNumber of the position
        request.price=NormalizeDouble(gd_sell_stop, Digits());
        request.type =ORDER_TYPE_SELL_STOP;
        request.sl =NormalizeDouble(gd_highest, Digits());
        request.tp =NormalizeDouble(gd_sell_stop-(gd_highest-gd_sell_stop)*RR_Ratio, Digits());
        //OrderSend(request,result);
        if(!OrderSend(request,result)) {
          PrintFormat("OrderSend error %d",GetLastError());  // if unable to send the request, output the error code
          //--- information about the operation
          PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
        }

      }
    }
  }

}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void PlaceBuyPendingOrders(void)
{
//int res;
//ulong ticket;
  MqlTradeRequest request;
  MqlTradeResult  result;

  ZeroMemory(request);
  ZeroMemory(result);
//--- setting the operation parameters
  request.action  =TRADE_ACTION_PENDING; // type of trade operation
//request.position=in_ticket_no;   // ticket of the position
  request.symbol=_Symbol;     // symbol
  request.volume=glots;
  request.price=NormalizeDouble(gd_buy_stop, Digits());
  request.price=NormalizeDouble(gd_sell_stop, Digits());
  request.type =ORDER_TYPE_BUY_STOP;
  request.type =ORDER_TYPE_BUY_LIMIT;
  request.sl =NormalizeDouble(gd_lowest, Digits());
  request.sl =NormalizeDouble(gd_sell_stop-(gd_highest-gd_lowest), Digits());
  request.tp =NormalizeDouble(gd_buy_stop+(gd_buy_stop-gd_lowest)*RR_Ratio, Digits());
  request.tp =NormalizeDouble(gd_sell_stop+(gd_highest-gd_lowest)*RR_Ratio, Digits());
  request.magic=input_Magic;         // MagicNumber of the position
  if(!OrderSend(request,result)) {
    PrintFormat("OrderSend error %d",GetLastError());  // if unable to send the request, output the error code
    //--- information about the operation
    PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
  }
}
//+------------------------------------------------------------------+
void PlaceSellPendingOrders(void)
{
//int res;
//ulong ticket;
  MqlTradeRequest request;
  MqlTradeResult  result;

  ZeroMemory(request);
  ZeroMemory(result);
//--- setting the operation parameters
  request.action  =TRADE_ACTION_PENDING; // type of trade operation
//request.position=in_ticket_no;   // ticket of the position
  request.symbol=_Symbol;     // symbol
  request.volume=glots;
//request.price=NormalizeDouble(gd_sell_stop, Digits());
  request.price=NormalizeDouble(gd_buy_stop, Digits());
  request.type =ORDER_TYPE_SELL_STOP;
  request.type =ORDER_TYPE_SELL_LIMIT;
  request.sl =NormalizeDouble(gd_highest, Digits());
  request.sl =NormalizeDouble(gd_buy_stop+(gd_highest-gd_lowest), Digits());
  request.tp =NormalizeDouble(gd_sell_stop-(gd_highest-gd_sell_stop)*RR_Ratio, Digits());
  request.tp =NormalizeDouble(gd_buy_stop-(gd_highest-gd_lowest)*RR_Ratio, Digits());
  request.magic=input_Magic;         // MagicNumber of the position
  if(!OrderSend(request,result)) {
    PrintFormat("OrderSend error %d",GetLastError());  // if unable to send the request, output the error code
    //--- information about the operation
    PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
  }
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void CheckPositions(void)
{

  giLongCount=0;
  giShortCount=0;
  ulong ticket;

  int positions_total = PositionsTotal();
  for(int i = positions_total -1 ; 0 <= i ; i--) {
    ticket = PositionGetTicket(i);
    if(0<ticket) {
      if(PositionSelectByTicket(ticket)) {
        int position_type = (int)PositionGetInteger(POSITION_TYPE);
        if(position_type == POSITION_TYPE_BUY) {
          giLongCount++;
          //Print("iLongCount="+iLongCount);
        } else if(position_type == POSITION_TYPE_SELL) {
          giShortCount++;
          //Print("iShortCount="+iShortCount);
        }
      }
    }
  }
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void CheckWinLoseHistorySort()
{
// [0]=date, [1]=ticket
  WinLoseHist WinLoseHistArray[];

// receive history for the last 180 days
  HistorySelect(iTime(NULL, PERIOD_CURRENT, 0)-3600*24*180, iTime(NULL, PERIOD_CURRENT, 0));
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
        last_ticket=WinLoseHistArray[i_hist].ticket_num;
      }
      break;
    } else if(d_profit<0) {
      WinLoseHistArray[i_hist].WinPlus_Even0_LoseMinus = -1;
      contiguous_lose++;
      if(last_result==0) {
        last_result=-1;
        last_ticket=WinLoseHistArray[i_hist].ticket_num;
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
  if(0<last_result && prev_ticket != last_ticket) {
    riskpercent_d_Alembert -= d_Alembert_risk_diff;
    prev_ticket = last_ticket;
  } else if(last_result<0 && prev_ticket != last_ticket) {
    riskpercent_d_Alembert += d_Alembert_risk_diff;
    prev_ticket = last_ticket;
  }
//Print("riskpercent_d_Alembert0="+riskpercent_d_Alembert);
  if(riskpercent_d_Alembert < d_Alembert_1st_risk) riskpercent_d_Alembert = d_Alembert_1st_risk;
//Print("riskpercent_d_Alembert1="+riskpercent_d_Alembert);
  if(riskpercent_d_Alembert_max < riskpercent_d_Alembert) riskpercent_d_Alembert_max = riskpercent_d_Alembert;
//Print("riskpercent_d_Alembert_max="+  riskpercent_d_Alembert_max);

}
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
  if(bUse_d_Alembert){
    CheckWinLoseHistorySort();
    risk_percent=riskpercent_d_Alembert;
  }
  
  
  AB=AccountInfoDouble(ACCOUNT_EQUITY);
  double tickvalue = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
  double account_value_risk = AB * (risk_percent/100.0);
  double tick_diff = g_price_diff/Point();
  if(0<tick_diff && 0<tickvalue){
    glots=NormalizeDouble(account_value_risk/(tickvalue*tick_diff), 2);
  }
}
//+------------------------------------------------------------------+
