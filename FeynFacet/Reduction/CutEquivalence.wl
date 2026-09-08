
(* Exact equivalences of powered cut integrals under affine loop changes.
   Canonical loop coordinates are independent, positively oriented cut
   momenta. Only unit-Jacobian maps are used; uncut prescriptions, cut
   derivatives, external kinematics and normalization stay in the key.
   No equality is inferred from a denominator support or a mode label. *)

Clear[FindCutIntegralEquivalences];
ClearAll[cutEquivalenceFamilyName, cutEquivalenceIntegral, cutEquivalenceVector,
  cutEquivalenceScalarProducts, cutEquivalenceTopology,
  cutEquivalenceFrames, cutEquivalenceSignature];

cutEquivalenceFamilyName[x_] := If[StringQ[x], x, SymbolName[x]];

cutEquivalenceIntegral[expr_] := Replace[expr,
  (h_Symbol)[f_, powers_List] /; SymbolName[h] === "GLI" :>
    FeynCalc`GLI[If[StringQ[f], f, SymbolName[f]], powers]];

cutEquivalenceVector[q_, momenta_List] := Module[{v},
  v = Coefficient[Expand[q], #] & /@ momenta;
  If[! VectorQ[v, MatchQ[#, _Integer | _Rational] &] ||
      Expand[q - v.momenta] =!= 0, Return[$Failed]];
  v
];

cutEquivalenceScalarProducts[expr_, momenta_List, gram_] :=
  Expand[expr /. FeynCalc`Pair[FeynCalc`Momentum[a_, ___],
      FeynCalc`Momentum[b_, ___]] :>
    With[{va = cutEquivalenceVector[a, momenta],
      vb = cutEquivalenceVector[b, momenta]},
      If[MemberQ[{va, vb}, $Failed], $Failed, va.gram.vb]]];

