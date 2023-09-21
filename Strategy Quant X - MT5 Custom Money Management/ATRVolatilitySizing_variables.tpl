input string smm = "----------- Money Management - ATR Volatility Sizing-----------";
input bool UseMoneyManagement = true;
input double mmRiskedMoney = <@printMMVariableNumber "#RiskedMoney#" />;
input double mmRiskPercent = <@printMMVariableNumber "#RiskPercent#" />;
input int mmDecimals = <@printMMVariableNumber "#Decimals#" />;
input double mmMultiplier = <@printMMVariableNumber "#Multiplier#" />;
input int mmATRPeriod = <@printMMVariableNumber "#ATRPeriod#" />;