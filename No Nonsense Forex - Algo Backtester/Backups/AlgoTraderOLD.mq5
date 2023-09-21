//+------------------------------------------------------------------+
//|                                          Export Indicator Values |
//+------------------------------------------------------------------+
#property description "This Script Export Indicators Values to CSV File."
#property description "(You can change the iCustom function parameters to change what indicator to export)"
#property copyright "NFTrader"
#property version   "2.00"
#property script_show_inputs

string files[];

int fileHandle, ind1_handle = -1, ind2_handle = -1, sym_handle = -1, atr_handle = -1;

double value, value1;
int action, action1, action2;

int win, win1, win2, loss, loss1, loss2, even, even2;
bool inTrade = false, inTrade2 = false, isBuy = false, isBuy2 = false;
double totalpips = 0, totalpips2 = 0, price = 0, price2 = 0, atr = 0, atr2 = 0;

int indicator1, indicator2;
double currprice = 0, high = 0, low = 0;

bool wantATRmanaged = true;

/*struct Trend {
   bool trade;
   bool buy;
};*/


//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart(){

   string separator = ",";
   int line_count = 1;
   string current_directory = "AlgoTrading\\D1_GBPNZD+\\";
   string ind1_filename = "";
   string ind2_filename = "";
   string sym_filename = "AlgoTrading\\D1_GBPNZD+\\GBPNZD+\\GBPNZD+.CSV";
   string atr_filename = "AlgoTrading\\D1_GBPNZD+\\0ATR.CSV";
   fileHandle = FileOpen("AlgoTrading\\output.CSV",FILE_WRITE|FILE_CSV);
   FileWriteString(fileHandle, "ID,Indicator 1,Wins,Losses,Breakeven,TotalTrades,TotalPips,Prev ID,Indicator 2,Wins,Losses,Breakeven,TotalTrades,TotalPips,Wins/Losses\n");
   sym_handle = FileOpen(sym_filename, FILE_CSV|FILE_ANSI|FILE_READ, separator, CP_ACP);
   atr_handle = FileOpen(atr_filename, FILE_CSV|FILE_ANSI|FILE_READ, separator, CP_ACP);
   GetFiles(current_directory, true);
   
   for(int i = 0; i < ArraySize(files); i++){
      ind1_filename = current_directory + files[i];
      ind1_handle = FileOpen(ind1_filename, FILE_CSV|FILE_ANSI|FILE_READ, separator, CP_ACP);
      
      for(int j = -1; j < ArraySize(files); j++){
         if(i == j){
            continue;
         }
         if(j != -1){
            ind2_filename = current_directory + files[j];
            ind2_handle = FileOpen(ind2_filename, FILE_CSV|FILE_ANSI|FILE_READ, separator, CP_ACP);
         }
         else{
            ind2_filename = ind1_filename;
            ind2_handle = ind1_handle;
         }
         
         if(ind1_handle < 0 || ind2_handle < 0 || sym_handle < 0){
            Comment("I can't open the file.");
         }
         else{
            while (FileIsEnding(ind1_handle) == false && FileIsEnding(ind2_handle) == false && FileIsEnding(sym_handle) == false){
               string s = FileReadString(sym_handle); //skip the date for now
               FileReadString(sym_handle); //skip the time for now
               FileReadString(sym_handle); //skip the open for now
               currprice = (double)FileReadString(sym_handle);
               high = (double)FileReadString(sym_handle);
               low = (double)FileReadString(sym_handle);
               FileReadString(sym_handle); //skip the volume for now
               FileReadString(atr_handle); //skip the date for now
               FileReadString(atr_handle); //skip the time for now
               atr = (double)FileReadString(atr_handle);
               indicator1 = TrendIndicator(ind1_handle, true, ind1_filename, current_directory);
               if(j != -1){
                  indicator2 = TrendIndicator(ind2_handle, false, ind2_filename, current_directory);
               }
               else{
                  indicator2 = indicator1;
               }
               if(wantATRmanaged == true && inTrade2 == true && ((-(low - price2) >= (atr2 * 1.5) && isBuy2 == true) || ((high - price2) >= atr2 && isBuy2 == true) || ((high - price2) >= (atr2 * 1.5) && isBuy2 == false) || (-(low - price2) >= atr2 && isBuy2 == false))){
                  EndTrade();//calculate loss by using high and low
               }
               if(wantATRmanaged == false && inTrade2 == true && (indicator1 == 0 || ((indicator1 != 1 && isBuy2 == true) || (indicator1 != -1 && isBuy2 == false)))){
                  EndTrade();
               }
               if(indicator1 == indicator2 && indicator1 != 0 && inTrade2 == false){
                  MakeTrade();
               }
            
               if (FileIsLineEnding(sym_handle) == true){
                  line_count++;
               }
            }
         }
         if(j != -1){
            FileClose(ind2_handle);
            double wl = 1000;
            if(loss1 - loss2 != 0){
               wl = ((win1 - win2) * 1.) / (loss1 - loss2);
            }
            SetFiles(2, i, files[j], win2, loss2, even2, win2 + loss2 + even2, totalpips2 * 10000, wl);
         }
         else{
            win1 = win2;
            loss1 = loss2;
            SetFiles(1, i, files[i], win2, loss2, even2, win2 + loss2 + even2, totalpips2 * 10000, 0);
         }
         //printf("Indicator1     Wins: %d Losses: %d Breakeven: %d TotalTrades: %d TotalPips: %s %s", win1, loss1, even1, win1 + loss1 + even1, DoubleToString(totalpips1 * 10000), ind1_filename);
         //printf("%s     %d%d: Wins: %d Losses: %d Breakeven: %d TotalTrades: %d TotalPips: %s Wins/Losses: %s", ind2_filename, i, j, win2, loss2, even2, win2 + loss2 + even2, DoubleToString(totalpips2 * 10000), DoubleToString(wl));
         ResetVariables();
         FileSeek(ind1_handle, 0, SEEK_SET);
         FileSeek(sym_handle, 0, SEEK_SET);
         FileSeek(atr_handle, 0, SEEK_SET);
      }
      FileClose(ind1_handle);
   }
   FileClose(sym_handle);
   FileClose(fileHandle);
}

