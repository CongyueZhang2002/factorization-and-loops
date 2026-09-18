(* Loop-first evaluation of scalar insertions in labeled three-particle phase
   space. Unit particle cuts are required; dotted virtual lines are allowed. *)
BeginPackage["FeynFacet`"];
IntegrateSimplexLaurentMonomials::usage="IntegrateSimplexLaurentMonomials[rational,variables,parameters] integrates a rational Laurent-monomial combination with the unnormalized Dirichlet density Product[x_i^(parameters_i-1)] delta(1-Total[variables]). Affine denominator factors are reduced on that simplex; non-monomial denominators fail. The Gamma expression is the meromorphic continuation from convergent moments, not a prescription-removal certificate.";
EvaluateOneLoopPhaseSpaceBubble::usage="EvaluateOneLoopPhaseSpaceBubble[family,integral,epsilon] evaluates a recognized causal one-loop bubble insertion on unit massless three-particle cuts. Full-D tensor reduction precedes exact affine-epsilon Dirichlet moments; the family measure is converted once to standard phase space and the raw virtual-loop measure. Nonbubble functions, non-monomial outer kernels and dotted particle cuts return Failure. No measured hard coefficient enters.";
EvaluateOneLoopPhaseSpaceBox::usage="EvaluateOneLoopPhaseSpaceBox[family,integral,epsilon,{low,high}] identifies a unit-power one-mass box with an inverse complementary pair invariant, integrated over labeled massless three-body phase space, by exact prescribed momentum maps. It supplies the independently derived universal scalar Laurent expansion through its finite term, converting the declared measure once. Orders not covered after normalization return Failure; no measured hard function is supplied.";
Begin["`Private`"];
IntegrateSimplexLaurentMonomials[expression_,variables:{__Symbol},parameters_List]:=Catch[Module[
 {value,canonical,den,powers,rows,orders},
 If[Length[variables]=!=Length[parameters]||!DuplicateFreeQ[variables]||
   !FreeQ[parameters,Alternatives@@variables],cutFamilyFail["IndependentDirichletParametersRequired"]];
 value=Cancel[Together[expression]];
 If[value===0,Return[<|"Value"->0,"MonomialPowers"->{}|>,Module]];
 canonical[f_]:=If[!FreeQ[f,Alternatives@@variables]&&PolynomialQ[f,variables]&&
   AllTrue[First/@CoefficientRules[f,variables],Total[#]<=1&],
   Expand[Sum[(f/.Thread[variables->UnitVector[Length[variables],j]])variables[[j]],{j,Length[variables]}]],f];
 den=Times@@((canonical[First[#]]^Last[#])&/@FactorList[Denominator[value]]);
 value=Cancel[Numerator[value]/den];den=Denominator[value];
 powers=Exponent[den,#]&/@variables;
 If[!VectorQ[powers,IntegerQ]||!FreeQ[Cancel[den/Times@@MapThread[Power,{variables,powers}]],Alternatives@@variables],
  cutFamilyFail["SimplexLaurentMonomialDenominatorsRequired"]];
 value=Cancel[value Times@@MapThread[Power,{variables,powers}]];
 If[!PolynomialQ[value,variables],cutFamilyFail["PolynomialSimplexNumeratorRequired"]];
 rows=CoefficientRules[value,variables];orders=(First[#]-powers)&/@rows;
 <|"Value"->Total[MapThread[Last[#1]Times@@(Gamma/@(parameters+#2))/Gamma[Total[parameters+#2]]&,{rows,orders}]],
   "MonomialPowers"->orders,"DirichletParameters"->parameters,
   "Definition"->"Unnormalized simplex moments on their convergence domain, uniquely continued meromorphically in the exponents."|>
],"CutFamily"];

EvaluateOneLoopPhaseSpaceBubble[input_Association,integral_FeynCalc`GLI,e_Symbol]:=Catch[Module[
 {family,top,particles,total,scale,loops,ell,powers,cuts,ordinary,virtual,descriptors,
  expression,variables={Unique["pairFraction"],Unique["pairFraction"],Unique["pairFraction"]},
  rules,kin,conditions,reduced,value,objects,aliases,rows,result=0,parameter,argument,
  moment,coefficient,bubble,normalization,terms,coordinate,seconds},
 family=FeynFacet`CreateCutIntegralFamily[input];
 If[!AssociationQ[family],cutFamilyFail["TypedCutLoopFamilyRequired"]];
 top=family["Topology"];particles=Lookup[family,"FinalMomenta",{}];total=family["TimeDirection"];
 powers=integral[[2]];cuts=family["CutIndices"];
 If[integral[[1]]=!=top[[1]]||Length[powers]=!=Length[top[[2]]]||!VectorQ[powers,IntegerQ]||
   Length[particles]=!=3||family["MeasurementCutIndices"]=!={}||Length[cuts]=!=3||
   powers[[cuts]]=!={1,1,1}||top[[4]]=!={total}||
   !AllTrue[family["Cuts"],#["Type"]==="Particle"&&#["MassSquared"]===0&&#["EnergyDirection"]===1&],
  cutFamilyFail["UnitMasslessThreeParticleCutsRequired"]];
 loops=Complement[top[[3]],Most[particles]];
 If[Length[loops]=!=1,cutFamilyFail["OneVirtualLoopOutsideParticleCutDirectionsRequired"]];ell=First[loops];
 If[!FreeQ[family["MeasurePrefactor"],Alternatives@@top[[3]]],cutFamilyFail["ExternalMixedIntegralNormalizationRequired"]];
 scale=FeynCalc`FCI[FeynCalc`SPD[total]]/.top[[5]];
 If[!TrueQ[FullSimplify[scale>0,Assumptions->family["Assumptions"]]],cutFamilyFail["PositiveTimelikeInvariantRequired"]];
 ordinary=Complement[Range[Length[powers]],cuts];
 virtual=Select[ordinary,powers[[#]]>0&&!FreeQ[top[[2,#]],ell]&];
 descriptors=propagatorDescriptor[#]&/@top[[2,virtual]];
 If[Length[virtual]<=1&&AllTrue[descriptors,AssociationQ[#]&&#["Type"]==="QuadraticLorentzian"&&
    Factor[(FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[#["Momentum"]]]]-#["UnitCore"])/.top[[5]]]===0&],
  Return[<|"MasterIntegral"->integral,"AnalyticExpression"->0,"DimensionalRegulator"->e,
   "ExactInRegulator"->True,"EvaluationMethod"->"ScalelessVirtualSubloop","UnitParticleCuts"->True|>,Module]];
 If[Length[virtual]=!=2||!AllTrue[descriptors,AssociationQ[#]&&#["Type"]==="QuadraticLorentzian"&]||
   family["OrdinaryPropagatorPrescriptions"][[virtual]]=!={1,1},
  cutFamilyFail["PositiveCausalQuadraticBubbleRequired"]];
 expression=Times@@Table[Which[powers[[i]]>0,top[[2,i]]^powers[[i]],powers[[i]]<0,
   family["InversePropagators"][[i]]^-powers[[i]],True,1],{i,ordinary}];
 rules=invariantParticleRules[particles,total,scale,
   scale{variables[[1]],variables[[2]],1-variables[[1]]-variables[[2]]}];
 conditions=scale>0&&variables[[1]]>0&&variables[[2]]>0&&variables[[1]]+variables[[2]]<1;
 kin=<|"ExternalMomenta"->particles,"MomentumRules"->{total->Total[particles]},
   "KinematicRules"->rules,"Assumptions"->conditions,"DimensionalRegulator"->e|>;
 {seconds,reduced}=AbsoluteTiming[FeynFacet`ReduceOneLoopIntegrands[<|"Scalar"->expression|>,kin,<|"LoopMomentum"->ell|>]];
 If[!AssociationQ[reduced],cutFamilyFail["PhysicalBubbleTensorReductionRequired",<|"Cause"->reduced|>]];
 value=Factor[reduced["InteriorValues"]["Scalar"]/.D->4-2e];
 If[!FreeQ[value,_FeynCalc`C0|_FeynCalc`D0|_FeynCalc`PaVe|_FeynCalc`GenPaVe],
  cutFamilyFail["ScalarBubbleCombinationRequired"]];
 objects=DeleteDuplicates[Cases[value,_FeynCalc`B0,{0,Infinity}]];aliases=Unique["bubbleScalar"]&/@objects;
 rows=FeynFacet`PolynomialCoefficientRules[value/.Thread[objects->aliases],aliases];
 If[!ListQ[rows]||!AllTrue[First/@rows,Total[#]<=1&],cutFamilyFail["LinearScalarBubblesRequired"]];
 bubble=FeynFacet`EvaluateOneLoopScalarFunctions[FeynCalc`B0[1,0,0],e,True];
 If[FailureQ[bubble],Throw[bubble,"CutFamily"]];
 Do[
  parameter=ConstantArray[1-e,3];coefficient=Last[row];
  If[Total[First[row]]===1,
   coordinate=First@FirstPosition[First[row],1];argument=objects[[coordinate]];
   If[!MatchQ[argument,FeynCalc`B0[_,0,0]],cutFamilyFail["MasslessScalarBubbleRequired"]];
   argument=Factor[argument[[1]]/scale];
   coordinate=SelectFirst[Range[3],Factor[argument-({variables[[1]],variables[[2]],
     1-variables[[1]]-variables[[2]]}[[#]])]===0&,None];
   If[coordinate===None&&argument=!=1,cutFamilyFail["PairInvariantOrTotalInvariantBubbleRequired",<|"Argument"->argument|>]];
   If[coordinate=!=None,parameter[[coordinate]]-=e]];
  (* Gamma/phase constants are outside the rational simplex parser. *)
  terms=coefficient;
  moment=FeynFacet`IntegrateSimplexLaurentMonomials[terms,variables,parameter];
  If[!AssociationQ[moment],Throw[moment,"CutFamily"]];
  result+=moment["Value"]If[Total[First[row]]===1,bubble scale^-e,1],{row,rows}];
 normalization=(family["MeasurePrefactor"]/(2Pi)^(3-2D))/.D->4-2e;
 If[!FreeQ[normalization,Alternatives@@top[[3]]],cutFamilyFail["ExternalMixedIntegralNormalizationRequired"]];
 result=normalization(4Pi)^(2e)scale^(1-2e)/(128Pi^3 Gamma[2-2e])*result;
 <|"MasterIntegral"->integral,"AnalyticExpression"->result,"DimensionalRegulator"->e,
   "ExactInRegulator"->True,"EvaluationMethod"->"CausalBubbleTensorReductionAndDirichletMoments",
   "TensorReductionSeconds"->seconds,"UnitParticleCuts"->True,
   "Normalization"->"Declared mixed-family measure; full-D raw virtual integration followed by labeled Lorentz-invariant phase space. The PaVe conversion is internal to evaluating the tensor-reduced bubble exactly once."|>
],"CutFamily"];
EvaluateOneLoopPhaseSpaceBox[input_Association,integral_FeynCalc`GLI,e_Symbol,range:{low_Integer,high_Integer}]:=Catch[Module[
 {family,top,particles,total,scale,loops,ell,powers,ordinary,virtual,external,
  phase,prop,source,reference,refFamily,refMaster,mapping,match,normalization,
  factor,lower,series,coefficients,referenceName},
 family=FeynFacet`CreateCutIntegralFamily[input];
 If[!AssociationQ[family],cutFamilyFail["TypedCutLoopFamilyRequired"]];
 top=family["Topology"];particles=Lookup[family,"FinalMomenta",{}];total=family["TimeDirection"];powers=integral[[2]];
 If[low>high||integral[[1]]=!=top[[1]]||Length[powers]=!=Length[top[[2]]]||
   !VectorQ[powers,MemberQ[{0,1},#]&]||Length[particles]=!=3||top[[4]]=!={total}||
   family["MeasurementCutIndices"]=!={}||Length[family["ParticleCutIndices"]]=!=3||
   powers[[family["CutIndices"]]]=!={1,1,1}||
   !AllTrue[family["Cuts"],#["Type"]==="Particle"&&#["MassSquared"]===0&&#["EnergyDirection"]===1&],
  cutFamilyFail["UnitThreeParticleInclusiveBoxRequired"]];
 loops=Complement[top[[3]],Most[particles]];
 If[Length[loops]=!=1,cutFamilyFail["OneVirtualLoopOutsideParticleCutDirectionsRequired"]];ell=First[loops];
 ordinary=Select[Complement[Range[Length[powers]],family["CutIndices"]],powers[[#]]>0&];
 virtual=Select[ordinary,!FreeQ[top[[2,#]],ell]&];external=Complement[ordinary,virtual];
 If[Length[virtual]=!=4||Length[external]=!=1||family["OrdinaryPropagatorPrescriptions"][[ordinary]]=!=ConstantArray[1,5],
  cutFamilyFail["CausalBoxAndOneExternalPairDenominatorRequired"]];
 scale=FeynCalc`FCI[FeynCalc`SPD[total]]/.top[[5]];
 If[!TrueQ[FullSimplify[scale>0,Assumptions->family["Assumptions"]]],cutFamilyFail["PositiveTimelikeInvariantRequired"]];
 phase=FeynFacet`CreateMasslessPhaseSpaceDefinition[<|"FinalMomenta"->particles,"TotalMomentum"->total,
   "ExternalMomenta"->top[[4]],"KinematicRules"->top[[5]],"Assumptions"->family["Assumptions"]|>];
 If[!AssociationQ[phase],cutFamilyFail["InclusiveBoxPhaseSpaceDefinitionRequired"]];
 prop[p_]:=FeynCalc`FCI[FeynCalc`SFAD[p]];
 source=Times@@(prop/@{ell,ell-particles[[1]],ell-particles[[1]]-particles[[3]],ell-total,particles[[1]]+particles[[2]]});
 referenceName="InclusiveOneMassBoxReference";
 If[cutEquivalenceFamilyName[top[[1]]]===referenceName<>"1",referenceName=referenceName<>"Alternate"];
 reference=FeynFacet`DecomposeCutLoopIntegrands[<|"Scalar"->source|>,phase,{ell},
  <|"FamilyNamePrefix"->referenceName,"VirtualLoopMeasurePrefactor"->Cancel[family["MeasurePrefactor"]/phase["MeasurePrefactor"]]|>];
 If[!AssociationQ[reference],cutFamilyFail["UniversalInclusiveBoxReferenceRequired"]];
 refFamily=First[reference["Families"]];refMaster=First[reference["Targets"]];
 mapping=FeynFacet`FindCutIntegralEquivalences[{integral,refMaster},{family,refFamily},
   "Normalization"->"DeclaredTypedCutMeasures","PreferredMasterIntegrals"->{refMaster}];
 If[!AssociationQ[mapping]||mapping["EquivalenceClassCount"]=!=1,
  cutFamilyFail["UniversalInclusiveBoxMomentumMapNotEstablished"]];
 match=SelectFirst[mapping["Mappings"],#["Source"]===integral&];
 normalization=((family["MeasurePrefactor"]/phase["MeasurePrefactor"])/.D->4-2e) I Pi^(2-e);
 If[!FreeQ[normalization,Alternatives@@top[[3]]],cutFamilyFail["ExternalMixedIntegralNormalizationRequired"]];
 (* This is the universal scalar U8 from its own Euler/Mellin-Barnes
    derivation, not a measured coefficient. See Design/InclusiveOneLoopScalars.md. *)
 factor=normalization (4Pi)^(2e)scale^(-2-3e)Exp[I Pi e]/(128Pi^3 Gamma[1-e]Gamma[2-2e]);
 lower=FeynFacet`DetermineMeromorphicLaurentLowerBound[factor,e];
 If[!IntegerQ[lower]||high-lower>0,cutFamilyFail["UniversalInclusiveBoxOrderNotAvailable",
   <|"RequestedUpperOrder"->high,"NormalizationLowerBound"->lower,"UniversalKnownThroughOrder"->0|>]];
 epsilonAuditMultiplier[factor,e,-4,0,high,"InclusiveUniversalScalarBox",integral];
 series=Normal[Series[factor(5/(2e^4)-13Pi^2/(4e^2)-89Zeta[3]/e-1297Pi^4/720),{e,0,high}]];
 If[!FreeQ[series,_Series|_SeriesData|_SeriesCoefficient|Indeterminate|_DirectedInfinity],
  cutFamilyFail["ExplicitInclusiveBoxCoefficientsRequired"]];
 coefficients=Association@Table[j->Coefficient[Expand[e^(4-lower)series],e,j+4-lower],{j,Min[low,lower-4],high}];
 <|"MasterIntegral"->integral,"DimensionalRegulator"->e,"Coefficients"->coefficients,
   "LaurentLowerBound"->Min[low,lower-4],"KnownThroughOrder"->high,"ExactInEpsilon"->False,
   "ReferenceMomentumMap"->match,"ReferenceIntegral"->refMaster,
   "EvaluationMethod"->"UniversalInclusiveOneMassBoxEulerIntegral",
   "UniversalScalarInput"->"Unit positive-energy three-particle cuts, chords (0,p1,p1+p3,q), extra 1/s12, and d^D ell/(i pi^(D/2)); converted to the declared family measure once. Independently derived scalar coefficients through epsilon^0."|>
],"CutFamily"];
End[];EndPackage[];
