//+------------------------------------------------------------------+
//|                                          Export Indicator Values |
//+------------------------------------------------------------------+
#property description "This Script Export Indicators Values to CSV File."
#property description "(You can change the iCustom function parameters to change what indicator to export)"
#property copyright "NFTrader"
#property version   "2.00"
#property script_show_inputs

MqlRates  rates_array[];
/*string sSymbols[] = {"EURGBP", "EURNZD", "EURUSD", "EURAUD", "EURCAD", "EURJPY", "GBPNZD", "GBPUSD", 
"GBPAUD", "GBPCAD", "GBPCHF", "GBPJPY", "NZDUSD", "AUDNZD", "NZDCAD", "NZDCHF", "NZDJPY", "AUDUSD", "USDCAD", 
"USDCHF", "USDJPY", "AUDCAD", "AUDCHF", "AUDJPY", "CADCHF", "CADJPY", "CHFJPY"};*/
string sSymbols[] = {"GBPNZD"};

string sSymbol;
const int day = 86400;
datetime startdate=D'01.01.2015';
string Indicator_Directory_And_Name;

// Convert Period to string to use it in the file name
string sPeriod = StringSubstr(EnumToString(Period()), 7);

string ExtFileName; // ="RSI(XX, XX, ...).CSV";
string Ext1FileName;
string Ext2FileName;

int iCurrent, bars, to_copy;

int action, lastaction = 0;
double close = 0;
string outputData = "", outputDatab = "";

double IndicatorBufferATR[];

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart(){
// Comment to appear in the up left screen
   Comment("Exporting ... Please wait... ");
   uint start=GetTickCount();
   for(int i = 0; i < ArraySize(sSymbols); i++){
      sSymbol = sSymbols[i] + "+";
      ExtFileName = sSymbol;
      ArraySetAsSeries(rates_array, true);
      if((int(TimeCurrent()) - int(startdate)) / (PeriodSeconds(Period())) < 10000){
         iCurrent = CopyRates(sSymbol, Period(), TimeCurrent(), startdate, rates_array);
      }
      else{
         iCurrent = CopyRates(sSymbol, Period(), 0, 10000, rates_array);
      }
      bars = Bars(sSymbol, PERIOD_CURRENT);
      to_copy = bars;
   
   
      string separator = ",";
      int m_handle = -1, line_count = 1;
      string m_filename = "AlgoTrading\\indicators.txt";
   
      Comment("Exporting " + sSymbol + " " + IntegerToString(i) + "/" + IntegerToString(ArraySize(sSymbols)) + " ...");
      ExportPairs();
   
      m_handle = FileOpen(m_filename, FILE_CSV|FILE_ANSI|FILE_READ, separator, CP_ACP);
      if(m_handle < 0){
         Comment("I can't open the file.");
      }
      else{
         Comment("File successfully open.");
         while (FileIsEnding(m_handle) == false){
            Indicator_Directory_And_Name = "Downloads\\" + FileReadString(m_handle);
            Comment("Exporting " + sSymbol + " " + IntegerToString(i) + "/" + IntegerToString(ArraySize(sSymbols)) + " ... " + IntegerToString(line_count) + " ...");
            int id = (int)StringToInteger(FileReadString(m_handle));
            int BufferCount = (int)StringToInteger(FileReadString(m_handle));
            string data = FileReadString(m_handle);
            ExportIndicators(id, BufferCount, data);
            
            if (FileIsLineEnding(m_handle) == true){
               line_count++;
            }
         }
         FileClose(m_handle);
      }
   }
   Comment("Finished");
   Print(GetTickCount() - start);
}

