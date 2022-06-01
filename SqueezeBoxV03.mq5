//+------------------------------------------------------------------+
//|                                                SqueezeBoxVxx.mq5 |
//|                                                 Tislin (ttss000) |
//|                                      https://twitter.com/ttss000 |
//+------------------------------------------------------------------+
//reference: https://humidity50.com/archives/post-14734html

#property copyright "Tislin (ttss000)"
#property link      "https://twitter.com/ttss000"
#property version   "v3"
#property indicator_chart_window

#property indicator_buffers 4
#property indicator_plots   4

#property indicator_label1 "Upper_Line"     // データウィンドウでのプロット名
#property indicator_type1   DRAW_LINE   // プロットの種類は「線」
#property indicator_color1  clrBlue     // 線の色
#property indicator_style1 STYLE_SOLID // 線のスタイル
#property indicator_width1  2           // 線の幅

#property indicator_label2 "Lower_Line"     // データウィンドウでのプロット名
#property indicator_type2   DRAW_LINE   // プロットの種類は「yajirushi」
#property indicator_color2  clrRed     // 線の色
#property indicator_style2 STYLE_SOLID // 線のスタイル
#property indicator_width2  2           // 線の幅

#property indicator_label3 "UpperFuture_Line"     // データウィンドウでのプロット名
#property indicator_type3   DRAW_LINE   // プロットの種類は「線」
#property indicator_color3  clrTurquoise     // 線の色
#property indicator_style3 STYLE_SOLID // 線のスタイル
#property indicator_width3  1           // 線の幅

#property indicator_label4 "LowerFuture_Line"     // データウィンドウでのプロット名
#property indicator_type4   DRAW_LINE   // プロットの種類は「yajirushi」
#property indicator_color4  clrPlum     // 線の色
#property indicator_style4 STYLE_SOLID // 線のスタイル
#property indicator_width4  1           // 線の幅

input unsigned int bars_cals=20;
input double squeeze_ratio_to_price=0.0012;
//----- d'Alembert -----
input string memo_d_Alembert="";
input bool bUse_d_Alembert=true;
input double d_Alembert_1st_risk=2.0;
input double d_Alembert_risk_diff=0.2;

double Upper_Line[]; //
double Lower_Line[];

double UpperFuture_Line[]; //
double LowerFuture_Line[];

// file output variables
int h_FileOutput, filehandle;
string data_folder_str ;
string filename;
datetime rec_dt[10];
double rec_double[10];
datetime rec_dt_long[10];
datetime rec_dt_short[10];
double rec_double_long[10];
double rec_double_short[10];

ulong last_ticket=0;
ulong prev_ticket=0;

double riskpercent_d_Alembert = d_Alembert_1st_risk;
double riskpercent_d_Alembert_max = 0;

struct WinLoseHist {
  datetime           dt;
  ulong              ticket_num;
  int                WinPlus_Even0_LoseMinus;
};


//+------------------------------------------------------------------+
int ObjectType(string name)
{
  return ObjectGetInteger (0, name, OBJPROP_TYPE);
}
//+------------------------------------------------------------------+
datetime TimeMonth(datetime TargetTime)
{
  MqlDateTime tm;
  TimeToStruct(TargetTime,tm);
  return tm.mon;
}
//+------------------------------------------------------------------+
datetime TimeDay(datetime TargetTime)
{
  MqlDateTime tm;
  TimeToStruct(TargetTime,tm);
  return tm.day;
}
//+------------------------------------------------------------------+
datetime TimeMinute(datetime TargetTime)
{
  MqlDateTime tm;
  TimeToStruct(TargetTime,tm);
  return tm.min;
}
//+------------------------------------------------------------------+
datetime TimeHour(datetime TargetTime)
{
  MqlDateTime tm;
  TimeToStruct(TargetTime,tm);
  return tm.hour;
}
//+------------------------------------------------------------------+
datetime TimeDayOfWeek(datetime TargetTime)
{
  MqlDateTime tm;
  TimeToStruct(TargetTime,tm);
  return tm.day_of_week;
}
//+------------------------------------------------------------------+//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{

