package SQ.CustomAnalysis;

import com.strategyquant.lib.*;

import com.strategyquant.pluginlib.program.IProgram;
import com.strategyquant.pluginlib.program.Program;

import java.io.File;
import org.apache.commons.lang3.ArrayUtils;

import java.util.ArrayList;

import com.strategyquant.datalib.*;
import com.strategyquant.tradinglib.*;

public class SaveStrategy extends CustomAnalysisMethod {

	private String filePath = "C:/Users/Kevin/Desktop/Algo Business/SQX/Seasonality v0.5/SQX Debug Projects/";

	//------------------------------------------------------------------------
	//------------------------------------------------------------------------
	//------------------------------------------------------------------------
	
	public SaveStrategy() {
		super("SaveStrategy", TYPE_FILTER_STRATEGY);
	}
	
	//------------------------------------------------------------------------
	
	@Override
	public boolean filterStrategy(String project, String task, String databankName, ResultsGroup rg) throws Exception {
		String[] taskNames;

		//Get list of tasks
		File ftasks = new File(filePath + project + "/");
        taskNames = ftasks.list();

		IProgram saver = Program.get("Saver");
		if(taskNames == null){
			//if no folders exist create a new folder with starting number: 0 and save strategy
        	saver.call("saveFile", rg, filePath + project + "/" + 0 + ". " + task + "/" + rg.getName() + ".sqx", true);
		}
		else{
			//get index of partial match to folder (full task match without the number)
			int i = 0;
			while (i < taskNames.length) {
        		if (taskNames[i].indexOf(task) > -1) {
            		break;
        		}
				i++;
    		}
			if(i == taskNames.length){
				//if folder does not exist create a new folder with next number and save strategy
        		saver.call("saveFile", rg, filePath + project + "/" + taskNames.length + ". " + task + "/" + rg.getName() + ".sqx", true);
			}
			else{
				//if folder exists use that folder number and save strategy
        		saver.call("saveFile", rg, filePath + project + "/" + i + ". " + task + "/" + rg.getName() + ".sqx", true);
			}
		}
		
		return true;
	}
	
	
	//------------------------------------------------------------------------
	
	@Override
	public ArrayList<ResultsGroup> processDatabank(String project, String task, String databankName, ArrayList<ResultsGroup> databankRG) throws Exception {
		return databankRG;
	}
}