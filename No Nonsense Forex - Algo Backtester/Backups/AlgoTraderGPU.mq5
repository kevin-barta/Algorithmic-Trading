//+------------------------------------------------------------------+
//|                                          Export Indicator Values |
//+------------------------------------------------------------------+
#property description "This Script Export Indicators Values to CSV File."
#property description "(You can change the iCustom function parameters to change what indicator to export)"
#property copyright "NFTrader"
#property version   "2.00"
#property script_show_inputs

#resource "AlgoTrader.cl" as string cl_src

string files[], pairs[], indicators[];

long pairsTime[], indicatorsTime[];
double pairsDouble[];
int indicatorsLoc[], indicatorsInt[];

int fileHandle;

struct output {
    int indicators[5];
    int win;
    int loss;
    int even;
    int totaltrades;
    //float totalpips;
    //float balance;
    //int maxdd;
    //int winpercent;
    //int incr_winpercent;
    int ind1handle;
    int symhandle;
    int ind1date;
    int symdate;
    float currprice;
    float high;
    float low;
    float curratr;
    //bool inTrade;
};

output results[];

int accountsize = 1000;
int risk = 2;


double value;
int action, action1, action2;
int win, loss, even, winpercent, dd, maxdd;
bool inTrade = false, isBuy = false, isdd = false;
double totalpips = 0, pips = 0, dd_low = 0, dd_high = 0, acc_size = 0, acc_size1 = 0, price = 0, atr = 0, atr1 = 0;
double currprice = 0, high = 0, low = 0, curratr = 0;

bool wantATRmanaged = true;

uint totaltime;

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart(){
   uint start=GetTickCount();
   string current_directory = "AlgoTrading\\D1_GBPNZD+\\";
   string filename = "AlgoTrading\\D1_GBPNZD+\\GBPNZD+\\GBPNZD+.CSV";
   fileHandle = FileOpen("AlgoTrading\\output.CSV",FILE_WRITE|FILE_ANSI|FILE_CSV);
   FileWriteString(fileHandle, "ID,Indicator 1,Wins,Losses,Breakeven,TotalTrades,TotalPips,Balance,MaxDD,Win %,Prev ID,Indicator 2,Wins,Losses,Breakeven,TotalTrades,TotalPips,Balance,MaxDD,Win %,Increased Win %\n");
   GetFiles(current_directory, true);
   FileToStrings(filename, pairs);
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
   ArrayResize(results, (ArraySize(indicatorsLoc) / 4) * (ArraySize(indicatorsLoc) / 2));
   WithOpenCL();
   
   Print(GetTickCount() - start);
   FileClose(fileHandle);
}

