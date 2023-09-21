package com.strategyquant.extend.StatValues;

import java.util.Iterator;
import java.util.ArrayList;
import java.lang.Math;

import com.strategyquant.lib.results.StatValue;
import com.strategyquant.lib.results.StatsConst;
import com.strategyquant.lib.results.SQStats;
import com.strategyquant.lib.settings.SQSettings;
import com.strategyquant.lib.results.SQOrderList;
import com.strategyquant.lib.results.SQOrder;
import com.strategyquant.lib.results.StatsTypeCombination;
import com.strategyquant.lib.time.SQTime;
import com.strategyquant.lib.utils.SQUtils;
import com.strategyquant.lib.settings.SQConst;

public class PortfolioStrategyDirectionValue extends StatValue {
   private double strategiesBuy, strategiesSell;
	
	@Override
	public void initCompute(SQStats stats, StatsTypeCombination combination, SQOrderList ordersList, SQSettings settings, SQStats statsLong, SQStats statsShort) throws Exception {
      strategiesBuy = 0;
      strategiesSell = 0;
	}

	@Override
	public void computeForOrder(SQStats stats, StatsTypeCombination combination, SQOrder order, SQSettings settings, SQStats statsLong, SQStats statsShort) throws Exception {

	}

	@Override
	public void endCompute(SQStats stats, StatsTypeCombination combination, SQOrderList ordersList, SQSettings settings, SQStats statsLong, SQStats statsShort) throws Exception {
      ArrayList<String> strategies = new ArrayList<>();
      
      for(Iterator<SQOrder> i = ordersList.listIterator(); i.hasNext();) {
         SQOrder order = i.next();
         if(order.isFilledOrder() && order.isRealOrder()) {

            //if a new strategy name is found add to list and check if it is a buy or a sell trade(i.e is buy or sell strategy)
            if(!strategies.contains(order.StrategyName)){
               strategies.add(order.StrategyName);
               if(order.Type==SQConst.ORDER_BUY){
                  strategiesBuy++;
               }
               else if(order.Type==SQConst.ORDER_SELL){
                  strategiesSell++;
               }
            }
         }
      }

      //Get percentage difference of buy and sell strategies i.e 3 buy:1 sell strategies would be 25% difference
      double portfolioStrategyDirection = Math.abs(0.5 - SQUtils.safeDivide(strategiesBuy, strategiesBuy + strategiesSell)) * 100;
      
      // sets the newly computed statistics values to stats array
		stats.set("Portfolio_Strategy_Direction", portfolioStrategyDirection);
	}     
}