(* Compact phase-space geometry and exact causal certificates for cut poles. *)
Begin["FeynFacet`Private`"];
Clear[cutOrderVector,cutOrderSquare,cutOrderGeometry,cutOrderCone,
 cutOrderCausalBranch,cutOrderQuadraticCertificate,cutOrderReduceExternal,
 cutOrderNormalDerivatives,cutOrderPoleBound,cutOrderBilinearCertificate,
 cutOrderSingularityCertificates];

cutOrderVector[q_,mom_] := Module[{v},
 v=Coefficient[Expand[q],#]& /@ mom;
 If[!epsOrderZero[q-v.mom] || !FreeQ[v,Alternatives@@mom],
  epsOrderFail["LinearMomentumRoutingRequired"]];v
];
cutOrderSquare[q_,kin_] := Cancel[
 FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[q]]]/.kin];

cutOrderGeometry[d_] := Module[
 {loops,ext,all,cuts,cm,l,nu,kin,rayVectors,rays,masses,energies,p,psq,
  route,independent,bases,coneBases,active,couplings,eff,fullspace,
  qvec,constant,signs,propMasses,propMom,positive,externalGram,spatialGram},
 loops=d["LoopMomenta"];ext=d["ExternalMomenta"];all=Join[loops,ext];
 cuts=d["CutIndices"];cm=d["OrientedCutMomenta"];l=Length[loops];nu=d["PropagatorPowers"];
 kin=d["KinematicRules"];p=Expand[Total[cm]];psq=cutOrderSquare[p,kin];
 If[d["VirtualLoopCount"]=!=0 || Length[cuts]=!=l+1 ||
   !FreeQ[p,Alternatives@@loops] || !TrueQ[psq>0],
   epsOrderFail["CompactConnectedPhaseSpaceRequired"]];
 route=Table[Coefficient[m,k],{m,cm},{k,loops}];
 independent=SelectFirst[Subsets[Range[l+1],{l}],!epsOrderZero[Det[route[[#]]]]&,None];
 If[independent===None,epsOrderFail["IndependentCutMomentumRoutingRequired"]];
 propMom=Lookup[d,"PropagatorMomenta",{}];
 If[Length[propMom]=!=Length[nu],epsOrderFail["PropagatorMomentumDataRequired"]];
 signs=ConstantArray[Missing["NotQuadratic"],Length[nu]];
 propMasses=signs;
 Do[
  If[!MatchQ[propMom[[j]],_Missing],
   qvec=cutOrderSquare[propMom[[j]],kin];
   Do[constant=Expand[qvec-sign d["InversePropagators"][[j]]];
    If[FreeQ[constant,Alternatives@@loops],
     signs[[j]]=sign;propMasses[[j]]=constant;Break[]],{sign,{1,-1}}]],
 {j,Length[nu]}];
 If[!AllTrue[propMasses[[cuts]],TrueQ[#>=0]&],
  epsOrderFail["NonnegativeCutMassesRequired"]];
 If[!TrueQ[psq>Total[Sqrt /@ propMasses[[cuts]]]^2],
  epsOrderFail["OrdinaryPhaseSpacePointAboveThresholdRequired"]];
 If[!TrueQ[(FeynCalc`ExpandScalarProduct[FeynCalc`FCI[
   FeynCalc`SPD[p,d["TimeDirection"]]]]/.kin)>0],
  epsOrderFail["FutureTotalPhaseSpaceMomentumRequired"]];
 (* All cut momenta are future causal on the physical domain. Keep precisely
    the external momenta whose future-causal character is established. *)
 positive=Select[ext,TrueQ[cutOrderSquare[#,kin]>=0] &&
   TrueQ[(FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[#,p]]]/.kin)>0]&];
 rays=Join[cm,positive];rayVectors=cutOrderVector[#,all]& /@ rays;
 masses=Join[propMasses[[cuts]],cutOrderSquare[#,kin]& /@ positive];
 bases=Select[Subsets[Range[Length[rays]],{Length[all]}],
   !epsOrderZero[Det[rayVectors[[#]]]]&];
 coneBases=<|"RayIndices"->#,"Inverse"->Inverse[rayVectors[[#]]]|>& /@ bases;
 active=Union[cuts,Select[Range[Length[nu]],nu[[#]]=!=0&]];
 couplings=Flatten[Table[
   Table[Coefficient[Expand[d["InversePropagators"][[j]]],
    FeynCalc`FCI[FeynCalc`SPD[k,ext[[a]]]]],{a,Length[ext]}],
 {j,active},{k,loops}],1];
 (* The fixed total momentum is also the time reference for compactness. *)
 couplings=Append[couplings,cutOrderVector[p,all][[l+Range[Length[ext]]]]];
 eff=DeleteCases[RowReduce[couplings],v_ /; AllTrue[v,epsOrderZero]];
 fullspace=Join[Take[IdentityMatrix[Length[all]],l],
   (Join[ConstantArray[0,l],#]& /@ eff)];
 externalGram=Table[FeynCalc`FCI[FeynCalc`SPD[a,b]]/.kin,{a,ext},{b,ext}];
 spatialGram=Outer[Times,(FeynCalc`ExpandScalarProduct[FeynCalc`FCI[
   FeynCalc`SPD[#,p]]]/.kin& /@ ext),
   (FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[#,p]]]/.kin& /@ ext)]/psq-externalGram;
 If[!TrueQ[Det[externalGram]!=0] || !And@@Flatten[Table[
   TrueQ[Det[spatialGram[[set,set]]]>=0],{size,Length[ext]},
   {set,Subsets[Range[Length[ext]],{size}]}]],
  epsOrderFail["PhysicalExternalGramSignatureRequired"]];
 If[!FreeQ[{externalGram,d["InversePropagators"],cm},d["DimensionalRegulator"]],
  epsOrderFail["RegulatorIndependentPhaseSpaceGeometryRequired"]];
 <|"LoopCount"->l,"Momenta"->all,"ExternalMomenta"->ext,
  "TotalMomentum"->p,"TotalMomentumSquared"->psq,
  "IndependentCutMomenta"->independent,"CutRoutingMatrix"->route,
  "CompactnessEstablished"->True,
  "CompactnessReason"->"Future on-shell cut energies sum to the fixed timelike total energy; independent cut momenta determine all loop momenta.",
  "Rays"->rays,"RayVectors"->rayVectors,"RayMassSquared"->masses,
  "FixedNullRays"->Select[Range[Length[cm]+1,Length[rays]],epsOrderZero[masses[[#]]]&],
  "NonnegativeCutMassDeformation"->True,
  "EventualHolomorphyArgument"->"On the compact physical domain with independently increased nonnegative cut masses, uniform semialgebraic domination at sufficiently large Re(D) permits all required mass derivatives, including differentiation of the moving Gram and energy boundaries. The resulting integrals are holomorphic in a complex-D half-plane.",
  "ConeBases"->coneBases,"PropagatorSigns"->signs,"PropagatorMassSquared"->propMasses,
  "ActivePropagatorIndices"->active,"EffectiveExternalBasis"->eff,
  "EffectiveExternalRank"->Length[eff],"IntegralMomentumSubspace"->fullspace,
  "ExternalGramMatrix"->externalGram|>
];

cutOrderCone[v_,g_] := Module[{out={},c,weights},
 Do[
  c=Map[Cancel,v.basis["Inverse"]];
  If[!AllTrue[c,TrueQ[#>=0]&],Continue[]];
  weights=ConstantArray[0,Length[g["Rays"]]];
  weights[[basis["RayIndices"]]]=c;
  AppendTo[out,weights],
 {basis,g["ConeBases"]}];
 DeleteDuplicates[out]
];
cutOrderCausalBranch[v_,weights_,g_] := Module[{ids,span,rank,intersection},
 ids=Select[Range[Length[weights]],!epsOrderZero[weights[[#]]]&];
 If[AnyTrue[g["RayMassSquared"][[ids]],TrueQ[#>0]&],
  Return[<|"Reason"->"A positive combination containing a future timelike vector cannot be null.",
   "RayCoefficients"->weights,"NullVectorExcluded"->True|>]];
 span=Join[{v},g["RayVectors"][[ids]]];
 rank=MatrixRank[span];
 intersection=rank+Length[g["IntegralMomentumSubspace"]]-
   MatrixRank[Join[span,g["IntegralMomentumSubspace"]]];
 If[intersection<2,Return[None]];
 <|"Reason"->"A null sum of future null vectors makes them collinear; at least two independent combinations belong to the integral momentum subspace, so its Gram determinant vanishes.",
  "RayCoefficients"->weights,"IntersectionDimension"->intersection,
  "NullVectorExcludedInGramInterior"->True|>
];
cutOrderQuadraticCertificate[q_,g_] := Module[{v,candidates,answer=None,branches={},signed,
 p,weights,proof,span,ids,rank,intersection},
 v=cutOrderVector[q,g["Momenta"]];
 If[AllTrue[v,epsOrderZero],Return[None]];
 Do[
  candidates=cutOrderCone[sgn v,g];
  Do[proof=cutOrderCausalBranch[sgn v,weights,g];
   If[AssociationQ[proof],answer=Join[proof,<|"Method"->"FutureCausalSum","Sign"->sgn|>];Break[]],
  {weights,candidates}];
  If[AssociationQ[answer],Break[]],
 {sgn,{1,-1}}];
 If[AssociationQ[answer],Return[answer]];
 (* Treat the future and past branches of a null q separately. A null q with
    zero energy is the zero vector and also forces the integral Gram to vanish. *)
 Do[
  answer=None;signed=sgn v;
  Do[
   If[!MemberQ[g["FixedNullRays"],j],Continue[]];
   p=g["RayVectors"][[j]];
   candidates=cutOrderCone[p-signed,g];
   Do[
    (* p = signed q + the listed future rays, with p future null. *)
    ids=Select[Range[Length[weights]],!epsOrderZero[weights[[#]]]&];
    If[AnyTrue[g["RayMassSquared"][[ids]],TrueQ[#>0]&],
     answer=<|"NullRay"->j,"RayCoefficients"->weights,
       "Reason"->"A future null vector cannot contain a future timelike summand."|>;Break[]];
    span=Join[{p,signed},g["RayVectors"][[ids]]];
    rank=MatrixRank[span];
    intersection=rank+Length[g["IntegralMomentumSubspace"]]-
      MatrixRank[Join[span,g["IntegralMomentumSubspace"]]];
    If[intersection>=2,
     answer=<|"NullRay"->j,"RayCoefficients"->weights,
      "IntersectionDimension"->intersection,
      "Reason"->"The null decomposition forces a linear dependence inside the integral momentum subspace."|>;
     Break[]],
   {weights,candidates}];
   If[AssociationQ[answer],Break[]],
  {j,Length[g["Rays"]]}];
  If[!AssociationQ[answer],Break[]];
  AppendTo[branches,Join[answer,<|"NullMomentumSign"->sgn|>]],
 {sgn,{1,-1}}];
 If[Length[branches]=!=2,Return[None]];
 <|"Method"->"BothEnergySigns","Branches"->branches,
  "ZeroEnergyBranch"->"A null vector orthogonal to a timelike vector is zero; its nonzero coefficient vector lies in the integral momentum subspace."|>
];

(* Express only the scalar products actually occurring in the master using an
   independent external basis. This removes unused angular directions exactly. *)
cutOrderReduceExternal[d_,g_] := Module[
 {r=d,loops=d["LoopMomenta"],old=d["ExternalMomenta"],eff=g["EffectiveExternalBasis"],
  ext,cols,all,active=g["ActivePropagatorIndices"],newCuts,rules,cores,momMap,
  coefficient,externalPart,representation,kin,gram,couplings,spAtoms,spVariables,newSP,
  oldG,loopG,polys,constant,vector,coeffs,masses,cutMom,propMom},
 ext=Table[Unique["externalBasisMomentum"],{Length[eff]}];
 all=Join[loops,old];
 (* Pivot columns make the coefficient reconstruction a small exact solve. *)
 cols=SelectFirst[Subsets[Range[Length[old]],{Length[eff]}],
  !epsOrderZero[Det[eff[[All,#]]]]&,None];
 If[cols===None,epsOrderFail["IndependentExternalMomentumBasisRequired"]];
 momMap[q_] := Module[{v,ec,c},
  v=cutOrderVector[q,all];ec=Drop[v,Length[loops]];
  c=ec[[cols]].Inverse[eff[[All,cols]]];
  If[!And@@(epsOrderZero /@ (ec-c.eff)),Return[Missing["OutsideIntegralMomentumSpan"]]];
  Take[v,Length[loops]].loops+c.ext
 ];
 oldG=g["ExternalGramMatrix"];gram=Map[Cancel,eff.oldG.Transpose[eff],{2}];
 kin=Flatten[Table[FeynCalc`FCI[FeynCalc`SPD[ext[[i]],ext[[j]]]]->gram[[i,j]],
  {i,Length[ext]},{j,i,Length[ext]}]];
 cores=Table[
  polys=Expand[d["InversePropagators"][[j]]];
  Do[
   vector=Table[Coefficient[polys,FeynCalc`FCI[FeynCalc`SPD[k,p]]],{p,old}];
   coeffs=vector[[cols]].Inverse[eff[[All,cols]]];
   If[!And@@(epsOrderZero /@ (vector-coeffs.eff)),
    epsOrderFail["ExternalMomentumReductionFailed"]];
   polys=polys-Sum[vector[[a]] FeynCalc`FCI[FeynCalc`SPD[k,old[[a]]]],{a,Length[old]}]+
     Sum[coeffs[[a]] FeynCalc`FCI[FeynCalc`SPD[k,ext[[a]]]],{a,Length[ext]}],
  {k,loops}];
  Expand[polys],
 {j,active}];
 newCuts=(First[FirstPosition[active,#]]& /@ d["CutIndices"]);
 cutMom=momMap /@ d["OrientedCutMomenta"];
 If[AnyTrue[cutMom,MissingQ],epsOrderFail["CutMomentumOutsideIntegralMomentumSpan"]];
 propMom=Map[momMap,Lookup[d,"PropagatorMomenta"][[active]]/.m_Missing->0];
 r=Join[r,<|"ExternalMomenta"->ext,"InversePropagators"->cores,
  "PropagatorMomenta"->propMom,"PropagatorPowers"->d["PropagatorPowers"][[active]],
  "CutIndices"->newCuts,"OrientedCutMomenta"->cutMom,
  "KinematicRules"->kin,"TimeDirection"->momMap[g["TotalMomentum"]],
  "OriginalPropagatorIndices"->active,
  "ExternalBasisDefinition"->Thread[ext->eff.old]|>];
 Join[r,miRepBaikov[r]]
];

cutOrderNormalDerivatives[d_] := Module[
 {p=d["BaikovPolynomial"],a=d["BaikovExponent"],z=d["IntegrationVariables"],
  cuts=d["CutIndices"],nu=d["PropagatorPowers"],terms=<|0->1|>,next,zero,fac=1,degree,poly},
 Do[
  fac=fac (nu[[j]]-1)!;
  Do[
   next=<||>;
   KeyValueMap[Function[{shift,numerator},
    AssociateTo[next,shift->(Lookup[next,shift,0]+D[numerator,z[[j]]])];
    AssociateTo[next,(shift+1)->(Lookup[next,shift+1,0]+
      (a-shift) numerator D[p,z[[j]]])]],terms];
   terms=Select[Map[Expand,next],!epsOrderZero[#]&],
  {repeat,nu[[j]]-1}],
 {j,cuts}];
 zero=Thread[z[[cuts]]->0];p=Factor[p/.zero];
 If[epsOrderZero[p],epsOrderFail["CutSurfaceHasNoGramInterior"]];
 <|"IntegrationVariables"->Delete[z,List /@ cuts],"Polynomial"->p,
  "DomainConditions"->(d["DomainConditions"]/.zero),
  "Prefactor"->d["ParametricPrefactor"]/fac,
  "Terms"->KeyValueMap[<|"GramPowerShift"->#1,"Exponent"->a-#1,
    "Numerator"->Factor[#2/.zero]|>&,terms],
  "NormalDerivativeOrder"->Total[nu[[cuts]]-1]|>
];

cutOrderBilinearCertificate[core_,d_,g_] := Module[
 {atoms,vars,rules,reduce,target,candidate,coefficients,position,scale,span,intersection,answer=None},
 atoms=DeleteDuplicates[Cases[d["InversePropagators"],
  _FeynCalc`Pair,Infinity]];
 vars=Table[Unique["scalarProductCoordinate"],{Length[atoms]}];rules=Thread[atoms->vars];
 reduce[x_] := Expand[x/.rules];
 target=reduce[core];
 If[epsOrderZero[target],Return[None]];
 Do[
  candidate=reduce[FeynCalc`ExpandScalarProduct[FeynCalc`FCI[
    FeynCalc`SPD[g["Rays"][[i]],g["Rays"][[j]]]]]/.d["KinematicRules"]];
  If[epsOrderZero[candidate],Continue[]];
  coefficients=CoefficientRules[candidate,vars];position=First[First[coefficients]];
  scale=CoefficientRules[target,vars];
  scale=Last[SelectFirst[scale,First[#]===position&,position->0]]/Last[First[coefficients]];
  If[epsOrderZero[scale] || !epsOrderZero[target-scale candidate],Continue[]];
  span=g["RayVectors"][[{i,j}]];
  intersection=MatrixRank[span]+Length[g["IntegralMomentumSubspace"]]-
    MatrixRank[Join[span,g["IntegralMomentumSubspace"]]];
  If[intersection<2,Continue[]];
  answer=<|"Method"->"FutureCausalScalarProduct","Rays"->{i,j},
   "ProportionalityFactor"->scale,"IntersectionDimension"->intersection,
   "Reason"->"A zero scalar product between future causal vectors implies collinearity or a zero vector, forcing a Gram dependence."|>;
  Break[],
 {i,Length[g["Rays"]]},{j,i,Length[g["Rays"]]}];
 answer
];

cutOrderSingularityCertificates[d_,g_,seconds_] := Module[
 {certificates=<||>,active,core,proof,rd=None,z,var,domain,reducedIndex,condition,result},
 active=Select[Range[Length[d["PropagatorPowers"]]],
  d["PropagatorPowers"][[#]]>0 && !MemberQ[d["CutIndices"],#]&];
 Do[
  core=d["InversePropagators"][[j]];
  If[FreeQ[core,Alternatives@@d["LoopMomenta"]],
   If[epsOrderZero[core],epsOrderFail["ZeroUncutInversePropagator"]];
   AssociateTo[certificates,j-><|"Method"->"NonzeroKinematicConstant"|>];Continue[]];
  proof=None;
  If[epsOrderZero[g["PropagatorMassSquared"][[j]]] &&
    !MissingQ[d["PropagatorMomenta"][[j]]],
   proof=cutOrderQuadraticCertificate[d["PropagatorMomenta"][[j]],g]];
  If[!AssociationQ[proof] && MissingQ[g["PropagatorMassSquared"][[j]]],
   proof=cutOrderBilinearCertificate[core,d,g]];
  If[!AssociationQ[proof],
   If[rd===None,rd=cutOrderReduceExternal[d,g]];
   z=rd["IntegrationVariables"];
   reducedIndex=First[FirstPosition[g["ActivePropagatorIndices"],j]];
   domain=rd["DomainConditions"];
   var=Delete[z,reducedIndex];
   condition=domain && rd["BaikovPolynomial"]>0 &&
     And@@Thread[(z[[rd["CutIndices"]]] g["PropagatorSigns"][[d["CutIndices"]]])>=0] &&
     z[[reducedIndex]]==0;
   condition=condition/.z[[reducedIndex]]->0;
   result=TimeConstrained[Resolve[Exists[var,condition],Reals],seconds,$TimedOut];
   If[result===False,proof=<|"Method"->"RealAlgebraicZeroContainment",
      "Statement"->"The inverse propagator cannot vanish in the positive Gram interior throughout the nonnegative cut-mass deformation.",
      "Decision"->False|>]
  ];
  If[!AssociationQ[proof],epsOrderFail["CutPropagatorBoundaryContainmentNotEstablished",
    <|"PropagatorIndex"->j,"InversePropagator"->core|>]];
  AssociateTo[certificates,j->Join[proof,<|"NonnegativeCutMassDeformation"->True|>]],
 {j,active}];
 certificates
];

cutOrderPoleBound[d_,e_,seconds_] := Module[
 {g,certificates,rd,nd,n,a,alpha0,slope,prefVal,ordinary,maximumShift,num,poly,nu,
  zero,termVal,lower,statement},
 g=cutOrderGeometry[d];
 certificates=cutOrderSingularityCertificates[d,g,seconds];
 rd=cutOrderReduceExternal[d,g];
 If[!TrueQ[rd["KinematicConditions"]],epsOrderFail["PhysicalKinematicConditionsNotEstablished"]];
 nd=cutOrderNormalDerivatives[rd];n=Length[nd["IntegrationVariables"]];
 a=rd["BaikovExponent"];alpha0=Limit[a,e->0];slope=epsOrderValuation[Cancel[a-alpha0],e];
 If[slope===Infinity || !IntegerQ[slope] || slope<1,
  epsOrderFail["NonconstantDimensionRegulatorRequired"]];
 If[!FreeQ[nd["Polynomial"],e],epsOrderFail["RegulatorIndependentGramPolynomialRequired"]];
 prefVal=epsOrderValuation[nd["Prefactor"],e];
 maximumShift=Max[Prepend[Lookup[nd["Terms"],"GramPowerShift"],0]];
 poly=nd["Polynomial"];
 num=Factor[Total[(#["Numerator"] poly^(maximumShift-#["GramPowerShift"])& /@ nd["Terms"])]];
 ordinary=Times@@Table[If[MemberQ[rd["CutIndices"],j],1,
   rd["IntegrationVariables"][[j]]^-rd["PropagatorPowers"][[j]]],
  {j,Length[rd["PropagatorPowers"]]}];
 termVal=epsOrderValuation[num,e];
 lower=If[termVal===Infinity,Infinity,prefVal+termVal-n slope];
 <|"DataType"->"IntegralLaurentBound","Status"->"BoundEstablishedForRepresentation",
  "LowerBound"->lower,"Representation"->d,
  "Method"->"CompactSemialgebraicPoleMultiplicityBound",
  "EffectiveExternalRank"->g["EffectiveExternalRank"],
  "RemainingIntegrationDimension"->n,"RegulatorSlopeValuation"->slope,
  "PrefactorLaurentValuation"->prefVal,"NumeratorLaurentValuation"->termVal,
  "CompactnessCertificate"->KeyTake[g,{"TotalMomentum","TotalMomentumSquared",
    "IndependentCutMomenta","CutRoutingMatrix","CompactnessEstablished","CompactnessReason"}],
  "PropagatorBoundaryCertificates"->certificates,
  "CausalRays"->KeyTake[g,{"Momenta","Rays","RayVectors","RayMassSquared","IntegralMomentumSubspace"}],
  "CutIntegralTerms"-><|"IntegrationVariables"->nd["IntegrationVariables"],
    "Prefactor"->nd["Prefactor"],"RationalFactor"->num ordinary,
    "Polynomial"->poly,"Exponent"->a-maximumShift,
    "DomainConditions"->nd["DomainConditions"],
    "ExternalBasisDefinition"->rd["ExternalBasisDefinition"],
    "NormalDerivativeOrder"->nd["NormalDerivativeOrder"]|>,
  "PoleMultiplicityArgument"->"After normal derivatives in a convergence half-plane, compact semialgebraic normal-crossing resolution has at most n integration coordinates. Every singular divisor is regulated by the Gram power, so each coordinate contributes at most the valuation of its regulator slope. Explicit prefactor and numerator valuations are included.",
  "SectorResolutionPerformed"->False,"IntegralValuesEvaluatedNumerically"->False,
  "BoundIsSufficientNotNecessarilySharp"->True|>
];

End[];
