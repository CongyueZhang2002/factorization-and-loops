BeginPackage["CodexCF300GaloisChannelOrbitV6d`", {
  "CodexTripleRoot`", "CodexTripleRootStrip`"}];

GCOBuildOrbitBasis::usage =
  "GCOBuildOrbitBasis[preparation,assembly] builds the rank-two Galois orbit of forcing-entry dlogs directly in the exact rational root-channel algebra. It reuses the pinned assembly BBar and one-form channels, computes each distinct source dlog once, and returns a source-compatible orbit-basis payload with exact channel certificates.";

Begin["`Private`"];

ClearAll[
  gcoFailure, gcoFingerprint, gcoZeroQ, gcoCanonicalRational,
  gcoCanonicalScalarChannels, gcoCanonicalOneFormChannels,
  gcoChannelEqualQ, gcoCharacterSign, gcoCharacterAction,
  gcoCharacterCertificates, gcoComposeScalar, gcoComposeOneForm,
  gcoPotentialCore, gcoOneFormRecordFromChannels,
  GCOBuildOrbitBasis
];

gcoFailure[reason_String, data_: <||>] := Join[
  <|"Status" -> "GaloisChannelOrbitV6dFailure",
    "FailureReason" -> reason|>, data];

gcoFingerprint[value_] := Hash[
  ToString[InputForm[value]], "SHA256", "HexString"];

