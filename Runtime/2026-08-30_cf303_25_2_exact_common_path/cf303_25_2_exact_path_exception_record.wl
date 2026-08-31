<|
  "Status" -> "ExactPathTransportExceptionReadyV1",
  "Family" -> "CF303", "Sector" -> 25, "HardSector" -> 25,
  "LowerSector" -> 2,
  "Method" -> "ExactRationalPathTransportException",
  "Gauge" -> "LiteralZero", "Installed" -> False,
  "ExactDLog" -> False,
  "ArtifactFile" -> "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-30_cf303_25_2_exact_common_path/cf303_25_2_exact_structured_path.wl",
  "ArtifactStatus" -> "CF303Block2ExactStructuredPathV1",
  "SourceInput" -> "/home/maxzhang/factorization-and-loops-codex/Runtime/CF303_exception14_continuation_2026-08-30/sector_CF303_standard/CF303_25_2_input.wl",
  "SourceCheckpoint" -> "/home/maxzhang/factorization-and-loops-codex/Runtime/CF303_exception14_continuation_2026-08-30/sector_CF303_standard/CF303_25_strip_state.wl",
  "SourceInputSHA256" -> "db6c2e6aad6970dceb607fdbd62aa088dedd1f573f92a2f319580b664b90d7e7",
  "SourceCheckpointSHA256" -> "9a9aa8129e91566d7e5267900a402c91968549dbcfe7caca903408a80a2bf7f2",
  "RowRange" -> {44, 45},
  "ColumnRange" -> {2},
  "RowBlockBasis" -> {5, 6},
  "ColumnBlockBasis" -> {39},
  "SourceDimensions" -> {2, 2, 1}, "Dimensions" -> {2, 2, 1},
  "PathDimensions" -> {2, 1},
  "BasisDerivationEvidence" -> "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-30_cf303_25_2_exact_common_path/cf303_25_2_checkpoint_basis_derivation.json",
  "Path" -> <|
    "Chart" -> "Kallen2Bilinear115",
    "ArtifactIdentity" -> <|"Chart" -> "Kallen2Bilinear115",
      "FrozenChartU" -> 3|>,
    "Coordinate" -> "p", "FrozenCoordinate" -> <|"u" -> 3|>,
    "SourceMap" ->
      "a=(4 p (1-p)-6)/(9+4 p (1-p)); x=-a p; y=(1-a)(1-p)",
    "BranchRoots" -> {"a-p", "1+3a"},
    "EndpointContract" ->
      "p(tau)=p0+tau (p1-p0), tau in [0,1], u=3",
    "Reparameterization" ->
      "B_tau(tau,eps)=(p1-p0) B_p(p0+tau(p1-p0),eps)"
  |>,
  "PathExtension" -> <|"Type" -> "None"|>,
  "CommonPathContract" -> "/home/maxzhang/factorization-and-loops-codex/Diagnostics/Artifacts/cf303_u3_common_path_contract.wl",
  "ConstantConvention" ->
    "derive final c25 from authoritative complete PrevD/current A at the eventual row endpoint: c25=Inverse[Phi25[p0]].(I25[p0]-Sum[D25m[p0].Im[p0],{m,1,24}]); D25,2=0",
  "ExactContent" ->
    "accepted-gauge B_(25,2) contracted with dp on the declared fixed path; the literal-zero gauge contribution is additive",
  "Acceptance" -> "ExactPathForcingAccepted",
  "Consumer" ->
    "CodexDiagnostics`ExactPathTransportException`InstallExactPathTransportExceptionIntoAhat",
  "InstallationStage" ->
    "after every other coupling has been restricted to the same path and before masterTransportDepthBudget/masterTransportBlockwiseSolve",
  "AssemblyRequirement" ->
    "the caller must supply a complete path connection without eagerly materializing this exceptional source block",
  "GaugeScreenDisposition" ->
    "31-form conservative-superset GaugeImageObstruction at two images is ansatz-relative motivation only and is not promoted to a global obstruction",
  "ClaimBoundary" ->
    "exact accepted-gauge forcing only on the fixed u=3 path; ExactPathForcingAccepted, not EpsFormObstructionCertified, global no-eps-form, or a family epsilon-form certificate",
  "AcceptanceEvidence" -> {
    "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-30_cf303_25_2_exact_common_path/cf303_25_2_common_path_degree_p2147483423_e11.json",
    "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-30_cf303_25_2_exact_common_path/cf303_25_2_common_epsilon_degree_p2147483423_z27.json",
    "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-30_cf303_25_2_exact_common_path/cf303_25_2_exact_path_report.json",
    "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-30_cf303_25_2_exact_common_path/cf303_25_2_exact_path_unseen_prime.json",
    "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-30_cf303_25_2_exact_common_path/cf303_25_2_path_campaign_checkpoint.json",
    "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-30_cf303_25_2_exact_common_path/cf303_25_2_checkpoint_basis_derivation.json"
  }
|>
