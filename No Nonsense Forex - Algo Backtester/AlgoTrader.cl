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
}results;

typedef struct trade {
   float value;
   int trade, news;
   int win, loss, even, dd, maxdd, SD_n;
   bool isBuy, isdd, exitReady;
   float pipswon, pipslost, pips, price, stoploss, lots, atr;
   float acc_size, dd_low, dd_high;
   float currprice, high, low, curratr, pipsize;
   float exit_rate, news_rate;
   float SD, SD_neg, SD_ROI;
   double SD_sum, SD_sum_squared, SD_sum_neg_squared;
   
   long symTime, ind1Time, ind2Time, baselineTime, volumeTime, exitTime;
   int ind1Value, ind2Value, baselineValue, baselineValue2, volumeValue, exitValue;
   int symHandle, symLength, ind1Handle, ind1Length, ind2Handle, ind2Length, baselineHandle, baselineLength, volumeHandle, volumeLength, exitHandle, exitLength;
   int lastSignal, baselineStart;
   bool ind1Signal, baselineSignal;
   bool exitTrade, volumeTrade, ind2Trade;
}trade;

void ResetVariables(trade *t, int accountsize, bool fullReset);
void MakeTrade(trade *t);
float GetTradeBalance(trade *t);
void EndTrade(trade *t);

