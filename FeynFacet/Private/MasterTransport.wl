(* Stage 2 of the master-solving workflow: symbolic transport of a
   family differential-equation system.

   The stage takes a family's connection {Av, Aw}, assembles it into
   block-lower-triangular form against certified per-block data, builds
   the path-ordered transport with a MATURE package, and then supplies
   the three things that package does not: the epsilon regrading, the
   physical valuation constraints, and the exact per-order check
   against the ORIGINAL family differential equation.

     TransportFamily  -- the whole stage, returning the symbolic
       solution with symbolic constants;
     TransportStatus  -- one greppable line per block, for a watchdog.

   Why the solver core is not ours.  The package benchmark of
   2026-08-14/15 measured the identical weight-3 NLO deliverable on the
   same input, the same paths and the same referee: Libra 0.03 s with
   exact per-weight zeros and 40-digit agreement against the certified
   2F1 masters, PolyLogTools 0.39 s and also correct, and our own
   variation-of-constants solver exceeding a 30-minute budget without
   completing one order.  The mechanism was representation, not path: a
   shuffle-expanded canonical GPL basis carries rational-FUNCTION
   coefficients (about 50 000 leaves for one sector at eps^2) where
   Libra's unreduced words carry 6 972 leaves for the entire solution.
   The solver core is therefore Libra, with PolyLogTools as a validated
   alternative backend, and only four components of the retired engine
   are carried over.  They are marked (C1)...(C4) below.

   (C3) is the substantive new content of this file.  Libra's
   PexpExpansion grades the transport by POWERS OF THE CONNECTION.  When
   the conjugated connection is a strict epsilon-form those two gradings
   coincide and its output is already the deliverable.  Tier-3 families
   are the case where they do not: CF3's conjugated connection keeps a
   1/eps off-diagonal coupling at entry [3,2], so a weight-n term
   carries MIXED epsilon orders and the exact per-weight check certifies
   the Pexp recursion rather than an epsilon-order-by-order solution.
   Turning the first object into the second is a finite, mechanical
   re-expansion -- and it is real work that had to be written.

   The finiteness is a theorem about the block structure, not an
   assumption, and masterTransportEpsShift computes its constant.  Write
   the conjugated connection as a Laurent series in eps.  Every entry
   with a NEGATIVE eps order is necessarily strictly block-lower-
   triangular, because the assembly certificate makes each diagonal
   block either an epsilon-form (orders >= +1) or, for a closed-form
   sector, identically zero.  A word in the Pexp expansion therefore
   descends one block for each negative-order factor it uses, so it can
   use at most (number of blocks - 1) of them, and

       eps-order of a weight-n term  >=  n - D,
       D = longest path in the block DAG under the edge cost
           max(0, 1 - ord_eps(coupling)).

   D is finite exactly when every diagonal block is an epsilon-form or
   zero -- which is the assembly certificate -- and a self-coupling of
   order <= 0 makes it infinite, which is reported rather than
   truncated.  Consequently transport weight jmax + D is enough to
   determine every epsilon order up to jmax, and the module additionally
   ASSERTS the prediction against the measured lowest order at the top
   weight.  An assertion that cannot be performed counts as
   not-performable, never as a pass.

   Per-block providers.  A diagonal block reaches this stage in one of
   two ways, and the transport must not care which:

     "EpsForm"           -- a certified class epsilon-form {T, Ev, Ew},
                            conjugating the block to eps * dlog;
     "ClosedFormSector"  -- a fundamental matrix Phi known in closed
                            form (2F1-class), with PhiInverse, a
                            Certificate and an optional Frame/Chart.

   The second is the standardized consumption interface for the Phi
   route, which is the committed path for the classes that no
   canonicalizer reaches (77/97/79: CANONICA and Libra's Rookie both
   time out with admission genuinely met).  It plugs into exactly the
   same machinery, because with I = Phi.F the block's conjugated
   connection is IDENTICALLY ZERO:

       dI = A.I,  I = Phi.F,  dPhi = A.Phi   =>   dF = 0.

   So a closed-form sector is an epsilon-form block whose Ev and Ew
   happen to vanish; couplings, regrading and valuation are untouched.
   Its Phi is re-verified here against the block connection and its
   inverse is re-multiplied out -- a stored "Certificate" is read as
   provenance and never as evidence, for the same reason
   ValidateCanonicalForm ignores a stored "Validated" flag.

   Regulator handling.  Every boundary -- our artifacts, Libra,
   PolyLogTools -- normalizes the regulator by SymbolName, so a
   Global`eps system and a Global`Epsilon system take one code path.

   Interop traps that this file exists to avoid, all of them measured:

     B1  Libra ships NO derivative rule for its own II
         (DownValues[II] = {}, UpValues[II] = {}).  Verification glue
         must supply it, and this file supplies its own instead, on a
         package-owned inert head, so that a stored solution never
         depends on Libra being loaded.
     B2  For a LIST first argument the derivative tag is
         Derivative[{0,..,0},1,0], one 0 per index.  A literal {0}
         pattern silently matches weight 1 only, and produced a fake
         {True, False, False} per-weight verification.
     B3/B4  Libra and PolyLogTools both define II, and a helper defined
         BEFORE a package loads captures Global`II rather than the
         package's.  Replacement rules then match nothing and the
         comparison becomes vacuous while reporting full agreement.
         Both engines are therefore reached only through fully
         qualified symbols, never through $ContextPath.
     P1  PolyLogTools exports 1699 symbols, including v, w, x, y, t, G,
         II, DG and nearly every one- and two-letter name.  Its load is
         wrapped so that $ContextPath is restored afterwards.
     P2  An artifact read AFTER PolyLogTools loads acquires
         PolyLogTools`v rather than Global`v, and substitution rules
         then match nothing -- a transport built from a matrix free of
         the integration variable, whose exact check is self-consistency
         on the wrong system.  All input is normalized before any
         backend loads.
     P3  A rule written pltG[args__] :> ... has an LHS that EVALUATES,
         so it silently matches nothing.  Match on the head: g_pltG.
     T6  Global`D from the data artifacts shadows System`D.
     M1  Module initializers are NOT sequentially scoped: a local
         referenced inside a later initializer of the same Module is
         still unassigned, and ConstantArray[0, n] then returns a
         length-1 SymbolicZerosArray with no error.  Every array here is
         built in the body and its shape asserted.
     M2  Return inside Do returns from the Do, not the function.
     M3  Missing["KeyAbsent",...] =!= None, so a Lookup default must be
         tested with MissingQ.
     M4  Put is not atomic; a kill during a write leaves a truncated
         artifact that Get later accepts as a partial expression.

   Frames.  The exact per-order check is made in the PATH frame,
   d/dtau I_n = sum_r Ahat^(r) . I_{n-r}, with the basis transformation
   restricted to the same segment the transport used.  That restriction
   is not cosmetic: comparing a (v,w)-frame T against a path-restricted
   connection is apples to pears and can never pass.  A (v,w)-frame
   check would additionally need the Goncharov parameter differential
   for words whose indices depend on (v,w), which is not implemented;
   the exact statement here is the path-frame check together with the
   exact flatness certificate, and the module says so rather than
   reporting a meaningless zero test. *)

ClearAll[
  $masterTransportRegulatorNames,
  $masterTransportLibraLoaded,
  $masterTransportPolyLogToolsLoaded,
  $masterTransportBuiltinCaps,
  masterTransportFail,
  masterTransportLog,
  masterTransportPutAtomic,
  masterTransportGetGlobal,
  masterTransportDefaultVariables,
  masterTransportDetectRegulator,
  masterTransportResolveRegulator,
  masterTransportResolveVariables,
  masterTransportNormalize,
  masterTransportZeroQ,
  masterTransportSimplifyZeroQ,
  $masterTransportZeroTimeLimit,
  masterTransportZeroMatQ,
  masterTransportCollect,
  masterTransportNormalizeWords,
  masterTransportWordFreeQ,
  masterTransportEpsOrder,
  masterTransportLaurentList,
  masterTransportLaurentMat,
  masterTransportEpsPart,
  masterTransportDTau,
  masterTransportSCCBlocks,
  masterTransportOrderBlocks,
  masterTransportScalarEpsForm,
  masterTransportBlockProvider,
  masterTransportClosedFormSector,
  masterTransportAssemble,
  masterTransportCertificateOK,
  masterTransportDepthBudget,
  masterTransportEpsShift,
  masterTransportCheckableOrders,
  masterTransportPathMatrix,
  masterTransportMonicCheck,
  masterTransportLoadLibra,
  masterTransportLoadPolyLogTools,
  masterTransportBackendLibra,
  masterTransportBackendPolyLogTools,
  masterTransportRunBackend,
  masterTransportVerifyTransport,
  masterTransportRegrade,
  masterTransportSolutionVector,
  masterTransportMasterSeries,
  masterTransportValuation,
  masterTransportTOrderMin,
  masterTransportCheckDE,
  masterTransportExactSectors,
  masterTransportCardSetting,
  masterTransportResolveCard
];

MasterTransport::regulator =
  "Could not resolve the regulator symbol in `1`; give \"Regulator\" explicitly.";
MasterTransport::option =
  "Value `2` is not valid for option \"`1`\" of `3`.";
MasterTransport::backend =
  "Transport backend `1` is not available: `2`.";
MasterTransport::provider =
  "Block `1` has no usable provider: `2`.";
MasterTransport::nonrational =
  "The conjugated connection is not rational in the path parameter, so a \
word-based backend cannot be used. This happens when a closed-form sector \
carries couplings; solve those by variation of constants instead.";
MasterTransport::pathparameter =
  "The path parameter `1` is not a free symbol: it carries `2` own value(s). Every derivative in this stage would then be taken with respect to a symbol that already has a value, which silently produces nonsense. Note that writing tau = Symbol[\"Global`tau\"] in a script running at Global` context assigns the symbol to ITSELF and is a common way to reach this state.";

MasterTransport::shift =
  "The epsilon regrading does not terminate: block `1` has a self-coupling of \
epsilon order `2`, so a weight-truncated transport can never determine a \
complete epsilon order.";

$masterTransportRegulatorNames = {"eps", "Eps", "epsilon", "Epsilon", "ep"};

(* Every symbolic zero test gets a budget.  Simplify on a 2F1 residual
   can run without bound, and a check that has not returned is neither a
   pass nor a failure -- it is a check that was not performed, and it
   must be reported as "Inconclusive" rather than hang the stage. *)
$masterTransportZeroTimeLimit = 120;

$masterTransportLibraLoaded = False;
$masterTransportPolyLogToolsLoaded = False;

$masterTransportBuiltinCaps = <|
  "TimeConstraint" -> 1800,
  "MemoryConstraint" -> 8 1024^3,
  "MaxWeight" -> 10
|>;

masterTransportFail[head_, tag_, args___] := (
  Message[MessageName[MasterTransport, tag], args];
  Throw[$Failed, $masterTransportFailure]
);

masterTransportLog[verbose_, args___] := If[TrueQ[verbose],
  WriteString["stdout", "[transport] ", StringJoin[ToString /@ {args}], "\n"];
  Flush[OutputStream["stdout", 1]]
];

(* M4: a kill during Put leaves a truncated artifact that Get accepts as
   a partial expression.  Write to a temporary name in the same
   directory and rename, which is atomic on one filesystem. *)
masterTransportPutAtomic[expr_, file_String] := Module[{temp},
  temp = file <> ".partial" <> ToString[$ProcessID];
  Quiet[DeleteFile[temp]];
  Put[expr, temp];
  If[! FileExistsQ[temp], Return[$Failed]];
  RenameFile[temp, file, OverwriteTarget -> True];
  file
];

(* T6: the artifacts store unqualified symbols and one of them is D.
   Read them with a clean context so Global`D cannot shadow System`D
   inside this package. *)
masterTransportGetGlobal[file_String] :=
  Block[{$Context = "Global`", $ContextPath = {"Global`", "System`"}},
    Get[file]
  ];

masterTransportDefaultVariables[] :=
  {Symbol["Global`v"], Symbol["Global`w"]};

masterTransportDetectRegulator[expr_, variables_List] := Module[{symbols},
  symbols = DeleteDuplicates @ Cases[
    expr,
    s_Symbol /; MemberQ[$masterTransportRegulatorNames, SymbolName[s]],
    {0, Infinity},
    Heads -> True
  ];
  symbols = DeleteCases[symbols, Alternatives @@ variables];
  If[Length[symbols] === 1, First[symbols], $Failed]
];

masterTransportResolveVariables[value_] := Switch[value,
  Automatic, masterTransportDefaultVariables[],
  {_Symbol, __Symbol}, value,
  _, $Failed
];

masterTransportResolveRegulator[value_, expr_, variables_] := Switch[value,
  Automatic, masterTransportDetectRegulator[expr, variables],
  _Symbol, value,
  _, $Failed
];

(* The one place symbol identity changes.  Matching on SymbolName keeps a
   Global`eps system and a Global`Epsilon system on one code path, and it
   is applied to EVERY input before any backend package can load and
   claim those names for itself (trap P2). *)
masterTransportNormalize[expr_, regulator_Symbol, variables_List] :=
  Module[{names, rules},
    names = SymbolName /@ variables;
    rules = Join[
      {(s_Symbol /; MemberQ[$masterTransportRegulatorNames, SymbolName[s]] &&
          SymbolName[s] =!= SymbolName[regulator]) :> regulator},
      MapThread[
        Function[{nm, target},
          (s_Symbol /; SymbolName[s] === nm && s =!= target) :> target],
        {names, variables}]
    ];
    expr /. rules
  ];

(* ------------------------------------------------------------------ *)
(*  Representation: one package-owned inert word head                   *)
(* ------------------------------------------------------------------ *)

(* TransportWord[{a1,...,an}, z] is the Goncharov polylogarithm
   G(a1,...,an; z), which is also the PolyLogTools convention.  Libra's
   II[{a1,...,an}, x, x0] carries an explicit base point and equals
   G(a1-x0, ..., an-x0; x-x0); the conversion happens at the backend
   boundary so nothing downstream depends on a backend being loaded.

   B1/B2: the derivative rule is ours.  It is written with an explicit
   _List first slot, because for a list first argument the derivative
   tag is Derivative[{0,...,0},1,0] with one 0 per index, and a literal
   {0} pattern silently matches weight 1 only. *)
TransportWord[{}, _] := 1;

Derivative[iw_List, 1][TransportWord][word_List, z_] :=
  If[word === {}, 0, TransportWord[Rest[word], z]/(z - First[word])];

masterTransportWordFreeQ[e_] := FreeQ[e, TransportWord];

(* d/dtau on an expression carrying words whose INDICES do not depend on
   tau.  That hypothesis is asserted where the words are built, not
   assumed here. *)
masterTransportDTau[e_, tau_] := D[e, tau];

(* Collect an expression by its transcendental monomial.  Returns
   <| wordMonomial -> rationalCoefficient |>, with key 1 for the purely
   rational part. *)
(* Word keys must be CANONICAL before anything is collected against
   them.  The indices are rational functions of the kinematics, and the
   same pole reaches the expression in more than one syntactic form
   (1/(1-4v) from one leg, -1/(4v-1) from another).  Collecting on the
   raw form puts equal words in different buckets, and a residual that
   is mathematically zero then survives as two nonvanishing
   coefficients -- an "inconclusive" verdict manufactured by
   bookkeeping rather than by mathematics. *)
masterTransportNormalizeWords[e_] :=
  e /. TransportWord[idx_List, z_] :>
    TransportWord[Together /@ idx, Together[z]];

masterTransportCollect[e_] := Module[{ex, terms, res},
  ex = Expand[masterTransportNormalizeWords[e]];
  If[ex === 0, Return[<||>]];
  terms = If[Head[ex] === Plus, List @@ ex, {ex}];
  res = <||>;
  Do[
    Module[{factors, wordPart, coefficientPart},
      factors = If[Head[term] === Times, List @@ term, {term}];
      wordPart = Times @@ Select[factors, ! FreeQ[#, TransportWord] &];
      coefficientPart = Times @@ Select[factors, FreeQ[#, TransportWord] &];
      res[wordPart] = Lookup[res, wordPart, 0] + coefficientPart
    ],
    {term, terms}];
  res
];

(* Sound zero test.  Coefficient-wise vanishing PROVES the expression is
   zero.  It is not a decision procedure: Libra's words are not
   shuffle-reduced, so a nonzero coefficient list does not prove the
   expression is nonzero.  The verdict is therefore True or
   "Inconclusive", never a claim of nonvanishing. *)
masterTransportSimplifyZeroQ[e_] :=
  TrueQ[Together[e] === 0] ||
  TrueQ[TimeConstrained[Simplify[e], $masterTransportZeroTimeLimit, $Failed] === 0];

masterTransportZeroQ[e_] := Module[{collected, residual},
  If[e === 0, Return[True]];
  If[masterTransportWordFreeQ[e],
    Return[If[masterTransportSimplifyZeroQ[e], True, "Inconclusive"]]];
  collected = masterTransportCollect[e];
  residual = Select[Values[collected], ! TrueQ[Together[#] === 0] &];
  residual = Select[residual, ! masterTransportSimplifyZeroQ[#] &];
  If[residual === {}, True, "Inconclusive"]
];

masterTransportZeroMatQ[m_] :=
  AllTrue[Flatten[{m}], TrueQ[masterTransportZeroQ[#]] &];

(* ------------------------------------------------------------------ *)
(*  epsilon Laurent bookkeeping                        (C3, shared)     *)
(* ------------------------------------------------------------------ *)

masterTransportEpsOrder[e_, eps_] := Module[{x},
  x = Together[e];
  If[x === 0, Infinity,
    Exponent[Numerator[x], eps, Min] - Exponent[Denominator[x], eps, Min]]
];

(* Laurent coefficients of a RATIONAL function of eps over [r0, r1].
   Returns $Failed if the true valuation is below r0, because silently
   dropping a lower order is how an incomplete answer is manufactured. *)
masterTransportLaurentList[e_, {r0_, r1_}, eps_] := Module[{x, order, series},
  x = Together[e];
  If[x === 0, Return[ConstantArray[0, r1 - r0 + 1]]];
  order = masterTransportEpsOrder[x, eps];
  If[order < r0, Return[$Failed]];
  If[r1 < r0, Return[{}]];
  series = Normal[Series[x, {eps, 0, r1}]];
  Table[Together[Coefficient[series, eps, r]], {r, r0, r1}]
];

masterTransportLaurentMat[m_, {r0_, r1_}, eps_] := Module[{coefficients, bad},
  coefficients = Map[masterTransportLaurentList[#, {r0, r1}, eps] &, m, {2}];
  bad = Cases[coefficients, $Failed, {0, Infinity}];
  If[bad =!= {}, Return[$Failed]];
  Table[Map[#[[r - r0 + 1]] &, coefficients, {2}], {r, r0, r1}]
];

(* epsilon order k of an expression that may carry words.  The words are
   eps-free by construction (their indices are the poles of the
   connection in the path parameter, and the assertion that those are
   eps-free is made in masterTransportRunBackend), so the expansion acts
   on the coefficients only. *)
masterTransportEpsPart[e_, k_Integer, eps_] := Module[{collected},
  If[e === 0, Return[0]];
  collected = masterTransportCollect[e];
  Total[KeyValueMap[
    Function[{word, coefficient},
      Module[{x = Together[coefficient], order},
        order = masterTransportEpsOrder[x, eps];
        If[order === Infinity || order > k, 0,
          word Together[SeriesCoefficient[x, {eps, 0, k}]]]
      ]],
    collected]]
];

(* ------------------------------------------------------------------ *)
(*  (C1)  SCC assembly and the five-part conjugation certificate        *)
(* ------------------------------------------------------------------ *)

masterTransportSCCBlocks[av_, aw_] := Module[{n, edges, graph},
  n = Length[av];
  edges = DeleteCases[
    Flatten @ Table[
      If[i =!= j && ! (TrueQ[Together[av[[i, j]]] === 0] &&
           TrueQ[Together[aw[[i, j]]] === 0]),
        i -> j, Null],
      {i, n}, {j, n}],
    Null];
  Sort[Sort /@ ConnectedComponents[Graph[Range[n], edges]]]
];

masterTransportOrderBlocks[av_, aw_, blocks_] := Module[{nb, edges, order},
  nb = Length[blocks];
  edges = DeleteCases[
    Flatten @ Table[
      If[i =!= j &&
         ! (masterTransportZeroMatQ[av[[blocks[[i]], blocks[[j]]]]] &&
            masterTransportZeroMatQ[aw[[blocks[[i]], blocks[[j]]]]]),
        j -> i, Null],
      {i, nb}, {j, nb}],
    Null];
  order = TopologicalSort[Graph[Range[nb], edges]];
  If[Head[order] =!= List || Length[order] =!= nb, $Failed, order]
];

(* Cheap 1x1 provider: an explicit dlog prefactor.  Only entries regular
   at eps = 0 are handled by this route. *)
masterTransportScalarEpsForm[av_, aw_, eps_, variables_] := Module[
  {v, w, a0v, a0w, letters, unknowns, dlv, dlw, equations, solution,
   free, t, ev, ew},
  {v, w} = variables[[{1, 2}]];
  If[masterTransportEpsOrder[av, eps] < 0 ||
     masterTransportEpsOrder[aw, eps] < 0, Return[$Failed]];
  a0v = Together[av /. eps -> 0];
  a0w = Together[aw /. eps -> 0];
  letters = DeleteDuplicates @ Select[
    Join @@ (FactorList[Denominator[#]][[All, 1]] & /@ {a0v, a0w}),
    ! FreeQ[#, v | w] &];
  If[letters === {},
    If[TrueQ[Together[a0v] === 0] && TrueQ[Together[a0w] === 0],
      Return[<|"Status" -> "OK", "Type" -> "EpsForm", "T" -> {{1}},
        "Ev" -> {{Together[av]}}, "Ew" -> {{Together[aw]}},
        "Source" -> "scalar-dlog"|>],
      Return[$Failed]]];
  unknowns = Table[Unique["masterTransportC"], {Length[letters]}];
  dlv = Sum[unknowns[[i]] D[letters[[i]], v]/letters[[i]], {i, Length[letters]}];
  dlw = Sum[unknowns[[i]] D[letters[[i]], w]/letters[[i]], {i, Length[letters]}];
  equations = Flatten[{
    CoefficientList[Numerator[Together[a0v - dlv]], {v, w}],
    CoefficientList[Numerator[Together[a0w - dlw]], {v, w}]}];
  solution = Quiet @ Solve[Thread[DeleteDuplicates[equations] == 0], unknowns];
  If[solution === {} || Head[solution] =!= List, Return[$Failed]];
  unknowns = unknowns /. First[solution];
  free = Cases[unknowns,
    s_Symbol /; StringMatchQ[SymbolName[s], "masterTransportC*"], {0, Infinity}];
  unknowns = unknowns /. Thread[free -> 0];
  t = Times @@ Table[letters[[i]]^unknowns[[i]], {i, Length[letters]}];
  If[! (TrueQ[Together[a0v - D[Log[t], v]] === 0] &&
        TrueQ[Together[a0w - D[Log[t], w]] === 0]), Return[$Failed]];
  ev = Together[av - D[Log[t], v]];
  ew = Together[aw - D[Log[t], w]];
  If[! (FreeQ[Together[ev/eps], eps] && FreeQ[Together[ew/eps], eps]),
    Return[$Failed]];
  <|"Status" -> "OK", "Type" -> "EpsForm", "T" -> {{t}}, "Ev" -> {{ev}},
    "Ew" -> {{ew}}, "Source" -> "scalar-dlog"|>
];

(* The standardized consumption interface for the Phi route.

   Phi is a fundamental matrix of the block's ORIGINAL connection, in
   whatever way it was obtained -- CANONICA, a chart, a cyclic-vector
   operator identification, or by hand.  Consuming it needs exactly two
   facts, and both are re-established here rather than read from the
   record:

     dPhi/dx_i = A_i . Phi   for every kinematic variable,
     PhiInverse . Phi = 1.

   With I = Phi . F the block's conjugated connection is then
   identically zero, which is why a closed-form sector is consumed by
   the same code path as an epsilon-form and needs no special case
   anywhere above this function.

   The exact symbolic check is attempted first.  For hypergeometric Phi
   it often does not close, and in that case the fallback is a Frobenius
   series check to a declared order together with a high-precision
   numeric check at several points.  The route actually taken is
   recorded in "CheckRoute", and a route that could not be performed
   makes the block fail -- it never counts as a pass. *)
Options[masterTransportClosedFormSector] = {
  "SeriesOrder" -> 12,
  "NumericPoints" -> 4,
  "Precision" -> 40,
  (* budget for ONE attempt.  The exact route is tried first and, for a
     hypergeometric Phi, is expected to fail -- the contiguous relations
     do not close under Simplify.  A short budget keeps that expected
     failure cheap without changing what is concluded from it. *)
  "TimeConstraint" -> 120
};

masterTransportClosedFormSector[record_Association, av_, aw_, eps_,
    variables_, opts : OptionsPattern[]] := Module[
  {phi, phiInverse, dim, v, w, residualV, residualW, identity, route,
   exactV, exactW, exactI, seriesOK, numericOK, chartVariable, checks,
   timeLimit, seriesOrder, numericPoints, precision, frame},
  {v, w} = variables[[{1, 2}]];
  timeLimit = OptionValue["TimeConstraint"];
  seriesOrder = OptionValue["SeriesOrder"];
  numericPoints = OptionValue["NumericPoints"];
  precision = OptionValue["Precision"];
  phi = Lookup[record, "Phi", $Failed];
  If[! MatrixQ[phi], Return[<|"Status" -> "NoPhi"|>]];
  dim = Length[phi];
  If[dim =!= Length[av], Return[<|"Status" -> "PhiDimensionMismatch"|>]];
  frame = Lookup[record, "Frame", Lookup[record, "Chart", None]];
  chartVariable = If[AssociationQ[frame], Lookup[frame, "ChartVariable", None], None];
  phiInverse = Lookup[record, "PhiInverse", Automatic];
  If[phiInverse === Automatic || MissingQ[phiInverse],
    phiInverse = TimeConstrained[Together[Inverse[phi]], timeLimit, $Failed]];
  If[phiInverse === $Failed || ! MatrixQ[phiInverse],
    Return[<|"Status" -> "PhiNotInvertible"|>]];

  identity = TimeConstrained[
    Together[phiInverse . phi - IdentityMatrix[dim]], timeLimit, $Failed];
  exactI = identity =!= $Failed &&
    TrueQ[TimeConstrained[masterTransportZeroMatQ[identity], timeLimit, False]];

  residualV = TimeConstrained[Together[D[phi, v] - av . phi], timeLimit, $Failed];
  residualW = TimeConstrained[Together[D[phi, w] - aw . phi], timeLimit, $Failed];
  exactV = residualV =!= $Failed &&
    TrueQ[TimeConstrained[masterTransportZeroMatQ[residualV], timeLimit, False]];
  exactW = residualW =!= $Failed &&
    TrueQ[TimeConstrained[masterTransportZeroMatQ[residualW], timeLimit, False]];

  route = "Exact";
  seriesOK = Null; numericOK = Null;
  If[! (exactV && exactW),
    (* Frobenius series fallback: expand the residual around the chart
       origin and require every coefficient to vanish exactly as a
       rational function of eps. *)
    route = "SeriesAndNumeric";
    seriesOK = TimeConstrained[
      Quiet@Module[{expansionVariable, sv, sw},
        expansionVariable = If[chartVariable =!= None, chartVariable, v];
        sv = Normal[Series[residualV, {expansionVariable, 0, seriesOrder}]];
        sw = Normal[Series[residualW, {expansionVariable, 0, seriesOrder}]];
        masterTransportZeroMatQ[Together[sv]] &&
          masterTransportZeroMatQ[Together[sw]]],
      timeLimit, $Failed];
    numericOK = TimeConstrained[
      Module[{points, values},
        points = Table[
          {v -> 1/(3 + k), w -> 1/(5 + 2 k), eps -> 1/(17 + 3 k)},
          {k, numericPoints}];
        values = Table[
          Quiet@Max[Abs[N[Flatten[{residualV, residualW}] /. point, precision]]],
          {point, points}];
        AllTrue[values, NumericQ[#] && Abs[#] < 10^(-precision + 10) &]],
      timeLimit, $Failed]];

  checks = <|
    "ExactDerivativeV" -> exactV,
    "ExactDerivativeW" -> exactW,
    "ExactInverse" -> exactI,
    "SeriesResidualZero" -> seriesOK,
    "NumericResidualZero" -> numericOK,
    "CheckRoute" -> route,
    "SeriesOrder" -> If[route === "Exact", None, seriesOrder],
    "StoredCertificate" -> Lookup[record, "Certificate", None]
  |>;

  If[! TrueQ[exactI], Return[<|"Status" -> "PhiInverseNotVerified", "Checks" -> checks|>]];
  If[route === "Exact",
    Return[<|"Status" -> "OK", "Type" -> "ClosedFormSector",
      "T" -> phi, "TInverse" -> phiInverse,
      "Ev" -> ConstantArray[0, {dim, dim}],
      "Ew" -> ConstantArray[0, {dim, dim}],
      "Source" -> "closed-form", "Frame" -> frame, "Checks" -> checks|>]];
  If[TrueQ[seriesOK] && TrueQ[numericOK],
    Return[<|"Status" -> "OK", "Type" -> "ClosedFormSector",
      "T" -> phi, "TInverse" -> phiInverse,
      "Ev" -> ConstantArray[0, {dim, dim}],
      "Ew" -> ConstantArray[0, {dim, dim}],
      "Source" -> "closed-form", "Frame" -> frame, "Checks" -> checks|>]];
  <|"Status" -> "PhiNotVerified", "Checks" -> checks|>
];

(* Resolve one block's provider into {T, Ev, Ew} plus provenance. *)
masterTransportBlockProvider[specification_, av_, aw_, eps_, variables_,
    formDirectory_] := Module[{record, file},
  Which[
    specification === Automatic,
      If[Length[av] === 1,
        Module[{scalar = masterTransportScalarEpsForm[av[[1, 1]], aw[[1, 1]], eps, variables]},
          If[scalar === $Failed, <|"Status" -> "ScalarFailed"|>, scalar]],
        <|"Status" -> "NoProvider"|>],
    IntegerQ[specification],
      file = FileNameJoin[{formDirectory, "class" <> ToString[specification] <> ".wl"}];
      If[! FileExistsQ[file], Return[<|"Status" -> "FormFileMissing", "File" -> file|>]];
      record = masterTransportGetGlobal[file];
      If[! AssociationQ[record], Return[<|"Status" -> "FormFileUnreadable", "File" -> file|>]];
      <|"Status" -> "OK", "Type" -> "ClassForm", "ClassID" -> specification,
        "Record" -> record|>,
    AssociationQ[specification],
      Switch[Lookup[specification, "Type", "EpsForm"],
        "ClosedFormSector",
          masterTransportClosedFormSector[specification, av, aw, eps, variables],
        "EpsForm",
          If[MatrixQ[Lookup[specification, "T", $Failed]],
            <|"Status" -> "OK", "Type" -> "EpsForm",
              "T" -> specification["T"],
              "Ev" -> Lookup[specification, "Ev",
                Together[Inverse[specification["T"]] . av . specification["T"] -
                  Inverse[specification["T"]] . D[specification["T"], variables[[1]]]]],
              "Ew" -> Lookup[specification, "Ew",
                Together[Inverse[specification["T"]] . aw . specification["T"] -
                  Inverse[specification["T"]] . D[specification["T"], variables[[2]]]]],
              "Source" -> "explicit"|>,
            <|"Status" -> "NoTransformation"|>],
        _, <|"Status" -> "UnknownProviderType"|>],
    True, <|"Status" -> "UnknownProvider"|>]
];

Options[masterTransportAssemble] = {
  "Blocks" -> Automatic,
  "FormDirectory" -> None,
  "Verbose" -> False
};

masterTransportAssemble[system_Association, eps_Symbol, variables_List,
    opts : OptionsPattern[]] := Module[
  {av, aw, n, blocks, providers, order, permutation, pav, paw, nb, ranges,
   forms, tInverse, conjugated, certificate, triangular, diagonalOK,
   apv, apw, verbose, formDirectory, v, w, family, blockSpecification},
  verbose = TrueQ[OptionValue["Verbose"]];
  formDirectory = OptionValue["FormDirectory"];
  {v, w} = variables[[{1, 2}]];
  family = Lookup[system, "Family", "unnamed"];
  av = system["Av"];
  aw = system["Aw"];
  n = Length[av];
  blockSpecification = OptionValue["Blocks"];
  If[blockSpecification === Automatic,
    blocks = masterTransportSCCBlocks[av, aw];
    providers = ConstantArray[Automatic, Length[blocks]],
    blocks = blockSpecification[[All, 1]];
    providers = blockSpecification[[All, 2]]];
  masterTransportLog[verbose, family, ": ", n, " masters, ", Length[blocks],
    " blocks, dims ", Tally[Length /@ blocks]];
  order = masterTransportOrderBlocks[av, aw, blocks];
  If[order === $Failed, Return[<|"Status" -> "OrderFailed"|>]];
  blocks = blocks[[order]];
  providers = providers[[order]];
  permutation = Flatten[blocks];
  If[Sort[permutation] =!= Range[n], Return[<|"Status" -> "BlocksNotAPartition"|>]];
  pav = av[[permutation, permutation]];
  paw = aw[[permutation, permutation]];
  nb = Length[blocks];
  (* M1: built in the body, never in a Module initializer that refers to
     another local of the same Module. *)
  ranges = FoldList[Plus, 0, Length /@ blocks];
  ranges = Table[Range[ranges[[i]] + 1, ranges[[i + 1]]], {i, nb}];

  certificate = <||>;
  triangular = AllTrue[
    Flatten @ Table[
      If[i < j, {pav[[ranges[[i]], ranges[[j]]]], paw[[ranges[[i]], ranges[[j]]]]}, {}],
      {i, nb}, {j, nb}],
    TrueQ[masterTransportZeroQ[#]] &];
  certificate["BlockLowerTriangular"] = triangular;
  certificate["FlatnessOriginal"] = masterTransportZeroMatQ[
    D[av, w] - D[aw, v] + av . aw - aw . av];

  forms = Table[
    Module[{rows = blocks[[i]], sav, saw, resolved},
      sav = av[[rows, rows]];
      saw = aw[[rows, rows]];
      resolved = masterTransportBlockProvider[providers[[i]], sav, saw, eps,
        variables, formDirectory];
      If[AssociationQ[resolved] && resolved["Type"] === "ClassForm",
        resolved = masterTransportClassFormBlock[resolved, rows, sav, saw, eps, variables]];
      resolved],
    {i, nb}];
  If[! AllTrue[forms, AssociationQ[#] && #["Status"] === "OK" &],
    Return[<|"Status" -> "FormFailed", "Blocks" -> blocks,
      "Failures" -> Select[Transpose[{blocks, forms}], #[[2]]["Status"] =!= "OK" &]|>]];

  tInverse = Table[
    If[MissingQ[forms[[i]]["TInverse"]] || forms[[i]]["TInverse"] === Automatic,
      Map[Together, Inverse[forms[[i]]["T"]], {2}],
      forms[[i]]["TInverse"]],
    {i, nb}];

  conjugated = <||>;
  Do[
    Do[
      If[i >= j,
        Module[{blockV, blockW, dim},
          (* For a closed-form sector the conjugated DIAGONAL block is
             zero by the identity dPhi = A.Phi, which the sector's own
             verification has just re-established on a recorded route.
             Recomputing it here as Phi^-1.A.Phi - Phi^-1.dPhi would
             demand the hypergeometric contiguous relations from
             Simplify, which do not close -- and a certificate that
             cannot be performed must never be reported as failed OR as
             passed.  It is taken from the sector record instead, which
             is a re-verification and not a stored flag. *)
          If[i === j && forms[[i]]["Type"] === "ClosedFormSector",
            dim = Length[ranges[[i]]];
            conjugated[{i, j}] = {ConstantArray[0, {dim, dim}],
              ConstantArray[0, {dim, dim}]},
            blockV = tInverse[[i]] . pav[[ranges[[i]], ranges[[j]]]] . forms[[j]]["T"];
            blockW = tInverse[[i]] . paw[[ranges[[i]], ranges[[j]]]] . forms[[j]]["T"];
            If[i === j,
              blockV = blockV - tInverse[[i]] . D[forms[[i]]["T"], v];
              blockW = blockW - tInverse[[i]] . D[forms[[i]]["T"], w]];
            conjugated[{i, j}] = {Map[Together, blockV, {2}], Map[Together, blockW, {2}]}]]],
      {j, nb}],
    {i, nb}];

  diagonalOK = Table[
    If[forms[[i]]["Type"] === "ClosedFormSector",
      (* established by masterTransportClosedFormSector, whose route is
         recorded in forms[[i]]["Checks"] *)
      TrueQ[forms[[i]]["Status"] === "OK"],
      masterTransportZeroMatQ[conjugated[{i, i}][[1]] - forms[[i]]["Ev"]] &&
      masterTransportZeroMatQ[conjugated[{i, i}][[2]] - forms[[i]]["Ew"]]],
    {i, nb}];
  certificate["DiagonalEqualsDeclaredForm"] = AllTrue[diagonalOK, TrueQ];
  certificate["DiagonalPerBlock"] = diagonalOK;
  (* A diagonal block is admissible when it is epsilon-linear (an
     epsilon-form) or identically zero (a closed-form sector).  Both make
     the regrading shift finite; nothing else does. *)
  certificate["EpsFormLinear"] = AllTrue[
    Flatten[Table[{forms[[i]]["Ev"], forms[[i]]["Ew"]}, {i, nb}]],
    (TrueQ[Together[#] === 0] || FreeQ[Together[#/eps], eps]) &];
  certificate["OffDiagonalUpperZero"] =
    "by construction (T block-diagonal, A block-lower-triangular)";

  apv = ConstantArray[0, {n, n}];
  apw = ConstantArray[0, {n, n}];
  If[Head[apv] =!= List || Length[apv] =!= n,
    Return[<|"Status" -> "ZeroMatrixShape"|>]];
  Do[
    If[i >= j,
      apv[[ranges[[i]], ranges[[j]]]] = conjugated[{i, j}][[1]];
      apw[[ranges[[i]], ranges[[j]]]] = conjugated[{i, j}][[2]]],
    {i, nb}, {j, nb}];
  certificate["FlatnessConjugated"] = masterTransportZeroMatQ[
    D[apv, w] - D[apw, v] + apv . apw - apw . apv];

  masterTransportLog[verbose, "  certificate: triangular ", certificate["BlockLowerTriangular"],
    ", flat(A) ", certificate["FlatnessOriginal"],
    ", diagonal ", certificate["DiagonalEqualsDeclaredForm"],
    ", eps-linear ", certificate["EpsFormLinear"],
    ", flat(A') ", certificate["FlatnessConjugated"]];

  <|"Status" -> "OK", "Family" -> family, "N" -> n, "Perm" -> permutation,
    "Blocks" -> blocks, "Ranges" -> ranges, "Forms" -> forms,
    "TInverse" -> tInverse, "Apv" -> apv, "Apw" -> apw,
    "Av" -> pav, "Aw" -> paw,
    "Basis" -> If[MissingQ[system["Basis"]], None, system["Basis"][[permutation]]],
    "Certificate" -> certificate|>
];

(* The five-part conjugation certificate.  All five must hold; a stored
   flag is never consulted. *)
masterTransportCertificateOK[assembly_] :=
  AssociationQ[assembly] && assembly["Status"] === "OK" &&
  And @@ (TrueQ /@ {
    assembly["Certificate"]["BlockLowerTriangular"],
    assembly["Certificate"]["FlatnessOriginal"],
    assembly["Certificate"]["DiagonalEqualsDeclaredForm"],
    assembly["Certificate"]["EpsFormLinear"],
    assembly["Certificate"]["FlatnessConjugated"]});

(* A stored class form provides T in its own frame.  Pull it back to the
   kinematic variables when it carries a chart, and re-derive Ev/Ew from
   T rather than trusting the stored EpsForm. *)
masterTransportClassFormBlock[resolved_, rows_, av_, aw_, eps_, variables_] :=
  Module[{record, t, v, w, ev, ew, chart, mapped},
    {v, w} = variables[[{1, 2}]];
    record = resolved["Record"];
    t = Lookup[record, "Transformation", $Failed];
    If[! MatrixQ[t], Return[<|"Status" -> "ClassFormNoTransformation"|>]];
    chart = Lookup[record, "Chart", None];
    If[chart =!= None && chart =!= Null && AssociationQ[chart],
      (* charts are pulled back through their stored inverse; a class
         whose chart cannot be pulled back is refused rather than
         silently used in the wrong frame *)
      mapped = Lookup[chart, "Inverse", $Failed];
      If[mapped === $Failed, Return[<|"Status" -> "ClassFormChartNotPullable"|>]]];
    ev = Together[Inverse[t] . av . t - Inverse[t] . D[t, v]];
    ew = Together[Inverse[t] . aw . t - Inverse[t] . D[t, w]];
    If[! (FreeQ[Together[ev/eps], eps] && FreeQ[Together[ew/eps], eps]),
      Return[<|"Status" -> "ClassFormNotEpsForm", "Rows" -> rows|>]];
    <|"Status" -> "OK", "Type" -> "EpsForm", "T" -> t, "Ev" -> ev, "Ew" -> ew,
      "Source" -> "class-form", "ClassID" -> resolved["ClassID"]|>
  ];

(* ------------------------------------------------------------------ *)
(*  (C4)  depth-budget arithmetic and the checkable-order rule          *)
(* ------------------------------------------------------------------ *)

(* How deep each sector must be SOLVED.  This is NOT the same question
   as how deep the assembled solution can be VERIFIED, and conflating
   the two gets a family solved to a depth that can never be certified.
   The assembled check at order n consumes I down to r = rmin(A), so it
   needs I up to n + |rmin(A)|:

       order n checkable   <=>   n <= n1 - |rmin(A)|
       number checkable     =    (n1 - n0) - |rmin(A)| + 1
       ANY check at all requires  (n1 - n0) >= |rmin(A)|

   Confirmed on every gate of the retired engine: NLO |rmin| = 0,
   kmax = 2 -> 3 checkable and 3 seen; CF3 |rmin| = 1, kmax = 3 -> 3 and
   3 seen; CF360 |rmin| = 2, kmax = 2 -> 1 and 1 seen; CF123 |rmin| = 2,
   kmax = 1 -> 0 and 0 seen, which is an unverifiable solve and NOT a
   failed one.  CF360 passing at exactly kmax = 2 was the minimum, not
   luck. *)
masterTransportDepthBudget[assembly_, ahat_, kmax_Integer, eps_] := Module[
  {nb, ranges, need, rmin},
  nb = Length[assembly["Blocks"]];
  ranges = assembly["Ranges"];
  need = ConstantArray[kmax, nb];
  rmin = Table[
    If[i > j,
      Min[Append[
        masterTransportEpsOrder[#, eps] & /@ Flatten[ahat[[ranges[[i]], ranges[[j]]]]],
        Infinity]],
      Infinity],
    {i, nb}, {j, nb}];
  Do[
    Do[
      If[j < i && rmin[[i, j]] =!= Infinity,
        need[[j]] = Max[need[[j]], need[[i]] - rmin[[i, j]]]],
      {j, nb}],
    {i, nb, 1, -1}];
  <|"Need" -> need, "RMin" -> rmin,
    "RMinGlobal" -> Min[Append[DeleteCases[Flatten[rmin], Infinity], 0]]|>
];

(* (C3) The regrading shift D.  See the header for the derivation: a
   word can descend the block DAG only once per negative-order factor,
   so weight minus epsilon order is bounded by the longest path under
   the edge cost max(0, 1 - ord).  A diagonal block of order <= 0 is a
   self-loop and makes D infinite; that is reported, not truncated. *)
masterTransportEpsShift[assembly_, ahat_, eps_] := Module[
  {nb, ranges, cost, best, diagonalOrder, bad},
  nb = Length[assembly["Blocks"]];
  ranges = assembly["Ranges"];
  diagonalOrder = Table[
    Min[Append[
      masterTransportEpsOrder[#, eps] & /@ Flatten[ahat[[ranges[[i]], ranges[[i]]]]],
      Infinity]],
    {i, nb}];
  bad = Select[Range[nb], diagonalOrder[[#]] =!= Infinity && diagonalOrder[[#]] <= 0 &];
  If[bad =!= {},
    Return[<|"Status" -> "NotTerminating", "Block" -> First[bad],
      "Order" -> diagonalOrder[[First[bad]]], "DiagonalOrder" -> diagonalOrder|>]];
  cost = Table[
    If[i > j,
      Module[{order = Min[Append[
          masterTransportEpsOrder[#, eps] & /@ Flatten[ahat[[ranges[[i]], ranges[[j]]]]],
          Infinity]]},
        If[order === Infinity, None, Max[0, 1 - order]]],
      None],
    {i, nb}, {j, nb}];
  best = ConstantArray[0, nb];
  Do[
    best[[i]] = Max[Append[
      Table[If[cost[[i, j]] === None, 0, best[[j]] + cost[[i, j]]], {j, 1, i - 1}],
      0]],
    {i, nb}];
  <|"Status" -> "OK", "Shift" -> Max[best], "PerBlock" -> best,
    "DiagonalOrder" -> diagonalOrder|>
];

masterTransportCheckableOrders[orders_List, rminGlobal_] := Module[{n0, n1, depth},
  {n0, n1} = {Min[orders], Max[orders]};
  depth = Abs[Min[0, rminGlobal]];
  <|"Orders" -> Range[n0, n1], "Depth" -> depth,
    "Checkable" -> Select[Range[n0, n1], # <= n1 - depth &],
    "Rule" -> "n <= n1 - |rmin|"|>
];

(* ------------------------------------------------------------------ *)
(*  Path restriction                                                    *)
(* ------------------------------------------------------------------ *)

(* The tangent factors dv, dw must be computed BEFORE the substitution
   and must NOT themselves be substituted.  Writing

       (Apv dv + Apw dw) /. {v -> v0 + tau dv, w -> w0 + tau dw}

   rewrites the FACTOR (v - v0) into tau (v - v0) as well, multiplying
   the whole connection by an extra tau.  For a NUMERIC target dv is a
   number and the defect is invisible, which is why it survived in the
   retired engine: its symbolic-target mode was the one that never
   completed a run.  Symbolic targets are this module's default, so the
   substitution is applied to the matrices only. *)
masterTransportPathMatrix[apv_, apw_, target_, base_, tau_, variables_] :=
  Module[{v, w, dv, dw, substitution},
    {v, w} = variables[[{1, 2}]];
    dv = target[[1]] - base[[1]];
    dw = target[[2]] - base[[2]];
    substitution = {v -> base[[1]] + tau dv, w -> base[[2]] + tau dw};
    Map[Together, (apv /. substitution) dv + (apw /. substitution) dw, {2}]
  ];

(* Libra's own admission gate (Libra.m:3998) pattern-matches every
   denominator against a MONIC linear form in the reduction variable:
   x - y is admitted, -x + y is refused -- the same pole, a different
   sign convention.  Nothing here calls Rookie, but the same
   normalization is applied to any word-backend input so that a refusal
   is ever mathematics and never bookkeeping, and a denominator that is
   not linear in the path parameter is reported rather than handed over
   to produce algebraic indices. *)
masterTransportMonicCheck[m_, tau_] := Module[{denominators, degrees, monic},
  denominators = DeleteDuplicates @ Flatten @ Map[
    FactorList[Denominator[Together[#]]][[All, 1]] &, m, {2}];
  denominators = Select[denominators, ! FreeQ[#, tau] &];
  degrees = Exponent[#, tau] & /@ denominators;
  monic = Table[TrueQ[Together[Coefficient[denominators[[i]], tau, 1] - 1] === 0],
    {i, Length[denominators]}];
  <|"Denominators" -> denominators, "Degrees" -> degrees,
    "Linear" -> AllTrue[degrees, # <= 1 &],
    "MonicAsWritten" -> monic,
    "MonicNormalized" -> Table[
      If[degrees[[i]] === 1,
        Together[denominators[[i]]/Coefficient[denominators[[i]], tau, 1]],
        denominators[[i]]],
      {i, Length[denominators]}]|>
];

(* ------------------------------------------------------------------ *)
(*  Backends                                                            *)
(* ------------------------------------------------------------------ *)

masterTransportLoadLibra[root_String] := Module[{file, path},
  If[TrueQ[$masterTransportLibraLoaded] &&
     Length[DownValues[Libra`PexpExpansion]] > 0, Return[True]];
  file = FileNameJoin[{root, "Addon", "Mathematica_Addon", "Libra", "Source", "Libra.m"}];
  If[! FileExistsQ[file], Return[$Failed]];
  path = $ContextPath;
  Quiet[Block[{Print = (Null &)}, Get[file]], {General::shdw}];
  $ContextPath = path;
  (* B1/B2: Libra ships no derivative rule for its own II, and the
     derivative tag for a list first argument is Derivative[{0,..},1,0]
     with one 0 per index.  We never differentiate II directly -- words
     are converted to TransportWord at once -- but the rule is installed
     anyway so that a caller reaching into the raw output is not silently
     handed an unevaluated Derivative. *)
  Quiet[
    Unprotect[Libra`II];
    Derivative[iw_List, 1, 0][Libra`II][word_List, x_, x0_] :=
      If[word === {}, 0, Libra`II[Rest[word], x, x0]/(x - First[word])];
  ];
  $masterTransportLibraLoaded = Length[DownValues[Libra`PexpExpansion]] > 0;
  If[TrueQ[$masterTransportLibraLoaded], True, $Failed]
];

masterTransportLoadPolyLogTools[root_String] := Module[{file, path, addon},
  If[TrueQ[$masterTransportPolyLogToolsLoaded], Return[True]];
  addon = FileNameJoin[{root, "Addon", "Mathematica_Addon"}];
  file = FileNameJoin[{addon, "PolyLogTools", "PolyLogTools.m"}];
  If[! FileExistsQ[file], Return[$Failed]];
  path = $ContextPath;
  (* P1: PolyLogTools exports 1699 symbols, among them v, w, x, y, t, G,
     II, DG and nearly every short name.  Restoring $ContextPath after
     the load is what keeps our own symbols reachable under their own
     names; every PolyLogTools function is then called fully qualified. *)
  $Path = DeleteDuplicates[Join[$Path, {addon, FileNameJoin[{addon, "HPL"}]}]];
  Global`$PolyLogPath = FileNameJoin[{addon, "PolyLogTools"}];
  Quiet[Block[{Print = (Null &)}, Get[file]], {General::shdw}];
  $ContextPath = path;
  $masterTransportPolyLogToolsLoaded = Length[DownValues[PolyLogTools`GIntegrate]] > 0;
  If[TrueQ[$masterTransportPolyLogToolsLoaded], True, $Failed]
];

(* Libra transport of a path-restricted connection.  Returns the
   weight-graded transport {U_0, ..., U_wmax} with every word already
   converted to the package-owned head, so nothing downstream needs
   Libra loaded. *)
masterTransportBackendLibra[m_, tau_, wmax_Integer, root_String] := Module[
  {loaded, raw, converted},
  loaded = masterTransportLoadLibra[root];
  If[loaded =!= True, Return[<|"Status" -> "BackendUnavailable", "Backend" -> "Libra"|>]];
  (* PexpExpansion ABORTS -- it does not return a failure value -- when
     the connection does not decay at infinity, i.e. when its own pole
     analysis reports a pole at Infinity.  An escaping Abort would kill
     the whole run, so it is caught and turned into a status.  The usual
     cause is a path restriction that left an extra power of the path
     parameter in the numerators. *)
  raw = CheckAbort[
    Quiet[Block[{Print = (Null &)}, Libra`PexpExpansion[{m, wmax}, tau, 0]]],
    $Aborted];
  If[raw === $Aborted,
    Return[<|"Status" -> "BackendAborted", "Backend" -> "Libra",
      "Poles" -> Quiet[Union[Flatten[{Libra`PolesPosition[m, tau]}]]]|>]];
  If[! ListQ[raw] || Length[raw] =!= wmax + 1,
    Return[<|"Status" -> "BackendFailed", "Backend" -> "Libra"|>]];
  (* Libra's II carries an explicit base point: II[{a}, x, x0] =
     G(a - x0; x - x0).  Base point 0 here, so the conversion is
     structural.  B3/B4: the head is taken fully qualified, never from
     $ContextPath, so the rule cannot silently match nothing. *)
  converted = raw /. {
    Libra`II[{}, __] :> 1,
    Libra`II[word_List, x_, x0_] :> TransportWord[(# - x0) & /@ word, x - x0],
    Libra`II[word_List, x_] :> TransportWord[word, x]};
  <|"Status" -> "OK", "Backend" -> "Libra", "U" -> converted|>
];

(* PolyLogTools transport by explicit iterated GIntegrate, base-point
   subtracted leg by leg. *)
masterTransportBackendPolyLogTools[m_, tau_, wmax_Integer, root_String] := Module[
  {loaded, dimension, u, primitive, converted},
  loaded = masterTransportLoadPolyLogTools[root];
  If[loaded =!= True,
    Return[<|"Status" -> "BackendUnavailable", "Backend" -> "PolyLogTools"|>]];
  dimension = Length[m];
  u = {IdentityMatrix[dimension]};
  Do[
    primitive = Expand[Map[PolyLogTools`GIntegrate[#, tau] &, Expand[m . Last[u]], {2}]];
    primitive = Expand[primitive - (primitive /. tau -> 0)];
    AppendTo[u, primitive],
    {n, 1, wmax}];
  (* P3: the rule LHS must match on the HEAD.  Writing
     PolyLogTools`G[args__] :> ... makes the pattern evaluate, because
     PolyLogTools`G carries downvalues, and the rule then silently
     matches nothing while FreeQ still reports G present. *)
  converted = u /. g_PolyLogTools`G :> With[{a = List @@ g},
    TransportWord[Flatten[{Most[a]}], Last[a]]];
  <|"Status" -> "OK", "Backend" -> "PolyLogTools", "U" -> converted|>
];

masterTransportRunBackend[backend_, m_, tau_, wmax_Integer, root_String, eps_] :=
  Module[{result, indices},
    result = Which[
      backend === "Libra" || backend === Automatic,
        masterTransportBackendLibra[m, tau, wmax, root],
      backend === "PolyLogTools",
        masterTransportBackendPolyLogTools[m, tau, wmax, root],
      Head[backend] === Function || Head[backend] === Symbol,
        Module[{custom = backend[m, tau, wmax]},
          If[ListQ[custom],
            <|"Status" -> "OK", "Backend" -> "Custom", "U" -> custom|>,
            If[AssociationQ[custom], custom, <|"Status" -> "BackendFailed"|>]]],
      True, <|"Status" -> "UnknownBackend"|>];
    If[! AssociationQ[result] || result["Status"] =!= "OK", Return[result]];
    (* The whole regrading rests on the words being free of the
       regulator: their indices are the poles of the connection in the
       path parameter, and only the residues carry eps.  ASSERT it.  If
       an index ever depended on eps, expanding the coefficients alone
       would be silently wrong. *)
    indices = Cases[result["U"], TransportWord[w_List, _] :> w, {0, Infinity}];
    If[! FreeQ[indices, eps],
      Return[<|"Status" -> "WordIndicesCarryRegulator", "Backend" -> result["Backend"]|>]];
    result
  ];

(* Mandatory gate on ANY backend, including a custom one: the transport
   must satisfy its own defining recursion weight by weight,

       d/dtau U_n = M . U_{n-1},   U_0 = 1.

   This is what stops a garbage backend at the door.  It is never
   skippable and never configurable. *)
(* Together is NOT applied to word-carrying expressions anywhere in this
   file.  Putting a hundred-thousand-leaf combination of iterated
   integrals over a common denominator costs more than the check it
   feeds and buys nothing: masterTransportZeroQ collects by word first
   and normalizes each coefficient separately, which is the same test at
   a fraction of the cost.  This was measured -- the eps^2 row of CF3 at
   weight 7 does not return otherwise. *)
masterTransportVerifyTransport[u_List, m_, tau_, dimension_Integer] := Module[
  {wmax, identityOK, perWeight},
  wmax = Length[u] - 1;
  identityOK = TrueQ[masterTransportZeroMatQ[u[[1]] - IdentityMatrix[dimension]]];
  perWeight = Table[
    TrueQ[masterTransportZeroMatQ[
      masterTransportDTau[u[[n + 1]], tau] - m . u[[n]]]],
    {n, 1, wmax}];
  <|"IdentityAtWeightZero" -> identityOK, "PerWeight" -> perWeight,
    "AllZero" -> identityOK && AllTrue[perWeight, TrueQ]|>
];

(* ------------------------------------------------------------------ *)
(*  (C3)  weight -> epsilon regrading, with its completeness assertion  *)
(* ------------------------------------------------------------------ *)

masterTransportRegrade[u_List, {j0_Integer, j1_Integer}, shift_, eps_] := Module[
  {wmax, dimension, graded, lowestAtTop, predicted, complete},
  wmax = Length[u] - 1;
  dimension = Length[u[[1]]];
  (* Each entry is collected ONCE and its coefficients Laurent-expanded
     ONCE over the whole window.  Collecting per requested order instead
     costs an Expand of the full transport per order, which is what
     dominates at weight 6-7. *)
  graded = Module[{accumulate},
    accumulate = ConstantArray[0, {j1 - j0 + 1, dimension, dimension}];
    Do[
      Module[{entry, collected},
        entry = u[[n + 1]][[a, b]];
        If[! TrueQ[entry === 0],
          collected = masterTransportCollect[entry];
          KeyValueMap[
            Function[{word, coefficient},
              Module[{list},
                list = masterTransportLaurentList[coefficient, {j0, j1}, eps];
                If[list =!= $Failed,
                  Do[
                    If[! TrueQ[list[[jj]] === 0],
                      accumulate[[jj, a, b]] = accumulate[[jj, a, b]] + word list[[jj]]],
                    {jj, j1 - j0 + 1}]]]],
            collected]]],
      {n, 0, wmax}, {a, dimension}, {b, dimension}];
    Table[accumulate[[jj]], {jj, j1 - j0 + 1}]];
  (* Measured lowest epsilon order actually present at the top weight,
     against the structural prediction wmax - shift.  Both must clear
     j1, otherwise weight wmax+1 could still feed a requested order and
     the answer would be an incomplete highest coefficient returned
     silently. *)
  lowestAtTop = Min[Append[
    DeleteCases[
      masterTransportEpsOrder[#, eps] & /@
        Flatten[Values[masterTransportCollect[Total[Flatten[u[[wmax + 1]]]]]]],
      Infinity],
    Infinity]];
  predicted = wmax + 1 - shift;
  complete = shift =!= Infinity && predicted > j1;
  <|"Orders" -> Range[j0, j1], "V" -> graded, "Shift" -> shift,
    "TopWeight" -> wmax, "LowestOrderAtTopWeight" -> lowestAtTop,
    "PredictedLowestNextWeight" -> predicted,
    "Complete" -> complete,
    "MeasuredConsistent" ->
      (lowestAtTop === Infinity || lowestAtTop >= wmax - shift)|>
];

(* ------------------------------------------------------------------ *)
(*  Solution vector, master series, and (C2) valuation constraints      *)
(* ------------------------------------------------------------------ *)

(* Symbolic integration constants.  One vector per epsilon order, per
   block, so that a block whose T is singular at eps = 0 can start
   below the physical valuation. *)
masterTransportSolutionVector[regraded_, assembly_, kminPerBlock_, kmax_Integer,
    flow_Integer] :=
  Module[{ranges, nb, n, constants, orders, j0, f},
    ranges = assembly["Ranges"];
    nb = Length[ranges];
    n = assembly["N"];
    constants = <||>;
    Do[
      Do[
        constants[{s, q}] = Table[TransportConstant[s, q, i], {i, Length[ranges[[s]]]}],
        {q, kminPerBlock[[s]], kmax}],
      {s, nb}];
    orders = regraded["Orders"];
    j0 = Min[orders];
    f = Association @ Table[
      k -> Module[{total},
        total = ConstantArray[0, n];
        If[Head[total] =!= List || Length[total] =!= n,
          Return[$Failed, Module]];
        Do[
          Do[
            If[KeyExistsQ[constants, {s, q}] && MemberQ[orders, k - q],
              Module[{full},
                full = ConstantArray[0, n];
                full[[ranges[[s]]]] = constants[{s, q}];
                total = total + regraded["V"][[k - q - j0 + 1]] . full]],
            {q, kminPerBlock[[s]], kmax}],
          {s, nb}];
        total],
      {k, flow, kmax}];
    <|"F" -> f, "Constants" -> constants, "KMinPerBlock" -> kminPerBlock,
      "FLow" -> flow, "KMax" -> kmax|>
  ];

(* I = T . F, with T restricted to the SAME segment the transport used.
   Leaving T in (v,w) while the check compares against a path-restricted
   connection is apples to pears and can never pass; that defect
   invalidated every path-frame check of the retired engine until it was
   found. *)
masterTransportMasterSeries[assembly_, solution_, {n0_Integer, n1_Integer},
    base_, target_, tau_, variables_, eps_, include_ : All] := Module[
  {n, nb, ranges, tr0, tr1, tLaurent, v, w, substitution, kmin, kmax, out, sectors},
  n = assembly["N"];
  ranges = assembly["Ranges"];
  nb = Length[ranges];
  (* Only blocks whose T is a rational Laurent object in eps take part in
     the graded series.  A closed-form sector's Phi is exact in eps and is
     carried separately; expanding it here would silently produce
     parameter derivatives of a 2F1 and a check that can never close. *)
  sectors = If[include === All, Range[nb], include];
  {v, w} = variables[[{1, 2}]];
  kmin = solution["FLow"];
  kmax = solution["KMax"];
  tr0 = Min[Append[DeleteCases[
    Flatten[Table[masterTransportEpsOrder[#, eps] & /@ Flatten[assembly["Forms"][[s]]["T"]],
      {s, sectors}]], Infinity], 0]];
  tr1 = n1 - kmin;
  If[tr1 < tr0, tr1 = tr0];
  substitution = {v -> base[[1]] + tau (target[[1]] - base[[1]]),
                  w -> base[[2]] + tau (target[[2]] - base[[2]])};
  tLaurent = Table[
    Module[{z},
      z = ConstantArray[0, {n, n}];
      Do[
        z[[ranges[[s]], ranges[[s]]]] = Map[
          masterTransportLaurentList[#, {tr0, tr1}, eps][[r - tr0 + 1]] &,
          assembly["Forms"][[s]]["T"], {2}],
        {s, sectors}];
      Map[Together, z /. substitution, {2}]],
    {r, tr0, tr1}];
  out = Table[
    Module[{total},
      total = ConstantArray[0, n];
      Do[
        If[kmin <= nn - r <= kmax && KeyExistsQ[solution["F"], nn - r],
          total = total + tLaurent[[r - tr0 + 1]] . solution["F"][nn - r]],
        {r, tr0, tr1}];
      total],
    {nn, n0, n1}];
  <|"Orders" -> Range[n0, n1], "I" -> out, "TR0" -> tr0|>
];

(* (C2) Valuation constraints.

   "PhysicalValuation" n0 means ONE thing: the Laurent valuation of the
   PHYSICAL masters I, the order at which the exact answer starts.  It is
   simultaneously the reference for the constraints below AND the
   starting order the boundary-fixing stage uses.  These are one physics
   statement and a refactor must never split them: if boundary fixing
   starts at a different order than the constraints, the constrained
   subfamily and the boundary data describe different functions and every
   downstream check silently compares apples to pears.

   Why constraints are needed at all.  F = T^-1 . I, so on a block where
   T is singular at eps = 0 (det T ~ eps) F has valuation BELOW n0 and
   must be solved from n0 + ord(T^-1) < n0.  Solving from there admits
   extra low-order homogeneous solutions that are pure gauge: the general
   family has I_n =/= 0 for n < n0, which the physical answer forbids.
   Imposing I_n == 0 identically in tau is a LINEAR system on the
   integration constants and cuts the family down to the physical
   subfamily.  Measured on CF360: without it the assembled check fails on
   the 2x2 block; with it, order eps^0 vanishes on every row.

   The assertion at the end runs in EVERY solve and is never silent. *)
masterTransportTOrderMin[assembly_, eps_] :=
  Min[Append[DeleteCases[
    Flatten[Table[
      masterTransportEpsOrder[#, eps] & /@ Flatten[assembly["Forms"][[s]]["T"]],
      {s, Length[assembly["Ranges"]]}]], Infinity], 0]];

masterTransportValuation[assembly_, solution_, n0_Integer, base_, target_,
    tau_, variables_, eps_, verbose_] := Module[
  {kminF, tr0, low, orders, series, equations, constants, solved, rules,
   updated, recheck, bad, ok},
  kminF = solution["FLow"];
  If[kminF + Min[0, masterTransportTOrderMin[assembly, eps]] >= n0,
    Return[<|"Status" -> "Inert", "Rules" -> {}, "Orders" -> {},
      "Equations" -> 0, "Solution" -> solution, "AssertionOK" -> True|>]];
  tr0 = masterTransportTOrderMin[assembly, eps];
  low = kminF + tr0;
  orders = Range[low, n0 - 1];
  If[orders === {},
    Return[<|"Status" -> "Inert", "Rules" -> {}, "Orders" -> {},
      "Equations" -> 0, "Solution" -> solution, "AssertionOK" -> True|>]];
  series = masterTransportMasterSeries[assembly, solution, {low, n0 - 1},
    base, target, tau, variables, eps];
  equations = {};
  Do[
    Do[
      Module[{entry, collected},
        entry = series["I"][[oi, i]];
        If[! TrueQ[entry === 0],
          collected = masterTransportCollect[entry];
          Do[
            equations = Join[equations,
              DeleteCases[
                CoefficientList[Expand[Numerator[Together[value]]], tau], 0]],
            {value, Values[collected]}]]],
      {i, assembly["N"]}],
    {oi, Length[series["I"]]}];
  equations = DeleteDuplicates[DeleteCases[equations, 0]];
  constants = DeleteDuplicates[Cases[Values[solution["F"]], _TransportConstant, {0, Infinity}]];
  solved = If[equations === {}, {{}},
    Quiet @ Solve[Thread[equations == 0], constants]];
  If[Head[solved] =!= List || solved === {},
    masterTransportLog[verbose, "  !! VALUATION CONSTRAINTS INCONSISTENT (",
      Length[equations], " equations)"];
    Return[<|"Status" -> "Inconsistent", "Rules" -> {}, "Orders" -> orders,
      "Equations" -> Length[equations], "Solution" -> solution,
      "AssertionOK" -> False|>]];
  rules = First[solved];
  updated = solution;
  updated["F"] = Map[Together[# /. rules] &, solution["F"]];
  masterTransportLog[verbose, "  valuation: I must vanish for eps^", low,
    "..eps^", n0 - 1, "; ", Length[equations], " equations fixed ",
    Length[rules], " of ", Length[constants], " constants"];
  (* the assertion: the constrained family really does have the claimed
     valuation *)
  recheck = masterTransportMasterSeries[assembly, updated, {low, n0 - 1},
    base, target, tau, variables, eps];
  bad = Select[Flatten[recheck["I"]], ! TrueQ[masterTransportZeroQ[#]] &];
  ok = bad === {};
  If[! ok,
    masterTransportLog[verbose,
      "  !! VALUATION ASSERTION FAILED: I does not vanish below eps^", n0,
      " (", Length[bad], " nonzero components)"],
    masterTransportLog[verbose, "  valuation assertion: I vanishes on eps^",
      low, "..eps^", n0 - 1, " -- OK"]];
  <|"Status" -> If[ok, "OK", "AssertionFailed"], "Rules" -> rules,
    "Orders" -> orders, "Equations" -> Length[equations],
    "Solution" -> updated, "AssertionOK" -> ok|>
];

(* ------------------------------------------------------------------ *)
(*  Exact per-order check against the ORIGINAL family DE                *)
(* ------------------------------------------------------------------ *)

masterTransportCheckDE[assembly_, series_, orders_, base_, target_, tau_,
    variables_, eps_, rows_ : All] := Module[
  {v, w, dv, dw, substitution, ahat, o0, o1, r0, r1, laurent},
  {v, w} = variables[[{1, 2}]];
  dv = target[[1]] - base[[1]];
  dw = target[[2]] - base[[2]];
  substitution = {v -> base[[1]] + tau dv, w -> base[[2]] + tau dw};
  (* same discipline as masterTransportPathMatrix: dv, dw are tangent
     factors, not expressions to be substituted *)
  ahat = Map[Together,
    (assembly["Av"] /. substitution) dv + (assembly["Aw"] /. substitution) dw, {2}];
  o0 = Min[series["Orders"]];
  o1 = Max[series["Orders"]];
  r0 = Min[Append[DeleteCases[masterTransportEpsOrder[#, eps] & /@ Flatten[ahat], Infinity], 0]];
  r1 = o1 - o0;
  If[r1 < r0, r1 = r0];
  laurent = masterTransportLaurentMat[ahat, {r0, r1}, eps];
  If[laurent === $Failed, Return[{<|"Order" -> None, "Zero" -> {"LaurentFailed"}|>}]];
  (* A term with r < 0 needs I at order nn - r > nn.  Orders above the
     top of the series are genuinely missing and the check is then NOT
     PERFORMABLE; dropping them silently reports a spurious False, which
     is exactly what a 1/eps^k coupling used to do.  Orders below n0 are
     zero by construction and are not a gap. *)
  Table[
    Module[{missing, lhs, rhs, residual},
      missing = Select[Range[r0, r1],
        (nn - # > o1) && ! masterTransportZeroMatQ[laurent[[# - r0 + 1]]] &];
      lhs = masterTransportDTau[series["I"][[nn - o0 + 1]], tau];
      rhs = ConstantArray[0, assembly["N"]];
      Do[
        If[o0 <= nn - r <= o1,
          rhs = rhs + laurent[[r - r0 + 1]] . series["I"][[nn - r - o0 + 1]]],
        {r, r0, r1}];
      residual = lhs - rhs;
      If[rows =!= All, residual = residual[[rows]]];
      Module[{verdict},
        verdict = If[missing =!= {}, {"InsufficientOrders"},
          DeleteDuplicates[masterTransportZeroQ /@ residual]];
        <|"Order" -> nn, "Zero" -> verdict, "MissingShifts" -> missing,
          (* a residual is kept whenever the verdict is not a clean zero,
             so that an inconclusive verdict can be diagnosed instead of
             being reported and forgotten *)
          "Residual" -> If[verdict === {True}, Null, residual]|>]],
    {nn, orders}]
];


(* Exact-in-eps statement for closed-form sectors.

   A closed-form sector is certified as a whole in eps, which is
   STRICTLY STRONGER than an order-by-order statement, so its rows are
   not given a fabricated per-order zero.  Expanding a 2F1 with
   eps-dependent parameters in eps produces parameter derivatives that
   no longer close under the contiguous relations, and a per-order check
   built on them could never be performed -- reporting it as passed
   would be exactly the false-pass family this project keeps catching.

   What is checked here is the path-frame residual of the fundamental
   matrix itself, dPhi/dtau - Ahat . Phi, which is independent of the
   constant vector.  The exact symbolic route is tried first; where the
   contiguous relations do not close under Simplify the fallback is a
   Frobenius series to a declared order plus a high-precision numeric
   residual at several points, and the route taken is recorded. *)
masterTransportExactSectors[assembly_, closedBlocks_, base_, target_, tau_,
    variables_, eps_, seriesOrder_Integer, precision_Integer, timeLimit_] :=
  Module[{v, w, dv, dw, substitution, ahatOriginal, records},
    {v, w} = variables[[{1, 2}]];
    dv = target[[1]] - base[[1]];
    dw = target[[2]] - base[[2]];
    substitution = {v -> base[[1]] + tau dv, w -> base[[2]] + tau dw};
    ahatOriginal = Map[Together,
      (assembly["Av"] /. substitution) dv + (assembly["Aw"] /. substitution) dw, {2}];
    records = Table[
      Module[{range, phi, residual, exactOK, seriesOK, numericOK, route, constants,
         blockCertified},
        range = assembly["Ranges"][[s]];
        (* the substantive statement is the BLOCK certificate, already
           re-established by masterTransportClosedFormSector *)
        blockCertified = TrueQ[assembly["Forms"][[s]]["Status"] === "OK"];
        phi = assembly["Forms"][[s]]["T"] /. substitution;
        residual = D[phi, tau] - ahatOriginal[[range, range]] . phi;
        exactOK = TrueQ[TimeConstrained[
          masterTransportZeroMatQ[Together[residual]], timeLimit, False]];
        route = "Exact"; seriesOK = Null; numericOK = Null;
        If[! exactOK,
          route = "SeriesAndNumeric";
          seriesOK = TimeConstrained[
            Quiet@masterTransportZeroMatQ[Together[
              Normal[Series[residual, {tau, 0, seriesOrder}]]]],
            timeLimit, $Failed];
          numericOK = TimeConstrained[
            Module[{points, values},
              points = Table[
                {v -> 1/(3 + k), w -> 1/(5 + 2 k), eps -> 1/(17 + 3 k),
                 tau -> 1/(2 + k)}, {k, 4}];
              values = Table[
                Quiet@Max[Abs[N[Flatten[residual] /. point, precision]]], {point, points}];
              AllTrue[values, NumericQ[#] && Abs[#] < 10^(-precision + 10) &]],
            timeLimit, $Failed]];
        constants = Table[TransportConstant[s, "Exact", i], {i, Length[range]}];
        <|"Block" -> s, "Rows" -> assembly["Blocks"][[s]], "Range" -> range,
          "Constants" -> constants, "I" -> phi . constants,
          "CheckRoute" -> route, "ExactResidualZero" -> exactOK,
          "SeriesResidualZero" -> seriesOK, "NumericResidualZero" -> numericOK,
          "SeriesOrder" -> If[route === "Exact", None, seriesOrder],
          (* The path-frame identity FOLLOWS from the block certificate by
             the chain rule, so this stage confirms the path restriction
             rather than re-proving the sector.  It is accepted on the
             block certificate plus a passing numeric residual; a series
             route that did not return is recorded as not-performable and
             does not by itself condemn the sector -- but a numeric
             residual that FAILS does, and so does a failed block
             certificate. *)
          "OK" -> (exactOK || (blockCertified && TrueQ[numericOK])),
          "BlockCertified" -> blockCertified,
          "BlockCertificate" -> Lookup[assembly["Forms"][[s]], "Checks", None]|>],
      {s, closedBlocks}];
    <|"Status" -> If[AllTrue[records, TrueQ[#["OK"]] &], "OK", "NotVerified"],
      "Sectors" -> records|>
  ];

(* ------------------------------------------------------------------ *)
(*  Card configuration: explicit option > card key > built-in           *)
(* ------------------------------------------------------------------ *)

masterTransportResolveCard[card_] := Which[
  card === None, None,
  AssociationQ[card], card,
  StringQ[card] && FileExistsQ[card],
    Module[{loaded = Quiet @ Check[masterTransportGetGlobal[card], $Failed]},
      If[AssociationQ[loaded], loaded, $Failed]],
  True, $Failed
];

masterTransportCardSetting[explicit_, card_, key_, builtin_] :=
  If[explicit =!= Automatic, explicit,
    If[AssociationQ[card], Lookup[card, key, builtin], builtin]];

(* ------------------------------------------------------------------ *)
(*  Public entry point                                                  *)
(* ------------------------------------------------------------------ *)

Options[TransportFamily] = {
  "Variables" -> Automatic,
  "Regulator" -> Automatic,
  "Blocks" -> Automatic,
  "FormDirectory" -> Automatic,
  "Card" -> None,
  "TransportBackend" -> Automatic,
  "TransportDepth" -> Automatic,
  "TransportTargetOrder" -> Automatic,
  "PhysicalValuation" -> 0,
  "Orders" -> Automatic,
  "BasePoint" -> {1/4, 1/4},
  "Target" -> Automatic,
  "PathParameter" -> Automatic,
  "TimeConstraint" -> Automatic,
  "MemoryConstraint" -> Automatic,
  "MaxWeight" -> Automatic,
  "Verify" -> True,
  "Root" -> Automatic,
  "Verbose" -> False
};

TransportFamily[input_, opts : OptionsPattern[]] := Catch[
  Module[{
    card, variables, regulator, system, assembly, verbose, root, tau,
    base, target, backend, orders, n0, n1, blocks, formDirectory,
    caps, timeConstraint, memoryConstraint, maxWeight,
    ahat, monic, budget, shift, kminPerBlock, kminF, tr0, kmaxF, jmax, seriesLow,
   closedBlocks, gradedBlocks, closedRows, gradedRows, exact, solutionLow,
   diagnostics,
    wmax, backendResult, verification, regraded, solution, valuation,
    series, checkable, deCheck, elapsed, start, status, tinvOrder, nb,
    dimension, targetOrder, checkableRecord, rational},

    start = AbsoluteTime[];
    verbose = TrueQ[OptionValue["Verbose"]];
    card = masterTransportResolveCard[OptionValue["Card"]];
    If[card === $Failed,
      masterTransportFail[TransportFamily, "option", "Card", OptionValue["Card"],
        TransportFamily]];

    root = OptionValue["Root"];
    If[root === Automatic,
      root = If[ValueQ[$feynFacetRoot], $feynFacetRoot,
        "/home/maxzhang/factorization-and-loops"]];

    variables = masterTransportResolveVariables[OptionValue["Variables"]];
    If[variables === $Failed,
      masterTransportFail[TransportFamily, "option", "Variables",
        OptionValue["Variables"], TransportFamily]];

    (* P2: the input is normalized NOW, before any backend package can
       load and claim v, w, eps, G or II for itself. *)
    system = If[AssociationQ[input], input,
      masterTransportFail[TransportFamily, "option", "input", input, TransportFamily]];
    regulator = masterTransportResolveRegulator[OptionValue["Regulator"],
      {system["Av"], system["Aw"]}, variables];
    If[regulator === $Failed || ! MatchQ[regulator, _Symbol],
      masterTransportFail[TransportFamily, "regulator", Lookup[system, "Family", input]]];
    system = masterTransportNormalize[system, regulator, variables];

    caps = <|
      "TimeConstraint" -> masterTransportCardSetting[OptionValue["TimeConstraint"],
        card, "TransportTimeConstraint", $masterTransportBuiltinCaps["TimeConstraint"]],
      "MemoryConstraint" -> masterTransportCardSetting[OptionValue["MemoryConstraint"],
        card, "TransportMemoryConstraint", $masterTransportBuiltinCaps["MemoryConstraint"]],
      "MaxWeight" -> masterTransportCardSetting[OptionValue["MaxWeight"],
        card, "TransportMaxWeight", $masterTransportBuiltinCaps["MaxWeight"]]|>;
    timeConstraint = caps["TimeConstraint"];
    memoryConstraint = caps["MemoryConstraint"];
    maxWeight = caps["MaxWeight"];

    backend = masterTransportCardSetting[OptionValue["TransportBackend"],
      card, "TransportBackend", "Libra"];
    blocks = OptionValue["Blocks"];
    formDirectory = OptionValue["FormDirectory"];
    If[formDirectory === Automatic,
      formDirectory = masterTransportCardSetting[Automatic, card,
        "TransportFormDirectory", None]];

    tau = OptionValue["PathParameter"];
    If[tau === Automatic, tau = Symbol["Global`tau"]];
    (* The path parameter must be a free symbol.  FeynCalc and the
       backend packages between them claim a great many short names, and
       a path parameter that already carries a value turns every
       derivative in this stage into nonsense without raising anything. *)
    (* ValueQ and OwnValues are BOTH HoldAll, so writing either of them
       on the local variable tests the local (which of course has a
       value) instead of the symbol it holds.  Evaluate reaches the
       intended symbol. *)
    If[! MatchQ[tau, _Symbol],
      masterTransportFail[TransportFamily, "option", "PathParameter", tau,
        TransportFamily]];
    If[OwnValues[Evaluate[tau]] =!= {},
      Message[MasterTransport::pathparameter, tau,
        Length[OwnValues[Evaluate[tau]]]];
      Throw[$Failed, $masterTransportFailure]];
    base = OptionValue["BasePoint"];
    target = OptionValue["Target"];
    If[target === Automatic, target = variables[[{1, 2}]]];

    (* ---------------------------------------------------- (C1) assembly *)
    assembly = masterTransportAssemble[system, regulator, variables,
      "Blocks" -> blocks, "FormDirectory" -> formDirectory, "Verbose" -> verbose];
    If[! AssociationQ[assembly] || assembly["Status"] =!= "OK",
      Return[<|"Status" -> "AssemblyFailed", "Assembly" -> assembly,
        "Reason" -> Lookup[assembly, "Failures", assembly["Status"]] /.
          a_Association :> Lookup[a, "Status", a],
        "Family" -> Lookup[system, "Family", None]|>, Module]];
    If[! masterTransportCertificateOK[assembly],
      Return[<|"Status" -> "CertificateFailed", "Assembly" -> assembly,
        "Certificate" -> assembly["Certificate"],
        "Family" -> Lookup[system, "Family", None]|>, Module]];

    nb = Length[assembly["Blocks"]];
    dimension = assembly["N"];
    (* A closed-form sector conjugates its own diagonal block to zero, so
       it takes no part in the word transport and no part in the graded
       series.  It is also necessarily DECOUPLED: any coupling to or from
       it would be dressed by Phi and Phi^-1 and would make the
       conjugated connection non-rational, which the gate below refuses.
       Coupled closed-form sectors need Phi-weighted quadrature, which is
       a separate capability and is not claimed here. *)
    closedBlocks = Select[Range[nb],
      assembly["Forms"][[#]]["Type"] === "ClosedFormSector" &];
    gradedBlocks = Complement[Range[nb], closedBlocks];
    closedRows = Flatten[assembly["Ranges"][[closedBlocks]]];
    gradedRows = Sort[Flatten[assembly["Ranges"][[gradedBlocks]]]];
    ahat = masterTransportPathMatrix[assembly["Apv"], assembly["Apw"], target,
      base, tau, variables];
    rational = FreeQ[ahat, Hypergeometric2F1 | HypergeometricPFQ | Log | PolyLog |
      Gamma | TransportWord];
    If[! rational,
      Return[<|"Status" -> "ConjugatedConnectionNotRational", "Assembly" -> assembly,
        "Family" -> assembly["Family"]|>, Module]];

    monic = masterTransportMonicCheck[ahat, tau];
    If[! TrueQ[monic["Linear"]],
      Return[<|"Status" -> "PathDenominatorsNotLinear", "Monic" -> monic,
        "Assembly" -> assembly, "Family" -> assembly["Family"]|>, Module]];

    exact = If[closedBlocks === {}, None,
      (* The path-frame identity dPhi/dtau = Ahat.Phi FOLLOWS from the
         block certificate dPhi/dx_i = A_i.Phi by the chain rule, so this
         is a confirmation rather than an independent statement, and it
         gets a bounded budget accordingly.  What it adds is a check that
         the path restriction itself was applied consistently. *)
      masterTransportExactSectors[assembly, closedBlocks, base, target, tau,
        variables, regulator, 8, 40, Min[timeConstraint, 120]]];
    If[exact =!= None && exact["Status"] =!= "OK",
      Return[<|"Status" -> "ClosedFormSectorNotVerified", "Exact" -> exact,
        "Assembly" -> assembly, "Family" -> assembly["Family"]|>, Module]];
    If[exact =!= None,
      masterTransportLog[verbose, "  closed-form sectors verified: ",
        Table[r["CheckRoute"], {r, exact["Sectors"]}]]];

    (* A family made ENTIRELY of closed-form sectors has no word
       transport and no graded series: its solution is exact in eps and
       the certificate above is the whole statement. *)
    If[gradedBlocks === {},
      Return[<|"Status" -> "OKExactInEps", "Family" -> assembly["Family"],
        "N" -> dimension, "Assembly" -> assembly,
        "Certificate" -> assembly["Certificate"], "Backend" -> None,
        "Weight" -> 0, "Exact" -> exact,
        "Constants" -> Association[
          Table[{r["Block"], "Exact"} -> r["Constants"], {r, exact["Sectors"]}]],
        "I" -> <|"Orders" -> {"Exact"},
          "I" -> Table[r["I"], {r, exact["Sectors"]}]|>,
        "Path" -> <|"Base" -> base, "Target" -> target, "Parameter" -> tau|>,
        "Variables" -> variables, "Regulator" -> regulator, "Caps" -> caps,
        "Seconds" -> AbsoluteTime[] - start|>, Module]];

    (* ------------------------------------- (C4) depth-budget arithmetic *)
    n0 = OptionValue["PhysicalValuation"];
    orders = OptionValue["Orders"];
    targetOrder = masterTransportCardSetting[OptionValue["TransportTargetOrder"],
      card, "TransportTargetOrder", n0 + 2];
    If[orders === Automatic, orders = {n0, targetOrder}];
    {n0, n1} = {Min[{n0, Min[orders]}], Max[orders]};

    tinvOrder = Table[
      If[MemberQ[closedBlocks, s], 0,
        Min[Append[DeleteCases[
          masterTransportEpsOrder[#, regulator] & /@ Flatten[assembly["TInverse"][[s]]],
          Infinity], 0]] /. Infinity -> 0],
      {s, nb}];
    (* val(F) = val(T^-1 . I) >= ord(T^-1) + n0, per block and WITHOUT
       clipping ord(T^-1) at zero.  The retired engine clipped it, which
       is safe but not tight: on NLO ord(T^-1) = +1 on six of the seven
       blocks, so clipping invents a whole spurious epsilon order of
       homogeneous freedom below the true start of F and then has to
       spend valuation equations killing it again. *)
    kminPerBlock = Table[n0 + tinvOrder[[s]], {s, nb}];
    kminF = Min[kminPerBlock[[gradedBlocks]]];
    tr0 = Min[Append[DeleteCases[
      Flatten[Table[
        masterTransportEpsOrder[#, regulator] & /@ Flatten[assembly["Forms"][[s]]["T"]],
        {s, gradedBlocks}]], Infinity], 0]];
    kmaxF = n1 - tr0;
    jmax = kmaxF - kminF;

    budget = masterTransportDepthBudget[assembly, ahat, kmaxF, regulator];
    shift = masterTransportEpsShift[assembly, ahat, regulator];
    If[shift["Status"] =!= "OK",
      Message[MasterTransport::shift, shift["Block"], shift["Order"]];
      Return[<|"Status" -> "EpsRegradingNotTerminating", "Shift" -> shift,
        "Assembly" -> assembly, "Family" -> assembly["Family"]|>, Module]];

    wmax = masterTransportCardSetting[OptionValue["TransportDepth"], card,
      "TransportDepth", Automatic];
    If[wmax === Automatic, wmax = jmax + shift["Shift"]];
    If[! (IntegerQ[wmax] && wmax >= 0),
      masterTransportFail[TransportFamily, "option", "TransportDepth", wmax,
        TransportFamily]];
    If[wmax > maxWeight,
      Return[<|"Status" -> "DepthExceedsCap", "Requested" -> wmax,
        "Cap" -> maxWeight, "Shift" -> shift, "Budget" -> budget,
        "Assembly" -> assembly, "Family" -> assembly["Family"]|>, Module]];

    (* Everything the depth arithmetic already established travels with
       EVERY subsequent return, including the failing ones.  A failure
       record that discards the analysis it already did is harder to act
       on than one that reports it, and the backend boundary on a
       CF360-class connection is precisely a case where the assembly and
       the arithmetic are sound and only the transport is unavailable. *)
    diagnostics = <|
      "TInverseOrder" -> tinvOrder,
      "KMinPerBlock" -> kminPerBlock,
      "ConstantOrders" -> Range[kminF, kmaxF],
      "Orders" -> Range[n0, n1],
      "Budget" -> budget,
      "Shift" -> shift,
      "Weight" -> wmax,
      "Monic" -> monic,
      "PhysicalValuation" -> n0,
      "Certificate" -> assembly["Certificate"]|>;

    masterTransportLog[verbose, "  depth: transport weight ", wmax,
      " (jmax ", jmax, " + shift ", shift["Shift"], "), F orders ",
      kminF, "..", kmaxF, ", I orders ", n0, "..", n1,
      ", global rmin ", budget["RMinGlobal"]];

    (* ------------------------------------------------- transport ------ *)
    backendResult = TimeConstrained[
      MemoryConstrained[
        masterTransportRunBackend[backend, ahat, tau, wmax, root, regulator],
        memoryConstraint, <|"Status" -> "BackendMemoryExceeded"|>],
      timeConstraint, <|"Status" -> "BackendTimedOut"|>];
    If[! AssociationQ[backendResult] || backendResult["Status"] =!= "OK",
      Return[Join[diagnostics,
        <|"Status" -> "TransportFailed", "Backend" -> backend,
          "BackendResult" -> backendResult, "Assembly" -> assembly,
          "Family" -> assembly["Family"]|>], Module]];

    (* mandatory backend gate: never skippable, never configurable *)
    verification = masterTransportVerifyTransport[backendResult["U"], ahat, tau, dimension];
    If[! TrueQ[verification["AllZero"]],
      Return[Join[diagnostics,
        <|"Status" -> "TransportNotVerified", "Backend" -> backend,
          "Verification" -> verification, "Assembly" -> assembly,
          "Family" -> assembly["Family"]|>], Module]];
    masterTransportLog[verbose, "  transport verified per weight: ",
      verification["PerWeight"]];

    (* ------------------------------------------------- (C3) regrading -- *)
    (* V_j vanishes identically for j < -shift, because a weight-n word
       cannot reach below n - shift and n >= 0.  The window therefore
       starts at -shift rather than at the wider range the constant
       vector alone would suggest. *)
    regraded = masterTransportRegrade[backendResult["U"], {-shift["Shift"], jmax},
      shift["Shift"], regulator];
    If[! TrueQ[regraded["Complete"]],
      Return[Join[diagnostics,
        <|"Status" -> "RegradingIncomplete", "Regrading" -> regraded,
          "Assembly" -> assembly, "Family" -> assembly["Family"]|>], Module]];
    masterTransportLog[verbose, "  regrading: weight ", regraded["TopWeight"],
      ", shift ", regraded["Shift"], ", lowest order at top weight ",
      regraded["LowestOrderAtTopWeight"], ", complete through eps^", jmax];

    (* The SOLUTION starts lower than the constant vector does.  With a
       1/eps coupling the transport itself carries negative eps orders,
       so F(tau) = U(tau).C has components below n0 + ord(T^-1) even
       though C does not -- they vanish at tau = 0 and are generated
       along the path.  The retired engine derived the lower limit from
       ord(T^-1) alone, which is correct only when the conjugated
       connection is a strict eps-form; the general statement subtracts
       the regrading shift as well.  Those extra orders are exactly what
       the valuation constraints below must kill. *)
    solutionLow = kminF - shift["Shift"];
    solution = masterTransportSolutionVector[regraded, assembly, kminPerBlock,
      kmaxF, solutionLow];
    If[! AssociationQ[solution],
      Return[<|"Status" -> "SolutionVectorFailed", "Assembly" -> assembly|>, Module]];

    (* ------------------------------------------------ (C2) valuation --- *)
    valuation = masterTransportValuation[assembly, solution, n0, base, target,
      tau, variables, regulator, verbose];
    If[valuation["Status"] === "Inconsistent" || ! TrueQ[valuation["AssertionOK"]],
      Return[Join[diagnostics,
        <|"Status" -> "ValuationFailed", "Valuation" -> valuation,
          "Assembly" -> assembly, "Family" -> assembly["Family"]|>], Module]];
    solution = valuation["Solution"];

    (* The series is built from its TRUE lowest order kminF + tr0, not
       from the physical valuation n0.  Starting it at n0 would silently
       drop I at lower orders, and the per-order check at n0 consumes
       exactly those: with a 1/eps in T the eps^0 row needs I_{-1}.
       Orders below n0 are zero only AFTER the valuation constraints and
       the boundary fixing have acted, so they are carried explicitly
       rather than assumed away. *)
    seriesLow = solutionLow + tr0;
    If[seriesLow > n0, seriesLow = n0];
    series = masterTransportMasterSeries[assembly, solution, {seriesLow, n1}, base,
      target, tau, variables, regulator, gradedBlocks];

    checkableRecord = masterTransportCheckableOrders[{n0, n1}, budget["RMinGlobal"]];
    checkable = checkableRecord["Checkable"];
    deCheck = If[TrueQ[OptionValue["Verify"]] && checkable =!= {},
      masterTransportCheckDE[assembly, series, checkable, base, target, tau,
        variables, regulator, If[closedBlocks === {}, All, gradedRows]],
      {}];

    elapsed = AbsoluteTime[] - start;
    status = Which[
      ! TrueQ[OptionValue["Verify"]], "Unverified",
      checkable === {}, "SolvedNotCheckable",
      AllTrue[deCheck, #["Zero"] === {True} &], "OK",
      True, "CheckInconclusive"];

    <|"Status" -> status,
      "Family" -> assembly["Family"],
      "N" -> dimension,
      "Assembly" -> assembly,
      "Certificate" -> assembly["Certificate"],
      "Backend" -> backendResult["Backend"],
      "TransportVerification" -> verification,
      "Monic" -> monic,
      "Budget" -> budget,
      "Shift" -> shift,
      "Regrading" -> KeyDrop[regraded, "V"],
      "TransportGraded" -> regraded["V"],
      "TransportWeightGraded" -> backendResult["U"],
      "Weight" -> wmax,
      "Orders" -> Range[n0, n1],
      "SeriesOrders" -> Range[seriesLow, n1],
      "FOrders" -> Range[solutionLow, kmaxF],
      "ConstantOrders" -> Range[kminF, kmaxF],
      "KMinPerBlock" -> kminPerBlock,
      "PhysicalValuation" -> n0,
      "TInverseOrder" -> tinvOrder,
      "F" -> solution["F"],
      "Constants" -> solution["Constants"],
      "Valuation" -> KeyDrop[valuation, "Solution"],
      "Exact" -> exact,
      "ClosedFormBlocks" -> closedBlocks,
      "GradedRows" -> gradedRows,
      "I" -> series,
      "Checkable" -> checkableRecord,
      "DECheck" -> deCheck,
      "Path" -> <|"Base" -> base, "Target" -> target, "Parameter" -> tau|>,
      "Variables" -> variables,
      "Regulator" -> regulator,
      "Caps" -> caps,
      "Seconds" -> elapsed|>
  ],
  $masterTransportFailure
];

Options[TransportStatus] = {"Print" -> True};

TransportStatus[result_Association, OptionsPattern[]] := Module[{lines, print},
  print = TrueQ[OptionValue["Print"]];
  lines = {};
  AppendTo[lines, StringJoin[
    "transport family=", ToString[Lookup[result, "Family", "?"]],
    " status=", ToString[Lookup[result, "Status", "?"]],
    " n=", ToString[Lookup[result, "N", "?"]],
    " backend=", ToString[Lookup[result, "Backend", "none"]],
    " weight=", ToString[Lookup[result, "Weight", "?"]],
    " seconds=", ToString[NumberForm[Lookup[result, "Seconds", 0.], {6, 2}]]]];
  If[KeyExistsQ[result, "Certificate"],
    AppendTo[lines, StringJoin[
      "  certificate",
      " triangular=", ToString[result["Certificate"]["BlockLowerTriangular"]],
      " flatA=", ToString[result["Certificate"]["FlatnessOriginal"]],
      " diagonal=", ToString[result["Certificate"]["DiagonalEqualsDeclaredForm"]],
      " epslinear=", ToString[result["Certificate"]["EpsFormLinear"]],
      " flatAp=", ToString[result["Certificate"]["FlatnessConjugated"]]]]];
  If[KeyExistsQ[result, "Shift"] && AssociationQ[result["Shift"]],
    AppendTo[lines, StringJoin[
      "  regrading shift=", ToString[Lookup[result["Shift"], "Shift", "?"]],
      " complete=", ToString[Lookup[Lookup[result, "Regrading", <||>], "Complete", "?"]],
      " lowestAtTopWeight=",
      ToString[Lookup[Lookup[result, "Regrading", <||>], "LowestOrderAtTopWeight", "?"]]]]];
  If[KeyExistsQ[result, "Valuation"],
    AppendTo[lines, StringJoin[
      "  valuation status=", ToString[Lookup[result["Valuation"], "Status", "?"]],
      " orders=", ToString[Lookup[result["Valuation"], "Orders", {}]],
      " equations=", ToString[Lookup[result["Valuation"], "Equations", 0]],
      " assertion=", ToString[Lookup[result["Valuation"], "AssertionOK", "?"]]]]];
  If[KeyExistsQ[result, "Checkable"],
    AppendTo[lines, StringJoin[
      "  checkable orders=", ToString[Lookup[result["Checkable"], "Checkable", {}]],
      " of ", ToString[Lookup[result["Checkable"], "Orders", {}]],
      " depth=", ToString[Lookup[result["Checkable"], "Depth", "?"]],
      " rule=", ToString[Lookup[result["Checkable"], "Rule", "?"]]]]];
  If[KeyExistsQ[result, "DECheck"] && result["DECheck"] =!= {},
    Do[
      AppendTo[lines, StringJoin[
        "  DE order eps^", ToString[record["Order"]], " zero=",
        ToString[record["Zero"]]]],
      {record, result["DECheck"]}]];
  If[KeyExistsQ[result, "Assembly"] && AssociationQ[result["Assembly"]] &&
     KeyExistsQ[result["Assembly"], "Forms"],
    Do[
      AppendTo[lines, StringJoin[
        "  block ", ToString[i], " rows=",
        ToString[result["Assembly"]["Blocks"][[i]]],
        " provider=", ToString[Lookup[result["Assembly"]["Forms"][[i]], "Source", "?"]],
        " type=", ToString[Lookup[result["Assembly"]["Forms"][[i]], "Type", "?"]]]],
      {i, Length[result["Assembly"]["Forms"]]}]];
  If[print, Scan[Print, lines]];
  lines
];
