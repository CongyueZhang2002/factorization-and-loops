#!/usr/bin/env wolframscript
(* Feasibility probe for multiquadratic/channel and split finite-field
   propagation on a saved completed-row gauge.  This does not mutate the
   state and does not claim a reconstruction; it measures the prerequisites
   before the full black-box benchmark is built. *)

args = Rest[$ScriptCommandLine];
If[Length[args] < 4,
  Print["Usage: probe_family_row_basis_transformation_components.wls <family> <state.wl> <off_diagonal_block_state.wl> <result.wl>"];
  Exit[64]];
{family, stateFile, stripFile, resultFile} = args[[1 ;; 4]];
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
exchange = FileNameJoin[{root, "Exchange", "Codex", "2026-08-22",
  "04_triple_root_campaign"}];
Get[FileNameJoin[{exchange, "TripleRootAlgebra.wl"}]];
Get[FileNameJoin[{exchange, "TripleRootStripAdapter.wl"}]];

state = Get[stateFile]; checkpoint = Get[stripFile];
If[! AssociationQ[state] || ! AssociationQ[checkpoint], Exit[2]];
variables = {Symbol["Global`x"], Symbol["Global`y"]};
epsilon = Symbol["Global`eps"];
frame = FeynFacet`FamilyRootData[family];
roots = CodexTripleRootStrip`TRCurrentRoots[frame, variables];
k = checkpoint["Sector"]; ranges = state["Ranges"];
rows = ranges[[k]]; start = First[rows]; n = Length[state["S"]];
columns = Range[start - 1]; gauge = checkpoint["PrevD"];
payload = {
  state["A"][[All, start ;; n, rows]],
  state["A"][[All, columns, columns]],
  state["S"][[All, rows]], state["SInverse"][[columns, All]], gauge};
classification = CodexTripleRootStrip`TRClassifyStripRecord[
  <|"Family" -> family, "Sector" -> k, "LowerSector" -> 1,
    "Variables" -> variables, "OffDiagonalBlockEquation" -> payload|>, frame];
activeIndices = Lookup[classification, "RootIndices", {}];
activeRoots = If[ListQ[roots] && VectorQ[activeIndices, IntegerQ],
  roots[[activeIndices]], {}];
nonzero = DeleteCases[Flatten[payload], 0];
unique = DeleteDuplicates[nonzero, SameTest -> SameQ];
representativeGauge = Last[SortBy[
  DeleteCases[Flatten[gauge], 0], LeafCount]];
representativeA = Last[SortBy[
  DeleteCases[Flatten[state["A"][[All, start ;; n, rows]]], 0],
  LeafCount]];
Print["CHANNEL PROBE classification=", KeyTake[classification,
  {"Status", "RootIndices", "RootSquares"}], " payloadNonzero=",
  Length[nonzero], " unique=", Length[unique], " maxGaugeLeaves=",
  LeafCount[representativeGauge], " maxALeaves=", LeafCount[representativeA]];

rootSymbols = Array[Symbol["Global`rho" <> ToString[#]] &, Length[activeRoots]];
{branchGaugeSeconds, branchedGauge} = AbsoluteTiming[
  CodexTripleRootStrip`TRApplyRootBranches[
    gauge, activeRoots, rootSymbols]];
remainingRadicals = DeleteDuplicates[Cases[branchedGauge,
  Power[base_, exponent_Rational /; Denominator[exponent] === 2] :>
    Together[base], Infinity]];
Print["CHANNEL PROBE branchGaugeSeconds=", N[branchGaugeSeconds],
  " remainingRadicals=", Length[remainingRadicals]];

{gaugeDecomposeSeconds, gaugeChannels} = AbsoluteTiming[
  TimeConstrained[
    CodexTripleRootStrip`TRFieldDecompose[
      representativeGauge, activeRoots], 300, $TimedOut]];
gaugeRoundTrip = ListQ[gaugeChannels] && TrueQ[Together[
  CodexTripleRootStrip`TRFieldCompose[gaugeChannels, activeRoots] -
    representativeGauge] === 0];
Print["CHANNEL PROBE gaugeDecomposeSeconds=", N[gaugeDecomposeSeconds],
  " result=", If[gaugeChannels === $TimedOut, "TimedOut", Head[gaugeChannels]],
  " roundTrip=", gaugeRoundTrip];

{aDecomposeSeconds, aChannels} = AbsoluteTiming[
  TimeConstrained[
    CodexTripleRootStrip`TRFieldDecompose[
      representativeA, activeRoots], 300, $TimedOut]];
