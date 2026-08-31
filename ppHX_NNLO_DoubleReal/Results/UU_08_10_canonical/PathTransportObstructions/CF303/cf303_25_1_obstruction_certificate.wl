<|
  "Status" -> "CF303Block1EpsFormObstructionCertifiedV1",
  "Family" -> "CF303", "Sector" -> 25, "LowerSector" -> 1,
  "Claim" -> "No dlog/epsilon-form gauge exists for CF303 (25,1) \
over the COMPLETE certified divisor span: in the Kallen23 (t,s) \
frame (rationalizes lambda2/lambda3; the bilinear root is the \
surviving rank-one extension), the residue-only integrability \
system over the complete span -- family divisor census v2 plus the \
three closure curves Z4 (deg 4), Z2 (deg 2), P3 (polar, deg 3), 25 \
letters total -- is inconsistent with defect {1,1,1} at THREE \
independent modular images. The span is closed by the (25,1) \
census closure: every lifted residual divisor either binds inside \
the family census or factors into the dual-certified absolutely \
irreducible curves above (Maple evala(AFactors) + Singular \
absFactorize, fresh-prime verified).",
  "Standard" -> "Block-18 pattern per user note 09 + addendum: span \
completeness plus a residue-integrability defect at two usable \
images plus one further independent image; here all three are \
CONFIGURED images (the package's fresh-image generator cannot run \
on the provider route -- it samples regulator values against the \
zero Bbar placeholder), the third at an independently \
primality-verified fresh prime.",
  "Route" -> "NativeForcingProvider: the forcing is Codex's \
chart-native deferred DAG (cf303_build_kallen23_native_forcing.wls, \
block 1, native-verified at build time), evaluated pointwise by the \
FLINT deferred evaluator inside the screen -- no symbolic Bbar \
materialization; the 10.2M-leaf symbolic compile wall of \
2026-08-31 morning is bypassed, screen wall 291.8 s.",
  "Evidence" -> <|
    "CensusClosure" -> "cf303_25_1_census_closure.json",
    "CompletenessScreen" -> "cf303_25_1_completeness_screen.wl",
    "ChartNativeInput" -> "factorization-and-loops-codex/Runtime/\
2026-08-31_cf303_kallen23_native_forcing/sector_CF303_standard/\
CF303_25_1_kallen23_native_input.wl",
    "SourceInput" -> "factorization-and-loops-codex/Runtime/\
2026-08-30_cf303_25_2_exact_common_path/resume/sector_CF303_standard/\
CF303_25_1_input.wl",
    "ScreenDriver" -> "screen_cf303_row25_provider.wls"|>,
  "Images" -> {
    <|"Prime" -> 2147483423, "RegulatorValue" -> 1/13|>,
    <|"Prime" -> 2147483399, "RegulatorValue" -> 3/17|>,
    <|"Prime" -> 2147483179, "RegulatorValue" -> 5/19,
      "Note" -> "fresh third image, primality verified"|>},
  "ScreenResult" -> <|"Status" -> "AlphabetIntegrabilityObstruction",
    "Defects" -> {1, 1, 1}, "Confirmed" -> True,
    "Verdict" -> "ConfirmedObstruction", "ConfiguredUsable" -> 3,
    "LetterCount" -> 25, "ScreenSeconds" -> 291.804617|>,
  "TransportDisposition" -> "The (25,1) integral-form transport \
edge stands backed by a proved impossibility, per the user's \
promotion policy.",
  "Date" -> "2026-08-31"
|>
