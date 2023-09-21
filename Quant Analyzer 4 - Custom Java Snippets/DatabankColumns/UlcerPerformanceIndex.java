/*
 * Copyright (c) 2015, StrategyQuant - All rights reserved.
 *
 * Code in this file was made in a good faith that it is correct and does what it should. 
 * If you found a bug in this code OR you have an improvement suggestion OR you want to include 
 * your own code snippet into our standard library please contact us at:
 * http://tasks.strategyquant.com/projects/snippets/
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
package com.strategyquant.extend.DatabankColumns;

import com.strategyquant.lib.databank.DatabankColumn;
import com.strategyquant.lib.language.L;
import com.strategyquant.lib.results.SQResult;
import com.strategyquant.lib.results.SQResultsGroup;
import com.strategyquant.lib.results.SQStats;
import com.strategyquant.lib.results.StatsConst;
import com.strategyquant.lib.results.StatsMissingException;
import com.strategyquant.lib.settings.SQConst;

public class UlcerPerformanceIndex extends DatabankColumn {
    
	public UlcerPerformanceIndex() {
		super();
		
		setName(L.t("Ulcer Performance Index"));
		setTooltip(L.t("Ulcer Performance Index"));
		setWidth(60);
	}
	
	@Override
	public Object getValue(SQResultsGroup strategyResults, String dataType, String direction, String sampleType, String plType) throws Exception {
		SQResult result = strategyResults.getResult(SQConst.SYMBOL_PORTFOLIO);
		
		SQStats stats = result.getStats(direction, getGlobalPlType(plType), sampleType);
		if(stats==null) throw new StatsMissingException();
		
		return stats.getDouble("Ulcer_Performance_Index", 0);
	}
	
	@Override
	public String displayString(SQResultsGroup strategyResults, String dataType, String direction, String sampleType, String plType) throws Exception {
		Double upi = (Double) getValue(strategyResults, dataType, direction, sampleType, plType);
		
		return twoDecimalFormat(upi);
	}
}