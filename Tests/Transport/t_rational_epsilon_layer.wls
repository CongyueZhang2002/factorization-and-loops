#!/usr/bin/env wolframscript
(* Round 8: transport of a final layer whose incoming connection is rational in
   eps (BuildRationalEpsilonLayerTransport), on a synthetic 2x2 layer over a
   2-master dlog source with poles at -1, 2 and the quadratic factor u^2 + 1.
   Reference: an independent characteristic-zero computation of the same
   recurrence (Series in eps, Apart, Integrate) -- the K residues on the pole
   alphabet must be SameQ with the reconstructed ones, and the demanded word
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
layer = <|"Rows" -> {44, 45}, "PathVariable" -> u, "Regulator" -> eps, "BasePoint" -> 1/2,
  "Diagonal" -> diagonal, "Incoming" -> incoming,
  "TargetBoundarySelectors" -> <|0 -> IdentityMatrix[2], 1 -> {{1, 1}, {0, 1}}|>|>;
demand = <|"Pairs" -> {{-2, 1}, {-2, 2}, {-1, 1}, {-1, 2}, {0, 1}, {0, 2}}|>;
{seconds, result} = AbsoluteTiming[BuildRationalEpsilonLayerTransport[source, layer, demand, "PrimeCount" -> 3]];
Print["route: ", Lookup[result, "Status", None], " in ", Round[seconds, 0.01], " s; window ", Lookup[result, "Window", None], "; residue keys ", Length[Lookup[result, "KResidues", <||>]], "; comparisons ", Lookup[Lookup[result, "Certificate", <||>], "ResidueComparisons", None]];
FTAssert["the synthetic rational layer is transported and accepted by the public predicate",
  result["Status"] === "RationalEpsilonLayerTransportAccepted" && AcceptedRationalEpsilonLayerTransportQ[result] && result["Window"] === {-2, 0}];
FTAssert["every reconstructed residue is a 2x2 matrix over the 2-master source (the layer shape is read from the matrices, not from an expression's term count)",
  AllTrue[Values[result["KResidues"]], Dimensions[#] === {2, 2} &] && Length[result["KResidues"]] === 10];
(* a wider source (3 masters) with the same layer: the third column declared zero *)
source3 = <|"Dimension" -> 3, "Letters" -> source["Letters"], "Residues" -> (ArrayFlatten[{{#, {{0}, {0}}}, {{{0, 0}}, {{1}}}}] & /@ source["Residues"]),
  "BoundarySelectors" -> <|0 -> IdentityMatrix[3], 1 -> {{0, 1, 0}, {0, 0, 0}, {0, 0, 1}}|>|>;
result3 = BuildRationalEpsilonLayerTransport[source3, Join[layer, <|"ZeroColumns" -> {3}|>], demand, "PrimeCount" -> 3];
FTAssert["a 3-master source with the third column declared zero gives 2x3 residues whose first two columns equal the 2-master result",
  result3["Status"] === "RationalEpsilonLayerTransportAccepted" &&
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
hPrev = ConstantArray[0, {2, 2}]; kRef = <||>;
Do[
  omega = bOrder[order] + d1[hPrev] - Sum[hPrev . (sl[[2]] letterForm[sl[[1]]]), {sl, Transpose[{source["Letters"], source["Residues"]}]}];
  omega = Map[Together, omega, {2}];
  h = ConstantArray[0, {2, 2}];
  Do[With[{hr = hermiteQ[omega[[i, j]]]},
      h[[i, j]] = Together[hr["Exact"] - (hr["Exact"] /. u -> 1/2)];
      KeyValueMap[Function[{factor, list}, Do[Module[{matrix = Lookup[kRef, Key[{order, factor, kk - 1}], ConstantArray[0, {2, 2}]]},
          matrix[[i, j]] = list[[kk]]; kRef[{order, factor, kk - 1}] = matrix], {kk, Length[list]}]], hr["Residues"]]],
    {i, 2}, {j, 2}];
  hPrev = h,
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
(* the H gauge: the modular images must agree with the exact reference at the base and at a probe point *)
hRefProbe = Map[Together, hPrev, {2}];
With[{p = First[Keys[result["GaugeImages"]]]}, With[{img = result["GaugeImages"][p][0]},
  Print["gauge diagnostic at u = 3, prime ", p, ": image ", InputForm[Table[Mod[(img[[i, j, 1]] /. u -> 3) PowerMod[(img[[i, j, 2]] /. u -> 3), -1, p], p], {i, 2}, {j, 2}]],
    " reference ", InputForm[Table[With[{v = hRefProbe[[i, j]] /. u -> 3}, Mod[Numerator[v] PowerMod[Denominator[v], -1, p], p]], {i, 2}, {j, 2}]],
    " image keys ", Keys[result["GaugeImages"][p]], " image entry short ", InputForm[Short[img[[2, 1]], 2]]]]];
FTAssert["the last-order gauge image agrees with the exact reference at u = 3 modulo every prime used",
  And @@ Table[With[{p = key, img = result["GaugeImages"][key][0]},
    And @@ Flatten[Table[Mod[(img[[i, j, 1]] /. u -> 3) - Numerator[hRefProbe[[i, j]] /. u -> 3] PowerMod[Denominator[hRefProbe[[i, j]] /. u -> 3], -1, p] (img[[i, j, 2]] /. u -> 3), p] === 0, {i, 2}, {j, 2}]]],
    {key, Keys[result["GaugeImages"]]}]];
(* demanded words: rebuild from the reference residues with the route's own word grammar *)
wordsRef = Association@Table[pair -> FeynFacet`Private`rationalLayerWords[pair[[1]], pair[[2]], diagonal, kRef, source,
    <|0 -> (Join[#, {0, 0}] & /@ IdentityMatrix[2]), 1 -> (Join[{0, 0}, #] & /@ {{1, 1}, {0, 1}})|>, 2, 4, 4], {pair, demand["Pairs"]}];
FTAssert["the demanded word coefficients are SameQ with those built from the reference residues, and nonempty",
  And @@ Table[result["DemandedWords"][pair] === wordsRef[pair], {pair, demand["Pairs"]}] &&
    Total[Length /@ Values[result["DemandedWords"]]] > 0];
Print["demanded words per pair: ", Length /@ result["DemandedWords"]];
FTAssert["the pruned enumeration keeps the word counts of the exhaustive one (1, 0, 7, 5, 26, 23) and a cap is typed",
  Values[Length /@ result["DemandedWords"]] === {1, 0, 7, 5, 26, 23} &&
    With[{capped = BuildRationalEpsilonLayerTransport[source, layer, demand, "MaximumWords" -> 3]},
      capped["Status"] === "RationalEpsilonLayerTransportAccepted" &&
        capped["DemandedWords"][{0, 1}]["Status"] === "WordEnumerationCapped"]];
(* ---- typed refusals ---- *)
FTAssert["a curve letter without a declared curve is refused typed",
  BuildRationalEpsilonLayerTransport[source, Join[layer, <|"Incoming" -> Append[incoming, <|"Row" -> 1, "Column" -> 1, "Coefficient" -> 1/eps, "Letter" -> {"E4Pole", 3}|>]|>], demand]["Status"] === "CurveDeclarationRequired"];
FTAssert["a curve letter with a declared curve is admitted by the gate but its channel is refused typed",
  BuildRationalEpsilonLayerTransport[source, Join[layer, <|"Curve" -> u^4 + 1, "Incoming" -> Append[incoming, <|"Row" -> 1, "Column" -> 1, "Coefficient" -> 1/eps, "Letter" -> {"E4Pole", 3}|>]|>], demand]["Status"] === "CurveChannelNotImplemented"];
FTAssert["an algebraic pole position is refused typed (declare the conjugate pair as a GPLFactor letter)",
  With[{r = BuildRationalEpsilonLayerTransport[source, Join[layer, <|"Incoming" -> Append[incoming, <|"Row" -> 1, "Column" -> 1, "Coefficient" -> 1/eps, "Letter" -> {"GPLPole", Sqrt[5]}|>]|>], demand]},
    r["Status"] === "AlgebraicPoleNotAdmitted" && r["Label"] === {"GPLPole", Sqrt[5]}]];
FTAssert["an unknown letter head is refused typed with its label",
  With[{r = BuildRationalEpsilonLayerTransport[source, Join[layer, <|"Incoming" -> Append[incoming, <|"Row" -> 1, "Column" -> 1, "Coefficient" -> 1/eps, "Letter" -> {"Mystery", 3}|>]|>], demand]},
    r["Status"] === "AlphabetLetterNotAdmitted" && r["Label"] === {"Mystery", 3}]];
FTAssert["an incoming coefficient not rational in eps is refused typed",
  BuildRationalEpsilonLayerTransport[source, Join[layer, <|"Incoming" -> Append[incoming, <|"Row" -> 1, "Column" -> 1, "Coefficient" -> Sqrt[eps]/eps, "Letter" -> {"GPLPole", 3/4}|>]|>], demand]["Status"] === "IncomingNotRationalInEpsilon"];
FTAssert["a source column with no incoming entry and no zero declaration is a typed lower-block exception",
  With[{r = BuildRationalEpsilonLayerTransport[source, Join[layer, <|"Incoming" -> Select[incoming, #["Column"] === 1 &]|>], demand]},
    r["Status"] === "LowerBlockExceptionRequired" && r["Columns"] === {2}] &&
  BuildRationalEpsilonLayerTransport[source, Join[layer, <|"Incoming" -> Select[incoming, #["Column"] === 1 &], "ZeroColumns" -> {2}|>], demand]["Status"] === "RationalEpsilonLayerTransportAccepted"];
FTAssert["an unspecialized parameter in a coefficient is refused typed",
  With[{r = BuildRationalEpsilonLayerTransport[source, Join[layer, <|"Incoming" -> Append[incoming, <|"Row" -> 1, "Column" -> 1, "Coefficient" -> Symbol["Global`layerP"]/eps, "Letter" -> {"GPLPole", 3/4}|>]|>], demand]},
    r["Status"] === "PathParameterNotSpecialized" && r["Symbols"] === {Symbol["Global`layerP"]}]];
FTAssert["a residue at a pole outside the alphabet cannot arise from declared letters and coefficients; a malformed letter is refused",
  BuildRationalEpsilonLayerTransport[source, Join[layer, <|"Diagonal" -> Append[diagonal, {{"GPLFactor", (u - 1)^2, 0}, IdentityMatrix[2]}]|>], demand]["Status"] === "AlphabetLetterNotAdmitted"];
(* stage 4: a layer whose incoming coefficients are path-free takes the exact
   direct route; forced through the sealed modular circuit it must give the
   same residues and words (SameQ) *)
dlogIncoming = {
  <|"Row" -> 1, "Column" -> 1, "Coefficient" -> (1 + 3 eps + eps^2)/(eps^2 (1 + eps)), "Letter" -> {"GPLFactor", q, 1}|>,
  <|"Row" -> 1, "Column" -> 2, "Coefficient" -> (2 + eps)/eps^2, "Letter" -> {"GPLPole", -1}|>,
  <|"Row" -> 2, "Column" -> 1, "Coefficient" -> (eps + 2)/eps, "Letter" -> {"GPLFactor", q, 0}|>,
  <|"Row" -> 2, "Column" -> 2, "Coefficient" -> 1/(eps (1 - 2 eps)), "Letter" -> {"GPLPole", 3/4}|>};
dlogLayer = Join[layer, <|"Incoming" -> dlogIncoming|>];
direct = BuildRationalEpsilonLayerTransport[source, dlogLayer, demand];
modular = BuildRationalEpsilonLayerTransport[source, dlogLayer, demand, "IncomingRoute" -> "Modular", "PrimeCount" -> 3];
FTAssert["a path-free incoming connection takes the exact direct route, accepted, gauge vanishing",
  direct["Status"] === "RationalEpsilonLayerTransportAccepted" && AcceptedRationalEpsilonLayerTransportQ[direct] &&
    direct["Certificate"]["IncomingRoute"] === "IncomingDlogDirect" && direct["GaugeStatus"] === "GaugeVanishes" &&
    TrueQ[direct["Certificate"]["Exact"]]];
(* a REDUCIBLE factor letter (9/16 - u^2 splits over Q) must land on the same irreducible-factor letters in both routes *)
splitLayer = Join[layer, <|"Incoming" -> Append[dlogIncoming, <|"Row" -> 2, "Column" -> 1, "Coefficient" -> (3 + eps)/eps^2, "Letter" -> {"GPLFactor", 9/16 - u^2, 1}|>]|>];
splitDirect = BuildRationalEpsilonLayerTransport[source, splitLayer, demand];
splitModular = BuildRationalEpsilonLayerTransport[source, splitLayer, demand, "IncomingRoute" -> "Modular", "PrimeCount" -> 3];
FTAssert["a reducible GPLFactor letter is decomposed onto the irreducible factors identically by the direct and the modular route (SameQ residues and words)",
  splitDirect["Status"] === "RationalEpsilonLayerTransportAccepted" && splitModular["Status"] === "RationalEpsilonLayerTransportAccepted" &&
    KeySort[splitDirect["KResidues"]] === KeySort[Select[splitModular["KResidues"], ! AllTrue[Flatten[#], # === 0 &] &]] &&
    splitDirect["DemandedWords"] === splitModular["DemandedWords"] &&
    MemberQ[Keys[splitDirect["KResidues"]], {-2, u + 3/4, 0}]];
FTAssert["the sealed modular circuit on the same layer gives SameQ residues and words",
  modular["Certificate"]["IncomingRoute"] === "SealedModularCircuit" && AcceptedRationalEpsilonLayerTransportQ[modular] &&
    KeySort[direct["KResidues"]] === KeySort[Select[modular["KResidues"], ! AllTrue[Flatten[#], # === 0 &] &]] &&
    direct["DemandedWords"] === modular["DemandedWords"]];
FTAssert["the predicate refuses a tampered certificate",
  ! AcceptedRationalEpsilonLayerTransportQ[Join[result, <|"Certificate" -> Join[result["Certificate"], <|"ResidueMismatches" -> 1|>]|>]] &&
  ! AcceptedRationalEpsilonLayerTransportQ[KeyDrop[result, "Certificate"]]];
FTReport[];