cutEquivalenceTopology[record_Association, normalization_] := Module[
  {top, momenta, loops, external, n, gram, descriptors, polynomials,
   kinematics, cutVectors, indices, directions},
  top = Lookup[record, "Topology", None];
  If[! MatchQ[top, _FeynCalc`FCTopology], Return[$Failed]];
  loops = top[[3]]; external = top[[4]];
  momenta = Join[loops, external]; n = Length[momenta];
  gram = Table[cutScalarProduct[Min[i, j], Max[i, j]], {i, n}, {j, n}];
  descriptors = propagatorDescriptor[#, {}] & /@ top[[2]];
  If[MemberQ[descriptors, $Failed] ||
      Length[Cases[top[[2]], _FeynCalc`StandardPropagatorDenominator, Infinity]] =!= Length[top[[2]]], Return[$Failed]];
  polynomials = cutEquivalenceScalarProducts[#, momenta, gram] & /@
    Lookup[descriptors, "UnitCore"];
  kinematics = cutEquivalenceScalarProducts[#, momenta, gram] & /@ top[[5]];
  indices = Lookup[record, "CutIndices", {}];
  directions = Lookup[record, "CutDirections", {}];
  cutVectors = cutEquivalenceVector[#, momenta] & /@
    Lookup[record, "CutMomenta", {}];
  If[Length[indices] =!= Length[cutVectors] ||
      Length[directions] =!= Length[indices] || ! DuplicateFreeQ[indices] ||
      ! AllTrue[indices, IntegerQ[#] && 1 <= # <= Length[polynomials] &] ||
      ! AllTrue[directions, MemberQ[{1, -1}, #] &] ||
      MemberQ[cutVectors, $Failed] || ! FreeQ[polynomials, $Failed],
    Return[$Failed]];
  <|"Family" -> cutEquivalenceFamilyName[top[[1]]], "Loops" -> loops,
    "External" -> external, "GramMatrix" -> gram,
    "KinematicRules" -> kinematics, "PropagatorPolynomials" -> polynomials,
    "Prescriptions" -> (Last[#[[4]]] & /@
      Cases[top[[2]], _FeynCalc`StandardPropagatorDenominator, Infinity]),
    "CutIndices" -> indices,
    "OrientedCutMomenta" -> MapThread[Times, {directions, cutVectors}],
    "Normalization" -> Lookup[record, "Normalization", normalization]|>
];

cutEquivalenceFrames[top_Association] := Module[
  {l, n, cuts, choices, frames = {}, a, b, t, mappedGram, rules},
  l = Length[top["Loops"]]; n = Length[top["GramMatrix"]];
  cuts = top["OrientedCutMomenta"];
  choices = Flatten[Permutations /@ Subsets[Range[Length[cuts]], {l}], 1];
  Do[
    a = cuts[[chosen, 1 ;; l]];
    If[! MemberQ[{1, -1}, Det[a]], Continue[]];
    b = cuts[[chosen, l + 1 ;; n]];
    t = Join[Join[Inverse[a], -Inverse[a].b, 2],
      Join[ConstantArray[0, {n - l, l}], IdentityMatrix[n - l], 2]];
    mappedGram = Expand[t.top["GramMatrix"].Transpose[t]];
    rules = DeleteDuplicates[Thread[
      Flatten[top["GramMatrix"]] -> Flatten[mappedGram]]];
    AppendTo[frames, <|"ChosenCutMomenta" -> chosen,
      "LoopTransformation" -> t[[1 ;; l]],
      "CutMomenta" -> (Expand[#.t] & /@ cuts),
      "Polynomials" -> (Expand[# /. rules /. top["KinematicRules"]] & /@
        top["PropagatorPolynomials"])|>],
    {chosen, choices}];
  frames
];

cutEquivalenceSignature[integral_, top_, frames_] := Module[
  {powers, cuts, ordinary, candidates, key},
  powers = integral[[2]]; cuts = top["CutIndices"];
  If[Length[powers] =!= Length[top["PropagatorPolynomials"]] ||
      ! VectorQ[powers, IntegerQ], Return[$Failed]];
  If[AnyTrue[cuts, powers[[#]] <= 0 &],
    Return[<|"Zero" -> True, "Key" -> {"MissingReverseUnitarityCut"}|>]];
  If[frames === {}, Return[<|"Zero" -> False,
    "Key" -> {"UnmappedIntegral", integral}, "Frame" -> Missing["CutRank"]|>]];
  ordinary = Complement[Range[Length[powers]], cuts];
  candidates = Table[
    key = {top["External"], Sort[top["KinematicRules"]],
      top["Normalization"],
      Sort[MapThread[List, {frame["CutMomenta"], powers[[cuts]],
        frame["Polynomials"][[cuts]]}]],
      Sort[Select[Table[{frame["Polynomials"][[i]],
          top["Prescriptions"][[i]], powers[[i]]}, {i, ordinary}],
        Last[#] =!= 0 &]]};
    <|"Zero" -> False, "Key" -> key, "Frame" -> frame|>,
    {frame, frames}];
  First[SortBy[candidates, #["Key"] &]]
];

Options[FindCutIntegralEquivalences] = {
  "PreferredMasterIntegrals" -> {}, "Normalization" -> Automatic};

FindCutIntegralEquivalences[integrals_List, records_List,
    OptionsPattern[]] := Catch@Module[
  {ms, tops, selectedRecords, frames, signatures, groups, mappings = {},
   representatives = {}, preferred, rep, repSig, sig, original, fam,
   normalization = OptionValue["Normalization"]},
  If[normalization === Automatic,
    Throw[Failure["NormalizationRequired", <|
      "MessageTemplate" -> "Supply the common integral normalization explicitly."|>]]];
  ms = cutEquivalenceIntegral /@ integrals;
  If[! AllTrue[ms, MatchQ[#, FeynCalc`GLI[_String, {_Integer ..}]] &] ||
      ! DuplicateFreeQ[ms], Throw[Failure["InvalidMasterIntegrals", <||>]]];
  preferred = cutEquivalenceIntegral /@ OptionValue["PreferredMasterIntegrals"];
  selectedRecords = Select[records,
    MemberQ[DeleteDuplicates[ms[[All, 1]]], cutEquivalenceFamilyName[#["Topology"][[1]]]] &];
  tops = cutEquivalenceTopology[#, normalization] & /@ selectedRecords;
  If[MemberQ[tops, $Failed], Throw[Failure["UnsupportedCutTopology", <||>]]];
  tops = Association[(#["Family"] -> #) & /@ tops];
  If[Complement[ms[[All, 1]], Keys[tops]] =!= {},
    Throw[Failure["MissingCutTopology", <||>]]];
  frames = cutEquivalenceFrames /@ tops;
  signatures = Association[Table[
    fam = m[[1]]; sig = cutEquivalenceSignature[m, tops[fam], frames[fam]];
    If[sig === $Failed, Throw[Failure["InvalidPoweredCutIntegral", <|"Integral" -> m|>]]];
    m -> sig, {m, ms}]];
  groups = GatherBy[ms, signatures[#]["Key"] &];
  Do[
    rep = First[SortBy[group, {If[MemberQ[preferred, #], 0, 1] &,
      LeafCount, ToString[#, InputForm] &}]];
    repSig = signatures[rep]; AppendTo[representatives, rep];
    Do[
      original = integrals[[First@FirstPosition[ms, m]]];
      AppendTo[mappings, <|"Source" -> original,
        "Representative" -> integrals[[First@FirstPosition[ms, rep]]],
        "Factor" -> If[TrueQ[signatures[m]["Zero"]], 0, 1],
        "SourceFrame" -> KeyTake[Replace[Lookup[signatures[m], "Frame", <||>], _Missing -> <||>],
          {"ChosenCutMomenta", "LoopTransformation"}],
        "RepresentativeFrame" -> KeyTake[Replace[Lookup[repSig, "Frame", <||>], _Missing -> <||>],
          {"ChosenCutMomenta", "LoopTransformation"}]|>],
      {m, group}],
    {group, groups}];
  <|"DataType" -> "CutIntegralEquivalences", "SchemaVersion" -> 1,
    "Method" -> "ExactAffineLoopMomentumChanges",
    "InputCount" -> Length[ms], "EquivalenceClassCount" -> Length[groups],
    "Normalization" -> normalization, "Mappings" -> mappings,
    "RepresentativeMasterIntegrals" ->
      (integrals[[First@FirstPosition[ms, #]]] & /@ representatives),
    "UnmappedMasterIntegrals" ->
      Select[ms, MatchQ[Lookup[signatures[#], "Frame", None], _Missing] &],
    "MinimalIBPMasterCountDetermined" -> False|>
];
