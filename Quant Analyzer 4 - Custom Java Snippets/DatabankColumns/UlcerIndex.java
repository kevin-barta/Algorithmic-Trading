package com.strategyquant.extend.DatabankColumns;

import com.strategyquant.lib.databank.DatabankColumn;
import com.strategyquant.lib.language.L;
import com.strategyquant.lib.results.SQResult;
import com.strategyquant.lib.results.SQResultsGroup;
import com.strategyquant.lib.results.SQStats;
import com.strategyquant.lib.results.StatsConst;
import com.strategyquant.lib.results.StatsMissingException;
import com.strategyquant.lib.settings.SQConst;

public class UlcerIndex extends DatabankColumn {
    
   public UlcerIndex() {
      super();
   
      setName(L.t("UlcerIndex"));
      setTooltip(L.t("UlcerIndex"));
      setWidth(60);
   }

   public Object getValue(SQResultsGroup strategyResults, String dataType, String direction, String sampleType, String plType) throws Exception { 
      // get result for portfolio 
      SQResult result = strategyResults.getResult(SQConst.SYMBOL_PORTFOLIO); 
      
      // get stats for portfolioand the correct combination of direction, pl type, sample type 
      SQStats stats = result.getStats(direction, getGlobalPlType(plType), sampleType); 
      if(stats==null) throw new StatsMissingException(); 
      
      // returns the value 
      return stats.getDouble("Ulcer_Index", 0);
   }   

   public String displayString(SQResultsGroup strategyResults, String dataType, String direction, String sampleType, String plType) throws Exception {
      
      // retrieves value from the stats 
      Double value = (Double) getValue(strategyResults, dataType, direction, sampleType, plType); 
      
      return twoDecimalFormat(value); // display the number with two decimal points 
   }
}