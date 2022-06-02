//+------------------------------------------------------------------+
//|                                                MTF_ZigZagVxx.mq5 |
//|                                                 Tislin (ttss000) |
//|                                      https://twitter.com/ttss000 |
//+------------------------------------------------------------------+
// thanks to
// https://pcoroom.com/post-5212/

#property copyright "Tislin (ttss000)"
#property link      "https://twitter.com/ttss000"
#property version   "V06"
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   4

//--- plot ZigZag
#property indicator_label1  "UpArrow"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

//--- plot ZigZag
#property indicator_label2  "DnArrow"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrTurquoise
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

//--- plot ZigZag
#property indicator_label3  "UpArrow2"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrMagenta
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1

//--- plot ZigZag
#property indicator_label4  "DnArrow2"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrLime
#property indicator_style4  STYLE_SOLID
#property indicator_width4  1


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
//double    HighMapBufferL[];     // ZigZag high extremes (peaks)
//double    LowMapBufferL[];      // ZigZag low extremes (bottoms)

double    ZigZagBufferM[];      // main buffer
//double    HighMapBufferM[];     // ZigZag high extremes (peaks)
//double    LowMapBufferM[];      // ZigZag low extremes (bottoms)

double    ZigZagBufferS[];      // main buffer
//double    HighMapBufferS[];     // ZigZag high extremes (peaks)
//double    LowMapBufferS[];      // ZigZag low extremes (bottoms)

//int       ExtRecalcL=3;         // number of last extremes for recalculation
//int       ExtRecalcM=3;         // number of last extremes for recalculation
//int       ExtRecalcS=3;         // number of last extremes for recalculation
//
//enum EnSearchMode {
//  Extremum=0, // searching for the first extremum
//  Peak=1,     // searching for the next ZigZag peak
//  Bottom=-1   // searching for the next ZigZag bottom
//};

int h_Custom_S;
int h_Custom_M;
int h_Custom_L;

double UpArrow[];
double DnArrow[];

double UpArrow2[];
double DnArrow2[];

double TopS[];
double BottomS[];
int tPositionS[];
int bPositionS[];

double TopL[];
double BottomL[];
int tPositionL[];
int bPositionL[];

double top_S_new = 0, top_S_prev = 0;
double bottom_S_new = 0, bottom_S_prev = 0;

double top_L_new = 0, top_L_prev = 0;
double bottom_L_new = 0, bottom_L_prev = 0;

int ishift_S_latest = 0;
int ishift_S_latest2 = 0;

int ishift_S_Top_latest = 0;
int ishift_S_Top_prev = 0;
int ishift_S_Bot_latest = 0;
int ishift_S_Bot_prev = 0;


int ishift_L_latest = 0;
int ishift_L_latest2 = 0;

int ishift_L_Top_latest = 0;
int ishift_L_Top_prev = 0;
int ishift_L_Bot_latest = 0;
int ishift_L_Bot_prev = 0;

int S_direction = 0;
int L_direction = 0;
int S_Dow_direction = 0;
int L_Dow_direction = 0;


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
  ArraySetAsSeries(UpArrow2, true);
  ArraySetAsSeries(DnArrow2, true);

//SetIndexStyle(0,DRAW_ARROW);
//SetIndexBuffer(0,UpArrow);
  SetIndexBuffer(0,UpArrow, INDICATOR_DATA);
  PlotIndexSetInteger(0,PLOT_ARROW,Symbol_UP);

////SetIndexStyle(1,DRAW_ARROW);
//SetIndexArrow(1,Symbol_Down);
//SetIndexBuffer(1,DnArrow);
  SetIndexBuffer(1,DnArrow, INDICATOR_DATA);
  PlotIndexSetInteger(1,PLOT_ARROW,Symbol_Down);

  SetIndexBuffer(2,UpArrow2, INDICATOR_DATA);
  PlotIndexSetInteger(2,PLOT_ARROW,Symbol_UP);

  SetIndexBuffer(3,DnArrow2, INDICATOR_DATA);
  PlotIndexSetInteger(3,PLOT_ARROW,Symbol_Down);

