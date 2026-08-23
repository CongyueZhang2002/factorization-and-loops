#!/usr/bin/env wolframscript
(* Stage 2 in a two-variable chart: TransportFamilyInChart.

   Classes 97 (CF258_B9) and 77 (CF230_B1) have no rational epsilon-form
   in (v,w) -- their form exists only in the chart v = x y,
   w = (1-x)(1-y), where sqrt(lambda) = x - y.  A family carrying such a
   block therefore cannot be transported in (v,w) at all.  The layer
   under test moves the WHOLE family into the chart -- the connection by
   the chain rule, every block's stored class form by composition with
   the chart's coordinate map -- and calls the EXISTING TransportFamily
   there.

   Acceptance criteria, stated before any of them is run.

   P. The chart layer itself.
      P1  the class-97 chart resolves and its Jacobian determinant
          d(v,w)/d(x,y) is EXACTLY x - y;
      P2  the chart's own rationalization statement is exact:
          RootSquare pulled back through Subst equals Root^2;
      P3  a chart substitution that is not rational is refused BY NAME;
      P4  a chart with a degenerate Jacobian is refused BY NAME;
      P5  the pullback of a flat two-by-two epsilon-form is the chain
          rule, entry by entry and exactly, and its flatness is
          certified exactly;
      P6  a system that is NOT flat is refused BY NAME rather than
          pulled back;
      P7  a class form whose stored EpsForm does not reproduce the
          re-derivation from the block system is REJECTED (the stored
          form is provenance, never evidence).

   T1. Control, on a family the suite already transports: the NLO 7x7
      epsilon-form system, transported (i) in (v,w) exactly as
      t_master_transport does it, and (ii) through TransportFamilyInChart
      with the class-97 chart.  Criteria:
      T1a the pulled-back system is flat -- exactly;
      T1b every pulled-back block form is re-derived from the pulled-back
          block system and is an epsilon-form -- exactly, for all seven;
      T1c both runs reach the SAME status, "OK", and both carry the
          five-part conjugation certificate;
      T1d the two conjugated connections are related by the chain rule
          EXACTLY: Apx == Apv d_x v + Apw d_x w and Apy == Apv d_y v +
          Apw d_y w, with the same block permutation.  This is what is
          compared instead of the two solutions themselves: the runs use
          different paths (see T1f), so their GPL words are different
          representations of the same flat connection and a direct word
          comparison would need shuffle identities.  What IS compared
          per run is the substantive statement -- each solution satisfies
          its OWN original family differential equation exactly, order by
          order (T1e);
      T1e both runs' per-order checks against the ORIGINAL family
          differential equation are exact symbolic zeros at every
          checkable order;
      T1f the reason the chart path is axis-aligned is MEASURED, not
          assumed: on a generic straight segment in (x,y) the pulled-back
          alphabet carries letters that are quadratic in the path
          parameter, and the run is refused with PathDenominatorsNotLinear.

   T2. The target: CF258 (24 masters, 12 blocks, hard blocks of class 97
      and class 77) in the class-97 chart.
      T2a the class-97 record's stored chart is exactly the target chart;
      T2b CF258's connection pulls back with an exact flatness
          certificate;
      T2c EVERY one of CF258's 12 block forms pulls back and re-verifies
          as an epsilon-form in the chart, exactly -- including the two
          single-conic-chart classes (49, 95), whose conic parameter is
          solved LINEARLY against the chart's rational root and then
          confirmed by the exact chart identity;
      T2d the class-97 block, transported standalone in the chart, has
          the five-part certificate and an exact per-order check against
          its original differential equation;
      T2e (heavy, opt-in) the whole of CF258 transports in the chart with
          the five-part certificate and exact per-order checks;
      T2f the SAME record handed to the plain (v,w) entry point is
          REFUSED by name (ClassFormTwoVariableChartNeedsChartTransport)
          rather than differentiated with respect to (v,w), i.e. used in
          the wrong frame.  A two-variable chart record carries a chart
          "Inverse", so the older guard would have let it through.

   T3. The same for CF230 (13 masters, 6 blocks, hard block of class 77).

   The heavy whole-family items (T2e, T3e) are opt-in via
   FT_CHART_HEAVY=1, following the FT_LEGACY_ROUTE precedent in
   t_master_transport.wls: they are the expensive end of the same
   statement, and the default run makes the complete, exactly certified
   part of it.  Every item prints its measured wall time. *)

root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], ".."}]];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

(* Every input is addressed relative to `root`; nothing here reads a
   temporary directory. *)
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
vv = Symbol["Global`v"]; ww = Symbol["Global`w"];
xx = Symbol["Global`x"]; yy = Symbol["Global`y"];
ee = Symbol["Global`eps"];
tauSymbol = Symbol["Global`tau"];

heavyFlag = Environment["FT_CHART_HEAVY"];
heavy = StringQ[heavyFlag] && MemberQ[{"1", "true", "TRUE", "yes", "on"}, heavyFlag];

normalizeRegulator[expr_] := expr /. s_Symbol /;
   MemberQ[{"eps", "Eps", "epsilon", "Epsilon", "ep"}, SymbolName[s]] :> ee;

