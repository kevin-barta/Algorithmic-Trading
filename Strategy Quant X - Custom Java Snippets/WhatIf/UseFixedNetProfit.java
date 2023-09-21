package SQ.WhatIf;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.strategyquant.tradinglib.ClassConfig;
import com.strategyquant.tradinglib.Help;
import com.strategyquant.tradinglib.Order;
import com.strategyquant.tradinglib.OrdersList;
import com.strategyquant.tradinglib.Parameter;
import com.strategyquant.tradinglib.WhatIf;
import com.strategyquant.tradinglib.SQStats;
import com.strategyquant.lib.SQUtils;

import java.util.List;

import it.unimi.dsi.fastutil.objects.ObjectListIterator;

@ClassConfig(name="Use fixed Net Profit", display="Use $#Size# fixed Net Profit")
@Help("Use fixed Net Profit")
public class UseFixedNetProfit extends WhatIf {
	
	@Parameter(name="Size", defaultValue="10000", minValue=100, maxValue=100000, step=1)
	public double Size;
	
	@Parameter(name="Decimals", defaultValue="2", minValue=0, maxValue=6, step=1)
	public int Decimals;

	SQUtils utils = new SQUtils();  

	@Override
	public void filter(OrdersList orders) throws Exception {

		// Calculate the Strategy current Net Profit
		double netProfit = 0;
		for(int i = 0; i<orders.size(); i++) {
			Order order = orders.get(i);
			
			if(order.isBalanceOrder()) {
				// don't count balance orders (deposits, withdrawals) in
				continue;
			}
			
			netProfit += order.PL;
		}
		netProfit = utils.round2(netProfit);

		//Calculate the adjusted multiplier size
		double adjustMultiplier = utils.safeDivide(Size, netProfit);
		if(adjustMultiplier <= 0 || adjustMultiplier >= 20){
			adjustMultiplier = 1;
		}
		
		/*List s = getParametersList();
		int j = 0;
		while(s.size() > j){
			fdebug("testholygrail", String.valueOf(s.get(j)));
			j++;
		}

		//setParameterValue("AdjustMultiplier", adjustMultiplier + "");
		setName(getName() + "{" + utils.round(adjustMultiplier, Decimals + 1) +  "}");*/
		
		// Adjust Order PL & Size to fixed Net Profit
		for(ObjectListIterator<Order> i = orders.listIterator(); i.hasNext();) {
			Order order = i.next(); 	
			  
			order.Comment = "{" + utils.round(adjustMultiplier, Decimals + 1) + "}";
            order.PL = (order.PL/order.Size) * (float)utils.round(order.Size * adjustMultiplier, Decimals);
			order.CommSwap = (order.CommSwap/order.Size) * (float)utils.round(order.Size * adjustMultiplier, Decimals);
			order.Size = (float)utils.round(order.Size * adjustMultiplier, Decimals);
		}
	}
}