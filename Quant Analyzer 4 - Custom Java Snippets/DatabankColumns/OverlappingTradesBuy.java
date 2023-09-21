package com.strategyquant.extend.DatabankColumns;

import com.strategyquant.lib.databank.DatabankColumn;
import com.strategyquant.lib.language.L;
import com.strategyquant.lib.results.SQResult;
import com.strategyquant.lib.results.SQResultsGroup;
import com.strategyquant.lib.results.SQStats;
import com.strategyquant.lib.settings.SQConst;
import com.strategyquant.lib.results.StatsMissingException;
import com.strategyquant.lib.results.StatsConst;

public class OverlappingTradesBuy extends DatabankColumn {
    
	public OverlappingTradesBuy() {
		super();
		
		setName(L.t("Overlapping Trades Buy"));		
		setTooltip(L.t("Overlapping Trades Buy"));
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
		
		return stats.getDouble("Overlapping_Trades_Buy");
	}
	
	/**
	 * formats value obtained by getValue() into a string that willbe displayed
	 */
	@Override
	public String displayString(SQResultsGroup strategyResults, String dataType, String direction, String sampleType, String plType) throws Exception {
		Double overlappingTrades = (Double) getValue(strategyResults, dataType, direction, sampleType, plType);
      
      return twoDecimalFormat(overlappingTrades);
	}
}