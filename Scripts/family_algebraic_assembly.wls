#!/usr/bin/env wolframscript

$HistoryLength = 0;

repositoryRoot = DirectoryName[DirectoryName[ExpandFileName[$InputFileName]]];
Get[FileNameJoin[{repositoryRoot, "Addon", "Load", "LoadFACET.wl"}]];

arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 5,
  Print["Usage: family_algebraic_assembly.wls " <>
    "<family> <differential-system.wl> <block-assignments.wl> " <>
    "<class-form-directory> <output.wl>"];
  Exit[64]
];

{family, systemFile, assignmentFile, formDirectory, outputFile} = arguments;

read[file_, description_] := Module[{value},
  If[! FileExistsQ[file],
    Print[description, " does not exist: ", file]; Exit[66]];
  value = Quiet[Check[Get[file], $Failed]];
  If[value === $Failed,
    Print[description, " could not be read: ", file]; Exit[65]];
  value
];

writeAtomic[value_, file_] := Module[{directory, temporary},
  directory = DirectoryName[file];
  If[! DirectoryQ[directory],
    CreateDirectory[directory, CreateIntermediateDirectories -> True]];
  temporary = file <> ".tmp-" <> ToString[$ProcessID];
  Put[value, temporary];
  RenameFile[temporary, file, OverwriteTarget -> True]
];

v = Symbol["Global`v"];
w = Symbol["Global`w"];
eps = Symbol["Global`eps"];

de = read[systemFile, "Differential system"];
assignments = read[assignmentFile, "Block assignments"];
If[! AssociationQ[de] || ! ListQ[assignments],
  Print["The differential system or block assignments have the wrong form"];
  Exit[65]
];

blocks = ({#["Rows"], #["ClassID"]} &) /@
  Select[assignments, Lookup[#, "Family", None] === family &];
If[blocks === {}, Print["No block assignments for ", family]; Exit[65]];

frame = FeynFacet`FamilyRootData[family];
If[! AssociationQ[frame] ||
    Lookup[frame, "CoefficientField", None] =!= "Multiquadratic",
  Print[family, " does not have a declared multiquadratic frame"];
  Exit[65]
];

system = <|"Family" -> family,
  "Basis" -> Lookup[de, "BlockBasis", Lookup[de, "Basis", None]],
  "Av" -> de["Av"], "Aw" -> de["Aw"]|>;

start = AbsoluteTime[];
result = FeynFacet`AssembleFamilyDifferentialSystemWithEpsilonFormDiagonalBlocks[system, frame,
  "SourceVariables" -> {v, w}, "Regulator" -> eps,
  "Blocks" -> blocks,
  "FormDirectory" -> formDirectory, "Verbose" -> True];

If[! AssociationQ[result] || result["Status"] =!=
    "FamilyDifferentialSystemAssembledWithEpsilonFormDiagonalBlocks",
  Print[family, " assembly failed: ",
    InputForm[KeyTake[result, {"Status", "Family", "Failures"}]]];
  Exit[1]
];

census = FeynFacet`FamilySquareRootGeneratorCensus[
  result["FamilyDifferentialSystem"], frame];
If[census["Status"] =!= "ExactSquareRootGeneratorCensus",
  Print[family, " root census failed: ", InputForm[census]];
  Exit[1]
];

result = Join[result, <|"RootCensus" -> census,
  "SourceFiles" -> <|"DifferentialSystem" -> ExpandFileName[systemFile],
    "BlockAssignments" -> ExpandFileName[assignmentFile],
    "ClassForms" -> ExpandFileName[formDirectory]|>,
  "TotalSeconds" -> AbsoluteTime[] - start|>];
writeAtomic[result, outputFile];

Print[family, " family system assembled with epsilon-form diagonal blocks: ",
  result["FamilyDifferentialSystem"]["N"], " masters, ",
  Length[result["FamilyDifferentialSystem"]["Blocks"]],
  " blocks, root counts ",
  InputForm[census["SquareRootGeneratorCountHistogram"]], ", maximum ",
  census["MaximumSquareRootGeneratorCount"], ", ",
  Round[result["TotalSeconds"], 0.01], " s"];
