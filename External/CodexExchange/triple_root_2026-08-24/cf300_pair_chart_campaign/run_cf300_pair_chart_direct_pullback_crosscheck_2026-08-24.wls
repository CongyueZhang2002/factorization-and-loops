#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 4,
  Print["CF300PAIRDIRECT FAIL usage=<project-root> <input.wl> <chart-strip.wxf> <summary.wl>"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
inputFile = ExpandFileName[arguments[[2]]];
chartStripFile = ExpandFileName[arguments[[3]]];
summaryFile = ExpandFileName[arguments[[4]]];
loadFile = FileNameJoin[{projectRoot, "Addon", "Load", "LoadFACET.wl"}];
dependencyFiles = <|
  "LoadFACET" -> loadFile,
  "FeynFacetPublic" -> FileNameJoin[{projectRoot, "FeynFacet", "FeynFacet.m"}],
  "TransportCharts" -> FileNameJoin[{projectRoot, "FeynFacet", "Private", "TransportCharts.wl"}],
  "MasterTransport" -> FileNameJoin[{projectRoot, "FeynFacet", "Private", "MasterTransport.wl"}]
|>;

If[! DirectoryQ[projectRoot] || ! FileExistsQ[inputFile] ||
    ! FileExistsQ[chartStripFile] ||
    ! AllTrue[Values[dependencyFiles], FileExistsQ] || FileExistsQ[summaryFile],
  Print["CF300PAIRDIRECT FAIL invalid input or stale output target"];
  Exit[65]];
If[! DirectoryQ[DirectoryName[summaryFile]],
  CreateDirectory[DirectoryName[summaryFile], CreateIntermediateDirectories -> True]];

inputHashBefore = FileHash[inputFile, "SHA256", "HexString"];
chartStripHashBefore = FileHash[chartStripFile, "SHA256", "HexString"];
driverHashBefore = FileHash[$InputFileName, "SHA256", "HexString"];
dependencyHashesBefore = Map[FileHash[#, "SHA256", "HexString"] &, dependencyFiles];
If[System`Names["FeynFacet`FamilyArtifactRead"] === {}, Get[loadFile]];
If[Map[FileHash[#, "SHA256", "HexString"] &, dependencyFiles] =!= dependencyHashesBefore,
  Print["CF300PAIRDIRECT FAIL package changed while loading"];
  Exit[95]];

writeAtomic[value_, file_] := Module[{temporary, written, renamed},
  temporary = file <> ".tmp." <> StringReplace[CreateUUID[], "-" -> ""];
  If[FileExistsQ[file], Return[$Failed]];
  written = Quiet[Check[Put[value, temporary], $Failed]];
  If[written === $Failed || ! FileExistsQ[temporary], Return[$Failed]];
  renamed = Quiet[Check[RenameFile[temporary, file, OverwriteTarget -> False], $Failed]];
  If[renamed === $Failed || ! FileExistsQ[file], $Failed, file]
];
finish[status_String, data_: <||>, code_: 2] := Module[{result},
  result = Join[<|
    "Status" -> status,
    "InputFile" -> inputFile, "InputSHA256" -> inputHashBefore,
    "ChartStripFile" -> chartStripFile,
    "ChartStripSHA256" -> chartStripHashBefore,
    "DriverFile" -> $InputFileName, "DriverSHA256" -> driverHashBefore,
    "DependencyHashes" -> dependencyHashesBefore
  |>, data];
  If[writeAtomic[result, summaryFile] === $Failed,
    Print["CF300PAIRDIRECT FAIL atomic summary write"];
    Exit[98]];
  Print["CF300PAIRDIRECT RESULT status=", status, " output=", summaryFile];
  Exit[code]
];
zeroQ[expression_] := AllTrue[Flatten[{expression}], TrueQ[Together[#] === 0] &];

Print["CF300PAIRDIRECT stage=load time=", DateString["ISODateTime"]];
record = FeynFacet`FamilyArtifactRead[inputFile];
payload = Quiet[Check[Import[chartStripFile, "WXF"], $Failed]];
If[FileHash[inputFile, "SHA256", "HexString"] =!= inputHashBefore ||
    FileHash[chartStripFile, "SHA256", "HexString"] =!= chartStripHashBefore,
  finish["InputChangedDuringLoad", <||>, 96]];
If[! AssociationQ[record] || ! AssociationQ[payload] ||
    Lookup[record, {"Family", "Sector", "LowerSector"}, None] =!= {"CF300", 12, 9} ||
    Lookup[payload, "Status", None] =!= "CF300PairChartRationalStripV1" ||
    Lookup[payload, "InputSHA256", None] =!= inputHashBefore,
  finish["PayloadProvenanceMismatch", <||>, 66]];

{p, q} = payload["Variables"];
{x, y} = record["Variables"];
chart = payload["Chart"];
subst = chart["Subst"];
rootRules = MapThread[
  Sqrt[#1["RootSquare"]] -> #2 &,
  {payload["UsedRoots"], payload["RootImages"]}];
imageX = Together[x /. subst];
imageY = Together[y /. subst];
jacobian = {
  {D[imageX, p], D[imageX, q]},
  {D[imageY, p], D[imageY, q]}
};

manualComponents[pair_] := Map[
  Function[matrix, Map[Together, matrix /. rootRules /. subst, {2}]],
  pair];
directPull[pair_] := Module[{components = manualComponents[pair], mx, my},
  {mx, my} = components;
  {
    Map[Together, jacobian[[1, 1]] mx + jacobian[[2, 1]] my, {2}],
    Map[Together, jacobian[[1, 2]] mx + jacobian[[2, 2]] my, {2}]
  }
];
wrongPull[pair_] := Module[{components = manualComponents[pair], mx, my},
  {mx, my} = components;
  {
    Map[Together, jacobian[[1, 1]] mx + jacobian[[1, 2]] my, {2}],
    Map[Together, jacobian[[2, 1]] mx + jacobian[[2, 2]] my, {2}]
  }
];

Print["CF300PAIRDIRECT stage=ordinary-D-direct-pullback time=", DateString["ISODateTime"]];
{directSeconds, directStrip} = AbsoluteTiming[directPull /@ record["Strip"]];
directResidual = MapThread[Subtract, {directStrip, payload["Strip"]}, 1];
If[! zeroQ[directResidual],
  finish["DirectPullbackMismatch", <|
    "DirectSeconds" -> directSeconds,
    "NonzeroResidualPositions" -> Position[directResidual, item_ /; ! zeroQ[item], {0, Infinity}]
  |>, 2]];

Print["CF300PAIRDIRECT stage=wrong-jacobian-mutant time=", DateString["ISODateTime"]];
{mutantSeconds, mutantStrip} = AbsoluteTiming[wrongPull /@ record["Strip"]];
mutantResidual = MapThread[Subtract, {mutantStrip, payload["Strip"]}, 1];
If[zeroQ[mutantResidual],
  finish["WrongJacobianMutantUnexpectedlyPassed", <|
    "DirectSeconds" -> directSeconds, "MutantSeconds" -> mutantSeconds|>, 2]];

finish["CF300PairChartDirectPullbackPassedV1", <|
  "DirectSeconds" -> directSeconds,
  "MutantSeconds" -> mutantSeconds,
  "DirectOrdinaryDFormula" ->
    "A_p = x_p A_x + y_p A_y; A_q = x_q A_x + y_q A_y",
  "DirectResidualsZero" -> True,
  "WrongJacobianOrientationRejected" -> True,
  "ChartJacobianDetNonzero" -> ! TrueQ[Together[Det[jacobian]] === 0],
  "StripLeafCount" -> LeafCount[directStrip],
  "PackageUnmodifiedDuringCheck" ->
    (Map[FileHash[#, "SHA256", "HexString"] &, dependencyFiles] === dependencyHashesBefore)
|>, 0];
