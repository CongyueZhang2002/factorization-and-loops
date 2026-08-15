(* QF pilot boundary-period certificate -- exchange schema
   REVISED 2026-08-15 (stage-3 rework): status moved to the strict
   taxonomy in ../LEDGER.md; the numeric links in the proof chain were
   replaced by exact symbolic ones.  See ../Proofs/Period01.md. *)
<|
  "PeriodID" -> 1,
  "RepresentativeBasis" -> {gli[CF1, {1, 1, 1, 0, 1, 0, 0, 0, 0}]},
  "ClassID" -> 2,
  "OrderedPhysicalLimit" -> {"1-v-w -> 0 (v generic)",        "w -> 0 (v generic)"},
  "UndeterminedAtStrata" -> {"soft", "wEdge"},
  "IntegerValuation" -> <|"soft" -> 0, "wEdge" -> 0|>,
  "FrobeniusExponent" -> <|"soft" -> 0, "wEdge" -> 0|>,
  "ExactCoefficient" -> 0,
  "Status" -> "Exact",
  "StatusTaxonomy" -> "Exact | AnalyticCandidate | NotEvaluated | Rejected (see ../LEDGER.md)",
  "ProofRecord" -> "../Proofs/Period01.md",
  "Certificate" -> <|
    "Method" -> "exact symbolic DE identity + dominated-convergence endpoint proof",
    "ProofChain" -> {
      "parametric cut representation J = v + x s - x (v+s) y and the measure exponents re-derived symbolically from the Kira family definition (Scripts/verify_parametric_representation.wls: R1-R4, C1, M1-M5)",
      "exact corner form J = v u + (1-u)(v+s) t (verify_soft_domination.wls: K1)",
      "uniform lower bound J >= (v/4)(u+t) for all s >= 0, by exact quantifier elimination (L1, L2, L3)",
      "dominating function integrable exactly for Re[eps] < 1/2, with the closed bound (2/v) B(1/2-sig,2-2sig) B(1/2-sig,1-sig) (D1-D4)",
      "dominated convergence => R bounded as s -> 0+; free mode v^(-eps) s^(2 eps-1) unbounded on the same half plane (B1, B2) => A = 0 there; meromorphic continuation => A === 0",
      "closed form R = -(2-3eps)/(v(1-2eps)) 2F1(1-eps,1;2-2eps;-(1-v-w)/v) satisfies both differential equations as a literal zero under Together, in both rows and in reduced scalar form (verify_period_01_de.wls: P2d-P2i)",
      "the 2F1 contiguous relation used there is itself proved symbolically for general (a,c) from the Pochhammer recursion (P1a, P1b)",
      "reconstruction cross-check against Kira's connection is exact and numerics-free: Euler + Pochhammer cancellation + Gauss at unit argument (S0-S4, S7)"},
    "NumericChecksOnly" -> "30-digit agreement of the closed form with a direct phase-space evaluation at v=w=1/4, eps=1/10 and 1/5; contiguous bracket 0 to 76-80 digits at four rational points. Independent checks; NOT part of the proof chain.",
    "Withdrawn" -> "the recorded DE residual 1.25e-9 was the O(h^4) truncation error of a 5-point stencil, not a measure of the identity; superseded by the exact residual",
    "DERow" -> 2,
    "DEBasisLength" -> 2,
    "CoupledMasters" -> 1,
    "UncutDenominators" -> 1,
    "SelfTest" -> "CF1 control reproduces probe_CF1.wl row/residues/coupling"
  |>,
  "EvaluatedRealization" -> "CF1",
  "FamiliesWhereUndetermined" -> {"CF300"},
  "RealizationTransferCaveat" -> False,
  "UncheckedRealizations" -> {},
  "VerifiedTransfers" -> <|
    "CF300" -> <|"Row" -> 5, "Master" -> gli[CF300, {1, 1, 0, 0, 1, 0, 0, 1, 0}],
      "UncutPropagator" -> 5, "MatchedCutLeg" -> 2,
      "Signature" -> "(kc-ka+q)^2", "Status" -> "Exact"|>|>,
  "TransferNote" -> "All listed realizations verified exactly: the target master is the same 3-particle massless cut integral with the same invariant uncut denominator, and its DE row couples only to its own family's volume master. See ../Proofs/RealizationTransfers.md.",
  "Provenance" -> "qf_pilot sweep + stageB; NullityPeriods.wl; nnlo_de_<fam>.wl; Kira integralfamilies.yaml"
|>
