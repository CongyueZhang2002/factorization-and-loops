(* Support composition of a factorized finite-field boundary-function map
   with tangential boundary evolution.  Exact coefficient definitions,
   including lazy endpoint functionals, remain in the left factor; neither
   cross-factor coefficient multiplication nor the Cartesian product of path
   sequences is formed before a characteristic-zero lift. *)

Clear[ComposeFactorizedFiniteFieldBoundaryFunctionSolutionMapWithTangentialEvolution,
  FactorizedFiniteFieldBoundarySolutionCompositionQ];

ClearAll[finiteFieldSolutionFailure, finiteFieldSolutionLookup,
  finiteFieldSolutionPortableReferenceQ,
  finiteFieldSolutionRegularizedActionReferenceQ,
  finiteFieldSolutionPolynomialTermsQ,
  finiteFieldSolutionDenseUnivariatePolynomialQ,
  finiteFieldSolutionEndpointFunctionalQ,
  finiteFieldSolutionCoefficientDefinitionQ,
  finiteFieldSolutionBoundaryMapQ, finiteFieldSolutionSupportProxy,
  finiteFieldSolutionRequiredDefinitionIDs,
  finiteFieldSolutionConstruct];

finiteFieldSolutionFailure[status_String, extra_: <||>] :=
  Failure[status, Join[<|"Status" -> status|>, extra]];

(* Lookup treats a list-valued identifier as a list of separate keys. *)
finiteFieldSolutionLookup[association_Association, key_,
    default_: Missing[]] :=
  If[KeyExistsQ[association, key], association[[Key[key]]], default];

finiteFieldSolutionPortableReferenceQ[reference_] := Module[{path},
  If[! AssociationQ[reference], Return[False]];
  path = Lookup[reference, "RelativePath", Missing[]];
  StringQ[path] && StringLength[path] > 0 &&
    ! StringStartsQ[path, "/"] &&
    ! StringStartsQ[path, "\\"] &&
    ! StringMatchQ[path, RegularExpression["^[A-Za-z]:.*"]]
];

finiteFieldSolutionRegularizedActionReferenceQ[reference_, family_String,
    prime_Integer] := finiteFieldSolutionPortableReferenceQ[reference] &&
  StringQ[Lookup[reference, "DataType", Missing[]]] &&
  StringLength[reference["DataType"]] > 0 &&
  Lookup[reference, "SchemaVersion", None] === 2 &&
  Lookup[reference, "Family", None] === family &&
  Lookup[reference, "Prime", None] === prime;

