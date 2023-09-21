/*
 * Copyright (c) 2017-2018, StrategyQuant and bendx77 - All rights reserved.
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
package SQ.MonteCarlo.Retest;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.strategyquant.lib.*;
import com.strategyquant.datalib.*;
import com.strategyquant.tradinglib.*;
import java.lang.Math;

/**
 * Random history data modification created by bendx77
 * Random history bounded created by kbtech
 * See: https://roadmap.strategyquant.com/tasks/sq4_7233/
 * and: https://strategyquant.com/forum/topic/possible-new-way-to-randomize-data-with-change-instead-of-atr/
 * Build 132 update - see: https://roadmap.strategyquant.com/tasks/sq4_8001
 * @author bendx77
 * @author kbtech
 */
@ClassConfig(name="Randomize history data (bounded)", display="Randomize history data bounded to original history +-#BoundPercent# %, with max change of #MaxChange# % per candle/tick")
@Help("<b>Note!</b>This option is supposed to work best with Selected Timeframe precision.")
public class RandomizeHistoryDataBounded extends MonteCarloRetest {

	public static final Logger Log = LoggerFactory.getLogger(RandomizeHistoryDataFixedRange.class);

	@Parameter(name="Max % from original history", defaultValue="20", minValue=1, maxValue=200, step=1)
	@Help("Max % from original history")
	public double BoundPercent;

	@Parameter(name="Max % change per candle", defaultValue="20", minValue=0, maxValue=1000, step=1)
	@Help("Max % change per candle")
	public int MaxChange;

	//bendedit: we need some persistant variables so we can track price and allow it to wander away from original data
	private double lastbid=0;
	private double lastorgbid=0;
	private long lastticktime=0;
    private int SymDigMod;
    
	//------------------------------------------------------------------------
	//------------------------------------------------------------------------
	//------------------------------------------------------------------------

	public RandomizeHistoryDataBounded() {
		super(MonteCarloTestTypes.ModifyData);
	}

	//------------------------------------------------------------------------

	@Override
	public void modifyData(IRandomGenerator rng, TickEvent tickEvent, double globalATR) {
		double ask = tickEvent.getAsk();
		double bid = tickEvent.getBid();
		double spread = ask - bid;
		double tickorgchange=0;
		long currentticktime = tickEvent.getTime();

		//bendedit: check if first tick, if not then set original tick change.
		if (lastticktime <= currentticktime && lastticktime!=0) {
			//bendedit: calculate the price change from last original tick to the current tick from original data
			tickorgchange=bid-lastorgbid;

		} else { 
			//bendedit: in case of first tick there is no change.
			lastbid=bid;
			tickorgchange=0;
		}

		//bendedit:set last original data bid in to variable before we change bid, we only need it to calculate the price change next time.
		lastorgbid=bid;

		//bendedit:store the ticktime.
		lastticktime = currentticktime;

		int change;

		if(MaxChange <= 0) {
			MaxChange = 1;
		}
		
		change = rng.nextInt(MaxChange);

		double dblChange = ((double) change)/ 100.0d; 

		//bendedit: Modding every tick and allowing price to move far away from original data therefore we need to use much smaller adjustments.
		//bendedit: I chose a percent of a percent
		//bendedit: changed from using ATR to just use tick price change of original data.
		double priceChange = Math.abs(tickorgchange) * dblChange;
		double boundPrice = (BoundPercent / 100) * lastorgbid;

		//kbtechit: calculate probabilistic based direction for priceChange
		int rngNum = rng.nextInt(-99, 100, 1);
		int centerNum = (int) (((lastbid - lastorgbid) / boundPrice) * 100);

		if(rngNum > centerNum){
			//kbtechedit: positive adjustment
			bid = lastbid + tickorgchange + priceChange;
		}
		else{
			//kbtechedit: negative adjustment
			bid = lastbid + tickorgchange - priceChange;
		}

		//kbtechedit: check for bound breaches
		if(lastorgbid + boundPrice < bid){
			//kbtechedit: upper bound breached
			bid = lastorgbid + boundPrice;
		}
		else if(lastorgbid - boundPrice > bid){
			//kbtechedit: lower bound breached
			bid = lastorgbid - boundPrice;
		}


         //bendedit:set last bid in to variable for next time undrounded
         lastbid = bid; 

         //round to proper tick for engine
         bid = SQUtils.round(bid, SymDigMod);

         //set modded bid and ask for further processing
         tickEvent.setBid(bid);
         tickEvent.setAsk(bid + spread);		
	}

	//------------------------------------------------------------------------
	
    public void initSettings(SettingsMap settings) {
        super.initSettings(settings);

        // Get symbolinfo for digits
        ChartSetup chartSetup = (ChartSetup) settings.get(SettingsKeys.BacktestChart);
        ChartDef chart = chartSetup.getMainChart();
        InstrumentInfo symbolInfo = chart.getSymbolInfo();
        SymDigMod = symbolInfo.decimals;
    }

	//------------------------------------------------------------------------

	/**
	 * Clones this MC retest object
	 *
	 * @return the clone
	 * @throws Exception the exception
	 */
	@Override
	public RandomizeHistoryDataBounded getClone() throws Exception {
		RandomizeHistoryDataBounded mc = new RandomizeHistoryDataBounded();
		mc.BoundPercent = this.BoundPercent;
		mc.MaxChange = this.MaxChange;
		return mc;
	}	
}
