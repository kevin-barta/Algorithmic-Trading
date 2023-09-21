package com.strategyquant.extend.DatabankColumns;

import com.strategyquant.lib.databank.DatabankColumn;
import com.strategyquant.lib.language.L;
import com.strategyquant.lib.results.SQResult;
import com.strategyquant.lib.results.SQResultsGroup;
import com.strategyquant.lib.results.SQStats;
import com.strategyquant.lib.settings.SQConst;
import com.strategyquant.lib.results.StatsMissingException;
import com.strategyquant.lib.results.StatsConst;

public class PortfolioStrategyDirection extends DatabankColumn {
    
	public PortfolioStrategyDirection() {
		super();
		
		setName(L.t("Portfolio Strategy Direction"));		
		setTooltip(L.t("Portfolio Strategy Direction"));
		setWidth(60);
	}

	/**
	 * retrieves value that should be displayed in this column and returns it as an Object
	 */
	@Override
	public Object getValue(SQResultsGroup strategyResults, String dataType, String direction, String sampleType, String plType) throws Exception {
		SQResult result = strategyResults.getResult(SQConst.SYMBOL_PORTFOLIO);
		
		SQStats stats = result.getStats(direction, getGlobalPlType(plType), sampleType);
		if(stats==null) throw new StatsMissingException();
		
		return stats.getDouble("Portfolio_Strategy_Direction");
	}
	
	/**
	 * formats value obtained by getValue() into a string that willbe displayed
	 */
	@Override
	public String displayString(SQResultsGroup strategyResults, String dataType, String direction, String sampleType, String plType) throws Exception {
		Double value = (Double) getValue(strategyResults, dataType, direction, sampleType, plType);
      
      return twoDecimalFormat(value);
	}
}