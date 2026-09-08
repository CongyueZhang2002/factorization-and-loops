(* Finite solutions in quadratures at an ordinary base point.
   All sums, epsilon convolutions and scalar integral definitions are constructed
   here. Reading the data never calls this constructor or enumerates words. *)
Begin["FeynFacet`Private`"];

Clear[solutionFail, solutionZero, solutionMatrixZero, solutionValuation,
  solutionLaurentCoefficients, solutionFlatness, solutionShareMatrix,
  solutionCoefficient, solutionConstruct, solutionWrite, solutionExplicitExpressionQ,
  solutionExpandedCoefficientsQ, solutionConstantDegreeRange, solutionBasisOrderBound, solutionRegulatorSeries, solutionNumericalZero, solutionGaugeChecks, solutionValidationPoints, solutionConnectionCoefficientConjugation];

solutionFail[tag_, data_:<||>] := Throw[Failure[tag, data], "FiniteSolution"];
solutionExplicitExpressionQ[z_] := Cases[z,
  h_[___] /; !MemberQ[{Plus,Times,Power,Rational,Complex,Log,Exp,
    Sin,Cos,Tan,Cot,Sec,Csc,ArcSin,ArcCos,ArcTan,ArcSinh,ArcCosh,ArcTanh,Sinh,Cosh,Tanh,
    Sqrt,Abs,Sign,Re,Im,Conjugate,Pi,E,List,
    EllipticK,EllipticE,EllipticPi,JacobiSN,JacobiCN,JacobiDN,
    Gamma,PolyGamma,PolyLog,Zeta,Hypergeometric2F1,HypergeometricPFQ,
    BesselJ,BesselY,BesselI,BesselK,AiryAi,AiryBi,
    FeynFacetSolution`F,FeynFacetSolution`K,FeynFacetSolution`a,FeynFacetSolution`G},h] :> h,
    {0,Infinity}] === {};

solutionZero[x_] := TrueQ[x === 0] || TrueQ[Cancel[Together[x]] === 0];
solutionMatrixZero[m_] := AllTrue[Flatten[Normal[m]],solutionZero];
solutionValuation[x_, e_] := If[solutionZero[x], Infinity,
  With[{r = Together[x]},
    If[!PolynomialQ[Numerator[r], e] || !PolynomialQ[Denominator[r], e],
      solutionFail["NonLaurentRegulatorDependence", <|"Expression" -> x|>]];
    Exponent[Numerator[r], e, Min] - Exponent[Denominator[r], e, Min]]];

(* A lower bound suffices for basis-convolution planning. Epsilon-independent
   coefficients need not be subjected to difficult transcendental zero tests:
   if such a coefficient vanishes, its valuation only increases. *)
