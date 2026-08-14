(* Stage 1 (canonicalization) of the master-solving workflow.

   Acceptance criteria:

   A. The package exports the five stage-1 entry points with usage
      messages.
   B. Decomposition: the 7-master NLO UU system decomposes into
      strongly connected blocks whose dimensions sum to 7, and the
      per-family block-lower-triangularity certificate holds with zero
      forward couplings.
   C. Classification: the classes partition the blocks exactly, and
      every stored member map (permutation + optional v<->w swap)
      reproduces that member's connection matrices from the class
      representative entry by entry.  The test recomputes this itself
      rather than trusting the stored "MapVerified" flag.
   D. Canonicalization: every NLO class reaches a stored epsilon-form,
      with no unresolved class.
   E. Certificate: every stored NLO form re-validates through
      ValidateCanonicalForm, which reads the matrices and never the
      stored "Validated" flag.
   F. Failure-tuple gate (the regression that matters).  CANONICA
      reports a failed sector as {False, {partial, partial}}, which is
      shape-identical to a success; an earlier campaign accepted 47 of
      those as solved.  With an injected solver:
        F1 a {False, {T, A}} return must leave the class UNRESOLVED
           and must write no form file;
        F2 a shape-VALID {T, A} return whose A is not an epsilon-form
           must also leave the class UNRESOLVED and write no file --
           this is the part only the reconstruction gate can catch;
        F3 a return whose A really is an epsilon-form must be stored,
           so the gate is not vacuously rejecting everything.
   G. ValidateCanonicalForm accepts a genuine dlog form with constant
      residues, rejects a non-dlog matrix pair, rejects a pair with no
      regulator, and rejects a record whose "Validated" flag claims
      success.
   H. Chart branch: two small single-quadratic classes taken from the
      repository's own NNLO artifacts canonicalize only after the conic
      chart engages, one through each branch of the chart builder
      (direct linear solve, and square completion u = l + 2 t).
   I. The status helper prints one greppable line per stored form and
      reports classes that have no form yet.

   Provenance of the H representatives: class 98 of the 173-class
   quotient is CF259 rows {1,2} (quadratic 4 v + w^2, chart
   v -> (t^2 - w^2)/4, measured 1 s at ansatz degree 0) and class 90 is
   CF248 rows {1,2} (a Kallen variant, square-completion chart,
   measured 3 s).  Both are rebuilt here from the DE artifacts in this
   repository, so the test needs no scratch directory. *)

root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], ".."}]];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

(* Bare symbols are resolved at parse time, and CANONICA` joins
   $ContextPath as soon as the first canonicalization loads it, which
   would make a later bare "eps" ambiguous.  Every symbol used to build
   test matrices is therefore named explicitly. *)
vv = Symbol["Global`v"];
ww = Symbol["Global`w"];
epsG = Symbol["Global`eps"];
epsilonG = Symbol["Global`Epsilon"];

scratch = FileNameJoin[{$TemporaryDirectory,
  "ff_t_canonical_blocks_" <> ToString[$ProcessID]}];
Quiet[CreateDirectory[scratch, CreateIntermediateDirectories -> True]];
deDirectory = FileNameJoin[{scratch, "DifferentialEquations"}];
Quiet[CreateDirectory[deDirectory]];
formDirectory = FileNameJoin[{scratch, "forms"}];

(* --- A ------------------------------------------------------------ *)

(* ToExpression, not MessageName[Symbol[...], "usage"]: MessageName is
   HoldFirst, so it would never evaluate the Symbol and would report a
   missing usage message for every symbol. *)
entryPoints = {"DecomposeFamilyBlocks", "ClassifyBlocks",
  "CanonicalizeClasses", "ValidateCanonicalForm", "CanonicalBlocksStatus"};

(* System`Names, not Names: the loaded FeynCalc/FeynArts session shadows
   the bare symbol, so `Names[...]` stays unevaluated and every lookup
   silently compares an unevaluated expression against a list. *)
symbolReport = Table[
  Module[{qualified = "FeynFacet`" <> name},
    <|
      "Name" -> name,
      "InFeynFacet" -> System`Names[qualified],
      "Anywhere" -> System`Names["*`" <> name],
      "UsageIsString" -> StringQ[Quiet[ToExpression[qualified <> "::usage"]]],
      "Defined" -> (Length[Quiet[DownValues[Evaluate[Symbol[qualified]]]]] > 0)
    |>],
  {name, entryPoints}];

(* Names returns the SHORT name whenever the context is on $ContextPath,
   so a fully-qualified comparison can never match.  Existence is
   "the lookup found something"; that it is the real exported function
   is established by its usage message and its definitions. *)
symbolOK[row_] :=
  row["InFeynFacet"] =!= {} && row["UsageIsString"] && TrueQ[row["Defined"]];

