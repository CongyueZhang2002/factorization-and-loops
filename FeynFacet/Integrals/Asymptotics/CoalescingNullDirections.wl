
(* Whole-domain leading coefficient when future-null external directions
   coalesce in the recoil rest frame. Geometry-specific hypotheses live here,
   separately from permanent Euler integration and DE matching code. *)
Begin["FeynFacet`Private`"];
FeynFacet`ConstructCoalescingNullBoundaryIntegral::usage="ConstructCoalescingNullBoundaryIntegral[definition,boundary] constructs the whole-domain leading recoil coefficient for massless three-particle cuts with unit powers or one doubled cut, recognized external-subset factors, and at most two distinct pair invariants. Unsupported geometries remain unresolved.";
FeynFacet`ConstructCoalescingNullBoundaryIntegral[definition_Association,boundary_Association] := Catch[Module[
 {z=Lookup[boundary,"NormalVariable",None],edge=Lookup[boundary,"BoundaryKinematicRules",{}],
  eps=definition["DimensionalRegulator"],dim=definition["Dimension"],
  cuts=definition["CutIndices"],cm=definition["OrientedCutMomenta"],loops=definition["LoopMomenta"],
  powers=definition["PropagatorPowers"],kin=definition["KinematicRules"],
  external=definition["ExternalMomenta"],dot,dotEdge,total,routing,minor,det,
  active,descriptors={},momentum,found,subset,part,signs,prefactor=1,normalPower=0,
  inversePower=0,fractions,alpha,c2,t,u,density,scale,pair,constant,measure,extra,order,j,
  spatialGram,minorValue,nd,np,dp,leadingSign,singlePowers=ConstantArray[0,3],
  complementPowers=ConstantArray[0,3],externalFactor=1,permutation,nonzero,otherIndices,
  betaValue,terms,eulerTerms,structuredTerms,pairPowers=<||>,pairSet,pairPower=0,
  pairMoment=1,spectator=None,jointPairs=False,pairPowerList,common,pairOthers,
  permutations,jointVariables,jointKey=None,linear,linearRatio},
 If[Sort[powers[[cuts]]] === {1,1,2},
   Return[FeynFacet`ConstructCoalescingNullMassDerivative[definition,boundary]]];
 If[!MatchQ[z,_Symbol]||Length[loops]=!=2||Length[cm]=!=3||
   definition["VirtualLoopCount"]=!=0||!AllTrue[powers[[cuts]],#===1&],
   boundaryIntegrationFail["MasslessThreeParticleUnitCutsRequired"]];
 dot[a_,b_]:=Cancel[FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[a,b]]]/.kin];
 dotEdge[a_,b_]:=Cancel[FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[a,b]]]/.edge];
 total=Expand[Total[cm]];
 If[!FreeQ[total,Alternatives@@loops]||!TrueQ[Cancel[dot[total,total]-z]===0],
   boundaryIntegrationFail["RecoilInvariantMustBeTheNormalVariable"]];
 If[!AllTrue[Range[3],TrueQ[Cancel[dot[cm[[#]],cm[[#]]]-definition["InversePropagators"][[cuts[[#]]]]]===0]&],
   boundaryIntegrationFail["MasslessCutDefinitionRequired"]];
 If[!AllTrue[external,TrueQ[dot[#,#]===0]&&TrueQ[dotEdge[#,total]>0]&],
   boundaryIntegrationFail["FutureNullExternalDirectionsRequired"]];
 If[!AllTrue[Flatten[Table[dotEdge[a,b],{a,external},{b,external}]],NumberQ[#]&&TrueQ[#>=0]&],
   boundaryIntegrationFail["FiniteFixedTangentialKinematicsRequired"]];
 spatialGram=Table[Cancel[Together[dot[a,total]dot[b,total]/z-dot[a,b]]],{a,external},{b,external}];
 Do[
  minorValue=Cancel[Together[Det[spatialGram[[set,set]]]]];If[minorValue===0,Continue[]];
  nd=NumeratorDenominator[minorValue];
  If[!AllTrue[nd,PolynomialQ[#,z]&],boundaryIntegrationFail["RationalPhysicalGramLimitRequired"]];
  np=Exponent[nd[[1]],z,Min];dp=Exponent[nd[[2]],z,Min];
  leadingSign=Coefficient[nd[[1]],z,np]/Coefficient[nd[[2]],z,dp];
  If[!TrueQ[leadingSign>0],boundaryIntegrationFail["PhysicalExternalGramSignatureNotEstablished"]],
 {set,Subsets[Range[Length[external]],{1,Length[external]}]}];
 routing=Table[Coefficient[m,l],{m,cm},{l,loops}];
 minor=SelectFirst[Subsets[Range[3],{2}],TrueQ[Det[routing[[#]]]=!=0]&,None];
 If[minor===None||!MatrixQ[routing,MatchQ[#,_Integer|_Rational]&],
   boundaryIntegrationFail["FullRankConstantCutRoutingRequired"]];
 det=Abs[Det[routing[[minor]]]];
 active=Select[Complement[Range[Length[powers]],cuts],powers[[#]]=!=0&];
 t=Unique["fraction"];u=Unique["fraction"];fractions={t,(1-t)u,(1-t)(1-u)};
 Do[
  linear=definition["PropagatorTypes"][[j]]==="LinearLorentzian";
  If[linear,
   found=None;
   Do[
    part=Expand[Total[cm[[set]]]];
    linearRatio=Cancel[Together[definition["InversePropagators"][[j]]/dot[p,part]]];
    If[NumberQ[linearRatio]&&linearRatio=!=0,
     found=<|"Subset"->set,"ExternalMomentum"->p,"Scale"->linearRatio dotEdge[p,total]|>;Break[]],
    {p,external},{set,Subsets[Range[3],{1,3}]}];
   If[found===None,boundaryIntegrationFail["RecognizedLinearExternalSubsetPropagatorRequired",<|"PropagatorIndex"->j|>]],
  If[definition["PropagatorTypes"][[j]]=!="QuadraticLorentzian",
    boundaryIntegrationFail["QuadraticExternalSubsetPropagatorsRequired",<|"PropagatorIndex"->j|>]];
  momentum=definition["PropagatorMomenta"][[j]];
  If[!TrueQ[Cancel[dot[momentum,momentum]-definition["InversePropagators"][[j]]]===0],
    boundaryIntegrationFail["MasslessOrdinaryPropagatorRequired",<|"PropagatorIndex"->j|>]];
  If[Expand[momentum-total]===0||Expand[momentum+total]===0,
    normalPower-=powers[[j]];
    AppendTo[descriptors,<|"PropagatorIndex"->j,"Type"->"RecoilInvariant","Power"->powers[[j]]|>];Continue[]];
  pairSet=SelectFirst[Subsets[Range[3],{2}],
    Expand[momentum-Total[cm[[#]]]]===0||Expand[momentum+Total[cm[[#]]]]===0&,None];
  If[pairSet=!=None,
    AssociateTo[pairPowers,pairSet->(Lookup[pairPowers,Key[pairSet],0]+powers[[j]])];
    normalPower-=powers[[j]];inversePower+=Max[0,powers[[j]]];
    AppendTo[descriptors,<|"PropagatorIndex"->j,"Type"->"FinalStatePairInvariant",
      "Subset"->pairSet,"Power"->powers[[j]]|>];Continue[]];
  found=None;
  Do[part=Expand[Total[cm[[set]]]];
   Do[If[Expand[momentum-sign[[1]]p-sign[[2]]part]===0,
      found=<|"Subset"->set,"ExternalMomentum"->p,
        "Scale"->2 (Times@@sign) dotEdge[p,total]|>;Break[]],
    {sign,Tuples[{1,-1},2]}];
   If[found=!=None,Break[]],
   {p,external},{set,Subsets[Range[3],{1,3}]}];
  If[found===None,boundaryIntegrationFail["BoundaryPropagatorRequiresAnotherRepresentation",<|"PropagatorIndex"->j|>]];
  ];
  scale=found["Scale"];externalFactor*=scale^-powers[[j]];
  Switch[Length[found["Subset"]],
    1,singlePowers[[First[found["Subset"]]]]+=powers[[j]],
    2,complementPowers[[First[Complement[Range[3],found["Subset"]]]]]+=powers[[j]]];
  inversePower+=Max[0,powers[[j]]];
  AppendTo[descriptors,Join[found,<|"PropagatorIndex"->j,"Type"->"ExternalSubsetInvariant","Power"->powers[[j]]|>]],
 {j,active}];
 alpha=(dim-2)/2;c2=Pi^((dim-1)/2)/(2^(dim-2)Gamma[(dim-1)/2]);
 pairPowers=Select[pairPowers,#=!=0&];
 If[Length[pairPowers]>2,boundaryIntegrationFail["ThreeDistinctFinalStatePairMomentsRequired"]];
 jointPairs=Length[pairPowers]===2;
 If[Length[pairPowers]===1,
   pairSet=First[Keys[pairPowers]];pairPower=First[Values[pairPowers]];
   spectator=First[Complement[Range[3],pairSet]];
   complementPowers[[spectator]]+=pairPower;
   (* At fixed invariant light-cone fractions, s_ij/z=(x_i+x_j) rho,
      where rho has the Beta(alpha,alpha) distribution. Integer moments
      are exact rational functions of alpha, including numerator powers. *)
   pairMoment=Cancel[FunctionExpand[Pochhammer[alpha,-pairPower]/Pochhammer[2alpha,-pairPower]]]];
 measure=definition["MeasurePrefactor"];extra=definition["MasterIntegralPrefactor"];
 If[!FreeQ[{measure,extra},z],boundaryIntegrationFail["NormalIndependentMeasurePrefactorRequired"]];
 constant=measure extra/det^dim c2^2 Gamma[2alpha]/Gamma[alpha]^2 pairMoment;
 If[jointPairs,
   common=First[Intersection@@Keys[pairPowers]];pairOthers=Complement[Range[3],{common}];
   permutations=({common,Sequence@@#}&/@Permutations[pairOthers]);
   permutation=First[SortBy[permutations,{
     singlePowers[[#]],complementPowers[[#]],
     {pairPowers[[Key[Sort[#[[{1,2}]]]]]],pairPowers[[Key[Sort[#[[{1,3}]]]]]]}}&]];
   pairPowerList={pairPowers[[Key[Sort[permutation[[{1,2}]]]]]],
     pairPowers[[Key[Sort[permutation[[{1,3}]]]]]]};
   singlePowers=singlePowers[[permutation]];complementPowers=complementPowers[[permutation]];
   jointVariables={t,u,Unique["pairFraction"]};
   terms=coalescingTwoPairEulerTerms[alpha,singlePowers,complementPowers,pairPowerList,
     constant externalFactor,jointVariables];
   eulerTerms=terms;
   betaValue=None;
   If[Join[singlePowers,complementPowers]===ConstantArray[0,6],
     betaValue=Gamma[alpha]Times@@(Gamma[alpha-#]&/@pairPowerList)/
       Gamma[3alpha-Total[pairPowerList]];
     terms={<|"IntegrationVariables"->{},"Prefactor"->constant externalFactor betaValue|>}];
   jointKey={"ThreeParticleTwoPairMoment",dim,Join[singlePowers,complementPowers],pairPowerList},
  permutation=First[SortBy[Permutations[Range[3]],
   {Count[complementPowers[[Rest[#]]],Except[0]],Flatten[{singlePowers[[#]],complementPowers[[#]]}]}&]];
 singlePowers=singlePowers[[permutation]];complementPowers=complementPowers[[permutation]];
 prefactor=externalFactor Times@@MapThread[#1^-#2&,{fractions,singlePowers}] *
   Times@@MapThread[(1-#1)^-#2&,{fractions,complementPowers}];
 density=t^(alpha-1)(1-t)^(2alpha-1)u^(alpha-1)(1-u)^(alpha-1);
 eulerTerms={<|"IntegrationVariables"->{t,u},"Prefactor"->constant,
   "RegularFactor"->density prefactor|>};
 nonzero=Flatten[Position[complementPowers,Except[0],{1},Heads->False]];
 betaValue=None;
 If[nonzero==={},
   betaValue=Times@@(Gamma[alpha-#]&/@singlePowers)/Gamma[3alpha-Total[singlePowers]],
  If[Length[nonzero]===1,j=First[nonzero];otherIndices=Complement[Range[3],{j}];
   betaValue=Times@@(Gamma[alpha-#]&/@singlePowers[[otherIndices]])/
      Gamma[2alpha-Total[singlePowers[[otherIndices]]]] *
     Gamma[alpha-singlePowers[[j]]] Gamma[2alpha-Total[singlePowers[[otherIndices]]]-complementPowers[[j]]]/
      Gamma[3alpha-Total[singlePowers]-complementPowers[[j]]]]];
 structuredTerms={<|"IntegrationVariables"->{t,u},"Prefactor"->constant externalFactor,
   "EndpointPowers"->{alpha-1-singlePowers[[1]],alpha-1-singlePowers[[2]]},
   "UpperEndpointPowers"->{2alpha-1-singlePowers[[2]]-singlePowers[[3]]-complementPowers[[1]],alpha-1-singlePowers[[3]]},
   "RegularFactor"->1,"PolynomialFactors"->{
    <|"Polynomial"->1-u+t u,"Exponent"->-complementPowers[[2]]|>,
    <|"Polynomial"->t+u-t u,"Exponent"->-complementPowers[[3]]|>}|>};
 terms=If[betaValue===None,structuredTerms,
   {<|"IntegrationVariables"->{},"Prefactor"->constant externalFactor betaValue|>}]
 ];
 <|"DataType"->"PhysicalBoundaryIntegral","Representation"->"UnitCube",
  "DimensionalRegulator"->eps,"Terms"->terms,"EulerTerms"->eulerTerms,
  "EulerFractionPowers"->Join[singlePowers,complementPowers],
  "IntegralEquivalenceKey"->If[jointPairs,jointKey,{"ThreeParticleDirichletMoment",dim,Join[singlePowers,complementPowers]}],
  "IntegralScaleFactor"->constant externalFactor,
  "FractionPermutation"->permutation,"ExternalScaleFactor"->externalFactor,
  "ElementaryDirichletIntegralEvaluated"->(betaValue=!=None),
  "OriginalIntegralDefinition"->definition,"NormalVariable"->z,
  "PhysicalLimitEstablished"->True,"PositiveInversePowerCount"->inversePower,
  "ConditionalPairMoment"->If[jointPairs,Missing["JointAngularIntegralRequired"],pairMoment],
  "FinalStatePairPowers"->pairPowers,"TwoPairConditionalRepresentation"->jointPairs,"FinalStatePairPower"->pairPower,
  "FinalStatePairSpectator"->spectator,
  "ConditionalPairDistribution"->"Before reweighting, rho=(s_ij/z)/(x_i+x_j) has Beta[(D-2)/2,(D-2)/2] distribution at fixed x.",
  "NormalExponent"->dim-3+normalPower,"LogarithmPower"->0,
  "VanishingLogarithmCoefficientsAtThisPower"->True,
  "BoundaryKinematicRules"->edge,"PropagatorLimits"->descriptors,
  "LightConeFractions"->fractions,"ReferenceNullMomentum"->First[external],
  "FractionDefinition"->"x_i=(P_reference dot k_i)/(P_reference dot Q); these are not rest-frame energy fractions.",
  "ExternalSpatialGramMatrix"->spatialGram,"PhysicalKinematicsForSmallPositiveNormalCoordinate"->True,"FractionDistribution"->"Dirichlet[(D-2)/2,(D-2)/2,(D-2)/2]",
  "LargeDimensionConvergenceDomain"->dim>4inversePower+2,
  "LimitJustification"->"Coalescence of future-null external directions, almost-everywhere convergence on fixed unit-mass phase space, and uniform L^2 bounds from positive inverse moments and Holder's inequality; meromorphic continuation of the resulting coefficient identity.",
  "Scope"->"Whole-domain coefficient at the displayed normal exponent. Other epsilon slopes and subleading normal powers are not determined.",
  "NormalizationChanged"->False|>
],"BoundaryIntegration"];
End[];
