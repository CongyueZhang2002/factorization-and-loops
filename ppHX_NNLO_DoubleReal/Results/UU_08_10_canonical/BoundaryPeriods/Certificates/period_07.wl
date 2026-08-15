(* QF pilot boundary-period certificate -- exchange schema
   REVISED 2026-08-15 (stage-3 rework): the numeric branch identification
   was replaced by Codex's dominated-convergence proof, formalized and
   machine-checked.  See ../Proofs/Period06_07.md. *)
<|
  "PeriodID" -> 7,
  "RepresentativeBasis" -> {gli[CF124, {1, 1, 0, 0, 1, 0, 1, 0, 0}]},
  "ClassID" -> 17,
  "OrderedPhysicalLimit" -> {"1-v-w -> 0 (v generic)",        "w -> 0 (v generic)"},
  "UndeterminedAtStrata" -> {"soft", "wEdge"},
  "IntegerValuation" -> <|"soft" -> 0, "wEdge" -> 0|>,
  "FrobeniusExponent" -> <|"soft" -> 0, "wEdge" -> 0|>,
  "ExactCoefficient" -> 0,
  "Status" -> "Exact",
  "StatusTaxonomy" -> "Exact | AnalyticCandidate | NotEvaluated | Rejected (see ../LEDGER.md)",
  "ProofRecord" -> "../Proofs/Period06_07.md",
  "Certificate" -> <|
    "Method" -> "same master and same proof as PeriodID 6; differs only in which strata the counter flags undetermined",
    "SameMasterAs" -> 6,
    "ProofChain" -> "identical to PeriodID 6 -- see ../Proofs/Period06_07.md. The two entries are the same integral gli[CF124,{1,1,0,0,1,0,1,0,0}]; PID 6 is flagged undetermined at soft/vEdge/wEdge, PID 7 at soft/wEdge.",
    "NumericChecksOnly" -> "as PeriodID 6. Independent checks; NOT part of the proof chain.",
    "Withdrawn" -> "as PeriodID 6: the numeric branch identification is superseded by the domination proof",
    "NoClosedFormClaimed" -> "as PeriodID 6",
    "DERow" -> 6,
    "DEBasisLength" -> 12,
    "CoupledMasters" -> 1,
    "UncutDenominators" -> 1,
    "SelfTest" -> "CF1 control reproduces probe_CF1.wl row/residues/coupling"
  |>,
  "EvaluatedRealization" -> "CF124",
  "FamiliesWhereUndetermined" -> {"CF299", "CF300"},
  "RealizationTransferCaveat" -> False,
  "UncheckedRealizations" -> {},
  "VerifiedTransfers" -> <|
    "CF299" -> <|"Row" -> 8, "Master" -> gli[CF299, {1, 1, 0, 0, 0, 1, 0, 1, 0}], "UncutPropagator" -> 6, "MatchedCutLeg" -> 3, "Status" -> "Exact"|>,
    "CF300" -> <|"Row" -> 4, "Master" -> gli[CF300, {1, 1, 0, 0, 0, 1, 0, 1, 0}], "UncutPropagator" -> 6, "MatchedCutLeg" -> 3, "Status" -> "Exact"|>|>,
  "TransferNote" -> "Both listed realizations verified exactly. CF300 hosts realizations of BOTH PeriodID 1 (row 5) and PeriodID 7 (row 4), with different uncut propagators and different invariant signatures; the test distinguishes them. See ../Proofs/RealizationTransfers.md.",
  "Provenance" -> "qf_pilot sweep + stageB; NullityPeriods.wl; nnlo_de_<fam>.wl; Kira integralfamilies.yaml"
|>
