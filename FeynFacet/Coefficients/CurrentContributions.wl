(* Generated current amplitudes contracted with exact measured phase space. *)
BeginPackage["FeynFacet`"];
ConstructCurrentIntegrands::usage="ConstructCurrentIntegrands[setup,request] generates and projects complete current interferences with normalized partonic spin densities. Optional AngularAverage performs the joint correlated evanescent average for all integrated momenta. Phase space, flux, coupling renormalization and any additional conjugate interference remain explicit downstream operations.";
ConstructCurrentRealDensity::usage="ConstructCurrentRealDensity[setup,request] generates a two-particle tree current contribution with exact regulator dependence, normalized spin/color densities and the declared measured phase space.";
ConstructCurrentRealContribution::usage="ConstructCurrentRealContribution[density,request] expands the declared normal endpoint powers of a measured current density and returns the common epsilon-indexed partonic result.";
ConstructCurrentVirtualContribution::usage="ConstructCurrentVirtualContribution[setup,request] generates the one-loop interference of a one-particle current, reduces its tensor integrals, evaluates supported scalar loop functions with causal phases, and returns explicit endpoint coefficients.";
NormalizeMeasuredCurrentScalarValues::usage="NormalizeMeasuredCurrentScalarValues[source,request] applies the declared current normalization, physical two-particle density, symmetry/flavor factors and bare coupling conversion to tensor-reduced scalar integrands. It returns the common exact input for bulk and endpoint expansion.";
Begin["`Private`"];

NormalizeMeasuredCurrentScalarValues[source_Association,request_Association]:=Module[{normalization,values},
 If[!AssociationQ[Lookup[source,"InteriorValues",None]]||!AssociationQ[Lookup[source,"Measurement",None]]||
   !ContainsAll[Keys[request],{"CurrentNormalization","BareCouplingRules"}],
  Return[Failure["MeasuredScalarIntegrandsAndDeclaredNormalizationRequired",<||>]]];
 normalization=request["CurrentNormalization"]Lookup[request,"SymmetryFactor",1]*
   Lookup[request,"FlavorMultiplicity",1]source["Measurement"]["PhaseSpaceDensity"];
 values=Map[Factor[FeynFacet`SubstituteScalarPowers[normalization #,request["BareCouplingRules"]]/.
    Lookup[request,"ColorRules",{}]]&,source["InteriorValues"]];
 If[!FreeQ[values,_FeynCalc`SMP],Return[Failure["UnresolvedBareModelCoupling",<||>]]];values
];

(* Scalar projection before tensor simplification avoids carrying unused open
   current structures through large NNLO traces. Orthogonal averaging applies
   to the complete projected observable integrand, including all real momenta. *)
