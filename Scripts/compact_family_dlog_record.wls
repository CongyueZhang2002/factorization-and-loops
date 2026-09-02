#!/usr/bin/env wolframscript
(* Adopted 2026-09-02 from the Codex tree (Development/2026-09-01/gpu31_deferred_backend): replaces a family assembly's expanded epsilon matrices by the constant-residue dlog representation produced by the native dlog computation; family-neutral. *)

(* Replace a production assembly's expanded epsilon matrices by their exact
   constant-residue dlog representation.  No family identity is rechecked.

   Round 4 (2026-09-02, agent G on T's certificate): the compact record
   is written ONLY after its transport epsilon valuations are certified
   by FeynFacet`Private`observableTransportCertifyEpsilonValuations (three
   p-adic trials at fresh primes; T_transport_correctness.md section 1).
   The optional TRANSPORT_EPSILON_VALUATIONS file (TMin, BlockLower, e.g.
   from ExactAlgebraicPointValuation) is the CLAIM the certifier checks:
   a claim above the observed orders is refused; without the file the
   valuations are derived from the trials.  On any status other than
   TransportEpsilonValuationsCertified nothing is written, the typed
   status is printed and the exit code is 3 (2 usage, 1 invalid input). *)

If[! MemberQ[{4, 5}, Length[$ScriptCommandLine]],
  Print["usage: compact_family_dlog_record.wls ASSEMBLY DLOG OUTPUT " <>
    "[TRANSPORT_EPSILON_VALUATIONS]"];
  Exit[2]];

(* the certifier lives in the package; artifacts are read through the
   context-guarded reader once the package is on the context path *)
root = DirectoryName[ExpandFileName[$InputFileName], 2];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

assemblyFile = ExpandFileName[$ScriptCommandLine[[2]]];
dlogFile = ExpandFileName[$ScriptCommandLine[[3]]];
outputFile = ExpandFileName[$ScriptCommandLine[[4]]];
valuationFile = If[Length[$ScriptCommandLine] === 5,
  ExpandFileName[$ScriptCommandLine[[5]]], None];
started = AbsoluteTime[];
record = FeynFacet`FamilyArtifactRead[assemblyFile];
dlog = FeynFacet`FamilyArtifactRead[dlogFile];
If[! AssociationQ[record] || ! AssociationQ[dlog],
  Print["assembly or dlog input is invalid"]; Exit[1]];
valuations = If[valuationFile === None, None,
  FeynFacet`FamilyArtifactRead[valuationFile]];
If[valuationFile =!= None &&
    (! AssociationQ[valuations] ||
     ! IntegerQ[Lookup[valuations, "TMin", Missing[]]] ||
     ! VectorQ[Lookup[valuations, "BlockLower", Missing[]], IntegerQ]),
  Print["transport epsilon valuations are invalid"]; Exit[1]];

dimension = Length[Lookup[record, "TTotal", {}]];
If[Lookup[dlog, "Status", None] =!= "ComputedDLogResidues" ||
    ! TrueQ[Lookup[dlog, "Valid", False]] ||
    Lookup[dlog, "Dimension", None] =!= dimension ||
    Length[Lookup[dlog, "Letters", {}]] =!=
      Length[Lookup[dlog, "Residues", {}]],
  Print["dlog computation result has incompatible shape"]; Exit[1]];

ranges = Lookup[record, "Ranges", {}];
If[valuationFile =!= None &&
    Length[valuations["BlockLower"]] =!= Length[ranges],
  Print["transport epsilon valuations do not match the block layout"];
  Exit[1]];
stripSolvers = Lookup[record, "StripSolvers", {}];
pairs = DeleteDuplicates[Lookup[stripSolvers,
  {"Sector", "LowerSector"}, Missing[]]];
expectedPairs = Binomial[Length[ranges], 2];
blockSummary = <|
  "SectorCount" -> Length[ranges],
  "ExpectedOffDiagonalPairs" -> expectedPairs,
  "RecordedOffDiagonalPairs" -> Length[pairs],
  "CompletePairCoverage" -> Length[pairs] === expectedPairs,
  "ZeroForcingCount" -> Count[Lookup[stripSolvers, "Method", None],
    "ZeroForcing"],
  "ComputedBlockCount" -> Length[stripSolvers] -
    Count[Lookup[stripSolvers, "Method", None], "ZeroForcing"]|>;
If[! TrueQ[blockSummary["CompletePairCoverage"]],
  Print["accepted block coverage is incomplete"]; Exit[1]];

compact = Join[
  KeyDrop[record, {"EpsFormX", "EpsFormY", "S", "GateVerdict",
    "GaugeIdentity", "GaugeIdentityRoute", "Flatness", "FlatnessRoute",
    "TTotalInvertible"}],
  <|"Status" -> "TransportReadyEpsilonConnection",
    "SourceAssemblyStatus" -> Lookup[record, "Status", Missing[]],
    "EpsFormRepresentation" -> "ConstantResidueDLog",
    "DLog" -> dlog,
    "BlockAssemblyEvidence" -> blockSummary,
    "Purpose" -> "ObservableTransportInput",
    "CompactionSeconds" -> N[AbsoluteTime[] - started]|>,
  If[valuationFile === None, <||>,
    <|"TransportEpsilonValuations" -> valuations|>]];

(* certify the transport epsilon valuations (the valuation file, when
   given, is the claim; otherwise they are derived) -- nothing is written
   unless the certificate is issued *)
certification = FeynFacet`Private`observableTransportCertifyEpsilonValuations[compact];
If[! AssociationQ[certification] ||
    Lookup[certification, "Status", None] =!= "TransportEpsilonValuationsCertified",
  Print["transport epsilon valuations NOT certified; nothing written: ",
    InputForm[If[AssociationQ[certification],
      KeyDrop[certification, "Record"], certification]]];
  Exit[3]];
compact = certification["Record"];

temporary = outputFile <> ".tmp." <> ToString[$ProcessID];
Put[compact, temporary];
RenameFile[temporary, outputFile, OverwriteTarget -> True];
Print[InputForm[<|
  "Status" -> compact["Status"], "Family" -> compact["Family"],
  "Dimension" -> dimension, "Letters" -> Length[dlog["Letters"]],
  "ResidueMatrices" -> Length[dlog["Residues"]],
  "BlockAssemblyEvidence" -> blockSummary,
  "TransportEpsilonValuations" -> KeyTake[
    Lookup[compact, "TransportEpsilonValuations", <||>], {"TMin", "BlockLower"}],
  "ValuationCertificate" -> <|
    "Status" -> certification["Status"],
    "Tight" -> Lookup[certification, "Tight", Missing[]],
    "ClaimSource" -> If[valuationFile === None, "DerivedFromTrials", valuationFile]|>,
  "Bytes" -> FileByteCount[outputFile],
  "Seconds" -> N[AbsoluteTime[] - started]|>]];
