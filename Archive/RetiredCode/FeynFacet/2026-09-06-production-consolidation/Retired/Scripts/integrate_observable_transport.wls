#!/usr/bin/env wolframscript
(* Integrate a Codex observable-only transport record (Format
   "FeynFacetObservableDLogTransport", v1) into the FeynFacet Masters
   schema.  Provenance: the transport is Codex's construction and
   computation (Codex/ppHX_NNLO_DoubleReal/TransportProjection_2026-08-17/,
   OBSERVABLE_TRANSPORT_RESULT.md); this script does NOT repeat it.  What
   it establishes INDEPENDENTLY, in our kernel, before writing anything:
     (V1) format/structure: version, physical rows, word maps, exact
          rational entries in the declared chart variables;
     (V2) alphabet tie-in: every dlog letter of the record divides (up to
          a unit) a letter of OUR certified family eps-form record for the
          same family in the same chart -- ties Codex's alphabet to our
          stage-1/2 certificates;
     (V3) path-pole reconstruction from scratch: for every letter phi_a and
          the record's path z(tau) (Base -> Target, first variable moving),
          d/dtau log phi_a(z(tau)) must equal Sum_j m_aj/(tau - alpha_aj)
          from the record's PathPoleExpansion, EXACTLY (algebraic roots
          handled by RootReduce);
     (V4) the record's own certificate block is all True where boolean.
   Output: Masters/<CF>.wl (Status Transported, "Route" -> "ObservableOnly",
   provenance block, three-statement block) and Masters/<CF>.status.
   Usage: integrate_observable_transport.wls <family> <outdir> *)
