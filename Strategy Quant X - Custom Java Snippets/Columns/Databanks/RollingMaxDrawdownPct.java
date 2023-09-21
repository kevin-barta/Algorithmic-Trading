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
import com.strategyquant.lib.SettingsMap;
import com.strategyquant.tradinglib.CustomCellFormat;
import com.strategyquant.tradinglib.DatabankColumn;
import com.strategyquant.tradinglib.Order;
import com.strategyquant.tradinglib.OrdersList;
import com.strategyquant.tradinglib.ResultsGroup;
import com.strategyquant.tradinglib.SQStats;
import com.strategyquant.tradinglib.StatsTypeCombination;
import com.strategyquant.tradinglib.ValueTypes;

public class RollingMaxDrawdownPct extends DatabankColumn {
    
	// Rolling Window in days
	static final int rollingWindow = 30;

	public RollingMaxDrawdownPct() {
		super(L.tsq("Rolling " + rollingWindow + "D Max Drawdown %"), DatabankColumn.Decimal2Pct, ValueTypes.Minimize, 0, 0, 10000);
		
		// this means that value depends on number of trading days 
		// and has to be normalized by days when comparing with another
		// result with different number of trading days
		setDependentOnTradingPeriod(true); 
		
		setTooltip(L.tsq("Drawdown computed from open balance + MAE"));
	}
	
	//------------------------------------------------------------------------

	@Override
	public double compute(SQStats stats, StatsTypeCombination combination, OrdersList ordersList, SettingsMap settings, SQStats statsLong, SQStats statsShort) throws Exception {

		if(ordersList.size() == 0) {
			return 0;
		}
		
		double initialCapital = settings.getDouble("MoneyManagement.InitialCapital", 10000); 	
		double maxDD = 0;
		String maxDebugTime = "";

		for(int i=0; i<ordersList.size(); i++) {
			Order o = ordersList.get(i);
			
			// get Balance at trade open
			double oLowestBalance = o.AccountBalance - o.PL; 
			String DebugTime = "";

			for(int j=i; j<ordersList.size(); j++) {
				Order o2 = ordersList.get(j);

				if(SQTime.getDaysBetween​(o.OpenTime, o2.CloseTime) < rollingWindow){
					if(o2.AccountBalance - o2.PL - o2.MAE < oLowestBalance){
						// Worst DD so far
						oLowestBalance = o2.AccountBalance - o2.PL - o2.MAE;
						//DebugTime = " Open: " + SQTime.toDateMinuteString​(o.OpenTime) + " Close: " + SQTime.toDateMinuteString​(o2.CloseTime);
					}
				}
				else{
					// rolling window has exceed
					break;
				}
			}
		
			//if this DD is the MaxDD so far then update
			if(getPercentageDD((o.AccountBalance - o.PL) - oLowestBalance,  o.AccountBalance - o.PL) > maxDD){
				maxDD = getPercentageDD((o.AccountBalance - o.PL) - oLowestBalance,  o.AccountBalance - o.PL);
				maxDebugTime = DebugTime;
			}
		}
		//Log.info("Rolling " + rollingWindow + "D Max Drawdown: " + maxDD + maxDebugTime);
		return round2(maxDD);
	}
	
	//------------------------------------------------------------------------

	private double getPercentageDD(double pl, double equity) {
		if(equity <= 0 || pl > equity) {
			return -1;
		}
	    	
		return pl / (equity / 100);
	}		
	
	//------------------------------------------------------------------------

}