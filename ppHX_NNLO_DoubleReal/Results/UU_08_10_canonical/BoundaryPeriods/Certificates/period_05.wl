(* QF pilot boundary-period certificate -- exchange schema *)
<|
  "PeriodID" -> 5,
  "RepresentativeBasis" -> {gli[CF124, {1, 1, 1, 1, 1, 1, 1, -1, 0}]},
  "ClassID" -> 16,
  "OrderedPhysicalLimit" -> {"1-v-w -> 0 (v generic)", "v -> 0 (w generic)", "w -> 0 (v generic)"},
  "UndeterminedAtStrata" -> {"soft", "vEdge", "wEdge"},
  "IntegerValuation" -> <|"soft" -> 0, "vEdge" -> 0, "wEdge" -> 0|>,
  "FrobeniusExponent" -> <|"soft" -> 0, "vEdge" -> 0, "wEdge" -> 0|>,
  "ExactCoefficient" -> Missing["Unresolved", "4 uncut denominators and 11 coupled masters driving the block: needs the full 5-variable cut parametrization, not the 2-variable (x,y) chart that suffices at 1 denominator"],
  "Status" -> "UNRESOLVED",
  "Certificate" -> <|
    "Method" -> "not evaluated",
    "Evidence" -> "DE-side structure only (row, diagonal residues, drivers); no integrand reconstruction attempted in this pilot",
    "DERow" -> 3,
    "DEBasisLength" -> 12,
    "CoupledMasters" -> 11,
    "UncutDenominators" -> 4,
    "SelfTest" -> "CF1 control reproduces probe_CF1.wl row/residues/coupling"
  |>,
  "EvaluatedRealization" -> "CF124",
  "FamiliesWhereUndetermined" -> {"CF13", "CF18", "CF26", "CF33"},
  "RealizationTransferCaveat" -> True,
  "UncheckedRealizations" -> {"CF13", "CF18", "CF26", "CF33"},
  "TransferNote" -> "Value established for the EvaluatedRealization only. Transfer to the listed UncheckedRealizations was NOT verified: cross-family dedup convention unconfirmed.",
  "Provenance" -> "qf_pilot sweep + stageB; NullityPeriods.wl; nnlo_de_<fam>.wl; Kira integralfamilies.yaml"
|>
