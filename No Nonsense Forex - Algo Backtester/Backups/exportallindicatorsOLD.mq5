//+------------------------------------------------------------------+
//|                                          Export Indicator Values |
//+------------------------------------------------------------------+
#property description "This Script Export Indicators Values to CSV File."
#property description "(You can change the iCustom function parameters to change what indicator to export)"
#property copyright "NFTrader"
#property version   "2.00"
#property script_show_inputs

MqlRates  rates_array[];
string sSymbols[] = {"EURGBP", "EURNZD", "EURUSD", "EURAUD", "EURCAD", "EURJPY", "GBPNZD", "GBPUSD", 
"GBPAUD", "GBPCAD", "GBPCHF", "GBPJPY", "NZDUSD", "AUDNZD", "NZDCAD", "NZDCHF", "NZDJPY", "AUDUSD", "USDCAD", 
"USDCHF", "USDJPY", "AUDCAD", "AUDCHF", "AUDJPY", "CADCHF", "CADJPY", "CHFJPY"};

string sSymbol;
datetime startdate=D'01.01.2010';
string Indicator_Directory_And_Name;

// Convert Period to string to use it in the file name
string sPeriod = StringSubstr(EnumToString(Period()), 7);

string ExtFileName; // ="RSI(XX, XX, ...).CSV";

int iCurrent, bars, to_copy;

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart(){
// Comment to appear in the up left screen
   Comment("Exporting ... Please wait... ");

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
            int id = StringToInteger(FileReadString(m_handle));
            int BufferCount = StringToInteger(FileReadString(m_handle));
            ExportIndicators(id, BufferCount);
            
            if (FileIsLineEnding(m_handle) == true){
               line_count++;
            }
         }
         FileClose(m_handle);
      }
   }
   Comment("Finished");
}
  
void ExportIndicators (int id, int BufferCount){
   int pos = StringFind(Indicator_Directory_And_Name, "\\", 0);
   string indicatorName = StringSubstr(Indicator_Directory_And_Name, pos + 1, -1);
   StringConcatenate(ExtFileName, "AlgoTrading\\", sPeriod, "_", sSymbol, "\\", id, indicatorName, ".CSV");

   double IndicatorBuffer[];
   double IndicatorBuffer1[];
   double IndicatorBuffer2[];
   
   if(BufferCount > 0 && id == 4)
      SetIndexBuffer(1, IndicatorBuffer, INDICATOR_DATA);
   else if(BufferCount > 0)
      SetIndexBuffer(0, IndicatorBuffer, INDICATOR_DATA);
   if(BufferCount > 1)
      SetIndexBuffer(1, IndicatorBuffer1, INDICATOR_DATA);
   if(BufferCount > 2)
      SetIndexBuffer(2, IndicatorBuffer2, INDICATOR_DATA);

   int rsiHandle = iCustom(sSymbol, PERIOD_CURRENT, Indicator_Directory_And_Name);       // Change here.

   if(BufferCount > 0 && id == 4){
      CopyBuffer(rsiHandle, 1, 0, to_copy, IndicatorBuffer);
      ArraySetAsSeries(IndicatorBuffer, true);
   }
   else if(BufferCount > 0){
      CopyBuffer(rsiHandle, 0, 0, to_copy, IndicatorBuffer);
      ArraySetAsSeries(IndicatorBuffer, true);
   }
   if(BufferCount > 1){
      CopyBuffer(rsiHandle, 1, 0, to_copy, IndicatorBuffer1);
      ArraySetAsSeries(IndicatorBuffer1, true);
   }
   if(BufferCount > 2){
      CopyBuffer(rsiHandle, 2, 0, to_copy, IndicatorBuffer2);
      ArraySetAsSeries(IndicatorBuffer2, true);
   }

   int fileHandle = FileOpen(ExtFileName, FILE_WRITE|FILE_CSV);

   for(int i = iCurrent - 1; i > 0; i--){
      string outputData = StringFormat("%s", TimeToString(rates_array[i].time, TIME_DATE));
      outputData += "," + TimeToString(rates_array[i].time, TIME_MINUTES);
      if(BufferCount > 0)
         outputData += "," + DoubleToString(IndicatorBuffer[i]);
      if(BufferCount > 1)
         outputData += "," + DoubleToString(IndicatorBuffer1[i]);
      if(BufferCount > 2)
         outputData += "," + DoubleToString(IndicatorBuffer2[i]);
      outputData += "\n";

      FileWriteString(fileHandle, outputData);
   }

   FileClose(fileHandle);
}

void ExportPairs (){
   int pos=StringFind(Indicator_Directory_And_Name,"\\",0);
   string indicatorName=StringSubstr(Indicator_Directory_And_Name,pos+1,-1);
   StringConcatenate(ExtFileName,"AlgoTrading\\", sPeriod, "_", sSymbol, "\\",sSymbol, "\\", sSymbol, ".CSV");

   int fileHandle=FileOpen(ExtFileName,FILE_WRITE|FILE_CSV);

   for(int i=iCurrent-1; i>0; i--){
      string outputData=StringFormat("%s", TimeToString(rates_array[i].time, TIME_DATE));
      outputData+=","+TimeToString(rates_array[i].time, TIME_MINUTES);
      outputData+=","+ DoubleToString(iOpen(sSymbol, PERIOD_CURRENT,i));
      outputData+=","+ DoubleToString(iClose(sSymbol, PERIOD_CURRENT,i));
      outputData+=","+ DoubleToString(iHigh(sSymbol, PERIOD_CURRENT,i));
      outputData+=","+ DoubleToString(iLow(sSymbol, PERIOD_CURRENT,i));
      outputData+=","+ DoubleToString(iVolume(sSymbol, PERIOD_CURRENT,i));
      outputData+="\n";

      FileWriteString(fileHandle, outputData);
   }

   FileClose(fileHandle);
}
//+------------------------------------------------------------------+
