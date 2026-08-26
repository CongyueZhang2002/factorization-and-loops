(* Prototypes/MultiquadraticInstallableSolution.wl

   The pure conversion from an already reconstructed/certified
   multiquadratic strip to the existing row-gauge solution ABI.  It is not
   loaded by FeynFacet and has no production caller.  Load it after FeynFacet.

   This prototype intentionally does no solving, interpolation, field
   arithmetic or residual evaluation.  It only validates and compacts facts
   produced by those stages. *)

Begin["FeynFacet`Private`"];

ClearAll[multiquadraticStripInstallFailure,
  multiquadraticStripFreshResidualEvidenceQ,
  multiquadraticStripBuildInstallableSolution];

multiquadraticStripInstallFailure[status_String,
    detail_Association : <||>] :=
  Join[<|"Status" -> status,
    "Module" -> "MultiquadraticInstallableSolution"|>, detail];

(* Accepted probabilistic evidence: all checks are fresh, provider-backed,
   zero residuals; at least minPrimes distinct unseen primes and minChecks
   distinct (epsilon,x,y) images at each prime. *)
multiquadraticStripFreshResidualEvidenceQ[evidence_Association,
    minPrimes_Integer?Positive, minChecks_Integer?Positive] := Module[
  {checks, primes, declaredPrimes, triples},
  If[Lookup[evidence, "Status", None] =!= "FreshProviderResidualZero" ||
      ! StringQ[Lookup[evidence, "Provider", None]] ||
      ! StringQ[Lookup[evidence, "ProviderFingerprint", None]],
    Return[False]];
  checks = Lookup[evidence, "Checks", None];
  If[! MatchQ[checks, {__Association}] ||
      ! AllTrue[checks,
        PrimeQ[Lookup[#1, "Prime", 0]] &&
          MatchQ[Lookup[#1, "RegulatorValue", None], _Integer | _Rational] &&
          MatchQ[Lookup[#1, "Point", None],
            {_Integer | _Rational, _Integer | _Rational}] &&
          TrueQ[Lookup[#1, "ResidualZero", False]] &&
          TrueQ[Lookup[#1, "ExcludedFromTraining", False]] &],
    Return[False]];
  triples = Lookup[checks, {"Prime", "RegulatorValue", "Point"}];
  If[! DuplicateFreeQ[triples], Return[False]];
  primes = DeleteDuplicates[Lookup[checks, "Prime"]];
  declaredPrimes = Lookup[evidence, "Primes", primes];
  Length[primes] >= minPrimes && Sort[declaredPrimes] === Sort[primes] &&
    AllTrue[primes,
      Count[checks, item_ /; Lookup[item, "Prime", None] === #1] >=
        minChecks &]
];
multiquadraticStripFreshResidualEvidenceQ[___] := False;

Options[multiquadraticStripBuildInstallableSolution] = {
  "MinimumUnseenPrimes" -> 2,
  "MinimumChecksPerPrime" -> 3
};

multiquadraticStripBuildInstallableSolution[
    reconstruction_Association, active_Association,
    verification_Association, dimensions : {_Integer?Positive,
      _Integer?Positive}, OptionsPattern[]] := Module[
  {minimumPrimes, minimumChecks, variables, epsilon, gauge, allResidues,
   indices, records, forms, residues, letters, potentialValidQ,
   exactEvidenceQ, pointwiseEvidenceQ, certificate, exactDLog},

  minimumPrimes = OptionValue["MinimumUnseenPrimes"];
  minimumChecks = OptionValue["MinimumChecksPerPrime"];
  If[! IntegerQ[minimumPrimes] || minimumPrimes < 1 ||
      ! IntegerQ[minimumChecks] || minimumChecks < 1,
    Return[multiquadraticStripInstallFailure[
      "InvalidInstallationEvidenceThresholds"]]];
  If[Lookup[reconstruction, "Status", None] =!=
      "ReconstructedRegulatorDependenceV1",
    Return[multiquadraticStripInstallFailure[
      "RegulatorReconstructionUnavailable"]]];
  variables = Lookup[reconstruction, "Variables", None];
  epsilon = Lookup[reconstruction, "Regulator", None];
  gauge = Lookup[reconstruction, "Gauge", None];
  allResidues = Lookup[reconstruction, "Residues", None];
  If[! MatchQ[variables, {_Symbol, _Symbol}] || ! SymbolQ[epsilon] ||
      ! MatrixQ[gauge] || Dimensions[gauge] =!= dimensions ||
      ! ListQ[allResidues] ||
      ! AllTrue[allResidues, MatrixQ[#1] && Dimensions[#1] === dimensions &] ||
      ! FreeQ[allResidues, Alternatives @@ variables],
    Return[multiquadraticStripInstallFailure[
      "ReconstructedSolutionShapeInvalid"]]];

  If[Lookup[active, "Status", None] =!=
        "ActivePotentialCertificationV1" ||
      ! TrueQ[Lookup[active, "Certified", False]] ||
      KeyExistsQ[active, "Pending"],
    Return[multiquadraticStripInstallFailure[
      "ActivePotentialCertificationUnavailable"]]];
  indices = Lookup[active, "ActiveIndices", None];
  records = Lookup[active, "ActiveLetterRecords", None];
  forms = Lookup[active, "ActiveOneForms", None];
  residues = Lookup[active, "ActiveResidues", None];
  If[! VectorQ[indices, IntegerQ] || ! DuplicateFreeQ[indices] ||
      ! AllTrue[indices, 1 <= #1 <= Length[allResidues] &] ||
      ! MatchQ[records, {___Association}] || ! ListQ[forms] ||
      ! ListQ[residues] ||
      ! SameQ[Length /@ {indices, records, forms, residues},
        ConstantArray[Length[indices], 4]] ||
      ! SameQ[residues, allResidues[[indices]]],
    Return[multiquadraticStripInstallFailure[
      "ActiveSupportPayloadMismatch"]]];
  If[! AllTrue[forms, MatchQ[#1, {_, _}] &] ||
      ! AllTrue[residues,
        MatrixQ[#1] && Dimensions[#1] === dimensions &],
    Return[multiquadraticStripInstallFailure[
      "ActiveSupportShapeInvalid"]]];

  (* Map explicitly: Lookup[{}, key, default] treats the empty list as an
     empty rule set and returns the scalar default, while an empty active
     alphabet must remain the empty list. *)
  letters = Lookup[#1, "Letter", Missing["NoLetter"]] & /@ records;
  potentialValidQ[record_, form_] := Module[{potential, expectedKey},
    potential = Lookup[record, "Potential", <||>];
    expectedKey = multiquadraticStripPotentialPairKey[
      Lookup[record, "Letter", Missing["NoLetter"]], form,
      variables, epsilon];
    AssociationQ[potential] &&
      Lookup[potential, "Status", None] === "PotentialVerified" &&
      TrueQ[Lookup[potential, "Verified", False]] &&
      StringQ[expectedKey] &&
      Lookup[potential, "PairKey", None] === expectedKey];
  If[MemberQ[letters, _Missing] || ! FreeQ[letters, epsilon] ||
      ! FreeQ[forms, epsilon] ||
      ! And @@ MapThread[potentialValidQ, {records, forms}],
    Return[multiquadraticStripInstallFailure[
      "ActiveDLogPayloadUncertified"]]];

  exactEvidenceQ = Lookup[verification, "Status", None] ===
    "ExactChannelResidualZero";
  pointwiseEvidenceQ = multiquadraticStripFreshResidualEvidenceQ[
    verification, minimumPrimes, minimumChecks];
  If[! exactEvidenceQ && ! pointwiseEvidenceQ,
    Return[multiquadraticStripInstallFailure[
      "IndependentResidualEvidenceInsufficient"]]];
  certificate = If[exactEvidenceQ, "ExactResidual", "NumericalResidual"];
  exactDLog = If[exactEvidenceQ, True,
    Missing["DeferredToFamilyCertificate"]];

  <|"Status" -> "Solved",
    "Method" -> "DirectMultiquadraticFiniteField",
    "SolutionContract" -> "InstallableMultiquadraticDLogV1",
    "Gauge" -> gauge,
    "Alphabet" -> letters,
    "ResidueMatrices" -> residues,
    "OneForms" -> forms,
    "ActiveIndices" -> indices,
    "Variables" -> variables,
    "Regulator" -> epsilon,
    "Dimensions" -> dimensions,
    "Certificate" -> certificate,
    "ExactDLog" -> exactDLog,
    "DLogFormCertified" -> exactDLog,
    "NumericalPfaffianResidualsZero" -> pointwiseEvidenceQ,
    "ExactPfaffianResidualsZero" -> exactEvidenceQ,
    "LettersEpsFree" -> True,
    "ResiduesKinematicsFree" -> True,
    "ResiduesEpsFree" -> FreeQ[residues, epsilon],
    "Verification" -> verification,
    "Reconstruction" -> KeyTake[reconstruction,
      {"Method", "SamplePrimes", "UnseenPrime", "RegulatorValues",
       "NormalizationColumns", "DegreeHistogram"}]|>
];
multiquadraticStripBuildInstallableSolution[___] :=
  multiquadraticStripInstallFailure["InvalidInstallationArguments"];

End[];
