(* Formal GPL/elliptic iterated-integral representation used in master-integral
   solutions.

   Construction keeps polynomial-factor letters root free.  Expansion into
   marked points is performed only for a requested letter sequence, avoiding enormous
   radicals and the Cartesian expansion of the complete alphabet. *)

Clear[FormalChenIteratedIntegral, AlgebraicMarkedPoint,
  IteratedIntegralKernel, ExpandIteratedIntegralLetterSequence];
ClearAll[transportCurveBasisShift, transportLetterRoot,
  transportExpandOneLetter];

(* Inert formal integral with an explicit base point, path endpoint and
   optional curve.  The letter sequence is outermost first. *)
SetAttributes[FormalChenIteratedIntegral, HoldAll];

transportCurveBasisShift[curve_, variable_Symbol] := Module[
  {a4 = Coefficient[curve, variable, 4],
   a3 = Coefficient[curve, variable, 3]},
  If[a4 === 0, Missing["CurveNotQuartic"], Together[a3/(2 a4)]]
];

(* The inert root head also permits polynomial coefficients depending on
   spectator kinematics, which System`Root does not. *)
transportLetterRoot[polynomial_, variable_Symbol, index_Integer] :=
  AlgebraicMarkedPoint[CoefficientList[polynomial, variable], index];

IteratedIntegralKernel[{"GPLPole", point_}, variable_Symbol, _ : None] :=
  1/(variable - point);
IteratedIntegralKernel[{"GPLFactor", polynomial_, power_Integer},
    variable_Symbol, _ : None] := variable^power/polynomial;
IteratedIntegralKernel[{"E4Factor", polynomial_, power_Integer},
    variable_Symbol, curve_] :=
  variable^power/(polynomial Sqrt[curve]);
IteratedIntegralKernel[{"E4Pole", point_}, variable_Symbol, curve_] :=
  Sqrt[curve /. variable -> point]/
    ((variable - point) Sqrt[curve]);
IteratedIntegralKernel[{"E4Omega0"}, variable_Symbol, curve_] :=
  1/Sqrt[curve];
IteratedIntegralKernel[{"E4OmegaInf"}, variable_Symbol, curve_] :=
  variable/Sqrt[curve];
IteratedIntegralKernel[{"E4Eta2"}, variable_Symbol, curve_] := Module[
  {shift = transportCurveBasisShift[curve, variable]},
  If[MissingQ[shift], shift,
    (variable^2 + shift variable)/Sqrt[curve]]
];
IteratedIntegralKernel[_, _, _ : None] :=
  Missing["IteratedIntegralLetterNotSupported"];

transportExpandOneLetter[{"GPLFactor", polynomial_, power_Integer},
    variable_Symbol, _] := Module[
  {degree, derivative, root},
  If[! PolynomialQ[polynomial, variable] ||
      (degree = Exponent[polynomial, variable]) < 1 ||
      power < 0 || power >= degree ||
      Exponent[PolynomialGCD[polynomial, D[polynomial, variable]],
        variable] > 0,
    Return[{{1, Missing["MalformedGPLFactor"]}}]
  ];
  derivative = D[polynomial, variable];
  Table[
    root = transportLetterRoot[polynomial, variable, index];
    {Together[root^power/(derivative /. variable -> root)],
      {"GPLPole", root}},
    {index, degree}]
];

transportExpandOneLetter[{"E4Factor", polynomial_, power_Integer},
    variable_Symbol, curve_] := Module[
  {degree, derivative, root},
  If[! PolynomialQ[polynomial, variable] ||
      ! PolynomialQ[curve, variable] ||
      (degree = Exponent[polynomial, variable]) < 1 ||
      power < 0 || power >= degree ||
      Exponent[PolynomialGCD[polynomial, D[polynomial, variable]],
        variable] > 0 ||
      Exponent[PolynomialGCD[polynomial, curve], variable] > 0,
    Return[{{1, Missing["MalformedE4Factor"]}}]
  ];
  derivative = D[polynomial, variable];
  Table[
    root = transportLetterRoot[polynomial, variable, index];
    {Together[root^power/
      ((derivative /. variable -> root) Sqrt[curve /. variable -> root])],
      {"E4Pole", root}},
    {index, degree}]
];

transportExpandOneLetter[label_List, _, _] := {{1, label}};
transportExpandOneLetter[_, _, _] :=
  {{1, Missing["IteratedIntegralLetterNotSupported"]}};

(* definitions maps a composite label to {{coefficient, baseLabel}, ...}.
   The result is combined by complete marked-point letter sequence, but only
   for the requested sequence. *)
ExpandIteratedIntegralLetterSequence[letterSequence_List, variable_Symbol,
    curve_: None, definitions_: <||>] := Catch@Module[
  {fail, expanded = {{1, {}}}, baseChoices, choices, merged},
  fail[status_, extra_: <||>] := Throw[Join[<|"Status" -> status|>, extra]];
  If[! AssociationQ[definitions] ||
      (curve =!= None && (! PolynomialQ[curve, variable] ||
        Exponent[curve, variable] =!= 4)),
    fail["IteratedIntegralLetterSequenceInputInvalid"]];
  Do[
    baseChoices = Lookup[definitions, Key[label], {{1, label}}];
    If[! MatchQ[baseChoices, {{_, _List} ..}],
      fail["CompositeLetterDefinitionInvalid", <|"Letter" -> label|>]];
    choices = Flatten[Table[
      ({base[[1]] #[[1]], #[[2]]} &) /@
        transportExpandOneLetter[base[[2]], variable, curve],
      {base, baseChoices}], 1];
    If[! FreeQ[choices, _Missing],
      fail["IteratedIntegralLetterNotSupported", <|"Letter" -> label|>]];
    expanded = Flatten[Table[
      {left[[1]] right[[1]], Append[left[[2]], right[[2]]]},
      {left, expanded}, {right, choices}], 1],
    {label, letterSequence}];
  merged = Merge[(#[[2]] -> #[[1]]) & /@ expanded, Total];
  <|"Status" -> "IteratedIntegralLetterSequenceExpanded",
    "Terms" -> DeleteCases[
      ({Last[#], First[#]} &) /@ Normal[merged], {0, _}]|>
];

ExpandIteratedIntegralLetterSequence[___] :=
  <|"Status" -> "IteratedIntegralLetterSequenceInputInvalid"|>;