__kernel void CompareIndicators(__global results *output, __global long Indicatortime[], __global int Indicatorvalue[], __global int Indicatorvalue2[],
 __global int Indicatorcount[], __global int Indicatorstart[], __global long Pairstime[], __global float Pairsclose[], __global float Pairshigh[], 
 __global float Pairslow[], __global float Pairsatr[], __global int Pairsnews[], int Pairslength, float pip_size){
   
   const int month = 2628000;
   const float months = (Pairstime[Pairslength - 1] - Pairstime[0]) * 1.0 / month;
   int accountsize = 1000;
   int risk = 2;
   float trainsize = 0.75f;
   int SD_Candles = 130;
   float SD_Percent = SD_Candles / (12 * (Pairslength / months));
   float acceptable_ROI = 5;
   struct trade t;
   
   uint i = get_global_id(0);
         
   ResetVariables(&t, accountsize, true);
   
   t.pipsize = pip_size;
   t.symLength = Pairslength;
   t.ind1Handle = Indicatorcount[output[i].ind1];
   t.ind1Length = Indicatorcount[output[i].ind1 + 1];
   t.baselineStart = Indicatorcount[Indicatorstart[2]];
   t.baselineHandle = Indicatorcount[Indicatorstart[2] + output[i].baseline];
   t.baselineLength = Indicatorcount[Indicatorstart[2] + output[i].baseline + 1];
   if(output[i].exit != -1){
      t.exitTrade = true;
      t.exitHandle = Indicatorcount[Indicatorstart[4] + output[i].exit];
      t.exitLength = Indicatorcount[Indicatorstart[4] + output[i].exit + 1];
   }
   if(output[i].volume != -1){
      t.volumeTrade = true;
      t.volumeHandle = Indicatorcount[Indicatorstart[3] + output[i].volume];
      t.volumeLength = Indicatorcount[Indicatorstart[3] + output[i].volume + 1];
   }
   if(output[i].ind2 != -1){
      t.ind2Trade = true;
      t.ind2Handle = Indicatorcount[Indicatorstart[1] + output[i].ind2];
      t.ind2Length = Indicatorcount[Indicatorstart[1] + output[i].ind2 + 1];
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
            t.ind1Time = Indicatortime[t.ind1Handle + 1];
         }
         t.ind1Value = Indicatorvalue[t.ind1Handle];
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
            t.baselineTime = Indicatortime[t.baselineHandle + 1];
         }
         t.baselineValue = Indicatorvalue[t.baselineHandle];
         t.baselineValue2 = Indicatorvalue2[t.baselineHandle - t.baselineStart];
         t.baselineHandle++;
         t.baselineSignal = true;
      }
      if(t.exitTrade == true && t.symTime >= t.exitTime && t.exitHandle < t.exitLength){
         if(t.exitHandle + 1 < t.exitLength){
            t.exitTime = Indicatortime[t.exitHandle + 1];
         }
         t.exitValue = Indicatorvalue[t.exitHandle];
         t.exitHandle++;
      }
      if(t.volumeTrade == true && t.symTime >= t.volumeTime && t.volumeHandle < t.volumeLength){
         if(t.volumeHandle + 1 < t.volumeLength){
            t.volumeTime = Indicatortime[t.volumeHandle + 1];
         }
         t.volumeValue = Indicatorvalue[t.volumeHandle];
         t.volumeHandle++;
      }
      if(t.ind2Trade == true && t.symTime >= t.ind2Time && t.ind2Handle < t.ind2Length){
         if(t.ind2Handle + 1 < t.ind2Length){
            t.ind2Time = Indicatortime[t.ind2Handle + 1];
         }
         t.ind2Value = Indicatorvalue[t.ind2Handle];
         t.ind2Handle++;
      }
      
      if((t.trade == 3 || t.trade == 4) && ((t.exitValue == 1 && t.isBuy == true) || (t.exitValue == -1 && t.isBuy == false))){
	      t.exitReady = true;
      }
      
      if((t.trade == 3 || t.trade == 4) && ((t.trade == 3 && t.news == 1 && t.stoploss != t.price) || ((((t.low <= t.stoploss) || t.ind1Value != 1 || t.baselineValue != 1 || (t.exitReady == true && t.exitValue != 1)) && t.isBuy == true) || (((t.high >= t.stoploss) || t.ind1Value != -1 || t.baselineValue != -1 || (t.exitReady == true && t.exitValue != -1)) && t.isBuy == false)))){
         if((t.low <= t.stoploss && t.isBuy == true) || (t.high >= t.stoploss && t.isBuy == false)){
            t.currprice = t.stoploss;
         }
         EndTrade(&t);
         if(t.exitTrade == false && t.exitReady == true && ((t.exitValue != 1 && t.isBuy == true) || (t.exitValue != -1 && t.isBuy == false))){
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
      
      if(t.trade == 3 && t.stoploss != t.price && (((t.high - t.price) >= t.atr && t.isBuy == true) || (-(t.low - t.price) >= t.atr && t.isBuy == false))){
         if(t.isBuy == true){
            t.stoploss = t.price;
         }
         else{
            t.stoploss = t.price;
         }
      }
      if(t.trade == 3 && (((t.currprice - t.price) >= (t.atr * 2) && t.isBuy == true) || (-(t.currprice - t.price) >= (t.atr * 2) && t.isBuy == false))){
         t.trade = 4;
         if(t.isBuy == true){
            t.stoploss = t.currprice - (t.atr * 1.5);
         }
         else{
            t.stoploss = t.currprice + (t.atr * 1.5);
         }
      }
      else if(t.trade == 4 && (((t.currprice - (t.atr * 1.5)) > t.stoploss && t.isBuy == true) || ((t.currprice + (t.atr * 1.5)) < t.stoploss && t.isBuy == false))){
         if(t.isBuy == true){
            t.stoploss = t.currprice - (t.atr * 1.5);
         }
         else{
            t.stoploss = t.currprice + (t.atr * 1.5);
         }
      }
           
      if(t.trade == 2){
         if((t.baselineValue == -1 && t.isBuy == true) || (t.baselineValue == 1 && t.isBuy == false)){
            t.trade = 0;
         }
         else if(t.ind1Signal == true && t.baselineValue == t.ind1Value && t.baselineValue == t.ind2Value && t.news == 0){
            MakeTrade(&t);
         }
      }
      if(t.trade == 0 || t.trade == 1){
         if((t.ind1Value == -1 && t.isBuy == true) || (t.ind1Value == 1 && t.isBuy == false)){
            t.trade = 0;
         }
         if(((t.ind1Value != 0 && (t.ind1Signal == true || t.trade == 1)) || (t.baselineValue != 0 && (t.baselineSignal == true || t.trade == 1))) && t.news == 0){
            if(t.ind1Value == t.baselineValue && t.ind1Value == t.ind2Value && t.volumeValue != 0 && t.baselineValue2 == 0){
               if(t.trade == 1 || t.ind1Signal == true || (t.baselineSignal == true && t.lastSignal < 7)){
                  MakeTrade(&t);
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
         float balance = 0;
         if(t.trade == 3 || t.trade == 4){
            balance = GetTradeBalance(&t);
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
         output[i].win = t.win;
         output[i].loss = t.loss;
         output[i].even = t.even;
         output[i].acc_size = t.acc_size;
         output[i].return_rate = 100 * (pow(t.acc_size / accountsize, 1 / ((months / 12) * trainsize)) - 1);
         output[i].maxdd = t.maxdd;
         output[i].pipswon = t.pipswon;
         output[i].pipslost = t.pipslost;
         output[i].exit_rate = 100 * t.exit_rate / (t.win + t.loss + t.even);
         output[i].news_rate = 100 * t.news_rate / (t.win + t.loss + t.even);
         ResetVariables(&t, accountsize, false); 
      }
   }
   output[i].std = t.SD;
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
   output[i].news_rate1 = 100 * t.news_rate / (t.win + t.loss + t.even);
};

void ResetVariables(trade *t, int accountsize, bool fullReset){
   t->value = 0;
   t->trade = t->news = 0;

   t->win = t->loss = t->even = t->dd = t->maxdd = 0;
   t->isBuy = t->isdd = t->exitReady = false;
   t->pipswon = t->pipslost = t->pips = t->price = t->stoploss = t->lots = t->atr = 0;
   t->acc_size = t->dd_low = t->dd_high = accountsize;
   t->exit_rate = t->news_rate = 0;
   
   if(fullReset == true){
      t->SD = t->SD_neg = t->SD_ROI = 0;
      t->SD_sum = t->SD_sum_squared = t->SD_sum_neg_squared = 0;
      t->SD_n = 0;
      
      t->currprice = t->high = t->low = t->curratr = t->pipsize = 0;
      t->symTime = t->ind1Time = t->ind2Time = t->baselineTime = t->volumeTime = t->exitTime = 0;
      t->ind1Value = t->ind2Value = t->baselineValue = t->baselineValue2 = t->volumeValue = t->exitValue = 0;
      t->symHandle = t->symLength = t->ind1Handle = t->ind1Length = t->ind2Handle = t->ind2Length = t->baselineHandle = t->baselineLength = t->volumeHandle = t->volumeLength = t->exitHandle = t->exitLength = 0;
      t->lastSignal = 7;
      t->ind1Signal = t->baselineSignal = false;
      t->exitTrade = t->volumeTrade = t->ind2Trade = false;
   }
}

void MakeTrade(trade *t){
   const int risk = 2;
   t->trade = 3;
   t->price = t->currprice;
   t->atr = t->curratr;
   t->lots = (t->acc_size * risk / 100) / (t->atr / t->pipsize * 1.5);
   if(t->ind1Value == 1){
      t->isBuy = true;
      t->stoploss = t->currprice - (t->atr * 1.5);
   }
   else if(t->ind1Value == -1){
      t->isBuy = false;
      t->stoploss = t->currprice + (t->atr * 1.5);
   }
}

float GetTradeBalance(trade *t){
   if(t->isBuy == true){
      if(t->stoploss >= t->price){
         t->pips = ((t->currprice - t->price) + t->atr) * 0.5;
      }
      else{
         t->pips = (t->currprice - t->price);
      }
   }
   else{
      if(t->stoploss <= t->price){
         t->pips = (-(t->currprice - t->price) + t->atr) * 0.5;
      }
      else{
         t->pips = -(t->currprice - t->price);
      }
   }
   t->SD_ROI += (t->pips / t->pipsize) * t->lots;
   return (t->pips / t->pipsize) * t->lots;
}

void EndTrade(trade *t){
   t->trade = 0;
   t->exitReady = false;
   t->acc_size += GetTradeBalance(t);
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