//SetIndexBuffer(1,DnArrow, INDICATOR_CALCULATIONS);
//SetIndexBuffer(2,DnArrow, INDICATOR_CALCULATIONS);
//SetIndexBuffer(3,DnArrow, INDICATOR_CALCULATIONS);
//SetIndexBuffer(4,DnArrow, INDICATOR_CALCULATIONS);
//SetIndexBuffer(5,DnArrow, INDICATOR_CALCULATIONS);
//SetIndexBuffer(6,DnArrow, INDICATOR_CALCULATIONS);
//SetIndexBuffer(7,DnArrow, INDICATOR_CALCULATIONS);
//SetIndexBuffer(8,DnArrow, INDICATOR_CALCULATIONS);
//SetIndexBuffer(9,DnArrow, INDICATOR_CALCULATIONS);
//SetIndexBuffer(10,DnArrow, INDICATOR_CALCULATIONS);

  ArrayInitialize(UpArrow, EMPTY_VALUE);
  ArrayInitialize(DnArrow, EMPTY_VALUE);
  ArrayInitialize(UpArrow2, EMPTY_VALUE);
  ArrayInitialize(DnArrow2, EMPTY_VALUE);

//  ArrayResize(TopS, S_max_count);
//  ArrayResize(BottomS, S_max_count);
//  ArrayResize(tPositionS, S_max_count);
//  ArrayResize(bPositionS, S_max_count);
//
//  ArrayResize(TopL, L_max_count);
//  ArrayResize(BottomL, L_max_count);
//  ArrayResize(tPositionL, L_max_count);
//  ArrayResize(bPositionL, L_max_count);
//
//  ArrayInitialize(TopS, 0);
//  ArrayInitialize(BottomS, 0);
//  ArrayInitialize(tPositionS, 0);
//  ArrayInitialize(bPositionS, 0);
//
//  ArrayInitialize(TopL, 0);
//  ArrayInitialize(BottomL, 0);
//  ArrayInitialize(tPositionL, 0);
//  ArrayInitialize(bPositionL, 0);

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
  //int m,n;
  //int m1,n1;

  int limit;

  //m=0;
  //n=0;
  //m1=0;
  //n1=0;
  bool bFoundS = false;
  bool bFoundL = false;


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

//limit = 200*2*4;
  if (prev_calculated == 0) {
    limit = rates_total - 1;
  } else {
    limit = rates_total - prev_calculated;

  }

