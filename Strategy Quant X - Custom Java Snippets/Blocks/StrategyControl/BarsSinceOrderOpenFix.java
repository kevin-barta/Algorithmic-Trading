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
package SQ.Blocks.StrategyControl;

import SQ.Functions.OrderFunctions;
import SQ.Internal.ValueBlock;

import com.strategyquant.lib.*;
import com.strategyquant.datalib.*;
import com.strategyquant.tradinglib.*;

//import org.slf4j.Logger;
//import org.slf4j.LoggerFactory;

@BuildingBlock(display="BarsSinceOrderOpen(#Symbol#, #MagicNumber#, #Direction#, \"#Comment#\")", returnType = ReturnTypes.Number)
@Help("Returns number of bars since the specified order was opened.")
@SortOrder(400)
@IgnoreInBuilder
public class BarsSinceOrderOpenFix extends ValueBlock {
	
	@Parameter(defaultValue="Current", category="Order identification", showIfDefault=false, allowAny=true)
	public String Symbol;
	
	@Parameter(defaultValue="0", category="Order identification", showIfDefault=false)
	@Editor(type=Editors.Selection, values="Long=1,Short=-1,Any=0")
	public int Direction;
	
	@Parameter(defaultValue="MagicNumber", category="Order identification", showIfDefault=false)
	@Help("Magic number that can identify the order.")
	@Editor(type=Editors.SelectionVariablesWithAny)
	public int MagicNumber;

	@Parameter(defaultValue="", category="Order identification", showIfDefault=false)
	@Help("Comment can be also used to identify the order. In case of Comment, order matches if the order comments contains the text specified here.")
	public String Comment;
	
	//------------------------------------------------------------------------
	//------------------------------------------------------------------------
	//------------------------------------------------------------------------

	//public static final Logger Log = LoggerFactory.getLogger("BarsSinceOrderOpenFix");

	@Override
	public double OnBlockEvaluate(int relativeShift) throws TradingException {

		long hour = 3600000;//60 * 60 * 1000 (millisecs to 1 hour)
		ILiveOrder order = OrderFunctions.findLiveOrder(Strategy, Symbol, Direction, MagicNumber, Comment);
		if(order != null) {
			long orderTime = Strategy.TimeCurrent() - order.getOpenTime();
			int numberOfBars = 0;

			for(long i=order.getOpenTime(); i<Strategy.TimeCurrent(); i += hour) {
				if(SQTime.getDayOfWeekOriginal(i) == 6) {//check if Saturday
					orderTime -=  (48 * hour);//-48h for weekend gap
					break;
				}
			}

			//Log.debug(String.valueOf(Strategy.TimeCurrent()) + "  w  " + String.valueOf(order.getOpenTime()));

			numberOfBars = (int) (orderTime / hour);
			return(numberOfBars);
		}
		
		return(-1);
	}

}
