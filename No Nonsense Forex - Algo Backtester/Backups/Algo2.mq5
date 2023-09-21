//+------------------------------------------------------------------+
//|                                                         Algo.mq5 |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   3
//--- plot Algo
#property indicator_label1  "Algo"
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  clrDeepPink
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrDodgerBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrDodgerBlue
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
//--- input parameters
input string   C1 = "2,0,2,TRIX with LR signal,2,1,14";
input string   Baseline = "3,0,ParabolicSAR,0.01010567,0.20000000";
input string   Exit;
input string   Volume;
input string   C2;
//--- indicator buffers
double         AlgoBuffer[];
double         AlgoColors[];
double         AlgoLineBuffer[];
double         ZeroLineBuffer[];

MqlRates  rates_array[];

string sSymbol = "GBPNZD+";

const int day = 86400;
datetime startdate=D'01.01.2017';

struct Indicators {
   MqlParam param[];
   datetime time[];
   int value[];
   int value2[];
   int length;
};

struct Buffers {
   double buffer[];
};

int iCurrent;
int atrHandle;
int handles[5];

int action, lastaction = 0;

datetime Pairstime[];
double Pairsclose[];
double Pairshigh[];
double Pairslow[];
double Pairsatr[];
int Pairsnews[];
int Pairslength;

double IndicatorBufferATR[];

struct output {
   datetime time[];
   double value[];
};
output results;
bool temp = false;

struct trade {
   double value;
   int trade, news;
   int win, loss, even, dd, maxdd, SD_n;
   bool isBuy, isdd;
   double pipswon, pipslost, pips, price, stoploss, lots, atr;
   double acc_size, dd_low, dd_high;
   double currprice, high, low, curratr;
   double exit_rate, news_rate;
   double SD, SD_neg, SD_ROI;
   double SD_sum, SD_sum_squared, SD_sum_neg_squared;
   
   datetime symTime, ind1Time, ind2Time, baselineTime, volumeTime, exitTime;
   int ind1Value, ind2Value, baselineValue, baselineValue2, volumeValue, exitValue;
   int symHandle, symLength, ind1Handle, ind1Length, ind2Handle, ind2Length, baselineHandle, baselineLength, volumeHandle, volumeLength, exitHandle, exitLength;
   int lastSignal;
   bool ind1Signal, baselineSignal;
   bool exitTrade, volumeTrade, ind2Trade;
};

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit(){
   IndicatorSetString(INDICATOR_SHORTNAME, "Algo");
   
   SetIndexBuffer(0, AlgoBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, AlgoColors, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2, AlgoLineBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(3, ZeroLineBuffer, INDICATOR_CALCULATIONS);

   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
   
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, 2);
   PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, 2);
   PlotIndexSetInteger(2, PLOT_DRAW_BEGIN, 2);

   IndicatorSetInteger(INDICATOR_DIGITS, 2);
   
   atrHandle = iCustom(sSymbol, PERIOD_CURRENT, "Downloads\\ATR");
   
   for(int i = 0; i < 5; i++){
      int id;
      int ID_Buffers[];
      string name;
      MqlParam parameters[];
      ENUM_INDICATOR indicator_type;
      int params_num;
      string s[];
      
      //Seperate the Indicator settings into the array
      StringSplit(GetCurrentIndicator(i), StringGetCharacter(",", 0), s);
      if(ArraySize(s) == 0){
         continue;
      }
      SeperateIndicatorSettings(s, id, ID_Buffers, name);
      
      //Get Indicator parameter count and default settings
      params_num = IndicatorParameters(iCustom(sSymbol, PERIOD_CURRENT, "Downloads\\" + name), indicator_type, parameters);
      parameters[0].string_value = StringSubstr(parameters[0].string_value, 11);
      
      //Add our optimized parameter settings
      StringToMqlParam(s, parameters);
      
      //Create indicator handle and get the trades
      handles[i] = IndicatorCreate(sSymbol, PERIOD_CURRENT, indicator_type, params_num, parameters);
   }
   
   EventSetTimer(1);
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[], const double &open[], const double &high[], 
                const double &low[], const double &close[], const long &tick_volume[], const long &volume[], const int &spread[]){
   
   if(temp == true){
      int p = 0;
      for(int i = 0; i < rates_total - 1; i++){
         ZeroLineBuffer[i] = 0;
         
         if(time[i] == results.time[p]){
            AlgoBuffer[i] = results.value[p];
            AlgoColors[i] = 0;
            AlgoLineBuffer[i] = results.value[p];
            p++;
         }
         else{
            AlgoBuffer[i] = 0;
         }
      }
   }
   
   return(rates_total);
}

