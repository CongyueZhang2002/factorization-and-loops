(* FactorFamilyRegulatorDependenceInFrame (Codex package bug report
   2026-08-22, CF300 (8,5)): a connection in a multiquadratic identity
   frame whose completed part uses one catalogued root is pulled back to
   that root's chart, factored there by a constant T(eps), and the
   constant is applied and verified in the source frame; a rational
   connection goes straight to the rational factorization; a root set
   without a joint catalogued chart is a typed stop; the factorization
   is idempotent. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
pass = 0; fail = 0;
check[label_, ok_] := (If[TrueQ[ok], pass++; Print["OK   ", label], fail++; Print["FAIL ", label]]);
x = Symbol["Global`x"]; y = Symbol["Global`y"]; eps = Symbol["Global`eps"];
v = Symbol["Global`v"]; w = Symbol["Global`w"];
lambda1[a_, b_] := (1 - a - b)^2 - 4 a b;
(* identity frame on (x, y) with two declared roots: sqrt(lambda1) (chart
   Kallen1) and sqrt(1 - 4 x y) (chart Bilinear115); no joint chart *)
frame = <|"Name" -> "TestMultiquadratic", "Kind" -> "TwoVariable",
  "CoefficientField" -> "Multiquadratic", "Variables" -> {x, y},
  "Subst" -> {v -> x, w -> y},
  "Roots" -> {<|"Root" -> Sqrt[lambda1[x, y]], "RootSquare" -> lambda1[v, w]|>,
    <|"Root" -> Sqrt[1 - 4 x y], "RootSquare" -> 1 - 4 v w|>}|>;
r1 = Sqrt[lambda1[x, y]]; r2 = Sqrt[1 - 4 x y];
dl[L_] := Map[Together, {D[Log[L], x], D[Log[L], y]}];
k1 = {{1, 0, 0}, {0, -1, 0}, {2, 0, 0}}; k2 = {{0, 1, 0}, {1, 0, 0}, {0, 0, 3}};
k3 = {{2, 0, 1}, {0, 0, 0}, {0, 1, -2}}; k4 = {{0, 0, 0}, {1, 0, 0}, {0, 2, 0}};
letters1 = {x, y, 1 - x - y, (1 - x - y + r1)/(1 - x - y - r1)};
canonical1 = Table[eps Sum[{k1, k2, k3, k4}[[a]] dl[letters1[[a]]][[mu]], {a, 4}], {mu, 2}];
t = {{1, eps, 0}, {0, 1 + 4 eps, 0}, {eps^2, 0, 1/(1 - 2 eps)}}; tInv = Inverse[t];
connection1 = Table[Map[Together, t . canonical1[[mu]] . tInv, {2}], {mu, 2}];
check["one-root input carries the root", ! FreeQ[connection1, Power[_, 1/2]]];
check["one-root input is not eps-factored", ! FeynFacet`Private`familyRegulatorFactoredQ[connection1[[1]], eps]];
{sec, f} = AbsoluteTiming[FeynFacet`FactorFamilyRegulatorDependenceInFrame[connection1, {x, y}, eps, frame]];
Print["one root: ", If[AssociationQ[f], KeyTake[f, {"Status", "Method", "Chart", "RootIndices", "Points"}], f], " (", Round[sec, 0.1], " s)"];
check["one root: status OK", AssociationQ[f] && f["Status"] === "OK"];
check["one root: chart Kallen1, root index 1", AssociationQ[f] && f["Chart"] === "Kallen1" && f["RootIndices"] === {1}];
If[AssociationQ[f] && f["Status"] === "OK",
  check["one root: source-frame connection eps-factored",
    FeynFacet`Private`familyRegulatorFactoredQ[f["Connection"][[1]], eps] && FeynFacet`Private`familyRegulatorFactoredQ[f["Connection"][[2]], eps]];
  check["one root: T constant in the variables, eps-dependent", FreeQ[f["Transformation"], x | y] && ! FreeQ[f["Transformation"], eps]];
  check["one root: inverse exact", And @@ Flatten[Map[PossibleZeroQ, Together[f["Transformation"] . f["Inverse"] - IdentityMatrix[3]], {2}]]];
  check["one root: gauge identity in the source frame", And @@ Flatten[Table[
    PossibleZeroQ[Together[(f["Inverse"] . connection1[[mu]] . f["Transformation"])[[i, j]] - f["Connection"][[mu, i, j]]]], {mu, 2}, {i, 3}, {j, 3}]]];
  g = FeynFacet`FactorFamilyRegulatorDependenceInFrame[f["Connection"], {x, y}, eps, frame];
  check["one root: idempotent (AlreadyEpsFactored)", AssociationQ[g] && g["Status"] === "AlreadyEpsFactored"]];
(* rational connection: straight to the rational factorization *)
letters0 = {x, y, 1 - x - y};
canonical0 = Table[eps Sum[{k1, k2, k3}[[a]] dl[letters0[[a]]][[mu]], {a, 3}], {mu, 2}];
connection0 = Table[Map[Together, t . canonical0[[mu]] . tInv, {2}], {mu, 2}];
f0 = FeynFacet`FactorFamilyRegulatorDependenceInFrame[connection0, {x, y}, eps, frame];
check["rational: status OK via the rational path", AssociationQ[f0] && f0["Status"] === "OK" && f0["RootIndices"] === {} && f0["Method"] === "ExactRationalSamples"];
(* Two roots without a joint chart.  BEHAVIOR CHANGE 2026-08-25: this
   used to be the typed stop "NoRationalChart".  Since
   FactorFamilyRegulatorDependenceMultiquadratic exists, a root set with
   no joint rational chart is ATTEMPTED in the graded algebra first and
   the typed stop is what remains when THAT route refuses (the refusal
   case is covered by Tests/Multiquadratic/t_multiquadratic_regulator_factor.wls).  Here
   the connection is a planted constant conjugation of a clean eps-form,
   so the graded route factors it. *)
check["catalog has no joint chart for {lambda1, 1 - 4 v w}", MissingQ[FeynFacet`LookupCataloguedRationalizingParametrizationForRoots[{lambda1[v, w], 1 - 4 v w}, {v, w}]]];
letters2 = {x, y, 1 - x - y, (1 - x - y + r1)/(1 - x - y - r1), (1 + r2)/(1 - r2)};
canonical2 = Table[eps Sum[{k1, k2, k3, k4, k1}[[a]] dl[letters2[[a]]][[mu]], {a, 5}], {mu, 2}];
connection2 = Table[Map[Together, t . canonical2[[mu]] . tInv, {2}], {mu, 2}];
f2 = FeynFacet`FactorFamilyRegulatorDependenceInFrame[connection2, {x, y}, eps, frame];
Print["two roots: ", If[AssociationQ[f2], KeyTake[f2, {"Status", "Method", "Chart", "RootIndices", "Rank"}], f2]];
check["two roots without a joint chart: factored in the graded algebra",
  AssociationQ[f2] && f2["Status"] === "OK" && Sort[f2["RootIndices"]] === {1, 2} &&
    f2["Chart"] === None && StringQ[f2["Method"]] &&
    StringMatchQ[f2["Method"], "MultiquadraticGradedAlgebra/*"] && f2["Rank"] === 2];
If[AssociationQ[f2] && f2["Status"] === "OK",
  check["two roots: the exact grade-wise statement is made",
    TrueQ[f2["ExactEpsFactorization"]] && TrueQ[f2["ExactInverse"]]];
  check["two roots: T is constant in the variables",
    FreeQ[f2["Transformation"], x | y] && ! FreeQ[f2["Transformation"], eps]]];
Print["t_family_regulator_factor_in_frame: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
