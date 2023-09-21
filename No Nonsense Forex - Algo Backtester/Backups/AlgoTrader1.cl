typedef struct results {
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
}results;

typedef struct trade {
   float value;
   int trade, news;
   int win, loss, even, dd, maxdd;
   bool isBuy, isdd;
   float pipswon, pipslost, pips, price, trailing, lots, atr;
   float acc_size, dd_low, dd_high;
   float currprice, high, low, curratr;
   
   long symTime, ind1Time, ind2Time, baselineTime, volumeTime, exitTime;
   int ind1Value, ind2Value, baselineValue, baselineValue2, volumeValue, exitValue;
   int symHandle, symLength, ind1Handle, ind1Length, ind2Handle, ind2Length, baselineHandle, baselineLength, volumeHandle, volumeLength, exitHandle, exitLength;
}trade;

void ResetVariables(trade *t, int accountsize);
void MakeTrade(trade *t);
void EndTrade(trade *t);

__kernel void CompareIndicators(__global results *output, __global long Indicatortime[], __global int Indicatorvalue[], __global int Indicatorvalue2[],
 __global int Indicatorcount[], __global int Indicatorstart[], __global long Pairstime[], __global float Pairsclose[], __global float Pairshigh[], 
 __global float Pairslow[], __global float Pairsatr[], __global int Pairsnews[], int Pairslength){
   
   int accountsize = 1000;
   int risk = 2;
   struct trade t;
   
   uint  i = get_global_id(0);
   uint  j = get_global_id(1);
   uint  k = get_global_id(2);
   uint  w = get_global_size(0);
   uint  w1 = w * 714;//get_global_size(1);
   
   ResetVariables(&t, accountsize);  
   t.symLength = Pairslength;
   t.ind1Handle = Indicatorcount[i];
   t.ind1Length = Indicatorcount[i+1];
   t.baselineHandle = Indicatorcount[Indicatorstart[2]+j];
   t.baselineLength = Indicatorcount[Indicatorstart[2]+j+1];
   t.exitHandle = Indicatorcount[Indicatorstart[4]+k];
   t.exitLength = Indicatorcount[Indicatorstart[4]+k+1];
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
            t.ind1Time = Indicatortime[t.ind1Handle + 1];
         }
         t.ind1Value = Indicatorvalue[t.ind1Handle];
         t.ind1Handle++;
      }
      if(t.symTime >= t.baselineTime && t.baselineHandle < t.baselineLength){
         if(t.baselineHandle + 1 < t.baselineLength){
            t.baselineTime = Indicatortime[t.baselineHandle + 1];
         }
         t.baselineValue = Indicatorvalue[t.baselineHandle];
         t.baselineValue2 = Indicatorvalue2[t.baselineHandle];
         t.baselineHandle++;
      }
      if(t.symTime >= t.exitTime && t.exitHandle < t.exitLength){
         if(t.exitHandle + 1 < t.exitLength){
            t.exitTime = Indicatortime[t.exitHandle + 1];
         }
         t.exitValue = Indicatorvalue[t.exitHandle];
         t.exitHandle++;
      }
      
      if(t.trade == 3 && (((t.high - t.price) >= t.atr && t.isBuy == true) || (-(t.low - t.price) >= t.atr && t.isBuy == false))){
         t.trade = 4;
         if(t.isBuy == true){
            t.trailing = t.high - t.atr;
         }
         else{
            t.trailing = t.low + t.atr;
         }
      }
      else if(t.trade == 4 && (((t.high - t.atr) > t.trailing && t.isBuy == true) || ((t.low + t.atr) < t.trailing && t.isBuy == false))){
         if(t.isBuy == true){
            t.trailing = t.high - t.atr;
         }
         else{
            t.trailing = t.low + t.atr;
         }
      }
      else if((t.trade == 3 || t.trade == 4) && ((t.trade == 3 && t.news == 1) || (((-(t.low - t.price) >= (t.atr * 1.5) || (t.trade == 4 && t.high == t.trailing) || t.ind1Value != 1 || t.baselineValue != 1 /*|| exitValue != 1*/) && t.isBuy == true) 
      || (((t.high - t.price) >= (t.atr * 1.5) || (t.trade == 4 && t.low == t.trailing) || t.ind1Value != -1 || t.baselineValue != -1 || t.exitValue != -1) && t.isBuy == false)))){
         EndTrade(&t);
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
         else if(t.baselineValue == t.ind1Value /*&& baselineValue == ind2Value*/ && t.news == 0){
            MakeTrade(&t);
         }
      }
      else if(t.trade == 0 || t.trade == 1){
         if((t.ind1Value == -1 && t.isBuy == true) || (t.ind1Value == 1 && t.isBuy == false)){
            t.trade = 0;
         }
         if(t.ind1Value != 0 && t.news == 0){
            if(t.ind1Value == 1){
               t.isBuy = true;
            }
            else{
               t.isBuy = false;
            }
            if(t.ind1Value == t.baselineValue /*&& ind1Value == ind2Value && ind1Value == volumeValue*/ /*&& baselineValue2 != 0*/){
               MakeTrade(&t);
            }
            else if(t.trade == 1){
               if(t.ind1Handle + 1 < t.ind1Length){
                  for(int a = t.symHandle; a < t.symLength; a++){
                     if(t.ind1Time == Pairstime[a]){
                        t.symHandle = a;
                        t.trade = 0;
                        break;
                     }
                  }
               }
               else{
                  break;
               }
            }
            else{
               t.trade = 1;
            }
         }
      }
   }
   output[i+j*w+k*w1].ind1 = i;
   output[i+j*w+k*w1].baseline = j;
   output[i+j*w+k*w1].exit = k;
   output[i+j*w+k*w1].win = t.win;
   output[i+j*w+k*w1].loss = t.loss;
   output[i+j*w+k*w1].even = t.even;
   output[i+j*w+k*w1].acc_size = t.acc_size;
   output[i+j*w+k*w1].maxdd = t.maxdd;
   output[i+j*w+k*w1].pipswon = t.pipswon;
   output[i+j*w+k*w1].pipslost = t.pipslost;
};

