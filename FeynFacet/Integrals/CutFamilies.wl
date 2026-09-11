(* Cut propagators as distributions, including linear measurement constraints.
   Particle cuts additionally carry their declared positive-energy condition.
   No ordinary causal prescription is removed by construction or by IBP. *)
BeginPackage["FeynFacet`"];
CutPropagator::usage="CutPropagator[G,n] is the discontinuity [(G-i0)^(-n)-(G+i0)^(-n)]/(2 Pi I), equal to (-1)^(n-1) delta^(n-1)(G)/(n-1)!. Nonpositive integer powers vanish. Positive-energy conditions belong to particle-cut metadata, not to a measurement cut.";
NormalizeCutPropagator::usage="NormalizeCutPropagator[CutPropagator[G,n],variables,assumptions] makes a real linear constraint monic, retaining the sign and Jacobian for every derivative order.";
CreateCutIntegralDefinition::usage="CreateCutIntegralDefinition[request] validates typed particle and measurement cuts and affine inverse propagators before partial fractions. Denominators may be linearly dependent. CreateCutIntegralFamily additionally requires a complete independent denominator basis for reduction and differentiation.";
CreateCutIntegralFamily::usage="CreateCutIntegralFamily[request] validates a complete FCTopology with explicitly typed Cuts (Particle or Measurement). Particle cuts declare Index, Momentum, optional MassSquared and EnergyDirection; Measurement cuts declare Index. MeasurePrefactor and TimeDirection are explicit. No i0-independence certificate is inferred.";
DifferentiateCutIntegral::usage="DifferentiateCutIntegral[family,GLI,parameter,request] differentiates at fixed loop components, including moving external momenta, all denominator powers and MeasurePrefactor. Request may supply MomentumDerivatives as an Association; otherwise the nondegenerate external Gram matrix determines a lift. The entire forward-cut family is defined by joint meromorphic continuation; extra acceptance theta functions are outside this interface.";
ApplyMeasurementCutToTestFunction::usage="ApplyMeasurementCutToTestFunction[CutPropagator[G,n],z,phi,assumptions] evaluates the exact distributional pairing in z for an affine real G with nonzero slope. The derivative acts on the entire supplied multiplier phi, including any explicit z dependence.";
CreateMeasuredPhaseSpaceDefinition::usage="CreateMeasuredPhaseSpaceDefinition[request] builds the typed massless forward-cut definition from FinalMomenta, TotalMomentum, ExternalMomenta, KinematicRules, ReferenceMomentum, TaggedMomentum and MeasurementVariable. The last final momentum is eliminated by momentum conservation. It uses the standard Lorentz-invariant phase-space measure and delta(z-p.tag/p.total); ordinary prescribed propagators may be supplied before partial fractions.";
CreateLoopIntegralFamily::usage="CreateLoopIntegralFamily[request] validates a complete ordinary loop-integral family with its FCTopology, MeasurePrefactor and causal prescriptions. It uses the same affine scalar-product algebra as cut families and has no cut constraints.";
Begin["`Private`"];
CutPropagator[g_,n_Integer/;n<=0]:=0;
Derivative[1,0][CutPropagator][g_,n_Integer?Positive]:=-n CutPropagator[g,n+1];
NormalizeCutPropagator[CutPropagator[g_,n_Integer?Positive],variables_List,assumptions_:True]:=Module[{compiled,scale},
 compiled=CompileLinearMeasurement[<|"Observable"->-g,"Value"->0,
  "IntegrationVariables"->variables,"Assumptions"->assumptions|>];
 If[FailureQ[compiled],Return[compiled]];
 scale=compiled["ConstraintScale"];
 FullSimplify[Sign[scale]^(n-1)compiled["Jacobian"]^n,Assumptions->assumptions]*
  CutPropagator[compiled["CutPolynomial"],n]
];
ApplyMeasurementCutToTestFunction[CutPropagator[g_,n_Integer?Positive],z_Symbol,phi_,assumptions_:True]:=
 Catch[Module[{slope,root},
  If[!PolynomialQ[g,z]||Exponent[g,z]=!=1,cutFamilyFail["AffineMeasurementVariableRequired"]];
  slope=Coefficient[Expand[g],z];root=Cancel[-(g-slope z)/slope];
  If[!FreeQ[{slope,root},z]||!TrueQ[FullSimplify[Element[{slope,root},Reals]&&slope!=0,
    Assumptions->assumptions]],cutFamilyFail["NonzeroRealMeasurementSlopeRequired"]];
  FullSimplify[Sign[slope]^(n-1)/(Abs[slope]^n (n-1)!)*(D[phi,{z,n-1}]/.z->root),
   Assumptions->assumptions]
 ],"CutFamily"];
