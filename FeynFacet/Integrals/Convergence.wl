(* One compact-cut convergence proof for ordinary prescriptions, Laurent bounds
   and dimensional recurrences. Unit and repeated cuts use the same independent
   nonnegative cut-mass deformation. *)
Begin["FeynFacet`Private`"];
cutConvergenceProve[condition_,assumptions_] := assumptions=!=False &&
 (TrueQ[condition] || TrueQ[TimeConstrained[
   Quiet[FullSimplify[condition,Assumptions->assumptions]],2,False]]);

(* Complete independent loop scalar products, never fixed external Pairs. *)
cutConvergenceCoordinates[d_] := Module[{loops=d["LoopMomenta"],ext=d["ExternalMomenta"],l},
 l=Length[loops];
 Join[Flatten[Table[FeynCalc`FCI[FeynCalc`SPD[loops[[i]],loops[[j]]]],
   {i,l},{j,i,l}]],Flatten[Table[FeynCalc`FCI[FeynCalc`SPD[k,p]],{k,loops},{p,ext}]]]
];
cutConvergenceAffineQ[polynomials_,coordinates_,loops_] := Module[{matrix,constant,residual},
 matrix=Table[Coefficient[pol,z],{pol,polynomials},{z,coordinates}];
 constant=polynomials/.Thread[coordinates->0];
 residual=Expand /@ (polynomials-matrix.coordinates-constant);
 TrueQ[AllTrue[polynomials,PolynomialQ[#,coordinates]&] &&
   FreeQ[constant,Alternatives@@loops] && AllTrue[residual,epsOrderZero]]
];
cutConvergenceExternalBasis[couplings_,assum_] := Module[{eff,cols,rows},
 eff=DeleteCases[RowReduce[couplings],row_/;AllTrue[row,epsOrderZero]];
 If[MatrixQ[couplings,exactRationalQ],Return[eff]];
 (* RREF pivot columns must have a nonzero minor on the entire requested domain. *)
 cols=Table[SelectFirst[Range[Length[eff[[i]]]],!epsOrderZero[eff[[i,#]]]&],{i,Length[eff]}];
 rows=TimeConstrained[SelectFirst[Subsets[Range[Length[couplings]],{Length[eff]}],
   cutConvergenceProve[Det[couplings[[#,cols]]]!=0,assum]&,None],2,None];
 If[rows===None,epsOrderFail["UniformExternalMomentumRankNotEstablished"]];
 eff
];

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
  qvec,constant,signs,propMasses,propMom,positive,externalGram,spatialGram,assum,translation,coordinates,cores,coefficients},
 loops=d["LoopMomenta"];ext=d["ExternalMomenta"];all=Join[loops,ext];
 cuts=Lookup[d,"ParticleCutIndices",d["CutIndices"]];cm=d["OrientedCutMomenta"];l=Length[loops];nu=d["PropagatorPowers"];
 kin=d["KinematicRules"];assum=d["KinematicConditions"];
 If[assum===False,epsOrderFail["EmptyKinematicDomain"]];
 If[l<1 || !VectorQ[nu,IntegerQ] || cuts==={} ||
   !AllTrue[nu[[cuts]],#>0&],epsOrderFail["PositiveIntegerCutPowersRequired"]];
 If[!FreeQ[kin,Alternatives@@loops],epsOrderFail["ExternalKinematicRulesRequired"]];
 coordinates=cutConvergenceCoordinates[d];
 cores=d["InversePropagators"][[Union[cuts,Select[Range[Length[nu]],nu[[#]]=!=0&]]]];
 If[!cutConvergenceAffineQ[cores,coordinates,loops],
   epsOrderFail["AffineScalarProductDenominatorsRequired"]];
 coefficients=Flatten[Values[CoefficientRules[#,coordinates]]& /@ cores];
 If[!cutConvergenceProve[Element[coefficients,Reals],assum],
   epsOrderFail["RealInversePropagatorCoefficientsRequired"]];
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
 propMom=Lookup[d,"PropagatorMomenta",{}]/.None->Missing["NotQuadratic"];
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
 If[!AllTrue[MapThread[cutOrderSquare[#1,kin]-#2-#3 #4&,
   {cm,propMasses[[cuts]],signs[[cuts]],d["InversePropagators"][[cuts]]}],epsOrderZero],
   epsOrderFail["CutMomentumDoesNotMatchPropagator"]];
 If[!cutConvergenceProve[psq>Total[Sqrt /@ propMasses[[cuts]]]^2,assum],
  epsOrderFail["OrdinaryPhaseSpacePointAboveThresholdRequired"]];
 If[!FreeQ[d["TimeDirection"],Alternatives@@loops] ||
   !cutConvergenceProve[cutOrderSquare[d["TimeDirection"],kin]>0 &&
   (FeynCalc`ExpandScalarProduct[FeynCalc`FCI[
   FeynCalc`SPD[p,d["TimeDirection"]]]]/.kin)>0,assum],
  epsOrderFail["FutureTotalPhaseSpaceMomentumRequired"]];
 (* All cut momenta are future causal on the physical domain. Keep precisely
    the external momenta whose future-causal character is established. *)
 positive=Select[ext,cutConvergenceProve[cutOrderSquare[#,kin]>=0,assum] &&
   cutConvergenceProve[(FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[#,p]]]/.kin)>0,assum]&];
 positive=DeleteDuplicates[Append[positive,p]];
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
 eff=cutConvergenceExternalBasis[couplings,assum];
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
 <|"LoopCount"->l,"Momenta"->all,"ExternalMomenta"->ext,"ParticleCutIndices"->cuts,
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
(* If 2 p.P > P^2 for future null p, every nonempty future subset K of P
   satisfies (p-K)^2<=0. Equality forces K null and parallel to p, hence
   the same integral Gram boundary. This is a witness inside the one proof. *)
cutOrderSubsetCertificate[q_,g_]:=Module[
 {v,particleCount,subsetVectors,pv,kv,jacobian,pTotal,rank,intersection,answer=None},
 v=cutOrderVector[q,g["Momenta"]];
 (* Particle rows are exactly the cut routing rows, including the recoil. *)
 particleCount=Length[g["CutRoutingMatrix"]];
 pTotal=Drop[cutOrderVector[g["TotalMomentum"],g["Momenta"]],g["LoopCount"]];
 subsetVectors=Total[g["RayVectors"][[#]]]&/@Rest[Subsets[Range[particleCount]]];
 Do[pv=g["RayVectors"][[nullRay]];
  jacobian=2Drop[pv,g["LoopCount"]].g["ExternalGramMatrix"].pTotal;
  If[!cutConvergenceProve[jacobian>g["TotalMomentumSquared"],g["KinematicConditions"]],Continue[]];
  Do[
   If[!AnyTrue[{1,-1},And@@(epsOrderZero/@(pv-kv-# v))&],Continue[]];
   rank=MatrixRank[{pv,kv}];
   intersection=rank+Length[g["IntegralMomentumSubspace"]]-
     MatrixRank[Join[{pv,kv},g["IntegralMomentumSubspace"]]];
   If[intersection<2,Continue[]];
   answer=<|"Method"->"NullReferenceMinusFutureSubset","NullRay"->nullRay,
    "SubsetMomentumCoordinates"->kv,"ReferenceProjectionTwice"->jacobian,
    "IntersectionDimension"->intersection,
    "Reason"->"For 2 p.P>P^2, a zero of (p-K)^2 with K and P-K future causal requires K null and parallel to p; the actual integral Gram determinant vanishes."|>;
   Break[],{kv,subsetVectors}];
  If[AssociationQ[answer],Break[]],
 {nullRay,g["FixedNullRays"]}];answer
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
 If[Length[branches]=!=2,Return[cutOrderSubsetCertificate[q,g]]];
 <|"Method"->"BothEnergySigns","Branches"->branches,
  "ZeroEnergyBranch"->"A null vector orthogonal to a timelike vector is zero; its nonzero coefficient vector lies in the integral momentum subspace."|>
];

(* Express only the scalar products actually occurring in the master using an
   independent external basis. This removes unused angular directions exactly. *)
cutOrderReduceExternal[d_,g_] := Module[
 {r=d,loops=d["LoopMomenta"],old=d["ExternalMomenta"],eff=g["EffectiveExternalBasis"],
  ext,cols,all,active=g["ActivePropagatorIndices"],newCuts,rules,cores,momMap,
  coefficient,externalPart,representation,kin,gram,couplings,spAtoms,spVariables,newSP,
  oldG,loopG,polys,constant,vector,coeffs,masses,cutMom,propMom,particleCuts,measurementCuts},
 ext=Table[Unique["externalBasisMomentum"],{Length[eff]}];
 all=Join[loops,old];
 (* Pivot columns make the coefficient reconstruction a small exact solve. *)
 cols=SelectFirst[Subsets[Range[Length[old]],{Length[eff]}],
  !epsOrderZero[Det[eff[[All,#]]]]&,None];
 If[cols===None || !cutConvergenceProve[Det[eff[[All,cols]]]!=0,d["KinematicConditions"]],
   epsOrderFail["IndependentExternalMomentumBasisRequired"]];
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
  particleCuts=(First[FirstPosition[active,#]]& /@ Lookup[d,"ParticleCutIndices",d["CutIndices"]]);
  measurementCuts=(First[FirstPosition[active,#]]& /@ Lookup[d,"MeasurementCutIndices",{}]);
 cutMom=momMap /@ d["OrientedCutMomenta"];
 If[AnyTrue[cutMom,MissingQ],epsOrderFail["CutMomentumOutsideIntegralMomentumSpan"]];
 propMom=Map[momMap,Lookup[d,"PropagatorMomenta"][[active]]/.m_Missing->0];
 r=Join[r,<|"ExternalMomenta"->ext,"InversePropagators"->cores,
  "PropagatorMomenta"->propMom,"PropagatorPowers"->d["PropagatorPowers"][[active]],
  "CutIndices"->newCuts,"ParticleCutIndices"->particleCuts,
   "MeasurementCutIndices"->measurementCuts,"OrientedCutMomenta"->cutMom,
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

cutConvergenceZeroContainment[d_,g_,core_,seconds_] := Module[
 {loops=d["LoopMomenta"],ext=d["ExternalMomenta"],basis=g["EffectiveExternalBasis"],
  gram,projection,loopGram,transverse,sp,domain,energies,coordinates,variables,rules,condition,result,l},
 l=Length[loops];
 sp[a_,b_] := Factor[FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[a,b]]]/.d["KinematicRules"]];
 gram=Map[Cancel,basis.g["ExternalGramMatrix"].Transpose[basis],{2}];
 If[!cutConvergenceProve[Det[gram]!=0,d["KinematicConditions"]],
   epsOrderFail["IndependentEffectiveExternalGramRequired"]];
 projection=Table[sp[k,p],{k,loops},{p,ext}].Transpose[basis];
 loopGram=Table[sp[k,q],{k,loops},{q,loops}];
 transverse=Map[Factor,projection.Inverse[gram].Transpose[projection]-loopGram,{2}];
 energies=sp[#,g["TotalMomentum"]]& /@ d["OrientedCutMomenta"];
 domain=And@@Join[Flatten[Table[Det[transverse[[set,set]]]>=0,
   {size,l},{set,Subsets[Range[l],{size}]}]],Thread[energies>=0]];
 coordinates=cutConvergenceCoordinates[d];
 variables=Table[Unique["scalarProductCoordinate"],{Length[coordinates]}];
 rules=Thread[coordinates->variables];
 condition=(d["KinematicConditions"] && domain && Det[transverse]>0 &&
   And@@Thread[(d["InversePropagators"][[g["ParticleCutIndices"]]] g["PropagatorSigns"][[g["ParticleCutIndices"]]])>=0] &&
   core==0)/.rules;
 result=TimeConstrained[With[{quantifiedVariables=variables,physicalCondition=condition},
   Resolve[Exists[quantifiedVariables,physicalCondition],Reals]],seconds,$TimedOut];
 If[result===False,<|"Method"->"RealAlgebraicZeroContainment",
   "Statement"->"The original inverse polynomial has no zero in the positive effective Gram interior throughout nonnegative cut-mass increments; coordinates are independent loop scalar products.",
   "Decision"->False|>,None]
];

cutOrderSingularityCertificates[d_,g_,seconds_] := Module[
 {certificates=<||>,active,core,proof},
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
  If[!AssociationQ[proof],proof=cutConvergenceZeroContainment[d,g,core,seconds]];
  If[!AssociationQ[proof],epsOrderFail["CutPropagatorBoundaryContainmentNotEstablished",
    <|"PropagatorIndex"->j,"InversePropagator"->core|>]];
  AssociateTo[certificates,j->Join[proof,<|"NonnegativeCutMassDeformation"->True|>]],
 {j,active}];
 certificates
];

cutIntegralConvergenceCertificate[d_,seconds_:2] := Module[
 {g,witnesses,loops,frame,l,gram,projection,loopGram,transverse,sp,energies,
  domain,cuts,polynomials,coordinates,matrix,minor,nu,ordinary,measurements,jetOrder},
 g=cutOrderGeometry[d];
 cuts=d["CutIndices"];nu=d["PropagatorPowers"];
 measurements=Lookup[d,"MeasurementCutIndices",{}];
 If[!AllTrue[nu[[cuts]],#>0&],epsOrderFail["PositiveIntegerCutPowersRequired"]];
 jetOrder=Total[nu[[cuts]]-1];
 If[Sort[Join[g["ParticleCutIndices"],measurements]]=!=Sort[cuts]||
   !DuplicateFreeQ[Join[g["ParticleCutIndices"],measurements]],epsOrderFail["CompleteTypedCutPartitionRequired"]];
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
 coordinates=cutConvergenceCoordinates[d];
 matrix=Table[Coefficient[pol,z],{pol,polynomials},{z,coordinates}];
 If[!TrueQ[MatrixQ[matrix,exactRationalQ] && MatrixRank[matrix]===Length[cuts] &&
   cutConvergenceAffineQ[polynomials,coordinates,loops]],
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
   "NormalDerivativeOrder"->jetOrder,
   "ParticleCutIndices"->g["ParticleCutIndices"],"MeasurementCutIndices"->measurements,
   "UniformGramDomination"->True,
   "UniformDominationDomain"->"The closed compact union of forward phase spaces with independently increased nonnegative particle masses, before imposing any measurement slices.",
   "NormalDerivativeBudget"-><|"RequiredOrder"->jetOrder,"ZeroExtensionOrder"->jetOrder+1,
    "AdditionalGramInversePower"->jetOrder+1,
    "MaximumOrdinaryPowers"->Thread[ordinary->(nu[[ordinary]]+jetOrder+1)],
    "ThresholdArgument"->"If |Q_j|^-1 <= C_j P^-kappa_j on the parent compact domain, q + Sum[kappa_j (nu_j+q)] bounds the finite Gram-power loss through order q. The existing uniform zero-containment witnesses imply finite kappa_j by the semialgebraic Lojasiewicz inequality."|>,
   "MovingBoundaryContainment"->"Every boundary of the positive transverse Gram component and every forward particle energy tip lies on P=0. Sufficiently high Gram powers have vanishing normal jets there.",
   "NonnegativeCutMassDeformation"->True,"EventualHighDimensionHolomorphy"->True,
   "Scope"->"Generic fixed external kinematics; meromorphic dimensional continuation",
   "EndpointDistributionStatus"->"NotCertified",
   "GramPolynomial"->Factor[Det[transverse]],
   "GramExponent"->(d["Dimension"]-Length[frame]-l-1)/2,
   "ClosedDomainConditions"->domain,"CutEquations"->Thread[polynomials==0],
   "CutEliminationJacobian"->1/Abs[Det[matrix[[All,minor]]]],
   "ConvergenceDomain"->"There exists a finite D* such that Re(D)>D* admits uniform domination for the required finite cut-mass derivatives and ordinary eta limits.",
   "Proof"->"Compact positive-energy phase space throughout independent nonnegative cut-mass increments; every ordinary zero forces the actual integral Gram boundary; semialgebraic domination and sufficiently large Re(D) suppress all required boundary traces. Take ordinary eta to zero and finite cut-mass derivatives there, then continue dimension meromorphically.",
   "SmoothInsertionScope"->"Smooth functions of affine scalar-product coordinates, with bounded derivatives through the finite cut-normal order. The constant cut-elimination matrix differentiates these insertions with finite external coefficients; moving-domain and Gram-weight losses remain in the parent mass-derivative bound.",
   "SmoothInsertionDerivativeOrder"->Total[nu[[cuts]]-1],
   "NumeratorScope"->"Finite polynomial scalar-product numerators; coefficients finite at the stated external kinematics."|>
];


(* Joint external-domain specialization of this same compact-cut proof.
   Unit cuts have constant-rank affine elimination. The transverse angular
   pushforward is absolutely continuous for Re(D-E)>L-1; its positive Gram
   power is extended by zero before the cuts are eliminated. This constructs
   the joint measure, so no untested endpoint-supported measure is added.
   See Design/JointCutConvergence.md and Pro review 29. *)
cutJointCoefficientDivisors[expressions_,d_,variables_,closed_,gramFaces_] := Module[
 {dimension=Unique["dimension"],e=d["DimensionalRegulator"],factors,divisors={},proofs={},factor,
  spatial,poly,zeroFaces,allExpressions,dimensionCoefficients,leading},
 zeroFaces=Or@@(Equal@@(List@@#)&/@gramFaces);
 allExpressions=Join[expressions,{d["MeasurePrefactor"],Lookup[d,"MasterIntegralPrefactor",1]}];
 Do[
  factors=If[Head[expression]===Times,List@@expression,{expression}];
  Do[
   factor=source/.e->(4-dimension)/2/.D->dimension;
   If[FreeQ[factor,Alternatives@@variables],
    (* Normalizations are the declared meromorphic dimensional factors.
       Isolated poles are excluded from the open convergence domain. *)
    If[!FreeQ[factor,_ConditionalExpression|_Piecewise|_Abs|_Re|_Im|_Conjugate],
     epsOrderFail["MeromorphicDimensionalNormalizationRequired"]];
    Continue[]];
   poly=Cancel[Together[factor]];
   If[!PolynomialQ[Numerator[poly],variables]||
      !PolynomialQ[Denominator[poly],variables],
    epsOrderFail["RationalJointSpatialCoefficientRequired",<|"Factor"->source|>]];
   divisors=Join[divisors,First/@Rest[FactorList[Denominator[poly]]]],
  {source,factors}],
 {expression,allExpressions}];
 divisors=DeleteDuplicates[divisors];
 Do[
  If[FreeQ[factor,Alternatives@@variables],Continue[]];
  If[!FreeQ[factor,dimension],
   If[!PolynomialQ[factor,dimension],
    epsOrderFail["MixedDimensionKinematicDivisorNeedsUniformProof",<|"Divisor"->(factor/.dimension->D)|>]];
   dimensionCoefficients=CoefficientList[factor,dimension];leading=Last[dimensionCoefficients];
   If[!cutConvergenceProve[leading!=0&&Element[dimensionCoefficients,Reals],closed]||
     !AllTrue[dimensionCoefficients,
       cutConvergenceProve[Denominator[Together[#]]!=0,closed]&],
    epsOrderFail["MixedDimensionKinematicDivisorNeedsUniformProof",<|"Divisor"->(factor/.dimension->D)|>]];
   AppendTo[proofs,<|"Divisor"->(factor/.dimension->D),"Method"->"UniformPolynomialRootBound",
    "LeadingDimensionCoefficient"->leading,
    "Argument"->"All normalized polynomial coefficients are continuous on the compact spatial domain and the leading coefficient is uniformly nonzero. The Cauchy root bound therefore puts every dimension root in one bounded disk.",
    "ExplicitRootBoundComputed"->False|>];Continue[]];
  If[cutConvergenceProve[factor!=0,closed],
   AppendTo[proofs,<|"Divisor"->factor,"Method"->"NonzeroOnClosedExternalDomain"|>],
   If[!cutConvergenceProve[Implies[factor==0,zeroFaces],closed],
    epsOrderFail["JointCoefficientDivisorGramContainmentNotEstablished",<|"Divisor"->factor|>]];
   AppendTo[proofs,<|"Divisor"->factor,"Method"->"ZerosOnlyOnProvedGramFaces","GramFaces"->gramFaces|>]],
 {factor,divisors}];
 proofs
];

cutIntegralJointConvergenceCertificate[d_,generic_,request_] := Module[
 {joint,intervals,xs,z,allVariables,assumptions,closed,open,time,g,gram,loops,ext,p,
  sp,kin,nu,cuts,coordinates,polynomials,matrix,minor,faces={},exteriorFaces={},
  inside,faceCondition,square,frameCoefficients,externalExpressions,divisors,
  projection,loopGram,h,delta,energies,physical,coefficients,proofs,realCoefficients},
 joint=request["JointExternalDomain"];z=request["MeasurementVariable"];
 If[!AssociationQ[joint],epsOrderFail["JointExternalDomainRequired"]];
 {intervals,assumptions,time}=Lookup[joint,{"ExternalIntervals","Assumptions","TimeDirection"},None];
 If[!AssociationQ[intervals]||intervals===<||>||!MatchQ[z,_Symbol]||
   !AllTrue[Keys[intervals],MatchQ[#,_Symbol]&]||MemberQ[Keys[intervals],z]||
   !AllTrue[Values[intervals],MatchQ[#,{_,_}]&]||MemberQ[{assumptions,time},None],
  epsOrderFail["CompactExternalIntervalsAndTimelikeReferenceRequired"]];
 xs=Keys[intervals];allVariables=Append[xs,z];
 If[!FreeQ[{assumptions,Values[intervals]},Alternatives@@allVariables]||
   !cutConvergenceProve[And@@(Element[#,Reals]&/@Flatten[Values[intervals]])&&
    And@@(First[#]<Last[#]&/@Values[intervals]),assumptions],
  epsOrderFail["NonemptyCompactExternalIntervalsRequired"]];
 closed=assumptions&&And@@KeyValueMap[First[#2]<=#1<=Last[#2]&,intervals];
 open=assumptions&&And@@KeyValueMap[First[#2]<#1<Last[#2]&,intervals];
 inside=request["ExternalKinematicConditions"];
 If[!cutConvergenceProve[inside,open],epsOrderFail["JointInteriorMustMatchCertifiedKinematics"]];
 nu=d["PropagatorPowers"];cuts=d["CutIndices"];
 If[!AllTrue[nu[[cuts]],#===1&]||d["VirtualLoopCount"]=!=0,
  epsOrderFail["JointUnitCutPhaseSpaceRequired"]];
 loops=d["LoopMomenta"];ext=d["ExternalMomenta"];kin=d["KinematicRules"];
 g=generic["Geometry"];gram=g["ExternalGramMatrix"];p=g["TotalMomentum"];
 sp[a_,b_]:=Cancel[Together[FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[a,b]]]/.kin]];
 frameCoefficients=cutOrderVector[time,ext];
 If[!FreeQ[frameCoefficients,Alternatives@@loops]||
   !cutConvergenceProve[Element[frameCoefficients,Reals]&&sp[time,time]>0&&
      sp[time,p]>0&&sp[p,p]>=0&&Det[gram]!=0,closed],
  epsOrderFail["UniformJointFutureFrameAndExternalGramRequired"]];
 externalExpressions=Join[Flatten[gram],frameCoefficients,{sp[time,time],sp[time,p],sp[p,p]}];
 If[!AllTrue[externalExpressions,PolynomialQ[Numerator[Together[#]],xs]&&
    PolynomialQ[Denominator[Together[#]],xs]&&
    cutConvergenceProve[Denominator[Together[#]]!=0,closed]&],
  epsOrderFail["ContinuousRationalJointExternalGeometryRequired"]];
 Do[
  faceCondition=closed&&variable==endpoint;
  If[cutConvergenceProve[sp[p,p]==0,faceCondition],
   AppendTo[faces,variable->endpoint]];
  If[!cutConvergenceProve[inside,faceCondition],
   If[!MemberQ[faces,variable->endpoint],
    epsOrderFail["NewExternalFaceGramDegeneracyNotEstablished",<|"Face"->(variable->endpoint)|>]];
   AppendTo[exteriorFaces,variable->endpoint]],
 {variable,xs},{endpoint,intervals[variable]}];
 (* The already checked normalized future-null fraction has support [0,1].
    A vanishing tagged or complementary projection makes its transverse
    vectors dependent; both measurement faces lie in det(H)=0. *)
 faces=Join[faces,{z->0,z->1}];closed=closed&&0<=z<=1;
 coordinates=cutConvergenceCoordinates[d];polynomials=d["InversePropagators"][[cuts]];
 matrix=Table[Coefficient[pol,q],{pol,polynomials},{q,coordinates}];
 If[!MatrixQ[matrix,exactRationalQ]||MatrixRank[matrix]=!=Length[cuts]||
   !cutConvergenceAffineQ[polynomials,coordinates,loops],
  epsOrderFail["JointConstantRankAffineUnitCutsRequired"]];
 minor=SelectFirst[Subsets[Range[Length[coordinates]],{Length[cuts]}],Det[matrix[[All,#]]]=!=0&];
 projection=Table[sp[k,q],{k,loops},{q,ext}];loopGram=Table[sp[k,q],{k,loops},{q,loops}];
 h=Map[Cancel[Together[#]]&,projection.Inverse[gram].Transpose[projection]-loopGram,{2}];
 delta=Factor[Det[h]];energies=sp[#,time]&/@d["OrientedCutMomenta"];
 physical=closed&&And@@Thread[polynomials==0]&&And@@Thread[energies>=0]&&
  And@@Flatten[Table[Det[h[[set,set]]]>=0,{size,Length[loops]},
    {set,Subsets[Range[Length[loops]],{size}]}]];
 coefficients=Lookup[request,"ScalarCoefficients",{1}];
 If[!ListQ[coefficients]||!FreeQ[coefficients,Alternatives@@loops],
  epsOrderFail["ExternalRationalScalarCoefficientListRequired"]];
 proofs=cutJointCoefficientDivisors[coefficients,d,allVariables,closed,faces];
 Join[generic,<|"Status"->"CertifiedJointEndpointDistributions",
  "Method"->"CompactCutGramDomination","Scope"->"Joint meromorphic distributions on the declared external support.",
  "JointExternalDomain"->joint,"JointVariables"->allVariables,
  "JointPhysicalDomainConditions"->physical,"JointTransverseGramMatrix"->h,
  "GramPolynomial"->delta,"GramExponent"->(d["Dimension"]-Length[ext]-Length[loops]-1)/2,
  "GramConvention"->"Unscaled positive transverse determinant; the external factor is Abs[Det[G_external]]^(-L/2).",
  "CutEliminationJacobian"->1/Abs[Det[matrix[[All,minor]]]],
  "JointCutCoordinateIndices"->minor,"JointGramFaces"->faces,
  "NewExternalFaces"->exteriorFaces,"JointCoefficientDivisorCertificates"->proofs,
  "JointScalarCoefficients"->coefficients,
  "JointMeasureHasNoEndpointAtoms"->True,
  "JointMeasureArgument"->"The transverse angular pushforward has the absolutely continuous positive-semidefinite Gram density for Re(D-E)>L-1. Extend its sufficiently high Gram power by zero, then perform the constant-rank affine unit-cut elimination under the joint test integral. No rank-deficient stratum carries a separate measure.",
  "JointCompactnessArgument"->"The declared timelike reference and external Gram are continuous and uniformly nondegenerate on a compact external parameter set. Forward cut energies sum to the bounded positive total energy. An invertible cut routing bounds every loop component and hence the scalar domain.",
  "CommonConvergenceDomainExists"->True,"ExplicitDimensionThresholdKnown"->False,
  "UniformAbsoluteDensityBoundExists"->True,"ContinuousZeroExtensionExists"->True,
  "UniformBoundArgument"->"A finite positive Gram margin after all denominator losses makes the zero-extended scalar density continuous and bounded on a common compact box. Its integral is uniformly bounded in the external variables, locally uniformly on a pole-free high-dimension domain.",

  "JointL1PrescriptionConvergenceEstablished"->True,
  "PointwiseRegulatedConvergenceEstablished"->False,"ExternalEndpointUniformityEstablished"->True,
  "EndpointDistributionStatus"->"CertifiedJointEndpointDistributions",
  "JointContinuationArgument"->"Every spatial divisor zero lies on the unscaled Gram boundary. Compact semialgebraic Lojasiewicz inequalities give finite Gram losses; sufficiently large Re(D) dominates all of them. Ordinary eta limits hold in joint L1 on a common open dimension domain. The atom-free equality there has a unique meromorphic distributional continuation.",
  "AdditionalEndpointOrdersDetermined"->False,"EndpointCoefficientsComputed"->False|>]
];

End[];
