(* Path-transport exception seam: consume an ACCEPTED exceptional
   off-diagonal block as a typed fixed-path forcing record inside the
   blockwise transport representation.

   Two distinct concepts, never conflated (Codex note 20 A4): a record
   here asserts ExactPathForcingAccepted -- a constructive, modularly
   accepted path forcing sufficient to transport the row.  The stronger
   necessity claim, EpsFormObstructionCertified -- that no epsilon form
   of the block exists at all -- is a separate statement with its own
   certificate standard and is NOT implied by a record's presence.

   Scope contract (Exchange/Codex/2026-08-30/19, Exchange/Fable
   2026-08-30/10): this is a LOWER-LEVEL API.  It receives the family
   connection matrices and a typed plan, builds the COMPLETE connection
   on the plan's one path contract, installs the exceptional blocks into
   that same pullback, and routes the result by capability: either the
   caller may run the ordinary blockwise engine, or the installed block
   is outside the engine's proven representation class (an algebraic
   cover whose square exceeds degree two in the path parameter, or a
   denominator the linearizer refuses) and an inert typed
   AlgebraicQuadratureRequired record is returned instead.  It is NOT
   wired into TransportFamily and must not be reached from an ordinary
   axis-path transport: mixing one subblock pulled back along the
   contract path into a connection pulled back along a different path
   would combine forms from two different curves.

   No family names appear here.  All family content arrives through the
   typed contract, records, and artifact files. *)

ClearAll[
  pathTransportExceptionContractQ, pathTransportExceptionRecordQ,
  pathTransportExceptionExtensionQ, pathTransportExceptionPlanIssues,
  pathTransportExceptionPlanQ, pathTransportExceptionConnection,
  pathTransportExceptionArtifact, pathTransportExceptionReparameterize,
  pathTransportExceptionLocateBlock, pathTransportExceptionInstall,
  pathTransportExceptionValuationCheck, pathTransportExceptionCapability,
  pathTransportExceptionEntryCapability, pathTransportExceptionPrepare];

(* Two accepted spellings of a quadratic extension: the contract form
   carries the root and its square directly; the record form of the
   accepted artifacts names the ARTIFACT FIELDS that hold them
   (scratch-adapter schema).  Both must load unchanged. *)
pathTransportExceptionExtensionQ[extension_] := AssociationQ[extension] &&
  Switch[Lookup[extension, "Type", None],
    "None", True,
    "Quadratic",
      Lookup[extension, "Representation", None] === "ExplicitSqrt" &&
        StringQ[Lookup[extension, "BranchConvention", None]] &&
        ((StringQ[Lookup[extension, "ArtifactRootField", None]] &&
            StringQ[Lookup[extension, "ArtifactRootSquareField", None]]) ||
          (! MissingQ[Lookup[extension, "Root", Missing["NoRoot"]]] &&
            ! MissingQ[Lookup[extension, "RootSquare",
                Missing["NoSquare"]]])),
    _, False];
pathTransportExceptionExtensionQ[___] := False;

pathTransportExceptionContractQ[contract_] := AssociationQ[contract] &&
  Lookup[contract, "Status", None] === "ExactParametricPathContractV1" &&
  StringQ[Lookup[contract, "Family", None]] &&
  IntegerQ[Lookup[contract, "HardSector", None]] &&
  MatchQ[Lookup[contract, "Variables", None], {_Symbol, _Symbol}] &&
  MatchQ[Lookup[contract, "PathVariable", None], _Symbol] &&
  AssociationQ[Lookup[contract, "SourcePath", None]] &&
  Sort[Keys[contract["SourcePath"]]] === Sort[contract["Variables"]] &&
  ListQ[Lookup[contract, "SourceRootSquares", None]] &&
  ListQ[Lookup[contract, "SourceRootBranches", None]] &&
  Length[contract["SourceRootSquares"]] ===
    Length[contract["SourceRootBranches"]] &&
  ListQ[Lookup[contract, "SourceRootRules", None]] &&
  pathTransportExceptionExtensionQ[
    Lookup[contract, "PathExtension", <|"Type" -> "None"|>]];
