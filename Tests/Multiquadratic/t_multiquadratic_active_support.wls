#!/usr/bin/env wolframscript
(* Active-support potential certification (round-3 A2; Codex detailed
   instructions 2026-08-26).

   THE DEFECT (P0/P1).  The round-2 certification verdict was computed
   over the ENTIRE candidate pool: an unused candidate with zero
   reconstructed residue could obstruct installation, unverified
   Diagonal forms were inserted first and first-wins deduplication let
   them block later verified letters with the same one-form, and the
   preparation copied that pool verdict before residues existed.

   THE FIX.  Candidate construction is two-phase (collect raw, then one
   representative per one-form by stable priority: verified first);
   spanned diagnostic diagonals are pinned out of the layout with an
   exact constant-coefficient span certificate; an installed letter must
   be regulator-independent (kinematics-independent multiplicative
   content stripped, otherwise rejected); and the INSTALLATION verdict
   is computed only from the reconstructed ACTIVE support.

   ACCEPTANCE CRITERIA, stated before the run.

   The active-support verdict (direct, synthetic records).
   A1  An unused unverified candidate with an exactly zero residue
       matrix does not obstruct: Certified True, the candidate inactive.
   A2  An empty active alphabet (gauge-only solution) is vacuously
       certified: EmptyActiveAlphabet True, Certified True.
   A3  A residue entry that vanishes at sampled regulator values but is
       not identically zero keeps its letter ACTIVE (exact test, never
       sampling).
   A4  An unverified letter with a nonzero residue makes Certified False
       and is named in UnverifiedActiveIndices.
   A5  Without reconstruction the verdict is PendingReconstruction, not
       False-because-unused-candidate.

   The candidate builder.
   B1  A verified letter arriving AFTER an unverified Diagonal record
       with the same one-form replaces it (stable slot, superseded kind
       recorded).  Pre-fix: first-wins kept the unverified diagonal.
   B2  A diagonal form equal to 2 dlog x - dlog y is spanned by the
       verified letters x and y: it is pinned out of the layout into
       DiagnosticRecords with the exact coefficients {2, -1}.
   B3  A form that is NOT a constant-coefficient combination of the
       basis is not spanned (the kinematic-coefficient "span" is
       refused).
   B4  A letter eps*x is normalized to the letter x (content stripped,
       potential verified against the stripped letter); a letter x + eps
       is rejected entirely.

   The residue transfer.
   C1  K_a' = K_a + c_a K_diag, K_diag' = 0 preserves Sum K omega
       exactly, so the compact representation satisfies the same
       differential residual as the redundant one. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

pass = 0; fail = 0;
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];
report[label_, value_] := Print["     ", label, ": ", Short[value, 8]];
mq[name_String] := Symbol["FeynFacet`Private`" <> name];

{activeCert, diagonalSpan, kinematicPart, transferResidues,
  candidateLetters, verifyPotential} =
 {mq["multiquadraticOffDiagonalBlockActivePotentialCertification"],
  mq["multiquadraticOffDiagonalBlockDiagonalSpan"],
  mq["multiquadraticOffDiagonalBlockLetterKinematicPart"],
  mq["multiquadraticOffDiagonalBlockTransferDiagnosticResidues"],
  mq["multiquadraticOffDiagonalBlockCandidateLetters"],
  mq["multiquadraticOffDiagonalBlockVerifyPotential"]};

Clear[ax, ay, ae];
verifiedRecord = <|"Kind" -> "RationalFactor", "Letter" -> ax,
  "Potential" -> <|"Verified" -> True|>|>;
unverifiedRecord = <|"Kind" -> "Diagonal", "Letter" -> Missing["NotADLog"],
  "Potential" -> <|"Verified" -> False|>|>;

(* ------------------------------------------------------------------ *)
(* A: the active-support verdict                                        *)
(* ------------------------------------------------------------------ *)

certA1 = activeCert[{verifiedRecord, unverifiedRecord},
  {{{(3 + ae)/(1 - ae)}}, {{0}}}, True];
check["A1 an unused unverified candidate with zero residue does not \
obstruct: Certified True",
  certA1["Certified"] === True && certA1["ActiveIndices"] === {1} &&
    certA1["InactiveIndices"] === {2}];

certA2 = activeCert[{unverifiedRecord}, {{{0}}}, True];
check["A2 an empty active alphabet is vacuously certified",
  certA2["Certified"] === True &&
    certA2["EmptyActiveAlphabet"] === True &&
    certA2["ActiveIndices"] === {}];

certA3 = activeCert[{unverifiedRecord}, {{{(ae - 3) (ae - 7)}}}, True];
check["A3 a residue vanishing at sampled values but not identically \
zero keeps the letter active (and uncertified here)",
  certA3["ActiveIndices"] === {1} && certA3["Certified"] === False];

certA4 = activeCert[{verifiedRecord, unverifiedRecord},
  {{{1}}, {{ae}}}, True];
check["A4 an unverified ACTIVE letter is named and blocks certification",
  certA4["Certified"] === False &&
    certA4["UnverifiedActiveIndices"] === {2}];

certA5 = activeCert[{verifiedRecord, unverifiedRecord}, Missing[], False];
check["A5 without reconstruction the verdict is PendingReconstruction",
  certA5["Certified"] === False &&
    certA5["Pending"] === "PendingReconstruction"];

(* ------------------------------------------------------------------ *)
(* B: the candidate builder                                             *)
(* ------------------------------------------------------------------ *)

(* a strip whose E-block scalar closed form EQUALS dlog(x): the Diagonal
   record arrives first and unverified; the rational letter x arrives
   later with a verified potential and the same one-form *)