void OnTimer(){
   if(temp == false){
      temp = true;
      ArraySetAsSeries(rates_array, true);
      if((int(TimeCurrent()) - int(startdate)) / (PeriodSeconds(Period())) < 10000){
         iCurrent = CopyRates(sSymbol, Period(), TimeCurrent(), startdate, rates_array);
      }
      else{
         iCurrent = CopyRates(sSymbol, Period(), 0, 10000, rates_array);
      }
   
      ExportPairs();
   
      Indicators ind[];
      bool ready = false;
   
      for(int i = 0; i < 5; i++){
         int id;
         int ID_Buffers[];
         string name;
         MqlParam parameters[];
         string s[];
      
         //Seperate the Indicator settings into the array and add space for the indicator trades
         StringSplit(GetCurrentIndicator(i), StringGetCharacter(",", 0), s);
         ArrayResize(ind, ArraySize(ind) + 1);
         ind[ArraySize(ind) - 1].length = 0;
         
         if(ArraySize(s) == 0){
            continue;
         }
         SeperateIndicatorSettings(s, id, ID_Buffers, name);
      
      
         //Create indicator handle and get the trades
         ready = GetIndicatorTrades(handles[i], id, ID_Buffers, ind);
         if(ready == false){
            temp = false;
            break;
         }
         IndicatorRelease(handles[i]);
      }
      if(ready == true){
         CompareIndicators(ind);
      }
   }
}



//returns the string with the Current Indicator settings
string GetCurrentIndicator(int i){
   string indi;
   if(i == 0){
      indi = C1;
   }
   else if(i == 1){
      indi = Baseline;
   }
   else if(i == 2){
      indi = Exit;
   }
   else if(i == 3){
      indi = Volume;
   }
   else if(i == 4){
      indi = C2;
   }
   return indi;
}

void SeperateIndicatorSettings(string &s[], int &id, int &ID_Buffers[], string &name){
   id = (int) StringToInteger(s[0]);
   ArrayResize(ID_Buffers, 1, 1);
   ID_Buffers[0] = (int) StringToInteger(s[1]);
   
   if(id == 1 || id == 3){
      name = s[2];
   }
   else if(id == 2){
      ArrayResize(ID_Buffers, 2);
      ID_Buffers[1] = (int) StringToInteger(s[2]);
      name = s[3];
   }
   ArrayRemove(s, 0, ArraySize(ID_Buffers) + 2);
   //ArrayResize(s, ArraySize(s) - ArraySize(ID_Buffers) - 2);
}

//Copy the MqlParam from the source to the destination parameter
void CopyMqlParam(MqlParam &dst_param[], MqlParam &src_param[]){
   int i = 0;
   ArrayResize(dst_param, ArraySize(src_param));
   while(i < ArraySize(src_param)){
      dst_param[i] = src_param[i];
      i++;
   }
}

//Converts an MqlParam Array to String
void StringToMqlParam(string &s[], MqlParam &param[]){
   int i = 1;
   while(i < ArraySize(param)){
      if(param[i].type == TYPE_STRING){
         param[i].string_value = s[i - 1];
      }
      else if(param[i].type == TYPE_FLOAT || param[i].type == TYPE_DOUBLE){
         param[i].double_value = StringToDouble(s[i - 1]);
      }
      else{
         param[i].integer_value = StringToInteger(s[i - 1]);
      }
      i++;
   }
}
            
