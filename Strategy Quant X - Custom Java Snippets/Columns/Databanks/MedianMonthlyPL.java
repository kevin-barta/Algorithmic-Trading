package SQ.Columns.Databanks;

import java.util.Map;
import java.util.TreeMap;
import java.util.Arrays;

import com.strategyquant.lib.*;
import com.strategyquant.datalib.*;
import com.strategyquant.tradinglib.*;

public class MedianMonthlyPL extends DatabankColumn {
    
	public MedianMonthlyPL() {
		super(L.tsq("Median Monthly PL"), DatabankColumn.Decimal2PL, ValueTypes.Maximize, 0, -10000, 10000);
		
		setTooltip(L.tsq("Median Trade"));
	}
  
  //------------------------------------------------------------------------

  /**
   * This method should return computed value of this new column. You should typically compute it from the list of orders 
   * or from some already computed statistical values (other databank columns). 
   */
	@Override
	public double compute(SQStats stats, StatsTypeCombination combination, OrdersList ordersList, SettingsMap settings, SQStats statsLong, SQStats statsShort) throws Exception {
    
		int numberofMonths = 0;//Get number of months
		double medianMonthlyPL = 0;
		int i = 0;
		byte tradePeriod = 4; //Set to desired value.
		
		if(ordersList.size() == 0) return 0;

		TreeMap<String, Double> plByMonthMap = computeData(ordersList, combination, tradePeriod);
		for(Map.Entry<String, Double> entry : plByMonthMap.entrySet()) {
			numberofMonths++;
		}
		double monthlyPL[] = new double[numberofMonths];
		for(Map.Entry<String, Double> entry : plByMonthMap.entrySet()) {
			//convert map to monthlyPL array
			monthlyPL[i] = entry.getValue();
			i++;
		}



		//sort
		Arrays.sort(monthlyPL);
		
		if (numberofMonths % 2 == 0){
			medianMonthlyPL = (monthlyPL[numberofMonths / 2 - 1] + monthlyPL[(numberofMonths + 2) / 2 - 1]) / 2;
		}
		else{
			medianMonthlyPL = monthlyPL[(numberofMonths + 1) / 2 - 1];
		}
		return SQUtils.round(medianMonthlyPL, 4);
	}	

	private TreeMap<String, Double> computeData(OrdersList orders, StatsTypeCombination combination, byte tradePeriod) {
		TreeMap<String, Double> plByMonthMap = new TreeMap<String, Double>();

		double pl;
		String monthyear;
		
		for(int i = 0; i < orders.size(); i++) {
			Order order = orders.get(i);
			
			monthyear = SQTime.getMonth(order.getTimeByPeriodType(tradePeriod)) + " " + SQTime.getFullYear(order.getTimeByPeriodType(tradePeriod));
			
			pl = getPLByStatsType(order, combination);
			
			if(plByMonthMap.containsKey(monthyear)) {					
				plByMonthMap.put(monthyear,  plByMonthMap.get(monthyear)+pl);
			} else {
				plByMonthMap.put(monthyear, pl);
			}
		}
		
		return plByMonthMap;
	}

}