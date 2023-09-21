//+------------------------------------------------------------------+
//|                                          Export Indicator Values |
//+------------------------------------------------------------------+
#property description "This Script Export Indicators Values to CSV File."
#property description "(You can change the iCustom function parameters to change what indicator to export)"
#property copyright "NFTrader"
#property version   "2.00"
#property script_show_inputs

string files[], pairs[], indicators[];

datetime pairsTime[], indicatorsTime[];
double pairsDouble[];
int indicatorsInt[];

int fileHandle;

struct Indicator {
   int handle;
   int handle1;
   string filename;
   datetime date;
   int value;
};

int accountsize = 1000;
int risk = 2;

Indicator sym, ind1, ind2, volume;

double value;
int action, action1, action2;
int win, loss, even, winpercent, dd, maxdd;
bool inTrade = false, isBuy = false, isdd = false;
double totalpips = 0, pips = 0, dd_low = 0, dd_high = 0, acc_size = 0, price = 0, atr = 0, atr1 = 0;
double currprice = 0, high = 0, low = 0, curratr = 0;

bool wantATRmanaged = true;

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart(){
   uint start=GetTickCount();
   acc_size = dd_low = dd_high = accountsize;
   string current_directory = "AlgoTrading\\D1_GBPNZD+\\";
   sym.filename = "AlgoTrading\\D1_GBPNZD+\\GBPNZD+\\GBPNZD+.CSV";
   fileHandle = FileOpen("AlgoTrading\\output.CSV",FILE_WRITE|FILE_ANSI|FILE_CSV);
   FileWriteString(fileHandle, "ID,Indicator 1,Wins,Losses,Breakeven,TotalTrades,TotalPips,Balance,MaxDD,Win %,Prev ID,Indicator 2,Wins,Losses,Breakeven,TotalTrades,TotalPips,Balance,MaxDD,Win %,Increased Win %\n");
   GetFiles(current_directory, true);
   FileToStrings(sym.filename, pairs);
   ArrayResize(pairsTime, ArraySize(pairs)/7);
   ArrayResize(pairsDouble, ArraySize(pairs) - ArraySize(pairs)/7);
   ArrayResize(indicatorsTime, ArraySize(indicators)/2);
   ArrayResize(indicatorsInt, ArraySize(indicators)/2);
   for(int i = 0; i < ArraySize(pairs); i++){
      if(i % 7 == 0){
         pairsTime[i / 7] = StringToTime(pairs[i]);
      }
      else{
         pairsDouble[i - i / 7 - 1] = StringToDouble(pairs[i]);
      }
   }
   for(int i = 0; i < ArraySize(indicators); i++){
      if(i % 2 == 0){
         indicatorsTime[i / 2] = StringToTime(indicators[i]);
      }
      else{
         indicatorsInt[i / 2] = (int)StringToInteger(indicators[i]);
      }
   }
   for(int i = 0; i < ArraySize(files); i += 3){
      for(int j = -3; j < ArraySize(files); j += 3){
         if(i == j){
            continue;
         }
         
         ind1.filename = current_directory + files[i];
         ind1.handle = (int)StringToInteger(files[i + 1]);
         ind1.handle1 = (int)StringToInteger(files[i + 2]);
         sym.handle = 0;
         sym.handle1 = ArraySize(pairs) - 1;
         if(j != -3){
            ind2.filename = current_directory + files[j];
            ind2.handle = (int)StringToInteger(files[j + 1]);
            ind2.handle1 = (int)StringToInteger(files[j + 2]);
         }
         else{
            ind2.filename = ind1.filename;
            ind2.handle = ind1.handle;
            ind2.handle1 = ind1.handle1;
         }
         ind1.date = StringToTime(indicators[ind1.handle]);
         ind1.handle++;
         if(j != -3){
            ind2.date = StringToTime(indicators[ind2.handle]);
            ind2.handle++;
         }
         else{
            ind2.date = ind1.date;
         }
         
         while (sym.handle <= sym.handle1){
            sym.date = pairsTime[sym.handle / 7];
            currprice = pairsDouble[sym.handle - sym.handle / 7 + 1];
            high = pairsDouble[sym.handle - sym.handle / 7 + 2];
            low = pairsDouble[sym.handle - sym.handle / 7 + 3];
            curratr = pairsDouble[sym.handle - sym.handle / 7 + 5];
            sym.handle += 7;
            if(sym.date >= ind1.date && ind1.handle <= ind1.handle1){
               ind1.value = indicatorsInt[ind1.handle / 2];
               ind1.handle++;
               if(ind1.handle < ind1.handle1){
                  ind1.date = indicatorsTime[ind1.handle / 2];
                  ind1.handle++;
               }
            }
            if(sym.date >= ind2.date && ind2.handle <= ind2.handle1){
               if(j != -3){
                  ind2.value = indicatorsInt[ind2.handle / 2];
                  ind2.handle++;
                  if(ind2.handle < ind2.handle1){
                     ind2.date = indicatorsTime[ind2.handle / 2];
                     ind2.handle++;
                  }
               }
               else{
                  ind2.date = ind1.date;
                  ind2.value = ind1.value;
               }
            }
             
            if(wantATRmanaged == true && inTrade == true && ((-(low - price) >= (atr1 * 1.5) && isBuy == true) || ((high - price) >= (atr1 * 1.5) && isBuy == false))){
               EndTrade();
            }
            else if(wantATRmanaged == true && inTrade == true && (((high - price) >= atr1 && isBuy == true) || (-(low - price) >= atr1 && isBuy == false))){
               atr1 = 0;
            }
            if(wantATRmanaged == true && inTrade == true && (ind1.value == 0 || (ind1.value != 1 && isBuy == true) || (ind1.value != -1 && isBuy == false))){
               EndTrade();
            }
            if(ind1.value == ind2.value && ind1.value != 0 && inTrade == false){
               MakeTrade();
            }
         }
         if(j != -3){
            int incr_winpercent = 0;
            int winpercent1 = 0;
            if((win + loss + even) != 0){
               incr_winpercent = winpercent;
               winpercent1 = (int)((win * 1./ (win + loss + even)) * 100);
               incr_winpercent = winpercent1 - winpercent; 
            }
            SetFiles(2, i/3, files[j], win, loss, even, win + loss + even, totalpips * 10000, winpercent1, incr_winpercent);
         }
         else{
            if((win + loss + even) != 0){
               winpercent = (int)((win * 1./ (win + loss + even)) * 100);
            }
            SetFiles(1, i/3, files[i], win, loss, even, win + loss + even, totalpips * 10000, winpercent, 0);
         }
         ResetVariables();
      }
      Print(i);
   }
   Print(GetTickCount() - start);
   FileClose(fileHandle);
}