(* Trap P2, and it is not hypothetical: t_hard_class_epsforms failed 6 of
   24 assertions from exactly this.  A backend package (Libra,
   PolyLogTools, CANONICA) joins $ContextPath as soon as it loads, and an
   artifact read AFTER that point acquires PACKAGE symbols for its bare
   v, w, x, y, t and eps.  Substitution rules written with Global`
   symbols then match nothing, and the resulting check is self-consistency
   on the wrong expression while reporting success.  Every artifact in
   this file is read through readArtifact, which re-keys by SymbolName. *)
normalizeSymbols[expr_] := expr /. (s_Symbol /;
    MemberQ[{"eps", "Eps", "epsilon", "Epsilon", "ep", "v", "w", "x", "y",
      "t", "tau", "sqrtLambda", "gli"}, SymbolName[s]] &&
    Context[s] =!= "Global`" :> Symbol["Global`" <> SymbolName[s]]);

readArtifact[file_String] := normalizeRegulator[normalizeSymbols[Get[file]]];

log[a___] := (WriteString["stdout", "[t] ", StringJoin[ToString /@ {a}], "\n"];
  Flush[OutputStream["stdout", 1]]);

statusOf[r_] := If[AssociationQ[r], Lookup[r, "Status", None], $Failed];
resultQ[r_] := AssociationQ[r] && StringQ[Lookup[r, "Status", None]];
zeroOrder[record_] := AssociationQ[record] && record["Zero"] === {True};
tog[m_] := Map[Together, m, {2}];
zeroM[m_] := AllTrue[Flatten[tog[m]], # === 0 &];
secs[t_] := ToString[NumberForm[N[t], {8, 1}]] <> " s";

(* the chart of classes 97 and 77 *)
chart97 = <|"Kind" -> "TwoVariable", "Variables" -> {xx, yy},
  "Subst" -> {vv -> xx yy, ww -> (1 - xx) (1 - yy)},
  "Root" -> xx - yy, "RootSquare" -> (1 - vv - ww)^2 - 4 vv ww|>;

(* ------------------------------------------------------------------ A *)

FTAssert["A1 TransportFamilyInChart is exported with a usage message",
  StringQ[FeynFacet`TransportFamilyInChart::usage]];

(* ------------------------------------------------------------------ P *)

chartData = FeynFacet`Private`masterTransportChartData[chart97, {vv, ww}];

FTAssert["P1 the 97 chart resolves and det d(v,w)/d(x,y) is EXACTLY x - y",
  AssociationQ[chartData] && chartData["Status"] === "OK" &&
    TrueQ[Together[chartData["JacobianDet"] - (xx - yy)] === 0]];

FTAssert["P2 the chart's rationalization is exact: RootSquare pulled back \
through Subst equals Root^2",
  AssociationQ[chartData] && TrueQ[chartData["RootSquareConsistent"]]];

FTAssert["P3 a non-rational chart substitution is refused by name (ChartNotRational)",
  FeynFacet`Private`masterTransportChartData[
    <|"Kind" -> "TwoVariable", "Variables" -> {xx, yy},
      "Subst" -> {vv -> Sqrt[xx], ww -> yy}|>, {vv, ww}]["Status"] ===
    "ChartNotRational"];

FTAssert["P4 a chart with a degenerate Jacobian is refused by name \
(ChartJacobianDegenerate)",
  FeynFacet`Private`masterTransportChartData[
    <|"Kind" -> "TwoVariable", "Variables" -> {xx, yy},
      "Subst" -> {vv -> xx, ww -> 2 xx}|>, {vv, ww}]["Status"] ===
    "ChartJacobianDegenerate"];

(* a flat 2x2 epsilon-form with commuting diagonal residues *)
r1 = {{1, 0}, {0, 2}}; r2 = {{3, 0}, {0, 4}};
toyAv = tog[ee r1/vv]; toyAw = tog[ee r2/ww];
toyPull = FeynFacet`Private`masterTransportPullBackSystem[
  <|"Family" -> "toy", "Av" -> toyAv, "Aw" -> toyAw|>, chart97,
  "SourceVariables" -> {vv, ww}];

FTAssert["P5 the pullback is the chain rule entry by entry and its flatness \
is certified exactly (eps R1/v, eps R2/w -> eps R1/x - eps R2/(1-x) in x)",
  AssociationQ[toyPull] && toyPull["Status"] === "OK" &&
    TrueQ[toyPull["Certificate"]["ChartFlat"]] &&
    TrueQ[toyPull["Certificate"]["SourceFlat"]] &&
    zeroM[toyPull["Ax"] - tog[ee r1/xx - ee r2/(1 - xx)]] &&
    zeroM[toyPull["Ay"] - tog[ee r1/yy - ee r2/(1 - yy)]]];

FTAssert["P6 a system that is not flat is refused by name (SourceSystemNotFlat)",
  FeynFacet`Private`masterTransportPullBackSystem[
    <|"Family" -> "notflat", "Av" -> tog[ee {{0, 1}, {0, 0}}/vv],
      "Aw" -> tog[ee {{0, 0}, {1, 0}}/ww]|>, chart97,
    "SourceVariables" -> {vv, ww}]["Status"] === "SourceSystemNotFlat"];

(* P7: the same toy block with a CORRUPTED stored EpsForm.  The
   re-derivation from the block system is the truth; the stored form is
   provenance, and a disagreement must be a rejection. *)
