package SQ.Utils;

import com.strategyquant.datalib.TradingException;
import com.strategyquant.lib.SQTime;
import com.strategyquant.lib.ValuesMap;
import com.strategyquant.lib.XMLUtil;
import com.strategyquant.tradinglib.*;
import com.strategyquant.tradinglib.options.TradingOptionsList;
import com.strategyquant.tradinglib.propertygrid.IPGParameter;
import com.strategyquant.tradinglib.propertygrid.ParametersTableItemProperties;
import org.jdom2.Element;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class StrategyParametersHelperV2 {

	public static final Logger Log = LoggerFactory.getLogger(StrategyParametersHelperV2.class);

	public static final String ValueDelimiter = "=";
	public static final String ParamDelimiter = ",";

	/**
	 * Applies parameter values into strategy
	 * @param rg
	 * @param parameters - colon delimited list of parameters and their values - e.g. param1=123,param2=25.4
	 * @param symmetricVariables
	 * @param modifyLastSettings
	 * @throws Exception
	 */
	public static void setParameters(ResultsGroup rg, String parameters, boolean symmetricVariables, boolean modifyLastSettings) throws Exception {

		//Load XML and update variables
		StrategyBase strategyBase = getStrategyBase(rg, symmetricVariables);
		Variables variables = strategyBase.variables();

		String[] params = parameters.split(ParamDelimiter);
		HashMap<String, String> paramMap = new HashMap<>();

		for(int i=0; i<params.length; i++) {
			String[] values = params[i].split(ValueDelimiter);
			paramMap.put(values[0], values[1]);
		}

		for(int a=0; a<variables.size(); a++) {
			Variable variable = variables.get(a);
			if(paramMap.containsKey(variable.getName())) {
				variable.setFromString(paramMap.get(variable.getName()));
			}
		}

		strategyBase.transformToNumbers();

		rg.portfolio().addStrategyXml(strategyBase.getStrategyXml());
		rg.specialValues().setString(StatsKey.OPTIMIZATION_PARAMETERS, parameters);

		if(modifyLastSettings){
			try {
				Element lastSettings = XMLUtil.stringToElement(rg.getLastSettings());
				Element elParams = lastSettings.getChild("Options").getChild("BuildTradingOptions").getChild("Params");
				List<Element> paramElems = elParams.getChildren("Param");

				List<TradingOption> tradingOptions = TradingOptionsList.getInstance().getAvailableClasses();

				for(String paramName : paramMap.keySet()) {
					boolean processed = false;

					//we must find the right trading option
					for(int i=0; i<tradingOptions.size(); i++) {
						if(processed) break;

						TradingOption option = tradingOptions.get(i);
						String optionClass = option.getClass().getSimpleName();
						ArrayList<IPGParameter> optionParams = option.getParams();

						//go through its params and find the one with matching name
						for(int z=0; z<optionParams.size(); z++) {
							if(processed) break;

							IPGParameter optionParam = optionParams.get(z);
							String paramKey = optionParam.getKey();

							if(!optionParam.getName().equals(paramName)) continue;

							//now find the right Param element in settings XML and update its value
							for(int s=0; s<paramElems.size(); s++) {
								Element elParam = paramElems.get(s);
								String elParamClass = elParam.getAttributeValue("className");
								String elParamKey = elParam.getAttributeValue("key");

								if(elParamClass != null && elParamKey != null && elParamClass.equals(optionClass) && elParamKey.equals(paramKey)) {
									String value = paramMap.get(paramName);

									if(optionParam.getType() == ParametersTableItemProperties.TYPE_TIME) {
										value = "" + SQTime.HHMMToMinutes(Integer.parseInt(value)) * 60;
									}

									elParam.setText(value);

									processed = true;
									break;
								}
							}
						}
					}
				}

				rg.setLastSettings(XMLUtil.elementToString(lastSettings));
			}
			catch(Exception e){
				Log.error("Cannot apply trading options params to last settings", e);
			}
		}
	}

	/**
	 * Returns an ArrayList of strategy parameter names
	 * @param rg
	 * @param parameterTypes
	 * @param symmetricVariables
	 * @return
	 * @throws Exception
	 */
	public static ArrayList<String> getParameterNames(ResultsGroup rg, ValuesMap parameterTypes, boolean symmetricVariables) throws Exception {
		HashMap<String, String> paramsMap = getParameterValues(rg, parameterTypes, symmetricVariables);

		ArrayList<String> list = new ArrayList<>();
		list.addAll(paramsMap.keySet());

		return list;
	}

	/**
	 * Returns a map containing strategy parameter names and values
	 * @param rg
	 * @param parameterTypes - ValuesMap specifying ParametrizationTypes to check. If null, recommended parameter types are used.
	 * @param symmetricVariables
	 * @return
	 * @throws Exception
	 */
	public static HashMap<String, String> getParameterValues(ResultsGroup rg, ValuesMap parameterTypes, boolean symmetricVariables) throws Exception {
		StrategyBase strategyBase = getStrategyBase(rg, symmetricVariables);
		Variables variables = strategyBase.variables();

		HashMap<String, String> paramsList = new HashMap<>();

		boolean useRecommended = parameterTypes == null || parameterTypes.getBoolean(ParametrizationTypes.ParamTypeRecommended, false);

		if(useRecommended){
			parameterTypes = new ValuesMap();
			parameterTypes.set(ParametrizationTypes.ParamTypePeriod, true);
			parameterTypes.set(ParametrizationTypes.ParamTypeEntryLevel, true);
			parameterTypes.set(ParametrizationTypes.ParamTypeExitUsed, true);
		}

		for(int a=0; a<variables.size(); a++) {
			Variable variable = variables.get(a);
			String variableType = variable.getParamType();

			String varName = variable.getName();
			if(varName.equals("LongEntrySignal") || varName.equals("ShortEntrySignal") || varName.equals("LongExitSignal") || varName.equals("ShortExitSignal") || varName.equals("MagicNumber")) {
				// skip parameters that don't need to be set here
				continue;
			}

			if(variableType == null || parameterTypes.getBoolean(variableType, false)){
				paramsList.put(variable.getName(), variable.getValue());
			}
		}

		return paramsList;
	}

	/**
	 * Returns a value of selected parameter
	 * @param rg
	 * @param symmetricVariables
	 * @param parameterName
	 * @return
	 * @throws Exception
	 */
	public static String getParameterValue(ResultsGroup rg, boolean symmetricVariables, String parameterName) throws Exception {
		StrategyBase strategyBase = getStrategyBase(rg, symmetricVariables);
		Variables variables = strategyBase.variables();
		Variable variable = variables.get(parameterName);

		if(variable == null) return null;

		return variable.getValue();
	}

	/**
	 * Converts parameter map to string
	 * @param parametersMap
	 * @return
	 */
	public static String toString(HashMap<String, String> parametersMap){
		if(parametersMap == null) return null;

		StringBuilder sb = new StringBuilder();

		for(String name : parametersMap.keySet()){
			sb.append(ParamDelimiter);
			sb.append(name);
			sb.append(ValueDelimiter);
			sb.append(parametersMap.get(name));
		}

		return sb.length() > ParamDelimiter.length() ? sb.substring(ParamDelimiter.length()) : sb.toString();
	}

	private static StrategyBase getStrategyBase(ResultsGroup rg, boolean symmetricVariables) throws Exception {
		StrategyBase xmlS = StrategyBase.createXmlStrategy(rg.getStrategyXml());
		xmlS.transformToVariables(symmetricVariables);
		return xmlS;
	}

}