aRoundTrip = ListQ[aChannels] && TrueQ[Together[
  CodexTripleRootStrip`TRFieldCompose[aChannels, activeRoots] -
    representativeA] === 0];
Print["CHANNEL PROBE aDecomposeSeconds=", N[aDecomposeSeconds],
  " result=", If[aChannels === $TimedOut, "TimedOut", Head[aChannels]],
  " roundTrip=", aRoundTrip];

(* One real split-point sign projection of the representative gauge. *)
prime = 1000003; SeedRandom[20260823]; point = Missing["NotFound"];
Do[
  candidate = RandomInteger[{2, prime - 2}, 2];
  If[CodexTripleRoot`TRSplitPointQ[candidate,
      Lookup[activeRoots, "RootSquare", {}], variables, prime],
    point = candidate; Break[]],
  {200}];
splitProjection = $Failed; splitRoundTrip = False; splitSeconds = 0.;
If[ListQ[point],
  deltaValues = Mod[Lookup[activeRoots, "RootSquare", {}] /.
    Thread[variables -> point], prime];
  rootValues = CodexTripleRoot`TRSquareRoots[deltaValues, prime];
  modNumber[value_] := Module[{q = Together[value], den},
    If[! FreeQ[q, _Symbol], Return[$Failed]];
    den = Mod[Denominator[q], prime];
    If[den === 0, Return[$Failed]];
    Mod[Numerator[q] PowerMod[den, -1, prime], prime]];
  {splitSeconds, branchValues} = AbsoluteTiming[Table[
    signs = Table[If[BitGet[mask, bit] === 0, 1, -1],
      {bit, 0, Length[activeRoots] - 1}];
    modNumber[CodexTripleRootStrip`TRApplyRootBranches[
        representativeGauge, activeRoots, signs rootValues] /.
      Thread[variables -> point] /. epsilon -> 1/7],
    {mask, 0, 2^Length[activeRoots] - 1}]];
  If[FreeQ[branchValues, $Failed],
    splitProjection = CodexTripleRoot`TRProjectConjugates[
      branchValues, rootValues, prime];
    splitRoundTrip = Mod[
      CodexTripleRoot`TREvaluateConjugates[
        splitProjection, rootValues, prime] - branchValues, prime] ===
      ConstantArray[0, Length[branchValues]]]];
Print["CHANNEL PROBE splitPoint=", point, " splitSeconds=",
  N[splitSeconds], " projectionRoundTrip=", splitRoundTrip];

record = <|
  "Status" -> If[Lookup[classification, "Status", None] ===
      "ExactRootClassification" && remainingRadicals === {} &&
      gaugeRoundTrip && aRoundTrip && splitRoundTrip, "OK", "NotReady"],
  "Family" -> family, "Sector" -> k,
  "Classification" -> classification,
  "PayloadNonzeroCount" -> Length[nonzero],
  "PayloadUniqueCount" -> Length[unique],
  "MaximumGaugeLeafCount" -> LeafCount[representativeGauge],
  "MaximumALeafCount" -> LeafCount[representativeA],
  "BranchGaugeSeconds" -> branchGaugeSeconds,
  "RemainingRadicals" -> remainingRadicals,
  "GaugeDecomposeSeconds" -> gaugeDecomposeSeconds,
  "BasisTransformationCoordinateReexpressionVerified" -> gaugeRoundTrip,
  "ADecomposeSeconds" -> aDecomposeSeconds,
  "ARoundTrip" -> aRoundTrip,
  "SplitPrime" -> prime, "SplitPoint" -> point,
  "SplitSeconds" -> splitSeconds,
  "SplitProjectionRoundTrip" -> splitRoundTrip|>;
FeynFacet`FamilyArtifactWrite[record, resultFile];
Print["CHANNEL PROBE RESULT ", KeyTake[record,
  {"Status", "BranchGaugeSeconds", "GaugeDecomposeSeconds",
    "ADecomposeSeconds", "SplitSeconds"}], " written=", resultFile];
Exit[If[record["Status"] === "OK", 0, 1]];
