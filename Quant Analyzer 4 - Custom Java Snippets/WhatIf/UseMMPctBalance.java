package com.strategyquant.extend.WhatIf;

import com.strategyquant.lib.language.L;
import com.strategyquant.lib.snippets.WhatIf;
import com.strategyquant.lib.results.SQOrderList;
import com.strategyquant.lib.results.SQOrder;
import com.strategyquant.lib.utils.SQUtils;
import java.lang.Math;

public class UseMMPctBalance extends WhatIf {

	public UseMMPctBalance() {
		setName(L.t("UseMMPctBalance"));

      addIntParameter("Decimals", L.t("Decimals"), 1, 0, 6, 1);
      addDoubleParameter("Multiplier", L.t("Multiplier"), 1d, 0.1d, 10d, 0.1d);

      setFormatedName(L.t("Use {Multiplier}x % Balance"));
	}
	
	/**
	 * Function receives list of all orders sorted by open time and it could manipulate 
	 * the list and remove any order that matches certain filter from the list.     
	 * 
	 * Order structure is available in the documentation here:
	 * http://www.strategyquant.com/doc/api/com/strategyquant/lib/results/SQOrder.html
	 *
	 * @param originalOrders - list of original orders that can be changed. Each order has the order properties specified above
	 */    
	@Override
	public void filter(SQOrderList originalOrders) throws Exception {
      int decimals = getIntParameterValue("Decimals");
		double multiplier = getDoubleParameterValue("Multiplier");
      double initialBalance = -1;
      double balance = -1;
      
		for(SQOrder order : originalOrders) {
			if(order.isBalanceOrder()) continue;

         //set initial balance
         if(initialBalance == -1){
            initialBalance = order.AccountBalance;
            balance = order.AccountBalance;
         }
         
         //calculate new trade size
         double size = SQUtils.round(balance/initialBalance * multiplier * order.Size, decimals);
         if(size <= 0){
            size = Math.pow(10, -decimals);
         }
         
         // recompute P/L for the new size
         order.PL = (order.PL/order.Size)*size;
         order.CommSwap = (order.CommSwap/order.Size)*size;
         balance += order.PL;

         // set order size to the configured value       
         order.Size = size;
		}			
	}
}