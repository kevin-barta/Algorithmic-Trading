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
package SQ.MoneyManagement;

import com.strategyquant.lib.SQUtils;
//import com.strategyquant.datalib.*;
import com.strategyquant.tradinglib.*;
import java.lang.Math;
import com.strategyquant.lib.XMLUtil;
import org.jdom2.Element;
import com.strategyquant.tradinglib.Order;
import com.strategyquant.tradinglib.OrdersList;
import it.unimi.dsi.fastutil.objects.ObjectListIterator;

@ClassConfig(name="Close Fixed Sizing", display="Close Fixed Sizing: #Size# lot with multiplication #Multiplier#")
@Help("<b>ATR Volatility Sizing</b>")
@Description("ATR Volatility Sizing, #Size# lot and #Multiplier#")
@SortOrder(700)
public class CloseFixedSizing extends MoneyManagementMethod {

	@Parameter(defaultValue="0.1", minValue=0.0001d, name="Order size", maxValue=1000000d, step=0.1d, category="Default")
	@Help("Order size (number of lots for forex)")
	public double Size;

	@Parameter(defaultValue="2", minValue=0d, name="Size Decimals", maxValue=6d, step=1d, category="Default")
	@Help("Order size will be rounded to the selected number of decimal places before multiplying")
	public int Decimals;

	@Parameter(defaultValue="1", minValue=0.0001d, name="Multiplier", maxValue=100, step=0.1d, category="Default")
	@Help("Multiplier")
	public double Multiplier;

	@Parameter(defaultValue="1", minValue=0.01d, name="Buy Multiplier", maxValue=1000, step=0.1d, category="Default")
	@Help("Multiplier used to equalize Buy/Sell ratio in Robustness Verification")
	public double BuyMultiplier;

	@Parameter(defaultValue="1", minValue=0.01d, name="Sell Multiplier", maxValue=1000, step=0.1d, category="Default")
	@Help("Multiplier used to equalize Buy/Sell ratio in Robustness Verification")
	public double SellMultiplier;



	//------------------------------------------------------------------------
	//------------------------------------------------------------------------
	//------------------------------------------------------------------------
	
	@Override
	public double computeTradeSize(StrategyBase strategy, String symbol, byte orderType, double price, double sl, double tickSize, double pointValue) throws Exception {
		if(Size < 0) {
			throw new Exception("Money management wasn't properly initialized. Call init() method before computing trade size!");
		}

		double tradeSize;

		// get order list
		OrdersList orders = strategy.Trader.getHistoryOrders();

		// get open price
		double openPrice = 0;
		for(ObjectListIterator<Order> i = orders.listIterator(); i.hasNext();) {
			Order order = i.next();
			openPrice = order.OpenPrice;
			break;
		}

		// simple example of using HistoryDataLoader to load historical data for given symbol and timeframe
		/*try {
            HistoryDataLoader loader = new HistoryDataLoader();
            Log.info("Loading started ...");
			Log.info("\n from: {}", SQTime.parseToMilis​(from, "dd.MM.yyyy"));
			Log.info("\n to: {}", SQTime.parseToMilis​(to, "dd.MM.yyyy"));
            HistoryOHLCData data = loader.get(symbol, tf, SQTime.parseToMilis​(from, "dd.MM.yyyy"), SQTime.parseToMilis​(to, "dd.MM.yyyy") + dayINms, Session.NoSession);

			float priceStart = data.Open[0];

		} catch(HistoryDataNotAvailableExeption e) {
            Log.error("Error loading data.", e);
        }*/

		//Adjust Multiplier to UseFixedNetProfit
		String name = strategy.getStrategyName();
		if(name.contains("{") && name.contains("}")){
			int i = name.indexOf("{") + 1;
			int j = name.indexOf("}");
			Multiplier = Double.parseDouble(name.substring(i, j));
		}

		// set trade size rounded to correct decimals
		//tradeSize = SQUtils.round(Size * (openPrice / price) * Multiplier, Decimals);
		double openTradePrice = price > 0 ? price : (OrderTypes.isLongOrder(orderType) ? strategy.MarketData.Chart(symbol).Ask() : strategy.MarketData.Chart(symbol).Bid());
		if(openPrice == 0){
			tradeSize = SQUtils.round(Size * Multiplier, Decimals);
		}
		else{
			tradeSize = SQUtils.round(Size * (openPrice / openTradePrice) * Multiplier, Decimals);
		}

		if(tradeSize <= 0){
			tradeSize = Math.pow(10, -Decimals);
		}

		//Multipliers used to equalize Buy/Sell ratio, mainly used for Robustness Verification on Holdout/IS Data
		if(BuyMultiplier != 1 && orderType == 0x1)
			tradeSize *= BuyMultiplier;
		if(SellMultiplier != 1 && orderType == 0x2)
			tradeSize *= SellMultiplier;

		return tradeSize;
		
	}
	
}
