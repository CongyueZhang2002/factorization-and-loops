#!/usr/bin/env wolframscript
root = DirectoryName[ExpandFileName[$InputFileName], 4];
artifact = Get[FileNameJoin[{root, "Scripts", "Transport", "CF303",
  "Artifacts", "CF303PhysicalSoftSixSystem.wl"}]];
Print[InputForm[Keys[artifact]]];
Scan[Function[key, Print[InputForm[{key, Head[artifact[key]],
    If[AssociationQ[artifact[key]], Keys[artifact[key]],
      Dimensions[artifact[key]]]}]]], Keys[artifact]];
Scan[Function[part,
  Print[InputForm[{part, Map[Function[key,
      {key, Head[artifact[part, key]],
        If[AssociationQ[artifact[part, key]], Keys[artifact[part, key]],
          Dimensions[artifact[part, key]]]}], Keys[artifact[part]]]}]]],
  {"Homogeneous", "InheritedForcing"}];
Print["homogeneous normal sample"];
Scan[Print[InputForm[#]] &, Take[artifact["Homogeneous", "Normal"], UpTo[8]]];
Print["homogeneous tangential sample"];
Scan[Print[InputForm[#]] &, Take[artifact["Homogeneous", "Tangential"], UpTo[8]]];
frame = Get[FileNameJoin[{root, "Scripts", "Transport", "CF303",
  "Artifacts", "CF303SixModeEndpointFrame.wl"}]];
Print["frame keys"];
Scan[Function[key, Print[InputForm[{key, Head[frame[key]],
    If[AssociationQ[frame[key]], Keys[frame[key]],
      Dimensions[frame[key]]]}]]], Keys[frame]];
p3 = Import["/tmp/cf303_soft_residue_p3_codex.json", "RawJSON"];
p239 = Import["/tmp/cf303_soft_residue_p239d47_codex.json", "RawJSON"];
residueData[point_] := ({Lookup[#, {"order", "target_master", "source_master"}],
      Lookup[#, "rational"], Lookup[#, "elliptic_numerator"]} &) /@
    point["residue_entries"];
Print["residue same p images=", residueData[p3] === residueData[p239]];
Print["first residue entries"];
Scan[Print[InputForm[#]] &, Take[residueData[p3], 12]];
ff[expr_, rules_, prime_] := Module[{value = Together[expr /. rules]},
  Mod[Numerator[value] PowerMod[Mod[Denominator[value], prime], -1, prime],
    prime]];
bMatrix[point_, epsilonValue_] := Module[
  {prime = point["prime"], rows = point["source_rows"], matrix},
  matrix = ConstantArray[0, {2, Length[rows]}];
  Scan[Function[entry, With[
    {row = First@FirstPosition[{44, 45}, entry["target_master"]],
     column = First@FirstPosition[rows, entry["source_master"]],
     order = entry["order"], value = First[entry["rational"]]},
    matrix[[row, column]] = Mod[matrix[[row, column]] +
      value PowerMod[epsilonValue, order, prime], prime]]],
    point["residue_entries"]];
  matrix];
Scan[Function[epsilonValue, Module[{prime = p3["prime"], m3, m239,
    s3, s239, projected3, projected239},
  m3 = bMatrix[p3, epsilonValue];
  m239 = bMatrix[p239, epsilonValue];
  s3 = Map[ff[#, {p -> 3, eps -> epsilonValue}, prime] &,
    frame["ProductionInput", "AcceptedZPathJunction", "SourceModeMap"], {2}];
  s239 = Map[ff[#, {p -> Mod[239 PowerMod[47, -1, prime], prime],
        eps -> epsilonValue}, prime] &,
    frame["ProductionInput", "AcceptedZPathJunction", "SourceModeMap"], {2}];
  projected3 = Mod[m3 . s3, prime];
  projected239 = Mod[m239 . s239, prime];
  Print["projected B.Source eps=", epsilonValue, " equal=",
    projected3 === projected239, " p3=", InputForm[projected3],
    " p239=", InputForm[projected239]]]], {5, 7}];
inheritedVectors = {
  {1 -> 1}, {2 -> 1}, {12 -> 1},
  {21 -> 2, 22 -> -3}, {22 -> 1},
  {29 -> 2, 30 -> -3}, {30 -> 1}};
Scan[Function[epsilonValue, Module[{prime = p3["prime"], m3, m239,
    projection3, projection239},
  m3 = bMatrix[p3, epsilonValue]; m239 = bMatrix[p239, epsilonValue];
  projection3 = Mod[m3 . Transpose[Map[Function[rules,
        Table[Lookup[Association[rules], row, 0],
          {row, p3["source_rows"]}]], inheritedVectors]], prime];
  projection239 = Mod[m239 . Transpose[Map[Function[rules,
        Table[Lookup[Association[rules], row, 0],
          {row, p239["source_rows"]}]], inheritedVectors]], prime];
  Print["inherited B modes eps=", epsilonValue, " equal=",
    projection3 === projection239, " p3=", InputForm[projection3],
    " p239=", InputForm[projection239]]]], {5}];
