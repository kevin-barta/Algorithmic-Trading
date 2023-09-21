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

public class MeanDD extends DatabankColumn {
	
	//------------------------------------------------------------------------
	//------------------------------------------------------------------------
	//------------------------------------------------------------------------

	public MeanDD() {
		super(L.tsq("Mean DD $"), DatabankColumn.Decimal2PL, ValueTypes.Maximize, 0, -100, 100);
		
		this.setTooltip(L.tsq("Mean DD (in $)"));	
	}
	
	//------------------------------------------------------------------------

	@Override
	public double compute(SQStats stats, StatsTypeCombination combination, OrdersList ordersList, SettingsMap settings, SQStats statsLong, SQStats statsShort) throws Exception {
		
		double drawdownMean = computeAvgDrawdown(ordersList, settings);
		return round2(drawdownMean);
	}
	
	//------------------------------------------------------------------------

	private double computeAvgDrawdown(OrdersList ordersList, SettingsMap settings) {
		if(ordersList.size() == 0) {
			return 0;
		}
		
		double initialCapital = settings.getDouble("MoneyManagement.InitialCapital", 10000); 	
		
    	double maeEquity = 0;
    	double moneyEquity = initialCapital;
    	double peakEquity = initialCapital;
    	
		for(int i=0; i<ordersList.size(); i++) {
			Order o = ordersList.get(i);
			
			maeEquity = moneyEquity - o.MAE;
			moneyEquity += o.PL;

            o.Extra1 = (float) specialSubtraction(peakEquity, maeEquity);
            
            if(moneyEquity > peakEquity) {
            	peakEquity = moneyEquity;
            }            
    	}		

		double avgDD = 0;
		
		for(int i=0; i<ordersList.size(); i++) {
			Order o = ordersList.get(i);
			avgDD += o.Extra1;
		}

		avgDD /= ordersList.size();
		
		return round2(Math.abs(avgDD));
	}

	//------------------------------------------------------------------------

	private static double specialSubtraction(double peak, double equity) {
		double dd = peak - equity;
			
		if(dd < 0) {
			// this means that current equity is bigger than last peak, 
			// so we are not in drawdown currently
			dd = 0;
		}
		
		// convert DD to negative number
		return -1 * dd;
	}  	

}