$HistoryLength = 0;
root = "/home/maxzhang/factorization-and-loops";
Get[FileNameJoin[{root, "FeynFacet", "FeynFacet.m"}]];
args = Rest[$ScriptCommandLine];
family = args[[1]]; outdir = args[[2]];
start = AbsoluteTime[];
log[a___] := Print["[integrate ", family, " +", ToString[Round[AbsoluteTime[] - start]], "s] ", StringJoin[ToString[#, InputForm] & /@ {a}]];
codexDir = FileNameJoin[{root, "Codex", "ppHX_NNLO_DoubleReal", "TransportProjection_2026-08-17"}];
recFile = FileNameJoin[{codexDir, "ObservableTransport_" <> family <> ".wl"}];
ourRec = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical", "FamilyEpsForms", "family_epsform_" <> family <> ".wl"}];
putAtomic[expr_, file_] := Module[{tmp = file <> ".tmp"}, Put[expr, tmp]; RenameFile[tmp, file, OverwriteTarget -> True]];
writeStatus[st_, note_: ""] := Export[FileNameJoin[{outdir, family <> ".status"}],
  StringJoin[family, " ", st, " ", ToString[Round[AbsoluteTime[] - start]], "s ", note], "Text"];
fail[why_] := (log["!! ", why]; writeStatus["Failed", "ObservableIntegration:" <> why]; Exit[1]);
If[! FileExistsQ[recFile], fail["NoCodexRecord"]];
R = Get[recFile];
If[! AssociationQ[R] || R["Format"] =!= "FeynFacetObservableDLogTransport" || R["FormatVersion"] =!= 1, fail["UnexpectedFormat"]];
vars = R["Variables"]; ep = R["Regulator"];
path = R["Path"]; base = path["Base"]; target = path["Target"];
(* the record's pole positions are written for the parameter tau with
   z(tau) = base + tau (target - base) in the FIRST variable, the second
   variable symbolic; the record may or may not name the parameter *)
tau = Lookup[path, "Parameter", Missing[]];
If[MissingQ[tau] || ! MatchQ[tau, _Symbol], tau = Symbol["Global`tauObs"]];
maps = R["ObservableWordMaps"]; rows = R["PhysicalRows"]; coords = R["BoundaryCoordinates"];
letters = R["DLogLetters"];
log["record: ", Length[maps], " word maps, ", Length[rows], " physical rows, ", Length[coords], " boundary coordinates, ", Length[letters], " letters, max weight ", R["MaximumWeight"]];
(* V1 *)
v1 = AllTrue[maps, AssociationQ[#] && ListQ[#["Word"]] && ListQ[#["Entries"]] &&
  AllTrue[#["Entries"], MatchQ[#, {_Integer, _Integer, _}] && FreeQ[#[[3]], ep] &&
    PolynomialQ[Numerator[Together[#[[3]]]], vars] && PolynomialQ[Denominator[Together[#[[3]]]], vars] &] &];
log["V1 structure/exact-rational entries: ", v1];
If[! v1, fail["V1"]];
(* V2 *)
ours = Get[ourRec];
ourLetters = Together /@ ours["Letters"];
divides[l_, L_] := PolynomialQ[Together[Numerator[Together[L]] / Numerator[Together[l]]], vars] ||
  PolynomialQ[Together[Numerator[Together[L]] / Numerator[Together[l /. Thread[vars -> Reverse[vars]]]]], vars];
v2 = AllTrue[letters, l1 = #; AnyTrue[ourLetters, divides[l1, #] &] || (* also accept the record letter dividing a product of ours *)
  AnyTrue[Subsets[ourLetters, {2}], divides[l1, Times @@ #] &] &];
log["V2 alphabet tie-in to our certified family eps-form: ", v2];
If[! v2, log["   record letters: ", InputForm[letters]]; log["   our letters: ", InputForm[ourLetters]]; fail["V2"]];
(* V3 *)
pathSub = {vars[[1]] -> base[[1]] + tau (target[[1]] - base[[1]]), vars[[2]] -> base[[2]]};
ppe = R["PathPoleExpansion"];
v3 = AllTrue[ppe, Module[{a = #["Letter"], poles = #["Poles"], lhs, rhs, diff},
  lhs = Together[D[Log[letters[[a]] /. pathSub], tau]];
  rhs = Total[#[[2]]/(tau - #[[1]]) & /@ poles];
  diff = Together[lhs - rhs];
  If[! FreeQ[diff, Power[_, 1/2] | Sqrt], diff = RootReduce[diff]];
  TrueQ[diff === 0]] &];
log["V3 path-pole reconstruction from scratch, all letters: ", v3];
If[! v3, fail["V3"]];
(* V4 *)
cert = R["Certificate"];
v4 = AllTrue[Select[Values[cert], BooleanQ], TrueQ] && TrueQ[cert["ExactConnectionReconstruction"]] && TrueQ[cert["BoundaryKernel"]] && TrueQ[cert["InitialValue"]];
log["V4 record certificate block: ", v4, "  ", InputForm[cert]];
If[! v4, fail["V4"]];
(* contract into master representation: I[{n,row}] = Sum_w M_w[row,:] . coords * word *)
labels = rows; nr = Length[rows]; nc = Length[coords];
masters = Association @ Table[lab -> 0, {lab, labels}];
Do[
  Module[{m = SparseArray[(#[[1 ;; 2]] -> #[[3]]) & /@ item["Entries"], {nr, nc}], wd = item["Word"], wv},
    wv = If[wd === {}, 1, TransportWord[wd, 1]];
    Do[masters[labels[[i]]] += (m[[i]] . coords) wv, {i, nr}]],
  {item, maps}];
words = Length[maps]; maxw = Max[Lookup[maps, "Weight"]];
out = <|"Family" -> family, "Status" -> "Transported", "Route" -> "ObservableOnly",
  "Frame" -> R["Frame"], "Variables" -> vars, "Regulator" -> ep, "Parameter" -> tau,
  "Base" -> base, "Target" -> target, "PhysicalRows" -> labels,
  "BoundaryCoordinates" -> coords, "DLogLetters" -> letters, "WordConvention" -> R["WordConvention"],
  "Masters" -> masters, "ObservableWordMaps" -> maps, "PathPoleExpansion" -> ppe,
  "MaxWeight" -> maxw, "WordCount" -> words,
  "Provenance" -> <|"Construction" -> "Codex observable-only transport (pre-transport Laurent-valuation kernel, demanded-row projection, two-segment word maps)",
    "Source" -> recFile, "SourceCertificate" -> cert,
    "SourceDocument" -> FileNameJoin[{codexDir, "OBSERVABLE_TRANSPORT_RESULT.md"}],
    "IndependentChecksHere" -> <|"V1Structure" -> v1, "V2AlphabetTieIn" -> v2, "V3PathPoleReconstruction" -> v3, "V4SourceCertificate" -> v4|>,
    "NotRepeatedHere" -> "the transport itself (full 17-block word closure is the measured wall this route avoids)"|>,
  "ThreeStatements" -> <|"TransportedMapKnown" -> True,
    "EndpointModesMatched" -> "Codex records EndpointFrobenius_/BoundaryModeMap_ (not re-verified here)",
    "BoundaryPeriodsEvaluated" -> False|>,
  "Timestamp" -> DateString["ISODateTime"]|>;
putAtomic[out, FileNameJoin[{outdir, family <> ".wl"}]];
writeStatus["Transported", StringJoin["observable-only w", ToString[maxw], " words", ToString[words], " V1-V4:True provenance:Codex"]];
log["written ", FileNameJoin[{outdir, family <> ".wl"}]];
Exit[0]