finiteFieldSolutionPolynomialTermsQ[terms_, variableCount_Integer,
    prime_Integer] := ListQ[terms] && terms =!= {} &&
  AllTrue[terms, AssociationQ[#] &&
      VectorQ[Lookup[#, "ExponentVector", Missing[]],
        IntegerQ[#] && # >= 0 &] &&
      Length[#["ExponentVector"]] === variableCount &&
      IntegerQ[Lookup[#, "CoefficientModuloPrime", None]] &&
      0 <= #["CoefficientModuloPrime"] < prime &] &&
  DuplicateFreeQ[Lookup[terms, "ExponentVector"]];

finiteFieldSolutionDenseUnivariatePolynomialQ[coefficients_,
    prime_Integer] := ListQ[coefficients] && coefficients =!= {} &&
  AllTrue[coefficients,
    IntegerQ[#] && 0 <= # < prime &];

finiteFieldSolutionEndpointFunctionalQ[functional_, prime_Integer] :=
  AssociationQ[functional] &&
    StringQ[Lookup[functional, "Operation", Missing[]]] &&
    StringLength[functional["Operation"]] > 0 &&
    StringQ[Lookup[functional, "MathematicalDefinition", Missing[]]] &&
    StringLength[functional["MathematicalDefinition"]] > 0 &&
    MatchQ[Lookup[functional, "SourceReferences", Missing[]],
      {__Association}] &&
    AllTrue[functional["SourceReferences"],
      finiteFieldSolutionPortableReferenceQ] &&
    IntegerQ[prime] && prime > 2;

finiteFieldSolutionCoefficientDefinitionQ[definition_, field_Association] :=
 Module[{prime, variables, representation, numerator, denominator,
   components},
  If[! AssociationQ[definition] ||
      ! StringQ[Lookup[definition, "CoefficientDefinitionID", None]] ||
      StringLength[definition["CoefficientDefinitionID"]] === 0,
    Return[False]];
  prime = field["Prime"];
  variables = field["CoefficientVariables"];
  representation = Lookup[definition, "Representation", None];
  Switch[representation,
    "RationalFunctionModuloPrime",
      If[KeyExistsQ[definition, "NumeratorCoefficientsModuloPrime"] ||
          KeyExistsQ[definition, "DenominatorCoefficientsModuloPrime"],
        numerator = Lookup[definition,
          "NumeratorCoefficientsModuloPrime", Missing[]];
        denominator = Lookup[definition,
          "DenominatorCoefficientsModuloPrime", Missing[]];
        Length[variables] === 1 &&
          finiteFieldSolutionDenseUnivariatePolynomialQ[numerator, prime] &&
          finiteFieldSolutionDenseUnivariatePolynomialQ[denominator,
            prime] && AnyTrue[numerator, # =!= 0 &] &&
          AnyTrue[denominator, # =!= 0 &],
        numerator = Lookup[definition,
          "NumeratorPolynomialTerms", Missing[]];
        denominator = Lookup[definition,
          "DenominatorPolynomialTerms", Missing[]];
        finiteFieldSolutionPolynomialTermsQ[numerator, Length[variables],
            prime] &&
          finiteFieldSolutionPolynomialTermsQ[denominator,
            Length[variables], prime] &&
          AnyTrue[numerator,
            Lookup[#, "CoefficientModuloPrime", 0] =!= 0 &] &&
          AnyTrue[denominator,
            Lookup[#, "CoefficientModuloPrime", 0] =!= 0 &]],
    "OrderedExactEndpointFunctionalSumModuloPrime",
      components = Lookup[definition, "OrderedComponents", Missing[]];
      MatchQ[components, {__Association}] &&
        AllTrue[components,
          IntegerQ[Lookup[#, "SignModuloPrime", None]] &&
            MemberQ[{1, prime - 1}, #["SignModuloPrime"]] &&
            finiteFieldSolutionEndpointFunctionalQ[
              Lookup[#, "ExactEndpointFunctional", Missing[]], prime] &],
    _, False]
];

finiteFieldSolutionBoundaryMapQ[record_] := Module[
  {requiredKeys, field, prime, variables, definitions, definitionIDs,
   definitionIndex, coordinates, labels, demands, terms, rowCount,
   columnCount, entries, referencedIDs, validation, conditions, domain,
   regulator},
  requiredKeys = {"DataType", "SchemaVersion", "Status", "Family",
    "FamilyDifferentialSystemReference",
    "MasterIntegralEpsilonOrderRequirementsReference",
    "BoundaryDataType", "BoundaryDomain", "DimensionalRegulator",
    "RequestedMasterIntegralEpsilonOrderAndRowPairs",
    "BoundaryFunctionEpsilonCoefficientRecords",
    "BoundaryFunctionEpsilonCoefficientLabels", "CoefficientField",
    "FiniteFieldRegularizedActionReference",
    "FiniteFieldCoefficientDefinitions",
    "IteratedIntegralCoefficientReferenceRecords",
    "FiniteFieldDemandCoverage", "CharacteristicZeroDemandCoverage",
    "FormalResultConvention", "Validation"};
  If[! AssociationQ[record] || ! ContainsAll[Keys[record], requiredKeys] ||
      record["DataType"] =!=
        "FactorizedFiniteFieldBoundaryFunctionToMasterIntegralSolutionMap" ||
      record["SchemaVersion"] =!= 2 ||
      record["Status"] =!=
        "FactorizedFiniteFieldBoundaryFunctionToMasterIntegralSolutionMapValidated" ||
      ! StringQ[record["Family"]] ||
      ! finishFamilyDifferentialSystemReferenceQ[
        record["FamilyDifferentialSystemReference"], record["Family"]] ||
      ! finiteFieldSolutionPortableReferenceQ[
        record["FamilyDifferentialSystemReference"]] ||
      ! finishMasterIntegralEpsilonOrderRequirementsReferenceQ[
        record["MasterIntegralEpsilonOrderRequirementsReference"]] ||
      ! finiteFieldSolutionPortableReferenceQ[
        record["MasterIntegralEpsilonOrderRequirementsReference"]],
    Return[False]];
  field = record["CoefficientField"];
  If[! AssociationQ[field] ||
      Lookup[field, "Type", None] =!=
        "RationalFunctionFieldModuloPrime" ||
      ! IntegerQ[Lookup[field, "Prime", None]] ||
      ! TrueQ[PrimeQ[field["Prime"]]] || field["Prime"] <= 2 ||
      ! MatchQ[Lookup[field, "CoefficientVariables", Missing[]],
        {__Symbol}] ||
      DuplicateFreeQ[field["CoefficientVariables"]] =!= True,
    Return[False]];
  prime = field["Prime"];
  variables = field["CoefficientVariables"];
  If[! finiteFieldSolutionRegularizedActionReferenceQ[
      record["FiniteFieldRegularizedActionReference"], record["Family"],
      prime], Return[False]];
  regulator = record["DimensionalRegulator"];
  domain = record["BoundaryDomain"];
  If[! MatchQ[regulator, _Symbol] || MemberQ[variables, regulator] ||
      ! AssociationQ[domain] ||
      Lookup[domain, "Type", None] =!= "PhysicalBoundaryStratum" ||
      ! MatchQ[Lookup[domain, "TangentialVariables", Missing[]],
        {__Symbol}] || ! ContainsAll[variables,
        domain["TangentialVariables"]], Return[False]];
  coordinates = record["BoundaryFunctionEpsilonCoefficientRecords"];
  labels = record["BoundaryFunctionEpsilonCoefficientLabels"];
  demands = record["RequestedMasterIntegralEpsilonOrderAndRowPairs"];
  If[record["BoundaryDataType"] =!= "BoundaryFunction" ||
      ! MatchQ[coordinates, {__Association}] ||
      ! AllTrue[coordinates,
        KeyExistsQ[#, "BoundaryFunctionID"] &&
          IntegerQ[Lookup[#, "EpsilonOrder", None]] &] ||
      ! DuplicateFreeQ[(HoldComplete[#["BoundaryFunctionID"],
            #["EpsilonOrder"]] &) /@ coordinates] ||
      labels =!= ({#["BoundaryFunctionID"], #["EpsilonOrder"]} & /@
          coordinates) || ! MatchQ[demands, {{_Integer, _Integer} ...}] ||
      ! DuplicateFreeQ[demands], Return[False]];
  definitions = record["FiniteFieldCoefficientDefinitions"];
  If[! MatchQ[definitions, {__Association}] ||
      ! AllTrue[definitions,
        finiteFieldSolutionCoefficientDefinitionQ[#, field] &],
    Return[False]];
  definitionIDs = Lookup[definitions, "CoefficientDefinitionID"];
  If[! DuplicateFreeQ[definitionIDs], Return[False]];
  definitionIndex = AssociationThread[definitionIDs, definitions];
  rowCount = Length[demands];
  columnCount = Length[coordinates];
  terms = record["IteratedIntegralCoefficientReferenceRecords"];
  If[! MatchQ[terms, {__Association}], Return[False]];
  If[! AllTrue[terms, Function[term,
      MatchQ[Lookup[term, {"CurrentPathFirstSegmentLetterIndices",
            "CurrentPathSecondSegmentLetterIndices",
            "BoundaryPathFirstSegmentLetterIndices",
            "BoundaryPathSecondSegmentLetterIndices"}, Missing[]],
        {_List, _List, _List, _List}] &&
      MatchQ[Lookup[term, "NonzeroCoefficientEntries", Missing[]],
        {__Association}] && With[
        {termEntries = term["NonzeroCoefficientEntries"]},
        AllTrue[termEntries,
          IntegerQ[Lookup[#,
                "RequestedMasterIntegralEpsilonOrderAndRowPairIndex",
                None]] &&
              1 <= #[
                "RequestedMasterIntegralEpsilonOrderAndRowPairIndex"] <=
                rowCount &&
              IntegerQ[Lookup[#,
                "BoundaryFunctionEpsilonCoefficientIndex", None]] &&
              1 <= #["BoundaryFunctionEpsilonCoefficientIndex"] <=
                columnCount &&
              StringQ[Lookup[#, "CoefficientDefinitionID", None]] &&
              AssociationQ[finiteFieldSolutionLookup[definitionIndex,
                #["CoefficientDefinitionID"], Missing[]]] &] &&
          DuplicateFreeQ[
            ({#["RequestedMasterIntegralEpsilonOrderAndRowPairIndex"],
                #["BoundaryFunctionEpsilonCoefficientIndex"]} &) /@
              termEntries]]]],
    Return[False]];
  entries = Flatten[Lookup[terms, "NonzeroCoefficientEntries", {}]];
  referencedIDs = DeleteDuplicates@Lookup[entries,
    "CoefficientDefinitionID", {}];
  validation = record["Validation"];
  conditions = Lookup[validation, "Conditions", Missing[]];
  Sort[referencedIDs] === Sort[definitionIDs] &&
    record["FiniteFieldDemandCoverage"] === "Complete" &&
    record["CharacteristicZeroDemandCoverage"] === "NotEstablished" &&
    AssociationQ[record["FormalResultConvention"]] &&
    AssociationQ[validation] && AssociationQ[conditions] &&
    conditions =!= <||> && AllTrue[Values[conditions], TrueQ]
];

finiteFieldSolutionSupportProxy[map_Association] := Module[
  {rowCount, columnCount, records},
  rowCount = Length[map["RequestedMasterIntegralEpsilonOrderAndRowPairs"]];
  columnCount = Length[map["BoundaryFunctionEpsilonCoefficientRecords"]];
  records = Map[Function[record, Join[
      KeyTake[record, {"CurrentPathFirstSegmentLetterIndices",
        "CurrentPathSecondSegmentLetterIndices",
        "BoundaryPathFirstSegmentLetterIndices",
        "BoundaryPathSecondSegmentLetterIndices"}], <|
        "IteratedIntegralCoefficientMatrix" -> SparseArray[
          (({#["RequestedMasterIntegralEpsilonOrderAndRowPairIndex"],
                #["BoundaryFunctionEpsilonCoefficientIndex"]} -> 1) &) /@
            record["NonzeroCoefficientEntries"],
          {rowCount, columnCount}]|>]],
    map["IteratedIntegralCoefficientReferenceRecords"]];
  <|
    "DataType" -> "BoundaryFunctionToMasterIntegralSolutionMap",
    "SchemaVersion" -> 2,
    "Status" -> "BoundaryFunctionToMasterIntegralSolutionMapValidated",
    "Family" -> map["Family"],
    "FamilyDifferentialSystemReference" ->
      map["FamilyDifferentialSystemReference"],
    "MasterIntegralEpsilonOrderRequirementsReference" ->
      map["MasterIntegralEpsilonOrderRequirementsReference"],
    "BoundaryDataType" -> "BoundaryFunction",
    "BoundaryDomain" -> map["BoundaryDomain"],
    "DimensionalRegulator" -> map["DimensionalRegulator"],
    "RequestedMasterIntegralEpsilonOrderAndRowPairs" ->
      map["RequestedMasterIntegralEpsilonOrderAndRowPairs"],
    "DemandCoverage" -> "Complete",
    "BoundaryFunctionEpsilonCoefficientRecords" ->
      map["BoundaryFunctionEpsilonCoefficientRecords"],
    "BoundaryFunctionEpsilonCoefficientLabels" ->
      map["BoundaryFunctionEpsilonCoefficientLabels"],
    "IteratedIntegralCoefficientMatrixRecords" -> records,
    "BoundaryDataRequirements" -> {},
    "FormalResultConvention" -> map["FormalResultConvention"],
    "Validation" -> <|"Method" -> "DeclaredNonzeroSupportProjection",
      "Conditions" -> <|"CoefficientReferenceClosure" -> True,
        "BoundaryFunctionInterface" -> True,
        "FiniteFieldDemandCoverage" -> True|>|>|>
];

finiteFieldSolutionRequiredDefinitionIDs[map_Association,
    dependencies_List] := Module[{records, pairs},
  records = map["IteratedIntegralCoefficientReferenceRecords"];
  pairs = Flatten[Map[Function[dependency,
      Flatten[Map[Function[index,
          Cases[records[[index]]["NonzeroCoefficientEntries"],
            entry_Association /;
                entry["BoundaryFunctionEpsilonCoefficientIndex"] ===
                  dependency[
                    "BoundaryFunctionEpsilonCoefficientIndex"] :>
              entry["CoefficientDefinitionID"]]],
        dependency["LeftFactorRecordIndices"]]]], dependencies]];
  DeleteDuplicates[pairs]
];

finiteFieldSolutionConstruct[map_Association,
    evolution_Association] := Catch@Module[
  {proxy, supportSolution, worklist, dependencies, requiredIDs,
   definitionIndex, requiredDefinitions, lazyIDs, product},
  If[! finiteFieldSolutionBoundaryMapQ[map],
    Throw[finiteFieldSolutionFailure[
      "FactorizedFiniteFieldBoundaryFunctionSolutionMapRequired"]]];
  If[! TangentialBoundaryEvolutionOperatorQ[evolution],
    Throw[finiteFieldSolutionFailure[
      "TangentialBoundaryEvolutionOperatorRequired"]]];
  proxy = finiteFieldSolutionSupportProxy[map];
  supportSolution = finishFactorizedMasterIntegralSolution[proxy, evolution];
  If[FailureQ[supportSolution], Throw[supportSolution]];
  worklist = supportSolution[
    "BoundaryConstantEpsilonCoefficientEvaluationWorklist"];
  dependencies = worklist[
    "BoundaryFunctionInterfaceCoordinateDependencies"];
  requiredIDs = finiteFieldSolutionRequiredDefinitionIDs[map, dependencies];
  definitionIndex = AssociationThread[
    Lookup[map["FiniteFieldCoefficientDefinitions"],
      "CoefficientDefinitionID"],
    map["FiniteFieldCoefficientDefinitions"]];
  requiredDefinitions = finiteFieldSolutionLookup[definitionIndex, #] & /@
    requiredIDs;
  lazyIDs = Lookup[Select[requiredDefinitions,
      #["Representation"] ===
        "OrderedExactEndpointFunctionalSumModuloPrime" &],
    "CoefficientDefinitionID", {}];
  worklist = Join[worklist, <|
      "RequiredFiniteFieldCoefficientDefinitionIDs" -> requiredIDs,
      "RequiredLazyEndpointFunctionalCoefficientDefinitionIDs" -> lazyIDs|>];
  product = supportSolution["OrderedSparseCoefficientOperatorProduct"];
  product = ReplacePart[product, "LeftFactor" -> map];
  <|
    "DataType" -> "FactorizedFiniteFieldBoundarySolutionComposition",
    "SchemaVersion" -> 2,
    "Status" ->
      "FactorizedFiniteFieldBoundarySolutionCompositionConstructed",
    "CompositionRepresentation" ->
      "OrderedUnmultipliedCoefficientOperatorFactors",
    "Family" -> map["Family"],
    "FamilyDifferentialSystemReference" ->
      map["FamilyDifferentialSystemReference"],
    "MasterIntegralEpsilonOrderRequirementsReference" ->
      map["MasterIntegralEpsilonOrderRequirementsReference"],
    "BoundaryDomain" -> map["BoundaryDomain"],
    "DimensionalRegulator" -> map["DimensionalRegulator"],
    "LeftFactorCoefficientField" -> map["CoefficientField"],
    "TangentialEvolutionCoefficientDomain" ->
      "AsDeclaredByTangentialBoundaryEvolutionOperator",
    "CrossFactorCoefficientMultiplicationStatus" ->
      "DeferredUntilCharacteristicZeroLift",
    "FiniteFieldRegularizedActionReference" ->
      map["FiniteFieldRegularizedActionReference"],
    "RequestedMasterIntegralEpsilonOrderAndRowPairs" ->
      map["RequestedMasterIntegralEpsilonOrderAndRowPairs"],
    "FiniteFieldDemandCoverage" -> "Complete",
    "CharacteristicZeroDemandCoverage" -> "NotEstablished",
    "CharacteristicZeroLiftStatus" -> "NotEstablished",
    "BoundaryDataStatus" -> supportSolution["BoundaryDataStatus"],
    "SourceBoundaryFunctionIDs" -> evolution["BoundaryFunctionIDs"],
    "BoundaryFunctionToTangentialBasePointBoundaryConstantIDs" ->
      evolution[
        "BoundaryFunctionToTangentialBasePointBoundaryConstantIDs"],
    "TangentialBasePoint" -> evolution["TangentialBasePoint"],
    "TangentialPath" -> evolution["TangentialPath"],
    "OrderedCoefficientOperatorFactors" -> product,
    "BoundaryConstantEpsilonCoefficientRecords" ->
      supportSolution["BoundaryConstantEpsilonCoefficientRecords"],
    "BoundaryConstantEpsilonCoefficientLabels" ->
      supportSolution["BoundaryConstantEpsilonCoefficientLabels"],
    "BoundaryDataRequirements" ->
      supportSolution["BoundaryDataRequirements"],
    "BoundaryConstantEpsilonCoefficientEvaluationWorklist" -> worklist,
    "EpsilonOrderCoverage" -> supportSolution["EpsilonOrderCoverage"],
    "IteratedIntegralLetterSequenceOrientation" -> "OutermostFirst",
    "CharacteristicZeroLiftRequirements" -> {
      "Reconstruct or otherwise define every required finite-field coefficient over the declared characteristic-zero coefficient field",
      "Replay every required lazy endpoint functional over characteristic zero or lift it from enough construction primes with independent-prime validation",
      "Bind the lifted coefficient definitions to the same boundary-function coordinate interface and path-segment alphabets"},
    "MapConvention" ->
      "The right tangential-evolution factor acts first. The finite-field left factor retains coefficient-definition references, including ordered lazy endpoint-functional sums. Cross-factor coefficient multiplication and the Cartesian product of iterated-integral sequences are deferred until characteristic-zero lift."|>
];

ComposeFactorizedFiniteFieldBoundaryFunctionSolutionMapWithTangentialEvolution[
    map_Association, evolution_Association] :=
  finiteFieldSolutionConstruct[map, evolution];

ComposeFactorizedFiniteFieldBoundaryFunctionSolutionMapWithTangentialEvolution[
    ___] :=
  finiteFieldSolutionFailure[
    "FactorizedFiniteFieldBoundaryCompositionInputsNotWellFormed"];

FactorizedFiniteFieldBoundarySolutionCompositionQ[
    record_Association] := Module[
  {product, left, right, evolution, expected},
  If[Lookup[record, "DataType", None] =!=
        "FactorizedFiniteFieldBoundarySolutionComposition" ||
      Lookup[record, "SchemaVersion", None] =!= 2 ||
      Lookup[record, "Status", None] =!=
        "FactorizedFiniteFieldBoundarySolutionCompositionConstructed" ||
      Lookup[record, "CharacteristicZeroLiftStatus", None] =!=
        "NotEstablished" ||
      Lookup[record, "CharacteristicZeroDemandCoverage", None] =!=
        "NotEstablished" ||
      KeyExistsQ[record, "IteratedIntegralCoefficientMatrixTerms"],
    Return[False]];
  product = Lookup[record,
    "OrderedCoefficientOperatorFactors", Missing[]];
  If[! AssociationQ[product], Return[False]];
  left = Lookup[product, "LeftFactor", Missing[]];
  right = Lookup[product, "RightFactor", Missing[]];
  evolution = If[AssociationQ[right], Lookup[right,
      "TangentialBoundaryEvolutionOperator", Missing[]], Missing[]];
  If[! AssociationQ[left] || ! AssociationQ[evolution], Return[False]];
  expected = finiteFieldSolutionConstruct[left, evolution];
  AssociationQ[expected] && SameQ[record, expected]
];

FactorizedFiniteFieldBoundarySolutionCompositionQ[_] :=
  False;
