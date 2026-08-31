<|
  "Status" -> "ExactPathTransportExceptionReadyV1",
  "Family" -> "CF303",
  "HardSector" -> 25,
  "LowerSector" -> 11,
  "Method" -> "ExactQuadraticPathTransportException",
  "Gauge" -> "LiteralZero",
  "Installed" -> False,
  "ExactDLog" -> False,

  "ArtifactFile" ->
    "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-30_cf303_25_11_exact_common_path/cf303_25_11_exact_quadratic_path.wl",
  "ArtifactStatus" -> "CF303Block11ExactQuadraticPathV1",
  "SourceInput" ->
    "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-30_cf303_25_11_exact_common_path/cf303_25_11_exact_path_coefficients.json",

  "RowRange" -> {44, 45},
  "ColumnRange" -> {12},
  "RowBlockBasis" -> {5, 6},
  "ColumnBlockBasis" -> {8},
  "SourceDimensions" -> {2, 2, 1},
  "Dimensions" -> {2, 2, 1},
  "PathDimensions" -> {2, 1},

  "Path" -> <|
    "Chart" -> "Kallen2Bilinear115",
    "ArtifactIdentity" -> <|
      "Chart" -> "Kallen2Bilinear115", "FrozenChartU" -> 3|>,
    "Coordinate" -> "p",
    "FrozenCoordinate" -> <|"u" -> 3|>,
    "SourceMap" ->
      "a=(4 p (1-p)-6)/(9+4 p (1-p)); x=-a p; y=(1-a)(1-p)",
    "BranchRoots" -> {"r2 on the selected quadratic sheet", "a-p",
      "1+3a"},
    "EndpointContract" ->
      "p(tau)=p0+tau (p1-p0), tau in [0,1], u=3",
    "Reparameterization" ->
      "B_tau(tau,eps)=(p1-p0) B_p(p0+tau(p1-p0),eps)"
  |>,
  "PathExtension" -> <|
    "Type" -> "Quadratic",
    "ArtifactRootField" -> "PathRoot",
    "ArtifactRootSquareField" -> "PathRootSquare",
    "Representation" -> "ExplicitSqrt",
    "RootRelation" ->
      "r2^2=(16 p^6-104 p^4+288 p^3-311 p^2-456 p+576)/(4 p^2-4 p-9)^2",
    "DerivativeRule" ->
      "r2'=Delta2'/(2 r2)=P'/(2 r2 D^2)-r2 D'/D",
    "BranchConvention" ->
      "choose one value of r2 at the basepoint and continue that sheet; the opposite sheet is its negative"
  |>,
  "CommonPathContract" ->
    "/home/maxzhang/factorization-and-loops-codex/Diagnostics/Artifacts/cf303_u3_common_path_contract.wl",

  "ConstantConvention" ->
    "derive final c25 from the authoritative complete PrevD/current A at the eventual row endpoint; D25,11=0",
  "ExactContent" ->
    "accepted-gauge B_(25,11)=B0+r2 B1 contracted with dp on the declared fixed path; channels {1,r2}x{row 1,2}x{column 1}; the literal-zero gauge contribution is additive",
  "Consumer" ->
    "FeynFacet`Private`pathTransportExceptionInstall / CodexDiagnostics`ExactPathTransportException`InstallExactPathTransportExceptionIntoAhat",
  "InstallationStage" ->
    "after every other coupling has been restricted to the same path and before masterTransportDepthBudget/masterTransportBlockwiseSolve",
  "AssemblyRequirement" ->
    "the caller must supply a complete path connection without eagerly materializing this exceptional source block",
  "ClaimBoundary" ->
    "exact accepted-gauge forcing only on the fixed u=3 path over one residual quadratic root; ExactPathForcingAccepted, not EpsFormObstructionCertified and not a family epsilon-form certificate",

  "AcceptanceEvidence" -> {
    "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-30_cf303_25_11_exact_common_path/cf303_25_11_exact_path_report.json",
    "/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-30_cf303_25_11_exact_common_path/cf303_25_11_exact_path_unseen_prime.json"
  }
|>
