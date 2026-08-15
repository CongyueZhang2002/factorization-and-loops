(* QF pilot boundary-period certificate -- exchange schema *)
<|
  "PeriodID" -> 2,
  "RepresentativeBasis" -> {gli[CF123, {1, 1, 1, 1, 0, 1, 1, 0, 0}]},
  "ClassID" -> 10,
  "OrderedPhysicalLimit" -> {"v = a rho, w = b rho",        "1-v-w -> 0 (v generic)", "v -> 0 (w generic)", "w -> 0 (v generic)"},
  "UndeterminedAtStrata" -> {"cornerRay", "soft", "vEdge", "wEdge"},
  "IntegerValuation" -> <|"cornerRay" -> 0, "soft" -> 0, "vEdge" -> 0,        "wEdge" -> 0|>,
  "FrobeniusExponent" -> <|"cornerRay" -> 0, "soft" -> 0,        "vEdge" -> 0, "wEdge" -> 0|>,
  "ExactCoefficient" -> Missing["Unresolved", "3 uncut denominators and 3 coupled masters driving the block: needs the full 5-variable cut parametrization, not the 2-variable (x,y) chart that suffices at 1 denominator"],
  "Status" -> "UNRESOLVED",
  "Certificate" -> <|
    "Method" -> "not evaluated",
    "Evidence" -> "DE-side structure only (row, diagonal residues, drivers); no integrand reconstruction attempted in this pilot",
    "DERow" -> 1,
    "DEBasisLength" -> 11,
    "CoupledMasters" -> 3,
    "UncutDenominators" -> 3,
    "SelfTest" -> "CF1 control reproduces probe_CF1.wl row/residues/coupling"
  |>,
  "EvaluatedRealization" -> "CF123",
  "FamiliesWhereUndetermined" -> {"CF123", "CF269", "CF308", "CF311", "CF67", "CF71"},
  "RealizationTransferCaveat" -> False,
  "UncheckedRealizations" -> {"CF269", "CF308", "CF311", "CF67", "CF71"},
  "TransferNote" -> "Value established for the EvaluatedRealization only. Transfer to the listed UncheckedRealizations was NOT verified: cross-family dedup convention unconfirmed.",
  "Provenance" -> "qf_pilot sweep + stageB; NullityPeriods.wl; nnlo_de_<fam>.wl; Kira integralfamilies.yaml"
|>
