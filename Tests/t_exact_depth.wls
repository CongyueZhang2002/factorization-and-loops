#!/usr/bin/env wolframscript
(* The EXACT per-block transport-depth recursion (C4b).

   The module's shipped depth rule charges every block-DAG edge the cost
   max(0, 1 - ord_eps(coupling)) and sums along a path.  That is a proved
   UPPER bound on the transport weight and not the minimum: the exact
   contribution of a descending chain is |p| - sum_e ord_e, so a deficit
   edge (ord <= 0) and a slack edge (ord >= 2) on the SAME chain
   compensate and per-edge clamping throws the compensation away.  The
   2026-08-16 GPT-Pro review states the exact rule as a recursion on
   (block, epsilon order) -- its Eq. (4) -- and gives the decisive
   example: ord = -3 followed by ord = +3 along a chain costs 2 extra
   word lengths where the clamped rule charges 4.

   masterTransportExactDepth implements that recursion with the FULL
   Laurent support of every coupling (not its lowest order alone), and
   returns the Bellman potentials of the Fable-Max reply beside it.

   Acceptance criteria, stated before any of them is run.

   S. The Laurent-support primitive.
     S1  a coupling whose denominator is an epsilon MONOMIAL has a FINITE
         support, and it is returned exactly and completely;
     S2  a coupling that is rational in epsilon with a non-monomial
         denominator has an infinite support; the orders are returned
         exactly up to the cap and the truncation is REPORTED, never
         hidden;
     S3  an identically zero entry has order Infinity and empty support.

   E. The recursion on synthetic three-block DAGs (1x1 blocks, so the
      arithmetic is the whole content and nothing else can be blamed).
     E1  GPT-Pro's example, ord_21 = -3 then ord_32 = +3: the exact rule
         gives W_3 = 2 where the clamped rule gives 4, and the maxima
         over the DAG are 2 and 4;
     E2  the potentials for that DAG are pi = {0, 4, 4} and the clamped
         per-block numbers are {0, 1, 4} -- i.e. the test pins BOTH
         accountings, not just their difference;
     E3  a chain with NO slack edge (ord = -1 then ord = 0) has exact ==
         clamped, block by block: the sharper rule must not move a number
         it has no reason to move;
     E4  an isolated block (no couplings at all) has W = N - kmin under
         both rules;
     E5  the returned W table satisfies the DEFINING recursion itself,
         re-evaluated in this file from Eq. (4) against the returned
         support, for every (block, order) in the table;
     E6  a coupling carrying BOTH a deficit order and a slack order in
         the same block (1/eps^2 in one entry, eps^2 in another) is
         reported as a mixed edge and its full support is used -- the
         lowest order alone would give a different answer.

   R. One real case: the class-97 block (CF258 rows 18-21) standalone in
      its chart, reached with MaxWeight -> 0 so that nothing is
      transported.
     R1  the run returns the depth arithmetic (a single block, so there
         is no coupling and the two rules MUST agree), and the exact
         weight equals the clamped weight;
     R2  the exact record's per-block demand, kmin and lowest-carried
         order are the module's own kminPerBlock arithmetic.

   O. The option.
     O1  "DepthRule" -> "Clamped" is the default and reproduces the
         weight the module has always requested;
     O2  "DepthRule" -> "Exact" is accepted and both numbers are recorded;
     O3  any other value is refused BY NAME rather than silently
         defaulted. *)

root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], ".."}]];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

ftData = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical"}];
ftClassForms = FileNameJoin[{ftData, "ClassForms"}];
ftDE = FileNameJoin[{ftData, "DifferentialEquations"}];
ftHard = FileNameJoin[{ftData, "HardClasses", "EpsFormRoute"}];

vv = Symbol["Global`v"]; ww = Symbol["Global`w"];
xx = Symbol["Global`x"]; yy = Symbol["Global`y"];
ee = Symbol["Global`eps"];

(* Trap: a backend package on $ContextPath re-keys a later Get's bare
   eps, v, w, x, y to ITS context.  Every artifact is read through this. *)
normalizeSymbols[expr_] := expr /. (s_Symbol /;
    MemberQ[{"eps", "Eps", "epsilon", "Epsilon", "ep", "v", "w", "x", "y",
      "t", "tau", "sqrtLambda", "gli"}, SymbolName[s]] &&
    Context[s] =!= "Global`" :> Symbol["Global`" <> SymbolName[s]]);