void GetFiles(string current_directory, bool isFiles){
   string file_name; 
   int i = 0;
   
   long search_handle=FileFindFirst(current_directory + "*", file_name); 
   
   if(search_handle!=INVALID_HANDLE){ 
      do{
         if(FileIsExist(current_directory + file_name) == isFiles && file_name != "0ATR.CSV"){
            ArrayResize(files, i + 1);
            files[i] = file_name;
            i++;
         }
      } 
      while(FileFindNext(search_handle,file_name)); 
      FileFindClose(search_handle); 
   } 
   else {
      Comment("Files not found!");
   }
}

void SetFiles (int depth, int id, string indicator, int wins, int losses, int breakeven, int total, double totalPips, double wl){
   string outputData = "";
   if(depth == 1){
      outputData = IntegerToString(id) + "," + indicator + "," + IntegerToString(wins) + "," + IntegerToString(losses);
      outputData += "," + IntegerToString(breakeven) + "," + IntegerToString(total) + "," + DoubleToString(totalPips);
   }
   else if(depth == 2){
      outputData = ",,,,,,," + IntegerToString(id) + "," + indicator + "," + IntegerToString(wins) + "," + IntegerToString(losses);
      outputData += "," + IntegerToString(breakeven) + "," + IntegerToString(total) + "," + DoubleToString(totalPips) + "," + DoubleToString(wl);
   }
   outputData+="\n";

   FileWriteString(fileHandle, outputData);
}

void ResetVariables(){
   value = value1 = 0;
   action = action1 = action2 = 0;

   win = win2 = loss = loss2 = even = even2 = 0;
   inTrade = inTrade2 = isBuy = isBuy2 = false;
   totalpips = totalpips2 = price = price2 = atr = atr2 = 0;

   indicator1 = indicator2 = 0;
   currprice = high = low = 0;
}

void MakeTrade(){
   GetTradeData();
   inTrade = true;
   price = currprice;
   atr2 = atr;
   if(indicator1 == 1){
      isBuy = true;
   }
   else if(indicator1 == -1){
      isBuy = false;
   }
   SetTradeData();
}

