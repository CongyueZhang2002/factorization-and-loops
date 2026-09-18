(* Solve the momentum-induced coordinate map and derive its density weight. *)
BeginPackage["FeynFacet`"];
ConstructCollinearMomentumMap::usage="ConstructCollinearMomentumMap[geometry,leg] solves the coordinate transformation induced by PDF p->xi p or FF k->k/xi. Geometry supplies scalar-product equations, coordinates, endpoint variable, assumptions and the stored-density prefactor. The endpoint chart and scalar measures are generated together; unresolved multiple branches are rejected.";
Begin["`Private`"];
$collinearMomentumMapCache=<||>;
collinearMapFail[tag_,data_:<||>]:=Throw[Failure[tag,data],"CollinearMomentumMap"];
ConstructCollinearMomentumMap[geometry_Association,leg_Association]:=Catch[Module[
 {coordinates,w,e,xi,q,y,z,momenta,momentum,role,rules,lhs,rhs,equations,unknowns,solutions,regular,
  branches,chi,assumptions,operator,weight,normalization,endpoint,domain,scalarRules,cached,result,key={geometry,leg}},
 cached=Lookup[$collinearMomentumMapCache,Key[key],None];If[AssociationQ[cached],Return[cached]];
 If[!ContainsAll[Keys[geometry],{"Coordinates","EndpointVariable","DimensionalRegulator","ExternalMomenta","KinematicRules","DensityPrefactor"}]||
   !ContainsAll[Keys[leg],{"Role","Momentum"}],collinearMapFail["CollinearMomentumGeometryRequired"]];
 {coordinates,w,e,momenta,rules,normalization}=Lookup[geometry,
   {"Coordinates","EndpointVariable","DimensionalRegulator","ExternalMomenta","KinematicRules","DensityPrefactor"}];
 {role,momentum}=Lookup[leg,{"Role","Momentum"}];
 If[!MemberQ[{"PDF","FF"},role]||!MemberQ[momenta,momentum]||!MemberQ[coordinates,w]||
   !DuplicateFreeQ[coordinates]||!AllTrue[coordinates,MatchQ[#,_Symbol]&],collinearMapFail["IndependentCollinearCoordinatesRequired"]];
 xi=collinearIntegrationFraction;q=Lookup[leg,"Variable",collinearEndpointFraction];
 y=collinearExternalFraction;z=collinearOperatorFraction;
 If[!MatchQ[q,_Symbol]||MemberQ[Join[coordinates,momenta,{e,xi,y,z}],q],collinearMapFail["IndependentConvolutionVariableRequired"]];
 assumptions=Lookup[geometry,"Assumptions",True];domain=assumptions&&0<xi<1&&0<q<1;
 scalarRules=Select[FeynCalc`FCI[rules],MatchQ[First[#],FeynCalc`Pair[FeynCalc`Momentum[_Symbol,___],FeynCalc`Momentum[_Symbol,___]]]&&
   ContainsAll[momenta,Cases[First[#],FeynCalc`Momentum[k_Symbol,___]:>k,Infinity]]&];
 If[scalarRules==={},collinearMapFail["ScalarProductCoordinateEquationsRequired"]];
 unknowns=Array[collinearMappedCoordinate,Length[coordinates]];
 (* Bilinearity avoids asking the amplitude algebra whether a new integration
    symbol is a scalar or another momentum. Each occurrence is counted once. *)
 lhs=Function[rule,Last[rule]xi^(If[role==="PDF",1,-1]
   Length[Cases[First[rule],FeynCalc`Momentum[k_Symbol,___]/;k===momentum,Infinity]])]/@scalarRules;
 rhs=(Last/@scalarRules)/.Thread[coordinates->unknowns];
 equations=Thread[rhs==lhs];solutions=Solve[equations,unknowns];
 If[Length[solutions]=!=1||!FreeQ[unknowns/.First[solutions],Alternatives@@unknowns],
  collinearMapFail["UniqueCollinearCoordinateBranchNotEstablished",<|"Equations"->equations|>]];
 regular=Thread[coordinates->(Factor/@(unknowns/.First[solutions]))];
 branches=Solve[(w/.regular)==w/q,xi];
 If[Length[branches]=!=1,collinearMapFail["UniqueEndpointFractionBranchNotEstablished",<|"Branches"->branches|>]];
 chi=Factor[xi/.First[branches]];
 If[!TrueQ[FullSimplify[(chi/.q->1)==1&&D[chi,q]>0&&0<chi<=1,Assumptions->domain]],
  collinearMapFail["PhysicalMonotoneEndpointFractionRequired",<|"Fraction"->chi|>]];
 operator=FeynFacet`BareCollinearOperatorNormalization[role,Lookup[leg,"Species","q"],z,4-2e];
 If[!AssociationQ[operator],collinearMapFail["BareOperatorNormalizationRequired",<|"Cause"->operator|>]];
 weight=FeynFacet`CollinearPairingAdjointWeight[operator,operator,xi,y,normalization,normalization,regular];
 weight=FullSimplify[weight,Assumptions->domain&&Element[e,Reals]];
 If[!FreeQ[weight,y|_Failure],collinearMapFail["ClosedCoefficientDensityRescalingRequired",<|"Weight"->weight|>]];
 endpoint=Map[First[#]->Cancel[Together[Last[#]/.xi->chi]]&,DeleteCases[regular,Rule[w,_]]];
 result=<|"Variable"->q,"Fraction"->chi,"EndpointRules"->endpoint,
   "RegularRules"->(regular/.xi->q),"LowerFraction"->(chi/.q->w),
   "EndpointMeasure"->(weight/.xi->chi),"RegularMeasure"->(weight/.xi->q),
   "Derivation"-><|"MomentumRescaling"->(momentum->If[role==="PDF",xi momentum,momentum/xi]),
     "CoordinateEquations"->equations,"OperatorNormalization"->operator,"DensityPrefactor"->normalization,
     "Geometry"->geometry,"LegDefinition"->leg,"Status"->"UniqueCoordinateAndEndpointBranches"|>|>;
 AssociateTo[$collinearMomentumMapCache,key->result];result
],"CollinearMomentumMap"];
ConstructCollinearMomentumMap[___]:=Failure["CollinearMomentumGeometryRequired",<||>];
End[];EndPackage[];
