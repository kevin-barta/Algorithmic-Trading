//+------------------------------------------------------------------+
//|                                          Export Indicator Values |
//+------------------------------------------------------------------+
#property description "This Script Export Indicators Values to CSV File."
#property description "(You can change the iCustom function parameters to change what indicator to export)"
#property copyright "NFTrader"
#property version   "2.00"
#property script_show_inputs

int fileHandle;

struct Indicators {
   datetime time[];
   int value[];
   int value2[];
   string filename;
   int length;
};

struct Pairs {
   datetime time[];
   double open[];
   double close[];
   double high[];
   double low[];
   int volume[];
   double atr[];
   int news[];
   int length;
};

const int month = 2628000;
int accountsize = 1000;
int risk = 2;

Pairs sym;
Indicators ind1[], ind2[], baseline[], volume[], exit[];

double value, months;
int trade, news;
int win, loss, even, dd, maxdd;
bool isBuy = false, isdd = false;
double pips = 0, pipswon = 0, pipslost = 0, dd_low = 0, dd_high = 0, acc_size = 0, price = 0, trailing = 0, lots = 0, atr = 0;
double currprice = 0, high = 0, low = 0, curratr = 0;
datetime symTime, ind1Time, ind2Time, baselineTime, volumeTime, exitTime;
int ind1Value, ind2Value, baselineValue, baselineValue2, volumeValue, exitValue;
int symHandle, symLength, ind1Handle, ind1Length, ind2Handle, ind2Length, baselineHandle, baselineLength, volumeHandle, volumeLength, exitHandle, exitLength;

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart(){
   uint start=GetTickCount();
   string current_directory = "AlgoTrading\\D1_GBPNZD+\\";
   fileHandle = FileOpen("AlgoTrading\\output.CSV",FILE_WRITE|FILE_ANSI|FILE_CSV);
   FileWriteString(fileHandle, "Indicator 1,Baseline,Exit,Volume,Indicator 2,Wins,Losses,Breakeven,TotalTrades,TotalPips,Balance,MaxDD,Average Win,Average Loss,Expectancy,ROI,Win %\n");
   GetPairs(sym, current_directory);
   GetFiles(ind1, 2, current_directory + "Confirmation\\", true);
   GetFiles(ind2, 2, current_directory + "Confirmation2\\", true);
   GetFiles(baseline, 3, current_directory + "Baseline\\", true);
   GetFiles(volume, 2, current_directory + "Volume\\", true);
   GetFiles(exit, 2, current_directory + "Exit\\", true);
   
   months = (sym.time[sym.length - 1] - sym.time[0]) * 1.0 / month;
   
   for(int i = 0; i < ArraySize(ind1); i += 1){
      for(int j = 0; j < ArraySize(baseline); j += 1){
         ResetVariables();
         symLength = sym.length;
         ind1Length = ind1[i].length;
         baselineLength = baseline[j].length;
         while (symHandle < symLength){
            symTime = sym.time[symHandle];
            currprice = sym.close[symHandle];
            high = sym.high[symHandle];
            low = sym.low[symHandle];
            curratr = sym.atr[symHandle];
            news = sym.news[symHandle];
            symHandle++;
            
            if(symTime >= ind1Time && ind1Handle < ind1Length){
               if(ind1Handle + 1 < ind1Length){
                  ind1Time = ind1[i].time[ind1Handle + 1];
               }
               ind1Value = ind1[i].value[ind1Handle];
               ind1Handle++;
            }
            if(symTime >= baselineTime && baselineHandle < baselineLength){
               if(baselineHandle + 1 < baselineLength){
                  baselineTime = baseline[j].time[baselineHandle + 1];
               }
               baselineValue = baseline[j].value[baselineHandle];
               baselineValue2 = baseline[j].value2[baselineHandle];
               baselineHandle++;
            }
            
            
            
            if(trade == 3 && (((high - price) >= atr && isBuy == true) || (-(low - price) >= atr && isBuy == false))){
               trade = 4;
               if(isBuy == true){
                  trailing = high - atr;
               }
               else{
                  trailing = low + atr;
               }
            }
            else if(trade == 4 && (((high - atr) > trailing && isBuy == true) || ((low + atr) < trailing && isBuy == false))){
               if(isBuy == true){
                  trailing = high - atr;
               }
               else{
                  trailing = low + atr;
               }
            }
            else if((trade == 3 || trade == 4) && ((trade == 3 && news == 1) || (((-(low - price) >= (atr * 1.5) || (trade == 4 && high == trailing) || ind1Value != 1 || baselineValue != 1 /*|| exitValue != 1*/) && isBuy == true) 
            || (((high - price) >= (atr * 1.5) || (trade == 4 && low == trailing) || ind1Value != -1 || baselineValue != -1 /*|| exitValue != -1*/) && isBuy == false)))){
               EndTrade();
               if((baselineValue == 1 && isBuy == true) || (baselineValue == -1 && isBuy == false)){
                  trade = 2;
               }
               else{
                  trade = 0;
               }
            }
            
            if(trade == 2){
               if((baselineValue == -1 && isBuy == true) || (baselineValue == 1 && isBuy == false)){
                  trade = 0;
               }
               else if(baselineValue == ind1Value /*&& baselineValue == ind2Value*/ && news == 0){
                  MakeTrade();
               }
            }
            else if(trade == 0 || trade == 1){
               if((ind1Value == -1 && isBuy == true) || (ind1Value == 1 && isBuy == false)){
                  trade = 0;
               }
               if(ind1Value != 0 && news == 0){
                  if(ind1Value == 1){
                     isBuy = true;
                  }
                  else{
                     isBuy = false;
                  }
                  if(ind1Value == baselineValue /*&& ind1Value == ind2Value && ind1Value == volumeValue*/ /*&& baselineValue2 != 0*/){
                     MakeTrade();
                  }
                  else if(trade == 1){
                     if(ind1Handle + 1 < ind1Length){
                        for(int a = symHandle; a < symLength; a++){
                           if(ind1Time == sym.time[a]){
                              symHandle = a;
                              trade = 0;
                              break;
                           }
                        }
                     }
                     else{
                        break;
                     }
                  }
                  else{
                     trade = 1;
                  }
               }
            }
         }
         
         int winpercent = 0;
         if((win + loss + even) != 0){
            winpercent = (int)((win * 1./ (win + loss + even)) * 100);
         }
         SetFiles (ind1[i].filename, baseline[j].filename, "", "", "", win + loss + even, winpercent);
      }
      if(i%10==0){
         Print(i);
      }
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

void GetFiles(Indicators &ind[], int numofvalues, string current_directory, bool isFiles){
   string file_name;
   int lastsize = 0;
   long search_handle=FileFindFirst(current_directory + "*", file_name); 
   
   if(search_handle!=INVALID_HANDLE){ 
      do{
         if(FileIsExist(current_directory + file_name) == isFiles){
            string str[];
            int size = ArraySize(ind);
            
            FileToStrings(current_directory + file_name, str);
            
            ArrayResize(ind, ArraySize(ind) + 1);
            ArrayResize(ind[size].time, ArraySize(str) / numofvalues);
            ArrayResize(ind[size].value, ArraySize(str) / numofvalues);
            if(numofvalues == 3){
               ArrayResize(ind[size].value2, ArraySize(str) / numofvalues);
            }
            
            ind[size].filename = file_name;
            ind[size].length = ArraySize(str) / numofvalues;
            for(int i = 0; i < ArraySize(str) / numofvalues; i++){
               ind[size].time[i] = StringToTime(str[i * numofvalues]);
               ind[size].value[i] = (int) StringToInteger(str[i * numofvalues + 1]);
               if(numofvalues == 3){
                  ind[size].value2[i] = (int) StringToInteger(str[i * numofvalues + 2]);
               }
            }
         }
      } 
      while(FileFindNext(search_handle,file_name)); 
      FileFindClose(search_handle); 
   } 
   else {
      Comment("Files not found!");
   }
}

void GetPairs(Pairs &ind, string current_directory){
   string str[];
   string p = StringSubstr(current_directory, StringLen(current_directory) - 8, 7);
   FileToStrings(current_directory + p + "\\" + p + ".CSV", str);
   
   ArrayResize(ind.time, ArraySize(str) / 8);
   ArrayResize(ind.open, ArraySize(str) / 8);
   ArrayResize(ind.close, ArraySize(str) / 8);
   ArrayResize(ind.high, ArraySize(str) / 8);
   ArrayResize(ind.low, ArraySize(str) / 8);
   ArrayResize(ind.volume, ArraySize(str) / 8);
   ArrayResize(ind.atr, ArraySize(str) / 8);
   ArrayResize(ind.news, ArraySize(str) / 8);
   
   ind.length = ArraySize(str) / 8;
   for(int i = 0; i < ArraySize(str) / 8; i++){
      ind.time[i] = StringToTime(str[i * 8]);
      ind.open[i] = StringToDouble(str[i * 8 + 1]);
      ind.close[i] = StringToDouble(str[i * 8 + 2]);
      ind.high[i] = StringToDouble(str[i * 8 + 3]);
      ind.low[i] = StringToDouble(str[i * 8 + 4]);
      ind.volume[i] = (int) StringToInteger(str[i * 8 + 5]);
      ind.atr[i] = StringToDouble(str[i * 8 + 6]);
      ind.news[i] = (int) StringToInteger(str[i * 8 + 7]);
   }
}

void SetFiles (string ind1Name, string baselineName, string exitName, string volumeName, string ind2Name, int total, int winpercent){
   string outputData = "";
   double totalpips = (pipswon - pipslost) * 10000;
   double avgwin = 0;
   double avgloss = 0;
   double expectancy = 0;
   double roi = 0;
   //double sd = totalpips / total;
   
   if(win != 0){
      avgwin = pipswon / win * 10000;
   }
   if(loss != 0){
      avgloss = pipslost / loss * 10000;
      expectancy = (1 + avgwin / avgloss) * winpercent - 100;
      //roi = expectancy * risk / 100 * total / months;
      roi = (MathPow(acc_size / accountsize, 1 / months) - 1) * 100;
   }
   
   outputData = ind1Name + "," + baselineName + "," + exitName + "," + volumeName + "," + ind2Name + "," + IntegerToString(win) + "," + IntegerToString(loss) + "," + IntegerToString(even);
   outputData += "," + IntegerToString(total) + "," + DoubleToString(totalpips) + "," + DoubleToString(acc_size) + "," + IntegerToString(maxdd) + "," + DoubleToString(avgwin);
   outputData += "," + DoubleToString(avgloss) + "," + DoubleToString(expectancy) + "," + DoubleToString(roi) /*+ "," + DoubleToString(sd)*/ + "," + IntegerToString(winpercent);
   outputData += "\n";

   FileWriteString(fileHandle, outputData);
}

void ResetVariables(){
   value = 0;
   trade = news = 0;

   win = loss = even = dd = maxdd = 0;
   isBuy = isdd = false;
   pipswon = pipslost = pips = price = trailing = lots = atr = 0;
   acc_size = dd_low = dd_high = accountsize;
   
   currprice = high = low = curratr = 0;
   symTime = ind1Time = ind2Time = baselineTime = volumeTime = exitTime = 0;
   ind1Value = ind2Value = baselineValue = baselineValue2 = volumeValue = exitValue = 0;
   symHandle = symLength = ind1Handle = ind1Length = ind2Handle = ind2Length = baselineHandle = baselineLength = volumeHandle = volumeLength = exitHandle = exitLength = 0;
}

void MakeTrade(){
   trade = 3;
   price = currprice;
   atr = curratr;
   lots = ((acc_size * risk / 100) / (atr * 10000 * 1.5));
   if(ind1Value == 1){
      isBuy = true;
   }
   else if(ind1Value == -1){
      isBuy = false;
   }
}

void EndTrade(){
   trade = 0;
   if(isBuy == true){
      pips = (currprice - price);
   }
   else{
      pips = -(currprice - price);
   }
   acc_size += (pips * 10000) * lots;
   if(pips > 0){
      win++;
      pipswon += pips;
      if(isdd == false){
         dd_high = dd_low = acc_size;
      }
      else if(dd_high <= acc_size){
         isdd = false;
         dd = int(((dd_high - dd_low) / dd_high) * 100);
         if(dd > maxdd){
            maxdd = dd;
         }
      }
   }
   else if(pips < 0){
      loss++;
      pipslost -= pips;
      isdd = true;
      if(dd_low > acc_size){
         dd_low = acc_size;
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
