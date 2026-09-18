(* Scalar massless decay coordinates. Overall spatial rotations are integrated.
   Four-body phase space is factored into Q -> P12 P34 and two massless decays.
   No amplitude, observable, identical-state factor or measurement delta is included. *)
BeginPackage["FeynFacet`"];
MasslessInvariantPhaseSpaceCoordinates::usage="MasslessInvariantPhaseSpaceCoordinates[particles,total,s,epsilon,parameters] returns physical unit-interval coordinates, pair invariants and the standard Lorentz-invariant phase-space density for two, three or four massless final particles from one timelike source. It integrates overall rotations; additional external directions require a different representation. Four-body coordinates use two cluster masses, two polar angles and one relative azimuth. This is an integration representation, not an evaluated master integral.";
MasslessPairPhaseSpaceCoordinates::usage="MasslessPairPhaseSpaceCoordinates[{p1,p2,p3,p4},q,s,epsilon,{z,x,y,a,b}] resolves the first two labeled particles in massless four-body phase space. z is their rest-frame pair angle, x their first energy fraction and y the second energy coordinate; a,b are the recoil decay angles. Overall orientations and both parity sheets are integrated, so only scalar-product observables are supported. It retains the physical recoil geometry and absolute dimensional measure; singular endpoints and moving collinear loci are not resolved or integrated.";
Begin["`Private`"];
masslessInvariantCoordinateRecord[particles_,total_,s_,e_,parameters_,invariants_,density_,radial_,angular_,method_]:=Module[
 {n=Length[particles],pairs,gram,rules},
 pairs=Subsets[Range[n],{2}];gram=ConstantArray[0,{n,n}];
 Do[gram[[Sequence@@pairs[[i]]]]=invariants[[i]]/2;
    gram[[Sequence@@Reverse[pairs[[i]]]]]=invariants[[i]]/2,{i,Length[pairs]}];
 rules=Join[Flatten[Table[FeynCalc`FCI[FeynCalc`SPD[particles[[i]],particles[[j]]]]->gram[[i,j]],{i,n},{j,i,n}]],
   Table[FeynCalc`FCI[FeynCalc`SPD[total,particles[[i]]]]->Total[gram[[i]]],{i,n}],
   {FeynCalc`FCI[FeynCalc`SPD[total]]->s}];
 <|"Format"->"FeynFacet-InvariantPhaseSpaceCoordinates","Method"->method,
   "FinalMomenta"->particles,"TotalMomentum"->total,"Scale"->s,"DimensionalRegulator"->e,
   "Parameters"->parameters,"Bounds"->({#,0,1}&/@parameters),
   "PhysicalDomain"->(s>0&&And@@(0<#<1&/@parameters)),
   "AngularConvergenceCondition"->Re[e]<1/2,"ScalarProductRules"->rules,
   "PairInvariants"->AssociationThread[pairs,invariants],"GramMatrix"->gram,
   "EnergyFractions"->(2Total[#]/s&/@gram),"Density"->density,
   "RadialDensity"->radial,"NormalizedAngularDensities"->angular,
   "Normalization"->"Product d^(D-1)p/((2 Pi)^(D-1) 2E) times (2 Pi)^D delta^D(Q-sum p)",
   "MeasurementIncluded"->False,"IntegralEvaluated"->False|>
];
MasslessInvariantPhaseSpaceCoordinates[particles_List,total_Symbol,s_,e_Symbol,parameters_List]:=Module[
 {n=Length[particles],u,v,a,b,t,x,y,c1,c2,cp,lambda,cross,invariants,pairs,gram,rules,
  density,radial,angular,constant,alpha=1-e,method},
 If[!MemberQ[{2,3,4},n]||!MatchQ[particles,{_Symbol..}]||
   !DuplicateFreeQ[Join[particles,{total,e},parameters]]||!MatchQ[parameters,{_Symbol...}]||
   Length[parameters]=!=Switch[n,2,0,3,2,4,5]||
   !FreeQ[s,Alternatives@@Join[particles,{total,e},parameters]],
  Return[Failure["IndependentMasslessDecayCoordinatesRequired",<||>]]];
 Switch[n,
  2,
   invariants={s};radial=FeynFacet`MasslessPhaseSpaceVolume[2,s,e];angular={};
   method="TwoBodyInvariantConstant",
  3,
   {u,v}=parameters;invariants=s{u,(1-u)v,(1-u)(1-v)};
   radial=FeynFacet`MasslessPhaseSpaceVolume[3,s,e]u^(alpha-1)(1-u)^(2alpha-1)/Beta[alpha,2alpha];
   angular={v^(alpha-1)(1-v)^(alpha-1)/Beta[alpha,alpha]};
   method="ThreeBodyDirichletCoordinates",
  4,
   {u,v,a,b,t}=parameters;x=u^2;y=(1-u)^2v^2;
   {c1,c2,cp}={1-2a,1-2b,1-2t};
   lambda=(1-(u+(1-u)v)^2)(1-(u-(1-u)v)^2);
   cross=8u(1-u)v Sqrt[a(1-a)b(1-b)]cp;
   invariants=s{x,
    ((1-x-y)(1+c1 c2)+Sqrt[lambda](c1+c2)-cross)/4,
    ((1-x-y)(1-c1 c2)+Sqrt[lambda](c1-c2)+cross)/4,
    ((1-x-y)(1-c1 c2)+Sqrt[lambda](-c1+c2)+cross)/4,
    ((1-x-y)(1+c1 c2)-Sqrt[lambda](c1+c2)-cross)/4,y};
   (* ds12 ds34 = s^2 4u(1-u)^2 v du dv. Each cluster decay
      has its complete angular volume; the remaining angular measures are
      normalized, including the noninteger-dimensional relative azimuth. *)
   constant=FeynFacet`MasslessPhaseSpaceVolume[2,1,e];
   radial=constant^3 s^(2-3e)/(2Pi)^2 4u(1-u)^2v*
     x^-e y^-e lambda^(1/2-e);
   angular={a^-e(1-a)^-e/Beta[1-e,1-e],b^-e(1-b)^-e/Beta[1-e,1-e],
     t^(-1/2-e)(1-t)^(-1/2-e)/Beta[1/2-e,1/2-e]};
   method="TwoClusterDecayCoordinates"
 ];
 density=radial Times@@angular;
 masslessInvariantCoordinateRecord[particles,total,s,e,parameters,invariants,density,radial,angular,method]
];
MasslessInvariantPhaseSpaceCoordinates[___]:=Failure["MasslessDecayCoordinateArgumentsRequired",<||>];
MasslessPairPhaseSpaceCoordinates[particles_List,total_Symbol,s_,e_Symbol,parameters_List]:=Module[
 {z,x,y,a,b,x2,rho,d,k,zeta,cpsi,spsi,c,h,aa,bb,p23,invariants,constant,radial,angular,record,energy1,energy2},
 If[!MatchQ[particles,{_Symbol,_Symbol,_Symbol,_Symbol}]||
   !MatchQ[parameters,{_Symbol,_Symbol,_Symbol,_Symbol,_Symbol}]||
   !DuplicateFreeQ[Join[particles,{total,e},parameters]]||
   !FreeQ[s,Alternatives@@Join[particles,{total,e},parameters]],
  Return[Failure["IndependentFourParticlePairCoordinatesRequired",<||>]]];
 {z,x,y,a,b}=parameters;d=1-z x;x2=(1-x)y/d;rho=(1-x)(1-y);k=1-z+z rho;
 zeta=z rho/k;cpsi=1-2zeta;spsi=2Sqrt[z(1-z)rho]/k;
 aa=s x k/(2d);bb=s(1-x)y/2;c=1-2a;h=1-2b;
 p23=bb(1-c cpsi-2Sqrt[a(1-a)]spsi h)/2;
 invariants={s z x x2,2aa a,2aa(1-a),2p23,2(bb-p23),s rho};
 constant=FeynFacet`MasslessResolvedPairDensityFactor[4-2e]*FeynFacet`MasslessPhaseSpaceVolume[2,1,e];
 radial=constant s^(2-3e)z^-e(1-z)^-e x^(1-2e)(1-x)^(2-3e)*
   y^(1-2e)(1-y)^-e d^(-2+2e);
 angular={a^-e(1-a)^-e/Beta[1-e,1-e],b^(-1/2-e)(1-b)^(-1/2-e)/Beta[1/2-e,1/2-e]};
 record=masslessInvariantCoordinateRecord[particles,total,s,e,parameters,invariants,
   radial Times@@angular,radial,angular,"TwoResolvedParticlesAndRecoilDecay"];
 energy1=2FeynCalc`FCI[FeynCalc`SPD[total,particles[[1]]]]/s;
 energy2=2FeynCalc`FCI[FeynCalc`SPD[total,particles[[2]]]]/s;
 Join[record,<|"ResolvedPair"->Take[particles,2],"PairAngleVariable"->z,
   "RecoilMomentum"->(total-Total[Take[particles,2]]),"RecoilMassFraction"->rho,
   "EnergyMapDenominator"->d,"RecoilAngleDenominator"->k,
   "RecoilAngleFraction"->zeta,"RecoilAngleCosine"->cpsi,"RecoilAngleSine"->spsi,
   "ResolvedRecoilProducts"->{aa,bb},"Prefactor"->constant,
   "EnergyJacobian"->(1-x)/d,"InverseEnergyMap"->{x->energy1,y->energy2(1-z energy1)/(1-energy1)},
   "GramDeterminant"->-s^4 x^2 x2^2 z(1-z)rho a(1-a)b(1-b),
   "MovingCollinearLoci"->{<|"ParticlePair"->particles[[{2,3}]],"Equations"->{b==0,a==zeta}|>,
     <|"ParticlePair"->particles[[{2,4}]],"Equations"->{b==1,a==1-zeta}|>},
   "ScalarProductObservablesOnly"->True,"OrientationSignRetained"->False,
   "LabeledParticles"->True,"EndpointResolved"->False,
   "Scope"->"Generic scalar invariant data with residual angular multiplicities integrated. Parity-sensitive oriented observables, dotted particle cuts and singular endpoint limits need additional constructions."|>]
];
MasslessPairPhaseSpaceCoordinates[___]:=Failure["MasslessPairCoordinateArgumentsRequired",<||>];
End[];EndPackage[];