bool GetIndicatorTrades(int h, int id, int &ID_Buffers[], Indicators &ind[]){
   Buffers buff[];
   int ind_size = ArraySize(ind);
   
   //Make space in the Buffer for the raw indicator data
   for(int i = 0; i < ArraySize(ID_Buffers); i++){
      ArrayResize(buff, ArraySize(buff) + 1);
      if(CopyBuffer(h, ID_Buffers[i], 0, iCurrent, buff[i].buffer) <= 0){
         return false;
      }
      ArraySetAsSeries(buff[i].buffer, true);
   }
   
   //Make space in for the trade results
   ArrayResize(ind[ind_size - 1].time, iCurrent);
   ArrayResize(ind[ind_size - 1].value, iCurrent);
   ArrayResize(ind[ind_size - 1].value2, iCurrent);
   action = lastaction = 0;
   
   //Determine what are the trades and output the results
   for(int i = iCurrent - 1; i > 0; i--){
      double close = iClose(sSymbol, PERIOD_CURRENT, i);
      if(id == 1){
         TrendZeroCross(buff[0].buffer[i]);
      }
      if(id == 2){
         TrendTwoLinesCross(buff[0].buffer[i], buff[1].buffer[i]);
      }
      if(id == 3){
         TrendChartIndicator(buff[0].buffer[i], close);
      }
            
      if(lastaction != action && (action == 1 || action == -1)){
         ind[ind_size - 1].time[ind[ind_size - 1].length] = rates_array[i].time;
         ind[ind_size - 1].value[ind[ind_size - 1].length] = action;
         
         if(action == -1 && close + IndicatorBufferATR[i] >= buff[0].buffer[i]){
            ind[ind_size - 1].value2[ind[ind_size - 1].length] = 1;
         }
         else if(action == 1 && close - IndicatorBufferATR[i] <= buff[0].buffer[i]){
            ind[ind_size - 1].value2[ind[ind_size - 1].length] = 1;
         }
         else{
            ind[ind_size - 1].value2[ind[ind_size - 1].length] = 0;
         }
         
         ind[ind_size - 1].length++;
         lastaction = action;
      }
   }
   ArrayResize(ind[ind_size - 1].time, ind[ind_size - 1].length);
   ArrayResize(ind[ind_size - 1].value, ind[ind_size - 1].length);
   ArrayResize(ind[ind_size - 1].value2, ind[ind_size - 1].length);
   return true;
}

void ExportPairs (){
   datetime cal[];
   Calendar(cal);
   
   CopyBuffer(atrHandle, 0, 0, iCurrent, IndicatorBufferATR);
   ArraySetAsSeries(IndicatorBufferATR, true);
   
   ArrayResize(Pairstime, iCurrent - 1);
   ArrayResize(Pairsclose, iCurrent - 1);
   ArrayResize(Pairshigh, iCurrent - 1);
   ArrayResize(Pairslow, iCurrent - 1);
   ArrayResize(Pairsatr, iCurrent - 1);
   ArrayResize(Pairsnews, iCurrent - 1);
   
   Pairslength = 0;
   
   for(int i = iCurrent - 1; i > 0; i--){
      Pairstime[Pairslength] = rates_array[i].time;
      Pairsclose[Pairslength] = iClose(sSymbol, PERIOD_CURRENT, i);
      Pairshigh[Pairslength] = iHigh(sSymbol, PERIOD_CURRENT, i);
      Pairslow[Pairslength] = iLow(sSymbol, PERIOD_CURRENT, i);
      Pairsatr[Pairslength] = IndicatorBufferATR[i];
      Pairsnews[Pairslength] = CalendarCheck(cal, rates_array[i].time);
      Pairslength++;
   }
   IndicatorRelease(atrHandle);
}

int CalendarCheck(datetime &cal[], datetime time){
   for(int i = 0; i < ArraySize(cal); i++){
      if(cal[i] - day <= time && cal[i] >= time){
         return 1;
      }
   }
   return 0;
}

