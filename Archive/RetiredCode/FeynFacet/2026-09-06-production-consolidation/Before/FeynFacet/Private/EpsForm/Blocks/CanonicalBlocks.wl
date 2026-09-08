(* Stage 1 of the master-solving workflow: canonicalization of the
   coupled blocks of a differential-equation lattice.

   The stage turns a directory of family differential-equation
   artifacts into a set of certified epsilon-forms, one per
   connection-equivalence class of blocks:

     DecomposeFamilyBlocks  -- strongly connected components of the
       per-family dependency graph, with the block-lower-triangularity
       certificate that licenses solving the family block by block;
     ClassifyBlocks         -- the exact quotient of the block set by
       (basis permutation) x (optional v<->w relabelling), emitted as
       content-addressed class records carrying an explicit, exactly
       verified orbit map for every member;
     CanonicalizeClasses    -- the CANONICA campaign over the class
       representatives: an ansatz-degree ladder in the original
       variables, a conic-chart retry for single-quadratic classes,
       and the reconstruction gate below in front of every stored file;
     ValidateCanonicalForm  -- the certificate itself, as a standalone
       check;
     CanonicalBlocksStatus  -- one greppable line per class, for a
       watchdog running in a second kernel.

   Two facts drive the whole design.

   The first is that CANONICA reports a failed sector as
   {False, {partial transformation, partial matrix}}, which is a
   two-element list of a matrix and a matrix -- structurally identical
   to a success.  A campaign that tests the return shape accepts
   failures as successes; ours did, and 47 of a claimed 83 successes
   were failure tuples.  The ONLY accepted certificate is exact
   reconstruction of the stored matrix from constant residues:

     A_eps^(i) == eps * Sum_j R_j * d/dx_i log(letter_j),  R_j constant.

   ValidateCanonicalForm is that check and nothing else; in particular
   it never reads a stored "Validated" flag, so a corrupted or
   hand-edited artifact cannot certify itself.

   The second is that this stage is pure geometry.  Boundary VALUES
   are stage-3 physics input and appear nowhere here: a class is
   canonicalized or it is not, independently of any integral's value.

   Regulator handling: CANONICA works in its own CANONICA`eps.  The
   symbol is protected inside that package, and rewriting our matrices
   into it by ordinary substitution leaks the protected symbol into
   stored artifacts.  Every entry point therefore translates only at
   the CANONICA call boundary, matching on SymbolName so that a
   Global`eps and a Global`Epsilon system are handled alike, and
   translates back before anything is written. *)

ClearAll[
  $canonicalBlocksFailure,
  $canonicalBlocksBreak,
  $canonicalBlocksArtifactFormat,
  $canonicalBlocksArtifactVersion,
  $canonicalBlocksRegulatorNames,
  $canonicalBlocksCanonicaLoaded,
  canonicalBlocksFail,
  canonicalBlocksGetGlobal,
  canonicalBlocksPutAtomic,
  canonicalBlocksDefaultVariables,
  canonicalBlocksDetectRegulator,
  canonicalBlocksResolveRegulator,
  canonicalBlocksResolveVariables,
  canonicalBlocksEntry,
  canonicalBlocksMatrix,
  canonicalBlocksSwap,
  canonicalBlocksSwapPair,
  canonicalBlocksZeroQ,
  canonicalBlocksPairInvariant,
  canonicalBlocksBucketKey,
  canonicalBlocksRowInvariants,
  canonicalBlocksOrbitCandidates,
  canonicalBlocksOrbitKey,
  canonicalBlocksMatchOrbit,
  canonicalBlocksFamilyBlocks,
  canonicalBlocksTriangularityCertificate,
  canonicalBlocksTotalDegree,
  canonicalBlocksQuadraticFactors,
  canonicalBlocksBuildChart,
  canonicalBlocksApplyChart,
  canonicalBlocksClassList,
  canonicalBlocksClassLabel,
  canonicalBlocksHistogram
];

(* Clear, not ClearAll: the public symbols carry the usage messages
   FeynFacet.m installed before this file is read. *)
Clear[
  DecomposeFamilyBlocks,
  ClassifyBlocks,
  CanonicalizeClasses,
  ValidateCanonicalForm,
  CanonicalBlocksStatus
];

DecomposeFamilyBlocks::dir =
  "`1` is not a directory of differential-equation artifacts.";

DecomposeFamilyBlocks::files =
  "No differential-equation file in `1` matches `2`.";

DecomposeFamilyBlocks::artifact =
  "`1` is not a family differential-equation artifact: `2`.";

DecomposeFamilyBlocks::dimensions =
  "Family `1` declares `2` basis elements but connection matrices of \
dimensions `3` and `4`.";

DecomposeFamilyBlocks::regulator =
  "Cannot infer the regulator symbol; supply \"Regulator\" explicitly.";

DecomposeFamilyBlocks::option = "Invalid `1` option: `2`.";

ClassifyBlocks::blocks = "`1` is not a block list or a decomposition record.";

ClassifyBlocks::dimension =
  "Block dimension `1` exceeds \"MaxBlockDimension\" (`2`); orbit \
enumeration over `1`! permutations was refused rather than approximated.";

ClassifyBlocks::option = "Invalid `1` option: `2`.";

CanonicalizeClasses::classes = "`1` is not a class list or a classification record.";

CanonicalizeClasses::directory = "Cannot create output directory `1`.";

CanonicalizeClasses::canonica =
  "CANONICA was not found at `1`; canonicalization needs it.";

CanonicalizeClasses::option = "Invalid `1` option: `2`.";
CanonicalizeClasses::variables = "Class `1` declares no variables and its representative matrices contain the symbols `2`, which are not the documented {v, w} convention; declare \"Variables\" in the class record or pass the option.";

CanonicalizeClasses::chartparameter =
  "The chart parameter `1` is one of the class variables `2`; the conic \
chart needs a new coordinate.";

ValidateCanonicalForm::form =
  "`1` is not a canonical-form record, file or {matrices, variables} pair.";

ValidateCanonicalForm::variables =
  "The record stores `1` variables but an epsilon-form of `2` matrices.";

ValidateCanonicalForm::regulator =
  "Cannot infer the regulator symbol of the epsilon-form; supply \
\"Regulator\" explicitly.";

CanonicalBlocksStatus::directory = "`1` is not a form directory.";

$canonicalBlocksFailure = Unique["canonicalBlocksFailure$"];

(* A separate tag for loop control flow.  Sharing the failure tag
   would let an inner "first success wins" Catch swallow a genuine
   error thrown from deeper in the same call. *)
$canonicalBlocksBreak = Unique["canonicalBlocksBreak$"];

$canonicalBlocksArtifactFormat = "FeynFacet-CanonicalBlocks";
$canonicalBlocksArtifactVersion = 1;

(* Symbols accepted as the dimensional regulator when a system does not
   name it.  Existing artifacts use both eps and Epsilon. *)
$canonicalBlocksRegulatorNames = {"eps", "Eps", "epsilon", "Epsilon", "ep"};

$canonicalBlocksCanonicaLoaded = False;

canonicalBlocksFail[symbol_, message_, args___] := (
  Message[MessageName[symbol, message], args];
  Throw[$Failed, $canonicalBlocksFailure]
);

(* The differential-equation artifacts store unqualified symbols
   (v, w, eps, gli).  Read inside FeynFacet`Private` those would become
   private symbols distinct from the Global` ones every consumer uses,
   so the read happens in a Global` reading context. *)
canonicalBlocksGetGlobal[file_String] :=
  Block[{$Context = "Global`", $ContextPath = {"Global`", "System`"}},
    Get[file]
  ];