void ExportIndicators (int id, int BufferCount, string data){
   int pos = StringFind(Indicator_Directory_And_Name, "\\", 0);
   string indicatorName = StringSubstr(Indicator_Directory_And_Name, pos + 1, -1);
   StringConcatenate(ExtFileName, "AlgoTrading\\", sPeriod, "_", sSymbol, "\\", id, indicatorName);
   Ext2FileName = "AlgoTrading\\" + sPeriod + "_" + sSymbol + "\\";
   
   string data0[];
   double data1[];
   
   StringSplit(data, 34, data0);
   int param_Num = ((ArraySize(data0) - 2) / 3);
   ArrayResize(data1, param_Num * 3);
   
   for (int i = 1; i <= param_Num * 3; i++){
      data1[i - 1] = StringToDouble(data0[i]);
   }
   
   if(param_Num > 0){
      for(double i1 = data1[0]; i1 <= data1[2]; i1 += data1[1]){
         if(param_Num > 1){
            for(double i2 = data1[3]; i2 <= data1[5]; i2 += data1[4]){
               if(param_Num > 2){
                  for(double i3 = data1[6]; i3 <= data1[8]; i3 += data1[7]){
                     if(param_Num > 3){
                        for(double i4 = data1[9]; i4 <= data1[11]; i4 += data1[10]){
                           if(param_Num > 4){
                              for(double i5 = data1[12]; i5 <= data1[14]; i5 += data1[13]){
                                 if(param_Num > 5){
                                    for(double i6 = data1[15]; i6 <= data1[17]; i6 += data1[16]){
                                       if(param_Num > 6){
                                          for(double i7 = data1[18]; i7 <= data1[20]; i7 += data1[19]){
                                             Ext1FileName = ExtFileName + "(" + ToString(i1) + " " + ToString(i2) + " " + ToString(i3) + " " + ToString(i4) + " " + ToString(i5) + " " + ToString(i6) + " " + ToString(i7) + ")" + ".CSV";
                                             LoopIndicatorData(id, BufferCount, iCustom(sSymbol, PERIOD_CURRENT, Indicator_Directory_And_Name, i1, i2, i3, i4, i5, i6, i7));
                                          }
                                       }
                                       else{
                                          Ext1FileName = ExtFileName + "(" + ToString(i1) + " " + ToString(i2) + " " + ToString(i3) + " " + ToString(i4) + " " + ToString(i5) + " " + ToString(i6) + ")" + ".CSV";
                                          LoopIndicatorData(id, BufferCount, iCustom(sSymbol, PERIOD_CURRENT, Indicator_Directory_And_Name, i1, i2, i3, i4, i5, i6));
                                       }
                                    }
                                 }
                                 else{
                                    Ext1FileName = ExtFileName + "(" + ToString(i1) + " " + ToString(i2) + " " + ToString(i3) + " " + ToString(i4) + " " + ToString(i5) + ")" + ".CSV";
                                    LoopIndicatorData(id, BufferCount, iCustom(sSymbol, PERIOD_CURRENT, Indicator_Directory_And_Name, i1, i2, i3, i4, i5));
                                 }
                              }
                           }
                           else{
                              Ext1FileName = ExtFileName + "(" + ToString(i1) + " " + ToString(i2) + " " + ToString(i3) + " " + ToString(i4) + ")" + ".CSV";
                              LoopIndicatorData(id, BufferCount, iCustom(sSymbol, PERIOD_CURRENT, Indicator_Directory_And_Name, i1, i2, i3, i4));
                           }
                        }
                     }
                     else{
                        Ext1FileName = ExtFileName + "(" + ToString(i1) + " " + ToString(i2) + " " + ToString(i3) + ")" + ".CSV";
                        LoopIndicatorData(id, BufferCount, iCustom(sSymbol, PERIOD_CURRENT, Indicator_Directory_And_Name, i1, i2, i3));
                     }
                  }
               }
               else{
                  Ext1FileName = ExtFileName + "(" + ToString(i1) + " " + ToString(i2) + ")" + ".CSV";
                  LoopIndicatorData(id, BufferCount, iCustom(sSymbol, PERIOD_CURRENT, Indicator_Directory_And_Name, i1, i2));
               }
            }
         }
         else{
            Ext1FileName = ExtFileName + "(" + ToString(i1) + ")" + ".CSV";
            LoopIndicatorData(id, BufferCount, iCustom(sSymbol, PERIOD_CURRENT, Indicator_Directory_And_Name, i1));
         }
      }
   }
   else{
      Ext1FileName = ExtFileName + ".CSV";
      LoopIndicatorData(id, BufferCount, iCustom(sSymbol, PERIOD_CURRENT, Indicator_Directory_And_Name));
   }
}

