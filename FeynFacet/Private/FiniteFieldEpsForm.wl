(* Exact lifting and verification of simultaneous finite-field strip gauges. *)

(* SymbolQ is not a Wolfram Language builtin. Without this definition
   the record guards below returned unevaluated, never fired, and a
   malformed record (e.g. "Regulator" -> 0) could reach a Pfaffian
   check at a SPECIALIZED regulator (2026-08-20 review, BLOCKER). *)
ClearAll[SymbolQ];
SymbolQ[x_] := MatchQ[x, _Symbol];

(* Public symbols are Clear'ed, not ClearAll'ed: ClearAll also removes
   the usage messages FeynFacet.m defines before loading this file
   (found 2026-08-21). Clear still drops their definitions, so re-Get of
   this file stays clean. *)
Clear[NormalizeEpsFormAffineSample, ReconstructEpsFormStrip, VerifyEpsFormStrip];
ClearAll[
  epsFormFiniteFieldRationalReconstruct,
  epsFormFiniteFieldCombineLists,
  epsFormFiniteFieldCombineCoordinate,
  epsFormFiniteFieldImageQ,
  epsFormFiniteFieldGaugeDenominator
];

NormalizeEpsFormAffineSample::shape =
  "The affine sample and normalization columns have incompatible dimensions.";
NormalizeEpsFormAffineSample::singular =
  "The selected nullspace-coordinate block is singular modulo `1`.";

ReconstructEpsFormStrip::record =
  "The record must contain a valid two-variable Strip, Variables, and Regulator.";
ReconstructEpsFormStrip::data =
  "The modular interpolation records are incomplete or mutually inconsistent.";
ReconstructEpsFormStrip::dlog =
  "The lifted solution is not a dlog form: `1`.";
ReconstructEpsFormStrip::modulus =
  "The combined modulus is too small for unique rational reconstruction.";
ReconstructEpsFormStrip::check =
  "The reconstructed gauge does not satisfy both exact Pfaffian equations.";

VerifyEpsFormStrip::record = ReconstructEpsFormStrip::record;
VerifyEpsFormStrip::solution =
  "The solution must contain Gauge, Alphabet, and ResidueMatrices with compatible dimensions.";

Options[VerifyEpsFormStrip] = {
  "KernelCount" -> Automatic,
  (* "Exact": both Pfaffian identities as rational-function identities
     (Together on every entry; 16-60 s on a hard block).  "Numerical"
     (production guard, user decision 2026-08-22): the same residuals
     evaluated EXACTLY at "Points" random rational points (x, y, eps) --
     ~1 s, a wrong gauge passes with probability ~ degree/10^6 per point;
     the exact statement is then made once by the family certificate. *)
  "Method" -> "Exact",
  "Points" -> 2
};

Options[ReconstructEpsFormStrip] = Join[Options[VerifyEpsFormStrip],
  {"ExactCheck" -> True}];

