(* The eps-dependent apparent loci carried by the class transformations
   of the blocks whose couplings S1 measured as NOT pure dlog.

   For each requested block: factor det T, list the eps-dependent factors
   that actually depend on (x,y) -- an eps-dependent factor free of (x,y)
   is a constant in the kinematics and cannot produce a pole in the path
   parameter -- and report the eps -> 0 degeneration of each, together
   with which genuine chart letter (if any) divides it.

   NOTE on what this does and does not license.  It locates the locus; it
   does NOT say a per-class scalar gauge can remove it.  A scalar gauge
   c multiplies T by c and scales det T by c^dim, so it cannot strip a
   single power of one factor; and the conjugated connection Ahat does
   not depend on the ORIGINAL basis at all.  What controls these poles is
   the relation between the CANONICAL basis of this block and those of
   its subsectors, i.e. the off-diagonal cleanup (strip transformations
   on the assembled chart connection).  This diagnostic is the input to
   that work, not a prescription for a gauge. *)

$HistoryLength = 0;
root = DirectoryName[ExpandFileName[$InputFileName], 3];
scratch = "/tmp/claude-1000/-home-maxzhang/97c0fce7-1578-4630-a481-38730c7f8b9d/scratchpad/opus_blockwise";
(* the cached assembly this reads is produced by Scripts/Diagnostics/blockwise_structure.wls *)
Quiet[Clear["Global`tau"]];
start = AbsoluteTime[];
log[a___] := Print["[locus +", ToString[Round[AbsoluteTime[] - start]], "s] ",
  StringJoin[ToString /@ {a}]];

argv = Rest[$ScriptCommandLine];
family = If[Length[argv] >= 1, argv[[1]], "CF258"];
targets = If[Length[argv] >= 2, ToExpression[argv[[2]]], {8, 10, 12}];
outdir = If[Length[argv] >= 3, argv[[3]], scratch];

log["loading FACET"];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
ee = Symbol["Global`eps"]; xx = Symbol["Global`x"]; yy = Symbol["Global`y"];

cache = Get[FileNameJoin[{scratch, "assembly_" <> family <> ".wl"}]];
assembly = cache["Assembly"];
blocks = assembly["Blocks"];
log[family, ": ", Length[blocks], " blocks; requested ", targets];

(* the chart alphabet of these families, for the eps -> 0 comparison *)
letters = {xx, yy, 1 - xx, 1 - yy, xx - yy, xx + yy, xx + yy - xx yy,
  xx + yy - 2 xx yy, 1 - xx yy, 2 - xx - yy, 1 - xx - yy};

kinematic[e_] := ! FreeQ[e, xx] || ! FreeQ[e, yy];

matchLetter[f_] := Module[{f0, hits},
  f0 = Factor[Together[f /. ee -> 0]];
  hits = Select[letters,
    TrueQ[Together[PolynomialRemainder[Numerator[Together[f0]],
      Numerator[Together[#]], xx]] === 0] &];
  <|"EpsZero" -> f0, "DividedBy" -> hits|>];

records = Table[
  Module[{t, tInverse, detT, factors, epsFactors, kinematicFactors, report},
    t = assembly["Forms"][[b]]["T"];
    tInverse = assembly["TInverse"][[b]];
    detT = Together[Det[t]];
    factors = FactorList[Numerator[detT]][[All, 1]];
    epsFactors = Select[factors, ! FreeQ[#, ee] && ! NumberQ[#] &];
    kinematicFactors = Select[epsFactors, kinematic];
    log["==== block ", b, " rows ", blocks[[b]], " dim ", Length[t],
      ": det T has ", Length[factors], " numerator factors, ",
      Length[epsFactors], " eps-dependent, ",
      Length[kinematicFactors], " of those depend on (x,y)"];
    report = Table[
      Module[{m = matchLetter[f]},
        Print["    eps-dependent (x,y)-factor: ", InputForm[f]];
        Print["      at eps = 0: ", InputForm[m["EpsZero"]],
          "   divisible by chart letter(s): ",
          If[m["DividedBy"] === {}, "NONE", InputForm[m["DividedBy"]]]];
        <|"Factor" -> f, "EpsZero" -> m["EpsZero"],
          "DividedBy" -> m["DividedBy"]|>],
      {f, kinematicFactors}];
    Do[Print["    eps-dependent but (x,y)-FREE (harmless): ", InputForm[f]],
      {f, Complement[epsFactors, kinematicFactors]}];
    <|"Block" -> b, "Rows" -> blocks[[b]], "Dim" -> Length[t],
      "DetT" -> detT, "DetTNumeratorFactors" -> factors,
      "EpsDependentFactors" -> epsFactors,
      "EpsDependentKinematicFactors" -> kinematicFactors,
      "PerFactor" -> report,
      "TInverseEpsDependentDenominatorFactors" ->
        Select[DeleteDuplicates[Flatten[Map[
          Function[e, Module[{x = Together[e]},
            If[TrueQ[x === 0], {}, FactorList[Denominator[x]][[All, 1]]]]],
          tInverse, {2}]]], ! FreeQ[#, ee] && ! NumberQ[#] &]|>],
  {b, targets}];

log["==== TABLE ===="];
Do[
  log["  block ", r["Block"], " rows ", r["Rows"], " dim ", r["Dim"],
    ": ", Length[r["EpsDependentKinematicFactors"]],
    " eps-dependent (x,y)-factor(s) in det T; eps=0 forms ",
    InputForm[Table[p["EpsZero"], {p, r["PerFactor"]}]],
    "; letters ", InputForm[Table[p["DividedBy"], {p, r["PerFactor"]}]]],
  {r, records}];

FeynFacet`Private`masterTransportPutAtomic[
  <|"Family" -> family, "Blocks" -> targets, "Records" -> records,
    "Statement" -> "eps-dependent apparent loci in det T of the class \
transformations of the blocks whose couplings S1 measured as not pure dlog \
in the path parameter.  An eps-dependent factor free of (x,y) is a constant \
in the kinematics and cannot produce a pole in the path parameter.  This \
locates the loci; removing them is the off-diagonal cleanup (canonical \
bases of the block relative to its subsectors), NOT a per-class scalar \
gauge, which would scale det T by c^dim.",
    "Date" -> DateString[]|>,
  FileNameJoin[{outdir, "blockwise_class_locus_" <> family <> ".wl"}]];
log["written blockwise_class_locus_", family, ".wl"];
log["DONE"];
