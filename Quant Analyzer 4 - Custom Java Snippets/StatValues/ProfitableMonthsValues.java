package com.strategyquant.extend.StatValues;

import com.strategyquant.lib.results.StatValue;
import com.strategyquant.lib.results.StatsConst;
import com.strategyquant.lib.results.SQStats;
import com.strategyquant.lib.settings.SQSettings;
import com.strategyquant.lib.results.SQOrderList;
import com.strategyquant.lib.results.SQOrder;
import com.strategyquant.lib.results.StatsTypeCombination;
import com.strategyquant.lib.time.SQTime;
import com.strategyquant.lib.utils.SQUtils;

import java.util.HashMap;
import java.util.Iterator;

public class ProfitableMonthsValues extends StatValue {
	private int trades;
	
	@Override
	public String dependsOn() {
		return StatsConst.join(StatsConst.TOTAL_TRADING_DAYS, StatsConst.TOTAL_TRADING_MONTHS);
	}

	@Override
	public void initCompute(SQStats stats, StatsTypeCombination combination, SQOrderList ordersList, SQSettings settings, SQStats statsLong, SQStats statsShort) throws Exception {
		trades = 0;
	}

	@Override
	public void computeForOrder(SQStats stats, StatsTypeCombination combination, SQOrder order, SQSettings settings, SQStats statsLong, SQStats statsShort) throws Exception {
      if(order.isCanceledOrder()) {
         return;
      }

      trades++;
	}

	@Override
	public void endCompute(SQStats stats, StatsTypeCombination combination, SQOrderList ordersList, SQSettings settings, SQStats statsLong, SQStats statsShort) throws Exception {

      SQTime sqTime;
      String month, year;
      HashMap<String, Double> map = new HashMap<String, Double>();
      
      for(Iterator<SQOrder> i = ordersList.listIterator(); i.hasNext();) {
         SQOrder order = i.next();
         
         if(order.isFilledOrder() && order.isRealOrder()) {

            sqTime = new SQTime(order.CloseTime);
            month = Integer.toString(sqTime.getMonth()); //0-11
            year = Integer.toString(sqTime.getYear()); //Year - 1900

            if (map.containsKey(month + year)) {
               map.put(month+year, map.get(month + year) + order.PL);
            }
            else {
               // No key exists yet
               map.put(month+year, order.PL);
            }
         }
      }

      double count = 0;
      for (String key: map.keySet()) {
         double value = map.get(key);
         if (value >= 0){
            count++;
         }
      }
      
		stats.set("ProfitableMonths", count);
      stats.set("ProfitableMonthsPct", SQUtils.round2((count / map.size()) * 100));
	}
}