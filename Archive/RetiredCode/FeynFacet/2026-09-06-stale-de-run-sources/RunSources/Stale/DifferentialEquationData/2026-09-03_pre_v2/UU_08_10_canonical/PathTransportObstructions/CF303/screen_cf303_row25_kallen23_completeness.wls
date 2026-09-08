#!/usr/bin/env wolframscript
(* CF303 (25,2) COMPLETENESS screen in the Kallen23 (t,s) frame
   (Codex note 21 route): the residue-only integrability screen over
   the complete certified span -- family census v2 + {Z4, Z2, P3} --
   with the rank-ONE root list (the bilinear root, the surviving
   one-generator extension).  E, C, Bbar are transformed EXACTLY into
   the frame: Bbar is materialized from the raw deferred preparation
   by the documented symbolic reference route (1.4 MB input; this is
   the smallest block), then the catalog branch rules are applied
   BEFORE the variable substitution, in the established pullback
   order.  Two standard images + one fresh confirmation. *)

root = "/home/maxzhang/factorization-and-loops";
codexRoot = "/home/maxzhang/factorization-and-loops-codex";
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
priv = Symbol["FeynFacet`Private`" <> #] &;

blockIndex = If[Length[$ScriptCommandLine] >= 2,
  ToExpression[$ScriptCommandLine[[2]]], 2];
inputFile = FileNameJoin[{codexRoot, "Runtime",
  Switch[blockIndex,
    2, "CF303_exception14_continuation_2026-08-30",
    1, "2026-08-30_cf303_25_2_exact_common_path/resume",
    14, "2026-08-31_cf303_25_14_schema_current"],
  "sector_CF303_standard",
  "CF303_25_" <> ToString[blockIndex] <> "_input.wl"}];
record = Get[inputFile];
{x, y} = record["Variables"];
eps = record["Regulator"];
preparation = record["DeferredPreparation"]["Preparation"];
{e0, c0, bbarPlaceholder} = record["Strip"];

(* lower-block dimension from the record's own E (block 14 is 2x2;
   blocks 1 and 2 are 1x1) -- the coupling Bbar is 2 x dimLower *)
dimLower = Length[e0[[1]]];
If[Dimensions[e0[[1]]] =!= {dimLower, dimLower},
  Print[InputForm[<|"Status" -> "LowerBlockShapeUnrecognized",
    "EDimensions" -> Dimensions[e0[[1]]]|>]]; Exit[1]];
Print["materializing Bbar symbolically (2x2x", dimLower,
  " targets) ..."];
mSeconds = First[AbsoluteTiming[
  bbar0 = Table[
    priv["blockEquationDeferredSourceExpression"][preparation,
      {mu, i, j}],
    {mu, 2}, {i, 2}, {j, dimLower}];]];
Print["materialized in ", mSeconds, " s; leaves ",
  LeafCount[bbar0]];
If[! FreeQ[bbar0, _Missing],
  Print[InputForm[<|"Status" -> "MaterializationFailed"|>]]; Exit[1]];
If[Dimensions[bbar0] =!= {2, 2, dimLower},
  Print[InputForm[<|"Status" -> "BbarShapeUnrecognized",
    "BbarDimensions" -> Dimensions[bbar0]|>]]; Exit[1]];

(* the chart: rational x, y, lambda2/lambda3 branches; the bilinear
   root survives as the ONE generator *)
