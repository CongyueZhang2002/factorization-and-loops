(* Conversion of a reconstructed provider-backed multiquadratic strip into
   the compact off-diagonal basis-transformation result.  This layer solves
   nothing: it checks the reconstructed mathematical data, active dlog
   support, and independent residual evidence before publishing an
   installable object. *)

ClearAll[$multiquadraticStripInstallationSchema,
  multiquadraticStripInstallFailure,
  multiquadraticStripInstallationEvidence,
  multiquadraticStripBuildInstallableSolution];

$multiquadraticStripInstallationSchema =
  "InstallableMultiquadraticDLogV1";

multiquadraticStripInstallFailure[status_String,
    detail_Association : <||>] :=
  Join[<|"Status" -> status,
    "Module" -> "MultiquadraticInstallation"|>, detail];

(* Accept either an exact generic residual or provider-backed fresh images.
   Pointwise independence is recomputed from the concrete prime, regulator
   and kinematic points; implementation identities are irrelevant. *)
multiquadraticStripInstallationEvidence[evidence_Association,
    reconstruction_Association, minimumPrimes_Integer?Positive,
    minimumImages_Integer?Positive] := Module[
  {status, checks, trainingKeys, validationKeys, validationPrimes,
   samplePrimes, declaredPrimes, keyValidQ, checkValidQ},
  status = Lookup[evidence, "Status", None];
  If[status === "ExactChannelResidualZero",
    Return[<|"Status" -> "InstallationEvidenceAccepted",
      "Certificate" -> "ExactResidual", "Exact" -> True,
      "ValidationPrimeCount" -> 0, "ValidationImageCount" -> 0|>]];
  If[status =!= "FreshProviderResidualZero",
    Return[multiquadraticStripInstallFailure[
      "IndependentResidualEvidenceInsufficient"]]];
  checks = Lookup[evidence, "Checks", None];
  trainingKeys = Lookup[reconstruction, "TrainingImageKeys", None];
  samplePrimes = Lookup[reconstruction, "SamplePrimes", None];
  If[! MatchQ[checks, {__Association}] || ! ListQ[trainingKeys] ||
      ! DuplicateFreeQ[trainingKeys] ||
      ! VectorQ[samplePrimes, PrimeQ],
    Return[multiquadraticStripInstallFailure[
      "IndependentResidualEvidenceInsufficient"]]];
  keyValidQ[key_] := ListQ[key] && Length[key] === 3 &&
    PrimeQ[key[[1]]] &&
    MatchQ[key[[2]], _Integer | _Rational] &&
    MatchQ[key[[3]], {_Integer, _Integer}];
  If[! AllTrue[trainingKeys, keyValidQ],
    Return[multiquadraticStripInstallFailure[
      "IndependentResidualEvidenceInsufficient"]]];
  checkValidQ[item_Association] := Module[
    {prime, regulatorValue, points, keys, expectedKeys},
    prime = Lookup[item, "Prime", 0];
    regulatorValue = Lookup[item, "RegulatorValue", None];
    points = Lookup[item, "Points", None];
    keys = Lookup[item, "ValidationImageKeys", None];
    If[Lookup[item, "Status", None] =!=
          "ProviderPointwiseResidualZero" ||
        ! TrueQ[Lookup[item, "Passed", False]] || ! PrimeQ[prime] ||
        ! MatchQ[regulatorValue, _Integer | _Rational] ||
        ! MatchQ[points, {{_Integer, _Integer} ..}] ||
        ! ListQ[keys] || ! DuplicateFreeQ[keys],
      Return[False]];
    expectedKeys = ({prime, regulatorValue, #1} &) /@ Mod[points, prime];
    keys === expectedKeys && AllTrue[keys, keyValidQ]
  ];
  If[! AllTrue[checks, checkValidQ],
    Return[multiquadraticStripInstallFailure[
      "IndependentResidualEvidenceInsufficient"]]];
  validationKeys = Flatten[Lookup[checks, "ValidationImageKeys", {}], 1];
  validationPrimes = DeleteDuplicates[Lookup[checks, "Prime"]];
  declaredPrimes = Lookup[evidence, "Primes", validationPrimes];
  If[! DuplicateFreeQ[validationKeys] ||
      Intersection[trainingKeys, validationKeys] =!= {} ||
      Intersection[samplePrimes, validationPrimes] =!= {} ||
      Length[validationPrimes] < minimumPrimes ||
      Sort[declaredPrimes] =!= Sort[validationPrimes] ||
      ! AllTrue[validationPrimes, Function[prime,
        Count[validationKeys,
          key_ /; key[[1]] === prime] >= minimumImages]],
    Return[multiquadraticStripInstallFailure[
      "IndependentResidualEvidenceInsufficient"]]];
  <|"Status" -> "InstallationEvidenceAccepted",
    "Certificate" -> "NumericalResidual", "Exact" -> False,
    "ValidationPrimeCount" -> Length[validationPrimes],
    "ValidationImageCount" -> Length[validationKeys],
    "ValidationPrimes" -> validationPrimes|>
];
multiquadraticStripInstallationEvidence[___] :=
  multiquadraticStripInstallFailure["InvalidInstallationEvidence"];

Options[multiquadraticStripBuildInstallableSolution] = {
  "MinimumUnseenPrimes" -> 2,
  "MinimumImagesPerPrime" -> 3
};

multiquadraticStripBuildInstallableSolution[
    preparation_Association, reconstruction_Association,
    active_Association,
    evidence_Association,
    dimensions : {_Integer?Positive, _Integer?Positive},
    OptionsPattern[]] := Module[
  {minimumPrimes, minimumImages, variables, epsilon, vector, gauge,
   allResidues, gaugeChannels, unpacked, preparationForms,
   computedIndices, indices,
   records, forms, residues, letters, zeroEntryQ, zeroMatrixQ,
   payloadEqualQ,
   potentialValidQ, acceptedEvidence, exactDLog},
  minimumPrimes = OptionValue["MinimumUnseenPrimes"];
  minimumImages = OptionValue["MinimumImagesPerPrime"];
  If[! IntegerQ[minimumPrimes] || minimumPrimes < 1 ||
      ! IntegerQ[minimumImages] || minimumImages < 1,
    Return[multiquadraticStripInstallFailure[
      "InvalidInstallationEvidenceThresholds"]]];
  If[Lookup[reconstruction, "Status", None] =!=
      "ReconstructedRegulatorDependenceV1",
    Return[multiquadraticStripInstallFailure[
      "RegulatorReconstructionUnavailable"]]];
  variables = Lookup[reconstruction, "Variables", None];
  epsilon = Lookup[reconstruction, "Regulator", None];
  vector = Lookup[reconstruction, "Vector", None];
  gauge = Lookup[reconstruction, "Gauge", None];
  allResidues = Lookup[reconstruction, "Residues", None];
  If[! MatchQ[variables, {_Symbol, _Symbol}] || ! SymbolQ[epsilon] ||
      ! VectorQ[vector] || ! MatrixQ[gauge] ||
      Dimensions[gauge] =!= dimensions || ! ListQ[allResidues] ||
      ! AllTrue[allResidues,
        MatrixQ[#1] && Dimensions[#1] === dimensions &] ||
      ! FreeQ[allResidues, Alternatives @@ variables] ||
      ! StringQ[Lookup[reconstruction, "Provider", None]],
    Return[multiquadraticStripInstallFailure[
      "ReconstructedSolutionShapeInvalid"]]];

  (* The vector is the reconstructed mathematical object; the basis-
     transformation block, residues
     and the active dlog payload are only views of that vector in the
     preparation layout.  Re-derive those views at the installation boundary
     instead of trusting separately supplied fields from a stale or mutated
     reconstruction record. *)
  If[! multiquadraticStripPreparationValidQ[preparation] ||
      Lookup[preparation, "Variables", None] =!= variables ||
      Lookup[preparation, "Regulator", None] =!= epsilon ||
      Lookup[preparation, "Dimensions", None] =!= dimensions,
    Return[multiquadraticStripInstallFailure[
      "InstallationPreparationMismatch"]]];
  unpacked = multiquadraticStripUnpackVector[preparation, vector];
  If[Lookup[unpacked, "Status", None] =!=
      "UnpackedMultiquadraticSolution",
    Return[multiquadraticStripInstallFailure[
      "ReconstructedVectorUnpackFailed"]]];
  gaugeChannels = Lookup[reconstruction, "GaugeChannels", None];
  payloadEqualQ[left_, right_] := ListQ[left] && ListQ[right] &&
    Dimensions[left] === Dimensions[right] && Quiet[Check[
      AllTrue[Flatten[left - right],
        TrueQ[Numerator[Together[#1]] === 0] &], False]];
  If[! payloadEqualQ[gauge, unpacked["Gauge"]] ||
      ! payloadEqualQ[gaugeChannels, unpacked["GaugeChannels"]] ||
      ! payloadEqualQ[allResidues, unpacked["Residues"]],
    Return[multiquadraticStripInstallFailure[
      "ReconstructionPayloadMismatch", <|
        "GaugeExactlyEqual" -> payloadEqualQ[gauge, unpacked["Gauge"]],
        "GaugeChannelsExactlyEqual" ->
          payloadEqualQ[gaugeChannels, unpacked["GaugeChannels"]],
        "ResiduesExactlyEqual" ->
          payloadEqualQ[allResidues, unpacked["Residues"]]|>]]];
  preparationForms = Lookup[preparation, "OneForms", None];

  If[Lookup[active, "Status", None] =!=
        "ActivePotentialCertificationV1" ||
      ! TrueQ[Lookup[active, "Certified", False]] ||
      KeyExistsQ[active, "Pending"],
    Return[multiquadraticStripInstallFailure[
      "ActivePotentialCertificationUnavailable"]]];
  zeroEntryQ[value_] := Quiet[Check[
    TrueQ[Numerator[Together[value]] === 0], False]];
  zeroMatrixQ[matrix_] := AllTrue[Flatten[matrix], zeroEntryQ];
  computedIndices = Select[Range[Length[allResidues]],
    ! zeroMatrixQ[allResidues[[#1]]] &];
  indices = Lookup[active, "ActiveIndices", None];
  records = Lookup[active, "ActiveLetterRecords", None];
  forms = Lookup[active, "ActiveOneForms", None];
  residues = Lookup[active, "ActiveResidues", None];
  If[! VectorQ[indices, IntegerQ] || ! DuplicateFreeQ[indices] ||
      indices =!= computedIndices ||
      ! MatchQ[records, {___Association}] || ! ListQ[forms] ||
      ! ListQ[residues] ||
      ! SameQ[Length /@ {indices, records, forms, residues},
        ConstantArray[Length[indices], 4]] ||
      ! SameQ[residues, allResidues[[indices]]] ||
      ! ListQ[preparationForms] ||
      ! payloadEqualQ[forms, preparationForms[[indices]]],
    Return[multiquadraticStripInstallFailure[
      "ActiveSupportPayloadMismatch"]]];
  If[! AllTrue[forms, MatchQ[#1, {_, _}] &] ||
      ! AllTrue[residues,
        MatrixQ[#1] && Dimensions[#1] === dimensions &],
    Return[multiquadraticStripInstallFailure[
      "ActiveSupportShapeInvalid", <|
        "ExpectedMatrixDimensions" -> dimensions,
        "OneFormShapes" -> (Dimensions /@ forms),
        "ResidueShapes" -> (Dimensions /@ residues)|>]]];

  letters = Lookup[#1, "Letter", Missing["NoLetter"]] & /@ records;
  potentialValidQ[record_, form_] := Module[{potential, letter},
    potential = Lookup[record, "Potential", <||>];
    letter = Lookup[record, "Letter", Missing["NoLetter"]];
    AssociationQ[potential] &&
      Lookup[potential, "Status", None] === "PotentialVerified" &&
      TrueQ[Lookup[potential, "Verified", False]] &&
      SameQ[Lookup[potential, "Letter", Missing[]], letter] &&
      payloadEqualQ[{Lookup[potential, "OneForm", Missing[]]}, {form}]
  ];
  If[MemberQ[letters, _Missing] || ! FreeQ[letters, epsilon] ||
      ! FreeQ[forms, epsilon] ||
      ! And @@ MapThread[potentialValidQ, {records, forms}],
    Return[multiquadraticStripInstallFailure[
      "ActiveDLogPayloadUncertified"]]];

  acceptedEvidence = multiquadraticStripInstallationEvidence[evidence,
    reconstruction, minimumPrimes, minimumImages];
  If[Lookup[acceptedEvidence, "Status", None] =!=
      "InstallationEvidenceAccepted", Return[acceptedEvidence]];
  exactDLog = If[TrueQ[acceptedEvidence["Exact"]], True,
    Missing["DeferredToFamilyCertificate"]];
  <|"Status" -> "Solved",
    "Method" -> "DirectMultiquadraticFiniteField",
    "SolutionContract" -> $multiquadraticStripInstallationSchema,
    "Gauge" -> gauge,
    "Alphabet" -> letters,
    "ResidueMatrices" -> residues,
    "OneForms" -> forms,
    "ActiveIndices" -> indices,
    "Variables" -> variables,
    "Regulator" -> epsilon,
    "Dimensions" -> dimensions,
    "Certificate" -> acceptedEvidence["Certificate"],
    "ExactDLog" -> exactDLog,
    "DLogFormCertified" -> exactDLog,
    "OneFormsCertified" -> True,
    "NumericalPfaffianResidualsZero" ->
      ! TrueQ[acceptedEvidence["Exact"]],
    "ExactPfaffianResidualsZero" -> TrueQ[acceptedEvidence["Exact"]],
    "LettersEpsFree" -> True,
    "ResiduesKinematicsFree" -> True,
    "ResiduesEpsFree" -> FreeQ[residues, epsilon],
    "Provider" -> reconstruction["Provider"],
    "Verification" -> evidence,
    "InstallationEvidence" -> acceptedEvidence,
    "Reconstruction" -> KeyTake[reconstruction,
      {"Method", "SamplePrimes", "UnseenPrimes", "RegulatorValues",
       "NormalizationColumns", "DegreeHistogram"}]|>
];
multiquadraticStripBuildInstallableSolution[___] :=
  multiquadraticStripInstallFailure["InvalidInstallationArguments"];
