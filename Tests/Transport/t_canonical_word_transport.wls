#!/usr/bin/env wolframscript
(* The compiled word core must reproduce the mature block-wise recursion
   exactly while keeping boundary constants as sparse integer columns until
   final materialization.  This suite is intentionally a small algebraic
   anchor; large-family performance belongs to campaign diagnostics. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "FeynFacet", "FeynFacet.m"}]];

assembly = <|
  "Family" -> "CompiledWordToy", "Blocks" -> {{1}, {2}},
  "Ranges" -> {{1}, {2}}, "N" -> 2,
  "Forms" -> ConstantArray[<|"Type" -> "EpsForm"|>, 2],
  "TInverse" -> ConstantArray[{{1}}, 2]|>;
ahat = {{eps/(tau - 1), 0},
  {eps/(tau - 2), eps/(tau - 3)}};
kmin = {0, 0};
budget = FeynFacet`Private`masterTransportDepthBudget[
  assembly, ahat, 2, eps];
FeynFacet`Private`masterTransportSupportCacheClear[];
exact = FeynFacet`Private`masterTransportExactDepth[
  assembly, ahat, <|"Demands" -> {2, 2}, "KMin" -> kmin|>,
  eps, True];
legacy = FeynFacet`Private`masterTransportBlockwiseSolve[
  assembly, ahat, budget, kmin, 2, 0, tau, eps, {x, y},
  {0, 0}, {x, y}, "Certify" -> True, "PhiCrossCheck" -> False,
  "ConstantDepth" -> "PerBlockNeed", "ExactDepth" -> exact];
compiled = FeynFacet`Private`masterTransportCanonicalWordSolve[
  assembly, ahat, budget, kmin, 2, tau, eps,
  "ConstantDepth" -> "PerBlockNeed", "ExactDepth" -> exact];

orders = Intersection[Keys[legacy["Solution", "F"]],
  Keys[compiled["Solution", "F"]]];
same = AllTrue[Flatten@Table[
    TrueQ[Together[#] === 0] & /@
      (legacy["Solution", "F"][k] - compiled["Solution", "F"][k]),
    {k, orders}], TrueQ];

FTAssert["CW1 the compiled epsilon-form core reaches every requested order",
  compiled["Status"] === "OK" &&
    compiled["Route"] === "CompiledSparseWord" &&
    orders === {0, 1, 2} &&
    TrueQ[compiled["Certificate", "AllZero"]] &&
    compiled["Certificate", "Route"] === "InternedWordModular"];
FTAssert["CW2 sparse boundary-column recursion materializes exactly the mature block-wise GPL result",
  same];
FTAssert["CW3 constants are columns during recursion and appear symbolically only in the final F boundary",
  Length[compiled["IR", "BoundaryColumns"]] === 6 &&
    AllTrue[Values[compiled["IR", "States"]],
      AllTrue[Values[#], Head[#] === SparseArray &] &]];
FTAssert["CW4 words are interned cons cells rather than copied letter lists",
  Length[compiled["IR", "WordHead"]] === 7 &&
    AllTrue[Values[compiled["IR", "WordTail"]], IntegerQ]];

deficitAhat = ReplacePart[ahat, {2, 1} -> 1/(eps (tau - 2))];
deficitBudget = FeynFacet`Private`masterTransportDepthBudget[
  assembly, deficitAhat, 1, eps];
FeynFacet`Private`masterTransportSupportCacheClear[];
deficitDepth = FeynFacet`Private`masterTransportExactDepth[
  assembly, deficitAhat,
  <|"Demands" -> {1, 1}, "KMin" -> kmin|>, eps, True];
deficit = FeynFacet`Private`masterTransportCanonicalWordSolve[
  assembly, deficitAhat, deficitBudget, kmin, 1, tau, eps,
  "ConstantDepth" -> "PerBlockNeed", "ExactDepth" -> deficitDepth,
  "Materialize" -> False];
deficitValuation = FeynFacet`Private`masterTransportCWIdentityValuation[
  deficit["IR"], 0];
deficitPhysical = FeynFacet`Private`masterTransportCWMaterializeIR[
  deficitValuation["IR"], tau, 1];
FTAssert["CW5 identity-gauge valuation is imposed on sparse boundary columns before GPL materialization",
  deficitValuation["Status"] === "OK" &&
    TrueQ[deficitValuation["AssertionOK"]] &&
    deficitValuation["FixedConstantCount"] === 1 &&
    FreeQ[deficitPhysical["F"], TransportConstant[1, 0, 1]]];

generalAhat = ReplacePart[ahat, {2, 1} -> 1/(tau - 2)^2];
generalBudget = FeynFacet`Private`masterTransportDepthBudget[
  assembly, generalAhat, 2, eps];
general = FeynFacet`Private`masterTransportCanonicalWordSolve[
  assembly, generalAhat, generalBudget, kmin, 2, tau, eps,
  "ConstantDepth" -> "PerBlockNeed", "ExactDepth" -> None];
FTAssert["CW6 a non-dlog kernel requests the general-integrator fallback by name",
  general["Status"] === "CompiledWordFallbackRequired" &&
    general["Reason"] === "NonDlogCoupling"];

FeynFacet`Private`masterTransportSupportCacheClear[];
FTReport[];
