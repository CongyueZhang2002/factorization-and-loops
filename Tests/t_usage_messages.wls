#!/usr/bin/env wolframscript
(* Every exported FeynFacet symbol keeps the usage message FeynFacet.m
   defines for it, and the attributes set there survive the private-file
   load.  Regression test for the 2026-08-21 finding that private files
   ClearAll'ed 34 public symbols (ClearAll removes messages), which left
   `?Symbol` empty for them. *)
root = ParentDirectory[DirectoryName[$InputFileName]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
symbols = System`Names["FeynFacet`*"];
usageQ[name_] := StringQ[ToExpression[name <> "::usage"]];
missing = Select[symbols, ! usageQ[#] &];
checks = <|
  "ExportedSymbolsPresent" -> Length[symbols] >= 90,
  "EveryExportedSymbolHasUsage" -> missing === {},
  "CutKeepsHoldAll" -> Attributes[FeynFacet`Cut] === {HoldAll},
  "PartialFractionKeepsOptions" -> Options[FeynFacet`PartialFraction] =!= {},
  "PublicDefinitionsLoaded" -> AllTrue[{FeynFacet`DiagonalBlockEpsForm,
    FeynFacet`SolveEpsFormStripFiniteField, FeynFacet`TransportFamilyChart,
    FeynFacet`CertifyFamilyEpsilonForm, FeynFacet`SimplifyHardCoefficients},
    Length[DownValues[#]] > 0 &]
|>;
Print[InputForm[checks]];
Print["exported: ", Length[symbols], "  missing usage: ", missing];
Exit[If[And @@ Values[checks], 0, 1]];
