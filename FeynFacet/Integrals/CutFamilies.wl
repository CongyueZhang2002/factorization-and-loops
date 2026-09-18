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
CreateMasslessPhaseSpaceDefinition::usage="CreateMasslessPhaseSpaceDefinition[request] builds the standard Lorentz-invariant phase space for declared massless FinalMomenta at fixed external TotalMomentum. The last final momentum is eliminated by momentum conservation. Optional ReferenceMomentum, TaggedMomentum and MeasurementVariable add a null-reference measurement cut. No flux, coupling, spin, color or identical-particle factor is included.";
CreateMeasuredPhaseSpaceDefinition::usage="CreateMeasuredPhaseSpaceDefinition[request] builds the typed massless forward-cut definition from FinalMomenta, TotalMomentum, ExternalMomenta, KinematicRules, ReferenceMomentum, TaggedMomentum and MeasurementVariable. The last final momentum is eliminated by momentum conservation. It uses the standard Lorentz-invariant phase-space measure and delta(z-p.tag/p.total); ordinary prescribed propagators may be supplied before partial fractions.";
CreateLoopIntegralFamily::usage="CreateLoopIntegralFamily[request] validates a complete ordinary loop-integral family with its FCTopology, MeasurePrefactor and causal prescriptions. It uses the same affine scalar-product algebra as cut families and has no cut constraints.";
CreateFinalStateMeasurementDefinitions::usage="CreateFinalStateMeasurementDefinitions[phaseSpace,measurement] constructs card-defined tuple measurements on massless final-state phase space. Identical constraints are combined by adding their declared weights; contact constraints and the original tuple inventory are retained.";
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
CreateMeasuredPhaseSpaceDefinition[request_Association]:=If[
 ContainsAll[Keys[request],{"ReferenceMomentum","TaggedMomentum","MeasurementVariable"}],
 CreateMasslessPhaseSpaceDefinition[request],Failure["MeasuredPhaseSpaceGeometryRequired",<||>]];
CreateMasslessPhaseSpaceDefinition[request_Association]/;KeyExistsQ[request,"Measurements"]:=
 createPolynomialMeasuredPhaseSpace[request];
