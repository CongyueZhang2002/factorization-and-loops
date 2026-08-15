(* QF pilot boundary-period certificate -- exchange schema
   REVISED 2026-08-15 (stage-3 rework): the numeric branch identification
   was replaced by Codex's dominated-convergence proof, formalized and
   machine-checked.  See ../Proofs/Period06_07.md. *)
<|
  "PeriodID" -> 6,
  "RepresentativeBasis" -> {gli[CF124, {1, 1, 0, 0, 1, 0, 1, 0, 0}]},
  "ClassID" -> 17,
  "OrderedPhysicalLimit" -> {"1-v-w -> 0 (v generic)", "v -> 0 (w generic)", "w -> 0 (v generic)"},
  "UndeterminedAtStrata" -> {"soft", "vEdge", "wEdge"},
  "IntegerValuation" -> <|"soft" -> 0, "vEdge" -> 0, "wEdge" -> 0|>,
  "FrobeniusExponent" -> <|"soft" -> 0, "vEdge" -> 0, "wEdge" -> 0|>,
  "ExactCoefficient" -> 0,
  "Status" -> "Exact",
  "StatusTaxonomy" -> "Exact | AnalyticCandidate | NotEvaluated | Rejected (see ../LEDGER.md)",
  "ProofRecord" -> "../Proofs/Period06_07.md",
  "Certificate" -> <|
    "Method" -> "dominated-convergence endpoint proof (Codex's argument, machine-checked) + exact DE structure",
    "ProofChain" -> {
      "uncut denominator D5 = (kc+ke+kf)^2 = (ka+kb-q)^2 = 1 - 2 q.(ka+kb) with q the third cut leg, verified symbolically on the cut (Scripts/verify_transfers.wls)",
      "parametric form D5 = 1 - x s - x (1-s) y and the measure exponents re-derived symbolically from the rest-frame kinematics (verify_parametric_representation.wls: R1-R2, C2, C3, M1-M5)",
      "exact corner form D5 = u + (1-u)(1-s) t (verify_soft_domination.wls: K2)",
      "for 0 <= s <= s0 < 1, bound D5 >= ((1-s0)/4)(u+t) by exact quantifier elimination (L1, L4)",
      "endpoint kernel dominated by u^(-eps) t^(-eps)/(u + c t); dominating function integrable exactly for Re[eps] < 1/2 with closed bound (2/(1-s0)) B(1/2-sig,2-2sig) B(1/2-sig,1-sig) (D1-D4)",
      "dominated convergence => the normalized integral is finite at s = 0 => R bounded; free mode s^(2 eps-1) unbounded on the same half plane (B1, B2) => A = 0 there; meromorphic continuation => A === 0",
      "exact DE structure from the repository connection: row 6 couples only to row 5 (volume) and itself in both Av and Aw; Av[6,5] = (2-3eps)/((v+w-1)(v+w)), Av[6,6] = -eps/(v+w); forced finite-branch value R_soft = (2-3eps)/(1-2eps) (S5a-S5d)",
      "reconstruction cross-check against Kira is now exact and numerics-free: the s=0 parametric integral evaluates in closed form to Int dmu * (2-3eps)/(1-2eps) by Euler + Pochhammer cancellation + Gauss at unit argument (S0-S4, S6)"},
    "NumericChecksOnly" -> "reconstructed soft value 2.12499999999999999999999999999999999999999998868 vs 17/8 at eps=1/10 (29.7 digits) and 29.6 digits at eps=1/5; R(s) decreasing monotonically 2.9543, 2.4465, 2.2703, ... -> 2.125 over s = 1/2..1/32. Independent checks; NOT part of the proof chain.",
    "Withdrawn" -> "the branch was previously selected by the monotonic decrease of finitely many numeric samples, which cannot exclude a small nonzero coefficient; superseded by the domination proof",
    "NoClosedFormClaimed" -> "no closed form in (v,w) is claimed for this period; what is exact is the connection, the soft indicial structure, the forced finite-branch value, and the vanishing of the free mode -- which is the period",
    "DERow" -> 6,
    "DEBasisLength" -> 12,
    "CoupledMasters" -> 1,
    "UncutDenominators" -> 1,
    "SelfTest" -> "CF1 control reproduces probe_CF1.wl row/residues/coupling"
  |>,
  "EvaluatedRealization" -> "CF124",
  "FamiliesWhereUndetermined" -> {"CF21", "CF226", "CF23", "CF248", "CF253", "CF53", "CF57", "CF91", "CF97"},
  "RealizationTransferCaveat" -> False,
  "UncheckedRealizations" -> {},
  "VerifiedTransfers" -> <|
    "CF21"  -> <|"Row" -> 1,  "Master" -> gli[CF21,  {1, 1, 0, 0, 0, 1, 0, 1, 0}], "UncutPropagator" -> 6, "MatchedCutLeg" -> 3, "Status" -> "Exact"|>,
    "CF226" -> <|"Row" -> 5,  "Master" -> gli[CF226, {1, 1, 0, 0, 1, 0, 1, 0, 0}], "UncutPropagator" -> 5, "MatchedCutLeg" -> 3, "Status" -> "Exact"|>,
    "CF23"  -> <|"Row" -> 5,  "Master" -> gli[CF23,  {1, 1, 0, 0, 0, 1, 0, 1, 0}], "UncutPropagator" -> 6, "MatchedCutLeg" -> 3, "Status" -> "Exact"|>,
    "CF248" -> <|"Row" -> 6,  "Master" -> gli[CF248, {1, 1, 0, 0, 0, 1, 0, 1, 0}], "UncutPropagator" -> 6, "MatchedCutLeg" -> 3, "Status" -> "Exact"|>,
    "CF253" -> <|"Row" -> 4,  "Master" -> gli[CF253, {1, 1, 0, 0, 0, 1, 0, 1, 0}], "UncutPropagator" -> 6, "MatchedCutLeg" -> 3, "Status" -> "Exact"|>,
    "CF53"  -> <|"Row" -> 13, "Master" -> gli[CF53,  {1, 1, 0, 0, 0, 1, 0, 1, 0}], "UncutPropagator" -> 6, "MatchedCutLeg" -> 3, "Status" -> "Exact"|>,
    "CF57"  -> <|"Row" -> 8,  "Master" -> gli[CF57,  {1, 1, 0, 0, 0, 1, 0, 1, 0}], "UncutPropagator" -> 6, "MatchedCutLeg" -> 3, "Status" -> "Exact"|>,
    "CF91"  -> <|"Row" -> 6,  "Master" -> gli[CF91,  {1, 1, 0, 0, 0, 1, 0, 1, 0}], "UncutPropagator" -> 6, "MatchedCutLeg" -> 3, "Status" -> "Exact"|>,
    "CF97"  -> <|"Row" -> 4,  "Master" -> gli[CF97,  {1, 1, 0, 0, 0, 1, 0, 1, 0}], "UncutPropagator" -> 6, "MatchedCutLeg" -> 3, "Status" -> "Exact"|>|>,
  "TransferNote" -> "All nine listed realizations verified exactly. NOTE: the rows above were found by SEARCHING each family's block basis, not by reading NullityPeriods.wl positionally -- that record's Families and BlockRows lists are independently deduplicated and cannot be paired. See ../Proofs/RealizationTransfers.md.",
  "Provenance" -> "qf_pilot sweep + stageB; NullityPeriods.wl; nnlo_de_<fam>.wl; Kira integralfamilies.yaml"
|>
