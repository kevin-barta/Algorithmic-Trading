//+------------------------------------------------------------------+
//|                                               AlgoBacktester.mq5 |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property script_show_inputs

#resource "AlgoTrader.cl" as string cl_src

//--- Testmode
enum testmode {
   algo_test = 0, // Algo Test 
   repaint_test = 1, // Repaint Test
 };
 
  //--- Metrics
 enum metrics {
   none = 0, // None
   roi = 1, // Total Return (ROI)
   maxdd = 2, // Max Drawdown
 };
 
 
 //--- Compare
 enum compare {
   gr_eq = 0, // Greater Than or Equal To
   ls_eq = 1, // Less Than or Equal To
   eq = 2, // Equal To
   ls = 3, // Less Than
   gr = 4, // Greater Than
 };
 
//--- input parameters
input testmode swapmode = algo_test; // Test Mode
input string period = "H4"; // Test Period

input string s1 = "========================================================================================================"; // ============ Indicators ============
input string baseline_n; // Baseline
input string ind1_n; // Main Confirmation (C1)
input string ind2_n; // 2nd Confirmation (C2)
input string volume_n; // Volume
input string exit_n; // Exit

input string s2 = "========================================================================================================"; // ============ Indicators Parameters ============
input string baseline_p; // Baseline
input string ind1_p; // Main Confirmation (C1)
input string ind2_p; // 2nd Confirmation (C2)
input string volume_p; // Volume
input string exit_p; // Exit

input string s3 = "========================================================================================================"; // ============ Active Entries/Rules ============
input bool st_entry = true; // Standard Entry
input bool bl_entry = true; // Baseline Entry
input bool cont_entry = true; // Continuation Entry
input bool pull_entry = true; // Pullback Entry
input float bl_retrace = 1; // Within x ATR of Baseline
input bool onecandle_rule = true; // One Candle Rule
input bool bridge_rule = true; // Bridge To Far Rule
input int bridge_candles = 7; // Bridge To Far Candles

input string s4 = "========================================================================================================"; // ============ Money Management ============
input float atr_tp = 1; // x ATR for TP
input float atr_sl = 1.5; // x ATR for SL
input float atr_slbr = 1; // x ATR for SL->BE 
input float atr_ts = 2; // x ATR for SL->TS
input float risk = 2; // Risk (%) per Entry
input string s5 = "========================================================================================================"; // ============ Testing Parameters ============
input float oos = 25; // Out of Sample Percent

input string s6 = "========================================================================================================"; // ============ Report ============
input metrics mt1; // Metric 1
input compare cm1; // Compare 1
input float val1; // Value 1
input metrics mt2; // Metric 2
input compare cm2; // Compare 2
input float val2; // Value 2
input metrics mt3; // Metric 3
input compare cm3; // Compare 3
input float val3; // Value 3



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
   int vol[];
   double atr[];
   int news[];
   int length;
   Indicators ind1[], ind2[], baseline[], volume[], exit[];
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
   float return_rate;
   float maxdd;
   float pipswon;
   float pipslost;
   float exit_rate;
   float news_rate;
   float std;
   float sharpe; 
   float sortino;
   int win1;
   int loss1;
   int even1;
   float acc_size1;
   float return_rate1;
   float maxdd1;
   float pipswon1;
   float pipslost1;
   float exit_rate1;
   float news_rate1;
   output() {
	   ind1 = ind2 = baseline = volume = exit = -1;
	   win = win1 = loss = loss1 = even = even1 = 0;
	   acc_size = acc_size1 = 1000;
	   return_rate = return_rate1 = 0;
	   maxdd = maxdd1 = pipswon = pipswon1 = pipslost = pipslost1 = 0;
   }
};

string sSymbol[] = {"GBPNZD+", "EUR/USD+", "AUD/NZD+", "EUR/GBP+", "AUD/CAD+", "CHF/JPY+"};

const int month = 2628000;
int accountsize = 1000;
//int risk = 2;

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
float pip_size;