(* A kill -9 during Put leaves a truncated artifact that Get later
   accepts as a partial expression; write to a temporary name in the
   same directory and rename, which is atomic on one filesystem. *)
canonicalBlocksPutAtomic[expr_, file_String] := Module[{temp},
  temp = file <> ".partial" <> ToString[$ProcessID];
  Quiet[DeleteFile[temp]];
  Put[expr, temp];
  If[! FileExistsQ[temp], Return[$Failed]];
  RenameFile[temp, file, OverwriteTarget -> True];
  file
];

canonicalBlocksDefaultVariables[] :=
  {Symbol["Global`v"], Symbol["Global`w"]};

(* None = no regulator-named symbol occurs (a regulator-free input is
   valid; the caller decides); $Failed = MORE than one candidate, a real
   ambiguity that must be a typed refusal, never a silent pick
   (generality audit F5, 2026-08-23) *)
canonicalBlocksDetectRegulator[expr_, variables_List] := Module[{symbols},
  symbols = DeleteDuplicates @ Cases[
    expr,
    s_Symbol /; MemberQ[$canonicalBlocksRegulatorNames, SymbolName[s]],
    {0, Infinity},
    Heads -> True
  ];
  symbols = DeleteCases[symbols, Alternatives @@ variables];
  Which[symbols === {}, None,
    Length[symbols] === 1, First[symbols],
    True, $Failed]
];

(* Automatic with an expression is a VERIFIED convention default: the
   {v, w} pair is used only when the expression's symbols (minus
   regulator-named ones) are a subset of {v, w}; any other symbol set is
   a typed refusal, because a silent {v, w} on foreign input is a
   wrong-but-plausible run, and detection of arbitrary pairs cannot fix
   the ORDER of the two variables (generality audit F5, 2026-08-23).
   Automatic without an expression keeps the historical blind default
   for internal fixed-frame callers. *)
canonicalBlocksResolveVariables[value_] :=
  canonicalBlocksResolveVariables[value, None];
canonicalBlocksResolveVariables[value_, expr_] := Switch[value,
  Automatic, If[expr === None, canonicalBlocksDefaultVariables[],
    Module[{found},
      found = DeleteDuplicates @ Cases[expr,
        s_Symbol /; Context[s] === "Global`" &&
          ! MemberQ[$canonicalBlocksRegulatorNames, SymbolName[s]],
        {0, Infinity}, Heads -> True];
      If[SubsetQ[canonicalBlocksDefaultVariables[], found],
        canonicalBlocksDefaultVariables[],
        <|"Status" -> "ClassVariablesUndeclared",
          "FoundSymbols" -> found|>]]],
  {_Symbol, __Symbol}, value,
  _, $Failed
];

canonicalBlocksResolveRegulator[value_, expr_, variables_] := Switch[value,
  Automatic, canonicalBlocksDetectRegulator[expr, variables],
  _Symbol, value,
  _, $Failed
];

(* --- exact rational normal form ----------------------------------- *)

(* Two entries are equal as rational functions exactly when this pair
   agrees: Cancel[Together[]] fixes the reduced representative and the
   division by the leading denominator coefficient fixes the remaining
   scale freedom.  Structural === on unreduced entries is what split
   two of our classes that are in fact equal. *)
canonicalBlocksEntry[0, variables_, regulator_] := {0, 1};

canonicalBlocksEntry[entry_, variables_List, regulator_] :=
  Module[{together, numerator, denominator, rules, lead},
    together = Cancel[Together[entry]];
    numerator = Numerator[together];
    denominator = Denominator[together];
    rules = CoefficientRules[denominator, Append[variables, regulator]];
    lead = If[rules === {}, 1, rules[[1, 2]]];
    {Expand[numerator/lead], Expand[denominator/lead]}
  ];

