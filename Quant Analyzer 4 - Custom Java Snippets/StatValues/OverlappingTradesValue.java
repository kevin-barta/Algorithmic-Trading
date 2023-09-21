package com.strategyquant.extend.StatValues;

import java.util.Iterator;

import com.strategyquant.lib.results.StatValue;
import com.strategyquant.lib.results.StatsConst;
import com.strategyquant.lib.results.SQStats;
import com.strategyquant.lib.settings.SQSettings;
import com.strategyquant.lib.results.SQOrderList;
import com.strategyquant.lib.results.SQOrder;
import com.strategyquant.lib.results.StatsTypeCombination;
import com.strategyquant.lib.time.SQTime;
import com.strategyquant.lib.utils.SQUtils;

public class OverlappingTradesValue extends StatValue {
	private double overlappingTrades;
	
   /**
    * returns an array of stat values that this new value depends on. This ensures that our new value
    * will be computed AFTER the values it depends on.
    * Make sure there is no circular dependence, for example A depends on B, B depends on A
    *
	@Override
	public String dependsOn() {
      return StatsConst.join(StatsConst.PCT_DRAWDOWN, StatsConst.CAGR);
	}/

   /**
    * initializes computation. It can be used to reset the variables to their default values
    */
	@Override
	public void initCompute(SQStats stats, StatsTypeCombination combination, SQOrderList ordersList, SQSettings settings, SQStats statsLong, SQStats statsShort) throws Exception {
		overlappingTrades = 0;
	}

   /**
    * called once for every order.
    * It is possible either to use this function, or use function endCompute() to compute the stats. Then you can leave this function empty.
    */
	@Override
	public void computeForOrder(SQStats stats, StatsTypeCombination combination, SQOrder order, SQSettings settings, SQStats statsLong, SQStats statsShort) throws Exception {

	}

   /**
    * called in the end, after all orders have been processed.
    * It shuld set the newly computed statistics values to stats array.
    *
    * For more complicated procesing it is possible to keep function computeForOrder() empty and do the whole computation here.
    *
    * @param ordersList - list of orders for given combination
    */
	@Override
	public void endCompute(SQStats stats, StatsTypeCombination combination, SQOrderList ordersList, SQSettings settings, SQStats statsLong, SQStats statsShort) throws Exception {
      long closeTime = -1;
      
      for(Iterator<SQOrder> i = ordersList.listIterator(); i.hasNext();) {
         SQOrder order = i.next();
         
         if(order.isFilledOrder() && order.isRealOrder()) {
            
            if(closeTime==-1) {
               closeTime = order.CloseTime;
            } else {
               if(order.OpenTime>closeTime) {
                  closeTime = order.CloseTime;
                  
                  continue;
               } 
               
               // when we are here it means that current trade opened before previous trade closed,
               // which means the trades are overlapping and current trade is overlapping
               overlappingTrades++;
               closeTime = order.CloseTime; //for multiple consecutive overlapping trades
            }
         }
      }
      
      // sets the newly computed statistics values to stats array
		stats.set("Overlapping_Trades", overlappingTrades);
	}
}