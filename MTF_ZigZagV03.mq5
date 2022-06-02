//+------------------------------------------------------------------+
//|                                                MTF_ZigZagVxx.mq5 |
//|                                                 Tislin (ttss000) |
//|                                      https://twitter.com/ttss000 |
//+------------------------------------------------------------------+
// thanks to
// https://pcoroom.com/post-5212/

#property copyright "Tislin (ttss000)"
#property link      "https://twitter.com/ttss000"
#property version   "V03"
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2

//--- plot ZigZag
#property indicator_label1  "UpArrow"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

//--- plot ZigZag
#property indicator_label2  "DnArrow"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrTurquoise
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

//--- plot ZigZag
//#property indicator_label1  "ZigZagS"
//#property indicator_type1   DRAW_SECTION
//#property indicator_color1  clrOrchid
//#property indicator_style1  STYLE_SOLID
//#property indicator_width1  1

//--- input parameters
input int InpDepth    =12;  // Depth
input int InpDeviation=5;   // Deviation
input int InpBackstep =3;   // Back Step
input int ZigZagL=96;
//input int ZigZagM=24;
input int ZigZagS=12;
//input int Symbol_UP=236; //上向きの記号の文字コード
//input  int Symbol_Down=238; //下向きの記号の文字コード
input int Symbol_UP=159; //上向きの記号の文字コード
input  int Symbol_Down=159; //下向きの記号の文字コード
input int S_max_count=40;
input int L_max_count=10;


//--- indicator buffers
double    ZigZagBufferL[];      // main buffer
double    HighMapBufferL[];     // ZigZag high extremes (peaks)
double    LowMapBufferL[];      // ZigZag low extremes (bottoms)

double    ZigZagBufferM[];      // main buffer
double    HighMapBufferM[];     // ZigZag high extremes (peaks)
double    LowMapBufferM[];      // ZigZag low extremes (bottoms)

double    ZigZagBufferS[];      // main buffer
double    HighMapBufferS[];     // ZigZag high extremes (peaks)
double    LowMapBufferS[];      // ZigZag low extremes (bottoms)

int       ExtRecalcL=3;         // number of last extremes for recalculation
int       ExtRecalcM=3;         // number of last extremes for recalculation
int       ExtRecalcS=3;         // number of last extremes for recalculation

enum EnSearchMode {
  Extremum=0, // searching for the first extremum
  Peak=1,     // searching for the next ZigZag peak
  Bottom=-1   // searching for the next ZigZag bottom
};

int h_Custom_S;
int h_Custom_M;
int h_Custom_L;

double UpArrow[];
double DnArrow[];

double TopS[];
double BottomS[];
int tPositionS[];
int bPositionS[];

