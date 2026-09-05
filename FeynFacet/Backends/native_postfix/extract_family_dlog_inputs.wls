#!/usr/bin/env wolframscript

(* Extract only the data needed to compute common dlog residues.  This is a
   computation input, not a family certificate: no inverse, gauge, flatness,
   or source-connection identity is evaluated here. *)

If[Length[$ScriptCommandLine] =!= 3,
  Print["usage: extract_family_dlog_inputs.wls FAMILY_EPSFORM OUTPUT"];
  Exit[2]];

input = ExpandFileName[$ScriptCommandLine[[2]]];
output = ExpandFileName[$ScriptCommandLine[[3]]];
started = AbsoluteTime[];
record = Quiet[Check[Get[input], $Failed]];
If[! AssociationQ[record], Print["input is not an association"]; Exit[1]];

required = {"Variables", "Regulator", "ChartRecord", "EpsFormX",
  "EpsFormY", "Letters", "OffDiagonalBlockSolutions", "SectorCertificates",
  "Status", "Family"};
If[! AllTrue[required, KeyExistsQ[record, #] &],
  Print["missing keys: ", Complement[required, Keys[record]]]; Exit[1]];

variables = record["Variables"];
letters = record["Letters"];
If[! MatchQ[variables, {_Symbol, _Symbol}] || ! ListQ[letters],
  Print["invalid variables or letters"]; Exit[1]];

dimension = Length[record["EpsFormX"]];
rootRecords = Lookup[record["ChartRecord"], "Roots", {}];
computationRoots = Map[Function[rootRecord,
  <|"Root" -> rootRecord["Root"],
    "RootSquare" -> Together[rootRecord["Root"]^2]|>], rootRecords];
result = <|
  "Schema" -> "FamilyDLogComputationSidecarV1",
  "Family" -> record["Family"],
  "SourceStatus" -> record["Status"],
  "Variables" -> variables,
  "Regulator" -> record["Regulator"],
  "Dimension" -> dimension,
  "Roots" -> computationRoots,
  "Letters" -> letters,
  "LetterX" -> ({D[#, variables[[1]]]/#} & /@ letters),
  "LetterY" -> ({D[#, variables[[2]]]/#} & /@ letters),
  "AcceptedBlockEvidence" -> <|
    "OffDiagonalBlockSolutions" -> record["OffDiagonalBlockSolutions"],
    "SectorCertificates" -> record["SectorCertificates"]|>,
  "Purpose" -> "ComputeCommonDLogResiduesForTransport"
|>;

Put[result, output];
Print[InputForm[<|
  "Status" -> "FamilyDLogComputationInputWritten",
  "Family" -> result["Family"],
  "Dimension" -> dimension,
  "LetterCount" -> Length[letters],
  "Bytes" -> FileByteCount[output],
  "Seconds" -> N[AbsoluteTime[] - started]|>]];