t = Global`kallen23T; s = Global`kallen23S;
a = (s - 3) (s + 1 - 2 t)/(s^2 - 1);
xts = -a t;
yts = (1 - a) (1 - t);
branch1 = a - t;                       (* lambda2 branch *)
branch2 = 1 + t + s (a - 1);           (* lambda3 branch *)
rootSym = Global`kallen23BilinearRoot;
delta1xy = 1 + 2 x + x^2 - 2 y + 2 x y + y^2;
delta2xy = 1 - 2 x + x^2 + 2 y + 2 x y + y^2;
delta3xy = 1 - 4 x y;
delta3ts = Together[1 - 4 xts yts];

branchRules = {
  Power[b_, exp_Rational] /;
      TrueQ[Together[b - delta1xy] === 0] :> branch1^(2 exp),
  Power[b_, exp_Rational] /;
      TrueQ[Together[b - delta2xy] === 0] :> branch2^(2 exp),
  Power[b_, exp_Rational] /;
      TrueQ[Together[b - delta3xy] === 0] :> rootSym^(2 exp)};

transform[expr_] := (expr /. branchRules) /. {x -> xts, y -> yts};

Print["transforming E, C, Bbar into (t, s) with the Jacobian ..."];
(* one-form components transform by the CHAIN RULE, not bare
   substitution: W_t = W_x dx/dt + W_y dy/dt, W_s likewise -- without
   the Jacobian the transformed diagonal connections are not flat and
   the screen rightly refuses (measured: DiagonalConnectionsNotFlat) *)
dxdt = D[xts, t]; dxds = D[xts, s];
dydt = D[yts, t]; dyds = D[yts, s];
chainRule[w_] := Module[{wx, wy},
  wx = Map[transform, w[[1]], {2}];
  wy = Map[transform, w[[2]], {2}];
  {wx dxdt + wy dydt, wx dxds + wy dyds}];
tSeconds = First[AbsoluteTiming[
  eTS = chainRule[e0];
  cTS = chainRule[c0];
  bbarTS = chainRule[bbar0];]];
Print["transformed in ", tSeconds, " s"];
leftoverRadicals = DeleteDuplicates[Cases[{eTS, cTS, bbarTS},
  Power[b_, exp_Rational] /; ! FreeQ[b, t] || ! FreeQ[b, s] :> b,
  {0, Infinity}]];
leftoverRadicals = Select[leftoverRadicals,
  TrueQ[Together[# - delta3ts] =!= 0] &];
If[! FreeQ[{eTS, cTS, bbarTS}, x] || ! FreeQ[{eTS, cTS, bbarTS}, y] ||
    leftoverRadicals =!= {},
  Print[InputForm[<|"Status" -> "FrameTransformIncomplete",
    "LeftoverRadicals" -> Short[leftoverRadicals, 4]|>]]; Exit[1]];
(* any surviving Sqrt[delta3ts] spelling joins the declared root *)
bbarTS = bbarTS /. Power[b_, exp_Rational] /;
  TrueQ[Together[b - delta3ts] === 0] :> rootSym^(2 exp);
eTS = eTS /. Power[b_, exp_Rational] /;
  TrueQ[Together[b - delta3ts] === 0] :> rootSym^(2 exp);
cTS = cTS /. Power[b_, exp_Rational] /;
  TrueQ[Together[b - delta3ts] === 0] :> rootSym^(2 exp);

(* letters: family census v2 + the three block curves, grade zero *)
censusJSON = Import[FileNameJoin[{codexRoot, "Diagnostics",
  "Artifacts", "cf303_25_11_divisor_union_census.json"}], "RawJSON"];
letterPoly[terms_Association] := Total[KeyValueMap[
  Function[{monomial, fraction}, Module[{ij = ToExpression /@
      StringSplit[monomial, ","]},
    (fraction[[1]]/fraction[[2]]) t^ij[[1]] s^ij[[2]]]],
  terms]];
censusLetters = Cases[censusJSON["entries"],
  entry_Association /; ! KeyExistsQ[entry, "identical_to"] &&
    entry["terms"] =!= "homogenization_variable" :>
      letterPoly[entry["terms"]]];
sharedCurves = {
  -3 s^2 t^2 + s^2 + 8 s t^3 + 6 s t^2 - 12 s t + 2 s - 24 t^3 +
    33 t^2 - 12 t + 1,
  -s^2 + 4 s t + 4 s - 12 t + 5,
  -s^2 t - s^2 + 2 s t^2 + 2 s t - 6 t^2 + 3 t + 1};
block14Curves = {
  -2 s^2 t^2 + s^2 t + 2 s^2 + 4 s t^3 + 4 s t^2 - 4 s t - 4 s -
    12 t^3 + 6 t^2 + 11,
  -s^5 - 4 s^4 t^3 - 6 s^4 t^2 + s^4 + 8 s^3 t^4 + 32 s^3 t^3 + 36 s^3 t^2 - 24 s^3 t + 6 s^3 - 40 s^2 t^4 - 104 s^2 t^3 + 48 s^2 t^2 - 8 s^2 t + 2 s^2 + 88 s t^4 + 64 s t^3 - 132 s t^2 + 56 s t - 5 s - 120 t^4 + 204 t^3 - 138 t^2 + 40 t - 3};
blockCurves = If[blockIndex === 14,
  Join[sharedCurves, block14Curves], sharedCurves];
allLetters = DeleteDuplicates[Join[censusLetters, blockCurves]];
letterRecords = (<|"Letter" -> #,
   "OneForm" -> {D[#, t]/#, D[#, s]/#}|> &) /@ allLetters;
Print["letters: ", Length[letterRecords]];

(* the screen's compiler expects the catalog Sqrt spelling of a
   declared root, exactly as its own drivers declare them
   (Root -> Sqrt[square]); an undeclared bare symbol fails the
   compile *)
eTS = eTS /. rootSym -> Sqrt[delta3ts];
cTS = cTS /. rootSym -> Sqrt[delta3ts];
bbarTS = bbarTS /. rootSym -> Sqrt[delta3ts];
screenRecord = <|"Variables" -> {t, s}, "Regulator" -> eps,
  "Strip" -> {eTS, cTS, bbarTS},
  "Family" -> "CF303", "Sector" -> 25, "LowerSector" -> blockIndex|>;
roots = {<|"Root" -> Sqrt[delta3ts], "RootSquare" -> delta3ts|>};

Print["running the screen at two images + fresh ..."];
screenSeconds = First[AbsoluteTiming[
  result = priv["multiquadraticStripIntegrabilityScreenImages"][
    screenRecord, roots, letterRecords,
    "Images" -> {{2147483423, 1/13}, {2147483399, 3/17}},
    "ConfirmObstruction" -> True,
    "FreshImageCount" -> 1,
    "PointCount" -> Max[24, Ceiling[(4 Length[letterRecords] + 16)/8]],
    "RandomSeed" -> 2026083199];]];
Print["screen seconds: ", screenSeconds];

out = <|"Status" -> "CF303Block" <> ToString[blockIndex] <> "CompletenessScreenV1",
  "Frame" -> "Kallen23",
  "InputFile" -> inputFile,
  "LetterCount" -> Length[letterRecords],
  "BlockCurves" -> blockCurves,
  "GaugeMultiplicities" -> "recorded in cf303_25_2_census_closure.json",
  "MaterializeSeconds" -> mSeconds,
  "TransformSeconds" -> tSeconds,
  "ScreenSeconds" -> screenSeconds,
  "Screen" -> result|>;
outputFile = FileNameJoin[{codexRoot, "Diagnostics", "Artifacts",
  "cf303_25_" <> ToString[blockIndex] <> "_completeness_screen.wl"}];
Put[out, outputFile];
Print["written ", outputFile];
Print[InputForm[KeyTake[If[AssociationQ[result], result, <||>],
  {"Status", "Defects", "Images", "Confirmed", "EvidenceRecord"}]]];
(* an unusable/inconclusive screen is a FAILURE of this run, not a
   verdict -- exit nonzero so the wrapper's exit code is honest *)
usable = If[AssociationQ[result] &&
    AssociationQ[result["EvidenceRecord"]],
  Lookup[result["EvidenceRecord"], "ConfiguredUsable", 0], 0];
If[! TrueQ[usable >= 2],
  Print["SCREEN NOT USABLE (ConfiguredUsable=", usable, ")"];
  Exit[2]];
Print["DONE"];
