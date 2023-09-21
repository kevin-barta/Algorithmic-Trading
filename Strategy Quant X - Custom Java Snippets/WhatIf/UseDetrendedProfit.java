package SQ.WhatIf;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.strategyquant.tradinglib.ClassConfig;
import com.strategyquant.tradinglib.Help;
import com.strategyquant.tradinglib.Order;
import com.strategyquant.tradinglib.OrdersList;
import com.strategyquant.tradinglib.Parameter;
import com.strategyquant.tradinglib.WhatIf;
import com.strategyquant.tradinglib.SQStats;
import com.strategyquant.lib.SQUtils;

import com.strategyquant.lib.*;
import com.strategyquant.datalib.session.*;

import java.util.List;

import it.unimi.dsi.fastutil.objects.ObjectListIterator;

@ClassConfig(name="Use Detrended Profit", display="Use Detrended Profit")
@Help("Use Detrended Profit")
public class UseDetrendedProfit extends WhatIf {

	@Parameter(name="TimeFrame", defaultValue="H1")
	public String tf;

	@Parameter(defaultValue="1", minValue=1, name="Start Day", maxValue=31, step=1, category="Default")
	public int StartDay;

	@Parameter(defaultValue="1", minValue=1, name="Start Month", maxValue=12, step=1, category="Default")
	public int StartMonth;

	@Parameter(defaultValue="2007", minValue=1900, name="Start Year", maxValue=2200, step=1, category="Default")
	public int StartYear;

	@Parameter(defaultValue="31", minValue=1, name="End Day", maxValue=31, step=1, category="Default")
	public int EndDay;

	@Parameter(defaultValue="12", minValue=1, name="End Month", maxValue=12, step=1, category="Default")
	public int EndMonth;

	@Parameter(defaultValue="2018", minValue=1900, name="End Year", maxValue=2200, step=1, category="Default")
	public int EndYear;

	@Parameter(name="Use OOS Dates", defaultValue="false")
	public boolean useOOS;

	@Parameter(defaultValue="1", minValue=1, name="OOS Day", maxValue=31, step=1, category="Default")
	public int OOSDay;

	@Parameter(defaultValue="1", minValue=1, name="OOS Month", maxValue=12, step=1, category="Default")
	public int OOSMonth;

	@Parameter(defaultValue="2013", minValue=1900, name="OOS Year", maxValue=2200, step=1, category="Default")
	public int OOSYear;

	@Parameter(name="Use Fixed Net Profit", defaultValue="false")
	@Help("Use Fixed Detrended Net Profit")
	public boolean useDetrendedNetProfit;

	@Parameter(name="Size Per Year", defaultValue="1000", minValue=100, maxValue=100000, step=1)
	public double SizePerYear;

	@Parameter(name="Multiplier Decimals", defaultValue="2", minValue=0, maxValue=6, step=1)
	@Help("Multiplier Decimals in Order Comment")
	public int Decimals;

	@Parameter(name="PointValue", defaultValue="0", minValue=0.00001, maxValue=100000, step=1)
	public double PointValueFix;



	SQUtils utils = new SQUtils();  
	long dayINms = 86400000;
	double pointValue = 0;
	double pointValueCount = 0;

