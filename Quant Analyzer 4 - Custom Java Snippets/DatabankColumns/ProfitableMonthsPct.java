package com.strategyquant.extend.DatabankColumns;

import com.strategyquant.lib.databank.DatabankColumn;
import com.strategyquant.lib.language.L;
import com.strategyquant.lib.results.SQResult;
import com.strategyquant.lib.results.SQResultsGroup;
import com.strategyquant.lib.results.SQStats;
import com.strategyquant.lib.settings.SQConst;
import com.strategyquant.lib.results.StatsMissingException;
import com.strategyquant.lib.results.StatsConst;

public class ProfitableMonthsPct extends DatabankColumn {
    
	public ProfitableMonthsPct() {
		super();
		
      setName(L.t("Profitable Months Pct"));
      setTooltip(L.t("Profitable Months Pct"));
		setWidth(60);
	}

	@Override
	public Object getValue(SQResultsGroup strategyResults, String dataType, String direction, String sampleType, String plType) throws Exception {
      SQResult result = strategyResults.getResult(SQConst.SYMBOL_PORTFOLIO);
    
      SQStats stats = result.getStats(direction, getGlobalPlType(plType), sampleType);
      if(stats==null) throw new StatsMissingException();
      
      return stats.getDouble("ProfitableMonthsPct", 0);
	}
	
	@Override
	public String displayString(SQResultsGroup strategyResults, String dataType, String direction, String sampleType, String plType) throws Exception {
		Double value = (Double) getValue(strategyResults, dataType, direction, sampleType, plType);
      
      return twoDecimalPctFormat(value);
	}
}