(* Run with Scripts/Transport/determine_epsilon_orders.wls.
   The inputs are explicit resolved integrals on [0,1], with all normalizations.
   This example illustrates a product followed by a Laurent coefficient map. *)
With[{
 first=FeynFacet`DetermineIntegralLaurentBound[
  <|"DimensionalRegulator"->eps,"Terms"->{
   <|"IntegrationVariables"->{x},"EndpointPowers"->{-1-eps},
     "RegularFactor"->1/(1+x)|>}|>],
 second=FeynFacet`DetermineIntegralLaurentBound[
  <|"DimensionalRegulator"->eps,"Terms"->{
   <|"IntegrationVariables"->{y},"EndpointPowers"->{-2-eps},
     "RegularFactor"->1+y,"Prefactor"->eps|>}|>]},
 <|"Task"->"Calculation","Data"-><|
  "DimensionalRegulator"->eps,
  "Inputs"-><|"I1"->first,"I2"->second|>,
  "Operations"->{
   <|"Id"->"product","Operation"->"Product","Inputs"->{"I1","I2"}|>,
   <|"Id"->"observable","Operation"->"LinearCombination","Terms"->{
     <|"Input"->"product","Coefficient"->(1+eps)/eps|>}|>},
  "RequestedOrders"-><|"observable"->0|>,
  "Scope"->"The stated integral representations and product; no additional endpoint or renormalization operation is implicit."|>|>]
