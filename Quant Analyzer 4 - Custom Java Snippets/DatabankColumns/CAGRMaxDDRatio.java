package com.strategyquant.extend.DatabankColumns;

import com.strategyquant.lib.databank.DatabankColumn;
import com.strategyquant.lib.language.L;
import com.strategyquant.lib.results.SQResult;
import com.strategyquant.lib.results.SQResultsGroup;
import com.strategyquant.lib.results.SQStats;
import com.strategyquant.lib.settings.SQConst;
import com.strategyquant.lib.results.StatsMissingException;
import com.strategyquant.lib.results.StatsConst;

public class CAGRMaxDDRatio extends DatabankColumn {
    
	public CAGRMaxDDRatio() {
		super();
		
		setName(L.t("CAGR/MaxDD Ratio"));		
		setTooltip(L.t("CAGR/MaxDD Ratio"));
		setWidth(60);
	}

	@Override
	public Object getValue(SQResultsGroup strategyResults, String dataType, String direction, String sampleType, String plType) throws Exception {
		SQResult result = strategyResults.getResult(SQConst.SYMBOL_PORTFOLIO);
      
      SQStats stats = result.getStats(direction, getGlobalPlType(plType), sampleType);
      if(stats==null) throw new StatsMissingException();
      
      return stats.getDouble("CAGR_MaxDD_Ratio", 0);
	}
	
	@Override
	public String displayString(SQResultsGroup strategyResults, String dataType, String direction, String sampleType, String plType) throws Exception {
		// retrieves value from the stats 
      Double value = (Double) getValue(strategyResults, dataType, direction, sampleType, plType); 
      
      return twoDecimalFormat(value); // display the number with two decimal points 
	}
}