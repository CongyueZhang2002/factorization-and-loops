#!/usr/bin/env wolframscript
(* Cheap gate (b): ONE REAL mid-size off-diagonal block from a saved
   campaign state.  Compares the deferred construction route against the
   symbolic one on wall time and on exact value, and cross-checks both
   against the strip input production actually wrote for that block.
   Deferred first, so the number that decides the design is on disk
   before the 536 s symbolic route is paid. *)
$HistoryLength = 0;
root = "/home/maxzhang/factorization-and-loops";
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

fixtureFile = $ScriptCommandLine[[2]];
productionInput = If[Length[$ScriptCommandLine] >= 3,
  $ScriptCommandLine[[3]], None];
progressFile = fixtureFile <> ".progress";
note[a___] := Module[{str = OpenAppend[progressFile]},
  WriteString[str, DateString["Time"], "  ",
    StringJoin[ToString[#, InputForm] & /@ {a}], "\n"]; Close[str];
  Print[StringJoin[ToString[#, InputForm] & /@ {a}]]];

ee = Global`eps; xx = Global`x; yy = Global`y;
$normalizeNames = {"eps", "Eps", "epsilon", "Epsilon", "ep", "v", "w",
   "x", "y", "u", "t", "tau", "s", "p", "sqrtLambda", "gli"};
normalizeSymbols[expr_] := Module[{syms, rules},
  syms = DeleteDuplicates[Cases[expr,
     sy_Symbol /; MemberQ[$normalizeNames, SymbolName[sy]] &&
       Context[sy] =!= "Global`", {0, Infinity}, Heads -> True]];
  rules = Table[syms[[i]] -> Symbol["Global`" <> SymbolName[syms[[i]]]],
    {i, Length[syms]}]; expr /. rules];

fx = normalizeSymbols[Get[fixtureFile]];
feeders = fx["Feeders"];
rk = fx["RowIndices"]; rj = fx["ColumnIndices"];
allRanges = fx["Ranges"];
note["fixture ", fx["Family"], " block ", {fx["Sector"], fx["LowerSector"]},
  ": rows ", rk, ", columns ", rj, ", feeders ", feeders,
  ", leaf counts A_kj ", LeafCount[fx["ABlockKJ"]],
  " feeds ", LeafCount[fx["AFeed"]], " gauges ", LeafCount[fx["Gauge"]]];

(* ---------- route B: the deferred construction ------------------------ *)
(* a reduced connection carrying exactly the blocks the formula reads;
   block order (lower sector, feeders..., sector) *)
blocks = Join[{fx["LowerSector"]}, feeders, {fx["Sector"]}];
sizes = Length[allRanges[[#]]] & /@ blocks;
offsets = Prepend[Accumulate[Most[sizes]], 0];
localRange = Table[offsets[[b]] + Range[sizes[[b]]], {b, Length[blocks]}];
nLocal = Total[sizes];
localOf = Association[Table[blocks[[b]] -> b, {b, Length[blocks]}]];
connection = Table[ConstantArray[0, {nLocal, nLocal}], {2}];
Do[
  connection[[mu, localRange[[localOf[fx["Sector"]]]], localRange[[1]]]] =
    fx["ABlockKJ"][[mu]];
  Do[connection[[mu, localRange[[localOf[m]]], localRange[[1]]]] =
      fx["AFeed"][m][[mu]], {m, feeders}],
  {mu, 2}];
solved = Association[Table[localOf[m] -> fx["Gauge"][m], {m, feeders}]];
kLocal = localOf[fx["Sector"]]; jLocal = 1;

prepTiming = AbsoluteTiming[
  prep = FeynFacet`Private`blockEquationDeferredPrepare[
    connection, localRange, kLocal, jLocal, solved, {xx, yy}, ee]];
note["[deferred] prepare: ", Round[First[prepTiming], 0.01], " s -> ",
  Lookup[prep, "Status", prep], " ", Lookup[prep, "Statistics", <||>]];
If[Lookup[prep, "Status", None] =!= "Prepared", note["ABORT"]; Exit[2]];

censusTriples = Flatten[Table[{pt, e0, p0},
   {p0, {1000003, 1000033}},
   {pt, {{7717, 9227}, {31627, 44417}}},
   {e0, {104729, 15485867}}], 2];
censusTiming = AbsoluteTiming[
  censusResult = FeynFacet`Private`blockEquationDeferredNonzeroCensus[
    prep, censusTriples]];
note["[deferred] census: ", Round[First[censusTiming], 0.01], " s -> ",
  KeyTake[censusResult, {"Status", "AcceptedSamples", "NonzeroProvedQ"}],
  " rejection statuses ", Tally[Lookup[#, "Status", None] & /@
    Lookup[censusResult, "Rejections", {}]]];

matTiming = AbsoluteTiming[
  mat = FeynFacet`Private`blockEquationDeferredMaterialize[prep]];
note["[deferred] materialize: ", Round[First[matTiming], 0.1], " s -> ",
  KeyDrop[mat, "Values"]];

dims = prep["Dimensions"];
bbarDeferred = Table[mat["Values"][{mu, i, jj}],
  {mu, dims[[1]]}, {i, dims[[2]]}, {jj, dims[[3]]}];
deferredSeconds = First[prepTiming] + First[censusTiming] + First[matTiming];
note["[deferred] TOTAL ", Round[deferredSeconds, 0.1], " s"];

(* ---------- route A: the symbolic construction (current production) --- *)
(* cached across bench runs: the baseline is the same 536 s object every
   time, and re-paying it would eat the time-box *)
symbolicCache = fixtureFile <> ".symbolic";
If[FileExistsQ[symbolicCache],
  cached = Get[symbolicCache];
  bbarSymbolic = cached["Forcing"];
  symTiming = {cached["Seconds"], Null};
  zeroTiming = {cached["ZeroSeconds"], Null};
  symbolicZeroQ = cached["ZeroForcingQ"];
  note["[symbolic] reusing the cached baseline: ",
    Round[First[symTiming], 0.1], " s forcing + ",
    Round[First[zeroTiming], 0.1], " s zero probe (measured earlier)"],
  symTiming = AbsoluteTiming[
    bbarSymbolic = Table[
      Map[Together, fx["ABlockKJ"][[mu]] -
        Sum[fx["Gauge"][m] . fx["AFeed"][m][[mu]], {m, feeders}], {2}],
      {mu, 2}]];
  note["[symbolic] blockEquation forcing: ", Round[First[symTiming], 0.1], " s"];
  zeroTiming = AbsoluteTiming[
    symbolicZeroQ = AllTrue[Flatten[bbarSymbolic], TrueQ[Together[#] === 0] &]];
  Put[<|"Forcing" -> bbarSymbolic, "Seconds" -> First[symTiming],
     "ZeroSeconds" -> First[zeroTiming], "ZeroForcingQ" -> symbolicZeroQ|>,
    symbolicCache]];
note["[symbolic] zero-forcing probe: ", Round[First[zeroTiming], 0.1],
  " s -> ", symbolicZeroQ];
note["[symbolic] TOTAL ", Round[First[symTiming] + First[zeroTiming], 0.1], " s"];

note["--- wall time: symbolic ",
  Round[First[symTiming] + First[zeroTiming], 0.1], " s  vs deferred ",
  Round[deferredSeconds, 0.1], " s  (speedup ",
  Round[(First[symTiming] + First[zeroTiming])/deferredSeconds, 0.01], "x) ---"];

(* ---------- exact equality ------------------------------------------- *)
eqTiming = AbsoluteTiming[
  exactEqual = AllTrue[Flatten[Table[
      Together[bbarDeferred[[mu, i, jj]] - bbarSymbolic[[mu, i, jj]]],
      {mu, dims[[1]]}, {i, dims[[2]]}, {jj, dims[[3]]}]],
    TrueQ[# === 0] &]];
note["exact equality deferred == symbolic: ", exactEqual,
  " (", Round[First[eqTiming], 0.1], " s)"];

(* ---------- modular image equality at 3 (prime, eps, point) triples --- *)
triples = {{{12345, 54321}, 7, 1000003}, {{99991, 31337}, -3, 1000033},
   {{4242, 8484}, 1/5, 1000037}};
imageChecks = Table[
  Module[{ev, symImage, ok},
   ev = FeynFacet`Private`blockEquationDeferredEvaluate[prep,
     t[[1]], t[[2]], t[[3]]];
   If[Lookup[ev, "Status", None] =!= "OK", {t[[3]], t[[2]], ev["Status"]},
    symImage = Table[
      Module[{q = Together[bbarSymbolic[[mu, i, jj]] /.
          {xx -> t[[1, 1]], yy -> t[[1, 2]], ee -> t[[2]]}]},
       Mod[Numerator[q] PowerMod[Denominator[q], -1, t[[3]]], t[[3]]]],
      {mu, dims[[1]]}, {i, dims[[2]]}, {jj, dims[[3]]}];
    ok = symImage === ev["Image"];
    {t[[3]], t[[2]], ok}]],
  {t, triples}];
note["modular image equality (prime, eps, ok): ", imageChecks];

(* ---------- cross-check against what production wrote ---------------- *)
If[StringQ[productionInput] && FileExistsQ[productionInput],
  saved = normalizeSymbols[Get[productionInput]];
  savedBbar = saved["Strip"][[3]];
  note["production strip input dimensions ", Dimensions[savedBbar]];
  note["deferred == production bbar: ",
    AllTrue[Flatten[Table[
       Together[bbarDeferred[[mu, i, jj]] - savedBbar[[mu, i, jj]]],
       {mu, 2}, {i, dims[[2]]}, {jj, dims[[3]]}]], TrueQ[# === 0] &]]];

(* ---------- solver-visible metadata ---------------------------------- *)
alphaSym = FeynFacet`Private`epsFormStripAlphabet[
  {fx["ADiagK"], fx["ADiagJ"], bbarSymbolic}, {xx, yy}, ee];
alphaDef = FeynFacet`Private`epsFormStripAlphabet[
  {fx["ADiagK"], fx["ADiagJ"], bbarDeferred}, {xx, yy}, ee];
note["alphabet symbolic ", Length[alphaSym], " vs deferred ",
  Length[alphaDef], "; identical: ", Sort[alphaSym] === Sort[alphaDef]];
note["leaf counts: symbolic ", LeafCount[bbarSymbolic], " deferred ",
  LeafCount[bbarDeferred]];
(* the rest of the solver's input contract: the gauge denominator and the
   a-priori support census are read off bbar's denominators, so a less
   cancelled entry would enlarge the ansatz even with the same alphabet *)
gaugeDen[b_] := Module[{factorPairs, factors, factorPowers},
  factorPairs = Flatten[
    FeynFacet`Private`finiteFieldStripEntryFactorList /@ Flatten[b], 1];
  factors = If[factorPairs === {}, {},
    DeleteDuplicates[factorPairs[[All, 1]], SameQ]];
  factorPowers = Table[{f, Max[Cases[factorPairs,
     {c_, pw_} /; SameQ[c, f] :> pw]]}, {f, factors}];
  Times @@ ((First[#]^(Last[#] - 1)) & /@
    Select[factorPowers, Last[#] > 1 &])];
gSym = gaugeDen[bbarSymbolic]; gDef = gaugeDen[bbarDeferred];
note["gauge denominator equal: ", TrueQ[Together[gSym - gDef] === 0],
  "; symbolic ", gSym, " deferred ", gDef];
prepSym = FeynFacet`Private`finiteFieldStripPrepare[<|
   "Family" -> "bench", "Variables" -> {xx, yy}, "Regulator" -> ee,
   "Strip" -> {fx["ADiagK"], fx["ADiagJ"], bbarSymbolic}|>];
prepDef = FeynFacet`Private`finiteFieldStripPrepare[<|
   "Family" -> "bench", "Variables" -> {xx, yy}, "Regulator" -> ee,
   "Strip" -> {fx["ADiagK"], fx["ADiagJ"], bbarDeferred}|>];
note["solver preparation: symbolic census ",
  Lookup[prepSym, "SupportCensus", <||>], " (", 
  Round[Lookup[prepSym, "PrepareSeconds", 0.], 0.1], " s)"];
note["solver preparation: deferred census ",
  Lookup[prepDef, "SupportCensus", <||>], " (",
  Round[Lookup[prepDef, "PrepareSeconds", 0.], 0.1], " s)"];
note["solver denominator degrees equal: ",
  Lookup[prepSym, "DenominatorDegrees", None] ===
    Lookup[prepDef, "DenominatorDegrees", None],
  "; numerator degree bound equal: ",
  Lookup[Lookup[prepSym, "SupportCensus", <||>], "NumeratorTotalDegreeBound", None] ===
    Lookup[Lookup[prepDef, "SupportCensus", <||>], "NumeratorTotalDegreeBound", None]];
note["DONE"];
