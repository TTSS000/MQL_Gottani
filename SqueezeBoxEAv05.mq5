//+------------------------------------------------------------------+
//|                                              SqueezeBoxEAvxx.mq5 |
//|                                                 Tislin (ttss000) |
//|                                      https://twitter.com/ttss000 |
//+------------------------------------------------------------------+
#property copyright "Tislin (ttss000)"
#property link      "https://twitter.com/ttss000"
#property strict
#property version   "v05"


input unsigned int bars_cals=20;
input double squeeze_ratio_to_price=0.0012;
input int input_Magic=20220529;
input double input_lots=0.1;
input double input_Slip_point=10;
input int      HourStart=2;
input int      HourEnd=18;
input double RR_Ratio=1;
input double buffer_ratio=1.02;
input int ma_L_bars = 200;
input int ma_M_bars = 75;
input int BobaPeriod= 20;
input double BobaDeviations= 2.8;

//----- d'Alembert -----
input string memo_d_Alembert="";
input bool bUse_d_Alembert=false;
input double d_Alembert_1st_risk=2.0;
input double d_Alembert_risk_diff=0.2;

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

double lots=input_lots;

double BBUpperBuffer[];
double BBLowerBuffer[];
double MABufLongTerm[];
double MABufMiddleTerm[];
double MABufShortTerm[];

