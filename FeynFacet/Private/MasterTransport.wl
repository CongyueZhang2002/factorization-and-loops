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
     TransportFamilyInChart -- the same stage for a family whose hard
       block is only an epsilon-form in a two-variable chart: it moves
       the WHOLE family into the chart and calls TransportFamily there;
     TransportStatus  -- one greppable line per block, for a watchdog.

   Usage of the chart entry point (classes 97 = CF258_B9 and
   77 = CF230_B1, chart v = x y, w = (1-x)(1-y), sqrt(lambda) = x - y):

     TransportFamilyInChart[
       <|"Family" -> "CF258", "Av" -> av, "Aw" -> aw|>,
       <|"Kind" -> "TwoVariable", "Variables" -> {x, y},
         "Subst" -> {v -> x y, w -> (1 - x) (1 - y)},
         "Root" -> x - y, "RootSquare" -> (1 - v - w)^2 - 4 v w|>,
       "Blocks" -> {{{1, 2}, 95}, ..., {{18, 19, 20, 21}, 97}},
       "FormDirectory" -> classFormDirectory,
       "PhysicalValuation" -> 0, "Orders" -> {0, 1}]

   The system is pulled back by the chain rule, every block's stored
   class form is composed with the chart's coordinate map and RE-VERIFIED
   against the pulled-back block system, and the result is
   TransportFamily's, extended by "Chart", "ChartNotes" (the chart, its
   Jacobian and the path convention) and "PullBack" (the certificates).
   It fails closed with "ChartPullBackFailed" if one block's form cannot
   be pulled back.  The default path is AXIS-ALIGNED -- see the chart
   section further down for the measured reason.  No physics bookkeeping
   is done here: no chamber, no branch, no sign.

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

   (C4b) The clamped D above is an upper bound, not the minimum.  The
   exact per-block rule -- the recursion of the 2026-08-16 GPT-Pro
   review's Eq. (4), with the FULL Laurent support of every coupling --
   is implemented as masterTransportExactDepth and is computed on EVERY
   run, reported beside the clamped number as "ExactDepth".  The option
   "DepthRule" selects which one sets the weight:

     "Clamped" (default)  wmax = jmax + D          -- the proved bound,
     "Exact"              wmax = max_i W_i(N_i)    -- the minimum.

   The default is deliberately the bound: the two agree exactly when no
   maximizing chain mixes a deficit edge (eps-order <= 0) with a slack
   edge (eps-order >= 2), which is the MEASURED situation for CF258 and
   CF230, and changing the default would silently change what an already
   stored run means.  One consequence is recorded here rather than
   papered over: the regrading completeness assertion
   (masterTransportRegrade) is stated with the GLOBAL clamped shift, so
   when "Exact" returns a strictly smaller weight that assertion refuses
   the run with RegradingIncomplete.  Making the completeness statement
   per-block-exact is the outstanding work; until it is done, "Exact" is
   usable in production only where it equals the clamped weight, and the
   module fails closed everywhere else.

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
     D1  D differentiates EVERY slot, including one holding a pure
         function, and D[Function[s, g[s]], t] returns Function[s, 0]
         rather than 0.  A head with an integrand slot therefore picks
         up a term  Function[s,0] * Derivative[1,0,0][head][...]  that
         is mathematically zero and survives Expand, Together and
         Simplify.  Its derivative is then never syntactically equal to
         its integrand, and identities built on it fail silently while
         the mathematics is correct.  Declare the slot's derivative to
         be 0 and ASSERT the invariant that justifies it.
     H1  The pattern Hypergeometric2F1[_,_,_,_] EVALUATES to (1-_)^(-_),
         because its four Blank[] arguments are structurally identical
         and the built-in rule 2F1(a,b;b;z) = (1-z)^-a therefore fires
         on the pattern itself.  Cases/MatchQ against it silently find
         NOTHING in an expression full of 2F1s.  Match on the head
         (_Hypergeometric2F1) or use named blanks, which are distinct
         expressions and do not trigger the rule.

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
  $masterTransportSupportCache,
  $masterTransportPolyLogToolsLoaded,
  $masterTransportBuiltinCaps,
  masterTransportFail,
  masterTransportLog,
  masterTransportLogStream,
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
  masterTransportCombineExactness,
  masterTransportGaussPQ,
  masterTransportHypergeometricCertificate,
  masterTransportClosedFormSector,
  masterTransportAssemble,
  masterTransportCertificateOK,
  masterTransportClassRepPair,
  masterTransportClassNormalize,
  masterTransportClassMemberMap,
  masterTransportClassMemberPermutation,
  masterTransportClassActT,
  masterTransportClassFormBlock,
  masterTransportFreeSymbols,
  masterTransportRationalQ,
  masterTransportChartRecordQ,
  masterTransportChartData,
  masterTransportPullBackOneForm,
  masterTransportPullBackSystem,
  masterTransportRecordCoordinateMap,
  masterTransportChartSwapData,
  masterTransportPullBackClassFormOnce,
  masterTransportPullBackClassForm,
  masterTransportChartBlockSpec,
  masterTransportChartNotes,
  masterTransportDepthBudget,
  masterTransportDepthBudgetFromTable,
  masterTransportEpsShift,
  masterTransportLaurentSupport,
  masterTransportLaurentSupportCompute,
  masterTransportSupportCacheClear,
  masterTransportResolveBlockDemands,
  masterTransportExactDepth,
  masterTransportCheckableOrders,
  masterTransportAxisBasePoints,
  masterTransportBasePointCandidates,
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
  masterTransportClosedFormCoupling,
  masterTransportQuadratureDerivativeRule,
  masterTransportQuadratureIdentity,
  masterTransportPhiQuadrature,
  masterTransportCoupledSolve,
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

MasterTransport::root =
  "The installation root the transport backends are loaded from could not be \
resolved from `1`. Give \"Root\" -> <directory> explicitly, or set \
Global`$FACETAddonRoot before the package is loaded.";

$masterTransportRegulatorNames = {"eps", "Eps", "epsilon", "Epsilon", "ep"};

(* Every symbolic zero test gets a budget.  Simplify on a 2F1 residual
   can run without bound, and a check that has not returned is neither a
   pass nor a failure -- it is a check that was not performed, and it
   must be reported as "Inconclusive" rather than hang the stage. *)
$masterTransportZeroTimeLimit = 120;

$masterTransportLibraLoaded = False;
$masterTransportSupportCache = <||>;
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

(* The installation root the backend packages (Libra, PolyLogTools,
   Fermatica) are loaded from.  Automatic is the add-on root of THIS
   installation; there is no built-in absolute path (generality pass
   2026-08-23, B1).  Returns $Failed when nothing resolves, so every
   caller can refuse typed instead of reading a nonexistent tree. *)
masterTransportResolveInstallationRoot[value_] := Which[
  StringQ[value] && DirectoryQ[value], value,
  StringQ[value], $Failed,
  value === Automatic && ValueQ[$feynFacetAddonRoot] &&
    StringQ[$feynFacetAddonRoot], $feynFacetAddonRoot,
  value === Automatic && ValueQ[$feynFacetRoot] && StringQ[$feynFacetRoot],
    $feynFacetRoot,
  True, $Failed
];

(* Every progress line carries the wall clock and the seconds since this
   file was loaded, so a RATE can be read off a log without instrumenting
   the caller: the cost of a long stage is the difference between two
   consecutive lines, and a stalled stage is visible as the absence of
   one.  A watchdog reading this log needs nothing else. *)
$masterTransportLogStart = AbsoluteTime[];

masterTransportLog[verbose_, args___] := If[TrueQ[verbose],
  WriteString[masterTransportLogStream[], "[transport ",
    DateString[{"Hour", ":", "Minute", ":", "Second"}], " +",
    ToString[Round[AbsoluteTime[] - $masterTransportLogStart]], "s] ",
    StringJoin[ToString /@ {args}], "\n"];
  Flush[masterTransportLogStream[]]
];

(* Where a progress line goes.  A plain wolframscript run has
   $Output = {OutputStream["stdout", 1]}, so this is the stream it always
   used.  Inside a KernelPool mission the pool rebinds $Output to the
   mission's own log file, and a line written to the literal "stdout"
   stream would land in the POOL's log instead of the mission's -- i.e.
   the per-item progress a watchdog is required to see would be in the
   wrong file, interleaved with every other mission.  Resolving the
   stream at call time fixes that without changing anything else. *)
masterTransportLogStream[] :=
  If[ListQ[$Output] && $Output =!= {}, First[$Output], OutputStream["stdout", 1]];

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

(* TransportQuadrature[f, t, t0] is the unevaluated Int_t0^t f[s] ds.

   Like TransportWord it is a package-owned inert head carrying its own
   derivative rule, so a stored solution never depends on any package
   being loaded, and so that nothing can silently "simplify" a formal
   integral into a wrong closed form.

   The integrand is a pure FUNCTION, not an expression in t.  That is
   the whole reason the derivative tag below is unambiguous: with an
   expression the chain rule would also differentiate through the first
   argument and produce Derivative[1,0,0] terms that mean nothing here.
   The tag is {0,1,0} -- the derivative with respect to the UPPER LIMIT
   -- and it is the fundamental theorem of calculus, nothing more. *)
Derivative[0, 1, 0][TransportQuadrature][f_, t_, t0_] := f[t];

(* MEASURED, and the reason the coupled certificate did not close.

   D also differentiates the INTEGRAND slot, and D[Function[s, g[s]], t]
   returns Function[s, 0] -- the zero function, but written in a form no
   simplifier reduces to the number 0.  So

     D[TransportQuadrature[f, t, 0], t]
       =  f[t]  +  Function[s, 0] * Derivative[1,0,0][TransportQuadrature][...]

   and the second term, though mathematically zero, survives Expand,
   Together and Simplify alike.  The derivative was therefore never
   syntactically equal to its integrand, and every downstream identity
   built on it failed while the mathematics was correct.

   The slot holds a pure FUNCTION, not a quantity, so differentiating
   with respect to it is not a meaningful operation and the honest value
   is zero.  The invariant that makes this sound -- the integrand never
   depends on the path parameter, because it is always built by
   substituting that parameter out -- is asserted where the quadrature
   is constructed, not assumed here. *)
Derivative[1, 0, 0][TransportQuadrature][f_, t_, t0_] := 0;

