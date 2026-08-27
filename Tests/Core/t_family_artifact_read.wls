#!/usr/bin/env wolframscript
(* FamilyArtifactRead: the mandatory context-guarded artifact reader
   (FeynFacet/Private/FamilyEpsForm.wl), rebased 2026-08-23 on the
   hydration pattern of MultiquadraticStripSolve.wl (port-agent defect
   J: Quiet[Check[Get[file], $Failed]] discards a valid artifact after
   any benign message, and the context guard hardcoded Global`).

   Acceptance criteria, stated before the run:
     - a VALID artifact whose evaluation emits a benign message is
       returned, not $Failed, and the message is visible in the
       diagnostic $familyArtifactReadMessages;
     - a clean artifact reads exactly as before, records no message, and
       its bare symbols land in Global` even when another context that
       defines the same names sits in front of Global` on the context
       path (the CANONICA hazard this reader exists for);
     - the failure modes stay typed: a missing file, a truncated file, a
       stray-bracket file and binary garbage all return $Failed;
     - the optional second argument parses the artifact into an explicit
       context and creates NO Global` symbol;
     - the one-argument call is exactly the two-argument call with
       "Global`", and a context without a trailing backtick is refused. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];

scratch = FileNameJoin[{$TemporaryDirectory,
  "ft_family_artifact_read_" <> ToString[$ProcessID]}];
Quiet[CreateDirectory[scratch, CreateIntermediateDirectories -> True]];
write[name_String, text_String] := Module[{file, stream},
  file = FileNameJoin[{scratch, name}];
  stream = OpenWrite[file];
  WriteString[stream, text];
  Close[stream];
  file];
messages[] := FeynFacet`Private`$familyArtifactReadMessages;

(* ---- a valid artifact that emits a benign message during Get ---- *)
messageFile = write["message_artifact.wl",
  "(qqqArtifactBenignProbe::benign = \"benign message emitted while the artifact evaluates\";\n" <>
  " Message[qqqArtifactBenignProbe::benign];\n" <>
  " <|\"Schema\" -> \"ProbeV1\", \"Payload\" -> {1, 2, 3}|>)\n"];
messageValue = FeynFacet`FamilyArtifactRead[messageFile];
messageMessages = messages[];
FTTest`FTAssert["a benign message during Get no longer discards the artifact",
  AssociationQ[messageValue] &&
    messageValue === <|"Schema" -> "ProbeV1", "Payload" -> {1, 2, 3}|>];
FTTest`FTAssert["the benign message is collected as a diagnostic",
  ListQ[messageMessages] && Length[messageMessages] >= 1 &&
    StringContainsQ[ToString[messageMessages], "benign"]];

(* ---- a clean artifact: value, no messages, Global` symbols ---- *)
cleanFile = write["clean_artifact.wl",
  "<|\"Schema\" -> \"CleanV1\", \"Symbol\" -> qqqArtifactCleanSymbol,\n" <>
  "  \"Rational\" -> 3/4, \"Matrix\" -> {{1, 2}, {3, 4}}|>\n"];
cleanValue = FeynFacet`FamilyArtifactRead[cleanFile];
cleanMessages = messages[];
FTTest`FTAssert["a clean artifact reads exactly and records no message",
  AssociationQ[cleanValue] && cleanValue["Schema"] === "CleanV1" &&
    cleanValue["Rational"] === 3/4 &&
    cleanValue["Matrix"] === {{1, 2}, {3, 4}} && cleanMessages === {}];
FTTest`FTAssert["the one-argument call is the two-argument call at Global`",
  FeynFacet`FamilyArtifactRead[cleanFile] ===
    FeynFacet`FamilyArtifactRead[cleanFile, "Global`"]];

(* the reader exists because a package context loaded earlier in the
   session can otherwise capture bare artifact symbols; put a shadowing
   context in front of Global` and check the guard still wins *)
Symbol["FeynFacet`ArtifactShadowProbe`qqqArtifactCleanSymbol"];
shadowedValue = Block[
  {$ContextPath = Prepend[$ContextPath, "FeynFacet`ArtifactShadowProbe`"],
   $Context = "FeynFacet`ArtifactShadowProbe`"},
  FeynFacet`FamilyArtifactRead[cleanFile]];
