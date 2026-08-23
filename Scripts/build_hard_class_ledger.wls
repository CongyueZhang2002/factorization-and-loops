(* Ledger records for the hard classes (97 = CF258_B9, 77 = CF230_B1,
   79 = CF231_B1) in the ClassForms schema, built from the certified
   two-variable eps-form artifacts under
   Results/UU_08_10_canonical/HardClasses/EpsFormRoute/.

   Schema: ClassID, RepFamily, RepRows, Dim, Transformation, EpsForm,
   Variables, Chart, AnsatzDegree, Validated.

   "Chart" is an Association of a NEW kind, "TwoVariable": the earlier
   records carry the single-variable conic chart, and a consumer that
   assumed that shape must not silently accept this one.  The chart is
   the rationalization of the block's square root:

       97, 77:  v = x y,      w = (1-x)(1-y),   sqrtLambda = x - y,
                lambda = (1-v-w)^2 - 4 v w
       79:      v = -x y,     w = (1-x)(1-y),   sqrtQ      = x - y,
                Q      = (1+v-w)^2 + 4 v w

   "Inverse" is the branch x = (1+v-w+sqrtLambda)/2, y = (1+v-w-sqrtLambda)/2
   (for 79 read sqrtQ for sqrtLambda), with sqrtLambda an INERT symbol:
   it stands for a fixed branch of the square root and is not a rational
   function of (v,w), which is exactly why these classes need the chart.

   "Validated" is the measured result of ValidateCanonicalForm on the
   record built here, not an assertion.

   Arg 1 (optional): output ClassForms directory (default: repository). *)
root = "/home/maxzhang/factorization-and-loops";
R = root <> "/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical";
Edir = R <> "/HardClasses/EpsFormRoute";
out = If[Length[$ScriptCommandLine] >= 2 && $ScriptCommandLine[[2]] =!= "",
   $ScriptCommandLine[[2]], R <> "/ClassForms"];
Get[root <> "/Addon/Load/LoadFACET.wl"];
x = Symbol["Global`x"]; y = Symbol["Global`y"]; v = Symbol["Global`v"];
w = Symbol["Global`w"]; eps = Symbol["Global`eps"];
sqrtLambda = Symbol["Global`sqrtLambda"];
tog[m_] := Map[Together, m, {2}];
zeroM[m_] := AllTrue[Flatten[tog[m]], # === 0 &];
putAtomic[expr_, file_] := Module[{tmp = file <> ".tmp"}, Put[expr, tmp]; RenameFile[tmp, file, OverwriteTarget -> True]];
cls = Get[R <> "/BlockClasses/classes.wl"];

(* Inverse branch: 97/77 have x+y = 1+v-w, xy = v  ->  x,y = (1+v-w +- sqrtLambda)/2;
   79 has x+y = 1-v-w, xy = -v  ->  x,y = (1-v-w +- sqrtQ)/2  (discriminant = Q). *)
sqrtQ = Symbol["Global`sqrtQ"];
chartFor[cid_] := Module[{subst, rootSquare, sym, lin},
  subst = If[cid === 79, {v -> -x y, w -> (1 - x) (1 - y)}, {v -> x y, w -> (1 - x) (1 - y)}];
  rootSquare = If[cid === 79, (1 + v - w)^2 + 4 v w, (1 - v - w)^2 - 4 v w];
  sym = If[cid === 79, sqrtQ, sqrtLambda];
  lin = If[cid === 79, 1 - v - w, 1 + v - w];
  <|"Kind" -> "TwoVariable", "Subst" -> subst, "Root" -> x - y,
    "RootSquare" -> rootSquare,
    "Inverse" -> {x -> (lin + sym)/2, y -> (lin - sym)/2},
    "RootSymbol" -> sym, "Variables" -> {x, y}|>];

build[cid_, file_] := Module[{f, ent, chart, record, subst, ok1, ok2, ok3, valid},
  f = Get[Edir <> "/" <> file];
  ent = SelectFirst[cls, #["ClassID"] == cid &];
  chart = chartFor[cid];
  subst = chart["Subst"];
  (* chart self-consistency, measured, not assumed *)
  ok1 = Together[(chart["RootSquare"] /. subst) - chart["Root"]^2] === 0;
  ok2 = Together[({x, y} /. chart["Inverse"]) /. chart["RootSymbol"] -> chart["Root"] /. subst] === {x, y};
  Print["class ", cid, ": RootSquare pulls back to Root^2: ", ok1,
    ";  Inverse o Subst = identity on the stored branch: ", ok2];
  record = <|
    "ClassID" -> cid,
    "RepFamily" -> ent["RepFamily"],
    "RepRows" -> ent["RepRows"],
    "Dim" -> ent["Dim"],
    "Transformation" -> f["T"],
    "EpsForm" -> {f["Ax"], f["Ay"]},
    "Variables" -> {x, y},
    "Chart" -> chart,
    "AnsatzDegree" -> None,
    "Validated" -> False|>;
  valid = TrueQ[FeynFacet`ValidateCanonicalForm[record, "Variables" -> {x, y}, "Regulator" -> eps]];
  Print["class ", cid, ": ValidateCanonicalForm = ", valid];
  record["Validated"] = valid;
  putAtomic[record, out <> "/class" <> ToString[cid] <> ".wl"];
  Print[">>> wrote ", out <> "/class" <> ToString[cid] <> ".wl"];
  {cid, valid, ok1, ok2}];

res = {build[97, "c97_epsform_two_variable.wl"], build[77, "c77_epsform_two_variable.wl"]};
If[FileExistsQ[Edir <> "/c79_epsform_two_variable.wl"],
  AppendTo[res, build[79, "c79_epsform_two_variable.wl"]],
  Print["c79_epsform_two_variable.wl not present; class 79 record not written"]];
Print["summary {class, Validated, RootSquareOK, InverseOK}: ", res];
Print["DONE"];
