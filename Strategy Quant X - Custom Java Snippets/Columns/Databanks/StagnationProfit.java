/*
 * Copyright (c) 2017-2018, StrategyQuant - All rights reserved.
 *
 * Code in this file was made in a good faith that it is correct and does what it should.
 * If you found a bug in this code OR you have an improvement suggestion OR you want to include
 * your own code snippet into our standard library please contact us at:
 * https://roadmap.strategyquant.com
 *
 * This code can be used only within StrategyQuant products.
 * Every owner of valid (free, trial or commercial) license of any StrategyQuant product
 * is allowed to freely use, copy, modify or make derivative work of this code without limitations,
 * to be used in all StrategyQuant products and share his/her modifications or derivative work
 * with the StrategyQuant community.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
 * PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES
 * OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 */
package SQ.Columns.Databanks;

import com.strategyquant.lib.L;
import com.strategyquant.lib.SQTime;
import com.strategyquant.lib.SQUtils;
import com.strategyquant.lib.SettingsMap;
import com.strategyquant.tradinglib.DatabankColumn;
import com.strategyquant.tradinglib.Order;
import com.strategyquant.tradinglib.OrdersList;
import com.strategyquant.tradinglib.SQStats;
import com.strategyquant.tradinglib.SampleTypes;
import com.strategyquant.tradinglib.StatsKey;
import com.strategyquant.tradinglib.StatsTypeCombination;
import com.strategyquant.tradinglib.ValueTypes;
import com.strategyquant.tradinglib.strategy.OutOfSample;

public class StagnationProfit extends DatabankColumn {
	
	public StagnationProfit() {
		super(L.tsq("Stagnation Profit"), DatabankColumn.Integer, ValueTypes.Minimize, 0, 0, 10000);

		setTooltip(L.tsq("Stagnation Profit in Days"));

		// this means that value depends on number of trading days 
		// and has to be normalized by days when comparing with another
		// result with different number of trading days
		setDependentOnTradingPeriod(true); 
	}
	
	//------------------------------------------------------------------------

	@Override
	public double compute(SQStats stats, StatsTypeCombination combination, OrdersList ordersList, SettingsMap settings, SQStats statsLong, SQStats statsShort) throws Exception {
		long stagnationDays = 0;
		
		// go through orders
		for(int i=0; i<ordersList.size(); i++) {
			long stagnationOrderDays = 0;
			Order order = ordersList.get(i);

			// go through each order after current order
			for(int j=i + 1; j<ordersList.size(); j++) {
				Order orderAfter = ordersList.get(j);

				// if profit after current order is less than order: stagnation
				if(orderAfter.AccountBalance <= order.AccountBalance){
					long stagDays = SQTime.getDaysBetween(order.CloseTime, orderAfter.CloseTime);
					if(stagDays >= stagnationOrderDays){
						stagnationOrderDays = stagDays;
					}
				}
			}

			// if this order is biggest stagnation so far, set it to biggest
			if(stagnationOrderDays >= stagnationDays){
				stagnationDays = stagnationOrderDays;
			}
		}
		
		// calculate total trading days for stagnation profit pct
		int totalDays;
		if(ordersList.isEmpty()) {
			totalDays = 0;
		} else {
			totalDays = SQTime.getDaysBetween(ordersList.get(0).OpenTime, ordersList.get(ordersList.size() - 1).CloseTime);
		}

		// stagnation profit percent
		double stagnationDaysPct = SQUtils.safeDivide(stagnationDays, totalDays) * 100d;
		stats.set("StagnationProfitPct", round2(stagnationDaysPct));

		return (int) stagnationDays;
	}

	
}