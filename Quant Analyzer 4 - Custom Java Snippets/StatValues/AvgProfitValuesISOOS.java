package com.strategyquant.extend.StatValues;

import com.strategyquant.lib.results.SQOrder;
import com.strategyquant.lib.results.SQOrderList;
import com.strategyquant.lib.results.SQStats;
import com.strategyquant.lib.results.StatValue;
import com.strategyquant.lib.results.StatsConst;
import com.strategyquant.lib.results.StatsTypeCombination;
import com.strategyquant.lib.settings.SQSettings;
import com.strategyquant.lib.utils.SQUtils;
import com.strategyquant.lib.settings.SQConst;

public class AvgProfitValuesISOOS extends StatValue {
	private double sumTradesInMoney_IS, sumTradesInMoney_OOS;
	
	@Override
	public String dependsOn() {
		return StatsConst.join(StatsConst.PCT_DRAWDOWN, StatsConst.TOTAL_TRADING_YEARS);
	}

	@Override
	public void initCompute(SQStats stats, StatsTypeCombination combination, SQOrderList ordersList, SQSettings settings, SQStats statsLong, SQStats statsShort) throws Exception {
      sumTradesInMoney_IS = 0;
      sumTradesInMoney_OOS = 0;
	}

	@Override
	public void computeForOrder(SQStats stats, StatsTypeCombination combination, SQOrder order, SQSettings settings, SQStats statsLong, SQStats statsShort) throws Exception {
      int sampleType = order.getSampleType();

      if(sampleType == SQConst.SAMPLE_IS){
         sumTradesInMoney_IS += order.PL;
      }
      else if (sampleType == SQConst.SAMPLE_OOS1){
         sumTradesInMoney_OOS += order.PL;
      }
	}

	@Override
	public void endCompute(SQStats stats, StatsTypeCombination combination, SQOrderList ordersList, SQSettings settings, SQStats statsLong, SQStats statsShort) throws Exception {

      // Percent Drawdown's for IS and OOS
      double maxPctDD_IS = 99999999;
      double maxPctDD_OOS = 99999999;
      
      for(SQOrder order : ordersList) {
         int sampleType = order.getSampleType();
         if(sampleType == SQConst.SAMPLE_IS){
            if(order.PctDD < maxPctDD_IS) maxPctDD_IS = order.PctDD;
         }
         else if (sampleType == SQConst.SAMPLE_OOS1){
            if(order.PctDD < maxPctDD_OOS) maxPctDD_OOS = order.PctDD;
         }
      }

      stats.set("PCT_DRAWDOWN_IS", SQUtils.round2(Math.abs(maxPctDD_IS)));
      stats.set("PCT_DRAWDOWN_OOS", SQUtils.round2(Math.abs(maxPctDD_OOS)));
      // End Percent Drawdown's for IS and OOS
      


      double totalYearsOfTrading_IS = ((double) stats.getInt(StatsConst.TOTAL_TRADING_YEARS)) / 2; // Assumes 50-50 IS/OOS (fix eventually)
      double totalYearsOfTrading_OOS = ((double) stats.getInt(StatsConst.TOTAL_TRADING_YEARS)) / 2; // Assumes 50-50 IS/OOS (fix eventually)

      double initialCapital = settings.getDouble("InitialDeposit");

      double CAGR_IS = CAGR(initialCapital, totalYearsOfTrading_IS, sumTradesInMoney_IS);
      double CAGR_OOS = CAGR(initialCapital, totalYearsOfTrading_OOS, sumTradesInMoney_OOS);
      double CAGR_Ratio = SQUtils.safeDivide(CAGR_OOS, CAGR_IS);
      stats.set("CAGR_IS", SQUtils.round2(CAGR_IS)); 
      stats.set("CAGR_OOS", SQUtils.round2(CAGR_OOS));
      stats.set("CAGR_Ratio", SQUtils.round2(CAGR_Ratio));

      double CAGR_MaxDD_IS = SQUtils.safeDivide(CAGR_IS, maxPctDD_IS);
      double CAGR_MaxDD_OOS = SQUtils.safeDivide(CAGR_OOS, maxPctDD_OOS);
      double CAGR_MaxDD_Ratio = SQUtils.safeDivide(CAGR_MaxDD_OOS, CAGR_MaxDD_IS);
      stats.set("CAGR_MaxDD_IS", SQUtils.round2(CAGR_MaxDD_IS));    
      stats.set("CAGR_MaxDD_OOS", SQUtils.round2(CAGR_MaxDD_OOS)); 
      stats.set("CAGR_MaxDD_Ratio", SQUtils.round2(CAGR_MaxDD_Ratio)); 
	}

   // CAGR formula:
   // http://www.investopedia.com/ask/answers/071014/what-formula-calculating-compound-annual-growth-rate-cagr-excel.asp
   private static double CAGR(double initialCapital, double totalYearsOfTrading, double sumTradesInMoney) {
      double temp1 = (initialCapital + sumTradesInMoney) / initialCapital;
      double temp2 = 1 / totalYearsOfTrading;
      
      return (Math.pow(temp1, temp2) - 1) * 100; //CAGR
   }     
}