void WithOpenCL(){
  //--- variables for using OpenCL
   int cl_ctx;
   int cl_prg;
   int cl_krn_1;
   int cl_mem_1;
   int cl_mem_2;
   int cl_mem_3;
   int cl_mem_4;
   int cl_mem_5;
   int cl_mem_6;
   string debug;
//--- create context for OpenCL (selection of device)
   if((cl_ctx = CLContextCreate(CL_USE_ANY)) == INVALID_HANDLE){
      Print("OpenCL not found");
      return;
   }
//--- create a program based on the code in the cl_src line
   if((cl_prg = CLProgramCreate(cl_ctx, cl_src, debug))==INVALID_HANDLE){
      CLContextFree(cl_ctx);
      Print("OpenCL program create failed");
      Print(debug);
      return;
   }
//--- create a kernel for calculation of values of the function of two variables
   if((cl_krn_1 = CLKernelCreate(cl_prg, "CompareIndicators")) == INVALID_HANDLE){
      CLProgramFree(cl_prg);
      CLContextFree(cl_ctx);
      Print("OpenCL kernel_1 create failed");
      return;
   }
//--- OpenCL buffer for function 
   if((cl_mem_1 = CLBufferCreate(cl_ctx, sizeof(results) * ArraySize(results), CL_MEM_READ_WRITE)) == INVALID_HANDLE){
      CLKernelFree(cl_krn_1);
      CLProgramFree(cl_prg);
      CLContextFree(cl_ctx);
      Print("OpenCL buffer create failed");
      return;
   }
   if((cl_mem_2 = CLBufferCreate(cl_ctx, sizeof(int) * ArraySize(indicatorsLoc), CL_MEM_READ_WRITE)) == INVALID_HANDLE){
      CLBufferFree(cl_mem_1);
      CLKernelFree(cl_krn_1);
      CLProgramFree(cl_prg);
      CLContextFree(cl_ctx);
      Print("OpenCL buffer create failed");
      return;
   }
   if((cl_mem_3 = CLBufferCreate(cl_ctx, sizeof(long) * ArraySize(pairsTime), CL_MEM_READ_WRITE)) == INVALID_HANDLE){
      CLBufferFree(cl_mem_2);
      CLBufferFree(cl_mem_1);
      CLKernelFree(cl_krn_1);
      CLProgramFree(cl_prg);
      CLContextFree(cl_ctx);
      Print("OpenCL buffer create failed");
      return;
   }
   if((cl_mem_4 = CLBufferCreate(cl_ctx, sizeof(long) * ArraySize(indicatorsTime), CL_MEM_READ_WRITE)) == INVALID_HANDLE){
      CLBufferFree(cl_mem_3);
      CLBufferFree(cl_mem_2);
      CLBufferFree(cl_mem_1);
      CLKernelFree(cl_krn_1);
      CLProgramFree(cl_prg);
      CLContextFree(cl_ctx);
      Print("OpenCL buffer create failed");
      return;
   }
   if((cl_mem_5 = CLBufferCreate(cl_ctx, sizeof(double) * ArraySize(pairsDouble), CL_MEM_READ_WRITE)) == INVALID_HANDLE){
      CLBufferFree(cl_mem_4);
      CLBufferFree(cl_mem_3);
      CLBufferFree(cl_mem_2);
      CLKernelFree(cl_krn_1);
      CLProgramFree(cl_prg);
      CLContextFree(cl_ctx);
      Print("OpenCL buffer create failed");
      return;
   }
   if((cl_mem_6 = CLBufferCreate(cl_ctx, sizeof(int) * ArraySize(indicatorsInt), CL_MEM_READ_WRITE)) == INVALID_HANDLE){
      CLBufferFree(cl_mem_5);
      CLBufferFree(cl_mem_4);
      CLBufferFree(cl_mem_3);
      CLBufferFree(cl_mem_2);
      CLKernelFree(cl_krn_1);
      CLProgramFree(cl_prg);
      CLContextFree(cl_ctx);
      Print("OpenCL buffer create failed");
      return;
   }
//--- array sets indices at which the calculation will start  
   uint offset[2] = {0,0};
//--- array sets limits up to which the calculation will be performed
   uint work[2];
   work[0] = 1;
   work[1] = 1;
//--- write the values to the buffer
   CLBufferWrite(cl_mem_2, indicatorsLoc);
   CLBufferWrite(cl_mem_3, pairsTime);
   CLBufferWrite(cl_mem_4, indicatorsTime);
   CLBufferWrite(cl_mem_5, pairsDouble);
   CLBufferWrite(cl_mem_6, indicatorsInt);
//--- pass the values to the kernel
   CLSetKernelArgMem(cl_krn_1, 0, cl_mem_1);
   CLSetKernelArgMem(cl_krn_1, 1, cl_mem_2);
   CLSetKernelArgMem(cl_krn_1, 2, cl_mem_3);
   CLSetKernelArgMem(cl_krn_1, 3, cl_mem_4);
   CLSetKernelArgMem(cl_krn_1, 4, cl_mem_5);
   CLSetKernelArgMem(cl_krn_1, 5, cl_mem_6);
   CLSetKernelArg(cl_krn_1, 6, ArraySize(pairsTime) - 1);
//--- start the execution of the kernel
   CLExecute(cl_krn_1, 2, offset, work);
//--- read the obtained values to the array
   CLBufferRead(cl_mem_1, results);
   CLBufferFree(cl_mem_6);
   CLBufferFree(cl_mem_5);
   CLBufferFree(cl_mem_4);
   CLBufferFree(cl_mem_3);
   CLBufferFree(cl_mem_2);
   CLBufferFree(cl_mem_1);
   CLKernelFree(cl_krn_1);
   CLProgramFree(cl_prg);
   CLContextFree(cl_ctx);
   printf(1);
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
            int loc[2];
            FileToStrings(current_directory + file_name, str);
            ArrayCopy(indicators, str, ArraySize(indicators));
            str1[0] = file_name;
            str1[1] = IntegerToString(lastsize);
            str1[2] = IntegerToString(ArraySize(indicators) / 2 - 1);
            loc[0] = lastsize;
            loc[1] = ArraySize(indicators) / 2 - 1;
            lastsize = ArraySize(indicators) / 2;
            ArrayCopy(files, str1, ArraySize(files));
            ArrayCopy(indicatorsLoc, loc, ArraySize(indicatorsLoc));
         }
      } 
      while(FileFindNext(search_handle,file_name)); 
      FileFindClose(search_handle); 
   } 
   else {
      Comment("Files not found!");
   }
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