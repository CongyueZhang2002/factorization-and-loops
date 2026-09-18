(* Differential-system variables and regulator conventions. *)
ClearAll[
  $masterTransportRegulatorNames,
  $masterTransportZeroTimeLimit,
  masterTransportDefaultVariables,
  masterTransportDetectRegulator,
  masterTransportResolveVariables,
  masterTransportResolveRegulator,
  masterTransportNormalize,
  masterTransportSimplifyZeroQ,
  masterTransportZeroQ,
  observableTransportZeroQ, observableTransportZeroMatrixQ,
  observableTransportBlockLowerQ,
  masterTransportZeroMatQ,
  masterTransportCheckLevel,
  masterTransportPointZeroQ, differentialDimensionPoint
];

$masterTransportRegulatorNames = {"eps", "Eps", "epsilon", "Epsilon", "ep"};


(* Every symbolic zero test gets a budget.  Simplify on a 2F1 residual
   can run without bound, and a check that has not returned is neither a
   pass nor a failure -- it is a check that was not performed, and it
   must be reported as "Inconclusive" rather than hang the stage. *)
$masterTransportZeroTimeLimit = 120;


masterTransportDefaultVariables[] :=
  {Symbol["Global`v"], Symbol["Global`w"]};

masterTransportDetectRegulator[expr_, variables_List] := Module[{symbols},
  symbols = DeleteDuplicates @ Cases[
    expr,
    s_Symbol /; MemberQ[$masterTransportRegulatorNames, SymbolName[s]],
    {0, Infinity},
    Heads -> True
  ];
  symbols = DeleteCases[symbols, Alternatives @@ variables];
  If[Length[symbols] === 1, First[symbols], $Failed]
];

masterTransportResolveVariables[value_] := Switch[value,
  Automatic, masterTransportDefaultVariables[],
  {_Symbol, __Symbol}, value,
  _, $Failed
];

masterTransportResolveRegulator[value_, expr_, variables_] := Switch[value,
  Automatic, masterTransportDetectRegulator[expr, variables],
  _Symbol, value,
  _, $Failed
];

(* The one place symbol identity changes.  Matching on SymbolName keeps a
   Global`eps system and a Global`Epsilon system on one code path, and it
   is applied to EVERY input before any backend package can load and
   claim those names for itself (trap P2). *)
masterTransportNormalize[expr_, regulator_Symbol, variables_List] :=
  Module[{names, rules},
    names = SymbolName /@ variables;
    rules = Join[
      {(s_Symbol /; MemberQ[$masterTransportRegulatorNames, SymbolName[s]] &&
          SymbolName[s] =!= SymbolName[regulator]) :> regulator},
      MapThread[
        Function[{nm, target},
          (s_Symbol /; SymbolName[s] === nm && s =!= target) :> target],
        {names, variables}]
    ];
    expr /. rules
  ];

(* Keep dimension/regulator sample values consistent with the declared affine
   convention. Never substitute into a rule's left-hand side. *)
differentialDimensionPoint[point_List,system_Association,convention_:"Regulator"]:=Module[
 {e=Lookup[system,"DimensionalRegulator",None],rule=Lookup[system,"DimensionRule",None],
  dimension,rhs,constant,slope,values,dv,ev,rest,missing=Missing["NotSpecified"]},
 If[!MatchQ[point,{(_Rule)...}]||!DuplicateFreeQ[First/@point]||
   !MemberQ[{"Regulator","Dimension","Both"},convention],
  Return[Failure["ExplicitConsistentDimensionPointRequired",<|"Point"->point|>]]];
 If[rule===None,Return[point]];
 If[!MatchQ[e,_Symbol]||!MatchQ[rule,Rule[_Symbol,_]],
  Return[Failure["DeclaredAffineDimensionRuleRequired",<||>]]];
 dimension=First[rule];rhs=masterTransportNormalize[Last[rule],e,{}];
 If[dimension===e||!FreeQ[rhs,dimension]||!PolynomialQ[rhs,e]||Exponent[rhs,e]=!=1,
  Return[Failure["DeclaredAffineDimensionRuleRequired",<||>]]];
 constant=rhs/.e->0;slope=Coefficient[rhs,e];
 If[slope===0,Return[Failure["InvertibleDimensionRuleRequired",<||>]]];
 values=Association[masterTransportNormalize[point,e,Lookup[system,"KinematicVariables",{}]]];
 dv=Lookup[values,dimension,missing];ev=Lookup[values,e,missing];
 rest=Normal[KeyDrop[values,{dimension,e}]];
 If[dv=!=missing&&ev=!=missing&&Together[dv-((rhs/.e->ev)/.rest)]=!=0,
  Return[Failure["InconsistentDimensionAndRegulatorPoint",<|"Point"->point,"DimensionRule"->rule|>]]];
 If[ev===missing&&dv=!=missing,ev=Together[(dv-(constant/.rest))/(slope/.rest)]];
 If[dv===missing&&ev=!=missing,dv=(rhs/.e->ev)/.rest];
 Join[rest,If[convention=!="Dimension"&&ev=!=missing,{e->ev},{}],
   If[convention=!="Regulator"&&dv=!=missing,{dimension->dv},{}]]
];
