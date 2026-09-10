(* Inclusive massless phase space and one massless eikonal denominator.
   For N particles and alpha=(D-2)/2, the energy fraction y is beta
   distributed with parameters (2 alpha,(N-2) alpha), and the polar
   fraction z with (alpha,alpha). For a lightlike external P,
   2 P.k = (2 P.Q) y z. Their inverse moments give the Gamma ratio below,
   first in a convergence domain and then by dimensional continuation. *)

ClearAll[miRepElementaryPhaseSpace,miRepMeasuredPhaseVolume];

(* A null-reference fraction of one massless particle has a universal Beta
   density for any multiplicity. The typed definition supplies the measure;
   measurement dots differentiate the density with all external data fixed.
   Particle dots are deliberately not evaluated by this massless formula. *)
miRepMeasuredPhaseVolume[definition_]:=Module[
 {source,cuts,particleCuts,measurement,powers,loops,cm,kin,dim,e,n,q,p,tag,z,j,s,
  dot,coefficients,chosen,det,standardMeasure,ratio,u,value,derivativeOrder},
 source=Lookup[definition,"SourceCutDefinition",<||>];
 measurement=Lookup[definition,"MeasurementCutIndices",{}];
 particleCuts=Lookup[definition,"ParticleCutIndices",{}];cuts=definition["CutIndices"];
 powers=definition["PropagatorPowers"];loops=definition["LoopMomenta"];cm=definition["OrientedCutMomenta"];
 n=Length[cm];kin=definition["KinematicRules"];dim=definition["Dimension"];e=definition["DimensionalRegulator"];
 If[Length[measurement]=!=1||n=!=Length[loops]+1||n<2||
   !AllTrue[powers[[particleCuts]],#===1&]||powers[[First[measurement]]]<1||
   !AllTrue[Complement[Range[Length[powers]],cuts],powers[[#]]===0&]||
   !ContainsAll[Keys[source],{"ReferenceMomentum","TaggedMomentum","MeasurementVariable"}],
  Return[None]];
 {p,tag,z}=Lookup[source,{"ReferenceMomentum","TaggedMomentum","MeasurementVariable"}];
 q=Expand[Total[cm]];
 dot[a_,b_]:=Cancel[FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[a,b]]]/.kin];
 If[!FreeQ[{q,p,z},Alternatives@@loops]||q===0||!AnyTrue[cm,Expand[#-tag]===0&]||
   !epsOrderZero[dot[p,p]]||
   !And@@MapThread[epsOrderZero[dot[#1,#1]-#2]&,
     {cm,definition["InversePropagators"][[particleCuts]]}],Return[None]];
 j=2dot[p,q];s=dot[q,q];
 If[!miRepPositiveQ[j,definition]||!miRepPositiveQ[s,definition]||
   !TrueQ[FullSimplify[0<z<1,Assumptions->definition["KinematicConditions"]]]||
   !epsOrderZero[definition["InversePropagators"][[First[measurement]]]-(2dot[p,tag]-j z)],
  Return[None]];
 coefficients=Table[Coefficient[m,k],{m,cm},{k,loops}];
 chosen=SelectFirst[Subsets[Range[n],{Length[loops]}],
   !epsOrderZero[Det[coefficients[[#]]]]&,None];
 If[chosen===None,Return[None]];
 det=Abs[Det[coefficients[[chosen]]]];
 standardMeasure=(2Pi)^(n-Length[loops]dim)j;
 ratio=definition["MasterIntegralPrefactor"]definition["MeasurePrefactor"]/(standardMeasure det^dim);
 derivativeOrder=powers[[First[measurement]]]-1;u=Unique["measuredFraction$"];
 value=FeynFacet`MasslessMeasuredPhaseSpace[n,s,u,e];
 value=ratio (D[value,{u,derivativeOrder}]/(j^derivativeOrder derivativeOrder!)/.u->z);
 <|"Representation"->"UnitCube","Terms"->{<|"IntegrationVariables"->{},"Prefactor"->value|>},
  "ConstructionMethod"->"Exact massless measured phase-space Beta density, with finite derivatives of the independent measurement coordinate.",
  "TotalMomentumSquared"->s,"MeasurementJacobian"->j,"MeasurementDerivativeOrder"->derivativeOrder,
  "PhaseSpaceRoutingDeterminant"->det,
  "EvaluationScope"->"Generic interior measured values; endpoint distributions are obtained from the regulated density by the common endpoint expansion."|>
];



miRepElementaryPhaseSpace[definition_] := Module[
  {volume, cuts, powers, active, row, a, cutMomenta, loops, kin, q, p,
   lambda, qCoefficients, cutCoefficients, selected, scale, dim, alpha, particles,
   dot, original, result = None, raised},
  If[Lookup[definition,"MeasurementCutIndices",{}]=!={},
    Return[miRepMeasuredPhaseVolume[definition]]];
  volume = miRepPhaseVolume[definition];
  If[AssociationQ[volume], Return[volume]];
  volume = miRepTwoBodyAngular[definition];
  If[AssociationQ[volume], Return[volume]];
  cuts = definition["CutIndices"]; powers = definition["PropagatorPowers"];
  active = Select[Complement[Range[Length[powers]], cuts], powers[[#]] =!= 0 &];
  raised = Select[cuts, powers[[#]] === 2 &];
  If[active === {} && Length[raised] === 1 &&
      AllTrue[Complement[cuts, raised], powers[[#]] === 1 &],
    volume = miRepPhaseVolume[Join[definition, <|
      "PropagatorPowers" -> ReplacePart[powers, First[raised] -> 1]|>]];
    If[AssociationQ[volume],
      dim = definition["Dimension"]; alpha = (dim - 2)/2;
      particles = Length[cuts];
      Return[Join[volume, <|"Terms" -> {
        <|"IntegrationVariables" -> {},
          "Prefactor" -> volume["Terms"][[1]]["Prefactor"] *
            -(particles alpha - 1) ((particles - 1) alpha - 1) /
              ((alpha - 1) volume["TotalMomentumSquared"])|>},
        "ConstructionMethod" -> "One cut-mass-squared derivative of the inclusive massless phase-space volume; the doubled cut is minus delta prime.",
        "ConvergenceCondition" -> Re[dim] > 4|>]]]];
  If[Length[active] =!= 1 || ! AllTrue[powers[[cuts]], # === 1 &],
    Return[None]];
  row = First[active]; a = powers[[row]];
  If[! IntegerQ[a] || definition["PropagatorTypes"][[row]] =!= "QuadraticLorentzian",
    Return[None]];
  original = definition["PropagatorMomenta"][[row]];
  loops = definition["LoopMomenta"]; kin = definition["KinematicRules"];
  cutMomenta = definition["OrientedCutMomenta"];
  dot[u_, v_] := Cancel[FeynCalc`ExpandScalarProduct[
    FeynCalc`FCI[FeynCalc`SPD[u, v]]] /. kin];
  If[! epsOrderZero[(dot[original, original] - definition["InversePropagators"][[row]]) /. kin],
    Return[None]];
  volume = miRepPhaseVolume[Join[definition, <|
    "PropagatorPowers" -> ReplacePart[powers, row -> 0]|>]];
  If[! AssociationQ[volume], Return[None]];
  q = Expand[Total[cutMomenta]];
  qCoefficients = Coefficient[original, #] & /@ loops;
  dim = definition["Dimension"]; alpha = (dim - 2)/2;
  particles = Length[cutMomenta];
  Do[
    cutCoefficients = Coefficient[cm, #] & /@ loops;
    selected = SelectFirst[Range[Length[loops]], cutCoefficients[[#]] =!= 0 &, None];
    If[selected === None, Continue[]];
    lambda = qCoefficients[[selected]]/cutCoefficients[[selected]];
    If[! MatchQ[lambda, _Integer | _Rational] || lambda === 0, Continue[]];
    p = Expand[original - lambda cm];
    If[! FreeQ[p, Alternatives@@loops] || p === 0 || ! epsOrderZero[dot[p, p]],
      Continue[]];
    scale = 2 lambda dot[q, p];
    If[! TrueQ[scale > 0 || scale < 0], Continue[]];
    result = Join[volume, <|"Terms" -> {
      <|"IntegrationVariables" -> {},
        "Prefactor" -> volume["Terms"][[1]]["Prefactor"] scale^-a *
          Gamma[particles alpha] Gamma[alpha - a] /
          (Gamma[particles alpha - a] Gamma[alpha])|>},
      "ConstructionMethod" -> "Exact beta moments of the energy and polar fractions for one lightlike eikonal denominator.",
      "LightlikeExternalMomentum" -> p, "SelectedCutMomentum" -> cm,
      "DenominatorScale" -> scale,
      "ConvergenceCondition" -> Re[alpha] > Max[0, a]|>];
    Break[],
    {cm, cutMomenta}];
  result
];

(* Two massless cut particles and up to two lightlike eikonal directions.
   Every propagator is recognized algebraically against both oriented cuts.
   The angular integral is the Gauss function, normalized by the two-body
   volume; coincident directions are one Beta moment with combined power. *)
miRepTwoBodyAngular[definition_] := Module[
 {cuts,powers,active,loops,cm,q,kin,dot,volume,rows={},original,cutCoefficients,
  lambda,p,scale,coreScale,found,alpha,eps,rho,angular,value,totalPower},
 cuts=definition["CutIndices"];powers=definition["PropagatorPowers"];
 loops=definition["LoopMomenta"];cm=definition["OrientedCutMomenta"];
 active=Select[Complement[Range[Length[powers]],cuts],powers[[#]]=!=0&];
 If[Length[loops]=!=1||Length[cuts]=!=2||!AllTrue[powers[[cuts]],#===1&]||
  !MemberQ[{1,2},Length[active]]||!AllTrue[powers[[active]],IntegerQ[#]&&#>0&]||
  !AllTrue[definition["PropagatorTypes"][[active]],#==="QuadraticLorentzian"&],Return[None]];
 kin=definition["KinematicRules"];q=Expand[Total[cm]];
 dot[u_,v_]:=Cancel[FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[u,v]]]/.kin];
 volume=miRepPhaseVolume[Join[definition,<|"PropagatorPowers"->ReplacePart[powers,((#->0)& /@ active)]|>]];
 If[!AssociationQ[volume],Return[None]];
 Do[
  original=definition["PropagatorMomenta"][[row]];found=None;
  If[!FreeQ[original,Complex],original=Expand[-I original]];
  coreScale=Cancel[definition["InversePropagators"][[row]]/dot[original,original]];
  If[!MatchQ[coreScale,_Integer|_Rational]||coreScale===0,Return[None,Module]];
  Do[
   cutCoefficients=Coefficient[cm[[j]],First[loops]];
   If[cutCoefficients===0,Continue[]];
   lambda=Coefficient[original,First[loops]]/cutCoefficients;
   If[!MatchQ[lambda,_Integer|_Rational]||lambda===0,Continue[]];
   p=Expand[original-lambda cm[[j]]];
   If[p===0||!FreeQ[p,First[loops]]||!epsOrderZero[dot[p,p]],Continue[]];
   scale=Cancel[coreScale lambda dot[p,q]];
   If[!miRepPositiveQ[scale^2,definition],Continue[]];
   found=<|"CutPosition"->j,"LightlikeMomentum"->p,"Scale"->scale,"Power"->powers[[row]]|>;Break[],{j,2}];
  If[found===None,Return[None]];AppendTo[rows,found],{row,active}];
 alpha=(definition["Dimension"]-2)/2;eps=(4-definition["Dimension"])/2;
 totalPower=Total[Lookup[rows,"Power"]];
 If[Length[rows]===1,
  rho=0,
  rho=Cancel[dot[rows[[1]]["LightlikeMomentum"],rows[[2]]["LightlikeMomentum"]]dot[q,q]/
    (2dot[rows[[1]]["LightlikeMomentum"],q]dot[rows[[2]]["LightlikeMomentum"],q])];
  If[rows[[1]]["CutPosition"] =!= rows[[2]]["CutPosition"],rho=Cancel[1-rho]]];
 (* Noncoincident higher powers need their own verified contiguous reduction. *)
 If[!epsOrderZero[rho]&&!AllTrue[Lookup[rows,"Power"],#===1&],Return[None]];
 angular=If[epsOrderZero[rho],
  Gamma[2alpha]Gamma[alpha-totalPower]/(2^totalPower Gamma[alpha]Gamma[2alpha-totalPower]),
  Gamma[2alpha]Gamma[alpha-rows[[1]]["Power"]]Gamma[alpha-rows[[2]]["Power"]]/
   (2^totalPower Gamma[alpha]^2 Gamma[2alpha-totalPower])
    Hypergeometric2F1[rows[[1]]["Power"],rows[[2]]["Power"],alpha,1-rho]];
 value=volume["Terms"][[1]]["Prefactor"] angular/(Times@@(# ["Scale"]^#["Power"]& /@ rows));
 Join[volume,<|"Terms"->{<|"IntegrationVariables"->{},"Prefactor"->value|>},
  "ConstructionMethod"->"Two-body lightlike angular integral in Beta and Gauss hypergeometric functions",
  "AngularDenominators"->rows,"AngularInvariant"->rho,
  "ConvergenceCondition"->Re[alpha]>totalPower,"AnalyticContinuation"->"Dimensional continuation from the convergent angular integral on the physical two-body phase space"|>]
];
