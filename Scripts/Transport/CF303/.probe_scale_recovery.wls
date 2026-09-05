#!/usr/bin/env wolframscript
$AllowInternet = False;
$HistoryLength = 0;
root = DirectoryName[ExpandFileName[$InputFileName], 4];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
fits = Import[#, "RawJSON"] & /@ Sort[FileNames["q*.json",
  "/tmp/cf303_junction_interpolations"]];
primes = Lookup[fits, "prime"];
modulus = Times @@ primes;
key = If[Rest[$ScriptCommandLine] === {}, "1:-2:44:0",
  First[Rest[$ScriptCommandLine]]];
validationPath = If[Length[Rest[$ScriptCommandLine]] >= 2,
  Rest[$ScriptCommandLine][[2]],
  "/tmp/cf303_junction_validation_q2305843009213693693_p3.json"];
records = (SelectFirst[#["coordinates"], #["key"] === key &] &) /@ fits;
vectors = Join[#["numerator"], #["denominator"]] & /@ records;
images = ChineseRemainder[#, primes] & /@ Transpose[vectors];
dimension = Length[images];
split = Length[First[records]["numerator"]];
validation = Import[validationPath, "RawJSON"];
q = validation["prime"];
point = validation["p_mod_prime"];
expected = Lookup[Association[(StringRiffle[ToString /@
      {#["mode_index"], #["epsilon_order"], #["target_master"],
       Lookup[#, "radical_mask_bits", 0]}, ":"] -> #["value"]) & /@
    validation["normal_residue_projection"]], key, 0];
center[value_] := With[{reduced = Mod[value, modulus]},
  If[2*reduced > modulus, reduced - modulus, reduced]];
primitive[vector_] := Module[{gcd = Apply[GCD, Abs[vector]], result},
  If[gcd === 0, Return[vector]];
  result = vector/gcd;
  If[Last[result] < 0, -result, result]];
freshValid[vector_] := Module[{numerator, denominator, nv, dv},
  numerator = Take[vector, split]; denominator = Drop[vector, split];
  nv = Mod[numerator . PowerMod[point, Range[0, split - 1], q], q];
  dv = Mod[denominator . PowerMod[point,
      Range[0, dimension - split - 1], q], q];
  dv =!= 0 && Mod[nv*PowerMod[dv, -1, q], q] === expected];
constructionValid[vector_] := And @@ MapThread[
  Function[{record, prime}, Mod[Last[vector], prime] =!= 0 &&
    Mod[vector*PowerMod[Mod[Last[vector], prime], -1, prime], prime] ===
      Join[record["numerator"], record["denominator"]]],
  {records, primes}];
expandScale[scale_] := primitive[center /@ (images*scale)];

individual = Table[FeynFacet`Private`modularLift[
    List /@ vectors[[All, index]], primes], {index, dimension}];
successful = Cases[individual, {value_} :> value];
seed = Apply[LCM, Denominator /@ successful];
seedCandidate = expandScale[seed];
Print[InputForm[<|"Key" -> key, "Dimension" -> dimension,
  "IndividualSuccesses" -> Length[successful],
  "LCMSeedBits" -> IntegerLength[seed, 2],
  "SeedHeightBits" -> IntegerLength[Max[Abs[seedCandidate]], 2],
  "SeedConstructionValid" -> constructionValid[seedCandidate],
  "SeedFreshValid" -> freshValid[seedCandidate]|>]];

nonzero = Flatten@Position[images, Except[0], {1}, Heads -> False];
candidateScales = {seed};
Do[
  edgeOrder = DeleteDuplicates@Flatten@Table[
    {index, split + 1 - index, split + index,
      dimension + 1 - index}, {index, Ceiling[count/2]}];
  spreadIndices = DeleteDuplicates[Round[Subdivide[1, Length[nonzero],
      Min[count, Length[nonzero]] - 1]]];
  spread = Extract[nonzero, List /@ spreadIndices];
  subsetCandidates = DeleteDuplicates[Map[
    Sort@DeleteCases[Take[DeleteDuplicates[#], UpTo[count]],
      index_ /; index < 1 || index >= dimension] &,
    {Take[nonzero, UpTo[count]], Take[Reverse[nonzero], UpTo[count]],
      spread, edgeOrder,
      Select[Range[split + 1, dimension - 1],
        Mod[#, Max[1, Floor[(dimension - split - 1)/count]]] === 0 &],
      Select[Range[1, split],
        Mod[#, Max[1, Floor[split/count]]] === 0 &]}]];
  Do[
    If[subset === {}, Continue[]];
    localImages = images[[subset]];
    localDimension = Length[localImages] + 1;
    basis = Join[Table[ReplacePart[ConstantArray[0, localDimension],
        index -> modulus], {index, localDimension - 1}],
      {Join[localImages, {1}]}];
    timing = AbsoluteTiming[reduced = SortBy[LatticeReduce[basis],
        Max[Abs[#]] &]];
    rows = Take[reduced, UpTo[12]];
    rows = Join[rows, Flatten[Table[
        {rows[[left]] + rows[[right]], rows[[left]] - rows[[right]]},
        {left, Min[6, Length[rows]]},
        {right, left + 1, Min[6, Length[rows]]}], 2]];
    candidateScales = Join[candidateScales, Last /@ rows];
    candidates = DeleteDuplicates[expandScale /@ candidateScales];
    accepted = Select[candidates, constructionValid[#] && freshValid[#] &];
    Print[InputForm[<|"SubsetSize" -> Length[subset],
      "Seconds" -> First[timing],
      "ShortestBits" -> IntegerLength[Max[Abs[First[reduced]]], 2],
      "CandidateCount" -> Length[candidates],
      "Accepted" -> Length[accepted],
      "AcceptedHeightBits" -> If[accepted === {}, None,
        IntegerLength[Max[Abs[First[accepted]]], 2]]|>]];
    If[accepted =!= {}, Quit[0]],
    {subset, subsetCandidates}],
  {count, {4, 6, 8, 10, 12, 16, 20, 24}}];
Quit[3];