toyRecord = <|"Transformation" -> IdentityMatrix[2], "Variables" -> {vv, ww},
  "EpsForm" -> {toyAv, toyAw + tog[ee r2/ww^2]}|>;
FTAssert["P7 a class form whose stored EpsForm disagrees with the \
re-derivation from the block system is REJECTED (ClassFormStoredEpsFormMismatch)",
  FeynFacet`Private`masterTransportPullBackClassForm[toyRecord, chartData,
    "SourceVariables" -> {vv, ww}, "Regulator" -> ee,
    "BlockSystem" -> {toyPull["Ax"], toyPull["Ay"]}]["Status"] ===
    "ClassFormStoredEpsFormMismatch"];

FTAssert["P7b the same class form with its TRUE stored EpsForm is accepted \
and re-derived from the block system",
  Module[{ok = FeynFacet`Private`masterTransportPullBackClassForm[
      <|"Transformation" -> IdentityMatrix[2], "Variables" -> {vv, ww},
        "EpsForm" -> {toyAv, toyAw}|>, chartData,
      "SourceVariables" -> {vv, ww}, "Regulator" -> ee,
      "BlockSystem" -> {toyPull["Ax"], toyPull["Ay"]}]},
    AssociationQ[ok] && ok["Status"] === "OK" &&
      TrueQ[ok["Certificate"]["EpsFormReDerivedFromBlockSystem"]] &&
      TrueQ[ok["Certificate"]["StoredEpsFormPullbackMatches"]] &&
      ok["Frame"] === "Rational"]];

(* P8: a class MEMBER that differs from the representative by a basis
   PERMUTATION.

   Class equivalence is a basis permutation OPTIONALLY composed with
   v <-> w.  This route already TRIED the swap -- in this chart the
   involution (x,y) -> (1-x,1-y), measured on three real members at
   T2c'' below -- but not the permutation, so a permuted member was
   refused as ClassFormNotEpsFormInChart or ClassFormStoredEpsFormMismatch.

   No member of the stored 1119 needs a permutation (measured
   2026-08-17: 252 of the 1028 rational-frame members need the swap and
   none a permutation), so the member here is CONSTRUCTED, by relabelling
   the two basis elements of the class-6 representative -- which is
   exactly what "a member of class 6" means.  The block system it is
   verified against comes from masterTransportPullBackSystem, i.e. the
   chain rule applied to the stored RepAv/RepAw, and is then permuted;
   nothing about the answer is taken from the record.

   Criteria: the unpermuted member is accepted with the identity (the
   control that this class pulls back to this chart at all); the
   permuted one is accepted with Permutation {2,1}; the accepted
   transformation is the unpermuted one with its two rows and columns
   exchanged and is DIFFERENT from it, so the assertion cannot pass
   without the permutation having been applied; and both exact chart
   gates -- the epsilon-form re-derived from the block system, and the
   stored EpsForm pulled back and compared -- hold. *)

