#!/usr/bin/env wolframscript

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

u = Symbol["Global`curveLayerU"];
eps = Symbol["Global`curveLayerEps"];
(* P differs from a square by u(u-1)(u-2), hence the three rational points
   (0,1), (1,2), (2,5); its cubic coefficient is nonzero, exercising the
   E4Eta2 -> u^2+a3 u/(2 a4) basis shift. *)
curve = u^4 - u^3 + 5 u^2 - 2 u + 1;
prime = 1000033;

rfValue[{numerator_, denominator_}, point_, q_] :=
  Mod[(numerator /. u -> point) PowerMod[denominator /. u -> point, -1, q], q];
rfExpression[{numerator_, denominator_}] := numerator/denominator;
modValue[expression_, point_, q_] := rfValue[
  FeynFacet`Private`rationalLayerModularFunction[expression, u, q], point, q];

(* First exercise the elliptic reduction itself.  The primitive has a repeated
   pole, while an added simple-pole and cohomology term force every output
   component to be present. *)
g = (u - 1)/(u + 3);
ellipticInput = Together[curve D[g, u] + D[curve, u] g/2 +
  (2 + 3 u)/(u + 1) + 5 + 7 u + 11 u^2];
curveImage = FeynFacet`Private`rationalLayerModularPolynomial[curve, u, prime];
inputImage = FeynFacet`Private`rationalLayerModularFunction[ellipticInput, u, prime];
reduction = FeynFacet`Private`rationalLayerEllipticHermite[
  inputImage, curveImage, u, prime];
reducedExpression = With[
  {primitive = rfExpression[reduction["Primitive"]],
   proper = rfExpression[reduction["ProperRemainder"]],
   cohomology = reduction["Cohomology"]},
  Together[curveImage D[primitive, u] + D[curveImage, u] primitive/2 +
    proper + cohomology . {1, u, u^2}]];
FTAssert["quartic Hermite reduction returns a primitive, square-free remainder and three cohomology coordinates",
  reduction["Status"] === "EllipticHermiteReduced" &&
    Length[reduction["Cohomology"]] === 3 &&
    And @@ Table[modValue[ellipticInput - reducedExpression, point, prime] === 0,
      {point, {3, 4, 5}}]];

(* A two-order recurrence.  At the leading order B is d(g Y), hence K=0
   and H is elliptic.  At the next order D H-H S has both rational and
   elliptic channels, exercising the pair multiplication and both Hermite
   reductions.  The extra 3/u term becomes the normalized E4Pole at (0,1),
   while the other rational points fix the base and endpoint sheets. *)
source = <|
  "Dimension" -> 1,
  "Letters" -> {{"E4Omega0"}},
  "Residues" -> {{{1}}},
  "BoundarySelectors" -> <|0 -> {{1}}|>
|>;
diagonal = {{{"GPLPole", -1}, {{1}}}};
forcing = Together[curve D[g, u] + D[curve, u] g/2 + 3/u];
layer = <|
  "Rows" -> {1},
  "PathVariable" -> u,
  "Regulator" -> eps,
  "BasePoint" -> 1,
  "Endpoint" -> 2,
  "Curve" -> curve,
  "CurvePointValues" -> <|0 -> 1, 1 -> 2, 2 -> 5|>,
  "Diagonal" -> diagonal,
  "Incoming" -> {<|"Row" -> 1, "Column" -> 1,
    "Coefficient" -> forcing/eps, "Letter" -> {"E4Omega0"}|>},
  "TargetBoundarySelectors" -> <|0 -> {{1}}|>
|>;
demand = <|"Pairs" -> {{-1, 1}, {0, 1}}|>;
result = BuildRationalEpsilonLayerTransport[source, layer, demand,
  "IncomingRoute" -> "Modular", "WordRepresentation" -> "LazyOperator",
  "PrimeCount" -> 3, "MaximumPrimeCount" -> 12];
curveLabels = FeynFacet`Private`rationalLayerResidueLabel /@
  Keys[Lookup[result, "KResidues", <||>]];