double TopL[];
double BottomL[];
int tPositionL[];
int bPositionL[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
//--- indicator buffers mapping
  h_Custom_S = iCustom(NULL,PERIOD_CURRENT,"ZigZag",ZigZagS,5,3);
  //h_Custom_M = iCustom(NULL,PERIOD_CURRENT,"ZigZag",12*2,5,3);
  h_Custom_L = iCustom(NULL,PERIOD_CURRENT,"ZigZag",ZigZagL,5,3);
  ArraySetAsSeries(ZigZagBufferS, true);
  ArraySetAsSeries(ZigZagBufferM, true);
  ArraySetAsSeries(ZigZagBufferL, true);
  ArraySetAsSeries(UpArrow, true);
  ArraySetAsSeries(DnArrow, true);
  
  ArrayResize(TopS, S_max_count);
  ArrayResize(BottomS, S_max_count);
  ArrayResize(tPositionS, S_max_count);
  ArrayResize(bPositionS, S_max_count);

  ArrayResize(TopL, S_max_count);
  ArrayResize(BottomL, S_max_count);
  ArrayResize(tPositionL, S_max_count);
  ArrayResize(bPositionL, S_max_count);

//SetIndexStyle(0,DRAW_ARROW);
//SetIndexBuffer(0,UpArrow);
  SetIndexBuffer(0,UpArrow, INDICATOR_DATA);
  PlotIndexSetInteger(0,PLOT_ARROW,Symbol_UP);

////SetIndexStyle(1,DRAW_ARROW);
//SetIndexArrow(1,Symbol_Down);
//SetIndexBuffer(1,DnArrow);
  SetIndexBuffer(1,DnArrow, INDICATOR_DATA);
  PlotIndexSetInteger(1,PLOT_ARROW,Symbol_Down);


//---
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

//---Zigzag L--------------------------------------------------------------//
  int m,n;
  int m1,n1;

  int limit;


  m=0;
  n=0;
  m1=0;
  n1=0;

//  limit = 200;
//  if(rates_total < limit) {
//    limit = rates_total - 1;
//  }
//  CopyBuffer(h_Custom_S, 0, 0, limit+1, ZigZagBufferS);
//
//  for(int i=0; i<=limit; i++) {
//    double Zg=ZigZagBufferS[i];
//    //if(i==0) Print("i Zg ="+i+"  "+Zg);
//    if(Zg!=0 && MathAbs(Zg - iHigh(NULL, PERIOD_CURRENT, i)) < Point()/2 ) {
//      Top[m++]=Zg;
//      tPosition[m-1]=i;
//      if(m>=10)break;
//    }
//    if(Zg!=0 && MathAbs(Zg - iLow(NULL, PERIOD_CURRENT, i)) < Point()/2 ) {
//      Bottom[n++]=Zg;
//      bPosition[n-1]=i;
//      if(n>=10)break;
//    }
//  }

  limit = 200*2*4;
  if(rates_total < limit) {
    limit = rates_total - 1;
  }

  CopyBuffer(h_Custom_S, 0, 0, limit+1, ZigZagBufferS);
  CopyBuffer(h_Custom_M, 0, 0, limit+1, ZigZagBufferM);
  CopyBuffer(h_Custom_L, 0, 0, limit+1, ZigZagBufferL);

  for(int i=0; i<=limit; i++) {
    double ZgL=ZigZagBufferL[i];
    double ZgS=ZigZagBufferS[i];
    if(m1 < L_max_count && ZgL!=0 && MathAbs(ZgL - iHigh(NULL, PERIOD_CURRENT, i)) < Point()/2) {
      //Print("m,n,m1,n1="+m+" "+n+" "+m1+" "+n1);
            TopL[m1++]=ZgL;

      tPositionL[m1-1]=i;
      if(m1>=L_max_count && n1>=L_max_count)break;
    }
    if(n1 < L_max_count && ZgL!=0 && MathAbs(ZgL - iLow(NULL, PERIOD_CURRENT, i)) < Point()/2 ) {
      BottomL[n1++]=ZgL;
      bPositionL[n1-1]=i;
      if(m1>=L_max_count && L_max_count>=10)break;
    }
    //if(i==0) Print("i Zg ="+i+"  "+Zg);
    if(m < S_max_count && ZgS!=0 && MathAbs(ZgS - iHigh(NULL, PERIOD_CURRENT, i)) < Point()/2 ) {
      TopS[m++]=ZgS;
      tPositionS[m-1]=i;
      //if(m>=10)break;
    }
    if(n < S_max_count && ZgS!=0 && MathAbs(ZgS - iLow(NULL, PERIOD_CURRENT, i)) < Point()/2 ) {
      BottomS[n++]=ZgS;
      bPositionS[n-1]=i;
      //if(n>=10)break;
    }
  }

  m=0;
  n=0;
  m1=0;
  n1=0;

  int ishift_latest = 0;
  int ishift_latest2 = 0;
  int ishift_latestL = 0;
  int ishift_latestS = 0;
  int S_direction = 0;
  int L_direction = 0;

  while(m<S_max_count && n<S_max_count && m1<L_max_count && n1<L_max_count) {

    // find minimum shift of zigzag
    if(tPositionL[m1] < bPositionL[n1]) {
      ishift_latestL = tPositionL[m1];
      L_direction = -1; // down trend
      //m1++;
    } else if(bPositionL[n1] < tPositionL[m1]) {
      ishift_latestL = bPositionL[n1];
      L_direction = 1; // up trend
      //n1++;
    }

    if(tPositionS[m] < bPositionS[n]) {
      ishift_latestS = tPositionS[n];
      S_direction = -1; // down trend
    } else if(bPositionS[n] < tPositionS[m]) {
      ishift_latestS = bPositionS[n];
      S_direction = 1; // up trend
    }

    if(ishift_latestL < ishift_latestS) {
      ishift_latest2 = ishift_latestL;
      if(0<L_direction) n1++; else m1++;
    } else {
      ishift_latest2 = ishift_latestS;
      if(0<S_direction) n++; else m++;
    }

    for(int i = ishift_latest ; i <= ishift_latest2 ; i++) {
      UpArrow[i] = EMPTY_VALUE;
      DnArrow[i] = EMPTY_VALUE;

      if(0 < L_direction &&  0 < S_direction) {
        UpArrow[i] = iHigh(NULL, PERIOD_CURRENT, i)+20*Point();
      } else if(L_direction < 0  &&  S_direction < 0) {
        DnArrow[i] = iLow(NULL, PERIOD_CURRENT, i)-20*Point();
      }
    }
    //Print("ishift_latest, ishift_latest2 ="+ishift_latest+"    "+ishift_latest2);
    //Print("i ="+i);
    ishift_latest = ishift_latest2;
    //Print("m,n,m1,n1="+m+" "+n+" "+m1+" "+n1);
  }



//  Comment(
//
//
//    "Top_0= ",TopS[0],",Position=",tPositionS[0],"\n",
//    "Top_1=",TopS[1],",Position=",tPositionS[1],"\n",
//    "Top_2=",TopS[2],",Position=",tPositionS[2],"\n",
//    "Bottom_0=",BottomS[0],",Position=",bPositionS[0],"\n",
//    "Bottom_1=",BottomS[1],",Position=",bPositionS[1],"\n",
//    "Bottom_2=",BottomS[2],",Position=",bPositionS[2],"\n"
//    ,"\n\n",
//    "Top_0= ",TopL[0],",Position=",tPositionL[0],"\n",
//    "Top_1=",TopL[1],",Position=",tPositionL[1],"\n",
//    "Top_2=",TopL[2],",Position=",tPositionL[2],"\n",
//    "Bottom_0=",BottomL[0],",Position=",bPositionL[0],"\n",
//    "Bottom_1=",BottomL[1],",Position=",bPositionL[1],"\n",
//    "Bottom_2=",BottomL[2],",Position=",bPositionL[2],"\n"
//
//  );




//---Zigzag--------------------------------------------------------------//

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
  Comment("");
}
//+------------------------------------------------------------------+
