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
package SQ.MonteCarlo.Retest;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.strategyquant.lib.*;
import com.strategyquant.datalib.*;
import com.strategyquant.tradinglib.*;

@ClassConfig(name="Randomize strategy parameters - Seasonality", display="Randomize seasonality strategy parameters, with probability #Probability# % and max change #MaxChange# % or #MaxChangeHour# h")
public class RandomizeStrategyParametersSeasonality extends MonteCarloRetest {
	public static final Logger Log = LoggerFactory.getLogger(RandomizeStrategyParameters.class);
	
	@Parameter(name="Probability", defaultValue="10", minValue=1, maxValue=100, step=1)
	public int Probability;
	
	@Parameter(name="Max change Hour", defaultValue="5", minValue=1, maxValue=100, step=1)
	public int MaxChangeHour;

	@Parameter(name="Max change", defaultValue="20", minValue=1, maxValue=100, step=1)
	public int MaxChange;
	
	@Parameter(name="Symmetric parameters", defaultValue="true")
	@Help("If true, it uses symmetric parameters - the parameters will be shared for long and short side. Otherwise, the parameters for long and short side will be independent.")
	public boolean Symmetric;

	private ValuesMap paramTypes = new ValuesMap();
	
	//------------------------------------------------------------------------
	//------------------------------------------------------------------------
	//------------------------------------------------------------------------

	public RandomizeStrategyParametersSeasonality() {
		super(MonteCarloTestTypes.ModifySettings);
	}
	
	//------------------------------------------------------------------------	
	
	public void modifySettings(IRandomGenerator rng, SettingsMap settings) throws Exception {
		StrategyBase strategy = StrategyBase.getStrategy(settings);

		paramTypes.set(ParametrizationTypes.ParamTypePeriod, true);
		paramTypes.set(ParametrizationTypes.ParamTypeShift, false);
		paramTypes.set(ParametrizationTypes.ParamTypeConstant, false);
		paramTypes.set(ParametrizationTypes.ParamTypeOtherParam, true);
		paramTypes.set(ParametrizationTypes.ParamTypeExitUsed, false);
		paramTypes.set(ParametrizationTypes.ParamTypeExitUnused, false);
		paramTypes.set(ParametrizationTypes.ParamTypeBoolean, false);	
		paramTypes.set(ParametrizationTypes.ParamTypeTradingOptions, false);		
		
		strategy.transformToVariables(Symmetric, paramTypes);

		Variables vars = strategy.variables();
		vars.sortByName();

		if(vars.size() == 0) {
			return;
		}
		
		double dblProbability = ((double) Probability/ 100.0d);

		int tries = 0;
		while(true) {
			
			int varsChanged = modifyParameters(vars, dblProbability, rng);
			if(varsChanged > 0) {
				break;
			}
			
			tries++;
			if(tries > 10) {
				break;
			}
		}
	}

	//------------------------------------------------------------------------	

	private int modifyParameters(Variables vars, double dblProbability, IRandomGenerator rng) {
		int varsChanged = 0;
		
		int valuesThatCanChange = 0;
		
		for(int i=0; i<vars.size(); i++) {
			Variable variable = vars.get(i);
			
			if(!isCorrectType(variable)) {
				// it is variable of a different type
				continue;
			}
			
			if(variable.getName().contains("Magic")) {
				continue;
			}
			
			valuesThatCanChange++;
		}
		
		if(valuesThatCanChange > 0) {

			int cycles = 0;
			
			while(true) {
				varsChanged = changeSomeVars(vars, dblProbability, rng);

				// we must change at least one variable
				if(varsChanged > 0) {
					break;
				}
				
				if(cycles > 100) {
					// protection against infinite cycle
					break;
				}
			}
		}

		//printVars("test", vars, varsChanged);
		return varsChanged;
	}

	//------------------------------------------------------------------------	

	private int changeSomeVars(Variables vars, double dblProbability, IRandomGenerator rng) {
		int varsChanged = 0;
		
		for(int i=0; i<vars.size(); i++) {
			Variable variable = vars.get(i);

			if(!isCorrectType(variable)) {
				// it is variable of a different type
				continue;
			}
			
			if(variable.getName().contains("Magic")) {
				continue;
			}

			if(!rng.probability(dblProbability)) {
				// we shouldn't change this value
				continue;
			}
			
			int varType = variable.getInternalType();
			if(varType == Variable.TypeBoolean) {
				variable.setValue(!variable.getValueAsBoolean());
				varsChanged++;
				
			} else if(varType == Variable.TypeInt || varType == Variable.TypeDouble) {
				
				double value = variable.getValueAsDouble();
			
				// randomly determine change
				double change = 0;
				if(variable.getParamType() == ParametrizationTypes.ParamTypeOtherParam){
					change = Double.valueOf(rng.nextInt​(MaxChangeHour));
				}
				else{
					double pctChange = ((double) (1+rng.nextInt(MaxChange)) / 100.0d);
				
					change = value * pctChange;
				}

				// randomly determine positive or negative
				double newValue = (rng.nextInt(2) == 0 ? value + change : value - change);

				if(varType == Variable.TypeInt) {
					newValue = (int) Math.round(newValue);
				}
				
				if(value != newValue) {
					varsChanged++;
				}

				if(varType == Variable.TypeInt) {
					variable.setValue((int) newValue);
				} else {
					variable.setValue(newValue);
				}
			}
		}
		
		return varsChanged;
	}

	//------------------------------------------------------------------------	

	private void printVars(String string, Variables vars, int varsChanged) {
		Log.info("------------------------------------");
		Log.info(string+", Changed: "+varsChanged);
		Log.info("------------------------------------");
		
		for(int i=0; i<vars.size(); i++) {
			Variable variable = vars.get(i);
			
			Log.info("Var #{} : {}", i, variable.toString());
		}
	}

	//------------------------------------------------------------------------	

	private boolean isCorrectType(Variable variable) {
		if(variable == null || variable.getParamType() == null) {
			return false;
		}
		
		return (paramTypes.getBoolean(variable.getParamType(), false) == true);
	}		

	/**
	 * Gets the clone.
	 *
	 * @return the clone
	 * @throws Exception the exception
	 */
	@Override
	public RandomizeStrategyParametersSeasonality getClone() throws Exception {
		RandomizeStrategyParametersSeasonality mc = new RandomizeStrategyParametersSeasonality();

		mc.setParams(this.getParams());

		mc.Probability = this.Probability;
		mc.MaxChange = this.MaxChange;
		mc.MaxChangeHour = this.MaxChangeHour;
		mc.Symmetric = this.Symmetric;
		
		return mc;
	}

}