cutFamilyFail[tag_,data_:<||>]:=Throw[Failure[tag,data],"CutFamily"];
CreateMeasuredPhaseSpaceDefinition[request_Association]:=Catch[Module[
 {final,total,external,reference,tag,z,kin,conditions,loops,recoil,routing,jacobian,cuts,
  particles,ordinary,top,definition,name,dimension},
 If[!ContainsAll[Keys[request],{"FinalMomenta","TotalMomentum","ExternalMomenta",
    "KinematicRules","ReferenceMomentum","TaggedMomentum","MeasurementVariable","Assumptions"}],
  cutFamilyFail["MeasuredPhaseSpaceGeometryRequired"]];
 {final,total,external,reference,tag,z,kin,conditions}=Lookup[request,
  {"FinalMomenta","TotalMomentum","ExternalMomenta","ReferenceMomentum","TaggedMomentum",
   "MeasurementVariable","KinematicRules","Assumptions"}];
 If[!MatchQ[final,{_Symbol,_Symbol..}]||!DuplicateFreeQ[final]||
    !MatchQ[external,{_Symbol..}]||!DuplicateFreeQ[external]||
    Intersection[final,external]=!={}||!MemberQ[final,tag]||!MatchQ[z,_Symbol]||
    !MatchQ[kin,{(_Rule)..}],cutFamilyFail["DistinctMasslessFinalMomentaAndExternalFrameRequired"]];
 loops=Most[final];recoil=Expand[total-Total[loops]];routing={Last[final]->recoil};
 If[!PolynomialQ[total,external]||!TrueQ[(total/.Thread[external->0])===0]||
   !AllTrue[First/@CoefficientRules[total,external],Total[#]<=1&]||
   !PolynomialQ[reference,external]||!TrueQ[(reference/.Thread[external->0])===0]||
   !AllTrue[First/@CoefficientRules[reference,external],Total[#]<=1&],
  cutFamilyFail["LinearExternalTotalAndMeasurementReferenceRequired"]];
 kin=FeynCalc`FCI[kin];dimension=Lookup[request,"Dimension",D];
 If[dimension=!=D,cutFamilyFail["AmbientDPhaseSpaceRequired"]];
 jacobian=Factor[2FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[reference,total]]]/.kin];
 If[!TrueQ[FullSimplify[jacobian>0&&
   (FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[reference]]]/.kin)==0,
   Assumptions->conditions]],cutFamilyFail["FutureNullMeasurementReferenceRequired"]];
 particles=final/.routing;
 cuts=Join[MapIndexed[<|"Index"->First[#2],"Type"->"Particle","Momentum"->#1|>&,particles],
  {<|"Index"->Length[final]+1,"Type"->"Measurement"|>}];
 ordinary=FeynCalc`FCI[Lookup[request,"OrdinaryPropagators",{}]/.routing];
 If[!ListQ[ordinary],cutFamilyFail["OrdinaryPropagatorListRequired"]];
 name=Lookup[request,"Name",MeasuredPhaseSpace];
 top=FeynCalc`FCTopology[name,Join[
  FeynCalc`FCI[FeynCalc`SFAD[#]]&/@particles,
  {FeynCalc`FeynAmpDenominator[FeynCalc`StandardPropagatorDenominator[0,
    2FeynCalc`FCI[FeynCalc`SPD[reference,tag/.routing]],-jacobian z,{1,1}]]},ordinary],
  loops,external,kin,{}];
 definition=CreateCutIntegralDefinition[<|"Topology"->top,"Cuts"->cuts,
  "TimeDirection"->total,"Assumptions"->conditions,"Dimension"->D,
  "MeasurePrefactor"->(2Pi)^(Length[final]-(Length[final]-1)D)jacobian|>];
 If[FailureQ[definition],Return[definition]];
 Join[definition,<|"MomentumConservationRules"->routing,"FinalMomenta"->final,
  "MeasurementVariable"->z,"ReferenceMomentum"->reference,"TaggedMomentum"->(tag/.routing),
  "MeasurementJacobian"->jacobian,
  "PhaseSpaceConvention"->"Product d^D k delta_+(k^2)/(2 Pi)^(D-1), times (2 Pi)^D delta^D(P-sum k), with delta(z-p.tag/p.P). No flux, coupling, spin, color or identical-particle factor."|>]
],"CutFamily"];
CreateCutIntegralDefinition[request_Association]:=createCutIntegralData[request,False];
CreateCutIntegralFamily[request_Association]:=createCutIntegralData[request,True];
CreateLoopIntegralFamily[request_Association]:=createCutIntegralData[
 Join[request,<|"Cuts"->{},"IntegrationType"->"Virtual"|>],True];
createCutIntegralData[request_Association,complete_]:=Catch[Module[
 {top,cuts,indices,particle,measurement,descriptors,cores,loops,external,kin,conditions,reference,
  prefactor,basis,variables,replace,polynomials,matrix,constant,denominators,inverse,idx,expected,energy},
 If[!ContainsAll[Keys[request],{"Topology","Cuts","MeasurePrefactor"}],
  cutFamilyFail["CutFamilyDefinitionRequired"]];
 If[Lookup[request,"AdditionalAcceptanceBoundaries",None]=!=None,
  cutFamilyFail["AdditionalAcceptanceBoundariesNotImplemented"]];
 If[KeyExistsQ[request,"CutConvention"]&&
  request["CutConvention"]=!="(-1)^(n-1) delta^(n-1)(G)/(n-1)!; particle cuts additionally restrict positive energy",
  cutFamilyFail["UnsupportedCutDistributionConvention"]];
 If[MemberQ[{"FeynFacet-CutIntegralFamily","FeynFacet-CutIntegralDefinition"},Lookup[request,"Format",None]]&&
  KeyExistsQ[request,"Definition"]&&
  request["Definition"]=!="Joint meromorphic dimensional/analytic continuation of forward-energy cut integrals; the continued distribution fixes the massless-tip extension.",
  cutFamilyFail["UnsupportedForwardCutContinuation"]];
 top=request["Topology"];cuts=request["Cuts"];prefactor=request["MeasurePrefactor"];
 (* Completeness is checked below by the exact affine scalar-product matrix.
    FeynCalc's basis checker additionally demands a common eta sign, which is
    not a condition for independence and rejects valid prescribed sources. *)
 If[!MatchQ[top,_FeynCalc`FCTopology]||!TrueQ[FeynCalc`FCLoopValidTopologyQ[top]]||
  !ListQ[cuts]||(cuts==={}&&Lookup[request,"IntegrationType",None]=!="Virtual")||!AllTrue[cuts,AssociationQ]||
  !AllTrue[cuts,ContainsAll[Keys[#],{"Index","Type"}]&],
  cutFamilyFail["CompleteTopologyAndTypedCutsRequired"]];
 loops=top[[3]];external=top[[4]];kin=FeynCalc`FCI[top[[5]]];
 conditions=Lookup[request,"Assumptions",True];reference=Lookup[request,"TimeDirection",None];
 prefactor=FeynCalc`ExpandScalarProduct[FeynCalc`FCI[prefactor]]/.kin;
 If[!FreeQ[prefactor,_FeynCalc`Pair|_FeynCalc`Momentum],cutFamilyFail["ExplicitExternalMeasureRequired"]];
 indices=If[cuts==={},{},Lookup[cuts,"Index"]];
 If[!DuplicateFreeQ[indices]||!VectorQ[indices,IntegerQ[#]&&1<=#<=Length[top[[2]]]&]||
   !AllTrue[cuts,MemberQ[{"Particle","Measurement"},#["Type"]]&],
  cutFamilyFail["DistinctTypedCutSlotsRequired"]];
 If[!FreeQ[{kin,prefactor,reference},Alternatives@@loops]||
   !FreeQ[{top,cuts,prefactor},_Real|_Failure|_Missing|$Failed|$Aborted]||TrueQ[prefactor===0],
  cutFamilyFail["ExactExternalCutFamilyDataRequired"]];
 descriptors=propagatorDescriptor/@top[[2]];
 If[MemberQ[descriptors,$Failed]||!AllTrue[descriptors,#["Power"]===1&],
  cutFamilyFail["UnitPowerTopologyPropagatorsRequired"]];
 cores=(FeynCalc`ExpandScalarProduct[#["UnitCore"]]/.kin)&/@descriptors;
 particle=Select[cuts,#["Type"]==="Particle"&];measurement=Select[cuts,#["Type"]==="Measurement"&];
 If[particle=!={}&&(reference===None||!TrueQ[FullSimplify[
   (FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[reference]]]/.kin)>0,Assumptions->conditions]]),
  cutFamilyFail["TimelikeParticleCutReferenceRequired"]];
 Do[
  idx=cut["Index"];
  If[cut["Type"]==="Particle",
   If[!KeyExistsQ[cut,"Momentum"]||!MemberQ[{1,-1},Lookup[cut,"EnergyDirection",1]]||
     descriptors[[idx,"Type"]]=!="QuadraticLorentzian",cutFamilyFail["OrientedQuadraticParticleCutRequired"]];
   expected=FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[cut["Momentum"]]-Lookup[cut,"MassSquared",0]]]/.kin;
   If[!TrueQ[Factor[cores[[idx]]-expected]===0],cutFamilyFail["ParticleCutPolynomialMismatch"]];
   energy=FeynCalc`ExpandScalarProduct[FeynCalc`FCI[
    FeynCalc`SPD[Lookup[cut,"EnergyDirection",1]cut["Momentum"],reference]]]/.kin;
   cuts=Replace[cuts,cut->Join[cut,<|"EnergyDirection"->Lookup[cut,"EnergyDirection",1],
    "MassSquared"->Lookup[cut,"MassSquared",0],"PositiveEnergyCondition"->(energy>0)|>],{1}],
   If[descriptors[[idx,"Type"]]=!="LinearLorentzian"||
      KeyExistsQ[cut,"EnergyDirection"]||KeyExistsQ[cut,"Momentum"]||
      Lookup[cut,"PositiveEnergyCondition",None]=!=None,
    cutFamilyFail["LinearMeasurementCutWithoutEnergyConditionRequired"]];
   cuts=Replace[cuts,cut->Join[cut,<|"PositiveEnergyCondition"->None|>],{1}]
  ],{cut,cuts}];
 basis=Join[Flatten[Table[FeynCalc`FCI[FeynCalc`SPD[loops[[i]],loops[[j]]]],
   {i,Length[loops]},{j,i,Length[loops]}]],
  Flatten[Table[FeynCalc`FCI[FeynCalc`SPD[ell,ext]],{ell,loops},{ext,external}]]];
 variables=Table[Unique["loopScalarProduct$"],{Length[basis]}];replace=Thread[basis->variables];
 polynomials=Expand[cores/.replace];
 If[!AllTrue[polynomials,PolynomialQ[#,variables]&]||
  !FreeQ[polynomials,_FeynCalc`Pair|_FeynCalc`Momentum]||
  !AllTrue[Flatten[First/@CoefficientRules[#,variables]&/@polynomials,1],Total[#]<=1&],
  cutFamilyFail["AffineScalarProductDenominatorsRequired"]];
 matrix=Table[Coefficient[poly,var],{poly,polynomials},{var,variables}];
 constant=polynomials/.Thread[variables->0];
 If[TrueQ[complete]&&(Length[matrix]=!=Length[variables]||TrueQ[Factor[Det[matrix]]===0]),
  cutFamilyFail["IndependentCompleteScalarProductBasisRequired"]];
 denominators=Table[Unique["inversePropagator$"],{Length[cores]}];
 inverse=If[TrueQ[complete],Factor/@LinearSolve[matrix,denominators-constant],Missing["DependentDenominatorsAllowed"]];
 Join[request,<|"Format"->If[cuts==={},"FeynFacet-LoopIntegralFamily",If[TrueQ[complete],"FeynFacet-CutIntegralFamily","FeynFacet-CutIntegralDefinition"]],"FormatVersion"->1,
  "Cuts"->cuts,"MeasurePrefactor"->prefactor,"CutIndices"->indices,"ParticleCutIndices"->Lookup[particle,"Index",{}],
  "MeasurementCutIndices"->Lookup[measurement,"Index",{}],"InversePropagators"->cores,
  "LoopScalarProducts"->basis,"DenominatorVariables"->denominators,
  "ScalarProductRules"->If[TrueQ[complete],Thread[basis->inverse],Missing["IndependentBasisRequired"]],
  "OrdinaryPropagatorPrescriptions"->Table[
    If[MemberQ[indices,i],None,
     FirstCase[FeynCalc`FCI[top[[2,i]]],FeynCalc`StandardPropagatorDenominator[___,{_,sign_}]:>sign,1,Infinity]],
    {i,Length[cores]}],
  "Definition"->If[cuts==={},
    "Dimensionally and analytically continued virtual loop integral with declared ordinary causal prescriptions.",
    "Joint meromorphic dimensional/analytic continuation of forward-energy cut integrals; the continued distribution fixes the massless-tip extension."],
  "AdditionalAcceptanceBoundaries"->None,
  "DerivativeScope"->"Interior physical chamber and finite derivative closure; external endpoint distributions are expanded afterward, not discarded.",
  "CutConvention"->"(-1)^(n-1) delta^(n-1)(G)/(n-1)!; particle cuts additionally restrict positive energy",
  "OrdinaryPrescriptionLimitEstablished"->False|>]
],"CutFamily"];
(* G'=B G+G B^T fixes external invariants without changing loop variables.
   Eliminate external scalar products before this lift, then differentiate
   remaining loop-external products as well as explicit parameter factors.
   Review: External/ChatGPT/Records/2026-09-09/09_cut_family_differential_equations.md. *)
cutExternalMomentumVelocity[family_,parameter_,request_]:=Module[
 {top=family["Topology"],external,kin,gram,derivative,velocity,given,momenta},
 external=top[[4]];kin=FeynCalc`FCI[top[[5]]];
 gram=FeynCalc`FCI[Outer[FeynCalc`SPD,external,external]]/.kin;
 If[!FreeQ[gram,_FeynCalc`Pair]||TrueQ[Factor[Det[gram]]===0],
  cutFamilyFail["NondegenerateExternalGramMatrixRequired"]];
 derivative=D[gram,parameter];
 given=Lookup[request,"MomentumDerivatives",Automatic];
 If[given===Automatic,velocity=Map[Factor,derivative.Inverse[gram]/2,{2}],
  If[!AssociationQ[given]||Sort[Keys[given]]=!=Sort[external],
   cutFamilyFail["DerivativeOfEveryExternalMomentumRequired"]];
  momenta=Lookup[given,external];
  If[!AllTrue[momenta,PolynomialQ[#,external]&&
    TrueQ[(#/.Thread[external->0])===0]&&
    AllTrue[First/@CoefficientRules[#,external],Total[#]<=1&]&],
   cutFamilyFail["LinearExternalMomentumDerivativesRequired"]];
  velocity=Table[Coefficient[mom,ext],{mom,momenta},{ext,external}]];
 If[!AllTrue[Flatten[Map[Factor,derivative-velocity.gram-gram.Transpose[velocity],{2}]],#===0&],
  cutFamilyFail["MomentumDerivativeDoesNotRealizeKinematicVariation"]];
 velocity
];
DifferentiateCutIntegral[family_Association,master_FeynCalc`GLI,parameter_Symbol,request_Association:<||>]:=Catch[Module[
 {top,indices,cuts,cores,prefactor,variables,raised,polynomial,constant,result,coefficient,velocity,
  basis,coordinates,scalarDerivatives,external,loops,corePolynomial,totalDerivative},
 If[Lookup[family,"Format",None]=!="FeynFacet-CutIntegralFamily",cutFamilyFail["CutIntegralFamilyRequired"]];
 top=family["Topology"];indices=master[[2]];cuts=family["CutIndices"];
 external=top[[4]];loops=top[[3]];
 If[master[[1]]=!=top[[1]]||Length[indices]=!=Length[top[[2]]]||!VectorQ[indices,IntegerQ]||
  MemberQ[Join[loops,external],parameter]||!FreeQ[Lookup[family,"Dimension",D],parameter],
  cutFamilyFail["MatchingIntegralIndicesAndExternalParameterRequired"]];
 If[AnyTrue[indices[[cuts]],#<=0&],Return[0]];
 velocity=cutExternalMomentumVelocity[family,parameter,request];
 cores=family["InversePropagators"];prefactor=family["MeasurePrefactor"];variables=family["DenominatorVariables"];
 basis=family["LoopScalarProducts"];coordinates=Table[Unique["fixedLoopScalar$"],{Length[basis]}];
 scalarDerivatives=Join[ConstantArray[0,Length[loops](Length[loops]+1)/2],
  Flatten[Table[Sum[velocity[[a,b]]FeynCalc`FCI[FeynCalc`SPD[ell,external[[b]]]],{b,Length[external]}],
   {ell,loops},{a,Length[external]}]]];
 result=Factor[D[prefactor,parameter]/prefactor]master;
 Do[
  If[indices[[idx]]===0,Continue[]];
  corePolynomial=cores[[idx]]/.Thread[basis->coordinates];
  totalDerivative=(D[corePolynomial,parameter]+
    Sum[Coefficient[corePolynomial,coordinates[[j]]]scalarDerivatives[[j]],{j,Length[basis]}])/.Thread[coordinates->basis];
  polynomial=Expand[totalDerivative/.family["ScalarProductRules"]];
  If[polynomial===0,Continue[]];
  raised=ReplacePart[indices,idx->indices[[idx]]+1];constant=polynomial/.Thread[variables->0];
  result-=indices[[idx]]constant FeynCalc`GLI[master[[1]],raised];
  Do[coefficient=Coefficient[polynomial,variables[[j]]];
   If[coefficient===0,Continue[]];
   With[{lowered=ReplacePart[raised,j->raised[[j]]-1]},
    If[AllTrue[lowered[[cuts]],#>0&],result-=indices[[idx]]coefficient FeynCalc`GLI[master[[1]],lowered]]],
   {j,Length[variables]}],
 {idx,Length[cores]}];
 Expand[result]
],"CutFamily"];

(* Shared defining data for conservative identity checks. Provenance and
   auxiliary inverse-matrix coordinates are not integral definitions. *)
cutDefinitionConventions[record_Association]:=KeyTake[record,{
 "Dimension","MeasurePrefactor","MasterIntegralPrefactor","Normalization","MomentumSpaceConvention",
 "AdditionalAcceptanceBoundaries","Assumptions","KinematicConditions","KinematicRules",
 "TimeDirection","CutConvention","CutDistributionConvention","Definition","BranchPrescription"}];
normalizeCutTopologyRecord[record_Association]:=Module[{value=record,top},
 If[MemberQ[{"FeynFacet-CutIntegralFamily","FeynFacet-CutIntegralDefinition"},Lookup[record,"Format",None]],
  value=FeynFacet`CreateCutIntegralDefinition[record]];
 If[FailureQ[value],Return[value]];
 top=Lookup[value,"Topology",None];
 If[!MatchQ[top,_FeynCalc`FCTopology]||!MatchQ[top[[1]],_String|_Symbol],
  Return[Failure["CutTopologyDefinitionRequired",<||>]]];
 value
];
normalizeCutTopologyRecord[_]:=Failure["CutTopologyDefinitionRequired",<||>];
cutTopologyDefinitionMetadata[record_Association]:=Module[{top=record["Topology"],name},
 name=If[StringQ[top[[1]]],top[[1]],SymbolName[top[[1]]]];
 Join[cutDefinitionConventions[record],KeyTake[record,{
   "Format","Cuts","CutMomenta","CutIndices","CutDirections","ParticleCutIndices",
   "MeasurementCutIndices","OrdinaryPropagatorPrescriptions","PropagatorMassDimensions",
   "InversePropagators","IntegrationType"}],<|"Topology"->ReplacePart[top,1->name]|>]
];

End[];EndPackage[];