//limit = rates_total - prev_calculated - 1;
//if(rates_total - 1 < limit) {
//  limit = rates_total - 1;
//}
//if(limit < 0) {
//  limit = 0;
//}

  CopyBuffer(h_Custom_S, 0, 0, limit, ZigZagBufferS);
  CopyBuffer(h_Custom_M, 0, 0, limit, ZigZagBufferM);
  CopyBuffer(h_Custom_L, 0, 0, limit, ZigZagBufferL);

  for(int i=limit-1 ; 0<=i ; i--) {
    // calc from old bar
    double ZgL=ZigZagBufferL[i];
    double ZgS=ZigZagBufferS[i];
    //if(i==0) Print("i Zg ="+i+"  "+Zg);

    // ======================= short term ============================
    // calc short term zigzag first
    bFoundS = false;
    if(ZgS!=0 && MathAbs(ZgS - iHigh(NULL, PERIOD_CURRENT, i)) < Point()/2 ) {
      // found top
      if(top_S_new == 0) {
        top_S_new = ZgS;
        ishift_S_Top_latest = i;
      } else {
        ishift_S_Top_prev = ishift_S_Top_latest;
        ishift_S_Top_latest = i;

        top_S_prev = top_S_new;
        top_S_new = ZgS;
        bFoundS = true;
        //if(i < 300)        Print ("top ishift_Top_prev ishift_Top_latest="+ishift_S_Top_prev+ "    "+ishift_S_Top_latest);
      }
      //TopS[m++]=ZgS;
      //tPositionS[m-1]=i;
      //if(m>=10)break;
    }

    if(ZgS!=0 && MathAbs(ZgS - iLow(NULL, PERIOD_CURRENT, i)) < Point()/2 ) {
      // found bottom
      //BottomS[n++]=ZgS;
      //bPositionS[n-1]=i;
      //if(n>=10)break;
      if(bottom_S_new == 0) {
        bottom_S_new = ZgS;
        ishift_S_Bot_latest = i;
      } else {
        ishift_S_Bot_prev = ishift_S_Bot_latest;
        ishift_S_Bot_latest = i;
        bottom_S_prev = bottom_S_new;
        bottom_S_new = ZgS;
        bFoundS = true;
        //if(i < 300) Print ("bottom ishift_S_Bot_prev ishift_S_Bot_latest="+ishift_S_Bot_prev+ "    "+ishift_S_Bot_latest);
      }
    }

    if(bFoundS) {
      if(top_S_prev < top_S_new && bottom_S_prev < bottom_S_new) {
        // m is older and m+1 is newer
        // older is lower so, up trend
        if(ishift_S_Bot_prev <= ishift_S_Top_prev) {
          // need larger
          ishift_S_latest = ishift_S_Top_prev;
        } else {
          ishift_S_latest = ishift_S_Bot_prev;
        }
        if(ishift_S_Top_latest <= ishift_S_Bot_latest) {
          // need small
          ishift_S_latest2 = ishift_S_Top_latest;
        } else {
          ishift_S_latest2 = ishift_S_Bot_latest;
        }
        //if(i < 300)  Print ("i,ishift_S_latest,ishift_S_latest2  ="+i+"  "+ishift_S_latest+"  "+ishift_S_latest2);
        DrawUpArrow(ishift_S_latest, ishift_S_latest2);
      }

      if(top_S_prev > top_S_new && bottom_S_prev > bottom_S_new) {
        // m is older and m+1 is newer
        // older is lower so, up trend
        if(ishift_S_Bot_prev <= ishift_S_Top_prev) {
          // need largerr
          ishift_S_latest = ishift_S_Top_prev;
        } else {
          ishift_S_latest = ishift_S_Bot_prev;
        }
        if(ishift_S_Top_latest <= ishift_S_Bot_latest) {
          // need smaller
          ishift_S_latest2 = ishift_S_Top_latest;
        } else {
          ishift_S_latest2 = ishift_S_Bot_latest;
        }
        DrawDownArrow(ishift_S_latest, ishift_S_latest2);
      }

    }

    // ======================= long term ============================
    // calc long term zigzag next
    bFoundL = false;
    if(ZgL!=0 && MathAbs(ZgL - iHigh(NULL, PERIOD_CURRENT, i)) < Point()/2 ) {
      // found top
      if(top_L_new == 0) {
        top_L_new = ZgL;
        ishift_L_Top_latest = i;
      } else {
        ishift_L_Top_prev = ishift_L_Top_latest;
        ishift_L_Top_latest = i;

        top_L_prev = top_L_new;
        top_L_new = ZgL;
        bFoundL = true;
        //if(i < 300)        Print ("top ishift_L Top_prev ishift_L Top_latest="+ishift_L_Top_prev+ "    "+ishift_L_Top_latest);
      }
      //TopS[m++]=ZgS;
      //tPositionS[m-1]=i;
      //if(m>=10)break;
    }

    if(ZgL!=0 && MathAbs(ZgL - iLow(NULL, PERIOD_CURRENT, i)) < Point()/2 ) {
      // found bottom
      //BottomS[n++]=ZgS;
      //bPositionS[n-1]=i;
      //if(n>=10)break;
      if(bottom_L_new == 0) {
        bottom_L_new = ZgL;
        ishift_L_Bot_latest = i;
      } else {
        ishift_L_Bot_prev = ishift_L_Bot_latest;
        ishift_L_Bot_latest = i;
        bottom_L_prev = bottom_L_new;
        bottom_L_new = ZgL;
        bFoundL = true;
        //if(i < 300) Print ("bottom ishift_L_Bot_prev ishift_L_Bot_latest="+ishift_L_Bot_prev+ "    "+ishift_L_Bot_latest);
      }
    }

    if(bFoundL) {
      if(top_L_prev < top_L_new && bottom_L_prev < bottom_L_new) {
        // m is older and m+1 is newer
        // older is lower so, up trend
        if(ishift_L_Bot_prev <= ishift_L_Top_prev) {
          // need larger
          ishift_L_latest = ishift_L_Top_prev;
        } else {
          ishift_L_latest = ishift_L_Bot_prev;
        }
        if(ishift_L_Top_latest <= ishift_L_Bot_latest) {
          // need small
          ishift_L_latest2 = ishift_L_Top_latest;
        } else {
          ishift_L_latest2 = ishift_L_Bot_latest;
        }
        //if(i < 300)  Print ("i,ishift_L_latest,ishiftL_latest2  ="+i+"  "+ishift_L_latest+"  "+ishift_L_latest2);
        DrawUpArrow2(ishift_L_latest, ishift_L_latest2);
      }

      if(top_L_prev > top_L_new && bottom_L_prev > bottom_L_new) {
        // m is older and m+1 is newer
        // older is lower so, up trend
        if(ishift_L_Bot_prev <= ishift_L_Top_prev) {
          // need largerr
          ishift_L_latest = ishift_L_Top_prev;
        } else {
          ishift_L_latest = ishift_L_Bot_prev;
        }
        if(ishift_L_Top_latest <= ishift_L_Bot_latest) {
          // need smaller
          ishift_L_latest2 = ishift_L_Top_latest;
        } else {
          ishift_L_latest2 = ishift_L_Bot_latest;
        }
        DrawDownArrow2(ishift_L_latest, ishift_L_latest2);
      }

    }




//    if(m1 < L_max_count && ZgL!=0 && MathAbs(ZgL - iHigh(NULL, PERIOD_CURRENT, i)) < Point()/2) {
//      //Print("m,n,m1,n1="+m+" "+n+" "+m1+" "+n1);
//
//      TopL[m1++]=ZgL;
//
//      tPositionL[m1-1]=i;
//      if(m1>=L_max_count && n1>=L_max_count)break; // escape from the loop
//    }
//    if(n1 < L_max_count && ZgL!=0 && MathAbs(ZgL - iLow(NULL, PERIOD_CURRENT, i)) < Point()/2 ) {
//      BottomL[n1++]=ZgL;
//      bPositionL[n1-1]=i;
//      if(m1>=L_max_count && n1>=L_max_count)break; // escape from the loop
//    }
  }

