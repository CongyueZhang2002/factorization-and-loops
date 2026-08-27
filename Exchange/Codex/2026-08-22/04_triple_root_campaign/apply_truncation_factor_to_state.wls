#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 4, Exit[64]];
projectRoot = ExpandFileName[arguments[[1]]];
stateFile = ExpandFileName[arguments[[2]]];
factorFile = ExpandFileName[arguments[[3]]];
outputFile = ExpandFileName[arguments[[4]]];

Get[FileNameJoin[{projectRoot, "Addon", "Load", "LoadFACET.wl"}]];
state = Get[stateFile];
artifact = Get[factorFile];
factor = artifact["Factor"];
dimension = artifact["Dimension"];
epsilon = FirstCase[state["A"], symbol_Symbol /;
  SymbolName[symbol] === "eps", Missing["Regulator"], Infinity];
If[! (AssociationQ[state] && AssociationQ[factor] &&
    Lookup[factor, "Status", None] === "OK" &&
    IntegerQ[dimension] && dimension > 0 && SymbolQ[epsilon]),
  Print["TRAPPLY FAIL invalid_input"];
  Exit[65]];

n = Length[state["A"][[1]]];
transformation = IdentityMatrix[n];
inverse = IdentityMatrix[n];
transformation[[1 ;; dimension, 1 ;; dimension]] =
  factor["Transformation"];
inverse[[1 ;; dimension, 1 ;; dimension]] = factor["Inverse"];

newA = Table[FeynFacet`Private`familyRegulatorConjugate[
  inverse, state["A"][[mu]], transformation], {mu, 2}];
newS = FeynFacet`Private`familyRegulatorSparseDot[
  state["S"], transformation, False];
newSInverse = FeynFacet`Private`familyRegulatorSparseDot[
  inverse, state["SInverse"], True];

epsFactoredQ[connection_] := AllTrue[Flatten[connection],
  TrueQ[Together[#1] === 0] || FreeQ[Together[#1/epsilon], epsilon] &];
lowerConnection = newA[[All, 1 ;; dimension, 1 ;; dimension]];
inverseQ = AllTrue[Flatten[Map[Together,
  factor["Transformation"].factor["Inverse"] -
    IdentityMatrix[dimension], {2}]], TrueQ[#1 === 0] &];
factoredQ = epsFactoredQ[lowerConnection];
If[! TrueQ[inverseQ && factoredQ],
  Print["TRAPPLY FAIL inverse=", inverseQ,
    " eps_factored=", factoredQ];
  Exit[66]];

newState = Join[state, <|
  "A" -> newA,
  "S" -> newS,
  "SInverse" -> newSInverse,
  "RegulatorFactorizations" -> Append[
    Lookup[state, "RegulatorFactorizations", {}],
    <|"Rows" -> artifact["Sector"],
      "Method" -> "TargetedRationalChart/" <> factor["Method"],
      "ChartRootIndices" -> artifact["RootIndices"],
      "Points" -> factor["Points"],
      "Seconds" -> artifact["Seconds"],
      "SourceArtifact" -> factorFile|>]|>];
If[! DirectoryQ[DirectoryName[outputFile]],
  CreateDirectory[DirectoryName[outputFile],
    CreateIntermediateDirectories -> True]];
temporary = outputFile <> ".tmp";
Put[newState, temporary];
RenameFile[temporary, outputFile, OverwriteTarget -> True];
Print["TRAPPLY sector=", artifact["Sector"],
  " dimension=", dimension,
  " total_dimension=", n,
  " inverse=", inverseQ,
  " eps_factored=", factoredQ,
  " output=", outputFile];