void Calendar(datetime &cal[]){
   for(int count = 0; count < 6; count += 3){
      string currency_code = StringSubstr(sSymbol, count, 3);
      string keywords[];
      MqlCalendarValue values[];
      MqlCalendarEvent events[];
   
      CalendarValueHistory(values, startdate, TimeCurrent() + day, NULL, currency_code); 
      CalendarEventByCurrency(currency_code, events);
      Keywords(keywords, currency_code);
      for(int i = 0; i < ArraySize(values); i++){
         for(int j = 0; j < ArraySize(events); j++){
            if(values[i].event_id == events[j].id){
               int k = 0;
               while(k < ArraySize(keywords)){
                  if(StringFind(events[j].event_code, keywords[k]) != -1){
                     ArrayResize(cal, ArraySize(cal) + 1);
                     cal[ArraySize(cal) - 1] = values[i].time;
                  }
                  k++;
               }
               break;
            }
         }
      }
   }
}

void Keywords(string &array[], string currency){
   string usd[] = {"interest-rate", "consumer-price-index", "nonfarm-payroll", "powell"};
   string eur[] = {"interest-rate", "draghi"};
   string gbp[] = {"interest-rate", "mpc-vote", "gdp"};
   string chf[] = {"interest-rate"};
   string aud[] = {"interest-rate", "employment"};
   string cad[] = {"interest-rate", "employment", "cpi", "retail-sales"};
   string nzd[] = {"interest-rate", "employment", "gdp", "gdt"};
   string jpy[] = {"interest-rate"};
   
   if(currency == "USD"){
      ArrayCopy(array, usd);
   }
   else if(currency == "EUR"){
      ArrayCopy(array, eur);
   }
   else if(currency == "GBP"){
      ArrayCopy(array, gbp);
   }
   else if(currency == "CHF"){
      ArrayCopy(array, chf);
   }
   else if(currency == "AUD"){
      ArrayCopy(array, aud);
   }
   else if(currency == "CAD"){
      ArrayCopy(array, cad);
   }
   else if(currency == "NZD"){
      ArrayCopy(array, nzd);
   }
   else if(currency == "JPY"){
      ArrayCopy(array, jpy);
   }
}

void TrendZeroCross(double value){
   if((action == 1 && !(value > 0)) || (action == -1 && !(value < 0))){
      action = 0;
   }
   if(action == 0 && value > 0){
      action = 1;
   }
   else if(action == 0 && value < 0){
      action = -1;
   }
}

void TrendTwoLinesCross(double value, double value2){
   if(action == 0 && value > value2){
      action = 1;
   }
   else if(action == 0 && value < value2){
      action = -1;
   }
   else if(action == 1 && value < value2){
      action = -1;
   }
   else if(action == -1 && value > value2){
      action = 1;
   }
}

void TrendChartIndicator(double value, double close){
   if(action == 0 && value < close){
      action = 1;
   }
   else if(action == 0 && value > close){
      action = -1;
   }
   else if(action == -1 && value < close){
      action = 1;
   }
   else if(action == 1 && value > close){
      action = -1;
   }
}


