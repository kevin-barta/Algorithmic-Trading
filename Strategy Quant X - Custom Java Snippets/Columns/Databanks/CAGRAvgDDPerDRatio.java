package SQ.Columns.Databanks;

import com.strategyquant.lib.*;
import com.strategyquant.datalib.*;
import com.strategyquant.tradinglib.*;

public class CAGRAvgDDPerDRatio extends DatabankColumn {
    
	public CAGRAvgDDPerDRatio() {
		super("CAGRAvgDDPerDRatio", 
          DatabankColumn.Decimal2, // value display format
          ValueTypes.Maximize, // whether value should be maximized / minimized / approximated to a value   
          0, // target value if approximation was chosen  
          0, // average minimum of this value
          100); // average maximum of this value
		
    setWidth(80); // defaultcolumn width in pixels
    
		setTooltip("%CAGR/%AvgDDPerD Ratio");  
    setDependencies("CAGR", "AvgPctDrawdown");

	}
  
  //------------------------------------------------------------------------


	@Override
	public double compute(SQStats stats, StatsTypeCombination combination, OrdersList ordersList, SettingsMap settings, SQStats statsLong, SQStats statsShort) throws Exception {
    
    double cagr = stats.getDouble("CAGR");
    double avgDD = stats.getDouble("AvgPctDrawdown");
   
		return round2( SQUtils.safeDivide(cagr, avgDD));
	}	
}