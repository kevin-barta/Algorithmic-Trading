package SQ.CustomAnalysis;

import com.strategyquant.lib.*;

import com.strategyquant.tradinglib.correlation.*;

import java.util.List;
import java.util.ArrayList;
import java.util.Iterator;

import com.strategyquant.datalib.*;
import com.strategyquant.tradinglib.*;
import com.strategyquant.tradinglib.results.*;
import com.strategyquant.tradinglib.results.SpecialValues;

import com.strategyquant.tradinglib.CorrelationLib;
import com.strategyquant.tradinglib.CorrelationType;

import SQ.CorrelationOf.*;

public class MonthlyCorrelation97 extends CustomAnalysisMethod {

	//------------------------------------------------------------------------
	//------------------------------------------------------------------------
	//------------------------------------------------------------------------
	
	public MonthlyCorrelation97() {
		super("Monthly_P&L_Correlation<0.97", TYPE_PROCESS_DATABANK);
	}
	
	//------------------------------------------------------------------------
	
	@Override
	public boolean filterStrategy(String project, String task, String databankName, ResultsGroup rg) throws Exception {
		return true;
	}
	
	
	//------------------------------------------------------------------------
	
	@Override
	public ArrayList<ResultsGroup> processDatabank(String project, String task, String databankName, ArrayList<ResultsGroup> databankRG) throws Exception {
		// Check for correlated strategies using fitness score as a ranking/priority list
		ArrayList<ResultsGroup> rgSortedCandidates = new ArrayList<>(databankRG);

		rgSortedCandidates.sort((o1, o2) -> Double.valueOf(o1.getFitness()).compareTo(Double.valueOf(o2.getFitness())));
		
		ArrayList<ResultsGroup> rgSortedCandidatesRanked = new ArrayList();

		for(ResultsGroup rgSC : rgSortedCandidates) {
			rgSortedCandidatesRanked.add(0, rgSC);
		}
		
		ArrayList<ResultsGroup> rgUncorrelated = new ArrayList();
		// todo: multiple strategies could have the same fitness. this should be addressed using additional sorting (i.e. fitness > pf > ret/dd .. etc)

		while (rgSortedCandidatesRanked.size() > 0) {
			ResultsGroup focusStrat = rgSortedCandidatesRanked.get(0).clone();
			String focusStratName = focusStrat.getName();

			rgUncorrelated.add(focusStrat.clone()); // add the best strategy in the pool to the uncorrelated list as a starting point
			rgSortedCandidatesRanked.remove(0);

			Iterator<ResultsGroup> it = rgSortedCandidatesRanked.iterator();

			while(it.hasNext()) {
				ResultsGroup subStrat = it.next();

				String subStratName = subStrat.getName();

				if (subStratName != focusStratName) {
					CorrelationPeriods corrPeriods = new CorrelationPeriods();

					ProfitLoss corrType = new ProfitLoss();
					CorrelationComputer correlationComputer = new CorrelationComputer();

					/*
						CORRELATION PERIODS (CorrelationPeriodTypes.class):

						public static final int HOUR = 5;
						public static final int DAY = 10;
						public static final int WEEK = 20;
						public static final int MONTH = 30;
					*/
					
					// Monthly correlation periods
					CorrelationPeriods correlationPeriods = precomputePeriods(focusStrat, subStrat, 30, corrType);
					double corrValue = SQUtils.round2(correlationComputer.computeCorrelation(false, focusStratName, subStratName, focusStrat.orders(), subStrat.orders(), correlationPeriods));

					if (corrValue >= 0.97) {
						it.remove();
					}
				} else {
					it.remove();
				}
			}
		}

		return rgUncorrelated;
	}

	public CorrelationPeriods precomputePeriods(ResultsGroup paramResultsGroup1, ResultsGroup paramResultsGroup2, int paramInt, CorrelationType paramCorrelationType) throws Exception {
		CorrelationPeriods correlationPeriods = new CorrelationPeriods();
		TimePeriod timePeriod = CorrelationLib.getPeriod(paramResultsGroup1.orders());
		long l1 = timePeriod.from;
		long l2 = timePeriod.to;
		timePeriod = CorrelationLib.getPeriod(paramResultsGroup2.orders());
		if (timePeriod.from < l1)
		l1 = timePeriod.from; 
		if (timePeriod.to > l2)
		l2 = timePeriod.to; 
		TimePeriods timePeriods1 = CorrelationLib.generatePeriods(paramInt, l1, l2);
		TimePeriods timePeriods2 = timePeriods1.clone();
		paramCorrelationType.computePeriods(paramResultsGroup1.orders(), paramInt, timePeriods1);
		correlationPeriods.put(paramResultsGroup1.getName(), timePeriods1);
		paramCorrelationType.computePeriods(paramResultsGroup2.orders(), paramInt, timePeriods2);
		correlationPeriods.put(paramResultsGroup2.getName(), timePeriods2);
		return correlationPeriods;
	}
}