eBlock = {{{1/ax}}, {{0}}};   (* omega = dx/x + 0 dy = dlog x *)
cBlock = {{{0}}, {{0}}};
inhomogeneity = Table[{{Together[
  D[(ax + 2 ay)/(1 - ax - ay), {ax, ay}[[mu]]] +
    ae (5/2) D[Log[1 - ax - ay], {ax, ay}[[mu]]]]}}, {mu, 2}];
record = <|"Family" -> "ACTIVE_SUPPORT", "Sector" -> 2, "LowerSector" -> 1,
  "Variables" -> {ax, ay}, "Regulator" -> ae,
  "OffDiagonalBlockEquation" -> {eBlock, cBlock, inhomogeneity}|>;
letters = candidateLetters[{eBlock, cBlock, inhomogeneity}, {}, {ax, ay}, ae,
  record, "AdditionalLetters" -> {ax, ay, 1 - ax - ay}];
check["the candidate builder runs",
  Lookup[letters, "Status", None] === "MultiquadraticCandidateLettersV1"];
records = letters["LetterRecords"];
dlogxRecords = Select[records,
  Together[Lookup[#1, "OneForm", {0, 0}][[1]] - 1/ax] === 0 &&
    Together[Lookup[#1, "OneForm", {0, 0}][[2]]] === 0 &];
report["B1 the dlog x representative", KeyTake[First[dlogxRecords, <||>],
  {"Kind", "Letter", "SupersededKinds"}]];
check["B1 the verified letter x replaced the unverified Diagonal record \
with the same one-form",
  Length[dlogxRecords] === 1 &&
    Lookup[First[dlogxRecords], "Kind", None] =!= "Diagonal" &&
    TrueQ[Lookup[Lookup[First[dlogxRecords], "Potential", <||>],
      "Verified", False]] &&
    MemberQ[Lookup[First[dlogxRecords], "SupersededKinds", {}], "Diagonal"]];

(* B2: a diagonal form 2 dlog x - dlog y against verified x, y *)
spanB2 = diagonalSpan[{2/ax, -(1/ay)},
  {{1/ax, 0}, {0, 1/ay}}, {ax, ay}];
check["B2 2 dlog x - dlog y is spanned with exact coefficients {2, -1}",
  AssociationQ[spanB2] && spanB2["Spanned"] === True &&
    spanB2["Coefficients"] === {2, -1}];

spanB3 = diagonalSpan[{ay/ax, 0}, {{1/ax, 0}, {0, 1/ay}}, {ax, ay}];
check["B3 a form needing kinematic coefficients is NOT spanned",
  MatchQ[spanB3, _Missing]];

(* B4: regulator content *)
lettersB4 = candidateLetters[{cBlock, cBlock, inhomogeneity}, {}, {ax, ay}, ae,
  record, "AdditionalLetters" -> {ae ax, ax + ae}];
recordsB4 = lettersB4["LetterRecords"];
strippedB4 = Select[recordsB4, Lookup[#1, "StrippedContent", False] === True &];
check["B4 the letter eps*x is normalized to the letter x with a verified \
potential",
  Length[strippedB4] === 1 &&
    Together[First[strippedB4]["Letter"] - ax] === 0 &&
    TrueQ[Lookup[Lookup[First[strippedB4], "Potential", <||>], "Verified",
      False]]];
(* x + eps dies at the ONE-FORM filter (dlog(x + eps) carries the
   regulator), one stage before the letter-content guard: only a
   MULTIPLICATIVE regulator content can survive to the guard at all,
   because eps-free dlog components force L = c(eps) f(x, y) exactly.
   The contract to assert is that the letter appears nowhere and that
   no installed one-form carries the regulator. *)
check["B4 the letter x + eps is rejected outright, and no installed \
one-form carries the regulator",
  ! MemberQ[Together[#1["Letter"] - (ax + ae)] === 0 & /@
      Select[recordsB4, ! MissingQ[Lookup[#1, "Letter", Missing[]]] &], True] &&
    AllTrue[Lookup[recordsB4, "OneForm", {}], FreeQ[#1, ae] &]];

(* ------------------------------------------------------------------ *)
(* C: the residue transfer                                              *)
(* ------------------------------------------------------------------ *)

omegaX = {1/ax, 0}; omegaY = {0, 1/ay};
omegaDiag = {2/ax, -(1/ay)};   (* = 2 omega_x - omega_y *)
residues = {{{3 + ae}}, {{-2}}, {{7 ae}}};   (* K_x, K_y, K_diag *)
transferred = transferResidues[residues, 3, {2, -1}, {1, 2}];
check["C1 the transfer zeroes the diagnostic residue",
  transferred[[3]] === {{0}}];
check["C1 Sum K omega is preserved EXACTLY by the transfer",
  Module[{before, after},
    before = Table[Together[
      residues[[1, 1, 1]] {omegaX, omegaY, omegaDiag}[[1, mu]] +
      residues[[2, 1, 1]] {omegaX, omegaY, omegaDiag}[[2, mu]] +
      residues[[3, 1, 1]] {omegaX, omegaY, omegaDiag}[[3, mu]]], {mu, 2}];
    after = Table[Together[
      transferred[[1, 1, 1]] {omegaX, omegaY, omegaDiag}[[1, mu]] +
      transferred[[2, 1, 1]] {omegaX, omegaY, omegaDiag}[[2, mu]] +
      transferred[[3, 1, 1]] {omegaX, omegaY, omegaDiag}[[3, mu]]], {mu, 2}];
    AllTrue[Together[before - after], #1 === 0 &]]];

Print["t_multiquadratic_active_support: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
