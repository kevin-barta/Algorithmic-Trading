package SQ.Columns.Databanks;

import com.strategyquant.lib.*;
import com.strategyquant.datalib.*;
import com.strategyquant.tradinglib.*;
import java.util.Arrays;

public class MedianTrade extends DatabankColumn {
    
	public MedianTrade() {
		super(L.tsq("Median Trade"), DatabankColumn.Decimal2PL, ValueTypes.Maximize, 0, 0, 200);
		
		setDependencies("NumberOfTrades");
		setTooltip(L.tsq("Median Trade"));
	}
  
  //------------------------------------------------------------------------

  /**
   * This method should return computed value of this new column. You should typically compute it from the list of orders 
   * or from some already computed statistical values (other databank columns). 
   */
	@Override
	public double compute(SQStats stats, StatsTypeCombination combination, OrdersList ordersList, SettingsMap settings, SQStats statsLong, SQStats statsShort) throws Exception {
    
    	/* an example - this is how you can get other values that this new value is dependent on */
    	int numberOfTrades = stats.getInt("NumberOfTrades");
    
		if(numberOfTrades == 0) return 0;

   		/* an example - calculating median profit from the list of trades */
		double medianProfit = 0;
		double profit[] = new double[numberOfTrades];
		int j = 0;
		int i = 0; 

		for(i = 0; i<ordersList.size(); i++) {
			Order order = ordersList.get(i);
			
			if(!(order.isFilledOrder() && order.isRealOrder())) continue;
			
      		/* method getPLByStatsType automatically returns PL depending on given stats type - in money, % or pips */
			double PL = getPLByStatsType(order, combination);
			
			profit[j] = PL;
			j++;
		}

		//sort
		Arrays.sort(profit);
		
		if (numberOfTrades % 2 == 0){
			medianProfit = (profit[numberOfTrades / 2 - 1] + profit[(numberOfTrades + 2) / 2 - 1]) / 2;
		}
		else{
			medianProfit = profit[(numberOfTrades + 1) / 2 - 1];
		}

    	/* round and return the value. It will be saved into stats under the key "MedianTrade" */
		return SQUtils.round(medianProfit, 4);
	}	
}