permClasses = readArtifact[FileNameJoin[{ftBlockClasses, "classes.wl"}]];
permClass = SelectFirst[permClasses, #["ClassID"] === 6 &, None];
permRecord = If[FileExistsQ[FileNameJoin[{ftClassForms, "class6.wl"}]],
  readArtifact[FileNameJoin[{ftClassForms, "class6.wl"}]], None];

If[! (AssociationQ[permClass] && permClass["Dim"] === 2 &&
      AssociationQ[permRecord] && Lookup[permRecord, "Chart", None] === None),
  log["class 6 is not the expected 2x2 rational class -- P8 NOT PERFORMABLE"];
  FTAssert["P8 a class member that differs from the representative by a basis \
PERMUTATION is recovered in the chart and re-verified exactly", False],
  Module[{pull, plain, permuted},
   pull = FeynFacet`Private`masterTransportPullBackSystem[
     <|"Family" -> "class6rep", "Av" -> permClass["RepAv"],
       "Aw" -> permClass["RepAw"]|>, chart97, "SourceVariables" -> {vv, ww}];
   plain = FeynFacet`Private`masterTransportPullBackClassForm[permRecord,
     chartData, "SourceVariables" -> {vv, ww}, "Regulator" -> ee,
     "ClassID" -> 6, "BlockSystem" -> {pull["Ax"], pull["Ay"]}];
   permuted = FeynFacet`Private`masterTransportPullBackClassForm[permRecord,
     chartData, "SourceVariables" -> {vv, ww}, "Regulator" -> ee,
     "ClassID" -> 6, "BlockSystem" ->
       {pull["Ax"][[{2, 1}, {2, 1}]], pull["Ay"][[{2, 1}, {2, 1}]]}];
   log["P8 class-6 representative in the chart: ", statusOf[plain],
     " permutation ", Lookup[plain, "Permutation", "-"]];
   log["P8 class-6 permuted member in the chart: ", statusOf[permuted],
     " permutation ", Lookup[permuted, "Permutation", "-"]];

   FTAssert["P8a the class-6 representative pulls back to the chart with the \
identity permutation (control)",
     AssociationQ[pull] && pull["Status"] === "OK" &&
       AssociationQ[plain] && plain["Status"] === "OK" &&
       Lookup[plain, "Permutation", None] === {1, 2}];
   FTAssert["P8b a member differing by a basis PERMUTATION is recovered in \
the chart, with both exact gates, and its transformation is the \
representative's with the two basis elements exchanged",
     AssociationQ[permuted] && permuted["Status"] === "OK" &&
       Lookup[permuted, "Permutation", None] === {2, 1} &&
       AssociationQ[plain] && MatrixQ[Lookup[plain, "T", None]] &&
       permuted["T"] === plain["T"][[{2, 1}, {2, 1}]] &&
       permuted["T"] =!= plain["T"] &&
       TrueQ[permuted["Certificate"]["EpsFormReDerivedFromBlockSystem"]] &&
       TrueQ[permuted["Certificate"]["EpsFormLinear"]] &&
       TrueQ[permuted["Certificate"]["StoredEpsFormPullbackMatches"]]]]];

(* P9: the axis-direction choice in the chart.

   "PathDirection" -> "First" freezes the second chart variable and
   moves the first from the anchor; "Second" is the mirror image.  Which
   of the two a family admits is a property of its pulled-back alphabet,
   so Automatic -- now the default -- hands BOTH down to TransportFamily
   as candidates and lets the monic gate choose.  Criteria: the run
   still transports and checks exactly (the direction machinery must not
   change the answer); TWO candidates were offered; the direction taken
   is read back and recorded in "ChartNotes" rather than assumed.

   The datum is the flat 2x2 epsilon-form toy above, so this costs a
   weight-2 transport and not a family. *)

Module[{auto, first, path},
  auto = FeynFacet`TransportFamilyInChart[
    <|"Family" -> "TOYaxis", "Av" -> toyAv, "Aw" -> toyAw|>,
    chart97, "SourceVariables" -> {vv, ww}, "Regulator" -> ee,
    "Blocks" -> {{{1, 2}, <|"Type" -> "EpsForm", "T" -> IdentityMatrix[2]|>}},
    "PhysicalValuation" -> 0, "Orders" -> {0, 1},
    "TransportBackend" -> "Libra", "MaxWeight" -> 4];
  first = FeynFacet`TransportFamilyInChart[
    <|"Family" -> "TOYaxis", "Av" -> toyAv, "Aw" -> toyAw|>,
    chart97, "SourceVariables" -> {vv, ww}, "Regulator" -> ee,
    "Blocks" -> {{{1, 2}, <|"Type" -> "EpsForm", "T" -> IdentityMatrix[2]|>}},
    "PhysicalValuation" -> 0, "Orders" -> {0, 1}, "PathDirection" -> "First",
    "TransportBackend" -> "Libra", "MaxWeight" -> 4];
  path = Lookup[auto, "Path", <||>];
  log["P9 chart PathDirection Automatic -> ", statusOf[auto],
    "  base ", Lookup[path, "Base", "-"],
    "  candidates ", Lookup[path, "Candidates", "-"],
    "  notes direction ",
      Lookup[Lookup[Lookup[auto, "ChartNotes", <||>], "Path", <||>],
        "Direction", "-"]];

  FTAssert["P9a with \"PathDirection\" -> Automatic BOTH chart axis \
directions are offered as candidates, the chosen one is recorded under \
\"Path\" and named in \"ChartNotes\"",
    resultQ[auto] && Length[Lookup[path, "Candidates", {}]] === 2 &&
      Lookup[path, "Candidates", {}] === {{1/2, yy}, {xx, 1/2}} &&
      MatchQ[Lookup[path, "Base", None], {_, _}] &&
      MemberQ[{"First", "Second"},
        Lookup[Lookup[Lookup[auto, "ChartNotes", <||>], "Path", <||>],
          "Direction", None]]];
  FTAssert["P9b the direction machinery does not change the answer: the \
Automatic run and the explicit \"First\" run reach the same status and both \
check exactly against the ORIGINAL differential equation",
    resultQ[auto] && resultQ[first] && statusOf[auto] === statusOf[first] &&
      statusOf[auto] === "OK" &&
      auto["DECheck"] =!= {} && AllTrue[auto["DECheck"], zeroOrder] &&
      first["DECheck"] =!= {} && AllTrue[first["DECheck"], zeroOrder]]];

(* ----------------------------------------------------------------- T1 *)

nloRaw = readArtifact[FileNameJoin[{root, "ppHX_NLO", "Results", "NLO_UU_Masters.wl"}]];
nloSystem = nloRaw["DifferentialSystem"];
nloBasis = nloSystem["Basis"];
nloAv = normalizeRegulator[nloSystem["Av"]];
nloAw = normalizeRegulator[nloSystem["Aw"]];
nloT = DiagonalMatrix[{1, (2 ee - 1)/(ee vv), (2 ee - 1)/(ee ww (vv + ww - 1)),
   (2 ee - 1)/(ee ww), (2 ee - 1)/(ee (vv + ww - 1)),
   (2 ee - 1)/(ee vv (vv + ww - 1)), (2 ee - 1)/(ee vv ww)}];
nloBlocks = Table[{{i}, <|"Type" -> "EpsForm", "T" -> {{nloT[[i, i]]}}|>}, {i, 7}];
nloInput = <|"Family" -> "NLO", "Basis" -> nloBasis, "Av" -> nloAv, "Aw" -> nloAw|>;

log["T1 (i) NLO in (v,w)"];
{t1vwSeconds, resultVW} = AbsoluteTiming[FeynFacet`TransportFamily[nloInput,
  "Variables" -> {vv, ww}, "Regulator" -> ee, "Blocks" -> nloBlocks,
  "BasePoint" -> {1/4, 1/4}, "Orders" -> {-1, 2}, "PhysicalValuation" -> -1,
  "TransportBackend" -> "Libra"]];
log["T1 (i) status ", statusOf[resultVW], "  weight ",
  Lookup[resultVW, "Weight", "?"], "  ", secs[t1vwSeconds]];

log["T1 (ii) NLO in the 97 chart"];
{t1chartSeconds, resultChart} = AbsoluteTiming[FeynFacet`TransportFamilyInChart[
  nloInput, chart97, "SourceVariables" -> {vv, ww}, "Regulator" -> ee,
  "Blocks" -> nloBlocks, "Orders" -> {-1, 2}, "PhysicalValuation" -> -1,
  "TransportBackend" -> "Libra", "MaxWeight" -> 12]];
log["T1 (ii) status ", statusOf[resultChart], "  weight ",
  Lookup[resultChart, "Weight", "?"], "  ", secs[t1chartSeconds]];

FTAssert["T1a the pulled-back NLO system is flat in the chart -- exact",
  resultQ[resultChart] &&
    TrueQ[Lookup[resultChart, "PullBack", <||>]["System"]["ChartFlat"]] &&
    TrueQ[resultChart["PullBack"]["System"]["SourceFlat"]]];

FTAssert["T1b all seven block forms are re-derived from the pulled-back \
block system and are epsilon-forms -- exact",
  resultQ[resultChart] &&
    Length[Lookup[resultChart, "PullBack", <||>]["Forms"]] === 7 &&
    AllTrue[Values[resultChart["PullBack"]["Forms"]],
      TrueQ[#["EpsFormReDerivedFromBlockSystem"]] && TrueQ[#["EpsFormLinear"]] &] &&
    TrueQ[resultChart["Certificate"]["EpsFormLinear"]]];

FTAssert["T1c both runs reach status OK and carry the five-part conjugation \
certificate",
  resultQ[resultVW] && resultQ[resultChart] &&
    statusOf[resultVW] === "OK" && statusOf[resultChart] === "OK" &&
    TrueQ[FeynFacet`Private`masterTransportCertificateOK[resultVW["Assembly"]]] &&
    TrueQ[FeynFacet`Private`masterTransportCertificateOK[resultChart["Assembly"]]]];

FTAssert["T1d the two conjugated connections agree EXACTLY by the chain \
rule, on the same block permutation",
  resultQ[resultVW] && resultQ[resultChart] &&
    Module[{apv, apw, jac},
      apv = tog[resultVW["Assembly"]["Apv"] /. chartData["Subst"]];
      apw = tog[resultVW["Assembly"]["Apw"] /. chartData["Subst"]];
      jac = chartData["Jacobian"];
      resultVW["Assembly"]["Perm"] === resultChart["Assembly"]["Perm"] &&
        zeroM[resultChart["Assembly"]["Apv"] - (apv jac[[1, 1]] + apw jac[[2, 1]])] &&
        zeroM[resultChart["Assembly"]["Apw"] - (apv jac[[1, 2]] + apw jac[[2, 2]])]]];

FTAssert["T1e both runs satisfy their ORIGINAL family differential equation \
as exact symbolic zeros at every checkable order",
  resultQ[resultVW] && resultQ[resultChart] &&
    resultVW["DECheck"] =!= {} && AllTrue[resultVW["DECheck"], zeroOrder] &&
    resultChart["DECheck"] =!= {} && AllTrue[resultChart["DECheck"], zeroOrder]];

log["T1f measuring the generic-path boundary (strict gate)"];
(* Since 2026-08-17 the default "AlgebraicLetters" -> Automatic ADMITS
   quadratic path denominators with an eps-free discriminant as pairs of
   algebraic letters, so on a generic segment the transport now RUNS
   (with algebraic letters) instead of being refused.  T1f measures the
   STRICT gate's boundary, which is what motivated the axis-aligned
   default; it therefore pins "AlgebraicLetters" -> False explicitly.
   Measured 2026-08-17 (agent A, t_ch_A/t_ch_B): with the default the
   generic-path NLO transport proceeds and does not return in 2000 s. *)
{t1genericSeconds, resultGeneric} = AbsoluteTiming[
  FeynFacet`TransportFamilyInChart[nloInput, chart97,
    "SourceVariables" -> {vv, ww}, "Regulator" -> ee, "Blocks" -> nloBlocks,
    "BasePoint" -> {1/2, 1/4}, "PathDirection" -> "Generic",
    "Orders" -> {-1, 0}, "PhysicalValuation" -> -1,
    "AlgebraicLetters" -> False,
    "TransportBackend" -> "Libra"]];
log["T1f generic-path status ", statusOf[resultGeneric], "  ", secs[t1genericSeconds]];

FTAssert["T1f the axis-aligned default is MEASURED: under the STRICT gate \
(AlgebraicLetters -> False) a generic straight segment in (x,y) makes a \
pulled-back letter quadratic in the path parameter and is refused with \
PathDenominatorsNotLinear",
  resultQ[resultGeneric] && statusOf[resultGeneric] === "PathDenominatorsNotLinear"];
FTAssert["T1f' the same generic segment is ADMISSIBLE with algebraic letters \
(every quadratic path denominator has an eps-free discriminant)",
  resultQ[resultGeneric] && KeyExistsQ[resultGeneric, "Monic"] &&
    TrueQ[resultGeneric["Monic"]["AlgebraicAdmissible"]]];

FTAssert["T1g the chart is recorded with its Jacobian determinant, and no \
physics bookkeeping is done in the engine",
  resultQ[resultChart] &&
    TrueQ[Together[resultChart["ChartNotes"]["JacobianDet"] - (xx - yy)] === 0] &&
    resultChart["ChartNotes"]["Path"]["Direction"] === "First" &&
    StringQ[resultChart["ChartNotes"]["PhysicsBookkeeping"]]];

log["T1 wall times: (v,w) ", secs[t1vwSeconds], ", chart ", secs[t1chartSeconds],
  ", generic-path probe ", secs[t1genericSeconds]];

(* ----------------------------------------------------------------- T2 *)

(* The hard-class records.  ClassForms/classNN.wl is used when it
   exists; otherwise the record is assembled here from the repository
   artifact HardClasses/EpsFormRoute/cNN_epsform_two_variable.wl, in the
   ClassForms schema.  Both inputs are under version control. *)
classFormFile[cid_] := FileNameJoin[{ftClassForms, "class" <> ToString[cid] <> ".wl"}];

hardArtifact[cid_] := FileNameJoin[{ftHard,
  "c" <> ToString[cid] <> "_epsform_two_variable.wl"}];

hardRecord[cid_, repFamily_, repRows_] := Module[{raw},
  If[FileExistsQ[classFormFile[cid]],
    Return[readArtifact[classFormFile[cid]]]];
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
record77 = hardRecord[77, "CF230", {1, 2, 3, 4}];
log["class-97 record source: ",
  If[FileExistsQ[classFormFile[97]], classFormFile[97], hardArtifact[97]]];
log["class-77 record source: ",
  If[FileExistsQ[classFormFile[77]], classFormFile[77], hardArtifact[77]]];

FTAssert["T2a the class-97 record is in the target chart and its stored \
substitution matches it EXACTLY",
  Module[{map = FeynFacet`Private`masterTransportRecordCoordinateMap[
      record97, chartData, Automatic]},
    AssociationQ[map] && map["Status"] === "OK" &&
      map["Frame"] === "TargetChart" && TrueQ[map["CompositionExact"]]]];

assignments = readArtifact[FileNameJoin[{ftBlockClasses, "block_class_assign.wl"}]];

familyBlocks[family_] := Module[{rows},
  rows = Select[assignments, #["Family"] === family &];
  Table[{a["Rows"], Which[
      a["ClassID"] === 97 && ! FileExistsQ[classFormFile[97]], record97,
      a["ClassID"] === 77 && ! FileExistsQ[classFormFile[77]], record77,
      True, a["ClassID"]]}, {a, rows}]];

cf258 = readArtifact[FileNameJoin[{ftDE, "nnlo_de_CF258.wl"}]];
cf258Blocks = familyBlocks["CF258"];
log["CF258: ", Length[cf258["Av"]], " masters, ", Length[cf258Blocks], " blocks, classes ",
  Select[assignments, #["Family"] === "CF258" &][[All, "ClassID"]]];

{t2bSeconds, cf258Pull} = AbsoluteTiming[
  FeynFacet`Private`masterTransportPullBackSystem[
    <|"Family" -> "CF258", "Av" -> cf258["Av"], "Aw" -> cf258["Aw"]|>,
    chartData, "SourceVariables" -> {vv, ww}]];
log["T2b CF258 system pullback: ", statusOf[cf258Pull], "  ", secs[t2bSeconds]];

FTAssert["T2b CF258's connection pulls back to the chart with an exact \
flatness certificate in both frames",
  AssociationQ[cf258Pull] && cf258Pull["Status"] === "OK" &&
    TrueQ[cf258Pull["Certificate"]["SourceFlat"]] &&
    TrueQ[cf258Pull["Certificate"]["ChartFlat"]]];

cf258Forms = If[! (AssociationQ[cf258Pull] && cf258Pull["Status"] === "OK"), {},
  Table[
    Module[{r, seconds},
      {seconds, r} = AbsoluteTiming[
        FeynFacet`Private`masterTransportChartBlockSpec[b[[2]], b[[1]],
          cf258Pull["Ax"], cf258Pull["Ay"], chartData, ee, ftClassForms,
          Automatic,
          (* ninth argument since 2026-08-17 (multiquadratic frames); this
             call was left at eight and the test has been red since
             (found 2026-08-22) *)
          Lookup[chartData, "CoefficientField", "Rational"]]];
      log["  T2c block rows ", b[[1]], " class ", Lookup[r, "ClassID", "-"],
        " -> ", statusOf[r], " frame ",
        Lookup[Lookup[r, "Certificate", <||>], "Frame", "-"], "  ", secs[seconds]];
      r],
    {b, cf258Blocks}]];

FTAssert["T2c every one of CF258's 12 block forms pulls back and re-verifies \
as an epsilon-form in the chart -- exact, including the two single-conic-chart \
classes",
  Length[cf258Forms] === Length[cf258Blocks] && cf258Forms =!= {} &&
    AllTrue[cf258Forms, AssociationQ[#] && #["Status"] === "OK" &] &&
    AllTrue[cf258Forms,
      Module[{c = Lookup[#, "Certificate", <||>]},
        c["Frame"] === "ScalarAutomatic" ||
          (TrueQ[c["EpsFormReDerivedFromBlockSystem"]] &&
           TrueQ[c["EpsFormLinear"]] && TrueQ[c["CompositionExact"]])] &]];

(* Class equivalence is a basis permutation OPTIONALLY composed with
   v <-> w, so a member's connection need not equal the representative's.
   Measured: CF258 rows {5} and {24} and CF230 row {7} are exactly that
   case.  In this chart the swap is (x,y) -> (1-x,1-y), and it must be
   RESOLVED by the exact re-derivation, never assumed. *)
log["T2c swapped blocks: ",
  Select[Transpose[{cf258Blocks[[All, 1]], cf258Forms}],
    TrueQ[Lookup[Lookup[#[[2]], "Certificate", <||>], "Swapped", False]] &][[All, 1]]];

FTAssert["T2c'' the v<->w class-equivalence swap is exercised, RESOLVED by \
the exact re-derivation rather than assumed, and its members re-verify as \
epsilon-forms in the chart",
  cf258Forms =!= {} &&
    Module[{swapped = Select[cf258Forms,
        TrueQ[Lookup[Lookup[#, "Certificate", <||>], "Swapped", False]] &]},
      Length[swapped] >= 1 &&
        AllTrue[swapped, #["Status"] === "OK" &&
          TrueQ[#["Certificate"]["EpsFormReDerivedFromBlockSystem"]] &&
          TrueQ[#["Certificate"]["EpsFormLinear"]] &&
          TrueQ[#["Certificate"]["StoredEpsFormPullbackMatches"]] &]]];

FTAssert["T2c' the single-conic-chart classes are composed with the chart by \
a LINEAR solve of their own Root, confirmed by the exact chart identity -- no \
square root is introduced",
  cf258Forms =!= {} &&
    Module[{conic = Select[cf258Forms,
        Lookup[Lookup[#, "Certificate", <||>], "Frame", None] ===
          "SingleConicChart" &]},
      Length[conic] >= 1 &&
        AllTrue[conic, TrueQ[#["Certificate"]["CompositionExact"]] &&
          FreeQ[#["Form"]["Coordinates"]["ParameterMap"],
            Power[_, _Rational] | _Root] &]]];

(* T2d: the class-97 block standalone.  It is a legitimate family in its
   own right -- the diagonal block of a block-lower-triangular flat
   connection is flat by itself -- and it is the cheap scale at which the
   whole point of this layer is testable. *)
hardRows97 = {18, 19, 20, 21};
log["T2d transporting the class-97 block (rows ", hardRows97, ") in the chart"];
{t2dSeconds, result97} = AbsoluteTiming[FeynFacet`TransportFamilyInChart[
  <|"Family" -> "CF258_B97", "Av" -> cf258["Av"][[hardRows97, hardRows97]],
    "Aw" -> cf258["Aw"][[hardRows97, hardRows97]]|>,
  chart97, "SourceVariables" -> {vv, ww}, "Regulator" -> ee,
  "Blocks" -> {{{1, 2, 3, 4}, record97}},
  "PhysicalValuation" -> 0, "Orders" -> {0, 1},
  "TransportBackend" -> "Libra", "MaxWeight" -> 10]];
log["T2d status ", statusOf[result97], "  weight ", Lookup[result97, "Weight", "?"],
  "  ", secs[t2dSeconds]];
If[resultQ[result97], FeynFacet`TransportStatus[result97]];

FTAssert["T2d the class-97 block transports in the chart with the five-part \
certificate and an exact per-order check against its ORIGINAL differential \
equation",
  resultQ[result97] && statusOf[result97] === "OK" &&
    TrueQ[FeynFacet`Private`masterTransportCertificateOK[result97["Assembly"]]] &&
    result97["DECheck"] =!= {} && AllTrue[result97["DECheck"], zeroOrder]];

(* T2f: the same block through the PLAIN (v,w) entry point must be
   refused BY NAME.  A two-variable chart record carries a chart
   "Inverse", so it passes that guard; its T would then be differentiated
   with respect to (v,w) -- symbols it does not contain -- and conjugated
   against a (v,w) block system, i.e. used in the wrong frame.  Only
   TransportFamilyInChart may consume such a record. *)
log["T2f probing the plain (v,w) path with the class-97 record"];
resultWrongFrame = FeynFacet`TransportFamily[
  <|"Family" -> "CF258_B97_vw", "Av" -> cf258["Av"][[hardRows97, hardRows97]],
    "Aw" -> cf258["Aw"][[hardRows97, hardRows97]]|>,
  "Variables" -> {vv, ww}, "Regulator" -> ee,
  "Blocks" -> {{{1, 2, 3, 4}, 97}}, "FormDirectory" -> ftClassForms,
  "BasePoint" -> {1/4, 1/4}, "PhysicalValuation" -> 0, "Orders" -> {0, 1}];
log["T2f status ", statusOf[resultWrongFrame], "  reason ",
  Lookup[resultWrongFrame, "Reason", "?"]];

FTAssert["T2f a two-variable chart record is REFUSED by the plain (v,w) \
path with ClassFormTwoVariableChartNeedsChartTransport, never used in the \
wrong frame",
  resultQ[resultWrongFrame] && statusOf[resultWrongFrame] === "AssemblyFailed" &&
    ! FreeQ[resultWrongFrame, "ClassFormTwoVariableChartNeedsChartTransport"]];

(* ----------------------------------------------------------------- T3 *)

cf230 = readArtifact[FileNameJoin[{ftDE, "nnlo_de_CF230.wl"}]];
cf230Blocks = familyBlocks["CF230"];
log["CF230: ", Length[cf230["Av"]], " masters, ", Length[cf230Blocks], " blocks, classes ",
  Select[assignments, #["Family"] === "CF230" &][[All, "ClassID"]]];

hardRows77 = {1, 2, 3, 4};
log["T3d transporting the class-77 block (rows ", hardRows77, ") in the chart"];
{t3dSeconds, result77} = AbsoluteTiming[FeynFacet`TransportFamilyInChart[
  <|"Family" -> "CF230_B77", "Av" -> cf230["Av"][[hardRows77, hardRows77]],
    "Aw" -> cf230["Aw"][[hardRows77, hardRows77]]|>,
  chart97, "SourceVariables" -> {vv, ww}, "Regulator" -> ee,
  "Blocks" -> {{{1, 2, 3, 4}, record77}},
  "PhysicalValuation" -> 0, "Orders" -> {0, 1},
  "TransportBackend" -> "Libra", "MaxWeight" -> 10]];
log["T3d status ", statusOf[result77], "  weight ", Lookup[result77, "Weight", "?"],
  "  ", secs[t3dSeconds]];

FTAssert["T3d the class-77 block transports in the chart with the five-part \
certificate and an exact per-order check against its ORIGINAL differential \
equation",
  resultQ[result77] && statusOf[result77] === "OK" &&
    TrueQ[FeynFacet`Private`masterTransportCertificateOK[result77["Assembly"]]] &&
    result77["DECheck"] =!= {} && AllTrue[result77["DECheck"], zeroOrder]];

(* ------------------------------------------- heavy, whole-family items *)

If[! heavy,
  log["T2e/T3e SKIPPED (whole-family transport); set FT_CHART_HEAVY=1 to run them"],
  Module[{tf, rf},
   log["T2e transporting the WHOLE of CF258 in the chart"];
   {tf, rf} = AbsoluteTiming[FeynFacet`TransportFamilyInChart[
     <|"Family" -> "CF258", "Basis" -> Lookup[cf258, "BlockBasis", None],
       "Av" -> cf258["Av"], "Aw" -> cf258["Aw"]|>,
     chart97, "SourceVariables" -> {vv, ww}, "Regulator" -> ee,
     "Blocks" -> cf258Blocks, "FormDirectory" -> ftClassForms,
     "PhysicalValuation" -> 0, "Orders" -> {0, 1},
     "TransportBackend" -> "Libra", "MaxWeight" -> 12, "Verbose" -> True]];
   log["T2e status ", statusOf[rf], "  weight ", Lookup[rf, "Weight", "?"],
     "  ", secs[tf]];
   If[resultQ[rf], FeynFacet`TransportStatus[rf]];
   FTAssert["T2e the whole of CF258 transports in the chart with the \
five-part certificate and exact per-order checks",
     resultQ[rf] && statusOf[rf] === "OK" &&
       TrueQ[FeynFacet`Private`masterTransportCertificateOK[rf["Assembly"]]] &&
       rf["DECheck"] =!= {} && AllTrue[rf["DECheck"], zeroOrder]];

   log["T3e transporting the WHOLE of CF230 in the chart"];
   {tf, rf} = AbsoluteTiming[FeynFacet`TransportFamilyInChart[
     <|"Family" -> "CF230", "Basis" -> Lookup[cf230, "BlockBasis", None],
       "Av" -> cf230["Av"], "Aw" -> cf230["Aw"]|>,
     chart97, "SourceVariables" -> {vv, ww}, "Regulator" -> ee,
     "Blocks" -> cf230Blocks, "FormDirectory" -> ftClassForms,
     "PhysicalValuation" -> 0, "Orders" -> {0, 1},
     "TransportBackend" -> "Libra", "MaxWeight" -> 12, "Verbose" -> True]];
   log["T3e status ", statusOf[rf], "  weight ", Lookup[rf, "Weight", "?"],
     "  ", secs[tf]];
   If[resultQ[rf], FeynFacet`TransportStatus[rf]];
   FTAssert["T3e the whole of CF230 transports in the chart with the \
five-part certificate and exact per-order checks",
     resultQ[rf] && statusOf[rf] === "OK" &&
       TrueQ[FeynFacet`Private`masterTransportCertificateOK[rf["Assembly"]]] &&
       rf["DECheck"] =!= {} && AllTrue[rf["DECheck"], zeroOrder]]]];

FTReport[];
