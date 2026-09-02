#!/usr/bin/env wolframscript
(* Finish regulator factorization from a blockwise Fuchsian checkpoint.
   The chart letters are extracted as polynomial factors.  This avoids
   Libra`PolesInfo, whose simultaneous Solve over all denominators is
   fragile on a full two-variable family. *)

$HistoryLength = 0;
root = DirectoryName[ExpandFileName[$InputFileName], 3];
argv = Rest[$ScriptCommandLine];
If[Length[argv] < 2,
  Print["usage: libra_checkpoint_factor_dependence.wls CHECKPOINT OUTPUT [BUDGET]"];
  Exit[2]];
checkpointFile = ExpandFileName[argv[[1]]];
outputFile = ExpandFileName[argv[[2]]];
budget = If[Length[argv] >= 3, ToExpression[argv[[3]]], 600];

record = Block[{$Context = "Global`", $ContextPath = {"Global`", "System`"}},
  Get[checkpointFile]];
Quiet[Block[{Print = (Null &)},
  Get[FileNameJoin[{root, "Addon", "Mathematica_Addon", "Libra",
    "Source", "Libra.m"}]]], {General::shdw}];
Off[OptionValue::optnf];
Off[OptionValue::nodef];

family = record["Family"];
{x1, x2} = record["Variables"];
epsilon = record["Regulator"];
ranges = record["Ranges"];
ax0 = record["SystemX"];
ay0 = record["SystemY"];
ax = ax0;
ay = ay0;
total0 = record["Transformation"];
n = Length[ax];
reference = Unique["libraMu"];
start = AbsoluteTime[];