Pairs pair[];
//Indicators ind1[], ind2[], baseline[], volume[], exit[];////////////////////////////////////////////
output results[], temp[], queue[], queue1[];

double value, months;

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart(){

   bool err = false;
   
   //--- Loop through all symbols and import the pair and indicator data
   for(int i = 0; i < ArraySize(sSymbol); i++){
      string current_directory = "AlgoTrading\\" + period + "_" + sSymbol[i] + "\\";
   
      GetPairs(pair[i], current_directory);
   
      GetFiles(pair[i].ind1, 2, current_directory + "Confirmation\\", true);
      GetFiles(pair[i].ind2, 2, current_directory + "Confirmation2\\", true);
      GetFiles(pair[i].baseline, 3, current_directory + "Baseline\\", true);
      GetFiles(pair[i].volume, 2, current_directory + "Volume\\", true);
      GetFiles(pair[i].exit, 2, current_directory + "Exit\\", true);
      if(i != 0 && (ArraySize(pair[i - 1].ind1) != ArraySize(pair[i].ind1) || 
         ArraySize(pair[i - 1].ind2) != ArraySize(pair[i].ind2) ||
         ArraySize(pair[i - 1].baseline) != ArraySize(pair[i].baseline) ||
         ArraySize(pair[i - 1].volume) != ArraySize(pair[i].volume) ||
         ArraySize(pair[i - 1].exit) != ArraySize(pair[i].exit))){
         
         Print("Some pairs are missing indicator settings " + sSymbol[i]);
         err = true;
         break;
      }
   }
   if(err == false){
      //using first pair for time length
      months = (pair[0].time[pair[0].length - 1] - pair[0].time[0]) * 1.0 / month;
/******//* Fix for JPY pairs (sSymbol[0]) */ pip_size = (float) SymbolInfoDouble(sSymbol[0], SYMBOL_POINT) * 10;
      WithOpenCL(200000, 5000);
   }
}

//+------------------------------------------------------------------+
//| Main OPENCL function                                             |
//| Runs all calulations on GPU and returns results                  |
//+------------------------------------------------------------------+
void WithOpenCL(int results_size, int CL_size){
  //--- variables for using OpenCL
   int cl[];
   string debug;
   
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
   CLVariables(cl, sizeof(results) * CL_size);
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
   CLSetKernelArg(cl[2], ArraySize(cl) - 2, pip_size);
   
//--- array sets indices at which the calculation will start  
   uint offset[1] = {0};
//--- array sets limits up to which the calculation will be performed
   uint work[1];
   work[0] = CL_size;
   
//--- setup ind1 results array to work with GPU buffer calculations
   ArrayResize(results, results_size, results_size / 2);
   for(int i = 0; i < ArraySize(pair[0].ind1); i++){
      results[i].ind1 = i;
   }
   
   int ind_length = 0;
   int q_length = 0;
   int results_length = 0;
//--- setup and run all the work for the GPU using a buffer
   for(int i = 0; i < 4; i++){
      results_length = results_size;
      ArrayCopy(temp, results);
      if(i == 0){
         ind_length = ArraySize(pair[0].baseline);
      }
      else if(i == 1){
         ind_length = ArraySize(pair[0].exit);
      }
      else if(i == 2){
         ind_length = ArraySize(pair[0].volume);
      }
      else if(i == 3){
         ind_length = ArraySize(pair[0].ind2);
      }
      for(int j = 0; j < results_size; j++){
         if((i == 0 && temp[j].ind1 != -1) || (i == 1 && temp[j].ind1 != -1 && temp[j].baseline != -1) || (i == 2 && temp[j].ind1 != -1 && temp[j].baseline != -1 && temp[j].exit != -1)
         || (i == 3 && temp[j].ind1 != -1 && temp[j].baseline != -1 && temp[j].exit != -1 && temp[j].volume != -1)){
            ArrayResize(queue, q_length + ind_length);
            for(int k = 0; k < ind_length; k++){
               queue[q_length + k] = temp[j];
               if(i == 0){
                  queue[q_length + k].baseline = k;
               }
               else if(i == 1){
                  queue[q_length + k].exit = k;
               }
               else if(i == 2){
                  queue[q_length + k].volume = k;
               }
               else if(i == 3){
                  queue[q_length + k].ind2 = k;
               }
            }
            q_length += ind_length;
            while(q_length >= CL_size){
               CLRun(cl, offset, work, CL_size, results_size, results_length, q_length);
            }
         }
         if(j % 1000 == 0){
            printf("%d %d",i, j);
         }
      }
//--- final run for the rest of the work in the buffer
      if(q_length != 0){
         CLRun(cl, offset, work, q_length, results_size, results_length, q_length);
      } 
//--- final sort for this computation
      mergeSort(results, 0, results_length - 1);
      for(int j = 1; j < results_length; j++){
         if(results[j - 1].return_rate == results[j].return_rate && results[j - 1].maxdd == results[j].maxdd){
            results[j - 1].return_rate = 0;
         }
      }
      mergeSort(results, 0, results_length - 1);
      ArrayResize(results, results_size);
   }
   
//--- free all the GPU memory 
   CLFree(cl);
}

