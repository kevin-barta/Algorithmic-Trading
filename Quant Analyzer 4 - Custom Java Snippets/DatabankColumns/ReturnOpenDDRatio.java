package com.strategyquant.extend.DatabankColumns;

import com.strategyquant.lib.databank.DatabankColumn;
import com.strategyquant.lib.language.L;
import com.strategyquant.lib.results.SQResult;
import com.strategyquant.lib.results.SQResultsGroup;
import com.strategyquant.lib.results.SQStats;
import com.strategyquant.lib.results.StatsConst;
import com.strategyquant.lib.results.StatsMissingException;
import com.strategyquant.lib.settings.SQConst;

public class ReturnOpenDDRatio extends DatabankColumn {
    
	public ReturnOpenDDRatio() {
		super();
		
		setName(L.t("Return/OpenDD Ratio"));		
		setTooltip(L.t("Return/OpenDD Ratio"));
		setWidth(60);
	}

	@Override
	public Object getValue(SQResultsGroup strategyResults, String dataType, String direction, String sampleType, String plType) throws Exception {
		SQResult result = strategyResults.getResult(SQConst.SYMBOL_PORTFOLIO);
		
		SQStats stats = result.getStats(direction, getGlobalPlType(plType), sampleType);
		if(stats==null) throw new StatsMissingException();
    
      double ratio = 0.0;
      
      if(stats.getDouble(StatsConst.PIPS_MAX_OPEN_DD, 0) != 0)
         ratio = stats.getDouble(StatsConst.NET_PROFIT)/stats.getDouble(StatsConst.PIPS_MAX_OPEN_DD, 0);
		
		return ratio;
	}
	
	@Override
	public String displayString(SQResultsGroup strategyResults, String dataType, String direction, String sampleType, String plType) throws Exception {
		Double value = (Double) getValue(strategyResults, dataType, direction, sampleType, plType); 
      
      return twoDecimalFormat(value); // display the number with two decimal points 
	}
}