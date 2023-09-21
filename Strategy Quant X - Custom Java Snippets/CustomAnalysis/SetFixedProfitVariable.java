package SQ.CustomAnalysis;

import com.strategyquant.lib.*;

import java.util.List;
import java.util.ArrayList;
import java.util.Iterator;

import com.strategyquant.datalib.*;
import com.strategyquant.tradinglib.*;
import com.strategyquant.tradinglib.results.*;
import com.strategyquant.tradinglib.results.SpecialValues;


public class SetFixedProfitVariable extends CustomAnalysisMethod {

	//------------------------------------------------------------------------
	//------------------------------------------------------------------------
	//------------------------------------------------------------------------
	
	public SetFixedProfitVariable() {
		super("Set Fixed Profit Variable", TYPE_PROCESS_DATABANK);
	}
	
	//------------------------------------------------------------------------
	
	@Override
	public boolean filterStrategy(String project, String task, String databankName, ResultsGroup rg) throws Exception {
		return true;
	}
	
	
	//------------------------------------------------------------------------
	
	@Override
	public ArrayList<ResultsGroup> processDatabank(String project, String task, String databankName, ArrayList<ResultsGroup> databankRG) throws Exception {
		ArrayList<ResultsGroup> newdatabankRG = new ArrayList<>(databankRG);

		if (databankRG.size() > 0) {
			Iterator<ResultsGroup> it = databankRG.iterator();

			while(it.hasNext()) {
				ResultsGroup strategy = it.next();
				newdatabankRG.add(strategy.clone());

				OrdersList orders = strategy.orders();
				// Get adjusted multiplier size
				for(int i = 0; i<orders.size(); i++) {
					Order order = orders.get(i);
			
					if(order.isBalanceOrder()) {
						continue;
					}
					if(order.Comment != null){
						if(order.Comment != "" && order.Comment.contains("{")){
							strategy.setName(strategy.getName() + order.Comment);
							newdatabankRG.add(strategy.clone());
							break;
						}
					}
				}
			}
		}

		return newdatabankRG;
	}
}