	@Override
	public void filter(OrdersList orders) throws Exception {
		// Merge day, month and year to string
		String from = String.format("%02d", StartDay) + "." + String.format("%02d", StartMonth) + "." + String.format("%04d", StartYear);
		String to = String.format("%02d", EndDay) + "." + String.format("%02d", EndMonth) + "." + String.format("%04d", EndYear);
		String oos = String.format("%02d", OOSDay) + "." + String.format("%02d", OOSMonth) + "." + String.format("%04d", OOSYear);

		// Get symbol from order
		String symbol = "";
		for(ObjectListIterator<Order> i = orders.listIterator(); i.hasNext();) {
			Order order = i.next();
			symbol = order.Symbol;
			break;
		}

		Log.info("\nExample - Strategy last backtest setting: {} / {}, from: {}, to: {}", symbol, tf, from, to);

		// simple example of using HistoryDataLoader to load historical data for given symbol and timeframe
		try {
            HistoryDataLoader loader = new HistoryDataLoader();
            Log.info("Loading started ...");
			Log.info("\n from: {}", SQTime.parseToMilis​(from, "dd.MM.yyyy"));
			Log.info("\n to: {}", SQTime.parseToMilis​(to, "dd.MM.yyyy"));
            HistoryOHLCData data = loader.get(symbol, tf, SQTime.parseToMilis​(from, "dd.MM.yyyy"), SQTime.parseToMilis​(to, "dd.MM.yyyy") + dayINms, Session.NoSession);

            // we use this to get the length of the data
            int dataLength = data.Time.length;
            Log.info("Loaded data length: {}", dataLength);
			// OOS calculations
			long oosfrom = SQTime.parseToMilis​(oos, "dd.MM.yyyy");
			int oosDataLength = 0;
			if(useOOS){
				for(int i=0;i<dataLength; i++) {
					if(data.Time[i] >= oosfrom){
						oosDataLength = i;
						break;
					}
				}
			}

			// go through data
			float priceStart = data.Open[0];
			float priceEnd = data.Close[dataLength - 1];
			float priceOOS = data.Open[oosDataLength];
			
			// calculate mean priceDiff which will be used to detrend
			double priceDiff, priceDiffOOS = 0;
			if(!useOOS){
				priceDiff = (priceStart - priceEnd)/(dataLength - 1);
            	Log.info("{} - {}, {}", priceStart, priceEnd, priceDiff);
			}
			else{
				priceDiff = (priceStart - priceOOS)/(oosDataLength - 1);
				priceDiffOOS = (priceOOS - priceEnd)/(dataLength - oosDataLength - 1);
            	Log.info("{} - {} - {}, {} {}", priceStart, priceOOS, priceEnd, priceDiff, priceDiffOOS);
			}

			// for each order detrend using mean
			int k = 0;
			for(ObjectListIterator<Order> i = orders.listIterator(); i.hasNext();) {
				Order order = i.next();
				PointValue(order);
				for(int j=k;j<dataLength; j++) {
					//find count of tf bars till order Time.
   					if(data.Time[j] == order.OpenTime){
						//detrend using (j) counts of mean price
						order.OpenPrice += (useOOS && (oosDataLength <= j)) ? ((priceStart - priceOOS) + priceDiffOOS * (j - oosDataLength)) : priceDiff * j;
						//order.OpenPrice += priceDiff * j;
					}
					if(data.Time[j] == order.CloseTime){
						//detrend using (j) counts of mean price
						order.ClosePrice += (useOOS && (oosDataLength <= j)) ? ((priceStart - priceOOS) + priceDiffOOS * (j - oosDataLength)) : priceDiff * j;
						//order.ClosePrice += priceDiff * j;
						k = j;
						break;
					}
				}
			}



			// Use fixed Net Profit
			// Calculate the Strategy current Net Profit
			if(useDetrendedNetProfit){
				pointValue = utils.safeDivide(pointValue, pointValueCount);
				Log.info("Point Value: {}", pointValue);
				if(PointValueFix != 0){
					pointValue = PointValueFix;
					Log.info("Point Value: {}", pointValue);
				}
				double netProfit = 0;
				for(int i = 0; i<orders.size(); i++) {
					Order order = orders.get(i);
			
					if(order.isBalanceOrder()) {
						// don't count balance orders (deposits, withdrawals) in
						continue;
					}

					// calculate order netprofit with new detrended prices
					if(order.getDirection() == 1){
						netProfit += (order.ClosePrice - order.OpenPrice) * order.Size * pointValue + order.CommSwap;
					}
					else{
						netProfit += (order.OpenPrice - order.ClosePrice) * order.Size * pointValue + order.CommSwap;
					}
				}
				netProfit = utils.round2(netProfit);
				Log.info("Net Profit: {}", netProfit);

				// Calculate Multiplier
				double years = (SQTime.parseToMilis​(to, "dd.MM.yyyy") - SQTime.parseToMilis​(from, "dd.MM.yyyy")) / (365.25 * dayINms);
				Log.info("Years: {}", years);
				double adjustMultiplier = utils.safeDivide(SizePerYear * years, netProfit);
				if(adjustMultiplier <= 0 || adjustMultiplier >= 20){
					adjustMultiplier = 1;
				}

				// Adjust Order PL & Size to fixed Net Profit
				for(ObjectListIterator<Order> i = orders.listIterator(); i.hasNext();) {
					Order order = i.next(); 	
			  
					order.Comment = "{" + utils.round(adjustMultiplier, Decimals + 1) + "}";
					order.CommSwap = (order.CommSwap/order.Size) * (float)utils.round(order.Size * adjustMultiplier, Decimals);
					order.Size = (float)utils.round(order.Size * adjustMultiplier, Decimals);
				}
			}



        } catch(HistoryDataNotAvailableExeption e) {
            Log.error("Error loading data.", e);
        }
	}


	

	// Get point value (using avg for accuracy)
	void PointValue(Order order) {
		if(order.ClosePrice - order.OpenPrice != 0){
			if(order.getDirection() == 1){
				// Buy Order
				pointValue += (order.PL - order.CommSwap) / ((order.ClosePrice - order.OpenPrice) * order.Size);
			}
			else{
				// Sell Order
				pointValue += (order.PL - order.CommSwap) / ((order.OpenPrice - order.ClosePrice) * order.Size);
			}
			pointValueCount++;
		}
	}
}