ConstructCurrentIntegrands[setup_Association,request_Association]:=Catch[Module[
 {generated,amplitudes,interference,projectors,spinRequest,scalar,average,values=<||>,
  records=<||>,generationSeconds,contractionSeconds=<||>,seconds,helicityAverage,
  helicityMethod,helicityRecords=<||>},
 helicityMethod=Lookup[request,"LongitudinalCurrentAverage","Automatic"];
 If[!MemberQ[{"Automatic","BeforeContraction","AfterContraction"},helicityMethod],
  partonicResultFail["DeclaredLongitudinalCurrentAverageMethodRequired"]];
 projectors=Lookup[request,"CurrentProjectors",None];
 If[!AssociationQ[projectors]||projectors===<||>,partonicResultFail["CurrentProjectorsRequired"]];
 {generationSeconds,generated}=AbsoluteTiming[GenerateCurrentAmplitudes[setup]];
 If[!AssociationQ[generated],partonicResultFail["CurrentAmplitudeGenerationFailed"]];
 amplitudes=generated["Amplitudes"];
 interference=Total[Values[amplitudes["Amplitude"]]]*
  conjugatePhysicalAmplitude[Total[Values[amplitudes["Conjugate"]]],setup];
 spinRequest=Join[KeyTake[setup,{"PhysicalMomenta","MasslessMomenta","SummedGluons","UnobservedGluonStates"}],
  <|"Assumptions"->Lookup[request,"Assumptions",True],"PrintTimings"->Lookup[request,"PrintTimings",False],"KernelCount"->Lookup[request,"KernelCount",1],
   "DiracAlgebraBackend"->Lookup[request,"DiracAlgebraBackend","Automatic"],
   "FORMOptions"->Lookup[request,"FORMOptions",<||>],
   "Momenta"->DeleteDuplicates[Join[Flatten[List@@setup["PartonMomentum"]],
    setup["ForwardAmplitudes"]["LoopMomenta"],setup["ConjugateAmplitudes"]["LoopMomenta"]]],
   "KinematicRules"->Select[Lookup[request,"KinematicRules",{}],
    With[{left=FeynCalc`FCI[First[#]]},
     MatchQ[left,FeynCalc`Pair[FeynCalc`Momentum[_Symbol,D],FeynCalc`Momentum[_Symbol,D]]]&&
     AllTrue[Cases[left,FeynCalc`Momentum[m_,___]:>m,Infinity],MemberQ[setup["PhysicalMomenta"],#]&]]&]|>];
 Do[
  Print["Contracting generated current structure ",name];
  {seconds,scalar}=AbsoluteTiming[
   helicityAverage=If[helicityMethod=!="AfterContraction"&&KeyExistsQ[request,"AngularAverage"],
    currentJointHelicityDensityData[setup,projectors[name],request["AngularAverage"]],None];
   If[AssociationQ[helicityAverage]&&!currentJointHelicityAmplitudeQ[interference,helicityAverage],
    helicityAverage=Failure["AdditionalPhysicalOrAxialAmplitudeTensors",<||>]];
   If[helicityMethod==="BeforeContraction"&&!AssociationQ[helicityAverage],
    partonicResultFail["JointHelicityAverageNotApplicable",<|"Cause"->helicityAverage|>]];
   scalar=If[AssociationQ[helicityAverage],
    AssociateTo[helicityRecords,name->helicityAverage["Metadata"]];
    contractPreparedPartonicSpinDensities[interference,setup["SpinDensities"],
     helicityAverage["Densities"],spinRequest],
    ContractPartonicSpinDensities[interference FeynCalc`FCI[projectors[name]],
     setup["SpinDensities"],spinRequest]];
   If[scalar===$Failed||FailureQ[scalar],partonicResultFail["CurrentSpinContractionFailed",<|"Cause"->scalar|>]];
   scalar=FeynCalc`Contract[scalar]/.Lookup[request,"ColorRules",{}];
   If[KeyExistsQ[request,"AngularAverage"],
    If[TrueQ[Lookup[request,"PrintTimings",False]],Print["Averaging correlated evanescent scalar products"]];
    average=AverageEvanescentScalarProducts[scalar,request["AngularAverage"]];
    If[!AssociationQ[average],partonicResultFail["CurrentJointAngularAverageFailed",<|"Cause"->average|>]];
    If[!IntegerQ[Lookup[average,"EvanescentPolynomialDegree",None]],partonicResultFail["ExplicitAngularPolynomialDegreeRequired"]];
    AssociateTo[records,name->KeyDrop[average,{"Value","PreservedPropagators"}]];scalar=average["Value"]];
   scalar];
  AssociateTo[values,name->scalar];AssociateTo[contractionSeconds,name->seconds],
 {name,Keys[projectors]}];
 If[!FreeQ[values,_FeynCalc`DiracTrace|_FeynCalc`DiracGamma|_FeynCalc`LorentzIndex|
   _FeynCalc`Spinor|_FeynCalc`Polarization|_Failure|$Failed|$Aborted],
  partonicResultFail["ScalarCurrentIntegrandsRequired"]];
 <|"Format"->"FeynFacet-CurrentIntegrands","FormatVersion"->1,
  "Values"->values,"ProcessDefinition"->setup,"CurrentProjectors"->projectors,
  "DiagramCounts"->Map[Length,amplitudes],"GenerationSeconds"->generationSeconds,
  "ContractionSeconds"->contractionSeconds,"AngularAverage"->records,
  "LongitudinalCurrentAverage"->helicityRecords,
  "PhaseSpaceAndFluxIncluded"->False,"ConjugateInterferenceAdded"->False|>
],"PartonicResults"];
ConstructCurrentRealDensity[setup_Association,request_Association]:=Catch[Module[
 {generated,amplitudes,interference,tensor,projectors,geometry,scalars,measured,values,normalization,
  couplingRules,seconds,meta,physicalRequest},
 If[!ContainsAll[Keys[request],{"CurrentProjectors","TwoParticleMeasurement","CurrentNormalization",
   "BareCouplingRules","DimensionalRegulator"}],partonicResultFail["MeasuredCurrentGeometryRequired"]];
 If[Lookup[setup["ForwardAmplitudes"],"LoopOrder"]!=0||Lookup[setup["ConjugateAmplitudes"],"LoopOrder"]!=0||
  Length[Last[setup["Partons"]]]=!=2,partonicResultFail["TwoParticleTreeCurrentRequired"]];
 projectors=request["CurrentProjectors"];couplingRules=request["BareCouplingRules"];
 If[!AssociationQ[projectors]||projectors===<||>||!MatchQ[couplingRules,{(_Rule)...}],
  partonicResultFail["CurrentProjectorsAndBareCouplingRulesRequired"]];
 geometry=ConstructTwoParticleMeasurement[Join[request["TwoParticleMeasurement"],
  <|"DimensionalRegulator"->request["DimensionalRegulator"]|>]];
 If[!AssociationQ[geometry],partonicResultFail["CurrentPhaseSpaceFailed",<|"Cause"->geometry|>]];
 If[Rest[geometry["Momenta"]][[2;;]]=!=Last[setup["PartonMomentum"]],
  partonicResultFail["MeasuredFinalMomentaMustMatchGeneratedCurrent"]];
 {seconds,generated}=AbsoluteTiming[GenerateCurrentAmplitudes[setup]];
 If[!AssociationQ[generated],partonicResultFail["CurrentRealGenerationFailed"]];
 amplitudes=generated["Amplitudes"];
 interference=Total[Values[amplitudes["Amplitude"]]]*
  conjugatePhysicalAmplitude[Total[Values[amplitudes["Conjugate"]]],setup];
 physicalRequest=KeyTake[setup,{"PhysicalMomenta","MasslessMomenta","SummedGluons","UnobservedGluonStates"}];
 tensor=ContractPartonicSpinDensities[interference,setup["SpinDensities"],physicalRequest];
 If[tensor===$Failed||FailureQ[tensor],partonicResultFail["CurrentRealSpinContractionFailed"]];
 scalars=FeynCalc`FeynAmpDenominatorExplicit[FeynCalc`Contract[FeynCalc`FCI[tensor #]]]&/@Values[projectors];
 If[!MemberQ[{{},{geometry["MeasurementVariable"]}},Lookup[request,"IntegratedPhaseSpaceVariables",{}]],
  partonicResultFail["DeclaredTwoParticleAngularIntegrationRequired"]];
 measured=If[Lookup[request,"IntegratedPhaseSpaceVariables",{}]==={},EvaluateTwoParticleMeasurement[#,geometry],
  IntegrateTwoParticleMeasurement[#,geometry]]&/@scalars;
 If[!AllTrue[measured,AssociationQ],partonicResultFail["CurrentRealPhaseSpaceFailed",<|"Cause"->measured|>]];
 normalization=request["CurrentNormalization"] Lookup[request,"SymmetryFactor",1];
 values=Map[Function[row,Factor[FeynFacet`SubstituteScalarPowers[normalization row["Value"],couplingRules]/.Lookup[request,"ColorRules",{}]]],measured];
 If[!FreeQ[values,_FeynCalc`SMP|_FeynCalc`Pair|_FeynCalc`Eps|_FeynCalc`DiracTrace|_FeynCalc`Polarization|_Integrate|_Failure],
  partonicResultFail["ExplicitCurrentRealDensityRequired"]];
 meta=KeyDrop[request,{"CurrentProjectors","KinematicRules","BornMomentumRules","BornConstraints","TwoParticleMeasurement","BareCouplingRules"}];
 Join[meta,<|"Format"->"FeynFacet-MeasuredCurrentDensity","FormatVersion"->1,"Order"->"NLO","Contribution"->"Real",
  "StructureFunctions"->Keys[projectors],"Values"->values,"ExactInEpsilon"->True,"ProcessDefinition"->setup,
  "Measurement"->geometry,"BareCouplingRules"->couplingRules,"SymmetryFactor"->Lookup[request,"SymmetryFactor",1],
  "DiagramCounts"->Map[Length,amplitudes],"GenerationSeconds"->seconds|>]
],"PartonicResults"];
ConstructCurrentRealContribution[density_Association,request_Association]:=Catch[Module[
 {e,axes,normals,powers,variables,distances,assumptions,smooth,normalData,expansions,rows,range,meta},
 If[Lookup[density,"Format",None]=!="FeynFacet-MeasuredCurrentDensity"||
  !ContainsAll[Keys[request],{"NormalVariables","EndpointPowers","EpsilonRange","EndpointConditions"}],
  partonicResultFail["CurrentRealEndpointRequestRequired"]];
 e=density["DimensionalRegulator"];axes=density["DistributionBasis"]["Axes"];
 variables=Lookup[axes,"Variable"];distances=Lookup[axes,"Distance"];
 normals=request["NormalVariables"];powers=request["EndpointPowers"];range=request["EpsilonRange"];
 If[Length[normals]=!=Length[axes]||Length[powers]=!=Length[axes]||!MatchQ[range,{_Integer,_Integer}]||First[range]>Last[range],
  partonicResultFail["CurrentRealEndpointAxesRequired"]];
 assumptions=Lookup[density,"Domain",True]&&And@@Thread[distances>0];
 smooth=FullSimplify[#/(Times@@MapThread[Power,{distances,powers}]),Assumptions->assumptions]&/@density["Values"];
 smooth=smooth/.Thread[variables->1-normals];
 normalData=<|"DimensionalRegulator"->e,"NormalVariables"->normals,"Intervals"->ConstantArray[{0,1},Length[normals]],
  "EndpointGeometry"->"NormalCrossings","EndpointConditions"->request["EndpointConditions"],
  "Assumptions"->Lookup[density,"Assumptions",True],
  "TestFunctionSupport"->Lookup[request,"TestFunctionSupport",<|"ExcludedFaces"->{}|>]|>;
 expansions=ExtractEndpointDistributions[Join[normalData,<|"Terms"->{<|"Powers"->powers,"SmoothFactor"->#|>}|>],
  <|"ThroughOrder"->Last[range]|>]&/@smooth;
 If[!AllTrue[expansions,AssociationQ],partonicResultFail["CurrentRealEndpointExpansionFailed",<|"Cause"->expansions|>]];
 meta=Join[KeyDrop[density,{"Format","FormatVersion","Values","ExactInEpsilon","Measurement","GenerationSeconds"}],
  <|"TestFunctionSupport"->normalData["TestFunctionSupport"],"DistributionBasis"-><|"Axes"->MapThread[Append[#1,"NormalVariable"->#2]&,{axes,normals}]|>|>];
 (* Each scalar expansion has one component until the final vector is assembled. *)
 If[Length[expansions]=!=Length[meta["StructureFunctions"]],
  partonicResultFail["CurrentStructureFunctionCountMismatch"]];
 rows=MapThread[CreatePartonicResultFromEndpointExpansion[#1,
  Join[meta,<|"StructureFunctions"->{#2}|>]]&,{expansions,meta["StructureFunctions"]}];
 If[!AllTrue[rows,AssociationQ],partonicResultFail["CurrentRealDistributionStorageFailed",<|"Cause"->rows|>]];
 rows=partonicDistributionVector[Lookup[rows,"Coefficients"]];
 (* Endpoint extraction determines a sufficient Laurent lower bound.
    Store requested coefficients below it explicitly as known zeros. *)
 rows=Association@Table[n->Lookup[rows,n,partonicDistributionZero[Length[axes]]],
  {n,Min[First[range],Min[Keys[rows]]],Max[Keys[rows]]}];
 CreatePartonicResult[rows,Join[meta,<|"EpsilonRange"->range,"EndpointOrderRequirements"->Lookup[expansions,"OrderRequirements"]|>]]
],"PartonicResults"];
(* The current contribution is contracted physically before loop integration.
   FeynCalc TID uses 1/(i pi^2) scalar functions; the analytic provider owns
   their normalization conversion. Only the incoming virtual amplitude is
   integrated here; its conjugate is included afterward as 2 Re. *)
ConstructCurrentVirtualContribution[setup_Association,request_Association]:=Catch[Module[
 {generated,amplitudes,tensor,interference,support,scalar,reduced,integrated,values,e,range,ell,physical,
  kinematicRules,point,conditions,series,coefficients,meta,normalization},
 If[!ContainsAll[Keys[request],{"CurrentProjectors","KinematicRules","BornMomentumRules","BornConstraints",
   "CurrentNormalization","DistributionBasis","Variables","DimensionalRegulator","EpsilonRange","BareCouplingRules"}],
  partonicResultFail["CurrentVirtualGeometryRequired"]];
 If[Lookup[setup["ForwardAmplitudes"],"LoopOrder"]!=1||Lookup[setup["ConjugateAmplitudes"],"LoopOrder"]!=0||
   Length[Last[setup["Partons"]]]=!=1,partonicResultFail["OneLoopOneParticleCurrentRequired"]];
 ell=First[setup["ForwardAmplitudes"]["LoopMomenta"]];
 e=request["DimensionalRegulator"];range=request["EpsilonRange"];
 If[!MatchQ[range,{_Integer,_Integer}]||First[range]>Last[range],partonicResultFail["CurrentVirtualEpsilonRangeRequired"]];
 support=currentBornSupport[request];point=support["Point"];kinematicRules=support["KinematicRules"]/.point;
 conditions=Lookup[request,"Assumptions",True];physical=setup["PhysicalMomenta"];
 generated=GenerateCurrentAmplitudes[setup];If[!AssociationQ[generated],partonicResultFail["CurrentVirtualGenerationFailed"]];
 amplitudes=generated["Amplitudes"];
 interference=Total[Values[amplitudes["Amplitude"]]]*
  conjugatePhysicalAmplitude[Total[Values[amplitudes["Conjugate"]]],setup];
 tensor=ContractPartonicSpinDensities[interference,setup["SpinDensities"],
  KeyTake[setup,{"PhysicalMomenta","MasslessMomenta","SummedGluons","UnobservedGluonStates"}]];
 If[tensor===$Failed||FailureQ[tensor],partonicResultFail["CurrentVirtualSpinContractionFailed"]];
 scalar=Map[Function[projection,FeynCalc`ExpandScalarProduct[FeynCalc`Contract[
   FeynCalc`FCI[tensor projection]]/.support["MomentumRules"]]],Values[request["CurrentProjectors"]]];
 scalar=With[{loopMomentum=ell},
  scalar/.(HoldPattern[FeynCalc`Pair[FeynCalc`Momentum[loopMomentum],FeynCalc`Momentum[external_]]]/;MemberQ[physical,external]):>
   FeynCalc`Pair[FeynCalc`Momentum[loopMomentum,D],FeynCalc`Momentum[external,D]]];
 scalar=Factor[scalar/.kinematicRules];
 scalar=Catch[oneLoopAveragePhysicalNumerator[#,ell,physical,kinematicRules,conditions],"EpsilonOrders"]&/@scalar;
 If[AnyTrue[scalar,FailureQ],partonicResultFail["CurrentEvanescentLoopAverageFailed",<|"Cause"->scalar|>]];
 reduced=withOneLoopKinematics[
  FeynCalc`TID[scalar,ell,FeynCalc`ToPaVe->True],
  Cases[kinematicRules,HoldPattern[FeynCalc`Pair[FeynCalc`Momentum[a_,D],FeynCalc`Momentum[b_,D]]->value_]:>{a,b,value}]]/.D->4-2e;
 If[!FreeQ[reduced,Indeterminate|_DirectedInfinity|_FeynCalc`TID],
  partonicResultFail["CurrentVirtualTensorReductionFailed",<|"Integrand"->scalar,"Reduced"->reduced|>]];
 integrated=EvaluateOneLoopScalarFunctions[reduced,e,conditions];
 If[FailureQ[integrated],partonicResultFail["CurrentVirtualScalarEvaluationFailed",<|"Cause"->integrated|>]];
 values=FeynFacet`SubstituteScalarPowers[integrated support["Measure"],request["BareCouplingRules"]]/.Lookup[request,"ColorRules",{}];
 values=FullSimplify[ComplexExpand[values+Conjugate[values]],Assumptions->conditions&&Element[e,Reals]];
 If[!FreeQ[values,_FeynCalc`Pair|_FeynCalc`PaVe|_FeynCalc`TID|_FeynCalc`FeynAmpDenominator|_FeynCalc`SMP|_FeynCalc`DiracTrace|_Integrate|_Conjugate|_Re|_Im],
  partonicResultFail["ExplicitRealCurrentVirtualCoefficientRequired"]];
 series=Normal[Series[values,{e,0,Last[range]}]];
 coefficients=Association@Table[n->partonicCornerDistribution[FullSimplify[Coefficient[series,e,n],
  Assumptions->conditions],Length[support["Axes"]]],{n,First[range],Last[range]}];
 meta=Join[KeyDrop[request,{"CurrentProjectors","KinematicRules","BornMomentumRules","BornConstraints","TwoParticleMeasurement","BareCouplingRules"}],
  <|"Order"->"NLO","Contribution"->"Virtual","StructureFunctions"->Keys[request["CurrentProjectors"]],
  "ProcessDefinition"->setup,"BornSupportJacobian"->support["JacobianDeterminant"],"LoopNormalization"->"Generated d^D ell/(2 pi)^D measure"|>];
 CreatePartonicResult[coefficients,meta]
],"PartonicResults"];
(* Structure functions share distribution axes; only leaf coefficients form a vector. *)
partonicDistributionVector[rows_List]:=Module[{associations,keys},
 associations=Select[rows,AssociationQ];If[associations==={},Return[rows]];
 If[!AllTrue[rows,AssociationQ[#]||#===0&],partonicResultFail["MatchingDistributionTreesRequired"]];
 keys=Union@@(Keys/@associations);
 Association@Table[key->partonicDistributionVector[If[AssociationQ[#],Lookup[#,key,0],0]&/@rows],{key,keys}]
];
End[];EndPackage[];
