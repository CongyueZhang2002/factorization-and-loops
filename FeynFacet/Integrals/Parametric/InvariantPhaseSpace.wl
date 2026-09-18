(* Scalar massless decay coordinates. Overall spatial rotations are integrated.
   Four-body phase space is factored into Q -> P12 P34 and two massless decays.
   No amplitude, observable, identical-state factor or measurement delta is included. *)
BeginPackage["FeynFacet`"];
MasslessInvariantPhaseSpaceCoordinates::usage="MasslessInvariantPhaseSpaceCoordinates[particles,total,s,epsilon,parameters] returns physical unit-interval coordinates, pair invariants and the standard Lorentz-invariant phase-space density for two, three or four massless final particles from one timelike source. It integrates overall rotations; additional external directions require a different representation. Four-body coordinates use two cluster masses, two polar angles and one relative azimuth. This is an integration representation, not an evaluated master integral.";
Begin["`Private`"];
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
 pairs=Subsets[Range[n],{2}];gram=ConstantArray[0,{n,n}];
 Do[gram[[Sequence@@pairs[[i]]]]=invariants[[i]]/2;
    gram[[Sequence@@Reverse[pairs[[i]]]]]=invariants[[i]]/2,{i,Length[pairs]}];
 rules=Join[Flatten[Table[FeynCalc`FCI[FeynCalc`SPD[particles[[i]],particles[[j]]]]->gram[[i,j]],{i,n},{j,i,n}]],
   Table[FeynCalc`FCI[FeynCalc`SPD[total,particles[[i]]]]->Total[gram[[i]]],{i,n}],
   {FeynCalc`FCI[FeynCalc`SPD[total]]->s}];
 density=radial Times@@angular;
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
MasslessInvariantPhaseSpaceCoordinates[___]:=Failure["MasslessDecayCoordinateArgumentsRequired",<||>];
End[];EndPackage[];