//+------------------------------------------------------------------+
//| Runs the OPENCL workload and outputs the results                 |
//+------------------------------------------------------------------+
void CLRun(int &cl[], uint &offset[], uint &work[], int CL_size, int &results_size, int &results_length, int &q_length){
   q_length -= CL_size;
   ArrayCopy(queue1, queue, 0, q_length, CL_size);
   ArrayResize(queue, q_length);
   CLBufferWrite(cl[3], queue1);
   //ArrayFree(queue1);
            
   CLExecute(cl[2], 1, offset, work);
   CLBufferRead(cl[3], queue1);
   for(int j = 0; j < CL_size; j++){
      if(queue1[j].return_rate > results[results_size - 1].return_rate && queue1[j].return_rate / 2 < queue1[j].return_rate1){
         results_length++;
         ArrayResize(results, results_length);
         results[results_length - 1] = queue1[j];
               
         if(results_size * 1.5 == results_length){
            mergeSort(results, 0, results_length - 1);
            for(int i = 1; i < results_length; i++){
               if(results[i - 1].return_rate == results[i].return_rate && results[i - 1].maxdd == results[i].maxdd){
                  results[i - 1].return_rate = 0;
               }
            }
            mergeSort(results, 0, results_length - 1);
            ArrayResize(results, results_size);
            results_length = results_size;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Create new memory buffer for the OPENCL program                  |
//+------------------------------------------------------------------+
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

//+------------------------------------------------------------------+
//| Free the OPENCL program resources                                |
//+------------------------------------------------------------------+
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

//+------------------------------------------------------------------+
//| Merge sort algorithm                                             |
//+------------------------------------------------------------------+
void mergeSort(output &arr[], int l, int r){
   if(l < r){
      int m = (l + r) / 2;
      mergeSort(arr, l, m);
      mergeSort(arr, m + 1, r);
      
      merge(arr, l, m, r);
   }
   
   return;
}

//+------------------------------------------------------------------+
//| Merge sort algorithm helper                                      |
//+------------------------------------------------------------------+
void merge(output &arr[], int l, int m, int r){
   int i, j, k; 
   int n1 = m - l + 1;
   int n2 = r - m;
  
   output L[], R[];
   ArrayResize(L, n1);
   ArrayResize(R, n2);
  
   for(i = 0; i < n1; i++){
      L[i] = arr[l + i];
   }
   for(j = 0; j < n2; j++){
      R[j] = arr[m + 1+ j]; 
   }
  
   i = 0;
   j = 0;
   k = l;
   while(i < n1 && j < n2){ 
      if(L[i].return_rate >= R[j].return_rate){ 
         arr[k] = L[i]; 
         i++; 
      } 
      else{ 
         arr[k] = R[j]; 
         j++;
      } 
      k++; 
   }
     
   while(i < n1){ 
      arr[k] = L[i]; 
      i++; 
      k++; 
   }
   
   while(j < n2){ 
      arr[k] = R[j]; 
      j++; 
      k++; 
   } 
}

//+------------------------------------------------------------------+
//| Import data from a file into a string array                      |
//+------------------------------------------------------------------+
void FileToStrings( const string FileName, string &Str[], bool hasHeader){
   uchar Bytes[];
   string Str1[];
   string Str2[];
   int i = 0;
   FileLoad(FileName, Bytes);
   StringSplit(CharArrayToString(Bytes), '\n', Str1);
   if(hasHeader == true){
      ArrayCopy(Str, Str1, 0, 0, 1);
      i = 1;
   }
   for(; i < ArraySize(Str1); i++){
      StringSplit(Str1[i], ',', Str2);
      ArrayCopy(Str, Str2, ArraySize(Str));
   }
}

//+------------------------------------------------------------------+
//| Import indicator data from CSV                                   |
//+------------------------------------------------------------------+
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
            int strsize;
            
            FileToStrings(current_directory + file_name, str, true);
            strsize = (ArraySize(str) - 1) / numofvalues;
            
            ArrayResize(ind, size + 1);
            ArrayResize(ind[size].time, strsize);
            ArrayResize(Indicatortime, lvalue + strsize);
            ArrayResize(ind[size].value, strsize);
            ArrayResize(Indicatorvalue, lvalue + strsize);
            if(numofvalues == 3){
               ArrayResize(ind[size].value2, strsize);
               ArrayResize(Indicatorvalue2, lvalue - lvalue2 + strsize);
            }
            
            ind[size].filename = str[0];
            ind[size].length = strsize;
            for(int i = 0; i < strsize; i++){
               ind[size].time[i] = StringToTime(str[i * numofvalues + 1]);
               Indicatortime[lvalue + i] = StringToTime(str[i * numofvalues + 1]);
               ind[size].value[i] = (int) StringToInteger(str[i * numofvalues + 2]);
               Indicatorvalue[lvalue + i] = (int) StringToInteger(str[i * numofvalues + 2]);
               if(numofvalues == 3){
                  ind[size].value2[i] = (int) StringToInteger(str[i * numofvalues + 3]);
                  Indicatorvalue2[lvalue - lvalue2 + i] = (int) StringToInteger(str[i * numofvalues + 3]);
               }
            }
            
            lvalue += strsize;
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

//+------------------------------------------------------------------+
//| Import pairs data from CSV                                       |
//+------------------------------------------------------------------+
void GetPairs(Pairs &ind, string current_directory){
   string str[];
   string p = StringSubstr(current_directory, StringLen(current_directory) - 8, 7);
   FileToStrings(current_directory + p + "\\" + p + ".CSV", str, false);
   
   ArrayResize(ind.time, ArraySize(str) / 8);
   ArrayResize(ind.open, ArraySize(str) / 8);
   ArrayResize(ind.close, ArraySize(str) / 8);
   ArrayResize(ind.high, ArraySize(str) / 8);
   ArrayResize(ind.low, ArraySize(str) / 8);
   ArrayResize(ind.vol, ArraySize(str) / 8);
   ArrayResize(ind.atr, ArraySize(str) / 8);
   ArrayResize(ind.news, ArraySize(str) / 8);
   
   ind.length = ArraySize(str) / 8;
   for(int i = 0; i < ArraySize(str) / 8; i++){
      ind.time[i] = StringToTime(str[i * 8]);
      ind.open[i] = StringToDouble(str[i * 8 + 1]);
      ind.close[i] = StringToDouble(str[i * 8 + 2]);
      ind.high[i] = StringToDouble(str[i * 8 + 3]);
      ind.low[i] = StringToDouble(str[i * 8 + 4]);
      ind.vol[i] = (int) StringToInteger(str[i * 8 + 5]);
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