pathTransportExceptionContractQ[___] := False;

(* Record schema: identical to the accepted scratch-adapter/artifact
   contract so the existing exception records load unchanged. *)
pathTransportExceptionRecordQ[record_] := AssociationQ[record] &&
  Lookup[record, "Status", None] === "ExactPathTransportExceptionReadyV1" &&
  MemberQ[{"ExactRationalPathTransportException",
      "ExactQuadraticPathTransportException"},
    Lookup[record, "Method", None]] &&
  Lookup[record, "Gauge", None] === "LiteralZero" &&
  Lookup[record, "Installed", True] === False &&
  Lookup[record, "ExactDLog", True] === False &&
  StringQ[Lookup[record, "ArtifactFile", None]] &&
  MatchQ[Lookup[record, "RowRange", None], {__Integer?Positive}] &&
  MatchQ[Lookup[record, "ColumnRange", None], {__Integer?Positive}] &&
  MatchQ[Lookup[record, "RowBlockBasis", None], {__Integer?Positive}] &&
  MatchQ[Lookup[record, "ColumnBlockBasis", None], {__Integer?Positive}] &&
  Lookup[record, "PathDimensions", None] ===
    {Length[record["RowRange"]], Length[record["ColumnRange"]]} &&
  AssociationQ[Lookup[record, "Path", None]] &&
  StringQ[Lookup[record["Path"], "Chart", None]] &&
  AssociationQ[Lookup[record["Path"], "FrozenCoordinate", None]] &&
  AssociationQ[Lookup[record["Path"], "ArtifactIdentity", None]] &&
  ListQ[Lookup[record["Path"], "BranchRoots", None]] &&
  pathTransportExceptionExtensionQ[Lookup[record, "PathExtension",
    <|"Type" -> "None"|>]];
pathTransportExceptionRecordQ[___] := False;

(* Every record of a plan must live on the SAME contract identity:
   family, hard sector, chart, frozen coordinates, and branch
   convention.  A mixed plan is refused before any assembly. *)
pathTransportExceptionPlanIssues[plan_] := Module[{issues = {}, contract,
    records, extension},
  If[! AssociationQ[plan], Return[{"PlanNotAssociation"}]];
  contract = Lookup[plan, "PathContract", None];
  If[StringQ[contract] && FileExistsQ[contract],
    contract = Quiet[Check[Get[contract], $Failed]]];
  If[! pathTransportExceptionContractQ[contract],
    AppendTo[issues, "InvalidPathContract"]];
  If[! MatchQ[Lookup[plan, "Endpoints", None], {_, _}],
    AppendTo[issues, "InvalidEndpoints"]];
  records = Lookup[plan, "Records", None];
  If[! MatchQ[records, {__Association}],
    AppendTo[issues, "NoRecords"],
    Do[
      If[! pathTransportExceptionRecordQ[record],
        AppendTo[issues, "InvalidRecord"],
        If[pathTransportExceptionContractQ[contract],
          If[Lookup[record, "Family", None] =!= contract["Family"] ||
              Lookup[record, "HardSector", None] =!= contract["HardSector"],
            AppendTo[issues, "RecordContractIdentityMismatch"]];
          If[record["Path"]["Chart"] =!= Lookup[contract, "Chart", None] ||
              record["Path"]["FrozenCoordinate"] =!=
                Lookup[contract, "FrozenCoordinates", None],
            AppendTo[issues, "RecordContractPathMismatch"]];
          extension = Lookup[record, "PathExtension", <|"Type" -> "None"|>];
          If[extension["Type"] === "Quadratic" &&
              Lookup[extension, "BranchConvention", None] =!=
                Lookup[Lookup[contract, "PathExtension", <||>],
                  "BranchConvention", None],
            AppendTo[issues, "RecordContractBranchMismatch"]]]],
      {record, records}]];
  DeleteDuplicates[issues]];

