#!/usr/bin/env wolframscript
(* Path-transport exception seam (PathTransportException.wl).

   Acceptance criteria, stated before any is run (Codex note 20 Wave A):

   A1. ONE pullback for the complete connection: on a toy contract with
       a rationalized branch AND a residual extension root, the full
       Ahat must contain neither the source variables, nor the contract
       path variable, nor the bare root symbol -- and must contain the
       explicit Sqrt of the root square composed with the path.  A
       hand-computed entry pins the curve derivative and the single
       endpoint Jacobian; the installed exceptional forcing, chosen as
       an exact z-derivative, must equal d/dtau of its antiderivative
       composed with the path.
   A2. Capability matches the implemented engine:
       1/(tau^2+3tau+1) admitted; Sqrt[2]/(tau-3) admitted (tau-free
       radical); Sqrt[tau+5]/(tau+7) refused as
       TauDependentAlgebraicCover regardless of radicand degree; a
       degree-three rational denominator preserves the engine's named
       refusal DenominatorDegreeAboveTwoInTau; the real (25,14)
       artifact refuses as a tau-dependent cover.
   A3. The route claim is scoped: the prepared result exposes
       ExceptionalBlocksRoute, not a whole-connection guarantee.
   A4. Declared record valuation is descriptive: an inconsistent
       declaration does NOT refuse; the depth budget reads the
       installed mathematics only (eps^-1 forcing raises the lower
       block's Need from 2 to 3 either way).
   B.  Mixed record/contract identities refuse before assembly.
   F.  Real CF303 records (guarded SKIP when absent): (25,18)
       reparameterizes with typed verdicts; (25,14) refuses into the
       quadrature branch. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

pte = Symbol["FeynFacet`Private`" <> #] &;
tmp = CreateDirectory[FileNameJoin[{$TemporaryDirectory,
  "t_path_transport_exception_" <> ToString[$ProcessID]}]];

toyZ = Global`toyPathZ; toyEps = Global`toyPathEps;
toyX = Global`toyPathX; toyY = Global`toyPathY;
toyRR = Global`toyPathResidualRoot;
tau = Global`toyPathTau;

(* contract with one rationalized branch (Sqrt[P1] -> 1 + z) and one
   residual root (Sqrt[P2] -> toyRR, toyRR^2 = z^3 + 2 on the path) *)
toyP1 = toyX + toyY^2;
toyP2 = 1 + toyX toyY;
toyContract = <|"Status" -> "ExactParametricPathContractV1",
  "Family" -> "TOY", "HardSector" -> 2, "Chart" -> "ToyChart",
  "FrozenCoordinates" -> <||>, "Variables" -> {toyX, toyY},
  "PathVariable" -> toyZ,
  "SourcePath" -> <|toyX -> toyZ^2, toyY -> 1 - toyZ|>,
  "SourceRootSquares" -> {toyP1, toyP2},
  "SourceRootBranches" -> {1 + toyZ, toyRR},
  "SourceRootRules" ->
    {Sqrt[toyP1] -> 1 + toyZ, Sqrt[toyP2] -> toyRR},
  "PathExtension" -> <|"Type" -> "Quadratic", "Root" -> toyRR,
    "RootSquare" -> toyZ^3 + 2, "Representation" -> "ExplicitSqrt",
    "BranchConvention" -> "toy principal sheet"|>|>;

toyG[z_] := 1/(z + 2);
toyArtifactFile = FileNameJoin[{tmp, "toy_rational_artifact.wl"}];
Put[<|"Status" -> "ToyPathForcingV1", "Family" -> "TOY",
  "HardSector" -> 2, "LowerSector" -> 1, "PathVariable" -> toyZ,
  "Regulator" -> toyEps,
  "PathForcing" -> {{D[toyG[toyZ], toyZ] (1/toyEps + 1)}}|>,
  toyArtifactFile];

toyRecord = <|"Status" -> "ExactPathTransportExceptionReadyV1",
  "Method" -> "ExactRationalPathTransportException",
  "Gauge" -> "LiteralZero", "Installed" -> False, "ExactDLog" -> False,
  "Family" -> "TOY", "HardSector" -> 2, "LowerSector" -> 1,
  "ArtifactStatus" -> "ToyPathForcingV1",
  "ArtifactFile" -> toyArtifactFile,
  "RowRange" -> {2}, "ColumnRange" -> {1},
  "RowBlockBasis" -> {2}, "ColumnBlockBasis" -> {1},
  "PathDimensions" -> {1, 1},
  "RegulatorValuation" -> -1,
  "Path" -> <|"Chart" -> "ToyChart", "FrozenCoordinate" -> <||>,
    "ArtifactIdentity" -> <|"Status" -> "ToyPathForcingV1"|>,
    "BranchRoots" -> {}|>,
  "PathExtension" -> <|"Type" -> "None"|>|>;

toyAssembly = <|"Blocks" -> {{1}, {2}}, "Ranges" -> {{1}, {2}}|>;
(* diagonal (1,1) carries the rationalized branch; diagonal (2,2)
   carries the residual root; the (2,1) slot is overwritten by the
   installation *)
toyApv = {{toyEps Sqrt[toyP1], 0}, {0, toyEps/(toyX + 3)}};
toyApw = {{0, 0}, {0, toyEps Sqrt[toyP2]}};
toyEndpoints = {1/5, 4/5};
toyPlan = <|"PathContract" -> toyContract, "Endpoints" -> toyEndpoints,
  "Records" -> {toyRecord}|>;

prepared = pte["pathTransportExceptionPrepare"][toyAssembly, toyApv,
  toyApw, toyPlan, tau, toyEps, 2];

FTAssert["prepare returns the prepared status",
  AssociationQ[prepared] &&
    prepared["Status"] === "PathTransportExceptionPreparedV1"];

(* A1: one curve for the COMPLETE connection *)
Module[{ahat, ztau, expected},
  ahat = prepared["Ahat"];
  FTAssert["A1: no source variable survives the pullback",
    FreeQ[ahat, toyX] && FreeQ[ahat, toyY]];
  FTAssert["A1: no contract path variable survives the pullback",
    FreeQ[ahat, toyZ]];
  FTAssert["A1: no bare residual-root symbol survives the pullback",
    FreeQ[ahat, toyRR]];
  ztau = toyEndpoints[[1]] + tau (toyEndpoints[[2]] - toyEndpoints[[1]]);
  FTAssert["A1: residual root appears as Sqrt of its path square",
    ! FreeQ[ahat[[2, 2]], Sqrt[ztau^3 + 2]]];
  (* hand computation of the (1,1) entry: branch(z) x'(z) dz/dtau *)
  expected = (toyEndpoints[[2]] - toyEndpoints[[1]]) *
    toyEps (1 + ztau) (2 ztau);
  FTAssert["A1: rationalized-branch entry matches the hand pullback",
    Together[ahat[[1, 1]] - expected] === 0];
  expected = D[toyG[ztau], tau] (1/toyEps + 1);
  FTAssert["A1: installed forcing = d/dtau of known antiderivative",
    Together[ahat[[2, 1]] - expected] === 0]];

(* A3 + A4: scoped route name; descriptive valuation; budget from the
   installed mathematics *)
FTAssert["A3: route is scoped to the exceptional blocks",
  prepared["ExceptionalBlocksRoute"] === "Blockwise" &&
    ! KeyExistsQ[prepared, "Route"]];
FTAssert["A4: eps^-1 forcing raises the lower Need through the budget",
  prepared["Budget"]["Need"] === {3, 2}];
Module[{declaredWrong, out},
  declaredWrong = toyPlan;
  declaredWrong["Records"] =
    {Append[toyRecord, "RegulatorValuation" -> 0]};
  out = pte["pathTransportExceptionPrepare"][toyAssembly, toyApv,
    toyApw, declaredWrong, tau, toyEps, 2];
  FTAssert["A4: inconsistent declared valuation does not refuse",
    out["Status"] === "PathTransportExceptionPreparedV1" &&
      out["Budget"]["Need"] === {3, 2} &&
      TrueQ[! out["Reports"][[1]]["Valuation"]["Consistent"]]]];

(* B: mixed identity refuses before assembly *)
Module[{mixed, issues},
  mixed = toyPlan;
  mixed["Records"] = {ReplacePart[toyRecord,
    Key["Path"] -> Append[toyRecord["Path"], "Chart" -> "OtherChart"]]};
  issues = pte["pathTransportExceptionPlanIssues"][mixed];
  FTAssert["B: mixed chart refused before assembly",
    MemberQ[issues, "RecordContractPathMismatch"]]];

(* A2: capability against the implemented engine, entry by entry *)
Module[{cap},
  cap = pte["pathTransportExceptionEntryCapability"];
  FTAssert["A2: rational quadratic denominator admitted",
    TrueQ[cap[1/(tau^2 + 3 tau + 1), tau, toyEps]["Admitted"]]];
  FTAssert["A2: tau-free radical coefficient admitted",
    TrueQ[cap[Sqrt[2]/(tau - 3), tau, toyEps]["Admitted"]]];
  FTAssert["A2: Sqrt[tau+5]/(tau+7) refused as a tau-dependent cover",
    Module[{v = cap[Sqrt[tau + 5]/(tau + 7), tau, toyEps]},
      ! TrueQ[v["Admitted"]] &&
        v["Reason"] === "TauDependentAlgebraicCover"]];
  FTAssert["A2: inverse root refused as a tau-dependent cover",
    Module[{v = cap[1/Sqrt[tau + 5], tau, toyEps]},
      ! TrueQ[v["Admitted"]] &&
        v["Reason"] === "TauDependentAlgebraicCover"]];
  FTAssert["A2: degree-three denominator keeps the engine's named refusal",
    Module[{v = cap[1/(tau^3 + 2), tau, toyEps]},
      ! TrueQ[v["Admitted"]] &&
        v["Reason"] === "DenominatorDegreeAboveTwoInTau"]]];

(* branch derivative through ordinary D, no upvalues *)
Module[{q},
  q = (toyZ + 5) /. toyZ ->
    toyEndpoints[[1]] + tau (toyEndpoints[[2]] - toyEndpoints[[1]]);
  FTAssert["branch derivative = rootSquare'/(2 root) via ordinary D",
    Together[D[Sqrt[q], tau] - D[q, tau]/(2 Sqrt[q])] === 0]];

(* a quadratic-cover forcing routes the PLAN to the quadrature branch *)
Module[{qArtifactFile, qRecord, qPlan, qPrepared},
  qArtifactFile = FileNameJoin[{tmp, "toy_cover_artifact.wl"}];
  Put[<|"Status" -> "ToyCoverForcingV1", "Family" -> "TOY",
    "HardSector" -> 2, "LowerSector" -> 1, "PathVariable" -> toyZ,
    "Regulator" -> toyEps,
    "PathExtensionRoot" -> toyRR,
    "PathExtensionRootSquare" -> toyZ + 5,
    "PathForcing" -> {{toyRR/(toyZ + 7)}}|>, qArtifactFile];
  qRecord = Join[toyRecord, <|
    "Method" -> "ExactQuadraticPathTransportException",
    "ArtifactStatus" -> "ToyCoverForcingV1",
    "ArtifactFile" -> qArtifactFile,
    "RegulatorValuation" -> 0,
    "PathExtension" -> <|"Type" -> "Quadratic", "Root" -> toyRR,
      "RootSquare" -> toyZ + 5, "Representation" -> "ExplicitSqrt",
      "BranchConvention" -> "toy principal sheet"|>|>];
  qRecord["Path"] = Append[qRecord["Path"],
    "ArtifactIdentity" -> <|"Status" -> "ToyCoverForcingV1"|>];
  qPlan = <|"PathContract" -> Join[toyContract,
      <|"PathExtension" -> qRecord["PathExtension"]|>],
    "Endpoints" -> toyEndpoints, "Records" -> {qRecord}|>;
  qPrepared = pte["pathTransportExceptionPrepare"][toyAssembly, toyApv,
    toyApw, qPlan, tau, toyEps, 2];
  FTAssert["A2: any tau-dependent cover routes the plan to quadrature",
    qPrepared["ExceptionalBlocksRoute"] === "AlgebraicQuadratureRequired" &&
      MemberQ[qPrepared["ExceptionalBlocksCapability"]["Refusals"],
        "TauDependentAlgebraicCover"]]];

(* F: real CF303 records, guarded SKIP when absent *)
Module[{recDir, rec18, rec14, r18, r14, rep, entries, verdicts},
  recDir = "/home/maxzhang/factorization-and-loops-codex/Diagnostics/Artifacts";
  rec18 = FileNameJoin[{recDir, "cf303_25_18_exact_path_exception_record.wl"}];
  rec14 = FileNameJoin[{recDir, "cf303_25_14_exact_path_exception_record.wl"}];
  If[! (FileExistsQ[rec18] && FileExistsQ[rec14]),
    Print["SKIP  real CF303 records not present on this machine"],
    r18 = Quiet[Check[Get[rec18], $Failed]];
    r14 = Quiet[Check[Get[rec14], $Failed]];
    FTAssert["F: real records satisfy the record contract",
      pte["pathTransportExceptionRecordQ"][r18] &&
        pte["pathTransportExceptionRecordQ"][r14]];
    rep = pte["pathTransportExceptionReparameterize"][r18, tau,
      Global`realEps, {1/7, 5/7}];
    FTAssert["F: (25,18) artifact reparameterizes",
      rep["Status"] === "PathTransportExceptionReparameterizedV1"];
    entries = Take[Flatten[rep["PathBlock"]], UpTo[2]];
    verdicts = pte["pathTransportExceptionEntryCapability"][#, tau,
      Global`realEps] & /@ entries;
    FTAssert["F: (25,18) entries yield typed capability verdicts",
      AllTrue[verdicts, AssociationQ[#] &&
        BooleanQ[Lookup[#, "Admitted", None]] &]];
    rep = pte["pathTransportExceptionReparameterize"][r14, tau,
      Global`realEps, {1/7, 5/7}];
    FTAssert["F: (25,14) artifact reparameterizes",
      rep["Status"] === "PathTransportExceptionReparameterizedV1"];
    entries = Take[Flatten[rep["PathBlock"]], UpTo[4]];
    verdicts = pte["pathTransportExceptionEntryCapability"][#, tau,
      Global`realEps] & /@ entries;
    FTAssert["F: (25,14) refuses into the quadrature branch",
      AnyTrue[verdicts, ! TrueQ[#["Admitted"]] &&
        #["Reason"] === "TauDependentAlgebraicCover" &]]]];

(* ================= Wave B: formal quadrature consumer ============= *)

(* T1, 1x1 terminal toy on the prepared plan: hard block 2, forcing
   with an eps^-1 layer.  U is supplied exactly (abelian tower of the
   pulled-back diagonal), and the BRUTE differentiate-back residual is
   checked per order, independently of the module's internal premises. *)
Module[{ztau, preparedB1, a1, u, iOrd, q, aOrd, bEntry, bOrd, dlt,
   residual, ok},
  ztau = toyEndpoints[[1]] + tau (toyEndpoints[[2]] - toyEndpoints[[1]]);
  (* dedicated fixture: root-free diagonal so U has a closed dlog tower
     (the main toy's (2,2) diagonal carries the residual root, which
     has no elementary antiderivative to supply U from) *)
  preparedB1 = pte["pathTransportExceptionPrepare"][toyAssembly,
    {{0, 0}, {0, toyEps/(toyX + 3)}}, {{0, 0}, {0, 0}},
    (* root-free fixture: a None-extension contract, else the consumer
       rightly demands a sheet value for the declared quadratic cover *)
    Join[toyPlan, <|"PathContract" -> Join[toyContract,
      <|"PathExtension" -> <|"Type" -> "None"|>|>]|>],
    tau, toyEps, 2];
  a1 = Coefficient[preparedB1["Ahat"][[2, 2]], toyEps, 1];
  FTAssert["B-T1: pulled-back diagonal is an exact dlog derivative",
    Together[a1 - D[Log[ztau^2 + 3], tau]] === 0];
  u = <|0 -> {{1}}, 1 -> {{Log[ztau^2 + 3] - Log[(1/5)^2 + 3]}}|>;
  u[2] = {{u[1][[1, 1]]^2/2}};
  iOrd = <|1 -> <|0 -> {1}, 1 -> {ztau}, 2 -> {ztau^2}|>|>;
  q = pte["pathTransportExceptionQuadrature"][preparedB1, toyAssembly, 2,
    u, iOrd, tau, toyEps, {-1, 0, 1}];
  FTAssert["B-T1: status is OKFormalPathQuadrature",
    q["Status"] === "OKFormalPathQuadrature"];
  FTAssert["B-T1: forcing minimum order and lower depth agree",
    q["ForcingMinimumOrder"] === -1 && q["LowerOrdersUsed"] === 2];
  FTAssert["B-T1: certificate premises checked on this data",
    TrueQ[q["Certificate"]["HomogeneousSeriesResidualZero"]] &&
      TrueQ[q["Certificate"]["PropagatorInverseResidualZero"]]];
  FTAssert["B-T1: the correction vanishes at the basepoint",
    AllTrue[Flatten[Values[q["DeltaI"]]] /. tau -> 0,
      TrueQ[Simplify[#] === 0] &]];
  aOrd = <|1 -> a1|>;
  bEntry = preparedB1["Ahat"][[2, 1]];
  bOrd = <|-1 -> Coefficient[bEntry toyEps, toyEps, 0],
    0 -> Coefficient[bEntry toyEps, toyEps, 1]|>;
  dlt = q["DeltaI"];
  ok = True;
  Do[
    residual = D[Lookup[dlt, n, {0}][[1]], tau] -
      Sum[Lookup[aOrd, a, 0] Lookup[dlt, n - a, {0}][[1]], {a, 1, 1}] -
      Sum[Lookup[bOrd, b, 0] Lookup[iOrd[1], n - b, {0}][[1]],
        {b, -1, 0}];
    ok = ok && TrueQ[Together[Expand[residual]] === 0],
    {n, -1, 1}];
  FTAssert["B-T1: brute differentiate-back residual is zero per order",
    ok]];

(* T2, 2x2 hard block with a noncommuting constant residue *)
Module[{assembly2, m, ahat2, prepared2, u, iOrd, q, dlt, aOrd, bOrd,
   residual, ok},
  assembly2 = <|"Blocks" -> {{1}, {2, 3}}, "Ranges" -> {{1}, {2, 3}}|>;
  m = {{0, 1}, {1, 0}};
  ahat2 = ConstantArray[0, {3, 3}];
  ahat2[[2 ;; 3, 2 ;; 3]] = toyEps m;
  ahat2[[2 ;; 3, 1 ;; 1]] = {{1/(tau + 2)}, {tau}};
  prepared2 = <|"Ahat" -> ahat2, "Extension" -> <|"Type" -> "None"|>|>;
  u = <|0 -> IdentityMatrix[2], 1 -> m tau, 2 -> (m . m) tau^2/2|>;
  iOrd = <|1 -> <|0 -> {1}, 1 -> {tau^2}|>|>;
  q = pte["pathTransportExceptionQuadrature"][prepared2, assembly2, 2,
    u, iOrd, tau, toyEps, {0, 1}];
  FTAssert["B-T2: 2x2 status is OKFormalPathQuadrature",
    q["Status"] === "OKFormalPathQuadrature"];
  dlt = q["DeltaI"];
  aOrd = <|1 -> m|>;
  bOrd = <|0 -> {{1/(tau + 2)}, {tau}}|>;
  ok = True;
  Do[
    residual = Map[D[#, tau] &, Lookup[dlt, n, {0, 0}]] -
      Sum[Lookup[aOrd, a, ConstantArray[0, {2, 2}]] .
        Lookup[dlt, n - a, {0, 0}], {a, 1, 1}] -
      Sum[Lookup[bOrd, b, ConstantArray[0, {2, 1}]] .
        Lookup[iOrd[1], n - b, {0}], {b, 0, 0}];
    ok = ok && AllTrue[residual,
      TrueQ[Together[Expand[#]] === 0] &],
    {n, 0, 1}];
  FTAssert["B-T2: 2x2 brute differentiate-back residual is zero",
    ok];
  (* insufficient lower depth refuses with the computed need *)
  q = pte["pathTransportExceptionQuadrature"][prepared2, assembly2, 2,
    u, <|1 -> <|0 -> {1}|>|>, tau, toyEps, {0, 1}];
  FTAssert["B-T3: insufficient lower orders refuse with the need",
    q["Status"] === "InsufficientLowerOrders" &&
      q["NeedLowerThrough"] === 1]];

(* T4, non-terminal hard block refuses by name *)
Module[{assembly3, ahat3, prepared3, q},
  assembly3 = <|"Blocks" -> {{1}, {2}, {3}},
    "Ranges" -> {{1}, {2}, {3}}|>;
  ahat3 = ConstantArray[0, {3, 3}];
  ahat3[[2, 1]] = 1/(tau + 2);
  ahat3[[3, 2]] = tau;   (* block 3 reads the hard block *)
  prepared3 = <|"Ahat" -> ahat3, "Extension" -> <|"Type" -> "None"|>|>;
  q = pte["pathTransportExceptionQuadrature"][prepared3, assembly3, 2,
    <|0 -> {{1}}|>, <|1 -> <|0 -> {1}|>|>, tau, toyEps, {0}];
  FTAssert["B-T4: non-terminal target refuses NestedQuadratureRequired",
    q["Status"] === "NestedQuadratureRequired"]];

(* T5, a quadratic extension without a sheet datum refuses: a prose
   branch convention is not a branch implementation *)
Module[{prepared5, q},
  prepared5 = <|"Ahat" -> ConstantArray[0, {2, 2}],
    "Extension" -> <|"Type" -> "Quadratic",
      "BranchConvention" -> "prose only"|>|>;
  q = pte["pathTransportExceptionQuadrature"][prepared5, toyAssembly, 2,
    <|0 -> {{1}}|>, <|1 -> <|0 -> {1}|>|>, tau, toyEps, {0}];
  FTAssert["B-T5: missing sheet datum refuses SheetDatumRequired",
    q["Status"] === "SheetDatumRequired"]];

DeleteDirectory[tmp, DeleteContents -> True];
FTTest`FTReport[];