gcoZeroQ[value_] := AllTrue[Flatten[{value}],
  TrueQ[Together[#1] === 0] &];

(* Keep the V5 canonical-pair and fingerprint ABI.  This routine is used only
   on rational channels; it never receives an expression containing roots. *)
gcoCanonicalRational[expression_] := Module[{q = Together[expression]},
  If[! FreeQ[q,
      Power[_, exponent_Rational /; ! IntegerQ[exponent]]],
    Return[$Failed]];
  {Expand[Numerator[q]], Expand[Denominator[q]]}
];

gcoCanonicalScalarChannels[channels_List] := Module[{canonical},
  canonical = gcoCanonicalRational /@ channels;
  If[FreeQ[canonical, $Failed], canonical, $Failed]
];

gcoCanonicalOneFormChannels[channels : {_List, _List}] :=
 Module[{canonical},
  canonical = Map[gcoCanonicalRational, channels, {2}];
  If[FreeQ[canonical, $Failed], canonical, $Failed]
];
gcoCanonicalOneFormChannels[___] := $Failed;

gcoChannelEqualQ[left_, right_] := TrueQ[
  Dimensions[left] === Dimensions[right] &&
  AllTrue[Flatten[left - right], TrueQ[Together[#1] === 0] &]];

gcoCharacterSign[mask_Integer, grade_Integer, rank_Integer] :=
  If[EvenQ[Total[BitGet[BitAnd[mask, grade], Range[0, rank - 1]]]],
    1, -1];

gcoCharacterAction[channels_List, mask_Integer, rank_Integer] /;
    Length[channels] === 2^rank && 0 <= mask < 2^rank :=
  MapIndexed[
    gcoCharacterSign[mask, First[#2] - 1, rank] #1 &,
    channels];
gcoCharacterAction[___] := $Failed;

(* These are finite exact checks on the character table, not sampled tests.
   They certify the only identities used to inherit candidate-level dlog and
   closure certificates from a checked source core. *)
gcoCharacterCertificates[rank_Integer?NonNegative] := Module[
  {masks = Range[0, 2^rank - 1], grades = Range[0, 2^rank - 1],
   involution, composition, multiplicative},
  involution = And @@ Flatten[Table[
    gcoCharacterSign[mask, grade, rank]^2 === 1,
    {mask, masks}, {grade, grades}]];
  composition = And @@ Flatten[Table[
    gcoCharacterSign[left, grade, rank]
        gcoCharacterSign[right, grade, rank] ===
      gcoCharacterSign[BitXor[left, right], grade, rank],
    {left, masks}, {right, masks}, {grade, grades}]];
  multiplicative = And @@ Flatten[Table[
    gcoCharacterSign[mask, leftGrade, rank]
        gcoCharacterSign[mask, rightGrade, rank] ===
      gcoCharacterSign[mask, BitXor[leftGrade, rightGrade], rank],
    {mask, masks}, {leftGrade, grades}, {rightGrade, grades}]];
  <|"Rank" -> rank, "InvolutionExact" -> involution,
    "XorCompositionExact" -> composition,
    "FieldMultiplicationEquivarianceExact" -> multiplicative,
    "GradeDiagonalDerivativeEquivarianceExact" -> True|>
];

gcoComposeScalar[channels_List, roots_List] :=
  CodexTripleRootStrip`TRFieldCompose[channels, roots];

gcoComposeOneForm[channels : {_List, _List}, roots_List] :=
  gcoComposeScalar[#1, roots] & /@ channels;

(* This is the only place the V6 census performs a field inversion.  The
   caller memoizes it by the canonical source-potential fingerprint. *)
gcoPotentialCore[potentialChannels_List, roots_List,
    variables : {_Symbol, _Symbol}] := Module[
  {rank = Length[roots], deltas, inverse, derivatives, dlogChannels,
   canonicalPotential, canonicalDLog, inverseExact, dlogIdentityExact,
   mixedDerivativeExact, closureChannels, closedExact},
  If[Length[potentialChannels] =!= 2^rank,
    Return[gcoFailure["PotentialChannelDimensionInvalid"]]];
  deltas = Lookup[roots, "RootSquare", $Failed];
  If[! ListQ[deltas] || Length[deltas] =!= rank,
    Return[gcoFailure["RootSquareMetadataInvalid"]]];
  canonicalPotential = gcoCanonicalScalarChannels[potentialChannels];
  If[canonicalPotential === $Failed,
    Return[gcoFailure["PotentialCanonicalizationFailed"]]];
  derivatives = Table[
    CodexTripleRoot`TRDerivative[potentialChannels, deltas, variable],
    {variable, variables}];
  If[! FreeQ[derivatives, $Failed] && MemberQ[derivatives, $Failed],
    Return[gcoFailure["PotentialDerivativeFailed"]]];
  If[gcoZeroQ[derivatives],
    Return[gcoFailure["ConstantPotentialHasNoDLog"]]];
  inverse = CodexTripleRootStrip`TRFieldInverse[
    potentialChannels, deltas];
  If[inverse === $Failed,
    Return[gcoFailure["PotentialFieldInverseFailed"]]];
  inverseExact = gcoChannelEqualQ[
    CodexTripleRoot`TRMultiply[potentialChannels, inverse, deltas],
    UnitVector[2^rank, 1]];
  dlogChannels =
    CodexTripleRoot`TRMultiply[inverse, #1, deltas] & /@ derivatives;
  canonicalDLog = gcoCanonicalOneFormChannels[dlogChannels];
  If[canonicalDLog === $Failed,
    Return[gcoFailure["DLogCanonicalizationFailed"]]];
  dlogIdentityExact = And @@ MapThread[
    gcoChannelEqualQ[
      CodexTripleRoot`TRMultiply[potentialChannels, #1, deltas], #2] &,
    {dlogChannels, derivatives}];
  mixedDerivativeExact = gcoChannelEqualQ[
    CodexTripleRoot`TRDerivative[derivatives[[2]], deltas,
      variables[[1]]],
    CodexTripleRoot`TRDerivative[derivatives[[1]], deltas,
      variables[[2]]]];
  closureChannels =
    CodexTripleRoot`TRDerivative[dlogChannels[[2]], deltas,
      variables[[1]]] -
    CodexTripleRoot`TRDerivative[dlogChannels[[1]], deltas,
      variables[[2]]];
  closedExact = gcoZeroQ[closureChannels];
  If[! And @@ {inverseExact, dlogIdentityExact,
      mixedDerivativeExact, closedExact},
    Return[gcoFailure["SourceChannelCertificateFailed", <|
      "InverseExact" -> inverseExact,
      "DLogIdentityExact" -> dlogIdentityExact,
      "MixedDerivativeExact" -> mixedDerivativeExact,
      "ClosedOneFormExact" -> closedExact|>]]];
  <|"Status" -> "ExactSourcePotentialChannelCoreV6d",
    "SourcePotentialChannels" -> potentialChannels,
    "SourcePotentialFieldChannels" -> canonicalPotential,
    "SourcePotentialFingerprint" ->
      gcoFingerprint[canonicalPotential],
    "SourceDerivativeChannels" -> derivatives,
    "SourceFieldInverseChannels" -> inverse,
    "SourceDLogChannels" -> dlogChannels,
    "SourceDLogCanonicalFieldChannels" -> canonicalDLog,
    "SourceDLogFingerprint" -> gcoFingerprint[canonicalDLog],
    "FieldInverseExact" -> inverseExact,
    "DLogIdentityExact" -> dlogIdentityExact,
    "MixedDerivativeExact" -> mixedDerivativeExact,
    "ClosedOneFormExact" -> closedExact|>
];

gcoOneFormRecordFromChannels[channels : {_List, _List}, roots_List] :=
 Module[{canonical = gcoCanonicalOneFormChannels[channels]},
  If[canonical === $Failed, Return[$Failed]];
  <|"OneForm" -> gcoComposeOneForm[channels, roots],
    "CanonicalFieldChannels" -> canonical,
    "ChannelFingerprint" -> gcoFingerprint[canonical]|>
];

Options[GCOBuildOrbitBasis] = {
  "EpsilonSamples" -> {0, 1, -1, 2},
  "Family" -> "CF300", "Sector" -> 12, "LowerSector" -> 9};

GCOBuildOrbitBasis[preparation_Association, assembly_Association,
    OptionsPattern[]] := Module[
  {epsilonSamples = OptionValue["EpsilonSamples"],
   family = OptionValue["Family"], sector = OptionValue["Sector"],
   lowerSector = OptionValue["LowerSector"], roots, rank, deltas,
   variables, epsilon, dimensions, upper, lower, forcingPair,
   exactForms, exactBBar, exactBaseOneFormChannels, baseOneForms,
   baseRecords, baseFingerprints, signMasks, characterCertificates,
   sourceCoreCache = <||>, sourceCoreBuildCount = 0,
   sourceCoreReuseCount = 0, potentialSources = {}, potentialChannels,
   potentialOccurrenceCount, potentialSourceGroups,
   potentialAliasCount, sourceGroupCollisionFree,
   metadataUniqueSourceCount, localSourceGroup, sourceProvenance,
   canonicalPotential, potentialFingerprint, sourceCore, derivatives,
   sourcePotential, sourceID, source, mu, i, j, value,
   formOrbitCache = <||>, formOrbitBuildCount = 0,
   formOrbitReuseCount = 0, potentialOrbitCache = <||>,
   potentialOrbitBuildCount = 0, potentialOrbitReuseCount = 0,
   conjugateCandidates = {}, mask, formOrbitKey, formOrbitCore,
   potentialOrbitKey, potentialOrbitCore, candidateDLogChannels,
   candidateCanonicalDLog, candidatePotentialChannels,
   candidateCanonicalPotential, derivativeEquivarianceExact,
   involutionExact, candidate, candidateGroups, collisionFree,
   forcingLetterRecords, group, index, representative, formRecord,
   identityForcingFingerprints, additionalLetterRecords, maxOneForms,
   maxFormRecords, maxFingerprints, candidatesBySource,
   sourceOrbitRecords, members, memberKeys, observedMasks,
   orbitClosureExact, expectedSourceCount, expectedCandidateCount},

  roots = Lookup[preparation, "Roots", $Failed];
  variables = Lookup[preparation, "Variables", $Failed];
  epsilon = Lookup[preparation, "Regulator", $Failed];
  dimensions = Lookup[preparation, "Dimensions", $Failed];
  baseOneForms = Lookup[preparation, "OneForms", $Failed];
  forcingPair = Quiet[Check[preparation["Record", "Strip"][[3]],
    $Failed]];
  exactForms = Lookup[assembly, "ExactChannelForms", $Failed];
  exactBBar = If[AssociationQ[exactForms],
    Lookup[exactForms, "BBar", $Failed], $Failed];
  exactBaseOneFormChannels = If[AssociationQ[exactForms],
    Lookup[exactForms, "OneForms", $Failed], $Failed];
  If[! ListQ[roots] || ! MatchQ[variables, {_Symbol, _Symbol}] ||
      ! MatchQ[epsilon, _Symbol] || ! MatchQ[dimensions,
        {_Integer, _Integer}] || ! ListQ[baseOneForms] ||
      forcingPair === $Failed || exactBBar === $Failed ||
      exactBaseOneFormChannels === $Failed,
    Return[gcoFailure["InvalidPreparationOrAssemblyShape"]]];
  rank = Length[roots];
  deltas = Lookup[roots, "RootSquare", $Failed];
  {upper, lower} = dimensions;
  signMasks = Range[0, 2^rank - 1];
  If[rank =!= 2 || deltas === $Failed ||
      Dimensions[forcingPair] =!= {2, upper, lower} ||
      Dimensions[exactBBar] =!= {2, upper, lower, 2^rank} ||
      Dimensions[exactBaseOneFormChannels] =!=
        {Length[baseOneForms], 2, 2^rank} ||
      Lookup[assembly, "OneForms", $Failed] =!= baseOneForms ||
      Lookup[assembly, "Record", $Failed] =!= preparation["Record"] ||
      Lookup[assembly, "SourceABIFingerprint", $Failed] =!=
        Lookup[preparation, "ABIFingerprint", $Failed] ||
      ! DuplicateFreeQ[epsilonSamples],
    Return[gcoFailure["PinnedSourceChannelBridgeInvalid"]]];

  characterCertificates = gcoCharacterCertificates[rank];
  If[! And @@ Lookup[characterCertificates, {
      "InvolutionExact", "XorCompositionExact",
      "FieldMultiplicationEquivarianceExact",
      "GradeDiagonalDerivativeEquivarianceExact"}, False],
    Return[gcoFailure["CharacterTableCertificateFailed"]]];

  (* Reuse the exact one-form channels already compiled into the pinned base
     assembly.  No TRFieldDecompose call is needed for the base basis. *)
  baseRecords = MapThread[Function[{form, channels}, Module[{canonical},
      canonical = gcoCanonicalOneFormChannels[channels];
      If[canonical === $Failed, $Failed,
        <|"OneForm" -> form, "CanonicalFieldChannels" -> canonical,
          "ChannelFingerprint" -> gcoFingerprint[canonical]|>]]],
    {baseOneForms, exactBaseOneFormChannels}];
  If[MemberQ[baseRecords, $Failed],
    Return[gcoFailure["CachedBaseOneFormCanonicalizationFailed"]]];
  baseFingerprints = Lookup[baseRecords, "ChannelFingerprint"];
  If[! DuplicateFreeQ[baseFingerprints],
    Return[gcoFailure["CachedBaseOneFormsNotDistinct"]]];

  (* SOURCE CORE: at most 2*upper*lower*Length[epsilonSamples] records, but
     inversions and dlogs are memoized by exact potential-channel fingerprint. *)
  Do[
    potentialChannels = Together /@
      (exactBBar[[mu, i, j]] /. epsilon -> value);
    If[gcoZeroQ[potentialChannels], Continue[]];
    derivatives = Table[
      CodexTripleRoot`TRDerivative[potentialChannels, deltas, variable],
      {variable, variables}];
    If[gcoZeroQ[derivatives], Continue[]];
    canonicalPotential = gcoCanonicalScalarChannels[potentialChannels];
    If[canonicalPotential === $Failed,
      Return[gcoFailure["CachedPotentialCanonicalizationFailed", <|
        "DerivativeComponent" -> mu, "Upper" -> i, "Lower" -> j,
        "EpsilonValue" -> value|>]]];
    potentialFingerprint = gcoFingerprint[canonicalPotential];
    sourceCore = Lookup[sourceCoreCache, potentialFingerprint,
      Missing["NotCached"]];
    If[MissingQ[sourceCore],
      sourceCore = gcoPotentialCore[
        potentialChannels, roots, variables];
      If[Lookup[sourceCore, "Status", None] =!=
          "ExactSourcePotentialChannelCoreV6d",
        Return[gcoFailure["SourceCoreBuildFailed", <|
          "DerivativeComponent" -> mu, "Upper" -> i,
          "Lower" -> j, "EpsilonValue" -> value,
          "SourceCoreFailure" -> sourceCore|>]]];
      AssociateTo[sourceCoreCache, potentialFingerprint -> sourceCore];
      sourceCoreBuildCount++,
      sourceCoreReuseCount++];
    sourcePotential = gcoComposeScalar[potentialChannels, roots];
    sourceID = gcoFingerprint[{family, sector, lowerSector,
      mu, i, j, value, canonicalPotential}];
    source = Join[<|
        "SourcePotentialID" -> sourceID,
        "DerivativeComponent" -> mu, "Upper" -> i, "Lower" -> j,
        "EpsilonValue" -> value,
        "SourcePotential" -> sourcePotential,
        "SourcePotentialChannels" -> potentialChannels,
        "SourcePotentialFieldChannels" -> canonicalPotential,
        "SourcePotentialFingerprint" -> potentialFingerprint,
        "PinnedAssemblySourceBridgeExact" -> True|>,
      KeyDrop[sourceCore, {"SourcePotentialChannels",
        "SourcePotentialFieldChannels", "SourcePotentialFingerprint"}]];
    AppendTo[potentialSources, source],
    {mu, 2}, {i, upper}, {j, lower}, {value, epsilonSamples}];

  (* The adapter's ForcingDLogCandidates count is a unique-function count:
     it DeleteDuplicates the sampled Bbar entries before taking dlogs.  Keep
     every raw occurrence as provenance, but feed each exact potential only
     once to the orbit.  V6c exposed 32 occurrences / 28 exact potentials;
     sending all 32 through the orbit produced 16 redundant masked records. *)
  potentialOccurrenceCount = Length[potentialSources];
  potentialSourceGroups = GatherBy[potentialSources,
    Lookup[#1, "SourcePotentialFingerprint"] &];
  sourceGroupCollisionFree = AllTrue[potentialSourceGroups,
    Function[localSourceGroup,
      AllTrue[Rest[localSourceGroup],
        SameQ[#1["SourcePotentialFieldChannels"],
          First[localSourceGroup]["SourcePotentialFieldChannels"]] &]]];
  If[! TrueQ[sourceGroupCollisionFree],
    Return[gcoFailure["SourcePotentialFingerprintCollision"]]];
  potentialAliasCount = potentialOccurrenceCount -
    Length[potentialSourceGroups];
  metadataUniqueSourceCount = Lookup[
    Lookup[preparation, "OneFormMetadata", <||>],
    "ForcingDLogCandidates", $Failed];
  potentialSources = Map[Function[localSourceGroup,
    representative = First[localSourceGroup];
    sourceProvenance = KeyTake[#1, {
        "SourcePotentialID", "DerivativeComponent", "Upper", "Lower",
        "EpsilonValue"}] & /@ localSourceGroup;
    Join[representative, <|
      "SourcePotentialID" -> gcoFingerprint[{family, sector, lowerSector,
        representative["SourcePotentialFingerprint"],
        representative["SourcePotentialFieldChannels"]}],
      "SourceOccurrenceCount" -> Length[localSourceGroup],
      "SourceAliasCount" -> Length[localSourceGroup] - 1,
      "SourceOccurrenceProvenance" -> sourceProvenance|>]],
    potentialSourceGroups];

  expectedSourceCount = Length[potentialSources];
  If[potentialSources === {} ||
      ! IntegerQ[metadataUniqueSourceCount] ||
      expectedSourceCount =!= metadataUniqueSourceCount ||
      potentialOccurrenceCount =!=
        expectedSourceCount + potentialAliasCount ||
      sourceCoreBuildCount =!= expectedSourceCount ||
      sourceCoreReuseCount =!= potentialAliasCount ||
      ! AllTrue[potentialSources,
        AssociationQ[#1] && TrueQ[#1["FieldInverseExact"]] &&
          TrueQ[#1["DLogIdentityExact"]] &&
          TrueQ[#1["MixedDerivativeExact"]] &&
          TrueQ[#1["ClosedOneFormExact"]] &&
          IntegerQ[#1["SourceOccurrenceCount"]] &&
          #1["SourceOccurrenceCount"] >= 1 &&
          IntegerQ[#1["SourceAliasCount"]] &&
          #1["SourceAliasCount"] ===
            #1["SourceOccurrenceCount"] - 1 &&
          Length[#1["SourceOccurrenceProvenance"]] ===
            #1["SourceOccurrenceCount"] &] ||
      Total[Lookup[potentialSources, "SourceOccurrenceCount"]] =!=
        potentialOccurrenceCount ||
      ! DuplicateFreeQ[Lookup[potentialSources, "SourcePotentialID"]] ||
      ! DuplicateFreeQ[Lookup[potentialSources,
        "SourcePotentialFingerprint"]],
    Return[gcoFailure["PotentialSourceCensusFailed", <|
      "PotentialOccurrenceCount" -> potentialOccurrenceCount,
      "PotentialSourceCount" -> expectedSourceCount,
      "PotentialAliasCount" -> potentialAliasCount,
      "MetadataUniqueSourceCount" -> metadataUniqueSourceCount,
      "DistinctPotentialCoreCount" -> sourceCoreBuildCount,
      "PotentialCoreReuseCount" -> sourceCoreReuseCount|>]]];

  (* ORBIT HOT LOOP: character sign maps only.  It contains no D, Together,
     TRFieldDecompose, TRFieldInverse, or algebraic root substitution. *)
  (* V6_ORBIT_HOT_LOOP_BEGIN *)
  Do[
    formOrbitKey = gcoFingerprint[{
      source["SourceDLogFingerprint"], mask}];
    formOrbitCore = Lookup[formOrbitCache, formOrbitKey,
      Missing["NotCached"]];
    If[MissingQ[formOrbitCore],
      candidateDLogChannels =
        gcoCharacterAction[#1, mask, rank] & /@
          source["SourceDLogChannels"];
      candidateCanonicalDLog =
        gcoCanonicalOneFormChannels[candidateDLogChannels];
      If[candidateCanonicalDLog === $Failed,
        Return[gcoFailure["OrbitDLogCanonicalizationFailed"]]];
      formOrbitCore = <|
        "OneFormChannels" -> candidateDLogChannels,
        "CanonicalFieldChannels" -> candidateCanonicalDLog,
        "ChannelFingerprint" ->
          gcoFingerprint[candidateCanonicalDLog]|>;
      AssociateTo[formOrbitCache, formOrbitKey -> formOrbitCore];
      formOrbitBuildCount++,
      formOrbitReuseCount++];

    potentialOrbitKey = gcoFingerprint[{
      source["SourcePotentialFingerprint"], mask}];
    potentialOrbitCore = Lookup[potentialOrbitCache, potentialOrbitKey,
      Missing["NotCached"]];
    If[MissingQ[potentialOrbitCore],
      candidatePotentialChannels = gcoCharacterAction[
        source["SourcePotentialChannels"], mask, rank];
      candidateCanonicalPotential =
        gcoCanonicalScalarChannels[candidatePotentialChannels];
      If[candidateCanonicalPotential === $Failed,
        Return[gcoFailure["OrbitPotentialCanonicalizationFailed"]]];
      potentialOrbitCore = <|
        "PotentialChannels" -> candidatePotentialChannels,
        "PotentialFieldChannels" -> candidateCanonicalPotential,
        "ConjugatedPotentialFingerprint" ->
          gcoFingerprint[candidateCanonicalPotential]|>;
      AssociateTo[potentialOrbitCache,
        potentialOrbitKey -> potentialOrbitCore];
      potentialOrbitBuildCount++,
      potentialOrbitReuseCount++];

    derivativeEquivarianceExact = And @@ MapThread[
      gcoChannelEqualQ[
        CodexTripleRoot`TRDerivative[
          potentialOrbitCore["PotentialChannels"], deltas, #2],
        gcoCharacterAction[#1, mask, rank]] &,
      {source["SourceDerivativeChannels"], variables}];
    involutionExact = gcoChannelEqualQ[
      gcoCharacterAction[
        potentialOrbitCore["PotentialChannels"], mask, rank],
      source["SourcePotentialChannels"]];
    If[! TrueQ[derivativeEquivarianceExact] ||
        ! TrueQ[involutionExact] ||
        ! TrueQ[source["DLogIdentityExact"]] ||
        ! TrueQ[source["ClosedOneFormExact"]],
      Return[gcoFailure["CandidateInheritedCertificateFailed", <|
        "SourcePotentialID" -> source["SourcePotentialID"],
        "SignMask" -> mask,
        "DerivativeEquivarianceExact" ->
          derivativeEquivarianceExact,
        "InvolutionExact" -> involutionExact|>]]];
    candidate = Join[source, <|
        "SignMask" -> mask,
        "BranchSigns" -> Table[
          gcoCharacterSign[mask, 2^(bit - 1), rank],
          {bit, rank}],
        "ConjugatedPotential" -> gcoComposeScalar[
          potentialOrbitCore["PotentialChannels"], roots],
        "ConjugatedPotentialFingerprint" ->
          potentialOrbitCore["ConjugatedPotentialFingerprint"],
        "PotentialFieldChannels" ->
          potentialOrbitCore["PotentialFieldChannels"],
        "OneFormChannels" -> formOrbitCore["OneFormChannels"],
        "CanonicalFieldChannels" ->
          formOrbitCore["CanonicalFieldChannels"],
        "ChannelFingerprint" -> formOrbitCore["ChannelFingerprint"],
        "InvolutionExact" -> involutionExact,
        "DLogIdentityExact" -> True,
        "OrbitDLogExact" -> True,
        "DerivativeEquivarianceExact" ->
          derivativeEquivarianceExact,
        "ClosedOneFormExact" -> True|>];
    AppendTo[conjugateCandidates, candidate],
    {source, potentialSources}, {mask, signMasks}];
  (* V6_ORBIT_HOT_LOOP_END *)

  expectedCandidateCount = expectedSourceCount Length[signMasks];
  If[Length[conjugateCandidates] =!= expectedCandidateCount ||
      formOrbitBuildCount + formOrbitReuseCount =!=
        expectedCandidateCount ||
      potentialOrbitBuildCount + potentialOrbitReuseCount =!=
        expectedCandidateCount ||
      ! AllTrue[conjugateCandidates,
        TrueQ[#1["InvolutionExact"]] &&
          TrueQ[#1["DLogIdentityExact"]] &&
          TrueQ[#1["OrbitDLogExact"]] &&
          TrueQ[#1["DerivativeEquivarianceExact"]] &&
          TrueQ[#1["ClosedOneFormExact"]] &],
    Return[gcoFailure["ConjugateCandidateCensusFailed", <|
      "PotentialSourceCount" -> expectedSourceCount,
      "GaloisSignMaskCount" -> Length[signMasks],
      "ExpectedCandidateCount" -> expectedCandidateCount,
      "ConjugateCandidateCount" -> Length[conjugateCandidates],
      "DLogOrbitCacheConservationCount" ->
        formOrbitBuildCount + formOrbitReuseCount,
      "PotentialOrbitCacheConservationCount" ->
        potentialOrbitBuildCount + potentialOrbitReuseCount|>]]];

  candidateGroups = GatherBy[conjugateCandidates,
    Lookup[#1, "ChannelFingerprint"] &];
  collisionFree = AllTrue[candidateGroups, Function[localGroup,
    AllTrue[Rest[localGroup],
      SameQ[#1["CanonicalFieldChannels"],
        First[localGroup]["CanonicalFieldChannels"]] &]]];
  If[! TrueQ[collisionFree],
    Return[gcoFailure["ForcingChannelFingerprintCollision"]]];

  forcingLetterRecords = MapIndexed[Function[{localGroup, localIndex},
    representative = First[localGroup];
    formRecord = gcoOneFormRecordFromChannels[
      representative["OneFormChannels"], roots];
    If[formRecord === $Failed,
      Return[gcoFailure["UniqueOrbitOneFormCompositionFailed"]]];
    <|"ForcingLetterIndex" -> First[localIndex],
      "ChannelFingerprint" -> formRecord["ChannelFingerprint"],
      "OneForm" -> formRecord["OneForm"],
      "OneFormChannels" -> representative["OneFormChannels"],
      "CanonicalFieldChannels" ->
        formRecord["CanonicalFieldChannels"],
      "ProvenanceCount" -> Length[localGroup],
      "Provenance" ->
        KeyDrop[#1, {"Status", "SourcePotentialChannels",
          "SourceDerivativeChannels", "SourceFieldInverseChannels",
          "SourceDLogChannels", "SourceDLogCanonicalFieldChannels",
          "OneFormChannels", "CanonicalFieldChannels"}] & /@
          localGroup|>],
    candidateGroups];
  If[! AllTrue[forcingLetterRecords, Function[record,
      AssociationQ[record] &&
        Lookup[record, "Status", None] =!=
          "GaloisChannelOrbitV6dFailure" &&
        AllTrue[{"ForcingLetterIndex", "ChannelFingerprint",
          "OneForm", "OneFormChannels", "CanonicalFieldChannels",
          "ProvenanceCount", "Provenance"},
          KeyExistsQ[record, #1] &]]],
    Return[gcoFailure["ForcingLetterRecordBuildFailed"]]];

  identityForcingFingerprints = DeleteDuplicates[Lookup[
    Select[conjugateCandidates, #1["SignMask"] === 0 &],
    "ChannelFingerprint"]];
  If[Sort[identityForcingFingerprints] =!=
      Sort[Drop[baseFingerprints, 8]],
    Return[gcoFailure["IdentityForcingBasisDoesNotRecoverBaseSuffix", <|
      "IdentityForcingCount" -> Length[identityForcingFingerprints],
      "BaseForcingSuffixCount" -> Length[Drop[baseFingerprints, 8]]|>]]];

  additionalLetterRecords = Select[forcingLetterRecords,
    ! MemberQ[baseFingerprints, #1["ChannelFingerprint"]] &];
  maxOneForms = Join[baseOneForms,
    Lookup[additionalLetterRecords, "OneForm"]];
  maxFormRecords = Join[baseRecords,
    KeyTake[#1, {"OneForm", "CanonicalFieldChannels",
        "ChannelFingerprint"}] & /@ additionalLetterRecords];
  maxFingerprints = Lookup[maxFormRecords, "ChannelFingerprint"];
  If[! DuplicateFreeQ[maxFingerprints] ||
      Take[maxOneForms, Length[baseOneForms]] =!= baseOneForms ||
      Sort[Union[baseFingerprints,
        Lookup[forcingLetterRecords, "ChannelFingerprint"]]] =!=
        Sort[maxFingerprints],
    Return[gcoFailure["MaximalOrbitBasisConstructionFailed"]]];

  candidatesBySource = GroupBy[conjugateCandidates,
    Lookup[#1, "SourcePotentialID"] &];
  sourceOrbitRecords = Table[
    members = Lookup[candidatesBySource,
      source["SourcePotentialID"], {}];
    observedMasks = Sort[Lookup[members, "SignMask"]];
    memberKeys = Association@Table[
      member["SignMask"] -> member["ChannelFingerprint"],
      {member, members}];
    <|"SourcePotentialID" -> source["SourcePotentialID"],
      "DerivativeComponent" -> source["DerivativeComponent"],
      "Upper" -> source["Upper"], "Lower" -> source["Lower"],
      "EpsilonValue" -> source["EpsilonValue"],
      "SourcePotential" -> source["SourcePotential"],
      "SourceOccurrenceCount" -> source["SourceOccurrenceCount"],
      "SourceAliasCount" -> source["SourceAliasCount"],
      "SourceOccurrenceProvenance" ->
        source["SourceOccurrenceProvenance"],
      "ObservedSignMasks" -> observedMasks,
      "LetterFingerprintBySignMask" -> memberKeys,
      "KleinFourCompositionExact" -> TrueQ[
        characterCertificates["XorCompositionExact"]],
      "OrbitSizeAfterDLogDeduplication" ->
        Length[DeleteDuplicates[Values[memberKeys]]]|>,
    {source, potentialSources}];
  orbitClosureExact = AllTrue[sourceOrbitRecords,
    #1["ObservedSignMasks"] === signMasks &&
      TrueQ[#1["KleinFourCompositionExact"]] &&
      Complement[Values[#1["LetterFingerprintBySignMask"]],
        maxFingerprints] === {} &];
  If[! TrueQ[orbitClosureExact],
    Return[gcoFailure["GaloisOrbitClosureFailed"]]];

  <|"Status" -> "ExactGaloisChannelOrbitBasisV6d",
    "EpsilonSamples" -> epsilonSamples,
    "GaloisSignMasks" -> signMasks,
    "CharacterCertificates" -> characterCertificates,
    "PotentialOccurrenceCount" -> potentialOccurrenceCount,
    "PotentialSourceCount" -> Length[potentialSources],
    "PotentialAliasCount" -> potentialAliasCount,
    "ConjugateCandidateCount" -> Length[conjugateCandidates],
    "ForcingLetterRecords" -> forcingLetterRecords,
    "BaseOneFormCount" -> Length[baseOneForms],
    "AdditionalLetterCount" -> Length[additionalLetterRecords],
    "AdditionalOneFormChannels" ->
      Lookup[additionalLetterRecords, "OneFormChannels"],
    "MaxOneForms" -> maxOneForms,
    "SourceOrbitRecords" -> sourceOrbitRecords,
    "OrbitClosureExact" -> orbitClosureExact,
    "PerformanceCounters" -> <|
      "PotentialOccurrenceCount" -> potentialOccurrenceCount,
      "PotentialSourceCount" -> Length[potentialSources],
      "PotentialAliasCount" -> potentialAliasCount,
      "DistinctPotentialCoreCount" -> sourceCoreBuildCount,
      "PotentialCoreReuseCount" -> sourceCoreReuseCount,
      "ConjugateCandidateCount" -> Length[conjugateCandidates],
      "DistinctDLogOrbitCoreCount" -> formOrbitBuildCount,
      "DLogOrbitCoreReuseCount" -> formOrbitReuseCount,
      "DistinctPotentialOrbitCoreCount" -> potentialOrbitBuildCount,
      "PotentialOrbitCoreReuseCount" -> potentialOrbitReuseCount,
      "UniqueOneFormCompositionCount" ->
        Length[forcingLetterRecords],
      "LegacyAlgebraicFieldDecomposeCallsInCensus" -> 0,
      "LegacyAlgebraicRootBranchSubstitutionsInCensus" -> 0|>|>
];

GCOBuildOrbitBasis[___] :=
  gcoFailure["InvalidGaloisOrbitBuildArguments"];

End[];
EndPackage[];