CreateMasslessPhaseSpaceDefinition[request_Association]:=Catch[Module[
 {final,total,external,reference,tag,z,kin,conditions,loops,recoil,routing,jacobian,cuts,
  particles,ordinary,top,definition,name,dimension,measured,measurementPropagators},
 measured=AnyTrue[{"ReferenceMomentum","TaggedMomentum","MeasurementVariable"},KeyExistsQ[request,#]&];
 If[!ContainsAll[Keys[request],{"FinalMomenta","TotalMomentum","ExternalMomenta","KinematicRules","Assumptions"}]||
   (measured&&!ContainsAll[Keys[request],{"ReferenceMomentum","TaggedMomentum","MeasurementVariable"}]),
  cutFamilyFail["MeasuredPhaseSpaceGeometryRequired"]];
 {final,total,external,reference,tag,z,kin,conditions}=Lookup[request,
  {"FinalMomenta","TotalMomentum","ExternalMomenta","ReferenceMomentum","TaggedMomentum",
   "MeasurementVariable","KinematicRules","Assumptions"},None];
 If[!MatchQ[final,{_Symbol,_Symbol..}]||!DuplicateFreeQ[final]||
    !MatchQ[external,{_Symbol..}]||!DuplicateFreeQ[external]||
    Intersection[final,external]=!={}||(measured&&(!MemberQ[final,tag]||!MatchQ[z,_Symbol]))||
    !MatchQ[kin,{(_Rule)..}],cutFamilyFail["DistinctMasslessFinalMomentaAndExternalFrameRequired"]];
 loops=Most[final];recoil=Expand[total-Total[loops]];routing={Last[final]->recoil};
 If[!PolynomialQ[total,external]||!TrueQ[(total/.Thread[external->0])===0]||
   !AllTrue[First/@CoefficientRules[total,external],Total[#]<=1&]||
   (measured&&(!PolynomialQ[reference,external]||!TrueQ[(reference/.Thread[external->0])===0]||
   !AllTrue[First/@CoefficientRules[reference,external],Total[#]<=1&])),
  cutFamilyFail["LinearExternalTotalAndMeasurementReferenceRequired"]];
 kin=FeynCalc`FCI[kin];dimension=Lookup[request,"Dimension",D];
 If[dimension=!=D,cutFamilyFail["AmbientDPhaseSpaceRequired"]];
 jacobian=If[measured,Factor[2FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[reference,total]]]/.kin],1];
 If[measured&&!TrueQ[FullSimplify[jacobian>0&&
   (FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[reference]]]/.kin)==0,
   Assumptions->conditions]],cutFamilyFail["FutureNullMeasurementReferenceRequired"]];
 particles=final/.routing;
 cuts=Join[MapIndexed[<|"Index"->First[#2],"Type"->"Particle","Momentum"->#1|>&,particles],
  If[measured,{<|"Index"->Length[final]+1,"Type"->"Measurement"|>},{}]];
 ordinary=FeynCalc`FCI[Lookup[request,"OrdinaryPropagators",{}]/.routing];
 If[!ListQ[ordinary],cutFamilyFail["OrdinaryPropagatorListRequired"]];
 name=Lookup[request,"Name",If[measured,MeasuredPhaseSpace,MasslessPhaseSpace]];
 measurementPropagators=If[measured,{FeynCalc`FeynAmpDenominator[FeynCalc`StandardPropagatorDenominator[0,
  2FeynCalc`FCI[FeynCalc`SPD[reference,tag/.routing]],-jacobian z,{1,1}]]},{}];
 top=FeynCalc`FCTopology[name,Join[
  FeynCalc`FCI[FeynCalc`SFAD[#]]&/@particles,
  measurementPropagators,ordinary],
  loops,external,kin,{}];
 definition=CreateCutIntegralDefinition[<|"Topology"->top,"Cuts"->cuts,
  "TimeDirection"->total,"Assumptions"->conditions,"Dimension"->D,
  "MeasurePrefactor"->(2Pi)^(Length[final]-(Length[final]-1)D)jacobian|>];
 If[FailureQ[definition],Return[definition]];
 Join[definition,<|"MomentumConservationRules"->routing,"FinalMomenta"->final,
  "PhaseSpaceConvention"->"Product d^D k delta_+(k^2)/(2 Pi)^(D-1), times (2 Pi)^D delta^D(P-sum k). No flux, coupling, spin, color or identical-particle factor."|>,
  If[measured,<|"MeasurementVariable"->z,"ReferenceMomentum"->reference,"TaggedMomentum"->(tag/.routing),
   "MeasurementJacobian"->jacobian,"MeasurementConvention"->"delta(z-p.tag/p.total)"|>,<||>]]
],"CutFamily"];
(* A measured observable is a pushforward of the same phase space.
   Loop-dependent unit-cut Jacobians are numerator insertions, not measures. *)
createPolynomialMeasuredPhaseSpace[request_Association]:=Catch[Module[
 {base,top,basis,coordinates,coordinateRules,fromCoordinates,kin,routing,particles,total,
  positive,assumptions,unitRules,measurements,compiled,observable,unitObservable,z,
  row,props,cuts,records={},contacts={},numerator=1,index,definition},
 measurements=request["Measurements"];
 If[!MatchQ[measurements,{__Association}]||
   !AllTrue[measurements,ContainsAll[Keys[#],{"Variable","Observable"}]&]||
   !DuplicateFreeQ[Lookup[measurements,"Variable"]],cutFamilyFail["DistinctPolynomialMeasurementsRequired"]];
 base=FeynFacet`CreateMasslessPhaseSpaceDefinition[KeyDrop[request,{"Measurements"}]];
 If[!AssociationQ[base],cutFamilyFail["UnderlyingMasslessPhaseSpaceRequired",<|"Cause"->base|>]];
 If[base["MeasurementCutIndices"]=!={},cutFamilyFail["OneExplicitMeasurementSpecificationRequired"]];
 top=base["Topology"];basis=base["LoopScalarProducts"];kin=top[[5]];
 routing=base["MomentumConservationRules"];particles=base["FinalMomenta"]/.routing;
 total=request["TotalMomentum"];
 coordinates=Table[Unique["measurementScalar$"],{Length[basis]}];
 coordinateRules=Thread[basis->coordinates];fromCoordinates=Reverse/@coordinateRules;
 positive=And@@((FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[total,#]]]/.kin)>0&/@particles);
 assumptions=(request["Assumptions"]&&positive&&
   Lookup[request,"MeasurementAssumptions",True])/.coordinateRules;
 assumptions=assumptions&&Element[Join[coordinates,Lookup[measurements,"Variable"]],Reals];
 unitRules=FeynFacet`UnitCutScalarProductRules[base];
 If[!ListQ[unitRules],cutFamilyFail["ParticleUnitCutCoordinatesRequired",<|"Cause"->unitRules|>]];
 props=top[[2]];cuts=base["Cuts"];
 Do[
  z=measurement["Variable"];
  If[!MatchQ[z,_Symbol]||!FreeQ[measurement["Observable"],z],cutFamilyFail["IndependentMeasuredVariableRequired"]];
  observable=FeynCalc`ExpandScalarProduct[FeynCalc`FCI[measurement["Observable"]/.routing]]/.kin;
  unitObservable=Cancel[Together[observable/.unitRules]];
  row=If[FreeQ[unitObservable,Alternatives@@top[[3]]],unitObservable,observable];
  compiled=FeynFacet`CompileMeasurement[<|"Observable"->(row/.coordinateRules),"Value"->z,
    "IntegrationVariables"->coordinates,"Assumptions"->assumptions|>];
  If[!AssociationQ[compiled],cutFamilyFail["PolynomialMeasurementCompilationFailed",<|"Cause"->compiled|>]];
  compiled=Join[KeyDrop[compiled,"IntegrationVariables"]/.fromCoordinates,
    <|"Variable"->z,"SourceObservable"->observable,"UnitCutObservable"->unitObservable|>];
  If[compiled["Kind"]==="Contact",
    AppendTo[contacts,compiled],
    index=Length[props]+1;
    AppendTo[props,FeynCalc`FeynAmpDenominator[FeynCalc`GenericPropagatorDenominator[compiled["CutPolynomial"],{1,1}]]];
    AppendTo[cuts,<|"Index"->index,"Type"->"Measurement"|>];
    AppendTo[records,Join[compiled,<|"CutIndex"->index|>]];
    numerator*=compiled["Jacobian"]],
 {measurement,measurements}];
 definition=FeynFacet`CreateCutIntegralDefinition[Join[base,<|"Topology"->ReplacePart[top,2->props],"Cuts"->cuts|>]];
 If[!AssociationQ[definition],cutFamilyFail["PolynomialMeasuredPhaseSpaceDefinitionFailed",<|"Cause"->definition|>]];
 Join[definition,<|"MeasurementDefinitions"->records,"ContactMeasurements"->contacts,
   "MeasurementNumerator"->Expand[numerator],"MeasurementVariables"->Lookup[measurements,"Variable"],
   "MeasurementConvention"->"Product delta(variable-observable); all final-state momenta integrated. Unit-cut Jacobians multiply the numerator once; contacts have no cut slot.",
   "ExternalKinematicConditions"->Lookup[request,"ExternalKinematicConditions",request["Assumptions"]]|>]
],"CutFamily"];

CreateFinalStateMeasurementDefinitions[phaseSpace_Association,specification_Association]:=Catch[Module[
 {terms,rows={},groups,definition,key,weight},
 terms=FeynFacet`FinalStateMeasurementTerms[specification,phaseSpace["FinalMomenta"]];
 If[!ListQ[terms],cutFamilyFail["FinalStateMeasurementTermsRequired",<|"Cause"->terms|>]];
 Do[
  definition=FeynFacet`CreateMasslessPhaseSpaceDefinition[Join[phaseSpace,<|
    "Measurements"->{KeyTake[term,{"Variable","Observable"}]}|>]];
  If[!AssociationQ[definition],cutFamilyFail["FinalStateMeasurementDefinitionFailed",<|"Cause"->definition|>]];
  key=Join[KeyTake[#, {"Variable","CutPolynomial","Jacobian"}]&/@definition["MeasurementDefinitions"],
    KeyTake[#, {"Variable","Observable"}]&/@definition["ContactMeasurements"]];
  weight=FeynCalc`ExpandScalarProduct[FeynCalc`FCI[term["Weight"]/.definition["MomentumConservationRules"]]]/.
    definition["Topology"][[5]];
  AppendTo[rows,<|"ConstraintKey"->key,"Definition"->definition,"Weight"->weight,
    "ParticleIndices"->term["ParticleIndices"]|>],{term,terms}];
 groups=GatherBy[rows,#["ConstraintKey"]&];
 Map[<|"Definition"->First[#]["Definition"],"Weight"->Total[Lookup[#,"Weight"]],
   "ParticleTuples"->Lookup[#,"ParticleIndices"],"TupleConvention"->specification["Tuples"]|>&,groups]
],"CutFamily"];

CreateCutIntegralDefinition[request_Association]:=createCutIntegralData[request,False];
CreateCutIntegralFamily[request_Association]:=createCutIntegralData[request,True];
CreateLoopIntegralFamily[request_Association]:=createCutIntegralData[
 Join[request,<|"Cuts"->{},"IntegrationType"->"Virtual"|>],True];
createCutIntegralData[request_Association,complete_]:=Catch[Module[
 {top,cuts,indices,particle,measurement,descriptors,cores,loops,external,kin,conditions,reference,
  prefactor,basis,variables,replace,polynomials,matrix,constant,denominators,inverse,idx,expected,energy,
   degrees,affine,selected={},rank=0,trial,dependent,relations},
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
   If[!MemberQ[{"LinearLorentzian","PolynomialLorentzian"},descriptors[[idx,"Type"]]]||
      KeyExistsQ[cut,"EnergyDirection"]||KeyExistsQ[cut,"Momentum"]||
      Lookup[cut,"PositiveEnergyCondition",None]=!=None,
    cutFamilyFail["PolynomialMeasurementCutWithoutEnergyConditionRequired"]];
   cuts=Replace[cuts,cut->Join[cut,<|"PositiveEnergyCondition"->None|>],{1}]
  ],{cut,cuts}];
 basis=Join[Flatten[Table[FeynCalc`FCI[FeynCalc`SPD[loops[[i]],loops[[j]]]],
   {i,Length[loops]},{j,i,Length[loops]}]],
  Flatten[Table[FeynCalc`FCI[FeynCalc`SPD[ell,ext]],{ell,loops},{ext,external}]]];
 variables=Table[Unique["loopScalarProduct$"],{Length[basis]}];replace=Thread[basis->variables];
 polynomials=Expand[cores/.replace];
 If[!AllTrue[polynomials,PolynomialQ[#,variables]&]||
   !FreeQ[polynomials,_FeynCalc`Pair|_FeynCalc`Momentum],
   cutFamilyFail["PolynomialScalarProductDenominatorsRequired"]];
 degrees=Map[If[#===0,0,Max[Total/@(First/@CoefficientRules[#,variables])]]&,polynomials];
 If[AnyTrue[degrees,#>2&]||AnyTrue[Complement[Range[Length[cores]],Lookup[measurement,"Index",{}]],degrees[[#]]>1&],
   cutFamilyFail["AffineOrdinaryAndAtMostQuadraticMeasurementDenominatorsRequired"]];
 affine=Flatten[Position[degrees,n_Integer/;n<=1]];
 matrix=Table[Coefficient[polynomials[[i]],var],{i,affine},{var,variables}];
 Do[trial=Append[selected,j];
   If[MatrixRank[matrix[[trial]]]>rank,selected=trial;rank++];
   If[rank===Length[variables],Break[]],{j,Length[affine]}];
 selected=affine[[selected]];
 If[TrueQ[complete]&&rank=!=Length[variables],
   cutFamilyFail["IndependentCompleteAffineScalarProductBasisRequired"]];
 denominators=Table[Unique["inversePropagator$"],{Length[cores]}];
 constant=polynomials/.Thread[variables->0];
 inverse=If[TrueQ[complete],Factor/@LinearSolve[
   Table[Coefficient[polynomials[[i]],var],{i,selected},{var,variables}],
   denominators[[selected]]-constant[[selected]]],Missing["IndependentBasisRequired"]];
 dependent=Complement[Range[Length[cores]],selected];
 relations=If[TrueQ[complete],Association@Table[i->Expand[
   (polynomials[[i]]/.Thread[variables->inverse])-denominators[[i]]],{i,dependent}],<||>];
 Join[request,<|"Format"->If[cuts==={},"FeynFacet-LoopIntegralFamily",If[TrueQ[complete],"FeynFacet-CutIntegralFamily","FeynFacet-CutIntegralDefinition"]],"FormatVersion"->1,
  "Cuts"->cuts,"MeasurePrefactor"->prefactor,"CutIndices"->indices,"ParticleCutIndices"->Lookup[particle,"Index",{}],
  "MeasurementCutIndices"->Lookup[measurement,"Index",{}],"InversePropagators"->cores,
  "LoopScalarProducts"->basis,"DenominatorVariables"->denominators,
   "AffineBasisIndices"->selected,"DenominatorDegrees"->degrees,
   "DependentDenominatorRelations"->relations,
  "ScalarProductRules"->If[TrueQ[complete],Thread[basis->inverse],Missing["IndependentBasisRequired"]],
  "OrdinaryPropagatorPrescriptions"->Table[
    If[MemberQ[indices,i],None,
     FirstCase[FeynCalc`FCI[top[[2,i]]],
      (FeynCalc`StandardPropagatorDenominator|FeynCalc`GenericPropagatorDenominator)[___,{_,sign_}]:>sign,1,Infinity]],
    {i,Length[cores]}],
  "Definition"->If[cuts==={},
    "Dimensionally and analytically continued virtual loop integral with declared ordinary causal prescriptions.",
    "Joint meromorphic dimensional/analytic continuation of forward-energy cut integrals; the continued distribution fixes the massless-tip extension."],
  "AdditionalAcceptanceBoundaries"->None,
  "DerivativeScope"->"Interior physical chamber and finite derivative closure; external endpoint distributions are expanded afterward, not discarded.",
  "CutConvention"->"(-1)^(n-1) delta^(n-1)(G)/(n-1)!; particle cuts additionally restrict positive energy",
  "OrdinaryPrescriptionLimitEstablished"->False|>]
],"CutFamily"];
(* Polynomial multiplication is common to momentum IBPs, parameter
   derivatives and defining relations. Cut pinches vanish after every shift. *)
cutIntegralPolynomialTerms[family_,powers_List,polynomial_]:=Module[
 {variables=family["DenominatorVariables"],expanded,rules,terms,cuts=family["CutIndices"]},
 expanded=Expand[polynomial/.family["ScalarProductRules"]];
 If[!PolynomialQ[expanded,variables]||!FreeQ[expanded,_FeynCalc`Pair|_FeynCalc`Momentum],
   cutFamilyFail["PolynomialIntegralNumeratorRequired",<|"Polynomial"->expanded|>]];
 rules=CoefficientRules[expanded,variables];
 terms=Map[Function[term,With[{shifted=powers-First[term]},
   If[Last[term]===0||!AllTrue[shifted[[cuts]],#>0&],Nothing,
     FeynCalc`GLI[family["Topology"][[1]],shifted]->Last[term]]]],rules];
 Select[Map[Factor,GroupBy[terms,First->Last,Total]],#=!=0&]
];
FeynFacet`MultiplyCutIntegral::usage="MultiplyCutIntegral[family,integral,polynomial] inserts a polynomial in scalar products into the typed integral, retaining unrestricted particle/measurement definitions and discarding only mandatory cut pinches.";
FeynFacet`MultiplyCutIntegral[family_Association,integral_FeynCalc`GLI,polynomial_]:=Catch[Module[{terms},
 If[!MemberQ[{"FeynFacet-CutIntegralFamily","FeynFacet-LoopIntegralFamily"},Lookup[family,"Format",None]]||
   integral[[1]]=!=family["Topology"][[1]]||Length[integral[[2]]]=!=Length[family["Topology"][[2]]]||
   !VectorQ[integral[[2]],IntegerQ],cutFamilyFail["MatchingTypedIntegralRequired"]];
 If[AnyTrue[integral[[2,family["CutIndices"]]],#<=0&],Return[0]];
 terms=cutIntegralPolynomialTerms[family,integral[[2]],polynomial];
 Total[KeyValueMap[Times,terms]]
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
    Sum[D[corePolynomial,coordinates[[j]]]scalarDerivatives[[j]],{j,Length[basis]}])/.Thread[coordinates->basis];
  polynomial=Expand[totalDerivative/.family["ScalarProductRules"]];
  If[polynomial===0,Continue[]];
  raised=ReplacePart[indices,idx->indices[[idx]]+1];
  result-=indices[[idx]]Total[KeyValueMap[Times,cutIntegralPolynomialTerms[family,raised,polynomial]]],
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
