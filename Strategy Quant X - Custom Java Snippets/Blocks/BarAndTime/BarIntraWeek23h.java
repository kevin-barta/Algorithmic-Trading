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
package SQ.Blocks.BarAndTime;

import SQ.Internal.ConditionBlock;

import com.strategyquant.lib.*;
import com.strategyquant.datalib.*;
import com.strategyquant.tradinglib.*;

@BuildingBlock(display="BarIntraWeek[#Shift#] is #IntraWeekHour#", returnType = ReturnTypes.Boolean)
@SortOrder(200)
@IgnoreInBuilder
public class BarIntraWeek23h extends ConditionBlock {
	
	@Parameter
	public ChartData Chart;

	//NO 21h candles

	//0 = Sunday at 22h
	//114 = Friday at 20h
	@Parameter(minValue=-2, maxValue=116, defaultValue="0", step=1)
	public int IntraWeekHour;
	
	@Parameter
	public int Shift;
	
	@Override
	public boolean OnBlockEvaluate() throws TradingException {
		int Day = 0; //Sunday=0,Monday=1,Tuesday=2,Wednesday=3,Thursday=4,Friday=5,Saturday=6
		int Hour = 0; //minValue=0, maxValue=23
		
		while (IntraWeekHour < 0) IntraWeekHour += 115;
		IntraWeekHour = IntraWeekHour % 115; //For Sequential Optimization stability bug

		Day = (IntraWeekHour + 21) / 23;
		Hour =  (IntraWeekHour + 21) % 23;
		if (Hour == 21 || Hour == 22){ //Compenstate for no 21h candle
			Hour++;
		}

		return (SQTime.getDayOfWeekOriginal(Chart.Time(Shift)) == Day && SQTime.getHour(Chart.Time(Shift)) == Hour);
	}
}
