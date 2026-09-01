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

precompiled = FeynFacet`Private`masterTransportCanonicalWordSolve[
  assembly, None, budget, kmin, 2, tau, eps,
  "ConstantDepth" -> "PerBlockNeed", "ExactDepth" -> exact,
  "PrecompiledCouplings" -> compiled["IR", "Couplings"],
  "PrecompiledLetters" -> compiled["IR", "Letters"]];
samePrecompiled = AllTrue[Flatten@Table[
    TrueQ[Together[#] === 0] & /@
      (compiled["Solution", "F"][k] -
        precompiled["Solution", "F"][k]),
    {k, orders}], TrueQ];
FTAssert["CW7 an accepted residue provider bypasses symbolic Ahat decomposition without changing any GPL coefficient",
  precompiled["Status"] === "OK" && samePrecompiled &&
    precompiled["CouplingRoute"] === "PrecompiledResidueProvider"];

chen = FeynFacet`Private`masterTransportCanonicalChenOperator[
  assembly, compiled["IR", "Couplings"], compiled["IR", "Letters"],
  <|"Low" -> exact["Lowest"], "Top" -> exact["NMax"]|>,
  kmin, budget["Need"]];
chenOrder2 = FeynFacet`Private`masterTransportCanonicalChenCoefficient[
  chen, 2, "MaxTerms" -> 100];
chenConstants = (TransportConstant @@ #) & /@ chen["BoundaryColumns"];
chenF2 = Total[Map[
    Function[term,
      (Normal[term["Coefficient"]] . chenConstants) *
        If[term["Word"] === {}, 1,
          TransportWord[chen["Letters"][[term["Word"]]], tau]]],
    chenOrder2["Terms"]]];
FTAssert["CW8 the lazy Chen residue-product operator materializes a requested GPL coefficient exactly without constructing unrelated words",
  chen["Status"] === "CanonicalGPLChenOperatorV1" &&
    chenOrder2["Status"] === "OK" &&
    AllTrue[compiled["Solution", "F"][2] - chenF2,
      TrueQ[Together[#] === 0] &]];

scalarAssembly = <|"Family" -> "SourceGaugeToy", "Blocks" -> {{1}},
  "Ranges" -> {{1}}, "N" -> 1|>;
scalarCouplings = <|{1, 1} -> <|1 -> <|
  1 -> SparseArray[{{1, 1} -> 2}, {1, 1}]|>|>|>;
scalarChen = FeynFacet`Private`masterTransportCanonicalChenOperator[
  scalarAssembly, scalarCouplings, {7},
  <|"Low" -> {0}, "Top" -> {0}|>, {0}, {0}];
scalarSource = FeynFacet`Private`masterTransportCanonicalSourceOperator[
  scalarChen,
  <|-1 -> SparseArray[{{1, 1} -> 1}, {1, 1}]|>,
  <|1 -> SparseArray[{{1, 1} -> 1}, {1, 1}]|>,
  {{0, 1}}];
scalarSource0 =
  FeynFacet`Private`masterTransportCanonicalSourceCoefficient[
    scalarSource, 0];
scalarSource2 =
  FeynFacet`Private`masterTransportCanonicalSourceCoefficient[
    scalarSource, 2];
maskedCanonical2 =
  FeynFacet`Private`masterTransportCanonicalChenWordCoefficient[
    scalarChen, {1, 1}, 0, 2];
FTAssert["CW9 source-gauge composition uses raw residues beyond the earlier canonical demand mask",
  scalarSource2["Status"] === "OK" &&
    scalarSource2["TermCount"] === 1 &&
    scalarSource2["Terms"][[1, "Word"]] === {1, 1} &&
    Normal[scalarSource2["Terms"][[1, "Coefficient"]]] === {{4}} &&
    ! FeynFacet`Private`masterTransportCWNonzeroSparseQ[maskedCanonical2]];
scalarSourceExpression =
  FeynFacet`Private`masterTransportCanonicalSourceExpression[
    scalarSource, scalarSource0, tau];
FTAssert["CW10 a physical source-boundary embedding reproduces the source datum at the base point",
  scalarSourceExpression["Status"] === "OK" &&
    scalarSourceExpression["Expression"] ===
      {FeynFacet`Private`SourceBoundaryConstant[0, 1]}];

layeredSource =
  FeynFacet`Private`masterTransportCanonicalSourceOperator[
    scalarChen,
    <|-1 -> SparseArray[{{1, 1} -> 1}, {1, 1}]|>,
    <|0 -> SparseArray[{{1, 1} -> 3}, {1, 1}],
      1 -> SparseArray[{{1, 1} -> 5}, {1, 1}],
      2 -> SparseArray[{{1, 1} -> 7}, {1, 1}]|>,
    {{0, 1}}];
layeredSource1 =
  FeynFacet`Private`masterTransportCanonicalSourceCoefficient[
    layeredSource, 1];
FTAssert["CW11 one residue-prefix tree serves every compatible boundary order without changing the coefficients",
  layeredSource1["Status"] === "OK" &&
    layeredSource1["TraversalRoute"] ===
      "GaugeFactoredConstantResidues" &&
    layeredSource1["VisitedPrefixes"] === 2 &&
    layeredSource1["Terms"][[All, "Word"]] === {{}, {1}, {1, 1}} &&
    (Normal[#1["Coefficient"]] & /@ layeredSource1["Terms"]) ===
      {{{7}}, {{10}}, {{12}}}];

FeynFacet`Private`masterTransportSupportCacheClear[];
FTReport[];
