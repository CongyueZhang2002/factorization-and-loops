(* Substitution and chain-rule pullback of differential-system one-forms. *)
Begin["FeynFacet`Private`"];
(* Chain rule for a matrix-valued 1-form.  av and aw are already expressed
   in the coefficient variables; the tangent factors come from the
   Jacobian and are not substituted into anything. *)
masterTransportPullBackOneForm[av_, aw_, jacobian_] := {
  Map[Together, av jacobian[[1, 1]] + aw jacobian[[2, 1]], {2}],
  Map[Together, av jacobian[[1, 2]] + aw jacobian[[2, 2]], {2}]};

(* Substitute and normalize only nonzero connection entries.  When the
   caller owns subkernels, largest entries enter the shared queue first;
   otherwise the identical worker runs serially.  The helper never
   launches kernels, so KernelPool remains the resource authority. *)
masterTransportMapTogetherSubstitute[tensor_List, rules_List] := Module[
  {dimensions, level, positions, entries, uniqueEntries, uniqueIndex,
   entryIndices, order, sorted, transformed, parallelResult,
   uniqueValues, values, out},
  dimensions = Dimensions[tensor];
  level = Length[dimensions];
  positions = Position[tensor, entry_ /; ! TrueQ[entry === 0], {level},
    Heads -> False];
  If[positions === {}, Return[ConstantArray[0, dimensions]]];
  entries = Extract[tensor, positions];
  (* Exact common-subexpression elimination.  Repeated connection entries
     occur throughout sector assemblies; substituting and Together-ing the
     same expression once per matrix position wastes the dominant stage. *)
  uniqueEntries = DeleteDuplicates[entries];
  uniqueIndex = AssociationThread[uniqueEntries,
    Range[Length[uniqueEntries]]];
  entryIndices = Lookup[uniqueIndex, Key[#]] & /@ entries;
  order = Ordering[ByteCount /@ uniqueEntries, All, Greater];
  sorted = uniqueEntries[[order]];
  transformed = Which[
    $KernelID === 0 && $KernelCount > 1 && Length[sorted] > 1,
      ParallelMap[Together[# /. rules] &, sorted,
        Method -> "FinestGrained", DistributedContexts -> None],
    Length[sorted] > 1 &&
        TrueQ[Quiet[Check[taskBrokerActiveQ[], False]]],
      parallelResult = taskBrokerParallelTogether[
        sorted, rules, "coefficientPresentation", Infinity];
      If[AssociationQ[parallelResult] &&
          Lookup[parallelResult, "Status", None] === "OK",
        parallelResult["Result"], Together[# /. rules] & /@ sorted],
    True,
      Together[# /. rules] & /@ sorted];
  uniqueValues = transformed[[Ordering[order]]];
  values = uniqueValues[[entryIndices]];
  out = ConstantArray[0, dimensions];
  MapThread[(out[[Sequence @@ #1]] = #2) &, {positions, values}];
  out];

Options[masterTransportPullBackSystem] = {
  "SourceVariables" -> Automatic,
  "FlatnessCheck" -> True
};

masterTransportPullBackSystem[system_Association, presentation_,
    opts : OptionsPattern[]] := Module[
  {sourceVariables, data, av, aw, avc, awc, ax, ay, x, y, flatSource,
   flatPulledBack, surviving, substitution, differentialPullback,
   relationVerification, pureVariableRenameQ},
  sourceVariables = OptionValue["SourceVariables"];
  If[sourceVariables === Automatic,
    sourceVariables = masterTransportDefaultVariables[]];
  If[! MatchQ[sourceVariables, {_Symbol, _Symbol}],
    Return[<|"Status" -> "SourceVariablesInvalid"|>]];
  (* Re-derive the map and every displayed relation even when the caller
     supplies an already enriched record.  Status -> "OK" is not itself a
     certificate and must not bypass schema verification. *)
  data = masterTransportCoefficientPresentationData[
    presentation, sourceVariables];
  If[data["Status"] =!= "OK", Return[data]];
  {x, y} = masterTransportPresentationVariables[data];
  substitution = masterTransportPresentationSubstitution[data];
  differentialPullback = data["DifferentialPullbackMatrix"];
  pureVariableRenameQ =
    substitution === Thread[sourceVariables[[{1, 2}]] -> {x, y}] &&
    differentialPullback === IdentityMatrix[2];
  av = Lookup[system, "Av", $Failed];
  aw = Lookup[system, "Aw", $Failed];
  If[! (MatrixQ[av] && MatrixQ[aw] && Dimensions[av] === Dimensions[aw] &&
        Length[av] === Length[First[av]]),
    Return[<|"Status" -> "SystemNotASquareMatrixPair"|>]];
  (* Refuse a non-flat source outright: the chain rule would produce a
     pulled-back system whose own flatness check then fails for an
     unrelated reason. *)
  (* Production checks flatness once, after pullback, in the assembly
     certificate.  Building the same 41x41 curvature before substitution
     was a second full matrix-product pass and dominated a measured
     production run. *)
  flatSource = If[masterTransportCheckLevel[] === "Production",
    Missing["DeferredToAssembly"],
    masterTransportZeroMatQ[
      D[av, sourceVariables[[2]]] - D[aw, sourceVariables[[1]]] +
        av . aw - aw . av]];
  If[flatSource === False,
    Return[<|"Status" -> "SourceSystemNotFlat"|>]];
  (* A pure symbol rename cannot create a common denominator and needs no
     rational simplification.  On a 47x47 three-root connection, applying
     Together independently to every renamed algebraic entry cost 430 s
     while changing no expression mathematically. *)
  {avc, awc} = If[pureVariableRenameQ,
    {av, aw} /. substitution,
    masterTransportMapTogetherSubstitute[{av, aw}, substitution]];
  surviving = If[data["PresentationKind"] === "SourceVariables", {},
    Cases[{avc, awc},
      s_Symbol /; MemberQ[SymbolName /@ sourceVariables[[{1, 2}]],
        SymbolName[s]],
      {0, Infinity}, Heads -> True]];
  If[surviving =!= {},
    Return[<|"Status" -> "SourceVariablesSurviveSubstitution",
      "Symbols" -> DeleteDuplicates[surviving]|>]];
  {ax, ay} = If[pureVariableRenameQ, {avc, awc},
    masterTransportPullBackOneForm[avc, awc, differentialPullback]];
  flatPulledBack = If[TrueQ[OptionValue["FlatnessCheck"]],
    masterTransportZeroMatQ[D[ax, y] - D[ay, x] + ax . ay - ay . ax],
    "NotPerformed"];
  If[flatPulledBack =!= "NotPerformed" && ! TrueQ[flatPulledBack],
    Return[<|"Status" -> "PulledBackSystemNotFlat"|>]];
  relationVerification = Switch[data["PresentationKind"],
    "SourceVariables", "NotApplicable",
    "RationalizingParametrization",
      AllTrue[data["RationalizedSquareRootIdentities"], TrueQ],
    "SquareRootGeneratorsAndQuadraticRelations",
      TrueQ[data["QuadraticRelationVerification", "Verified"]],
    _, False];
  Join[
    <|"Status" -> "OK",
      "System" -> Join[KeyDrop[system, {"Av", "Aw"}],
        <|"Av" -> ax, "Aw" -> ay|>],
      "Ax" -> ax, "Ay" -> ay,
      "CoefficientVariables" -> {x, y},
      "CoefficientPresentation" -> data|>,
    <|"Certificate" -> <|
      "SourceSystemFlat" -> flatSource,
      "SourceSystemFlatnessRoute" -> If[MissingQ[flatSource],
        "DeferredToAssemblyCertificate", "ExactRationalFunction"],
      "PulledBackSystemFlat" -> flatPulledBack,
      "SourceCoordinateImagesRational" -> True,
      "DisplayedSquareRootRelationsVerified" -> relationVerification,
      "ChainRule" ->
        If[pureVariableRenameQ,
          "Pure variable rename with identity differential pullback",
          "Ax = Av d_x v + Aw d_x w, Ay = Av d_y v + Aw d_y w (Together'd)"],
      "JacobianDeterminant" -> data["JacobianDeterminant"],
      "Exact" -> True|>|>]
];

End[];