normalizeRegulator[expr_] := expr /. s_Symbol /;
   MemberQ[{"eps", "Eps", "epsilon", "Epsilon", "ep"}, SymbolName[s]] :> ee;
readArtifact[file_String] := normalizeRegulator[normalizeSymbols[Get[file]]];

(* Print, not WriteString["stdout"]: a mission running on a kernel-pool
   subkernel has its Print output captured in the mission log, while a
   direct write to the stdout stream of the subkernel is lost. *)
log[a___] := Print["[t] ", StringJoin[ToString /@ {a}]];
secs[t_] := ToString[NumberForm[N[t], {8, 1}]] <> " s";

exactDepth = FeynFacet`Private`masterTransportExactDepth;
laurentSupport = FeynFacet`Private`masterTransportLaurentSupport;

(* ------------------------------------------------------------------ S *)

log["S: Laurent support primitive"];

sMonomial = laurentSupport[(3 + 2 ee^2)/(5 ee^3), 8, ee];
FTAssert["S1 an eps-monomial denominator gives a FINITE, complete support",
  AssociationQ[sMonomial] && sMonomial["Order"] === -3 &&
    sMonomial["Orders"] === {-3, -1} && TrueQ[sMonomial["Finite"]] &&
    sMonomial["Truncated"] === False];

sRational = laurentSupport[1/(ee (1 + ee)), 4, ee];
FTAssert["S2 a non-monomial denominator gives an infinite support: the \
orders are exact up to the cap and the truncation is REPORTED",
  AssociationQ[sRational] && sRational["Order"] === -1 &&
    sRational["Orders"] === Range[-1, 4] && sRational["Finite"] === False &&
    TrueQ[sRational["Truncated"]] && sRational["Cap"] === 4];

sGap = laurentSupport[(1 - ee^2)/(1 - ee), 5, ee];   (* = 1 + eps exactly *)
FTAssert["S2' an exact cancellation in a rational coupling is seen: \
(1-eps^2)/(1-eps) has support {0,1} and nothing above it",
  AssociationQ[sGap] && sGap["Orders"] === {0, 1}];

sZero = laurentSupport[0, 6, ee];
FTAssert["S3 an identically zero entry has order Infinity and empty support",
  AssociationQ[sZero] && sZero["Order"] === Infinity && sZero["Orders"] === {}];

(* ------------------------------------------------------------------ E *)

(* A synthetic assembly: three 1x1 blocks in dependency order, each an
   epsilon-form with T = 1.  Nothing but the DAG arithmetic is exercised. *)
toyAssembly[nb_Integer] := <|
  "Family" -> "TOY", "N" -> nb,
  "Blocks" -> Table[{i}, {i, nb}],
  "Ranges" -> Table[{i}, {i, nb}],
  "Forms" -> Table[<|"Type" -> "EpsForm"|>, {nb}],
  "TInverse" -> Table[{{1}}, {nb}]|>;

toyAhat[nb_Integer, couplings_List] := Module[{m},
  m = Table[If[i === j, ee, 0], {i, nb}, {j, nb}];
  Do[m[[c[[1]], c[[2]]]] = c[[3]], {c, couplings}];
  m];

(* E1/E2: GPT-Pro's chain.  Block 2 depends on block 1 through a
   1/eps^3 coupling; block 3 depends on block 2 through an eps^3
   coupling.  The demands are the SIGNED ones -- block 2 is only ever
   asked for what block 3 needs of it -- because that is the case in
   which per-edge clamping and per-chain accounting differ. *)
ahatGPT = toyAhat[3, {{2, 1, 1/ee^3}, {3, 2, ee^3}}];
gpt = exactDepth[toyAssembly[3], ahatGPT,
  <|"Demands" -> {0, -3, 0}, "KMin" -> {0, 0, 0}|>, ee];
log["E1 GPT chain: exact W = ", gpt["W"], " (max ", gpt["WMax"], "), clamped ",
  gpt["ClampedPerBlock"], " (max ", gpt["ClampedMax"], "), potentials ",
  gpt["Potentials"], ", lowest ", gpt["Lowest"]];

