
(* ==== moved from Private/MasterTransport.wl on 2026-09-02 (overhaul goal 1) ====
   Evidence: Libra path-ordered transport engines (Monolithic/Blockwise), replaced by the observable transport (user decision U1, 2026-09-02); TransportFamilyInChart keeps its assembly mode and answers RouteRetired for transport
   Symbols: TransportFamily
   This file is never loaded by FeynFacet.m. *)


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
     (FeynFacet/Private/Transport/BlockwiseTransport.wl), which is the same
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
    compiledCandidate, compiledIdentityQ, compiledValuation,
    materializedCompiled,
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
          "KMin" -> kminPerBlock|>, regulator, engine === "Blockwise"],
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
    (* When no independent Phi cross-check was requested, try the compiled
       epsilon-form core first.  It keeps boundary data as sparse columns
       and words as interned IDs, materializing symbols only once at the
       output boundary.  A genuinely non-dlog coupling falls back by name
       to the mature integration-by-parts engine; a failed compiled
       certificate never falls back and is therefore not masked. *)
    compiledIdentityQ = AllTrue[Range[nb],
      SameQ[assembly["Forms"][[#]]["T"],
          IdentityMatrix[Length[assembly["Ranges"][[#]]]]] &&
        SameQ[assembly["TInverse"][[#]],
          IdentityMatrix[Length[assembly["Ranges"][[#]]]]] &];
    compiledCandidate = If[OptionValue["PhiCrossCheck"] === False,
      masterTransportCanonicalWordSolve[assembly, ahat, budget,
        kminPerBlock, kmaxF, tau, regulator,
        "Verbose" -> verbose, "MaxWeight" -> maxWeight,
        "Certify" -> TrueQ[OptionValue["Verify"]],
        "Materialize" -> ! compiledIdentityQ,
        "ConstantDepth" -> OptionValue["ConstantDepth"],
        "ExactDepth" -> exactDepth],
      None];
    blockwise = If[AssociationQ[compiledCandidate] &&
        Lookup[compiledCandidate, "Status", None] =!=
          "CompiledWordFallbackRequired",
      compiledCandidate,
      masterTransportBlockwiseSolve[assembly, ahat, budget,
        kminPerBlock, kmaxF, n0, tau, regulator, variables, base, target,
        "Verbose" -> verbose, "Root" -> root, "MaxWeight" -> maxWeight,
        "Certify" -> TrueQ[OptionValue["Verify"]],
        "PhiCrossCheck" -> OptionValue["PhiCrossCheck"],
        "PhiCrossCheckMaxWeight" -> OptionValue["PhiCrossCheckMaxWeight"],
        "KeepMaps" -> TrueQ[OptionValue["KeepWordMaps"]],
        "ConstantDepth" -> OptionValue["ConstantDepth"],
        "ExactDepth" -> exactDepth]];
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
    If[Lookup[blockwise, "Route", None] === "CompiledSparseWord" &&
        TrueQ[compiledIdentityQ],
      {stageSeconds, compiledValuation} = AbsoluteTiming[
        masterTransportCWIdentityValuation[blockwise["IR"], n0]];
      If[Lookup[compiledValuation, "Status", None] =!= "OK",
        Return[Join[diagnostics,
          <|"Status" -> "ValuationFailed",
            "Valuation" -> KeyDrop[compiledValuation, "IR"],
            "Assembly" -> assembly,
            "Family" -> assembly["Family"]|>], Module]];
      materializedCompiled = masterTransportCWMaterializeIR[
        compiledValuation["IR"], tau, kmaxF];
      solution = Join[solution, materializedCompiled];
      valuation = Join[KeyDrop[compiledValuation, "IR"],
        <|"Solution" -> solution|>],
      {stageSeconds, valuation} = AbsoluteTiming[
        masterTransportValuation[assembly, solution, n0, base, target,
          tau, variables, regulator, verbose]]];
    masterTransportLog[verbose, "  physical Laurent valuation finished in ",
      Round[stageSeconds, 0.1], " s (", Lookup[valuation, "Route", "Legacy"],
      ")"];
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
        KeyDrop[blockwise, {"Solution", "IR"}], None],
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

(* ==== moved from Private/MasterTransport.wl on 2026-09-02 (overhaul goal 1) ====
   Evidence: path-ordered transport data structures and status printer of the retired TransportFamily route (user decision U1, 2026-09-02)
   Symbols: TransportQuadrature, TransportStatus, TransportWord
   This file is never loaded by FeynFacet.m. *)


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

(* the lower limit is a base point, so the quadrature vanishes there *)
TransportQuadrature[f_, t_, t_] := 0;

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

(* ==== moved from Private/Transport/MasterTransport.wl on 2026-09-02 (user decision U1) ====
   Derivative rules of the path-ordered word and quadrature heads. *)

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