(* the lower limit is a base point, so the quadrature vanishes there *)
TransportQuadrature[f_, t_, t_] := 0;

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
    TransportWord[masterTransportRadicalNormalize[Together[#]] & /@ idx,
      Together[z]];

(* Apply constant-fixing rules to a word expression WITHOUT a
   whole-expression Together (measured 2026-08-18: CF26's 136 MB / 9-order
   general solution stalled for hours in Map[Together[# /. rules]&, F];
   the words are untouched by the rules -- only the coefficients combine
   -- so the operation is linear and per-coefficient).  Words are kept
   as the Association keys the engine already uses; every coefficient is
   substituted and canonicalised on its own; vanishing coefficients drop
   their words. *)
masterTransportSubstituteConstants[e_, rules_] := Module[{coll, out},
  If[rules === {} || FreeQ[e, TransportConstant], Return[e]];
  If[FreeQ[e, TransportWord], Return[Together[e /. rules]]];
  coll = masterTransportCollect[e];
  (* build once with Total; repeated `out += c w` re-flattens a growing
     Plus each step (Codex review 2026-08-18) *)
  out = Table[
    Module[{c = Together[coll[w] /. rules]},
      If[TrueQ[c === 0], Nothing, c w]],
    {w, Keys[coll]}];
  Total[out]
];
(* MATRIX-VALUED WORD COEFFICIENTS (Codex + external review, 2026-08-18):
   F^(n) = Sum_w w . C_w^(n) . c  with c the constant vector; a solved
   constraint set c = N . b (N exact, from the valuation kernel) acts as
   C_w -> C_w . N -- small exact matrix products, no rewrite of the word
   sum.  The reassembled F keeps the standard representation downstream
   (certificates, checks, artifacts) but every coefficient is formed as a
   short linear combination, never via Together on a large sum. *)
masterTransportConstantKernel[rules_List, constants_List] := Module[
  {free, sub, mat},
  (* rules: {c_i -> linear form in the free constants}; the kernel N maps
     free constants b to all constants c *)
  free = Select[constants, ! MemberQ[First /@ rules, #] &];
  sub = constants /. rules;
  mat = Normal[CoefficientArrays[sub, free]];
  If[Length[mat] < 2, Return[<|"N" -> ConstantArray[0, {Length[constants], Length[free]}],
    "Free" -> free, "Affine" -> mat[[1]]|>]];
  <|"N" -> mat[[2]], "Free" -> free, "Affine" -> mat[[1]]|>
];
masterTransportApplyKernel[e_, kernel_Association, constants_List] := Module[
  {coll, free = kernel["Free"], nmat = kernel["N"], out},
  If[FreeQ[e, TransportConstant], Return[e]];
  If[FreeQ[e, TransportWord],
    Return[Together[e /. Thread[constants -> nmat . free] ]]];
  coll = masterTransportCollect[e];
  out = Table[
    Module[{cvec, row, newc},
      (* coefficient of this word is linear in the constants: extract its
         row vector, multiply by N, contract with the free constants *)
      cvec = Normal[CoefficientArrays[coll[w], constants]];
      row = If[Length[cvec] < 2, ConstantArray[0, Length[constants]], cvec[[2]]];
      newc = Together[(row . nmat) . free +
        If[Length[cvec] >= 1, cvec[[1]], 0]];
      If[TrueQ[newc === 0], Nothing, newc w]],
    {w, Keys[coll]}];
  Total[out]
];
masterTransportApplyKernel[list_List, kernel_Association, constants_List] :=
  masterTransportApplyKernel[#, kernel, constants] & /@ list;
masterTransportApplyKernel[a_Association, kernel_Association, constants_List] :=
  masterTransportApplyKernel[#, kernel, constants] & /@ a;

masterTransportSubstituteConstants[list_List, rules_] :=
  masterTransportSubstituteConstants[#, rules] & /@ list;
masterTransportSubstituteConstants[a_Association, rules_] :=
  masterTransportSubstituteConstants[#, rules] & /@ a;

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

(* ---- algebraic letters: radicals of the spectator ---------------------

   MEASURED 2026-08-17 (Scripts/... monic probes over all 91 families):
   the canonical alphabets contain letters that are QUADRATIC in the
   moving path variable with a discriminant that is not a square in the
   frozen variable -- 1 - w + v w pulled back to the class-97 chart is a
   (2,2)-curve on P^1 x P^1 (genus 1), so NO rational chart makes it
   linear.  Such a letter contributes the two roots

       tau_+- = (-b +- k Sqrt[D0]) / (2 a),     b^2 - 4 a c = k^2 D0,

   D0 square-free, to the word alphabet: G(tau_+, ...; tau) with an
   ALGEBRAIC index in the frozen variable -- the ordinary fibration
   representation of multivariate polylogarithms.  Libra's Pexp admits
   such poles natively (its PolesPosition is Solve[den == 0, x]); the
   monic gate below used to refuse them by policy, not by mathematics.

   Two disciplines make the arithmetic exact:

     (1) every radical is written as k Sqrt[D0] with D0 the SQUARE-FREE
         part of the discriminant (numeric content left to the kernel's
         own automatic normalization), so that equal extensions are
         syntactically equal and letters from different quadratics with
         the same D0 live in the same field;
     (2) a zero test that DECIDES over Q(vars, Sqrt[D0_1], ...): the
         radicals are replaced by symbols r_i, the expression is written
         as one fraction, and the numerator is reduced modulo r_i^2 - D0_i;
         it is zero iff every remaining coefficient of the r-monomials is
         zero.  Together alone is NOT a decision procedure here (it does
         not know r^2 = D0 once the radical sits inside a denominator),
         which is why this exists.

   Nothing else changes: word indices remain tau-free constants, the
   append rule and the recursion certificate are unchanged, and a letter
   with an eps-DEPENDENT discriminant is refused (an apparent
   singularity that the off-diagonal cleanup must remove, never a
   letter). *)

masterTransportRadicalQ[e_] := ! FreeQ[e, Power[_, _Rational]];

(* k Sqrt[D0] with D0 square-free, for a polynomial (or rational) D *)
masterTransportRadicalCanon[d_] := Module[{t, num, den, fl, k, d0},
  t = Together[d];
  If[TrueQ[t === 0], Return[0]];
  num = Numerator[t]; den = Denominator[t];
  (* Sqrt[num/den] = Sqrt[num den]/den *)
  fl = FactorSquareFreeList[Expand[num den]];
  k = Times @@ Table[f[[1]]^Quotient[f[[2]], 2], {f, fl}];
  d0 = Times @@ Table[If[OddQ[f[[2]]], f[[1]], 1], {f, fl}];
  Together[k Sqrt[Expand[d0]]/den]];

(* rewrite every half-integer power inside e as (radical) with the
   square-free discipline; idempotent *)
masterTransportRadicalNormalize[e_] :=
  e /. Power[b_, q_Rational] /; Denominator[q] === 2 :>
    Module[{m = Numerator[q], r = masterTransportRadicalCanon[b]},
      (* b^(m/2) = b^((m-1)/2) Sqrt[b] for every odd m, positive or
         negative: 1/Sqrt[b] = Sqrt[b]/b, b^(-3/2) = Sqrt[b]/b^2 *)
      b^((m - 1)/2) r];

(* the decision procedure: True iff e vanishes identically over the
   extension generated by its radicals *)
masterTransportRadicalZeroQ[e_] := Module[
  {t, radicals, syms, rules, relations, num, poly, remainder, coefficients},
  t = Together[masterTransportRadicalNormalize[e]];
  If[TrueQ[t === 0], Return[True]];
  (* every half-integer power b^(m/2), m odd, positive or negative: the
     kernel folds b Sqrt[b] into b^(3/2) automatically, so the bases are
     collected from ALL such powers and each is rewritten as
     b^((m-1)/2) r  (r^2 = b), which covers 1/Sqrt[b] = r/b and
     b^(-3/2) = r/b^2 as well *)
  radicals = DeleteDuplicates[Cases[t,
    Power[b_, q_Rational] /; Denominator[q] === 2 :> b, {0, Infinity}]];
  If[radicals === {}, Return[False]];
  syms = Table[Unique["masterTransportRadical"], {Length[radicals]}];
  rules = Table[
    With[{b = radicals[[i]], s = syms[[i]]},
      Power[b, q_Rational] /; Denominator[q] === 2 :>
        b^((Numerator[q] - 1)/2) s],
    {i, Length[radicals]}];
  relations = Table[syms[[i]]^2 - radicals[[i]], {i, Length[radicals]}];
  t = Together[t /. rules];
  num = Numerator[t];
  (* clear any radical left in the denominator by multiplying through
     with the conjugates: den * conj is r-free after reduction *)
  Module[{den = Denominator[t], i = 1},
    While[! FreeQ[den, Alternatives @@ syms] && i <= 4 Length[syms],
      Module[{s = SelectFirst[syms, ! FreeQ[den, #] &], conj},
        conj = den /. s -> -s;
        num = PolynomialRemainder[Expand[num conj], relations[[Position[syms, s][[1, 1]]]], s];
        den = PolynomialRemainder[Expand[den conj], relations[[Position[syms, s][[1, 1]]]], s]];
      i++]];
  poly = Expand[num];
  remainder = poly;
  Do[remainder = PolynomialRemainder[remainder, relations[[i]], syms[[i]]],
    {i, Length[syms]}];
  remainder = Together[remainder];
  If[TrueQ[remainder === 0], Return[True]];
  (* the denominator is radical-free after the conjugation loop; the
     numerator is a polynomial of degree <= 1 in every r_i whose
     r-monomial coefficients must ALL vanish (1, r_i, r_i r_j, ... are
     linearly independent over the rational functions when the D0_i are
     square-free and pairwise non-proportional modulo squares) *)
  coefficients = CoefficientList[Numerator[remainder], syms];
  AllTrue[Flatten[coefficients], TrueQ[Together[#] === 0] &]
];

(* Sound zero test.  Coefficient-wise vanishing PROVES the expression is
   zero.  It is not a decision procedure: Libra's words are not
   shuffle-reduced, so a nonzero coefficient list does not prove the
   expression is nonzero.  The verdict is therefore True or
   "Inconclusive", never a claim of nonvanishing.  Over an algebraic
   extension (radicals in the frozen variable) the coefficient test is
   the exact one above. *)
masterTransportSimplifyZeroQ[e_] :=
  TrueQ[Together[e] === 0] ||
  (masterTransportRadicalQ[e] && TrueQ[masterTransportRadicalZeroQ[e]]) ||
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

(* ------------------------------------------------------------------ *)
(*  Exactness taxonomy                                                  *)
(* ------------------------------------------------------------------ *)

(* The three states, in decreasing strength:

     "Exact"              proved symbolically;
     "AnalyticCandidate"  finite series and finitely many numerical
                          points agree, no proof;
     "Rejected"           a residual is nonzero or a check could not be
                          completed.

   Combining is a MINIMUM, never a vote: one Rejected rejects the whole,
   and one AnalyticCandidate stops the whole from being Exact.  An empty
   list is "Exact" -- there is nothing left unproved -- which is what
   makes a family with no closed-form sector fall through unchanged.

   An unrecognised state is treated as "Rejected" rather than ignored,
   so a typo downstream can never silently promote a sector. *)
masterTransportCombineExactness[states_List] := Which[
  ! AllTrue[states, MemberQ[{"Exact", "AnalyticCandidate", "Rejected"}, #] &],
    "Rejected",
  MemberQ[states, "Rejected"], "Rejected",
  MemberQ[states, "AnalyticCandidate"], "AnalyticCandidate",
  True, "Exact"];

(* ------------------------------------------------------------------ *)
(*  Exact Gauss certificate for a hypergeometric fundamental matrix     *)
(* ------------------------------------------------------------------ *)

(* Reduction coefficients of the Gauss differential equation.

     z(1-z) f'' + [c - (a+b+1) z] f' - a b f = 0

   is solved for f'' and differentiated repeatedly, giving

     f^(m)(z) = P_m(z) f(z) + Q_m(z) f'(z)

   with P_m, Q_m rational.  The recursion is the derivative of that
   statement, using the m = 2 case to eliminate the f'' it produces:

     P_{m+1} = P_m' + Q_m P_2,
     Q_{m+1} = P_m + Q_m' + Q_m Q_2.

   Returned as two lists indexed from order 0, so order m sits at part
   m+1.  Nothing here is truncated: these are exact rational functions
   and the identity they encode holds for every z. *)
masterTransportGaussPQ[a0_, b0_, c0_, zsym_Symbol, mmax_Integer] :=
  Module[{pl, ql, p2, q2, m},
    p2 = Together[a0 b0/(zsym (1 - zsym))];
    q2 = Together[-(c0 - (a0 + b0 + 1) zsym)/(zsym (1 - zsym))];
    (* M1: built in the body, not in a Module initializer that refers to
       another local of the same Module. *)
    pl = {1, 0, p2};
    ql = {0, 1, q2};
    Do[
      AppendTo[pl, Together[D[pl[[m + 1]], zsym] + ql[[m + 1]] p2]];
      AppendTo[ql, Together[pl[[m + 1]] + D[ql[[m + 1]], zsym] + ql[[m + 1]] q2]],
      {m, 2, mmax - 1}];
    {pl, ql}
  ];

(* The exact certificate itself.

   Mathematica's built-in derivative of Hypergeometric2F1 RAISES all
   three parameters, so differentiating a 2F1 with eps-dependent
   parameters walks up an infinite tower that Simplify cannot close.
   That is the whole reason the class-115 sector previously fell back to
   series-plus-numerics.  It is not an obstruction in the mathematics,
   only in the default rewriting, and the standard fix is the inert-head
   technique this repository already uses for the NLO masters
   (Tests/Reconstruction/t_nlo_masters.wls): substitute an inert head BEFORE any D, then
   supply the exact identity by hand.

   Two exact identities do the whole job.

   1. Every parameter-raised instance is a derivative of the tower base:

        d^n/dz^n 2F1(a,b;c;z) = ((a)_n (b)_n / (c)_n) 2F1(a+n,b+n;c+n;z),

      so 2F1(a+n,b+n;c+n;z) = ((c)_n / ((a)_n (b)_n)) f^(n)(z) with f the
      inert head of the base.  This is what collapses the tower: instead
      of infinitely many unrelated functions there is one function and
      its derivatives.

   2. The Gauss equation reduces every f^(m), m >= 2, to {f, f'} with
      exact rational coefficients (masterTransportGaussPQ).

   After both, the residual dPhi - A Phi is a rational-coefficient
   LINEAR combination of the independent atoms {f, f'} of each tower.
   The identity is proved by extracting those coefficients and showing
   each is literally zero -- Together on the whole residual is not
   trusted to see it, because the atoms are not polynomial variables to
   it.  No series is truncated and no number is substituted anywhere in
   this function, which is what lets its verdict be "Exact".

   `pairs` is a list of {connection, variable}: {{Av,v},{Aw,w}} in the
   kinematic frame, {{Ahat,tau}} on a path.  Every pair must come out
   zero for the certificate to be proved.

   Returns <|"Proved" -> True|False, ...|>; "Proved" -> False with a
   "Reason" means this route does not apply, NOT that Phi is wrong. *)
masterTransportHypergeometricCertificate[phi_, pairs_List, eps_,
    record_, timeLimit_] := Module[
  {instances, groups, rules, atoms, heads, towers, phiInert,
   zsym, freshVars, atomRules, zeroByCoefficients, reduce, outcome,
   applicable},
  (* H1: the pattern Hypergeometric2F1[_,_,_,_] EVALUATES, and therefore
     matches nothing.  Its four Blank[] arguments are structurally
     identical expressions, so the built-in rule 2F1(a,b;b;z) = (1-z)^-a
     fires on the pattern itself and turns it into (1 - _)^(-_).  Cases
     then silently returns {} on a Phi that is full of 2F1s, and the
     certificate would report "not applicable" instead of proving the
     identity -- a false negative that costs an Exact status.  Matching
     on the HEAD cannot evaluate. *)
  instances = DeleteDuplicates[Cases[phi, _Hypergeometric2F1, {0, Infinity}]];
  If[instances === {},
    Return[<|"Proved" -> False, "Reason" -> "NoHypergeometric2F1InPhi"|>]];

  zsym = Unique["masterTransportGaussZ"];
  rules = {}; atoms = {}; heads = {}; towers = {}; applicable = True;

  (* A tower is fixed by its argument and by the two parameter
     DIFFERENCES b-a and c-a, both of which are invariant under the
     common integer shift that raising produces. *)
  groups = GatherBy[instances,
    Function[h, {h[[4]], Simplify[h[[2]] - h[[1]]], Simplify[h[[3]] - h[[1]]]}]];

  Do[
    Module[{group, shifts, base, a0, b0, c0, zz, order, mmax, head, pq, pl, ql,
       n, m},
      group = groups[[k]];
      zz = group[[1, 4]];
      (* Part on a Hypergeometric2F1 expression returns an expression with
         the SAME head, so group[[i]][[1;;3]] would be a 3-argument
         Hypergeometric2F1 (and would emit an argument-count message),
         not a list.  Parts are taken one at a time. *)
      shifts = Table[group[[i]][[1]], {i, Length[group]}];
      order = Ordering[shifts];
      base = group[[First[order]]];
      {a0, b0, c0} = {base[[1]], base[[2]], base[[3]]};
      shifts = Table[Simplify[group[[i]][[1]] - a0], {i, Length[group]}];
      If[! AllTrue[shifts, IntegerQ[#] && # >= 0 &],
        applicable = False,
        (* the b and c shifts must be the SAME integer, or the instances
           are not one tower and the Pochhammer identity does not apply *)
        If[! AllTrue[Range[Length[group]],
             TrueQ[Simplify[group[[#]][[2]] - b0] === shifts[[#]]] &&
             TrueQ[Simplify[group[[#]][[3]] - c0] === shifts[[#]]] &],
          applicable = False,
          head = Unique["masterTransportHyp"];
          AppendTo[heads, head];
          Do[
            n = shifts[[i]];
            AppendTo[rules,
              group[[i]] -> Derivative[n][head][zz] *
                Pochhammer[c0, n]/(Pochhammer[a0, n] Pochhammer[b0, n])],
            {i, Length[group]}];
          (* Phi carries derivatives up to Max[shifts]; one more comes
             from d/dv and d/dw.  Two spare orders cost nothing. *)
          mmax = Max[shifts] + 4;
          pq = masterTransportGaussPQ[a0, b0, c0, zsym, mmax];
          pl = pq[[1]]; ql = pq[[2]];
          (* RuleDelayed is HoldRest and Do scopes its iterator, so a rule
             written directly in terms of m would carry an m with no value
             by the time the rule is USED, and would silently reduce
             nothing.  Everything is frozen with With at construction. *)
          Do[
            With[{mm = m, pp = pl[[m + 1]], qq = ql[[m + 1]], hh = head,
                  zs = zsym},
              AppendTo[rules,
                HoldPattern[Derivative[mm][hh][arg_]] :>
                  (pp /. zs -> arg) hh[arg] +
                  (qq /. zs -> arg) Derivative[1][hh][arg]]],
            {m, 2, mmax}];
          AppendTo[atoms, head[zz]];
          AppendTo[atoms, Derivative[1][head][zz]];
          AppendTo[towers, <|"Base" -> {a0, b0, c0}, "Argument" -> zz,
            "Shifts" -> shifts, "MaxReducedOrder" -> mmax|>]]]],
    {k, Length[groups]}];

  If[! applicable,
    Return[<|"Proved" -> False, "Reason" -> "NotAContiguousTower"|>]];

  phiInert = phi /. rules;
  If[! FreeQ[phiInert, Hypergeometric2F1],
    Return[<|"Proved" -> False, "Reason" -> "UnmatchedHypergeometricInstance"|>]];

  reduce[e_] := FixedPoint[Function[x, Together[x /. rules]], e, 8];

  freshVars = Table[Unique["masterTransportGaussAtom"], {Length[atoms]}];
  atomRules = Thread[atoms -> freshVars];
  zeroByCoefficients[res_] := Module[{sub, cl},
    sub = res /. atomRules;
    (* an inert head that survived the atom substitution means a
       derivative order the reduction did not reach: not a proof *)
    If[! FreeQ[sub, Alternatives @@ heads], Return[False, Module]];
    cl = Flatten[Map[CoefficientList[#, freshVars] &, Flatten[{sub}]]];
    AllTrue[cl, TrueQ[Together[#] === 0] &]];

  outcome = TimeConstrained[
    Table[
      zeroByCoefficients[
        reduce[D[phiInert, pairs[[i, 2]]] - pairs[[i, 1]] . phiInert]],
      {i, Length[pairs]}],
    timeLimit, $Failed];

  If[outcome === $Failed,
    Return[<|"Proved" -> False, "Reason" -> "TimedOut", "Towers" -> towers|>]];

  <|"Proved" -> AllTrue[outcome, TrueQ],
    "Method" -> "GaussODE+PochhammerTower",
    "Identities" -> {
      "d^n/dz^n 2F1(a,b;c;z) = ((a)_n (b)_n/(c)_n) 2F1(a+n,b+n;c+n;z)",
      "z(1-z) f'' + [c-(a+b+1) z] f' - a b f = 0"},
    "Statement" -> "dPhi/dx - A_x.Phi = 0 for every listed variable x, \
proved symbolically as an identity in the free atoms {f, f'} of each \
hypergeometric tower; no series truncation and no numerical substitution.",
    "Towers" -> towers,
    "Variables" -> pairs[[All, 2]],
    "PerVariableZero" -> outcome,
    "ClassID" -> Lookup[record, "ClassID",
      Lookup[Lookup[record, "Certificate", <||>], "ClassID", None]]|>
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

   EXACTNESS TAXONOMY.  Two different things are recorded, and they are
   deliberately not the same field:

     "CheckRoute"  -- the MECHANISM that was run, "Symbolic" or
                      "SeriesAndNumeric".  Neither name contains the
                      word Exact, so a route can never be misread as a
                      verdict.
     "Exactness"   -- the VERDICT, and the only thing downstream code
                      and the tests are allowed to assert:

       "Exact"             all three displayed identities -- the two
                           derivative residuals and the inverse -- are
                           proved SYMBOLICALLY, with no series
                           truncation and no numerical substitution;
       "AnalyticCandidate" the symbolic route did not close, and a
                           Frobenius truncation plus finitely many
                           high-precision numerical points agree.  This
                           is evidence, not a proof: a finite Taylor
                           expansion and finitely many values cannot
                           establish a functional identity;
       "Rejected"          a residual is nonzero, or a required check
                           could not be completed.

   The inverse identity is required SYMBOLICALLY in every accepted case,
   including "AnalyticCandidate" -- Phi^-1 is constructed here by
   Together[Inverse[phi]] and its verification is rational algebra, so a
   failure there is a genuine defect rather than a limitation of
   Simplify on contiguous relations.

   A route that could not be performed makes the block "Rejected"; it
   never counts as a pass. *)
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
   timeLimit, seriesOrder, numericPoints, precision, frame, exactness,
   certificate, certificateResult},
  {v, w} = variables[[{1, 2}]];
  timeLimit = OptionValue["TimeConstraint"];
  seriesOrder = OptionValue["SeriesOrder"];
  numericPoints = OptionValue["NumericPoints"];
  precision = OptionValue["Precision"];
  phi = Lookup[record, "Phi", $Failed];
  If[! MatrixQ[phi],
    Return[<|"Status" -> "Rejected", "Exactness" -> "Rejected",
      "Reason" -> "NoPhi"|>]];
  dim = Length[phi];
  If[dim =!= Length[av],
    Return[<|"Status" -> "Rejected", "Exactness" -> "Rejected",
      "Reason" -> "PhiDimensionMismatch"|>]];
  frame = Lookup[record, "Frame", Lookup[record, "Chart", None]];
  chartVariable = If[AssociationQ[frame], Lookup[frame, "ChartVariable", None], None];
  phiInverse = Lookup[record, "PhiInverse", Automatic];
  If[phiInverse === Automatic || MissingQ[phiInverse],
    phiInverse = TimeConstrained[Together[Inverse[phi]], timeLimit, $Failed]];
  If[phiInverse === $Failed || ! MatrixQ[phiInverse],
    Return[<|"Status" -> "Rejected", "Exactness" -> "Rejected",
      "Reason" -> "PhiNotInvertible"|>]];

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

  (* Second symbolic attempt, before any truncation is contemplated.
     Together alone does not close the contiguous relations of a 2F1
     with eps-dependent parameters, but the certificate route does it by
     construction: inert heads, the Gauss equation and exact contiguous
     identities.  It is still a SYMBOLIC proof, so it earns "Exact". *)
  certificate = None; certificateResult = None;
  (* "GaussCertificate" -> False suppresses this route.  It exists so a
     test can exercise the series-and-numeric branch on a Phi that the
     certificate WOULD prove, and check that the same matrix then earns
     "AnalyticCandidate" instead of "Exact" -- i.e. that the taxonomy
     separates the routes rather than always reporting the best one.
     Default Automatic: attempt the proof. *)
  If[! (exactV && exactW) &&
      Lookup[record, "GaussCertificate", Automatic] =!= False,
    certificateResult = masterTransportHypergeometricCertificate[
      phi, {{av, v}, {aw, w}}, eps, record, timeLimit];
    If[AssociationQ[certificateResult] &&
        TrueQ[certificateResult["Proved"]],
      exactV = True; exactW = True;
      certificate = certificateResult]];

  route = "Symbolic";
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

  (* THE verdict.  Note the asymmetry that Codex's taxonomy demands: a
     symbolic proof of both derivative identities AND the inverse is the
     only way to reach "Exact".  The series/numeric route can never
     reach it, however many orders or digits it is given. *)
  exactness = Which[
    ! TrueQ[exactI], "Rejected",
    TrueQ[exactV] && TrueQ[exactW], "Exact",
    TrueQ[seriesOK] && TrueQ[numericOK], "AnalyticCandidate",
    True, "Rejected"];

  checks = <|
    "SymbolicDerivativeV" -> exactV,
    "SymbolicDerivativeW" -> exactW,
    "SymbolicInverse" -> exactI,
    (* retained under the old names so a stored result stays readable;
       they carry the same booleans, not a verdict *)
    "ExactDerivativeV" -> exactV,
    "ExactDerivativeW" -> exactW,
    "ExactInverse" -> exactI,
    "SeriesResidualZero" -> seriesOK,
    "NumericResidualZero" -> numericOK,
    "CheckRoute" -> route,
    "Exactness" -> exactness,
    "Certificate" -> certificate,
    "SeriesOrder" -> If[route === "SeriesAndNumeric", seriesOrder, None],
    "StoredCertificate" -> Lookup[record, "Certificate", None]
  |>;

  If[exactness === "Rejected",
    Return[<|"Status" -> "Rejected", "Exactness" -> "Rejected",
      "Reason" -> If[! TrueQ[exactI], "PhiInverseNotVerified", "PhiNotVerified"],
      "Checks" -> checks|>]];

  <|"Status" -> "OK", "Type" -> "ClosedFormSector",
    "Exactness" -> exactness,
    "T" -> phi, "TInverse" -> phiInverse,
    "Ev" -> ConstantArray[0, {dim, dim}],
    "Ew" -> ConstantArray[0, {dim, dim}],
    "Source" -> "closed-form", "Frame" -> frame, "Checks" -> checks|>
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
              (* Automatic when absent: the assembly then computes the
                 inverse itself.  A supplied one is used only where it
                 was certified by its producer AND is re-checked by the
                 diagonal part of the assembly certificate. *)
              "TInverse" -> Lookup[specification, "TInverse", Automatic],
              "Ev" -> Lookup[specification, "Ev",
                Together[Inverse[specification["T"]] . av . specification["T"] -
                  Inverse[specification["T"]] . D[specification["T"], variables[[1]]]]],
              "Ew" -> Lookup[specification, "Ew",
                Together[Inverse[specification["T"]] . aw . specification["T"] -
                  Inverse[specification["T"]] . D[specification["T"], variables[[2]]]]],
              "Alphabet" -> Lookup[specification, "Alphabet", {}],
              "Source" -> "explicit"|>,
            <|"Status" -> "NoTransformation"|>],
        _, <|"Status" -> "UnknownProviderType"|>],
    True, <|"Status" -> "UnknownProvider"|>]
];

(* Check level (user decision 2026-08-22: checks stay separate from the
   calculation).  "Development": every identity exact (the default).
   "Production" (FACET_CHECK_LEVEL=Production): the identities that only
   guard the bookkeeping of an assembly -- curvature of the source and of
   the conjugated connection, per-block inverses, diagonal-equals-declared-
   form -- are evaluated EXACTLY AT RANDOM RATIONAL POINTS instead of as
   rational-function identities (a wrong matrix passes with probability
   ~ degree / 10^6 per point; two points are used), and the single exact
   statement is the family certificate made afterwards.  Measured on
   CF254 (dim 23, 2026-08-22): the exact identities were 446 s of a 626 s
   assembly; the conjugation itself 49 s. *)
masterTransportCheckLevel[requested_: Automatic] := Which[
  MemberQ[{"Production", "Development"}, requested], requested,
  Environment["FACET_CHECK_LEVEL"] === "Production", "Production",
  True, "Development"];

(* exact-rational evaluation of every entry at count random points; a
   point hitting a pole is replaced *)
masterTransportPointZeroQ[expr_, symbols_List, count_Integer: 2] := Module[
  {flat = Flatten[{expr}], tries = 0, done = 0, point, values},
  If[flat === {} || AllTrue[flat, TrueQ[# === 0] &], Return[True]];
  While[done < count && tries < 6 count,
    tries++;
    point = Thread[symbols -> RandomInteger[{3, 10^6}, Length[symbols]]/
      RandomInteger[{10^6, 10^7}, Length[symbols]]];
    values = Quiet[Check[flat /. point, $Failed]];
    If[values === $Failed || ! FreeQ[values, ComplexInfinity | Indeterminate | DirectedInfinity],
      Continue[]];
    If[! AllTrue[values, TrueQ[# == 0] &], Return[False]];
    done++];
  done >= count];

Options[masterTransportAssemble] = {
  "Blocks" -> Automatic,
  "FormDirectory" -> None,
  "ConjugatedFlatnessCheck" -> Automatic,
  "CheckLevel" -> Automatic,
  "Verbose" -> False
};

masterTransportAssemble[system_Association, eps_Symbol, variables_List,
    opts : OptionsPattern[]] := Module[
  {av, aw, n, blocks, providers, order, permutation, pav, paw, nb, ranges,
   forms, tInverse, conjugated, certificate, triangular, diagonalOK,
   apv, apw, verbose, formDirectory, v, w, family, blockSpecification,
   inversePerBlock, directFlatnessCheck, algebraicConnectionQ,
   checkLevel, productionQ, zeroMat},
  verbose = TrueQ[OptionValue["Verbose"]];
  formDirectory = OptionValue["FormDirectory"];
  checkLevel = masterTransportCheckLevel[OptionValue["CheckLevel"]];
  productionQ = checkLevel === "Production";
  {v, w} = variables[[{1, 2}]];
  (* the zero test of this assembly's guards: exact identity, or exact
     evaluation at random rational points in production *)
  zeroMat[m_] := If[productionQ,
    masterTransportPointZeroQ[m, {v, w, eps}], masterTransportZeroMatQ[m]];
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
  certificate["CheckLevel"] = checkLevel;
  certificate["FlatnessOriginal"] = zeroMat[
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
  inversePerBlock = Table[
    If[forms[[i]]["Type"] === "ClosedFormSector",
      TrueQ[Lookup[forms[[i]]["Checks"], "ExactInverse", False]],
      zeroMat[
        forms[[i]]["T"] . tInverse[[i]] -
          IdentityMatrix[Length[forms[[i]]["T"]]]] &&
      zeroMat[
        tInverse[[i]] . forms[[i]]["T"] -
          IdentityMatrix[Length[forms[[i]]["T"]]]]],
    {i, nb}];
  certificate["TransformationInversePerBlock"] = inversePerBlock;
  certificate["TransformationInverseVerified"] =
    AllTrue[inversePerBlock, TrueQ];

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
      {j, nb}];
    (* one line per block ROW of the conjugation, which is the stretch
       that dominates a large family: nb(nb+1)/2 conjugated blocks, and
       without this the whole assembly is one opaque wait *)
    masterTransportLog[verbose, "  conjugated block row ", i, "/", nb,
      " (dim ", Length[ranges[[i]]], ", leaves ",
      LeafCount[Table[conjugated[{i, j}], {j, i}]], ")"],
    {i, nb}];

  diagonalOK = Table[
    If[forms[[i]]["Type"] === "ClosedFormSector",
      (* established by masterTransportClosedFormSector, whose route is
         recorded in forms[[i]]["Checks"] *)
      TrueQ[forms[[i]]["Status"] === "OK"],
      zeroMat[conjugated[{i, i}][[1]] - forms[[i]]["Ev"]] &&
      zeroMat[conjugated[{i, i}][[2]] - forms[[i]]["Ew"]]],
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
  (* Flatness of the CONJUGATED connection.

     Curvature is gauge-covariant: with A' = T^-1 A T - T^-1 dT and T
     invertible, F(A') = T^-1 F(A) T.  So flatness of A' is a THEOREM
     given flatness of A, and this check exists to catch a bookkeeping
     error in building A', not to discover new mathematics.

     For a rational A' the direct computation settles it and remains the
     primary route.  For a connection over an explicitly declared
     algebraic field, or one dressed by a closed-form fundamental matrix,
     forming the full matrix curvature creates a much larger expression
     but proves no additional statement.  In that case the certificate
     records gauge covariance and requires both hypotheses separately:
     the original curvature vanishes exactly and every block basis change
     has an exact two-sided inverse.  A rational direct calculation that
     does not vanish is never replaced by this route. *)
  algebraicConnectionQ = ! FreeQ[{apv, apw},
    _Root | Power[_, exponent_Rational /; Denominator[exponent] > 1] |
      Hypergeometric2F1 | HypergeometricPFQ | MeijerG];
  (* production: flatness of A' follows from flatness of A and invertible
     T (gauge covariance); the direct 23x23 curvature was 361 s on CF254 *)
  directFlatnessCheck = Replace[OptionValue["ConjugatedFlatnessCheck"],
    Automatic -> (! algebraicConnectionQ && ! productionQ)];
  certificate["FlatnessConjugated"] = If[TrueQ[directFlatnessCheck],
    masterTransportZeroMatQ[
      D[apv, w] - D[apw, v] + apv . apw - apw . apv],
    Missing["ImpliedByGaugeCovariance"]];
  certificate["FlatnessConjugatedRoute"] = Which[
    TrueQ[certificate["FlatnessConjugated"]], "Verified",
    ! TrueQ[directFlatnessCheck] &&
      TrueQ[certificate["FlatnessOriginal"]] &&
      TrueQ[certificate["TransformationInverseVerified"]],
      "ByGaugeCovariance",
    TrueQ[certificate["FlatnessOriginal"]] &&
      ! FreeQ[{apv, apw},
        Hypergeometric2F1 | HypergeometricPFQ | MeijerG],
      "ByGaugeEquivalence",
    True, "Failed"];

  masterTransportLog[verbose, "  certificate: triangular ", certificate["BlockLowerTriangular"],
    ", flat(A) ", certificate["FlatnessOriginal"],
    ", diagonal ", certificate["DiagonalEqualsDeclaredForm"],
    ", eps-linear ", certificate["EpsFormLinear"],
    ", inverse(T) ", certificate["TransformationInverseVerified"],
    ", flat(A') ", certificate["FlatnessConjugatedRoute"]];

  <|"Status" -> "OK", "Family" -> family, "N" -> n, "Perm" -> permutation,
    "Blocks" -> blocks, "Ranges" -> ranges, "Forms" -> forms,
    "TInverse" -> tInverse, "Apv" -> apv, "Apw" -> apw,
    "Av" -> pav, "Aw" -> paw,
    (* M3: Missing["KeyAbsent",...] =!= None, and the converse bites too.
       A caller that passes "Basis" -> None explicitly (the coupled
       closed-form route builds its lower sub-system that way) is NOT
       caught by MissingQ, and the permutation was then applied to the
       symbol None -- Part::partd, a stream of messages, and a Basis of
       None[[...]] carried downstream.  Both spellings of "absent" are
       tested. *)
    "Basis" -> If[MissingQ[system["Basis"]] || system["Basis"] === None,
      None, system["Basis"][[permutation]]],
    "Certificate" -> certificate|>
];

(* The conjugation certificate.  Every condition must hold; a stored
   flag is never consulted. *)
masterTransportCertificateOK[assembly_] :=
  AssociationQ[assembly] && assembly["Status"] === "OK" &&
  And @@ (TrueQ /@ {
    assembly["Certificate"]["BlockLowerTriangular"],
    assembly["Certificate"]["FlatnessOriginal"],
    assembly["Certificate"]["DiagonalEqualsDeclaredForm"],
    assembly["Certificate"]["EpsFormLinear"],
    assembly["Certificate"]["TransformationInverseVerified"]}) &&
  (* the fifth part passes on the direct computation, or on the gauge
     -equivalence theorem whose hypothesis is the SECOND part above --
     never on an unexplained "Inconclusive" *)
  MemberQ[{"Verified", "ByGaugeCovariance", "ByGaugeEquivalence"},
    Lookup[assembly["Certificate"], "FlatnessConjugatedRoute",
      If[TrueQ[assembly["Certificate"]["FlatnessConjugated"]],
        "Verified", "Failed"]]];

(* ------------------------------------------------------------------ *)
(*  Class MEMBERS: the group element that carries the representative     *)
(*  onto this block                                                      *)
(* ------------------------------------------------------------------ *)

(* ClassifyBlocks defines class equivalence as a basis PERMUTATION,
   optionally composed with the v <-> w SWAP, and stage 1 certifies ONE
   epsilon-form per class -- the REPRESENTATIVE's.  A member's connection
   is therefore the representative's acted on by that group element, and
   the transformation that puts the MEMBER in epsilon-form is the SAME
   element applied to the stored T:

     swap  T(v,w) -> T(w,v)     relabelling v <-> w turns dF/dv = Av F,
                                dF/dw = Aw F into dF/dv = swap[Aw] F,
                                dF/dw = swap[Av] F, and the gauge
                                relabels with the system;
     perm  T      -> T[[q,q]]   conjugation by a CONSTANT permutation
                                matrix, so no dT term appears.

   Both are one-line consequences of A' = T^-1 A T - T^-1 dT being
   covariant under a constant conjugation and under a relabelling of the
   variables, and the epsilon-form transforms the same way
   (Ev -> swap[Ew][[q,q]], Ew -> swap[Ev][[q,q]]).

   Applying the representative's T to a member that needs a non-trivial
   element is the wrong-frame error one level down, and it is what
   ClassFormNotEpsForm was naming: measured 2026-08-17, 252 of the 1028
   members of a rational-frame class need the swap (213 of dimension 1,
   39 of dimension 2) and none needs a non-identity permutation, but the
   permutation is part of the definition of the class and is handled
   here rather than left as a latent wrong answer.

   The map is RECOVERED, not read: the stored
   BlockClasses/block_class_assign.wl predates the "Swap"/"Permutation"
   keys that ClassifyBlocks now writes (measured: 0 occurrences), and
   regenerating it is a separate, heavier operation.  The
   representative's own connection is reconstructed from the record's T
   and EpsForm,

       A_rep = (T . E + dT) . T^-1,

   and the member's element is the one carrying that onto this block,
   entry by entry, in the exact rational normal form ClassifyBlocks
   itself matches in.

   That reconstruction is a CANDIDATE GENERATOR ONLY.  The element it
   proposes is handed to the same exact epsilon-form gate as before, so
   a stale, wrong or missing stored EpsForm can only fail to repair a
   block -- it can never make one accepted.  Acceptance stays exact. *)

masterTransportClassRepPair[record_, variables_List, eps_Symbol] := Module[
  {t, e, ti, v, w},
  {v, w} = variables[[{1, 2}]];
  t = Lookup[record, "Transformation", $Failed];
  e = Lookup[record, "EpsForm", $Failed];
  If[! MatrixQ[t] || ! MatchQ[e, {_?MatrixQ, _?MatrixQ}], Return[$Failed]];
  If[Dimensions[e[[1]]] =!= Dimensions[t] ||
     Dimensions[e[[2]]] =!= Dimensions[t], Return[$Failed]];
  ti = Quiet[Check[Inverse[t], $Failed]];
  If[! MatrixQ[ti], Return[$Failed]];
  {Map[Together, (t . e[[1]] + D[t, v]) . ti, {2}],
   Map[Together, (t . e[[2]] + D[t, w]) . ti, {2}]}
];

(* The normal form is CanonicalBlocks': Cancel[Together[]] on every
   entry plus the division by the leading denominator coefficient.
   Using anything else here would compare a different equivalence than
   the one the class file was built with. *)
masterTransportClassNormalize[pair_, variables_List, eps_Symbol] :=
  canonicalBlocksMatrix[#, variables[[{1, 2}]], eps] & /@ pair;

masterTransportClassMemberMap[repPair_, memberPair_, variables_List,
    eps_Symbol] := Module[{vars = variables[[{1, 2}]], repN, repS, memN},
  repN = masterTransportClassNormalize[repPair, vars, eps];
  repS = masterTransportClassNormalize[
    canonicalBlocksSwapPair[repPair, vars], vars, eps];
  memN = masterTransportClassNormalize[memberPair, vars, eps];
  canonicalBlocksMatchOrbit[repN, repS, memN]
];

(* Permutation only, for a caller that has already fixed the swap (the
   chart route tries the swap by exchanging the chart images instead). *)
masterTransportClassMemberPermutation[repPair_, memberPair_, variables_List,
    eps_Symbol] := Module[{vars = variables[[{1, 2}]], repN, memN},
  repN = masterTransportClassNormalize[repPair, vars, eps];
  memN = masterTransportClassNormalize[memberPair, vars, eps];
  SelectFirst[canonicalBlocksOrbitCandidates[memN, repN],
    {repN[[1]][[#, #]], repN[[2]][[#, #]]} === memN &, None]
];

masterTransportClassActT[t_, swapQ_, q_, variables_List] :=
  Module[{tt},
    tt = If[TrueQ[swapQ], canonicalBlocksSwap[t, variables[[{1, 2}]]], t];
    tt[[q, q]]
  ];

(* A stored class form provides T in its own frame.  Pull it back to the
   kinematic variables when it carries a chart, and re-derive Ev/Ew from
   T rather than trusting the stored EpsForm. *)
masterTransportClassFormBlock[resolved_, rows_, av_, aw_, eps_, variables_] :=
  Module[{record, t, v, w, ev, ew, chart, mapped, recordVariables,
      repPair, map, tm, tmInverse},
    {v, w} = variables[[{1, 2}]];
    record = resolved["Record"];
    t = Lookup[record, "Transformation", $Failed];
    If[! MatrixQ[t], Return[<|"Status" -> "ClassFormNoTransformation"|>]];
    (* A two-variable chart record is refused HERE, by name, before
       anything is computed.

       This guard is not decorative.  Such a record DOES carry a chart
       "Inverse" (the stored map back to (v,w), which contains the square
       root), so it passes the Inverse guard further down; its T is then
       differentiated with respect to (v,w) -- symbols it does not even
       contain -- and conjugated against a (v,w) block system.  That is a
       transformation used in the WRONG FRAME, and the only thing standing
       between it and a silently wrong Ev/Ew would be the epsilon-form
       gate, which names the symptom rather than the cause.  Only
       TransportFamilyInChart may consume these records. *)
    chart = Lookup[record, "Chart", None];
    If[AssociationQ[chart] && Lookup[chart, "Kind", None] === "TwoVariable",
      Return[<|"Status" -> "ClassFormTwoVariableChartNeedsChartTransport",
        "Rows" -> rows, "ClassID" -> Lookup[resolved, "ClassID", None],
        "Chart" -> Lookup[chart, "Subst", None],
        "Hint" -> "this class is an epsilon-form only in a two-variable \
chart; transport the whole family with TransportFamilyInChart"|>]];
    (* A record whose own frame is not the frame this stage is working
       in is refused next, also by name. *)
    recordVariables = Lookup[record, "Variables", variables[[{1, 2}]]];
    (* a ONE-variable root record (class 115: Variables {u}, u^2 = 1 - 4vw)
       is an eps-form only in a chart that rationalizes its root; used
       here it would be the wrong-frame error again (measured 2026-08-17:
       it slipped past the two-symbol guard and surfaced as
       ClassFormNotEpsForm on CF299/CF300/CF303) *)
    If[MatchQ[recordVariables, {_Symbol}],
      Return[<|"Status" -> "ClassFormOneVariableChartNeedsChartTransport",
        "Rows" -> rows, "ClassID" -> Lookup[resolved, "ClassID", None],
        "RecordVariables" -> recordVariables,
        "Hint" -> "this class is an epsilon-form only in one variable u with \
u^2 a quadratic in (v,w); transport the whole family with TransportFamilyInChart \
in a chart that rationalizes it (TransportCharts.wl)"|>]];
    If[MatchQ[recordVariables, {_Symbol, _Symbol}] &&
       (SymbolName /@ recordVariables) =!= (SymbolName /@ variables[[{1, 2}]]),
      Return[<|"Status" -> "ClassFormChartNotPullable", "Rows" -> rows,
        "RecordVariables" -> recordVariables,
        "Hint" -> "the record is in another frame; TransportFamilyInChart \
transports the whole family in that frame"|>]];
    chart = Lookup[record, "Chart", None];
    If[chart =!= None && chart =!= Null && AssociationQ[chart],
      (* charts are pulled back through their stored inverse; a class
         whose chart cannot be pulled back is refused rather than
         silently used in the wrong frame *)
      mapped = Lookup[chart, "Inverse", $Failed];
      If[mapped === $Failed, Return[<|"Status" -> "ClassFormChartNotPullable"|>]]];
    If[Length[t] =!= Length[av],
      Return[<|"Status" -> "ClassFormDimensionMismatch", "Rows" -> rows,
        "ClassID" -> Lookup[resolved, "ClassID", None],
        "FormDimension" -> Length[t], "BlockDimension" -> Length[av]|>]];
    (* The stored T FIRST, unchanged: a member that is the representative
       itself, or whose connection equals it, must cost nothing extra, and
       a T that already conjugates THIS block to an epsilon-form is a valid
       transformation for it whatever the class bookkeeping says. *)
    ev = Together[Inverse[t] . av . t - Inverse[t] . D[t, v]];
    ew = Together[Inverse[t] . aw . t - Inverse[t] . D[t, w]];
    If[FreeQ[Together[ev/eps], eps] && FreeQ[Together[ew/eps], eps],
      Return[<|"Status" -> "OK", "Type" -> "EpsForm", "T" -> t, "Ev" -> ev,
        "Ew" -> ew, "Source" -> "class-form", "MemberMap" -> None,
        "ClassID" -> resolved["ClassID"]|>]];
    (* Otherwise this block is a class MEMBER whose connection is the
       representative's acted on by a swap and/or a basis permutation.
       Recover that element and retry against the SAME exact gate. *)
    repPair = masterTransportClassRepPair[record, variables, eps];
    If[! MatchQ[repPair, {_?MatrixQ, _?MatrixQ}],
      Return[<|"Status" -> "ClassFormNotEpsForm", "Rows" -> rows,
        "ClassID" -> Lookup[resolved, "ClassID", None],
        "MemberMap" -> Missing["NoRepresentativeConnection"]|>]];
    map = masterTransportClassMemberMap[repPair, {av, aw}, variables, eps];
    If[map === None,
      Return[<|"Status" -> "ClassFormNotEpsForm", "Rows" -> rows,
        "ClassID" -> Lookup[resolved, "ClassID", None],
        "MemberMap" -> Missing["NoMap"]|>]];
    tm = masterTransportClassActT[t, map["Swap"], map["Permutation"], variables];
    tmInverse = Quiet[Check[Inverse[tm], $Failed]];
    If[! MatrixQ[tmInverse],
      Return[<|"Status" -> "ClassFormMemberTransformationSingular",
        "Rows" -> rows, "ClassID" -> Lookup[resolved, "ClassID", None],
        "MemberMap" -> map|>]];
    ev = Together[tmInverse . av . tm - tmInverse . D[tm, v]];
    ew = Together[tmInverse . aw . tm - tmInverse . D[tm, w]];
    If[! (FreeQ[Together[ev/eps], eps] && FreeQ[Together[ew/eps], eps]),
      Return[<|"Status" -> "ClassFormNotEpsForm", "Rows" -> rows,
        "ClassID" -> Lookup[resolved, "ClassID", None],
        "MemberMap" -> map, "MemberMapApplied" -> True|>]];
    <|"Status" -> "OK", "Type" -> "EpsForm", "T" -> tm, "Ev" -> ev, "Ew" -> ew,
      "Source" -> "class-form-member", "MemberMap" -> map,
      "ClassID" -> resolved["ClassID"]|>
  ];

(* ------------------------------------------------------------------ *)
(*  Two-variable chart pullback                                         *)
(* ------------------------------------------------------------------ *)

(* Frames, continued.  Stage 1 certifies three kinds of class form:

     rational frame       Variables {v,w}, no chart;
     single-conic chart   Variables {v,t}, Chart <|Fixed, Subst, Root|>,
                          which rationalizes ONE quadratic locus;
     two-variable chart   Variables {x,y}, Chart <|"Kind" ->
                          "TwoVariable", "Subst" -> {v -> f(x,y),
                          w -> g(x,y)}, "Root" -> ...|>, which
                          rationalizes the Kallen root globally
                          (classes 97 and 77: v = x y, w = (1-x)(1-y),
                          sqrt(lambda) = x - y).

   A family whose hard block only has a form of the third kind cannot be
   transported in (v,w) at all -- no rational T exists there.  The WHOLE
   family is therefore moved into the chart (the system by the chain
   rule, every block's transformation by composition with the chart's
   coordinate map) and the EXISTING TransportFamily runs in (x,y).

   This layer does that and nothing else.  It makes no chamber, no
   branch and no sign choice; it records the chart, including the
   Jacobian determinant d(v,w)/d(x,y) -- x - y for the class-97 chart --
   under "ChartNotes", so that a later stage can.

   Everything is re-derived.  A stored "EpsForm" is read as provenance
   and COMPARED, never used: the chart epsilon-form is computed from the
   pulled-back BLOCK SYSTEM as T^-1 A T - T^-1 dT, exactly as the
   assembly does it, and a record whose frame cannot be composed with
   the target chart is refused by name rather than used in the wrong
   frame.

   Class equivalence is a basis permutation optionally composed with
   v <-> w, so the composition also TRIES that swap -- in this chart the
   involution (x,y) -> (1-x,1-y) -- and lets the exact re-derivation
   decide.  See masterTransportChartSwapData for the measured members.

   Composing a single-conic chart with the target chart needs no square
   root and is therefore done rather than refused: the conic record's
   "Root" is the same algebraic function that the target chart
   rationalizes, so setting it equal to the target chart's rational
   "Root" and solving for the conic parameter is ONE LINEAR SOLVE.  The
   solve is a candidate only; what licenses it is the exact identity
   that the conic chart's own substitution, evaluated at that parameter,
   reproduces the target chart's substitution.  Both signs of the root
   are tried and the one that satisfies the identity is recorded.  When
   neither does, the record is refused with a named status and no square
   root is ever introduced.  (Measured for the conic chart of classes
   49/95, w = (-t + t^2 + t v)/(t - 1) with Root = 2t + v - 1 - w:
   t = 1 - y in the class-97 chart, exactly.)

   Path note -- measured, and not incidental.  The pulled-back alphabet
   contains letters that are BILINEAR in (x,y): x + y - x y for class
   97, x + y - 2 x y for the pullback of 1 - v - w.  On a generic
   straight segment in (x,y) such a letter is QUADRATIC in the path
   parameter, and masterTransportMonicCheck refuses the connection
   (status PathDenominatorsNotLinear) -- correctly, because the word
   backends admit linear denominators only.  On an AXIS-ALIGNED segment,
   one chart variable held at its symbolic target value, every letter of
   the pulled-back alphabet is linear in tau again.
   TransportFamilyInChart therefore defaults to an axis-aligned path and
   says so in "ChartNotes".  The per-order check against the original
   family differential equation is then a statement about the path
   direction; the two-directional statements -- flatness of the chart
   system, and each diagonal block equalling its declared form in BOTH
   chart variables -- come from the assembly certificate as usual, and
   the pullback certificate carries the exact flatness of the chart
   system in its own right. *)

masterTransportFreeSymbols[expr_] := DeleteDuplicates @ Cases[expr,
  s_Symbol /; Context[s] =!= "System`", {0, Infinity}, Heads -> True];

masterTransportRationalQ[e_, vars_List] := Module[{x},
  x = Together[e];
  If[! FreeQ[x, Power[_, _Rational] | _Root | Log | Hypergeometric2F1],
    Return[False]];
  PolynomialQ[Numerator[x], vars] && PolynomialQ[Denominator[x], vars]
];

masterTransportChartRecordQ[chart_] :=
  AssociationQ[chart] &&
  MatchQ[Lookup[chart, "Variables", $Failed], {_Symbol, _Symbol}] &&
  MatchQ[Lookup[chart, "Subst", $Failed], {_Rule, _Rule}] &&
  Lookup[chart, "Kind", "TwoVariable"] === "TwoVariable";

(* Resolve a chart record against the caller's source symbols.  The
   chart's own Subst is re-keyed onto the CALLER's symbols by
   SymbolName, so that a chart read from a file and a system read from
   another file cannot end up in different contexts and silently
   substitute nothing (trap P2, in its chart form). *)
masterTransportChartData[chart_, sourceVariables_List] := Module[
  {chartVariables, subst, substNames, sourceNames, f, g, jacobian, det,
   root, rootSquare, rootOK},
  If[! masterTransportChartRecordQ[chart],
    Return[<|"Status" -> "ChartNotWellFormed"|>]];
  chartVariables = chart["Variables"];
  sourceNames = SymbolName /@ sourceVariables[[{1, 2}]];
  subst = chart["Subst"];
  substNames = SymbolName /@ (First /@ subst);
  If[substNames =!= sourceNames,
    Return[<|"Status" -> "ChartVariablesMismatch", "Expected" -> sourceNames,
      "Found" -> substNames|>]];
  If[Length[DeleteDuplicates[Join[sourceNames, SymbolName /@ chartVariables]]] =!= 4,
    Return[<|"Status" -> "ChartVariablesCollide"|>]];
  {f, g} = Together /@ (Last /@ subst);
  If[! AllTrue[{f, g}, masterTransportRationalQ[#, chartVariables] &],
    Return[<|"Status" -> "ChartNotRational"|>]];
  If[Complement[masterTransportFreeSymbols[{f, g}], chartVariables] =!= {},
    Return[<|"Status" -> "ChartCarriesForeignSymbols",
      "Symbols" -> Complement[masterTransportFreeSymbols[{f, g}], chartVariables]|>]];
  jacobian = Map[Together, {
    {D[f, chartVariables[[1]]], D[f, chartVariables[[2]]]},
    {D[g, chartVariables[[1]]], D[g, chartVariables[[2]]]}}, {2}];
  det = Together[Det[jacobian]];
  If[TrueQ[det === 0], Return[<|"Status" -> "ChartJacobianDegenerate"|>]];
  root = Lookup[chart, "Root", None];
  rootSquare = Lookup[chart, "RootSquare", None];
  (* If the chart declares both, the rationalization statement itself is
     an exact identity and is checked here rather than believed. *)
  rootOK = If[root === None || rootSquare === None || MissingQ[root] ||
      MissingQ[rootSquare], None,
    TrueQ[Together[root^2 - (rootSquare /. {sourceVariables[[1]] -> f,
      sourceVariables[[2]] -> g})] === 0]];
  If[rootOK === False, Return[<|"Status" -> "ChartRootSquareInconsistent"|>]];
  (* A chart may rationalize SEVERAL quadratics (the joint charts of
     TransportCharts.wl): every declared root is checked against its own
     RootSquare, exactly, and carried through under "Roots" so that a
     conic record can be composed with whichever root it needs. *)
  Module[{roots, rootsOK},
    roots = Lookup[chart, "Roots", None];
    If[! ListQ[roots],
      roots = If[root === None || rootSquare === None || MissingQ[root] || MissingQ[rootSquare],
        {}, {<|"Root" -> root, "RootSquare" -> rootSquare|>}]];
    rootsOK = AllTrue[roots, TrueQ[Together[#["Root"]^2 - (#["RootSquare"] /.
      {sourceVariables[[1]] -> f, sourceVariables[[2]] -> g})] === 0] &];
    If[! rootsOK, Return[<|"Status" -> "ChartRootSquareInconsistent", "Roots" -> roots|>]];
    <|"Status" -> "OK", "Kind" -> Lookup[chart, "Kind", "TwoVariable"],
      "Name" -> Lookup[chart, "Name", None],
      "CoefficientField" -> Lookup[chart, "CoefficientField", "Rational"],
      "Variables" -> chartVariables, "SourceVariables" -> sourceVariables[[{1, 2}]],
      "Subst" -> {sourceVariables[[1]] -> f, sourceVariables[[2]] -> g},
      "Jacobian" -> jacobian, "JacobianDet" -> det,
      "Root" -> If[MissingQ[root], None, root],
      "RootSquare" -> If[MissingQ[rootSquare], None, rootSquare],
      "RootSquareConsistent" -> rootOK,
      "Roots" -> roots,
      "Parents" -> Lookup[chart, "Parents", <||>]|>]
];

(* Chain rule for a matrix-valued 1-form.  av, aw are already expressed
   in the chart variables; the tangent factors come from the chart
   Jacobian and are NOT substituted into anything (same discipline as
   masterTransportPathMatrix). *)
masterTransportPullBackOneForm[av_, aw_, jacobian_] := {
  Map[Together, av jacobian[[1, 1]] + aw jacobian[[2, 1]], {2}],
  Map[Together, av jacobian[[1, 2]] + aw jacobian[[2, 2]], {2}]};

Options[masterTransportPullBackSystem] = {
  "SourceVariables" -> Automatic,
  "FlatnessCheck" -> True
};

masterTransportPullBackSystem[system_Association, chart_,
    opts : OptionsPattern[]] := Module[
  {sourceVariables, data, av, aw, avc, awc, ax, ay, x, y, flatSource,
   flatChart, surviving},
  sourceVariables = OptionValue["SourceVariables"];
  If[sourceVariables === Automatic,
    sourceVariables = masterTransportDefaultVariables[]];
  If[! MatchQ[sourceVariables, {_Symbol, __Symbol}],
    Return[<|"Status" -> "SourceVariablesInvalid"|>]];
  data = If[AssociationQ[chart] && Lookup[chart, "Status", None] === "OK" &&
      KeyExistsQ[chart, "Jacobian"], chart,
    masterTransportChartData[chart, sourceVariables]];
  If[data["Status"] =!= "OK", Return[data]];
  {x, y} = data["Variables"];
  av = Lookup[system, "Av", $Failed];
  aw = Lookup[system, "Aw", $Failed];
  If[! (MatrixQ[av] && MatrixQ[aw] && Dimensions[av] === Dimensions[aw] &&
        Length[av] === Length[First[av]]),
    Return[<|"Status" -> "SystemNotASquareMatrixPair"|>]];
  (* Refuse a non-flat source outright: the chain rule would produce a
     chart system whose own flatness check then fails for a reason that
     has nothing to do with the chart. *)
  flatSource = If[masterTransportCheckLevel[] === "Production",
    masterTransportPointZeroQ[
      D[av, sourceVariables[[2]]] - D[aw, sourceVariables[[1]]] +
        av . aw - aw . av,
      Join[sourceVariables[[{1, 2}]], DeleteDuplicates[Cases[{av, aw},
        s_Symbol /; ! MemberQ[sourceVariables, s] && Context[s] =!= "System`", {0, Infinity}]]]],
    masterTransportZeroMatQ[
      D[av, sourceVariables[[2]]] - D[aw, sourceVariables[[1]]] +
        av . aw - aw . av]];
  If[! TrueQ[flatSource], Return[<|"Status" -> "SourceSystemNotFlat"|>]];
  avc = Map[Together, av /. data["Subst"], {2}];
  awc = Map[Together, aw /. data["Subst"], {2}];
  surviving = Cases[{avc, awc},
    s_Symbol /; MemberQ[SymbolName /@ sourceVariables[[{1, 2}]], SymbolName[s]],
    {0, Infinity}, Heads -> True];
  If[surviving =!= {},
    Return[<|"Status" -> "SourceVariablesSurviveSubstitution",
      "Symbols" -> DeleteDuplicates[surviving]|>]];
  {ax, ay} = masterTransportPullBackOneForm[avc, awc, data["Jacobian"]];
  flatChart = If[TrueQ[OptionValue["FlatnessCheck"]],
    masterTransportZeroMatQ[D[ax, y] - D[ay, x] + ax . ay - ay . ax],
    "NotPerformed"];
  If[flatChart =!= "NotPerformed" && ! TrueQ[flatChart],
    Return[<|"Status" -> "ChartSystemNotFlat"|>]];
  <|"Status" -> "OK",
    "System" -> Join[KeyDrop[system, {"Av", "Aw"}], <|"Av" -> ax, "Aw" -> ay|>],
    "Ax" -> ax, "Ay" -> ay, "Variables" -> {x, y}, "Chart" -> data,
    "Certificate" -> <|
      "SourceFlat" -> flatSource,
      "ChartFlat" -> flatChart,
      "ChartRational" -> True,
      "RootSquareConsistent" -> data["RootSquareConsistent"],
      "ChainRule" ->
        "Ax = Av d_x v + Aw d_x w, Ay = Av d_y v + Aw d_y w (Together'd)",
      "JacobianDet" -> data["JacobianDet"],
      "Exact" -> True|>|>
];

(* The record's own coordinates as rational functions of the chart
   variables, plus the exact identity that licenses the composition.
   Three frames, one uniform answer {m1(x,y), m2(x,y)}:

     rational frame       {f, g}                       (identity check)
     target chart         {x, y}                       (Subst must match)
     single-conic chart   {f, tmap} or {tmap, f}       (linear root solve,
                                                        then the exact
                                                        chart identity) *)
masterTransportRecordCoordinateMap[record_Association, data_Association,
    conicRoute_] := Module[
  {sourceVariables, chartVariables, sourceNames, chartNames, recVariables,
   recNames, recChart, recSubst, f, g, fixed, parameter, fixedIndex,
   conicSubst, conicRoot, rootPulled, a, b, candidates, accepted, other,
   otherName, identity},
  sourceVariables = data["SourceVariables"];
  chartVariables = data["Variables"];
  sourceNames = SymbolName /@ sourceVariables;
  chartNames = SymbolName /@ chartVariables;
  {f, g} = Last /@ data["Subst"];
  recVariables = Lookup[record, "Variables", sourceVariables];
  (* --- frame 4: a ONE-VARIABLE root record (class 115: Variables {u},
         Chart <|"Definition" -> u^2 == 1 - 4 v w, ...|>).  Its T depends
         on u alone; in a target chart that rationalizes the same
         quadratic, u is the chart's rational root (either sign) and the
         identity root^2 == RootSquare o Subst licenses the map. ---------- *)
  If[MatchQ[recVariables, {_Symbol}] && AssociationQ[Lookup[record, "Chart", None]] &&
     MatchQ[Lookup[record["Chart"], "Definition", None], _Equal],
    Module[{u, definition, square, roots, tf, tg, matching},
      u = recVariables[[1]];
      definition = record["Chart"]["Definition"];
      (* Definition is u^2 == Q(v,w) or Q(v,w) == u^2 *)
      square = Which[
        TrueQ[Together[First[definition] - u^2] === 0], Last[definition],
        TrueQ[Together[Last[definition] - u^2] === 0], First[definition],
        True, $Failed];
      If[square === $Failed,
        Return[<|"Status" -> "ClassFormOneVariableDefinitionNotSquare"|>]];
      {tf, tg} = Last /@ data["Subst"];
      roots = Lookup[data, "Roots", {}];
      matching = Select[roots, TrueQ[Together[#["RootSquare"] - square] === 0] &&
        TrueQ[Together[#["Root"]^2 - (square /. {sourceVariables[[1]] -> tf,
          sourceVariables[[2]] -> tg})] === 0] &];
      If[matching === {},
        Return[<|"Status" -> "ClassFormOneVariableRootNotRationalized",
          "Definition" -> definition|>]];
      Return[<|"Status" -> "OK", "Frame" -> "OneVariableRoot",
        "Map" -> {u -> First[matching]["Root"]},
        "Images" -> {First[matching]["Root"]},
        "CompositionIdentity" ->
          "target root^2 equals the record's Definition square pulled back \
through the target Subst (exact); the record's single variable is that root",
        "CompositionExact" -> True|>]]];
  If[! MatchQ[recVariables, {_Symbol, _Symbol}],
    Return[<|"Status" -> "ClassFormVariablesInvalid"|>]];
  recNames = SymbolName /@ recVariables;
  recChart = Lookup[record, "Chart", None];
  If[MissingQ[recChart], recChart = None];
  (* a bare rule list is accepted as a chart substitution, which is how
     the hard-class artifacts store it *)
  recSubst = Which[
    AssociationQ[recChart], Lookup[recChart, "Subst", None],
    MatchQ[recChart, {_Rule, _Rule}], recChart,
    True, None];

  (* --- frame 1: rational, Variables {v,w} and no chart -------------- *)
  If[recNames === sourceNames && (recChart === None || recChart === Null),
    Return[<|"Status" -> "OK", "Frame" -> "Rational",
      "Map" -> {recVariables[[1]] -> f, recVariables[[2]] -> g},
      "Images" -> {f, g},
      "CompositionIdentity" -> "by construction (record frame = source frame)",
      "CompositionExact" -> True|>]];

  (* --- frame 2: already the target chart ---------------------------- *)
  If[recNames === chartNames,
    If[! MatchQ[recSubst, {_Rule, _Rule}],
      Return[<|"Status" -> "ClassFormChartMissingSubstitution"|>]];
    (* the stored chart must be THE target chart, entry by entry and
       exactly; a record in a different two-variable chart is a different
       frame and is refused rather than used *)
    identity = And @@ Table[
      Module[{nm = SymbolName[First[recSubst[[i]]]], target},
        target = Which[
          nm === sourceNames[[1]], f,
          nm === sourceNames[[2]], g,
          True, $Failed];
        target =!= $Failed &&
          TrueQ[Together[Last[recSubst[[i]]] - target] === 0]],
      {i, Length[recSubst]}];
    If[TrueQ[identity],
      Return[<|"Status" -> "OK", "Frame" -> "TargetChart",
        "Map" -> {recVariables[[1]] -> chartVariables[[1]],
                  recVariables[[2]] -> chartVariables[[2]]},
        "Images" -> chartVariables,
        "CompositionIdentity" ->
          "stored Subst equals the target chart Subst (exact)",
        "CompositionExact" -> True|>]]];

  (* --- frame 2b: a DIFFERENT two-variable chart that the target chart
         composes with rationally (a joint chart of TransportCharts.wl
         rationalizes the record's root, or the record's chart is the
         target's parent).  The record's variables are solved for with
         the target's rational root and the result is accepted only if
         the record's Subst reproduces the target Subst EXACTLY. ------ *)
  If[MatchQ[recSubst, {_Rule, _Rule}] && AssociationQ[recChart] &&
     Lookup[recChart, "Kind", "TwoVariable"] === "TwoVariable" &&
     ! KeyExistsQ[recChart, "Fixed"],
    Module[{composed},
      composed = masterTransportComposeTwoVariableRecord[
        Join[recChart, <|"Variables" -> recVariables, "Subst" -> recSubst|>],
        data, sourceVariables];
      If[AssociationQ[composed] && composed["Status"] === "OK",
        Return[<|"Status" -> "OK", "Frame" -> "TwoVariableComposition",
          "Map" -> composed["Map"], "Images" -> composed["Images"],
          "CompositionRoute" -> Lookup[composed, "Route", "Solve"],
          "CompositionIdentity" ->
            "record Subst at the solved record variables equals the target \
chart Subst (exact); record variables obtained from the target's rational \
root of the record's RootSquare",
          "CompositionExact" -> True|>],
        Return[<|"Status" -> "ClassFormChartIsADifferentChart",
          "Composition" -> composed|>]]]];

  (* --- frame 3: single-conic chart ---------------------------------- *)
  If[AssociationQ[recChart] && ! MissingQ[Lookup[recChart, "Fixed", Missing[]]] &&
      ! MissingQ[Lookup[recChart, "Root", Missing[]]],
    If[conicRoute === False,
      Return[<|"Status" -> "ClassFormConicChartRefused"|>]];
    fixed = recChart["Fixed"];
    fixedIndex = Position[recNames, SymbolName[fixed]];
    If[Length[fixedIndex] =!= 1,
      Return[<|"Status" -> "ClassFormConicFixedVariableNotFound"|>]];
    fixedIndex = fixedIndex[[1, 1]];
    parameter = recVariables[[3 - fixedIndex]];
    other = If[SymbolName[fixed] === sourceNames[[1]], sourceVariables[[2]],
      sourceVariables[[1]]];
    otherName = SymbolName[other];
    conicSubst = Lookup[recChart, "Subst", None];
    If[! MatchQ[conicSubst, _Rule],
      Return[<|"Status" -> "ClassFormConicSubstitutionInvalid"|>]];
    If[SymbolName[First[conicSubst]] =!= otherName,
      Return[<|"Status" -> "ClassFormConicSubstitutionInvalid"|>]];
    If[data["Root"] === None && Lookup[data, "Roots", {}] === {},
      Return[<|"Status" -> "ClassFormConicChartNotPullable",
        "Reason" -> "the target chart declares no rational Root"|>]];
    (* the conic Root is the algebraic function the target chart
       rationalizes; equate and solve LINEARLY for the conic parameter *)
    conicRoot = Together[recChart["Root"] /.
      {sourceVariables[[1]] -> f, sourceVariables[[2]] -> g}];
    conicRoot = Together[conicRoot /. If[SymbolName[fixed] === sourceNames[[1]],
      fixed -> f, fixed -> g]];
    If[! PolynomialQ[conicRoot, parameter] ||
       Exponent[conicRoot, parameter] =!= 1,
      Return[<|"Status" -> "ClassFormConicChartNotPullable",
        "Reason" -> "the conic Root is not linear in the chart parameter"|>]];
    a = Together[Coefficient[conicRoot, parameter, 1]];
    b = Together[conicRoot - a parameter];
    If[TrueQ[a === 0],
      Return[<|"Status" -> "ClassFormConicChartNotPullable",
        "Reason" -> "the conic Root does not involve the chart parameter"|>]];
    (* every root the target chart declares is tried, both signs: a joint
       chart rationalizes several quadratics and the record does not say
       which one it needs -- the exact identity below decides *)
    candidates = DeleteDuplicates[Flatten[Table[
      Together[(sign r - b)/a],
      {r, DeleteDuplicates[Join[
        If[data["Root"] === None, {}, {data["Root"]}],
        (#["Root"] & /@ Lookup[data, "Roots", {}])]]},
      {sign, {1, -1}}]]];
    accepted = Select[candidates,
      TrueQ[Together[(Last[conicSubst] /.
        {parameter -> #, fixed -> If[SymbolName[fixed] === sourceNames[[1]], f, g]}) -
        If[otherName === sourceNames[[2]], g, f]] === 0] &];
    If[accepted === {},
      Return[<|"Status" -> "ClassFormConicChartNotPullable",
        "Reason" -> "neither root branch reproduces the target chart substitution",
        "Candidates" -> candidates|>]];
    Return[<|"Status" -> "OK", "Frame" -> "SingleConicChart",
      "Map" -> {fixed -> If[SymbolName[fixed] === sourceNames[[1]], f, g],
                parameter -> First[accepted]},
      "Images" -> If[fixedIndex === 1,
        {If[SymbolName[fixed] === sourceNames[[1]], f, g], First[accepted]},
        {First[accepted], If[SymbolName[fixed] === sourceNames[[1]], f, g]}],
      "Parameter" -> parameter,
      "ParameterMap" -> First[accepted],
      "Branch" -> If[First[accepted] === First[candidates], "+", "-"],
      "CompositionIdentity" ->
        "conic Subst at the solved parameter equals the target chart Subst (exact)",
      "CompositionExact" -> True|>]];

  <|"Status" -> "ClassFormFrameUnknown", "RecordVariables" -> recNames|>
];

Options[masterTransportPullBackClassForm] = {
  "SourceVariables" -> Automatic,
  "Regulator" -> Automatic,
  "BlockSystem" -> None,
  "ConicChartRoute" -> Automatic,
  "Swap" -> Automatic,
  "ClassID" -> None,
  "CoefficientField" -> Automatic
};

(* The v <-> w swap, and why it is part of composing a class form with a
   chart at all.

   ClassifyBlocks defines class equivalence as a basis permutation
   OPTIONALLY COMPOSED WITH v <-> w.  A class member's connection
   therefore need NOT equal the representative's, and three of them here
   do not: measured 2026-08-16, CF258 rows {5} and {24} and CF230 row {7}
   are 1x1 blocks whose stored class form is the representative's with
   the two variables exchanged.  Consuming such a record unswapped is the
   wrong-frame error again, one level down.

   In this chart the swap is the involution (x,y) -> (1-x,1-y): it
   carries v = x y to w = (1-x)(1-y) and back, so composing with it is
   nothing more than exchanging the two images of the chart
   substitution.  RootSquare is symmetric in (v,w) and the root only
   changes sign, which the conic route's two branches already cover, so
   no other datum moves.

   The swap is TRIED, never assumed.  Acceptance is the same exact
   re-derivation from the block system plus the stored-EpsForm identity,
   so a wrong guess cannot pass; what the attempt buys is that a genuine
   swap member is transported instead of refused. *)
masterTransportChartSwapData[data_Association] :=
  Module[{f, g, sourceVariables, chartVariables, jacobian},
    sourceVariables = data["SourceVariables"];
    chartVariables = data["Variables"];
    {f, g} = Last /@ data["Subst"];
    jacobian = Map[Together, {
      {D[g, chartVariables[[1]]], D[g, chartVariables[[2]]]},
      {D[f, chartVariables[[1]]], D[f, chartVariables[[2]]]}}, {2}];
    Join[data, <|
      "Subst" -> {sourceVariables[[1]] -> g, sourceVariables[[2]] -> f},
      "Jacobian" -> jacobian, "JacobianDet" -> Together[Det[jacobian]],
      "Swapped" -> True|>]
  ];


masterTransportPullBackClassFormOnce[rec_Association, data_Association,
    eps_Symbol, blockSystem_, conicRoute_, classID_, swapped_,
    coefficientField_] := Module[
  {coordinates, x, y, t, tx, detTx, tInverse, inverseOK, ax, ay, ex, ey,
   epsLinear, stored, storedPulled, matches, jacobian, images, foreign,
   evaluate, identity, result, repChart, permutation,
   rationalTransformation, recordVariables, recordAlphabet, pulledAlphabet},
  If[! MemberQ[{"Rational", "Multiquadratic"}, coefficientField],
    Return[<|"Status" -> "ClassFormCoefficientFieldInvalid",
      "CoefficientField" -> coefficientField|>]];
  {x, y} = data["Variables"];
  coordinates = masterTransportRecordCoordinateMap[rec, data, conicRoute];
  If[coordinates["Status"] =!= "OK", Return[coordinates]];
  t = Lookup[rec, "Transformation", $Failed];
  If[! MatrixQ[t], Return[<|"Status" -> "ClassFormNoTransformation"|>]];
  images = coordinates["Images"];
  tx = Map[Together, t /. coordinates["Map"], {2}];
  foreign = Complement[masterTransportFreeSymbols[tx], {x, y, eps}];
  If[foreign =!= {},
    Return[<|"Status" -> "ClassFormCarriesForeignSymbols", "Symbols" -> foreign|>]];
  rationalTransformation =
    AllTrue[Flatten[tx], masterTransportRationalQ[#, {x, y}] &];
  If[coefficientField === "Rational" && ! TrueQ[rationalTransformation],
    Return[<|"Status" -> "ClassFormTransformationNotRationalInChart"|>]];
  detTx = Together[Det[tx]];
  If[TrueQ[detTx === 0],
    Return[<|"Status" -> "ClassFormTransformationSingularInChart"|>]];
  (* The inverse is computed once and RE-MULTIPLIED OUT, both ways, so
     that handing it to the assembly is a certified shortcut and not a
     trusted one -- the same discipline as a closed-form sector's
     PhiInverse. *)
  tInverse = Map[Together, Inverse[tx], {2}];
  inverseOK = masterTransportZeroMatQ[tx . tInverse - IdentityMatrix[Length[tx]]] &&
    masterTransportZeroMatQ[tInverse . tx - IdentityMatrix[Length[tx]]];
  If[! TrueQ[inverseOK],
    Return[<|"Status" -> "ClassFormTransformationInverseNotVerified"|>]];

  (* The chart epsilon-form is RE-DERIVED from the pulled-back block
     system.  Without that system there is nothing to re-derive it from,
     and a transformation pulled back but never re-verified is exactly
     the "stored flag as evidence" this module refuses everywhere else. *)
  If[! MatchQ[blockSystem, {_?MatrixQ, _?MatrixQ}],
    Return[<|"Status" -> "ClassFormNoBlockSystemToVerifyAgainst"|>]];
  {ax, ay} = blockSystem;
  If[Dimensions[ax] =!= Dimensions[tx] || Dimensions[ay] =!= Dimensions[tx],
    Return[<|"Status" -> "ClassFormBlockDimensionMismatch"|>]];

  (* The stored EpsForm is provenance.  It is pulled back by the same
     chain rule and COMPARED; a disagreement means the record does not
     describe this block as it stands, and that is a refusal, not a note.
     It is pulled back HERE, before the gate, because it is also what the
     member's basis permutation is recovered from (below). *)
  stored = Lookup[rec, "EpsForm", None];
  storedPulled = None;
  If[MatchQ[stored, {_?MatrixQ, _?MatrixQ}] &&
      Dimensions[stored[[1]]] === Dimensions[tx] &&
      Dimensions[stored[[2]]] === Dimensions[tx],
    jacobian = Map[Together, {
      {D[images[[1]], x], D[images[[1]], y]},
      {D[images[[2]], x], D[images[[2]], y]}}, {2}];
    storedPulled = masterTransportPullBackOneForm[
      Map[Together, stored[[1]] /. coordinates["Map"], {2}],
      Map[Together, stored[[2]] /. coordinates["Map"], {2}], jacobian]];
  (* A dlog alphabet pulls back functorially: dlog L becomes
       dlog (L o chart).
     Preserve that information while the class chart is still known.
     Recover it from the rational class form when older records did not
     store an explicit Alphabet; factoring the already algebraic target
     form later loses the conjugate letters and made the whole-family
     multiquadratic dlog certificate fail despite every gauge identity
     passing (CF300, 2026-08-29). *)
  recordVariables = Lookup[rec, "Variables", First /@ coordinates["Map"]];
  recordAlphabet = Lookup[rec, "Alphabet", Missing["NotStored"]];
  If[! ListQ[recordAlphabet] && MatchQ[stored, {_?MatrixQ, _?MatrixQ}] &&
      ListQ[recordVariables],
    recordAlphabet = Quiet[Check[
      familyCertLetters[stored, recordVariables, eps], {}]]];
  pulledAlphabet = If[ListQ[recordAlphabet],
    DeleteDuplicates[DeleteCases[
      Quiet[Check[Together[#1 /. coordinates["Map"]], $Failed]] & /@
        Select[recordAlphabet, FreeQ[#1, eps] &], $Failed]],
    {}];

  (* One candidate basis permutation q, put through both exact gates.
     (P T P^T)^-1 = P T^-1 P^T exactly, so the inverse that was just
     re-multiplied out both ways is permuted rather than recomputed, and
     the epsilon-form of a permuted member is the representative's
     permuted the same way. *)
  evaluate[q_] := Module[{qx, qi, qex, qey, qstored, qlinear, qmatch},
    qx = tx[[q, q]];
    qi = tInverse[[q, q]];
    qex = Map[Together, qi . ax . qx - qi . D[qx, x], {2}];
    qey = Map[Together, qi . ay . qx - qi . D[qx, y], {2}];
    qlinear = AllTrue[Flatten[{qex, qey}],
      (TrueQ[Together[#] === 0] || FreeQ[Together[#/eps], eps]) &];
    qstored = If[storedPulled === None, None,
      {storedPulled[[1]][[q, q]], storedPulled[[2]][[q, q]]}];
    qmatch = If[qstored === None, None,
      masterTransportZeroMatQ[qstored[[1]] - qex] &&
        masterTransportZeroMatQ[qstored[[2]] - qey]];
    <|"Permutation" -> q, "T" -> qx, "TInverse" -> qi, "Ex" -> qex, "Ey" -> qey,
      "EpsFormLinear" -> qlinear, "Matches" -> qmatch,
      "OK" -> TrueQ[qlinear] && (qmatch === None || TrueQ[qmatch])|>];

  identity = Range[Length[tx]];
  result = evaluate[identity];
  permutation = None;
  (* Class equivalence is a basis PERMUTATION composed with the optional
     v <-> w swap.  The swap is the caller's business -- in this chart it
     is the involution (x,y) -> (1-x,1-y), which the caller applies by
     exchanging the two chart images -- but the PERMUTATION was missing
     here, so a permuted member was refused as
     ClassFormNotEpsFormInChart / ClassFormStoredEpsFormMismatch.  It is
     recovered from the representative's own chart connection,
     A_rep = (T . E + dT) . T^-1, and then put through the same two exact
     gates, so a wrong candidate cannot pass. *)
  If[! TrueQ[result["OK"]] && storedPulled =!= None && Length[tx] > 1,
    repChart = {
      Map[Together, (tx . storedPulled[[1]] + D[tx, x]) . tInverse, {2}],
      Map[Together, (tx . storedPulled[[2]] + D[tx, y]) . tInverse, {2}]};
    permutation = masterTransportClassMemberPermutation[repChart, {ax, ay},
      {x, y}, eps];
    If[ListQ[permutation] && permutation =!= identity,
      Module[{candidate = evaluate[permutation]},
        If[TrueQ[candidate["OK"]], result = candidate]]]];

  {ex, ey} = {result["Ex"], result["Ey"]};
  epsLinear = result["EpsFormLinear"];
  matches = result["Matches"];
  If[! TrueQ[epsLinear],
    Return[<|"Status" -> "ClassFormNotEpsFormInChart",
      "ClassID" -> classID, "Frame" -> coordinates["Frame"],
      "PermutationTried" -> permutation|>]];
  If[matches =!= None && ! TrueQ[matches],
    Return[<|"Status" -> "ClassFormStoredEpsFormMismatch",
      "ClassID" -> classID, "Frame" -> coordinates["Frame"],
      "PermutationTried" -> permutation|>]];

  <|"Status" -> "OK", "Type" -> "EpsForm", "T" -> result["T"],
    "TInverse" -> result["TInverse"],
    "Ev" -> ex, "Ew" -> ey,
    "Alphabet" -> pulledAlphabet,
    "Source" -> "chart-pullback", "ClassID" -> classID,
    "Frame" -> coordinates["Frame"], "Variables" -> {x, y},
    "Coordinates" -> coordinates, "Swapped" -> swapped,
    "Permutation" -> result["Permutation"],
    "Certificate" -> <|
      "Frame" -> coordinates["Frame"],
      "CompositionExact" -> coordinates["CompositionExact"],
      "CompositionIdentity" -> coordinates["CompositionIdentity"],
      "CoefficientField" -> coefficientField,
      "TransformationRationalInChart" -> rationalTransformation,
      "TransformationInvertible" -> True,
      "TransformationInverseVerified" -> inverseOK,
      "EpsFormReDerivedFromBlockSystem" -> True,
      "EpsFormLinear" -> epsLinear,
      "StoredEpsFormPullbackMatches" -> matches,
      "Swapped" -> swapped,
      "Permutation" -> result["Permutation"],
      "Exact" -> True|>|>
];

masterTransportPullBackClassForm[record_Association, chart_,
    opts : OptionsPattern[]] := Module[
  {sourceVariables, data, eps, rec, swap, attempts, results, found, attempt,
   coefficientField},
  sourceVariables = OptionValue["SourceVariables"];
  If[sourceVariables === Automatic,
    sourceVariables = masterTransportDefaultVariables[]];
  data = If[AssociationQ[chart] && Lookup[chart, "Status", None] === "OK" &&
      KeyExistsQ[chart, "Jacobian"], chart,
    masterTransportChartData[chart, sourceVariables]];
  If[data["Status"] =!= "OK", Return[data]];
  coefficientField = OptionValue["CoefficientField"];
  If[coefficientField === Automatic,
    coefficientField = Lookup[data, "CoefficientField", "Rational"]];
  If[! MemberQ[{"Rational", "Multiquadratic"}, coefficientField],
    Return[<|"Status" -> "ClassFormCoefficientFieldInvalid",
      "CoefficientField" -> coefficientField|>]];
  eps = OptionValue["Regulator"];
  If[eps === Automatic,
    eps = masterTransportDetectRegulator[record,
      Join[data["SourceVariables"], data["Variables"]]]];
  If[! MatchQ[eps, _Symbol],
    Return[<|"Status" -> "ClassFormRegulatorUnresolved"|>]];
  (* One normalization for the whole record, by SymbolName, before any
     substitution: a record read from a file carries its own v, w, x, y
     and eps, and substituting the caller's symbols into a record written
     with different ones matches nothing while reporting success. *)
  rec = masterTransportNormalize[record, eps,
    Join[data["SourceVariables"], data["Variables"]]];
  swap = OptionValue["Swap"];
  attempts = Switch[swap, True, {True}, False, {False}, _, {False, True}];
  (* M2: no Return inside the Do -- it would return from the Do, and an
     inner Module would swallow a Return[..., Module] as well. *)
  results = {}; found = None;
  Do[
    If[found === None,
      attempt = masterTransportPullBackClassFormOnce[rec,
        If[TrueQ[s], masterTransportChartSwapData[data], data], eps,
        OptionValue["BlockSystem"], OptionValue["ConicChartRoute"],
        OptionValue["ClassID"], TrueQ[s], coefficientField];
      results = Append[results, attempt];
      If[AssociationQ[attempt] && attempt["Status"] === "OK",
        found = attempt]],
    {s, attempts}];
  (* the UNSWAPPED refusal is the one reported, because it names what the
     record actually is *)
  If[found =!= None, found, First[results]]
];


(* One block specification of TransportFamily, moved into the chart.
   The returned specification carries T only: Ev and Ew are deliberately
   left for masterTransportAssemble to re-derive from the chart block
   system, so the eps-form statement is made twice, independently, from
   the same system. *)
masterTransportChartBlockSpec[specification_, rows_List, ax_, ay_,
    data_Association, eps_Symbol, formDirectory_, conicRoute_,
    coefficientField_] := Module[
  {record, file, classID, blockSystem, pulled, loaded},
  blockSystem = {ax[[rows, rows]], ay[[rows, rows]]};
  classID = None;
  record = Which[
    specification === Automatic,
      If[Length[rows] === 1,
        Return[<|"Status" -> "OK", "Spec" -> Automatic,
          "Certificate" -> <|"Frame" -> "ScalarAutomatic",
            "Note" -> "1x1 block; the scalar dlog provider runs in the chart \
variables and its form is certified by the assembly as usual"|>|>],
        Return[<|"Status" -> "ChartBlockNoProvider", "Rows" -> rows|>]],
    IntegerQ[specification],
      classID = specification;
      If[! StringQ[formDirectory] || ! DirectoryQ[formDirectory],
        Return[<|"Status" -> "ChartFormDirectoryMissing", "Rows" -> rows|>]];
      file = FileNameJoin[{formDirectory, "class" <> ToString[specification] <> ".wl"}];
      If[! FileExistsQ[file],
        Return[<|"Status" -> "FormFileMissing", "File" -> file, "Rows" -> rows|>]];
      (* M2/scoping: the read is NOT wrapped in an inner Module, because
         Return inside one exits that Module and its value would then be
         used as the record instead of refusing. *)
      loaded = masterTransportGetGlobal[file];
      If[! AssociationQ[loaded],
        Return[<|"Status" -> "FormFileUnreadable", "File" -> file, "Rows" -> rows|>]];
      loaded,
    AssociationQ[specification] &&
      Lookup[specification, "Type", None] === "ClosedFormSector",
      Return[<|"Status" -> "ChartClosedFormSectorNotSupported", "Rows" -> rows,
        "Reason" -> "a fundamental matrix is certified in its own frame; \
pulling one back is not a rational operation and is not attempted here"|>],
    AssociationQ[specification] && KeyExistsQ[specification, "Record"],
      classID = Lookup[specification, "ClassID", None];
      specification["Record"],
    AssociationQ[specification] && KeyExistsQ[specification, "Transformation"],
      classID = Lookup[specification, "ClassID", None];
      specification,
    AssociationQ[specification] && MatrixQ[Lookup[specification, "T", $Failed]],
      (* an explicit {"Type" -> "EpsForm", "T" -> ...} provider, given in
         the SOURCE frame *)
      Join[<|"Transformation" -> specification["T"],
        "Variables" -> data["SourceVariables"]|>,
        If[MatrixQ[Lookup[specification, "Ev", $Failed]] &&
           MatrixQ[Lookup[specification, "Ew", $Failed]],
          <|"EpsForm" -> {specification["Ev"], specification["Ew"]}|>, <||>]],
    True, Return[<|"Status" -> "ChartUnknownProvider", "Rows" -> rows|>]];
  pulled = masterTransportPullBackClassForm[record, data,
    "SourceVariables" -> data["SourceVariables"], "Regulator" -> eps,
    "BlockSystem" -> blockSystem, "ConicChartRoute" -> conicRoute,
    "ClassID" -> classID, "CoefficientField" -> coefficientField];
  If[pulled["Status"] =!= "OK",
    Return[Join[pulled, <|"Rows" -> rows, "ClassID" -> classID|>]]];
  (* Ev, Ew and TInverse travel with the specification because they were
     just derived and CERTIFIED here (the inverse re-multiplied out both
     ways, the epsilon-form re-derived from this very block system).  The
     assembly still recomputes the conjugated diagonal block from T and
     compares it against them -- "DiagonalEqualsDeclaredForm" -- so the
     statement is still made twice, independently, and what is saved is
     one redundant 4x4 symbolic inverse per hard block, not a check. *)
  <|"Status" -> "OK", "Rows" -> rows, "ClassID" -> classID,
    "Spec" -> <|"Type" -> "EpsForm", "T" -> pulled["T"],
      "TInverse" -> pulled["TInverse"],
      "Ev" -> pulled["Ev"], "Ew" -> pulled["Ew"],
      "Alphabet" -> Lookup[pulled, "Alphabet", {}]|>,
    "Form" -> pulled, "Certificate" -> pulled["Certificate"]|>
];

masterTransportChartNotes[data_Association, basePoint_, target_,
    direction_] := <|
  "Kind" -> data["Kind"],
  "Variables" -> data["Variables"],
  "SourceVariables" -> data["SourceVariables"],
  "Subst" -> data["Subst"],
  "Jacobian" -> data["Jacobian"],
  (* d(v,w)/d(x,y).  For v = x y, w = (1-x)(1-y) this is x - y, the same
     rational function as sqrt(lambda) in this chart -- which is why the
     chart rationalizes it, and which a later stage needs in order to
     choose a chamber and a branch. *)
  "JacobianDet" -> data["JacobianDet"],
  "Root" -> data["Root"],
  "RootSquare" -> data["RootSquare"],
  "RootSquareConsistent" -> data["RootSquareConsistent"],
  "Path" -> <|"Direction" -> direction, "BasePoint" -> basePoint,
    "Target" -> target,
    "Reason" -> "the pulled-back alphabet carries bilinear letters \
(x + y - x y, x + y - 2 x y), which are quadratic in the path parameter on a \
generic straight segment and linear on an axis-aligned one",
    "DECheckDirection" -> "the per-order check against the original family \
differential equation is made along this segment; the two-directional \
statements are the assembly certificate (flatness, diagonal blocks equal to \
their declared forms in BOTH chart variables)"|>,
  "PhysicsBookkeeping" -> "none is done here: no chamber, no branch and no \
sign choice; the chart and its Jacobian determinant are recorded so that a \
later stage can make them"|>;

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

(* The recurrence alone, on a caller-supplied block-pair order table
   (split out 2026-08-31, Codex note 07).  Table contract: strictly
   lower-triangular minimum regulator orders, Infinity for absent
   edges -- exactly what masterTransportDepthBudget builds by scanning
   ahat.  A path-restricted connection can be gigabytes while its
   per-entry orders are bounded conservatively by the SOURCE pair
   before pullback (the path map and Jacobian are regulator-free, and
   a cancellation can only RAISE the true order), so a table caller
   may over-demand coefficients but can never under-budget.  The
   expression-scan route above stays as the diagnostic/reference. *)
masterTransportDepthBudgetFromTable[assembly_, rminTable_,
    kmax_Integer] := Module[
  {nb, need},
  nb = Length[assembly["Blocks"]];
  If[Dimensions[rminTable] =!= {nb, nb},
    Return[<|"Status" -> "InvalidOrderTable",
      "Dimensions" -> Dimensions[rminTable]|>]];
  need = ConstantArray[kmax, nb];
  Do[
    Do[
      If[j < i && rminTable[[i, j]] =!= Infinity,
        need[[j]] = Max[need[[j]], need[[i]] - rminTable[[i, j]]]],
      {j, nb}],
    {i, nb, 1, -1}];
  <|"Need" -> need, "RMin" -> rminTable,
    "RMinGlobal" -> Min[Append[
      DeleteCases[Flatten[rminTable], Infinity], 0]]|>
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

(* ------------------------------------------------------------------ *)
(*  (C4b) the EXACT per-block depth recursion                           *)
(* ------------------------------------------------------------------ *)

(* The clamped rule above assigns each DAG edge the cost max(0, 1 - r)
   and sums along a path.  That is an upper bound and not the minimum:
   the exact contribution of a descending chain is |p| - sum_e r_e, so a
   deficit edge (r <= 0) and a slack edge (r >= 2) on the SAME chain
   compensate, and clamping per edge throws the compensation away.  The
   2026-08-16 GPT-Pro review's example: r1 = -3 then r2 = +3 along a
   chain costs 2 extra word lengths, the clamped rule charges 4.

   The exact rule (that review's Eq. 4) is a recursion on (block, order),
   W_i(n) = the largest Chen-word length needed to determine F_{i,n}:

     W_i(n) = max{ 0                      if F_i's own boundary series
                                          can carry order n,
                   1 + W_i(n-1),          (the diagonal eps*Omega_i)
                   1 + W_j(n-r)           for every j < i and every
                                          eps-order r at which the
                                          coupling C_ij has a nonzero
                                          Laurent coefficient }

   with W_i(n) = -Infinity where no term can occur.  Two things this
   file supplies that the review states abstractly:

   (i) the FULL Laurent support of each coupling, not its lowest order.
       A coupling is rational in eps; when its denominator is an eps
       MONOMIAL the support is finite and is read off exactly with
       CoefficientList, and when it is not (class 97's scalar gauge
       carries 1/(y - eps/(1+4eps)), so this case is real) the support is
       infinite upward and the orders are taken exactly by Series up to a
       cap.  The cap is not a truncation: an order r can only matter
       through W_j(n-r), which is -Infinity as soon as n - r drops below
       the lowest order block j can carry, so the cap is CHOSEN from that
       bound and the truncation is provably irrelevant.  The flag is
       still reported, because a cap that was chosen by an argument must
       be auditable.

   (ii) the lowest order each block can carry.  It is NOT the block's
       kmin: a coupling of eps-order r < 0 generates orders below the
       boundary series' start.  L_i = min(kmin_i, min_j (L_j + rmin_ij))
       in topological order, which is the same statement the module makes
       globally as solutionLow = kminF - shift.

   The Bellman potentials pi_i = max(0, max_j (1 - r_ij) + pi_j) of the
   Fable-Max reply are returned beside it: they are the LP dual of the
   clamped longest path and the exponents of the per-block rescaling
   F_i -> eps^{pi_i} F_i, and max_i (N_i - L_i + pi_i) is that reply's
   W*.  Reporting both is the point -- the two rules differ exactly when
   a maximizing chain mixes deficit and slack edges. *)

(* Laurent support of a rational function of eps, over [ord, cap].
   "Finite" is True when the expansion terminates at or below cap, i.e.
   when the denominator is an eps monomial. *)
(* The support of one entry is CACHED across calls.  Without it the
   ledger, which asks for the recursion twice per family (once with the
   module's own demands, once with the measured per-master demands),
   pays the Series twice; MEASURED on CF230 that was the dominant cost of
   the whole pre-transport stage.  A cached record computed at a LARGER
   cap serves a smaller one (filter the orders); a smaller one does not
   serve a larger one, and a "Finite" record serves any cap. *)
masterTransportSupportCacheClear[] := ($masterTransportSupportCache = <||>;);

masterTransportLaurentSupport[e_, cap_Integer, eps_] := Module[
  {cached, computed},
  If[! AssociationQ[$masterTransportSupportCache],
    $masterTransportSupportCache = <||>];
  cached = Lookup[$masterTransportSupportCache, Key[{e, eps}], None];
  If[AssociationQ[cached] &&
     (TrueQ[cached["Finite"]] || cached["Cap"] >= cap),
    Return[If[TrueQ[cached["Finite"]] || cached["Cap"] === cap, cached,
      Join[cached, <|"Orders" -> Select[cached["Orders"], # <= cap &],
        "Cap" -> cap|>]]]];
  computed = masterTransportLaurentSupportCompute[e, cap, eps];
  If[Length[$masterTransportSupportCache] < 200000,
    $masterTransportSupportCache[{e, eps}] = computed];
  computed
];

masterTransportLaurentSupportCompute[e_, cap_Integer, eps_] := Module[
  {x, num, den, denLow, denHigh, ord, finite, top, orders, coefficients},
  x = Together[e];
  If[x === 0,
    Return[<|"Order" -> Infinity, "Orders" -> {}, "Finite" -> True,
      "Truncated" -> False, "Cap" -> cap|>]];
  num = Numerator[x];
  den = Denominator[x];
  denLow = Exponent[den, eps, Min];
  denHigh = Exponent[den, eps, Max];
  ord = Exponent[num, eps, Min] - denLow;
  finite = TrueQ[denLow === denHigh];
  If[finite,
    (* exact and cheap: the support is the numerator's own support,
       shifted.  No Series, no truncation. *)
    coefficients = CoefficientList[num, eps];
    orders = Table[
      If[TrueQ[Together[coefficients[[k]]] === 0], Nothing, k - 1 - denLow],
      {k, Length[coefficients]}];
    Return[<|"Order" -> ord, "Orders" -> orders, "Finite" -> True,
      "Truncated" -> False, "Cap" -> cap|>]];
  top = Max[cap, ord];
  coefficients = masterTransportLaurentList[x, {ord, top}, eps];
  If[coefficients === $Failed,
    Return[<|"Order" -> ord, "Orders" -> Range[ord, top], "Finite" -> False,
      "Truncated" -> True, "Cap" -> cap, "Route" -> "ConservativeFull"|>]];
  orders = Table[
    If[TrueQ[Together[coefficients[[k]]] === 0], Nothing, ord + k - 1],
    {k, Length[coefficients]}];
  <|"Order" -> ord, "Orders" -> orders, "Finite" -> False,
    "Truncated" -> True, "Cap" -> cap|>
];

(* A demand belongs to a mathematical block (the indicated rows of the
   input family), not to the block's temporary position in a caller's
   list.  masterTransportAssemble topologically orders the blocks before
   transport, so positional demands must be carried through that same
   permutation.  An Association may instead key demands directly by row
   lists; this is the unambiguous form for a caller using automatic SCCs. *)
masterTransportResolveBlockDemands[demands_, declaredBlocks_, assembly_] :=
  Module[{validQ, inputRows, inputDemands, resolved, position},
    If[demands === Automatic, Return[Automatic]];
    validQ[x_] := IntegerQ[x] || x === -Infinity;
    Which[
      AssociationQ[demands],
        inputRows = Keys[demands];
        inputDemands = Values[demands],
      ListQ[demands] && ListQ[declaredBlocks] &&
          AllTrue[declaredBlocks, MatchQ[#, {_List, _}] &] &&
          Length[demands] === Length[declaredBlocks],
        inputRows = declaredBlocks[[All, 1]];
        If[! DuplicateFreeQ[inputRows], Return[$Failed]];
        inputDemands = demands,
      ListQ[demands] && declaredBlocks === Automatic &&
          Length[demands] === Length[assembly["Blocks"]],
        (* With automatic SCCs there is no earlier caller order: the list
           is, by definition, already in the assembled topological order. *)
        resolved = demands;
        If[AllTrue[resolved, validQ] && AnyTrue[resolved, IntegerQ],
          Return[resolved], Return[$Failed]],
      True,
        Return[$Failed]
    ];
    resolved = Table[
      position = FirstPosition[inputRows, rows, None];
      If[position === None, Missing["NoBlockDemand", rows],
        inputDemands[[First[position]]]],
      {rows, assembly["Blocks"]}];
    If[AnyTrue[resolved, MissingQ] || ! AllTrue[resolved, validQ] ||
       ! AnyTrue[resolved, IntegerQ], Return[$Failed]];
    resolved
  ];

(* demands: Automatic | a per-block list of demanded top orders |
   an Association with "Demands" and (optionally) "KMin".  KMin defaults
   to the module's kminPerBlock convention with physical valuation 0. *)
masterTransportExactDepth[assembly_, ahat_, demands_, eps_] := Module[
  {nb, ranges, spec, need, kmin, rmin, support, truncated, lowest, cap,
   nmax, w, potentials, clamped, edges, blockSupport, i, j, n, best, r,
   entries, closed},
  nb = Length[assembly["Blocks"]];
  ranges = assembly["Ranges"];
  spec = Which[
    AssociationQ[demands], demands,
    ListQ[demands], <|"Demands" -> demands|>,
    True, <||>];
  (* default kmin: ord(T^-1) per block, physical valuation 0, exactly the
     convention TransportFamily uses for kminPerBlock *)
  closed = Table[
    TrueQ[assembly["Forms"][[s]]["Type"] === "ClosedFormSector"], {s, nb}];
  kmin = Lookup[spec, "KMin", Automatic];
  If[kmin === Automatic || ! ListQ[kmin] || Length[kmin] =!= nb,
    kmin = Table[
      If[closed[[s]], 0,
        Min[Append[DeleteCases[
          masterTransportEpsOrder[#, eps] & /@ Flatten[assembly["TInverse"][[s]]],
          Infinity], 0]] /. Infinity -> 0],
      {s, nb}]];
  rmin = Table[
    If[i > j,
      Min[Append[
        masterTransportEpsOrder[#, eps] & /@ Flatten[ahat[[ranges[[i]], ranges[[j]]]]],
        Infinity]],
      Infinity],
    {i, nb}, {j, nb}];
  need = Lookup[spec, "Demands", Automatic];
  If[need === Automatic || ! ListQ[need] || Length[need] =!= nb,
    need = masterTransportDepthBudget[assembly, ahat,
      Lookup[spec, "KMax", 0], eps]["Need"]];
  (* (ii) lowest order each block can carry, in topological order *)
  lowest = ConstantArray[0, nb];
  If[Length[lowest] =!= nb, Return[<|"Status" -> "ShapeFailed"|>]];
  Do[
    lowest[[i]] = Min[Append[
      Table[If[rmin[[i, j]] === Infinity, Infinity, lowest[[j]] + rmin[[i, j]]],
        {j, 1, i - 1}],
      kmin[[i]]]],
    {i, nb}];
  (* the cap argued for above: an order r beyond max(need) - min(lowest)
     can only feed a W_j below its block's lowest carried order *)
  cap = Max[need] - Min[lowest];
  edges = Flatten[Table[If[i > j && rmin[[i, j]] =!= Infinity, {i, j}, Nothing],
    {i, nb}, {j, nb}], 1];
  support = <||>;
  truncated = <||>;
  Do[
    {i, j} = e;
    entries = Flatten[ahat[[ranges[[i]], ranges[[j]]]]];
    blockSupport = masterTransportLaurentSupport[#, cap, eps] & /@ entries;
    support[{i, j}] = Union @@ (#["Orders"] & /@ blockSupport);
    truncated[{i, j}] = AnyTrue[blockSupport, TrueQ[#["Truncated"]] &],
    {e, edges}];
  (* the top order each block must reach, propagated down the DAG with
     the LOWEST coupling order (that is the one that reaches furthest up) *)
  nmax = need;
  Do[
    Do[
      If[j < i && rmin[[i, j]] =!= Infinity,
        nmax[[j]] = Max[nmax[[j]], nmax[[i]] - Min[support[{i, j}]]]],
      {j, nb}],
    {i, nb, 1, -1}];
  (* (C4b) the recursion itself *)
  w = <||>;
  Do[
    If[nmax[[i]] === -Infinity, Continue[]];
    Do[
      best = If[n >= kmin[[i]], 0, -Infinity];
      If[n - 1 >= lowest[[i]],
        best = Max[best, 1 + Lookup[w, Key[{i, n - 1}], -Infinity]]];
      Do[
        If[j < i && rmin[[i, j]] =!= Infinity,
          Do[
            If[n - r >= lowest[[j]],
              best = Max[best, 1 + Lookup[w, Key[{j, n - r}], -Infinity]]],
            {r, support[{i, j}]}]],
        {j, nb}];
      w[{i, n}] = best,
      {n, lowest[[i]], nmax[[i]]}],
    {i, nb}];
  potentials = ConstantArray[0, nb];
  If[Length[potentials] =!= nb, Return[<|"Status" -> "ShapeFailed"|>]];
  Do[
    potentials[[i]] = Max[Append[
      Table[If[rmin[[i, j]] === Infinity, 0,
        potentials[[j]] + Max[0, 1 - rmin[[i, j]]]], {j, 1, i - 1}],
      0]],
    {i, nb}];
  clamped = Table[(need[[i]] - kmin[[i]]) + potentials[[i]], {i, nb}];
  <|"Status" -> "OK",
    "Rule" -> "W_i(n) = max{0 if n >= kmin_i, 1 + W_i(n-1), 1 + W_j(n-r) for r in supp(C_ij)}",
    "Demands" -> need,
    "KMin" -> kmin,
    "Lowest" -> lowest,
    "NMax" -> nmax,
    "Cap" -> cap,
    "EdgeOrderMin" -> rmin,
    "Support" -> support,
    "SupportTruncated" -> truncated,
    "SlackEdges" -> Select[edges, Max[support[#]] >= 2 &],
    "DeficitEdges" -> Select[edges, Min[support[#]] <= 0 &],
    "MixedEdges" -> Select[edges, Min[support[#]] <= 0 && Max[support[#]] >= 2 &],
    "W" -> Table[Lookup[w, Key[{i, need[[i]]}], -Infinity], {i, nb}],
    "WMax" -> Max[Table[Lookup[w, Key[{i, need[[i]]}], -Infinity], {i, nb}]],
    "Potentials" -> potentials,
    "ClampedPerBlock" -> clamped,
    "ClampedMax" -> Max[clamped],
    "Table" -> w|>
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
(* The two AXIS-ALIGNED directions: one variable runs from a numeric
   anchor to its symbolic target while the other is held AT its symbolic
   target.  Both are straight segments, so every letter that is linear in
   the moving variable stays linear in the path parameter -- which is
   what the word backends admit -- and a letter that is bilinear in
   (v,w) becomes linear on an axis and quadratic on the diagonal.  Which
   of the two axes an individual family admits is a property of its
   alphabet: measured 2026-08-17, CF301 (letter (1-v)^2 + v w) is refused
   with v moving and accepted with w moving. *)
masterTransportAxisBasePoints[variables_List, anchor_] :=
  {{anchor, variables[[2]]}, {variables[[1]], anchor}};

(* A base-point option is a point, Automatic (= the two axis-aligned
   directions at the given anchor), or an explicit list of candidate
   points -- the form TransportFamilyInChart uses to hand its own two
   chart directions down.  The list form is recognised BEFORE the point
   form, because a two-element list of points also matches {_, _}. *)
masterTransportBasePointCandidates[value_, variables_List, anchor_] := Which[
  value === Automatic, masterTransportAxisBasePoints[variables, anchor],
  ListQ[value] && value =!= {} && AllTrue[value, MatchQ[#, {_, _}] &], value,
  MatchQ[value, {_, _}], {value},
  True, $Failed];

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
masterTransportMonicCheck[m_, tau_, eps_: None] := Module[
  {denominators, degrees, monic, quadratics, algebraic},
  denominators = DeleteDuplicates @ Flatten @ Map[
    FactorList[Denominator[Together[#]]][[All, 1]] &, m, {2}];
  denominators = Select[denominators, ! FreeQ[#, tau] &];
  degrees = Exponent[#, tau] & /@ denominators;
  monic = Table[TrueQ[Together[Coefficient[denominators[[i]], tau, 1] - 1] === 0],
    {i, Length[denominators]}];
  (* Degree-2 factors are ADMISSIBLE as algebraic letters (two roots
     (-b +- k Sqrt[D0])/(2a) in the frozen variable) exactly when their
     discriminant is free of the regulator: an eps-dependent discriminant
     means an eps-dependent locus, i.e. an apparent singularity that the
     off-diagonal cleanup owes us, never a letter.  Degree >= 3 is not
     admitted (no such factor has been measured; it would need a
     different representation and is refused by name). *)
  quadratics = Table[
    If[degrees[[i]] === 2,
      Module[{a, b, c, disc},
        a = Coefficient[denominators[[i]], tau, 2];
        b = Coefficient[denominators[[i]], tau, 1];
        c = Coefficient[denominators[[i]], tau, 0];
        disc = Together[b^2 - 4 a c];
        <|"Factor" -> denominators[[i]], "Discriminant" -> disc,
          "Radical" -> masterTransportRadicalCanon[disc],
          "EpsFree" -> (eps === None || FreeQ[disc, eps])|>],
      Nothing],
    {i, Length[denominators]}];
  algebraic = AllTrue[degrees, # <= 2 &] &&
    AllTrue[quadratics, TrueQ[#["EpsFree"]] &];
  <|"Denominators" -> denominators, "Degrees" -> degrees,
    "Linear" -> AllTrue[degrees, # <= 1 &],
    "Quadratics" -> quadratics,
    "AlgebraicAdmissible" -> algebraic,
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
  Quiet[Get[file], {General::shdw}];
  $ContextPath = path;
  (* WL 14.2: Libra's option forwarding can emit OptionValue::optnf in
     Projector and OptionValue::nodef in NewDSystem/HistoryAppend inside
     Check.  The messages make those calls return the wrong object or
     abort despite admissible input.  Do not suppress Libra's banner by
     rebinding Print while loading: that separately rewrites Libra's
     option key Print and also makes NewDSystem abort. *)
  Off[OptionValue::optnf];
  Off[OptionValue::nodef];
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
(* Budget policy (2026-08-16 reviews, both).  A Pexp that exceeds its
   time budget used to return NOTHING: 1859 CPU-seconds and, worse, the
   cost data point were lost.  MEASURED capability of the engine:
   Libra's PexpExpansion is a NestList over one operator
   (Libra.m:2496-2517), and PexpExpansion[{M, w}, x, x0] returns the
   whole prefix {U_0, ..., U_w}.  It can therefore be driven weight by
   weight from OUTSIDE without writing a Pexp: the ladder calls it at
   w = 0, 1, ..., wmax and keeps the last completed list as a
   checkpoint.  The re-work is the sum of the lower weights, which for a
   word count growing like L^w is a fraction 1/(L-1) of the top weight;
   the per-weight wall times are returned so that the log-t-vs-w slope
   the reviews asked for is a by-product rather than a separate probe.

   With no finite budget the ladder is skipped entirely and the single
   call is made, so the default path is bit-for-bit the old one. *)
masterTransportBackendLibra[m_, tau_, wmax_Integer, root_String,
    budget_ : Infinity] := Module[
  {loaded, raw, converted, deadline, ladder, best, bestWeight, seconds,
   perWeight, attempt, elapsed, aborted},
  loaded = masterTransportLoadLibra[root];
  If[loaded =!= True, Return[<|"Status" -> "BackendUnavailable", "Backend" -> "Libra"|>]];
  ladder = NumericQ[budget] && budget < Infinity && wmax >= 1;
  If[ladder,
    deadline = AbsoluteTime[] + budget;
    best = None; bestWeight = -1; perWeight = {};
    aborted = False;
    Do[
      elapsed = deadline - AbsoluteTime[];
      If[elapsed <= 0, Break[]];
      {seconds, attempt} = AbsoluteTiming[
        TimeConstrained[
          CheckAbort[
            Quiet[Block[{Print = (Null &)}, Libra`PexpExpansion[{m, k}, tau, 0]]],
            $Aborted],
          elapsed, $TimedOut]];
      (* An ABORT and a BUDGET OVERRUN must never be confused.  Libra
         aborts -- it does not return a failure value -- when its own
         pole analysis finds a pole at infinity (CF360 is the standing
         instance).  TimeConstrained implements its limit BY aborting,
         so an escaping Abort can come back as the timeout marker even
         though CheckAbort is nested inside it; that misreported CF360's
         documented backend boundary as a budget overrun in 0.0 s of an
         1800 s budget.  The discriminator is therefore not the marker
         but whether the BUDGET WAS ACTUALLY CONSUMED: a genuine overrun
         uses up (nearly) all of the remaining time, an abort returns at
         once.  Anything that comes back early is an abort and is
         reported with the abort's own status and the weights already
         completed. *)
      If[attempt === $Aborted ||
         (attempt === $TimedOut && ! TrueQ[seconds >= 0.5 elapsed]),
        aborted = True; Break[]];
      If[attempt === $TimedOut, Break[]];
      If[! ListQ[attempt] || Length[attempt] =!= k + 1,
        Return[<|"Status" -> "BackendFailed", "Backend" -> "Libra",
          "Weight" -> bestWeight, "Requested" -> wmax,
          "PerWeightSeconds" -> perWeight|>]];
      best = attempt; bestWeight = k;
      perWeight = Append[perWeight, {k, seconds}],
      {k, 0, wmax}];
    If[TrueQ[aborted],
      Return[<|"Status" -> "BackendAborted", "Backend" -> "Libra",
        "Weight" -> bestWeight, "Requested" -> wmax,
        "Partial" -> (bestWeight >= 0), "PerWeightSeconds" -> perWeight,
        "U" -> If[best === None, {}, best /. {
          Libra`II[{}, __] :> 1,
          Libra`II[word_List, x_, x0_] :> TransportWord[(# - x0) & /@ word, x - x0],
          Libra`II[word_List, x_] :> TransportWord[word, x]}],
        "Poles" -> Quiet[Union[Flatten[{Libra`PolesPosition[m, tau]}]]]|>]];
    If[best === None,
      Return[<|"Status" -> "BackendBudgetExceeded", "Backend" -> "Libra",
        "Weight" -> -1, "PerWeightSeconds" -> perWeight, "Requested" -> wmax|>]];
    (* radicals of the frozen variable (algebraic poles found by Libra's
       Solve) are brought to the square-free form the engine uses, so
       that both letters and coefficients are comparable word by word *)
    converted = masterTransportRadicalNormalize[best /. {
      Libra`II[{}, __] :> 1,
      Libra`II[word_List, x_, x0_] :> TransportWord[(# - x0) & /@ word, x - x0],
      Libra`II[word_List, x_] :> TransportWord[word, x]}];
    Return[<|
      "Status" -> If[bestWeight === wmax, "OK", "BackendBudgetExceeded"],
      "Backend" -> "Libra", "U" -> converted, "Weight" -> bestWeight,
      "Requested" -> wmax, "Partial" -> (bestWeight =!= wmax),
      "PerWeightSeconds" -> perWeight, "Route" -> "WeightLadder"|>]];
  (* PexpExpansion ABORTS -- it does not return a failure value -- when
     the connection does not decay at infinity, i.e. when its own pole
     analysis reports a pole at Infinity.  An escaping Abort would kill
     the whole run, so it is caught and turned into a status.  The usual
     cause is a path restriction that left an extra power of the path
     parameter in the numerators.

     CF360 is the standing instance and is a DOCUMENTED EXPECTED-PARTIAL,
     not an open bug: it returns TransportFailed with this backend
     status, and the suite asserts that controlled failure rather than
     accepting an unverified transport.  Repairing it needs a path or a
     gauge on which the conjugated connection is Fuchsian at infinity,
     which is a next-session item.  Scripts/HardClasses/diag_cf360_path.wls measures
     the obstruction -- polynomial part in tau per candidate path, and
     which block carries it -- so that attempt starts from data rather
     than from a guess.  Note an irregular singularity at infinity is
     intrinsic: reparametrizing tau cannot remove it, Fuchsifying might. *)
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
  converted = masterTransportRadicalNormalize[raw /. {
    Libra`II[{}, __] :> 1,
    Libra`II[word_List, x_, x0_] :> TransportWord[(# - x0) & /@ word, x - x0],
    Libra`II[word_List, x_] :> TransportWord[word, x]}];
  <|"Status" -> "OK", "Backend" -> "Libra", "U" -> converted,
    "Weight" -> wmax, "Requested" -> wmax, "Partial" -> False,
    "Route" -> "SingleCall"|>
];

(* PolyLogTools transport by explicit iterated GIntegrate, base-point
   subtracted leg by leg. *)
masterTransportBackendPolyLogTools[m_, tau_, wmax_Integer, root_String,
    budget_ : Infinity] := Module[
  {loaded, dimension, u, primitive, converted, deadline, perWeight, seconds,
   step},
  loaded = masterTransportLoadPolyLogTools[root];
  If[loaded =!= True,
    Return[<|"Status" -> "BackendUnavailable", "Backend" -> "PolyLogTools"|>]];
  dimension = Length[m];
  u = {IdentityMatrix[dimension]};
  (* this backend is already a per-weight loop, so the checkpoint is the
     loop's own state: on a budget overrun it returns the weights it
     completed instead of nothing *)
  deadline = If[NumericQ[budget] && budget < Infinity,
    AbsoluteTime[] + budget, Infinity];
  perWeight = {};
  Do[
    If[AbsoluteTime[] > deadline, Break[]];
    {seconds, step} = AbsoluteTiming[
      TimeConstrained[
        Module[{p},
          p = Expand[Map[PolyLogTools`GIntegrate[#, tau] &, Expand[m . Last[u]], {2}]];
          Expand[p - (p /. tau -> 0)]],
        If[deadline === Infinity, Infinity, deadline - AbsoluteTime[]],
        $TimedOut]];
    If[step === $TimedOut, Break[]];
    primitive = step;
    AppendTo[u, primitive];
    perWeight = Append[perWeight, {n, seconds}],
    {n, 1, wmax}];
  If[Length[u] =!= wmax + 1,
    converted = u /. g_PolyLogTools`G :> With[{a = List @@ g},
      TransportWord[Flatten[{Most[a]}], Last[a]]];
    Return[<|"Status" -> "BackendBudgetExceeded", "Backend" -> "PolyLogTools",
      "U" -> converted, "Weight" -> Length[u] - 1, "Requested" -> wmax,
      "Partial" -> True, "PerWeightSeconds" -> perWeight|>]];
  (* P3: the rule LHS must match on the HEAD.  Writing
     PolyLogTools`G[args__] :> ... makes the pattern evaluate, because
     PolyLogTools`G carries downvalues, and the rule then silently
     matches nothing while FreeQ still reports G present. *)
  converted = u /. g_PolyLogTools`G :> With[{a = List @@ g},
    TransportWord[Flatten[{Most[a]}], Last[a]]];
  <|"Status" -> "OK", "Backend" -> "PolyLogTools", "U" -> converted,
    "Weight" -> wmax, "Requested" -> wmax, "Partial" -> False,
    "PerWeightSeconds" -> perWeight|>
];

masterTransportRunBackend[backend_, m_, tau_, wmax_Integer, root_String, eps_,
    budget_ : Infinity] :=
  Module[{result, indices},
    result = Which[
      backend === "Libra" || backend === Automatic,
        masterTransportBackendLibra[m, tau, wmax, root, budget],
      backend === "PolyLogTools",
        masterTransportBackendPolyLogTools[m, tau, wmax, root, budget],
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

(* H1 (2026-08-17).  The completeness statement used to be made with the
   GLOBAL CLAMPED shift alone:

       predicted = wmax + 1 - D,   complete <=> predicted > j1,

   D the longest path in the block DAG.  That is the right statement for
   the clamped rule, whose weight IS jmax + D, and the wrong one for
   "DepthRule" -> "Exact": the exact rule returns
   wmax = max_i W_i(need_i), which is by construction <= jmax + D and
   usually strictly smaller, so the clamped inequality fails and the run
   is refused with RegradingIncomplete even though every block has all
   the weight it needs.  That is why "Exact" was usable only where it
   equalled the clamped number.

   The per-block statement is the one the exact rule actually proves.
   W_i(n) -- the recursion of masterTransportExactDepth -- is the largest
   Chen weight that can still contribute to block i at epsilon order n,
   and it is MONOTONE in n (its recursion only ever adds routes as n
   grows).  So

       wmax >= W_i(need_i)   certifies block i at every order <= need_i,

   and the window is complete when that holds for EVERY block.  This is
   exact, not a bound, so it is checked per block and the per-block
   verdicts are reported rather than folded into one flag.

   Two ways it can fail to be performable, and both are refusals rather
   than passes: a block whose W is -Infinity (its demand is below the
   lowest order it can carry, so the recursion has nothing to say), and
   a coupling whose Laurent support was TRUNCATED at the recursion's cap
   (then W is a lower bound on the truth, and a lower bound cannot
   certify).  The clamped route is kept and tried first, so a run that
   was complete before is complete now for the same reason. *)
masterTransportRegrade[u_List, {j0_Integer, j1_Integer}, shift_, eps_,
    exact_ : None] := Module[
  {wmax, dimension, graded, lowestAtTop, predicted, complete,
   clampedComplete, perBlock, exactComplete, exactUsable, route},
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
  clampedComplete = shift =!= Infinity && predicted > j1;
  (* the per-block exact statement, when the exact recursion is at hand *)
  exactUsable = AssociationQ[exact] && Lookup[exact, "Status", None] === "OK" &&
    ListQ[Lookup[exact, "W", None]] && FreeQ[exact["W"], -Infinity | Infinity] &&
    ! AnyTrue[Values[Lookup[exact, "SupportTruncated", <||>]], TrueQ];
  perBlock = If[exactUsable,
    Table[wmax >= exact["W"][[i]], {i, Length[exact["W"]]}],
    None];
  exactComplete = exactUsable && perBlock =!= {} && AllTrue[perBlock, TrueQ];
  complete = clampedComplete || exactComplete;
  route = Which[
    clampedComplete, "ClampedGlobalShift",
    exactComplete, "ExactPerBlock",
    True, "None"];
  <|"Orders" -> Range[j0, j1], "V" -> graded, "Shift" -> shift,
    "TopWeight" -> wmax, "LowestOrderAtTopWeight" -> lowestAtTop,
    "PredictedLowestNextWeight" -> predicted,
    "Complete" -> complete,
    "CompleteRoute" -> route,
    "ClampedComplete" -> clampedComplete,
    "ExactComplete" -> exactComplete,
    (* Missing, never False, when the exact recursion was not supplied or
       could not be used: "the statement was not made" and "the statement
       failed" are different verdicts. *)
    "PerBlockComplete" -> If[exactUsable, perBlock, Missing["NoExactDepth"]],
    "PerBlockWeightNeeded" -> If[exactUsable, exact["W"], Missing["NoExactDepth"]],
    "PerBlockDemands" -> If[exactUsable, Lookup[exact, "Demands", None],
      Missing["NoExactDepth"]],
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
  {n, nb, ranges, tr0, tr1, tLaurent, v, w, substitution, kmin, kmax, out,
   sectors, identityBlocks},
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
  (* A certified family epsilon-form is transported with identity
     diagonal blocks.  Expanding those identities into a Laurent matrix
     at every requested order and multiplying all the resulting zero
     matrices by large word vectors is exactly equivalent to selecting
     the requested rows of F, but can dominate the wall time. *)
  identityBlocks = AllTrue[sectors,
    SameQ[assembly["Forms"][[#]]["T"],
      IdentityMatrix[Length[ranges[[#]]]]] &];
  If[identityBlocks,
    out = Table[
      Module[{total = ConstantArray[0, n]},
        If[kmin <= nn <= kmax && KeyExistsQ[solution["F"], nn],
          Do[total[[ranges[[s]]]] = solution["F"][nn][[ranges[[s]]]],
            {s, sectors}]];
        total],
      {nn, n0, n1}];
    Return[<|"Orders" -> Range[n0, n1], "I" -> out, "TR0" -> 0,
      "Route" -> "IdentityBlocks"|>]];
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
   updated, recheck, bad, ok, stageSeconds},
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
  {stageSeconds, series} = AbsoluteTiming[
    masterTransportMasterSeries[assembly, solution, {low, n0 - 1},
      base, target, tau, variables, eps]];
  masterTransportLog[verbose, "  valuation: formed forbidden Laurent orders ",
    orders, " in ", Round[stageSeconds, 0.1], " s"];
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
  masterTransportLog[verbose, "  valuation: extracted ", Length[equations],
    " distinct linear equations"];
  constants = DeleteDuplicates[Cases[Values[solution["F"]], _TransportConstant, {0, Infinity}]];
  {stageSeconds, solved} = AbsoluteTiming[If[equations === {}, {{}},
    Quiet @ Solve[Thread[equations == 0], constants]]];
  masterTransportLog[verbose, "  valuation: solved the linear constraints in ",
    Round[stageSeconds, 0.1], " s"];
  If[Head[solved] =!= List || solved === {},
    masterTransportLog[verbose, "  !! VALUATION CONSTRAINTS INCONSISTENT (",
      Length[equations], " equations)"];
    Return[<|"Status" -> "Inconsistent", "Rules" -> {}, "Orders" -> orders,
      "Equations" -> Length[equations], "Solution" -> solution,
      "AssertionOK" -> False|>]];
  rules = First[solved];
  updated = solution;
  (* instrumented 2026-08-18 (CF26/CF33 multi-hour stall sits between
     "solved the linear constraints" and "reconstructed"): measure the
     constant back-substitution separately, with the input size *)
  masterTransportLog[verbose, "  valuation: substituting ", Length[rules],
    " constant rules into F (", ByteCount[solution["F"]], " bytes, ",
    Length[Keys[solution["F"]]], " orders)"];
  {stageSeconds, updated["F"]} = AbsoluteTiming[
    If[ListQ[constants] && constants =!= {},
      masterTransportApplyKernel[solution["F"],
        masterTransportConstantKernel[rules, constants], constants],
      masterTransportSubstituteConstants[solution["F"], rules]]];
  masterTransportLog[verbose, "  valuation: substitution finished in ",
    Round[stageSeconds, 0.1], " s (", ByteCount[updated["F"]], " bytes)"];
  masterTransportLog[verbose, "  valuation: I must vanish for eps^", low,
    "..eps^", n0 - 1, "; ", Length[equations], " equations fixed ",
    Length[rules], " of ", Length[constants], " constants"];
  (* the assertion: the constrained family really does have the claimed
     valuation *)
  {stageSeconds, recheck} = AbsoluteTiming[
    masterTransportMasterSeries[assembly, updated, {low, n0 - 1},
      base, target, tau, variables, eps]];
  masterTransportLog[verbose, "  valuation: reconstructed the constrained ",
    "orders in ", Round[stageSeconds, 0.1], " s"];
  {stageSeconds, bad} = AbsoluteTiming[
    Select[Flatten[recheck["I"]], ! TrueQ[masterTransportZeroQ[#]] &]];
  masterTransportLog[verbose, "  valuation: exact zero check finished in ",
    Round[stageSeconds, 0.1], " s"];
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
    variables_, eps_, rows_ : All, verbose_ : False] := Module[
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
      masterTransportLog[verbose, "  DE check at eps^", nn, " of ", orders];
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
   constant vector.  Three routes are tried in order and the one taken
   is recorded: plain symbolic (Together), then the exact Gauss
   certificate, and only then a Frobenius truncation plus a
   high-precision numeric residual.

   The per-sector "Exactness" obeys the same taxonomy as the block
   verdict, and it is the MINIMUM of the two statements: a sector whose
   path-frame identity is only an analytic candidate cannot be Exact
   even if its block certificate was, and vice versa.  Nothing here can
   upgrade a series-and-numeric result. *)
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
         blockCertified, blockExactness, certificateResult, certificate,
         pathExactness, exactness},
        range = assembly["Ranges"][[s]];
        (* the substantive statement is the BLOCK certificate, already
           re-established by masterTransportClosedFormSector *)
        blockCertified = TrueQ[assembly["Forms"][[s]]["Status"] === "OK"];
        blockExactness = Lookup[assembly["Forms"][[s]], "Exactness", "Rejected"];
        phi = assembly["Forms"][[s]]["T"] /. substitution;
        residual = D[phi, tau] - ahatOriginal[[range, range]] . phi;
        exactOK = TrueQ[TimeConstrained[
          masterTransportZeroMatQ[Together[residual]], timeLimit, False]];
        certificate = None; certificateResult = None;
        If[! exactOK && blockExactness =!= "AnalyticCandidate",
          (* the same exact machinery as the block verdict, on the path
             connection: a single {Ahat, tau} pair.  Skipped when the
             block itself only reached AnalyticCandidate, since the
             combined verdict cannot exceed that and the proof attempt
             would be spent for nothing. *)
          certificateResult = masterTransportHypergeometricCertificate[
            phi, {{ahatOriginal[[range, range]], tau}}, eps,
            Lookup[assembly["Forms"][[s]], "Checks", <||>], timeLimit];
          If[AssociationQ[certificateResult] && TrueQ[certificateResult["Proved"]],
            exactOK = True; certificate = certificateResult]];
        route = "Symbolic"; seriesOK = Null; numericOK = Null;
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
        (* The path-frame identity FOLLOWS from the block certificate by
           the chain rule, so this stage confirms the path restriction
           rather than re-proving the sector.  It is accepted on the
           block certificate plus a passing numeric residual; a series
           route that did not return is recorded as not-performable and
           does not by itself condemn the sector -- but a numeric
           residual that FAILS does, and so does a failed block
           certificate. *)
        pathExactness = Which[
          TrueQ[exactOK], "Exact",
          blockCertified && TrueQ[numericOK], "AnalyticCandidate",
          True, "Rejected"];
        (* the weaker of the two statements wins; nothing upgrades *)
        exactness = masterTransportCombineExactness[
          {blockExactness, pathExactness}];
        <|"Block" -> s, "Rows" -> assembly["Blocks"][[s]], "Range" -> range,
          "Constants" -> constants, "I" -> phi . constants,
          "CheckRoute" -> route, "ExactResidualZero" -> exactOK,
          "SeriesResidualZero" -> seriesOK, "NumericResidualZero" -> numericOK,
          "SeriesOrder" -> If[route === "SeriesAndNumeric", seriesOrder, None],
          "Exactness" -> exactness,
          "BlockExactness" -> blockExactness,
          "PathExactness" -> pathExactness,
          "Certificate" -> certificate,
          "OK" -> (exactness =!= "Rejected"),
          "BlockCertified" -> blockCertified,
          "BlockCertificate" -> Lookup[assembly["Forms"][[s]], "Checks", None]|>],
      {s, closedBlocks}];
    <|"Status" -> If[AllTrue[records, TrueQ[#["OK"]] &], "OK", "NotVerified"],
      "Exactness" -> masterTransportCombineExactness[
        Table[r["Exactness"], {r, records}]],
      "Sectors" -> records|>
  ];

(* ------------------------------------------------------------------ *)
(*  Phi-weighted quadrature for COUPLED closed-form blocks              *)
(* ------------------------------------------------------------------ *)

(* The structure this route handles, and the structure it refuses.

   With a hard block whose homogeneous solution is known in closed form
   and already-solved lower blocks,

     d I_h = A_h I_h + B I_l,     d I_l = A_l I_l,

   the substitution I_h = Phi J turns the hard equation into a pure
   quadrature,

     d J = Phi^-1 B I_l,   J(tau) = J(0) + Int_0^tau Phi^-1 B I_l ds.

   Supported: a closed-form block may READ any number of graded blocks
   below it.  Refused, explicitly and by name rather than by a wrong
   answer:

     - a graded block that reads FROM a closed-form block, which would
       require the word backend to integrate 2F1-dressed sources;
     - a closed-form block that reads from another closed-form block,
       which would require nested quadrature.

   Both refusals are structural facts about the block DAG, decided here
   before any integration is attempted. *)
masterTransportClosedFormCoupling[assembly_, closedBlocks_, gradedBlocks_] :=
  Module[{ranges, av, aw, nb, nonzeroQ, sources, feedsGraded, closedToClosed},
    ranges = assembly["Ranges"];
    av = assembly["Av"]; aw = assembly["Aw"];
    nb = Length[ranges];
    nonzeroQ[i_, j_] := ! (
      TrueQ[masterTransportZeroMatQ[av[[ranges[[i]], ranges[[j]]]]]] &&
      TrueQ[masterTransportZeroMatQ[aw[[ranges[[i]], ranges[[j]]]]]]);
    sources = Association @ Table[
      s -> Select[Range[nb], # =!= s && nonzeroQ[s, #] &],
      {s, closedBlocks}];
    feedsGraded = Flatten[
      Table[If[nonzeroQ[i, s], {{i, s}}, {}], {i, gradedBlocks}, {s, closedBlocks}],
      2];
    closedToClosed = Flatten[
      Table[If[MemberQ[closedBlocks, j], {{s, j}}, {}],
        {s, closedBlocks}, {j, sources[s]}],
      2];
    <|"Sources" -> sources,
      "Coupled" -> AnyTrue[closedBlocks, sources[#] =!= {} &],
      "FeedsGraded" -> feedsGraded,
      "ClosedToClosed" -> closedToClosed,
      "Supported" -> (feedsGraded === {} && closedToClosed === {})|>
  ];

(* The regrouping identity, proved ONCE on generic matrices.

   With J = J0 + Int Phi^-1 B I_l, so that dJ/dt = Phi^-1 B I_l,

     d/dt[Phi J] - A Phi J - B I_l
       = (dPhi/dt - A Phi) J + (Phi Phi^-1 - 1) B I_l

   is an identity of matrix algebra: it holds for ANY Phi, PhiInverse,
   A, B, I_l of the right shapes, because it is nothing but expanding
   the product rule and regrouping.  It says nothing about
   hypergeometric functions.

   Proving it per family, on the actual 2F1-dressed entries, therefore
   spends a large Together to re-derive a fact that does not depend on
   those entries -- and on the synthetic gate that Together did not
   close in budget, which reported the certificate as unproved when the
   mathematics was fine.  It is verified here on matrices of INDEPENDENT
   SYMBOLS instead, where the check is small and exact, and the
   family-specific content is left to the two factors:

     dPhi/dt - A Phi = 0   (the sector's Gauss certificate)
     Phi Phi^-1 - 1  = 0   (rational algebra in Phi's entries)

   Both of those ARE checked per family.  Nothing is assumed. *)

(* The statement is split into two independently diagnosable halves,
   because they fail for completely different reasons and a single
   boolean would not say which:

     (a) the DERIVATIVE RULE -- that d/dt of the inert quadrature head
         really returns its integrand.  This is about the head, not
         about the algebra, and it is where an integrand accidentally
         left as an expression in t (rather than a pure function) shows
         up;
     (b) the ALGEBRA -- the regrouping itself, with the integrand's
         derivative substituted explicitly, so it tests rearrangement
         and nothing else. *)
masterTransportQuadratureDerivativeRule[t_Symbol, timeLimit_] :=
  TimeConstrained[
    Module[{g, sv, f, q},
      g = Unique["mtqG"];
      sv = Unique["mtqS"];
      f = Function @@ {sv, g[sv]};
      q = TransportQuadrature[f, t, 0];
      TrueQ[D[q, t] === g[t]]],
    timeLimit, False];

masterTransportQuadratureIdentity[dim_Integer, nLower_Integer, t_Symbol,
    timeLimit_] :=
  TimeConstrained[
    Module[{phi, phiInv, am, bm, lv, cv, jv, kern, lhs, rhs},
      phi = Table[Unique["mtqPhi"][t], {dim}, {dim}];
      phiInv = Table[Unique["mtqPhiInv"][t], {dim}, {dim}];
      am = Table[Unique["mtqA"][t], {dim}, {dim}];
      bm = Table[Unique["mtqB"][t], {dim}, {nLower}];
      lv = Table[Unique["mtqL"][t], {nLower}];
      jv = Table[Unique["mtqJ"][t], {dim}];
      kern = phiInv . bm . lv;
      (* dJ/dt = Phi^-1 B I_l is SUBSTITUTED rather than obtained by
         differentiating the inert head -- that half is (a) above.  What
         is left here is pure rearrangement. *)
      lhs = D[phi, t] . jv + phi . kern - am . phi . jv - bm . lv;
      rhs = (D[phi, t] - am . phi) . jv +
        (phi . phiInv - IdentityMatrix[dim]) . bm . lv;
      TrueQ[Expand[lhs - rhs] === ConstantArray[0, dim]]],
    timeLimit, False];

(* Build the formal integral and its exact differentiate-back
   certificate for ONE closed-form block.

   The integrand mixes Phi^-1 (hypergeometric) with the lower solution
   (Goncharov words), which is a genuinely new integral class -- it is
   NOT claimed to be evaluated.  What is produced is a formal integral
   with a derivative rule, and what is proved is that differentiating
   the representation returns the differential equation:

     d/dtau [ Phi (J0 + Int Phi^-1 B I_l) ] - A_h Phi (J0 + Int ...)
       - B I_l
     = (dPhi/dtau - A_h Phi)(J0 + Int ...) + (Phi Phi^-1 - 1) B I_l
     = 0.

   Both brackets vanish identically -- the first by the sector's own
   certificate, the second by rational algebra in the entries of Phi --
   and NEITHER uses any property of I_l.  So the identity is proved with
   I_l left as arbitrary unknown functions of tau, which is a stronger
   statement than proving it for the particular lower solution at hand:
   the representation is correct for every inhomogeneity, so a later
   change of lower solution cannot invalidate it.

   What this does NOT establish: that the integral has a closed form,
   what function class it lies in, or any value for it. *)
masterTransportPhiQuadrature[assembly_, s_, lowerRows_, iLower_, base_, target_,
    tau_, variables_, eps_, timeLimit_, priorCertificate_ : None] :=
  Module[{v, w, dv, dw, substitution, ahatOriginal, range, phi, phiInverse, ah,
     bMatrix, kernel, quadrature, constants, jVector, iHard, dim, integrationVar,
     proved, rightInverse, certificate, identityOK, derivativeRuleOK,
     homogeneous, homogeneousZero, certificateUsed},
    {v, w} = variables[[{1, 2}]];
    dv = target[[1]] - base[[1]];
    dw = target[[2]] - base[[2]];
    substitution = {v -> base[[1]] + tau dv, w -> base[[2]] + tau dw};
    ahatOriginal = Map[Together,
      (assembly["Av"] /. substitution) dv + (assembly["Aw"] /. substitution) dw, {2}];
    range = assembly["Ranges"][[s]];
    dim = Length[range];
    phi = assembly["Forms"][[s]]["T"] /. substitution;
    phiInverse = assembly["Forms"][[s]]["TInverse"] /. substitution;
    ah = ahatOriginal[[range, range]];
    bMatrix = ahatOriginal[[range, lowerRows]];

    (* Phi^-1 B I_l, one scalar per hard row.

       Together here is COSMETIC -- the kernel is a representation, not a
       proof, and nothing downstream needs it in lowest terms.  On a
       2F1-dressed Phi^-1 against a word-carrying lower solution it can
       also run for a very long time, so it is budgeted and falls back
       to the un-normalised form.  An unbounded tidy-up in the middle of
       a solve is a hang, not a nicety. *)
    kernel = phiInverse . bMatrix . iLower;
    kernel = TimeConstrained[Together /@ kernel, Min[timeLimit, 60], kernel];

    (* The integrand is carried as a pure FUNCTION of the integration
       variable, never as an expression in tau.  If it were an
       expression in tau, D[TransportQuadrature[expr, tau, 0], tau]
       would apply the chain rule through the first argument as well and
       silently produce the wrong derivative.  With a Function the first
       argument is free of tau and the rule is unambiguous. *)
    integrationVar = Unique["masterTransportQuadratureVar"];
    quadrature = Table[
      (* Function is HoldAll, so Function[integrationVar, body] would
         hold the LOCAL symbols rather than their values.  Apply builds
         the pure function from the evaluated parts. *)
      Function @@ {integrationVar, kernel[[i]] /. tau -> integrationVar},
      {i, dim}];
    (* The invariant behind Derivative[1,0,0][TransportQuadrature] = 0:
       no integrand may still mention the path parameter.  It holds by
       the substitution just made, and it is ASSERTED rather than
       trusted, because if it ever failed the derivative rule would
       silently drop a real chain-rule term. *)
    If[! AllTrue[quadrature, FreeQ[#[[2]], tau] &],
      Return[<|"Block" -> s, "Range" -> range, "OK" -> False,
        "Certificate" -> <|"Proved" -> False,
          "Reason" -> "IntegrandStillDependsOnPathParameter",
          "Evaluated" -> False|>|>, Module]];
    quadrature = Table[
      TransportQuadrature[quadrature[[i]], tau, 0], {i, dim}];

    constants = Table[TransportConstant[s, "Quadrature", i], {i, dim}];
    jVector = constants + quadrature;
    iHard = phi . jVector;

    (* ---- the exact differentiate-back certificate ------------------- *)

    (* Three statements, each checked, together giving
       d/dtau[Phi J] = A_h Phi J + B I_l:

         (1) the regrouping identity, on generic matrices, once;
         (2) dPhi/dtau - A_h Phi = 0, for THIS Phi on THIS path;
         (3) Phi Phi^-1 - 1 = 0, for THIS Phi.

       (1) is the part that does not depend on the entries, so it is not
       re-derived per family on 2F1-dressed expressions -- doing that was
       measured to exceed the budget on the synthetic gate and reported
       the certificate as unproved while the mathematics was fine.  (2)
       and (3) are the family-specific content and are checked here. *)
    derivativeRuleOK = masterTransportQuadratureDerivativeRule[tau,
      Min[timeLimit, 60]];
    identityOK = masterTransportQuadratureIdentity[dim, Length[lowerRows], tau,
      Min[timeLimit, 120]];

    (* Phi Phi^-1 = 1 is needed on the RIGHT here, where the sector
       verified it on the left.  For a square matrix the two are
       equivalent, but the equivalence is a theorem about the matrix and
       not about this code, so it is checked rather than assumed. *)
    rightInverse = TrueQ[TimeConstrained[
      masterTransportZeroMatQ[
        Together[phi . phiInverse - IdentityMatrix[dim]]],
      timeLimit, False]];

    homogeneous = masterTransportDTau[phi, tau] - ah . phi;
    homogeneousZero = TrueQ[TimeConstrained[
      masterTransportZeroMatQ[Together[homogeneous]], Min[timeLimit, 120], False]];
    certificateUsed = None;
    If[! homogeneousZero,
      (* The sector check has already proved dPhi/dtau - A_h Phi = 0 on
         THIS path for THIS Phi.  Re-proving it would double the cost of
         the coupled route to establish a statement already in hand, so a
         prior certificate is reused when it carries a proof -- and
         re-derived when it does not. *)
      certificateUsed = If[AssociationQ[priorCertificate] &&
          TrueQ[priorCertificate["Proved"]],
        priorCertificate,
        masterTransportHypergeometricCertificate[
          phi, {{ah, tau}}, eps, <||>, timeLimit]];
      homogeneousZero = AssociationQ[certificateUsed] &&
        TrueQ[certificateUsed["Proved"]]];

    proved = If[TrueQ[derivativeRuleOK] && TrueQ[identityOK] &&
        TrueQ[homogeneousZero] && TrueQ[rightInverse],
      "ByFactorisation", False];

    certificate = <|
      "Statement" -> "d/dtau [Phi (J0 + Int Phi^-1 B I_l)] = A_h Phi (J0 + \
Int Phi^-1 B I_l) + B I_l, proved with I_l left as arbitrary unknown \
functions of tau, so the representation is correct for every \
inhomogeneity.",
      "Proved" -> (proved === True || proved === "ByFactorisation"),
      "Route" -> proved,
      (* the three checked components of the proof, reported separately so
         a failure names which one did not close *)
      "DerivativeRule" -> derivativeRuleOK,
      "RegroupingIdentity" -> identityOK,
      "HomogeneousResidualZero" -> homogeneousZero,
      "RightInverseVerified" -> rightInverse,
      "GaussCertificate" -> certificateUsed,
      "Evaluated" -> False,
      "Claim" -> "A formal integral with an exact differentiate-back \
certificate.  The integrand mixes hypergeometric Phi^-1 with the lower \
solution's Goncharov words; no closed form for the integral is claimed, \
no function class for it is claimed, and no value for it is computed.",
      "LowerRows" -> lowerRows|>;

    <|"Block" -> s, "Range" -> range, "Rows" -> assembly["Blocks"][[s]],
      "Kernel" -> kernel, "Quadrature" -> quadrature,
      "Constants" -> constants, "J" -> jVector, "I" -> iHard,
      "Certificate" -> certificate,
      "OK" -> TrueQ[certificate["Proved"]]|>
  ];

(* The coupled route as a whole.

   Three stages, each of which reports its own verdict:

     1. the closed-form sectors are re-verified exactly as in the
        decoupled route (masterTransportExactSectors);
     2. the graded blocks are solved by the ORDINARY machinery on the
        reduced system -- word transport, regrading, valuation and the
        per-order check against the original DE all apply unchanged,
        because the structural gate guarantees no graded block reads a
        closed-form block, so the graded rows really are a closed
        subsystem;
     3. each closed-form block is represented by Phi-weighted
        quadrature with its differentiate-back certificate.

   The status is deliberately NOT one of the exactness states.  A
   coupled family is returned as a REPRESENTATION containing unevaluated
   integrals, so calling it Exact would claim an evaluation that has not
   happened, and calling it AnalyticCandidate would suggest numerical
   evidence that was never gathered.  It is "OKFormalQuadrature", and
   the "Claim" field states in words exactly what has and has not been
   established. *)
masterTransportCoupledSolve[assembly_, system_, coupling_, closedBlocks_,
    gradedBlocks_, base_, target_, tau_, variables_, regulator_, caps_, card_,
    physicalValuation_, orders_, backend_, verbose_, start_, timeConstraint_,
    deCheckRule_ : All] :=
  Module[{perm, blocks, ranges, gradedOriginal, subSystem, subBlocks, subResult,
     subPerm, subSeries, subOrders, gradedRows, closedRows, indexOf, iLower,
     exact, quadratures, lowerRowsPermuted, status, allProved, n},
    perm = assembly["Perm"];
    blocks = assembly["Blocks"];
    ranges = assembly["Ranges"];
    n = assembly["N"];
    closedRows = Flatten[ranges[[closedBlocks]]];
    gradedRows = Sort[Flatten[ranges[[gradedBlocks]]]];
    (* ORIGINAL row indices of the graded rows, which is what a
       sub-system has to be cut out of *)
    gradedOriginal = Sort[Flatten[blocks[[gradedBlocks]]]];

    (* ---- 1. the sectors themselves --------------------------------- *)
    exact = masterTransportExactSectors[assembly, closedBlocks, base, target, tau,
      variables, regulator, 8, 40, Min[timeConstraint, 120]];
    If[exact["Status"] =!= "OK",
      Return[<|"Status" -> "Rejected", "Exactness" -> "Rejected",
        "Reason" -> "ClosedFormSectorNotVerified", "Exact" -> exact,
        "Assembly" -> assembly, "Family" -> assembly["Family"]|>, Module]];

    (* ---- 2. the lower system, by the ordinary route ----------------- *)
    (* The already-resolved epsilon-forms are handed straight back, so
       the sub-call re-derives nothing and cannot pick a different
       provider than the parent did. *)
    (* the Basis key is OMITTED rather than set to None when there is no
       basis: an absent key and a None value are different things to
       every Lookup downstream, and only one of them is what "no basis"
       has always meant here *)
    subSystem = <|
      "Family" -> ToString[assembly["Family"]] <> ":lower",
      "Av" -> system["Av"][[gradedOriginal, gradedOriginal]],
      "Aw" -> system["Aw"][[gradedOriginal, gradedOriginal]]|>;
    If[! (MissingQ[system["Basis"]] || system["Basis"] === None),
      subSystem = Append[subSystem,
        "Basis" -> system["Basis"][[gradedOriginal]]]];
    subBlocks = Table[
      {Flatten[Position[gradedOriginal, #] & /@ blocks[[g]]],
       <|"Type" -> "EpsForm", "T" -> assembly["Forms"][[g]]["T"],
         "Ev" -> assembly["Forms"][[g]]["Ev"],
         "Ew" -> assembly["Forms"][[g]]["Ew"]|>},
      {g, gradedBlocks}];
    masterTransportLog[verbose, "  coupled closed-form route: solving ",
      Length[gradedOriginal], " lower rows by the ordinary machinery"];
    subResult = TransportFamily[subSystem,
      "Variables" -> variables, "Regulator" -> regulator,
      "Blocks" -> subBlocks, "BasePoint" -> base, "Target" -> target,
      "PathParameter" -> tau, "PhysicalValuation" -> physicalValuation,
      "Orders" -> orders, "TransportBackend" -> backend,
      "MaxWeight" -> caps["MaxWeight"], "TimeConstraint" -> caps["TimeConstraint"],
      "MemoryConstraint" -> caps["MemoryConstraint"], "DECheck" -> deCheckRule,
      "Verbose" -> verbose];
    If[! AssociationQ[subResult] ||
        ! MemberQ[{"OK", "SolvedNotCheckable", "SolvedDECheckSkipped"},
          subResult["Status"]],
      Return[<|"Status" -> "LowerSystemNotSolved", "Lower" -> subResult,
        "Assembly" -> assembly, "Exact" -> exact,
        "Family" -> assembly["Family"]|>, Module]];

    (* ---- the lower solution, in the PARENT's permuted row order ----- *)
    subPerm = subResult["Assembly"]["Perm"];
    subSeries = subResult["I"]["I"];
    subOrders = subResult["I"]["Orders"];
    (* parent permuted position -> index into the sub-system series *)
    indexOf[p_] := Position[subPerm,
      Position[gradedOriginal, perm[[p]]][[1, 1]]][[1, 1]];
    iLower = Table[
      Sum[regulator^subOrders[[k]] *
        subSeries[[k]][[indexOf[gradedRows[[i]]]]], {k, Length[subOrders]}],
      {i, Length[gradedRows]}];

    (* ---- 3. Phi-weighted quadrature per closed-form block ----------- *)
    lowerRowsPermuted = gradedRows;
    quadratures = Table[
      masterTransportPhiQuadrature[assembly, closedBlocks[[k]],
        lowerRowsPermuted, iLower, base, target, tau, variables, regulator,
        Min[timeConstraint, 300],
        Lookup[exact["Sectors"][[k]], "Certificate", None]],
      {k, Length[closedBlocks]}];
    allProved = AllTrue[quadratures, TrueQ[#["OK"]] &];
    Do[
      masterTransportLog[verbose, "  block ", q["Block"], " rows ", q["Rows"],
        " quadrature certificate ", q["Certificate"]["Route"]],
      {q, quadratures}];

    status = If[allProved, "OKFormalQuadrature", "QuadratureNotCertified"];

    <|"Status" -> status,
      "Family" -> assembly["Family"],
      "N" -> n,
      "Assembly" -> assembly,
      "Certificate" -> assembly["Certificate"],
      "Coupling" -> coupling,
      "Exact" -> exact,
      "Exactness" -> exact["Exactness"],
      "Quadrature" -> quadratures,
      "QuadratureCertified" -> allProved,
      "Lower" -> subResult,
      "LowerRows" -> gradedRows,
      "ClosedFormBlocks" -> closedBlocks,
      "ClosedRows" -> closedRows,
      (* The per-order check against the ORIGINAL differential equation
         for the graded rows.  It is the parent's check, not merely the
         sub-system's: the structural gate established that no graded row
         reads a closed-form row, so the two systems agree exactly on
         these rows. *)
      "DECheck" -> subResult["DECheck"],
      "DECheckRule" -> deCheckRule,
      "DECheckSkipped" -> MissingQ[subResult["DECheck"]],
      "DECheckRows" -> gradedRows,
      "I" -> <|"Orders" -> {"FormalQuadrature"},
        "Lower" -> iLower,
        "Hard" -> Table[q["I"], {q, quadratures}]|>,
      (* the claim states what was actually done: with "DECheck" -> None
         the lower blocks are SOLVED but not checked, and a claim that
         says otherwise is the false-pass family this file exists to
         avoid *)
      "Claim" -> If[MissingQ[subResult["DECheck"]],
        "The lower blocks are solved.  The per-order check against the \
original differential equation was SKIPPED (\"DECheck\"), so no per-order \
statement is made about them.  The hard blocks are returned as \
Phi (J0 + Int Phi^-1 B I_l), a FORMAL integral with an exact \
differentiate-back certificate: no closed form for that integral is claimed \
and no value for it is computed.",
        "The lower blocks are solved and checked per epsilon order \
against the original differential equation.  The hard blocks are returned as \
Phi (J0 + Int Phi^-1 B I_l), a FORMAL integral with an exact \
differentiate-back certificate: no closed form for that integral is claimed \
and no value for it is computed."],
      "Path" -> <|"Base" -> base, "Target" -> target, "Parameter" -> tau|>,
      "Variables" -> variables, "Regulator" -> regulator, "Caps" -> caps,
      "Seconds" -> AbsoluteTime[] - start|>
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
  (* "Monolithic" (default) builds ONE path-ordered exponential of the
     whole conjugated connection and regrades it; "Blockwise" constructs
     the solution recursively on the block DAG instead
     (FeynFacet/Private/BlockwiseTransport.wl), which is the same
     mathematics with the union-alphabet word combinatorics removed.
     Everything around the transport -- assembly and its five-part
     certificate, depth arithmetic, valuation constraints, the per-order
     check against the ORIGINAL family differential equation -- is shared,
     so the two engines are comparable entry by entry. *)
  "Engine" -> Automatic,
  "PhiCrossCheck" -> Automatic,
  "PhiCrossCheckMaxWeight" -> 6,
  (* Retain the sparse internal representation word -> rational
     coefficient produced by the blockwise recursion.  This is intended
     for exact downstream linear algebra, such as Laurent-valuation
     constraints, before the maps are converted to TransportWord
     expressions. *)
  "KeepWordMaps" -> False,
  "ConstantDepth" -> Automatic,
  "TransportBackend" -> Automatic,
  "TransportDepth" -> Automatic,
  "DepthRule" -> "Clamped",
  "DepthReport" -> False,
  (* Direct epsilon-order demands for the transformed blocks.  Automatic
     retains the full-family window.  A list follows the caller's declared
     "Blocks" order and is remapped by row set after the assembly orders
     the block DAG; an Association may instead map row lists directly to
     demands.  The resolved demands are propagated through the exact
     Laurent orders of the lower-block couplings before transport;
     -Infinity denotes a block with no direct observable demand. *)
  "BlockDemands" -> Automatic,
  (* Lower Laurent order of each transformed block's boundary constants.
     A list follows the declared "Blocks" order and is remapped by its
     physical row set after DAG ordering, exactly as for BlockDemands. *)
  "BlockLowerOrders" -> Automatic,
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
  (* Which orders the per-order check against the ORIGINAL family
     differential equation runs at (H3, 2026-08-17):

       All (default)  every CHECKABLE order, n <= n1 - |rmin|;
       "Demanded"     only the checkable orders inside the DEMANDED
                      window Range[Min["Orders"], Max["Orders"]] -- the
                      orders the caller asked for, dropping the ones the
                      depth arithmetic added below them for its own
                      reasons (a negative "PhysicalValuation", or a
                      regrading shift that pushes the series lower);
       None           skip the check entirely.

     A SKIPPED check is reported as Missing["Skipped"], never as {}:
     AllTrue[{}, ...] is True, so an empty DECheck would make the status
     "OK" on a check that was never performed.  The status for a skipped
     check is "SolvedDECheckSkipped" and it is decided BEFORE the
     AllTrue. *)
  "DECheck" -> All,
  "Root" -> Automatic,
  (* Automatic admits algebraic letters (quadratic path denominators with
     an eps-free discriminant, see masterTransportMonicCheck); False keeps
     the strict linear gate *)
  "AlgebraicLetters" -> Automatic,
  "Verbose" -> False
};

TransportFamily[input_, opts : OptionsPattern[]] := Catch[
  Module[{
    card, variables, regulator, system, assembly, verbose, root, tau,
    base, target, backend, orders, n0, n1, blocks, formDirectory,
    caps, timeConstraint, memoryConstraint, maxWeight,
    ahat, monic, budget, shift, exactDepth, depthRule, blockDemands,
    blockLowerOrders,
    kminPerBlock, kminF, tr0, kmaxF, jmax, seriesLow,
   closedBlocks, gradedBlocks, closedRows, gradedRows, exact, exactness,
   coupling, solutionLow, diagnostics,
    wmax, backendResult, verification, regraded, solution, valuation,
    series, checkable, deCheck, elapsed, start, status, tinvOrder, nb,
    dimension, targetOrder, checkableRecord, rational, engine, blockwise,
    basePointCandidates, pathTrials, pathChoice, deCheckRule, deChecked,
    stageSeconds},

    start = AbsoluteTime[];
    (* M1: set in the body, never in the Module initializer -- an
       initializer that is not sequentially scoped is one of this file's
       paid-for traps, and an UNSET local would make pathChoice === Null
       False on the first pass and select nothing. *)
    pathChoice = Null;
    verbose = TrueQ[OptionValue["Verbose"]];
    card = masterTransportResolveCard[OptionValue["Card"]];
    If[card === $Failed,
      masterTransportFail[TransportFamily, "option", "Card", OptionValue["Card"],
        TransportFamily]];

    root = masterTransportResolveInstallationRoot[OptionValue["Root"]];
    If[root === $Failed,
      masterTransportFail[TransportFamily, "root", OptionValue["Root"]]];

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
    (* The ENGINE is resolved here, beside the backend, because it decides
       whether a global transport weight is meaningful at all: the
       block-wise engine never builds one Pexp of the whole connection, so
       the global weight cap below does not apply to it. *)
    engine = masterTransportCardSetting[OptionValue["Engine"], card,
      "TransportEngine", "Monolithic"];
    If[engine === Automatic, engine = "Monolithic"];
    If[! MemberQ[{"Monolithic", "Blockwise"}, engine],
      masterTransportFail[TransportFamily, "option", "Engine", engine,
        TransportFamily]];
    blockwise = None;
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
    deCheckRule = OptionValue["DECheck"];
    If[! MemberQ[{All, "Demanded", None}, deCheckRule],
      masterTransportFail[TransportFamily, "option", "DECheck", deCheckRule,
        TransportFamily]];

    (* "BasePoint" takes a point, Automatic, or an explicit list of
       candidate points; the path-direction trial below takes the first
       candidate the monic gate accepts.  The DEFAULT is unchanged --
       {1/4,1/4}, one candidate -- because changing it would silently
       change what an already stored run means. *)
    basePointCandidates = masterTransportBasePointCandidates[
      OptionValue["BasePoint"], variables, 1/4];
    If[basePointCandidates === $Failed,
      masterTransportFail[TransportFamily, "option", "BasePoint",
        OptionValue["BasePoint"], TransportFamily]];
    base = First[basePointCandidates];
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
       series.  If it is DECOUPLED the conjugated connection stays
       rational and the ordinary route below applies.

       If it is COUPLED to lower blocks, the conjugated connection
       acquires Phi^-1-dressed entries and the word backend cannot
       consume them.  That case is no longer refused: it is routed to
       the Phi-weighted quadrature, which solves the lower blocks with
       the ordinary machinery and represents the hard block by variation
       of constants.  The refusal that remains is structural and named
       (a graded block reading FROM a closed-form block, or nested
       closed-form blocks). *)
    closedBlocks = Select[Range[nb],
      assembly["Forms"][[#]]["Type"] === "ClosedFormSector" &];
    gradedBlocks = Complement[Range[nb], closedBlocks];
    closedRows = Flatten[assembly["Ranges"][[closedBlocks]]];
    gradedRows = Sort[Flatten[assembly["Ranges"][[gradedBlocks]]]];

    coupling = If[closedBlocks === {}, None,
      masterTransportClosedFormCoupling[assembly, closedBlocks, gradedBlocks]];
    (* The UNSUPPORTED structures are diagnosed even when the closed-form
       block itself reads nothing.  Otherwise a family whose only
       irregularity is a graded block reading FROM a closed-form block
       would fall through to the generic
       "ConjugatedConnectionNotRational" -- true, but it names the
       symptom rather than the cause, and the cause is structural and
       known here. *)
    If[AssociationQ[coupling] &&
        (TrueQ[coupling["Coupled"]] || coupling["FeedsGraded"] =!= {} ||
         coupling["ClosedToClosed"] =!= {}),
      If[! TrueQ[coupling["Supported"]],
        Return[<|"Status" -> "CoupledClosedFormNotSupported",
          "Coupling" -> coupling, "Assembly" -> assembly,
          "Reason" -> If[coupling["FeedsGraded"] =!= {},
            "a graded block reads from a closed-form block: the word backend \
would have to integrate 2F1-dressed sources",
            "a closed-form block reads from another closed-form block: this \
needs nested quadrature"],
          "Family" -> assembly["Family"]|>, Module]];
      Return[
        masterTransportCoupledSolve[assembly, system, coupling, closedBlocks,
          gradedBlocks, base, target, tau, variables, regulator, caps, card,
          OptionValue["PhysicalValuation"], OptionValue["Orders"], backend,
          verbose, start, timeConstraint, deCheckRule],
        Module]];

    (* ------------------------------------------- path-direction trial *)
    (* Which AXIS the path runs along is a property of the family's
       alphabet, not of the caller.  MEASURED 2026-08-17: CF301's letter
       (1-v)^2 + v w is QUADRATIC in tau on the segment from {1/4, w} to
       {v, w} -- v moving, w frozen at its symbolic target -- and LINEAR
       on the segment from {v, 1/4}, w moving.  The monic gate refuses
       the first and accepts the second, and nothing outside this module
       can be expected to know that in advance.

       So the candidates are tried in order and the FIRST the gate
       accepts is taken; a single candidate (the default) reproduces the
       old code exactly, one gate call and one Ahat.  A candidate is
       evaluated only while none has been accepted, so the second
       direction costs nothing when the first works.

       "AlgebraicLetters" -> Automatic (default) admits quadratic
       denominators in the path parameter as pairs of algebraic letters
       (radicals of the frozen variable; see the radical discipline next
       to masterTransportSimplifyZeroQ) provided every discriminant is
       eps-free; False restores the strict linear gate; degree >= 3 is
       always refused.  Which letters are algebraic is recorded under
       "Monic" -> "Quadratics" of the result. *)
    pathTrials = {};
    Do[
      If[pathChoice === Null,
        Module[{candidate = basePointCandidates[[bi]], a, r, m, ok},
          a = masterTransportPathMatrix[assembly["Apv"], assembly["Apw"],
            target, candidate, tau, variables];
          r = FreeQ[a, Hypergeometric2F1 | HypergeometricPFQ | Log | PolyLog |
            Gamma | TransportWord];
          m = If[TrueQ[r], masterTransportMonicCheck[a, tau, regulator],
            Missing["NotRational"]];
          ok = TrueQ[r] && (TrueQ[m["Linear"]] ||
            (OptionValue["AlgebraicLetters"] =!= False &&
             TrueQ[m["AlgebraicAdmissible"]]));
          pathTrials = Append[pathTrials,
            <|"BasePoint" -> candidate, "Rational" -> r, "Monic" -> m,
              "Accepted" -> ok|>];
          If[ok, pathChoice = <|"BasePoint" -> candidate, "Ahat" -> a,
            "Monic" -> m|>]]],
      {bi, Length[basePointCandidates]}];

    (* Every direction refused.  BOTH monic records travel with the
       refusal: the reason one axis fails and another might not is
       exactly what the reader needs, and reporting only the first would
       hide that the other was tried. *)
    If[pathChoice === Null,
      If[! TrueQ[First[pathTrials]["Rational"]],
        Return[<|"Status" -> "ConjugatedConnectionNotRational",
          "Assembly" -> assembly, "PathTrials" -> pathTrials,
          "Family" -> assembly["Family"]|>, Module]];
      Return[<|"Status" -> "PathDenominatorsNotLinear",
        "Monic" -> First[pathTrials]["Monic"], "PathTrials" -> pathTrials,
        "BasePointCandidates" -> basePointCandidates,
        "Assembly" -> assembly, "Family" -> assembly["Family"]|>, Module]];

    base = pathChoice["BasePoint"];
    ahat = pathChoice["Ahat"];
    monic = pathChoice["Monic"];
    (* D4 (generality pass 2026-08-23): the transport STARTS at the base
       point, so a letter of the assembled connection that vanishes
       there puts tau = 0 on a singular locus and every word built on
       the path diverges.  The path denominators are exactly the
       assembled letters restricted to the path, so the test is whether
       one of them vanishes at tau = 0.  The default base {1/4, 1/4} is
       off every letter of this project's families, which is why this
       was never a wrong answer here; a caller supplying its own base
       now gets a typed refusal instead of divergent words. *)
    With[{vanishing = Select[
        If[AssociationQ[monic], Lookup[monic, "Denominators", {}], {}],
        TrueQ[Together[# /. tau -> 0] === 0] &]},
      If[vanishing =!= {},
        Return[<|"Status" -> "BasePointOnLetterZero",
          "BasePoint" -> base, "VanishingLetters" -> vanishing,
          "PathTrials" -> pathTrials,
          "BasePointCandidates" -> basePointCandidates,
          "Assembly" -> assembly, "Family" -> assembly["Family"]|>,
          Module]]];
    rational = True;
    If[Length[basePointCandidates] > 1,
      masterTransportLog[verbose, "  path direction: ", base,
        " (candidate ", FirstPosition[basePointCandidates, base][[1]], " of ",
        Length[basePointCandidates], ")"]];

    exact = If[closedBlocks === {}, None,
      (* The path-frame identity dPhi/dtau = Ahat.Phi FOLLOWS from the
         block certificate dPhi/dx_i = A_i.Phi by the chain rule, so this
         is a confirmation rather than an independent statement, and it
         gets a bounded budget accordingly.  What it adds is a check that
         the path restriction itself was applied consistently. *)
      masterTransportExactSectors[assembly, closedBlocks, base, target, tau,
        variables, regulator, 8, 40, Min[timeConstraint, 120]]];
    If[exact =!= None && exact["Status"] =!= "OK",
      Return[<|"Status" -> "Rejected", "Exactness" -> "Rejected",
        "Reason" -> "ClosedFormSectorNotVerified", "Exact" -> exact,
        "Assembly" -> assembly, "Family" -> assembly["Family"]|>, Module]];
    (* "NotApplicable", not "Exact": a family with no closed-form sector
       has nothing for this taxonomy to describe, and reporting the
       vacuous truth as "Exact" would read as a claim about the family. *)
    exactness = If[exact === None, "NotApplicable", exact["Exactness"]];
    If[exact =!= None,
      masterTransportLog[verbose, "  closed-form sectors verified: ",
        Table[r["CheckRoute"], {r, exact["Sectors"]}],
        " -> ", exactness]];

    (* A family made ENTIRELY of closed-form sectors has no word
       transport and no graded series: the certificate above is the whole
       statement, and the STATUS IS THAT CERTIFICATE'S VERDICT.

       This is the distinction Codex's assessment turns on.  The old
       status "OKExactInEps" was returned on either route, so a sector
       accepted on a Frobenius truncation plus four numerical points read
       exactly like one proved symbolically.  Now the series-and-numeric
       route returns "AnalyticCandidate" -- a status that does not
       contain the word Exact, and cannot be mistaken for it by a
       reader, a grep, or a test. *)
    If[gradedBlocks === {},
      Return[<|"Status" -> exactness, "Family" -> assembly["Family"],
        "N" -> dimension, "Assembly" -> assembly,
        "Certificate" -> assembly["Certificate"], "Backend" -> None,
        "Weight" -> 0, "Exact" -> exact, "Exactness" -> exactness,
        "Constants" -> Association[
          Table[{r["Block"], "Exact"} -> r["Constants"], {r, exact["Sectors"]}]],
        "I" -> <|"Orders" -> {"Exact"},
          "I" -> Table[r["I"], {r, exact["Sectors"]}]|>,
        "Path" -> <|"Base" -> base, "Target" -> target, "Parameter" -> tau,
        "Candidates" -> basePointCandidates, "Trials" -> pathTrials|>,
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
    blockLowerOrders = masterTransportResolveBlockDemands[
      OptionValue["BlockLowerOrders"], blocks, assembly];
    If[blockLowerOrders =!= Automatic,
      If[blockLowerOrders === $Failed ||
          ! AllTrue[blockLowerOrders, IntegerQ],
        masterTransportFail[TransportFamily, "option", "BlockLowerOrders",
          OptionValue["BlockLowerOrders"], TransportFamily]];
      kminPerBlock = blockLowerOrders];
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

    (* (C4b) the exact per-block recursion.  It is LAZY: the full
       Laurent support of every coupling costs a Series per entry when a
       coupling's eps-denominator is not a monomial, and on CF230 that
       MEASURED 243 s against 56 s for all the rest of the pre-transport
       arithmetic.  Paying that on a run that does not use the number is
       a change of default behaviour, so it is computed only when the
       caller actually wants it:

         "DepthRule" -> "Exact"   -- it sets the weight, so it must run;
         "DepthReport" -> True    -- the caller wants the ledger.

       Otherwise the clamped rule alone is reported and "ExactDepth" is
       an explicit Missing["NotComputed"], never a silently absent key. *)
    depthRule = OptionValue["DepthRule"];
    If[! MemberQ[{"Clamped", "Exact"}, depthRule],
      masterTransportFail[TransportFamily, "option", "DepthRule", depthRule,
        TransportFamily]];
    blockDemands = masterTransportResolveBlockDemands[
      OptionValue["BlockDemands"], blocks, assembly];
    If[blockDemands =!= Automatic,
      If[blockDemands === $Failed,
        masterTransportFail[TransportFamily, "option", "BlockDemands",
          OptionValue["BlockDemands"], TransportFamily]];
      If[depthRule =!= "Exact",
        masterTransportFail[TransportFamily, "option",
          "BlockDemands requires DepthRule -> Exact", depthRule,
          TransportFamily]]];
    (* one family per cache: the entries are this family's couplings, so
       carrying them into the next family is pure memory growth in a
       long-lived pool subkernel.  A caller that re-runs the recursion on
       THIS family afterwards (the ledger does, with the measured
       per-master demands) still hits the warm cache. *)
    masterTransportSupportCacheClear[];
    exactDepth = If[depthRule === "Exact" || TrueQ[OptionValue["DepthReport"]],
      masterTransportExactDepth[assembly, ahat,
        <|"Demands" -> If[blockDemands === Automatic, budget["Need"], blockDemands],
          "KMin" -> kminPerBlock|>, regulator],
      Missing["NotComputed: set \"DepthReport\" -> True or \"DepthRule\" -> \"Exact\""]];
    If[blockDemands =!= Automatic,
      If[! AssociationQ[exactDepth] || Lookup[exactDepth, "Status", None] =!= "OK",
        Return[<|"Status" -> "BlockDemandPropagationFailed",
          "BlockDemands" -> blockDemands, "ExactDepth" -> exactDepth,
          "Assembly" -> assembly, "Family" -> assembly["Family"]|>, Module]];
      Module[{raw = exactDepth["NMax"], scheduled},
        (* An unconnected block has no route into a requested master.  Give
           it an empty order interval [lowest,lowest-1]; the solver then
           builds neither constants nor words for that block. *)
        scheduled = MapThread[If[#1 === -Infinity, #2 - 1, #1] &,
          {raw, exactDepth["Lowest"]}];
        exactDepth = Join[exactDepth,
          <|"RawNMax" -> raw, "NMax" -> scheduled,
            "InactiveBlocks" -> Flatten[Position[raw, -Infinity]]|>];
        budget = Join[budget,
          <|"UniformNeed" -> budget["Need"],
            "DirectDemands" -> blockDemands, "Need" -> scheduled|>]]];

    wmax = masterTransportCardSetting[OptionValue["TransportDepth"], card,
      "TransportDepth", Automatic];
    If[wmax === Automatic,
      wmax = If[depthRule === "Exact" && AssociationQ[exactDepth] &&
          exactDepth["Status"] === "OK" && IntegerQ[exactDepth["WMax"]],
        exactDepth["WMax"],
        jmax + shift["Shift"]]];
    If[! (IntegerQ[wmax] && wmax >= 0),
      masterTransportFail[TransportFamily, "option", "TransportDepth", wmax,
        TransportFamily]];
    (* The cap guards the MONOLITHIC Pexp, whose cost is (letters)^wmax on
       every entry.  The block-wise engine never builds that object -- its
       cost is per block and per order -- so it carries its own per-block
       cap inside masterTransportBlockwiseSolve and is not refused here.
       (This is also what lets a family whose monolithic weight is out of
       reach still be solved block-wise, which is the whole point.) *)
    If[wmax > maxWeight && engine =!= "Blockwise",
      Return[<|"Status" -> "DepthExceedsCap", "Requested" -> wmax,
        "Cap" -> maxWeight, "Shift" -> shift, "Budget" -> budget,
        "ExactDepth" -> exactDepth, "DepthRule" -> depthRule,
        "KMinPerBlock" -> kminPerBlock, "TInverseOrder" -> tinvOrder,
        "ClampedWeight" -> jmax + shift["Shift"],
        (* the path record travels with this refusal too: "MaxWeight" -> 0
           is how the ledger reaches the assembly and the depth
           arithmetic, and which axis direction the trial took is part of
           what that run establishes *)
        "Path" -> <|"Base" -> base, "Target" -> target, "Parameter" -> tau,
          "Candidates" -> basePointCandidates, "Trials" -> pathTrials|>,
        "Monic" -> monic,
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
      "ExactDepth" -> exactDepth,
      "BlockDemands" -> blockDemands,
      "DepthRule" -> depthRule,
      "ClampedWeight" -> jmax + shift["Shift"],
      "Weight" -> wmax,
      "Monic" -> monic,
      "Path" -> <|"Base" -> base, "Target" -> target, "Parameter" -> tau,
        "Candidates" -> basePointCandidates, "Trials" -> pathTrials|>,
      "PhysicalValuation" -> n0,
      "Certificate" -> assembly["Certificate"]|>;

    (* H2: exactDepth is an explicit Missing[...] whenever the exact
       recursion was not asked for, and Lookup on a Missing raises
       Lookup::invrl and then prints its own unevaluated head into the
       log (measured in payoff2.log).  A progress line must never emit a
       message; the guard is one MissingQ, and the line then says
       "not computed" rather than a broken expression. *)
    masterTransportLog[verbose, "  depth: transport weight ", wmax,
      " (rule ", depthRule, "; clamped jmax ", jmax, " + shift ",
      shift["Shift"], " = ", jmax + shift["Shift"], ", exact ",
      If[AssociationQ[exactDepth], Lookup[exactDepth, "WMax", "?"],
        "not computed"], "), F orders ",
      kminF, "..", kmaxF, ", I orders ", n0, "..", n1,
      ", global rmin ", budget["RMinGlobal"]];

    (* ------------------------------------------------- transport ------ *)
    If[engine === "Blockwise",
    (* ---------------------------------------- (B) block-wise engine ---
       The solution is constructed recursively on the block DAG
       (BlockwiseTransport.wl): no monolithic Pexp, no union alphabet, no
       weight-to-epsilon regrading (the recursion is graded in epsilon by
       construction), and the gate is the recursion certificate rather
       than the per-weight Pexp recursion.  Everything after this point --
       valuation, master series, the per-order check against the ORIGINAL
       family differential equation -- is the same code on the same
       objects, which is what makes the two engines comparable entry by
       entry. *)
    blockwise = masterTransportBlockwiseSolve[assembly, ahat, budget,
      kminPerBlock, kmaxF, n0, tau, regulator, variables, base, target,
      "Verbose" -> verbose, "Root" -> root, "MaxWeight" -> maxWeight,
      "Certify" -> TrueQ[OptionValue["Verify"]],
      "PhiCrossCheck" -> OptionValue["PhiCrossCheck"],
      "PhiCrossCheckMaxWeight" -> OptionValue["PhiCrossCheckMaxWeight"],
      "KeepMaps" -> TrueQ[OptionValue["KeepWordMaps"]],
      "ConstantDepth" -> OptionValue["ConstantDepth"],
      "ExactDepth" -> exactDepth];
    If[! AssociationQ[blockwise] ||
        ! MemberQ[{"OK", "SolvedNotCertified", "RecursionCertificateFailed"},
          blockwise["Status"]],
      Return[Join[diagnostics,
        <|"Status" -> "BlockwiseTransportFailed", "Engine" -> engine,
          "Blockwise" -> blockwise, "Assembly" -> assembly,
          "Family" -> assembly["Family"]|>], Module]];
    solution = blockwise["Solution"];
    solutionLow = solution["FLow"];
    wmax = blockwise["Weight"];
    backendResult = <|"Status" -> "OK", "Backend" -> "Blockwise", "U" -> None|>;
    verification = <|"IdentityAtWeightZero" -> True, "PerWeight" -> {},
      "AllZero" -> TrueQ[blockwise["Certificate"]["AllZero"]],
      "Route" -> "BlockwiseRecursionCertificate"|>;
    (* H1, block-wise branch, and precisely WHY the monolithic
       completeness statement is not needed here.

       There is no weight-to-epsilon REGRADING on this path: the
       recursion is graded in epsilon by construction, so the clamped
       statement wmax + 1 - D > j1 has nothing to be made about and
       masterTransportRegrade is correctly never called.  The block-wise
       completeness statement is instead the SCHEDULE plus the recursion
       certificate: the schedule fixes each block's window [low_i, top_i]
       and guarantees top_j >= top_i - rmin_ij, i.e. that every source a
       block reads has already been solved to the order it is read at,
       and blockwise["Certificate"] then verifies the constructed
       solution order by order.

       The exact rule's numbers are recorded here as a DIAGNOSTIC beside
       that, never as a gate.  They are a different quantity:
       "PerBlockScheduleWeight" is the window top_i - low_i, while
       exactDepth's W_i(N_i) is the CHAIN weight, which the recursion
       reaches through the higher orders of lower blocks that couplings
       of negative epsilon order read.  Window < W_i is therefore normal
       -- measured 2026-08-17 on CF262: windows <= 3 against chain weight
       4, with every certificate exact -- and an earlier version of this
       block that REFUSED on it was wrong.  Both numbers travel in the
       record so the difference can be read off a run, and they are
       Missing (not False) when the exact recursion was not computed or
       its Laurent support was truncated. *)
    regraded = Module[{perBlockWeight, need, usable, verdicts},
      perBlockWeight = Lookup[Lookup[blockwise, "Schedule", <||>],
        "PerBlockWeight", None];
      need = If[AssociationQ[exactDepth], Lookup[exactDepth, "W", None], None];
      usable = ListQ[perBlockWeight] && ListQ[need] &&
        Length[perBlockWeight] === Length[need] &&
        FreeQ[need, -Infinity | Infinity] &&
        AssociationQ[exactDepth] && exactDepth["Status"] === "OK" &&
        ! AnyTrue[Values[Lookup[exactDepth, "SupportTruncated", <||>]], TrueQ];
      verdicts = If[usable,
        Table[perBlockWeight[[i]] >= need[[i]], {i, Length[need]}],
        Missing["NoExactDepth"]];
      <|"Orders" -> Range[solutionLow, kmaxF],
        "Shift" -> shift["Shift"], "TopWeight" -> blockwise["Weight"],
        "Complete" -> True,
        "CompleteRoute" -> "BlockwiseRecursion",
        "PerBlockComplete" -> verdicts,
        "PerBlockScheduleWeight" -> If[ListQ[perBlockWeight], perBlockWeight,
          Missing["NoSchedule"]],
        "PerBlockWeightNeeded" -> If[usable, need, Missing["NoExactDepth"]],
        "ExactDepthConsistent" -> If[usable, AllTrue[verdicts, TrueQ],
          Missing["NoExactDepth"]],
        "Route" -> "BlockwiseRecursion (graded in epsilon by construction; \
no weight-to-epsilon regrading is performed; completeness is the schedule \
plus the recursion certificate, and the exact rule's chain weights travel \
beside them as a diagnostic)"|>];
    (* NOT a refusal (coordinator, 2026-08-17 03:45, measured on CF262):
       "PerBlockScheduleWeight" is the schedule WINDOW top_i - low_i, while
       the exact rule's W_i(N_i) is the CHAIN weight, which the recursion
       reaches through the higher orders of lower blocks that couplings of
       negative epsilon order read (the schedule guarantees top_j >= top_i
       - rmin_ij by construction).  The two are different quantities and
       window < W_i is normal (CF262: windows <= 3, chain weight 4, every
       certificate exact).  The comparison stays in the record as a
       diagnostic; the block-wise completeness statement is the schedule
       plus the recursion certificate. *)
    If[AssociationQ[regraded] && regraded["ExactDepthConsistent"] === False,
      masterTransportLog[verbose, "  blockwise: schedule windows ",
        regraded["PerBlockScheduleWeight"], " vs exact chain weights ",
        regraded["PerBlockWeightNeeded"], " (diagnostic only)"]];
    masterTransportLog[verbose, "  blockwise: status ", blockwise["Status"],
      ", max words per block-order ", blockwise["MaxWordCount"],
      ", max Chen weight ", blockwise["Weight"], ", ",
      Round[blockwise["Seconds"], 0.1], " s"],

    (* ---------------------------------------- (M) monolithic engine --- *)
    (* The budget is handed to the BACKEND, not only wrapped around it:
       inside, the weight ladder turns an overrun into a checkpoint.  The
       outer TimeConstrained stays as a hard guard with a margin, for a
       backend that does not take a budget at all (a custom one). *)
    backendResult = TimeConstrained[
      MemoryConstrained[
        masterTransportRunBackend[backend, ahat, tau, wmax, root, regulator,
          timeConstraint],
        memoryConstraint, <|"Status" -> "BackendMemoryExceeded"|>],
      If[NumericQ[timeConstraint], timeConstraint + 60, timeConstraint],
      <|"Status" -> "BackendTimedOut"|>];
    (* A budget overrun is no longer "nothing": the weights that DID
       complete travel back with the depth arithmetic and the per-weight
       wall times, so the run is a cost data point and a restart point
       rather than a loss.  It is still NOT a solution, and its status
       says so. *)
    If[AssociationQ[backendResult] &&
       backendResult["Status"] === "BackendBudgetExceeded",
      Return[Join[diagnostics,
        <|"Status" -> "TransportBudgetExceeded", "Backend" -> backend,
          "BackendResult" -> KeyDrop[backendResult, "U"],
          "PartialWeight" -> Lookup[backendResult, "Weight", -1],
          "RequestedWeight" -> wmax,
          "PerWeightSeconds" -> Lookup[backendResult, "PerWeightSeconds", {}],
          "PartialTransportWeightGraded" -> Lookup[backendResult, "U", {}],
          "Assembly" -> assembly,
          "Family" -> assembly["Family"]|>], Module]];
    If[! AssociationQ[backendResult] || backendResult["Status"] =!= "OK",
      (* A failing backend may still have completed lower weights (the
         ladder keeps them).  They travel under their own key with a
         failing status, never as "the transport": they have not been
         through the mandatory recursion gate. *)
      Return[Join[diagnostics,
        <|"Status" -> "TransportFailed", "Backend" -> backend,
          "BackendResult" -> If[AssociationQ[backendResult],
            KeyDrop[backendResult, "U"], backendResult],
          "PartialWeight" -> If[AssociationQ[backendResult],
            Lookup[backendResult, "Weight", -1], -1],
          "PartialTransportWeightGraded" -> If[AssociationQ[backendResult],
            Lookup[backendResult, "U", {}], {}],
          "PerWeightSeconds" -> If[AssociationQ[backendResult],
            Lookup[backendResult, "PerWeightSeconds", {}], {}],
          "Assembly" -> assembly,
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
    (* exactDepth travels in so the completeness statement can be made
       PER BLOCK (H1); it is Missing[...] unless the caller asked for the
       exact recursion, and the clamped route then decides alone, exactly
       as before. *)
    regraded = masterTransportRegrade[backendResult["U"], {-shift["Shift"], jmax},
      shift["Shift"], regulator, exactDepth];
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
      Return[<|"Status" -> "SolutionVectorFailed", "Assembly" -> assembly|>, Module]]
    ];

    (* ------------------------------------------------ (C2) valuation --- *)
    masterTransportLog[verbose, "  imposing physical Laurent valuation"];
    {stageSeconds, valuation} = AbsoluteTiming[
      masterTransportValuation[assembly, solution, n0, base, target,
        tau, variables, regulator, verbose]];
    masterTransportLog[verbose, "  physical Laurent valuation finished in ",
      Round[stageSeconds, 0.1], " s"];
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
    masterTransportLog[verbose, "  forming physical-basis Laurent coefficients"];
    {stageSeconds, series} = AbsoluteTiming[
      masterTransportMasterSeries[assembly, solution, {seriesLow, n1}, base,
        target, tau, variables, regulator, gradedBlocks]];
    masterTransportLog[verbose, "  physical-basis Laurent coefficients finished in ",
      Round[stageSeconds, 0.1], " s"];

    checkableRecord = masterTransportCheckableOrders[{n0, n1}, budget["RMinGlobal"]];
    checkable = checkableRecord["Checkable"];
    (* H3: which of the checkable orders this run actually checks. *)
    deChecked = Switch[deCheckRule,
      None, {},
      "Demanded", Select[checkable,
        Min[Flatten[{orders}]] <= # <= Max[Flatten[{orders}]] &],
      _, checkable];
    checkableRecord = Join[checkableRecord, <|
      "DECheckRule" -> deCheckRule,
      "Demanded" -> Range[Min[Flatten[{orders}]], Max[Flatten[{orders}]]],
      "Checked" -> deChecked,
      "NotChecked" -> Complement[checkable, deChecked]|>];
    deCheck = Which[
      ! TrueQ[OptionValue["Verify"]], {},
      checkable === {}, {},
      (* the TRAP, spelled out: an EMPTY result would make the AllTrue
         below vacuously true, so a check that was not performed is
         Missing["Skipped"] and is discriminated before the AllTrue *)
      deChecked === {}, Missing["Skipped"],
      True, masterTransportCheckDE[assembly, series, deChecked, base, target,
        tau, variables, regulator,
        If[closedBlocks === {}, All, gradedRows], verbose]];

    elapsed = AbsoluteTime[] - start;
    status = Which[
      ! TrueQ[OptionValue["Verify"]], "Unverified",
      (* the block-wise engine's own gate comes FIRST: a family whose
         recursion certificate did not close must never be reported as OK
         because the (separate, weaker) original-DE check happened to pass
         on the orders it could reach *)
      engine === "Blockwise" && ! TrueQ[blockwise["Certificate"]["AllZero"]],
        "RecursionCertificateFailed",
      (* H3 TRAP: BEFORE the AllTrue.  AllTrue[{}, ...] is True, so a
         skipped check reaching the AllTrue would be reported as OK. *)
      MissingQ[deCheck], "SolvedDECheckSkipped",
      checkable === {}, "SolvedNotCheckable",
      AllTrue[deCheck, #["Zero"] === {True} &], "OK",
      True, "CheckInconclusive"];

    <|"Status" -> status,
      "Family" -> assembly["Family"],
      "N" -> dimension,
      "Engine" -> engine,
      "Blockwise" -> If[engine === "Blockwise",
        KeyDrop[blockwise, "Solution"], None],
      "Assembly" -> assembly,
      "Certificate" -> assembly["Certificate"],
      "Backend" -> backendResult["Backend"],
      "BackendRoute" -> Lookup[backendResult, "Route", "SingleCall"],
      "PerWeightSeconds" -> Lookup[backendResult, "PerWeightSeconds", {}],
      "TransportVerification" -> verification,
      "Monic" -> monic,
      "Budget" -> budget,
      "Shift" -> shift,
      "ExactDepth" -> exactDepth,
      "DepthRule" -> depthRule,
      "ClampedWeight" -> jmax + shift["Shift"],
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
      (* the closed-form sectors' verdict travels with a mixed family
         too, where the family Status describes the WORD transport and
         says nothing about how the Phi blocks were established *)
      "Exactness" -> exactness,
      "ClosedFormBlocks" -> closedBlocks,
      "GradedRows" -> gradedRows,
      "I" -> series,
      "Checkable" -> checkableRecord,
      "DECheck" -> deCheck,
      "Path" -> <|"Base" -> base, "Target" -> target, "Parameter" -> tau,
        "Candidates" -> basePointCandidates, "Trials" -> pathTrials|>,
      "Variables" -> variables,
      "Regulator" -> regulator,
      "Caps" -> caps,
      "Seconds" -> elapsed|>
  ],
  $masterTransportFailure
];

Options[TransportFamilyInChart] = Join[
  {"SourceVariables" -> Automatic,
   "CoefficientField" -> Automatic,
   "AssemblyOnly" -> False,
   "ConicChartRoute" -> Automatic,
   "PathDirection" -> Automatic,
   "PathAnchor" -> 1/2,
   "BasePoint" -> Automatic},
  FilterRules[Options[TransportFamily], Except["Variables" | "BasePoint"]]];

TransportFamilyInChart[system_, chart_, opts : OptionsPattern[]] := Catch[
  Module[{sourceVariables, data, eps, normalized, pullback, chartSystem,
    chartVariables, blockSpecification, blocks, specs, resolved, failures,
    basePoint, target, direction, anchor, formDirectory, verbose, result,
    start, notes, forms, conicRoute, directionPoint, chosenBase,
    coefficientField, assembled},
    start = AbsoluteTime[];
    verbose = TrueQ[OptionValue["Verbose"]];
    (* OptionValue is resolved once, in the body, and never from inside a
       nested Table or Function where the enclosing definition is no
       longer the innermost one. *)
    conicRoute = OptionValue["ConicChartRoute"];
    sourceVariables = masterTransportResolveVariables[OptionValue["SourceVariables"]];
    If[sourceVariables === $Failed,
      masterTransportFail[TransportFamilyInChart, "option", "SourceVariables",
        OptionValue["SourceVariables"], TransportFamilyInChart]];
    If[! AssociationQ[system],
      masterTransportFail[TransportFamilyInChart, "option", "input", system,
        TransportFamilyInChart]];
    data = masterTransportChartData[chart, sourceVariables];
    If[data["Status"] =!= "OK",
      Return[<|"Status" -> "ChartRefused", "Chart" -> data,
        "Family" -> Lookup[system, "Family", None]|>, Module]];
    coefficientField = OptionValue["CoefficientField"];
    If[coefficientField === Automatic,
      coefficientField = Lookup[data, "CoefficientField", "Rational"]];
    If[! MemberQ[{"Rational", "Multiquadratic"}, coefficientField],
      Return[<|"Status" -> "ChartCoefficientFieldInvalid",
        "CoefficientField" -> coefficientField,
        "Family" -> Lookup[system, "Family", None]|>, Module]];
    chartVariables = data["Variables"];

    eps = masterTransportResolveRegulator[OptionValue["Regulator"],
      {Lookup[system, "Av", 0], Lookup[system, "Aw", 0]}, sourceVariables];
    If[eps === $Failed || ! MatchQ[eps, _Symbol],
      masterTransportFail[TransportFamilyInChart, "regulator",
        Lookup[system, "Family", system]]];
    (* P2 again: normalize BEFORE any pullback and long before a backend
       package can claim v, w, x, y or eps for itself. *)
    normalized = masterTransportNormalize[system, eps,
      Join[sourceVariables[[{1, 2}]], chartVariables]];

    masterTransportLog[verbose, "chart: ", data["Subst"],
      ", det d(v,w)/d(x,y) = ", data["JacobianDet"]];

    pullback = masterTransportPullBackSystem[normalized, data,
      "SourceVariables" -> sourceVariables,
      "FlatnessCheck" -> (masterTransportCheckLevel[] =!= "Production")];
    If[pullback["Status"] =!= "OK",
      Return[<|"Status" -> "ChartPullBackFailed", "Reason" -> pullback["Status"],
        "PullBack" -> <|"System" -> pullback|>, "Chart" -> data,
        "Family" -> Lookup[system, "Family", None],
        "Seconds" -> AbsoluteTime[] - start|>, Module]];
    chartSystem = pullback["System"];
    masterTransportLog[verbose, "  system pulled back: flat(chart) ",
      pullback["Certificate"]["ChartFlat"]];

    formDirectory = OptionValue["FormDirectory"];
    If[formDirectory === Automatic, formDirectory = None];

    blockSpecification = OptionValue["Blocks"];
    If[blockSpecification === Automatic,
      blocks = masterTransportSCCBlocks[pullback["Ax"], pullback["Ay"]];
      specs = ConstantArray[Automatic, Length[blocks]],
      blocks = blockSpecification[[All, 1]];
      specs = blockSpecification[[All, 2]]];

    resolved = Table[
      Module[{r},
        r = masterTransportChartBlockSpec[specs[[i]], blocks[[i]],
          pullback["Ax"], pullback["Ay"], data, eps, formDirectory,
          conicRoute, coefficientField];
        (* per-block progress with everything a rate needs: which block,
           its dimension, the verdict, the frame it composed through, and
           the SIZE of the object just produced *)
        masterTransportLog[verbose, "  block ", i, "/", Length[blocks],
          " rows ", blocks[[i]], " dim ", Length[blocks[[i]]],
          " class ", Lookup[r, "ClassID", "-"], " -> ", r["Status"],
          " frame ", Lookup[Lookup[r, "Certificate", <||>], "Frame", "-"],
          If[TrueQ[Lookup[Lookup[r, "Certificate", <||>], "Swapped", False]],
            " swapped", ""],
          " T leaves ", If[MatrixQ[Lookup[Lookup[r, "Spec", <||>], "T", None]],
            LeafCount[r["Spec"]["T"]], "-"],
          " bytes ", If[MatrixQ[Lookup[Lookup[r, "Spec", <||>], "T", None]],
            ByteCount[r["Spec"]["T"]], "-"]];
        r],
      {i, Length[blocks]}];
    failures = Select[Transpose[{blocks, resolved}], #[[2]]["Status"] =!= "OK" &];
    (* fail closed: a family is transported in the chart only when EVERY
       block's form was pulled back and re-verified there *)
    If[failures =!= {},
      Return[<|"Status" -> "ChartPullBackFailed",
        "Reason" -> "ClassFormNotPullable",
        "PullBack" -> <|"System" -> pullback["Certificate"],
          "Forms" -> resolved|>,
        "Failures" -> failures, "Chart" -> data,
        "ChartNotes" -> masterTransportChartNotes[data, None, None, "none"],
        "Family" -> Lookup[system, "Family", None],
        "Seconds" -> AbsoluteTime[] - start|>, Module]];

    (* Which chart axis the path runs along.  "PathDirection" -> "First"
       freezes the SECOND chart variable at its symbolic target and moves
       the first from the anchor, "Second" is the mirror image, and
       Automatic (the default) hands BOTH down as candidates and lets the
       monic gate in TransportFamily choose -- the same trial the (v,w)
       entry point makes, for the same measured reason (a letter that is
       bilinear in the chart variables is linear on one axis and need not
       be on the other).  The direction that was actually taken is read
       back off the result and recorded in "ChartNotes". *)
    direction = OptionValue["PathDirection"];
    anchor = OptionValue["PathAnchor"];
    directionPoint[d_] := Switch[d,
      "First", {anchor, chartVariables[[2]]},
      "Second", {chartVariables[[1]], anchor},
      _, {anchor, anchor}];
    basePoint = OptionValue["BasePoint"];
    If[basePoint === Automatic,
      basePoint = If[direction === Automatic,
        {directionPoint["First"], directionPoint["Second"]},
        directionPoint[direction]]];
    target = OptionValue["Target"];
    If[target === Automatic, target = chartVariables];

    forms = Association @ Table[
      blocks[[i]] -> resolved[[i]]["Certificate"], {i, Length[blocks]}];
    If[TrueQ[OptionValue["AssemblyOnly"]],
      assembled = masterTransportAssemble[chartSystem, eps, chartVariables,
        "Blocks" -> Table[{blocks[[i]], resolved[[i]]["Spec"]},
          {i, Length[blocks]}],
        "FormDirectory" -> None, "Verbose" -> verbose];
      If[! AssociationQ[assembled] || assembled["Status"] =!= "OK" ||
          ! TrueQ[masterTransportCertificateOK[assembled]],
        Return[<|"Status" -> "ChartAssemblyFailed",
          "Assembly" -> assembled, "Chart" -> data,
          "PullBack" -> <|"System" -> pullback["Certificate"],
            "Forms" -> forms|>,
          "Family" -> Lookup[system, "Family", None],
          "Seconds" -> AbsoluteTime[] - start|>, Module]];
      Return[<|"Status" -> "ExactFamilyAssembly",
        "Family" -> Lookup[system, "Family", None],
        "Assembly" -> assembled, "Chart" -> data,
        "PullBack" -> <|"System" -> pullback["Certificate"],
          "Forms" -> forms|>,
        "SourceVariables" -> sourceVariables[[{1, 2}]],
        "ChartSeconds" -> AbsoluteTime[] - start|>, Module]];
    (* provisional, for the failure returns below; recomputed from the
       direction the trial actually took once the result is in *)
    notes = masterTransportChartNotes[data,
      If[MatchQ[basePoint, {{_, _} ..}], First[basePoint], basePoint], target,
      If[direction === Automatic, "First", direction]];

    result = TransportFamily[chartSystem,
      Sequence @@ FilterRules[
        {opts},
        Except["Blocks" | "BasePoint" | "Target" | "FormDirectory" |
          "Variables" | "Regulator" | "SourceVariables" | "ConicChartRoute" |
          "PathDirection" | "PathAnchor" | "CoefficientField" |
          "AssemblyOnly"]],
      "Variables" -> chartVariables, "Regulator" -> eps,
      "Blocks" -> Table[{blocks[[i]], resolved[[i]]["Spec"]}, {i, Length[blocks]}],
      "FormDirectory" -> None,
      "BasePoint" -> basePoint, "Target" -> target];

    If[! AssociationQ[result],
      Return[<|"Status" -> "ChartTransportFailed", "Result" -> result,
        "Chart" -> data, "ChartNotes" -> notes,
        "PullBack" -> <|"System" -> pullback["Certificate"], "Forms" -> forms|>,
        "Family" -> Lookup[system, "Family", None],
        "Seconds" -> AbsoluteTime[] - start|>, Module]];

    (* the direction the trial took, read off the result rather than
       assumed; a refused run keeps the provisional record and its own
       "PathTrials" says what was tried *)
    chosenBase = Lookup[Lookup[result, "Path", <||>], "Base", Missing[]];
    If[MatchQ[chosenBase, {_, _}],
      notes = masterTransportChartNotes[data, chosenBase, target,
        Which[
          chosenBase === directionPoint["First"], "First",
          chosenBase === directionPoint["Second"], "Second",
          StringQ[direction], direction,
          True, "Automatic"]]];

    Join[result, <|
      "Chart" -> data,
      "ChartNotes" -> notes,
      "PullBack" -> <|"System" -> pullback["Certificate"], "Forms" -> forms|>,
      "SourceVariables" -> sourceVariables[[{1, 2}]],
      "SourceSystem" -> <|"Family" -> Lookup[system, "Family", None]|>,
      "ChartSeconds" -> AbsoluteTime[] - start|>]
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
  (* one greppable line per closed-form sector, carrying the verdict and
     the mechanism separately so a watchdog can never read a route name
     as a proof *)
  If[KeyExistsQ[result, "Exact"] && AssociationQ[result["Exact"]],
    AppendTo[lines, StringJoin[
      "  exactness=", ToString[Lookup[result["Exact"], "Exactness", "?"]],
      " sectors=", ToString[Length[Lookup[result["Exact"], "Sectors", {}]]]]];
    Do[
      AppendTo[lines, StringJoin[
        "  sector block=", ToString[Lookup[record, "Block", "?"]],
        " rows=", ToString[Lookup[record, "Rows", "?"]],
        " exactness=", ToString[Lookup[record, "Exactness", "?"]],
        " route=", ToString[Lookup[record, "CheckRoute", "?"]],
        " block=", ToString[Lookup[record, "BlockExactness", "?"]],
        " path=", ToString[Lookup[record, "PathExactness", "?"]]]],
      {record, Lookup[result["Exact"], "Sectors", {}]}]];
  If[KeyExistsQ[result, "Checkable"],
    AppendTo[lines, StringJoin[
      "  checkable orders=", ToString[Lookup[result["Checkable"], "Checkable", {}]],
      " of ", ToString[Lookup[result["Checkable"], "Orders", {}]],
      " depth=", ToString[Lookup[result["Checkable"], "Depth", "?"]],
      " rule=", ToString[Lookup[result["Checkable"], "Rule", "?"]]]]];
  (* H3: a SKIPPED check is Missing["Skipped"], not a list.  Iterating a
     Missing here would print nothing at all, which reads exactly like
     "no check was needed"; it is said in words instead. *)
  If[KeyExistsQ[result, "DECheck"] && MissingQ[result["DECheck"]],
    AppendTo[lines, StringJoin["  DE check SKIPPED (\"DECheck\" -> None or \
no demanded order was checkable); this run makes NO per-order statement \
against the original differential equation"]]];
  If[KeyExistsQ[result, "DECheck"] && ListQ[result["DECheck"]] &&
      result["DECheck"] =!= {},
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
