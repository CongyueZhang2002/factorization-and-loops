(* Geometry of a delta-function pushforward, independent of the scalar
   density inserted afterward. In particular this operation does not remove
   virtual prescriptions or expand regulator-dependent scalar functions. *)
BeginPackage["FeynFacet`"];
ConstructThreeParticleMeasurementPushforward::usage="ConstructThreeParticleMeasurementPushforward[definition,request] derives the physical roots of one native polynomial measurement on massless three-body phase space. It returns exact scalar-product substitutions, root Jacobians and dimensional one-dimensional kernels. MeasurementDensity includes the original measurement numerator once; PolynomialCutDensity excludes it for prepared cut densities that already contain it. Request declares ParticleOrder, optional Parameters and DimensionalRegulator, and open-domain Assumptions. Endpoint continuation and integration of a scalar density are separate operations.";
VerifyThreeParticleInclusiveChart::usage="VerifyThreeParticleInclusiveChart[chart,parameterConditions] proves that a measurement pushforward exhausts the original open massless three-particle phase space. It derives the observable from the affine measurement-variable constraint, verifies its support in (0,1), the unit delta normalization, and coverage by the retained roots. A regular chart covering only a restricted observable range is rejected. The result is geometric and makes no prescription-limit assertion.";
Begin["`Private`"];
ConstructThreeParticleMeasurementPushforward[input_Association,request_Association:<||>]:=Catch[Module[
 {definition,top,particles,total,s,order,parameters,x,y,z,assumptions,rules,g,roots,
  selected={},inside,outside,slope,jacobian,e,dimension,normalization,gram,numerator,cutSlots},
 definition=FeynFacet`CreateCutIntegralDefinition[input];
 If[!AssociationQ[definition],cutFamilyFail["TypedMeasurementGeometryRequired",<|"Cause"->definition|>]];
 top=definition["Topology"];particles=Lookup[definition,"FinalMomenta",{}];total=definition["TimeDirection"];
 If[Length[particles]=!=3||Length[top[[3]]]=!=2||Length[top[[4]]]=!=1||total=!=First[top[[4]]]||
   Complement[Range[Length[top[[2]]]],definition["CutIndices"]]=!={}||
   Length[definition["ParticleCutIndices"]]=!=3||Length[definition["MeasurementCutIndices"]]=!=1||
   !AllTrue[Select[definition["Cuts"],#["Type"]==="Particle"&],
     #["MassSquared"]===0&&#["EnergyDirection"]===1&],cutFamilyFail["MasslessThreeBodySingleMeasurementRequired"]];
 If[KeyExistsQ[input,"CutPowers"]&&input["CutPowers"]=!=ConstantArray[1,Length[definition["CutIndices"]]],
  cutFamilyFail["UnitMeasurementPushforwardRequired"]];
 s=FeynCalc`FCI[FeynCalc`SPD[total]]/.top[[5]];
 If[!TrueQ[FullSimplify[s>0,Assumptions->definition["Assumptions"]]],cutFamilyFail["PositiveTimelikeInvariantRequired"]];
 order=Lookup[request,"ParticleOrder",Range[3]];
 If[Sort[order]=!={1,2,3},cutFamilyFail["ParticlePermutationRequired"]];particles=particles[[order]];
 parameters=Lookup[request,"Parameters",{Unique["energyFraction"],Unique["energyFraction"]}];
 If[!MatchQ[parameters,{_Symbol,_Symbol}]||!DuplicateFreeQ[parameters],cutFamilyFail["IndependentEnergyFractionParametersRequired"]];
 {x,y}=parameters;z=First[definition["MeasurementVariables"]];e=Lookup[request,"DimensionalRegulator",None];
 If[(e=!=None&&!MatchQ[e,_Symbol])||!DuplicateFreeQ[Join[parameters,{z},If[e===None,{}, {e}]]]||
    !FreeQ[s,Alternatives@@parameters],cutFamilyFail["IndependentMeasurementCoordinatesRequired"]];
 assumptions=definition["Assumptions"]&&Lookup[request,"Assumptions",0<z<1];
 rules=invariantParticleRules[particles,total,s,{s(x+y-1),s(1-y),s(1-x)}];
 g=Factor[definition["InversePropagators"][[First[definition["MeasurementCutIndices"]]]]/.rules];
 numerator=Factor[FeynCalc`ExpandScalarProduct[FeynCalc`FCI[Lookup[definition,"MeasurementNumerator",1]]]/.rules];
 If[!FreeQ[{g,numerator},_FeynCalc`Pair|_FeynCalc`Momentum|_Failure|_Missing]||
   !PolynomialQ[g,y]||!MemberQ[{1,2},Exponent[g,y]],cutFamilyFail["PolynomialMeasurementRootRequired"]];
 dimension=If[e===None,4,4-2e];
 normalization=(definition["MeasurePrefactor"]/(2Pi)^(3-2D)/.D->dimension)*
   If[e===None,s/(128Pi^3),s^(1-2e)(4Pi)^(2e)/(128Pi^3 Gamma[2-2e])];
 roots=DeleteDuplicates[y/.Solve[g==0,y]];
 Do[
  inside=TrueQ[FullSimplify[Element[root,Reals]&&1-x<root<1,Assumptions->assumptions&&0<x<1]];
  outside=TrueQ[FullSimplify[!Element[root,Reals]||root<=1-x||root>=1,Assumptions->assumptions&&0<x<1]];
  If[!inside&&!outside,cutFamilyFail["MeasurementRootDomainPartitionRequired",<|"Root"->root|>]];
  If[inside,
   slope=Factor[D[g,y]/.y->root];
   If[!TrueQ[FullSimplify[slope!=0,Assumptions->assumptions&&0<x<1]],cutFamilyFail["SimpleInteriorMeasurementRootsRequired"]];
   jacobian=FullSimplify[1/Abs[slope],Assumptions->assumptions&&0<x<1];
   gram=Factor[(1-x)(1-y)(x+y-1)/.y->root];
   AppendTo[selected,<|"Root"->root,"EliminationRule"->(y->root),"Jacobian"->jacobian,
    "GramPolynomial"->gram,"MeasurementNumerator"->Factor[numerator/.y->root],
    "ScalarProductRules"->Map[First[#]->Factor[Last[#]/.y->root]&,rules],
    "PolynomialCutDensity"->normalization jacobian If[e===None,1,gram^-e],
    "MeasurementDensity"->normalization jacobian Factor[numerator/.y->root]If[e===None,1,gram^-e]|>]],
 {root,roots}];
 <|"Format"->"FeynFacet-ThreeParticleMeasurementPushforward","Definition"->definition,
   "IntegrationVariable"->x,"EliminatedVariable"->y,"Interval"->{0,1},"Variable"->z,
   "ParticleOrder"->order,"ScalarProductRules"->rules,"MeasurementPolynomial"->g,
   "Normalization"->normalization,"Branches"->selected,"DimensionalRegulator"->e,
   "Dimension"->dimension,"Domain"->assumptions,"EndpointDistributionIncluded"->False,
   "Scope"->"Geometry on the open measured interval. Scalar causal kernels are inserted without changing their prescriptions; endpoints require regulated continuation."|>
],"CutFamily"];
VerifyThreeParticleInclusiveChart[chart_Association,parameters_:True]:=Catch[Module[
 {x,y,z,e,g,slope,observable,numerator,conditions,variables,nonempty,prove,tests},
 If[Lookup[chart,"Format",None]=!="FeynFacet-ThreeParticleMeasurementPushforward"||
   Lookup[chart,"Interval",None]=!={0,1}||Lookup[chart,"Branches",{}]==={},
  cutFamilyFail["ThreeParticleMeasurementChartRequired"]];
 {x,y,z,e,g}=Lookup[chart,{"IntegrationVariable","EliminatedVariable","Variable",
    "DimensionalRegulator","MeasurementPolynomial"}];
 If[!FreeQ[parameters,Alternatives@@DeleteCases[{x,y,z,e},None]],
  cutFamilyFail["CoordinateIndependentInclusiveChartConditionsRequired"]];
 variables=DeleteDuplicates[Cases[parameters,s_Symbol/;Context[s]=!="System`",{0,Infinity}]];
 nonempty=If[variables==={},parameters,With[{vv=variables,condition=parameters},
   TimeConstrained[Resolve[Exists[vv,condition],Reals],10,$Failed]]];
 If[nonempty=!=True,cutFamilyFail["NonemptyInclusiveChartParameterDomainRequired"]];
 If[!PolynomialQ[g,z]||Exponent[g,z]=!=1,cutFamilyFail["AffineMeasurementVariableRequired"]];
 conditions=parameters&&0<x<1&&1-x<y<1;
 prove[claim_]:=TrueQ[TimeConstrained[FullSimplify[claim,Assumptions->conditions],10,False]];
 slope=Coefficient[g,z];
 If[!prove[Element[slope,Reals]&&slope!=0],cutFamilyFail["NonzeroPhysicalMeasurementSlopeRequired"]];
 observable=Cancel[-(g/.z->0)/slope];
 numerator=Factor[FeynCalc`ExpandScalarProduct[FeynCalc`FCI[
   Lookup[chart["Definition"],"MeasurementNumerator",1]]]/.chart["ScalarProductRules"]];
 tests=<|"FullObservableSupport"->prove[0<observable<1],
   "UnitDeltaNormalization"->prove[numerator==Abs[slope]],
   "OriginalDomainCovered"->prove[chart["Domain"]/.z->observable],
   "AllPhysicalPointsHaveRetainedRoots"->prove[
     Or@@((y==(# ["Root"]/.z->observable))&/@chart["Branches"])]|>;
 If[!AllTrue[Values[tests],TrueQ],cutFamilyFail["InclusiveMeasurementChartNotExhaustive",
   <|"Conditions"->tests,"Observable"->observable|>]];
 <|"Format"->"FeynFacet-InclusiveMeasurementChartVerification","FullPhaseSpaceCovered"->True,
   "Observable"->observable,"Interval"->{0,1},"ParameterConditions"->parameters,
   "PhysicalDomain"->conditions,"Checks"->tests,"VirtualPrescriptionRemoved"->False,
   "Argument"->"Every point of the open energy triangle maps into the declared measured interval, obeys the chart domain and belongs to a retained simple root. The measurement numerator equals the absolute measurement-variable slope, so integrating its delta over that interval gives one. Boundary continuations remain separate."|>
],"CutFamily"];
End[];EndPackage[];
