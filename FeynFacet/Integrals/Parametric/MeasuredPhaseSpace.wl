(* Recursive P -> k1 + K23, K23 -> k2 + k3 parameterization.
   The measured light-cone fraction fixes the first polar angle; three
   independent beta measures cover the remaining invariant phase space. *)
BeginPackage["FeynFacet`"];
ConstructMeasuredThreeParticlePhaseSpace::usage="ConstructMeasuredThreeParticlePhaseSpace[request] constructs a normalized three-variable Euler parameterization of massless three-particle phase space at fixed z=2 p.k1/(2 p.P). It returns all Lorentz scalar products, the exact D-dimensional density and independent beta weights. Physical azimuthal orientation has been integrated; scalar integrands must be invariant under rotations fixing the external plane.";
ConstructMeasuredThreeParticleIntegral::usage="ConstructMeasuredThreeParticleIntegral[definition,request] maps a normalized momentum-space integral with three unit massless particle cuts and one unit null-fraction measurement cut to the common three-variable phase-space chart, proving the routing and retaining the exact measure. It does not evaluate dotted particle cuts.";
Begin["`Private`"];
ConstructMeasuredThreeParticlePhaseSpace[request_Association]:=Catch[Module[
 {p,total,particles,scale,projection,z,e,parameters,t,y,a,assumptions,required,
  s23,s12,s13,taggedFractions,gram,rules,volume,weights,shapes,cosine,
  axis,radial,regular=1,fraction,fractionExpression,rationalRules,fullGram},
 required={"ReferenceMomentum","TotalMomentum","ParticleMomenta","InvariantMassSquared",
  "ReferenceProjection","MeasurementVariable","DimensionalRegulator","Parameters","Assumptions"};
 If[!ContainsAll[Keys[request],required],cutFamilyFail["MeasuredThreeParticleGeometryRequired"]];
 {p,total,particles,scale,projection,z,e,parameters,assumptions}=Lookup[request,required];
 If[!MatchQ[particles,{_Symbol,_Symbol,_Symbol}]||!MatchQ[parameters,{_Symbol,_Symbol,_Symbol}]||
  !MatchQ[{p,total,z,e},{_Symbol,_Symbol,_Symbol,_Symbol}]||
  !DuplicateFreeQ[Join[{p,total,z,e},particles,parameters]]||
  !FreeQ[{scale,projection},Alternatives@@Join[{p,total,z,e},particles,parameters]]||
  !FreeQ[{scale,projection,assumptions},_Real|_Failure|$Failed|$Aborted]||
  !TrueQ[FullSimplify[scale>0&&projection>0&&0<z<1,Assumptions->assumptions]],
  cutFamilyFail["NondegeneratePhysicalThreeParticleGeometryRequired"]];
 {t,y,a}=parameters;cosine=1-2a;
 axis=Lookup[request,"AngularAxis","ReferenceMomentum"];
 Switch[axis,
  "ReferenceMomentum",
   s23=scale(1-z)t;
   s12=scale(y+z t-(1+z)t y-2Sqrt[z t(1-t)y(1-y)]cosine);
   s13=scale-s23-s12;
   taggedFractions={z,(1-z)y,(1-z)(1-y)};
   fraction=None;fractionExpression=None;
   fullGram=-4projection^2 scale^2 z(1-z)^2 t(1-t)y(1-y)a(1-a),
  "TaggedParticle",
   radial=z+(1-z)t;
   fraction=Lookup[request,"AngularFractionSymbol",Unique["angularFraction"]];
   If[!MatchQ[fraction,_Symbol]||!FreeQ[Join[parameters,particles,{p,total,z,e}],fraction],
    cutFamilyFail["IndependentAngularFractionSymbolRequired"]];
   fractionExpression=t+y-2t y-2Sqrt[t(1-t)y(1-y)]cosine;
   s23=scale(1-z)t/radial;s12=scale z y/radial;s13=scale z(1-y)/radial;
   taggedFractions={z,(1-z)fraction,(1-z)(1-fraction)};
   regular=z^(1-e)radial^(-2+2e);
   fullGram=-4projection^2 scale^2 z^2(1-z)^2 t(1-t)y(1-y)a(1-a)/radial^2,
  _,cutFamilyFail["MeasuredAngularAxisUnsupported"]
 ];
 gram={{0,s12/2,s13/2},{s12/2,0,s23/2},{s13/2,s23/2,0}};
 rules=Join[
  Flatten[Table[FeynCalc`FCI[FeynCalc`SPD[particles[[i]],particles[[j]]]]->gram[[i,j]],{i,3},{j,i,3}]],
  MapThread[FeynCalc`FCI[FeynCalc`SPD[p,#1]]->projection #2&,{particles,taggedFractions}],
  Table[FeynCalc`FCI[FeynCalc`SPD[total,particles[[i]]]]->Total[gram[[i]]],{i,3}],
  FeynCalc`FCI[{FeynCalc`SPD[p]->0,FeynCalc`SPD[total]->scale,FeynCalc`SPD[p,total]->projection}]];
 rationalRules=rules;
 If[fraction=!=None,rules=rules/.fraction->fractionExpression];
 volume=FeynFacet`MasslessMeasuredPhaseSpace[3,scale,z,e];
 shapes={{1-e,1-e},{1-e,1-e},{1/2-e,1/2-e}};
 weights=MapThread[#1^(#2[[1]]-1)(1-#1)^(#2[[2]]-1)/(Beta@@#2)&,{parameters,shapes}];
 <|"Format"->"FeynFacet-MeasuredPhaseSpaceParameterization","FormatVersion"->1,
  "ParticleCount"->3,"ParticleMomenta"->particles,"ReferenceMomentum"->p,"TotalMomentum"->total,
  "MeasurementVariable"->z,"DimensionalRegulator"->e,"DimensionRule"->(D->4-2e),
  "Parameters"->parameters,"ParameterDomain"->And@@Join[Thread[parameters>0],Thread[parameters<1]],
  "ScalarProductRules"->rules,"RationalScalarProductRules"->rationalRules,
  "AngularAxis"->axis,"AngularFractionSymbol"->fraction,"AngularFractionExpression"->fractionExpression,
  "RegularMeasureFactor"->regular,"MomentumConservation"->(total->Total[particles]),
  "MeasuredPhaseSpaceVolume"->volume,"NormalizedMeasureFactors"->weights,
  "BetaShapes"->shapes,"MeasureDensity"->volume regular Times@@weights,
  "ConvergenceConditions"->Re[e]<1/2,"KinematicConditions"->assumptions,
  "FullGramMomenta"->Join[{p,total},Take[particles,2]],
  "FullGramDeterminant"->fullGram,
  "TaggedFractions"->taggedFractions,"PairInvariantMassesSquared"->{s12,s13,s23},
  "Derivation"->"Recursive Lorentz-invariant two-body phase spaces with ds23/(2 Pi); the measurement fixes the first polar angle and supplies its Jacobian.",
  "Scope"->"Scalar products only, after invariant azimuthal or joint evanescent averaging. No ordinary causal prescription is removed."|>
],"CutFamily"];

ConstructMeasuredThreeParticleIntegral[definition_Association,request_Association:<||>]:=
 Catch[Module[
 {d=definition,source,loops,ext,all,cuts,particleSlots,measurementSlots,cm,p,total,tag,z,e,
  kin,assumptions,powers,tagIndex,ordered,rows,inverse,chartMomenta,parameters,
  cp,ct,ck1,ck2,ck3,cz,chart,s,j,dot,chartRules,toChart,cores,ordinary,integrand,
  loopRoute,routingDet,standardMeasure,normalization,measure,certificate,rationalCores,rationalChartRules},
 source=Lookup[d,"SourceCutDefinition",<||>];
 If[!ContainsAll[Keys[source],{"ReferenceMomentum","TaggedMomentum","MeasurementVariable"}],
  cutFamilyFail["NullFractionMeasurementDefinitionRequired"]];
 loops=d["LoopMomenta"];ext=d["ExternalMomenta"];all=Join[loops,ext];
 cuts=d["CutIndices"];particleSlots=Lookup[d,"ParticleCutIndices",{}];
 measurementSlots=Lookup[d,"MeasurementCutIndices",{}];cm=d["OrientedCutMomenta"];
 powers=d["PropagatorPowers"];e=d["DimensionalRegulator"];kin=d["KinematicRules"];
 assumptions=d["KinematicConditions"];
 If[Length[loops]=!=2||Length[ext]=!=2||Length[particleSlots]=!=3||
  Length[measurementSlots]=!=1||Length[cm]=!=3||!AllTrue[powers[[cuts]],#===1&],
  cutFamilyFail["ThreeUnitParticleCutsAndOneUnitMeasurementRequired"]];
 {p,tag,z}=Lookup[source,{"ReferenceMomentum","TaggedMomentum","MeasurementVariable"}];
 total=Expand[Total[cm]];
 dot[a_,b_]:=Cancel[FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[a,b]]]/.kin];
 If[!epsOrderZero[dot[p,p]]||!FreeQ[{p,total,z},Alternatives@@loops]||
   !And@@MapThread[epsOrderZero[dot[#1,#1]-#2]&,{cm,d["InversePropagators"][[particleSlots]]}],
  cutFamilyFail["MasslessMeasuredPhaseSpaceRequired"]];
 tagIndex=SelectFirst[Range[3],epsOrderZero[cm[[#]]-tag]&,None];
 If[tagIndex===None,cutFamilyFail["MeasuredParticleRoutingNotEstablished"]];
 s=dot[total,total];j=2dot[p,total];
 If[!cutConvergenceProve[s>0&&j>0&&0<z<1,assumptions]||
  !epsOrderZero[d["InversePropagators"][[First[measurementSlots]]]-(2dot[p,tag]-j z)],
  cutFamilyFail["NormalizedPhysicalNullFractionRequired"]];
 ordered=Join[{tagIndex},Complement[Range[3],{tagIndex}]];
 rows=cutOrderVector[#,all]&/@Join[cm[[Take[ordered,2]]],{p,total}];
 If[!MatrixQ[rows,exactRationalQ]||Dimensions[rows]=!={4,4}||Det[rows]===0,
  cutFamilyFail["IndependentRationalMeasuredMomentumRoutingRequired"]];
 inverse=Inverse[rows];
 {cp,ct,ck1,ck2,ck3,cz}=Table[Unique["measuredMomentum"],{6}];
 chartMomenta={ck1,ck2,cp,ct};
 parameters=Lookup[request,"Parameters",Table[Unique["phaseSpaceParameter"],{3}]];
 chart=FeynFacet`ConstructMeasuredThreeParticlePhaseSpace[<|
  "ReferenceMomentum"->cp,"TotalMomentum"->ct,"ParticleMomenta"->{ck1,ck2,ck3},
  "InvariantMassSquared"->s,"ReferenceProjection"->j/2,"MeasurementVariable"->cz,
  "DimensionalRegulator"->e,"Parameters"->parameters,
  "AngularAxis"->Lookup[request,"AngularAxis","ReferenceMomentum"],
  "AngularFractionSymbol"->Lookup[request,"AngularFractionSymbol",Unique["angularFraction"]],
  "Assumptions"->assumptions&&0<cz<1|>];
 If[FailureQ[chart],Return[chart]];
 chartRules=chart["ScalarProductRules"]/.cz->z;
 toChart[a_]:=(cutOrderVector[a,all].inverse).chartMomenta;
 cores=d["InversePropagators"]/.FeynCalc`Pair[FeynCalc`Momentum[a_,___],FeynCalc`Momentum[b_,___]]:>
  (FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[toChart[a],toChart[b]]]]/.chartRules);
 cores=Factor/@cores;
 rationalChartRules=chart["RationalScalarProductRules"]/.cz->z;
 rationalCores=d["InversePropagators"]/.FeynCalc`Pair[FeynCalc`Momentum[a_,___],FeynCalc`Momentum[b_,___]]:>
  (FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[toChart[a],toChart[b]]]]/.rationalChartRules);
 rationalCores=Factor/@rationalCores;

 If[!AllTrue[cores[[cuts]],epsOrderZero]||!FreeQ[cores,_FeynCalc`Pair|_FeynCalc`Momentum],
  cutFamilyFail["MeasuredChartCutIdentityFailed"]];
 ordinary=Complement[Range[Length[powers]],cuts];
 integrand=Times@@(If[powers[[#]]===0,1,cores[[#]]^-powers[[#]]]&/@ordinary);
 If[!FreeQ[integrand,Indeterminate|_DirectedInfinity],
  cutFamilyFail["MeasuredChartInteriorDenominatorRequired"]];
 loopRoute=Table[Coefficient[m,k],{m,cm[[Take[ordered,2]]]},{k,loops}];
 routingDet=Abs[Det[loopRoute]];
 If[routingDet===0,cutFamilyFail["IndependentParticleLoopRoutingRequired"]];
 standardMeasure=(2Pi)^(3-2d["Dimension"])j;
 normalization=Cancel[d["MasterIntegralPrefactor"]d["MeasurePrefactor"]/standardMeasure]/routingDet^d["Dimension"];
 measure=(chart["MeasureDensity"]/.cz->z)normalization;
 certificate=Catch[cutIntegralConvergenceCertificate[d],"EpsilonOrders"];
 If[FailureQ[certificate],Return[certificate]];
 <|"DataType"->"MeasuredThreeParticleIntegral","MasterIntegral"->d["MasterIntegral"],
  "Definition"->d,"Parameters"->parameters,"DimensionalRegulator"->e,
  "MeasurementVariable"->z,"InvariantMassSquared"->s,"ReferenceProjectionTwice"->j,
  "ScalarIntegrand"->integrand,"MeasureDensity"->measure,
  "MeasuredPhaseSpaceVolume"->normalization(chart["MeasuredPhaseSpaceVolume"]/.cz->z),
  "NormalizedMeasureFactors"->chart["NormalizedMeasureFactors"],
  "BetaShapes"->chart["BetaShapes"],"ParameterDomain"->chart["ParameterDomain"],
  "KinematicConditions"->assumptions,"InversePropagatorExpressions"->cores,
  "RationalInversePropagatorExpressions"->rationalCores,
  "AngularAxis"->chart["AngularAxis"],"AngularFractionSymbol"->chart["AngularFractionSymbol"],
  "AngularFractionExpression"->chart["AngularFractionExpression"],
  "RegularMeasureFactor"->(chart["RegularMeasureFactor"]/.cz->z),
  "OrdinaryIndices"->ordinary,"OrdinaryPowers"->powers[[ordinary]],
  "ParticleOrdering"->ordered,"MomentumRoutingMatrix"->rows,
  "ParticleLoopRoutingDeterminant"->routingDet,"MeasureConversionFactor"->normalization,
  "ConvergenceCertificate"->certificate,
  "OrdinaryPrescriptionConvention"->"Defined by the common high-dimensional convergence domain and meromorphic continuation.",
  "Scope"->"Three unit massless particle cuts and one unit null-fraction measurement, scalar integrands invariant under rotations fixing the external plane."|>
 ],"CutFamily"];
End[];EndPackage[];
