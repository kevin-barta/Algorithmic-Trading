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

@ClassConfig(name="ATR Volatility Sizing", display="ATR Volatility Sizing: #RiskedMoney# $ with multiplication #Multiplier#")
@Help("<b>ATR Volatility Sizing</b>")
@Description("ATR Volatility Sizing, #RiskedMoney# $ and #Multiplier#")
@SortOrder(600)
public class ATRVolatilitySizing extends MoneyManagementMethod {

	@Parameter(defaultValue="100", minValue=0.01d, name="RiskedMoney", maxValue=1000d, step=0.5d, category="Default")
	@Help("Risk in $")
	public double RiskedMoney;

	@Parameter(defaultValue="0", minValue=0d, name="RiskPercent", maxValue=100000d, step=0.1d, category="Default")
	@Help("Risk in % of account per trade")
	public double Risk;

	@Parameter(defaultValue="1", minValue=0d, name="Size Decimals", maxValue=6d, step=1d, category="Default")
	@Help("Order size will be rounded to the selected number of decimal places before multiplying")
	public int Decimals;

	@Parameter(defaultValue="1", minValue=0.0001d, name="Multiplier", maxValue=100, step=0.1d, category="Default")
	@Help("Multiplier")
	public double Multiplier;

	@Parameter(defaultValue="520", minValue=2, name="ATR Period", maxValue=520, step=1, category="Default")
	@Help("ATR Period")
	public int ATRPeriod;

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
		if(RiskedMoney < 0) {
			throw new Exception("Money management wasn't properly initialized. Call init() method before computing trade size!");
		}

		double tradeSize;
		
		//Current Account Balance
		double currentBalance = strategy.Trader.getAccountBalance();

		// get ATR
		double valueATR = (  strategy.getATRValue(strategy.MarketData.Chart(symbol),ATRPeriod, 1) + strategy.getATRValue(strategy.MarketData.Chart(symbol),520, 1)  ) / 2;
		//double valueATR = strategy.getATRValue(strategy.MarketData.Chart(symbol),ATRPeriod, 1);

		//Adjust Multiplier to UseFixedNetProfit
		String name = strategy.getStrategyName();
		if(name.contains("{") && name.contains("}")){
			int i = name.indexOf("{") + 1;
			int j = name.indexOf("}");
			Multiplier = Double.parseDouble(name.substring(i, j));

			/*Element elParams = getXML().getChild("Method");
			XMLUtil.trySetAttr​(elParams.getChild("Params").getChildren().get(3), "value", Multiplier);
			try{
				setMethodFromXML​​(elParams);
			}
			catch(Exception e) {
				fdebug("testException",e.toString());
			}
			fdebug("testMM1", XMLUtil.elementToString(elParams));*/
		}

		// set trade size rounded to correct decimals
		if(Risk == 0){
			tradeSize = SQUtils.round((RiskedMoney/pointValue) / valueATR*Multiplier, Decimals);
		}
		else{
			tradeSize = SQUtils.round(((currentBalance * Risk / 100)/pointValue) / valueATR*Multiplier, Decimals);
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