pathTransportExceptionPlanQ[plan_] :=
  pathTransportExceptionPlanIssues[plan] === {};

(* ONE pullback for everything on the contract path (Codex note 20 A1).
   Mathematical order, applied identically to the ordinary connection
   and to path artifacts:

     1. source-root branch rules, while the catalog roots are still in
        their exact source Sqrt spelling;
     2. source variables -> the curve functions x(z), y(z);
     3. the residual extension root -> its explicit selected-sheet path
        representative Sqrt[rootSquare(z)];
     4. z -> z0 + tau (z1 - z0), so the z inside BRANCH expressions is
        reparameterized too;

   and the single endpoint Jacobian dz/dtau = (z1 - z0) enters once, at
   the caller.  No Together and no global simplification: Together
   rationalizes square-root denominators (CLAUDE.md trap) and the
   residual root must survive. *)
pathTransportExceptionPullback[expr_, contract_, endpoints : {z0_, z1_},
    tau_Symbol] := Module[{z, vars, path, extension, rootSub},
  z = contract["PathVariable"];
  vars = contract["Variables"];
  path = contract["SourcePath"];
  extension = Lookup[contract, "PathExtension", <|"Type" -> "None"|>];
  rootSub = If[AssociationQ[extension] &&
      extension["Type"] === "Quadratic" &&
      ! MissingQ[Lookup[extension, "Root", Missing[]]],
    {extension["Root"] -> Sqrt[extension["RootSquare"]]}, {}];
  (expr /. contract["SourceRootRules"] /.
      Thread[vars -> Lookup[path, vars]] /. rootSub) /.
    z -> z0 + tau (z1 - z0)];

(* The COMPLETE connection on the contract path.  A_z is built in z
   (curve derivatives x'(z), y'(z)), then reparameterized; the single
   Jacobian (z1 - z0) multiplies once.  PRECONDITION: contract already
   validated at the Prepare boundary. *)