SetAttributes[timed, HoldAll];
timed[expression_, seconds_] := Module[{time, value},
  {time, value} = AbsoluteTiming[
    TimeConstrained[CheckAbort[expression, "Aborted"], seconds, "TimedOut"]];
  <|"Value" -> value, "Seconds" -> time|>
];
zeroQ[expression_] := AllTrue[Flatten[{expression}],
  TrueQ[Together[#] === 0] &];
epsilonFactoredQ[expression_] := AllTrue[Flatten[{expression}],
  TrueQ[Together[#] === 0] || FreeQ[Together[#/epsilon], epsilon] &];
monic[factor_, variable_] := Together[
  factor/Coefficient[factor, variable, Exponent[factor, variable]]];
letterFactors[matrix_, variable_] :=
  (monic[#, variable] &) /@ DeleteDuplicates[Flatten[Table[
    If[TrueQ[entry === 0], {},
      Select[First /@ Rest[FactorList[Denominator[Cancel[entry]]]],
        ! FreeQ[#, variable] &]],
    {entry, Flatten[matrix]}]]];
residueAtFactor[matrix_, variable_, factor_] := Module[{pole},
  pole = Together[-Coefficient[factor, variable, 0]/
    Coefficient[factor, variable, 1]];
  Map[Together[(factor # /. variable -> pole)] &, matrix/epsilon, {2}]
];
specialize[transformation_] := Module[{constants, candidates},
  constants = DeleteDuplicates[Cases[transformation, _C, Infinity]];
  candidates = If[constants === {}, {{}},
    {Thread[constants -> Range[Length[constants]]],
     Thread[constants -> Prime[Range[Length[constants]]]],
     Thread[constants -> (Range[Length[constants]] + 1)]}];
  SelectFirst[
    (Map[Together, transformation /. # /. reference -> 1, {2}] &) /@
      candidates,
    MatrixQ[#] && Dimensions[#] === {n, n} &&
      ! TrueQ[Together[Det[#]] === 0] &, $Failed]
];

fuchsianBefore = {
  timed[Libra`FuchsianQ[ax, x1], budget],
  timed[Libra`FuchsianQ[ay, x2], budget]};
If[! AllTrue[fuchsianBefore, TrueQ[#1["Value"]] &],
  Print[InputForm[<|"Status" -> "InputNotFuchsian",
    "Results" -> fuchsianBefore|>]]; Exit[1]];

factorsX = letterFactors[ax, x1];
factorsY = letterFactors[ay, x2];
degreesX = Exponent[#, x1] & /@ factorsX;
degreesY = Exponent[#, x2] & /@ factorsY;
Print[InputForm[<|"Family" -> family,
  "LettersX" -> Length[factorsX], "DegreesX" -> Tally[degreesX],
  "LettersY" -> Length[factorsY], "DegreesY" -> Tally[degreesY]|>]];
attempts = {};
transformation = $Failed;
raw = $Failed;
factorResult = <|"Value" -> $Failed, "Seconds" -> 0|>;
tryConstraintMatrices[matrices_List, label_String, metadata_: <||>] := Module[
  {result, candidateRaw, candidate, exactCandidate, ci},
  Print["[factor-dependence] ", label, ": solving ", Length[matrices],
    " exact matrices"];
  result = timed[
    Libra`FactorDependence[matrices, epsilon, reference,
      DependentRowIndices -> Automatic, Sort -> True], budget];
  candidateRaw = result["Value"];
  candidate = If[MatrixQ[candidateRaw], specialize[candidateRaw], $Failed];
  exactCandidate = If[MatrixQ[candidate],
    ci = Map[Together, Inverse[candidate], {2}];
    epsilonFactoredQ[Map[Together, ci . ax . candidate, {2}]] &&
      epsilonFactoredQ[Map[Together, ci . ay . candidate, {2}]], False];
  AppendTo[attempts, Join[<|"Method" -> label,
    "Matrices" -> Length[matrices], "Seconds" -> result["Seconds"],
    "ExactEpsFactor" -> exactCandidate|>, metadata]];
  If[TrueQ[exactCandidate],
    method = label; factorResult = result; raw = candidateRaw;
    transformation = candidate; True,
    False]
];

(* CANONICA decomposes the complete rational one-form into exact dlog
   coefficient matrices without solving the nonlinear letters for their
   roots.  These matrices are the natural input for Libra's simultaneous
   regulator factorization. *)
canonicaFile = FileNameJoin[{root, "Addon", "Mathematica_Addon",
  "CANONICA", "src", "CANONICA.m"}];
If[FileExistsQ[canonicaFile],
  Quiet[Get[canonicaFile], General::shdw];
  CANONICA`$ComputeParallel = False;
  CANONICA`Private`$ComputeParallel = False;
  extract = Which[
    DownValues[CANONICA`ExtractIrreducibles] =!= {},
      CANONICA`ExtractIrreducibles,
    DownValues[CANONICA`Private`ExtractIrreducibles] =!= {},
      CANONICA`Private`ExtractIrreducibles,
    True, $Failed];
  calculate = Which[
    DownValues[CANONICA`CalculateDlogForm] =!= {},
      CANONICA`CalculateDlogForm,
    DownValues[CANONICA`Private`CalculateDlogForm] =!= {},
      CANONICA`Private`CalculateDlogForm,
    True, $Failed];
  If[extract =!= $Failed && calculate =!= $Failed,
    canonicaResult = timed[Module[{converted, letters, dlog},
      converted = {ax, ay} /. epsilon -> CANONICA`eps;
      letters = extract[converted, CANONICA`AllowEpsDependence -> True];
      dlog = calculate[converted, {x1, x2}, letters];
      {letters, dlog}], budget];
    If[MatchQ[canonicaResult["Value"], {_List, _List}],
      {canonicaLetters, canonicaDLog} = canonicaResult["Value"];
      If[Length[canonicaDLog] === Length[canonicaLetters] &&
          AllTrue[canonicaDLog, MatrixQ],
        constraintMatrices = Map[
          Together[(#/CANONICA`eps) /. CANONICA`eps -> epsilon] &,
          canonicaDLog, {3}];
        tryConstraintMatrices[constraintMatrices, "CANONICADLog",
          <|"Letters" -> Length[canonicaLetters],
            "DecompositionSeconds" -> canonicaResult["Seconds"]|>]]]]];

If[! MatrixQ[transformation] &&
   AllTrue[Join[degreesX, degreesY], # === 1 &],
  method = "FiniteResidues";
  Print["[factor-dependence] extracting exact finite residues"];
  constraintMatrices = Join[
    residueAtFactor[ax, x1, #] & /@ factorsX,
    residueAtFactor[ay, x2, #] & /@ factorsY];
  (* For a Fuchsian rational connection the residue at infinity is minus
     the sum of the finite residues, hence gives no new equation. *)
  tryConstraintMatrices[constraintMatrices, "FiniteResidues"]];

(* A constant regulator transformation obeys
     A(epsilon,x).T(epsilon) = T(epsilon).A(mu,x).
   Exact evaluations at generic rational chart points therefore give
   linear equations for the same T without solving nonlinear letter
   equations.  The final unsampled symbolic identity below is the
   acceptance criterion; too few points can only make an attempt fail
   that exact check. *)
If[! MatrixQ[transformation],
  method = "ExactRationalSamples";
  candidateRules = Table[
    {x1 -> Prime[k + 3]/Prime[k + 11],
     x2 -> Prime[2 k + 5]/Prime[2 k + 15]}, {k, 1, 24}];
  validRules = Select[candidateRules, Function[rules,
    sampled = Map[Together, {ax, ay} /. rules, {3}];
    FreeQ[sampled, Indeterminate | ComplexInfinity | DirectedInfinity[_]] &&
      AllTrue[Flatten[sampled], Denominator[#] =!= 0 &]]];
  Do[
    If[count > Length[validRules], Break[]];
    constraintMatrices = Flatten[Table[
      {Map[Together, (ax/epsilon) /. validRules[[k]], {2}],
       Map[Together, (ay/epsilon) /. validRules[[k]], {2}]},
      {k, count}], 1];
    If[tryConstraintMatrices[constraintMatrices, "ExactRationalSamples",
        <|"Points" -> count|>], Break[]],
    {count, {1, 2, 4, 8, 16}}]
];

If[MatrixQ[transformation],
  inverseTransformation = Map[Together, Inverse[transformation], {2}];
  ax = Map[Together, inverseTransformation . ax . transformation -
    inverseTransformation . D[transformation, x1], {2}];
  ay = Map[Together, inverseTransformation . ay . transformation -
    inverseTransformation . D[transformation, x2], {2}];
  total = Map[Together, total0 . transformation, {2}],
  inverseTransformation = $Failed;
  total = total0];

inverseTotal = Quiet[Check[Map[Together, Inverse[total], {2}], $Failed]];
finalAlphabet = {};
dlogCheck = False;
If[FileExistsQ[canonicaFile],
  Quiet[Get[canonicaFile], General::shdw];
  extract = Which[
    DownValues[CANONICA`ExtractIrreducibles] =!= {},
      CANONICA`ExtractIrreducibles,
    DownValues[CANONICA`Private`ExtractIrreducibles] =!= {},
      CANONICA`Private`ExtractIrreducibles,
    True, $Failed];
  checkDlog = Which[
    DownValues[CANONICA`CheckDlogForm] =!= {}, CANONICA`CheckDlogForm,
    DownValues[CANONICA`Private`CheckDlogForm] =!= {},
      CANONICA`Private`CheckDlogForm,
    True, $Failed];
  If[extract =!= $Failed && checkDlog =!= $Failed,
    convertedFinal = {ax, ay} /. epsilon -> CANONICA`eps;
    finalAlphabet = Union[{x1, x2},
      Select[extract[convertedFinal, CANONICA`AllowEpsDependence -> True],
        FreeQ[#, CANONICA`eps] &]];
    dlogCheck = TrueQ[
      checkDlog[convertedFinal, {x1, x2}, finalAlphabet]]]];
checks = <|
  "EpsFactored" -> (epsilonFactoredQ[ax] && epsilonFactoredQ[ay]),
  "DLog" -> dlogCheck,
  "Fuchsian" -> TrueQ[Libra`FuchsianQ[ax, x1]] &&
    TrueQ[Libra`FuchsianQ[ay, x2]],
  "BlockLowerTriangular" -> AllTrue[Flatten[Table[
    If[j > i, {ax[[ranges[[i]], ranges[[j]]]],
      ay[[ranges[[i]], ranges[[j]]]]}, {}],
    {i, Length[ranges]}, {j, Length[ranges]}]], TrueQ[# === 0] &],
  "Invertible" -> MatrixQ[inverseTotal] && zeroQ[{
    total . inverseTotal - IdentityMatrix[n],
    inverseTotal . total - IdentityMatrix[n]}],
  "GaugeIdentityFromCheckpoint" -> MatrixQ[inverseTransformation] && zeroQ[{
    inverseTransformation . ax0 . transformation -
      inverseTransformation . D[transformation, x1] - ax,
    inverseTransformation . ay0 . transformation -
      inverseTransformation . D[transformation, x2] - ay}],
  "Flatness" -> zeroQ[D[ax, x2] - D[ay, x1] + ax . ay - ay . ax]|>;
accepted = MatrixQ[transformation] && And @@ Values[checks];
output = <|"Status" -> If[accepted, "EpsForm", "NotEpsForm"],
  "Family" -> family, "Variables" -> {x1, x2},
  "Regulator" -> epsilon, "Ranges" -> ranges,
  "FactorsX" -> factorsX, "FactorsY" -> factorsY,
  "Alphabet" -> finalAlphabet,
  "ConstraintMethod" -> method,
  "ConstraintMatrixCount" -> If[ListQ[constraintMatrices],
    Length[constraintMatrices], 0], "Attempts" -> attempts,
  "FactorDependenceSeconds" -> factorResult["Seconds"],
  "RawTransformation" -> raw, "Transformation" -> total,
  "EpsFormX" -> ax, "EpsFormY" -> ay, "Checks" -> checks,
  "Seconds" -> AbsoluteTime[] - start|>;
Put[output, outputFile];
Print[InputForm[KeyDrop[output,
  {"RawTransformation", "Transformation", "EpsFormX", "EpsFormY"}]]];
If[! accepted, Exit[1]];
