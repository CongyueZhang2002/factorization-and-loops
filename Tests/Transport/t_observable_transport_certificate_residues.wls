#!/usr/bin/env wolframscript

(* Round 9 (T, 2026-09-03): constant dlog residues reconstructed on the
   letters of an exact certificate whose "Residues" were never
   reconstructed (CF265, CF305).  A 2x2 eps-linear connection built from
   known rational residues on four letters must come back exactly, with a
   fresh-prime validation; dependent letters, a pole outside the alphabet
   and an eps-nonlinear connection are refused typed. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

y = Symbol["Global`certResY"]; s = Symbol["Global`certResS"];
eps = Symbol["Global`eps"];
letters = {y, 1 - y, s, y + s - 1};
residues = {{{1, 2}, {0, -1/3}}, {{0, 1/2}, {1, 0}}, {{2, 0}, {-1, 1}},
  {{1/5, 0}, {0, 3}}};
connections = Table[Together[eps Sum[residues[[i]] D[letters[[i]], v]/letters[[i]],
    {i, 4}]], {v, {y, s}}];
reconstruct = FeynFacet`Private`observableTransportCertificateLetterResidues;

result = reconstruct[connections, {y, s}, eps, letters, 2];
FTAssert["the constant residues are reconstructed exactly on the certificate letters and validated at a fresh prime on fresh points",
  result["Status"] === "CertificateLetterResiduesReconstructed" &&
    result["Residues"] === residues &&
    result["Certificate"]["Mismatches"] === 0 &&
    result["Certificate"]["Comparisons"] === 2 * 4 * 3 &&
    TrueQ[result["Certificate"]["Probabilistic"]] &&
    Length[result["Certificate"]["Primes"]] >= 2 &&
    DuplicateFreeQ[result["Certificate"]["Primes"]] &&
    ! MemberQ[result["Certificate"]["Primes"],
      result["Certificate"]["FreshValidationPrime"]] &&
    result["Certificate"]["DesignRank"] === 4];

dependent = reconstruct[connections, {y, s}, eps, Append[letters, 2 y], 2];
outside = reconstruct[{connections[[1]] + eps {{0, 1/(y - 2)}, {0, 0}},
  connections[[2]]}, {y, s}, eps, letters, 2];
nonlinear = reconstruct[{connections[[1]] + eps^2 {{1/y, 0}, {0, 0}},
  connections[[2]]}, {y, s}, eps, letters, 2];
FTAssert["dependent letters, a pole outside the alphabet and an eps-nonlinear connection are refused typed",
  dependent["Status"] === "LetterFormsDependent" &&
    dependent["DesignRank"] === 4 && dependent["LetterCount"] === 5 &&
    outside["Status"] === "ConnectionOutsideLetterSpan" &&
    nonlinear["Status"] === "EpsilonLinearityFailed"];

FTAssert["a different seed reconstructs the same residues at different primes",
  With[{other = reconstruct[connections, {y, s}, eps, letters, 2, "Seed" -> 77]},
    other["Status"] === "CertificateLetterResiduesReconstructed" &&
      other["Residues"] === residues &&
      other["Certificate"]["Primes"] =!= result["Certificate"]["Primes"]]];

(* the probabilistic certificate the transport records and the acceptance
   predicate's named branch for it, with tampering *)
residueRecord = <|"Status" -> "CertifiedFiniteField", "Letters" -> letters,
  "Residues" -> result["Residues"],
  "ReconstructionCertificate" -> result["Certificate"]|>;
certificate = FeynFacet`Private`observableTransportReconstructedResidueCertificate[residueRecord];
certificateQ = FeynFacet`Private`observableTransportReconstructedResidueCertificateQ;
FTAssert["the recorded reconstruction certificate is accepted by the predicate's named branch and every tampering is refused",
  certificateQ[certificate] &&
    certificate["LetterCount"] === 4 && certificate["ResidueCount"] === 4 &&
    ! certificateQ[Join[certificate, <|"Mismatches" -> 1|>]] &&
    ! certificateQ[Join[certificate, <|"FreshValidationPrime" -> First[certificate["Primes"]]|>]] &&
    ! certificateQ[Join[certificate, <|"DesignRank" -> 3|>]] &&
    ! certificateQ[Join[certificate, <|"Primes" -> {First[certificate["Primes"]]}|>]] &&
    ! certificateQ[Join[certificate, <|"EpsilonLinearityChecked" -> False|>]] &&
    ! certificateQ[Join[certificate, <|"CoefficientField" -> "Multiquadratic"|>]] &&
    ! certificateQ[Join[certificate, <|"Status" -> "CertifiedDLogResidues"|>]] &&
    ! certificateQ[KeyDrop[certificate, "FreshValidationPoints"]]];

FTReport[];
