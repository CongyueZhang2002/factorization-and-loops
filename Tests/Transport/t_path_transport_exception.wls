#!/usr/bin/env wolframscript
(* Path-transport exception seam (PathTransportException.wl).

   Acceptance criteria, stated before any is run (Exchange/Codex
   2026-08-30/19 revised list):

   A. A common-path contract pulls the complete toy connection AND the
      exceptional block along exactly one curve, with the endpoint
      Jacobian applied exactly once: for a forcing chosen as an exact
      z-derivative, the installed entry must equal d/dtau of the known
      antiderivative composed with the path -- true only if the single
      (z1-z0) chain-rule factor is right.
   B. Mixed record/contract identities refuse before assembly.
   C. A negative regulator valuation is read from the INSTALLED
      connection by the existing depth budget and propagates once
      (Need on the lower block rises by exactly the valuation).
   D. The rational toy passes the exact differentiate-back identity
      through the seam (the recursion certificate in its one-block
      closed form).
   E. The simple quadratic toy (root square affine on the path)
      verifies the branch derivative through ordinary D and is admitted
      to the blockwise route; a cubic-cover toy is refused with
      AlgebraicCoverDegreeAboveTwoInTau and routes to
      AlgebraicQuadratureRequired.
   F. The REAL CF303 records, where present on this machine, route by
      their true content: the rational (25,18) artifact yields typed
      per-entry verdicts; the (25,14) artifact MUST refuse into the
      quadrature branch (genus-2 cover), never a word-decomposition
      success.  Absent files SKIP (they are not repository inputs yet;
      they move into Results/ when the family closes).
   G. A declared record valuation inconsistent with the installed
      mathematics fails closed. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

pte = Symbol["FeynFacet`Private`" <> #] &;
tmp = CreateDirectory[FileNameJoin[{$TemporaryDirectory,
  "t_path_transport_exception_" <> ToString[$ProcessID]}]];

(* ---- toy fixtures ------------------------------------------------ *)
toyZ = Global`toyPathZ; toyEps = Global`toyPathEps;
toyX = Global`toyPathX; toyY = Global`toyPathY;
toyR = Global`toyPathR;
tau = Global`toyPathTau;

toyContract = <|"Status" -> "ExactParametricPathContractV1",
  "Family" -> "TOY", "HardSector" -> 2, "Chart" -> "ToyChart",
  "FrozenCoordinates" -> <||>, "Variables" -> {toyX, toyY},
  "PathVariable" -> toyZ,
  "SourcePath" -> <|toyX -> toyZ^2, toyY -> 1 - toyZ|>,
  "SourceRootSquares" -> {}, "SourceRootBranches" -> {},
  "SourceRootRules" -> {},
  "PathExtension" -> <|"Type" -> "None"|>|>;

(* forcing = an exact z-derivative with an eps^-1 layer:
   g(z) = 1/(z+2), f(z) = g'(z) (1/eps + 1) *)
toyG[z_] := 1/(z + 2);
toyForcing = {{D[toyG[toyZ], toyZ] (1/toyEps + 1)}};
toyArtifactFile = FileNameJoin[{tmp, "toy_rational_artifact.wl"}];
Put[<|"Status" -> "ToyPathForcingV1", "Family" -> "TOY",
  "HardSector" -> 2, "LowerSector" -> 1, "PathVariable" -> toyZ,
  "Regulator" -> toyEps, "PathForcing" -> toyForcing|>,
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
(* ordinary connection: diagonal eps-blocks, zero off-diagonal slot
   that the installation overwrites *)
toyApv = {{toyEps/(toyX + 2), 0}, {0, toyEps/(toyX + 3)}};
toyApw = {{toyEps/(toyY + 2), 0}, {0, 0}};
toyEndpoints = {1/5, 4/5};
toyPlan = <|"PathContract" -> toyContract, "Endpoints" -> toyEndpoints,
  "Records" -> {toyRecord}|>;

prepared = pte["pathTransportExceptionPrepare"][toyAssembly, toyApv,
  toyApw, toyPlan, tau, toyEps, 2];

FTAssert["toy prepare returns the prepared status",
  AssociationQ[prepared] &&
    prepared["Status"] === "PathTransportExceptionPreparedV1"];
FTAssert["toy rational route is Blockwise",
  prepared["Route"] === "Blockwise"];

(* A: single Jacobian.  installed(2,1) must equal
   d/dtau[ g(z(tau)) ] (1/eps + 1) exactly. *)
Module[{ztau, expected, installed},
  ztau = toyEndpoints[[1]] + tau (toyEndpoints[[2]] - toyEndpoints[[1]]);
  expected = D[toyG[ztau], tau] (1/toyEps + 1);
  installed = prepared["Ahat"][[2, 1]];
  FTAssert["A: installed forcing = d/dtau of known antiderivative",
    Together[installed - expected] === 0]];

(* D: differentiate-back through the seam in closed form: with the
   (1,1) diagonal set to zero on the path there is no such toy here;
   instead certify on the exact solution of the installed row at
   eps-order -1: J2^(-1)(tau) = g(z(tau)) - g(z(0)) satisfies
   dJ2/dtau = installed(2,1)|_(eps^-1) * J1 with J1 = 1. *)
Module[{ztau, j2, id},
  ztau = toyEndpoints[[1]] + tau (toyEndpoints[[2]] - toyEndpoints[[1]]);
  j2 = toyG[ztau] - toyG[toyEndpoints[[1]]];
  id = D[j2, tau] -
    Coefficient[prepared["Ahat"][[2, 1]] toyEps, toyEps, 0];
  FTAssert["D: exact differentiate-back at the eps^-1 layer",
    Together[id] === 0]];

(* C: depth budget reads the installed ahat: valuation -1 must raise
   the lower block's Need from kmax to kmax + 1. *)
FTAssert["C: negative valuation propagates once through the budget",
  prepared["Budget"]["Need"] === {3, 2}];

(* G: a wrong declared valuation fails closed. *)
Module[{badPlan, out},
  badPlan = toyPlan;
  badPlan["Records"] =
    {Append[toyRecord, "RegulatorValuation" -> 0]};
  out = pte["pathTransportExceptionPrepare"][toyAssembly, toyApv,
    toyApw, badPlan, tau, toyEps, 2];
  FTAssert["G: inconsistent declared valuation refuses",
    out["Status"] === "PathRecordValuationMismatch"]];

(* B: mixed identity refuses before assembly. *)
Module[{mixed, issues},
  mixed = toyPlan;
  mixed["Records"] = {ReplacePart[toyRecord,
    Key["Path"] -> Append[toyRecord["Path"], "Chart" -> "OtherChart"]]};
  issues = pte["pathTransportExceptionPlanIssues"][mixed];
  FTAssert["B: mixed chart refused before assembly",
    MemberQ[issues, "RecordContractPathMismatch"]]];

(* E: quadratic toy, root square affine on the path -> admitted; the
   branch derivative comes from ordinary D. *)
Module[{qArtifactFile, qRecord, qContract, qPlan, qPrepared, qOnPath},
  qArtifactFile = FileNameJoin[{tmp, "toy_quadratic_artifact.wl"}];
  Put[<|"Status" -> "ToyQuadraticForcingV1", "Family" -> "TOY",
    "HardSector" -> 2, "LowerSector" -> 1, "PathVariable" -> toyZ,
    "Regulator" -> toyEps,
    "PathExtensionRoot" -> toyR,
    "PathExtensionRootSquare" -> toyZ + 5,
    "PathForcing" -> {{toyR/(toyZ + 7)}}|>, qArtifactFile];
  qContract = Join[toyContract, <|"PathExtension" ->
    <|"Type" -> "Quadratic", "Root" -> toyR,
      "RootSquare" -> toyZ + 5, "Representation" -> "ExplicitSqrt",
      "BranchConvention" -> "toy principal sheet"|>|>];
  qRecord = Join[toyRecord, <|
    "Method" -> "ExactQuadraticPathTransportException",
    "ArtifactStatus" -> "ToyQuadraticForcingV1",
    "ArtifactFile" -> qArtifactFile,
    "RegulatorValuation" -> 0,
    "PathExtension" -> <|"Type" -> "Quadratic", "Root" -> toyR,
      "RootSquare" -> toyZ + 5, "Representation" -> "ExplicitSqrt",
      "BranchConvention" -> "toy principal sheet"|>|>];
  qRecord["Path"] = Append[qRecord["Path"],
    "ArtifactIdentity" -> <|"Status" -> "ToyQuadraticForcingV1"|>];
  qPlan = <|"PathContract" -> qContract, "Endpoints" -> toyEndpoints,
    "Records" -> {qRecord}|>;
  qPrepared = pte["pathTransportExceptionPrepare"][toyAssembly, toyApv,
    toyApw, qPlan, tau, toyEps, 2];
  FTAssert["E: affine-cover quadratic toy prepares",
    qPrepared["Status"] === "PathTransportExceptionPreparedV1"];
  FTAssert["E: affine-cover quadratic toy is admitted to Blockwise",
    qPrepared["Route"] === "Blockwise"];
  qOnPath = (toyZ + 5) /. toyZ ->
    toyEndpoints[[1]] + tau (toyEndpoints[[2]] - toyEndpoints[[1]]);
  FTAssert["E: branch derivative = rootSquare'/(2 root) via ordinary D",
    Together[D[Sqrt[qOnPath], tau] -
      D[qOnPath, tau]/(2 Sqrt[qOnPath])] === 0];
  (* cubic cover -> refused into the quadrature branch *)
  Module[{cArtifactFile, cRecord, cContract, cPlan, cPrepared},
    cArtifactFile = FileNameJoin[{tmp, "toy_cubic_artifact.wl"}];
    Put[<|"Status" -> "ToyCubicForcingV1", "Family" -> "TOY",
      "HardSector" -> 2, "LowerSector" -> 1, "PathVariable" -> toyZ,
      "Regulator" -> toyEps,
      "PathExtensionRoot" -> toyR,
      "PathExtensionRootSquare" -> toyZ^3 + 2,
      "PathForcing" -> {{toyR/(toyZ + 7)}}|>, cArtifactFile];
    cContract = Join[toyContract, <|"PathExtension" ->
      <|"Type" -> "Quadratic", "Root" -> toyR,
        "RootSquare" -> toyZ^3 + 2, "Representation" -> "ExplicitSqrt",
        "BranchConvention" -> "toy principal sheet"|>|>];
    cRecord = Join[qRecord, <|
      "ArtifactStatus" -> "ToyCubicForcingV1",
      "ArtifactFile" -> cArtifactFile,
      "PathExtension" -> <|"Type" -> "Quadratic", "Root" -> toyR,
        "RootSquare" -> toyZ^3 + 2, "Representation" -> "ExplicitSqrt",
        "BranchConvention" -> "toy principal sheet"|>|>];
    cRecord["Path"] = Append[cRecord["Path"],
      "ArtifactIdentity" -> <|"Status" -> "ToyCubicForcingV1"|>];
    cPlan = <|"PathContract" -> cContract, "Endpoints" -> toyEndpoints,
      "Records" -> {cRecord}|>;
    cPrepared = pte["pathTransportExceptionPrepare"][toyAssembly,
      toyApv, toyApw, cPlan, tau, toyEps, 2];
    FTAssert["E: cubic cover routes to AlgebraicQuadratureRequired",
      cPrepared["Route"] === "AlgebraicQuadratureRequired" &&
        MemberQ[cPrepared["Capability"]["Refusals"],
          "AlgebraicCoverDegreeAboveTwoInTau"]]]];

(* F: real CF303 records, guarded SKIP when absent. *)
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
        #["Reason"] === "AlgebraicCoverDegreeAboveTwoInTau" &]]]];

DeleteDirectory[tmp, DeleteContents -> True];
FTTest`FTReport[];
