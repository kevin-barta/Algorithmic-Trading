package SQ.CustomAnalysis;

import com.strategyquant.lib.*;

import java.util.ArrayList;

import java.io.File;
import org.apache.commons.lang3.ArrayUtils;

import com.strategyquant.pluginlib.program.IProgram;
import com.strategyquant.pluginlib.program.Program;

import com.strategyquant.datalib.*;
import com.strategyquant.tradinglib.*;
import com.strategyquant.tradinglib.strategy.StrategyLoader;
import com.strategyquant.tradinglib.project.ProjectEngine;
import com.strategyquant.tradinglib.project.SQProject;

public class SaveFilteredHoldout extends CustomAnalysisMethod {

	//------------------------------------------------------------------------
	//------------------------------------------------------------------------
	//------------------------------------------------------------------------
	
	private String filePath = "C:/Users/Kevin/Desktop/Algo Business/SQX/Seasonality v0.5/SQX Debug Projects/";

	public SaveFilteredHoldout() {
		super("SaveFilteredHoldout", TYPE_PROCESS_DATABANK);
	}
	
	//------------------------------------------------------------------------
	
	@Override
	public boolean filterStrategy(String project, String task, String databankName, ResultsGroup rg) throws Exception {
		return true;
	}
	
	
	//------------------------------------------------------------------------
	
	@Override
	public ArrayList<ResultsGroup> processDatabank(String project, String task, String databankName, ArrayList<ResultsGroup> databankRG) throws Exception {
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
			if(ArrayUtils.contains(pathnames, "FilteredHoldout")){
				continue;
			}
			else{
				IProgram saver = Program.get("Saver");

				//save full databank of holdout passing strategies
				int i = 0;
				while(i < databankRG.size()){
        			saver.call("saveFile", databankRG.get(i), filePath + project + "/" + taskNames[j] + "/FilteredHoldout/" + databankRG.get(i).getName() + ".sqx", true);
					i++;
				}
				break;
			}
			
		}
		return databankRG;
	}
}