void CompareIndicators(Indicators &ind[]){
   const int month = 2628000;
   const double months = (Pairstime[Pairslength - 1] - Pairstime[0]) * 1.0 / month;
   int accountsize = 1000;
   int risk = 2;
   double trainsize = 0.75f;
   int SD_Candles = 130;
   double SD_Percent = SD_Candles / (12 * (Pairslength / months));
   double acceptable_ROI = 5;
   trade t;
         
   ResetVariables(t, accountsize, true);
   
   ArrayResize(results.time, Pairslength);
   ArrayResize(results.value, Pairslength);
   
   t.symLength = Pairslength;
   t.ind1Handle = 0;
   t.ind1Length = ind[0].length;
   t.baselineHandle = 0;
   t.baselineLength = ind[1].length;
   if(ind[2].length != 0){
      t.exitTrade = true;
      t.exitHandle = 0;
      t.exitLength = ind[2].length;
   }
   if(ind[3].length != 0){
      t.volumeTrade = true;
      t.volumeHandle = 0;
      t.volumeLength = ind[3].length;
   }
   if(ind[4].length != 0){
      t.ind2Trade = true;
      t.ind2Handle = 0;
      t.ind2Length = ind[4].length;
   }
   while (t.symHandle < t.symLength){
      t.symTime = Pairstime[t.symHandle];
      t.currprice = Pairsclose[t.symHandle];
      t.high = Pairshigh[t.symHandle];
      t.low = Pairslow[t.symHandle];
      t.curratr = Pairsatr[t.symHandle];
      t.news = Pairsnews[t.symHandle];
      t.symHandle++;
      
      if(t.symTime >= t.ind1Time && t.ind1Handle < t.ind1Length){
         if(t.ind1Handle + 1 < t.ind1Length){
            t.ind1Time = ind[0].time[t.ind1Handle + 1];
         }
         t.ind1Value = ind[0].value[t.ind1Handle];
         t.ind1Handle++;
         t.ind1Signal = true;
         t.lastSignal = 0;
         
         if(t.exitTrade == false){
            t.exitValue = t.ind1Value;
         }
         if(t.volumeTrade == false){
            t.volumeValue = t.ind1Value;
         }
         if(t.ind2Trade == false){
            t.ind2Value = t.ind1Value;
         }
      }
      if(t.symTime >= t.baselineTime && t.baselineHandle < t.baselineLength){
         if(t.baselineHandle + 1 < t.baselineLength){
            t.baselineTime = ind[1].time[t.baselineHandle + 1];
         }
         t.baselineValue = ind[1].value[t.baselineHandle];
         t.baselineValue2 = ind[1].value2[t.baselineHandle];
         t.baselineHandle++;
         t.baselineSignal = true;
      }
      if(t.exitTrade == true && t.symTime >= t.exitTime && t.exitHandle < t.exitLength){
         if(t.exitHandle + 1 < t.exitLength){
            t.exitTime = ind[2].time[t.exitHandle + 1];
         }
         t.exitValue = ind[2].value[t.exitHandle];
         t.exitHandle++;
      }
      if(t.volumeTrade == true && t.symTime >= t.volumeTime && t.volumeHandle < t.volumeLength){
         if(t.volumeHandle + 1 < t.volumeLength){
            t.volumeTime = ind[3].time[t.volumeHandle + 1];
         }
         t.volumeValue = ind[3].value[t.volumeHandle];
         t.volumeHandle++;
      }
      if(t.ind2Trade == true && t.symTime >= t.ind2Time && t.ind2Handle < t.ind2Length){
         if(t.ind2Handle + 1 < t.ind2Length){
            t.ind2Time = ind[4].time[t.ind2Handle + 1];
         }
         t.ind2Value = ind[4].value[t.ind2Handle];
         t.ind2Handle++;
      }
      
      //Output Results
      results.time[t.symHandle - 1] = t.symTime;
      if(t.trade >= 3){
         GetTradeBalance(t);
         results.value[t.symHandle - 1] = t.pips / t.atr;
      }
      else{
         results.value[t.symHandle - 1] = 0;
      }
      
      
      if(t.trade == 3 && t.stoploss != t.price && (((t.high - t.price) >= t.atr && t.isBuy == true) || (-(t.low - t.price) >= t.atr && t.isBuy == false))){
         if(t.isBuy == true){
            t.stoploss = t.price;
         }
         else{
            t.stoploss = t.price;
         }
      }
      if(t.trade == 3 && (((t.high - t.price) >= (t.atr * 2) && t.isBuy == true) || (-(t.low - t.price) >= (t.atr * 2) && t.isBuy == false))){
         t.trade = 4;
         if(t.isBuy == true){
            t.stoploss = t.high - (t.atr * 1.5);
         }
         else{
            t.stoploss = t.low + (t.atr * 1.5);
         }
      }
      else if(t.trade == 4 && (((t.high - (t.atr * 1.5)) > t.stoploss && t.isBuy == true) || ((t.low + (t.atr * 1.5)) < t.stoploss && t.isBuy == false))){
         if(t.isBuy == true){
            t.stoploss = t.high - (t.atr * 1.5);
         }
         else{
            t.stoploss = t.low + (t.atr * 1.5);
         }
      }
      
      if((t.trade == 3 || t.trade == 4) && ((t.trade == 3 && t.news == 1 && t.stoploss != t.price) || ((((t.low <= t.stoploss) || t.ind1Value != 1 || t.baselineValue != 1 || t.exitValue != 1) && t.isBuy == true) || (((t.high >= t.stoploss) || t.ind1Value != -1 || t.baselineValue != -1 || t.exitValue != -1) && t.isBuy == false)))){
         EndTrade(t);
         if(t.exitTrade == false && ((t.exitValue != 1 && t.isBuy == true) || (t.exitValue != -1 && t.isBuy == false))){
            t.exit_rate += 1;
         }
         if(t.news == 1){
            t.news_rate += 1;
         }
         if((t.baselineValue == 1 && t.isBuy == true) || (t.baselineValue == -1 && t.isBuy == false)){
            t.trade = 2;
         }
         else{
            t.trade = 0;
         }
      }
           
      if(t.trade == 2){
         if((t.baselineValue == -1 && t.isBuy == true) || (t.baselineValue == 1 && t.isBuy == false)){
            t.trade = 0;
         }
         else if(t.ind1Signal == true && t.baselineValue == t.ind1Value && t.baselineValue == t.exitValue && t.baselineValue == t.ind2Value && t.news == 0){
            MakeTrade(t);
         }
      }
      if(t.trade == 0 || t.trade == 1){
         if((t.ind1Value == -1 && t.isBuy == true) || (t.ind1Value == 1 && t.isBuy == false)){
            t.trade = 0;
         }
         if(((t.ind1Value != 0 && (t.ind1Signal == true || t.trade == 1)) || (t.baselineValue != 0 && (t.baselineSignal == true || t.trade == 1))) && t.news == 0){
            if(t.ind1Value == t.baselineValue && t.ind1Value == t.exitValue && t.ind1Value == t.ind2Value && t.volumeValue != 0 && t.baselineValue2 == 0){
               if(t.trade == 1 || t.ind1Signal == true || (t.baselineSignal == true && t.lastSignal < 7)){
                  MakeTrade(t);
               }
            }
            else if(t.trade == 1){
               t.trade = 0;
            }
            else{
               t.trade = 1;
            }
         }
      }
      t.lastSignal++;
      t.baselineSignal = false;
      t.ind1Signal = false;
      
      if(t.symHandle % SD_Candles == 0){
         double balance = 0;
         if(t.trade == 3 || t.trade == 4){
            balance = GetTradeBalance(t);
	      }
	      t.SD_ROI = 100 * t.SD_ROI / accountsize;
         t.SD_sum += t.SD_ROI;
         t.SD_sum_squared += pow(t.SD_ROI, 2);
         t.SD_n++;
         t.SD = sqrt(t.SD_sum_squared / t.SD_n - pow(t.SD_sum / t.SD_n, 2)) * sqrt(1 / SD_Percent);
         if(t.SD_ROI <= acceptable_ROI * SD_Percent){
            t.SD_sum_neg_squared += pow(t.SD_ROI - acceptable_ROI * SD_Percent, 2);
            t.SD_neg = sqrt(t.SD_sum_neg_squared / t.SD_n) * sqrt(1 / SD_Percent);
         }
	      t.SD_ROI = -balance;
      }
      
      if(t.symHandle == (int)(t.symLength * trainsize)){
         /*output[i].win = t.win;
         output[i].loss = t.loss;
         output[i].even = t.even;
         output[i].acc_size = t.acc_size;
         output[i].return_rate = 100 * (pow(t.acc_size / accountsize, 1 / ((months / 12) * trainsize)) - 1);
         output[i].maxdd = t.maxdd;
         output[i].pipswon = t.pipswon;
         output[i].pipslost = t.pipslost;
         output[i].exit_rate = 100 * t.exit_rate / (t.win + t.loss + t.even);
         output[i].news_rate = 100 * t.news_rate / (t.win + t.loss + t.even);*/
         ResetVariables(t, accountsize, false); 
      }
   }
   /*output[i].std = t.SD;
   output[i].sharpe = ((t.SD_sum / t.SD_n) * (1 / SD_Percent) - 3) / t.SD;
   output[i].sortino = ((t.SD_sum / t.SD_n) * (1 / SD_Percent) - 3) / t.SD_neg;
   
   output[i].win1 = t.win;
   output[i].loss1 = t.loss;
   output[i].even1 = t.even;
   output[i].acc_size1 = t.acc_size;
   output[i].return_rate1 = 100 * (pow(t.acc_size / accountsize, 1 / ((months / 12) * (1 - trainsize))) - 1);
   output[i].maxdd1 = t.maxdd;
   output[i].pipswon1 = t.pipswon;
   output[i].pipslost1 = t.pipslost;
   output[i].exit_rate1 = 100 * t.exit_rate / (t.win + t.loss + t.even);
   output[i].news_rate1 = 100 * t.news_rate / (t.win + t.loss + t.even);*/
};

