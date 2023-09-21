package SQ.CustomAnalysis;

import com.strategyquant.lib.*;

import java.util.ArrayList;

import com.strategyquant.tradinglib.results.SpecialValues;
import it.unimi.dsi.fastutil.objects.ObjectListIterator;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.strategyquant.datalib.*;
import com.strategyquant.tradinglib.*;
import com.strategyquant.datalib.session.*;

public class DetrendStrategy extends CustomAnalysisMethod {

	//------------------------------------------------------------------------
	//------------------------------------------------------------------------
	//------------------------------------------------------------------------
	
    /**
     * set the type of CA snippet here - it is either used as:
     * - strategy filter - it will call filterStrategy() method for one strategy
     * - databank processor - it will call processDatabank() for all strategies in databank
     * 
     * Uncomment the one you want to use.
     */
	public DetrendStrategy() {
		super("DetrendStrategy", TYPE_FILTER_STRATEGY);
		//super("DetrendStrategy", TYPE_PROCESS_DATABANK);
	}
	
	//------------------------------------------------------------------------
	
	@Override
	public boolean filterStrategy(String project, String task, String databankName, ResultsGroup rg) throws Exception {
		// another useful example - how to get symbol/TF from the strategy ?

		/**
     	* Example on how to retrieve symbol, TF and from-to date ranges from strategy.
     	* You can then later use it to load history data.
     	*/
        if(rg == null) {
            return false;
        }
        try {
            SettingsMap settings = rg.specialValues();
            String symbol = rg.mainResult().getString(SpecialValues.Symbol, "N/A");
            String tf = rg.mainResult().getString(SpecialValues.Timeframe, "N/A");
            long from = settings.getLong(SpecialValues.HistoryFrom);
            long to = settings.getLong(SpecialValues.HistoryTo);
            Log.info("\nExample - Strategy last backtest setting: {} / {}, from: {}, to: {}", symbol, tf, SQTime.toDateString(from), SQTime.toDateString(to));

			// simple example of using HistoryDataLoader to load historical data for given symbol and timeframe
			try {
            	HistoryDataLoader loader = new HistoryDataLoader();
            	Log.info("Loading started ...");
            	HistoryOHLCData data = loader.get(symbol, tf, from, to, Session.NoSession);
            	// we use this to get the length of the data
            	int dataLength = data.Time.length;
            	Log.info("Loaded data length: {}", dataLength);
            	// go through data
				float priceStart = data.Open[0];
				float priceEnd = data.Close[dataLength - 1];
				//fix for loss in percent
				double percentDiff = 0;
				percentDiff = (priceStart > priceEnd) ? (priceStart/priceEnd) : (priceEnd/priceStart);
				percentDiff = ((percentDiff - 1) / dataLength) * -1;
                Log.info("{} - {}, {}", priceStart, priceEnd, percentDiff);

				for(ObjectListIterator<Order> i = rg.orders().listIterator(); i.hasNext();) {
					Order order = i.next();
					int count = 0;
					//count number of "tf" bars in trade
					for(int j=0; j<dataLength; j++) {
   						if(data.Time[j] == order.OpenTime && count == 0){
							count -= j;
						}
						else if(data.Time[j] == order.CloseTime && count != 0){
							count += j;
							break;
						}
					}
					order.PL *= ((percentDiff * count) + 1);
				}

        	} catch(HistoryDataNotAvailableExeption e) {
            	Log.error("Error loading data.", e);
        	}
		} catch(Exception e) {
            Log.error("Exception", e);
        }


		return true;
	}
	
	
	//------------------------------------------------------------------------
	
	@Override
	public ArrayList<ResultsGroup> processDatabank(String project, String task, String databankName, ArrayList<ResultsGroup> databankRG) throws Exception {
		return databankRG;
	}

	//------------------------------------------------------------------------  
}