void FileToStrings( const string FileName, string &Str[] ){
   uchar Bytes[];
   string Str1[];
   string Str2[];
   FileLoad(FileName, Bytes);
   StringSplit(CharArrayToString(Bytes), '\n', Str1);
   for(int i = 0; i < ArraySize(Str1); i++){
      StringSplit(Str1[i], ',', Str2);
      ArrayCopy(Str, Str2, ArraySize(Str));
   }
}

void GetFiles(string current_directory, bool isFiles){
   string file_name;
   int lastsize = 0;
   long search_handle=FileFindFirst(current_directory + "*", file_name); 
   
   if(search_handle!=INVALID_HANDLE){ 
      do{
         if(FileIsExist(current_directory + file_name) == isFiles){
            string str[];
            string str1[3];
            FileToStrings(current_directory + file_name, str);
            ArrayCopy(indicators, str, ArraySize(indicators));
            str1[0] = file_name;
            str1[1] = IntegerToString(lastsize);
            str1[2] = IntegerToString(ArraySize(indicators) - 1);
            lastsize = ArraySize(indicators);
            ArrayCopy(files, str1, ArraySize(files));
         }
      } 
      while(FileFindNext(search_handle,file_name)); 
      FileFindClose(search_handle); 
   } 
   else {
      Comment("Files not found!");
   }
}

void SetFiles (int depth, int id, string indicator, int wins, int losses, int breakeven, int total, double totalPips, int winpercent1, int incr_winpercent){
   string outputData = "";
   if(depth == 1){
      outputData = IntegerToString(id) + "," + indicator + "," + IntegerToString(wins) + "," + IntegerToString(losses) + "," + IntegerToString(breakeven) + "," + IntegerToString(total);
      outputData += "," + DoubleToString(totalPips) + "," + DoubleToString(acc_size) + "," + IntegerToString(maxdd) + "," + IntegerToString(winpercent1);
   }
   else if(depth == 2){
      outputData = ",,,,,,,,,," + IntegerToString(id) + "," + indicator + "," + IntegerToString(wins) + "," + IntegerToString(losses) + "," + IntegerToString(breakeven) + "," + IntegerToString(total);
      outputData += "," + DoubleToString(totalPips) + "," + DoubleToString(acc_size) + "," + IntegerToString(maxdd) + "," + IntegerToString(winpercent1) + "," + IntegerToString(incr_winpercent);
   }
   outputData+="\n";

   FileWriteString(fileHandle, outputData);
}

void ResetVariables(){
   value = 0;
   action = action1 = action2 = 0;

   win = loss = even = dd = maxdd = 0;
   inTrade = isBuy = isdd = false;
   totalpips = pips = dd_low = price = atr = atr1 = 0;
   acc_size = dd_low = dd_high = accountsize;
   
   currprice = high = low = curratr = 0;
}

void MakeTrade(){
   inTrade = true;
   price = currprice;
   atr = atr1 = curratr;
   if(ind1.value == 1){
      isBuy = true;
   }
   else if(ind1.value == -1){
      isBuy = false;
   }
}

void EndTrade(){
   inTrade = false;
   if(isBuy == true){
      pips = (currprice - price);
   }
   else{
      pips = -(currprice - price);
   }
   totalpips += pips;
   acc_size += (pips * 10000) * ((acc_size * risk / 100) / (atr * 10000 * 1.5));
   if(pips > 0){
      win++;
      if(isdd == false){
         dd_high = dd_low = acc_size;
      }
      else if(dd_high <= acc_size){
         isdd = false;
         if(dd_high == 0){
            dd_high++;
         }
         dd = int(((dd_high - dd_low) / dd_high) * 100);
         if(dd > maxdd){
            maxdd = dd;
         }
      }
   }
   else if(pips < 0){
      loss++;
      isdd = true;
      if(dd_low > acc_size){
         dd_low = acc_size;
         if(dd_high == 0){
            dd_high++;
         }
         dd = int(((dd_high - dd_low) / dd_high) * 100);
         if(dd > maxdd){
            maxdd = dd;
         }
      }
   }
   else{
      even++;
   }
}
//+------------------------------------------------------------------+
