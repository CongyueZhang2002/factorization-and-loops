(* QF pilot boundary-period certificate -- exchange schema *)
<|
  "PeriodID" -> 17,
  "RepresentativeBasis" -> {gli[CF236, {1, 1, 1, 1, 0, 1, 1, 0, 1}]},
  "ClassID" -> 84,
  "OrderedPhysicalLimit" -> {"v = a rho, w = b rho",        "1-v-w -> 0 (v generic)", "v -> 0 (w generic)", "w -> 0 (v generic)"},
  "UndeterminedAtStrata" -> {"cornerRay", "soft", "vEdge", "wEdge"},
  "IntegerValuation" -> <|"cornerRay" -> -1, "soft" -> 0, "vEdge" -> -1,        "wEdge" -> 0|>,
  "FrobeniusExponent" -> <|"cornerRay" -> -1,        "soft" -> 0, "vEdge" -> -1, "wEdge" -> 0|>,
  "ExactCoefficient" -> Missing["Unresolved", "4 uncut denominators and 7 coupled masters driving the block: needs the full 5-variable cut parametrization, not the 2-variable (x,y) chart that suffices at 1 denominator"],
  "Status" -> "UNRESOLVED",
  "Certificate" -> <|
    "Method" -> "not evaluated",
    "Evidence" -> "DE-side structure only (row, diagonal residues, drivers); no integrand reconstruction attempted in this pilot",
    "DERow" -> 28,
    "DEBasisLength" -> 28,
    "CoupledMasters" -> 7,
    "UncutDenominators" -> 4,
    "SelfTest" -> "CF1 control reproduces probe_CF1.wl row/residues/coupling"
  |>,
  "EvaluatedRealization" -> "CF236",
  "FamiliesWhereUndetermined" -> {"CF404", "CF90"},
  "RealizationTransferCaveat" -> True,
  "UncheckedRealizations" -> {"CF404", "CF90"},
  "TransferNote" -> "Value established for the EvaluatedRealization only. Transfer to the listed UncheckedRealizations was NOT verified: cross-family dedup convention unconfirmed.",
  "Provenance" -> "qf_pilot sweep + stageB; NullityPeriods.wl; nnlo_de_<fam>.wl; Kira integralfamilies.yaml"
|>