If[! AllTrue[symbolReport, symbolOK],
  Print["A-DIAG: ", #] & /@ Select[symbolReport, ! symbolOK[#] &]];

FTTest`FTAssert["A. stage-1 entry points exported with usage messages",
  AllTrue[symbolReport, symbolOK]];

(* --- B ------------------------------------------------------------ *)

nloArtifact = Get[FileNameJoin[{root, "ppHX_NLO", "Results",
  "NLO_UU_Masters.wl"}]];
nloSystem = nloArtifact["DifferentialSystem"];

Put[<|
  "Family" -> "NLO_UU",
  "BlockBasis" -> nloSystem["Basis"],
  "Av" -> nloSystem["Av"],
  "Aw" -> nloSystem["Aw"]
|>, FileNameJoin[{deDirectory, "nlo_de_NLO_UU.wl"}]];

decomposition = DecomposeFamilyBlocks[deDirectory,
  "FilePattern" -> "nlo_de_*.wl", "Regulator" -> epsilonG];

nloBlocks = decomposition["Blocks"];
nloCertificate = First[decomposition["Certificates"]];

(* The NLO system is triangular: the volume master feeds the other six
   and nothing feeds back.  Its STRONG components are therefore several
   small blocks, while its WEAK components would be a single block of
   dimension 7 -- so the block count, not just the dimension sum,
   is what discriminates a correct decomposition here. *)
FTTest`FTAssert["B. NLO decomposition: 7 rows, dimensions sum to 7, genuinely split",
  decomposition["TotalRows"] === 7 &&
    Total[#["Dim"] & /@ nloBlocks] === 7 &&
    Length[nloBlocks] >= 2];

FTTest`FTAssert["B. block-lower-triangularity certificate, zero forward couplings",
  TrueQ[decomposition["BlockLowerTriangular"]] &&
    nloCertificate["ForwardCouplings"] === 0 &&
    TrueQ[nloCertificate["TopologicalSortComplete"]] &&
    Sort[nloCertificate["RowOrder"]] === Range[7]];

(* Independent re-derivation of the certificate: permute both matrices
   into the certified solving order and check directly that no entry
   couples an earlier block to a later one. *)
blockPosition = Module[{position = ConstantArray[0, 7], components, order},
  components = #["Rows"] & /@ nloBlocks;
  order = nloCertificate["BlockOrder"];
  Do[Scan[(position[[#]] = k) &, components[[order[[k]]]]],
    {k, Length[order]}];
  position];

FTTest`FTAssert["B. triangularity re-derived independently from the row order",
  And @@ Flatten @ Table[
    If[blockPosition[[i]] < blockPosition[[j]],
      nloSystem["Av"][[i, j]] === 0 && nloSystem["Aw"][[i, j]] === 0,
      True],
    {i, 7}, {j, 7}]];

(* --- C ------------------------------------------------------------ *)

classification = ClassifyBlocks[decomposition, "Progress" -> False];
nloClasses = Values[classification["Classes"]];

(* Independent re-derivation of the group action, written out here so
   the check does not reuse the implementation under test. *)
swapVW[expr_] := Module[{a, b},
  expr /. {vv -> a, ww -> b} /. {a -> ww, b -> vv}];

actOn[{av_, aw_}, swapQ_, perm_] := Module[{pair},
  pair = If[TrueQ[swapQ], {swapVW[aw], swapVW[av]}, {av, aw}];
  {pair[[1]][[perm, perm]], pair[[2]][[perm, perm]]}];

blockOf[family_, rows_] := SelectFirst[nloBlocks,
  #["Family"] === family && #["Rows"] === rows &];

mapCheck = AllTrue[nloClasses,
  Function[class,
    AllTrue[class["Members"],
      Function[member,
        Module[{target, image},
          target = blockOf[member["Family"], member["Rows"]];
          image = actOn[{class["RepAv"], class["RepAw"]},
            member["Swap"], member["Permutation"]];
          AssociationQ[target] &&
            Union[Flatten[Together[image[[1]] - target["Av"]]]] === {0} &&
            Union[Flatten[Together[image[[2]] - target["Aw"]]]] === {0}
        ]]]]];

FTTest`FTAssert["C. classes partition the blocks and every member map is exact",
  classification["MembersTotal"] === Length[nloBlocks] &&
    classification["ClassCount"] <= Length[nloBlocks] &&
    Length[DeleteDuplicates[#["ContentAddress"] & /@ nloClasses]] ===
      classification["ClassCount"] &&
    Length[nloClasses] === classification["ClassCount"] &&
    AllTrue[nloClasses, StringQ[#["ContentAddress"]] &] &&
    TrueQ[mapCheck]];

(* Regression for the invariant bug: an earlier bucket key folded in the
   swap by exchanging Av and Aw without relabelling v <-> w inside the
   entries, so swap-equivalent blocks were never compared and every one
   of the 7 NLO blocks became its own class.  Some of these blocks ARE
   equivalent, so a correct quotient is strictly coarser than the block
   set, and the classes must carry the merged members. *)
FTTest`FTAssert["C. the quotient is strictly coarser than the block set",
  classification["ClassCount"] < Length[nloBlocks] &&
    Max[#["Size"] & /@ nloClasses] >= 2 &&
    AllTrue[nloClasses, AllTrue[#["Members"], TrueQ[#["MapVerified"]] &] &]];

(* --- D ------------------------------------------------------------ *)

nloRun = CanonicalizeClasses[classification,
  "OutputDirectory" -> formDirectory,
  "AnsatzDegrees" -> {0, 1},
  "TimeConstraint" -> 180];

FTTest`FTAssert["D. every NLO class canonicalized, none unresolved",
  nloRun["Unresolved"] === 0 &&
    nloRun["Canonicalized"] === classification["ClassCount"] &&
    Length[FileNames["class*.wl", formDirectory]] ===
      classification["ClassCount"]];

(* --- E ------------------------------------------------------------ *)

storedForms = FileNames["class*.wl", formDirectory];

FTTest`FTAssert["E. every stored NLO form re-validates from its matrices",
  storedForms =!= {} &&
    AllTrue[storedForms, TrueQ[ValidateCanonicalForm[#]] &]];

(* --- F ------------------------------------------------------------ *)

(* A one-dimensional system that is deliberately NOT an epsilon-form:
   (-1 - eps)/v is not eps times a constant residue. *)
mockClass = <|
  "ClassID" -> 9001,
  "ContentAddress" -> "mockclass",
  "Dim" -> 1,
  "RepFamily" -> "MOCK",
  "RepRows" -> {1},
  "RepBasis" -> {"mock"},
  "RepAv" -> {{(-1 - epsG)/vv}},
  "RepAw" -> {{(1 + 2 epsG)/ww}},
  "Variables" -> {vv, ww},
  "Regulator" -> epsG
|>;

mockDirectory = FileNameJoin[{scratch, "mockforms"}];
Quiet[CreateDirectory[mockDirectory]];
mockFile = FileNameJoin[{mockDirectory, "class9001.wl"}];

(* F1: the literal CANONICA failure tuple. *)
Quiet[DeleteFile[mockFile]];
failureTupleRun = CanonicalizeClasses[mockClass,
  "OutputDirectory" -> mockDirectory,
  "AnsatzDegrees" -> {0},
  "Chart" -> False,
  "Solver" -> Function[{matrices, variables, degree},
    {False, {IdentityMatrix[Length[matrices[[1]]]], matrices}}]];

FTTest`FTAssert["F1. {False,{...}} failure tuple does not validate and writes no form",
  failureTupleRun["Canonicalized"] === 0 &&
    failureTupleRun["Unresolved"] === 1 &&
    ! FileExistsQ[mockFile]];

(* F2: shape-valid return, matrix is not an epsilon-form.  Only the
   reconstruction gate rejects this one. *)
Quiet[DeleteFile[mockFile]];
shapeValidRun = CanonicalizeClasses[mockClass,
  "OutputDirectory" -> mockDirectory,
  "AnsatzDegrees" -> {0},
  "Chart" -> False,
  "Solver" -> Function[{matrices, variables, degree},
    {IdentityMatrix[Length[matrices[[1]]]], matrices}]];

FTTest`FTAssert["F2. shape-valid non-epsilon-form is rejected by the gate, no form written",
  shapeValidRun["Canonicalized"] === 0 &&
    shapeValidRun["Unresolved"] === 1 &&
    ! FileExistsQ[mockFile]];

(* F3: positive control -- a genuine epsilon-form is accepted, so F1
   and F2 are not passing merely because everything is refused. *)
Quiet[DeleteFile[mockFile]];
genuineRun = CanonicalizeClasses[mockClass,
  "OutputDirectory" -> mockDirectory,
  "AnsatzDegrees" -> {0},
  "Chart" -> False,
  "Solver" -> Function[{matrices, variables, degree},
    Module[{e = Symbol["CANONICA`eps"]},
      {IdentityMatrix[Length[matrices[[1]]]],
        {{{-2 e/(-1 + variables[[1]] + variables[[2]])}},
          {{-2 e/(-1 + variables[[1]] + variables[[2]])}}}}]]];

FTTest`FTAssert["F3. a genuine epsilon-form return is accepted and stored",
  genuineRun["Canonicalized"] === 1 &&
    genuineRun["Unresolved"] === 0 &&
    FileExistsQ[mockFile] &&
    TrueQ[ValidateCanonicalForm[mockFile]]];

(* --- G ------------------------------------------------------------ *)

goodForm = {{{-2 epsG/(-1 + vv + ww)}}, {{-2 epsG/(-1 + vv + ww)}}};
badForm = {{{epsG/(vv^2 + ww)}}, {{epsG/(vv + ww^2)}}};
noRegulatorForm = {{{1/vv}}, {{1/ww}}};

FTTest`FTAssert["G. genuine dlog form with constant residues validates",
  TrueQ[ValidateCanonicalForm[goodForm, {vv, ww}]]];

FTTest`FTAssert["G. non-dlog matrix pair is rejected",
  ! TrueQ[ValidateCanonicalForm[badForm, {vv, ww}]]];

FTTest`FTAssert["G. pair with no regulator is rejected",
  ! TrueQ[Quiet[ValidateCanonicalForm[noRegulatorForm, {vv, ww}]]]];

FTTest`FTAssert["G. a stored Validated->True flag cannot certify a bad form",
  ! TrueQ[ValidateCanonicalForm[<|
    "EpsForm" -> badForm, "Variables" -> {vv, ww}, "Regulator" -> epsG,
    "Validated" -> True|>]]];

FTTest`FTAssert["G. details report exposes letters and constant-residue verdict",
  Module[{details},
    details = ValidateCanonicalForm[goodForm, {vv, ww}, "Details" -> True];
    AssociationQ[details] && TrueQ[details["Valid"]] &&
      TrueQ[details["ConstantResidues"]] && details["Letters"] =!= {}]];

(* --- H ------------------------------------------------------------ *)

chartFiles = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
    "UU_08_10_canonical", "DifferentialEquations", #}] & /@
  {"nnlo_de_CF259.wl", "nnlo_de_CF248.wl"};

chartDecomposition = DecomposeFamilyBlocks[chartFiles,
  "Regulator" -> epsG, "Progress" -> False];

chartTargets = {{"CF259", {1, 2}}, {"CF248", {1, 2}}};
chartBlocks = Select[chartDecomposition["Blocks"],
  MemberQ[chartTargets, {#["Family"], #["Rows"]}] &];

chartClassification = ClassifyBlocks[chartBlocks, "Regulator" -> epsG,
  "Progress" -> False];
chartClasses = Values[chartClassification["Classes"]];

chartDirectory = FileNameJoin[{scratch, "chartforms"}];

FTTest`FTAssert["H. both single-quadratic representatives were located",
  Length[chartBlocks] === 2 && Length[chartClasses] === 2];

chartRun = CanonicalizeClasses[chartClasses,
  "OutputDirectory" -> chartDirectory,
  "AnsatzDegrees" -> {0},
  "TimeConstraint" -> 300,
  "Regulator" -> epsG];

chartRecords = Get /@ FileNames["class*.wl", chartDirectory];

FTTest`FTAssert["H. both classes canonicalize, and only in the chart frame",
  chartRun["Canonicalized"] === 2 &&
    chartRun["Unresolved"] === 0 &&
    Length[chartRecords] === 2 &&
    AllTrue[chartRecords, #["Frame"] === "chart" &] &&
    AllTrue[chartRecords, #["Chart"] =!= None &]];

FTTest`FTAssert["H. both chart-builder branches are exercised",
  Sort[DeleteDuplicates[#["Chart"]["Branch"] & /@ chartRecords]] ===
    {"LinearSolve", "SquareCompletion"}];

FTTest`FTAssert["H. chart-frame forms validate in their chart variables",
  AllTrue[chartRecords, TrueQ[ValidateCanonicalForm[#]] &] &&
    AllTrue[chartRecords, Length[#["Variables"]] === 2 &] &&
    AllTrue[chartRecords, MemberQ[#["Variables"], Symbol["Global`t"]] &]];

(* --- I ------------------------------------------------------------ *)

statusReport = CanonicalBlocksStatus[formDirectory,
  "Classes" -> classification, "Validate" -> True];

statusMissing = CanonicalBlocksStatus[chartDirectory,
  "Classes" -> Append[chartClasses,
    <|"ClassID" -> 9999, "ContentAddress" -> "absent", "Dim" -> 1|>],
  "Print" -> False];

FTTest`FTAssert["I. status helper reports every form and re-validates it",
  statusReport["Done"] === Length[storedForms] &&
    statusReport["Revalidated"] === Length[storedForms] &&
    statusReport["MissingCount"] === 0];

FTTest`FTAssert["I. status helper names the classes that have no form yet",
  statusMissing["MissingCount"] === 1 &&
    MemberQ[statusMissing["Missing"], 9999]];

Quiet[DeleteDirectory[scratch, DeleteContents -> True]];

FTTest`FTReport[];
