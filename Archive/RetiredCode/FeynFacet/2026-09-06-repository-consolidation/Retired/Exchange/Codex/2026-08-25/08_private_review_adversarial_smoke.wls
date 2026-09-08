#!/usr/bin/env wolframscript
(* Bounded adversarial probes for the 2026-08-25 Fable hardening review.
   This is review evidence only; it does not modify package state on disk. *)

root = Directory[];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "FeynFacet", "Private",
  "MultiquadraticAlgebra.wl"}]];
Get[FileNameJoin[{root, "FeynFacet", "Private",
  "MultiquadraticStripSolve.wl"}]];

private[name_String] := Symbol["FeynFacet`Private`" <> name];
channelRecord = private["multiquadraticStripForcingChannelRecord"];
channelAccept = private["multiquadraticStripForcingChannelsAccept"];
fieldCompose = private["multiquadraticFieldCompose"];
dlogCertificate = private["multiquadraticStripLetterDLogCertificate"];
compactAdmission = private["multiquadraticStripCompactDLogAdmission"];
intern = private["multiquadraticStripIntern"];
internStatistics = private["multiquadraticStripInternStatistics"];
clearCaches = private["multiquadraticStripCompileCacheClear"];
candidateLetters = private["multiquadraticStripCandidateLetters"];

Clear[x, y, eps, eta];

rootsPlus = {<|"Root" -> Sqrt[x], "RootSquare" -> x|>};
rootsMinus = {<|"Root" -> -Sqrt[x], "RootSquare" -> x|>};
forcing = {{{Sqrt[x]}}, {{0}}};
channels = {{{{0, 1}}}, {{{0, 0}}}};
signedSeal = channelRecord[channels, forcing, rootsPlus, {x, y}, eps];
signVerdict = channelAccept[signedSeal, forcing, rootsMinus, {x, y}, eps];

wrongChannels = {{{{1, 0}}}, {{{0, 0}}}};
remintedWrongSeal = channelRecord[
  wrongChannels, forcing, rootsPlus, {x, y}, eps];
wrongSealVerdict = channelAccept[
  remintedWrongSeal, forcing, rootsPlus, {x, y}, eps];

wrongForm = {0, 0};
wrongDLogRecord = <|
  "Letter" -> x,
  "OneForm" -> wrongForm,
  "DLogCertificate" -> dlogCertificate[x, wrongForm, {x, y}, eps]|>;
wrongDLogVerdict = compactAdmission[
  wrongDLogRecord, wrongForm, {x, y}, eps, "CertifiedOrExact"];

clearCaches[];
Block[{
    FeynFacet`Private`$multiquadraticStripPoolByteLimit =
      <|"OneForm" -> 1000.|>,
    FeynFacet`Private`$multiquadraticStripPoolOversizeBytes =
      <|"OneForm" -> 1000.|>,
    FeynFacet`Private`$multiquadraticStripPoolEntryLimit =
      <|"OneForm" -> 8|>},
  intern["OneForm", Range[100000], Function[
    <|"Channels" -> {}, "Compiled" -> {}, "Path" -> "DecomposedForm"|>]]];
poolStats = internStatistics[];
poolActualBytes = ByteCount[
  FeynFacet`Private`$multiquadraticStripInternPools];

etaStrip = {
  {{{eta/x}}, {{0}}},
  {{{0}}, {{0}}},
  {{{0}}, {{0}}}};
etaCandidates = candidateLetters[
  etaStrip, {}, {x, y}, eta, <||>,
  "RegulatorSampleCount" -> 1, "AlgebraicLetters" -> {}];

Print[<|
  "RootSignSealStatus" -> Lookup[signVerdict, "Status", Missing[]],
  "AcceptedSignBasisComposition" -> fieldCompose[channels[[1, 1, 1]], rootsMinus],
  "RemintedWrongChannelSealStatus" ->
    Lookup[wrongSealVerdict, "Status", Missing[]],
  "RemintedChannelsComposeTo" ->
    fieldCompose[wrongChannels[[1, 1, 1]], rootsPlus],
  "OriginalForcingEntry" -> forcing[[1, 1, 1]],
  "SelfMintedWrongDLogAdmission" -> wrongDLogVerdict,
  "ReportedOneFormPoolBytes" -> Lookup[poolStats["OneForm"], "Bytes", Missing[]],
  "ActualPoolByteCount" -> poolActualBytes,
  "EtaRegulatorEnteredCandidateForms" ->
    ! FreeQ[Lookup[etaCandidates, "OneForms", {}], eta]
|>];

Exit[0];
