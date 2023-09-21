package SQ.CustomAnalysis;

import com.strategyquant.lib.*;

import java.util.ArrayList;

import com.strategyquant.datalib.*;
import com.strategyquant.tradinglib.*;

import com.strategyquant.pluginlib.program.IProgram;
import com.strategyquant.pluginlib.program.Program;

import SQ.TradingOptions.*;
import com.strategyquant.datalib.TimeframeManager;
import com.strategyquant.datalib.consts.Precisions;
import com.strategyquant.datalib.session.Session;
import com.strategyquant.lib.SettingsMap;
import com.strategyquant.lib.time.SQTimeOld;
import com.strategyquant.tradinglib.engine.BacktestEngine;
import com.strategyquant.tradinglib.moneymanagement.MoneyManagementMethodsList;
import com.strategyquant.tradinglib.options.TradingOptions;
import com.strategyquant.tradinglib.simulator.Engines;
import com.strategyquant.tradinglib.simulator.ITradingSimulator;
import com.strategyquant.tradinglib.simulator.impl.*;
import com.strategyquant.tradinglib.project.ProjectEngine;
import com.strategyquant.tradinglib.project.SQProject;
import org.jdom2.Element;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.strategyquant.lib.XMLUtil;

public class SaveAndHoldout extends CustomAnalysisMethod {

	//------------------------------------------------------------------------
	//------------------------------------------------------------------------
	//------------------------------------------------------------------------
	
	private String filePath = "C:/Users/Kevin/Desktop/Algo Business/SQX/Seasonality v0.5/SQX Projects/";

	public SaveAndHoldout() {
		super("SaveAndHoldout", TYPE_FILTER_STRATEGY);
	}
	
	//------------------------------------------------------------------------
	
	@Override
	public boolean filterStrategy(String project, String task, String databankName, ResultsGroup rg) throws Exception {
		IProgram saver = Program.get("Saver");
        saver.call("saveFile", rg, filePath + project + "/" + task + "/" + rg.getName() + ".sqx", true);

		//rg.getLastSettings();
		
		// get first strategy in databank to perform retest on it
		ResultsGroup strategyToRetest = rg;

		// we'll store all settings for new backtest in this SettingsMap
		SettingsMap settings = new SettingsMap();

		// prepare chart setup for backtest - you must specify the data name, range, etc
		ChartSetup chartSetup = new ChartSetup(
				"History", // this is constant
				"@EURUSD", // symbol name, must match the name in Data Manager
				TimeframeManager.TF_H1, // timeframe
				SQTimeOld.toLong(2008, 4, 20), // date from
				SQTimeOld.toLong(2009, 6, 29), // date to
				3.5, // spread
				Session.Forex_247 // session
		);
		settings.set(SettingsKeys.BacktestChart, chartSetup);


		// prepare other backtest settings - this will put other optional/required parts to the settings map
		prepareBacktestSettings(settings, strategyToRetest);

		/*String strategyName = rg.getName();
		Element elStrategy = rg.getStrategyXml();
		if(elStrategy == null) {
			// result doesn't have any strategy, cannot be tested
			throw new Exception("Result doesn't have any strategy, cannot be tested!");
		}
		StrategyBase strategy = StrategyBase.createXmlStrategy(elStrategy.clone(), strategyName);
		settings.set(SettingsKeys.StrategyObject, strategy);*/

		//settings = rg.mainResult().getSettings().clone();

		fdebug("ttst", XMLUtil.elementToString(rg.mainResult().getSettings().getXML()));

		// create trading simulator (later used for backtest engine)
		ITradingSimulator simulator = new MetaTrader5SimulatorNetting(OrderExecutionTypes.EXCHANGE);
		// simulators available:
		//MetaTrader4Simulator()
		//MetaTrader5SimulatorHedging(OrderExecutionTypes.EXCHANGE)
		//MetaTrader5SimulatorNetting(OrderExecutionTypes.EXCHANGE)
		//TradestationSimulator()
		//MultiChartsSimulator()
		//JForexSimulator()


		// set testing precision for the simulator
		simulator.setTestPrecision(Precisions.getPrecision(Precisions.PRECISION_BASE_TF));
		// Precisions available (depending also on data - you cannot use tick precision if you don't have tick data):
		//PRECISION_SELECTED_TF = "Selected timeframe only (fastest)";
		//PRECISION_BASE_TF = "1 minute data tick simulation (slow)";
		//PRECISION_TICK_CUSTOM_SPREADS = "Real Tick - custom spread (slowest)";
		//PRECISION_TICK_REAL_SPREADS = "Real Tick - real spread (slowest)";
		//PRECISION_OPEN_PRICES = "Trade On Bar Open";


		// create backtest engine using simulator
		BacktestEngine backtestEngine = new BacktestEngine(simulator);
		backtestEngine.setSingleThreaded(true);

		// add backtest settings to the engine
		backtestEngine.addSetup(settings);


		// ------------------------
		// run backtest - this will run the actual backtest using the settings configured above
		// Depending on the settings it could take a while.
		// When finished, it will return new ResultsGroup object with backtest result.
		// In case of error an Exception is thrown with the description of the error
		ResultsGroup backtestResultRG = backtestEngine.runBacktest().getResults();

		// 2. You can save the new backtest to a databank or file
		SQProject project1 = ProjectEngine.get(project);
		if(project1 == null) {
			throw new Exception("Project '"+project1+"' cannot be loaded!");
		}

		Databank targetDB = project1.getDatabanks().get("Results");
		if(targetDB == null) {
			throw new Exception("Target databank 'Results' was not found!");
		}

		// add the new strategy+backtest to this databank and refresh the databank grid
		targetDB.add(backtestResultRG, true);

		return true;
	}
	
	
	//------------------------------------------------------------------------
	
