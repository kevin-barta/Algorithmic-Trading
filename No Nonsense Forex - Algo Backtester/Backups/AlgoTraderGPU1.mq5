//+------------------------------------------------------------------+
//|                                          Export Indicator Values |
//+------------------------------------------------------------------+
#property description "This Script Export Indicators Values to CSV File."
#property description "(You can change the iCustom function parameters to change what indicator to export)"
#property copyright "NFTrader"
#property version   "2.00"
#property script_show_inputs

#resource "AlgoTrader.cl" as string cl_src

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

struct output {
   int ind1;
   int ind2;
   int baseline;
   int volume;
   int exit;
   int win;
   int loss;
   int even;
   float acc_size;
   float maxdd;
   float pipswon;
   float pipslost;
   output() {
	   ind1 = ind2 = baseline = volume = exit = -1;
	   win = loss = even = 0;
	   acc_size = 1000;
	   maxdd = pipswon = pipslost = 0;
   }
};

const int month = 2628000;
int accountsize = 1000;
int risk = 2;

datetime Indicatortime[];
int Indicatorvalue[];
int Indicatorvalue2[];
int Indicatorcount[];
int Indicatorstart[];
datetime Pairstime[];
float Pairsclose[];
float Pairshigh[];
float Pairslow[];
float Pairsatr[];
int Pairsnews[];
int Pairslength;

Pairs sym;
Indicators ind1[], ind2[], baseline[], volume[], exit[];
output results[];

double value, months;
int trade, news;
int win, loss, even, dd, maxdd;
bool isBuy = false, isdd = false;
double pips = 0, pipswon = 0, pipslost = 0, dd_low = 0, dd_high = 0, acc_size = 0, price = 0, trailing = 0, lots = 0, atr = 0;
double currprice = 0, high = 0, low = 0, curratr = 0;
datetime symTime, ind1Time, ind2Time, baselineTime, volumeTime, exitTime;
int ind1Value, ind2Value, baselineValue, baselineValue2 , volumeValue, exitValue;
int symHandle, symLength, ind1Handle, ind1Length, ind2Handle, ind2Length, baselineHandle, baselineLength, volumeHandle, volumeLength, exitHandle, exitLength;

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart(){
   //uint start=GetTickCount();
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
   
   uint start=GetTickCount();
   WithOpenCL(200000);
   
   Print(GetTickCount() - start);
   FileClose(fileHandle);
}

void WithOpenCL(int results_size){
  //--- variables for using OpenCL
   int cl[];
   string debug;
   ArrayResize(results, results_size);
   for(int i = 0; i < ArraySize(ind1); i++){
      results[i].ind1 = i;
   }
   
//--- create context for OpenCL (selection of device)
   ArrayResize(cl, ArraySize(cl) + 1);
   if((cl[0] = CLContextCreate(CL_USE_ANY)) == INVALID_HANDLE){
      Print("OpenCL not found");
      return;
   }
//--- create a program based on the code in the cl_src line
   ArrayResize(cl, ArraySize(cl) + 1);
   if((cl[1] = CLProgramCreate(cl[0], cl_src, debug))==INVALID_HANDLE){
      CLFree(cl);
      Print("OpenCL program create failed");
      Print(debug);
      return;
   }
//--- create a kernel for calculation of values of the function of two variables
   ArrayResize(cl, ArraySize(cl) + 1);
   if((cl[2] = CLKernelCreate(cl[1], "CompareIndicators")) == INVALID_HANDLE){
      CLFree(cl);
      Print("OpenCL kernel_1 create failed");
      return;
   }
   CLVariables(cl, sizeof(results) * ArraySize(results));
   CLVariables(cl, sizeof(datetime) * ArraySize(Indicatortime));
   CLBufferWrite(cl[ArraySize(cl) - 1], Indicatortime);
   CLVariables(cl, sizeof(int) * ArraySize(Indicatorvalue));
   CLBufferWrite(cl[ArraySize(cl) - 1], Indicatorvalue);
   CLVariables(cl, sizeof(int) * ArraySize(Indicatorvalue2));
   CLBufferWrite(cl[ArraySize(cl) - 1], Indicatorvalue2);
   CLVariables(cl, sizeof(int) * ArraySize(Indicatorcount));
   CLBufferWrite(cl[ArraySize(cl) - 1], Indicatorcount);
   CLVariables(cl, sizeof(int) * ArraySize(Indicatorstart));
   CLBufferWrite(cl[ArraySize(cl) - 1], Indicatorstart);
   CLVariables(cl, sizeof(datetime) * ArraySize(Pairstime));
   CLBufferWrite(cl[ArraySize(cl) - 1], Pairstime);
   CLVariables(cl, sizeof(float) * ArraySize(Pairsclose));
   CLBufferWrite(cl[ArraySize(cl) - 1], Pairsclose);
   CLVariables(cl, sizeof(float) * ArraySize(Pairshigh));
   CLBufferWrite(cl[ArraySize(cl) - 1], Pairshigh);
   CLVariables(cl, sizeof(float) * ArraySize(Pairslow));
   CLBufferWrite(cl[ArraySize(cl) - 1], Pairslow);
   CLVariables(cl, sizeof(float) * ArraySize(Pairsatr));
   CLBufferWrite(cl[ArraySize(cl) - 1], Pairsatr);
   CLVariables(cl, sizeof(int) * ArraySize(Pairsnews));
   CLBufferWrite(cl[ArraySize(cl) - 1], Pairsnews);
   CLSetKernelArg(cl[2], ArraySize(cl) - 3, Pairslength);
//--- array sets indices at which the calculation will start  
   uint offset[3] = {0, 0, 0};
//--- array sets limits up to which the calculation will be performed
   uint work[3];
   work[0] = ArraySize(ind1);
   work[1] = 1;
   work[2] = 1;
//--- start the execution of the kernel
   for(int j = 0; j < 10; j++){
      offset[2] = j;
      for(int i = 0; i < ArraySize(baseline); i++){
         offset[1] = i;
         CLExecute(cl[2], 3, offset, work);
      }
   }
//--- read the obtained values to the array
   CLBufferRead(cl[3], results);
   CLFree(cl);
   Print(1);
}

