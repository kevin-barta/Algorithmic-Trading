package SQ.CustomAnalysis;

import com.strategyquant.lib.*;

import java.util.ArrayList;

import java.io.File;
import org.apache.commons.lang3.ArrayUtils;

import com.strategyquant.datalib.*;
import com.strategyquant.tradinglib.*;
import com.strategyquant.tradinglib.strategy.StrategyLoader;
import com.strategyquant.tradinglib.project.ProjectEngine;
import com.strategyquant.tradinglib.project.SQProject;

public class Load extends CustomAnalysisMethod {

	//------------------------------------------------------------------------
	//------------------------------------------------------------------------
	//------------------------------------------------------------------------
	
	private String filePath = "C:/Users/Kevin/Desktop/Algo Business/SQX/Seasonality v0.5/SQX Debug Projects/";

	public Load() {
		super("Load", TYPE_FILTER_STRATEGY);
	}
	
	//------------------------------------------------------------------------
	
	@Override
	public boolean filterStrategy(String project, String task, String databankName, ResultsGroup rg) throws Exception {
		String[] taskNames;
		String[] pathnames;

		//Get list of tasks
		File ftasks = new File(filePath + project + "/");
        taskNames = ftasks.list();

		for(int j = 0; j < taskNames.length; j++){
			//Get list of strategies and Holdout folder
        	File fstrategy = new File(filePath + project + "/" + taskNames[j] + "/");
        	pathnames = fstrategy.list();

			//if Holdout is already tested on this task, skip
			if(ArrayUtils.contains(pathnames, "Holdout")){
				continue;
			}

			int i = 0;
			StrategyLoader sl = new StrategyLoader();
			while(i < pathnames.length){
				//ResultsGroup rg = loadStrategy(SQProject paramSQProject, String paramString1, String paramString2, double paramDouble);
				ResultsGroup rgNew = sl.loadStrategy(ProjectEngine.get(project), pathnames[i].substring(0, pathnames[i].length() - 4), filePath + project + "/" + taskNames[j] + "/" + pathnames[i], 100.0D);

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
				targetDB.add(rgNew, true);

				i++;
			}
			break;
		}
		return true;
	}
	
	
	//------------------------------------------------------------------------
	
	@Override
	public ArrayList<ResultsGroup> processDatabank(String project, String task, String databankName, ArrayList<ResultsGroup> databankRG) throws Exception {
		return databankRG;
	}
}