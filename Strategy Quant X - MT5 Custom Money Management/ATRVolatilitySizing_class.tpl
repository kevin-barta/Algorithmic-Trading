double sqMMATRVolatilitySizing(string symbol, ENUM_ORDER_TYPE orderType, double price, double sl, double RiskedMoney, double RiskInPercent, int Decimals, double Multiplier, int ATRPeriod) {
   Verbose("Computing Money Management for order -  ATR Volatility Sizing");
      
   string correctedSymbol = correctSymbol(symbol);
   double openPrice = price > 0 ? price : SymbolInfoDouble(correctedSymbol, isLongOrder(orderType) ? SYMBOL_ASK : SYMBOL_BID);

   double LotSize, DebugLotSize = 0;

   if(RiskedMoney <= 0 && RiskInPercent <= 0) {
      Verbose("Computing Money Management - Incorrect RiskedMoney or  RiskInPercent value, it must be above 0");
      return(0);
   }
   
   double PointValue = SymbolInfoDouble(correctedSymbol, SYMBOL_TRADE_TICK_VALUE) / SymbolInfoDouble(correctedSymbol, SYMBOL_TRADE_TICK_SIZE);      
   double Smallest_Lot = SymbolInfoDouble(correctedSymbol, SYMBOL_VOLUME_MIN);
   double Largest_Lot = SymbolInfoDouble(correctedSymbol, SYMBOL_VOLUME_MAX);    
   double LotStep = SymbolInfoDouble(correctedSymbol, SYMBOL_VOLUME_STEP);

   //--- Lot Size Calculation
   double valueATR = (NormalizeDouble((double) sqGetIndicatorValue(ATR_1, 0, 1), 6));
   
   if(RiskInPercent > 0){
      DebugLotSize = ((AccountInfoDouble(ACCOUNT_BALANCE) * RiskInPercent / 100) / PointValue) / valueATR*Multiplier;
   }
   else if(RiskedMoney > 0){
      DebugLotSize = (RiskedMoney/PointValue) / valueATR*Multiplier;
   }
   LotSize = NormalizeDouble(DebugLotSize, Decimals);
   
   if(LotSize <= 0){
	  LotSize = MathPow(10, -Decimals);
   }

   //--- MAXLOT and MINLOT management

   Verbose("Computing Money Management - Smallest_Lot: ", DoubleToString(Smallest_Lot), ", Largest_Lot: ", DoubleToString(Largest_Lot), ", Computed LotSize: ", DoubleToString(LotSize), ", Debug LotSize: ", DoubleToString(DebugLotSize));
   Verbose("Money to risk: ", DoubleToString(RiskedMoney), ", Risk %: ", DoubleToString(RiskInPercent), ", Point value: ", DoubleToString(PointValue), ", ATR value: ", DoubleToString(valueATR), ", Balance: ", DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE)));

   if(LotSize <= 0){
	  Verbose("Calculated LotSize is <= 0. Using value: ", DoubleToString(MathPow(10, -Decimals)), ")");
	  LotSize = MathPow(10, -Decimals);
   }                          

   if (LotSize < Smallest_Lot) {
      Verbose("Calculated LotSize is too small. Minimal allowed lot size from the broker is: ", DoubleToString(Smallest_Lot), ". Please, increase your risk or set fixed LotSize.");
      LotSize = Smallest_Lot;
   }
   else if (LotSize > Largest_Lot) {
      Verbose("LotSize is too big. LotSize set to maximal allowed market value: ", DoubleToString(Largest_Lot));
      LotSize = Largest_Lot;
   }

   //--------------------------------------------

   return (LotSize);
}