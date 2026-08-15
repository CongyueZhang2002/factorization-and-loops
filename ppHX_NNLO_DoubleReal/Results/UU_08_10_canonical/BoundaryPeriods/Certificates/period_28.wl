(* QF pilot boundary-period certificate -- exchange schema *)
<|
  "PeriodID" -> 28,
  "RepresentativeBasis" -> {gli[CF384, {1, 1, 1, 0, 1, 0, 1, 1, 1}]},
  "ClassID" -> 136,
  "OrderedPhysicalLimit" -> {"1-v-w -> 0 (v generic)",        "v -> 0 (w generic)", "w -> 0 (v generic)"},
  "UndeterminedAtStrata" -> {"soft", "vEdge", "wEdge"},
  "IntegerValuation" -> <|"soft" -> 0, "vEdge" -> 0, "wEdge" -> 0|>,
  "FrobeniusExponent" -> <|"soft" -> 0, "vEdge" -> 0, "wEdge" -> 0|>,
  "ExactCoefficient" -> Missing["Unresolved", "4 uncut denominators and 4 coupled masters driving the block: needs the full 5-variable cut parametrization, not the 2-variable (x,y) chart that suffices at 1 denominator"],
  "Status" -> "UNRESOLVED",
  "Certificate" -> <|
    "Method" -> "not evaluated",
    "Evidence" -> "DE-side structure only (row, diagonal residues, drivers); no integrand reconstruction attempted in this pilot",
    "DERow" -> 3,
    "DEBasisLength" -> 27,
    "CoupledMasters" -> 4,
    "UncutDenominators" -> 4,
    "SelfTest" -> "CF1 control reproduces probe_CF1.wl row/residues/coupling"
  |>,
  "EvaluatedRealization" -> "CF384",
  "FamiliesWhereUndetermined" -> {"CF384", "CF385", "CF413"},
  "RealizationTransferCaveat" -> False,
  "UncheckedRealizations" -> {"CF385", "CF413"},
  "TransferNote" -> "Value established for the EvaluatedRealization only. Transfer to the listed UncheckedRealizations was NOT verified: cross-family dedup convention unconfirmed.",
  "Provenance" -> "qf_pilot sweep + stageB; NullityPeriods.wl; nnlo_de_<fam>.wl; Kira integralfamilies.yaml"
|>