string ToString(double d){
   if(d == MathFloor(d)){
      return IntegerToString((int)d);
   }
   else{
      return DoubleToString(d);
   }
}

void LoopIndicatorData (int id, int BufferCount, int rsiHandle){
   double IndicatorBuffer[];
   double IndicatorBuffer1[];
   
   SetIndexBuffer(BufferCount, IndicatorBuffer, INDICATOR_DATA);
   if(id == 2){
      SetIndexBuffer(BufferCount + 1, IndicatorBuffer1, INDICATOR_DATA);
   }

   //int rsiHandle = iCustom(sSymbol, PERIOD_CURRENT, Indicator_Directory_And_Name);       // Change here.

   CopyBuffer(rsiHandle, BufferCount, 0, to_copy, IndicatorBuffer);
   ArraySetAsSeries(IndicatorBuffer, true);
   if(id == 2){
      CopyBuffer(rsiHandle, BufferCount + 1, 0, to_copy, IndicatorBuffer1);
      ArraySetAsSeries(IndicatorBuffer1, true);
   }
   
   int fileHandle = FileOpen(Ext1FileName, FILE_WRITE|FILE_ANSI|FILE_CSV);
   double value2 = 0;
   action = lastaction = 0;
   outputData = "";
   outputDatab = "";
   int count = 0, result = 0, i1 = 0;
   bool first = false, inTrade = false, buildoutput = false;
   double price = 0, price1 = 0;
   for(int i = iCurrent - 1; i > 0; i--){
      if(id == 2){
         value2 = IndicatorBuffer1[i];
      }
      close = iClose(sSymbol, PERIOD_CURRENT, i);
      result = 0;
      TrendIndicator(id, IndicatorBuffer[i], value2);
      if(lastaction != action){
         if(first == true){
            outputData += "\n";
            outputDatab += "\n";
         } 
         else{
            first = true;
         }
         outputData += StringFormat("%s", TimeToString(rates_array[i].time, TIME_DATE|TIME_MINUTES));
         outputDatab += StringFormat("%s", TimeToString(rates_array[i].time, TIME_DATE|TIME_MINUTES));
         outputData += "," + IntegerToString(action);
         outputDatab += "," + IntegerToString(action);
         if(action == 1 && close + IndicatorBufferATR[i] >= IndicatorBuffer[i]){ // baseline pullback
            outputDatab += ",1";
         }
         else if(action == -1 && close - IndicatorBufferATR[i] <= IndicatorBuffer[i]){ // baseline pullback
            outputDatab += ",1";
         }
         else{
            outputDatab += ",0";
         }
         lastaction = action;
         /*price = iClose(sSymbol, PERIOD_CURRENT, i);
         if(action != 0){
            inTrade = true;
            price1 = price;
            i1 = i;
         }
         buildoutput = true;*/
      }
      /*else if (inTrade == true && ((lastaction == 1 && -(low - price1) >= (IndicatorBufferATR[i1] * 1.5)) || (lastaction == -1 && (high - price1) >= (IndicatorBufferATR[i1] * 1.5)))){
         inTrade = false;
         buildoutput = true;
         result = -1;
      }
      else if (inTrade == true && ((lastaction == -1 && -(low - price1) >= (IndicatorBufferATR[i1])) || (lastaction == 1 && (high - price1) >= (IndicatorBufferATR[i1])))){
         inTrade = false;
         buildoutput = true;
         result = 1;
      }
      if(buildoutput == true){
         if(first == true){
            outputData += "," + IntegerToString(count);
            outputData += "\n";
         } 
         else{
            first = true;
         }
         outputData += StringFormat("%s", TimeToString(rates_array[i].time, TIME_DATE|TIME_MINUTES));
         outputData += "," + IntegerToString(action);
         outputData += "," + IntegerToString(result);
         lastaction = action;
         count = 0;
         buildoutput = false;
      }
      count++;*/
   }
   //FileWriteString(fileHandle, outputData + ",0");
   FileWriteString(fileHandle, outputData);
   FileClose(fileHandle);
   if(id == 3){
      int fileHandleb = FileOpen(Ext2FileName + "Baseline\\" + StringSubstr(Ext1FileName, StringLen(Ext2FileName)), FILE_WRITE|FILE_ANSI|FILE_CSV);
      FileWriteString(fileHandleb, outputDatab);
      FileClose(fileHandleb);
   }
   if(id <= 4){
      FileCopy(Ext1FileName, 0, Ext2FileName + "Confirmation\\" + StringSubstr(Ext1FileName, StringLen(Ext2FileName)), FILE_REWRITE);
      FileCopy(Ext1FileName, 0, Ext2FileName + "Confirmation2\\" + StringSubstr(Ext1FileName, StringLen(Ext2FileName)), FILE_REWRITE);
      FileCopy(Ext1FileName, 0, Ext2FileName + "Exit\\" + StringSubstr(Ext1FileName, StringLen(Ext2FileName)), FILE_REWRITE);
   }
   else if(id >= 5){
      FileCopy(Ext1FileName, 0, Ext2FileName + "Volume\\" + StringSubstr(Ext1FileName, StringLen(Ext2FileName)), FILE_REWRITE);
   }
   IndicatorRelease(rsiHandle);
}