void EndTrade(){
   GetTradeData();
   if(isBuy == true){
      totalpips += (currprice - price);
   }
   else{
      totalpips += -(currprice - price);
   }
   if(((currprice - price) > 0 && isBuy == true) || (-(currprice - price) > 0 && isBuy == false)){
      win++;
   }
   else if(((currprice - price) < 0 && isBuy == true) || (-(currprice - price) < 0 && isBuy == false)){
      loss++;
   }
   else{
      even++;
   }
   inTrade = false;
   SetTradeData();
}

void GetTradeData(){
   inTrade = inTrade2;
   isBuy = isBuy2;
   price = price2;
   totalpips = totalpips2;
   win = win2;
   loss = loss2;
   even = even2;
}

void SetTradeData(){
   inTrade2 = inTrade;
   isBuy2 = isBuy;
   price2 = price;
   totalpips2 = totalpips;
   win2 = win;
   loss2 = loss;
   even2 = even;
}

int TrendIndicator(int handle, bool isInd1, string filename, string directory){
   filename = StringSubstr(filename, StringLen(directory));
   if(StringSubstr(filename, 0, 1) == "1"){
      TrendZeroCross(handle, isInd1);
   }
   else if(StringSubstr(filename, 0, 1) == "2"){
      TrendTwoLinesCross(handle, isInd1);
   }
   else if(StringSubstr(filename, 0, 1) ==  "3"){
      TrendChartIndicator(handle, isInd1);
   }
   else if(StringSubstr(filename, 0, 1) ==  "4"){
      TrendColourIndicator(handle, isInd1);
   }
   return action;
}

void TrendZeroCross(int handle, bool isInd1){
   FileReadString(handle); //skip the date for now
   FileReadString(handle); //skip the time for now
   action = GetAction(isInd1);
   value = (double)FileReadString(handle);
   if((action == 1 && !(value > 0)) || (action == -1 && !(value < 0))){
      action = SetAction(isInd1, 0);
   }
   if(action == 0 && value > 0){
      action = SetAction(isInd1, 1);
   }
   else if(action == 0 && value < 0){
      action = SetAction(isInd1, -1);
   }
}

void TrendTwoLinesCross(int handle, bool isInd1){
   FileReadString(handle); //skip the date for now
   FileReadString(handle); //skip the time for now
   action = GetAction(isInd1);
   value = (double)FileReadString(handle);
   value1 = (double)FileReadString(handle);
   if(action == 0 && value > value1){
      action = SetAction(isInd1, 1);
   }
   else if(action == 0 && value < value1){
      action = SetAction(isInd1, -1);
   }
   else if(action == 1 && value < value1){
      action = SetAction(isInd1, -1);
   }
   else if(action == -1 && value > value1){
      action = SetAction(isInd1, 1);
   }
}

void TrendChartIndicator(int handle, bool isInd1){
   FileReadString(handle); //skip the date for now
   FileReadString(handle); //skip the time for now
   action = GetAction(isInd1);
   value = (double)FileReadString(handle);
   if(action == 0 && value < high){
      action = SetAction(isInd1, 1);
   }
   else if(action == 0 && value > low){
      action = SetAction(isInd1, -1);
   }
   else if(action == 1 && value > high){
      action = SetAction(isInd1, -1);
   }
   else if(action == -1 && value < low){
      action = SetAction(isInd1, 1);
   }
}

void TrendColourIndicator(int handle, bool isInd1){
   FileReadString(handle); //skip the date for now
   FileReadString(handle); //skip the time for now
   action = GetAction(isInd1);
   value = NormalizeDouble((double)FileReadString(handle), 0);
   if((action == 1 && !(value == 1)) || (action == -1 && !(value == 2))){
      action = SetAction(isInd1, 0);
   }
   if(action == 0 && value == 1){
      action = SetAction(isInd1, 1);
   }
   else if(action == 0 && value == 2){
      action = SetAction(isInd1, -1);
   }
}

int GetAction(bool isInd1){
   if(isInd1 == true){
      return action1;
   }
   else{
      return action2;
   }
}

int SetAction(bool isInd1, int actions){
   if(isInd1 == true){
      action1 = actions;
   }
   else{
      action2 = actions;
   }
   return actions;
}

//+------------------------------------------------------------------+