NormalizeEpsFormAffineSample[
    sample_Association, columns_List, modulus_Integer] := Module[
  {particular, nullspace, nullity, block, parameters, inverse,
   normalizedParticular, normalizedNullspace},
  If[! PrimeQ[modulus] ||
      ! KeyExistsQ[sample, "ParticularSolution"] ||
      ! KeyExistsQ[sample, "NullspaceBasis"],
    Message[NormalizeEpsFormAffineSample::shape]; Return[$Failed]];
  particular = sample["ParticularSolution"];
  nullspace = Normal[sample["NullspaceBasis"]];
  nullity = Length[nullspace];
  If[! VectorQ[particular] ||
      Length[columns] =!= nullity ||
      ! AllTrue[columns, IntegerQ[#] && 1 <= # <= Length[particular] &] ||
      (nullity > 0 &&
        Dimensions[nullspace] =!= {nullity, Length[particular]}),
    Message[NormalizeEpsFormAffineSample::shape]; Return[$Failed]];
  If[nullity === 0,
    Return[<|
      "ParticularSolution" -> particular,
      "NullspaceBasis" -> {},
      "NormalizationColumns" -> {},
      "Modulus" -> modulus
    |>]];
  block = nullspace[[All, columns]];
  If[MatrixRank[block, Modulus -> modulus] =!= nullity,
    Message[NormalizeEpsFormAffineSample::singular, modulus];
    Return[$Failed]];
  parameters = LinearSolve[
    Transpose[block], Mod[-particular[[columns]], modulus],
    Modulus -> modulus];
  inverse = LinearSolve[block, IdentityMatrix[nullity],
    Modulus -> modulus];
  normalizedParticular = Mod[
    particular + Transpose[nullspace].parameters, modulus];
  normalizedNullspace = Mod[inverse.nullspace, modulus];
  If[normalizedParticular[[columns]] =!= ConstantArray[0, nullity] ||
      normalizedNullspace[[All, columns]] =!= IdentityMatrix[nullity],
    Message[NormalizeEpsFormAffineSample::shape]; Return[$Failed]];
  <|
    "ParticularSolution" -> normalizedParticular,
    "NullspaceBasis" -> normalizedNullspace,
    "NormalizationColumns" -> columns,
    "Modulus" -> modulus
  |>
];

epsFormFiniteFieldRationalReconstruct[value_Integer, modulus_Integer] :=
 Module[{a, bound, r0, r1, t0 = 0, t1 = 1, quotient,
   numerator, denominator},
  a = Mod[value, modulus];
  If[a === 0, Return[0]];
  bound = Floor[Sqrt[(modulus - 1)/2]];
  {r0, r1} = {modulus, a};
  While[r1 > bound,
    quotient = Quotient[r0, r1];
    {r0, r1} = {r1, r0 - quotient r1};
    {t0, t1} = {t1, t0 - quotient t1}];
  {numerator, denominator} = {r1, t1};
  If[denominator < 0,
    {numerator, denominator} = {-numerator, -denominator}];
  If[denominator === 0 || Abs[numerator] > bound ||
      denominator > bound || CoprimeQ[numerator, denominator] =!= True ||
      Mod[numerator - a denominator, modulus] =!= 0,
    $Failed,
    numerator/denominator]
];

epsFormFiniteFieldCombineLists[lists_List, length_Integer,
    moduli_List] := Table[
  ChineseRemainder[
    (PadRight[#, length][[index]] &) /@ lists,
    moduli],
  {index, length}
];

epsFormFiniteFieldCombineCoordinate[data_List, moduli_List] := Module[
  {degrees, numeratorLength, denominatorLength},
  degrees = Lookup[data, "Degrees", Missing["Degrees"]];
  If[Length[DeleteDuplicates[degrees]] =!= 1, Return[$Failed]];
  numeratorLength = If[First[degrees][[1]] === -Infinity,
    1, First[degrees][[1]] + 1];
  denominatorLength = First[degrees][[2]] + 1;
  <|
    "Numerator" -> epsFormFiniteFieldCombineLists[
      Lookup[data, "Numerator"], numeratorLength, moduli],
    "Denominator" -> epsFormFiniteFieldCombineLists[
      Lookup[data, "Denominator"], denominatorLength, moduli],
    "Degrees" -> First[degrees]
  |>
];

epsFormFiniteFieldImageQ[integer_Integer, rational_, modulus_Integer] :=
 Module[{denominator = Mod[Denominator[rational], modulus]},
  denominator =!= 0 &&
    Mod[Numerator[rational] PowerMod[denominator, -1, modulus],
      modulus] === Mod[integer, modulus]
];

epsFormFiniteFieldGaugeDenominator[bbar_List, variables_List] := Module[
  {factorPairs, factors, powers},
  factorPairs = Flatten[
    Function[entry,
      Module[{denominator = Denominator[Together[entry]]},
        If[denominator === 1, {},
          Select[Rest[FactorList[denominator]],
            ! NumericQ[First[#]] &]]]] /@ Flatten[bbar],
    1];
  If[factorPairs === {}, Return[1]];
  factors = DeleteDuplicates[factorPairs[[All, 1]], SameQ];
  powers = Table[
    {factor, Max[Cases[factorPairs,
      {candidate_, power_} /; SameQ[candidate, factor] :> power]]},
    {factor, factors}];
  Times @@ ((First[#]^(Last[#] - 1)) & /@
    Select[powers,
      Last[#] > 1 && ! FreeQ[First[#], Alternatives @@ variables] &])
];

VerifyEpsFormStrip[record_Association, solution_Association,
    OptionsPattern[]] := Module[
  {strip, variables, epsilon, e, c, bbar, gauge, alphabet,
   residueMatrices, dimensions, dlog, residuals, entries, kernelCount,
   launched = {}, checkedEntries, seconds, identitiesZero,
   lettersEpsilonFree, residuesKinematicsFree, residuesEpsilonFree,
   dlogForm, canonical, numericalQ, points, pointOK},
  If[! And @@ (KeyExistsQ[record, #] & /@
      {"Strip", "Variables", "Regulator"}) ||
      ! MatchQ[record["Variables"], {_, _}] ||
      ! SymbolQ[record["Regulator"]] ||
      ! epsFormStripShapeQ[record["Strip"]],
    Message[VerifyEpsFormStrip::record]; Return[$Failed]];
  If[! And @@ (KeyExistsQ[solution, #] & /@
      {"Gauge", "Alphabet", "ResidueMatrices"}),
    Message[VerifyEpsFormStrip::solution]; Return[$Failed]];
  strip = record["Strip"];
  variables = record["Variables"];
  epsilon = record["Regulator"];
  {e, c, bbar} = strip;
  gauge = solution["Gauge"];
  alphabet = solution["Alphabet"];
  residueMatrices = solution["ResidueMatrices"];
  dimensions = Dimensions[bbar[[1]]];
  If[Dimensions[gauge] =!= dimensions ||
      Length[residueMatrices] =!= Length[alphabet] ||
      ! AllTrue[residueMatrices, Dimensions[#] === dimensions &],
    Message[VerifyEpsFormStrip::solution]; Return[$Failed]];
  (* Structural conditions (Codex audit 2026-08-21, scoped to the
     pipeline contract on 2026-08-21 evening).  The strip solver's product
     is a DLOG FORM: regulator-free letters and residues free of both
     kinematic variables; the regulator may still appear in the residues
     -- the sector driver removes it afterwards with CANONICA's
     TransformDlogToEpsForm and the family certifier demands the
     epsilon-factorized result (CF254's certified record was built from
     exactly such strips).  The two dlog conditions are checked BEFORE the
     expensive unspecialized Together pass; regulator-freedom of the
     residues is reported separately as the canonical-form statement. *)
  lettersEpsilonFree = FreeQ[alphabet, epsilon];
  residuesKinematicsFree = FreeQ[residueMatrices, Alternatives @@ variables];
  residuesEpsilonFree = FreeQ[residueMatrices, epsilon];
  If[! lettersEpsilonFree || ! residuesKinematicsFree,
    Return[<|
      "ExactPfaffianResidualsZero" -> Missing["NotRunStructuralGateFailed"],
      "ExactPfaffianIdentitiesZero" -> Missing["NotRunStructuralGateFailed"],
      "LettersEpsFree" -> lettersEpsilonFree,
      "ResiduesKinematicsFree" -> residuesKinematicsFree,
      "ResiduesEpsFree" -> residuesEpsilonFree,
      "ConstantResidues" -> residuesKinematicsFree && residuesEpsilonFree,
      "DLogFormCertified" -> False,
      "CanonicalEpsFormCertified" -> False,
      "StructuralFailureReasons" -> Pick[
        {"LettersDependOnRegulator", "ResiduesDependOnKinematics"},
        {! lettersEpsilonFree, ! residuesKinematicsFree}, True],
      "Residuals" -> Missing["NotRunStructuralGateFailed"],
      "ExactCheckSeconds" -> 0,
      "EquationCount" -> 2 Apply[Times, dimensions]
    |>]];
  dlog = Table[
    Together[D[Log[alphabet[[a]]], variables[[mu]]]],
    {a, Length[alphabet]}, {mu, 2}];
  residuals = Table[
    D[gauge, variables[[mu]]] -
      epsilon (e[[mu]].gauge - gauge.c[[mu]]) - bbar[[mu]] +
      epsilon Sum[residueMatrices[[a]] dlog[[a, mu]],
        {a, Length[alphabet]}],
    {mu, 2}];
  entries = Flatten[residuals];
  numericalQ = OptionValue["Method"] === "Numerical";
  If[numericalQ,
    (* exact rational arithmetic at random points; a point on a pole is
       replaced *)
    {seconds, pointOK} = AbsoluteTiming[Module[{done = 0, tries = 0, pt, vals, ok = True},
      While[ok && done < OptionValue["Points"] && tries < 12,
        tries++;
        pt = Thread[Join[variables, {epsilon}] ->
          RandomInteger[{3, 10^6}, 3]/RandomInteger[{10^6, 10^7}, 3]];
        vals = Quiet[Check[entries /. pt, $Failed]];
        If[vals === $Failed || ! FreeQ[vals, ComplexInfinity | Indeterminate | DirectedInfinity],
          Continue[]];
        If[! AllTrue[vals, TrueQ[# == 0] &], ok = False];
        done++];
      ok && done >= OptionValue["Points"]]];
    dlogForm = pointOK && lettersEpsilonFree && residuesKinematicsFree;
    canonical = dlogForm && residuesEpsilonFree;
    Return[<|
      "ExactPfaffianResidualsZero" -> Missing["NotRunNumericalMethod"],
      "ExactPfaffianIdentitiesZero" -> Missing["NotRunNumericalMethod"],
      "NumericalPfaffianResidualsZero" -> pointOK,
      "CheckMethod" -> "Numerical", "Points" -> OptionValue["Points"],
      "LettersEpsFree" -> lettersEpsilonFree,
      "ResiduesKinematicsFree" -> residuesKinematicsFree,
      "ResiduesEpsFree" -> residuesEpsilonFree,
      "ConstantResidues" -> residuesKinematicsFree && residuesEpsilonFree,
      "DLogFormCertified" -> dlogForm,
      "CanonicalEpsFormCertified" -> canonical,
      "StructuralFailureReasons" -> {},
      "Residuals" -> Missing["NotRunNumericalMethod"],
      "ExactCheckSeconds" -> seconds,
      "EquationCount" -> Length[entries]
    |>]];
  kernelCount = facetKernelCount[
    OptionValue["KernelCount"], Max[1, Length[entries]]];
  If[kernelCount > 1 && Length[Kernels[]] < kernelCount,
    launched = Quiet[LaunchKernels[kernelCount - Length[Kernels[]]]]];
  If[kernelCount > 1,
    DistributeDefinitions[entries];
    {seconds, checkedEntries} = AbsoluteTiming[
      ParallelMap[Together, entries, Method -> "FinestGrained",
        DistributedContexts -> Automatic]],
    {seconds, checkedEntries} = AbsoluteTiming[Together /@ entries]];
  If[launched =!= {}, Quiet[CloseKernels[launched]]];
  identitiesZero = AllTrue[checkedEntries, TrueQ[# === 0] &];
  dlogForm = identitiesZero && lettersEpsilonFree && residuesKinematicsFree;
  canonical = dlogForm && residuesEpsilonFree;
  <|
    (* the literal differential-identity result is kept separate from the
       structural conditions; the strip acceptance is DLogFormCertified,
       the epsilon-form statement is CanonicalEpsFormCertified *)
    "ExactPfaffianResidualsZero" -> identitiesZero,
    "ExactPfaffianIdentitiesZero" -> identitiesZero,
    "LettersEpsFree" -> lettersEpsilonFree,
    "ResiduesKinematicsFree" -> residuesKinematicsFree,
    "ResiduesEpsFree" -> residuesEpsilonFree,
    "ConstantResidues" -> residuesKinematicsFree && residuesEpsilonFree,
    "DLogFormCertified" -> dlogForm,
    "CanonicalEpsFormCertified" -> canonical,
    "CheckMethod" -> "Exact",
    "StructuralFailureReasons" -> {},
    "Residuals" -> ArrayReshape[checkedEntries, Dimensions[residuals]],
    "ExactCheckSeconds" -> seconds,
    "EquationCount" -> Length[entries]
  |>
];

ReconstructEpsFormStrip[record_Association, modularData_List,
    OptionsPattern[]] := Module[
  {strip, variables, epsilon, e, c, bbar, primes, coordinateCount,
   combinedModulus, combined, liftedPairs, liftedVector,
   coefficientChecks, numeratorDegrees, gaugeDenominator,
   gaugeDenominatorDegrees, dimensions, upperDimension, lowerDimension,
   gaugeUnknownCount, residueCount, alphabet, residueMatrices, gauge,
   columnIndex, result, verification, liftingSeconds, support, heldOutQ},
  If[! And @@ (KeyExistsQ[record, #] & /@
      {"Strip", "Variables", "Regulator"}) ||
      ! MatchQ[record["Variables"], {_, _}] ||
      ! SymbolQ[record["Regulator"]] ||
      ! epsFormStripShapeQ[record["Strip"]],
    Message[ReconstructEpsFormStrip::record]; Return[$Failed]];
  If[modularData === {} || ! AllTrue[modularData, AssociationQ] ||
      AnyTrue[modularData,
        Lookup[#, "UnresolvedCoordinates", {1}] =!= {} &],
    Message[ReconstructEpsFormStrip::data]; Return[$Failed]];
  primes = Lookup[modularData, "Prime", Missing["Prime"]];
  If[! DuplicateFreeQ[primes] || ! AllTrue[primes, PrimeQ] ||
      ! AllTrue[Subsets[primes, {2}], CoprimeQ @@ # &] ||
      Length[DeleteDuplicates[Lookup[modularData,
        "GaugeUnknownCount"]]] =!= 1 ||
      Length[DeleteDuplicates[Lookup[modularData,
        "FreeResidueCount"]]] =!= 1 ||
      Length[DeleteDuplicates[Lookup[modularData,
        "GaugeNumeratorDegrees"]]] =!= 1 ||
      Length[DeleteDuplicates[Lookup[modularData,
        "NormalizationColumns"]]] =!= 1 ||
      Length[DeleteDuplicates[Length /@
        Lookup[modularData, "Interpolations"]]] =!= 1,
    Message[ReconstructEpsFormStrip::data]; Return[$Failed]];
  (* A2: a held-out-certified interpolation carries the deterministic
     point requirement as metadata only; its certificates are the
     unseen-prime residual and the exact check below *)
  heldOutQ = AllTrue[modularData, Lookup[#, "CertificationMode", "Deterministic"] === "HeldOut" &];
  If[! And @@ Flatten[Map[
      Function[data,
        Lookup[#, "ConstructionNullity", 0] === 1 &&
          Lookup[#, "ValidatedPointCount", -1] ===
            data["SampleCount"] &&
          (heldOutQ || Lookup[#, "ValidatedPointCount", -1] >=
            Lookup[#, "UniquenessPointRequirement", Infinity]) & /@
          data["Interpolations"]],
      modularData]],
    Message[ReconstructEpsFormStrip::data]; Return[$Failed]];
  coordinateCount = Length[First[modularData]["Interpolations"]];
  combinedModulus = Times @@ primes;
  combined = Table[
    epsFormFiniteFieldCombineCoordinate[
      modularData[[All, "Interpolations", coordinate]], primes],
    {coordinate, coordinateCount}];
  If[MemberQ[combined, $Failed],
    Message[ReconstructEpsFormStrip::data]; Return[$Failed]];
  {liftingSeconds, liftedPairs} = AbsoluteTiming[
    Map[
      Function[data,
        <|
          "NumeratorCoefficients" ->
            (epsFormFiniteFieldRationalReconstruct[
                #, combinedModulus] & /@ data["Numerator"]),
          "DenominatorCoefficients" ->
            (epsFormFiniteFieldRationalReconstruct[
                #, combinedModulus] & /@ data["Denominator"])
        |>],
      combined]];
  If[! FreeQ[liftedPairs, $Failed],
    Message[ReconstructEpsFormStrip::modulus]; Return[$Failed]];
  coefficientChecks = MapThread[
    Function[{integers, rationals},
      And[
        And @@ MapThread[
          Function[{integer, rational},
            AllTrue[primes,
              epsFormFiniteFieldImageQ[integer, rational, #] &]],
          {integers["Numerator"],
            rationals["NumeratorCoefficients"]}],
        And @@ MapThread[
          Function[{integer, rational},
            AllTrue[primes,
              epsFormFiniteFieldImageQ[integer, rational, #] &]],
          {integers["Denominator"],
            rationals["DenominatorCoefficients"]}]
      ]],
    {combined, liftedPairs}];
  If[! And @@ coefficientChecks,
    Message[ReconstructEpsFormStrip::data]; Return[$Failed]];
  strip = record["Strip"];
  variables = record["Variables"];
  epsilon = record["Regulator"];
  {e, c, bbar} = strip;
  liftedVector = Together[
      FromDigits[Reverse[#NumeratorCoefficients], epsilon]/
        FromDigits[Reverse[#DenominatorCoefficients], epsilon]] & /@
    liftedPairs;
  numeratorDegrees = First[modularData]["GaugeNumeratorDegrees"];
  gaugeDenominator = epsFormFiniteFieldGaugeDenominator[
    bbar, variables];
  gaugeDenominatorDegrees = Exponent[gaugeDenominator, #] & /@ variables;
  dimensions = Dimensions[bbar[[1]]];
  {upperDimension, lowerDimension} = dimensions;
  (* A3: the gauge numerator support (list of {px, py}); older modular
     data without the key used the full rectangle *)
  support = Lookup[First[modularData], "GaugeSupport",
    Flatten[Table[{px, py}, {px, 0, numeratorDegrees[[1]]},
      {py, 0, numeratorDegrees[[2]]}], 1]];
  If[Length[DeleteDuplicates[Lookup[modularData, "GaugeSupport",
      Missing["GaugeSupport"]]]] =!= 1,
    Message[ReconstructEpsFormStrip::data]; Return[$Failed]];
  gaugeUnknownCount = upperDimension lowerDimension Length[support];
  alphabet = epsFormStripAlphabet[strip, variables, epsilon];
  If[alphabet === $Failed,
    Message[ReconstructEpsFormStrip::record]; Return[$Failed]];
  residueCount = Length[alphabet] upperDimension lowerDimension;
  If[gaugeUnknownCount =!= First[modularData]["GaugeUnknownCount"] ||
      residueCount =!= First[modularData]["FreeResidueCount"] ||
      Length[liftedVector] =!= gaugeUnknownCount + residueCount,
    Message[ReconstructEpsFormStrip::data]; Return[$Failed]];
  columnIndex[i_, j_, k_] :=
    ((i - 1) lowerDimension + (j - 1)) Length[support] + k;
  gauge = Table[
    Sum[liftedVector[[columnIndex[i, j, k]]]
        variables[[1]]^support[[k, 1]] variables[[2]]^support[[k, 2]],
      {k, Length[support]}]/gaugeDenominator,
    {i, upperDimension}, {j, lowerDimension}];
  residueMatrices = ArrayReshape[
    Drop[liftedVector, gaugeUnknownCount],
    {Length[alphabet], upperDimension, lowerDimension}];
  result = <|
    "Status" -> "Reconstructed",
    "Method" -> "SimultaneousFiniteFieldPDE",
    "Gauge" -> gauge,
    "Alphabet" -> alphabet,
    "ResidueMatrices" -> residueMatrices,
    "Primes" -> primes,
    "CombinedModulus" -> combinedModulus,
    "NormalizationColumns" ->
      First[modularData]["NormalizationColumns"],
    "GaugeDenominator" -> gaugeDenominator,
    "GaugeDenominatorDegrees" -> gaugeDenominatorDegrees,
    "GaugeNumeratorDegrees" -> numeratorDegrees,
    "GaugeSupport" -> support,
    "GaugeSupportCount" -> Length[support],
    "CoefficientLiftChecks" -> coefficientChecks,
    "LiftingSeconds" -> liftingSeconds
  |>;
  result = Join[result, <|"CertificationMode" -> If[heldOutQ, "HeldOut", "Deterministic"],
    "LiftedVector" -> liftedVector,
    (* the cheap structural conditions are reported on the unverified lift
       too, so a caller can stop before spending primes or the exact check
       on a lift that can never be a dlog form *)
    "LettersEpsFree" -> FreeQ[alphabet, epsilon],
    "ResiduesKinematicsFree" -> FreeQ[residueMatrices, Alternatives @@ variables],
    "ResiduesEpsFree" -> FreeQ[residueMatrices, epsilon]|>];
  If[! TrueQ[OptionValue["ExactCheck"]],
    Return[Join[result, <|"Status" -> "LiftedUnverified"|>]]];
  verification = VerifyEpsFormStrip[record, result,
    "KernelCount" -> OptionValue["KernelCount"]];
  If[AssociationQ[verification] &&
      Lookup[verification, "StructuralFailureReasons", {}] =!= {},
    Message[ReconstructEpsFormStrip::dlog,
      verification["StructuralFailureReasons"]]; Return[$Failed]];
  If[! AssociationQ[verification] ||
      ! TrueQ[verification["DLogFormCertified"]],
    Message[ReconstructEpsFormStrip::check]; Return[$Failed]];
  Join[KeyDrop[result, "LiftedVector"], KeyDrop[verification, "Residuals"],
    <|"Status" -> "Solved", "ExactDLog" -> True|>]
];
