(* One compact-cut convergence proof for ordinary prescriptions, Laurent bounds
   and dimensional recurrences. Unit and repeated cuts use the same independent
   nonnegative cut-mass deformation. *)
Begin["FeynFacet`Private`"];
cutConvergenceProve[condition_,assumptions_] := assumptions=!=False &&
 (TrueQ[condition] || TrueQ[TimeConstrained[
   Quiet[FullSimplify[condition,Assumptions->assumptions]],2,False]]);

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
  qvec,constant,signs,propMasses,propMom,positive,externalGram,spatialGram,assum,translation},
 loops=d["LoopMomenta"];ext=d["ExternalMomenta"];all=Join[loops,ext];
 cuts=d["CutIndices"];cm=d["OrientedCutMomenta"];l=Length[loops];nu=d["PropagatorPowers"];
 kin=d["KinematicRules"];assum=d["KinematicConditions"];
 If[assum===False,epsOrderFail["EmptyKinematicDomain"]];
 If[l<1 || !VectorQ[nu,IntegerQ] || cuts==={} ||
   !AllTrue[nu[[cuts]],#>0&],epsOrderFail["PositiveIntegerCutPowersRequired"]];
 If[!FreeQ[kin,Alternatives@@loops],epsOrderFail["ExternalKinematicRulesRequired"]];
 p=Expand[Total[cm]];psq=cutOrderSquare[p,kin];
 If[d["VirtualLoopCount"]=!=0 || Length[cuts]=!=l+1 ||
   !FreeQ[p,Alternatives@@loops] || !cutConvergenceProve[psq>0,assum],
   epsOrderFail["CompactConnectedPhaseSpaceRequired"]];
 route=Table[Coefficient[m,k],{m,cm},{k,loops}];
 translation=Expand /@ (cm-route.loops);
 If[!MatrixQ[route,exactRationalQ] || !FreeQ[translation,Alternatives@@loops] ||
   !MatrixQ[cutOrderVector[#,all]& /@ cm,exactRationalQ],
   epsOrderFail["AffineRealCutRoutingRequired"]];
 independent=SelectFirst[Subsets[Range[l+1],{l}],!epsOrderZero[Det[route[[#]]]]&,None];
 If[independent===None,epsOrderFail["IndependentCutMomentumRoutingRequired"]];
 propMom=Lookup[d,"PropagatorMomenta",{}];
 If[Length[propMom]=!=Length[nu],epsOrderFail["PropagatorMomentumDataRequired"]];
 (* SFAD may encode a negative quadratic using I q. Recover a real routing
    and keep its sign in the inverse polynomial. *)
 Do[If[!MissingQ[propMom[[j]]] &&
    !VectorQ[cutOrderVector[propMom[[j]],all],exactRationalQ],
   propMom[[j]]=If[VectorQ[cutOrderVector[-I propMom[[j]],all],exactRationalQ],
     Expand[-I propMom[[j]]],Missing["NonrealRouting"]]],{j,Length[nu]}];
 signs=ConstantArray[Missing["NotQuadratic"],Length[nu]];
 propMasses=signs;
 Do[
  If[!MatchQ[propMom[[j]],_Missing],
   qvec=cutOrderSquare[propMom[[j]],kin];
   Do[constant=Expand[qvec-sign d["InversePropagators"][[j]]];
    If[FreeQ[constant,Alternatives@@loops],
     signs[[j]]=sign;propMasses[[j]]=constant;Break[]],{sign,{1,-1}}]],
 {j,Length[nu]}];
 If[!AllTrue[propMasses[[cuts]],cutConvergenceProve[#>=0,assum]&],
  epsOrderFail["NonnegativeCutMassesRequired"]];
 If[!cutConvergenceProve[psq>Total[Sqrt /@ propMasses[[cuts]]]^2,assum],
  epsOrderFail["OrdinaryPhaseSpacePointAboveThresholdRequired"]];
 If[!cutConvergenceProve[(FeynCalc`ExpandScalarProduct[FeynCalc`FCI[
   FeynCalc`SPD[p,d["TimeDirection"]]]]/.kin)>0,assum],
  epsOrderFail["FutureTotalPhaseSpaceMomentumRequired"]];
 (* All cut momenta are future causal on the physical domain. Keep precisely
    the external momenta whose future-causal character is established. *)
 positive=Select[ext,cutConvergenceProve[cutOrderSquare[#,kin]>=0,assum] &&
   cutConvergenceProve[(FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[#,p]]]/.kin)>0,assum]&];
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
 If[!cutConvergenceProve[Det[externalGram]!=0 && Element[Flatten[externalGram],Reals],assum] || !And@@Flatten[Table[
   cutConvergenceProve[Det[spatialGram[[set,set]]]>=0,assum],{size,Length[ext]},
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
  "ConeBases"->coneBases,"PropagatorMomenta"->propMom,"PropagatorSigns"->signs,"PropagatorMassSquared"->propMasses,
  "ActivePropagatorIndices"->active,"EffectiveExternalBasis"->eff,
  "EffectiveExternalRank"->Length[eff],"IntegralMomentumSubspace"->fullspace,
  "ExternalGramMatrix"->externalGram,"KinematicConditions"->assum|>
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
 If[AnyTrue[g["RayMassSquared"][[ids]],cutConvergenceProve[#>0,g["KinematicConditions"]]&],
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
    If[AnyTrue[g["RayMassSquared"][[ids]],cutConvergenceProve[#>0,g["KinematicConditions"]]&],
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
  If[!cutConvergenceProve[scale!=0 && Element[scale,Reals],d["KinematicConditions"]] ||
   !epsOrderZero[target-scale candidate],Continue[]];
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
   If[!cutConvergenceProve[core!=0 && Element[core,Reals],d["KinematicConditions"]],
     epsOrderFail["NonzeroExternalDenominatorNotEstablished",<|"InversePropagator"->core|>]];
   AssociateTo[certificates,j-><|"Method"->"NonzeroKinematicConstant"|>];Continue[]];
  proof=None;
  If[epsOrderZero[g["PropagatorMassSquared"][[j]]] &&
    !MissingQ[g["PropagatorMomenta"][[j]]],
   proof=cutOrderQuadraticCertificate[g["PropagatorMomenta"][[j]],g]];
  If[!AssociationQ[proof] && MissingQ[g["PropagatorMassSquared"][[j]]],
   proof=cutOrderBilinearCertificate[core,d,g]];
  If[!AssociationQ[proof],
   If[rd===None,rd=cutOrderReduceExternal[d,g]];
   z=rd["IntegrationVariables"];
   reducedIndex=First[FirstPosition[g["ActivePropagatorIndices"],j]];
   domain=rd["DomainConditions"];
   var=Delete[z,reducedIndex];
   condition=d["KinematicConditions"] && domain && rd["BaikovPolynomial"]>0 &&
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

cutIntegralConvergenceCertificate[d_,seconds_:2] := Module[
 {g,witnesses,loops,frame,l,gram,projection,loopGram,transverse,sp,energies,
  domain,cuts,polynomials,coordinates,matrix,minor,nu,ordinary},
 g=cutOrderGeometry[d];
 cuts=d["CutIndices"];nu=d["PropagatorPowers"];
 loops=d["LoopMomenta"];frame=d["ExternalMomenta"];l=Length[loops];
 gram=g["ExternalGramMatrix"];
 sp[a_,b_] := Factor[FeynCalc`ExpandScalarProduct[
   FeynCalc`FCI[FeynCalc`SPD[a,b]]]/.d["KinematicRules"]];
 projection=Table[sp[k,p],{k,loops},{p,frame}];
 loopGram=Table[sp[a,b],{a,loops},{b,loops}];
 transverse=Map[Factor,projection.Inverse[gram].Transpose[projection]-loopGram,{2}];
 energies=sp[#,g["TotalMomentum"]]& /@ d["OrientedCutMomenta"];
 domain=And@@Join[Flatten[Table[Det[transverse[[set,set]]]>=0,
   {size,l},{set,Subsets[Range[l],{size}]}]],Thread[energies>=0]];
 polynomials=d["InversePropagators"][[cuts]];
 coordinates=DeleteDuplicates[Cases[polynomials,_FeynCalc`Pair,{0,Infinity}],SameQ];
 matrix=Table[Coefficient[pol,z],{pol,polynomials},{z,coordinates}];
 If[!MatrixQ[matrix,exactRationalQ] || MatrixRank[matrix]=!=Length[cuts] ||
   !AllTrue[polynomials,PolynomialQ[#,coordinates]&&Exponent[#,coordinates,Max]<=1&],
   epsOrderFail["ConstantNonsingularCutEliminationRequired"]];
 minor=SelectFirst[Subsets[Range[Length[coordinates]],{Length[cuts]}],
   Det[matrix[[All,#]]]=!=0&];
 witnesses=cutOrderSingularityCertificates[d,g,seconds];
 ordinary=Select[Complement[Range[Length[nu]],cuts],nu[[#]]>0&];
 <|"DataType"->"CutIntegralConvergenceCertificate",
   "Status"->"CertifiedGenericKinematics","Method"->"NonnegativeCutMassDeformation",
   "Geometry"->KeyDrop[g,"ConeBases"],"PropagatorBoundaryCertificates"->witnesses,
   "OrdinaryPrescriptionRemoved"->(ordinary=!={}),"CutPrescriptionsRemoved"->False,
   "OrdinaryIndices"->ordinary,"OrdinaryPowers"->nu[[ordinary]],
   "NormalDerivativeOrder"->Total[nu[[cuts]]-1],
   "NonnegativeCutMassDeformation"->True,"EventualHighDimensionHolomorphy"->True,
   "Scope"->"Generic fixed external kinematics; meromorphic dimensional continuation",
   "EndpointDistributionStatus"->"NotCertified",
   "GramPolynomial"->Factor[Det[transverse]],
   "GramExponent"->(d["Dimension"]-Length[frame]-l-1)/2,
   "ClosedDomainConditions"->domain,"CutEquations"->Thread[polynomials==0],
   "CutEliminationJacobian"->1/Abs[Det[matrix[[All,minor]]]],
   "ConvergenceDomain"->"There exists a finite D* such that Re(D)>D* admits uniform domination for the required finite cut-mass derivatives and ordinary eta limits.",
   "Proof"->"Compact positive-energy phase space throughout independent nonnegative cut-mass increments; every ordinary zero forces the actual integral Gram boundary; semialgebraic domination and sufficiently large Re(D) suppress all required boundary traces. Take ordinary eta to zero and finite cut-mass derivatives there, then continue dimension meromorphically.",
   "NumeratorScope"->"Finite polynomial scalar-product numerators; coefficients finite at the stated external kinematics."|>
];

End[];
