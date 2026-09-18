<|
 "ResultType"->"CompleteCoefficient", "EpsilonRange"->{0,0}, "RequireFinite"->True,
 (* Fundamental SU(N): 2 CF CA = CA^2 - 1. This selects an independent color basis. *)
 "ColorRules"->{FeynCalc`CF->(FeynCalc`CA^2-1)/(2 FeynCalc`CA)},
 (* The massive angular direction has a removable zero spatial velocity at x=z. *)
 "RemovableKinematicLimits"->{x->z},
 "Inputs"->{
  <|"Path"->"../../../Raw/NLO/q-q/Real", "Weight"->1|>,
  <|"Path"->"../../../Raw/NLO/q-q/Virtual", "Weight"->1|>,
  <|"Path"->"../../../Raw/NLO/q-q/Counter-UV", "Weight"->1, "OutputChannel"->"q-q"|>,
  <|"Path"->"../../../Raw/NLO/q-q/Counter-PDF", "Weight"->1, "OutputChannel"->"q-q"|>,
  <|"Path"->"../../../Raw/NLO/q-q/Counter-FF", "Weight"->1, "OutputChannel"->"q-q"|>
 }
|>