FTAssert["E1 GPT-Pro's example: ord -3 then ord +3 along a chain costs 2 \
exactly where the clamped rule charges 4, per block and in the maximum",
  AssociationQ[gpt] && gpt["Status"] === "OK" &&
    gpt["W"][[3]] === 2 && gpt["ClampedPerBlock"][[3]] === 4 &&
    gpt["WMax"] === 2 && gpt["ClampedMax"] === 4];

FTAssert["E2 both accountings are pinned, not only their difference: the \
Bellman potentials are {0,4,4} and the clamped per-block weights {0,1,4}",
  AssociationQ[gpt] && gpt["Potentials"] === {0, 4, 4} &&
    gpt["ClampedPerBlock"] === {0, 1, 4}];

FTAssert["E2' the couplings' eps-orders are read exactly and the slack \
edge is identified as such",
  AssociationQ[gpt] && gpt["Support"][{2, 1}] === {-3} &&
    gpt["Support"][{3, 2}] === {3} &&
    gpt["SlackEdges"] === {{3, 2}} && gpt["DeficitEdges"] === {{2, 1}}];

(* E3: no slack anywhere -- the two rules must agree block by block *)
ahatDeficit = toyAhat[3, {{2, 1, 1/ee}, {3, 2, 1}}];
deficit = exactDepth[toyAssembly[3], ahatDeficit,
  <|"Demands" -> {1, 1, 1}, "KMin" -> {0, 0, 0}|>, ee];
log["E3 deficit-only chain: exact ", deficit["W"], ", clamped ",
  deficit["ClampedPerBlock"]];
FTAssert["E3 a chain with no slack edge has exact == clamped block by \
block: the sharper rule does not move a number it has no reason to move",
  AssociationQ[deficit] && deficit["W"] === deficit["ClampedPerBlock"] &&
    deficit["WMax"] === deficit["ClampedMax"]];

(* E4: an isolated block *)
isolated = exactDepth[toyAssembly[1], toyAhat[1, {}],
  <|"Demands" -> {3}, "KMin" -> {-1}|>, ee];
FTAssert["E4 an isolated block needs exactly N - kmin under both rules",
  AssociationQ[isolated] && isolated["W"] === {4} &&
    isolated["ClampedPerBlock"] === {4} && isolated["Potentials"] === {0}];

(* E5: the returned table satisfies the DEFINING recursion.  This is
   re-evaluated here from Eq. (4) against the record's own support, so
   the test does not merely re-run the implementation. *)
recursionHolds[record_] := Module[{nb, kmin, low, w, ok, terms},
  nb = Length[record["Demands"]];
  kmin = record["KMin"]; low = record["Lowest"]; w = record["Table"];
  ok = True;
  KeyValueMap[
    Function[{key, value},
      Module[{i = key[[1]], n = key[[2]]},
        terms = {If[n >= kmin[[i]], 0, -Infinity]};
        If[n - 1 >= low[[i]],
          AppendTo[terms, 1 + Lookup[w, Key[{i, n - 1}], -Infinity]]];
        Do[
          If[KeyExistsQ[record["Support"], {i, j}],
            Do[
              If[n - r >= low[[j]],
                AppendTo[terms, 1 + Lookup[w, Key[{j, n - r}], -Infinity]]],
              {r, record["Support"][{i, j}]}]],
          {j, 1, i - 1}];
        If[Max[terms] =!= value, ok = False]]],
    w];
  ok];

FTAssert["E5 the returned W table satisfies Eq. (4) itself, re-evaluated \
in this file for every (block, order) it contains",
  AllTrue[{gpt, deficit, isolated}, recursionHolds]];

(* E6: one coupling BLOCK carrying two different Laurent orders.  The
   blocks are 2x2 here so that two entries of the same coupling can carry
   a deficit and a slack order at once. *)
mixedAssembly = <|
  "Family" -> "TOYMIX", "N" -> 4,
  "Blocks" -> {{1, 2}, {3, 4}}, "Ranges" -> {{1, 2}, {3, 4}},
  "Forms" -> Table[<|"Type" -> "EpsForm"|>, {2}],
  "TInverse" -> Table[IdentityMatrix[2], {2}]|>;
mixedAhat = {
  {ee, 0, 0, 0},
  {0, ee, 0, 0},
  {1/ee^2, 0, ee, 0},
  {0, ee^2, 0, ee}};
mixed = exactDepth[mixedAssembly, mixedAhat,
  <|"Demands" -> {0, 0}, "KMin" -> {0, 0}|>, ee];