void ResetVariables(trade *t, int accountsize){
   t->value = 0;
   t->trade = t->news = 0;

   t->win = t->loss = t->even = t->dd = t->maxdd = 0;
   t->isBuy = t->isdd = false;
   t->pipswon = t->pipslost = t->pips = t->price = t->trailing = t->lots = t->atr = 0;
   t->acc_size = t->dd_low = t->dd_high = accountsize;
   
   t->currprice = t->high = t->low = t->curratr = 0;
   t->symTime = t->ind1Time = t->ind2Time = t->baselineTime = t->volumeTime = t->exitTime = 0;
   t->ind1Value = t->ind2Value = t->baselineValue = t->baselineValue2 = t->volumeValue = t->exitValue = 0;
   t->symHandle = t->symLength = t->ind1Handle = t->ind1Length = t->ind2Handle = t->ind2Length = t->baselineHandle = t->baselineLength = t->volumeHandle = t->volumeLength = t->exitHandle = t->exitLength = 0;
}

void MakeTrade(trade *t){
   const int risk = 2;
   t->trade = 3;
   t->price = t->currprice;
   t->atr = t->curratr;
   t->lots = (t->acc_size * risk / 100) / (t->atr * 10000 * 1.5);
   if(t->ind1Value == 1){
      t->isBuy = true;
   }
   else if(t->ind1Value == -1){
      t->isBuy = false;
   }
}

void EndTrade(trade *t){
   t->trade = 0;
   if(t->isBuy == true){
      t->pips = (t->currprice - t->price);
   }
   else{
      t->pips = -(t->currprice - t->price);
   }
   t->acc_size += (t->pips * 10000) * t->lots;
   if(t->pips > 0){
      t->win++;
      t->pipswon += t->pips;
      if(t->isdd == false){
         t->dd_high = t->dd_low = t->acc_size;
      }
      else if(t->dd_high <= t->acc_size){
         t->isdd = false;
         t->dd = (int)(((t->dd_high - t->dd_low) / t->dd_high) * 100);
         if(t->dd > t->maxdd){
            t->maxdd = t->dd;
         }
      }
   }
   else if(t->pips < 0){
      t->loss++;
      t->pipslost -= t->pips;
      t->isdd = true;
      if(t->dd_low > t->acc_size){
         t->dd_low = t->acc_size;
         t->dd = (int)(((t->dd_high - t->dd_low) / t->dd_high) * 100);
         if(t->dd > t->maxdd){
            t->maxdd = t->dd;
         }
      }
   }
   else{
      t->even++;
   }
}
//+------------------------------------------------------------------+