<|
 "ResultType"->"CompleteCoefficient", "EpsilonRange"->{0,0}, "RequireFinite"->True,
 (* Fundamental SU(N): 2 CF CA = CA^2 - 1. This selects an independent color basis. *)
 "ColorRules"->{FeynCalc`CF->(FeynCalc`CA^2-1)/(2 FeynCalc`CA)},
 "Inputs"->{
  <|"Path"->"../../../Raw/NLO/q-qb/Real", "Weight"->1|>
 }
|>