int h_BB;
int h_MA_L;
int h_MA_M;
int h_MA_S;


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
  h_BB=iBands(NULL, PERIOD_CURRENT,BobaPeriod,0,BobaDeviations,PRICE_CLOSE);
  h_MA_L=iMA(NULL, PERIOD_CURRENT, ma_L_bars, 0, MODE_SMA, PRICE_CLOSE);
  h_MA_M=iMA(NULL, PERIOD_CURRENT, ma_M_bars, 0, MODE_SMA, PRICE_CLOSE);

  ArraySetAsSeries(BBUpperBuffer, true);
  ArraySetAsSeries(BBLowerBuffer, true);
  ArraySetAsSeries(MABufLongTerm, true);
  ArraySetAsSeries(MABufMiddleTerm, true);

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
  double d_hl_diff=-1;

  int i_highest=-1;
  int i_lowest=-1;

  CopyBuffer(h_BB,2,0,2,BBLowerBuffer);
  CopyBuffer(h_BB,1,0,2,BBUpperBuffer);
  CopyBuffer(h_MA_L,0,0,2,MABufLongTerm);
  CopyBuffer(h_MA_M,0,0,2,MABufMiddleTerm);

  if(bars_cals+1 < Bars(NULL, PERIOD_CURRENT)) {
    i_highest = iHighest(NULL,PERIOD_CURRENT, MODE_HIGH, bars_cals, 1);
    i_lowest = iLowest(NULL,PERIOD_CURRENT, MODE_LOW, bars_cals, 1);
    gd_highest = iHigh(NULL, PERIOD_CURRENT, i_highest);
    gd_lowest = iLow(NULL, PERIOD_CURRENT, i_lowest);
    d_hl_diff = gd_highest - gd_lowest;

    CheckWinLoseHistorySort();
    if(bUse_d_Alembert) lots = input_lots * riskpercent_d_Alembert;

    datetime hour_now = TimeHour(iTime(NULL, PERIOD_CURRENT, 0));
    if(HourStart <= hour_now && hour_now < HourEnd) {
      if(0 < squeeze_ratio_to_price && d_hl_diff/iClose(NULL, PERIOD_CURRENT, 1) < squeeze_ratio_to_price) {
        gd_buy_stop=buffer_ratio*(iClose(NULL, PERIOD_CURRENT, 1)*squeeze_ratio_to_price)+gd_lowest;
        gd_sell_stop=gd_highest-buffer_ratio*iClose(NULL, PERIOD_CURRENT, 1)*squeeze_ratio_to_price;
        DeletePendingOrders();
        //CheckPendingOrders();
        CheckPositions();

        if(gbBuyPending) {
          ModifyBuyPendingOrders();
        } else {
          if(giLongCount==0 && MABufLongTerm[0] < iClose(NULL, PERIOD_CURRENT, 0) 
          && MABufLongTerm[1] < MABufLongTerm[0]
          && MABufMiddleTerm[1] < MABufMiddleTerm[0]
          && MABufLongTerm[0] < MABufMiddleTerm[0]
          ){
            PlaceBuyPendingOrders();
          }

        }

        if(gbSellPending) {
          ModifyBuyPendingOrders();
        } else {
          if(giShortCount==0 && iClose(NULL, PERIOD_CURRENT, 0) < MABufLongTerm[0] 
          && MABufLongTerm[0] < MABufLongTerm[1]
          && MABufMiddleTerm[0] < MABufMiddleTerm[1]
          && MABufMiddleTerm[0] < MABufLongTerm[0]
          ){
            PlaceSellPendingOrders();
          }
        }
      } else {
        gd_buy_stop=0;
        gd_sell_stop=0;
        DeletePendingOrders();
      }
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
void DeletePendingOrders()
{
  int res;
  ulong ticket;

  MqlTradeRequest request;
  MqlTradeResult  result;

  for(int i = OrdersTotal()-1 ; i >= 0 ; i--) {
    ticket = OrderGetTicket(i);

    OrderSelect(ticket);
    if(OrderGetString(ORDER_SYMBOL) != Symbol() || OrderGetInteger(ORDER_MAGIC) != input_Magic) {
      continue;
    }
    ZeroMemory(request);
    ZeroMemory(result);
    //--- setting the operation parameters
    request.action  =TRADE_ACTION_REMOVE; // type of trade operation
    request.order=ticket;   // ticket of the position
    request.symbol=_Symbol;     // symbol
    request.volume=lots;
    //request.price=Low2;
    //request.stoplimit=in_Slip*10;
    //request.sl      =Low2+100*Point();                // Stop Loss of the position
    //request.tp      =Low2-150*Point();                // Take Profit of the position
    request.magic=input_Magic;         // MagicNumber of the position
    //request.type=ORDER_TYPE_BUY_STOP;
    OrderSend(request,result);
  }

  gbBuyPending=false;
  gbSellPending=false;
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void CheckPendingOrders()
{
  gbBuyPending=false;
  gbSellPending=false;

  int res;
  ulong ticket;
  for(int i = OrdersTotal()-1 ; i >= 0 ; i--) {
    ticket = OrderGetTicket(i);
    OrderSelect(ticket);
    if(OrderGetString(ORDER_SYMBOL) != Symbol() || OrderGetInteger(ORDER_MAGIC) != input_Magic) {
      continue;
    }
    int order_type = OrderGetInteger(ORDER_TYPE);
    if(order_type == ORDER_TYPE_BUY_STOP) {
      gbBuyPending=true;
    } else if(order_type == ORDER_TYPE_SELL_STOP) {
      gbSellPending=true;
    }
  }
}
//+------------------------------------------------------------------+
void ModifyBuyPendingOrders(void)
{
  int res;
  ulong ticket;
  MqlTradeRequest request;
  MqlTradeResult  result;


  for(int i = OrdersTotal()-1 ; i >= 0 ; i--) {
    ticket = OrderGetTicket(i);
    OrderSelect(ticket);
    if(OrderGetString(ORDER_SYMBOL) != Symbol() || OrderGetInteger(ORDER_MAGIC) != input_Magic) {
      continue;
    }
    int order_type = OrderGetInteger(ORDER_TYPE);
    if(order_type == ORDER_TYPE_BUY_STOP) {
      ZeroMemory(request);
      ZeroMemory(result);
      request.action   =TRADE_ACTION_MODIFY;        // type of trade operation
      request.position =ticket;          // ticket of the position
      request.symbol   =Symbol();          // symbol
      request.volume   =lots;                   // volume of the position
      request.deviation=input_Slip_point;
      request.magic    =input_Magic;             // MagicNumber of the position
      request.price=NormalizeDouble(gd_buy_stop, Digits());
      request.type =ORDER_TYPE_BUY_STOP;
      request.sl =NormalizeDouble(gd_lowest, Digits());
      request.tp =NormalizeDouble(gd_buy_stop+(gd_buy_stop-gd_lowest)*RR_Ratio, Digits());
      OrderSend(request,result);
    }
  }
}
//+------------------------------------------------------------------+
void ModifySellPendingOrders(void)
{
  int res;
  ulong ticket;
  MqlTradeRequest request;
  MqlTradeResult  result;

  for(int i = OrdersTotal()-1 ; i >= 0 ; i--) {
    ticket = OrderGetTicket(i);
    OrderSelect(ticket);
    if(OrderGetString(ORDER_SYMBOL) != Symbol() || OrderGetInteger(ORDER_MAGIC) != input_Magic) {
      continue;
    }
    int order_type = OrderGetInteger(ORDER_TYPE);
    if(order_type == ORDER_TYPE_SELL_STOP) {
      ZeroMemory(request);
      ZeroMemory(result);
      request.action   =TRADE_ACTION_MODIFY;        // type of trade operation
      request.position =ticket;          // ticket of the position
      request.symbol   =Symbol();          // symbol
      request.volume   =lots;                   // volume of the position
      request.deviation=input_Slip_point;
      request.magic    =input_Magic;             // MagicNumber of the position
      request.price=NormalizeDouble(gd_sell_stop, Digits());
      request.type =ORDER_TYPE_SELL_STOP;
      request.sl =NormalizeDouble(gd_highest, Digits());
      request.tp =NormalizeDouble(gd_sell_stop-(gd_highest-gd_sell_stop)*RR_Ratio, Digits());
      OrderSend(request,result);
    }
  }
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void PlaceBuyPendingOrders(void)
{
  int res;
  ulong ticket;
  MqlTradeRequest request;
  MqlTradeResult  result;

  ZeroMemory(request);
  ZeroMemory(result);
//--- setting the operation parameters
  request.action  =TRADE_ACTION_PENDING; // type of trade operation
//request.position=in_ticket_no;   // ticket of the position
  request.symbol=_Symbol;     // symbol
  request.volume=lots;
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
  int res;
  ulong ticket;
  MqlTradeRequest request;
  MqlTradeResult  result;

  ZeroMemory(request);
  ZeroMemory(result);
//--- setting the operation parameters
  request.action  =TRADE_ACTION_PENDING; // type of trade operation
//request.position=in_ticket_no;   // ticket of the position
  request.symbol=_Symbol;     // symbol
  request.volume=lots;
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
    if(ticket = PositionGetTicket(i)) {
      if(PositionSelectByTicket(ticket)) {
        int position_type = PositionGetInteger(POSITION_TYPE);
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
