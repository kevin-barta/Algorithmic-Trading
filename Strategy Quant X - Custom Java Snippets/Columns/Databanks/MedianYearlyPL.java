package SQ.Columns.Databanks;

import java.util.Map;
import java.util.TreeMap;
import java.util.Arrays;

import com.strategyquant.lib.*;
import com.strategyquant.datalib.*;
import com.strategyquant.tradinglib.*;

public class MedianYearlyPL extends DatabankColumn {
    
	public MedianYearlyPL() {
		super(L.tsq("Median Yearly PL"), DatabankColumn.Decimal2PL, ValueTypes.Maximize, 0, -10000, 10000);
		
		setTooltip(L.tsq("Median Trade"));
	}
  
  //------------------------------------------------------------------------

  /**
   * This method should return computed value of this new column. You should typically compute it from the list of orders 
   * or from some already computed statistical values (other databank columns). 
   */
	@Override
	public double compute(SQStats stats, StatsTypeCombination combination, OrdersList ordersList, SettingsMap settings, SQStats statsLong, SQStats statsShort) throws Exception {
    
		int numberofYears = 0;//Get number of years
		double medianYearlyPL = 0;
		int i = 0;
		byte tradePeriod = 5; //Set to desired value.
		
		if(ordersList.size() == 0) return 0;

		TreeMap<Integer, Double> plByYearMap = computeData(ordersList, combination, tradePeriod);
		for(Map.Entry<Integer, Double> entry : plByYearMap.entrySet()) {
			numberofYears++;
		}
		double yearlyPL[] = new double[numberofYears];
		for(Map.Entry<Integer, Double> entry : plByYearMap.entrySet()) {
			//convert map to yearlyPL array
			yearlyPL[i] = entry.getValue();
			i++;
		}



		//sort
		Arrays.sort(yearlyPL);
		
		if (numberofYears % 2 == 0){
			medianYearlyPL = (yearlyPL[numberofYears / 2 - 1] + yearlyPL[(numberofYears + 2) / 2 - 1]) / 2;
		}
		else{
			medianYearlyPL = yearlyPL[(numberofYears + 1) / 2 - 1];
		}
		return SQUtils.round(medianYearlyPL, 4);
	}	

	private TreeMap<Integer, Double> computeData(OrdersList orders, StatsTypeCombination combination, byte tradePeriod) {
		TreeMap<Integer, Double> plByYearMap = new TreeMap<Integer, Double>();

		double pl;
		int year;
		
		for(int i = 0; i < orders.size(); i++) {
			Order order = orders.get(i);
			
			year = SQTime.getFullYear(order.getTimeByPeriodType(tradePeriod));
			
			pl = getPLByStatsType(order, combination);
			
			if(plByYearMap.containsKey(year)) {					
				plByYearMap.put(year,  plByYearMap.get(year)+pl);
			} else {
				plByYearMap.put(year, pl);
			}
		}
		
		return plByYearMap;
	}

}