solutionBasisOrderBound[x_,e_] := Which[
 x===0,Infinity,FreeQ[x,e],0,x===e,1,
 MatchQ[x,Power[e,_Integer]],x[[2]],
 Head[x]===Times,Total[solutionBasisOrderBound[#,e]& /@ List@@x],
 Head[x]===Plus,Min[solutionBasisOrderBound[#,e]& /@ List@@x],
 Head[x]===Power && IntegerQ[x[[2]]] && x[[2]]>0,
   x[[2]] solutionBasisOrderBound[x[[1]],e],
 True,solutionValuation[x,e]];


(* Expand only in epsilon. Maximal epsilon-independent expressions are
   temporary coefficient-field symbols and are restored before any output.
   This avoids differentiating/simplifying large elementary function
   expressions while forming a rational regulator series. *)
solutionRegulatorSeries[expression_,e_,upper_] := Module[{result},
 result=regulatorSeries[expression,e,upper];
 If[FailureQ[result],solutionFail["RegulatorSeriesNotConstructed",<|"Cause"->result|>]];
 result
];

solutionLaurentCoefficients[m_, e_, upper_Integer, basis_:False] := Module[
 {a=Normal[m],series,lower,result,polynomials},
 series=Map[solutionRegulatorSeries[#,e,upper]&,a,{2}];
 lower=Min[Flatten[series[[All,All,1]]]];
 If[lower===Infinity || lower>upper,Return[<||>]];
 polynomials=Map[Expand[#,e]&,series[[All,All,2]],{2}];
 result=Association@Table[k->Map[Coefficient[#,e,k]&,polynomials,{2}],
   {k,lower,upper}];
 If[!FreeQ[Values[result],e],solutionFail["NonLaurentRegulatorDependence"]];
 Select[result,If[TrueQ[basis],!AllTrue[Flatten[#],#===0&],!solutionMatrixZero[#]]&]
];

(* Numerical validation evaluates the factors before matrix multiplication.
   Rational point coordinates are exact; elementary functions are evaluated at
   80 digits. Relative residuals below 10^-50 are numerical evidence only. *)
solutionValidationPoints[vars_,base_,e_] := Table[
 Append[Thread[vars->(base+Table[(j+i)/(1000 (i+1)),{i,Length[vars]}])],
   e->{1/31,2/37,3/41}[[j]]],{j,3}];
solutionNumericalZero[terms_List] := Module[{norms,residual},
 If[!And@@(MatrixQ[#,NumericQ]& /@ terms) ||
   !FreeQ[terms,Indeterminate|DirectedInfinity[_]],Return[False]];
 norms=Max[Abs[Flatten[#]]]& /@ terms;
 residual=Max[Abs[Flatten[Total[terms]]]];
 TrueQ[residual<10^-50 Max[1,Sequence@@norms]]
];
solutionGaugeChecks[t_,a_,b_,vars_,method_,points_] := If[method==="NumericalPoints",
 If[Length[points]<3,solutionFail["AtLeastThreeValidationPointsRequired"]];
 Table[And@@Table[With[{tt=N[t/.N[pt,80],80],aa=N[a[[i]]/.N[pt,80],80],bb=N[b[[i]]/.N[pt,80],80]},
   solutionNumericalZero[{N[D[t,vars[[i]]]/.N[pt,80],80],tt.bb,-aa.tt}]],{pt,points}],
 {i,Length[vars]}],
 Table[solutionMatrixZero[D[t,vars[[i]]]+t.b[[i]]-a[[i]].t],{i,Length[vars]}]
];

(* For an explicitly prepared basis, expand the smaller input DE first.
   Perform the finite gauge convolutions coefficient by coefficient. This
   avoids asking Series to expand large elementary-function quotients. *)
solutionConnectionCoefficientConjugation[source_,vars_,e_,upper_] := Module[
 {a=source["ConnectionMatrices"],m=source["BasisTransformationMatrix"],
  mi=source["InverseBasisTransformationMatrix"],n,la,ll,lr,lc,rc,ac,drc,lower,terms,zero},
 n=Length[m];zero=ConstantArray[0,{n,n}];
 ll=Min[Flatten[Map[solutionBasisOrderBound[#,e]&,mi,{2}]]];
 lr=Min[Flatten[Map[solutionBasisOrderBound[#,e]&,m,{2}]]];
 la=Min[Flatten[Map[solutionBasisOrderBound[#,e]&,a,{3}]]];
 If[la===Infinity,la=0];
 lc=solutionLaurentCoefficients[mi,e,Max[upper-lr-la,upper-lr],True];
 rc=solutionLaurentCoefficients[m,e,Max[upper-ll-la,upper-ll],True];
 ac=solutionLaurentCoefficients[#,e,upper-ll-lr,True]& /@ a;
 epsilonAuditProduct[{epsilonAuditSpec["InverseGauge",ll,Max[upper-lr-la,upper-lr]],
   epsilonAuditSpec["SourceConnection",la,upper-ll-lr],
   epsilonAuditSpec["Gauge",lr,Max[upper-ll-la,upper-ll]]},upper,
   "Stage2/ConnectionConjugation"];
 epsilonAuditProduct[{epsilonAuditSpec["InverseGauge",ll,Max[upper-lr-la,upper-lr]],
   epsilonAuditSpec["GaugeDerivative",lr,Max[upper-ll-la,upper-ll]]},upper,
   "Stage2/ConnectionGaugeDerivative"];
 drc=Table[Map[D[#,vars[[i]]]&,rc],{i,Length[vars]}];
 lower=Min[ll+la+lr,ll+lr];
 Table[Association@Table[
  terms=Flatten[Table[
    If[KeyExistsQ[ac[[i]],k-q-p],{lc[q].ac[[i]][k-q-p].rc[p]},{}],
    {q,Keys[lc]},{p,Keys[rc]}],2];
  k->(Total[Append[terms,zero]]-
    Total[Prepend[Table[
      If[KeyExistsQ[rc,k-q],lc[q].drc[[i]][k-q],zero],{q,Keys[lc]}],zero]]),
 {k,lower,upper}],{i,Length[vars]}]
];

solutionFlatness[a_, vars_, method_, points_] := Module[{residuals, checks},
  If[!MemberQ[{"Exact", "RationalPoints","NumericalPoints"}, method],
    solutionFail["UnknownFlatnessCheck"]];
  If[method==="NumericalPoints",
    If[Length[points]<3,solutionFail["AtLeastThreeValidationPointsRequired"]];
    checks=And@@Flatten[Table[
      With[{ai=N[a[[i]]/.pt,80],aj=N[a[[j]]/.pt,80]},
       solutionNumericalZero[{N[D[a[[j]],vars[[i]]]/.pt,80],
        -N[D[a[[i]],vars[[j]]]/.pt,80],aj.ai,-ai.aj}]],
      {i,Length[vars]},{j,i+1,Length[vars]},{pt,points}]];
    If[!TrueQ[checks],solutionFail["ConnectionNotFlat",<|"Method"->method|>]];
    Return[<|"Method"->method,"ExactIdentity"->False,
      "WorkingPrecision"->80,"RelativeTolerance"->10^-50,
      "AllKinematicVariablePairsChecked"->True,"Points"->points|>]
  ];
  residuals = Flatten[Table[
    D[a[[j]], vars[[i]]] - D[a[[i]], vars[[j]]] +
      a[[j]].a[[i]] - a[[i]].a[[j]],
    {i, Length[vars]}, {j, i+1, Length[vars]}], 1];
  If[method === "Exact",
    checks = And @@ (solutionMatrixZero /@ residuals),
    If[!ListQ[points] || Length[points] < 3 ||
        !And @@ (MatchQ[#, {__Rule}] & /@ points),
      solutionFail["AtLeastThreeValidationPointsRequired"]];
    checks = And @@ Flatten[Table[solutionMatrixZero[r /. pt],
      {r, residuals}, {pt, points}]]];
  If[!TrueQ[checks], solutionFail["ConnectionNotFlat",
    <|"Method" -> method|>]];
  <|"Method" -> method, "ExactIdentity" -> (method === "Exact"),
    "AllKinematicVariablePairsChecked" -> True,
    "Points" -> If[method === "Exact", {}, points]|>
];

(* Algebraic definitions are finite ordinary arithmetic, in dependency order. *)
solutionShareMatrix[m_, append_] := Map[
  If[# === 0 || NumberQ[#], #, append[#]] &, Normal[m], {2}];

solutionCoefficient[a_Association, k_, n_] :=
  Lookup[a, k, ConstantArray[0, {n,n}]];

Options[FeynFacet`ConstructMasterIntegralSolution] = {
  "FlatnessCheck" -> "NumericalPoints", "ValidationPoints" -> Automatic,
  "OutputDirectory" -> None, "AutomaticPreparation" -> True,
  "HomogeneousSolveTimeLimit" -> 30, "Verbose" -> False,
  "RegularityProofTimeLimit"->5,"MaximumSectors"->512,"MaximumSectorDepth"->32};

FeynFacet`ConstructMasterIntegralSolution[system_Association, request_Association,
    OptionsPattern[]] := If[AnyTrue[{"RequestedMasterIntegralOrderRanges","RequestedMasterIntegralUpperOrders"},KeyExistsQ[request,#]&],
    Catch[solutionConstructFromOrders[system,request,<|
      "FlatnessCheck"->OptionValue["FlatnessCheck"],"ValidationPoints"->OptionValue["ValidationPoints"],
      "OutputDirectory"->OptionValue["OutputDirectory"],"AutomaticPreparation"->OptionValue["AutomaticPreparation"],
      "HomogeneousSolveTimeLimit"->OptionValue["HomogeneousSolveTimeLimit"],"Verbose"->OptionValue["Verbose"],
      "RegularityProofTimeLimit"->OptionValue["RegularityProofTimeLimit"],
      "MaximumSectors"->OptionValue["MaximumSectors"],"MaximumSectorDepth"->OptionValue["MaximumSectorDepth"]|>],
      "FiniteSolution"],
    Catch[solutionConstruct[system, request,
      OptionValue["FlatnessCheck"], OptionValue["ValidationPoints"],
      OptionValue["OutputDirectory"], OptionValue["AutomaticPreparation"],
      OptionValue["HomogeneousSolveTimeLimit"], OptionValue["Verbose"]], "FiniteSolution"]];
FeynFacet`ConstructMasterIntegralSolution[___] :=
  Failure["ExplicitDifferentialSystemAndOrdinaryPointRequestRequired", <||>];

solutionConstruct[system_, request_, method_, points_, directory_, automatic_, seconds_, verbose_, planned_:None] := Module[
  {vars, e, a, n, base, baseRules, orders, rows, masterOrders, constantBounds, t, s, h, hi, g, gi0,
   transform, inverse, interaction, check, preparation, extraBasis, extraInverse, degree, lowerL, lowerR, needed,
   lc, rc, bc, kernels, kernelDefinitions={}, kernelData, funcs = {}, algebra = {}, append, addIntegral,
   values, current, integrand, q, w, coeffs, expr, result,
   originalBasis, maxOrder, minOrder, finiteQ, progress, originalGaugeChecks,validationPoints,coefficientSource,orderPlan,entryOrders,entryLower,connectionBounds,expandedThrough,constantBoundInputs,originalUpper=None,originalLower=None},
  progress[msg_] := If[TrueQ[verbose],Print[msg]];
  vars = Lookup[system, "KinematicVariables", {}];
  e = Lookup[system, "DimensionalRegulator", Missing["Regulator"]];
  a = Normal /@ Lookup[system, "ConnectionMatrices", {}];
  If[vars === {} || !DuplicateFreeQ[vars] || !And @@ (MatchQ[#, _Symbol] & /@ vars) ||
      !MatchQ[e, _Symbol] || MemberQ[vars, e] || Length[a] =!= Length[vars],
    solutionFail["InvalidDifferentialSystemVariables"]];
  (* Keep one regulator symbol at the input boundary. *)
  a = a /. z_Symbol /; MemberQ[{"eps","ep","Epsilon"}, SymbolName[z]] :> e;
  n = If[Length[a] > 0, Length[First[a]], 0];
  If[n === 0 || !And @@ (Dimensions[#] === {n,n} & /@ a),
    solutionFail["InvalidConnectionDimensions"]];
  base = Lookup[request, "BasePoint", {}];
  If[KeyExistsQ[system,"BasePoint"]&&base=!=system["BasePoint"],
    solutionFail["RequestedBasePointDoesNotMatchSourceNormalization"]];
  orders = Lookup[request, "RequestedEpsilonOrders", Automatic];
  masterOrders = Lookup[request, "RequestedMasterIntegralEpsilonOrders", None];
  constantBoundInputs = Lookup[request, "InitialConstantLaurentLowerBounds", None];
  constantBounds = If[ListQ[constantBoundInputs],epsOrderBound /@ constantBoundInputs,constantBoundInputs];
  If[masterOrders =!= None || constantBounds =!= None,
    If[!ListQ[masterOrders] || masterOrders === {} ||
        !VectorQ[masterOrders,IntegerQ] || !DuplicateFreeQ[masterOrders] ||
        !ListQ[constantBounds] || Length[constantBounds] =!= n ||
        !VectorQ[constantBounds,IntegerQ[#] || #===Infinity&],
      solutionFail["MasterIntegralOrdersAndInitialConstantBoundsRequired"]]];
  If[orders === Automatic && masterOrders === None,
    solutionFail["ExplicitEpsilonOrderRequestRequired"]];
  rows = Lookup[request, "RequestedRows", Range[n]];
  If[Length[base] =!= Length[vars] || !And @@ (NumericQ /@ base) ||
      !FreeQ[base, Alternatives @@ Append[vars,e]] || !FreeQ[base,_Real],
    solutionFail["FixedNumericBasePointRequired"]];
  If[(orders =!= Automatic &&
       (orders === {} || !VectorQ[orders, IntegerQ] || !DuplicateFreeQ[orders])) ||
      rows === {} || !VectorQ[rows, (IntegerQ[#] && 1 <= # <= n)&] ||
      !DuplicateFreeQ[rows], solutionFail["InvalidRequestedCoefficients"]];
  If[!StringQ[Lookup[request, "AnalyticDomain", None]] ||
      !StringQ[Lookup[request, "BranchPrescription", None]],
    solutionFail["AnalyticDomainAndBranchPrescriptionRequired"]];
  baseRules = Thread[vars -> base];
  validationPoints=If[points===Automatic,solutionValidationPoints[vars,base,e],points];
  If[!ListQ[validationPoints] || !And@@(MatchQ[#,{__Rule}]& /@ validationPoints),
    solutionFail["InvalidValidationPoints"]];
  If[method==="NumericalPoints" &&
    !And@@(And@@(NumericQ /@ (Append[vars,e]/.#))& /@ validationPoints),
    solutionFail["ValidationPointsMustSpecifyEveryCoordinateAndRegulator"]];
  originalBasis = Lookup[system, "OriginalMasterIntegralBasis", Range[n]];
  If[Length[originalBasis] =!= n, solutionFail["InvalidMasterIntegralBasis"]];
  transform = Normal[Lookup[system, "BasisTransformationMatrix", IdentityMatrix[n]]];
  transform = transform /. z_Symbol /; MemberQ[{"eps","ep","Epsilon"}, SymbolName[z]] :> e;
  h = Normal[Lookup[system, "HomogeneousFundamentalMatrix", IdentityMatrix[n]]];
  If[Dimensions[transform] =!= {n,n} || Dimensions[h] =!= {n,n} || !FreeQ[h,e],
    solutionFail["InvalidBasisOrHomogeneousMatrix"]];
  hi = Normal[Lookup[system, "InverseHomogeneousFundamentalMatrix", Inverse[h]]];
  If[!solutionMatrixZero[h.hi - IdentityMatrix[n]],
    solutionFail["IncorrectInverseHomogeneousMatrix"]];
  If[!FreeQ[{a,transform,h,hi},_Real],
    solutionFail["ExactDifferentialSystemInputRequired"]];
  If[!And @@ (solutionExplicitExpressionQ /@ Flatten[{a,transform,h,hi}]),
    solutionFail["UnspecifiedSpecialFunctionOrUnevaluatedOperation"]];
  interaction = MapThread[(hi.#1.h - hi.D[h,#2]) &, {a,vars}];
  progress["Checking flatness in all coordinates"];
  originalGaugeChecks=None;
  If[ListQ[Lookup[system,"OriginalConnectionMatrices",None]],
    progress["Checking the supplied basis against the original differential system"];
    originalGaugeChecks=solutionGaugeChecks[transform,system["OriginalConnectionMatrices"],a,vars,method,validationPoints];
    If[!And@@originalGaugeChecks,solutionFail["OriginalBasisDifferentialEquationMismatch"]];
    check=solutionFlatness[system["OriginalConnectionMatrices"],vars,method,validationPoints],
    check=solutionFlatness[interaction,vars,method,validationPoints]];
  progress["Preparing the connection for finite integration"];
  preparation = If[TrueQ[automatic],solutionPrepareConnection[interaction,vars,e,seconds,
    <|"BlockReductionData"->Lookup[system,"EpsilonZeroBlockReductions",{}]|>],
    <|"ConnectionMatrices"->interaction,"BasisTransformationMatrix"->IdentityMatrix[n],
      "InverseBasisTransformationMatrix"->IdentityMatrix[n],"Validation"-><|"AutomaticPreparation"->False|>|>];
  interaction = preparation["ConnectionMatrices"];
  extraBasis = preparation["BasisTransformationMatrix"];
  extraInverse = preparation["InverseBasisTransformationMatrix"];
  g = transform.h.extraBasis;
  inverse = Lookup[system, "InverseBasisTransformationMatrix", None];
  inverse = inverse /. z_Symbol /; MemberQ[{"eps","ep","Epsilon"}, SymbolName[z]] :> e;
  progress["Normalizing the complete basis transformation at the base point"];
  gi0 = If[inverse === None,
    (extraInverse /. baseRules).(hi /. baseRules).Inverse[transform /. baseRules],
    (extraInverse /. baseRules).(hi /. baseRules).(Normal[inverse] /. baseRules)];
  If[!solutionMatrixZero[(g /. baseRules).gi0 - IdentityMatrix[n]],
    solutionFail["SingularBasePointOrIncorrectInverseBasisMatrix"]];
  finiteQ[z_] := FreeQ[z, Indeterminate | ComplexInfinity | DirectedInfinity[_]];
  If[!finiteQ[interaction /. baseRules] || !finiteQ[gi0],
    solutionFail["SingularBasePoint"]];
  lowerL = Min[Flatten[Map[solutionBasisOrderBound[#,e] &, g, {2}]]];
  lowerR = Min[Flatten[Map[solutionBasisOrderBound[#,e] &, gi0, {2}]]];
  minOrder = lowerL + lowerR;
  If[orders === Automatic,
    orders = Range[minOrder,Max[minOrder,Max[masterOrders]-Min[constantBounds]]]];
  maxOrder = Max[0,Max[orders]];
  needed = Max[0, maxOrder - minOrder];
  If[AssociationQ[planned],
    If[base=!=planned["BasePoint"] ||
      interaction=!=planned["PreparedDifferentialSystem"]["ConnectionMatrices"] ||
      g=!=planned["PreparedDifferentialSystem"]["BasisTransformationMatrix"],
      solutionFail["OrderDeterminationSystemMismatch"]];
    orderPlan=planned["FundamentalMatrixEpsilonOrders"];
    needed=orderPlan["MaximumTransformedOrder"];
    originalUpper=planned["OriginalFundamentalMatrixCoefficientUpperOrders"];
    originalLower=planned["OriginalFundamentalMatrixEntryLowerBounds"]
  ];
  progress["Expanding the transformed connection through epsilon order "<>ToString[needed]];
  coefficientSource=Lookup[system,"ConnectionCoefficientSource",None];
  bc = If[AssociationQ[coefficientSource] && !TrueQ[automatic] && h===IdentityMatrix[n],
    progress["Transforming source epsilon coefficients by finite basis convolutions"];
    If[!And@@solutionGaugeChecks[coefficientSource["BasisTransformationMatrix"],
       coefficientSource["ConnectionMatrices"],interaction,vars,method,validationPoints],
      solutionFail["ConnectionCoefficientSourceMismatch"]];
    solutionConnectionCoefficientConjugation[coefficientSource,vars,e,needed],
    Table[solutionLaurentCoefficients[b, e, needed, True], {b,interaction}]];
  bc = Map[Association@KeyValueMap[If[#1<0 && solutionMatrixZero[#2],Nothing,#1->#2]&,#]&,bc];
  If[!Quiet[finiteQ[(Values /@ bc) /. baseRules]],
    solutionFail["BasePointSingularForEpsilonExpandedConnection"]];
  If[AnyTrue[bc, AnyTrue[Keys[#], # < 0 &] &],
    solutionFail["NegativeEpsilonPowerRequiresFurtherBasisTransformation"]];
  (* Degree zero may be strictly lower triangular: variation of constants
     then terminates in row order even without a strict epsilon form. *)
  If[!And @@ Table[With[{b = solutionCoefficient[c,0,n]},
      And @@ Flatten[Table[solutionZero[b[[i,j]]], {i,n}, {j,i,n}]]], {c,bc}],
    solutionFail["NontriangularEpsilonZeroConnectionRequiresHomogeneousSolution"]];
  (* The preceding identities prove these entries are zero. Store literal
     zeros before assigning scalar kernel names, so formal finite-integral
     identities do not treat identically zero kernels as independent. *)
  bc=Map[Function[c,If[KeyExistsQ[c,0],
    Join[c,<|0->MapIndexed[If[Last[#2]>=First[#2],0,#1]&,c[0],{2}]|>],c]],bc];
  (* Coefficients above this preliminary bound cannot contribute to any
     requested original-basis coefficient. Entrywise requirements then remove
     unnecessary finite integrals without expensive symbolic zero tests. *)
  expandedThrough=needed;
  If[!AssociationQ[planned],
  connectionBounds=Table[Min[Flatten[Table[
    If[solutionCoefficient[c,q,n][[i,j]]===0,expandedThrough+1,q],
    {c,bc},{q,0,expandedThrough}]]],{i,n},{j,n}];
  orderPlan=epsOrderPlanFromValuations[connectionBounds,
    Map[solutionBasisOrderBound[#,e]&,g,{2}],
    Map[solutionBasisOrderBound[#,e]&,gi0,{2}],
    Flatten[Table[{i,j,Max[orders]},{i,rows},{j,n}],1]];
  orderPlan=Join[orderPlan,<|
    "ConnectionCoefficientsExaminedThroughOrder"->expandedThrough,
    "ConnectionBoundConvention"->"An entry absent through the examined order has lower bound examined order + 1; no unexamined coefficient is assumed zero.",
    "BasisEntryBoundConvention"->"Conservative Laurent lower bounds; cancellations can only increase them."|>]
  ];
  needed=orderPlan["MaximumTransformedOrder"];
  entryOrders=orderPlan["TransformedCoefficientUpperOrders"];
  entryLower=orderPlan["TransformedCoefficientLowerBounds"];
  progress["Finite integration requires epsilon order "<>ToString[needed]<>
    " with "<>ToString[orderPlan["RequiredTransformedCoefficientCount"]]<>" matrix coefficients"];
  t = FeynFacetSolution`t; s = FeynFacetSolution`s;
  kernelData=solutionBuildKernelDefinitions[bc,vars,base,t,needed,n];
  kernels=kernelData["Matrices"];kernelDefinitions=kernelData["Definitions"];
  append[z_] := (AppendTo[algebra, z]; FeynFacetSolution`a[Length[algebra]]);
  addIntegral[z_] := If[z === 0, 0, Module[{j, u, body},
    j = Length[funcs]+1; u = Symbol["FeynFacetSolution`t" <> ToString[j]];
    body = z /. t -> u;
    AppendTo[funcs, <|"Index" -> j, "IntegrationVariable" -> u,
      "UpperLimitVariable" -> s, "LowerLimit" -> 0, "Integrand" -> body|>];
    FeynFacetSolution`F[j,t]]];
  progress["Constructing all finite integral definitions"];
  values = <||>;
  Do[
    current = ConstantArray[0,{n,n}];
    Do[
      If[degree>entryOrders[[i,j]] || degree<entryLower[[i,j]],Continue[]];
      integrand = Total[Table[
        Total[Table[kernels[q][[i,k]] *
          If[q === 0, current[[k,j]], values[degree-q][[k,j]]],
          {k, If[q === 0, i-1, n]}]], {q,0,degree}]];
      current[[i,j]] = If[degree === 0 && i === j, 1, 0] + addIntegral[integrand],
      {i,n}, {j,n}];
    AssociateTo[values, degree -> current],
    {degree,0,needed}];
  progress["Completing the basis-change epsilon convolutions"];
  lc = solutionLaurentCoefficients[g, e, maxOrder-lowerR, True];
  rc = solutionLaurentCoefficients[gi0, e, maxOrder-lowerL, True];
  epsilonAuditFiniteEvolution[interaction,bc,expandedThrough,g,gi0,lc,rc,
    maxOrder-lowerR,maxOrder-lowerL,maxOrder-lowerL,
    entryLower,entryOrders,rows,originalUpper,maxOrder,e];
  If[!Quiet[finiteQ[Values[lc] /. baseRules]],
    solutionFail["BasePointSingularForExpandedBasisTransformation"]];
  lc = Map[solutionShareMatrix[#,append] &, lc];
  rc = Map[solutionShareMatrix[#,append] &, rc];
  (* Resolve both epsilon convolutions now; every shared expression below is
     finite scalar arithmetic on the previously defined functions. *)
  w = <||>;
  Do[
    expr = Total[Table[
      (values[b] /. FeynFacetSolution`F[j_, t] :> FeynFacetSolution`F[j,1]).
        solutionCoefficient[rc,degree-b,n], {b,0,needed}]];
    AssociateTo[w, degree -> solutionShareMatrix[expr,append]],
    {degree,lowerR,maxOrder-lowerL}];
  coeffs = Association@Table[degree -> Table[
      expr = Total[Table[solutionCoefficient[lc,k,n][[r]] .
          solutionCoefficient[w,degree-k,n], {k,Keys[lc]}]];
      r -> If[originalUpper===None,expr,
        Table[Which[degree<originalLower[[r,j]],0,
          degree>originalUpper[[r,j]],Missing["NotComputed"],True,expr[[j]]],{j,n}]],
      {r,rows}], {degree,Sort[orders]}];
  result = <|"DataType" -> "MasterIntegralSolution", "SchemaVersion" -> 3,
    "Status" -> "FiniteExpressionConstructed",
    "SolutionRepresentation" -> "FiniteNestedIntegrals",
    "Family" -> Lookup[system,"Family",None],
    "RationalizingCoordinates" -> Lookup[system,"RationalizingCoordinates",None],
    "KinematicVariables" -> vars, "DimensionalRegulator" -> e,
    "OriginalMasterIntegralBasis" -> originalBasis,
    "BasePoint" -> base, "AnalyticDomain" -> request["AnalyticDomain"],
    "BranchPrescription" -> request["BranchPrescription"],
    "Path" -> <|"Parameter" -> t, "Coordinates" -> (base+t(vars-base)),
      "ParameterInterval" -> {0,1}|>,
    "InitialConstants" -> <|"Definition" -> "C(epsilon)=I(BasePoint,epsilon)",
      "KinematicsIndependent" -> True, "Count" -> n|>,
    "CoefficientConvention" ->
      "I_r(epsilon)=Sum_n Sum_j epsilon^n U[r,j,n] C_j(epsilon); stored rows are U[r,All,n].",
    "RequestedRows" -> rows, "RequestedEpsilonOrders" -> Sort[orders],
    "TransformedSystemEpsilonOrderRange" -> {0,needed},
    "EpsilonOrderRequirements" -> orderPlan,
    "TransformedCoefficientUpperOrders" -> entryOrders,
    "TransformedCoefficientStorageConvention" ->
      "Entries above their recorded upper orders are uncomputed placeholders. Only requested original-basis coefficients are complete.",
    "BasisTransformationLaurentLowerBounds" -> {lowerL,lowerR},
    "ConnectionMatrices" -> a,
    "OriginalConnectionMatrices" -> Lookup[system,"OriginalConnectionMatrices",
      If[transform===IdentityMatrix[n],a,None]],
    "BasisTransformationMatrix" -> transform,
    "HomogeneousFundamentalMatrix" -> h,
    "InverseTotalBasisTransformationAtBasePoint" -> gi0,
    "BasisConvolutionCoefficients" -> <|"LeftCoefficients"->lc,"RightCoefficients"->rc,
      "RightConvolutionCoefficients"->w|>,
    "PreparedConnectionMatrices" -> interaction,
    "AdditionalBasisTransformationMatrix" -> extraBasis,
    "TransformedSolutionCoefficients" -> values,
    "KernelDefinitions" -> kernelDefinitions,
    "KernelFunctionConvention" -> "K_i(t) are explicit scalar functions using only earlier K_j(t), including shared arithmetic.",
    "KernelDefinitionCounts"->KeyTake[kernelData,{"SharedScalarExpressionCount","IntegrationKernelCount"}],
    "KernelMatrices" -> kernels,
    "IntegralDefinitions" -> funcs, "AlgebraicDefinitions" -> algebra,
    "Coefficients" -> coeffs,
    "Validation" -> <|"OriginalInputBasisIdentities"->originalGaugeChecks,
      "OriginalInputBasisCheckMethod"->method,
      "FiniteIntegrationPreparation" -> preparation["Validation"],
      "InputDifferentialSystem" -> Lookup[system,"InputValidation",<||>],
      "Flatness" -> check,
      "BasePointInverseIdentity" -> True,
      "ExpandedConnectionRegularAtBasePoint" -> True,
      "ExpandedBasisRegularAtBasePoint" -> True,
      "CoefficientConstruction" -> "FiniteVariationOfConstants",
      "PhysicalEpsilonOrderCoverage" -> "NotEstablished",
      "BoundaryConstantsDetermined" -> False|>|>;
  If[AssociationQ[planned],result=Join[result,<|
    "OriginalFundamentalMatrixCoefficientUpperOrders"->originalUpper,
    "OriginalFundamentalMatrixEntryLowerBounds"->originalLower,
    "OriginalCoefficientStorageConvention"->"Missing[NotComputed] denotes an unneeded fundamental-matrix entry; it is never a zero coefficient."|>]];
  If[!FeynFacet`MasterIntegralSolutionQ[result],
    solutionFail["InvalidConstructedFiniteExpression"]];
  If[masterOrders =!= None,
    result = FeynFacet`ExpandMasterIntegralSolutionInInitialConstants[result,
      constantBoundInputs, masterOrders];
    If[FailureQ[result], Throw[result,"FiniteSolution"]]];
  If[directory =!= None,
    If[!StringQ[directory], solutionFail["OutputDirectoryMustBeAString"]];
    solutionWrite[result,directory]];
  result
];

(* This predicate checks the finite definitions, not physical boundary values
   or the differential equation afresh. No operator-only record can pass. *)
FeynFacet`MasterIntegralSolutionQ[r_Association] := Module[
  {f, a, c, refs, dims, vars, n, good, kd, upper,originalUpper,originalLower,plan,coverage},
  If[Lookup[r,"DataType",None] =!= "MasterIntegralSolution" ||
      ! MemberQ[{3,4,5}, Lookup[r,"SchemaVersion",None]] ||
      Lookup[r,"SolutionRepresentation",None] =!= "FiniteNestedIntegrals",
    Return[False]];
  f = Lookup[r,"IntegralDefinitions",None]; a = Lookup[r,"AlgebraicDefinitions",None];
  c = Lookup[r,"Coefficients",None]; n = Lookup[r,"SystemDimension",Lookup[r["InitialConstants"],"Count",0]];
  If[!ListQ[f] || !ListQ[a] || !AssociationQ[c] || n < 1, Return[False]];
  If[Lookup[r,"SchemaVersion",None] === 4,
    With[{bb = Lookup[r,"BoundaryBasis",None],
        count = Lookup[r["InitialConstants"],"Count",0]},
      If[!IntegerQ[n] || !IntegerQ[count] || count < 1 ||
          !ListQ[bb] || Length[bb] =!= count ||
          Lookup[bb,"Index",{}] =!= Range[count] ||
          Lookup[bb,"LaurentLowerBound",{}] =!=
            Lookup[r,"InitialConstantLaurentLowerBounds",None] ||
          !AllTrue[bb, KeyExistsQ[#,"MasterIntegral"] &&
            ListQ[Lookup[#,"ReferencePoint",None]] &&
            Length[#["ReferencePoint"]] === Length[r["KinematicVariables"]] &&
            FreeQ[#["ReferencePoint"], Alternatives@@r["KinematicVariables"]] &],
        Return[False]]]];


  If[Lookup[r,"SchemaVersion",None]===5,
    With[{bb=Lookup[r,"BoundaryAmplitudes",None],count=Lookup[r["InitialConstants"],"Count",0]},
     If[KeyExistsQ[r,"SharedBoundaryDefinitionFile"]||!ListQ[bb]||Length[bb]=!=count||
       Lookup[bb,"Index",{}]=!=Range[count]||
       Lookup[bb,"LaurentLowerBound",{}]=!=Lookup[r,"InitialConstantLaurentLowerBounds",None]||
       !AllTrue[bb,KeyExistsQ[#,"Definition"]&],Return[False]]]];

  upper=Lookup[r,"TransformedCoefficientUpperOrders",None];
  If[upper=!=None && (Dimensions[upper]=!={n,n} ||
    !AllTrue[Flatten[upper],IntegerQ[#]&&#>=0 || #===-Infinity&] ||
    !AssociationQ[Lookup[r,"EpsilonOrderRequirements",None]] ||
    Lookup[r["EpsilonOrderRequirements"],"TransformedCoefficientUpperOrders",None]=!=upper),
    Return[False]];

  kd=Lookup[r,"KernelDefinitions",{}];
  If[!ListQ[kd] || !And@@Table[
    AssociationQ[kd[[i]]] && Lookup[kd[[i]],"Index",None]===i &&
    KeyExistsQ[kd[[i]],"Expression"] && MatchQ[Lookup[kd[[i]],"Parameter",None],_Symbol] &&
    solutionExplicitExpressionQ[kd[[i,"Expression"]]] &&
    FreeQ[kd[[i]],FeynFacetSolution`F[__]|FeynFacetSolution`a[__]] &&
    And@@(MatchQ[#,FeynFacetSolution`K[_Integer,_]] &&
      1<=#[[1]]<i && #[[2]]===kd[[i,"Parameter"]]& /@
      Cases[kd[[i,"Expression"]],_FeynFacetSolution`K,{0,Infinity}]),
    {i,Length[kd]}],Return[False]];
  refs=Cases[{f,Lookup[r,"KernelMatrices",{}]},FeynFacetSolution`K[j_,_]:>j,Infinity];
  If[!And@@(IntegerQ[#]&&1<=#<=Length[kd]& /@ refs),Return[False]];
  good = And @@ Table[
    AssociationQ[f[[i]]] && Lookup[f[[i]],"Index",0] === i &&
    Lookup[f[[i]],"LowerLimit",None] === 0 &&
    MatchQ[Lookup[f[[i]],"IntegrationVariable",None],_Symbol] &&
    MatchQ[Lookup[f[[i]],"UpperLimitVariable",None],_Symbol] &&
    KeyExistsQ[f[[i]],"Integrand"] &&
    solutionExplicitExpressionQ[f[[i,"Integrand"]]] &&
    FreeQ[f[[i]],FeynFacetSolution`a[_]] &&
    And @@ (IntegerQ[#] && 1 <= # < i & /@
      Cases[f[[i]], FeynFacetSolution`F[j_,_] :> j, Infinity]),
    {i,Length[f]}];
  good = good && And @@ Table[
    solutionExplicitExpressionQ[a[[i]]] && And @@ (IntegerQ[#] && 1 <= # < i & /@
      Cases[a[[i]],FeynFacetSolution`a[j_] :> j,Infinity]),
    {i,Length[a]}];
  refs = Cases[{a,c},FeynFacetSolution`F[j_,_] :> j,Infinity];
  good = good && And @@ (IntegerQ[#] && 1 <= # <= Length[f] & /@ refs);
  refs = Cases[c,FeynFacetSolution`a[j_] :> j,Infinity];
  good = good && And @@ (IntegerQ[#] && 1 <= # <= Length[a] & /@ refs);
  originalUpper=Lookup[r,"OriginalFundamentalMatrixCoefficientUpperOrders",None];
  originalLower=Lookup[r,"OriginalFundamentalMatrixEntryLowerBounds",None];
  If[originalUpper=!=None && (Dimensions[originalUpper]=!={n,n} ||
      Dimensions[originalLower]=!={n,n} ||
      !AllTrue[Flatten[originalUpper],IntegerQ[#] || #===-Infinity&] ||
      !AllTrue[Flatten[originalLower],IntegerQ[#] || #===Infinity&]),Return[False]];
  plan=Lookup[r,"ExpansionOrderDetermination",None];
  If[plan=!=None,
    coverage=Lookup[r,"RequestedMasterOrderCoverage",<||>];
    If[!AssociationQ[plan] || !AssociationQ[coverage] ||
      Lookup[plan,"OriginalFundamentalMatrixCoefficientUpperOrders",None]=!=originalUpper ||
      Lookup[plan,"OriginalFundamentalMatrixEntryLowerBounds",None]=!=originalLower ||
      Lookup[plan,"BasePoint",None]=!=Lookup[r,"BasePoint",None] ||
      Lookup[plan,"OriginalMasterIntegralBasis",None]=!=Lookup[r,"OriginalMasterIntegralBasis",None] ||
      Lookup[plan,"RequestedMasterIntegralOrderRanges",None]=!=
        Lookup[r,"RequestedMasterIntegralOrderRanges",None] ||
      (Lookup[plan,"OrdinaryPointConstantLowerBounds",{}]/.m_Missing->Missing["NotRequired"])=!=
        Lookup[r,"LocalInitialConstantLaurentLowerBounds",Lookup[r,"InitialConstantLaurentLowerBounds",None]] ||
      Lookup[coverage,"Status",None]=!=Lookup[plan,"Status",None] ||
      Lookup[coverage,"BasePoint",None]=!=Lookup[r,"BasePoint",None] ||
      Lookup[coverage,"EveryRequestedCoefficientConstructed",False]=!=True,
      Return[False]]];
  good && solutionExpandedCoefficientsQ[r] && Keys[c] === r["RequestedEpsilonOrders"] &&
    And @@ Table[MatchQ[c[k], {(_Integer -> _List)..}] &&
      (First /@ c[k]) === r["RequestedRows"] &&
      And @@ (Function[row,Length[Last[row]]===n &&
        And@@Table[If[originalUpper=!=None && originalLower[[First[row],j]]<=k &&
            k>originalUpper[[First[row],j]],Last[row][[j]]===Missing["NotComputed"],
          solutionExplicitExpressionQ[Last[row][[j]]]],{j,n}]] /@ c[k]), {k,Keys[c]}]
];
(* Only homogeneity in C is needed here. Kinematic coefficients are scalars;
   a general polynomial test needlessly analyzes their internal algebra. *)
solutionConstantDegreeRange[expression_] := Module[{ranges},
 Which[
  expression===0,{Infinity,-Infinity},
  MatchQ[expression,FeynFacetSolution`C[_Integer,_Integer]],{1,1},
  FreeQ[expression,_FeynFacetSolution`C],{0,0},
  Head[expression]===Plus,
   ranges=solutionConstantDegreeRange /@ List@@expression;
   {Min[ranges[[All,1]]],Max[ranges[[All,2]]]},
  Head[expression]===Times,
   ranges=solutionConstantDegreeRange /@ List@@expression;
   Which[MemberQ[ranges,{Infinity,-Infinity}],{Infinity,-Infinity},
     MemberQ[ranges,{-Infinity,Infinity}],{-Infinity,Infinity},True,Total[ranges]],
  Head[expression]===Power && IntegerQ[expression[[2]]] && expression[[2]]>0,
   expression[[2]] solutionConstantDegreeRange[expression[[1]]],
  True,{-Infinity,Infinity}]
];
solutionExpandedCoefficientsQ[r_] := Module[{entries, bounds, orders, n, constants,ranges,expectedRows},
  If[!KeyExistsQ[r,"MasterIntegralCoefficients"], Return[True]];
  entries=r["MasterIntegralCoefficients"];
  bounds=Lookup[r,"InitialConstantLaurentLowerBounds",None];
  orders=Lookup[r,"RequestedMasterIntegralEpsilonOrders",None];
  n=r["InitialConstants"]["Count"];
  ranges=Lookup[r,"RequestedMasterIntegralOrderRanges",None];
  If[!AssociationQ[entries] || !ListQ[bounds] || Length[bounds]=!=n ||
     !VectorQ[bounds,IntegerQ[#] || #===Infinity || #===Missing["NotRequired"]&] || !ListQ[orders] || Keys[entries]=!=orders,
    Return[False]];
  And @@ Table[
    MatchQ[entries[k],{(_Integer->_)..}] &&
    (First /@ entries[k])===If[AssociationQ[ranges],
      Select[r["RequestedRows"],ranges[#][[1]]<=k<=ranges[#][[2]]&],r["RequestedRows"]] &&
    And @@ Table[
      constants=Cases[expr,FeynFacetSolution`C[arg___]:>{arg},{0,Infinity}];
      And @@ (MatchQ[#,{_Integer,_Integer}] &&
        1<=#[[1]]<=n && IntegerQ[bounds[[#[[1]]]]] && #[[2]]>=bounds[[#[[1]]]] & /@ constants) &&
      solutionExplicitExpressionQ[expr/.FeynFacetSolution`C[_,_]->1] &&
      MemberQ[If[KeyExistsQ[r,"KnownBoundaryValues"],
        {{0,0},{0,1},{1,1},{Infinity,-Infinity}},{{1,1},{Infinity,-Infinity}}],
        solutionConstantDegreeRange[expr]],
      {expr,Last /@ entries[k]}],
    {k,orders}]
];

FeynFacet`MasterIntegralSolutionQ[_] := False;

FeynFacet`MasterIntegralSolutionCoefficient[r_Association, row_Integer, order_Integer] :=
  If[FeynFacet`MasterIntegralSolutionQ[r] &&
      KeyExistsQ[r["Coefficients"],order] && MemberQ[r["RequestedRows"],row],
    With[{value=row/.r["Coefficients"][order]},
      If[FreeQ[value,_Missing],value,
       Failure["SomeFundamentalMatrixEntriesNotStored",<|"Row"->row,"EpsilonOrder"->order|>]]],
    Failure["CoefficientNotStored", <|"Row"->row,"EpsilonOrder"->order|>]];

FeynFacet`ExpandMasterIntegralSolutionInInitialConstants[
    r_Association, lowerBounds_List, orders_List] := Catch[Module[
  {n, lowest, terms, result, entries, neededOrders, constants, actualBounds, boundStatus},
  If[!FeynFacet`MasterIntegralSolutionQ[r],
    solutionFail["FiniteMasterIntegralSolutionRequired"]];
  If[KeyExistsQ[r,"BoundaryBasis"],
    solutionFail["SharedBoundaryBasisAlreadyExpanded"]];
  n = r["InitialConstants"]["Count"];
  actualBounds=epsOrderBound /@ lowerBounds;
  boundStatus=If[AllTrue[lowerBounds,epsOrderKnownBoundQ],
    "BoundsEstablishedForSuppliedIntegralRepresentations","ExplicitInputAssumption"];
  If[Length[actualBounds] =!= n || !VectorQ[actualBounds,IntegerQ[#] || #===Infinity&] ||
      orders === {} || !VectorQ[orders,IntegerQ] || !DuplicateFreeQ[orders],
    solutionFail["ExplicitInitialConstantLaurentBoundsAndOrdersRequired"]];
  lowest = Total[r["BasisTransformationLaurentLowerBounds"]];
  entries = Association@Table[order -> Table[
    terms = Flatten[Table[If[actualBounds[[j]]===Infinity,{},Table[
      With[{k = order-m},
        If[!KeyExistsQ[r["Coefficients"],k],
          solutionFail["FundamentalMatrixCoefficientNotStored",
            <|"EpsilonOrder"->k,"InitialConstantColumn"->j|>]];
        (row /. r["Coefficients"][k])[[j]] FeynFacetSolution`C[j,m]],
      {m,actualBounds[[j]],order-lowest}]], {j,n}]];
    row -> Total[terms], {row,r["RequestedRows"]}], {order,Sort[orders]}];
  Join[r,<|"InitialConstantLaurentLowerBounds"->actualBounds,
    "InitialConstantLowerBoundInputs"->lowerBounds,
    "InitialConstantLowerBoundStatus"->boundStatus,
    "RequestedMasterIntegralEpsilonOrders"->Sort[orders],
    "MasterIntegralCoefficients"->entries|>]
], "FiniteSolution"];

solutionWrite[r_, directory_String,format_:"WolframText"] := Module[{files, path, tmp,stream},
  If[!DirectoryQ[directory], CreateDirectory[directory,CreateIntermediateDirectories->True]];
  If[format==="WXF",
    If[FileExistsQ[FileNameJoin[{directory,"conventions.m"}]],Return[Failure["OutputFormatConflict",<||>]]];
    path=FileNameJoin[{directory,"solution.wxf"}];tmp=path<>".tmp-"<>ToString[$ProcessID];
    stream=OpenWrite[tmp,BinaryFormat->True];
    BinaryWrite[stream,Normal[BinarySerialize[r,PerformanceGoal->"Size"]],"Byte"];
    Close[stream];RenameFile[tmp,path,OverwriteTarget->True];Return[directory]];
  If[format=!="WolframText",Return[Failure["UnsupportedSolutionFileFormat",<||>]]];
  If[FileExistsQ[FileNameJoin[{directory,"solution.wxf"}]],Return[Failure["OutputFormatConflict",<||>]]];
  files = Join[
    <|"conventions.m" -> KeyDrop[r,{"IntegralDefinitions","AlgebraicDefinitions",
        "Coefficients","ConnectionMatrices","OriginalConnectionMatrices","KernelMatrices","BasisTransformationMatrix",
        "HomogeneousFundamentalMatrix","PreparedConnectionMatrices","KernelDefinitions","AdditionalBasisTransformationMatrix","InverseTotalBasisTransformationAtBasePoint","TransformedSolutionCoefficients","BasisConvolutionCoefficients","Validation","MasterIntegralCoefficients","ExpansionOrderDetermination"}],
      "functions.m" -> r["IntegralDefinitions"],
      "kernel_functions.m" -> r["KernelDefinitions"],
       "transformed_solution_coefficients.m" -> r["TransformedSolutionCoefficients"],
      "basis_convolutions.m" -> r["BasisConvolutionCoefficients"],
      "algebraic_expressions.m" -> r["AlgebraicDefinitions"],
      "kernels.m" -> KeyTake[r,{"ConnectionMatrices","OriginalConnectionMatrices","KernelMatrices",
        "BasisTransformationMatrix","HomogeneousFundamentalMatrix","PreparedConnectionMatrices","AdditionalBasisTransformationMatrix","InverseTotalBasisTransformationAtBasePoint"}],
      "validation.m" -> r["Validation"]|>,
    Association@KeyValueMap[("coefficients_order_" <> ToString[#1] <> ".m") -> #2 &,
      r["Coefficients"]],
    If[KeyExistsQ[r,"MasterIntegralCoefficients"],
      Association@KeyValueMap[("master_integrals_order_" <> ToString[#1] <> ".m") -> #2 &,
        r["MasterIntegralCoefficients"]], <||>]];
  If[KeyExistsQ[r,"ExpansionOrderDetermination"],
    path=FileNameJoin[{directory,"order_determination.wxf"}];tmp=path<>".tmp";
    stream=OpenWrite[tmp,BinaryFormat->True];
    BinaryWrite[stream,Normal[BinarySerialize[r["ExpansionOrderDetermination"],PerformanceGoal->"Size"]],"Byte"];
    Close[stream];RenameFile[tmp,path,OverwriteTarget->True]
  ];
  Do[path = FileNameJoin[{directory,name}];
    tmp = path <> ".tmp"; Block[{$Context="Global`",$ContextPath={"System`","Global`"}},Put[files[name],tmp]]; RenameFile[tmp,path,OverwriteTarget->True],
    {name,Keys[files]}];
  directory
];
Options[FeynFacet`WriteMasterIntegralSolution]={"FileFormat"->"WolframText"};
FeynFacet`WriteMasterIntegralSolution[r_Association, directory_String,OptionsPattern[]] :=
  If[FeynFacet`MasterIntegralSolutionQ[r], solutionWrite[r,directory,OptionValue["FileFormat"]],
    Failure["FiniteMasterIntegralSolutionRequired",<||>]];

End[];
