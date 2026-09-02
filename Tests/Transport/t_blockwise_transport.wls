#!/usr/bin/env wolframscript
(* Stage 2, block-wise transport engine
   (FeynFacet/Private/Transport/BlockwiseTransport.wl, reached as
   TransportFamily[..., "Engine" -> "Blockwise"]).

   Acceptance criteria, stated before any of them is run.

   A. Plumbing.  The engine is an OPTION of the existing entry point, not
      a second entry point: "Engine" -> "Blockwise" is accepted, an
      unknown engine is refused BY NAME, and the default is unchanged.

   W. The word algebra, on data small enough to check by hand.
      W1  a pure-dlog entry is decomposed into simple poles with tau-free
          residues, and the decomposition is an EXACT identity;
      W2  a double pole is refused BY NAME ("HigherPoleInTau") -- the
          word-append integration is not valid for it, and the engine
          must say so rather than integrate it wrongly;
      W3  a polynomial part in tau is refused BY NAME
          ("NotPureDlogInTau"), caught by the same exact reconstruction;
      W4  integration is a word APPEND: Int_0^tau dlog(s-a) G(w;s) =
          G(a,w;tau), and differentiating the result returns the
          integrand -- the fundamental theorem, on the representation;
      W5  the derivative of a word MAP agrees with the derivative of the
          same object written as an expression in TransportWord, i.e.
          the map layer and the module's own derivative rule are the
          same operator (this is what makes the certificate meaningful);
      W6  letters that are equal as rational functions but written
          differently are IDENTIFIED to one letter, and a letter sitting
          at the base point is refused -- the two hypotheses under the
          coefficient-wise zero test;
      W7  a connection with a DOUBLE POLE on the path is integrated
          exactly by parts rather than appended as if it were a dlog,
          and the engine records that it had to;
      W8  and it gets the right answer: for a connection whose exact
          solution is elementary, the returned eps^1 coefficient equals
          the closed form computed by hand.

   X. Path-dependent word coefficients (Codex review 2026-08-16, item 1).
      The representation deliberately allows F = sum_w c_w(tau) G(w;tau),
      because higher-pole integration by parts PRODUCES rational
      c_w(tau).  A dlog step that consumes such a coefficient may not
      append its letter and leave c_w outside the integral: in general
      Int_0^tau c(s)/(s-a) G(w;s) ds != c(tau) G(a,w;tau), and the
      difference is exactly the term with c'.  The three cases below are
      Codex's, and none of the existing tests reaches them (W7 has a
      constant coefficient, NLO and CF3 are pure dlog, CF230 never
      reached its certificate).
      X1  a dlog kernel acting on <|{} -> tau|> must give
          tau + a G(a;tau), never tau G(a;tau);
      X2  a double-pole integration followed by a dlog integration;
      X3  two general rational couplings in succession.
      X2 and X3 are checked by the two conditions that characterize a
      primitive exactly and avoid every branch-cut question: the result
      VANISHES at the base point, and its derivative (taken with the
      module's own TransportWord rule) IS the integrand.

   S. The S1 structure measurement, as repository evidence, and it is
      NOT what the reviews assumed.  The word-append integration is
      licensed only if every epsilon-Laurent coefficient of every
      coupling is pure dlog in the path parameter with tau-free
      residues; both 2026-08-16 reviews assume that.
      Scripts/Diagnostics/blockwise_structure.wls MEASURED it on CF230 in the chart
      and the answer is False: 13 of the 18 nonzero block pairs are pure
      dlog, and the five couplings FROM block 6 (class 49) into the
      blocks below it carry poles in tau of order up to 3 plus a
      polynomial part -- and those higher poles are already there before
      the regulator is expanded (multiplicities {1,2,3} exactly in eps
      for the (6,3) coupling), so they are structural and not an
      artifact of the expansion order.  The
      assertions below pin the measured structure, because it is what
      decides which integrator the engine must run.

   N. Anchor 1 (S3): the NLO 7x7 family.  The block-wise solution must
      equal the monolithic TransportFamily solution EXACTLY, entrywise
      and order by order, in the same word representation, with the same
      symbolic constants; the recursion certificate must be an exact
      zero for every block and every order; and the per-order check
      against the ORIGINAL family differential equation must still pass.

   C. Anchor 2 (S3): CF3, the tier-3 family whose conjugated connection
      keeps a 1/eps off-diagonal coupling.  Same criteria.  This is the
      case that exercises the part of the schedule a monolithic engine
      hides: a coupling of NEGATIVE epsilon order makes F_i at order n
      read F_j at the HIGHER order n+1 of a LOWER block, so the block
      order and the epsilon order cannot be traversed in the same
      direction.

   T. The target (S4): CF230 in the two-variable chart, block-wise, at
      Orders {0,1} -- the family whose monolithic Pexp exceeded the
      1800 s budget.  Heavy; opt-in via FT_BLOCKWISE_HEAVY=1, following
      the FT_CHART_HEAVY precedent in t_chart_transport.wls.

   Every item prints its measured wall time. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

ftData = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical"}];
ftClassForms = FileNameJoin[{ftData, "ClassForms"}];
ftBlockClasses = FileNameJoin[{ftData, "BlockClasses"}];
ftDE = FileNameJoin[{ftData, "DifferentialEquations"}];
ftHard = FileNameJoin[{ftData, "HardClasses", "EpsFormRoute"}];

Scan[
  If[! DirectoryQ[#], Print["FAIL  missing repository input: ", #]; Exit[1]] &,
  {ftClassForms, ftBlockClasses, ftDE, ftHard}];

(* Named explicitly: a backend package joins $ContextPath as soon as it
   loads, and PolyLogTools exports v, w, x, y, t, G and II. *)
(* Pool subkernels keep state between missions.  A mission that left an
   OWN VALUE on Global`tau (the "tau = Symbol[\"Global`tau\"]" trap) would
   make every later transport here fail with
   MasterTransport::pathparameter, which is the module refusing correctly
   for a reason that has nothing to do with this run. *)
Quiet[Clear["Global`tau"]];

vv = Symbol["Global`v"]; ww = Symbol["Global`w"];
xx = Symbol["Global`x"]; yy = Symbol["Global`y"];
ee = Symbol["Global`eps"];
tauSymbol = Symbol["Global`tau"];

If[! (StringQ[ftClassForms] && StringQ[ftDE]),
  Print["FAIL  data paths did not assign (symbol collision)"]; Exit[1]];

heavyFlag = Environment["FT_BLOCKWISE_HEAVY"];
heavy = StringQ[heavyFlag] &&
  MemberQ[{"1", "true", "TRUE", "yes", "on"}, heavyFlag];

log[a___] := Print["[t] ", StringJoin[ToString /@ {a}]];
secs[t_] := ToString[NumberForm[t, {6, 2}]] <> " s";

normalizeRegulator[expr_] := expr /. s_Symbol /;
   MemberQ[{"eps", "Eps", "epsilon", "Epsilon", "ep"}, SymbolName[s]] :> ee;
normalizeSymbols[expr_] := expr /. (s_Symbol /;
   MemberQ[{"eps", "Eps", "epsilon", "Epsilon", "ep", "v", "w", "x", "y",
     "t", "tau", "sqrtLambda", "gli"}, SymbolName[s]] &&
   Context[s] =!= "Global`" :> Symbol["Global`" <> SymbolName[s]]);
readArtifact[file_String] := normalizeRegulator[normalizeSymbols[Get[file]]];

statusOf[r_] := If[AssociationQ[r], Lookup[r, "Status", None], $Failed];
resultQ[r_] := AssociationQ[r] && StringQ[Lookup[r, "Status", None]];
zeroOrder[record_] := AssociationQ[record] && record["Zero"] === {True};
zeroQ[e_] := TrueQ[FeynFacet`Private`masterTransportZeroQ[e]];

(* ------------------------------------------------------------------ A *)

FTAssert["A1 the engine is an option of the existing entry point, and \
\"Blockwise\" is a legal value of it",
  MemberQ[Keys[Association[Options[FeynFacet`TransportFamily]]], "Engine"] &&
    Lookup[Association[Options[FeynFacet`TransportFamily]], "Engine"] === Automatic];

FTAssert["A2 the chart entry point forwards the engine option, so a \
chart family can be solved block-wise without a second entry point",
  MemberQ[Keys[Association[Options[FeynFacet`TransportFamilyInChart]]], "Engine"]];

FTAssert["A3 the usage message documents the engine option",
  StringContainsQ[FeynFacet`TransportFamily::usage, "Blockwise"]];

engineRefusal = Quiet[FeynFacet`TransportFamily[
  <|"Family" -> "engine-refusal", "Av" -> {{ee/vv}}, "Aw" -> {{0}}|>,
  "Variables" -> {vv, ww}, "Regulator" -> ee,
  "Blocks" -> {{{1}, <|"Type" -> "EpsForm", "T" -> {{1}}|>}},
  "BasePoint" -> {1/4, 1/4}, "Orders" -> {0, 1}, "PhysicalValuation" -> 0,
  "Engine" -> "NoSuchEngine"]];
FTAssert["A4 an unknown engine is REFUSED rather than silently defaulted",
  engineRefusal === $Failed];

(* ------------------------------------------------------------------ W *)

w1 = FeynFacet`Private`masterTransportBWDlogEntry[yy/(tauSymbol - (1 - yy)) + 3/(tauSymbol - 2),
  tauSymbol];
FTAssert["W1 a pure-dlog entry decomposes into simple poles with tau-free \
residues, and the decomposition is an exact identity",
  AssociationQ[w1] && w1["Status"] === "OK" &&
    Length[w1["Poles"]] === 2 &&
    TrueQ[Together[Lookup[w1["Poles"], Key[Together[1 - yy]], $Failed] - yy] === 0] &&
    TrueQ[Together[Lookup[w1["Poles"], Key[2], $Failed] - 3] === 0] &&
    FreeQ[Values[w1["Poles"]], tauSymbol]];

w2 = FeynFacet`Private`masterTransportBWDlogEntry[1/(tauSymbol - yy)^2, tauSymbol];
FTAssert["W2 a double pole in the path parameter is refused BY NAME \
(HigherPoleInTau), never integrated as if it were a dlog",
  AssociationQ[w2] && w2["Status"] === "HigherPoleInTau"];

w3 = FeynFacet`Private`masterTransportBWDlogEntry[tauSymbol/(tauSymbol - yy), tauSymbol];
FTAssert["W3 a polynomial part in the path parameter is refused BY NAME \
(NotPureDlogInTau), caught by the exact reconstruction rather than by a \
shape check",
  AssociationQ[w3] && w3["Status"] === "NotPureDlogInTau"];

w4rep = <|(1 - yy) -> {{1}}|>;
w4vec = {<|{yy} -> 1|>};
w4 = FeynFacet`Private`masterTransportBWIntegrate[w4rep, w4vec, 1, tauSymbol];
w4back = FeynFacet`Private`masterTransportBWDerivative[First[w4], tauSymbol];
w4integrand = FeynFacet`Private`masterTransportBWApply[w4rep, w4vec, 1, tauSymbol];
FTAssert["W4 integration is exactly one word APPEND, and differentiating \
the result returns the integrand (the fundamental theorem, on the \
representation)",
  Keys[First[w4]] === {{1 - yy, yy}} &&
    TrueQ[Together[Values[First[w4]][[1]] - 1] === 0] &&
    Keys[w4back] === Keys[First[w4integrand]] &&
    AllTrue[Keys[w4back],
      TrueQ[Together[w4back[#] - First[w4integrand][#]] === 0] &]];

w5map = <|{yy, 1 - yy} -> 1/(1 + yy), {} -> yy|>;
w5expression = FeynFacet`Private`masterTransportBWToExpression[w5map, tauSymbol];
w5direct = D[w5expression, tauSymbol];
w5viaMap = FeynFacet`Private`masterTransportBWToExpression[
  FeynFacet`Private`masterTransportBWDerivative[w5map, tauSymbol], tauSymbol];
FTAssert["W5 the word-map derivative IS the module's own TransportWord \
derivative rule, not a second implementation of it",
  zeroQ[w5direct - w5viaMap]];

w6identified = FeynFacet`Private`masterTransportBWLetterCheck[{yy, yy^2/yy, 1 - yy}];
w6base = FeynFacet`Private`masterTransportBWLetterCheck[{yy, 0}];
FTAssert["W6 letters equal as rational functions are identified to one \
letter, and a letter at the base point (divergent iterated integrals) is \
refused",
  w6identified["Count"] === 2 && TrueQ[w6identified["Distinct"]] &&
    TrueQ[w6identified["NoneAtBasePoint"]] &&
    ! TrueQ[w6base["NoneAtBasePoint"]]];

(* W7/W8: end to end on a connection with a DOUBLE pole on the path.
   The monic gate passes (the distinct denominator factor is linear), so
   the pole order is the engine's own business -- and it is the case S1
   measured on the real target, so it must be integrated exactly rather
   than appended.  The system is small enough that the answer is known
   in closed form:

     Ahat = eps/(dv (tau - a)^2),  dv = v - 1/4,  a = 1/(4 dv),

   so F_0 = C_0 and
     F_1 = C_1 + C_0 (1/dv) ( -1/(tau - a) + 1/(-a) ). *)
{w7Seconds, w7} = AbsoluteTiming[FeynFacet`TransportFamily[
   <|"Family" -> "double-pole", "Av" -> {{ee/(vv - 1/2)^2}}, "Aw" -> {{0}}|>,
   "Variables" -> {vv, ww}, "Regulator" -> ee,
   "Blocks" -> {{{1}, <|"Type" -> "EpsForm", "T" -> {{1}}|>}},
   "BasePoint" -> {1/4, 1/4}, "Orders" -> {0, 1}, "PhysicalValuation" -> 0,
   "Engine" -> "Blockwise"]];
log["W7 status ", statusOf[w7], "  general integrator used ",
  Lookup[Lookup[Lookup[w7, "Blockwise", <||>], "GeneralIntegrator", <||>],
    "Used", "?"], "  ", secs[w7Seconds]];
FTAssert["W7 a double pole on the path is integrated EXACTLY BY PARTS, \
not appended as a dlog, and the engine records that it had to",
  resultQ[w7] && MemberQ[{"OK", "SolvedNotCheckable"}, statusOf[w7]] &&
    AssociationQ[Lookup[w7, "Blockwise", None]] &&
    TrueQ[w7["Blockwise"]["GeneralIntegrator"]["Used"]] &&
    TrueQ[w7["Blockwise"]["Certificate"]["AllZero"]]];

w8Expected = Module[{dv = vv - 1/4, a, q},
  a = 1/(4 dv); q = 1/dv;
  FeynFacet`TransportConstant[1, 1, 1] +
    FeynFacet`TransportConstant[1, 0, 1] q (-1/(tauSymbol - a) + 1/(-a))];
FTAssert["W8 the integrated-by-parts answer is the closed form computed \
by hand for this connection, exactly",
  resultQ[w7] && KeyExistsQ[w7, "F"] && KeyExistsQ[w7["F"], 1] &&
    zeroQ[First[w7["F"][1]] - w8Expected]];

(* ------------------------------------------------------------------ X *)

(* A word map is the correct value of Int_0^tau f(s) ds exactly when it
   vanishes at the base point and its derivative is f.  Both are exact
   and neither needs a closed form, so no branch cut is ever crossed. *)
mapExpr[m_] := FeynFacet`Private`masterTransportBWToExpression[m, tauSymbol];
wordsToZero[e_] := e /. FeynFacet`TransportWord[_, _] :> 0;
integralOK[m_, integrand_] := Module[{expr, derivative, atBase},
  expr = mapExpr[m];
  derivative = D[expr, tauSymbol];
  atBase = Together[wordsToZero[expr] /. tauSymbol -> 0];
  zeroQ[derivative - integrand] && TrueQ[atBase === 0]];

xA = 1 - yy;   (* letters: nonzero at the base point tau = 0 *)
xB = 2 - yy;

x1 = FeynFacet`Private`masterTransportBWIntegrate[
  <|xA -> {{1}}|>, {<|{} -> tauSymbol|>}, 1, tauSymbol];
x1Expected = tauSymbol + xA FeynFacet`TransportWord[{xA}, tauSymbol];
log["X1 got      ", InputForm[mapExpr[First[x1]]]];
log["X1 expected ", InputForm[x1Expected]];
FTAssert["X1 a dlog kernel consuming a tau-DEPENDENT coefficient gives Int_0^tau s/(s-a) ds = tau + a G(a;tau), not the append rule's tau G(a;tau)",
  zeroQ[mapExpr[First[x1]] - x1Expected]];

x2Step1 = FeynFacet`Private`masterTransportBWIntegrateGeneral[
  {{1/(tauSymbol - xB)^2}}, {<|{} -> 1|>}, 1, tauSymbol];
FTAssert["X2a the double-pole integration itself is exact (vanishes at the base point, differentiates back to its integrand)",
  integralOK[First[x2Step1], 1/(tauSymbol - xB)^2]];

x2Step2 = FeynFacet`Private`masterTransportBWIntegrate[
  <|xA -> {{1}}|>, x2Step1, 1, tauSymbol];
FTAssert["X2b a dlog integration CONSUMING the rational coefficient that the double pole produced is exact -- the case the append rule gets wrong",
  integralOK[First[x2Step2],
    mapExpr[First[x2Step1]]/(tauSymbol - xA)]];

x3Step1 = FeynFacet`Private`masterTransportBWIntegrateGeneral[
  {{(tauSymbol + 1)/(tauSymbol - xB)^2}}, {<|{} -> 1|>}, 1, tauSymbol];
x3Step2 = FeynFacet`Private`masterTransportBWIntegrateGeneral[
  {{1/((tauSymbol - xA) (tauSymbol - xB))}}, x3Step1, 1, tauSymbol];
FTAssert["X3 two general rational couplings in succession are exact, so the general integrator also carries the derivative of the coefficient it inherits",
  integralOK[First[x3Step2],
    mapExpr[First[x3Step1]]/((tauSymbol - xA) (tauSymbol - xB))]];

(* ------------------------------------------------------------------ S *)

structureFile = FileNameJoin[{ftHard, "blockwise_structure_CF230.wl"}];
structure = If[FileExistsQ[structureFile], readArtifact[structureFile], None];

FTAssert["S1 the measured structure record of CF230's chart couplings is \
in the repository (Scripts/Diagnostics/blockwise_structure.wls produced it)",
  AssociationQ[structure]];

If[AssociationQ[structure],
  log["S1 record: max pole order ", structure["MaxPoleOrderInTau"],
    ", polynomial parts ", structure["PolynomialPartDegrees"],
    ", letters ", structure["DistinctLetters"],
    ", pure dlog ", structure["PureDlogConstantResidues"]];
  (* The measured fact, stated as the acceptance criterion it is: the
     reviews' assumption is FALSE here, and pinning it is what keeps the
     engine honest -- if a later change made the couplings pure dlog
     (the off-diagonal cleanup -- a change of the CANONICAL bases mixing
     block 6 with its subsectors -- which is what removes these poles;
     NOT a per-class scalar gauge, which scales det T by c^dim and
     cannot strip a single power of one factor, and which anyway cannot
     touch Ahat, since the conjugated connection does not depend on the
     original basis) this assertion would fail and the structure record
     would have to be re-measured, which is the correct outcome. *)
  FTAssert["S2 MEASURED, and it falsifies the reviews' assumption: \
CF230's chart couplings are NOT all pure dlog in the path parameter -- \
the maximum pole order is 3 and a polynomial part occurs, so the \
word-append integration alone is not licensed for this family",
    ! TrueQ[structure["PureDlogConstantResidues"]] &&
      structure["MaxPoleOrderInTau"] === 3 &&
      structure["PolynomialPartDegrees"] =!= {}];
  FTAssert["S3 the letters are nevertheless eps-free and tau-free, so \
the word representation itself stands: only the integration step needs \
more than an append",
    TrueQ[structure["LettersEpsFree"]] &&
      TrueQ[structure["LettersTauFree"]] &&
      IntegerQ[structure["DistinctLetters"]]];
  FTAssert["S4 the structure was measured on an assembly whose five-part \
conjugation certificate holds and whose path denominators are linear",
    TrueQ[structure["AssemblyCertificateOK"]] &&
      TrueQ[structure["MonicLinear"]]],
  FTAssert["S2 MEASURED: CF230's chart coupling structure", False];
  FTAssert["S3 the letters are eps-free and tau-free", False];
  FTAssert["S4 the structure record carries its assembly certificate", False]];

(* ------------------------------------------------------------------ N *)

(* The comparison.  An order present in only one engine's window is
   compared against ZERO rather than skipped: an engine that does not
   produce an order must not thereby agree with one that does. *)
compareSeries[keyA_, a_, keyB_, b_, dimension_] := Module[{orders, records},
  orders = Union[keyA, keyB];
  records = Table[
    Module[{va, vb},
      va = If[MemberQ[keyA, k], a[k], ConstantArray[0, dimension]];
      vb = If[MemberQ[keyB, k], b[k], ConstantArray[0, dimension]];
      <|"Order" -> k, "Zero" -> DeleteDuplicates[
         FeynFacet`Private`masterTransportZeroQ /@ (va - vb)]|>],
    {k, orders}];
  <|"Orders" -> orders, "PerOrder" -> records,
    "AllZero" -> AllTrue[records, #["Zero"] === {True} &]|>];

nloRaw = Get[FileNameJoin[{root, "ppHX_NLO", "Results", "NLO_UU_Masters.wl"}]];
nloSystem = nloRaw["DifferentialSystem"];
nloAv = normalizeRegulator[nloSystem["Av"]];
nloAw = normalizeRegulator[nloSystem["Aw"]];
nloT = DiagonalMatrix[{1, (2 ee - 1)/(ee vv), (2 ee - 1)/(ee ww (vv + ww - 1)),
   (2 ee - 1)/(ee ww), (2 ee - 1)/(ee (vv + ww - 1)),
   (2 ee - 1)/(ee vv (vv + ww - 1)), (2 ee - 1)/(ee vv ww)}];
nloInput = <|"Family" -> "NLO", "Basis" -> nloSystem["Basis"],
  "Av" -> nloAv, "Aw" -> nloAw|>;
nloOptions = {"Variables" -> {vv, ww}, "Regulator" -> ee,
  "Blocks" -> Table[{{i}, <|"Type" -> "EpsForm", "T" -> {{nloT[[i, i]]}}|>},
    {i, 7}],
  "BasePoint" -> {1/4, 1/4}, "Orders" -> {-1, 2},
  "PhysicalValuation" -> -1, "TransportBackend" -> "Libra"};

{nMonoSeconds, nMono} = AbsoluteTiming[FeynFacet`TransportFamily[nloInput,
   Sequence @@ nloOptions, "Engine" -> "Monolithic"]];
{nBlockSeconds, nBlock} = AbsoluteTiming[FeynFacet`TransportFamily[nloInput,
   Sequence @@ nloOptions, "Engine" -> "Blockwise"]];
log["N monolithic ", statusOf[nMono], " ", secs[nMonoSeconds],
  " | blockwise ", statusOf[nBlock], " ", secs[nBlockSeconds]];

FTAssert["N1 the NLO family transports block-wise with a verified status \
and an exact per-order check against the ORIGINAL family differential \
equation",
  resultQ[nBlock] && statusOf[nBlock] === "OK" &&
    nBlock["DECheck"] =!= {} && AllTrue[nBlock["DECheck"], zeroOrder]];
FTAssert["N2 the monolithic engine is unchanged by the addition of the \
block-wise one (positive control)",
  resultQ[nMono] && statusOf[nMono] === "OK" &&
    nMono["DECheck"] =!= {} && AllTrue[nMono["DECheck"], zeroOrder]];

nCompare = If[resultQ[nMono] && resultQ[nBlock],
  compareSeries[Keys[nMono["F"]], nMono["F"], Keys[nBlock["F"]], nBlock["F"],
    nMono["N"]], <|"AllZero" -> False|>];
log["N3 F orders compared: ", Lookup[nCompare, "Orders", {}]];
FTAssert["N3 the block-wise NLO solution equals the monolithic one \
EXACTLY, entrywise and order by order, with the same symbolic constants",
  TrueQ[nCompare["AllZero"]]];

nICompare = If[resultQ[nMono] && resultQ[nBlock],
  Module[{oa, ob},
    oa = nMono["I"]["Orders"]; ob = nBlock["I"]["Orders"];
    compareSeries[oa,
      Association[Table[oa[[k]] -> nMono["I"]["I"][[k]], {k, Length[oa]}]],
      ob,
      Association[Table[ob[[k]] -> nBlock["I"]["I"][[k]], {k, Length[ob]}]],
      nMono["N"]]], <|"AllZero" -> False|>];
FTAssert["N4 the assembled NLO masters agree exactly between the two \
engines, order by order",
  TrueQ[nICompare["AllZero"]]];

FTAssert["N5 the block-wise recursion certificate is an exact zero for \
every block and every epsilon order, and it was actually performed",
  resultQ[nBlock] && AssociationQ[nBlock["Blockwise"]] &&
    TrueQ[nBlock["Blockwise"]["Certificate"]["Performed"]] &&
    TrueQ[nBlock["Blockwise"]["Certificate"]["AllZero"]] &&
    nBlock["Blockwise"]["Certificate"]["PerBlockOrder"] =!= {}];

FTAssert["N6 the homogeneous part of the recursion equals Libra's cached \
per-class Phi_i . C_i exactly (independent cross-check of the engine \
against the mature package)",
  resultQ[nBlock] && AssociationQ[nBlock["Blockwise"]] &&
    TrueQ[nBlock["Blockwise"]["Phi"]["AllZero"]] &&
    nBlock["Blockwise"]["Phi"]["CrossChecks"] =!= {}];

FTAssert["N7 the block-wise engine reports its cost per block and per \
order (word counts and Chen weights), which is what makes a heavy family \
schedulable",
  resultQ[nBlock] && AssociationQ[nBlock["Blockwise"]] &&
    nBlock["Blockwise"]["WordCounts"] =!= {} &&
    IntegerQ[nBlock["Blockwise"]["MaxWordCount"]] &&
    IntegerQ[nBlock["Blockwise"]["Weight"]]];

(* ------------------------------------------------------------------ C *)

cf3 = normalizeRegulator[Get[FileNameJoin[{ftDE, "nnlo_de_CF3.wl"}]]];
cf3Input = <|"Family" -> "CF3", "Basis" -> cf3["BlockBasis"],
  "Av" -> cf3["Av"], "Aw" -> cf3["Aw"]|>;
cf3Options = {"Variables" -> {vv, ww}, "Regulator" -> ee, "Blocks" -> Automatic,
  "BasePoint" -> {1/4, 1/4}, "PhysicalValuation" -> -1, "Orders" -> {-1, 3},
  "TransportBackend" -> "Libra", "MaxWeight" -> 12};

log["C (CF3) transporting with both engines -- the expensive default item"];
{cMonoSeconds, cMono} = AbsoluteTiming[FeynFacet`TransportFamily[cf3Input,
   Sequence @@ cf3Options, "Engine" -> "Monolithic"]];
{cBlockSeconds, cBlock} = AbsoluteTiming[FeynFacet`TransportFamily[cf3Input,
   Sequence @@ cf3Options, "Engine" -> "Blockwise"]];
log["C monolithic ", statusOf[cMono], " weight ", Lookup[cMono, "Weight", "?"],
  " ", secs[cMonoSeconds], " | blockwise ", statusOf[cBlock],
  " max Chen weight ", Lookup[cBlock, "Weight", "?"], " ", secs[cBlockSeconds]];

FTAssert["C1 CF3 transports block-wise with a verified status and an \
exact per-order check against the ORIGINAL family differential equation \
through eps^2",
  resultQ[cBlock] && statusOf[cBlock] === "OK" &&
    cBlock["DECheck"] =!= {} && AllTrue[cBlock["DECheck"], zeroOrder] &&
    Complement[Range[-1, 2], cBlock["DECheck"][[All, "Order"]]] === {}];

cCompare = If[resultQ[cMono] && resultQ[cBlock] &&
   KeyExistsQ[cMono, "F"] && KeyExistsQ[cBlock, "F"],
  compareSeries[Keys[cMono["F"]], cMono["F"], Keys[cBlock["F"]], cBlock["F"],
    cMono["N"]], <|"AllZero" -> False|>];
log["C2 F orders compared: ", Lookup[cCompare, "Orders", {}]];
FTAssert["C2 the block-wise CF3 solution equals the monolithic one \
EXACTLY, entrywise and order by order -- including the orders the 1/eps \
coupling generates below the constant window",
  TrueQ[cCompare["AllZero"]]];

FTAssert["C3 the block-wise recursion certificate is an exact zero for \
every block and every order of CF3, where the schedule has to read a \
HIGHER order of a LOWER block",
  resultQ[cBlock] && AssociationQ[cBlock["Blockwise"]] &&
    TrueQ[cBlock["Blockwise"]["Certificate"]["AllZero"]]];

FTAssert["C4 the block-wise engine needs no weight-to-epsilon regrading \
on CF3: it is graded in epsilon by construction",
  resultQ[cBlock] && StringQ[Lookup[cBlock["Regrading"], "Route", None]] &&
    StringContainsQ[cBlock["Regrading"]["Route"], "Blockwise"]];

log["C timing: monolithic ", secs[cMonoSeconds], ", blockwise ",
  secs[cBlockSeconds]];

(* ------------------------------------------------------------------ T *)

If[! heavy,
  log["T SKIPPED (CF230 in the chart, block-wise); set \
FT_BLOCKWISE_HEAVY=1 to run it"],
  Module[{assignments, familyBlocks, chart97, cf230, blocks, tSeconds, tResult},
   assignments = readArtifact[
     FileNameJoin[{ftBlockClasses, "block_class_assign.wl"}]];
   familyBlocks[f_] := Table[{a["Rows"], a["ClassID"]},
     {a, Select[assignments, #["Family"] === f &]}];
   chart97 = <|"Kind" -> "TwoVariable", "Variables" -> {xx, yy},
     "Subst" -> {vv -> xx yy, ww -> (1 - xx) (1 - yy)},
     "Root" -> xx - yy, "RootSquare" -> (1 - vv - ww)^2 - 4 vv ww|>;
   cf230 = readArtifact[FileNameJoin[{ftDE, "nnlo_de_CF230.wl"}]];
   blocks = familyBlocks["CF230"];
   log["T transporting the WHOLE of CF230 in the chart, block-wise"];
   {tSeconds, tResult} = AbsoluteTiming[FeynFacet`TransportFamilyInChart[
      <|"Family" -> "CF230", "Basis" -> Lookup[cf230, "BlockBasis", None],
        "Av" -> cf230["Av"], "Aw" -> cf230["Aw"]|>,
      chart97, "SourceVariables" -> {vv, ww}, "Regulator" -> ee,
      "Blocks" -> blocks, "FormDirectory" -> ftClassForms,
      "PhysicalValuation" -> 0, "Orders" -> {0, 1},
      "Engine" -> "Blockwise", "TransportBackend" -> "Libra",
      "MaxWeight" -> 14, "Verbose" -> True]];
   log["T status ", statusOf[tResult], "  ", secs[tSeconds]];
   If[resultQ[tResult], FeynFacet`TransportStatus[tResult]];
   FTAssert["T1 CF230 transports in the chart BLOCK-WISE with the \
five-part conjugation certificate and an exact recursion certificate for \
every block and every order",
     resultQ[tResult] &&
       MemberQ[{"OK", "SolvedNotCheckable", "CheckInconclusive"},
         statusOf[tResult]] &&
       TrueQ[FeynFacet`Private`masterTransportCertificateOK[tResult["Assembly"]]] &&
       AssociationQ[Lookup[tResult, "Blockwise", None]] &&
       TrueQ[tResult["Blockwise"]["Certificate"]["AllZero"]]];
   FTAssert["T2 the per-order check against the ORIGINAL family \
differential equation is an exact zero at every checkable order of CF230",
     resultQ[tResult] && tResult["DECheck"] =!= {} &&
       AllTrue[tResult["DECheck"], zeroOrder]]]];

FTReport[];