void ExportPairs (){
   datetime cal[];
   Calendar(cal);
   
   StringConcatenate(ExtFileName,"AlgoTrading\\", sPeriod, "_", sSymbol, "\\",sSymbol, "\\", sSymbol, ".CSV");

   int fileHandle=FileOpen(ExtFileName,FILE_WRITE|FILE_ANSI|FILE_CSV);
   
   SetIndexBuffer(0, IndicatorBufferATR, INDICATOR_DATA);
   int rsiHandle = iCustom(sSymbol, PERIOD_CURRENT, "Downloads\\ATR");
   CopyBuffer(rsiHandle, 0, 0, to_copy, IndicatorBufferATR);
   ArraySetAsSeries(IndicatorBufferATR, true);

   for(int i = iCurrent - 1; i > 0; i--){
      outputData = StringFormat("%s", TimeToString(rates_array[i].time, TIME_DATE|TIME_MINUTES));
      outputData += "," + DoubleToString(iOpen(sSymbol, PERIOD_CURRENT, i));
      outputData += "," + DoubleToString(iClose(sSymbol, PERIOD_CURRENT, i));
      outputData += "," + DoubleToString(iHigh(sSymbol, PERIOD_CURRENT, i));
      outputData += "," + DoubleToString(iLow(sSymbol, PERIOD_CURRENT, i));
      outputData += "," + DoubleToString(iVolume(sSymbol, PERIOD_CURRENT, i));
      outputData += "," + DoubleToString(IndicatorBufferATR[i]);
      outputData += "," + IntegerToString(CalendarCheck(cal, rates_array[i].time));
      if(i != 1){
         outputData+="\n";
      }
      FileWriteString(fileHandle, outputData);
   }
   IndicatorRelease(rsiHandle);
   FileClose(fileHandle);
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


void TrendIndicator(int id, double value1, double value2){
   if(id == 1){
      TrendZeroCross(value1);
   }
   else if(id == 2){
      TrendTwoLinesCross(value1, value2);
   }
   else if(id == 3){
      TrendChartIndicator(value1);
   }
   else if(id == 4){
      TrendColourIndicator(value1);
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

void TrendChartIndicator(double value){
   if(action == 0 && value < close){
      action = -1;
   }
   else if(action == 0 && value > close){
      action = 1;
   }
   else if(action == 1 && value < close){
      action = -1;
   }
   else if(action == -1 && value > close){
      action = 1;
   }
}

void TrendColourIndicator(double value){
   value = NormalizeDouble(value, 0);
   if((action == 1 && !(value == 1)) || (action == -1 && !(value == 2))){
      action = 0;
   }
   if(action == 0 && value == 1){
      action = 1;
   }
   else if(action == 0 && value == 2){
      action = -1;
   }
}
//+------------------------------------------------------------------+
