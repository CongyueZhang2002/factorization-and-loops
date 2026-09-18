(* Scalar-provider adapters retain the same integral definitions and measures
   as the momentum-space pipeline. They store functions, not provider names. *)
BeginPackage["FeynFacet`"];Begin["`Private`"];
masterLibraryProviderDefinition[momenta_,loops_,external_,kin_,e_,pres_,eta_,conditions_,measure_]:=Module[
 {top,definition,input},
 top=FeynCalc`FCTopology["ScalarProvider",
  MapThread[FeynCalc`FeynAmpDenominator[FeynCalc`StandardPropagatorDenominator[
   FeynCalc`Momentum[#1,D],0,0,{1,#2}]]&,{momenta,eta}],loops,external,FeynCalc`FCI[kin],{}];
 input=<|"MasterIntegralBasis"->{FeynCalc`GLI["ScalarProvider",ConstantArray[1,Length[momenta]]]},
  "Topologies"->{<|"Topology"->top,"Prescription"->pres|>},
  "DimensionalRegulator"->e,"KinematicConditions"->conditions|>;
 definition=FeynFacet`ConstructMasterIntegralDefinitions[input];
 If[!AssociationQ[definition],Return[definition]];
 definition=definition["MasterIntegralDefinitions"][1];
 (* The scalar provider's measure is explicit. Conjugated bubbles have a
    different sign when both loops retain 1/(i pi^(D/2)). *)
 If[!TrueQ[Simplify[measure/definition["MeasurePrefactor"]]===1],
  definition=Join[definition,<|"MeasurePrefactor"->measure,
   "MomentumSpaceConvention"->"ExplicitMeasure",
   "MeasureConvention"->"Declared scalar-provider measure multiplying product d^D loop momenta."|>]];
 definition
];
masterLibraryEvaluateVector[d_,range_,provider_Function,metadata_:<||>]:=Module[
 {found,record,stored,value,e,lower,upper},
 If[!AssociationQ[d],Return[d]];
 e=d["DimensionalRegulator"];
 found=FeynFacet`FindMasterIntegralValue[d,range];
 If[FailureQ[found],Return[found]];
 If[AssociationQ[found],
  lower=found["LaurentLowerBound"];upper=found["KnownThroughOrder"];
  Return[Join[metadata,<|"DataType"->"LaurentCoefficientVector","DimensionalRegulator"->e,"Dimension"->1,
   "Coefficients"->Association@KeyValueMap[{1,#1}->#2&,found["Coefficients"]],
   "LaurentLowerBounds"->{lower},"KnownThroughOrders"->{upper},
   "StoredOrderRanges"->{{lower,upper}},"ExactTails"->{found["ExactInEpsilon"]},
   "LibraryReuse"->found["LibraryReuse"]|>]]];
 record=provider[];If[!AssociationQ[record],Return[record]];
 value=If[KeyExistsQ[record,"ExactValue"],KeyTake[record,{"ExactValue"}],
  <|"Coefficients"->Association@KeyValueMap[Last[#1]->#2&,record["Coefficients"]],
   "LaurentLowerBound"->Min[First[record["LaurentLowerBounds"]],Min[Last/@Keys[record["Coefficients"]]]],
   "KnownThroughOrder"->First[record["KnownThroughOrders"]]|>];
 stored=FeynFacet`StoreMasterIntegralValue[d,value,
  <|"Provenance"-><|"Producer"->Lookup[metadata,"EvaluationMethod","ScalarIntegralProvider"]|>|>];
 If[FailureQ[stored],Return[stored]];
 Join[record,<|"LibraryStorage"->stored|>]
];
masterLibraryScalarFunctionDefinition[obj_,e_,conditions_]:=Module[
 {k=FeynFacetLibrary`loop,p=FeynFacetLibrary`external1,q=FeynFacetLibrary`external2,
  momenta,external,kin,a,b,c},
 If[!MatchQ[obj,FeynCalc`B0[_,0,0]|FeynCalc`C0[_,_,_,0,0,0]],
  Return[Failure["MasslessScalarLoopFunctionRequired",<|"Function"->obj|>]]];
 If[Head[obj]===FeynCalc`B0,
  momenta={k,k-p};external={p};kin={FeynCalc`SPD[p]->obj[[1]]},
  {a,b,c}=Take[List@@obj,3];momenta={k,k-p,k-q};external={p,q};
  kin={FeynCalc`SPD[p]->a,FeynCalc`SPD[q]->b,FeynCalc`SPD[p,q]->(a+b-c)/2}];
 masterLibraryProviderDefinition[momenta,{k},external,kin,e,{1},
  ConstantArray[1,Length[momenta]],conditions,1/(I Pi^(2-e))]
];
masterLibraryBoxDefinition[{s_,t_,mass_},e_,conditions_,eta_]:=Module[
 {k=FeynFacetLibrary`loop,p=FeynFacetLibrary`external1,q=FeynFacetLibrary`external2,
  r=FeynFacetLibrary`external3},
 masterLibraryProviderDefinition[{k,k+p,k+p+q,k+p+q+r},{k},{p,q,r},
  {FeynCalc`SPD[p]->0,FeynCalc`SPD[q]->0,FeynCalc`SPD[r]->0,
   FeynCalc`SPD[p,q]->s/2,FeynCalc`SPD[q,r]->t/2,FeynCalc`SPD[p,r]->(mass-s-t)/2},
  e,{eta},ConstantArray[eta,4],conditions,eta/(I Pi^(2-e))]
];
End[];EndPackage[];
