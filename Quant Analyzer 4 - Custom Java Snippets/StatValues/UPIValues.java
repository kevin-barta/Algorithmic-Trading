package com.strategyquant.extend.StatValues;

import com.strategyquant.extend.Functions.StatFunctions;
import com.strategyquant.lib.results.SQOrder;
import com.strategyquant.lib.results.SQOrderList;
import com.strategyquant.lib.results.SQStats;
import com.strategyquant.lib.results.StatValue;
import com.strategyquant.lib.results.StatsConst;
import com.strategyquant.lib.results.StatsTypeCombination;
import com.strategyquant.lib.settings.SQSettings;
import com.strategyquant.lib.utils.SQUtils;

public class UPIValues extends StatValue {
   
	@Override
	public String dependsOn() {
		return StatsConst.join(StatsConst.NUMBER_OF_TRADES, StatsConst.AVG_PROFIT_BY_YEAR);
	}

	@Override
	public void initCompute(SQStats stats, StatsTypeCombination combination, SQOrderList ordersList, SQSettings settings, SQStats statsLong, SQStats statsShort) throws Exception {
		
	}

	@Override
	public void computeForOrder(SQStats stats, StatsTypeCombination combination, SQOrder order, SQSettings settings, SQStats statsLong, SQStats statsShort) throws Exception {

	}

   
	@Override
	public void endCompute(SQStats stats, StatsTypeCombination combination, SQOrderList ordersList, SQSettings settings, SQStats statsLong, SQStats statsShort) throws Exception {
      //Ulcer Index
      double sum  = 0;

      for(int i = 0; i<ordersList.size(); i++) {
         SQOrder order = ordersList.get(i);
         
         if(order.isFilledOrder() && order.isRealOrder()) {
      
            // Ulcer Index can be found here: https://blog.thinknewfound.com/2014/04/looking-into-the-ulcer-index/ computed as percentage value. So we focus on perc DD.
            double dd = order.PctDD;
            sum += Math.pow(dd,2);
         }
      }
      
      double ulcerIndex = SQUtils.round(SQUtils.safeDivide(Math.sqrt(sum), stats.getInt(StatsConst.NUMBER_OF_TRADES)), 5);

      

      //Ulcer Performance Index
      double UPI = 2 * SQUtils.safeDivide(stats.getDouble(StatsConst.AVG_PROFIT_BY_YEAR) / 10000.0, ulcerIndex);
      
      // sets the newly computed statistics values to stats array
      stats.set("Ulcer_Index", ulcerIndex);
		stats.set("Ulcer_Performance_Index", SQUtils.round2(UPI));
	}
}