	@Override
	public ArrayList<ResultsGroup> processDatabank(String project, String task, String databankName, ArrayList<ResultsGroup> databankRG) throws Exception {
		return databankRG;
	}

	//------------------------------------------------------------------------

	private void prepareBacktestSettings(SettingsMap settings,ResultsGroup strategyToRetest) throws Exception {
		// creates strategy object from strategy XML that is stored in the source ResultsGroup
		String strategyName = strategyToRetest.getName();
		Element elStrategy = strategyToRetest.getStrategyXml();
		if(elStrategy == null) {
			// result doesn't have any strategy, cannot be tested
			throw new Exception("Result doesn't have any strategy, cannot be tested!");
		}
		StrategyBase strategy = StrategyBase.createXmlStrategy(elStrategy.clone(), strategyName);
		settings.set(SettingsKeys.StrategyObject, strategy);


		settings.set(SettingsKeys.MinimumDistance, 0);

		// set initial capital and Money management
		settings.set(SettingsKeys.InitialCapital, 100000d);
		settings.set(SettingsKeys.MoneyManagement, MoneyManagementMethodsList.create("FixedSize", 0.1));
		// Note - you can create a different Money Managemtn method by specifying its (snippet) name
		// and parameters in their exact order, for example:
		// MoneyManagementMethodsList.create("RiskFixedPctOfAccount", 5, 100, 0.1, 0.5))


		// create and set required trading options
		TradingOptions options = createTradingOptions();
		settings.set(SettingsKeys.TradingOptions, options);
	}

	//------------------------------------------------------------------------

	private TradingOptions createTradingOptions() {
		TradingOptions options = new TradingOptions();

		// all trading options are defined as snippets
		// in SQ.TradingOptions.* (visible in CodeEditor)
		// below is an example of few of them applied
		ExitAtEndOfDay option = new ExitAtEndOfDay();
		option.ExitAtEndOfDay = true;
		option.EODExitTime = 0;
		options.add(option);

		ExitOnFriday option2 = new ExitOnFriday();
		option2.ExitOnFriday = true;
		option2.FridayExitTime = 0;
		options.add(option2);

		LimitTimeRange option3 = new LimitTimeRange();
		option3.LimitTimeRange = true;
		option3.SignalTimeRangeFrom = 700;
		option3.SignalTimeRangeTo = 1900;
		option3.ExitAtEndOfRange = true;
		options.add(option3);

		MinMaxSLPT optionMmSLPT = new MinMaxSLPT();
		optionMmSLPT.MinimumSL = 50;
		optionMmSLPT.MaximumSL = 100;
		optionMmSLPT.MinimumPT = 50;
		optionMmSLPT.MaximumPT = 100;
		options.add(optionMmSLPT);

		return options;
	}
}