//double UpperFuture_Line[]; //
//double LowerFuture_Line[];
//--- indicator buffers mapping
  SetIndexBuffer(0,Upper_Line, INDICATOR_DATA);
  PlotIndexSetInteger(0,PLOT_LINE_STYLE, STYLE_SOLID);

  SetIndexBuffer(1,Lower_Line, INDICATOR_DATA);
  PlotIndexSetInteger(1,PLOT_LINE_STYLE, STYLE_SOLID);

  SetIndexBuffer(2,UpperFuture_Line, INDICATOR_DATA);
  PlotIndexSetInteger(2,PLOT_LINE_STYLE, STYLE_SOLID);

  SetIndexBuffer(3,LowerFuture_Line, INDICATOR_DATA);
  PlotIndexSetInteger(3,PLOT_LINE_STYLE, STYLE_SOLID);

//---

  ArraySetAsSeries(Upper_Line, true);
  ArraySetAsSeries(Lower_Line, true);

  ArraySetAsSeries(UpperFuture_Line, true);
  ArraySetAsSeries(LowerFuture_Line, true);

  //file output
  //data_folder_str = TerminalInfoString(TERMINAL_DATA_PATH);
  //Print ("DataFolder="+data_folder_str);
  //filename = "MiddleH1v2.csv";
  ResetLastError();
  //filehandle = FileOpen(filename,FILE_WRITE|FILE_CSV);

  //if(filehandle!=INVALID_HANDLE) {
  //  Print("File opened correctly");
  //} else Print("Error in opening file "+filename+","+GetLastError());

  return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
//---
  //MqlDateTime tm;

  int limit;

  double d_highest=-1;
  double d_lowest=-1;
  double d_hl_diff=-1;
  double d_tmp;

  int i_highest=-1;
  int i_lowest=-1;

  if(prev_calculated == 0){
    limit = rates_total - 1;
  }else{
    limit = rates_total - prev_calculated;
  }

  for(int i = limit ; 0 <= i ; i--){

    Upper_Line[i]=EMPTY_VALUE;
    Lower_Line[i]=EMPTY_VALUE;

    UpperFuture_Line[i]=EMPTY_VALUE;
    LowerFuture_Line[i]=EMPTY_VALUE;

    // Get hour
    if( i + bars_cals < limit ){
      i_highest = iHighest(NULL,PERIOD_CURRENT, MODE_HIGH, bars_cals, i);
      i_lowest = iLowest(NULL,PERIOD_CURRENT, MODE_LOW, bars_cals, i);
      d_highest = iHigh(NULL, PERIOD_CURRENT, i_highest);
      d_lowest = iLow(NULL, PERIOD_CURRENT, i_lowest);
      d_hl_diff = d_highest - d_lowest;
      if(d_hl_diff/iClose(NULL, PERIOD_CURRENT, i) < squeeze_ratio_to_price){
        //for(int j = i ; j < i + bars_cals ; j++){
        for(int j = i + bars_cals - 1 ; i <= j ; j--){
          if( Upper_Line[j] == EMPTY_VALUE ){
            Upper_Line[j] = d_highest;
            if(0<squeeze_ratio_to_price){
              UpperFuture_Line[j]=iClose(NULL, PERIOD_CURRENT, j+1)*squeeze_ratio_to_price+Lower_Line[j+1];
            }
          } 
          if( Lower_Line[j] == EMPTY_VALUE ){
            Lower_Line[j] = d_lowest;
            if(0<squeeze_ratio_to_price){
              LowerFuture_Line[j]=Upper_Line[j+1]-iClose(NULL, PERIOD_CURRENT, j+1)*squeeze_ratio_to_price;
            }
          } 
        }
      }
    }
  }

//--- return value of prev_calculated for next call
  return(rates_total);
}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
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
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//--- destroy timer
  long ret_code = 0;
  FileFlush(h_FileOutput);
  FileClose(h_FileOutput);
}
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
