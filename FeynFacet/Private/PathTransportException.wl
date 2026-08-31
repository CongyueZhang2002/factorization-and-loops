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
  pathTransportExceptionEntryCapability,
  pathTransportExceptionSourceOrderTable, pathTransportExceptionPrepare];

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
    tau_Symbol] := Module[{z, vars, path, extension, branchRules,
    rootSub},
  z = contract["PathVariable"];
  vars = contract["Variables"];
  path = contract["SourcePath"];
  extension = Lookup[contract, "PathExtension", <|"Type" -> "None"|>];
  (* EVERY half-integer power of a declared root square takes its
     branch: the source entries spell radicals as Sqrt[P] and as
     Power[P, -1/2] (and in principle P^(3/2)); a rules list covering
     only the Sqrt spelling leaves inverse roots behind as a second,
     independent sign ambiguity on the path -- found by the Wave-E
     real-contract probe. *)
  branchRules = Flatten[MapThread[
    Function[{square, branch},
      With[{sq = square, br = branch},
        Power[sq, e_Rational] :> br^(2 e)]],
    {contract["SourceRootSquares"], contract["SourceRootBranches"]}]];
  rootSub = If[AssociationQ[extension] &&
      extension["Type"] === "Quadratic" &&
      ! MissingQ[Lookup[extension, "Root", Missing[]]],
    {extension["Root"] -> Sqrt[extension["RootSquare"]]}, {}];
  (expr /. branchRules /.
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

(* Block-pair regulator-order table from the SOURCE connection pair,
   BEFORE the nonlinear path substitution (Codex note 07): the path
   map and its Jacobian are regulator-free, so
   Min[order(apv_ij), order(apw_ij)] bounds the pulled-back entry's
   order from below -- a cancellation on the path can only raise the
   true order, so this table may over-demand coefficients but can
   never under-budget.

   The per-entry order is taken by EXACT-RATIONAL EVALUATION at two
   independent fixed-seed points of every non-regulator symbol -- the
   project's standard cheap-guard class (user decision 2026-08-22) --
   because a symbolic Together per source entry is itself the cost
   this table exists to avoid (a first implementation with the full
   symbolic scan exceeded 10 minutes on the real CF303 state; the
   post-pullback rescan it replaces was 2512.7 s of a 2625.5 s
   Prepare).  A specialization can only RAISE the observed order, on
   the measure-zero locus where a leading coefficient vanishes at the
   point; two independent points are min'd against that, a vanishing
   denominator at a point yields Infinity for that point and defers
   to the other, and an unlucky overestimate is caught fail-closed
   downstream (masterTransportLaurentList refuses a valuation below
   its window).  Edges in skipEdges are not scanned at all -- the
   caller overwrites them (installed exception blocks replaced their
   source couplings, which for the hard row are also the largest
   source entries). *)
pathTransportExceptionSourceOrderTable[assembly_, apv_, apw_, eps_,
    variables : {__Symbol}, skipEdges_List : {}] := Module[
  {nb, ranges, blockOrder},
  nb = Length[assembly["Blocks"]];
  ranges = assembly["Ranges"];
  blockOrder[i_, j_] := Module[{entries, symbols, orders},
    entries = DeleteCases[Join[
      Flatten[apv[[ranges[[i]], ranges[[j]]]]],
      Flatten[apw[[ranges[[i]], ranges[[j]]]]]], 0];
    If[entries === {}, Return[Infinity]];
    (* ONLY the declared kinematic variables are specialized (Codex
       note 10): a formal root/coefficient symbol given an independent
       integer would destroy its defining algebraic relation and could
       alter a regulator valuation.  And a formal generator left
       OPAQUE is NOT sound either (Codex note 11): with r^2 = Delta,
       1/(r^2 - Delta + eps) has true order -1 while the opaque
       generic order is 0 -- a relation cancelling a leading
       DENOMINATOR coefficient makes opacity UNDER-budget.  Explicit
       radicals of the variables specialize consistently and are
       fine; any remaining formal symbol beyond the declared
       variables refuses by name, and the radical/grade evaluator is
       the production route for such frames. *)
    symbols = DeleteDuplicates[Cases[entries,
      s_Symbol, {0, Infinity}, Heads -> False]];
    Module[{generators = Complement[symbols,
        variables, {eps}]},
      If[generators =!= {},
        Throw[<|"Status" -> "AlgebraicOrderTableNeedsGradeEvaluator",
          "Edge" -> {i, j}, "Generators" -> generators|>,
          pathTransportExceptionSourceOrderTable]]];
    symbols = Intersection[symbols, variables];
    orders = Table[
      Module[{rules, specialized},
        (* SMALL INTEGER points, not fractions: a rational p/q raised
           to the entries' polynomial degrees grows as q^degree and
           the exact arithmetic dominated the whole Prepare (measured
           2026-08-31: the fraction version tracked the 40-minute
           symbolic scan it was built to replace).  Small integers
           keep every power below ~100 digits; radicals of integers
           stay opaque atoms under Together; the residual risk of
           hitting a leading-coefficient zero is the same two-point,
           fail-closed-downstream guard as before. *)
        rules = Thread[symbols ->
          Table[Prime[7 + 5 point + 3 k], {k, Length[symbols]}]];
        specialized = Quiet[entries /. rules];
        (* a denominator vanishing AT THE POINT makes that entry's
           order unusable for this point only; defer to the other *)
        Min[If[FreeQ[#, ComplexInfinity | Indeterminate |
              DirectedInfinity[___]],
            Quiet[masterTransportEpsOrder[#, eps]], Infinity] & /@
          specialized]],
      {point, 2}];
    Min[orders]];
  Catch[
    Table[
      If[i > j && ! MemberQ[skipEdges, {i, j}],
        blockOrder[i, j],
        Infinity],
      {i, nb}, {j, nb}],
    pathTransportExceptionSourceOrderTable]];

(* Orchestration and the single validation boundary.  PRECONDITIONS
   AND CLAIMS: the caller owns the plan's path; the returned ahat is on
   that path and must never be mixed with an axis-path connection.  The
   route field is ExceptionalBlocksRoute -- a preflight over the
   installed exceptional blocks only; the blockwise engine's own named
   refusal remains the authority for the complete connection at solve
   time.  On "AlgebraicQuadratureRequired" the caller takes the
   formal-quadrature consumer; nothing here claims the integral
   evaluated. *)
Options[pathTransportExceptionPrepare] = {
  (* the block-pair regulator-order table; Automatic runs the cheap
     two-point source scan (reference/development -- measured NOT
     seconds-scale on the live CF303 state, 2026-08-31).  A caller
     with a faster authority -- the native modular point/radical
     evaluator across the provider seam -- supplies the matrix here.
     Exception edges are ALWAYS overwritten with installed valuations
     regardless of the source. *)
  "OrderTable" -> Automatic};

pathTransportExceptionPrepare[assembly_Association, apv_, apw_, plan0_,
    tau_Symbol, eps_, kmax_Integer, OptionsPattern[]] := Module[
  {plan = plan0, issues, contract, connection, installed, budget,
   capability, tConnection, tInstall, tBudget, tCapability},
  issues = pathTransportExceptionPlanIssues[plan];
  If[issues =!= {},
    Return[<|"Status" -> "PathTransportExceptionPlanRefused",
      "Issues" -> issues|>]];
  contract = Lookup[plan, "PathContract", None];
  If[StringQ[contract], contract = Get[contract]];
  plan["PathContract"] = contract;
  {tConnection, connection} = AbsoluteTiming[
    pathTransportExceptionConnection[apv, apw, contract,
      plan["Endpoints"], tau]];
  If[connection["Status"] =!= "PathTransportExceptionConnectionV1",
    Return[connection]];
  {tInstall, installed} = AbsoluteTiming[
    pathTransportExceptionInstall[assembly,
      connection["Ahat"], plan, tau, eps]];
  If[installed["Status"] =!= "PathTransportExceptionInstalledV1",
    Return[installed]];
  {tBudget, budget} = AbsoluteTiming[Module[{orderTable, supplied},
    supplied = OptionValue["OrderTable"];
    orderTable = If[ListQ[supplied], supplied,
      pathTransportExceptionSourceOrderTable[assembly,
        apv, apw, eps, contract["Variables"],
        #["Positions"] & /@ installed["Reports"]]];
    (* an accepted record REPLACED its whole block: the source
       coupling no longer exists at that edge, so the table entry is
       OVERWRITTEN -- not combined -- with the installed forcing's
       observed valuation (Codex note 07 item 2); nothing rescans the
       installed block *)
    If[AssociationQ[orderTable],
      (* typed refusal from the table builder (unresolved algebraic
         generators, Codex note 11) -- propagated as Prepare's result *)
      orderTable,
      Do[
        orderTable[[report["Positions"][[1]],
          report["Positions"][[2]]]] =
          report["Valuation"]["Observed"],
        {report, installed["Reports"]}];
      Append[masterTransportDepthBudgetFromTable[assembly, orderTable,
          kmax],
        "OrderTableRoute" -> If[ListQ[supplied], "CallerSupplied",
          "SourcePairPropagated"]]]]];
  (* fail closed on ANY typed budget refusal (grade-evaluator need,
     InvalidOrderTable from a malformed caller table, ...) -- nothing
     with a Status key proceeds to PreparedV1 (Codex note 14) *)
  If[Lookup[budget, "Status", None] =!= None,
    Return[budget]];
  {tCapability, capability} = AbsoluteTiming[
    pathTransportExceptionCapability[installed, assembly,
      tau, eps]];
  <|"Status" -> "PathTransportExceptionPreparedV1",
    "ExceptionalBlocksRoute" -> capability["Route"],
    "ExceptionalBlocksCapability" -> capability,
    "Ahat" -> installed["Ahat"],
    "Budget" -> budget,
    "Reports" -> installed["Reports"],
    "Extension" -> connection["Extension"],
    "PhaseSeconds" -> <|"Connection" -> tConnection,
      "Install" -> tInstall, "Budget" -> tBudget,
      "Capability" -> tCapability|>|>];
pathTransportExceptionPrepare[___] :=
  <|"Status" -> "InvalidPathPrepareInput"|>;

(* ==================================================================
   Wave B: the terminal-block formal quadrature consumer (Codex note
   20).  Additive correction around the ordinary solve:

     delta I_h' = A_hh delta I_h + Sum_j B_hj I_ord,j,
     delta I_h(0) = 0
     =>  delta I_h = U_h(tau) Int_0^tau U_h^-1 Sum_j B_hj I_ord,j,

   returned ORDER BY ORDER in the regulator with the integral held in
   the package-owned inert TransportQuadrature head.  The homogeneous
   propagator U_h arrives as a caller-supplied epsilon series from the
   existing diagonal word machinery; its inverse is built by series
   CONVOLUTION (V U = 1), never a symbolic matrix inverse; nothing is
   passed through Together, so a structured algebraic kernel
   (B0 + r B1) survives untouched.  The result claims
   OKFormalPathQuadrature: the differential representation is
   certified, the integral is NOT claimed evaluated. *)

ClearAll[pathTransportExceptionSeriesOrders,
  pathTransportExceptionSeriesInverse,
  pathTransportExceptionTerminalQ,
  pathTransportExceptionQuadrature];

(* epsilon-Laurent coefficients n_min..n_max of a matrix/vector whose
   entries are rational in eps (algebraic in tau allowed) *)
pathTransportExceptionSeriesOrders[m_, eps_, nmin_Integer, nmax_Integer] :=
  (* level {2}: the ENTRIES of the matrix, never the expression leaves
     -- a leaf-level map rebuilds each rational entry from per-leaf
     series coefficients and produces indeterminate garbage at every
     nonzero order *)
  Association @@ Table[
    n -> Map[SeriesCoefficient[#, {eps, 0, n}] &, m, {2}],
    {n, nmin, nmax}];

(* V with V U = 1 by convolution; requires U^(0) = Id (a dlog-form
   propagator starts at the identity; anything else is refused rather
   than inverted symbolically) *)
pathTransportExceptionSeriesInverse[u_Association, nmax_Integer] := Module[
  {dim, v},
  If[! MatchQ[Lookup[u, 0, None], _List] ||
      Lookup[u, 0] =!= IdentityMatrix[Length[Lookup[u, 0]]],
    Return[<|"Status" -> "PropagatorLeadingOrderNotIdentity"|>]];
  dim = Length[u[0]];
  v = <|0 -> IdentityMatrix[dim]|>;
  Do[
    v[n] = -Sum[v[n - k] . Lookup[u, k, ConstantArray[0, {dim, dim}]],
      {k, 1, n}],
    {n, 1, nmax}];
  v];

(* the hard block is terminal iff no OTHER block's equation reads it:
   every block of ahat in the hard block's columns, outside the hard
   row, must be identically zero *)
pathTransportExceptionTerminalQ[ahat_, assembly_, hard_Integer] := Module[
  {ranges = assembly["Ranges"]},
  AllTrue[Delete[Range[Length[ranges]], hard],
    Function[i, MatchQ[Union[Flatten[
      ahat[[ranges[[i]], ranges[[hard]]]]]], {} | {0}]]]];

Options[pathTransportExceptionQuadrature] = {
  (* Analytic-continuation DATUM: the exact value of the residual root
     at the basepoint tau = 0, recorded for the LATER evaluator that
     continues the selected sheet.  Passing it does not numerically
     select a branch here -- the formal kernel keeps the explicit root
     relation -- but a quadratic extension without this datum cannot be
     evaluated downstream, so its absence refuses (Codex note 27 B4). *)
  "SheetValue" -> None};

pathTransportExceptionQuadrature[prepared_Association,
    assembly_Association, hard_Integer, uSeries_Association,
    iOrd_Association, tau_Symbol, eps_, orders : {__Integer},
    OptionsPattern[]] := Module[
  {ranges, ahat, extension, sheet, nmax, ah, bRows, lowerBlocks, bmin,
   aMin, lowerMin, lowerMaxNeeded, requiredInverseOrder, aOrders,
   bOrders, iOrders, vSeries, premisesChecked, uvResidual, homResidual,
   kernelMin, kernel, quadrature, delta, certificate, dim,
   integrationVar, iOrdHard, zeroMat, contiguousQ, refusal = None},
  ranges = assembly["Ranges"];
  ahat = prepared["Ahat"];
  extension = Lookup[prepared, "Extension", <|"Type" -> "None"|>];
  sheet = OptionValue["SheetValue"];
  If[AssociationQ[extension] && extension["Type"] === "Quadratic" &&
      sheet === None,
    Return[<|"Status" -> "SheetDatumRequired",
      "BranchConvention" -> Lookup[extension, "BranchConvention"]|>]];
  If[! pathTransportExceptionTerminalQ[ahat, assembly, hard],
    Return[<|"Status" -> "NestedQuadratureRequired", "Hard" -> hard|>]];
  dim = Length[ranges[[hard]]];
  zeroMat = ConstantArray[0, {dim, dim}];
  nmax = Max[orders];
  ah = ahat[[ranges[[hard]], ranges[[hard]]]];
  lowerBlocks = Select[Range[Length[ranges]],
    # =!= hard && ! MatchQ[Union[Flatten[
      ahat[[ranges[[hard]], ranges[[#]]]]]], {} | {0}] &];
  bRows = ahat[[ranges[[hard]],
    Flatten[ranges[[#]] & /@ lowerBlocks]]];
  bmin = Min[Append[Flatten[Map[
    masterTransportEpsOrder[#, eps] &, bRows, {2}]], 0]];
  aMin = Min[Append[Flatten[Map[
    masterTransportEpsOrder[#, eps] &, ah, {2}]], 0]];
  lowerMaxNeeded = nmax - bmin;
  contiguousQ[keys_] := keys === Range[Min[keys], Max[keys]];

  (* B1/B2: each lower solution declares a CONTIGUOUS Laurent interval;
     below its own minimum the series is genuinely zero (that is what a
     declared lowest order asserts), above its maximum it is UNCOMPUTED
     and must refuse -- an absent order never silently means zero. *)
  Do[
    Module[{lower = Lookup[iOrd, j, None], keys},
      Which[
        ! AssociationQ[lower],
          refusal = <|"Status" -> "InsufficientLowerOrders",
            "MissingBlock" -> j,
            "NeedLowerThrough" -> lowerMaxNeeded,
            "ForcingMinimumOrder" -> bmin|>,
        (* an EMPTY association declares no interval at all; refuse
           before any Min/Max touches its key list (note 29 item 5) *)
        Length[lower] === 0,
          refusal = <|"Status" -> "InsufficientLowerOrders",
            "Block" -> j, "AvailableThrough" -> None,
            "NeedLowerThrough" -> lowerMaxNeeded,
            "ForcingMinimumOrder" -> bmin|>,
        keys = Sort[Keys[lower]]; ! contiguousQ[keys],
          refusal = <|"Status" -> "LowerOrdersNotContiguous",
            "Block" -> j, "Keys" -> keys|>,
        Max[keys] < lowerMaxNeeded,
          refusal = <|"Status" -> "InsufficientLowerOrders",
            "Block" -> j, "AvailableThrough" -> Max[keys],
            "NeedLowerThrough" -> lowerMaxNeeded,
            "ForcingMinimumOrder" -> bmin|>]],
    {j, lowerBlocks}];
  (* the refusal check sits at FUNCTION level: a Return inside the
     per-block Module above would return from that inner Module and be
     silently discarded -- the trap this file already documents *)
  If[refusal =!= None, Return[refusal, Module]];
  lowerMin = Min[Min[Keys[iOrd[#]]] & /@ lowerBlocks];
  requiredInverseOrder = nmax - bmin - lowerMin;

  (* B2: the propagator is mathematically a NONNEGATIVE series with
     U^(0) = Id, so its keys must be exactly 0 .. max -- a negative key
     would be silently ignored by the convolution bounds -- and max
     must cover the full inverse range (note 29 item 5); explicit zero
     matrices are values, absence is not *)
  If[Length[uSeries] === 0 ||
      Sort[Keys[uSeries]] =!= Range[0, Max[Keys[uSeries]]] ||
      Max[Keys[uSeries]] < requiredInverseOrder,
    Return[<|"Status" -> "InsufficientPropagatorOrders",
      "RequiredThrough" -> requiredInverseOrder,
      "Available" -> Sort[Keys[uSeries]]|>]];

  aOrders = pathTransportExceptionSeriesOrders[ah, eps, aMin,
    requiredInverseOrder];
  bOrders = pathTransportExceptionSeriesOrders[bRows, eps, bmin,
    nmax - lowerMin];
  iOrders = Association @@ Table[
    n -> Join @@ Table[Lookup[iOrd[j], n,
      ConstantArray[0, Length[ranges[[j]]]]], {j, lowerBlocks}],
    {n, lowerMin, lowerMaxNeeded}];
  vSeries = pathTransportExceptionSeriesInverse[uSeries,
    requiredInverseOrder];
  If[AssociationQ[vSeries] && KeyExistsQ[vSeries, "Status"],
    Return[vSeries]];

  (* B3: the exact per-order premise residuals (dU/dtau = A U and
     U V = 1 via Together) run in Development only.  Production
     consumes the upstream accepted homogeneous-propagator record; its
     acceptance boundary is the fresh modular path-point comparison of
     the Wave-E seam, not repeated symbolic simplification here. *)
  premisesChecked = masterTransportCheckLevel[] =!= "Production";
  If[premisesChecked,
    uvResidual = AllTrue[Flatten[Table[
      Sum[uSeries[k] . Lookup[vSeries, n - k, zeroMat], {k, 0, n}] -
        If[n === 0, IdentityMatrix[dim], zeroMat],
      {n, 0, requiredInverseOrder}]], TrueQ[Together[#] === 0] &];
    homResidual = AllTrue[Flatten[Table[
      Map[D[#, tau] &, uSeries[n], {2}] -
        Sum[Lookup[aOrders, n - k, zeroMat] . uSeries[k], {k, 0, n}],
      {n, 0, requiredInverseOrder}]], TrueQ[Together[#] === 0] &];
    If[! TrueQ[homResidual],
      Return[<|"Status" -> "HomogeneousSeriesResidualNonzero"|>]];
    If[! TrueQ[uvResidual],
      Return[<|"Status" -> "PropagatorInverseResidualNonzero"|>]],
    uvResidual = "DeferredToUpstreamAcceptance";
    homResidual = "DeferredToUpstreamAcceptance"];

  (* kernel orders K^(n) = [V B I]^(n): the convolution runs over the
     ACTUAL declared key ranges, a + b + c = n with c allowed negative;
     no bound assumes the lower series starts at eps^0 (note 27 B1).
     The kernel's true lowest order is kernelMin = bmin + lowerMin (V
     starts at order zero), and the kernel and its quadrature are built
     from kernelMin REGARDLESS of which output orders the caller
     requested: higher coefficients of U . Quadrature reach down to the
     lowest quadrature orders through the propagator convolution, so a
     suffix-only request built from Min[orders] would silently omit
     those contributions (note 29 item 2). *)
  kernelMin = bmin + lowerMin;
  kernel = Association @@ Table[
    n -> Sum[
      With[{c = n - a - b},
        If[KeyExistsQ[iOrders, c],
          Lookup[vSeries, a, zeroMat] .
            (Lookup[bOrders, b, ConstantArray[0, Dimensions[bRows]]] .
             iOrders[c]),
          ConstantArray[0, dim]]],
      {a, 0, requiredInverseOrder}, {b, bmin, nmax - lowerMin}],
    {n, kernelMin, nmax}];
  integrationVar = Unique["pathTransportQuadratureVar"];
  quadrature = Association @@ Table[
    n -> Table[
      With[{f = Function @@ {integrationVar,
          kernel[n][[i]] /. tau -> integrationVar}},
        If[! FreeQ[f[[2]], tau],
          Return[<|"Status" ->
            "IntegrandStillDependsOnPathParameter"|>, Module]];
        TransportQuadrature[f, tau, 0]],
      {i, dim}],
    {n, kernelMin, nmax}];
  (* returned keys stay restricted to the caller's requested interval;
     below kernelMin the correction is genuinely zero *)
  delta = Association @@ Table[
    n -> If[n < kernelMin, ConstantArray[0, dim],
      Sum[uSeries[a] . quadrature[n - a],
        {a, 0, Min[n - kernelMin, requiredInverseOrder]}]],
    {n, Min[orders], nmax}];
  iOrdHard = Lookup[iOrd, hard, None];
  certificate = <|
    "Statement" -> "delta I_h = U_h Int_0^tau U_h^-1 Sum_j B_hj \
I_ord,j, order by order in the regulator; differentiating the \
representation returns the inhomogeneous equation because (1) the \
inert head differentiates to its integrand, (2) dU/dtau = A U per \
order, (3) U V = 1 per order; the regrouping uses no property of \
I_ord, so the representation is correct for every inhomogeneity.",
    "CheckLevel" -> masterTransportCheckLevel[],
    "HomogeneousSeriesResidualZero" -> homResidual,
    "PropagatorInverseResidualZero" -> uvResidual,
    "Evaluated" -> False|>;
  <|"Status" -> "OKFormalPathQuadrature",
    "Hard" -> hard, "Orders" -> orders,
    "ForcingMinimumOrder" -> bmin,
    "LowerMinimumOrder" -> lowerMin,
    "KernelMinimumOrder" -> kernelMin,
    "LowerOrdersUsed" -> lowerMaxNeeded,
    "LowerBlocks" -> lowerBlocks,
    "Kernel" -> kernel,
    "DeltaI" -> delta,
    "IHard" -> If[AssociationQ[iOrdHard],
      Association @@ Table[n -> Lookup[iOrdHard, n,
          ConstantArray[0, dim]] + Lookup[delta, n,
          ConstantArray[0, dim]],
        {n, Min[orders], nmax}], None],
    "SheetDatum" -> sheet,
    "Certificate" -> certificate,
    "Claim" -> "A formal path quadrature with per-order checked \
premises in Development and upstream-accepted premises in Production. \
No closed form, function class, or value of the integral is claimed; \
SheetDatum is the analytic-continuation record for a later \
evaluator."|>];
pathTransportExceptionQuadrature[___] :=
  <|"Status" -> "InvalidPathQuadratureInput"|>;

(* ==================================================================
   Wave E: the generic entry point for transport on a typed path plan
   (Codex note 20, integration items 1-2).  One call owns the full
   seam order:

     1. validate the plan and assemble the COMPLETE connection on the
        contract path (one pullback, one endpoint Jacobian);
     2. install the accepted providers -- the record list is VARIABLE
        LENGTH, all records sharing one hard-row identity;
     3. compute one depth budget from the installed mathematics;
     4. dispatch by the measured exceptional-blocks capability:
        - "BlockwiseEngine": every installed entry is admitted; the
          caller feeds the returned Ahat/Budget to
          masterTransportBlockwiseSolve and owns the remaining depth
          arithmetic (kminPerBlock, kmaxF, n0) exactly as in the
          ordinary route -- it is NOT duplicated here, and the
          engine's own named refusal at solve time stays the authority
          for the complete connection;
        - "AlgebraicQuadratureRequired": the terminal hard block takes
          the formal quadrature consumer.  With "PropagatorSeries" and
          "LowerOrders" supplied the quadrature runs in the same call;
          otherwise the dispatch names exactly what is missing.

   Seam order (caller contract, Codex note 24): the ordinary row gauge
   is applied BEFORE the path forcing is formed -- the accepted
   records already carry accepted-gauge forcings (Gauge ->
   LiteralZero), so nothing here re-gauges.  No family names appear;
   the hard block is located from the records' shared row identity. *)

ClearAll[pathTransportExceptionTransport];
Options[pathTransportExceptionTransport] = {
  "PropagatorSeries" -> None,
  "LowerOrders" -> None,
  "Orders" -> None,
  "SheetValue" -> None,
  (* passed through to Prepare (see its option text) *)
  "OrderTable" -> Automatic};

pathTransportExceptionTransport[assembly_Association, apv_, apw_,
    plan_, tau_Symbol, eps_, kmax_Integer, opts : OptionsPattern[]] :=
  Module[{prepared, records, rowIds, hard, u, iOrd, orders, missing,
    quadrature},
  prepared = pathTransportExceptionPrepare[assembly, apv, apw, plan,
    tau, eps, kmax, "OrderTable" -> OptionValue["OrderTable"]];
  If[prepared["Status"] =!= "PathTransportExceptionPreparedV1",
    Return[prepared]];
  records = plan["Records"];
  rowIds = DeleteDuplicates[
    {Lookup[#, "RowRange"], Lookup[#, "RowBlockBasis"]} & /@ records];
  If[Length[rowIds] =!= 1,
    Return[<|"Status" -> "MultipleHardRowsUnsupported",
      "RowIdentities" -> rowIds|>]];
  hard = pathTransportExceptionLocateBlock[assembly,
    rowIds[[1, 1]], rowIds[[1, 2]]];
  If[MissingQ[hard],
    Return[<|"Status" -> "PathAssemblyBlockIdentityMismatch"|>]];
  If[prepared["ExceptionalBlocksRoute"] === "Blockwise",
    Return[Join[prepared, <|"Dispatch" -> "BlockwiseEngine",
      "HardBlock" -> hard|>]]];
  u = OptionValue["PropagatorSeries"];
  iOrd = OptionValue["LowerOrders"];
  orders = OptionValue["Orders"];
  missing = Pick[{"PropagatorSeries", "LowerOrders", "Orders"},
    {! AssociationQ[u], ! AssociationQ[iOrd],
     ! MatchQ[orders, {__Integer}]}];
  If[missing =!= {},
    Return[Join[prepared, <|"Dispatch" -> "AwaitingTerminalData",
      "HardBlock" -> hard, "Missing" -> missing|>]]];
  quadrature = pathTransportExceptionQuadrature[prepared, assembly,
    hard, u, iOrd, tau, eps, orders,
    "SheetValue" -> OptionValue["SheetValue"]];
  Join[prepared, <|"HardBlock" -> hard,
    "Dispatch" -> If[Lookup[quadrature, "Status", None] ===
        "OKFormalPathQuadrature",
      "FormalQuadrature", "FormalQuadratureRefused"],
    "Quadrature" -> quadrature|>]];
pathTransportExceptionTransport[___] :=
  <|"Status" -> "InvalidPathTransportInput"|>;

(* ==================================================================
   Ordinary lower solutions on the path as FORMAL variation of
   constants over the block DAG (Codex note 07): word admissibility is
   not a completeness requirement on a nonlinear path, so instead of
   forcing higher-degree denominators or algebraic covers into the
   quadratic-word engine, every ordinary block is represented as

     I_i = U_i (C_i + Integral[ U_i^-1 Sum_j B_ij I_j ]),

   order by order in the regulator, recursively up the DAG:

   - U_i is the block's OWN formal propagator tower: the diagonal must
     be strictly regulator-linear (A_ii = eps M_i, the pulled-back
     dlog form; anything else refuses by name), U^(0) = Id and
     U^(n) = Integral[M_i U^(n-1)] held as the inert
     TransportQuadrature atom -- no closed form, no word claim;
   - the kernels keep their rational/algebraic path integrands as
     provider-backed formal quadrature atoms: nothing is factored,
     nothing passes through Together;
   - C_i are per-order symbolic constant vectors (the boundary data a
     later evaluator fixes);
   - truncation windows come from the propagated depth budget (the
     forward lowest recursion of masterTransportBWSchedule on the
     prepared order table);
   - each (block, order) is computed once and memoized in the result.

   The claim is the same as the terminal consumer's: a certified
   differential REPRESENTATION (dU/dtau = eps M U holds identically
   through the inert head's derivative rule, U V = 1 by convolution
   construction, and the regrouping uses no property of the
   inhomogeneity); no value, function class, or word form is claimed,
   and production acceptance remains the fresh modular path-point
   comparison. *)

ClearAll[pathTransportExceptionFormalLower,
  pathTransportExceptionFormalRender,
  pathTransportExceptionFormalRelease,
  pathTransportFormalConstant, pathTransportFormalLowerNode,
  pathTransportExceptionFormalMemoized,
  $pathTransportExceptionFormalGraphs,
  $pathTransportExceptionFormalMemo];

(* LAZY REPRESENTATION (Codex note 10; supersedes the eager assembly
   of the first revision, whose nested quadrature trees would have
   been the next symbolic-memory pathology at production block
   counts).  The builder VALIDATES and records recurrence data only:
   windows, feeders, kernel floors, the small diagonal M_i, and
   per-edge coefficient-provider handles.  IOrders holds inert
   indexed nodes pathTransportFormalLowerNode[gid, block, order];
   nothing embeds an expanded matrix or nested quadrature tree, so
   the object grows with the number of requested (block, order, edge)
   nodes.  pathTransportExceptionFormalRender resolves a node into
   the explicit formal expression on demand, memoized bottom-up; a
   modular path-point evaluator plugs into the SAME graph through the
   "OrderExtraction" handles (the native-backend seam). *)

$pathTransportExceptionFormalGraphs = <||>;
$pathTransportExceptionFormalMemo = <||>;

(* compute stays HELD until first use; the assignment evaluates it
   once and stores the value *)
pathTransportExceptionFormalMemoized[key_, compute_] := Module[{held},
  held = Lookup[$pathTransportExceptionFormalMemo, Key[key],
    Missing["NotMemoized"]];
  If[! MissingQ[held], held,
    $pathTransportExceptionFormalMemo[key] = compute]];
SetAttributes[pathTransportExceptionFormalMemoized, HoldRest];

Options[pathTransportExceptionFormalLower] = {
  (* blocks to solve; Automatic = every block except ExcludeBlocks
     (the Wave E caller excludes the terminal hard block, which the
     quadrature consumer owns) *)
  "Blocks" -> Automatic,
  "ExcludeBlocks" -> {},
  (* head for the symbolic per-order constant vectors:
     head[block, order, component] *)
  "ConstantHead" -> pathTransportFormalConstant,
  (* per-edge coefficient providers: Automatic builds, per edge, a
     handle h[order] extracting ONE regulator order of the coupling
     block on demand (the renderer memoizes each requested order); a
     native backend supplies its own handles through this option as
     <|{i, j} -> handle|> without changing the mathematics.
     BOUNDARY (Codex note 11): Automatic closes over the explicit
     Ahat edge slices, so the aggregate graph can retain most of the
     materialized connection -- it is the REFERENCE/DEVELOPMENT
     provider, not the production memory route. *)
  "OrderExtraction" -> Automatic,
  (* the diagonal order-one connections M_i; Automatic derives each
     from the small diagonal block by differentiation, with the exact
     residual identity as a DEVELOPMENT diagnostic only -- production
     consumes the upstream-accepted diagonal eps-form data (Codex
     note 10 item 4).  An explicit association <|i -> M_i|> bypasses
     the derivation entirely. *)
  "DiagonalOrderOne" -> Automatic,
  (* The independent boundary constants of block i begin at
     n0 + ord(TInverse_i), not at the lowest order induced by incoming
     negative-epsilon couplings.  Production supplies both windows from the
     accepted diagonal transformations. *)
  "KMinPerBlock" -> Automatic,
  "ConstantTopPerBlock" -> Automatic};

pathTransportExceptionFormalLower[prepared_Association,
    assembly_Association, tau_Symbol, eps_, OptionsPattern[]] := Module[
  {ahat, ranges, nb, rmin, need, schedule, low, top, kmin, constantTop,
   selected, exclude, constant, extraction, diagonalOption, gid, blocks = <||>,
   iOrders = <||>, refusal = None},
  If[Lookup[prepared, "Status", None] =!=
      "PathTransportExceptionPreparedV1",
    Return[<|"Status" -> "InvalidPreparedInput"|>]];
  ahat = prepared["Ahat"];
  ranges = assembly["Ranges"];
  nb = Length[assembly["Blocks"]];
  rmin = prepared["Budget"]["RMin"];
  need = prepared["Budget"]["Need"];
  kmin = Replace[OptionValue["KMinPerBlock"],
    Automatic :> ConstantArray[0, nb]];
  constantTop = Replace[OptionValue["ConstantTopPerBlock"],
    Automatic :> need];
  If[! MatchQ[kmin, {___Integer}] || Length[kmin] =!= nb ||
      ! MatchQ[constantTop, {___Integer}] || Length[constantTop] =!= nb ||
      ! And @@ Thread[constantTop >= kmin],
    Return[<|"Status" -> "InvalidFormalConstantWindows",
      "KMinPerBlock" -> kmin,
      "ConstantTopPerBlock" -> constantTop|>]];
  schedule = masterTransportBWSchedule[rmin, kmin, need];
  low = schedule["Low"];
  top = schedule["Top"];
  exclude = OptionValue["ExcludeBlocks"];
  selected = Sort[Replace[OptionValue["Blocks"],
    Automatic :> Complement[Range[nb], exclude]]];
  constant = OptionValue["ConstantHead"];
  extraction = OptionValue["OrderExtraction"];
  diagonalOption = OptionValue["DiagonalOrderOne"];
  gid = Unique["pathTransportFormalGraph"];
  Do[
    Module[{i = block, feeders, dim, diag, m, kernelMin,
      requiredInverseOrder, handles},
      feeders = Select[Range[i - 1], rmin[[i, #]] =!= Infinity &];
      (* FIRST refusal wins: later blocks necessarily also refuse
         (their feeders are missing) and must not overwrite the
         root cause *)
      If[refusal === None && ! SubsetQ[Keys[blocks], feeders],
        refusal = <|"Status" -> "MissingFeederSolution", "Block" -> i,
          "Missing" -> Complement[feeders, Keys[blocks]]|>];
      If[refusal === None,
        dim = Length[ranges[[i]]];
        m = If[AssociationQ[diagonalOption],
          Lookup[diagonalOption, i, Missing["NoDiagonalData"]],
          Automatic];
        If[m === Automatic,
          diag = ahat[[ranges[[i]], ranges[[i]]]];
          m = Map[D[#, eps] &, diag, {2}];
          Which[
            ! FreeQ[m, eps],
              refusal = <|"Status" -> "DiagonalNotEpsilonLinear",
                "Block" -> i,
                "Reason" -> "RegulatorSurvivesDerivative"|>,
            masterTransportCheckLevel[] =!= "Production" &&
              Together[diag - eps m] =!=
                ConstantArray[0, {dim, dim}],
              refusal = <|"Status" -> "DiagonalNotEpsilonLinear",
                "Block" -> i,
                "Reason" -> "ResidualAfterLinearPart"|>]];
        If[refusal === None && MissingQ[m],
          refusal = <|"Status" -> "DiagonalDataMissing",
            "Block" -> i|>]];
      If[refusal === None,
        kernelMin = If[feeders === {}, 0,
          Min[Table[rmin[[i, j]] + low[[j]], {j, feeders}]]];
        requiredInverseOrder = Max[0, top[[i]] - kernelMin,
          top[[i]] - kmin[[i]]];
        handles = Association @@ Table[
          j -> Which[
            AssociationQ[extraction] &&
              KeyExistsQ[extraction, {i, j}],
              extraction[{i, j}],
            extraction === Automatic,
              (* lazy default: ONE order of the edge block per call;
                 the edge slice is shared structure, not a copy *)
              With[{edge = ahat[[ranges[[i]], ranges[[j]]]],
                  regulator = eps},
                Function[order, Map[
                  SeriesCoefficient[#, {regulator, 0, order}] &,
                  edge, {2}]]],
            True,
              refusal = <|"Status" -> "MissingEdgeProvider",
                "Edge" -> {i, j}|>; None],
          {j, feeders}];
        If[refusal === None,
          blocks[i] = <|"Dimension" -> dim, "Feeders" -> feeders,
            "M" -> m, "KernelMin" -> kernelMin,
            "RequiredInverseOrder" -> requiredInverseOrder,
            "EdgeHandles" -> handles|>;
          iOrders[i] = Association @@ Table[
            n -> pathTransportFormalLowerNode[gid, i, n],
            {n, low[[i]], top[[i]]}]]]],
    {block, selected}];
  If[refusal =!= None, Return[refusal, Module]];
  $pathTransportExceptionFormalGraphs[gid] = <|
    "Blocks" -> blocks, "Selected" -> selected,
    "Low" -> low, "Top" -> top, "RMin" -> rmin,
    "KMin" -> kmin, "ConstantTop" -> constantTop,
    "Tau" -> tau, "Regulator" -> eps,
    "ConstantHead" -> constant|>;
  <|"Status" -> "OKFormalLowerGraph",
    "GraphID" -> gid,
    "Blocks" -> selected,
    "Windows" -> <|"Low" -> low, "Top" -> top|>,
    "ConstantWindows" -> <|"Low" -> kmin,
      "Top" -> constantTop|>,
    "IOrders" -> iOrders,
    "ConstantHead" -> constant,
    "Certificate" -> <|
      "Statement" -> "Each block satisfies I_i = U_i (C_i + \
Int_0^tau U_i^-1 Sum_j B_ij I_j) order by order: dU/dtau = eps M U \
holds identically through the inert integral's derivative rule, \
U V = 1 by convolution construction, and the regrouping uses no \
property of the inhomogeneity.  No value, function class, or word \
form is claimed; production acceptance is the fresh modular \
path-point comparison.",
      "Representation" -> "IndexedNodes",
      "CheckLevel" -> masterTransportCheckLevel[],
      "Evaluated" -> False|>|>];
pathTransportExceptionFormalLower[___] :=
  <|"Status" -> "InvalidFormalLowerInput"|>;

(* On-demand resolution of a node into the explicit formal expression
   (the first revision's eager semantics, now memoized bottom-up per
   graph).  U, V, per-order edge coefficients, kernels, quadratures
   and lower solutions are each computed once per (graph, index).
   BOUNDARY (Codex note 11): rendering deliberately recreates a full
   nested formal expression -- a DEVELOPMENT/REFERENCE resolution for
   tests and single-node inspection.  Production transport evaluates
   the indexed graph bottom-up through native handles at a path point
   and never renders a whole family. *)
pathTransportExceptionFormalRender[graph_Association,
    pathTransportFormalLowerNode[gid_, i_Integer, n_Integer]] :=
  pathTransportExceptionFormalRender[graph, i, n];
pathTransportExceptionFormalRender[graph_Association, i_Integer,
    n_Integer] := Module[
  {gid, data, renderU, renderV, renderB, renderKernel, renderQ,
   renderI, memo = pathTransportExceptionFormalMemoized},
  gid = Lookup[graph, "GraphID", None];
  data = Lookup[$pathTransportExceptionFormalGraphs, Key[gid],
    Missing["GraphReleased"]];
  If[MissingQ[data],
    Return[<|"Status" -> "FormalGraphNotRegistered", "GraphID" -> gid|>]];
  If[TrueQ[Lookup[data, "ProviderOnly", False]],
    Return[<|"Status" -> "ProviderBackedGraphCannotRender",
      "GraphID" -> gid|>]];
  With[{tau = data["Tau"], low = data["Low"], top = data["Top"],
      kmin = data["KMin"], constantTop = data["ConstantTop"],
      rmin = data["RMin"], constant = data["ConstantHead"],
      blocksData = data["Blocks"]},
    renderU[b_, a_] := memo[{gid, "U", b, a}, Module[{bd, var},
      bd = blocksData[b];
      If[a === 0, IdentityMatrix[bd["Dimension"]],
        var = Unique["pathTransportPropagatorVar"];
        Table[
          With[{f = Function @@ {var,
              (bd["M"] . renderU[b, a - 1])[[r, c]] /. tau -> var}},
            TransportQuadrature[f, tau, 0]],
          {r, bd["Dimension"]}, {c, bd["Dimension"]}]]]];
    renderV[b_, a_] := memo[{gid, "V", b, a}, Module[{bd},
      bd = blocksData[b];
      If[a === 0, IdentityMatrix[bd["Dimension"]],
        -Sum[renderV[b, a - k] . renderU[b, k], {k, 1, a}]]]];
    renderB[b_, j_, order_] := memo[{gid, "B", b, j, order},
      blocksData[b]["EdgeHandles"][j][order]];
    renderKernel[b_, order_] := memo[{gid, "K", b, order},
      Module[{bd = blocksData[b]},
        Sum[
          renderV[b, a] .
          Sum[
            With[{c = order - a - beta},
              If[low[[j]] <= c <= top[[j]],
                renderB[b, j, beta] .
                  pathTransportExceptionFormalRender[graph, j, c],
                ConstantArray[0, bd["Dimension"]]]],
            {j, bd["Feeders"]},
            {beta, rmin[[b, j]], top[[b]] - low[[j]]}],
          {a, 0, bd["RequiredInverseOrder"]}]]];
    renderQ[b_, order_] := memo[{gid, "Q", b, order},
      Module[{bd = blocksData[b], var},
        var = Unique["pathTransportLowerVar"];
        Table[
          With[{f = Function @@ {var,
              renderKernel[b, order][[r]] /. tau -> var}},
            TransportQuadrature[f, tau, 0]],
          {r, bd["Dimension"]}]]];
    renderI[b_, order_] := memo[{gid, "I", b, order},
      Module[{bd = blocksData[b]},
        Sum[
          renderU[b, a] . (
            If[kmin[[b]] <= order - a <= constantTop[[b]],
              Table[constant[b, order - a, c], {c, bd["Dimension"]}],
              ConstantArray[0, bd["Dimension"]]] +
            If[bd["Feeders"] =!= {} && order - a >= bd["KernelMin"],
              renderQ[b, order - a],
              ConstantArray[0, bd["Dimension"]]]),
          {a, 0, Min[order - Min[kmin[[b]], bd["KernelMin"]],
            bd["RequiredInverseOrder"]]}]]];
    If[! KeyExistsQ[blocksData, i],
      Return[<|"Status" -> "BlockNotInFormalGraph", "Block" -> i|>]];
    renderI[i, n]]];
pathTransportExceptionFormalRender[___] :=
  <|"Status" -> "InvalidFormalRenderInput"|>;

(* drop a graph's registry entry and every memoized rendering *)
pathTransportExceptionFormalRelease[graph_Association] := Module[{gid},
  gid = Lookup[graph, "GraphID", None];
  $pathTransportExceptionFormalGraphs =
    KeyDrop[$pathTransportExceptionFormalGraphs, gid];
  $pathTransportExceptionFormalMemo = KeySelect[
    $pathTransportExceptionFormalMemo, First[#] =!= gid &];
  <|"Status" -> "FormalGraphReleased", "GraphID" -> gid|>];
pathTransportExceptionFormalRelease[___] :=
  <|"Status" -> "InvalidFormalReleaseInput"|>;

(* ==================================================================
   Modular path-point evaluation of the formal lower graph (contract:
   Fable note 11 as corrected by Codex note 14).  The result is an
   exact formal JET modulo tau^(T+1) at the path origin in the plain
   monomial basis -- OKModularGraphSeries with SeriesCenter -> 0,
   BasePoint -> 0, TruncationOrder -> T -- never an arbitrary-point
   integral value (finite-field truncation has no convergence
   interpretation).  Production acceptance compares constructed and
   direct differential systems as jets at a fresh prime/sheet.

   The numeric memo is scoped to ONE evaluation call and discarded on
   return, so opposite sheets, different boundary constants, or
   different providers can never collide by construction.  An
   ordinary Taylor basis needs a regular origin: a path denominator
   vanishing at tau = 0 refuses PathOriginSingular, a residual root
   with zero basepoint value refuses PathOriginRamified; the caller
   picks a different admissible path, nothing is coerced. *)

ClearAll[pathTransportExceptionJetOfExpression,
  pathTransportExceptionFormalEvaluate,
  $pathTransportExceptionJetTag];

(* ---- scalar jet algebra mod p: a jet is the coefficient list
   {c_0, ..., c_T}; helpers Throw typed refusals on the shared tag ---- *)

pathTransportExceptionJetThrow[status_, detail___Rule] :=
  Throw[<|"Status" -> status, detail|>, $pathTransportExceptionJetTag];

pathTransportExceptionJetMul[a_List, b_List, p_Integer] := Module[
  {t = Length[a] - 1},
  Table[Mod[Sum[a[[k + 1]] b[[n - k + 1]], {k, 0, n}], p],
    {n, 0, t}]];

pathTransportExceptionJetInverse[a_List, p_Integer] := Module[
  {t = Length[a] - 1, out, lead},
  If[Mod[First[a], p] === 0,
    pathTransportExceptionJetThrow["PathOriginSingular",
      "Reason" -> "DenominatorVanishesAtOrigin"]];
  lead = PowerMod[First[a], -1, p];
  out = ConstantArray[0, t + 1]; out[[1]] = lead;
  Do[
    out[[n + 1]] = Mod[-lead Sum[a[[k + 1]] out[[n - k + 1]],
      {k, 1, n}], p],
    {n, 1, t}];
  out];

(* sqrt jet on the sheet fixed by the basepoint value s0 (s0^2 = a_0
   mod p); s0 = 0 or a_0 = 0 is a ramified origin *)
pathTransportExceptionJetSqrt[a_List, s0_Integer, p_Integer] := Module[
  {t = Length[a] - 1, out, half},
  If[Mod[First[a], p] === 0 || Mod[s0, p] === 0,
    pathTransportExceptionJetThrow["PathOriginRamified",
      "Reason" -> "RootSquareVanishesAtOrigin"]];
  If[Mod[s0 s0 - First[a], p] =!= 0,
    pathTransportExceptionJetThrow["SheetDatumInconsistent",
      "BasePointSquare" -> Mod[First[a], p]]];
  half = PowerMod[2 s0, -1, p];
  out = ConstantArray[0, t + 1]; out[[1]] = Mod[s0, p];
  Do[
    out[[n + 1]] = Mod[half (a[[n + 1]] -
      Sum[out[[k + 1]] out[[n - k + 1]], {k, 1, n - 1}]), p],
    {n, 1, t}];
  out];

pathTransportExceptionJetIntegrate[a_List, p_Integer] := Module[
  {t = Length[a] - 1},
  Table[
    If[n === 0, 0,
      If[Mod[n, p] === 0,
        pathTransportExceptionJetThrow["TauOrderInsufficient",
          "Reason" -> "IntegrationStepDivisibleByPrime",
          "Step" -> n]];
      Mod[a[[n]] PowerMod[n, -1, p], p]],
    {n, 0, t}]];

(* ---- expression -> scalar jet (the reference/development route for
   diagonals and fallback edge providers; the native EdgeSeries
   handle bypasses this entirely) ---- *)

pathTransportExceptionJetOfExpression[expr_, tau_Symbol, p_Integer,
    t_Integer, sheet_] := Module[{jet},
  jet[e_Integer] := PadRight[{Mod[e, p]}, t + 1];
  jet[e_Rational] := If[Mod[Denominator[e], p] === 0,
    pathTransportExceptionJetThrow["ModularDenominatorClash",
      "Value" -> e],
    PadRight[{Mod[Numerator[e] PowerMod[Denominator[e], -1, p], p]},
      t + 1]];
  jet[e_Symbol] := Which[
    e === tau, PadRight[{0, 1}, t + 1],
    True, pathTransportExceptionJetThrow["UnresolvedSymbolInJet",
      "Symbol" -> e]];
  jet[e_Plus] := Mod[Total[jet /@ List @@ e], p];
  jet[e_Times] := Fold[pathTransportExceptionJetMul[#1, #2, p] &,
    jet[First[e]], jet /@ Rest[List @@ e]];
  jet[Power[b_, n_Integer]] := Which[
    n === 0, PadRight[{1}, t + 1],
    n > 0, Nest[pathTransportExceptionJetMul[#, jet[b], p] &,
      jet[b], n - 1],
    True, Nest[pathTransportExceptionJetMul[#,
        pathTransportExceptionJetInverse[jet[b], p], p] &,
      pathTransportExceptionJetInverse[jet[b], p], -n - 1]];
  jet[Power[b_, q_Rational]] := Module[{s, s0},
    If[Denominator[q] =!= 2,
      pathTransportExceptionJetThrow["UnsupportedRadicalDegree",
        "Exponent" -> q]];
    s0 = Which[
      AssociationQ[sheet], Lookup[sheet, Key[b],
        Missing["NoSheetDatum"]],
      sheet =!= None, sheet[b],
      True, Missing["NoSheetDatum"]];
    If[! IntegerQ[s0],
      pathTransportExceptionJetThrow["SheetDatumRequired",
        "Radicand" -> b]];
    s = pathTransportExceptionJetSqrt[jet[b], s0, p];
    (* integer power of the sqrt jet, negative allowed *)
    Module[{m = Numerator[2 q]},
      Which[
        m > 0, Nest[pathTransportExceptionJetMul[#, s, p] &, s, m - 1],
        m < 0, Module[{inv = pathTransportExceptionJetInverse[s, p]},
          Nest[pathTransportExceptionJetMul[#, inv, p] &, inv,
            -m - 1]],
        True, PadRight[{1}, t + 1]]]];
  jet[e_] := pathTransportExceptionJetThrow["UnsupportedJetHead",
    "Head" -> Head[e]];
  jet[expr]];

(* ---- the graph walk: one call, one memo, discarded on return ---- *)

Options[pathTransportExceptionFormalEvaluate] = {
  "TauOrder" -> 8,
  "Prime" -> None,
  (* per-radicand basepoint root values mod p (association keyed by
     the radicand expression, or a function radicand -> value) *)
  "SheetData" -> None,
  (* constants: a function f[block, order, component] -> value mod p,
     or an association keyed {block, order, component}; a missing
     value refuses ConstantsUnresolved *)
  "ConstantValues" -> None,
  (* THE NATIVE SEAM: h[{i, j}, order, T, p, sheet] -> matrix of jets
     for the edge coefficient block; Automatic falls back to the
     development extraction + jet expansion *)
  "EdgeSeries" -> Automatic,
  (* native diagonal handle h[block, T, p, sheet] -> matrix of jets
     for M_block; Automatic expands the stored small diagonal *)
  "DiagonalSeries" -> Automatic};

(* BATCH form (Codex note 16): every requested node is evaluated in
   ONE local context, so shared U/V/B/kernel dependencies are computed
   once and the cost is linear in the reachable graph size times
   TauOrder.  The terminal consumer requests all windows in one batch.
   A request outside the graph's recorded window refuses
   OrderOutsideGraphWindow -- the graph never claimed that order and
   constants must not be synthesized for it. *)
pathTransportExceptionFormalEvaluate[graph_Association,
    requests : {{_Integer, _Integer} ..}, OptionsPattern[]] := Module[
  {gid, data, p, t, sheet, constants, edgeOption, diagonalOption,
   store, localMemo, evalM, evalU, evalV, evalB, evalKernel, evalQ,
   evalI, constantAt, zeroJet, idJet, matMul,
   validJetMatrixQ, result},
  gid = Lookup[graph, "GraphID", None];
  data = Lookup[$pathTransportExceptionFormalGraphs, Key[gid],
    Missing["GraphReleased"]];
  If[MissingQ[data],
    Return[<|"Status" -> "FormalGraphNotRegistered",
      "GraphID" -> gid|>]];
  p = OptionValue["Prime"];
  t = OptionValue["TauOrder"];
  If[! (IntegerQ[p] && p > 2 && PrimeQ[p] && IntegerQ[t] && t >= 0),
    Return[<|"Status" -> "InvalidModularEvaluationRequest"|>]];
  (* window validation with a FUNCTION-scope refusal variable -- a
     Return inside the per-request scope would be silently discarded
     by Do (the trap this file documents) *)
  result = None;
  Do[
    With[{b = request[[1]], order = request[[2]]},
      Which[
        result =!= None, Null,
        ! KeyExistsQ[data["Blocks"], b],
          result = <|"Status" -> "BlockNotInFormalGraph",
            "Block" -> b|>,
        ! (data["Low"][[b]] <= order <= data["Top"][[b]]),
          result = <|"Status" -> "OrderOutsideGraphWindow",
            "Block" -> b, "Order" -> order,
            "Window" -> {data["Low"][[b]], data["Top"][[b]]}|>]],
    {request, requests}];
  If[result =!= None, Return[result]];
  sheet = OptionValue["SheetData"];
  constants = OptionValue["ConstantValues"];
  edgeOption = OptionValue["EdgeSeries"];
  diagonalOption = OptionValue["DiagonalSeries"];
  (* ONE evaluation context: local store, discarded on return (Codex
     note 14) -- sheets, constants, and providers cannot collide
     across calls by construction *)
  store = <||>;
  (* Lookup evaluates its default EAGERLY, so it cannot memoize a
     recursive computation; localMemo holds the compute argument and
     runs it only on a miss *)
  SetAttributes[localMemo, HoldRest];
  localMemo[key_, compute_] := If[KeyExistsQ[store, key],
    store[key], store[key] = compute];
  zeroJet = ConstantArray[0, t + 1];
  idJet[dim_] := Table[If[r === c, PadRight[{1}, t + 1], zeroJet],
    {r, dim}, {c, dim}];
  matMul[a_, b_] := Table[
    Mod[Total[Table[pathTransportExceptionJetMul[a[[r, k]],
      b[[k, c]], p], {k, Length[b]}]], p],
    {r, Length[a]}, {c, Length[First[b]]}];
  validJetMatrixQ[matrix_, rows_Integer, columns_Integer] :=
    Dimensions[matrix] === {rows, columns, t + 1} &&
      AllTrue[Flatten[matrix], IntegerQ[#1] && 0 <= #1 < p &];
  constantAt[b_, order_, comp_] := Module[{value},
    value = Which[
      AssociationQ[constants], Lookup[constants,
        Key[{b, order, comp}], Missing["NoConstant"]],
      constants =!= None, constants[b, order, comp],
      True, Missing["NoConstant"]];
    If[! IntegerQ[value],
      pathTransportExceptionJetThrow["ConstantsUnresolved",
        "Block" -> b, "Order" -> order, "Component" -> comp]];
    Mod[value, p]];
  With[{tau = data["Tau"], low = data["Low"], top = data["Top"],
      kmin = data["KMin"], constantTop = data["ConstantTop"],
      rmin = data["RMin"], blocksData = data["Blocks"]},
    evalM[b_] := localMemo[{"M", b}, Module[{value, dim},
      dim = blocksData[b]["Dimension"];
      value = If[diagonalOption === Automatic,
        Map[pathTransportExceptionJetOfExpression[#, tau, p, t,
          sheet] &, blocksData[b]["M"], {2}],
        diagonalOption[b, t, p, sheet]];
      If[! validJetMatrixQ[value, dim, dim],
        pathTransportExceptionJetThrow["DiagonalSeriesInvalid",
          "Block" -> b, "ObservedDimensions" -> Dimensions[value]]];
      value]];
    evalU[b_, a_] := localMemo[{"U", b, a}, If[a === 0,
        idJet[blocksData[b]["Dimension"]],
        Map[pathTransportExceptionJetIntegrate[#, p] &,
          matMul[evalM[b], evalU[b, a - 1]], {2}]]];
    evalV[b_, a_] := localMemo[{"V", b, a}, If[a === 0,
        idJet[blocksData[b]["Dimension"]],
        Mod[-Total[Table[matMul[evalV[b, a - k], evalU[b, k]],
          {k, 1, a}]], p]]];
    evalB[b_, j_, order_] := localMemo[{"B", b, j, order},
      Module[{value, rowDimension, columnDimension},
        rowDimension = blocksData[b]["Dimension"];
        columnDimension = blocksData[j]["Dimension"];
        value = If[edgeOption === Automatic,
          Map[pathTransportExceptionJetOfExpression[#, tau, p, t,
              sheet] &,
            blocksData[b]["EdgeHandles"][j][order], {2}],
          edgeOption[{b, j}, order, t, p, sheet]];
        If[! validJetMatrixQ[value, rowDimension, columnDimension],
          pathTransportExceptionJetThrow["EdgeSeriesInvalid",
            "Edge" -> {b, j}, "Order" -> order,
            "ObservedDimensions" -> Dimensions[value]]];
        value]];
    evalKernel[b_, order_] := localMemo[{"K", b, order}, Module[{bd = blocksData[b], acc},
        acc = Table[zeroJet, {bd["Dimension"]}];
        Do[
          Module[{inner = Table[zeroJet, {bd["Dimension"]}]},
            Do[
              With[{c = order - a - beta},
                If[low[[j]] <= c <= top[[j]],
                  inner = Mod[inner + Flatten[
                    matMul[evalB[b, j, beta],
                      Transpose[{evalI[j, c]}]], 1], p]]],
              {j, bd["Feeders"]},
              {beta, rmin[[b, j]], top[[b]] - low[[j]]}];
            acc = Mod[acc + Flatten[
              matMul[evalV[b, a], Transpose[{inner}]], 1], p]],
          {a, 0, bd["RequiredInverseOrder"]}];
        acc]];
    evalQ[b_, order_] := localMemo[{"Q", b, order},
        Map[pathTransportExceptionJetIntegrate[#, p] &,
          evalKernel[b, order]]];
    evalI[b_, order_] := localMemo[{"I", b, order}, Module[{bd = blocksData[b], acc},
        acc = Table[zeroJet, {bd["Dimension"]}];
        Do[
          Module[{vec},
            vec = If[kmin[[b]] <= order - a <= constantTop[[b]],
              Table[PadRight[{constantAt[b, order - a, comp]},
                t + 1], {comp, bd["Dimension"]}],
              Table[zeroJet, {bd["Dimension"]}]];
            If[bd["Feeders"] =!= {} &&
                order - a >= bd["KernelMin"],
              vec = Mod[vec + evalQ[b, order - a], p]];
            acc = Mod[acc + Flatten[
              matMul[evalU[b, a], Transpose[{vec}]], 1], p]],
          {a, 0, Min[order - Min[kmin[[b]], bd["KernelMin"]],
            bd["RequiredInverseOrder"]]}];
        acc]];
    result = None;
    Module[{nodes = <||>},
      Do[
        Module[{value},
          value = Catch[evalI[request[[1]], request[[2]]],
            $pathTransportExceptionJetTag];
          If[AssociationQ[value] && KeyExistsQ[value, "Status"],
            result = Join[value, <|"Block" -> request[[1]],
              "OrderRequested" -> request[[2]]|>],
            nodes[request] = <|"Status" -> "OKModularGraphSeries",
              "Block" -> request[[1]], "Order" -> request[[2]],
              "Series" -> value,
              "SeriesCenter" -> 0, "BasePoint" -> 0,
              "TruncationOrder" -> t, "Prime" -> p|>]];
        If[result =!= None, Break[]],
        {request, requests}];
      If[result === None,
        result = <|"Status" -> "OKModularGraphSeriesBatch",
          "Nodes" -> nodes,
          "SeriesCenter" -> 0, "BasePoint" -> 0,
          "TruncationOrder" -> t, "Prime" -> p,
          "Certificate" -> <|
            "Statement" -> "Exact formal jets modulo tau^(T+1) of \
the graph's variation-of-constants representation at the path \
origin, in the plain monomial basis, on the sheet fixed by the \
supplied basepoint root values; all requested nodes share one \
evaluation context, so every (kind, block, order) dependency is \
computed once.  Not arbitrary-point integral values; production \
acceptance compares constructed and direct systems as jets at a \
fresh prime/sheet.",
            "CheckLevel" -> masterTransportCheckLevel[],
            "Evaluated" -> "OriginJet"|>|>]];
    result]];

(* scalar form: a one-element batch (Codex note 16) *)
pathTransportExceptionFormalEvaluate[graph_Association, i_Integer,
    n_Integer, opts : OptionsPattern[]] := Module[{batch},
  batch = pathTransportExceptionFormalEvaluate[graph, {{i, n}}, opts];
  If[Lookup[batch, "Status", None] =!= "OKModularGraphSeriesBatch",
    batch,
    Join[batch["Nodes"][{i, n}],
      <|"Certificate" -> batch["Certificate"]|>]]];
pathTransportExceptionFormalEvaluate[___] :=
  <|"Status" -> "InvalidModularEvaluationInput"|>;