void CLVariables(int &cl[], int size){
   //--- OpenCL buffer for function 
   ArrayResize(cl, ArraySize(cl) + 1);
   if((cl[ArraySize(cl) - 1] = CLBufferCreate(cl[0], size, CL_MEM_READ_WRITE)) == INVALID_HANDLE){
      CLFree(cl);
      Print("OpenCL buffer create failed");
      return;
   }
   //--- pass the values to the kernel
   CLSetKernelArgMem(cl[2], ArraySize(cl) - 4, cl[ArraySize(cl) - 1]);
}

void CLFree(int &cl[]){
   for(int i = ArraySize(cl) - 1; i >= 0; i--){
      if(i == 0){
         CLContextFree(cl[0]);
      }
      else if(i == 1){
         CLProgramFree(cl[1]);
      }
      else if(i == 2){
         CLKernelFree(cl[2]);
      }
      else{
         CLBufferFree(cl[i]);
      }
   }
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
   int lvalue = 0;
   int lvalue2 = 0;
   if(ArraySize(Indicatorstart) == 0){     
      ArrayResize(Indicatorstart, 1);
      ArrayResize(Indicatorcount, 1);
      Indicatorstart[0] = 0;
      Indicatorcount[0] = 0;
   }
   else{
      lvalue = lvalue2 = Indicatorcount[Indicatorstart[ArraySize(Indicatorstart) - 1]];
   }
   long search_handle=FileFindFirst(current_directory + "*", file_name); 
   if(search_handle!=INVALID_HANDLE){ 
      do{
         if(FileIsExist(current_directory + file_name) == isFiles){
            string str[];
            int size = ArraySize(ind);
            
            FileToStrings(current_directory + file_name, str);
            
            ArrayResize(ind, size + 1);
            ArrayResize(ind[size].time, ArraySize(str) / numofvalues);
            ArrayResize(Indicatortime, lvalue + ArraySize(str) / numofvalues);
            ArrayResize(ind[size].value, ArraySize(str) / numofvalues);
            ArrayResize(Indicatorvalue, lvalue + ArraySize(str) / numofvalues);
            if(numofvalues == 3){
               ArrayResize(ind[size].value2, ArraySize(str) / numofvalues);
               ArrayResize(Indicatorvalue2, lvalue - lvalue2 + ArraySize(str) / numofvalues);
            }
            
            ind[size].filename = file_name;
            ind[size].length = ArraySize(str) / numofvalues;
            for(int i = 0; i < ArraySize(str) / numofvalues; i++){
               ind[size].time[i] = StringToTime(str[i * numofvalues]);
               Indicatortime[lvalue + i] = StringToTime(str[i * numofvalues]);
               ind[size].value[i] = (int) StringToInteger(str[i * numofvalues + 1]);
               Indicatorvalue[lvalue + i] = (int) StringToInteger(str[i * numofvalues + 1]);
               if(numofvalues == 3){
                  ind[size].value2[i] = (int) StringToInteger(str[i * numofvalues + 2]);
                  Indicatorvalue2[lvalue - lvalue2 + i] = (int) StringToInteger(str[i * numofvalues + 2]);
               }
            }
            
            lvalue += ArraySize(str) / numofvalues;
            ArrayResize(Indicatorcount, ArraySize(Indicatorcount) + 1);
            Indicatorcount[ArraySize(Indicatorcount) - 1] = lvalue;
         }
      } 
      while(FileFindNext(search_handle,file_name)); 
      FileFindClose(search_handle);
      
      ArrayResize(Indicatorstart, ArraySize(Indicatorstart) + 1);
      Indicatorstart[ArraySize(Indicatorstart) - 1] = ArraySize(Indicatorcount) - 1;
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
   
   Pairslength = ind.length;
   
   ArrayResize(Pairstime, Pairslength);
   ArrayResize(Pairsclose, Pairslength);
   ArrayResize(Pairshigh, Pairslength);
   ArrayResize(Pairslow, Pairslength);
   ArrayResize(Pairsatr, Pairslength);
   ArrayResize(Pairsnews, Pairslength);
   
   ArrayCopy(Pairstime, ind.time);
   ArrayCopy(Pairsclose, ind.close);
   ArrayCopy(Pairshigh, ind.high);
   ArrayCopy(Pairslow, ind.low);
   ArrayCopy(Pairsatr, ind.atr);
   ArrayCopy(Pairsnews, ind.news);
}

/*void SetFiles (int depth, int id, string indicator, int wins, int losses, int breakeven, int total, double totalPips, int winpercent1, int incr_winpercent){
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
}*/
//+------------------------------------------------------------------+