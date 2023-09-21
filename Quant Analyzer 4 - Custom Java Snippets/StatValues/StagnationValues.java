/*
 * Copyright (c) 2015, StrategyQuant - All rights reserved.
 *
 * Code in this file was made in a good faith that it is correct and does what it should. 
 * If you found a bug in this code OR you have an improvement suggestion OR you want to include 
 * your own code snippet into our standard library please contact us at:
 * http://tasks.strategyquant.com/projects/snippets/
 *
 * This code can be used only within StrategyQuant products. 
 * Every owner of valid (free, trial or commercial) license of any StrategyQuant product 
 * is allowed to freely use, copy, modify or make derivative work of this code without limitations,
 * to be used in all StrategyQuant products and share his/her modifications or derivative work 
 * with the StrategyQuant community.
 *  
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
 * PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES 
 * OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *  
 */
package com.strategyquant.extend.StatValues;

import com.strategyquant.lib.results.SQOrder;
import com.strategyquant.lib.results.SQOrderList;
import com.strategyquant.lib.results.SQStats;
import com.strategyquant.lib.results.StatValue;
import com.strategyquant.lib.results.StatsConst;
import com.strategyquant.lib.results.StatsTypeCombination;
import com.strategyquant.lib.settings.SQSettings;
import com.strategyquant.lib.time.SQTime;
import com.strategyquant.lib.utils.SQUtils;

public class StagnationValues extends StatValue {

   private SQTime dt = new SQTime();
   
	@Override
	public void initCompute(SQStats stats, StatsTypeCombination combination, SQOrderList ordersList, SQSettings settings, SQStats statsLong, SQStats statsShort) throws Exception {

	}
		
	@Override
	public void computeForOrder(SQStats stats, StatsTypeCombination combination, SQOrder order, SQSettings settings, SQStats statsLong, SQStats statsShort) throws Exception {
		
	}

	@Override
	public void endCompute(SQStats stats, StatsTypeCombination combination, SQOrderList ordersList, SQSettings settings, SQStats statsLong, SQStats statsShort) throws Exception {
      long stagnationDays = 0;
      long stagnationFrom = 0;
      long stagnationTo = 0;
      long stagnationToTemp = 0;
      double orderAccountBalance = 0;
      
      // go through orders
      for(int i=0; i<ordersList.size(); i++) {
         long stagnationOrderDays = 0;
         SQOrder order = ordersList.get(i);
         
         if(!order.isFilledOrder() || !order.isRealOrder()) {
            continue;
         }
         double pl = getPLByStatsType(order, combination);
         orderAccountBalance += pl;
         
         // go through each order after current order
         double orderAfterAccountBalance = orderAccountBalance;
         for(int j=i + 1; j<ordersList.size(); j++) {
            SQOrder orderAfter = ordersList.get(j);

            if(!orderAfter.isFilledOrder() || !orderAfter.isRealOrder()) {
               continue;
            }
         
            // if profit after current order is less than order: stagnation
            if(orderAfterAccountBalance <= orderAccountBalance){
               long stagDays = dt.getDaysBetween(order.CloseTime, orderAfter.CloseTime);
               if(stagDays >= stagnationOrderDays){
                  stagnationOrderDays = stagDays;
                  stagnationToTemp = orderAfter.CloseTime;
               }
            }
            double pl1 = getPLByStatsType(orderAfter, combination);
            orderAfterAccountBalance += pl1;
         }

         // if this order is biggest stagnation so far, set it to biggest
         if(stagnationOrderDays >= stagnationDays){
            stagnationDays = stagnationOrderDays;
            stagnationFrom = order.CloseTime;
            stagnationTo = stagnationToTemp;
         }
      }
      
      // calculate total trading days for stagnation profit pct
      int totalDays;
      if(ordersList.isEmpty()) {
         totalDays = 0;
      } else {
         totalDays = dt.getDaysBetween(ordersList.get(0).OpenTime, ordersList.get(ordersList.size() - 1).CloseTime);
      }

      // stagnation days
		stats.set(StatsConst.STAGNATION_FROM, stagnationFrom);
		stats.set(StatsConst.STAGNATION_TO, stagnationTo);
		stats.set(StatsConst.STAGNATION_PERIOD, (int)stagnationDays);

      // stagnation percent
		double stagnationDaysPct = SQUtils.safeDivide(stagnationDays, totalDays) * 100d;
		stats.set(StatsConst.STAGNATION_PERIOD_PCT, SQUtils.round2(stagnationDaysPct));
	}

}