FTAssert["the family-neutral quartic recurrence reconstructs an accepted lazy transport",
  result["Status"] === "RationalEpsilonLayerTransportAccepted" &&
    result["CurveChannel"] && result["WordRepresentation"] === "LazyOperator" &&
    result["GaugeAtEndpoint"][-1] === {{1}} &&
    MemberQ[curveLabels, {"E4Pole", 0}] &&
    AllTrue[{{"E4Omega0"}, {"E4OmegaInf"}, {"E4Eta2"}},
      MemberQ[curveLabels, #] &] &&
    AcceptedRationalEpsilonLayerTransportQ[result] &&
    AcceptedRationalEpsilonLayerTransportQ[result, source, layer, demand]];

prepared = BuildRationalEpsilonLayerTransport[source, layer, demand,
  "IncomingRoute" -> "Modular", "WordRepresentation" -> "LazyOperator",
  "PrepareOnly" -> True];
independentPrime = 1000033;
image = FeynFacet`Private`rationalLayerCurveRecurrenceImage[
  prepared["Laurent"], prepared["Diagonal"], prepared["Source"],
  prepared["Factors"], prepared["PathVariable"], prepared["Curve"],
  prepared["CurvePointValues"], prepared["BasePoint"],
  prepared["CurveBaseValue"], prepared["Orders"], independentPrime,
  prepared["Endpoint"], prepared["CurveEndpointValue"]];

reconstructionMatchesQ = And @@ Flatten[Table[
  With[{exact = Lookup[result["KResidues"], Key[key], {{0}}],
        modular = Lookup[image["KResidues"], Key[key], {{0}}]},
    Mod[Numerator[exact[[1, 1]]] - modular[[1, 1]] Denominator[exact[[1, 1]]],
      independentPrime] === 0],
  {key, Union[Keys[result["KResidues"]], Keys[image["KResidues"]]]}]];
gaugeMatchesQ = And @@ Table[
  With[{exact = result["GaugeAtEndpoint"][order], modular = image["HEndpoint"][order]},
    Mod[Numerator[exact[[1, 1]]] - modular[[1, 1]] Denominator[exact[[1, 1]]],
      independentPrime] === 0], {order, prepared["Orders"]}];

(* Independent pointwise replay of dH+K=B+D H(previous)-H(previous) S. *)
formProduct[h_, form_] := With[
  {h0 = rfExpression[h[[1]]], h1 = rfExpression[h[[2]]],
   f0 = form[[1]], f1 = form[[2]]},
  {h0 f0 + h1 f1, h0 f1 + curveImage h1 f0}];
differentiate[h_] := With[{h0 = rfExpression[h[[1]]], h1 = rfExpression[h[[2]]]},
  {D[h0, u], curveImage D[h1, u] + D[curveImage, u] h1/2}];
kForm[order_] := Total /@ Transpose[Prepend[
  Table[With[{label = FeynFacet`Private`rationalLayerResidueLabel[key],
      coefficient = image["KResidues"][key][[1, 1]]},
    coefficient FeynFacet`Private`rationalLayerLetterPair[
      label, u, curve, prepared["CurvePointValues"]]],
    {key, Select[Keys[image["KResidues"]], First[#] === order &]}], {0, 0}]];
dForm = FeynFacet`Private`rationalLayerLetterPair[
  diagonal[[1, 1]], u, curve, prepared["CurvePointValues"]];
sForm = FeynFacet`Private`rationalLayerLetterPair[
  source["Letters"][[1]], u, curve, prepared["CurvePointValues"]];
previous = {{0, 1}, {0, 1}};
differentialChecks = Reap[Do[
  current = image["HImages"][order][[1, 1]];
  lhs = MapThread[Plus, {differentiate[current], kForm[order]}];
  rhs = MapThread[Plus, {prepared["Laurent"][order][[1, 1]],
    formProduct[previous, dForm], -formProduct[previous, sForm]}];
  Do[Sow[And @@ Table[modValue[lhs[[channel]] - rhs[[channel]], point,
      independentPrime] === 0, {channel, 2}]], {point, {3, 4, 5}}];
  previous = current, {order, prepared["Orders"]}]][[2, 1]];
FTAssert["reconstructed K and endpoint gauge match an unused prime, whose pair recurrence satisfies the differential identity at independent points",
  image["Status"] === "RecurrenceImageEvaluated" && reconstructionMatchesQ &&
    gaugeMatchesQ && And @@ differentialChecks];

FTAssert["quartic channel refusals remain typed at unsupported branch poles and missing rational sheet data",
  FeynFacet`Private`rationalLayerEllipticHermite[
    FeynFacet`Private`rationalLayerModularFunction[1/u, u, prime],
    FeynFacet`Private`rationalLayerModularPolynomial[u (u - 1) (u^2 + 1), u, prime],
    u, prime]["Status"] === "CurveBranchPoleNotSupported" &&
  BuildRationalEpsilonLayerTransport[source,
    Join[layer, <|"Curve" -> u^4 + u + 1, "CurvePointValues" -> <||>|>],
    demand, "IncomingRoute" -> "Modular", "WordRepresentation" -> "LazyOperator"]["Status"] ===
      "CurvePointValueRequired"];

FTReport[];