pathTransportExceptionConnection[apv_, apw_, contract_,
    endpoints : {z0_, z1_}, tau_Symbol] := Module[
  {z, vars, path, ztau, az},
  z = contract["PathVariable"];
  vars = contract["Variables"];
  path = contract["SourcePath"];
  ztau = z0 + tau (z1 - z0);
  az = Map[pathTransportExceptionPullback[#, contract, endpoints, tau] &,
        apv, {2}] (D[path[vars[[1]]], z] /. z -> ztau) +
       Map[pathTransportExceptionPullback[#, contract, endpoints, tau] &,
        apw, {2}] (D[path[vars[[2]]], z] /. z -> ztau);
  <|"Status" -> "PathTransportExceptionConnectionV1",
    "Ahat" -> (z1 - z0) az, "PathRule" -> z -> ztau,
    "Extension" -> Replace[Lookup[contract, "PathExtension",
        <|"Type" -> "None"|>],
      ext_Association /; ext["Type"] === "Quadratic" :>
        Join[ext, <|"RootSquareOnPath" ->
          (ext["RootSquare"] /. z -> ztau)|>]]|>];
pathTransportExceptionConnection[___] :=
  <|"Status" -> "InvalidPathConnectionInput"|>;

pathTransportExceptionArtifact[record_] := Module[
  {artifact, artifactIdentity, extension},
  If[! pathTransportExceptionRecordQ[record],
    Return[<|"Status" -> "InvalidPathTransportExceptionRecord"|>]];
  If[! FileExistsQ[record["ArtifactFile"]],
    Return[<|"Status" -> "PathArtifactMissing",
      "File" -> record["ArtifactFile"]|>]];
  artifact = Quiet[Check[Get[record["ArtifactFile"]], $Failed]];
  If[! AssociationQ[artifact],
    Return[<|"Status" -> "PathArtifactUnreadable",
      "File" -> record["ArtifactFile"]|>]];
  artifactIdentity = record["Path"]["ArtifactIdentity"];
  extension = Lookup[record, "PathExtension", <|"Type" -> "None"|>];
  If[Lookup[artifact, "Status", None] =!= record["ArtifactStatus"] ||
      Lookup[artifact, "Family", None] =!= record["Family"] ||
      Lookup[artifact, "HardSector", None] =!= record["HardSector"] ||
      Lookup[artifact, "LowerSector", None] =!= record["LowerSector"] ||
      ! AllTrue[Normal[artifactIdentity],
        Lookup[artifact, First[#], Missing["NoIdentityField"]] ===
          Last[#] &] ||
      Dimensions[Lookup[artifact, "PathForcing", None]] =!=
        record["PathDimensions"],
    Return[<|"Status" -> "PathArtifactContractMismatch",
      "File" -> record["ArtifactFile"]|>]];
  artifact];
pathTransportExceptionArtifact[___] :=
  <|"Status" -> "InvalidPathTransportExceptionRecord"|>;

(* (z1 - z0) Jacobian exactly once; the extension root becomes the
   explicit Sqrt of its path square so ordinary D supplies the branch
   derivative rootSquare'/(2 root) with no extra rewrite rule. *)
pathTransportExceptionReparameterize[record_, tau_Symbol, eps_,
    endpoints : {z0_, z1_}] := Module[
  {artifact, z, artifactEps, forcing, rules, extension, extensionRules,
   extensionOut, rootSquareOnPath},
  artifact = pathTransportExceptionArtifact[record];
  If[Lookup[artifact, "Status", None] =!= record["ArtifactStatus"],
    Return[artifact]];
  z = artifact["PathVariable"];
  artifactEps = artifact["Regulator"];
  forcing = artifact["PathForcing"];
  rules = {z -> z0 + tau (z1 - z0), artifactEps -> eps};
  extension = Lookup[record, "PathExtension", <|"Type" -> "None"|>];
  {extensionRules, extensionOut} = Switch[extension["Type"],
    "None", {{}, <|"Type" -> "None"|>},
    "Quadratic",
      Module[{root, rootSquare},
        (* field-indirection schema first (the accepted records), then
           the direct contract schema, then the legacy artifact keys *)
        Which[
          StringQ[Lookup[extension, "ArtifactRootField", None]],
            root = Lookup[artifact, extension["ArtifactRootField"],
              Missing["NoRootField"]];
            rootSquare = Lookup[artifact,
              extension["ArtifactRootSquareField"],
              Missing["NoRootSquareField"]],
          ! MissingQ[Lookup[extension, "Root", Missing[]]],
            root = extension["Root"];
            rootSquare = extension["RootSquare"],
          True,
            root = Lookup[artifact, "PathExtensionRoot", Missing[]];
            rootSquare = Lookup[artifact, "PathExtensionRootSquare",
              Missing[]]];
        If[MissingQ[root] || MissingQ[rootSquare],
          Return[<|"Status" -> "PathExtensionRootUnresolved",
            "Record" -> record["ArtifactFile"]|>]];
        rootSquareOnPath = rootSquare /. rules;
        {{root -> Sqrt[rootSquareOnPath]},
         <|"Type" -> "Quadratic", "RootSquare" -> rootSquareOnPath,
           "BranchConvention" -> extension["BranchConvention"]|>}]];
  <|"Status" -> "PathTransportExceptionReparameterizedV1",
    "PathBlock" ->
      Map[(z1 - z0) (# /. rules /. extensionRules) &, forcing, {2}],
    "PathRule" -> z -> z0 + tau (z1 - z0),
    "Endpoints" -> endpoints,
    "PathExtension" -> extensionOut|>];
pathTransportExceptionReparameterize[___] :=
  <|"Status" -> "InvalidPathReparameterizationInput"|>;

pathTransportExceptionLocateBlock[assembly_Association, range_List,
    basis_List] := Module[{ranges, blocks, byRange, byBasis},
  ranges = Lookup[assembly, "Ranges", {}];
  blocks = Lookup[assembly, "Blocks", {}];
  byRange = FirstPosition[ranges, range, Missing["RangeNotFound"]];
  byBasis = FirstPosition[blocks, basis, Missing["BasisNotFound"]];
  If[MissingQ[byRange] || MissingQ[byBasis] || byRange =!= byBasis,
    Missing["AssemblyBlockIdentityMismatch"], First[byRange]]];

(* Declared regulator valuation is DESCRIPTIVE metadata (Codex note 20
   A4): the installed mathematics is the sole depth input, read by the
   existing budget from the installed connection.  The observed value
   is reported beside the declaration; a mismatch is diagnostic, never
   a refusal and never a second budget input. *)
pathTransportExceptionValuationCheck[record_, block_, eps_] := Module[
  {observed, declared},
  observed = Min[Append[
    masterTransportEpsOrder[#, eps] & /@ Flatten[block], Infinity]];
  declared = Lookup[record, "RegulatorValuation", None];
  <|"Observed" -> observed, "Declared" -> declared,
    "Consistent" -> (declared === None || declared === observed)|>];

(* PRECONDITION: plan already validated and contract-resolved at the
   Prepare boundary (single validation pass, Codex note 20 A4). *)
pathTransportExceptionInstall[assembly_Association, ahat_List, plan_,
    tau_Symbol, eps_] := Module[
  {endpoints, records, ranges, installed, reports, failed},
  endpoints = plan["Endpoints"];
  records = plan["Records"];
  ranges = Lookup[assembly, "Ranges", {}];
  If[Dimensions[ahat] =!= {Total[Length /@ ranges],
      Total[Length /@ ranges]},
    Return[<|"Status" -> "PathConnectionDimensionMismatch"|>]];
  installed = ahat; reports = {}; failed = None;
  Do[
    Module[{rowBlock, columnBlock, path, block, valuation},
      rowBlock = pathTransportExceptionLocateBlock[assembly,
        record["RowRange"], record["RowBlockBasis"]];
      columnBlock = pathTransportExceptionLocateBlock[assembly,
        record["ColumnRange"], record["ColumnBlockBasis"]];
      If[MissingQ[rowBlock] || MissingQ[columnBlock],
        failed = <|"Status" -> "PathAssemblyBlockIdentityMismatch",
          "Record" -> record["ArtifactFile"]|>; Break[]];
      path = pathTransportExceptionReparameterize[record, tau, eps,
        endpoints];
      If[path["Status"] =!= "PathTransportExceptionReparameterizedV1",
        failed = path; Break[]];
      block = path["PathBlock"];
      valuation = pathTransportExceptionValuationCheck[record, block, eps];
      installed[[ranges[[rowBlock]], ranges[[columnBlock]]]] = block;
      AppendTo[reports, <|"Record" -> record["ArtifactFile"],
        "Positions" -> {rowBlock, columnBlock},
        "Valuation" -> valuation,
        "PathExtension" -> path["PathExtension"]|>]],
    {record, records}];
  If[failed =!= None, Return[failed]];
  <|"Status" -> "PathTransportExceptionInstalledV1",
    "Ahat" -> installed, "Reports" -> reports|>];
pathTransportExceptionInstall[___] :=
  <|"Status" -> "InvalidPathInstallationInput"|>;

(* Capability of ONE installed entry for the ordinary blockwise engine
   (Codex note 20 A2).  The engine's algebraic letters are roots of
   rational tau-quadratic DENOMINATORS -- constants during the word
   integration.  A coefficient moving on an algebraic cover, any
   Sqrt[q(tau)] or half-integer power of a tau-dependent base, is a
   different object and is NOT supported regardless of the radicand's
   degree: it routes to the quadrature branch.  Tau-free algebraic
   coefficients are allowed; after that the blockwise linearizer is the
   single authority on the rational denominator and its named refusal
   is preserved verbatim. *)
pathTransportExceptionEntryCapability[entry_, tau_Symbol, eps_] := Module[
  {covers, den, linearized},
  covers = DeleteDuplicates[Cases[entry,
    Power[b_, e_] /; ! IntegerQ[e] && ! FreeQ[b, tau] :> b,
    {0, Infinity}]];
  If[covers =!= {},
    Return[<|"Admitted" -> False,
      "Reason" -> "TauDependentAlgebraicCover",
      "CoverBases" -> covers|>]];
  den = Denominator[Together[entry]];
  linearized = Catch[masterTransportBWLinearize[den, tau, eps],
    $masterTransportBlockwiseFailure];
  If[AssociationQ[linearized] &&
      ! MissingQ[Lookup[linearized, "Status", Missing[]]],
    Return[<|"Admitted" -> False,
      "Reason" -> linearized["Status"],
      "Detail" -> linearized|>]];
  <|"Admitted" -> True|>];

(* Preflight over the EXCEPTIONAL blocks only (Codex note 20 A3): this
   is ExceptionalBlocksCapability, not a guarantee for the complete
   connection -- on a nonlinear path an ordinary block can also carry
   an unsupported denominator, and the blockwise engine's own named
   refusal at solve time is the authority for the whole object. *)
pathTransportExceptionCapability[installed_Association, assembly_,
    tau_Symbol, eps_] := Module[{ranges, verdicts},
  ranges = Lookup[assembly, "Ranges", {}];
  verdicts = Flatten[Map[
    Function[report, Module[{block},
      block = installed["Ahat"][[
        ranges[[report["Positions"][[1]]]],
        ranges[[report["Positions"][[2]]]]]];
      Map[pathTransportExceptionEntryCapability[#, tau, eps] &,
        Flatten[block]]]],
    installed["Reports"]]];
  Module[{refused = Select[verdicts, ! TrueQ[#["Admitted"]] &]},
    If[refused === {},
      <|"Route" -> "Blockwise"|>,
      <|"Route" -> "AlgebraicQuadratureRequired",
        "Refusals" -> DeleteDuplicates[
          Lookup[refused, "Reason"]],
        "Detail" -> First[refused]|>]]];

(* Orchestration and the single validation boundary.  PRECONDITIONS
   AND CLAIMS: the caller owns the plan's path; the returned ahat is on
   that path and must never be mixed with an axis-path connection.  The
   route field is ExceptionalBlocksRoute -- a preflight over the
   installed exceptional blocks only; the blockwise engine's own named
   refusal remains the authority for the complete connection at solve
   time.  On "AlgebraicQuadratureRequired" the caller takes the
   formal-quadrature consumer; nothing here claims the integral
   evaluated. *)
pathTransportExceptionPrepare[assembly_Association, apv_, apw_, plan0_,
    tau_Symbol, eps_, kmax_Integer] := Module[
  {plan = plan0, issues, contract, connection, installed, budget,
   capability},
  issues = pathTransportExceptionPlanIssues[plan];
  If[issues =!= {},
    Return[<|"Status" -> "PathTransportExceptionPlanRefused",
      "Issues" -> issues|>]];
  contract = Lookup[plan, "PathContract", None];
  If[StringQ[contract], contract = Get[contract]];
  plan["PathContract"] = contract;
  connection = pathTransportExceptionConnection[apv, apw, contract,
    plan["Endpoints"], tau];
  If[connection["Status"] =!= "PathTransportExceptionConnectionV1",
    Return[connection]];
  installed = pathTransportExceptionInstall[assembly,
    connection["Ahat"], plan, tau, eps];
  If[installed["Status"] =!= "PathTransportExceptionInstalledV1",
    Return[installed]];
  budget = masterTransportDepthBudget[assembly, installed["Ahat"],
    kmax, eps];
  capability = pathTransportExceptionCapability[installed, assembly,
    tau, eps];
  <|"Status" -> "PathTransportExceptionPreparedV1",
    "ExceptionalBlocksRoute" -> capability["Route"],
    "ExceptionalBlocksCapability" -> capability,
    "Ahat" -> installed["Ahat"],
    "Budget" -> budget,
    "Reports" -> installed["Reports"],
    "Extension" -> connection["Extension"]|>];
pathTransportExceptionPrepare[___] :=
  <|"Status" -> "InvalidPathPrepareInput"|>;