void ResetVariables(trade &t, int accountsize, bool fullReset){
   t.value = 0;
   t.trade = t.news = 0;

   t.win = t.loss = t.even = t.dd = t.maxdd = 0;
   t.isBuy = t.isdd = false;
   t.pipswon = t.pipslost = t.pips = t.price = t.stoploss = t.lots = t.atr = 0;
   t.acc_size = t.dd_low = t.dd_high = accountsize;
   t.exit_rate = t.news_rate = 0;
   
   if(fullReset == true){
      t.SD = t.SD_neg = t.SD_ROI = 0;
      t.SD_sum = t.SD_sum_squared = t.SD_sum_neg_squared = 0;
      t.SD_n = 0;
      
      t.currprice = t.high = t.low = t.curratr = 0;
      t.symTime = t.ind1Time = t.ind2Time = t.baselineTime = t.volumeTime = t.exitTime = 0;
      t.ind1Value = t.ind2Value = t.baselineValue = t.baselineValue2 = t.volumeValue = t.exitValue = 0;
      t.symHandle = t.symLength = t.ind1Handle = t.ind1Length = t.ind2Handle = t.ind2Length = t.baselineHandle = t.baselineLength = t.volumeHandle = t.volumeLength = t.exitHandle = t.exitLength = 0;
      t.lastSignal = 7;
      t.ind1Signal = t.baselineSignal = false;
      t.exitTrade = t.volumeTrade = t.ind2Trade = false;
   }
}