FTTest`FTAssert["the default context guard still parses bare symbols into Global`",
  AssociationQ[shadowedValue] && shadowedValue === cleanValue &&
    (Context @@ {shadowedValue["Symbol"]}) === "Global`"];

(* ---- typed failures ---- *)
missingFile = FileNameJoin[{scratch, "no_such_artifact.wl"}];
truncatedFile = write["truncated_artifact.wl",
  "<|\"Schema\" -> \"CleanV1\", \"Payload\" -> {1, 2,"];
bracketFile = write["bracket_artifact.wl",
  "<|\"Schema\" -> \"CleanV1\", \"Payload\" -> {1, 2, 3}]]|>\n"];
binaryFile = write["binary_artifact.wl",
  FromCharacterCode[{60, 124, 34, 65, 34, 32, 45, 62, 32, 1, 2, 3}]];
FTTest`FTAssert["a missing file fails typed",
  FeynFacet`FamilyArtifactRead[missingFile] === $Failed];
FTTest`FTAssert["a truncated artifact fails typed",
  FeynFacet`FamilyArtifactRead[truncatedFile] === $Failed];
FTTest`FTAssert["a stray-bracket artifact fails typed",
  FeynFacet`FamilyArtifactRead[bracketFile] === $Failed];
FTTest`FTAssert["binary garbage fails typed",
  FeynFacet`FamilyArtifactRead[binaryFile] === $Failed];
FTTest`FTAssert["a context without a trailing backtick is refused",
  FeynFacet`FamilyArtifactRead[cleanFile, "Global"] === $Failed];

(* ---- the explicit context isolates the artifact's symbols ---- *)
isolatedFile = write["isolated_artifact.wl",
  "<|\"Schema\" -> \"IsolatedV1\", \"Symbol\" -> qqqArtifactIsolatedSymbol|>\n"];
isolationContext = "FeynFacet`ArtifactReadProbe`";
(* System`Names, not Names: FeynCalc shadows the latter in this session *)
FTTest`FTAssert["no Global` symbol exists before the isolated read",
  System`Names["Global`qqqArtifactIsolatedSymbol"] === {}];
isolatedValue = FeynFacet`FamilyArtifactRead[isolatedFile, isolationContext];
FTTest`FTAssert["the explicit context receives the artifact's symbols",
  AssociationQ[isolatedValue] && isolatedValue["Schema"] === "IsolatedV1" &&
    (Context @@ {isolatedValue["Symbol"]}) === isolationContext &&
    System`Names[isolationContext <> "qqqArtifactIsolatedSymbol"] =!= {}];
FTTest`FTAssert["the explicit context creates no Global` symbol",
  System`Names["Global`qqqArtifactIsolatedSymbol"] === {}];
defaultValue = FeynFacet`FamilyArtifactRead[isolatedFile];
FTTest`FTAssert["the default read of the same artifact stays in Global`",
  AssociationQ[defaultValue] &&
    (Context @@ {defaultValue["Symbol"]}) === "Global`" &&
    defaultValue =!= isolatedValue];

(* ---- an artifact written by FamilyArtifactWrite round-trips ---- *)
roundTripFile = FileNameJoin[{scratch, "round_trip.wl"}];
roundTripValue = <|"Schema" -> "RoundTripV1", "Blocks" -> {{1, 2}, {3}},
  "Regulator" -> Global`eps, "Value" -> 7/3|>;
FeynFacet`FamilyArtifactWrite[roundTripValue, roundTripFile];
FTTest`FTAssert["a written artifact round-trips through the reader",
  FeynFacet`FamilyArtifactRead[roundTripFile] === roundTripValue &&
    messages[] === {}];

Quiet[DeleteDirectory[scratch, DeleteContents -> True]];
FTTest`FTReport[];