canonicalBlocksMatrix[matrix_, variables_List, regulator_] :=
  Map[canonicalBlocksEntry[#, variables, regulator] &, matrix, {2}];

(* v <-> w through fresh Module symbols: a two-step replacement through
   named placeholders is the classic source of the self-assignment
   poison (v = Global`v) that cost us an overnight run. *)
canonicalBlocksSwap[expr_, {v_Symbol, w_Symbol}] :=
  Module[{tv, tw}, expr /. {v -> tv, w -> tw} /. {tv -> w, tw -> v}];

(* Relabelling v <-> w exchanges the roles of the two connection
   matrices as well as their arguments: the system dF/dv = Av F,
   dF/dw = Aw F becomes dF/dv = swap[Aw] F, dF/dw = swap[Av] F. *)
canonicalBlocksSwapPair[{av_, aw_}, variables_] :=
  {canonicalBlocksSwap[aw, variables], canonicalBlocksSwap[av, variables]};

canonicalBlocksZeroQ[entry_, "Structural"] := entry === 0;

canonicalBlocksZeroQ[entry_, "Algebraic"] :=
  entry === 0 || TrueQ[Together[entry] === 0];

(* --- the connection-equivalence quotient -------------------------- *)

(* Conjugation by a permutation matrix permutes the entries of each
   connection matrix, so any multiset of entries is an invariant.  The
   swap is folded in by taking the smaller of the two invariants, which
   makes the bucket key invariant under the full group. *)
canonicalBlocksPairInvariant[{av_, aw_}] :=
  {Sort[Flatten[av, 1]], Sort[Flatten[aw, 1]],
    Sort[Diagonal[av]], Sort[Diagonal[aw]]};

(* The swap does NOT merely exchange Av and Aw: it also relabels v <-> w
   inside every entry.  Folding it in by exchanging the two matrices
   alone put swap-equivalent blocks in different buckets, where they
   were never compared and became separate classes.  The swapped
   invariant must therefore be computed from the properly relabelled
   pair, which the caller already has.
   First[Sort[...]], not Min: the entries are lists of rational normal
   forms, and Min would flatten them and compare numerically. *)
canonicalBlocksBucketKey[pair_, swappedPair_] :=
  {Length[First[pair]],
    First[Sort[{canonicalBlocksPairInvariant[pair],
      canonicalBlocksPairInvariant[swappedPair]}]]};

(* Row i of A[[q, q]] is a permutation of row q[[i]] of A, so the row
   invariant travels with the row and prunes the permutation search to
   the compatible assignments. *)
canonicalBlocksRowInvariants[{av_, aw_}] :=
  Table[{Sort[av[[i]]], Sort[aw[[i]]], av[[i, i]], aw[[i, i]]},
    {i, Length[av]}];

canonicalBlocksOrbitCandidates[target_, source_] :=
  Module[{targetRows, sourceRows, dimension, allowed},
    targetRows = canonicalBlocksRowInvariants[target];
    sourceRows = canonicalBlocksRowInvariants[source];
    dimension = Length[targetRows];
    allowed = Table[
      Flatten[Position[sourceRows, targetRows[[i]], {1}, Heads -> False]],
      {i, dimension}];
    If[MemberQ[allowed, {}], Return[{}]];
    Select[Tuples[allowed], DuplicateFreeQ]
  ];

(* The content address of a class: the least element of the orbit of the
   normalized pair.  Full enumeration is exact and the honest thing to
   do; a dimension above the cap is refused rather than approximated,
   because a wrong canonical form silently merges or splits classes and
   poisons every downstream reuse. *)
canonicalBlocksOrbitKey[normalized : {av_, aw_}, normalizedSwapped_, maximum_] :=
  Module[{dimension = Length[av], permutations, candidates},
    If[dimension > maximum,
      canonicalBlocksFail[ClassifyBlocks, "dimension", dimension, maximum]];
    permutations = Permutations[Range[dimension]];
    candidates = Join[
      Table[{normalized[[1]][[q, q]], normalized[[2]][[q, q]]},
        {q, permutations}],
      Table[{normalizedSwapped[[1]][[q, q]], normalizedSwapped[[2]][[q, q]]},
        {q, permutations}]
    ];
    First[Sort[candidates]]
  ];

(* Search for an explicit group element carrying the representative onto
   the member, and return it only when the images agree entry by entry.
   The returned map is therefore a certificate of exact equality, not a
   claim about an invariant. *)
canonicalBlocksMatchOrbit[repNormalized_, repNormalizedSwapped_,
    memberNormalized_] :=
  Module[{result = None},
    Catch[
      Do[
        Module[{source = If[swapQ, repNormalizedSwapped, repNormalized],
            candidates},
          candidates = canonicalBlocksOrbitCandidates[memberNormalized, source];
          Do[
            If[{source[[1]][[q, q]], source[[2]][[q, q]]} === memberNormalized,
              result = <|"Swap" -> swapQ, "Permutation" -> q|>;
              Throw[result, $canonicalBlocksBreak]],
            {q, candidates}]
        ],
        {swapQ, {False, True}}],
      $canonicalBlocksBreak];
    result
  ];

canonicalBlocksHistogram[values_] := SortBy[Tally[values], First];

(* --- stage 1a: block decomposition -------------------------------- *)

canonicalBlocksFamilyBlocks[artifact_, file_, zeroTest_] :=
  Module[{family, basis, dimension, av, aw, edges, graph, components},
    If[! AssociationQ[artifact],
      canonicalBlocksFail[DecomposeFamilyBlocks, "artifact", file,
        "not an Association"]];
    If[! AllTrue[{"Family", "BlockBasis", "Av", "Aw"}, KeyExistsQ[artifact, #] &],
      canonicalBlocksFail[DecomposeFamilyBlocks, "artifact", file,
        "missing one of Family, BlockBasis, Av, Aw"]];
    family = artifact["Family"];
    basis = artifact["BlockBasis"];
    dimension = Length[basis];
    av = artifact["Av"];
    aw = artifact["Aw"];
    If[Dimensions[av] =!= {dimension, dimension} ||
        Dimensions[aw] =!= {dimension, dimension},
      canonicalBlocksFail[DecomposeFamilyBlocks, "dimensions", family,
        dimension, Dimensions[av], Dimensions[aw]]];
    (* i -> j when the derivative of basis element i involves element j:
       block i depends on block j. *)
    edges = Reap[
      Do[
        If[i =!= j &&
            (! canonicalBlocksZeroQ[av[[i, j]], zeroTest] ||
              ! canonicalBlocksZeroQ[aw[[i, j]], zeroTest]),
          Sow[DirectedEdge[i, j]]],
        {i, dimension}, {j, dimension}]][[2]];
    edges = If[edges === {}, {}, First[edges]];
    graph = Graph[Range[dimension], edges];
    components = Sort[Sort /@ ConnectedComponents[graph]];
    {family, basis, av, aw, graph, components}
  ];

(* The certificate that licenses block-by-block solving: order the
   blocks so that every dependency precedes its dependent, and check
   that no connection entry points strictly forward in that order. *)
canonicalBlocksTriangularityCertificate[family_, dimension_, av_, aw_,
    components_, zeroTest_] :=
  Module[{index, condensation, order, blockOrder, rowOrder, position,
      violations},
    index = ConstantArray[0, dimension];
    Do[Scan[(index[[#]] = k) &, components[[k]]], {k, Length[components]}];
    condensation = DeleteDuplicates @ Flatten @ Table[
      If[index[[i]] =!= index[[j]] &&
          (! canonicalBlocksZeroQ[av[[i, j]], zeroTest] ||
            ! canonicalBlocksZeroQ[aw[[i, j]], zeroTest]),
        {DirectedEdge[index[[i]], index[[j]]]},
        {}],
      {i, dimension}, {j, dimension}];
    (* Edge a -> b means block a depends on block b, so b must be
       solved first: the solving order is the reverse topological one. *)
    order = Quiet @ TopologicalSort[
      Graph[Range[Length[components]], condensation]];
    blockOrder = If[ListQ[order] && Length[order] === Length[components],
      Reverse[order],
      Range[Length[components]]];
    position = ConstantArray[0, Length[components]];
    Do[position[[blockOrder[[k]]]] = k, {k, Length[blockOrder]}];
    rowOrder = Flatten[components[[blockOrder]]];
    violations = Count[
      Flatten @ Table[
        (! canonicalBlocksZeroQ[av[[i, j]], zeroTest] ||
            ! canonicalBlocksZeroQ[aw[[i, j]], zeroTest]) &&
          position[[index[[i]]]] < position[[index[[j]]]],
        {i, dimension}, {j, dimension}],
      True];
    <|
      "Family" -> family,
      "Rows" -> dimension,
      "Blocks" -> Length[components],
      "BlockOrder" -> blockOrder,
      "RowOrder" -> rowOrder,
      "TopologicalSortComplete" ->
        (ListQ[order] && Length[order] === Length[components]),
      "ForwardCouplings" -> violations,
      "BlockLowerTriangular" -> (violations === 0)
    |>
  ];

Options[DecomposeFamilyBlocks] = {
  "FilePattern" -> "*.wl",
  "Variables" -> Automatic,
  "Regulator" -> Automatic,
  "ZeroTest" -> "Structural",
  "Progress" -> True,
  "OutputDirectory" -> None
};

DecomposeFamilyBlocks[input_, OptionsPattern[]] := Catch[
  Module[{files, pattern, variables, regulator, zeroTest, progress, output,
      blocks = {}, certificates = {}, totalRows = 0, count, artifact,
      family, basis, av, aw, graph, components, dimension, sample},
    pattern = OptionValue["FilePattern"];
    If[! StringQ[pattern],
      canonicalBlocksFail[DecomposeFamilyBlocks, "option", "FilePattern",
        pattern]];
    zeroTest = OptionValue["ZeroTest"];
    If[! MemberQ[{"Structural", "Algebraic"}, zeroTest],
      canonicalBlocksFail[DecomposeFamilyBlocks, "option", "ZeroTest",
        zeroTest]];
    progress = TrueQ[OptionValue["Progress"]];
    output = OptionValue["OutputDirectory"];

    files = Which[
      ListQ[input] && AllTrue[input, StringQ], ExpandFileName /@ input,
      StringQ[input] && FileExistsQ[input] && ! DirectoryQ[input],
        {ExpandFileName[input]},
      StringQ[input] && DirectoryQ[input],
        SortBy[FileNames[pattern, ExpandFileName[input]], FileBaseName],
      True, canonicalBlocksFail[DecomposeFamilyBlocks, "dir", input]];
    If[files === {},
      canonicalBlocksFail[DecomposeFamilyBlocks, "files", input, pattern]];

    variables = canonicalBlocksResolveVariables[OptionValue["Variables"]];
    If[variables === $Failed,
      canonicalBlocksFail[DecomposeFamilyBlocks, "option", "Variables",
        OptionValue["Variables"]]];

    count = Length[files];
    sample = canonicalBlocksGetGlobal[First[files]];
    regulator = canonicalBlocksResolveRegulator[OptionValue["Regulator"],
      If[AssociationQ[sample], Lookup[sample, "Av", sample], sample], variables];
    If[regulator === $Failed || ! MatchQ[regulator, _Symbol],
      canonicalBlocksFail[DecomposeFamilyBlocks, "regulator"]];

    Do[
      Module[{file = files[[k]]},
        artifact = If[k === 1, sample, canonicalBlocksGetGlobal[file]];
        {family, basis, av, aw, graph, components} =
          canonicalBlocksFamilyBlocks[artifact, file, zeroTest];
        dimension = Length[basis];
        totalRows += dimension;
        Do[
          AppendTo[blocks, <|
            "Family" -> family,
            "Rows" -> components[[m]],
            "Dim" -> Length[components[[m]]],
            "Basis" -> basis[[components[[m]]]],
            "Av" -> av[[components[[m]], components[[m]]]],
            "Aw" -> aw[[components[[m]], components[[m]]]]
          |>],
          {m, Length[components]}];
        AppendTo[certificates,
          canonicalBlocksTriangularityCertificate[family, dimension, av, aw,
            components, zeroTest]];
        If[progress,
          Print["[DecomposeFamilyBlocks] ", k, "/", count,
            " family=", family,
            " rows=", dimension,
            " blocks=", Length[components],
            " dims=", canonicalBlocksHistogram[Length /@ components],
            " lowertriangular=", Last[certificates]["BlockLowerTriangular"]]]
      ],
      {k, count}];

    Module[{record},
      record = <|
        "Format" -> $canonicalBlocksArtifactFormat,
        "FormatVersion" -> $canonicalBlocksArtifactVersion,
        "Stage" -> "Decomposition",
        "Created" -> DateString[],
        "Source" -> input,
        "Variables" -> variables,
        "Regulator" -> regulator,
        "ZeroTest" -> zeroTest,
        "Families" -> Length[files],
        "TotalRows" -> totalRows,
        "Blocks" -> blocks,
        "BlockCount" -> Length[blocks],
        "DimensionHistogram" ->
          canonicalBlocksHistogram[#["Dim"] & /@ blocks],
        "Certificates" -> certificates,
        "BlockLowerTriangular" ->
          AllTrue[certificates, #["BlockLowerTriangular"] &]
      |>;
      If[progress,
        Print["[DecomposeFamilyBlocks] families=", Length[files],
          " rows=", totalRows,
          " blocks=", Length[blocks],
          " dims=", record["DimensionHistogram"],
          " lowertriangular=", record["BlockLowerTriangular"]]];
      If[StringQ[output],
        If[! DirectoryQ[output], Quiet[CreateDirectory[output]]];
        canonicalBlocksPutAtomic[blocks, FileNameJoin[{output, "blocks.wl"}]];
        canonicalBlocksPutAtomic[record,
          FileNameJoin[{output, "decomposition.wl"}]]];
      record
    ]
  ],
  $canonicalBlocksFailure
];

(* --- stage 1b: the class quotient --------------------------------- *)

Options[ClassifyBlocks] = {
  "Variables" -> Automatic,
  "Regulator" -> Automatic,
  "MaxBlockDimension" -> 7,
  "Progress" -> True,
  "ProgressInterval" -> 100,
  "OutputDirectory" -> None
};

ClassifyBlocks[input_, OptionsPattern[]] := Catch[
  Module[{blocks, variables, regulator, maximum, progress, interval, output,
      count, normalized, normalizedSwapped, invariants, buckets, classes,
      provisional, assignment, order, classIDs, record},
    blocks = Which[
      AssociationQ[input] && KeyExistsQ[input, "Blocks"], input["Blocks"],
      ListQ[input] && AllTrue[input, AssociationQ], input,
      True, canonicalBlocksFail[ClassifyBlocks, "blocks", input]];
    If[! AllTrue[blocks, KeyExistsQ[#, "Av"] && KeyExistsQ[#, "Aw"] &],
      canonicalBlocksFail[ClassifyBlocks, "blocks", input]];

    maximum = OptionValue["MaxBlockDimension"];
    If[! (IntegerQ[maximum] && maximum >= 1),
      canonicalBlocksFail[ClassifyBlocks, "option", "MaxBlockDimension",
        maximum]];
    progress = TrueQ[OptionValue["Progress"]];
    interval = Max[1, OptionValue["ProgressInterval"]];
    output = OptionValue["OutputDirectory"];

    variables = canonicalBlocksResolveVariables[
      If[OptionValue["Variables"] === Automatic && AssociationQ[input],
        Lookup[input, "Variables", Automatic],
        OptionValue["Variables"]]];
    If[variables === $Failed,
      canonicalBlocksFail[ClassifyBlocks, "option", "Variables",
        OptionValue["Variables"]]];
    regulator = canonicalBlocksResolveRegulator[
      If[OptionValue["Regulator"] === Automatic && AssociationQ[input],
        Lookup[input, "Regulator", Automatic],
        OptionValue["Regulator"]],
      #["Av"] & /@ Take[blocks, UpTo[50]], variables];
    If[regulator === $Failed || ! MatchQ[regulator, _Symbol],
      canonicalBlocksFail[ClassifyBlocks, "option", "Regulator",
        OptionValue["Regulator"]]];

    count = Length[blocks];
    normalized = Table[
      If[progress && (Mod[i, interval] === 0 || i === count),
        Print["[ClassifyBlocks] normalize ", i, "/", count]];
      canonicalBlocksMatrix[#, variables, regulator] & /@
        {blocks[[i]]["Av"], blocks[[i]]["Aw"]},
      {i, count}];
    normalizedSwapped = Table[
      canonicalBlocksMatrix[#, variables, regulator] & /@
        canonicalBlocksSwapPair[{blocks[[i]]["Av"], blocks[[i]]["Aw"]},
          variables],
      {i, count}];
    invariants = Table[
      canonicalBlocksBucketKey[normalized[[i]], normalizedSwapped[[i]]],
      {i, count}];

    (* Bucket on the cheap invariant, then decide equivalence inside a
       bucket by an explicit group element. *)
    buckets = GroupBy[Range[count], invariants[[#]] &];
    provisional = {};
    Do[
      Module[{members = buckets[key], local = {}},
        Do[
          Module[{matched = None},
            Catch[
              Do[
                If[canonicalBlocksMatchOrbit[
                    normalized[[local[[c, "Representative"]]]],
                    normalizedSwapped[[local[[c, "Representative"]]]],
                    normalized[[i]]] =!= None,
                  matched = c;
                  local[[c, "Members"]] = Append[local[[c, "Members"]], i];
                  Throw[Null, $canonicalBlocksBreak]],
                {c, Length[local]}],
              $canonicalBlocksBreak];
            If[matched === None,
              AppendTo[local,
                <|"Representative" -> i, "Members" -> {i}|>]]
          ],
          {i, members}];
        provisional = Join[provisional, local]
      ],
      {key, Keys[buckets]}];

    (* Correctness must not depend on the bucketing.  The orbit key is
       canonical, so two provisional classes that share one are the same
       class however they were bucketed; merging on the key makes the
       invariant a pure optimization rather than part of the answer.  An
       earlier invariant folded in the swap by exchanging Av and Aw
       WITHOUT relabelling v <-> w inside the entries, which split
       swap-equivalent blocks into separate classes -- exactly the
       over-splitting failure this module exists to avoid. *)
    classes = Values @ GroupBy[
      Table[
        <|"Key" -> canonicalBlocksOrbitKey[
            normalized[[p["Representative"]]],
            normalizedSwapped[[p["Representative"]]], maximum],
          "Representative" -> p["Representative"],
          "Members" -> p["Members"]|>,
        {p, provisional}],
      #["Key"] &,
      <|"Key" -> #[[1]]["Key"],
        "Representative" -> #[[1]]["Representative"],
        "Members" -> Union[Flatten[#[[All, "Members"]]]]|> &];

    (* Integer labels are assigned after the mathematical partition exists,
       in a reproducible order. *)
    classes = SortBy[classes,
      {blocks[[#["Representative"]]]["Dim"] &,
        blocks[[#["Representative"]]]["Family"] &,
        blocks[[#["Representative"]]]["Rows"] &}];

    classes = Table[
      Module[{entry = classes[[c]], index, rep, key},
        index = entry["Representative"];
        rep = blocks[[index]];
        key = entry["Key"];
        If[progress,
          Print["[ClassifyBlocks] class=", c,
            " dim=", rep["Dim"],
            " size=", Length[entry["Members"]],
            " rep=", rep["Family"], ":", rep["Rows"]]];
        <|
          "Format" -> "FeynFacet-BlockClass",
          "FormatVersion" -> $canonicalBlocksArtifactVersion,
          "ClassID" -> c,
          "OrbitKey" -> key,
          "Dim" -> rep["Dim"],
          "Variables" -> variables,
          "Regulator" -> regulator,
          "RepFamily" -> rep["Family"],
          "RepRows" -> rep["Rows"],
          "RepBasis" -> rep["Basis"],
          "RepAv" -> rep["Av"],
          "RepAw" -> rep["Aw"],
          "Size" -> Length[entry["Members"]],
          (* Maps are derived against the FINAL representative, after
             merging, so they never refer to a provisional one. *)
          "Members" -> Table[
            Module[{map},
              map = canonicalBlocksMatchOrbit[normalized[[index]],
                normalizedSwapped[[index]], normalized[[m]]];
              <|
                "Family" -> blocks[[m]]["Family"],
                "Rows" -> blocks[[m]]["Rows"],
                "Basis" -> Lookup[blocks[[m]], "Basis", Missing[]],
                "Swap" -> If[map === None, Missing["NoMap"], map["Swap"]],
                "Permutation" ->
                  If[map === None, Missing["NoMap"], map["Permutation"]],
                "MapVerified" -> (map =!= None)
              |>],
            {m, entry["Members"]}],
          "Families" -> DeleteDuplicates[
            Table[blocks[[m]]["Family"], {m, entry["Members"]}]]
        |>
      ],
      {c, Length[classes]}];

    classIDs = Range[Length[classes]];
    assignment = Flatten @ Table[
      Table[<|
        "Family" -> m["Family"],
        "Rows" -> m["Rows"],
        "Dim" -> classes[[c]]["Dim"],
        "ClassID" -> c,
        "Swap" -> m["Swap"],
        "Permutation" -> m["Permutation"]
      |>, {m, classes[[c]]["Members"]}],
      {c, Length[classes]}];

    record = <|
      "Format" -> $canonicalBlocksArtifactFormat,
      "FormatVersion" -> $canonicalBlocksArtifactVersion,
      "Stage" -> "Classification",
      "Created" -> DateString[],
      "Variables" -> variables,
      "Regulator" -> regulator,
      "BlockCount" -> count,
      "ClassCount" -> Length[classes],
      "ClassOrder" -> classIDs,
      "Classes" -> AssociationThread[classIDs -> classes],
      "Assignment" -> assignment,
      "DimensionHistogram" ->
        canonicalBlocksHistogram[#["Dim"] & /@ classes],
      "MembersTotal" -> Total[#["Size"] & /@ classes]
    |>;
    If[progress,
      Print["[ClassifyBlocks] blocks=", count,
        " classes=", Length[classes],
        " dims=", record["DimensionHistogram"],
        " members=", record["MembersTotal"]]];
    If[StringQ[output],
      If[! DirectoryQ[output], Quiet[CreateDirectory[output]]];
      canonicalBlocksPutAtomic[classes, FileNameJoin[{output, "classes.wl"}]];
      canonicalBlocksPutAtomic[assignment,
        FileNameJoin[{output, "block_class_assign.wl"}]];
      canonicalBlocksPutAtomic[record,
        FileNameJoin[{output, "classification.wl"}]]];
    record
  ],
  $canonicalBlocksFailure
];

(* --- the certificate ---------------------------------------------- *)

Options[ValidateCanonicalForm] = {
  "Variables" -> Automatic,
  "Regulator" -> Automatic,
  "Details" -> False
};

(* RETIRED ROUTE (user decision N3, 2026-09-02): the CANONICA class ladder.
   DiagonalBlockClassCampaign (finite-field route) canonicalizes classes;
   the implementation is kept, unloaded, in Private_Backup/CanonicalBlocks.wl. *)
Options[CanonicalizeClasses] = {};
CanonicalizeClasses[___] := <|"Status" -> "RouteRetired",
  "Route" -> "CanonicalizeClasses (CANONICA class ladder)",
  "Replacement" -> "DiagonalBlockClassCampaign (Private/EpsForm/Blocks/DiagonalBlockEpsForm.wl)",
  "Note" -> "implementation kept, unloaded, in FeynFacet/Private_Backup/CanonicalBlocks.wl (2026-09-02)"|>;

ValidateCanonicalForm[file_String, opts : OptionsPattern[]] :=
  If[FileExistsQ[file],
    ValidateCanonicalForm[canonicalBlocksGetGlobal[file], opts],
    (Message[ValidateCanonicalForm::form, file]; False)];

ValidateCanonicalForm[form_Association, opts : OptionsPattern[]] :=
  Module[{matrices, variables},
    matrices = Lookup[form, "EpsForm", $Failed];
    If[matrices === $Failed,
      Message[ValidateCanonicalForm::form, form]; Return[False]];
    variables = Which[
      OptionValue["Variables"] =!= Automatic, OptionValue["Variables"],
      KeyExistsQ[form, "Variables"], form["Variables"],
      True, canonicalBlocksDefaultVariables[]];
    (* Deliberately NOT consulting form["Validated"]: a stored flag is
       an assertion, not a certificate. *)
    ValidateCanonicalForm[matrices, variables,
      "Regulator" -> If[OptionValue["Regulator"] === Automatic,
        Lookup[form, "Regulator", Automatic], OptionValue["Regulator"]],
      "Details" -> OptionValue["Details"]]
  ];

ValidateCanonicalForm[matrices_List, variables_List, OptionsPattern[]] :=
  Module[{regulator, dimension, forms, letters, dlogs, points, residues,
      residuals, constantQ, ok, details, entryResidues},
    If[! (Length[variables] >= 1 && AllTrue[variables, MatchQ[#, _Symbol] &]),
      Message[ValidateCanonicalForm::form, variables]; Return[False]];
    If[! (ListQ[matrices] && Length[matrices] === Length[variables]),
      Message[ValidateCanonicalForm::variables, Length[variables],
        Length[matrices]]; Return[False]];
    If[! AllTrue[matrices, MatrixQ], Return[False]];
    dimension = Length[First[matrices]];
    If[Dimensions[matrices] =!= {Length[variables], dimension, dimension},
      Return[False]];
    regulator = canonicalBlocksResolveRegulator[OptionValue["Regulator"],
      matrices, variables];
    If[regulator === $Failed || ! MatchQ[regulator, _Symbol],
      Message[ValidateCanonicalForm::regulator]; Return[False]];
    (* An epsilon-form is eps times a constant-residue dlog form.  This
       is decided WITHOUT CANONICA (user decision 2026-09-02): the
       letters are the irreducible denominator factors of the
       regulator-free forms, the residues are solved exactly from the
       dlog identity at random rational points, and the identity is
       re-verified symbolically -- Together is a canonical form. *)
    forms = Map[Together[#/regulator] &, matrices, {3}];
    If[! FreeQ[forms, regulator], Return[canonicalBlocksValidateResult[False,
      OptionValue["Details"], dimension, variables, regulator, {}, {},
      False, Missing["NotEpsilonLinear"]]]];
    letters = DeleteDuplicates[Flatten[
      (First /@ Rest[FactorList[Denominator[Together[#]]]]) & /@
        Select[Flatten[forms], ! TrueQ[# === 0] &]]];
    letters = Select[letters, ! FreeQ[#, Alternatives @@ variables] &];
    letters = DeleteDuplicates[letters,
      PossibleZeroQ[#1 - #2] || PossibleZeroQ[#1 + #2] &];
    If[letters === {},
      ok = AllTrue[Flatten[forms], TrueQ[# === 0] &];
      Return[canonicalBlocksValidateResult[ok, OptionValue["Details"],
        dimension, variables, regulator, {}, {}, ok,
        If[ok, ConstantArray[0, Dimensions[matrices]], forms]]]];
    dlogs = Table[Together[D[letter, var]/letter], {letter, letters},
      {var, variables}];
    (* one exact linear solve per matrix entry: the residue vector of
       that entry is determined by the dlog identity at enough points *)
    SeedRandom[20260902];
    points = Table[Thread[variables -> Table[RandomInteger[{2, 97}]/RandomInteger[{101, 199}],
      Length[variables]]], {Length[letters] + 4}];
    entryResidues[r_, c_] := Module[{rows, rhs, sol},
      rows = Flatten[Table[dlogs[[All, i]] /. pt, {pt, points}, {i, Length[variables]}], 1];
      rhs = Flatten[Table[forms[[i, r, c]] /. pt, {pt, points}, {i, Length[variables]}]];
      sol = Quiet[Check[LinearSolve[rows, rhs], $Failed]];
      If[sol === $Failed, ConstantArray[0, Length[letters]], sol]];
    residues = Table[Table[entryResidues[r, c][[a]], {r, dimension}, {c, dimension}],
      {a, Length[letters]}];
    residuals = Table[Map[Together,
      forms[[i]] - Sum[residues[[a]] dlogs[[a, i]], {a, Length[letters]}], {2}],
      {i, Length[variables]}];
    constantQ = FreeQ[residues, Alternatives @@ Append[variables, regulator]];
    ok = TrueQ[constantQ] && AllTrue[residuals,
      # === ConstantArray[0, {dimension, dimension}] &];
    canonicalBlocksValidateResult[ok, OptionValue["Details"], dimension,
      variables, regulator, letters, residues, constantQ, residuals]
  ];

canonicalBlocksValidateResult[ok_, detailsQ_, dimension_, variables_,
    regulator_, letters_, residues_, constantQ_, residuals_] :=
  If[TrueQ[detailsQ],
    <|"Valid" -> TrueQ[ok], "Dimension" -> dimension,
      "Variables" -> variables, "Regulator" -> regulator,
      "Letters" -> letters, "Residues" -> residues,
      "ConstantResidues" -> TrueQ[constantQ],
      "ReconstructionResidual" -> residuals|>,
    TrueQ[ok]];

ValidateCanonicalForm[other_ /; ! AssociationQ[other] && ! StringQ[other],
    OptionsPattern[]] := (
  Message[ValidateCanonicalForm::form, other]; False);

(* --- stage 1c: the canonicalization campaign ---------------------- *)

canonicalBlocksTotalDegree[polynomial_, variables_List] :=
  Module[{scale},
    Exponent[polynomial /. Thread[variables -> scale * variables], scale]
  ];

(* Irreducible denominator factors of total degree at least two.  The
   classifier must weigh v and w equally: an earlier version used the
   degree in a single variable and misfiled the bilinear 1 - 4 v w. *)
canonicalBlocksQuadraticFactors[matrices_, variables_List] :=
  Module[{denominators},
    denominators = DeleteDuplicates @ Flatten @ Map[
      FactorList[Denominator[Together[#]]][[All, 1]] &,
      matrices, {3}];
    Select[denominators,
      ! FreeQ[#, Alternatives @@ variables] &&
        canonicalBlocksTotalDegree[#, variables] >= 2 &]
  ];

(* Rational parametrization of a single conic.  Two branches, both
   verified symbolically before the chart is used:
     (a) q linear in one variable: solve q == t^2 for it directly;
     (b) q = l^2 + (linear): shift u = l + 2 t and solve the linear
         remainder, which covers the Kallen variants.
   The chart is returned only if the substituted q reproduces the
   square of the stated root exactly. *)
canonicalBlocksBuildChart[q_, variables : {v_Symbol, w_Symbol},
    parameter_Symbol] :=
  Module[{pairs = {{v, w}, {w, v}}},
    (* The chart parameter is a NEW coordinate.  If it is one of the
       source variables, Solve[q - parameter^2 == 0, x2] solves an
       equation in which the two sides mean the same symbol and returns
       a "chart" that silently identifies a kinematic variable with the
       conic parameter -- a wrong answer with no diagnosis.  Refused by
       type (generality pass 2026-08-23); the caller distinguishes a
       refusal from a chart by the "Status" key, which no chart has. *)
    If[MemberQ[variables, parameter],
      Return[<|"Status" -> "ChartParameterCollides",
        "Parameter" -> parameter, "Variables" -> variables|>]];
    Catch[
      Do[
        Module[{x1 = pair[[1]], x2 = pair[[2]], solution, substitution},
          If[Exponent[q, x2] === 1,
            solution = Quiet[Solve[q - parameter^2 == 0, x2]];
            If[solution =!= {} && ListQ[solution] &&
                FreeQ[solution, Power[_, 1/2]],
              substitution = x2 -> Together[x2 /. First[solution]];
              If[Together[(q /. substitution) - parameter^2] === 0,
                Throw[<|"Fixed" -> x1, "Subst" -> substitution,
                  "Root" -> parameter, "Branch" -> "LinearSolve"|>,
                  $canonicalBlocksBreak]]]]],
        {pair, pairs}];
      Do[
        Module[{x1 = pair[[1]], x2 = pair[[2]], lead, ell, linear, solution,
            substitution},
          lead = Coefficient[q, x1, 2];
          If[lead === 1,
            ell = x1 + Coefficient[q, x1, 1]/2;
            linear = Together[q - ell^2];
            If[Exponent[linear, x1] <= 1 && Exponent[linear, x2] <= 1 &&
                ! FreeQ[linear, x2],
              solution = Quiet[Solve[
                linear - 4 parameter ell - 4 parameter^2 == 0, x2]];
              If[solution =!= {} && ListQ[solution] &&
                  FreeQ[solution, Power[_, 1/2]],
                substitution = x2 -> Together[x2 /. First[solution]];
                If[Together[(q /. substitution) -
                    ((ell /. substitution) + 2 parameter)^2] === 0,
                  Throw[<|"Fixed" -> x1, "Subst" -> substitution,
                    "Root" -> (ell + 2 parameter),
                    "Branch" -> "SquareCompletion"|>,
                    $canonicalBlocksBreak]]]]]],
        {pair, pairs}];
      None,
      $canonicalBlocksBreak]
  ];

(* Pull the system back to the chart frame.  With x2 = s(x1, t) the
   chain rule gives d/dx1|_t = d/dx1 + (ds/dx1) d/dx2 and
   d/dt = (ds/dt) d/dx2. *)
canonicalBlocksApplyChart[{av_, aw_}, chart_, variables : {v_, w_},
    parameter_Symbol] :=
  Module[{fixed, image, substitution, fixedMatrix, solvedMatrix},
    fixed = chart["Fixed"];
    substitution = chart["Subst"];
    image = substitution[[2]];
    {fixedMatrix, solvedMatrix} = If[fixed === v, {av, aw}, {aw, av}];
    {
      {
        Map[Together, (fixedMatrix /. substitution) +
          (solvedMatrix /. substitution) D[image, fixed], {2}],
        Map[Together, (solvedMatrix /. substitution) D[image, parameter], {2}]
      },
      {fixed, parameter}
    }
  ];

canonicalBlocksClassList[input_] := Which[
  AssociationQ[input] && KeyExistsQ[input, "Classes"],
    If[AssociationQ[input["Classes"]], Values[input["Classes"]],
      input["Classes"]],
  AssociationQ[input] && KeyExistsQ[input, "RepAv"], {input},
  ListQ[input] && AllTrue[input, AssociationQ], input,
  True, $Failed
];

canonicalBlocksClassLabel[class_] :=
  Lookup[class, "ClassID", "unknown"];

(* --- the babysitter contract -------------------------------------- *)

Options[CanonicalBlocksStatus] = {
  "Classes" -> None,
  "Validate" -> False,
  "Print" -> True
};

CanonicalBlocksStatus[directory_String, OptionsPattern[]] := Catch[
  Module[{files, expected, records, rows, summary, validate, printQ},
    If[! DirectoryQ[ExpandFileName[directory]],
      canonicalBlocksFail[CanonicalBlocksStatus, "directory", directory]];
    validate = TrueQ[OptionValue["Validate"]];
    printQ = TrueQ[OptionValue["Print"]];
    files = SortBy[FileNames["class*.wl", ExpandFileName[directory]],
      FileBaseName];
    records = canonicalBlocksGetGlobal /@ files;
    expected = canonicalBlocksClassList[OptionValue["Classes"]];

    rows = Table[
      Module[{record = records[[i]], ok},
        ok = If[validate, TrueQ[ValidateCanonicalForm[record]], Missing["NotChecked"]];
        <|
          "ClassID" -> Lookup[record, "ClassID", None],
          "Dim" -> Lookup[record, "Dim", "-"],
          "AnsatzDegree" -> Lookup[record, "AnsatzDegree", "-"],
          "Frame" -> Lookup[record, "Frame",
            If[Lookup[record, "Chart", None] === None, "direct", "chart"]],
          "Seconds" -> Lookup[record, "Seconds", "-"],
          "Revalidated" -> ok,
          "File" -> files[[i]]
        |>],
      {i, Length[records]}];

    If[printQ,
      Do[
        Print["[CanonicalBlocksStatus] class=", row["ClassID"],
          " dim=", row["Dim"],
          " status=DONE",
          " degree=", row["AnsatzDegree"],
          " frame=", row["Frame"],
          " seconds=", row["Seconds"],
          If[validate, " revalidated=" <> ToString[row["Revalidated"]], ""]],
        {row, rows}]];

    If[expected =!= $Failed && expected =!= None && ListQ[expected],
      Module[{done, missing},
        done = Cases[rows, r_ :> r["ClassID"]];
        missing = Select[expected,
          ! MemberQ[done, Lookup[#, "ClassID", None]] &];
        If[printQ,
          Do[
            Print["[CanonicalBlocksStatus] class=",
              canonicalBlocksClassLabel[class],
              " dim=", Lookup[class, "Dim", "-"],
              " status=MISSING"],
            {class, missing}]];
        summary = <|"Expected" -> Length[expected],
          "Missing" -> canonicalBlocksClassLabel /@ missing,
          "MissingCount" -> Length[missing]|>],
      summary = <|"Expected" -> Missing["NotSupplied"], "Missing" -> {},
        "MissingCount" -> Missing["NotSupplied"]|>];

    Module[{result},
      result = Join[<|
        "Format" -> $canonicalBlocksArtifactFormat,
        "Stage" -> "Status",
        "Directory" -> ExpandFileName[directory],
        "Done" -> Length[rows],
        "Rows" -> rows,
        "DegreeHistogram" -> canonicalBlocksHistogram[
          Lookup[#, "AnsatzDegree", "-"] & /@ rows],
        "FrameHistogram" -> canonicalBlocksHistogram[
          Lookup[#, "Frame", "-"] & /@ rows],
        "Revalidated" -> If[validate,
          Count[rows, r_ /; TrueQ[r["Revalidated"]]], Missing["NotChecked"]]
      |>, summary];
      If[printQ,
        Print["[CanonicalBlocksStatus] done=", result["Done"],
          " expected=", result["Expected"],
          " missing=", result["MissingCount"],
          " degrees=", result["DegreeHistogram"],
          " frames=", result["FrameHistogram"],
          If[validate, " revalidated=" <> ToString[result["Revalidated"]], ""]]];
      result
    ]
  ],
  $canonicalBlocksFailure
];

(* Restored 2026-09-02 (round 2): the chart-parameter chooser is generic
   (t_generality_renamed_variables cross-checks it against
   diagonalBlockChartParameter); the reachability scan counted only the
   retired ladder as its caller. *)
canonicalBlocksChartParameter[Automatic, matrices_, variables_List,
    regulator_] := Module[{t = Symbol["Global`t"]},
  If[MemberQ[variables, t] || t === regulator || ! FreeQ[matrices, t],
    Unique["FeynFacet`Private`chartParameter"], t]];

canonicalBlocksChartParameter[parameter_Symbol, matrices_, variables_List,
    regulator_] := parameter;
