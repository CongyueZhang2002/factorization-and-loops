#!/usr/bin/env wolframscript
(* Variation-of-constants solution of a block whose incoming connection is
   rational in eps, tested on a synthetic 2x2 block over a
   2-master dlog source with poles at -1, 2 and the quadratic factor u^2 + 1.
   Reference: an independent characteristic-zero computation of the same
   recurrence (Series in eps, Apart, Integrate) -- the K residues on the pole
   alphabet must be SameQ with the reconstructed ones, and the requested
   iterated-integral coefficient terms
   coefficients built from them must be SameQ.  Then the typed refusals. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
u = Symbol["Global`layerU"]; eps = Symbol["Global`eps"];
q = u^2 + 1;
(* the second pole is the NON-INTEGER rational 3/4 (CF303's factors at p = 9/8 have such coefficients) *)
source = <|"Dimension" -> 2,
  "Letters" -> {{"GPLPole", -1}, {"GPLPole", 3/4}},
  "Residues" -> {{{0, 1}, {0, 0}}, {{1, 0}, {0, -1}}},
  "BoundarySelectors" -> <|0 -> IdentityMatrix[2], 1 -> {{0, 1}, {0, 0}}|>|>;
diagonal = {{{"GPLPole", 3/4}, {{1, 0}, {0, 2}}}, {{"GPLFactor", q, 0}, {{0, 1}, {1, 0}}}};
incoming = {
  <|"Row" -> 1, "Column" -> 1, "Coefficient" -> (1 + 3 eps + eps^2)/(eps^2 (1 + eps)), "Letter" -> {"GPLFactor", q, 1}|>,
  <|"Row" -> 1, "Column" -> 2, "Coefficient" -> (2 + eps)/eps^2 1/(u + 1), "Letter" -> {"GPLPole", -1}|>,
  <|"Row" -> 2, "Column" -> 1, "Coefficient" -> (eps + 2)/eps (u^2 + 3)/q, "Letter" -> {"GPLFactor", q, 0}|>,
  <|"Row" -> 2, "Column" -> 2, "Coefficient" -> 1/(eps (1 - 2 eps)) u/(u - 3/4), "Letter" -> {"GPLPole", -1}|>};
layer = <|"Rows" -> {44, 45}, "PathVariable" -> u, "Regulator" -> eps, "BasePoint" -> 1/2, "PathEndpoint" -> 1/4,
  "Diagonal" -> diagonal, "Incoming" -> incoming,
  "TargetBoundarySelectors" -> <|0 -> IdentityMatrix[2], 1 -> {{1, 1}, {0, 1}}|>|>;
demand = <|"RequestedOutputPairs" -> {{-2, 1}, {-2, 2}, {-1, 1}, {-1, 2}, {0, 1}, {0, 2}}|>;
{seconds, result} = AbsoluteTiming[SolveRationalEpsilonDependentBlockByVariationOfConstants[source, layer, demand, "PrimeCount" -> 3]];
Print["route: ", Lookup[result, "Status", None], " in ", Round[seconds, 0.01], " s; window ", Lookup[result, "Window", None], "; residue keys ", Length[Lookup[result, "KResidues", <||>]], "; comparisons ", Lookup[Lookup[result, "Certificate", <||>], "ResidueComparisons", None]];
FTAssert["the synthetic rational-epsilon-dependent block is solved and accepted by the public predicate",
  result["Status"] === "RationalEpsilonDependentBlockSolutionAccepted" && RationalEpsilonDependentBlockSolutionQ[result] && result["Window"] === {-2, 0}];
FTAssert["every reconstructed residue is a 2x2 matrix over the 2-master source (the layer shape is read from the matrices, not from an expression's term count)",
  AllTrue[Values[result["KResidues"]], Dimensions[#] === {2, 2} &] && Length[result["KResidues"]] === 10];
(* a wider source (3 masters) with the same layer: the third column declared zero *)
source3 = <|"Dimension" -> 3, "Letters" -> source["Letters"], "Residues" -> (ArrayFlatten[{{#, {{0}, {0}}}, {{{0, 0}}, {{1}}}}] & /@ source["Residues"]),
  "BoundarySelectors" -> <|0 -> IdentityMatrix[3], 1 -> {{0, 1, 0}, {0, 0, 0}, {0, 0, 1}}|>|>;
result3 = SolveRationalEpsilonDependentBlockByVariationOfConstants[source3, Join[layer, <|"ZeroColumns" -> {3}|>], demand, "PrimeCount" -> 3];
FTAssert["a 3-master source with the third column declared zero gives 2x3 residues whose first two columns equal the 2-master result",
  result3["Status"] === "RationalEpsilonDependentBlockSolutionAccepted" &&
    AllTrue[Values[result3["KResidues"]], Dimensions[#] === {2, 3} &] &&
    And @@ Table[result3["KResidues"][key][[All, 1 ;; 2]] === result["KResidues"][key], {key, Keys[result["KResidues"]]}]];

(* ---- independent characteristic-zero reference ---- *)
letterForm[{"GPLPole", c_}] := 1/(u - c); letterForm[{"GPLFactor", qq_, k_}] := u^k/qq;
factors = {u + 1, u - 3/4, q};
bOrder[order_] := Table[Sum[If[e["Row"] === i && e["Column"] === j,
    SeriesCoefficient[e["Coefficient"], {eps, 0, order}] letterForm[e["Letter"]], 0], {e, incoming}], {i, 2}, {j, 2}];
d1[f_] := Sum[letterForm[dl[[1]]] (dl[[2]] . f), {dl, diagonal}];
(* Hermite reduction over Q, independent of the route's linear-algebra
   (Horowitz-Ostrogradsky) version: partial fractions by Apart, then for a
   term N/Q^k (Q irreducible, k >= 2) the extended-gcd step
   N = A Q + B Q'  =>  N/Q^k = d[-B/((k-1) Q^(k-1))] + (A + B'/(k-1))/Q^(k-1),
   repeated down to k = 1; the simple-pole remainder on Q is the residue. *)
hermiteQ[f_] := Module[{a = Apart[Together[f], u], terms, exact = 0, residues = <||>, reduceTerm},
  terms = If[Head[a] === Plus, List @@ a, {a}]; terms = DeleteCases[terms, 0];
  reduceTerm[term_] := Module[{tt = Together[term], num, den, fl, Q, k, g, s, c, A, B, e = 0, rem, quot},
    If[PolynomialQ[tt, u], exact += Integrate[tt, u]; Return[Null]];
    num = Numerator[tt]; den = Denominator[tt];
    fl = Select[FactorList[den], ! FreeQ[#[[1]], u] &];
    If[Length[fl] =!= 1, Print["reference: unexpected partial-fraction term ", InputForm[tt]]; Return[$Failed]];
    {Q, k} = fl[[1]]; Q = Expand[Q/Coefficient[Q, u, Exponent[Q, u]]];
    num = Together[num/Together[den/Q^k]];   (* the constant factor of the denominator *)
    While[k > 1,
      {g, {s, c}} = PolynomialExtendedGCD[Q, D[Q, u], u];
      B = PolynomialRemainder[Together[num c/g], Q, u];
      A = PolynomialQuotient[Together[num - B D[Q, u]], Q, u];
      e += -B/((k - 1) Q^(k - 1));
      num = Together[A + D[B, u]/(k - 1)]; k--];
    quot = PolynomialQuotient[num, Q, u]; rem = PolynomialRemainder[num, Q, u];
    exact += e + Integrate[quot, u];
    residues[Q] = Together[Lookup[residues, Q, 0] + rem]];
  Scan[reduceTerm, terms];
  <|"Exact" -> Together[exact], "Residues" -> Association@KeyValueMap[#1 -> PadRight[CoefficientList[Together[#2], u], Exponent[#1, u], 0] &, residues]|>];
hPrev = ConstantArray[0, {2, 2}]; kRef = <||>; hRef = <||>;
Do[
  omega = bOrder[order] + d1[hPrev] - Sum[hPrev . (sl[[2]] letterForm[sl[[1]]]), {sl, Transpose[{source["Letters"], source["Residues"]}]}];
  omega = Map[Together, omega, {2}];
  h = ConstantArray[0, {2, 2}];
  Do[With[{hr = hermiteQ[omega[[i, j]]]},
      h[[i, j]] = Together[hr["Exact"] - (hr["Exact"] /. u -> 1/2)];
      KeyValueMap[Function[{factor, list}, Do[Module[{matrix = Lookup[kRef, Key[{order, factor, kk - 1}], ConstantArray[0, {2, 2}]]},
          matrix[[i, j]] = list[[kk]]; kRef[{order, factor, kk - 1}] = matrix], {kk, Length[list]}]], hr["Residues"]]],
    {i, 2}, {j, 2}];
  hPrev = h; hRef[order] = h,
  {order, -2, 0}];
kRef = KeySelect[kRef, True &];
kRef = Association@KeyValueMap[#1 -> (Together /@ #2) &, kRef];
kRef = Select[kRef, ! AllTrue[Flatten[#], # === 0 &] &];
kRoute = Select[result["KResidues"], ! AllTrue[Flatten[#], # === 0 &] &];
Print["reference residue keys ", Sort[Keys[kRef]]];
Print["route residue keys     ", Sort[Keys[kRoute]]];
Do[If[Lookup[kRef, Key[key], None] =!= Lookup[kRoute, Key[key], None],
  Print["DIFF ", InputForm[key], ": reference ", InputForm[Lookup[kRef, Key[key], None]], " route ", InputForm[Lookup[kRoute, Key[key], None]]]],
  {key, Union[Keys[kRef], Keys[kRoute]]}];
FTAssert["the reconstructed K residues are SameQ with the characteristic-zero reference on every (order, factor, power)",
  Sort[Keys[kRef]] === Sort[Keys[kRoute]] && And @@ Table[kRef[key] === kRoute[key], {key, Keys[kRef]}]];
(* A symbolic path endpoint needs the rational off-diagonal
   basis-transformation block H(u), not a numerical endpoint sample. It is
   reconstructed coefficientwise from the same
   modular recurrence and checked at a held-out finite-field point. *)
pEnd = Symbol["Global`layerEndpoint"];
symbolicLayer = Join[layer, <|"PathEndpoint" -> pEnd|>];
symbolic = SolveRationalEpsilonDependentBlockByVariationOfConstants[source, symbolicLayer, demand,
  "PrimeCount" -> 3, "IteratedIntegralCoefficientRepresentation" -> "LazyCoefficientOperator"];
symbolicOperator = ConstructRationalEpsilonDependentBlockIteratedIntegralCoefficientOperator[source, symbolicLayer,
  symbolic];
FTAssert["a symbolic path endpoint reconstructs the complete rational off-diagonal basis-transformation block and feeds the lazy operator",
  symbolic["Status"] === "RationalEpsilonDependentBlockSolutionAccepted" &&
    symbolic["OffDiagonalTransformationBlockStatus"] === "OffDiagonalTransformationBlockRationalFunctionReconstructed" &&
    symbolic["Certificate"]["OffDiagonalTransformationBlockRepresentation"] === "RationalFunction" &&
    symbolic["Certificate"]["OffDiagonalTransformationBlockMismatches"] === 0 &&
    And @@ Flatten@Table[
      Together[symbolic["OffDiagonalBasisTransformationBlockAtPathEndpoint"][order][[i, j]] -
        (hRef[order][[i, j]] /. u -> pEnd)] === 0,
      {order, Keys[hRef]}, {i, 2}, {j, 2}] &&
    RationalEpsilonDependentBlockSolutionQ[symbolic] &&
    VerifyRationalEpsilonDependentBlockSolution[symbolic, source,
      symbolicLayer, demand] &&
    RationalEpsilonDependentBlockIteratedIntegralCoefficientOperatorQ[symbolicOperator]];
(* The modular H images must agree with the exact reference at the base and
   at a probe point. *)
hRefProbe = Map[Together, hPrev, {2}];
With[{p = First[Keys[result["OffDiagonalTransformationBlockFiniteFieldImages"]]]}, With[{img = result["OffDiagonalTransformationBlockFiniteFieldImages"][p][0]},
  Print["off-diagonal basis-transformation diagnostic at u = 3, prime ", p, ": image ", InputForm[Table[Mod[(img[[i, j, 1]] /. u -> 3) PowerMod[(img[[i, j, 2]] /. u -> 3), -1, p], p], {i, 2}, {j, 2}]],
    " reference ", InputForm[Table[With[{v = hRefProbe[[i, j]] /. u -> 3}, Mod[Numerator[v] PowerMod[Denominator[v], -1, p], p]], {i, 2}, {j, 2}]],
    " image keys ", Keys[result["OffDiagonalTransformationBlockFiniteFieldImages"][p]], " image entry short ", InputForm[Short[img[[2, 1]], 2]]]]];
FTAssert["the last-order off-diagonal basis-transformation image agrees with the exact reference at u = 3 modulo every prime used",
  And @@ Table[With[{p = key, img = result["OffDiagonalTransformationBlockFiniteFieldImages"][key][0]},
    And @@ Flatten[Table[Mod[(img[[i, j, 1]] /. u -> 3) - Numerator[hRefProbe[[i, j]] /. u -> 3] PowerMod[Denominator[hRefProbe[[i, j]] /. u -> 3], -1, p] (img[[i, j, 2]] /. u -> 3), p] === 0, {i, 2}, {j, 2}]]],
    {key, Keys[result["OffDiagonalTransformationBlockFiniteFieldImages"]]}]];
(* Requested coefficient terms: rebuild them from the reference residues with
   the solver's own iterated-integral sequence grammar. *)
wordsRef = Association@Table[pair -> FeynFacet`Private`rationalEpsilonDependentBlockIteratedIntegralCoefficientTerms[pair[[1]], pair[[2]], diagonal, kRef, source,
    <|0 -> (Join[#, {0, 0}] & /@ IdentityMatrix[2]), 1 -> (Join[{0, 0}, #] & /@ {{1, 1}, {0, 1}})|>, 2, 4, 2,
    Infinity, Automatic, False,
    result["OffDiagonalBasisTransformationBlockAtPathEndpoint"]],
  {pair, demand["RequestedOutputPairs"]}];
FTAssert["the requested iterated-integral coefficients are SameQ with those built from the reference residues, and nonempty",
  And @@ Table[result["IteratedIntegralCoefficientTermsByRequestedOutput"][pair] === wordsRef[pair], {pair, demand["RequestedOutputPairs"]}] &&
    Total[Length /@ Values[result["IteratedIntegralCoefficientTermsByRequestedOutput"]]] > 0];
explicitOperator =
  ConstructRationalEpsilonDependentBlockIteratedIntegralCoefficientOperator[
    source, layer, result];
explicitCoefficientMap[pair_] := Module[
  {terms = result[
      "IteratedIntegralCoefficientTermsByRequestedOutput"][pair],
   coefficientMap},
  coefficientMap = If[terms === {}, <||>, Merge[
    (Association[#1["IteratedIntegralLetterSequence"] ->
        SparseArray[{#1["IteratedIntegralCoefficientVector"]}]] &) /@
      terms, SparseArray[Total[#1]] &]];
  Select[coefficientMap,
    Length[SparseArray[#1]["NonzeroPositions"]] > 0 &]
];
lazyCoefficientMaps = Association@Table[pair -> With[
    {built =
      ConstructRationalEpsilonDependentBlockIteratedIntegralCoefficientMap[
        explicitOperator, pair]},
    If[Lookup[built, "Status", None] ===
        "RationalEpsilonDependentBlockIteratedIntegralCoefficientMapConstructed",
      built["IteratedIntegralCoefficientMap"], built]],
  {pair, demand["RequestedOutputPairs"]}];
coefficientMapsSameQ[left_Association, right_Association] :=
  Sort[Keys[left]] === Sort[Keys[right]] &&
    And @@ Table[
      Normal[Lookup[left, Key[sequence]]] ===
        Normal[Lookup[right, Key[sequence]]],
      {sequence, Keys[left]}];
FTAssert["explicit and lazy coefficient representations agree for every requested output when the off-diagonal basis-transformation block is nonzero",
  RationalEpsilonDependentBlockIteratedIntegralCoefficientOperatorQ[
    explicitOperator] &&
    Cases[Flatten[Values[
        result["IteratedIntegralCoefficientTermsByRequestedOutput"]], 1],
      term_Association /;
        Lookup[term, "ContributionType", None] ===
          "OffDiagonalTransformationAtPathEndpoint"] =!= {} &&
    And @@ Table[
      AssociationQ[lazyCoefficientMaps[pair]] &&
        coefficientMapsSameQ[explicitCoefficientMap[pair],
          lazyCoefficientMaps[pair]],
      {pair, demand["RequestedOutputPairs"]}]];
Print["iterated-integral coefficient terms per requested output: ",
  Length /@ result["IteratedIntegralCoefficientTermsByRequestedOutput"]];
With[{cw = SolveRationalEpsilonDependentBlockByVariationOfConstants[source, layer, demand, "MaximumIteratedIntegralCoefficientTerms" -> 3], cg = SolveRationalEpsilonDependentBlockByVariationOfConstants[source, layer, demand, "MaximumWeight" -> 1]},
  Print["cap diagnostic: counts ", Values[Length /@ result["IteratedIntegralCoefficientTermsByRequestedOutput"]], "; MaximumIteratedIntegralCoefficientTerms 3 -> ", cw["Status"], " predicate ", RationalEpsilonDependentBlockSolutionQ[cw],
    "; MaximumWeight 1 -> ", cg["Status"], " needed ", cg["NeededWeight"], " dropped ", cg["DroppedCombinations"], " predicate ", RationalEpsilonDependentBlockSolutionQ[cg]]];
FTAssert["term and weight caps are typed refusals without changing an uncapped coefficient enumeration",
  result["IteratedIntegralCoefficientTermsByRequestedOutput"] === wordsRef &&
    With[{capped = SolveRationalEpsilonDependentBlockByVariationOfConstants[source, layer, demand, "MaximumIteratedIntegralCoefficientTerms" -> 3]},
      capped["Status"] === "IteratedIntegralCoefficientTermEnumerationCapped" && ! RationalEpsilonDependentBlockSolutionQ[capped]] &&
    With[{capped = SolveRationalEpsilonDependentBlockByVariationOfConstants[source, layer, demand, "MaximumWeight" -> 1]},
      capped["Status"] === "IteratedIntegralWeightCapReached" && capped["NeededWeight"] === 2 && capped["DroppedCombinations"] > 0 &&
        ! RationalEpsilonDependentBlockSolutionQ[capped]]];
(* ---- typed refusals ---- *)
FTAssert["a curve letter without a declared curve is refused typed",
  SolveRationalEpsilonDependentBlockByVariationOfConstants[source, Join[layer, <|"Incoming" -> Append[incoming, <|"Row" -> 1, "Column" -> 1, "Coefficient" -> 1/eps, "Letter" -> {"E4Pole", 3}|>]|>], demand]["Status"] === "CurveDeclarationRequired"];
FTAssert["a curve letter with a declared square-free quartic is accepted on the exact path-free route",
  With[{r = SolveRationalEpsilonDependentBlockByVariationOfConstants[source,
      Join[layer, <|"Curve" -> u^4 + 1,
        "Incoming" -> {
          <|"Row" -> 1, "Column" -> 1, "Coefficient" -> 1/eps,
            "Letter" -> {"E4Pole", 3}|>,
          <|"Row" -> 1, "Column" -> 2, "Coefficient" -> 1,
            "Letter" -> {"GPLPole", -1}|>}|>], demand,
      "IteratedIntegralCoefficientRepresentation" -> "LazyCoefficientOperator"]},
    r["Status"] === "RationalEpsilonDependentBlockSolutionAccepted" &&
      r["CurveChannel"] && r["Certificate"]["VariationOfConstantsMethod"] === "ExactDLogDecomposition"]];
FTAssert["an algebraic pole position is refused typed (declare the conjugate pair as a GPLFactor letter)",
  With[{r = SolveRationalEpsilonDependentBlockByVariationOfConstants[source, Join[layer, <|"Incoming" -> Append[incoming, <|"Row" -> 1, "Column" -> 1, "Coefficient" -> 1/eps, "Letter" -> {"GPLPole", Sqrt[5]}|>]|>], demand]},
    r["Status"] === "AlgebraicPoleNotAdmitted" && r["Label"] === {"GPLPole", Sqrt[5]}]];
FTAssert["an unknown letter head is refused typed with its label",
  With[{r = SolveRationalEpsilonDependentBlockByVariationOfConstants[source, Join[layer, <|"Incoming" -> Append[incoming, <|"Row" -> 1, "Column" -> 1, "Coefficient" -> 1/eps, "Letter" -> {"Mystery", 3}|>]|>], demand]},
    r["Status"] === "AlphabetLetterNotAdmitted" && r["Label"] === {"Mystery", 3}]];
FTAssert["an incoming coefficient not rational in eps is refused typed",
  SolveRationalEpsilonDependentBlockByVariationOfConstants[source, Join[layer, <|"Incoming" -> Append[incoming, <|"Row" -> 1, "Column" -> 1, "Coefficient" -> Sqrt[eps]/eps, "Letter" -> {"GPLPole", 3/4}|>]|>], demand]["Status"] === "IncomingNotRationalInEpsilon"];
FTAssert["a source column with no incoming entry and no zero declaration is a typed lower-block exception",
  With[{r = SolveRationalEpsilonDependentBlockByVariationOfConstants[source, Join[layer, <|"Incoming" -> Select[incoming, #["Column"] === 1 &]|>], demand]},
    r["Status"] === "LowerBlockExceptionRequired" && r["Columns"] === {2}] &&
  SolveRationalEpsilonDependentBlockByVariationOfConstants[source, Join[layer, <|"Incoming" -> Select[incoming, #["Column"] === 1 &], "ZeroColumns" -> {2}|>], demand]["Status"] === "RationalEpsilonDependentBlockSolutionAccepted"];
FTAssert["an unspecialized parameter in a coefficient is refused typed",
  With[{r = SolveRationalEpsilonDependentBlockByVariationOfConstants[source, Join[layer, <|"Incoming" -> Append[incoming, <|"Row" -> 1, "Column" -> 1, "Coefficient" -> Symbol["Global`layerP"]/eps, "Letter" -> {"GPLPole", 3/4}|>]|>], demand]},
    r["Status"] === "PathParameterNotSpecialized" && r["Symbols"] === {Symbol["Global`layerP"]}]];
FTAssert["a residue at a pole outside the alphabet cannot arise from declared letters and coefficients; a malformed letter is refused",
  SolveRationalEpsilonDependentBlockByVariationOfConstants[source, Join[layer, <|"Diagonal" -> Append[diagonal, {{"GPLFactor", (u - 1)^2, 0}, IdentityMatrix[2]}]|>], demand]["Status"] === "AlphabetLetterNotAdmitted"];
(* stage 4: a layer whose incoming coefficients are path-free takes the exact
   direct route; forced through the sealed modular circuit it must give the
   same residues and words (SameQ) *)
dlogIncoming = {
  <|"Row" -> 1, "Column" -> 1, "Coefficient" -> (1 + 3 eps + eps^2)/(eps^2 (1 + eps)), "Letter" -> {"GPLFactor", q, 1}|>,
  <|"Row" -> 1, "Column" -> 2, "Coefficient" -> (2 + eps)/eps^2, "Letter" -> {"GPLPole", -1}|>,
  <|"Row" -> 2, "Column" -> 1, "Coefficient" -> (eps + 2)/eps, "Letter" -> {"GPLFactor", q, 0}|>,
  <|"Row" -> 2, "Column" -> 2, "Coefficient" -> 1/(eps (1 - 2 eps)), "Letter" -> {"GPLPole", 3/4}|>};
dlogLayer = Join[layer, <|"Incoming" -> dlogIncoming|>];
direct = SolveRationalEpsilonDependentBlockByVariationOfConstants[source, dlogLayer, demand];
modular = SolveRationalEpsilonDependentBlockByVariationOfConstants[source, dlogLayer, demand, "VariationOfConstantsMethod" -> "FiniteFieldHermiteReductionAndReconstruction", "PrimeCount" -> 3];
FTAssert["a path-free incoming connection takes the exact direct route, accepted, with vanishing off-diagonal basis-transformation block",
  direct["Status"] === "RationalEpsilonDependentBlockSolutionAccepted" && RationalEpsilonDependentBlockSolutionQ[direct] &&
    direct["Certificate"]["VariationOfConstantsMethod"] === "ExactDLogDecomposition" && direct["OffDiagonalTransformationBlockStatus"] === "OffDiagonalTransformationBlockVanishes" &&
    TrueQ[direct["Certificate"]["Exact"]]];
lazyDirect = SolveRationalEpsilonDependentBlockByVariationOfConstants[source, dlogLayer, demand,
  "IteratedIntegralCoefficientRepresentation" -> "LazyCoefficientOperator"];
alteredIncomingDLogBlock = Join[dlogLayer, <|"Incoming" ->
  ReplacePart[dlogLayer["Incoming"], 1 ->
    Join[dlogLayer["Incoming"][[1]], <|"Coefficient" -> 3/eps|>]]|>];
FTAssert["the accepted solution does not duplicate its source/block inputs and input-backed verification checks the supplied incoming connection",
  Intersection[Keys[lazyDirect],
      {"CoefficientOperatorSourceSystem",
        "CoefficientOperatorTargetBlock"}] === {} &&
    lazyDirect["RequestedOutputPairs"] === demand["RequestedOutputPairs"] &&
    VerifyRationalEpsilonDependentBlockSolution[lazyDirect, source, dlogLayer, demand] &&
    ! VerifyRationalEpsilonDependentBlockSolution[lazyDirect, source,
      alteredIncomingDLogBlock, demand]];
(* a REDUCIBLE factor letter (9/16 - u^2 splits over Q) must land on the same irreducible-factor letters in both routes *)
splitLayer = Join[layer, <|"Incoming" -> Append[dlogIncoming, <|"Row" -> 2, "Column" -> 1, "Coefficient" -> (3 + eps)/eps^2, "Letter" -> {"GPLFactor", 9/16 - u^2, 1}|>]|>];
splitDirect = SolveRationalEpsilonDependentBlockByVariationOfConstants[source, splitLayer, demand];
splitModular = SolveRationalEpsilonDependentBlockByVariationOfConstants[source, splitLayer, demand, "VariationOfConstantsMethod" -> "FiniteFieldHermiteReductionAndReconstruction", "PrimeCount" -> 3];
FTAssert["a reducible GPLFactor letter is decomposed onto irreducible factors identically by exact dlog decomposition and finite-field Hermite reduction",
  splitDirect["Status"] === "RationalEpsilonDependentBlockSolutionAccepted" && splitModular["Status"] === "RationalEpsilonDependentBlockSolutionAccepted" &&
    KeySort[splitDirect["KResidues"]] === KeySort[Select[splitModular["KResidues"], ! AllTrue[Flatten[#], # === 0 &] &]] &&
    splitDirect["IteratedIntegralCoefficientTermsByRequestedOutput"] === splitModular["IteratedIntegralCoefficientTermsByRequestedOutput"] &&
    MemberQ[Keys[splitDirect["KResidues"]], {-2, u + 3/4, 0}]];
FTAssert["finite-field Hermite reduction and reconstruction on the same block gives the same residues and iterated-integral coefficient terms",
  modular["Certificate"]["VariationOfConstantsMethod"] === "FiniteFieldHermiteReductionAndReconstruction" && RationalEpsilonDependentBlockSolutionQ[modular] &&
    KeySort[direct["KResidues"]] === KeySort[Select[modular["KResidues"], ! AllTrue[Flatten[#], # === 0 &] &]] &&
    direct["IteratedIntegralCoefficientTermsByRequestedOutput"] === modular["IteratedIntegralCoefficientTermsByRequestedOutput"]];
(* An exact derivative can produce a nonzero off-diagonal
   basis-transformation block at the path endpoint with no dlog
   remainder at all.  This is a complete transport, not a vanished layer. *)
exactDerivativeSource = <|"Dimension" -> 1, "Letters" -> {{"GPLPole", -1}},
  "Residues" -> {{{0}}}, "BoundarySelectors" -> <|0 -> {{1}}|>|>;
exactDerivativeBlock = <|"Rows" -> {1}, "PathVariable" -> u, "Regulator" -> eps,
  "BasePoint" -> 0, "PathEndpoint" -> 1,
  "Diagonal" -> {{{"GPLPole", -1}, {{0}}}},
  "Incoming" -> {<|"Row" -> 1, "Column" -> 1,
    "Coefficient" -> 1/(eps (u + 1)), "Letter" -> {"GPLPole", -1}|>},
  "TargetBoundarySelectors" -> <|0 -> {{1}}|>|>;
exactDerivativeDemand = <|"RequestedOutputPairs" -> {{-1, 1}}|>;
exactDerivativeSolution = SolveRationalEpsilonDependentBlockByVariationOfConstants[
  exactDerivativeSource, exactDerivativeBlock, exactDerivativeDemand,
  "PrimeCount" -> 3];
FTAssert["K=0 with a nonzero off-diagonal basis-transformation block at the path endpoint is a valid variation-of-constants solution",
  exactDerivativeSolution["Status"] ===
      "RationalEpsilonDependentBlockSolutionAccepted" &&
    exactDerivativeSolution["KResidues"] === <||> &&
    exactDerivativeSolution[
      "OffDiagonalBasisTransformationBlockAtPathEndpoint"][-1] === {{1/2}} &&
    exactDerivativeSolution["OffDiagonalTransformationBlockStatus"] ===
      "OffDiagonalTransformationBlockReconstructedAtPathEndpoint" &&
    exactDerivativeSolution["Certificate"]["ResidueComparisons"] === 0 &&
    exactDerivativeSolution["Certificate"][
      "OffDiagonalTransformationBlockComparisons"] > 0 &&
    RationalEpsilonDependentBlockSolutionQ[exactDerivativeSolution] &&
    VerifyRationalEpsilonDependentBlockSolution[exactDerivativeSolution,
      exactDerivativeSource, exactDerivativeBlock, exactDerivativeDemand]];
lazy = SolveRationalEpsilonDependentBlockByVariationOfConstants[source, layer,
  demand, "IteratedIntegralCoefficientRepresentation" -> "LazyCoefficientOperator", "MaximumStates" -> 1,
  "MaximumIteratedIntegralCoefficientTerms" -> 0, "PrimeCount" -> 3];
FTAssert["the lazy coefficient-operator representation skips explicit coefficient-term enumeration even under impossible explicit caps",
  lazy["Status"] === "RationalEpsilonDependentBlockSolutionAccepted" &&
    lazy["IteratedIntegralCoefficientRepresentation"] === "LazyCoefficientOperator" && lazy["IteratedIntegralCoefficientTermsByRequestedOutput"] === None &&
    AssociationQ[lazy["KResidues"]] && RationalEpsilonDependentBlockSolutionQ[lazy] &&
    VerifyRationalEpsilonDependentBlockSolution[lazy, source, layer, demand] &&
    SolveRationalEpsilonDependentBlockByVariationOfConstants[source, layer, demand,
      "IteratedIntegralCoefficientRepresentation" -> "ExplicitCoefficientTerms", "MaximumIteratedIntegralCoefficientTerms" -> 0,
      "PrimeCount" -> 3]["Status"] === "IteratedIntegralCoefficientTermEnumerationCapped" &&
    SolveRationalEpsilonDependentBlockByVariationOfConstants[source, layer, demand,
      "IteratedIntegralCoefficientRepresentation" -> "Unknown"]["Status"] ===
        "IteratedIntegralCoefficientRepresentationInvalid" &&
    SolveRationalEpsilonDependentBlockByVariationOfConstants[source, layer,
      demand, "VariationOfConstantsMethod" -> "Unknown"]["Status"] ===
        "VariationOfConstantsMethodInvalid" &&
    SolveRationalEpsilonDependentBlockByVariationOfConstants[source, layer,
      demand, "VariationOfConstantsMethod" ->
        "ExactDLogDecomposition"]["Status"] ===
      "ExactDLogDecompositionNotApplicable"];

sharedSource = <|"Dimension" -> 1, "Letters" -> {{"GPLPole", -1}},
  "Residues" -> {{{0}}}, "BoundarySelectors" -> <|0 -> {{1}}|>|>;
sharedLayer = <|"Rows" -> {1}, "PathVariable" -> u, "Regulator" -> eps,
  "BasePoint" -> 0, "PathEndpoint" -> 1,
  "Diagonal" -> {{{"GPLPole", -1}, {{0}}}},
  "Incoming" -> {<|"Row" -> 1, "Column" -> 1, "Coefficient" -> 1,
    "Letter" -> {"GPLPole", -1}|>},
  "TargetBoundarySelectors" -> <|0 -> {{1}}|>,
  "SharedBoundaryCoordinates" -> True|>;
sharedDemand = <|"RequestedOutputPairs" -> {{0, 1}}|>;
shared = SolveRationalEpsilonDependentBlockByVariationOfConstants[sharedSource, sharedLayer, sharedDemand];
sharedWordValue = Total[(First[#["IteratedIntegralCoefficientVector"]]
      If[#["IteratedIntegralLetterSequence"] === {}, 1, Log[2]]) & /@
  shared["IteratedIntegralCoefficientTermsByRequestedOutput"][{0, 1}]];
sharedODEValue = NDSolveValue[{f'[z] == 1/(z + 1), f[0] == 1}, f[1],
  {z, 0, 1}, WorkingPrecision -> 30, AccuracyGoal -> 20, PrecisionGoal -> 20];
separate = SolveRationalEpsilonDependentBlockByVariationOfConstants[sharedSource,
  KeyDrop[sharedLayer, "SharedBoundaryCoordinates"], sharedDemand];
FTAssert["one shared boundary coefficient contributes to source and target terms without duplication",
  shared["Status"] === "RationalEpsilonDependentBlockSolutionAccepted" &&
    shared["SharedBoundaryCoordinates"] && shared["BoundaryColumns"] === 1 &&
    AllTrue[shared["IteratedIntegralCoefficientTermsByRequestedOutput"][{0, 1}],
      Length[#["IteratedIntegralCoefficientVector"]] === 1 &] &&
    Abs[N[sharedWordValue - sharedODEValue]] < 10^-10 &&
    separate["BoundaryColumns"] === 2 &&
    VerifyRationalEpsilonDependentBlockSolution[shared, sharedSource, sharedLayer, sharedDemand] &&
    SolveRationalEpsilonDependentBlockByVariationOfConstants[sharedSource,
      Join[sharedLayer, <|"TargetBoundarySelectors" -> <|0 -> {{1, 0}}|>|>],
      sharedDemand]["Status"] === "SharedBoundarySelectorsInvalid"];
(* ---- R1's independent end-to-end check (round 8b): the ODE dF = A F solved
   numerically order by order (NDSolve, 30 digits) versus the route's words
   evaluated as numerical iterated integrals -- no use of the route's
   enumerator; a NEGATIVE source boundary order (S1), and order 2 with
   length-2 target words (S2b) ---- *)
sourceNeg = Join[source, <|"BoundarySelectors" -> <|-1 -> {{1, 0}, {0, 1}}, 0 -> IdentityMatrix[2], 1 -> {{0, 1}, {0, 0}}|>|>];
odeIncoming = Append[dlogIncoming, <|"Row" -> 2, "Column" -> 2, "Coefficient" -> 3/eps, "Letter" -> {"GPLPole", -1}|>];
odeLayer = Join[layer, <|"Incoming" -> odeIncoming|>];
letterForm[{"GPLFactor", qq_, k_, "Incoming", _}] := u^k/qq;
base = 1/2; u1 = 1/4; prec = 40; goals = Sequence[PrecisionGoal -> 20, AccuracyGoal -> 20];
selS = sourceNeg["BoundarySelectors"]; selT = odeLayer["TargetBoundarySelectors"];
fS0[qq_] := If[KeyExistsQ[selS, qq], ArrayFlatten[{{selS[qq], ConstantArray[0, {2, 2}]}}], ConstantArray[0, {2, 4}]];
fT0[qq_] := If[KeyExistsQ[selT, qq], ArrayFlatten[{{ConstantArray[0, {2, 2}], selT[qq]}}], ConstantArray[0, {2, 4}]];
S1form = Total[MapThread[letterForm[#1] #2 &, {sourceNeg["Letters"], sourceNeg["Residues"]}]];
D1form = Sum[letterForm[dl[[1]]] dl[[2]], {dl, diagonal}];
Bn[n_] := Table[Sum[If[e["Row"] === i && e["Column"] === j, SeriesCoefficient[e["Coefficient"], {eps, 0, n}] letterForm[e["Letter"]], 0], {e, odeIncoming}], {i, 2}, {j, 2}];
fS = <||>; fT = <||>;
Do[fS[qq] = If[qq < -1, ConstantArray[0, {2, 4}], Module[{f, sol, rhs},
    rhs = If[qq - 1 < -1, ConstantArray[0, {2, 4}], S1form . fS[qq - 1]];
    sol = NDSolve[Join[Flatten[Table[f[i, j]'[u] == rhs[[i, j]], {i, 2}, {j, 4}]], Flatten[Table[f[i, j][base] == fS0[qq][[i, j]], {i, 2}, {j, 4}]]],
      Flatten[Table[f[i, j], {i, 2}, {j, 4}]], {u, u1, base}, WorkingPrecision -> prec, MaxSteps -> 10^6, goals];
    Table[f[i, j][u] /. First[sol], {i, 2}, {j, 4}]]], {qq, -1, 5}];
Do[fT[n] = Module[{f, sol, rhs},
    rhs = Sum[Bn[r] . If[KeyExistsQ[fS, n - r], fS[n - r], ConstantArray[0, {2, 4}]], {r, -2, n + 1}] + D1form . If[KeyExistsQ[fT, n - 1], fT[n - 1], ConstantArray[0, {2, 4}]];
    sol = NDSolve[Join[Flatten[Table[f[i, j]'[u] == rhs[[i, j]], {i, 2}, {j, 4}]], Flatten[Table[f[i, j][base] == fT0[n][[i, j]], {i, 2}, {j, 4}]]],
      Flatten[Table[f[i, j], {i, 2}, {j, 4}]], {u, u1, base}, WorkingPrecision -> prec, MaxSteps -> 10^6, goals];
    Table[f[i, j][u] /. First[sol], {i, 2}, {j, 4}]], {n, -3, 2}];
odeValue[n_, row_] := (fT[n] /. u -> u1)[[row]];
iterated[{}] := 1;
iterated[letters_List] := Module[{k = Length[letters], y, sol, eqs},
  eqs = Join[{y[k]'[u] == letterForm[letters[[k]]]}, Table[y[j]'[u] == letterForm[letters[[j]]] y[j + 1][u], {j, k - 1}], Table[y[j][base] == 0, {j, k}]];
  sol = NDSolve[eqs, Table[y[j], {j, k}], {u, u1, base}, WorkingPrecision -> prec, MaxSteps -> 10^6, goals];
  y[1][u1] /. First[sol]];
mapped[v_] := {v[[1]], v[[2]], v[[3]] + v[[5]], v[[4]] + v[[6]]};
wordSum[r_, pair_] := With[
  {ws = r["IteratedIntegralCoefficientTermsByRequestedOutput"][pair]},
  If[ws === {}, ConstantArray[0, 6], Total[Table[
    iterated[e["IteratedIntegralLetterSequence"]] *
      e["IteratedIntegralCoefficientVector"], {e, ws}]]]];
odeDemand = <|"RequestedOutputPairs" -> Flatten[Table[{n, row}, {n, -1, 2}, {row, 2}], 1]|>;
{odeSeconds, odeResult} = AbsoluteTiming[SolveRationalEpsilonDependentBlockByVariationOfConstants[sourceNeg, odeLayer, odeDemand]];
odeDeviations = Table[{n, row, N[Norm[odeValue[n, row] - mapped[wordSum[odeResult, {n, row}]]], 3]}, {n, -1, 2}, {row, 2}];
Print["ODE check (negative boundary order, orders -1..2): window ", odeResult["Window"], "; route ", Round[odeSeconds, 0.01], " s; deviations ", odeDeviations];
FTAssert["S1: with a source boundary order -1 the window is widened (high = N_max - q_min = 3) and the words for a pair do not depend on what else is demanded",
  odeResult["Window"] === {-2, 3} &&
    With[{alone = SolveRationalEpsilonDependentBlockByVariationOfConstants[sourceNeg, odeLayer, <|"RequestedOutputPairs" -> {{0, 1}}|>]},
      alone["Window"] === {-2, 1} &&
      Sort[Lookup[alone["IteratedIntegralCoefficientTermsByRequestedOutput"][{0, 1}],
        "IteratedIntegralLetterSequence"]] ===
      Sort[Lookup[odeResult["IteratedIntegralCoefficientTermsByRequestedOutput"][{0, 1}],
        "IteratedIntegralLetterSequence"]]]];
FTAssert["R1's ODE check: every demanded (order, row) of orders -1..2 agrees with the numerical ODE solution to 1e-9 (words evaluated as iterated integrals, outermost letter first)",
  odeResult["Status"] === "RationalEpsilonDependentBlockSolutionAccepted" && AllTrue[Flatten[odeDeviations, 1], #[[3]] < 10^-9 &]];
FTAssert["S2b: order 2 has target words of length 2 and they enter the ODE agreement in the outermost-first convention",
  Count[odeResult["IteratedIntegralCoefficientTermsByRequestedOutput"][{2, 1}],
      e_ /; e["ContributionType"] === "TargetBoundary" &&
        Length[e["IteratedIntegralLetterSequence"]] === 2] > 0 &&
    N[Norm[odeValue[2, 1] - mapped[wordSum[odeResult, {2, 1}]]]] < 10^-9 &&
    N[Norm[odeValue[2, 2] - mapped[wordSum[odeResult, {2, 2}]]]] < 10^-9];
(* ---- S3: the lifted off-diagonal basis-transformation block at the path
   endpoint, exact reference SameQ, and the full solution F_T = G + H F_S
   against the ODE for the u-dependent block ---- *)
FTAssert["S3: the off-diagonal basis-transformation block at the path endpoint is reconstructed and SameQ with the exact reference at every order",
  result["OffDiagonalTransformationBlockStatus"] === "OffDiagonalTransformationBlockReconstructedAtPathEndpoint" && result["Certificate"]["OffDiagonalTransformationBlockReconstructed"] &&
    result["Certificate"]["OffDiagonalTransformationBlockComparisons"] > 0 && result["Certificate"]["OffDiagonalTransformationBlockMismatches"] === 0 &&
    And @@ Table[result["OffDiagonalBasisTransformationBlockAtPathEndpoint"][order] === Map[Together, hRef[order] /. u -> 1/4, {2}], {order, -2, 0}]];
FTAssert["a u-dependent layer without an endpoint is refused typed",
  SolveRationalEpsilonDependentBlockByVariationOfConstants[source,
    KeyDrop[layer, "PathEndpoint"], demand, "PrimeCount" -> 3]["Status"] ===
      "PathEndpointRequired"];
selS2 = source["BoundarySelectors"];
fS02[qq_] := If[KeyExistsQ[selS2, qq], ArrayFlatten[{{selS2[qq], ConstantArray[0, {2, 2}]}}], ConstantArray[0, {2, 4}]];
S1form2 = Total[MapThread[letterForm[#1] #2 &, {source["Letters"], source["Residues"]}]];
Bn2[n_] := Table[Sum[If[e["Row"] === i && e["Column"] === j, SeriesCoefficient[e["Coefficient"], {eps, 0, n}] letterForm[e["Letter"]], 0], {e, incoming}], {i, 2}, {j, 2}];
fS2 = <||>; fT2 = <||>;
Do[fS2[qq] = If[qq < 0, ConstantArray[0, {2, 4}], Module[{f, sol, rhs},
    rhs = If[qq - 1 < 0, ConstantArray[0, {2, 4}], S1form2 . fS2[qq - 1]];
    sol = NDSolve[Join[Flatten[Table[f[i, j]'[u] == rhs[[i, j]], {i, 2}, {j, 4}]], Flatten[Table[f[i, j][base] == fS02[qq][[i, j]], {i, 2}, {j, 4}]]],
      Flatten[Table[f[i, j], {i, 2}, {j, 4}]], {u, u1, base}, WorkingPrecision -> prec, MaxSteps -> 10^6, goals];
    Table[f[i, j][u] /. First[sol], {i, 2}, {j, 4}]]], {qq, 0, 3}];
Do[fT2[n] = Module[{f, sol, rhs},
    rhs = Sum[Bn2[r] . If[KeyExistsQ[fS2, n - r], fS2[n - r], ConstantArray[0, {2, 4}]], {r, -2, n}] + D1form . If[KeyExistsQ[fT2, n - 1], fT2[n - 1], ConstantArray[0, {2, 4}]];
    sol = NDSolve[Join[Flatten[Table[f[i, j]'[u] == rhs[[i, j]], {i, 2}, {j, 4}]], Flatten[Table[f[i, j][base] == fT0[n][[i, j]], {i, 2}, {j, 4}]]],
      Flatten[Table[f[i, j], {i, 2}, {j, 4}]], {u, u1, base}, WorkingPrecision -> prec, MaxSteps -> 10^6, goals];
    Table[f[i, j][u] /. First[sol], {i, 2}, {j, 4}]], {n, -2, 0}];
transported[n_, row_] := mapped[wordSum[result, {n, row}]];
solutionDeviations = Table[{n, row,
    N[Norm[(fT2[n] /. u -> u1)[[row]] - transported[n, row]], 3]},
  {n, -2, 0}, {row, 2}];
Print["u-dependent block, F_T = G + H F_S against the ODE: deviations ",
  solutionDeviations];
FTAssert["S3 end to end: on the u-dependent block the explicit coefficients include H F_S and agree with the ODE to 1e-9 at every requested (order, row)",
  AllTrue[Flatten[solutionDeviations, 1], #[[3]] < 10^-9 &]];
(* ---- S5-S8 typed refusals ---- *)
FTAssert["S5: a diagonal residue with the path variable, a source residue with eps, and a selector with a symbol are refused typed",
  SolveRationalEpsilonDependentBlockByVariationOfConstants[source, Join[dlogLayer, <|"Diagonal" -> {{{"GPLPole", 3/4}, {{u, 0}, {0, 2}}}, diagonal[[2]]}|>], demand]["Status"] === "ResidueMatrixNotConstant" &&
  SolveRationalEpsilonDependentBlockByVariationOfConstants[Join[source, <|"Residues" -> {{{0, eps}, {0, 0}}, {{1, 0}, {0, -1}}}|>], dlogLayer, demand]["Status"] === "ResidueMatrixNotConstant" &&
  SolveRationalEpsilonDependentBlockByVariationOfConstants[Join[source, <|"BoundarySelectors" -> <|0 -> {{1, x}, {0, 1}}|>|>], dlogLayer, demand]["Status"] === "ResidueMatrixNotConstant"];
FTAssert["selector orders, row dimensions and the shared source-column shape are validated before enumeration",
  SolveRationalEpsilonDependentBlockByVariationOfConstants[Join[source, <|"BoundarySelectors" -> <|"zero" -> IdentityMatrix[2]|>|>], dlogLayer, demand]["Status"] === "SourceBoundarySelectorsInvalid" &&
  SolveRationalEpsilonDependentBlockByVariationOfConstants[Join[source, <|"BoundarySelectors" -> <|0 -> IdentityMatrix[2], 1 -> {{1}, {0}}|>|>], dlogLayer, demand]["Status"] === "SourceBoundarySelectorsInvalid" &&
  SolveRationalEpsilonDependentBlockByVariationOfConstants[source, Join[dlogLayer, <|"TargetBoundarySelectors" -> <|"zero" -> IdentityMatrix[2]|>|>], demand]["Status"] === "TargetBoundarySelectorsInvalid" &&
  SolveRationalEpsilonDependentBlockByVariationOfConstants[source, Join[dlogLayer, <|"TargetBoundarySelectors" -> <|0 -> {{1, 0}}|>|>], demand]["Status"] === "TargetBoundarySelectorsInvalid" &&
  SolveRationalEpsilonDependentBlockByVariationOfConstants[source, dlogLayer,
    <|"RequestedOutputPairs" -> {{0, 1}, {0, 1}}|>]["Status"] ===
      "RequestedOutputPairsInvalid"];
FTAssert["S6: a coefficient whose eps^-3 term vanishes at three fixed points is not truncated: the Series valuation below the certified window is refused typed, and the probe points are random",
  With[{r = SolveRationalEpsilonDependentBlockByVariationOfConstants[source, Join[layer, <|"Incoming" -> Append[incoming, <|"Row" -> 1, "Column" -> 1, "Coefficient" -> (u - 1/2) (u - 5/6) (u - 11/14)/eps^3 + 1/eps^2, "Letter" -> {"GPLPole", -1}|>]|>], <|"RequestedOutputPairs" -> {{-2, 1}}|>, "PrimeCount" -> 3]},
    r["Status"] === "RationalEpsilonDependentBlockSolutionAccepted" && r["Window"][[1]] === -3 && DuplicateFreeQ[r["Certificate"]["ValuationProbePoints"]]] &&
  With[{r = SolveRationalEpsilonDependentBlockByVariationOfConstants[source, Join[layer, <|"Incoming" -> Append[incoming, <|"Row" -> 1, "Column" -> 1, "Coefficient" -> (u - 1/2) (u - 5/6) (u - 11/14)/eps^3 + 1/eps^2, "Letter" -> {"GPLPole", -1}|>]|>], <|"RequestedOutputPairs" -> {{-2, 1}}|>, "PrimeCount" -> 3, "Seed" -> 1]},
    MemberQ[{"RationalEpsilonDependentBlockSolutionAccepted", "LaurentValuationBelowWindow"}, r["Status"]] && (r["Status"] =!= "RationalEpsilonDependentBlockSolutionAccepted" || r["Window"][[1]] === -3)]];
FTAssert["S7: a prime at which a pole factor degenerates is skipped and recorded, the result still accepted; a bad prime is never a misleading status",
  With[{r = SolveRationalEpsilonDependentBlockByVariationOfConstants[source, Join[layer, <|"Incoming" -> Append[incoming, <|"Row" -> 1, "Column" -> 1, "Coefficient" -> u/(eps^2 (u^2 - 1000003)), "Letter" -> {"GPLPole", -1}|>]|>], <|"RequestedOutputPairs" -> {{-2, 1}}|>,
      "Primes" -> {1000003, 1000033, 1000037, 1000039, 1000081, 1000099, 1000117, 1000121, 1000133, 1000151, 1000159, 1000171}, "PrimeCount" -> 3]},
    r["Status"] === "RationalEpsilonDependentBlockSolutionAccepted" && Lookup[r["Certificate"]["SkippedPrimes"], "Prime"] === {1000003} && ! MemberQ[r["Certificate"]["Primes"], 1000003] && r["Certificate"]["FreshValidationPrime"] =!= 1000003]];
FTAssert["S8: a non-quartic curve is refused typed, E4Eta2 is a curve letter, ZeroColumns naming a present or out-of-range column is refused typed",
  SolveRationalEpsilonDependentBlockByVariationOfConstants[source, Join[layer, <|"Curve" -> u^2, "Incoming" -> Append[incoming, <|"Row" -> 1, "Column" -> 1, "Coefficient" -> 1/eps, "Letter" -> {"E4Pole", 3}|>]|>], demand]["Status"] === "CurveNotQuartic" &&
  SolveRationalEpsilonDependentBlockByVariationOfConstants[source, Join[layer, <|"Incoming" -> Append[incoming, <|"Row" -> 1, "Column" -> 1, "Coefficient" -> 1/eps, "Letter" -> {"E4Eta2"}|>]|>], demand]["Status"] === "CurveDeclarationRequired" &&
  SolveRationalEpsilonDependentBlockByVariationOfConstants[source, Join[dlogLayer, <|"ZeroColumns" -> {2, 7}|>], demand]["Status"] === "ZeroColumnsInvalid"];
FTAssert["a source word growth beyond the state cap is a typed refusal",
  SolveRationalEpsilonDependentBlockByVariationOfConstants[sourceNeg,
    odeLayer, odeDemand, "MaximumStates" -> 5]["Status"] ===
      "SourceIteratedIntegralSequenceGrowthCapped"];
FTAssert["S4: input-backed verification checks both solution methods and catches an altered residue at a fresh prime",
  VerifyRationalEpsilonDependentBlockSolution[result, source, layer, demand] &&
    VerifyRationalEpsilonDependentBlockSolution[direct, source, dlogLayer, demand] &&
    With[{tampered = Join[result, <|"KResidues" -> MapAt[# + 1 &, result["KResidues"], {Key[First[Keys[result["KResidues"]]]], 1, 1}]|>]},
      RationalEpsilonDependentBlockSolutionQ[tampered] &&
      ! VerifyRationalEpsilonDependentBlockSolution[tampered, source, layer, demand]] &&
    ! VerifyRationalEpsilonDependentBlockSolution[result, source, Join[layer, <|"BasePoint" -> 1/3|>], demand] &&
    ! VerifyRationalEpsilonDependentBlockSolution[direct, source, layer, demand]];
(* ---- Round 8c: R1's re-review findings N1-N4 ---- *)
FTAssert["N1: mathematical iterated-integral coefficient changes and structural payload mismatches are caught by input-backed re-enumeration",
  With[{doubled = Join[result, <|
        "IteratedIntegralCoefficientTermsByRequestedOutput" ->
          MapAt[Join[#, <|"IteratedIntegralCoefficientVector" ->
              2 #["IteratedIntegralCoefficientVector"]|>] &,
            result["IteratedIntegralCoefficientTermsByRequestedOutput"],
            {Key[{0, 1}], 1}]|>],
      deleted = Join[result, <|"IteratedIntegralCoefficientTermsByRequestedOutput" -> MapAt[Rest, result["IteratedIntegralCoefficientTermsByRequestedOutput"], {Key[{0, 1}]}]|>],
      removed = Join[result, <|"IteratedIntegralCoefficientTermsByRequestedOutput" -> KeyDrop[result["IteratedIntegralCoefficientTermsByRequestedOutput"], {{0, 1}}]|>],
      moved = Join[result, <|"PathEndpoint" -> 1/3|>]},
    RationalEpsilonDependentBlockSolutionQ[doubled] && ! VerifyRationalEpsilonDependentBlockSolution[doubled, source, layer, demand] &&
    RationalEpsilonDependentBlockSolutionQ[deleted] && ! VerifyRationalEpsilonDependentBlockSolution[deleted, source, layer, demand] &&
    ! RationalEpsilonDependentBlockSolutionQ[removed] && ! VerifyRationalEpsilonDependentBlockSolution[removed, source, layer, demand] &&
    ! RationalEpsilonDependentBlockSolutionQ[moved] && ! VerifyRationalEpsilonDependentBlockSolution[moved, source, layer, demand] &&
    VerifyRationalEpsilonDependentBlockSolution[result, source, layer, demand] && VerifyRationalEpsilonDependentBlockSolution[direct, source, dlogLayer, demand]]];
FTAssert["OffDiagonalTransformationBlockStatus is semantically bound to the variation-of-constants method and H payload",
  ! RationalEpsilonDependentBlockSolutionQ[Join[result, <|"OffDiagonalTransformationBlockStatus" -> "OffDiagonalTransformationBlockVanishes"|>]] &&
  ! RationalEpsilonDependentBlockSolutionQ[Join[direct, <|"OffDiagonalTransformationBlockStatus" -> "OffDiagonalTransformationBlockReconstructedAtPathEndpoint"|>]] &&
  ! RationalEpsilonDependentBlockSolutionQ[Join[direct, <|"OffDiagonalBasisTransformationBlockAtPathEndpoint" -> Map[# + 1 &, direct["OffDiagonalBasisTransformationBlockAtPathEndpoint"], {3}]|>]] &&
  ! RationalEpsilonDependentBlockSolutionQ[Join[result, <|"Certificate" -> Join[result["Certificate"], <|"OffDiagonalTransformationBlockReconstructed" -> False|>]|>]]];
FTAssert["N2: a degenerate prime placed in the fresh-prime slot of an explicit schedule (position PrimeCount + 1) is skipped and recorded, the result accepted with the next prime as the fresh one",
  With[{r = SolveRationalEpsilonDependentBlockByVariationOfConstants[source, Join[layer, <|"Incoming" -> Append[incoming, <|"Row" -> 1, "Column" -> 1, "Coefficient" -> u/(eps^2 (u^2 - 1000003)), "Letter" -> {"GPLPole", -1}|>]|>], <|"RequestedOutputPairs" -> {{-2, 1}}|>,
      "Primes" -> {1000033, 1000037, 1000039, 1000081, 1000099, 1000117, 1000121, 1000133, 1000151, 1000003, 1000159, 1000171}, "PrimeCount" -> 9, "MaximumPrimeCount" -> 11]},
    r["Status"] === "RationalEpsilonDependentBlockSolutionAccepted" && MemberQ[Lookup[r["Certificate"]["SkippedPrimes"], "Prime"], 1000003] && r["Certificate"]["FreshValidationPrime"] =!= 1000003]];
FTAssert["the prime contract rejects composite, duplicate and undersized schedules and uses the final explicit prime for fresh validation",
  SolveRationalEpsilonDependentBlockByVariationOfConstants[exactDerivativeSource, exactDerivativeBlock, exactDerivativeDemand,
    "Primes" -> {3, 5, 7, 9}, "PrimeCount" -> 3]["Status"] === "InvalidPrimeSchedule" &&
  SolveRationalEpsilonDependentBlockByVariationOfConstants[exactDerivativeSource, exactDerivativeBlock, exactDerivativeDemand,
    "Primes" -> {3, 5, 5, 7}, "PrimeCount" -> 3]["Status"] === "InvalidPrimeSchedule" &&
  SolveRationalEpsilonDependentBlockByVariationOfConstants[exactDerivativeSource, exactDerivativeBlock, exactDerivativeDemand,
    "Primes" -> {1000033, 1000037, 1000039}, "PrimeCount" -> 3]["Status"] === "InvalidPrimeSchedule" &&
  SolveRationalEpsilonDependentBlockByVariationOfConstants[exactDerivativeSource, exactDerivativeBlock, exactDerivativeDemand,
    "PrimeCount" -> 4, "MaximumPrimeCount" -> 3]["Status"] === "InvalidPrimeCount" &&
  With[{r = SolveRationalEpsilonDependentBlockByVariationOfConstants[exactDerivativeSource, exactDerivativeBlock, exactDerivativeDemand,
      "Primes" -> {1000033, 1000037, 1000039, 1000081}, "PrimeCount" -> 3]},
    r["Status"] === "RationalEpsilonDependentBlockSolutionAccepted" &&
      r["Certificate"]["Primes"] === {1000033, 1000037, 1000039} &&
      r["Certificate"]["FreshValidationPrime"] === 1000081]];
FTAssert["N3: a Gaussian-rational coefficient is refused typed early on the modular route and accepted exactly on the direct route",
  SolveRationalEpsilonDependentBlockByVariationOfConstants[source, Join[layer, <|"Incoming" -> Append[incoming, <|"Row" -> 1, "Column" -> 1, "Coefficient" -> I/(eps^2 (u + 1)), "Letter" -> {"GPLPole", -1}|>]|>], <|"RequestedOutputPairs" -> {{-2, 1}}|>, "PrimeCount" -> 3]["Status"] === "CoefficientFieldNotRational" &&
  With[{r = SolveRationalEpsilonDependentBlockByVariationOfConstants[source, Join[dlogLayer, <|"Incoming" -> Append[dlogIncoming, <|"Row" -> 1, "Column" -> 1, "Coefficient" -> I/eps^2, "Letter" -> {"GPLPole", -1}|>]|>], <|"RequestedOutputPairs" -> {{-2, 1}}|>]},
    r["Status"] === "RationalEpsilonDependentBlockSolutionAccepted" && ! FreeQ[r["KResidues"], _Complex]]];
FTAssert["N4: unresolved base-point or endpoint singularities are a typed non-acceptance, while a regular pair carries empty notes",
  With[{r = SolveRationalEpsilonDependentBlockByVariationOfConstants[source, Join[layer, <|"PathEndpoint" -> 3/4, "Incoming" -> Append[incoming, <|"Row" -> 1, "Column" -> 1, "Coefficient" -> 1/(eps^2 (u - 1/2)), "Letter" -> {"GPLPole", -1}|>]|>], <|"RequestedOutputPairs" -> {{-2, 1}}|>, "PrimeCount" -> 3]},
    r["Status"] === "PathRegularizationRequired" && ! RationalEpsilonDependentBlockSolutionQ[r] &&
      r["RegularizationRequired"]["BasePoint"] === {u - 1/2} &&
      r["RegularizationRequired"]["PathEndpoint"] === {u - 3/4}] &&
  result["Certificate"]["RegularizationRequired"] === <|"BasePoint" -> {}, "PathEndpoint" -> {}|>];
FTAssert["the predicate refuses a tampered certificate",
  ! RationalEpsilonDependentBlockSolutionQ[Join[result, <|"Certificate" -> Join[result["Certificate"], <|"ResidueMismatches" -> 1|>]|>]] &&
  ! RationalEpsilonDependentBlockSolutionQ[KeyDrop[result, "Certificate"]]];
FTReport[];