log["E6 mixed edge: support ", mixed["Support"][{2, 1}], ", mixed edges ",
  mixed["MixedEdges"], ", exact ", mixed["W"], ", clamped ",
  mixed["ClampedPerBlock"]];
FTAssert["E6 a coupling block carrying BOTH a deficit and a slack order \
is reported as mixed and its FULL support is used",
  AssociationQ[mixed] && mixed["Support"][{2, 1}] === {-2, 2} &&
    mixed["MixedEdges"] === {{2, 1}}];

(* ------------------------------------------------------------------ R *)

log["R: the class-97 block standalone in its chart (MaxWeight -> 0, no transport)"];

chart97 = <|"Kind" -> "TwoVariable", "Variables" -> {xx, yy},
  "Subst" -> {vv -> xx yy, ww -> (1 - xx) (1 - yy)},
  "Root" -> xx - yy, "RootSquare" -> (1 - vv - ww)^2 - 4 vv ww|>;

classFormFile[cid_] := FileNameJoin[{ftClassForms, "class" <> ToString[cid] <> ".wl"}];
hardArtifact[cid_] := FileNameJoin[{ftHard,
  "c" <> ToString[cid] <> "_epsform_two_variable.wl"}];
hardRecord[cid_, repFamily_, repRows_] := Module[{raw},
  If[FileExistsQ[classFormFile[cid]], Return[readArtifact[classFormFile[cid]]]];
  raw = readArtifact[hardArtifact[cid]];
  <|"ClassID" -> cid, "RepFamily" -> repFamily, "RepRows" -> repRows,
    "Dim" -> Length[raw["T"]],
    "Transformation" -> raw["T"], "EpsForm" -> {raw["Ax"], raw["Ay"]},
    "Variables" -> {xx, yy},
    "Chart" -> <|"Kind" -> "TwoVariable",
      "Subst" -> {vv -> xx yy, ww -> (1 - xx) (1 - yy)},
      "Root" -> xx - yy, "RootSquare" -> (1 - vv - ww)^2 - 4 vv ww,
      "Variables" -> {xx, yy}|>,
    "AnsatzDegree" -> None, "Validated" -> True|>];

record97 = hardRecord[97, "CF258", {18, 19, 20, 21}];
cf258 = readArtifact[FileNameJoin[{ftDE, "nnlo_de_CF258.wl"}]];
hardRows97 = {18, 19, 20, 21};