void MakeTrade(trade &t){
   const int risk = 2;
   t.trade = 3;
   t.price = t.currprice;
   t.atr = t.curratr;
   t.lots = (t.acc_size * risk / 100) / (t.atr * 10000 * 1.5);
   if(t.ind1Value == 1){
      t.isBuy = true;
      t.stoploss = t.currprice - (t.atr * 1.5);
   }
   else if(t.ind1Value == -1){
      t.isBuy = false;
      t.stoploss = t.currprice + (t.atr * 1.5);
   }
}

double GetTradeBalance(trade &t){
   if(t.isBuy == true){
      if(t.stoploss >= t.price){
         t.pips = ((t.currprice - t.price) + t.atr) * 0.5;
      }
      else{
         t.pips = (t.currprice - t.price);
      }
   }
   else{
      if(t.stoploss <= t.price){
         t.pips = (-(t.currprice - t.price) + t.atr) * 0.5;
      }
      else{
         t.pips = -(t.currprice - t.price);
      }
   }
   //t.SD_ROI += (t.pips * 10000) * t.lots;///////////////////////////////
   return (t.pips * 10000) * t.lots;
}

void EndTrade(trade &t){
   t.trade = 0;
   t.acc_size += GetTradeBalance(t);
   if(t.pips > 0){
      t.win++;
      t.pipswon += t.pips;
      if(t.isdd == false){
         t.dd_high = t.dd_low = t.acc_size;
      }
      else if(t.dd_high <= t.acc_size){
         t.isdd = false;
         t.dd = (int)(((t.dd_high - t.dd_low) / t.dd_high) * 100);
         if(t.dd > t.maxdd){
            t.maxdd = t.dd;
         }
      }
   }
   else if(t.pips < 0){
      t.loss++;
      t.pipslost -= t.pips;
      t.isdd = true;
      if(t.dd_low > t.acc_size){
         t.dd_low = t.acc_size;
         t.dd = (int)(((t.dd_high - t.dd_low) / t.dd_high) * 100);
         if(t.dd > t.maxdd){
            t.maxdd = t.dd;
         }
      }
   }
   else{
      t.even++;
   }
}