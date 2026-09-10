(* Analytic massless one-loop scalar integrals, detected from momentum
   geometry. Normalization is d^D l/(i pi^(D/2)) and its conjugate.
   Bubbles are exact Gamma expressions; the on-shell box is known through
   epsilon^0. The finite-order contract rejects deeper box requests. *)
FeynFacet`EvaluateOneLoopIntegral::usage="EvaluateOneLoopIntegral[definition,{low,high}] returns explicit Laurent coefficients for a massless one-loop bubble, triangle with at least one null external leg, or on-shell scalar box, recognized without family names. Bubbles allow arbitrary positive powers and orders; unit-power boxes currently support high<=0. Causal phases follow the declared loop prescription and kinematic conditions.";
oneLoopCausalLog[value_,prescription_,conditions_]:=Which[
 TrueQ[FullSimplify[value>0,Assumptions->conditions]],Log[value]-I Pi prescription,
 TrueQ[FullSimplify[value<0,Assumptions->conditions]],Log[-value],
 True,epsOrderFail["OneLoopCausalDomainRequired",<|"Invariant"->value,"Conditions"->conditions|>]];
FeynFacet`EvaluateOneLoopIntegral[definition_Association,{low_Integer,high_Integer}]:=Catch[Module[
 {loops,ell,e,dim,prescription,powers,active,momenta,kin,conditions,lambda,shifts,
  normal,factor,masses,distances,nonzero,channel,aa,bb,expr,poly,coeffs,method,
  exact=True,ss,tt,ls,lt,rGamma,lower,nonzeroPairs},
 loops=Lookup[definition,"LoopMomenta",{}];e=Lookup[definition,"DimensionalRegulator",None];
 dim=Lookup[definition,"Dimension",None];powers=Lookup[definition,"PropagatorPowers",{}];
 If[Length[loops]=!=1||Lookup[definition,"CutIndices",None]=!={}||low>high||
  !MatchQ[e,_Symbol]||!TrueQ[Expand[dim-(4-2e)]===0]||!VectorQ[powers,IntegerQ]||AnyTrue[powers,#<0&],
  epsOrderFail["ScalarOneLoopIntegralRequired"]];
 ell=First[loops];prescription=Lookup[definition,"Prescription",{}];
 If[!MatchQ[prescription,{1}|{-1}],epsOrderFail["OneLoopPrescriptionRequired"]];prescription=First[prescription];
 active=Select[Range[Length[powers]],powers[[#]]>0&];
 If[!MemberQ[{2,3,4},Length[active]]||!AllTrue[definition["PropagatorTypes"][[active]],#==="QuadraticLorentzian"&],
  epsOrderFail["OneLoopAnalyticGeometryUnsupported"]];
 momenta=definition["PropagatorMomenta"][[active]];kin=definition["KinematicRules"];
 conditions=Lookup[definition,"KinematicConditions",True];
 lambda=Coefficient[#,ell]& /@ momenta;
 If[!AllTrue[lambda,MatchQ[#,_Integer|_Rational]&&#=!=0&],epsOrderFail["LinearOneLoopRoutingRequired"]];
 shifts=MapThread[Expand[#1/#2-ell]&,{momenta,lambda}];
 If[!FreeQ[shifts,ell],epsOrderFail["LinearOneLoopRoutingRequired"]];
 masses=MapThread[Expand[(FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[#1]]]/.kin)-#2]&, 
   {momenta,definition["InversePropagators"][[active]]}];
 If[!AllTrue[masses,epsOrderZero],epsOrderFail["MasslessOneLoopPropagatorsRequired"]];
 normal=Simplify[definition["MeasurePrefactor"]prescription I Pi^(dim/2)];
 factor=definition["MasterIntegralPrefactor"]normal (Times@@MapThread[#1^(-2#2)&,{lambda,powers[[active]]}]);
 distances=Flatten[Table[FullSimplify[FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[shifts[[i]]-shifts[[j]]]]]/.kin,Assumptions->conditions],
   {i,Length[shifts]},{j,i+1,Length[shifts]}]];
 If[Length[active]<=3,
  method=If[Length[active]===2,"MasslessBubbleGammaFormula","MasslessTriangleGammaFormula"];
  expr=factor oneLoopSingleScaleGamma[distances,powers[[active]],dim,prescription,conditions],
  If[!AllTrue[powers[[active]],#===1&]||high>0,epsOrderFail["OnShellBoxKnownOnlyThroughFiniteOrder"]];
  nonzero=Select[distances,!epsOrderZero[#]&];
  nonzeroPairs=Pick[Subsets[Range[Length[shifts]],{2}],(!epsOrderZero[#]& /@ distances),True];
  If[Length[nonzero]=!=2||Length[Union[Flatten[nonzeroPairs]]]=!=4,epsOrderFail["FourMasslessExternalLegsRequired"]];
  {ss,tt}=nonzero;ls=oneLoopCausalLog[ss,prescription,conditions];lt=oneLoopCausalLog[tt,prescription,conditions];
  rGamma=Gamma[1+e]Gamma[1-e]^2/Gamma[1-2e];
  expr=factor 2rGamma/(ss tt)((Exp[-e ls]+Exp[-e lt])/e^2-(ls-lt)^2/2-Pi^2/2);
  exact=False;method="MasslessOnShellBoxLaurentFormula"];
 poly=Normal[Series[expr,{e,0,high}]];
 If[!FreeQ[poly,_SeriesData|_Series|_SeriesCoefficient|_Integrate|_Failure|Indeterminate|_DirectedInfinity],epsOrderFail["ExplicitOneLoopLaurentCoefficientsRequired"]];
 lower=Min[low,If[Length[active]>=3,-2,-1]];
 coeffs=Association@Table[j->Coefficient[Expand[e^-lower poly],e,j-lower],{j,lower,high}];
 <|"MasterIntegral"->definition["MasterIntegral"],"DimensionalRegulator"->e,
  "LaurentLowerBound"->lower,"KnownThroughOrder"->high,"RequestedRange"->{low,high},
  "Coefficients"->coeffs,"ExactInEpsilon"->TrueQ[expr===0],
  "AnalyticExpression"->If[exact,expr,Missing["FiniteLaurentExpression"]],
  "EvaluationMethod"->method,"LoopPrescription"->prescription,
  "Normalization"->"d^D l/(i pi^(D/2)), conjugated for negative prescription"|>
 ],"EpsilonOrders"];

(* Feynman-parameter Dirichlet integral. A single nonzero squared distance
   makes the second Symanzik polynomial one monomial. This covers arbitrary
   positive integer powers of bubbles and single-off-shell triangles. *)
oneLoopSingleScaleGamma[distances_List,powers_List,dim_,prescription_,conditions_]:=Module[
 {count=Length[powers],pairs,active,indices,alpha,total,shift},
 If[!MemberQ[{2,3},count]||Length[distances]=!=Binomial[count,2]||
  !VectorQ[powers,IntegerQ[#]&&#>0&],epsOrderFail["SingleScaleScalarGeometryRequired"]];
 pairs=Subsets[Range[count],{2}];active=Select[Range[Length[distances]],!epsOrderZero[distances[[#]]]&];
 If[active==={},Return[0]];
 If[count===3&&Length[active]===2&&powers==={1,1,1},
  Return[oneLoopTwoScaleTriangleGamma[distances[[active]],dim,prescription,conditions]]];
 If[Length[active]=!=1,epsOrderFail["SingleOffShellInvariantRequired"]];
 indices=pairs[[First[active]]];total=Total[powers];shift=dim/2-total;
 alpha=powers+Table[If[MemberQ[indices,i],shift,0],{i,count}];
 (-1)^total Exp[shift oneLoopCausalLog[distances[[First[active]]],prescription,conditions]]*
 Gamma[total-dim/2] Times@@(Gamma/@alpha)/(Times@@(Gamma/@powers) Gamma[dim-total])
];

(* Integrating the two-variable Dirichlet representation first along the
   edge between the two nonzero invariants gives a divided difference.
   Its coincident limit is taken analytically, before numerical evaluation. *)
oneLoopTwoScaleTriangleGamma[{a_,b_},dim_,prescription_,conditions_]:=Module[
 {e=(4-dim)/2,la,lb,rGamma},
 la=oneLoopCausalLog[a,prescription,conditions];
 lb=oneLoopCausalLog[b,prescription,conditions];
 rGamma=Gamma[1+e]Gamma[1-e]^2/Gamma[1-2e];
 If[TrueQ[FullSimplify[a==b,Assumptions->conditions]],
  rGamma/e Exp[(-1-e)la],
  rGamma/e^2 (Exp[-e la]-Exp[-e lb])/(a-b)]
];
FeynFacet`EvaluateOneLoopScalarFunctions::usage="EvaluateOneLoopScalarFunctions[expression,epsilon,conditions] evaluates massless FeynCalc B0 and C0 functions with at least one null external leg exactly in epsilon. It includes the conversion from FeynCalc's 1/(i pi^2) convention to the normalized loop Gamma formulas.";
FeynFacet`EvaluateOneLoopScalarFunctions[expression_,e_Symbol,conditions_]:=Catch[Module[{objects,rules,result},
 objects=DeleteDuplicates[Cases[expression,_FeynCalc`B0|_FeynCalc`C0,{0,Infinity}]];
 rules=Table[obj->Switch[obj,
  FeynCalc`B0[_,0,0],Pi^(-e) oneLoopSingleScaleGamma[{obj[[1]]},{1,1},4-2e,1,conditions],
  FeynCalc`C0[_,_,_,0,0,0],Pi^(-e) oneLoopSingleScaleGamma[Take[List@@obj,3],{1,1,1},4-2e,1,conditions],
  _,epsOrderFail["MasslessScalarLoopFunctionRequired",<|"Function"->obj|>]],{obj,objects}];
 result=expression/.rules;
 If[!FreeQ[result,_FeynCalc`A0|_FeynCalc`B0|_FeynCalc`B1|_FeynCalc`C0|_FeynCalc`D0|_FeynCalc`PaVe|_FeynCalc`GenPaVe],
  epsOrderFail["UnsupportedScalarLoopFunction"]];
 result
],"EpsilonOrders"];

(* After scalar contraction, evanescent numerator powers may be averaged
   in the orthogonal complement of the physical external momentum span.
   All propagators depend on full D-dimensional products; this is a
   rotational tensor identity, not setting the evanescent square to zero. *)
oneLoopAveragePhysicalNumerator[expression_,loop_Symbol,external_List,kinematics_List,conditions_]:=Module[
 {gram,products,parallel,transverse,kappa=Unique["evanescentSquare$"],rational,num,den,rank=Length[external],value},
 If[With[{loopValue=loop},FreeQ[expression,FeynCalc`Momentum[loopValue]]],Return[expression]];
 If[!DuplicateFreeQ[external]||!MatchQ[external,{__Symbol}]||MemberQ[external,loop]||rank>4,
  epsOrderFail["IndependentPhysicalExternalLoopBasisRequired"]];
 gram=Table[Factor[FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[a,b]]]/.kinematics],{a,external},{b,external}];
 If[!TrueQ[FullSimplify[Det[gram]!=0,Assumptions->conditions]],epsOrderFail["NondegenerateExternalLoopGramRequired"]];
 products=FeynCalc`FCI[FeynCalc`SPD[loop,#]]&/@external;
 parallel=Factor[products.Inverse[gram].products];
 transverse=FeynCalc`FCI[FeynCalc`SPD[loop]]-parallel;
 value=With[{loopValue=loop},
  expression/.HoldPattern[FeynCalc`Pair[FeynCalc`Momentum[loopValue],FeynCalc`Momentum[loopValue]]]->
   (FeynCalc`FCI[FeynCalc`SPD[loop]]-kappa)];
 If[!FreeQ[value,FeynCalc`Momentum[loop]],epsOrderFail["UnresolvedPhysicalLoopNumerator"]];
 If[!oneLoopTransverseInvariantQ[value,loop,external],epsOrderFail["TransverseInvariantLoopWeightRequired"]];
 rational=Together[value];num=Numerator[rational];den=Denominator[rational];
 If[!FreeQ[den,kappa]||!PolynomialQ[num,kappa],epsOrderFail["PolynomialEvanescentLoopNumeratorRequired"]];
 Factor[Sum[Coefficient[num,kappa,a] transverse^a Pochhammer[(D-4)/2,a]/Pochhammer[(D-rank)/2,a],
  {a,0,Max[0,Exponent[num,kappa]]}]/den]
];

(* An unlisted momentum in a full-D product also breaks the scalar
   transverse average. Propagator shifts and numerator products must
   both lie in the declared loop/external linear span. Cut measurements
   and mixed prescriptions need a separate support argument. *)
oneLoopTransverseInvariantQ[expression_,loop_Symbol,external_List]:=Module[{allowed,momenta},
 allowed=Prepend[external,loop];
 If[!FreeQ[expression,_Cut|_FeynCalc`Eps|_FeynCalc`LorentzIndex|_FeynCalc`CartesianIndex|
  _FeynCalc`DiracGamma|_FeynCalc`DiracTrace|_FeynCalc`StandardPropagatorDenominator|
  _FeynCalc`GenericPropagatorDenominator|_FeynCalc`CartesianPropagatorDenominator],Return[False]];
 momenta=DeleteDuplicates[Cases[expression,_FeynCalc`Momentum,{0,Infinity}]];
 AllTrue[momenta,Function[momentum,Module[{vector=First[momentum],coordinates},
  coordinates=Coefficient[Expand[vector],#]&/@allowed;
  AllTrue[coordinates,MatchQ[#,_Integer|_Rational]&]&&
   TrueQ[Expand[vector-coordinates.allowed]===0]]]]
];

(* Exact massless triangle IBPs reduce the scalar basis before expanding
   epsilon. This also exposes cancellations of reduction poles. *)
FeynFacet`ReduceMasslessScalarTriangles::usage=
 "ReduceMasslessScalarTriangles[expression,epsilon,conditions] applies exact bubble-triangle identities for massless C0 functions with a null external leg, retaining the shared causal prescription and scalar-function normalization.";
FeynFacet`ReduceMasslessScalarTriangles[expression_,e_Symbol,conditions_]:=Catch[Module[
 {objects,rules,values,active,a,b},
 objects=DeleteDuplicates[Cases[expression,_FeynCalc`C0,{0,Infinity}]];
 rules=Table[
  If[Length[obj]=!=6||Take[List@@obj,-3]=!={0,0,0},
   epsOrderFail["MasslessTriangleRequired"]];
  values=Take[List@@obj,3];active=Select[values,!TrueQ[FullSimplify[#==0,Assumptions->conditions]]&];
  obj->Switch[Length[active],
   0,0,
   1,a=First[active];(1-2e)/(e a)FeynCalc`B0[a,0,0],
   2,{a,b}=active;
    If[TrueQ[FullSimplify[a==b,Assumptions->conditions]],-(1-2e)/a FeynCalc`B0[a,0,0],
     (1-2e)/(e(a-b))(FeynCalc`B0[a,0,0]-FeynCalc`B0[b,0,0])],
   _,epsOrderFail["NullExternalTriangleLegRequired"]],
  {obj,objects}];
 expression/.rules
],"EpsilonOrders"];