{rSeconds, r97} = AbsoluteTiming[FeynFacet`TransportFamilyInChart[
  <|"Family" -> "CF258_B97", "Av" -> cf258["Av"][[hardRows97, hardRows97]],
    "Aw" -> cf258["Aw"][[hardRows97, hardRows97]]|>,
  chart97, "SourceVariables" -> {vv, ww}, "Regulator" -> ee,
  "Blocks" -> {{{1, 2, 3, 4}, record97}},
  "PhysicalValuation" -> 0, "Orders" -> {0, 1},
  "TransportBackend" -> "Libra", "MaxWeight" -> 0, "DepthReport" -> True,
  "Verbose" -> False]];
log["R status ", Lookup[r97, "Status", "?"], ", requested weight ",
  Lookup[r97, "Requested", Lookup[r97, "Weight", "?"]], "  ", secs[rSeconds]];

r97Exact = Lookup[r97, "ExactDepth", None];
If[AssociationQ[r97Exact],
  log["R exact depth: W = ", r97Exact["W"], ", clamped per block ",
    r97Exact["ClampedPerBlock"], ", demands ", r97Exact["Demands"],
    ", kmin ", r97Exact["KMin"], ", lowest ", r97Exact["Lowest"],
    ", couplings ", Length[Keys[r97Exact["Support"]]]]];

FTAssert["R1 the class-97 block standalone: a single block has no \
coupling, so the exact rule and the clamped rule MUST agree, and they do",
  AssociationQ[r97] && AssociationQ[r97Exact] &&
    r97Exact["Status"] === "OK" &&
    IntegerQ[r97Exact["WMax"]] &&
    r97Exact["WMax"] === Lookup[r97, "ClampedWeight", None] &&
    Keys[r97Exact["Support"]] === {}];

FTAssert["R2 the exact record's demand/kmin arithmetic is the module's \
own: W = demand - kmin for the single block, and kmin is KMinPerBlock",
  AssociationQ[r97Exact] &&
    r97Exact["W"] === {r97Exact["Demands"][[1]] - r97Exact["KMin"][[1]]} &&
    r97Exact["KMin"] === Lookup[r97, "KMinPerBlock", None] &&
    r97Exact["Lowest"] === r97Exact["KMin"]];

(* ------------------------------------------------------------------ O *)

optionExact = FeynFacet`TransportFamilyInChart[
  <|"Family" -> "CF258_B97", "Av" -> cf258["Av"][[hardRows97, hardRows97]],
    "Aw" -> cf258["Aw"][[hardRows97, hardRows97]]|>,
  chart97, "SourceVariables" -> {vv, ww}, "Regulator" -> ee,
  "Blocks" -> {{{1, 2, 3, 4}, record97}},
  "PhysicalValuation" -> 0, "Orders" -> {0, 1}, "DepthRule" -> "Exact",
  "TransportBackend" -> "Libra", "MaxWeight" -> 0, "Verbose" -> False];
log["O2 DepthRule -> Exact: status ", Lookup[optionExact, "Status", "?"],
  ", requested ", Lookup[optionExact, "Requested", "?"],
  ", clamped ", Lookup[optionExact, "ClampedWeight", "?"]];

FTAssert["O1 \"Clamped\" is the default and is what the record says it used",
  Lookup[r97, "DepthRule", None] === "Clamped" &&
    Lookup[r97, "Requested", None] === Lookup[r97, "ClampedWeight", None]];

FTAssert["O2 \"Exact\" is accepted, sets the requested weight from the \
recursion, and BOTH numbers are recorded",
  AssociationQ[optionExact] &&
    Lookup[optionExact, "DepthRule", None] === "Exact" &&
    IntegerQ[Lookup[optionExact, "ClampedWeight", None]] &&
    Lookup[optionExact, "Requested", None] ===
      optionExact["ExactDepth"]["WMax"]];

(* O4 is the pinned guard against the regression this option exists to
   avoid: the exact recursion needs the FULL Laurent support of every
   coupling, which is a Series per entry when an eps-denominator is not a
   monomial (MEASURED on CF230: 243 s against 56 s for all the rest of
   the pre-transport arithmetic).  A run that does not ask for the number
   must not pay for it. *)
defaultRun = FeynFacet`TransportFamilyInChart[
  <|"Family" -> "CF258_B97", "Av" -> cf258["Av"][[hardRows97, hardRows97]],
    "Aw" -> cf258["Aw"][[hardRows97, hardRows97]]|>,
  chart97, "SourceVariables" -> {vv, ww}, "Regulator" -> ee,
  "Blocks" -> {{{1, 2, 3, 4}, record97}},
  "PhysicalValuation" -> 0, "Orders" -> {0, 1},
  "TransportBackend" -> "Libra", "MaxWeight" -> 0, "Verbose" -> False];
log["O4 default run ExactDepth -> ", Lookup[defaultRun, "ExactDepth", "absent"]];

FTAssert["O4 with neither \"DepthRule\" -> \"Exact\" nor \"DepthReport\" -> \
True the exact recursion is NOT run -- it is an explicit Missing, never a \
silently absent key, and the clamped weight is still reported",
  AssociationQ[defaultRun] &&
    MissingQ[Lookup[defaultRun, "ExactDepth", None]] &&
    IntegerQ[Lookup[defaultRun, "ClampedWeight", None]] &&
    Lookup[defaultRun, "Requested", None] ===
      Lookup[defaultRun, "ClampedWeight", None]];

badRule = FeynFacet`TransportFamilyInChart[
  <|"Family" -> "CF258_B97", "Av" -> cf258["Av"][[hardRows97, hardRows97]],
    "Aw" -> cf258["Aw"][[hardRows97, hardRows97]]|>,
  chart97, "SourceVariables" -> {vv, ww}, "Regulator" -> ee,
  "Blocks" -> {{{1, 2, 3, 4}, record97}},
  "PhysicalValuation" -> 0, "Orders" -> {0, 1}, "DepthRule" -> "Cheapest",
  "TransportBackend" -> "Libra", "MaxWeight" -> 0, "Verbose" -> False];
log["O3 bad DepthRule -> ", If[AssociationQ[badRule],
  Lookup[badRule, "Status", "?"], ToString[badRule]]];

FTAssert["O3 an unknown DepthRule is REFUSED (MasterTransport::option, \
fail-closed), never silently defaulted to one of the two rules",
  AssociationQ[badRule] &&
    Lookup[badRule, "Status", None] === "ChartTransportFailed" &&
    Lookup[badRule, "Result", None] === $Failed];

(* ------------------------------------------------------------------ X *)

(* X. The completeness assertion, restated PER BLOCK (H1, 2026-08-17).

   masterTransportRegrade used to decide completeness with the GLOBAL
   CLAMPED shift alone, predicted = wmax + 1 - D > j1.  With
   "DepthRule" -> "Exact" the requested weight is max_i W_i(need_i),
   which is <= jmax + D and usually strictly smaller, so that inequality
   fails and the run was refused with RegradingIncomplete even though
   every block had all the weight it needs.  That is precisely why
   "Exact" was usable only where it equalled the clamped weight.

   W_i(n) is monotone in n, so wmax >= W_i(need_i) certifies block i at
   every order <= need_i; the window is complete when that holds for
   every block.  It is tested here directly on masterTransportRegrade,
   with a synthetic transport, because that isolates the arithmetic from
   any family's cost -- and the negative controls are what make it a
   statement rather than a switch.

     X1  the exact rule's weight passes the per-block route where the
         clamped statement fails, and the route taken is reported;
     X2  a weight that is genuinely too small for one block is still
         REFUSED -- the fix must not turn the gate off;
     X3  a truncated Laurent support makes W a LOWER bound, and a lower
         bound cannot certify: the per-block verdict is Missing, not
         True, and completeness falls back to the clamped route;
     X4  with no exact record the behaviour is exactly the old one. *)

regrade = FeynFacet`Private`masterTransportRegrade;

(* three weights of a 1x1 synthetic transport: 1, eps, eps^2 *)
toyU = {{{1}}, {{ee}}, {{ee^2}}};

toyExact[w_List, truncated_ : False] := <|
  "Status" -> "OK", "W" -> w, "Demands" -> ConstantArray[2, Length[w]],
  "SupportTruncated" -> <|{2, 1} -> truncated|>|>;

Module[{perBlock, tooSmall, truncated, noExact},
  perBlock = regrade[toyU, {-4, 2}, 4, ee, toyExact[{0, 1, 2}]];
  tooSmall = regrade[toyU, {-4, 2}, 4, ee, toyExact[{0, 1, 5}]];
  truncated = regrade[toyU, {-4, 2}, 4, ee, toyExact[{0, 1, 2}, True]];
  noExact = regrade[toyU, {-4, 2}, 4, ee];
  log["X1 per-block route: complete ", perBlock["Complete"], " via ",
    perBlock["CompleteRoute"], " verdicts ", perBlock["PerBlockComplete"],
    "  (clamped statement ", perBlock["ClampedComplete"], ")"];
  log["X2 one block short: complete ", tooSmall["Complete"], " via ",
    tooSmall["CompleteRoute"], " verdicts ", tooSmall["PerBlockComplete"]];
  log["X3 truncated support: complete ", truncated["Complete"], " verdicts ",
    truncated["PerBlockComplete"]];

  FTAssert["X1 the exact rule's weight is certified PER BLOCK where the \
global clamped statement fails, and the route taken is reported",
    AssociationQ[perBlock] && perBlock["ClampedComplete"] === False &&
      TrueQ[perBlock["Complete"]] &&
      perBlock["CompleteRoute"] === "ExactPerBlock" &&
      perBlock["PerBlockComplete"] === {True, True, True} &&
      perBlock["PerBlockWeightNeeded"] === {0, 1, 2}];
  FTAssert["X2 a weight genuinely too small for one block is still REFUSED: \
the per-block restatement is a statement, not a switch",
    AssociationQ[tooSmall] && tooSmall["Complete"] === False &&
      tooSmall["CompleteRoute"] === "None" &&
      tooSmall["PerBlockComplete"] === {True, True, False}];
  FTAssert["X3 a TRUNCATED Laurent support makes W a lower bound, which \
cannot certify: the verdict is Missing, never True",
    AssociationQ[truncated] && MissingQ[truncated["PerBlockComplete"]] &&
      truncated["Complete"] === False];
  FTAssert["X4 with no exact record the old behaviour is exact: completeness \
is the clamped statement and the per-block verdict is Missing",
    AssociationQ[noExact] &&
      noExact["Complete"] === noExact["ClampedComplete"] &&
      MissingQ[noExact["PerBlockComplete"]]];
  FTAssert["X5 the clamped route still decides on its own when it holds, and \
is reported as the route taken",
    Module[{wide = regrade[toyU, {-4, 0}, 1, ee, toyExact[{0, 1, 2}]]},
      TrueQ[wide["Complete"]] && wide["CompleteRoute"] === "ClampedGlobalShift" &&
        TrueQ[wide["ClampedComplete"]]]]];

(* X6: why the monolithic completeness statement is not needed on the
   BLOCK-WISE path, and what is recorded there instead.

   That engine's recursion is graded in epsilon by construction, so there
   is no weight-to-epsilon regrading to complete and
   masterTransportRegrade is correctly never called.  Its completeness
   statement is the SCHEDULE (each block's window, with top_j >= top_i -
   rmin_ij, so every source is solved to the order it is read at) plus
   the recursion certificate.

   The exact rule's numbers are recorded beside that as a DIAGNOSTIC and
   are NOT a gate.  They are a different quantity: the schedule weight is
   the window top_i - low_i, while W_i(N_i) is the CHAIN weight the
   recursion reaches through the higher orders of lower blocks that
   negative-epsilon-order couplings read, so window < W_i is normal
   (measured 2026-08-17 on CF262: windows <= 3 against chain weight 4,
   every certificate exact).  An earlier version of this branch REFUSED
   on that comparison and was wrong.

   What is pinned here is therefore the RECORD and the run, not the
   verdict: the branch is exercised end to end on the class-97 block in
   its chart with the exact recursion switched on, it reports the route
   and BOTH quantities so the difference can be read off a run, and it
   does not refuse. *)
Module[{bw, regraded},
  bw = FeynFacet`TransportFamilyInChart[
    <|"Family" -> "CF258_B97", "Av" -> cf258["Av"][[hardRows97, hardRows97]],
      "Aw" -> cf258["Aw"][[hardRows97, hardRows97]]|>,
    chart97, "SourceVariables" -> {vv, ww}, "Regulator" -> ee,
    "Blocks" -> {{{1, 2, 3, 4}, record97}},
    "PhysicalValuation" -> 0, "Orders" -> {0, 1}, "Engine" -> "Blockwise",
    "DepthRule" -> "Exact", "DepthReport" -> True,
    "TransportBackend" -> "Libra", "MaxWeight" -> 10, "Verbose" -> False];
  regraded = Lookup[bw, "Regrading", <||>];
  log["X6 blockwise status ", Lookup[bw, "Status", "?"],
    "  route ", Lookup[regraded, "CompleteRoute", "-"],
    "  scheduleW ", Lookup[regraded, "PerBlockScheduleWeight", "-"],
    "  neededW ", Lookup[regraded, "PerBlockWeightNeeded", "-"],
    "  verdicts ", Lookup[regraded, "PerBlockComplete", "-"],
    "  consistent ", Lookup[regraded, "ExactDepthConsistent", "-"]];
  FTAssert["X6 the block-wise branch records the exact rule's chain \
weights beside its own schedule weights as a DIAGNOSTIC -- both present, \
neither a gate -- and does not refuse",
    AssociationQ[bw] &&
      (* the recursion certificate itself is t_blockwise_transport's
         subject; what is pinned here is that the branch reached its
         record, reported both quantities, and did NOT turn the
         comparison into a refusal *)
      MemberQ[{"OK", "SolvedNotCheckable", "CheckInconclusive"},
        Lookup[bw, "Status", None]] &&
      Lookup[bw, "Status", None] =!= "RegradingIncomplete" &&
      AssociationQ[regraded] &&
      regraded["CompleteRoute"] === "BlockwiseRecursion" &&
      TrueQ[regraded["Complete"]] &&
      ListQ[Lookup[regraded, "PerBlockScheduleWeight", None]] &&
      ListQ[Lookup[regraded, "PerBlockWeightNeeded", None]] &&
      ListQ[Lookup[regraded, "PerBlockComplete", None]] &&
      Length[regraded["PerBlockComplete"]] ===
        Length[regraded["PerBlockScheduleWeight"]] &&
      BooleanQ[regraded["ExactDepthConsistent"]]]];

FTReport[];