//  m=0;
//  n=0;
//  m1=0;
//  n1=0;
//
//
//  while(m+1<S_max_count && n+1<S_max_count) {
//    if(TopS[m] < TopS[m+1] && BottomS[n] < BottomS[n+1]) {
//      // m is older and m+1 is newer
//      // older is lower so, up trend
//      if(tPositionS[m] <= bPositionS[n]) {
//        // need smaller
//        ishift_latest = tPositionS[m];
//      } else {
//        ishift_latest = bPositionS[n];
//      }
//      if(tPositionS[m+1] <= bPositionS[n+1]) {
//        // need larger
//        ishift_latest2 = bPositionS[n+1];
//      } else {
//        ishift_latest2 = tPositionS[m+1];
//      }
//      DrawUpArrow(ishift_latest, ishift_latest2);
//    }
//    if(TopS[m] > TopS[m+1] && BottomS[n] > BottomS[n+1]) {
//      // m is older and m+1 is newer
//      // older is lower so, down trend
//      if(tPositionS[m] <= bPositionS[n]) {
//        // need smaller
//        ishift_latest = tPositionS[m];
//      } else {
//        ishift_latest = bPositionS[n];
//      }
//      if(tPositionS[m+1] <= bPositionS[n+1]) {
//        // need larger
//        ishift_latest2 = bPositionS[n+1];
//      } else {
//        ishift_latest2 = tPositionS[m+1];
//      }
//      DrawDownArrow(ishift_latest, ishift_latest2);
//    }
//    m++;
//    n++;
//    //Print("m,n,m1,n1="+m+" "+n+" "+m1+" "+n1);
//
//  }
//  while(m<S_max_count && n<S_max_count && m1<L_max_count && n1<L_max_count) {
//
//    // find minimum shift of zigzag
//    if(tPositionL[m1] < bPositionL[n1]) {
//      ishift_latestL = tPositionL[m1];
//      L_direction = -1; // down trend
//      //m1++;
//    } else if(bPositionL[n1] < tPositionL[m1]) {
//      ishift_latestL = bPositionL[n1];
//      L_direction = 1; // up trend
//      //n1++;
//    }
//    if(m1+1 < L_max_count && n1+1 < L_max_count){
//      if( TopL[m1+1] < TopL[m1] && BottomL[n1+1] < BottomL[n1] ){
//        L_Dow_direction = 1;
//      }else if( TopL[m1+1] > TopL[m1] && BottomL[n1+1] > BottomL[n1] ){
//        L_Dow_direction = -1;
//      }
//    }
//
//    if(tPositionS[m] < bPositionS[n]) {
//      ishift_latestS = tPositionS[n];
//      S_direction = -1; // down trend
//    } else if(bPositionS[n] < tPositionS[m]) {
//      ishift_latestS = bPositionS[n];
//      S_direction = 1; // up trend
//    }
//    if(m+1 < L_max_count && n+1 < L_max_count){
//      if( TopS[m+1] < TopS[m] && BottomS[n+1] < BottomS[n] ){
//        S_Dow_direction = 1;
//      }else if( TopS[m+1] > TopS[m] && BottomS[n+1] > BottomS[n] ){
//        S_Dow_direction = -1;
//      }
//    }
//
//    if(ishift_latestL < ishift_latestS) {
//      ishift_latest2 = ishift_latestL;
//      if(0<L_direction) n1++; else m1++;
//    } else {
//      ishift_latest2 = ishift_latestS;
//      if(0<S_direction) n++; else m++;
//    }
//
//    for(int i = ishift_latest ; i <= ishift_latest2 ; i++) {
//      UpArrow[i] = EMPTY_VALUE;
//      DnArrow[i] = EMPTY_VALUE;
//
//      if(0 < L_Dow_direction &&  0 < S_Dow_direction) {
//        UpArrow[i] = iHigh(NULL, PERIOD_CURRENT, i)+20*Point();
//      } else if(L_Dow_direction < 0  &&  S_Dow_direction < 0) {
//        DnArrow[i] = iLow(NULL, PERIOD_CURRENT, i)-20*Point();
//      }
//    }
//    //Print("ishift_latest, ishift_latest2 ="+ishift_latest+"    "+ishift_latest2);
//    //Print("i ="+i);
//    ishift_latest = ishift_latest2;
//    //Print("m,n,m1,n1="+m+" "+n+" "+m1+" "+n1);
//  }



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
void DrawDownArrow(int ishift_latest, int ishift_latest2)
{
  int start, end;

  if(ishift_latest < ishift_latest2) {
    start= ishift_latest;
    end = ishift_latest2;
  } else {
    start= ishift_latest2;
    end = ishift_latest;
  }

  if(start < end) {
    for(int i2 = start ; i2 <= end ; i2++) {
      DnArrow[i2] = iLow(NULL, PERIOD_CURRENT, i2)-100*Point();
      //if(DnArrow[i2] == EMPTY_VALUE){
      //  DnArrow[i2] = iLow(NULL, PERIOD_CURRENT, i2)-100*Point();
      //}else{
      //  DnArrow[i2] = EMPTY_VALUE;
      //}
    }
  }
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void DrawUpArrow(int ishift_latest, int ishift_latest2)
{
  int start, end;

  if(ishift_latest < ishift_latest2) {
    start= ishift_latest;
    end = ishift_latest2;
  } else {
    start= ishift_latest2;
    end = ishift_latest;
  }

  if(start < end) {
    for(int i2 = start ; i2 <= end ; i2++) {
      UpArrow[i2] = iHigh(NULL, PERIOD_CURRENT, i2)+100*Point();
      //if(UpArrow[i2] == EMPTY_VALUE){
      //  UpArrow[i2] = iHigh(NULL, PERIOD_CURRENT, i2)+100*Point();
      //}else{
      //  UpArrow[i2] =EMPTY_VALUE;
      //}
    }
  }
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void DrawDownArrow2(int ishift_latest, int ishift_latest2)
{
  int start, end;

  if(ishift_latest < ishift_latest2) {
    start= ishift_latest;
    end = ishift_latest2;
  } else {
    start= ishift_latest2;
    end = ishift_latest;
  }

  if(start < end) {
    for(int i2 = start ; i2 <= end ; i2++) {
      DnArrow2[i2] = iLow(NULL, PERIOD_CURRENT, i2)-200*Point();
      //if(DnArrow[i2] == EMPTY_VALUE){
      //  DnArrow[i2] = iLow(NULL, PERIOD_CURRENT, i2)-100*Point();
      //}else{
      //  DnArrow[i2] = EMPTY_VALUE;
      //}
    }
  }
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void DrawUpArrow2(int ishift_latest, int ishift_latest2)
{
  int start, end;

  if(ishift_latest < ishift_latest2) {
    start= ishift_latest;
    end = ishift_latest2;
  } else {
    start= ishift_latest2;
    end = ishift_latest;
  }

  if(start < end) {
    for(int i2 = start ; i2 <= end ; i2++) {
      UpArrow2[i2] = iHigh(NULL, PERIOD_CURRENT, i2)+200*Point();
      //if(UpArrow[i2] == EMPTY_VALUE){
      //  UpArrow[i2] = iHigh(NULL, PERIOD_CURRENT, i2)+100*Point();
      //}else{
      //  UpArrow[i2] =EMPTY_VALUE;
      //}
    }
  }
}
//+------------------------------------------------------------------+
