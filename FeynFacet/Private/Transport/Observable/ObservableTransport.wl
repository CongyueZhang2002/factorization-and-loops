(* Observable-only transport for two-variable epsilon-form families.
   Small records are exact and materialized.  Large records retain the exact
   operator chain lazily; an optional quotient automaton remains available
   when a compressed rational realization is specifically requested. *)

(* Public symbols are Clear'ed, not ClearAll'ed: ClearAll also removes
   the usage messages FeynFacet.m defines before loading this file
   (found 2026-08-21). Clear still drops their definitions, so re-Get of
   this file stays clean. *)
Clear[BuildObservableTransportManifest, FindObservableTransportPath,
  BuildObservableTransportDemand, BuildObservableTransport,
  ObservableTransportWordMap, ReconstructObservableTransportWordMaps,
  AcceptedObservableTransportQ];
ClearAll[
  observableTransportCancel,
  observableTransportCancelMatrix,
  observableTransportStructuralZeroMatrixQ,
  observableTransportSlotKey,
  observableTransportEpsilonOrder,
  observableTransportLaurentMatrices,
  observableTransportLaurentMatricesTask,
  observableTransportLaurentRows,
  $observableTransportLaurentMethod,
  $observableTransportLaurentJetRetired,
  $observableTransportLaurentDiagnostics,
  observableTransportLaurentEntrySeries,
  observableTransportLaurentRowHighs,
  observableTransportIndependentRows,
  observableTransportIndependentRowsTask,
  observableTransportIndependentRowsAtSamples,
  observableTransportMaximalIndependentRows,
  observableTransportMaximalIndependentExtensionRows,
  observableTransportCovariantRows,
  observableTransportCovariantRowsTask,
  observableTransportCovariantRowClosure,
  observableTransportKernel,
  observableTransportBoundaryEmbedding,
  observableTransportResidues,
  observableTransportRecordRegularQ,
  observableTransportLiftResidues,
  observableTransportWordMaps,
  observableTransportWordCountBound,
  observableTransportCompactDualAutomaton,
  observableTransportKernelDecomposition,
  observableTransportSecondSegmentMaps,
  observableTransportFamilyName,
  observableTransportIntegralIndices,
  observableTransportNonsingularQ,
  observableTransportFamilyFromFile,
  observableTransportWriteAtomic,
  observableTransportCoefficientField,
  observableTransportPointAdmissibleQ,
  observableTransportAdmissibleSamples,
  $observableTransportSampleFractions,
  observableTransportCoefficientFieldDeclared,
  observableTransportRadicalFieldNames,
  observableTransportEpsilonValuationFingerprint,
  observableTransportCanonicalRadicals,
  observableTransportAlgebraicZeroQ,
  observableTransportEpsilonOrderAtPoint,
  observableTransportExactPointValuations,
  observableTransportCertifyEpsilonValuations,
  observableTransportCertifyEpsilonValuationsFile,
  observableTransportEpsilonValuationCertificateShapeQ,
  observableTransportEpsilonValuationStatus,
  observableTransportEpsilonValuationCertificateBoundQ,
  $observableTransportValuationTrialCount
];

observableTransportCancel[x_] := Quiet[Cancel[Together[x]]];

observableTransportCancelMatrix[m_] :=
  Map[observableTransportCancel, Normal[m], {2}];



(* Use only after entrywise exact cancellation.  A nonliteral zero is kept as
   a possible edge, so this cheap predicate can overestimate the block DAG but
   can never discard a coupling. *)
observableTransportStructuralZeroMatrixQ[m_] :=
  AllTrue[Flatten[{Normal[m]}], TrueQ[# === 0] &];


(* Coefficient field of a family record (overhaul 2026-09-02; round 4,
   Codex review: "coefficient-field fallback is incomplete").
   Resolution order: an explicit declaration -- the record's own
   "CoefficientField", the chart record, the epsilon-form certificate --
   and, only for records that are NOT transport-ready, a legacy
   inference over EVERY computational field (letters, TTotal,
   TTotalInverse, the epsilon-form matrices, the dlog letters and
   residues, the chart roots): "Rational" when all are free of radicals,
   otherwise Missing["CoefficientFieldRequired", fields] naming the
   radical fields.  A transport-ready record (compact dlog
   representation, never materialized as full matrices) must declare its
   field: Missing["CoefficientFieldDeclarationRequired"].  History: the
   02:43 revision read the field only from record["ChartRecord"] and
   refused the certified ordinary-family records, which carry it in
   their certificate; the 08:38 revision inferred from Letters and
   TTotal alone, so a radical in TTotalInverse or a residue made a
   record "Rational". *)
observableTransportCoefficientFieldDeclared[record_Association] := Module[
  {chartRecord = Lookup[record, "ChartRecord", <||>],
   certificate = Lookup[record, "EpsilonFormCertificate", <||>],
   fields = {"Rational", "Multiquadratic"}},
  Which[
    MemberQ[fields, Lookup[record, "CoefficientField", None]],
      record["CoefficientField"],
    AssociationQ[chartRecord] &&
      MemberQ[fields, Lookup[chartRecord, "CoefficientField", None]],
      chartRecord["CoefficientField"],
    AssociationQ[certificate] &&
      MemberQ[fields, Lookup[certificate, "CoefficientField", None]],
      certificate["CoefficientField"],
    True, None]
];

(* Names of the computational fields of a record that carry a radical
   (Power[_, _Rational] or Sqrt); the legacy inference inspects all. *)
observableTransportRadicalFieldNames[record_Association] := Module[
  {dlog = Lookup[record, "DLog", <||>],
   chartRecord = Lookup[record, "ChartRecord", <||>], candidates},
  candidates = {
    "Letters" -> Lookup[record, "Letters", {}],
    "TTotal" -> Lookup[record, "TTotal", {}],
    "TTotalInverse" -> Lookup[record, "TTotalInverse", {}],
    "EpsFormX" -> Lookup[record, "EpsFormX", {}],
    "EpsFormY" -> Lookup[record, "EpsFormY", {}],
    "DLog/Letters" -> If[AssociationQ[dlog], Lookup[dlog, "Letters", {}], {}],
    "DLog/Residues" -> If[AssociationQ[dlog], Lookup[dlog, "Residues", {}], {}],
    "ChartRecord/Roots" -> If[AssociationQ[chartRecord],
      Lookup[chartRecord, "Roots", {}], {}]};
  First /@ Select[candidates,
    ! FreeQ[Last[#], Power[_, _Rational] | Sqrt[_]] &]
];

observableTransportCoefficientField[record_Association] := Module[
  {declared = observableTransportCoefficientFieldDeclared[record],
   radicalFields},
  If[declared =!= None, Return[declared]];
  If[Lookup[record, "Status", None] === "TransportReadyEpsilonConnection",
    Return[Missing["CoefficientFieldDeclarationRequired"]]];
  radicalFields = observableTransportRadicalFieldNames[record];
  If[radicalFields === {}, "Rational",
    Missing["CoefficientFieldRequired", radicalFields]]
];
observableTransportCoefficientField[___] := Missing["CoefficientField"];

(* Admissible sample points for rank and residue sampling (overhaul
   2026-09-02, goal 9).  The fixed default samples are fine for rational
   families, but an algebraic (multiquadratic) record can have a letter
   or a declared root square that vanishes at one of them, and every
   finite-field trial at that point is then rejected (CF259 probe 1:
   SingularConstraintRankSample).  A sample is admissible when every
   letter and every root square is a nonzero rational at the point.
   Samples are drawn from a fixed fraction grid, so the choice is
   deterministic and family-neutral; the caller keeps the defaults when
   they are admissible. *)
observableTransportPointAdmissibleQ[letters_List, rootSquares_List, rules_List] :=
  AllTrue[Join[letters, rootSquares], Function[expression,
    Module[{value = Quiet[Check[Together[expression /. rules], $Failed]]},
      value =!= $Failed && NumericQ[value] && TrueQ[value != 0] &&
        FreeQ[value, Indeterminate | ComplexInfinity | DirectedInfinity[_]]]]];

observableTransportAdmissibleSamples[letters_List, rootSquares_List,
    pointFunction_, candidates_List, count_Integer] := Module[{chosen = {}},
  Do[
    If[Length[chosen] >= count, Break[]];
    If[observableTransportPointAdmissibleQ[letters, rootSquares,
        pointFunction[candidate]],
      AppendTo[chosen, candidate]],
    {candidate, candidates}];
  chosen
];
$observableTransportSampleFractions = {2/5, 3/5, 4/7, 3/11, 4/13, 2/9,
  5/13, 3/8, 5/11, 7/16, 4/9, 5/12, 7/15, 6/17, 8/19, 9/23, 5/14, 7/18};

(* ---------------------------------------------------------------------
   Transport epsilon-valuation certificate (round 4, 2026-09-02; Codex
   review, correctness point 1: "transport epsilon valuations are trusted
   rather than certified").

   A transport-ready record carries TMin (the minimum epsilon order of
   TTotal) and BlockLower (per block, the minimum epsilon order of the
   rows of TTotalInverse); they fix the Laurent range and the physical
   convolution, and a value that is too HIGH omits a real leading
   coefficient.  The certificate is bound to the record and computed
   EXACTLY at random rational kinematic points: after the point is
   substituted every entry is a rational function of eps alone whose
   coefficients are algebraic numbers (numeric radicals); its order is
   ord(numerator) - ord(denominator) at eps = 0, read off the coefficient
   lists of Together's fraction (a common factor changes neither order),
   the first nonzero coefficient decided exactly (RootReduce).  No prime,
   no lifting, no series: two earlier designs (p-adic roots) failed on
   CF259 -- merged numeric radicands needed 7-13 residue conditions per
   trial, and hidden exact zeros of entries appear as p-adic noise at any
   finite precision (probe runs 1 and 3, 13:58 and 14:11).
   A specialization can only RAISE an order (a leading coefficient may
   vanish at the point), so the observed minima are upper bounds of the
   true ones and equal them off a proper subvariety; a claim above the
   observation is refused, a claim at or below it is accepted (a lower
   claim is conservative: it only adds zero coefficients).  Three
   independent points must agree.  No symbolic valuation scan is
   performed.  The certificate stores a fingerprint of the record's
   TTotal, TTotalInverse and Ranges (structural Hash, whose value is
   version-dependent: $VersionNumber is recorded, and a mismatch is a
   typed refusal, never a silent re-trust). *)

$observableTransportValuationTrialCount = 3;

observableTransportEpsilonValuationFingerprint[record_Association] := <|
  "Version" -> 1,
  "Dimension" -> Length[Lookup[record, "TTotal", {}]],
  "Ranges" -> Lookup[record, "Ranges", Missing["Ranges"]],
  "Variables" -> ToString[Lookup[record, "Variables", Missing[]], InputForm],
  "Regulator" -> ToString[Lookup[record, "Regulator", Missing[]], InputForm],
  "TTotalHash" -> Hash[Normal[Lookup[record, "TTotal", Missing["TTotal"]]]],
  "TTotalInverseHash" ->
    Hash[Normal[Lookup[record, "TTotalInverse", Missing["TTotalInverse"]]]],
  "HashVersion" -> $VersionNumber|>;

(* Numeric radicals in canonical form: Power[r, n/2] with r a nonzero
   rational becomes rational * Sqrt[s]^(0 or 1) with s a square-free
   positive integer (I for a negative r).  With the radicands square-free,
   {Sqrt[s]} is linearly independent over Q(I), which makes the exact zero
   test below a decision, not a heuristic. *)
observableTransportCanonicalRadicals[expression_] := expression //.
  Power[r_ /; MatchQ[r, _Integer | _Rational] && r =!= 0,
      q_Rational /; Denominator[q] === 2] :>
    With[{split = observableTransportFFSquareFreeSplit[Abs[r]],
        n = Numerator[q]},
      (If[r < 0, I, 1] split[[1]])^n split[[2]]^((n - 1)/2) Sqrt[split[[2]]]];

(* Exact zero test of an algebraic number.  In canonical form the number
   is a Q(I)-linear combination of Sqrt[s] with s square-free positive
   integers; those are linearly independent, so after Expand (which
   collects equal radical monomials) the number is zero iff it is
   syntactically zero, and a nonempty sum of such monomials is nonzero.
   Anything outside that grammar (a radical left in a denominator, a
   nested radical) goes to RootReduce; a non-numeric coefficient is
   $Failed, never a guess.  RootReduce as the primary test was measured
   too slow on CF259 (probe run 4, killed at the 120 s cap). *)
observableTransportAlgebraicZeroQ[value_] := Module[{canonical, monomialQ},
  If[value === 0, Return[True]];
  If[MatchQ[value, _Integer | _Rational | _Complex], Return[False]];
  If[! NumericQ[value], Return[$Failed]];
  canonical = observableTransportCanonicalRadicals[Expand[
    observableTransportCanonicalRadicals[value]]];
  If[canonical === 0, Return[True]];
  monomialQ[term_] := MatchQ[term,
    _Integer | _Rational | _Complex |
    Power[s_Integer /; s > 1 && SquareFreeQ[s], 1/2] |
    Times[_Integer | _Rational | _Complex,
      Power[s_Integer /; s > 1 && SquareFreeQ[s], 1/2]]];
  If[If[Head[canonical] === Plus, AllTrue[List @@ canonical, monomialQ],
      monomialQ[canonical]],
    Return[False]];
  With[{reduced = Quiet[Check[RootReduce[canonical], $Failed]]},
    If[reduced === $Failed, $Failed, reduced === 0]]
];

(* Order in eps at eps = 0 of a univariate rational function with
   algebraic-number coefficients: Infinity for an identically vanishing
   function, ComplexInfinity for a vanishing denominator, $Failed when a
   coefficient could not be decided. *)
observableTransportEpsilonOrderAtPoint[expression_, eps_Symbol] := Module[
  {fraction, order},
  If[expression === 0, Return[Infinity]];
  fraction = Together[observableTransportCanonicalRadicals[expression]];
  If[fraction === 0, Return[Infinity]];
  order[polynomial_] := Module[
    {coefficients = CoefficientList[polynomial, eps], k = 0, zeroQ},
    While[k < Length[coefficients],
      zeroQ = observableTransportAlgebraicZeroQ[coefficients[[k + 1]]];
      If[zeroQ === $Failed, Return[$Failed, Module]];
      If[! zeroQ, Break[]];
      k++];
    If[k === Length[coefficients], Infinity, k]];
  With[{n = order[Numerator[fraction]], d = order[Denominator[fraction]]},
    Which[
      n === $Failed || d === $Failed, $Failed,
      d === Infinity, ComplexInfinity,
      n === Infinity, Infinity,
      True, n - d]]
];

(* One trial: TMin and BlockLower of the record's gauge observed at one
   rational point.  Same conventions as the exact gauge scan of
   BuildObservableTransport, except that TMin is the true minimum (the
   scan caps it at 0, a conservative choice that the acceptance rule
   admits). *)
observableTransportExactPointValuations[tTotal_, tInverse_, ranges_List,
    variables_List, eps_Symbol, point_List] := Module[
  {start = AbsoluteTime[], failure, rules, entriesT, entriesI, ordersT,
   ordersI, columns, tmin, blockLower},
  failure[status_, extra_: <||>] := Join[<|"Status" -> status,
    "Point" -> point|>, extra];
  entriesT = Flatten[Normal[tTotal]];
  entriesI = Flatten[Normal[tInverse]];
  columns = Length[First[Normal[tInverse]]];
  If[! FreeQ[{entriesT, entriesI},
      Power[a_ /; ! FreeQ[a, eps], e_ /; ! IntegerQ[e]]],
    Return[failure["EpsilonUnderRadicalOrSymbolicPower"]]];
  If[! FreeQ[{entriesT, entriesI}, Power[_, e_ /; ! FreeQ[e, eps]]],
    Return[failure["EpsilonInExponent"]]];
  rules = Thread[variables -> point];
  entriesT = entriesT /. rules;
  entriesI = entriesI /. rules;
  If[! FreeQ[{entriesT, entriesI},
      ComplexInfinity | Indeterminate | DirectedInfinity[___]],
    Return[failure["PointSingular"]]];
  If[! FreeQ[{entriesT, entriesI}, Alternatives @@ variables],
    Return[failure["PointSubstitutionIncomplete"]]];
  ordersT = observableTransportEpsilonOrderAtPoint[#, eps] & /@ entriesT;
  ordersI = observableTransportEpsilonOrderAtPoint[#, eps] & /@ entriesI;
  If[MemberQ[ordersT, $Failed] || MemberQ[ordersI, $Failed],
    Return[failure["CoefficientZeroTestUndecided"]]];
  If[MemberQ[ordersT, ComplexInfinity] || MemberQ[ordersI, ComplexInfinity],
    Return[failure["PointSingular"]]];
  If[DeleteCases[ordersT, Infinity] === {},
    Return[failure["TransformationVanishesAtPoint"]]];
  tmin = Min[DeleteCases[ordersT, Infinity]];
  ordersI = Partition[ordersI, columns];
  blockLower = Table[
    With[{orders = DeleteCases[
        Flatten[ordersI[[ranges[[block]], All]]], Infinity]},
      If[orders === {}, 0, Min[orders]]],
    {block, Length[ranges]}];
  <|"Status" -> "ExactPointValuationsEvaluated",
    "Point" -> point, "TMin" -> tmin, "BlockLower" -> blockLower,
    "Seconds" -> N[AbsoluteTime[] - start]|>
];

Options[observableTransportCertifyEpsilonValuations] = {
  "Trials" -> Automatic,
  "Seed" -> 20260902,
  "Valuations" -> Automatic,
  "MaximumAttempts" -> 24
};

(* Certify the record's TransportEpsilonValuations (or, when the record
   has none and "Valuations" is Automatic, DERIVE them from the trials).
   Returns <|"Status" -> "TransportEpsilonValuationsCertified",
   "Record" -> record with the certificate attached, ...|> or a typed
   failure.  Meant to run once, at compact-record construction
   (Scripts/compact_family_dlog_record.wls) or in place on an existing
   record (observableTransportCertifyEpsilonValuationsFile). *)
observableTransportCertifyEpsilonValuations[record_Association,
    OptionsPattern[]] := Module[
  {start = AbsoluteTime[], variables, eps, tTotal, tInverse, ranges,
   letters, dlog, rootSquares, claimed, claimedTMin, claimedBlockLower,
   trialCount, seed, maximumAttempts, trials = {}, rejected = {},
   attempts = 0, point, trial, observedTMin, observedBlockLower, tight,
   certificate, valuations, fingerprint},
  variables = Lookup[record, "Variables", Missing[]];
  eps = Lookup[record, "Regulator", Missing[]];
  tTotal = Lookup[record, "TTotal", Missing[]];
  tInverse = Lookup[record, "TTotalInverse", Missing[]];
  ranges = Lookup[record, "Ranges", Missing[]];
  If[! MatchQ[variables, {_Symbol, _Symbol}] || ! MatchQ[eps, _Symbol] ||
      ! MatrixQ[tTotal] || ! MatrixQ[tInverse] || ! ListQ[ranges] ||
      Dimensions[tTotal] =!= Dimensions[tInverse] ||
      Sort[Flatten[ranges]] =!= Range[Length[tTotal]],
    Return[<|"Status" -> "IncompleteFamilyEpsilonFormRecord"|>]];
  dlog = Lookup[record, "DLog", <||>];
  letters = Replace[Lookup[record, "Letters", Missing[]], Except[_List] :>
    If[AssociationQ[dlog], Replace[Lookup[dlog, "Letters", {}],
      Except[_List] -> {}], {}]];
  (* the declared root squares in the CURRENT variables, as the transport
     itself resolves them; a chart without roots contributes none *)
  rootSquares = Quiet[Check[transportChartCurrentRoots[
    Lookup[record, "ChartRecord", <||>], variables], $Failed]];
  rootSquares = Replace[rootSquares,
    {roots : {__Association} :> Lookup[roots, "RootSquare", {}], _ -> {}}];
  rootSquares = Select[rootSquares, ! FreeQ[#, Alternatives @@ variables] &];
  trialCount = Replace[OptionValue["Trials"],
    Automatic -> $observableTransportValuationTrialCount];
  seed = OptionValue["Seed"];
  maximumAttempts = OptionValue["MaximumAttempts"];
  If[! IntegerQ[trialCount] || trialCount < 2 || ! IntegerQ[seed] ||
      ! IntegerQ[maximumAttempts] || maximumAttempts < trialCount,
    Return[<|"Status" -> "TransportEpsilonValuationOptionsInvalid"|>]];
  claimed = Replace[OptionValue["Valuations"],
    Automatic :> Lookup[record, "TransportEpsilonValuations", None]];
  If[MissingQ[claimed], claimed = None];
  If[claimed =!= None &&
      ! (AssociationQ[claimed] &&
        IntegerQ[Lookup[claimed, "TMin", Missing[]]] &&
        VectorQ[Lookup[claimed, "BlockLower", Missing[]], IntegerQ] &&
        Length[claimed["BlockLower"]] === Length[ranges]),
    Return[<|"Status" -> "TransportEpsilonValuationsInvalid",
      "Valuations" -> claimed, "BlockCount" -> Length[ranges]|>]];
  BlockRandom[
    SeedRandom[seed];
    While[Length[trials] < trialCount && attempts < maximumAttempts,
      attempts++;
      point = Table[RandomInteger[{1, 199}]/RandomInteger[{200, 397}],
        {Length[variables]}];
      If[MemberQ[Lookup[trials, "Point", {}], point] ||
          ! observableTransportPointAdmissibleQ[letters, rootSquares,
            Thread[variables -> point]],
        AppendTo[rejected, <|"Status" -> "PointNotAdmissible",
          "Point" -> point|>]; Continue[]];
      trial = observableTransportExactPointValuations[tTotal, tInverse,
        ranges, variables, eps, point];
      If[Lookup[trial, "Status", None] =!= "ExactPointValuationsEvaluated",
        AppendTo[rejected, trial]; Continue[]];
      AppendTo[trials, trial]]];
  If[Length[trials] < trialCount,
    Return[<|"Status" -> "TransportEpsilonValuationTrialsInsufficient",
      "Accepted" -> Length[trials], "Required" -> trialCount,
      "Attempts" -> attempts, "RejectedTrials" -> rejected|>]];
  observedTMin = DeleteDuplicates[Lookup[trials, "TMin"]];
  observedBlockLower = DeleteDuplicates[Lookup[trials, "BlockLower"]];
  If[Length[observedTMin] =!= 1 || Length[observedBlockLower] =!= 1,
    Return[<|"Status" -> "TransportEpsilonValuationTrialsDisagree",
      "Trials" -> trials|>]];
  observedTMin = First[observedTMin];
  observedBlockLower = First[observedBlockLower];
  If[claimed === None,
    claimedTMin = observedTMin; claimedBlockLower = observedBlockLower,
    claimedTMin = claimed["TMin"]; claimedBlockLower = claimed["BlockLower"];
    If[claimedTMin > observedTMin ||
        AnyTrue[claimedBlockLower - observedBlockLower, # > 0 &],
      Return[<|"Status" -> "TransportEpsilonValuationsTooHigh",
        "ClaimedTMin" -> claimedTMin, "ObservedTMin" -> observedTMin,
        "ClaimedBlockLower" -> claimedBlockLower,
        "ObservedBlockLower" -> observedBlockLower,
        "Trials" -> trials|>]]];
  tight = claimedTMin === observedTMin &&
    claimedBlockLower === observedBlockLower;
  fingerprint = observableTransportEpsilonValuationFingerprint[record];
  certificate = <|
    "Status" -> "RationalPointEpsilonValuationCertificate",
    "Version" -> 1,
    "Accepted" -> True, "Probabilistic" -> True, "Exact" -> False,
    "Method" -> "ExactUnivariateOrderAtRandomRationalPoints",
    "TMin" -> claimedTMin, "BlockLower" -> claimedBlockLower,
    "ObservedTMin" -> observedTMin,
    "ObservedBlockLower" -> observedBlockLower,
    "Tight" -> tight,
    "Trials" -> trials, "RejectedTrials" -> rejected,
    "Seed" -> seed,
    "RootSquares" -> rootSquares,
    "Fingerprint" -> fingerprint,
    "Seconds" -> N[AbsoluteTime[] - start]|>;
  valuations = Join[If[AssociationQ[claimed], claimed, <||>], <|
    "TMin" -> claimedTMin, "BlockLower" -> claimedBlockLower,
    "Certificate" -> certificate|>];
  <|"Status" -> "TransportEpsilonValuationsCertified",
    "Tight" -> tight,
    "Valuations" -> valuations,
    "Certificate" -> certificate,
    "Record" -> Join[record, <|"TransportEpsilonValuations" -> valuations|>],
    "Seconds" -> N[AbsoluteTime[] - start]|>
];

(* Shape and arithmetic of a certificate for the claimed valuations:
   flags, at least two trials at distinct points that agree with the
   recorded observation, claim never above the observation. *)
observableTransportEpsilonValuationCertificateShapeQ[certificate_,
    tmin_, blockLower_] := AssociationQ[certificate] &&
  Lookup[certificate, "Status", None] ===
    "RationalPointEpsilonValuationCertificate" &&
  TrueQ[Lookup[certificate, "Accepted", False]] &&
  TrueQ[Lookup[certificate, "Probabilistic", False]] &&
  TrueQ[Lookup[certificate, "Exact", True] === False] &&
  IntegerQ[tmin] && VectorQ[blockLower, IntegerQ] &&
  Lookup[certificate, "TMin", Missing[]] === tmin &&
  Lookup[certificate, "BlockLower", Missing[]] === blockLower &&
  IntegerQ[Lookup[certificate, "ObservedTMin", Missing[]]] &&
  VectorQ[Lookup[certificate, "ObservedBlockLower", Missing[]], IntegerQ] &&
  Length[certificate["ObservedBlockLower"]] === Length[blockLower] &&
  tmin <= certificate["ObservedTMin"] &&
  AllTrue[blockLower - certificate["ObservedBlockLower"], # <= 0 &] &&
  MatchQ[Lookup[certificate, "Trials", None], {__Association}] &&
  Length[certificate["Trials"]] >= 2 &&
  AllTrue[certificate["Trials"],
    Lookup[#, "Status", None] === "ExactPointValuationsEvaluated" &&
      VectorQ[Lookup[#, "Point", Missing[]],
        MatchQ[#, _Integer | _Rational] &] &&
      Lookup[#, "TMin", Missing[]] === certificate["ObservedTMin"] &&
      Lookup[#, "BlockLower", Missing[]] ===
        certificate["ObservedBlockLower"] &] &&
  DuplicateFreeQ[Lookup[certificate["Trials"], "Point"]] &&
  AssociationQ[Lookup[certificate, "Fingerprint", None]];

(* Typed status of a record's transport epsilon valuations. *)
observableTransportEpsilonValuationStatus[record_Association] := Module[
  {valuations, certificate, ranges, fingerprint, stored},
  valuations = Lookup[record, "TransportEpsilonValuations",
    Missing["NotAvailable"]];
  If[MissingQ[valuations],
    Return[<|"Status" -> "TransportEpsilonValuationsNotAvailable"|>]];
  ranges = Lookup[record, "Ranges", {}];
  If[! AssociationQ[valuations] ||
      ! IntegerQ[Lookup[valuations, "TMin", Missing[]]] ||
      ! VectorQ[Lookup[valuations, "BlockLower", Missing[]], IntegerQ] ||
      ! ListQ[ranges] ||
      Length[valuations["BlockLower"]] =!= Length[ranges],
    Return[<|"Status" -> "TransportEpsilonValuationsInvalid",
      "Valuations" -> valuations, "BlockCount" -> Length[ranges]|>]];
  certificate = Lookup[valuations, "Certificate", Missing["Uncertified"]];
  If[! AssociationQ[certificate],
    Return[<|"Status" -> "TransportEpsilonValuationsUncertified",
      "TMin" -> valuations["TMin"],
      "Remedy" -> "observableTransportCertifyEpsilonValuations"|>]];
  If[! observableTransportEpsilonValuationCertificateShapeQ[certificate,
      valuations["TMin"], valuations["BlockLower"]],
    Return[<|"Status" -> "TransportEpsilonValuationCertificateInvalid",
      "TMin" -> valuations["TMin"], "BlockLower" -> valuations["BlockLower"],
      "CertificateTMin" -> Lookup[certificate, "TMin", Missing[]],
      "CertificateObservedTMin" ->
        Lookup[certificate, "ObservedTMin", Missing[]]|>]];
  fingerprint = observableTransportEpsilonValuationFingerprint[record];
  stored = certificate["Fingerprint"];
  If[stored =!= fingerprint,
    Return[<|"Status" -> "TransportEpsilonValuationCertificateMismatch",
      "StoredFingerprint" -> stored, "RecordFingerprint" -> fingerprint|>]];
  <|"Status" -> "TransportEpsilonValuationsCertified",
    "TMin" -> valuations["TMin"], "BlockLower" -> valuations["BlockLower"],
    "Tight" -> TrueQ[Lookup[certificate, "Tight", False]],
    "Certificate" -> certificate|>
];

(* The result-level binding checked by AcceptedObservableTransportQ: the
   valuations the transport USED are the ones its certificate names. *)
observableTransportEpsilonValuationCertificateBoundQ[source_, certificate_,
    valuations_] := AssociationQ[valuations] && AssociationQ[certificate] &&
  IntegerQ[Lookup[valuations, "TMin", Missing[]]] &&
  VectorQ[Lookup[valuations, "BlockLower", Missing[]], IntegerQ] &&
  Which[
    source === "FamilyRecord",
      observableTransportEpsilonValuationCertificateShapeQ[certificate,
        valuations["TMin"], valuations["BlockLower"]] &&
      TrueQ[Lookup[certificate, "FingerprintVerified", False]],
    source === "ComputedFromGauge",
      Lookup[certificate, "Status", None] === "ExactGaugeValuationScan" &&
      TrueQ[Lookup[certificate, "Accepted", False]] &&
      TrueQ[Lookup[certificate, "Exact", False]] &&
      Lookup[certificate, "Probabilistic", True] === False &&
      Lookup[certificate, "TMin", Missing[]] === valuations["TMin"] &&
      Lookup[certificate, "BlockLower", Missing[]] === valuations["BlockLower"],
    True, False];

Options[observableTransportCertifyEpsilonValuationsFile] = Join[
  Options[observableTransportCertifyEpsilonValuations],
  {"OutputFile" -> Automatic, "Write" -> True}];

(* Certify a record on disk in place (atomic replace; "OutputFile" for a
   copy, "Write" -> False for a dry run).  Reads through the
   context-guarded FamilyArtifactRead like every other artifact reader. *)
observableTransportCertifyEpsilonValuationsFile[file_String,
    opts : OptionsPattern[]] := Module[
  {start = AbsoluteTime[], record, status, result, output},
  If[! FileExistsQ[file],
    Return[<|"Status" -> "FamilyRecordFileMissing", "File" -> file|>]];
  record = FamilyArtifactRead[file];
  If[! AssociationQ[record],
    Return[<|"Status" -> "FamilyRecordUnreadable", "File" -> file|>]];
  status = observableTransportEpsilonValuationStatus[record];
  If[status["Status"] === "TransportEpsilonValuationsCertified",
    Return[Join[status, <|"File" -> file, "AlreadyCertified" -> True,
      "Seconds" -> N[AbsoluteTime[] - start]|>]]];
  result = observableTransportCertifyEpsilonValuations[record,
    Sequence @@ FilterRules[{opts},
      Options[observableTransportCertifyEpsilonValuations]]];
  If[Lookup[result, "Status", None] =!= "TransportEpsilonValuationsCertified",
    Return[Join[result, <|"File" -> file, "PriorStatus" -> status["Status"],
      "Seconds" -> N[AbsoluteTime[] - start]|>]]];
  output = Replace[OptionValue["OutputFile"], Automatic -> file];
  If[TrueQ[OptionValue["Write"]],
    observableTransportWriteAtomic[result["Record"], output]];
  Join[KeyDrop[result, {"Record", "Valuations"}], <|
    "File" -> file, "OutputFile" -> If[TrueQ[OptionValue["Write"]], output, None],
    "PriorStatus" -> status["Status"],
    "Seconds" -> N[AbsoluteTime[] - start]|>]
];



(* CertifyFamilyEpsilonForm and ExactFamilyEpsilonFormQ moved to
   FamilyEpsForm.wl on 2026-08-20. *)

(* Default family-name extractor (generality pass 2026-08-23): the family
   is the one canonical-family token in the file's base name, whatever
   prefix a campaign gives its artifacts.  A campaign whose file names do
   not carry the token supplies its own function through
   "FamilyFromFileName". *)
observableTransportFamilyFromFile[file_String] := Module[{match},
  match = DeleteDuplicates[StringCases[FileBaseName[file],
    $canonicalFamilyPrefix ~~ DigitCharacter ..]];
  If[Length[match] === 1, First[match], Missing["NoFamily"]]
];

observableTransportWriteAtomic[value_, file_String, format_: Automatic] :=
 Module[{directory, temporary},
  directory = DirectoryName[ExpandFileName[file]];
  If[! DirectoryQ[directory],
    CreateDirectory[directory, CreateIntermediateDirectories -> True]];
  temporary = FileNameJoin[{directory,
    "." <> FileNameTake[file] <> ".tmp-" <> ToString[$ProcessID]}];
  If[format === Automatic, Put[value, temporary],
    Export[temporary, value, format]];
  RenameFile[temporary, file, OverwriteTarget -> True];
  file
];

(* Generality pass 2026-08-23 (A2): the artifact NAMING of a campaign is
   the campaign's, not the package's.  The file patterns, the file-name ->
   family map and the family sort order are options; their defaults name
   no campaign prefix (only the canonical-family token) and the driver
   script passes the project's own patterns explicitly. *)
Options[BuildObservableTransportManifest] = {
  "Card" -> None,
  "ReportFile" -> Automatic,
  "DifferentialFilePattern" -> "*.wl",
  "EpsFormFilePattern" -> "*.wl",
  "FamilyFromFileName" -> Automatic,
  "FamilySortKey" -> Identity
};

BuildObservableTransportManifest[
    epsilonFormDirectories : {__String},
    differentialSystemDirectory_String, valuationsFile_String,
    manifestFile_String, OptionsPattern[]] := Module[
  {directories, differentialFiles, familyFromFile, candidates,
   candidateRows, grouped, selected = <||>, rejected = <||>,
   duplicates = <||>, missing, family, records, certifiedRecords,
   card, reportFile, rows, report, differentialPattern, epsFormPattern,
   familySortKey},
  directories = ExpandFileName /@ epsilonFormDirectories;
  If[! AllTrue[directories, DirectoryQ] ||
      ! DirectoryQ[differentialSystemDirectory] ||
      ! FileExistsQ[valuationsFile],
    Return[<|"Status" -> "InputPathMissing"|>]];
  differentialPattern = OptionValue["DifferentialFilePattern"];
  epsFormPattern = OptionValue["EpsFormFilePattern"];
  If[! StringQ[differentialPattern] || ! StringQ[epsFormPattern],
    Return[<|"Status" -> "InvalidFilePatternOption"|>]];
  familyFromFile = Replace[OptionValue["FamilyFromFileName"],
    Automatic -> observableTransportFamilyFromFile];
  familySortKey = Replace[OptionValue["FamilySortKey"],
    Automatic -> Identity];
  differentialFiles = SortBy[
    FileNames[differentialPattern, differentialSystemDirectory],
    FileBaseName];
  differentialFiles = Association @ Cases[differentialFiles,
    file_ :> With[{name = familyFromFile[file]},
      If[! StringQ[name], Nothing, name -> ExpandFileName[file]]]];
  If[differentialFiles === <||>,
    Return[<|"Status" -> "NoDifferentialFamiliesFound",
      "DifferentialSystemDirectory" ->
        ExpandFileName[differentialSystemDirectory],
      "DifferentialFilePattern" -> differentialPattern,
      "DifferentialFamilyCount" -> 0|>]];
  candidates = Flatten[Table[
    Thread[{priority,
      FileNames[epsFormPattern, directories[[priority]],
        Infinity]}],
    {priority, Length[directories]}], 1];
  candidateRows = Cases[candidates, {priority_Integer, file_String} :>
    Module[{name, record},
      name = familyFromFile[file];
      If[! StringQ[name] || ! KeyExistsQ[differentialFiles, name],
        Nothing,
        record = Quiet[Check[Get[file], $Failed]];
        <|"Family" -> name, "Priority" -> priority,
          "File" -> ExpandFileName[file],
          "Certified" -> CertifiedFamilyEpsilonFormQ[record],
          "Exact" -> ExactFamilyEpsilonFormQ[record]|>]
    ]];
  grouped = GroupBy[candidateRows, #Family &];
  Do[
    records = SortBy[Lookup[grouped, family, {}],
      {#Priority &, #File &}];
    certifiedRecords = Select[records, TrueQ[#Certified] &];
    If[certifiedRecords === {},
      If[records =!= {}, AssociateTo[rejected, family -> records]],
      AssociateTo[selected, family -> First[certifiedRecords]];
      If[Length[certifiedRecords] > 1,
        AssociateTo[duplicates, family -> Rest[certifiedRecords]]]],
    {family, Keys[differentialFiles]}];
  missing = Select[Keys[differentialFiles], ! KeyExistsQ[selected, #] &];
  card = OptionValue["Card"];
  If[card =!= None && (! StringQ[card] || ! FileExistsQ[card]),
    Return[<|"Status" -> "TransportCardMissing", "Card" -> card|>]];
  rows = Prepend[
    Table[{family, selected[family]["File"],
      differentialFiles[family], ExpandFileName[valuationsFile],
      If[card === None, "", ExpandFileName[card]]},
      {family, SortBy[Keys[selected], familySortKey]}],
    {"family", "epsilon_form", "differential_system", "valuations",
      "card"}];
  observableTransportWriteAtomic[rows, manifestFile, "TSV"];
  report = <|
    "Status" -> If[missing === {}, "CompleteCertifiedInventory",
      "IncompleteCertifiedInventory"],
    "DifferentialFamilyCount" -> Length[differentialFiles],
    "CertifiedFamilyCount" -> Length[selected],
    "MissingFamilies" -> SortBy[missing, familySortKey],
    "Selected" -> selected,
    "RejectedCandidates" -> rejected,
    "AdditionalCertifiedCandidates" -> duplicates,
    "Manifest" -> ExpandFileName[manifestFile]
  |>;
  reportFile = Replace[OptionValue["ReportFile"],
    Automatic :> FileNameJoin[{DirectoryName[ExpandFileName[manifestFile]],
      "transport_inventory.wl"}]];
  If[reportFile =!= None,
    observableTransportWriteAtomic[report, reportFile]];
  report
];

observableTransportFamilyName[integral_] := Module[{arguments, family},
  arguments = Quiet[Check[List @@ integral, {}]];
  If[Length[arguments] < 1, Return[Missing["NoFamily"], Module]];
  family = First[arguments];
  Which[
    StringQ[family], family,
    Head[family] === Symbol, SymbolName[family],
    True, Missing["NoFamily"]
  ]
];

observableTransportIntegralIndices[integral_] := Module[{arguments},
  arguments = Quiet[Check[List @@ integral, {}]];
  If[Length[arguments] >= 2 && ListQ[arguments[[2]]],
    arguments[[2]], Missing["NoIndices"]]
];

observableTransportNonsingularQ[expressions_List, rules_List] :=
  AllTrue[expressions, Function[expression,
    Module[{value = Quiet[Check[Together[expression /. rules], $Failed]]},
      value =!= $Failed &&
        FreeQ[value,
          Indeterminate | ComplexInfinity | DirectedInfinity[_]] &&
        ! TrueQ[Numerator[value] === 0] &&
        ! TrueQ[Denominator[value] === 0]
    ]
  ]];

observableTransportRecordRegularQ[record_Association, rules_List] :=
  AllTrue[
    DeleteCases[Flatten[{
      Lookup[record, "TTotal", {}],
      Lookup[record, "TTotalInverse", {}],
      Lookup[record, "EpsFormX", {}],
      Lookup[record, "EpsFormY", {}]
    }], 0],
    Function[expression,
      Module[{value = Quiet[Check[Together[expression /. rules], $Failed]]},
        value =!= $Failed &&
          FreeQ[value,
            Indeterminate | ComplexInfinity | DirectedInfinity[_]] &&
          ! TrueQ[Denominator[value] === 0]
      ]
    ]
  ];

Options[FindObservableTransportPath] = {
  "Candidates" -> Automatic
};

FindObservableTransportPath[record_Association, OptionsPattern[]] := Module[
  {variables, letters, coefficientField, fractions, candidates, selected,
   admissibleQ},
  variables = Lookup[record, "Variables", Missing[]];
  letters = Lookup[record, "Letters", Missing[]];
  If[! MatchQ[variables, {_Symbol, _Symbol}] || ! ListQ[letters],
    Return[<|"Status" -> "PathInputNotWellFormed"|>]
  ];
  fractions = {1/4, 1/3, 1/5, 2/7, 3/8, 2/5, 3/7, 3/11,
    4/11, 5/13};
  candidates = Replace[OptionValue["Candidates"], Automatic ->
    Select[Tuples[fractions, 3], #[[1]] =!= #[[3]] &]];
  If[! MatchQ[candidates, {{_, _, _} ..}],
    Return[<|"Status" -> "InvalidPathCandidates"|>]
  ];
  (* round 4: a record whose field cannot be resolved is refused here,
     not silently treated as rational *)
  coefficientField = observableTransportCoefficientField[record];
  If[MissingQ[coefficientField],
    Return[<|"Status" -> "CoefficientFieldRequired",
      "CoefficientField" -> coefficientField|>]
  ];
  admissibleQ = If[coefficientField === "Multiquadratic",
    Function[point,
      observableTransportRecordRegularQ[record,
        Thread[variables -> point]]],
    Function[point,
      observableTransportNonsingularQ[letters,
        Thread[variables -> point]]]
  ];
  selected = SelectFirst[candidates,
    admissibleQ[#[[1 ;; 2]]] &&
      admissibleQ[{#[[3]], #[[2]]}] &,
    Missing["NoNonsingularPath"]];
  If[MissingQ[selected],
    <|"Status" -> "NoNonsingularRationalPath"|>,
    <|
      "Status" -> "ExactPathData",
      "FirstVariable" -> variables[[1]],
      "SecondVariable" -> variables[[2]],
      "FirstBase" -> selected[[1]],
      "SecondBase" -> selected[[2]],
      "FirstTargetSample" -> selected[[3]],
      "BranchStatement" ->
        "The exact transport map is retained in the polynomial dlog " <>
        "alphabet. Physical analytic continuation is fixed separately."
    |>
  ]
];

Options[BuildObservableTransportDemand] = {
  "HardFunctionOrders" -> {0},
  "SafetyOrders" -> 1,
  "MasterValuation" -> 0,
  "Path" -> Automatic
};

BuildObservableTransportDemand[record_Association,
    familySystem_Association, valuations_List, OptionsPattern[]] := Module[
  {family, basis, permutation, hardOrders, safety, masterValuation,
   path, familyValuations, rows = {}, missing = {}, pairs, originalRow,
   recordRow, maximumOrder},

  family = Lookup[record, "Family", Missing["NoFamily"]];
  basis = Lookup[familySystem, "BlockBasis", Missing["NoBasis"]];
  permutation = Flatten[Lookup[record, "Blocks", Missing["NoBlocks"]]];
  hardOrders = Sort@DeleteDuplicates@Flatten@{
    OptionValue["HardFunctionOrders"]};
  safety = OptionValue["SafetyOrders"];
  masterValuation = OptionValue["MasterValuation"];
  path = OptionValue["Path"];
  If[! StringQ[family] || ! ListQ[basis] ||
      ! VectorQ[permutation, IntegerQ] ||
      ! VectorQ[hardOrders, IntegerQ] || hardOrders === {} ||
      ! IntegerQ[safety] || safety < 0 || ! IntegerQ[masterValuation],
    Return[<|"Status" -> "InvalidObservableDemandInput"|>]
  ];

  familyValuations = Select[valuations,
    AssociationQ[#] && Lookup[#, "Family", None] === family &&
      ListQ[Lookup[#, "Indices", None]] &&
      IntegerQ[Lookup[#, "Valuation", None]] &];
  Do[
      originalRow = FirstPosition[basis,
        integral_ /;
          observableTransportFamilyName[integral] === family &&
          observableTransportIntegralIndices[integral] ===
            item["Indices"],
        Missing["NotInFamilyBasis"], {1}];
      If[MissingQ[originalRow],
        AppendTo[missing, <|"Valuation" -> item,
          "Reason" -> "MasterNotInFamilyBasis"|>],
        originalRow = First[originalRow];
        recordRow = FirstPosition[permutation, originalRow,
          Missing["NotInRecordPermutation"], {1}];
        If[MissingQ[recordRow],
          AppendTo[missing,
            <|"Valuation" -> item, "OriginalRow" -> originalRow,
              "Reason" -> "MasterNotInRecordPermutation"|>],
          maximumOrder = Max[hardOrders] - item["Valuation"] + safety;
          If[maximumOrder >= masterValuation,
            AppendTo[rows, <|"Valuation" -> item["Valuation"],
              "OriginalRow" -> originalRow,
              "RecordRow" -> First[recordRow],
              "Orders" -> Range[masterValuation, maximumOrder]|>]
        ]
      ]
    ],
      {item, familyValuations}];
  If[missing =!= {},
    Return[<|"Status" -> "ObservableDemandMappingFailed",
      "Family" -> family, "Missing" -> missing|>]
  ];
  If[rows === {},
    Return[<|"Status" -> "NoNonzeroMasterCoefficientDemand",
      "Family" -> family|>]
  ];
  pairs = Sort@DeleteDuplicates@Flatten[
    Table[{order, row["RecordRow"]}, {row, rows},
      {order, row["Orders"]}], 1];
  <|
    "Status" -> "ExactObservableDemand",
    "Family" -> family,
    "PhysicalDemandPairs" -> pairs,
    "PhysicalValuation" -> masterValuation,
    "HardFunctionOrders" -> hardOrders,
    "SafetyOrders" -> safety,
    "MasterRows" -> rows,
    "Path" -> path
  |>
];

observableTransportSlotKey[{order_, component_}] :=
  ToString[Unevaluated[{order, component}], InputForm];

observableTransportEpsilonOrder[0, _] := Infinity;
observableTransportEpsilonOrder[x_, eps_] :=
  masterTransportEpsOrder[x, eps];

(* Laurent coefficients of a matrix of rational functions of eps whose
   coefficients live in an algebraic function field.  Three routes share
   one contract: an Association order -> matrix of coefficients, every
   coefficient canonicalized with Cancel[Together].

   "Series" (default since round 4, 2026-09-02, agent L): ONE Series call
   per entry, to the highest order that entry's row is read at, the
   coefficients read off the SeriesData.  Measured on real CF259 entries
   (Design/PrivateOverhaul_2026-09-01_evidence/round4/L_modular_laurent_route.md):
   the canonical coefficients are IDENTICAL (SameQ) to the former route's,
   at 1.4x (500 KB entries) to 30x (10 KB entries) lower cost -- the former
   route recomputed the series once per order and then paid a far more
   expensive Cancel[Together] on SeriesCoefficient's bulkier output.  An
   entry outside the SeriesData contract (Puiseux exponents, a
   non-SeriesData result) takes the SeriesCoefficient route for that entry
   alone, so every route is the same function of the input.  Rows are
   expanded only as far as the transport reads them (a demanded component
   to its highest demanded order, every other component to the forbidden
   range, see observableTransportLaurentRowHighs); orders above a row's
   cap are stored as 0 and never read -- both consumers assert that.

   "SeriesCoefficient": the former route (SeriesCoefficient per entry and
   order), kept for comparison.

   "Jet" is RETIRED (round 6, 2026-09-02): the epsilon-jet route (compile
   each entry once into an eps-polynomial numerator/denominator, division
   recurrence) was measured pathological on nested-quotient entries
   (agent L, round4/L_modular_laurent_route.md: the compile of CF259 entry
   (42,20) does not finish in 30 s; the 21-minute rejection of 05:05 was
   the same effect) and lives in Private_Backup/ObservableTransportJet.wl
   with its test; selecting it answers $observableTransportLaurentJetRetired. *)
$observableTransportLaurentMethod = "Series";
$observableTransportLaurentJetRetired = <|"Status" -> "RouteRetired",
  "Route" -> "Laurent jet", "Replacement" -> "Series"|>;


(* One Series call per entry (route "Series").  Returns the coefficient
   list for orders low..high, or $Failed when the SeriesData contract is
   not met (the caller then uses SeriesCoefficient for that entry).  The
   transport's valuation record asserts that no entry has a pole below
   `low`; an entry that has one is counted in
   $observableTransportLaurentDiagnostics["ValuationBelowRange"] and the
   transport refuses the record (fail closed) where the former route
   silently truncated. *)
$observableTransportLaurentDiagnostics = <||>;
observableTransportLaurentEntrySeries[e_, eps_, {low_Integer, high_Integer}] :=
 Module[{series, coefficients, nmin, nmax},
  If[high < low, Return[{}]];
  If[TrueQ[e === 0], Return[ConstantArray[0, high - low + 1]]];
  If[FreeQ[e, eps],
    Return[Table[If[order === 0, observableTransportCancel[e], 0],
      {order, low, high}]]];
  series = Quiet[Check[Series[e, {eps, 0, high}], $Failed]];
  If[Head[series] =!= SeriesData || series[[1]] =!= eps ||
      series[[2]] =!= 0 || series[[6]] =!= 1,
    Return[$Failed]];
  (* Part with a list spec keeps the SeriesData head: read the three
     fields one at a time *)
  coefficients = series[[3]]; nmin = series[[4]]; nmax = series[[5]];
  (* orders below nmax are known (listed or zero); an order at or above
     the truncation is not, and cannot occur for the rational class this
     route serves: fall back rather than guess *)
  If[nmax <= high, Return[$Failed]];
  If[coefficients =!= {} && nmin < low,
    $observableTransportLaurentDiagnostics["ValuationBelowRange"] =
      Lookup[$observableTransportLaurentDiagnostics,
        "ValuationBelowRange", 0] + 1];
  Table[observableTransportCancel[
      If[nmin <= order <= nmin + Length[coefficients] - 1,
        coefficients[[order - nmin + 1]], 0]],
    {order, low, high}]
];

(* Highest order at which the transport reads each component of the
   Laurent tensor: the forbidden map reads every component at orders up to
   valuation - 1 - flow, the demanded map reads a demanded component up to
   its highest demanded order - flow. *)
observableTransportLaurentRowHighs[dimension_Integer, valuation_Integer,
    flow_Integer, physicalDemandPairs_List] := Table[
  Max[valuation - 1 - flow,
    Max[Cases[physicalDemandPairs, {order_, component} :> order - flow]]],
  {component, dimension}];

observableTransportLaurentRows[matrix_, eps_, {low_Integer, high_Integer},
    indices_List, rowHighs_: Automatic] := Module[
  {caps, rows, entryCoefficients},
  caps = If[rowHighs === Automatic, ConstantArray[high, Length[indices]],
    Min[high, #] & /@ rowHighs[[indices]]];
  Which[
   $observableTransportLaurentMethod === "Jet",
    Return[$observableTransportLaurentJetRetired, Module],
   $observableTransportLaurentMethod === "Series",
    entryCoefficients[entry_, cap_] := Module[{coefficients},
      If[cap < low, Return[ConstantArray[0, high - low + 1], Module]];
      coefficients = observableTransportLaurentEntrySeries[entry, eps,
        {low, cap}];
      If[coefficients === $Failed,
        $observableTransportLaurentDiagnostics["SeriesFallbackCount"] =
          Lookup[$observableTransportLaurentDiagnostics,
            "SeriesFallbackCount", 0] + 1;
        coefficients = Table[observableTransportCancel[
          SeriesCoefficient[entry, {eps, 0, order}]], {order, low, cap}]];
      (* orders above the row's cap are placeholders, never read *)
      PadRight[coefficients, high - low + 1, 0]];
    rows = MapThread[Function[{row, cap},
        Map[entryCoefficients[#, cap] &, Normal[matrix[[row]]]]],
      {indices, caps}],
   True,
    (* the former route, per entry and order, up to the row's cap *)
    rows = MapThread[Function[{row, cap},
        Map[Function[entry, PadRight[Table[observableTransportCancel[
            SeriesCoefficient[entry, {eps, 0, order}]], {order, low, cap}],
          high - low + 1, 0]], Normal[matrix[[row]]]]],
      {indices, caps}]
  ];
  Association@Table[order -> rows[[All, All, order - low + 1]],
    {order, low, high}]
];

observableTransportLaurentMatricesTask[file_String,
    indices_List] := Module[
  {data = FamilyArtifactRead[file], matrix, eps, orderRange, rowHighs,
   coefficients},
  If[! AssociationQ[data], Return[$Failed, Module]];
  {matrix, eps, orderRange} =
    Lookup[data, {"Matrix", "Epsilon", "OrderRange"}, $Failed];
  rowHighs = Lookup[data, "RowHighs", Automatic];
  If[! MatrixQ[matrix] || eps === $Failed ||
      ! MatchQ[orderRange, {_Integer, _Integer}],
    Return[$Failed, Module]];
  $observableTransportLaurentDiagnostics = <||>;
  coefficients = observableTransportLaurentRows[matrix, eps, orderRange,
    indices, rowHighs];
  <|"Coefficients" -> coefficients,
    "Diagnostics" -> $observableTransportLaurentDiagnostics|>
];

observableTransportLaurentMatrices[m_, eps_,
    orderRange : {low_Integer, high_Integer}, rowHighs_: Automatic] := Module[
  {matrix = Normal[m], dimensions, helperCount, chunks, payloadFile,
   codes, handle, local, results, mergeDiagnostics},
  $observableTransportLaurentDiagnostics = <||>;
  If[$observableTransportLaurentMethod === "Jet",
    Return[$observableTransportLaurentJetRetired, Module]];
  dimensions = Quiet[Check[Dimensions[matrix], {}]];
  If[Length[dimensions] =!= 2,
    Return[Association@Table[order -> Map[
      observableTransportCancel[SeriesCoefficient[#, {eps, 0, order}]] &,
      matrix, {2}], {order, low, high}], Module]];
  If[rowHighs =!= Automatic &&
      ! (VectorQ[rowHighs, IntegerQ] && Length[rowHighs] === dimensions[[1]]),
    Return[$Failed, Module]];
  local[indices_List] :=
    observableTransportLaurentRows[matrix, eps, orderRange, indices,
      rowHighs];
  (* helper kernels report their own counters; sum them into ours *)
  mergeDiagnostics[diagnostics_Association] := KeyValueMap[
    ($observableTransportLaurentDiagnostics[#1] =
      Lookup[$observableTransportLaurentDiagnostics, #1, 0] + #2) &,
    diagnostics];
  helperCount = If[dimensions[[1]] > 1 &&
      Times @@ dimensions Max[1, high - low + 1] >= 2048 &&
      TrueQ[taskBrokerActiveQ[]],
    Min[dimensions[[1]] - 1,
      Max[0, Quiet[Check[taskBrokerFreeKernels[], 0]]]], 0];
  If[helperCount < 1,
    Return[local[Range[dimensions[[1]]]], Module]];
  chunks = Partition[Range[dimensions[[1]]],
    UpTo[Ceiling[dimensions[[1]]/(helperCount + 1)]]];
  payloadFile = taskBrokerDataFile[
    "observable_laurent_" <> ToString[$ProcessID] <> "_" <>
      StringReplace[CreateUUID[], "-" -> ""],
    <|"Matrix" -> matrix, "Epsilon" -> eps,
      "OrderRange" -> orderRange, "RowHighs" -> rowHighs|>];
  codes = ("FeynFacet`Private`observableTransportLaurentMatricesTask[" <>
      ToString[payloadFile, InputForm] <> "," <>
      ToString[#, InputForm] <> "]") & /@ Most[chunks];
  handle = taskBrokerSubmit[codes, "Label" -> "observableLaurent"];
  (* the local chunk counts its diagnostics in this kernel directly, so
     it is wrapped with an empty record *)
  results = Append[taskBrokerCollect[handle],
    <|"Coefficients" -> local[Last[chunks]], "Diagnostics" -> <||>|>];
  results = MapThread[Function[{result, chunk},
    If[AssociationQ[result] &&
        AssociationQ[Lookup[result, "Coefficients", None]] &&
        Sort[Keys[result["Coefficients"]]] === Range[low, high] &&
        AllTrue[Values[result["Coefficients"]], Function[value,
          MatrixQ[value] &&
            Dimensions[value] === {Length[chunk], dimensions[[2]]}]],
      mergeDiagnostics[Lookup[result, "Diagnostics", <||>]];
      result["Coefficients"],
      local[chunk]]], {results, chunks}];
  Quiet[DeleteFile[payloadFile]];
  Association@Table[
    order -> Join @@ (Lookup[#, order] & /@ results),
    {order, low, high}]
];

observableTransportIndependentRows[m_, rules_List] := Module[
  {evaluated, reduced, pivots},
  If[Length[m] === 0, Return[{}]];
  evaluated = Normal[m] /. rules;
  If[! FreeQ[evaluated,
      Indeterminate | ComplexInfinity | DirectedInfinity[_]],
    Return[$Failed]
  ];
  reduced = RowReduce[Transpose[evaluated]];
  pivots = DeleteMissing[
    (Replace[
       FirstPosition[#, x_ /; ! TrueQ[x === 0],
         Missing["ZeroRow"], {1}, Heads -> False],
       {position_Integer} :> position
     ] &) /@ reduced
  ];
  DeleteDuplicates[pivots]
];

observableTransportIndependentRowsTask[file_String, indices_List] := Module[
  {data},
  data = taskBrokerRead[file];
  If[! AssociationQ[data], Return[$Failed, Module]];
  observableTransportIndependentRows[data["Matrix"],
      data["Samples"][[#]]] & /@ indices
];

(* Multiquadratic rank proposals use cheap local modular images below.  Exact
   rational samples remain independent and can be memory-heavy, so borrow at
   most one helper per additional sample within the dynamic family grant. *)
observableTransportIndependentRowsAtSamples[m_, samples_List,
    rootSquares_List : {}] := Module[
  {dimensions, helperCount, chunks, payloadFile, codes, handle, results,
   local, variables},
  dimensions = Quiet[Check[Dimensions[m], {}]];
  variables = DeleteDuplicates[Cases[samples,
    HoldPattern[(variable_Symbol -> _)] :> variable, Infinity]];
  If[rootSquares =!= {},
    Return[observableTransportFFAlgebraicIndependentRowsAtSamples[
      m, variables, samples, rootSquares], Module]];
  local[indices_List] :=
    (observableTransportIndependentRows[m, samples[[#]]] &) /@ indices;
  helperCount = If[Length[samples] > 1 && Length[dimensions] === 2 &&
      Times @@ dimensions >= 4096 && TrueQ[taskBrokerActiveQ[]],
    Min[Quiet[Check[taskBrokerFreeKernels[], 0]],
      Length[samples] - 1], 0];
  If[helperCount < 1,
    Return[local[Range[Length[samples]]], Module]];
  chunks = Partition[Range[Length[samples]],
    UpTo[Ceiling[Length[samples]/(helperCount + 1)]]];
  payloadFile = taskBrokerDataFile[
    "observable_rank_" <> ToString[$ProcessID] <> "_" <>
      StringReplace[CreateUUID[], "-" -> ""],
    <|"Matrix" -> m, "Samples" -> samples|>];
  codes = ("FeynFacet`Private`observableTransportIndependentRowsTask[" <>
      ToString[payloadFile, InputForm] <> "," <>
      ToString[#, InputForm] <> "]") & /@ Most[chunks];
  handle = taskBrokerSubmit[codes, "Label" -> "observableRank"];
  results = Append[taskBrokerCollect[handle], local[Last[chunks]]];
  results = MapThread[
    If[ListQ[#1] && Length[#1] === Length[#2], #1, local[#2]] &,
    {results, chunks}];
  Quiet[DeleteFile[payloadFile]];
  Flatten[results, 1]
];

observableTransportMaximalIndependentRows[m_, samples_List,
    rootSquares_List : {}] := Module[
  {candidates},
  candidates = DeleteCases[
    observableTransportIndependentRowsAtSamples[
      m, samples, rootSquares], $Failed];
  If[candidates === {}, $Failed,
    First@MaximalBy[candidates, Length]]
];

(* Extend an already-certified basis without ever exchanging one of its rows
   for a sample-dependent pivot.  Losing a prefix row here can silently lose
   an original forbidden constraint at an exceptional rank sample. *)
observableTransportMaximalIndependentExtensionRows[basis_, additions_,
    samples_List, rootSquares_List : {}] := Module[
  {prefixLength, candidate, candidates, pivots},
  prefixLength = Length[basis];
  candidate = Join[basis, additions];
  pivots = observableTransportIndependentRowsAtSamples[
    candidate, samples, rootSquares];
  candidates = Select[pivots, Function[value,
    value =!= $Failed &&
      AllTrue[Range[prefixLength], MemberQ[value, #] &]]];
  If[candidates === {}, $Failed,
    First@MaximalBy[candidates, Length]]
];

observableTransportCovariantRowsTask[file_String, indices_List] := Module[
  {data, basis, connection, variable},
  data = taskBrokerRead[file];
  If[! AssociationQ[data], Return[$Failed, Module]];
  {basis, connection, variable} =
    Lookup[data, {"Basis", "Connection", "Variable"}, $Failed];
  If[! MatrixQ[basis] || ! MatrixQ[connection] ||
      ! MatchQ[variable, _Symbol], Return[$Failed, Module]];
  basis = Normal[basis[[indices]]];
  D[basis, variable] + basis . Normal[connection]
];

(* A family mission cannot launch nested subkernels.  For a sufficiently
   large closure step, lend its independent row batches to the free kernels
   of the existing flat task broker; small steps retain the direct path. *)
observableTransportCovariantRows[basis_, connection_, variable_Symbol] :=
 Module[{normalBasis = Normal[basis], normalConnection = Normal[connection],
   dimensions, rowCount, columnCount, helperCount, chunks, payloadFile,
   codes, handle, results, local},
  dimensions = Dimensions[normalBasis];
  If[Length[dimensions] =!= 2, Return[$Failed, Module]];
  {rowCount, columnCount} = dimensions;
  local[indices_List] := D[normalBasis[[indices]], variable] +
    normalBasis[[indices]] . normalConnection;
  helperCount = If[TrueQ[taskBrokerActiveQ[]] &&
      rowCount columnCount >= 4096,
    Min[Quiet[Check[taskBrokerFreeKernels[], 0]],
      Max[0, Quotient[rowCount, 8] - 1]], 0];
  If[helperCount < 1, Return[local[Range[rowCount]], Module]];
  chunks = Partition[Range[rowCount],
    UpTo[Ceiling[rowCount/(helperCount + 1)]]];
  payloadFile = taskBrokerDataFile[
    "observable_covariant_" <> ToString[$ProcessID] <> "_" <>
      StringReplace[CreateUUID[], "-" -> ""],
    <|"Basis" -> normalBasis, "Connection" -> normalConnection,
      "Variable" -> variable|>];
  codes = ("FeynFacet`Private`observableTransportCovariantRowsTask[" <>
      ToString[payloadFile, InputForm] <> "," <>
      ToString[#, InputForm] <> "]") & /@ Most[chunks];
  handle = taskBrokerSubmit[codes, "Label" -> "observableCovariant"];
  results = Append[taskBrokerCollect[handle], local[Last[chunks]]];
  results = MapThread[
    If[MatrixQ[#1] && Dimensions[#1] === {Length[#2], columnCount},
      #1, local[#2]] &,
    {results, chunks}];
  Quiet[DeleteFile[payloadFile]];
  Join @@ results
];

(* Close a row space under D_variable + A without constructing its nullspace
   or reconstructing a rational change of row basis.  Every retained basis row
   is an actual generated row.  Rank samples propose the finite basis; fresh
   modular points certify both the initial compression and final closure. *)
observableTransportCovariantRowClosure[rows_, connection_, variable_,
    variables_List, samples_List, maximumSteps_Integer,
    primeCount_Integer, pointsPerPrime_Integer,
    verbose_: False, rootSquares_: {}] := Module[
  {dimensions, stateDimension, pivots, basis, rankHistory,
   initialSpanCertificate = Missing["Structural"],
   stabilizationCertificate = Missing["FullRank"],
   initialSpanMethod, stabilizationMethod, covariant, candidate,
   covariantCompiled, modularCovariant, pivotCandidates, selectedRows,
   nextPivots, currentRank, nextRank, step, certify},
  certify[space_, candidates_] := If[
    transportChartRadicalBases[{space, candidates}] === {},
    observableTransportModularSubspaceInclusion[
      space, candidates, variables,
      "ValidationPrimeCount" -> primeCount,
      "ValidationPointsPerPrime" -> pointsPerPrime],
    observableTransportModularAlgebraicSubspaceInclusion[
      space, candidates, variables, rootSquares,
      "ValidationPrimeCount" -> primeCount,
      "ValidationPointsPerPrime" -> pointsPerPrime]];
  dimensions = Quiet[Check[Dimensions[rows], {}]];
  (* round 4 (2026-09-02): SparseArray[{}, {0, n}] evaluates to the plain
     list {} -- a zero-row matrix has no second dimension -- so an empty
     row set (a record without forbidden constraints, AmbientBasePoint
     branch) takes its state dimension from the connection *)
  If[Length[rows] === 0 && MatchQ[Dimensions[connection], {n_, n_}],
    dimensions = {0, First[Dimensions[connection]]}];
  If[Length[dimensions] =!= 2 ||
      Dimensions[connection] =!= {Last[dimensions], Last[dimensions]},
    Return[<|"Status" -> "CovariantClosureInputsInvalid"|>, Module]];
  stateDimension = Last[dimensions];
  If[First[dimensions] === 0,
    Return[<|"Status" -> "CovariantRowClosureAccepted",
      "Basis" -> SparseArray[{}, {0, stateDimension}],
      "RankHistory" -> {0}, "InitialSpanMethod" -> "Structural",
      "StabilizationMethod" -> "NoRows",
      "InitialSpanCertificate" -> initialSpanCertificate,
      "StabilizationCertificate" -> stabilizationCertificate|>, Module]];
  pivots = observableTransportMaximalIndependentRows[
    rows, samples, rootSquares];
  If[pivots === $Failed,
    Return[<|"Status" -> "CovariantClosureRankSampleFailed"|>, Module]];
  basis = rows[[pivots]];
  rankHistory = {Length[pivots]};
  If[Length[pivots] < First[dimensions],
    initialSpanCertificate = certify[basis, rows];
    If[! AssociationQ[initialSpanCertificate] ||
        Lookup[initialSpanCertificate, "Status", None] =!=
          "FreshModularSubspaceInclusionAccepted",
      Return[If[AssociationQ[initialSpanCertificate],
        initialSpanCertificate,
        <|"Status" -> "CovariantClosureInitialSpanFailed"|>], Module]];
    initialSpanMethod = "FreshModular",
    initialSpanMethod = "Structural"
  ];
  If[Length[pivots] === stateDimension,
    stabilizationMethod = "FullRank";
    Return[<|"Status" -> "CovariantRowClosureAccepted",
      "Basis" -> basis, "RankHistory" -> rankHistory,
      "InitialSpanMethod" -> initialSpanMethod,
      "StabilizationMethod" -> stabilizationMethod,
      "InitialSpanCertificate" -> initialSpanCertificate,
      "StabilizationCertificate" -> stabilizationCertificate|>, Module]
  ];
  Do[
    currentRank = Length[basis];
    modularCovariant = False;
    covariantCompiled = If[rootSquares === {}, $Failed,
      Quiet[Check[observableTransportFFCompileAlgebraicCovariant[
        basis, connection, variables, rootSquares], $Failed]]];
    If[rootSquares =!= {} && ! AssociationQ[covariantCompiled],
      Return[<|"Status" -> "AlgebraicCovariantCompilerFailed",
        "Step" -> step|>, Module]];
    If[AssociationQ[covariantCompiled],
      pivotCandidates = Select[
        observableTransportFFAlgebraicCovariantIndependentRowsAtSamples[
          covariantCompiled, variable, variables, samples],
        Function[value, value =!= $Failed &&
          AllTrue[Range[currentRank], MemberQ[value, #] &]]];
      If[pivotCandidates =!= {},
        nextPivots = First@MaximalBy[pivotCandidates, Length];
        modularCovariant = True,
        Return[<|"Status" -> "AlgebraicCovariantRankProposalFailed",
          "Step" -> step|>, Module]]];
    If[! TrueQ[modularCovariant],
      covariant = observableTransportCovariantRows[
        basis, connection, variable];
      If[! MatrixQ[covariant],
        Return[<|"Status" -> "CovariantClosureConstructionFailed",
          "Step" -> step|>, Module]];
      candidate = Join[basis, covariant];
      nextPivots = observableTransportMaximalIndependentExtensionRows[
        basis, covariant, samples, rootSquares]];
    If[nextPivots === $Failed,
      Return[<|"Status" -> "CovariantClosureRankSampleFailed",
        "Step" -> step|>, Module]];
    nextRank = Length[nextPivots];
    If[nextRank < currentRank,
      Return[<|"Status" -> "CovariantClosureRankDecreased",
        "Step" -> step, "CurrentRank" -> currentRank,
        "NextRank" -> nextRank|>, Module]];
    If[TrueQ[verbose], Print["Observable covariant closure step ", step,
      ": rank ", currentRank, " -> ", nextRank]];
    If[nextRank === currentRank,
      stabilizationCertificate = If[TrueQ[modularCovariant],
        observableTransportModularAlgebraicCovariantSubspaceInclusion[
          covariantCompiled, variable, variables,
          "ValidationPrimeCount" -> primeCount,
          "ValidationPointsPerPrime" -> pointsPerPrime],
        certify[basis, covariant]];
      If[stabilizationCertificate === $Failed,
        If[rootSquares =!= {},
          Return[<|"Status" -> "AlgebraicCovariantCertificateUnavailable",
            "Step" -> step|>, Module]];
        covariant = observableTransportCovariantRows[
          basis, connection, variable];
        If[! MatrixQ[covariant],
          Return[<|"Status" -> "CovariantClosureConstructionFailed",
            "Step" -> step|>, Module]];
        stabilizationCertificate = certify[basis, covariant]];
      If[! AssociationQ[stabilizationCertificate] ||
          Lookup[stabilizationCertificate, "Status", None] =!=
            "FreshModularSubspaceInclusionAccepted",
        Return[If[AssociationQ[stabilizationCertificate],
          stabilizationCertificate,
          <|"Status" -> "CovariantClosureStabilizationFailed"|>],
          Module]];
      stabilizationMethod = "FreshModular";
      AppendTo[rankHistory, currentRank];
      Return[<|"Status" -> "CovariantRowClosureAccepted",
        "Basis" -> basis, "RankHistory" -> rankHistory,
        "InitialSpanMethod" -> initialSpanMethod,
        "StabilizationMethod" -> stabilizationMethod,
        "InitialSpanCertificate" -> initialSpanCertificate,
        "StabilizationCertificate" -> stabilizationCertificate|>, Module]
    ];
    If[TrueQ[modularCovariant],
      selectedRows = Select[nextPivots, # > currentRank &] - currentRank;
      covariant = observableTransportCovariantRows[
        basis[[selectedRows]], connection, variable];
      If[! MatrixQ[covariant],
        Return[<|"Status" -> "CovariantClosureConstructionFailed",
          "Step" -> step|>, Module]];
      basis = Join[basis, covariant],
      basis = candidate[[nextPivots]]];
    AppendTo[rankHistory, nextRank];
    If[nextRank === stateDimension,
      stabilizationMethod = "FullRank";
      Return[<|"Status" -> "CovariantRowClosureAccepted",
        "Basis" -> basis, "RankHistory" -> rankHistory,
        "InitialSpanMethod" -> initialSpanMethod,
        "StabilizationMethod" -> stabilizationMethod,
        "InitialSpanCertificate" -> initialSpanCertificate,
        "StabilizationCertificate" -> stabilizationCertificate|>, Module]
    ],
    {step, maximumSteps}];
  <|"Status" -> "CovariantClosureDidNotStabilize",
    "RankHistory" -> rankHistory|>
];

observableTransportKernel[m_] := Module[{dimension, vectors},
  dimension = If[MatrixQ[m], Dimensions[m][[2]], 0];
  If[Length[m] === 0,
    Return[If[dimension === 0, {}, IdentityMatrix[dimension]]]];
  vectors = NullSpace[m];
  If[vectors === {}, ConstantArray[0, {dimension, 0}], Transpose[vectors]]
];

observableTransportBoundaryEmbedding[kernel_, boundarySlots_List,
    newBoundarySlots_List, extendedPositions_Association,
    extendedCount_Integer] := Module[{columns, rules},
  columns = If[boundarySlots === {}, 0,
    If[MatrixQ[kernel], Dimensions[kernel][[2]], 0]];
  rules = Reap[
    Do[
      With[{stateRow = extendedPositions[observableTransportSlotKey[
            boundarySlots[[boundaryRow]]]],
          value = kernel[[boundaryRow, column]]},
        If[! observableTransportZeroQ[value],
          Sow[{stateRow, column} -> value]]],
      {boundaryRow, Length[boundarySlots]}, {column, columns}];
    Do[
      Sow[{extendedPositions[observableTransportSlotKey[
            newBoundarySlots[[i]]]], columns + i} -> 1],
      {i, Length[newBoundarySlots]}]
  ][[2]];
  SparseArray[
    If[rules === {}, {}, First[rules]],
    {extendedCount, columns + Length[newBoundarySlots]}]
];

(* Reconstruct constant residue matrices R_a from
     A_i/eps = Sum_a R_a d_i Log[letter_a]
   and then check the identity symbolically in both variables. *)
observableTransportResidues[letters_List, connections_List,
    variables : {_, _}, samples_List] := Module[
  {dlogs, coefficientRows, connectionRows, letterPivots, selectedLetters,
   selectedDlogs, rowPivots, square, sampledConnections, residueRows,
   dimension, residues, reconstructed},

  dimension = Length[First[connections]];
  dlogs = ({
      observableTransportCancel[D[#, variables[[1]]]/#],
      observableTransportCancel[D[#, variables[[2]]]/#]
    } &) /@ letters;
  coefficientRows = Flatten[Table[
    (#[[direction]] /. Thread[variables -> point]) & /@ dlogs,
    {point, samples}, {direction, 2}], 1];
  connectionRows = Flatten[Table[
    Flatten[connections[[direction]] /. Thread[variables -> point]],
    {point, samples}, {direction, 2}], 1];

  letterPivots = observableTransportIndependentRows[
    Transpose[coefficientRows], {}];
  If[letterPivots === $Failed || letterPivots === {},
    Return[<|"Status" -> "ResidueRankFailed"|>]
  ];
  selectedLetters = letters[[letterPivots]];
  selectedDlogs = dlogs[[letterPivots]];
  coefficientRows = coefficientRows[[All, letterPivots]];

  rowPivots = observableTransportIndependentRows[coefficientRows, {}];
  If[rowPivots === $Failed || Length[rowPivots] < Length[selectedLetters],
    Return[<|"Status" -> "ResidueSamplingFailed"|>]
  ];
  rowPivots = Take[rowPivots, Length[selectedLetters]];
  square = coefficientRows[[rowPivots]];
  sampledConnections = connectionRows[[rowPivots]];
  residueRows = LinearSolve[square, sampledConnections];
  residues = Partition[#, dimension] & /@ residueRows;

  reconstructed = Table[
    Sum[selectedDlogs[[a, direction]] residues[[a]],
      {a, Length[selectedLetters]}],
    {direction, 2}
  ];
  reconstructed = observableTransportCancelMatrix /@ reconstructed;
  If[! And @@ MapThread[
      observableTransportZeroMatrixQ[#1 - #2] &,
      {connections, reconstructed}],
    Return[<|"Status" -> "ResidueIdentityFailed"|>]
  ];
  <|
    "Status" -> "Exact",
    "Letters" -> selectedLetters,
    "Residues" -> residues,
    "Identity" -> True
  |>
];

observableTransportLiftResidues[residues_List, slots_List] := Module[
  {positions, dimension, liftedDimension, rules, row, column, value},
  If[residues === {}, Return[{}]];
  positions = AssociationThread[
    observableTransportSlotKey /@ slots, Range[Length[slots]]];
  dimension = Length[First[residues]];
  liftedDimension = Length[slots];
  Table[
    rules = Reap[
      Do[
        row = positions[observableTransportSlotKey[slot]];
        Do[
          column = Lookup[positions,
            observableTransportSlotKey[{slot[[1]] - 1, source}], Missing[]];
          value = residues[[a, slot[[2]], source]];
          (* This test controls sparse storage only.  Keeping a nonliteral
             mathematical zero is harmless; proving it here repeats the same
             connection-entry simplification for every epsilon slot. *)
          If[! MissingQ[column] && ! TrueQ[value === 0],
            Sow[{row, column} -> value]],
          {source, dimension}],
        {slot, slots}]
    ][[2]];
    SparseArray[If[rules === {}, {}, First[rules]],
      {liftedDimension, liftedDimension}],
    {a, Length[residues]}]
];

observableTransportWordMaps[residues_List, boundary_, demanded_,
    maximumWeight_Integer] := Module[
  {states, maps, stateCounts, mapCounts, scalarCounts, projected, children},
  states = {{{}, boundary}};
  maps = {};
  stateCounts = {};
  mapCounts = {};
  scalarCounts = {};
  Do[
    AppendTo[stateCounts, Length[states]];
    projected = ({#[[1]],
          observableTransportCancelMatrix[demanded . #[[2]]]} &) /@ states;
    projected = Select[projected,
      ! observableTransportZeroMatrixQ[#[[2]]] &];
    maps = Join[maps, projected];
    AppendTo[mapCounts, Length[projected]];
    AppendTo[scalarCounts,
      Total[Count[Flatten[#[[2]]], x_ /; ! observableTransportZeroQ[x]] & /@
        projected]];
    If[weight < maximumWeight,
      children = Flatten[Table[
        With[{child = residues[[a]] . state[[2]]},
          If[observableTransportZeroMatrixQ[child], Nothing,
            {Prepend[state[[1]], a], child}]],
        {state, states}, {a, Length[residues]}], 1],
      children = states
    ];
    states = children,
    {weight, 0, maximumWeight}
  ];
  children = Flatten[Table[
    With[{child = residues[[a]] . state[[2]]},
      If[observableTransportZeroMatrixQ[child], Nothing,
        {Prepend[state[[1]], a], child}]],
    {state, states}, {a, Length[residues]}], 1];
  <|
    "Maps" -> maps,
    "StateCountsByWeight" -> stateCounts,
    "MapCountsByWeight" -> mapCounts,
    "ScalarCountsByWeight" -> scalarCounts,
    "NextWeightIsZero" -> (children === {})
  |>
];

(* Upper bound for the number of ordered two-segment words through the
   requested weight.  It is used only to choose a representation; the
   compact branch never enumerates this inventory. *)
observableTransportWordCountBound[firstAlphabet_Integer,
    secondAlphabet_Integer, maximumWeight_Integer, limit_Integer] := Module[
  {count = 0, firstPower = 1, secondPower, firstWeight, secondWeight},
  Do[
    secondPower = 1;
    Do[
      count += firstPower secondPower;
      If[count > limit, Return[limit + 1, Module]];
      secondPower *= secondAlphabet,
      {secondWeight, 0, maximumWeight - firstWeight}
    ];
    firstPower *= firstAlphabet,
    {firstWeight, 0, maximumWeight}
  ];
  count
];

(* Demand-dual weighted automaton.  At weight w, O_w is a row basis of

       span { P R_word : |word| = w }.

   The reconstructed quotient matrices satisfy

       O_w R_a = C_(a,w) O_(w+1)

   at independently chosen finite-field points.  Crucially, the first-path
   terminal factor and the final base embedding stay separate.  Thus the
   ambient-base-point ordering is

       A0 C... O_w K_b... N_base,

   rather than the incorrect O_w N_base K_b ordering. *)
observableTransportCompactDualAutomaton[residues_List, demanded_,
    firstBoundary_, finalEmbedding_, maximumWeight_Integer,
    variables_List, sampleRules_List, coordinateOptions_Association,
    verbose_: False] := Module[
  {rowBasis, basisRecord, observableRows, initialCoordinates,
   transitions = {}, terminals = {}, ranks = {}, coordinateCertificates,
   products, candidates, coordinates, transitionMatrices, currentRank,
   stateDimension, firstBoundaryColumns, remainingWeights, zeroRows,
   zeroTerminal, zeroTransitions, weight, key},

  stateDimension = Dimensions[firstBoundary][[1]];
  firstBoundaryColumns = Dimensions[firstBoundary][[2]];
  coordinateCertificates = {};
  rowBasis[matrix_, coordinateKey_] :=
    observableTransportModularRowBasis[
      matrix, variables, sampleRules,
      "CoordinateBackend" ->
        Lookup[coordinateOptions, "CoordinateBackend", Automatic],
      "CoordinateCacheDirectory" ->
        Lookup[coordinateOptions, "CoordinateCacheDirectory", Automatic],
      "ReconstructionThreads" ->
        Lookup[coordinateOptions, "ReconstructionThreads", Automatic],
      "ValidationPrimeCount" ->
        Lookup[coordinateOptions, "ValidationPrimeCount", 2],
      "ValidationPointsPerPrime" ->
        Lookup[coordinateOptions, "ValidationPointsPerPrime", 1],
      "CoordinateKey" -> coordinateKey,
      "Verbose" -> verbose
    ];

  basisRecord = rowBasis[demanded, "weight-000-initial"];
  If[! AssociationQ[basisRecord] ||
      Lookup[basisRecord, "Status", None] =!=
        "ModularRowBasisAccepted",
    Return[If[AssociationQ[basisRecord], basisRecord,
      <|"Status" -> "ModularInitialRowBasisFailed"|>], Module]
  ];
  observableRows = basisRecord["Basis"];
  initialCoordinates = basisRecord["Coordinates"];
  AppendTo[coordinateCertificates, basisRecord["ModularCertificate"]];

  If[residues === {},
    currentRank = Dimensions[observableRows][[1]];
    ranks = Join[{currentRank}, ConstantArray[0, maximumWeight]];
    zeroTerminal = SparseArray[{}, {0, firstBoundaryColumns}];
    terminals = Join[{If[currentRank === 0, zeroTerminal,
        observableRows . firstBoundary]},
      ConstantArray[zeroTerminal, maximumWeight]];
    transitions = ConstantArray[{}, maximumWeight];
    Return[<|
      "Status" -> "ModularCompactAutomatonAccepted",
      "Orientation" -> "DualObservableRows",
      "RequestedMaximumWeight" -> maximumWeight,
      "ObservableRankByExactWeight" -> ranks,
      "InitialCoordinates" -> initialCoordinates,
      "ObservableTransitionsByWeight" -> transitions,
      "TerminalContractionsByExactWeight" -> terminals,
      "FinalBoundaryEmbedding" -> finalEmbedding,
      "CoordinateCertificates" -> coordinateCertificates,
      "Probabilistic" -> True|>, Module]
  ];

  Do[
    currentRank = Dimensions[observableRows][[1]];
    AppendTo[ranks, currentRank];
    AppendTo[terminals, If[currentRank === 0,
      SparseArray[{}, {0, firstBoundaryColumns}],
      observableRows . firstBoundary]];

    If[currentRank === 0 && weight < maximumWeight,
      remainingWeights = maximumWeight - weight;
      ranks = Join[ranks, ConstantArray[0, remainingWeights]];
      zeroRows = SparseArray[{}, {0, stateDimension}];
      zeroTerminal = SparseArray[{}, {0, firstBoundaryColumns}];
      terminals = Join[terminals,
        ConstantArray[zeroTerminal, remainingWeights]];
      zeroTransitions = Table[SparseArray[{}, {0, 0}],
        {Length[residues]}];
      transitions = Join[transitions,
        ConstantArray[zeroTransitions, remainingWeights]];
      observableRows = zeroRows;
      Break[]
    ];

    If[weight < maximumWeight,
      products = (observableRows . #) & /@ residues;
      candidates = If[products === {},
        SparseArray[{}, {0, stateDimension}], Join @@ products];
      key = "weight-" <> IntegerString[weight + 1, 10, 3];
      If[TrueQ[verbose], Print[
        "Observable compact quotient ", key, ": candidates ",
        Dimensions[candidates], ", current rank ", currentRank]];
      basisRecord = rowBasis[candidates, key];
      If[! AssociationQ[basisRecord] ||
          Lookup[basisRecord, "Status", None] =!=
            "ModularRowBasisAccepted",
        Return[Join[<|"Weight" -> weight + 1|>,
          If[AssociationQ[basisRecord], basisRecord,
            <|"Status" -> "ModularTransitionRowBasisFailed"|>]], Module]
      ];
      coordinates = basisRecord["Coordinates"];
      transitionMatrices = If[basisRecord["Rank"] === 0,
        Table[SparseArray[{}, {currentRank, 0}], {Length[residues]}],
        Table[
          coordinates[[(a - 1) currentRank + Range[currentRank], All]],
          {a, Length[residues]}]
      ];
      AppendTo[transitions, transitionMatrices];
      AppendTo[coordinateCertificates, basisRecord["ModularCertificate"]];
      observableRows = If[basisRecord["Rank"] === 0,
        SparseArray[{}, {0, stateDimension}], basisRecord["Basis"]]
    ],
    {weight, 0, maximumWeight}
  ];

  <|
    "Status" -> "ModularCompactAutomatonAccepted",
    "Orientation" -> "DualObservableRows",
    "RequestedMaximumWeight" -> maximumWeight,
    "ObservableRankByExactWeight" -> ranks,
    "InitialCoordinates" -> initialCoordinates,
    "ObservableTransitionsByWeight" -> transitions,
    "TerminalContractionsByExactWeight" -> terminals,
    "FinalBoundaryEmbedding" -> finalEmbedding,
    "CoordinateCertificates" -> coordinateCertificates,
    "Probabilistic" -> True
  |>
];

(* Decompose a one-variable rational connection into exact kernels times
   constant matrices. The kernels remain rational functions; no branch is
   selected here. *)
observableTransportKernelDecomposition[m_, variable_] := Module[
  {terms, kernels, matrices, key, position, apart, together, numerator,
   denominator, degree, leading, monicDenominator, normalizedNumerator,
   coefficientRules, coefficient},
  kernels = {};
  matrices = {};
  Do[
    apart = Apart[m[[row, column]], variable];
    terms = If[Head[apart] === Plus, List @@ apart, {apart}];
    Do[
      If[observableTransportZeroQ[term], Continue[]];
      together = observableTransportCancel[term];
      numerator = Numerator[together];
      denominator = Denominator[together];
      degree = Exponent[denominator, variable];
      If[degree <= 0,
        Return[<|"Status" -> "PolynomialSecondSegment",
          "Entry" -> {row, column}, "Term" -> term|>]
      ];
      leading = Coefficient[denominator, variable, degree];
      monicDenominator = Expand[denominator/leading];
      normalizedNumerator = Expand[numerator/leading];
      If[Exponent[normalizedNumerator, variable] >= degree,
        Return[<|"Status" -> "ImproperSecondSegmentFraction",
          "Entry" -> {row, column}, "Term" -> term|>]
      ];
      coefficientRules = CoefficientRules[normalizedNumerator, {variable}];
      Do[
        coefficient = rule[[2]];
        If[! FreeQ[coefficient, variable],
          Return[<|"Status" -> "NonconstantKernelCoefficient",
            "Entry" -> {row, column}, "Term" -> term|>]
        ];
        key = observableTransportCancel[
          variable^First[rule[[1]]]/monicDenominator];
        position = FirstPosition[kernels, key, Missing[]];
        If[MissingQ[position],
          AppendTo[kernels, key];
          AppendTo[matrices, ConstantArray[0, Dimensions[m]]];
          position = {Length[kernels]}
        ];
        matrices[[position[[1]], row, column]] += coefficient,
        {rule, coefficientRules}],
      {term, terms}
    ],
    {row, Length[m]}, {column, Length[First[m]]}
  ];
  matrices = observableTransportCancelMatrix /@ matrices;
  <|"Status" -> "Exact", "Kernels" -> kernels,
    "Matrices" -> matrices, "Identity" -> True|>
];

observableTransportSecondSegmentMaps[firstMaps_List, matrices_List,
    baseEmbedding_, maximumWeight_Integer] := Module[
  {output, counts, scalarCounts, states, children, totalWeight, projected},
  output = {};
  counts = ConstantArray[0, maximumWeight + 1];
  scalarCounts = ConstantArray[0, maximumWeight + 1];
  Do[
    states = {{{}, first[[2]]}};
    Do[
      totalWeight = Length[first[[1]]] + secondWeight;
      Do[
        projected = observableTransportCancelMatrix[
          state[[2]] . baseEmbedding];
        If[! observableTransportZeroMatrixQ[projected],
          AppendTo[output, {first[[1]], state[[1]], projected}];
          counts[[totalWeight + 1]]++;
          scalarCounts[[totalWeight + 1]] +=
            Count[Flatten[projected],
              x_ /; ! observableTransportZeroQ[x]]
        ],
        {state, states}
      ];
      If[totalWeight < maximumWeight,
        children = Flatten[Table[
          With[{child = state[[2]] . matrices[[a]]},
            If[observableTransportZeroMatrixQ[child], Nothing,
              {Append[state[[1]], a], child}]],
          {state, states}, {a, Length[matrices]}], 1],
        children = {}
      ];
      states = children,
      {secondWeight, 0, maximumWeight - Length[first[[1]]]}
    ],
    {first, firstMaps}
  ];
  <|"Maps" -> output, "MapCountsByWeight" -> counts,
    "ScalarCountsByWeight" -> scalarCounts|>
];

Options[BuildObservableTransport] = {
  "MaximumWeight" -> Automatic,
  "ClosureSteps" -> Automatic,
  "RankSamples" -> Automatic,
  "ResidueSamples" -> Automatic,
  "BoundaryEvolution" -> Automatic,
  "MovingKernelLeafLimit" -> 2000,
  "WordRepresentation" -> Automatic,
  "MaterializedWordLimit" -> 4096,
  "CoordinateBackend" -> Automatic,
  "CoordinateCacheDirectory" -> Automatic,
  "ReconstructionThreads" -> Automatic,
  "ValidationPrimeCount" -> 2,
  "ValidationPointsPerPrime" -> 1,
  "GaugeConstantRules" -> Automatic,
  "DiagnosticDirectory" -> None,
  "Verbose" -> False
};

BuildObservableTransport[record_Association, demand_Association,
    OptionsPattern[]] := Catch@Module[
  {status, variables, eps, dimension, ranges, tTotal, tInverse,
   epsConnections, letters, physicalDemandPairs, physicalRows,
   physicalOrders, valuation,
   path, firstVariable, secondVariable, firstBase, secondBase,
   firstTargetSample, tau, rankSamples, automatonRankSamples,
   residueSamples, valuationRecord, valuationSource, valuationStatus,
   valuationCertificate, sampleExhaustion, tmin,
   blockLower, rowLower, blockOfRow, pathRules, tangent,
   firstConnection, secondConnection, propagatedLower, stateRowLower,
   flow, forbiddenFHigh, forbiddenPhysicalOrders, slots, positions,
   boundarySlots, boundaryPositions, embedding, lifted, tLaurent,
   tLaurentHigh,
   forbiddenRows, forbiddenLabels, forbiddenMap, basis,
   closureHistory, closureSteps, constraintMatrix, constraintPivots,
   constraintRank,
   baseStageStart,
   closureRecord, closureInitialSpanCertificate, closureInitialSpanMethod,
   closureStabilizationCertificate, closureStabilizationMethod,
   constraintLeafCount, boundaryEvolution, movingKernelLeafLimit,
   boundaryKernel, baseConstraintMatrix, baseBoundaryKernel,
   extendedFHigh, extendedSlots, extendedPositions, extendedBoundarySlots,
   newBoundarySlots, transportBoundary, baseBoundaryEmbedding,
   terminalEmbedding, boundarySelector, extendedConstraintMatrix,
   ambientSecondConnection, ambientLiftedSecond, ambientCovariant,
   ambientInvarianceCertificate, secondClosureRecord, secondClosureHistory,
   secondClosureInitialSpanCertificate, secondClosureInitialSpanMethod,
   secondClosureStabilizationCertificate,
   secondClosureStabilizationMethod, secondRankSamples,
   tDemandLaurent, demandedRows, physicalLabels, rowHighs, laurentOrder,
   laurentOverrun,
   physicalDemand, physicalOrder, component,
   demandedMap, familyCertificate, recordDLog, certificateDLog,
   certifiedDLog, residueDLogSource, residueProbabilistic,
   residueRecord, residueRecordUsableQ, usableDLogQ,
   firstKernelRecord,
   liftedResidues,
   pathActiveLetters, firstKernelIndices, firstKernelMethod,
   maximumWeight, wordRecord, wordRepresentation, materializedWordLimit,
   wordCountBound, compactAutomaton, operatorAutomaton, coordinateOptions,
   liftedSecond, boundaryDerivative, inducedRhs, pivotRows, pivotSquare,
   secondEvolutionConnection, inducedResidual, kernelRecord,
   secondActiveLetters,
   secondRecord, verbose, start, recordExactQ, recordCertifiedQ,
   recordTransportReadyQ, computedDLogQ, epsFormRepresentation,
   compactDLogActiveIndices, compactDLogConnection,
   compactResidueSupport, firstSupport, stabilized,
   coefficientField, gaugeConstants, gaugeConstantRules, resultStatus,
   probabilisticCertificates, structuralProbabilisticCertificates,
   algebraicRootRecords, rankFailure},

  start = AbsoluteTime[];
  verbose = TrueQ[OptionValue["Verbose"]];
  status = Lookup[record, "Status", Missing[]];
  variables = Lookup[record, "Variables", Missing[]];
  eps = Lookup[record, "Regulator", Missing[]];
  If[! MatchQ[variables, {_Symbol, _Symbol}] || ! MatchQ[eps, _Symbol],
    Return[<|"Status" -> "TwoVariableRecordRequired"|>, Module]
  ];
  dimension = Lookup[record, "Dim", Length[Lookup[record, "TTotal", {}]]];
  ranges = Lookup[record, "Ranges", Missing[]];
  tTotal = Lookup[record, "TTotal", Missing[]];
  tInverse = Lookup[record, "TTotalInverse", Missing[]];
  letters = Lookup[record, "Letters", Missing[]];
  recordDLog = Lookup[record, "DLog", <||>];
  epsFormRepresentation = Lookup[record, "EpsFormRepresentation", "ExplicitMatrices"];
  coefficientField = observableTransportCoefficientField[record];
  If[! MemberQ[{"Rational", "Multiquadratic"}, coefficientField],
    Return[<|"Status" -> "ObservableTransportCoefficientFieldMissingOrInvalid",
      "CoefficientField" -> coefficientField|>, Module]
  ];
  computedDLogQ[value_] := AssociationQ[value] &&
    Lookup[value, "Status", None] === "ComputedDLogResidues" &&
    TrueQ[Lookup[value, "Valid", False]] &&
    Lookup[value, "Purpose", None] === "ObservableTransportInput" &&
    Lookup[value, "Variables", Missing[]] === variables &&
    Lookup[value, "Regulator", Missing[]] === eps &&
    Lookup[value, "Dimension", Missing[]] === dimension &&
    Lookup[value, "CoefficientField", Missing[]] === coefficientField &&
    ListQ[Lookup[value, "Letters", None]] &&
    ListQ[Lookup[value, "Residues", None]] &&
    Length[value["Letters"]] === Length[value["Residues"]] &&
    AllTrue[value["Residues"],
      MatrixQ[#] && Dimensions[#] === {dimension, dimension} &] &&
    TrueQ[Lookup[value, "ConstantResidues", False]] &&
    TrueQ[Lookup[value, "PointwiseReplay", False]] &&
    TrueQ[Lookup[value, "FreshPrimeValidation", False]];
  recordExactQ = ExactFamilyEpsilonFormQ[record];
  recordCertifiedQ = CertifiedFamilyEpsilonFormQ[record];
  recordTransportReadyQ =
    status === "TransportReadyEpsilonConnection" &&
    epsFormRepresentation === "ConstantResidueDLog" &&
    TrueQ[Lookup[Lookup[record, "BlockAssemblyEvidence", <||>],
      "CompletePairCoverage", False]] && computedDLogQ[recordDLog];
  If[! (recordCertifiedQ || recordExactQ || recordTransportReadyQ),
    Return[<|"Status" -> "FamilyEpsilonFormInputNotReady",
      "RecordStatus" -> status,
      "ComputedDLogReady" -> computedDLogQ[recordDLog]|>, Module]
  ];
  epsConnections = {
    Lookup[record, "EpsFormX", Missing[]],
    Lookup[record, "EpsFormY", Missing[]]
  };
  algebraicRootRecords = If[coefficientField === "Multiquadratic",
    Quiet[Check[transportChartCurrentRoots[
      Lookup[record, "ChartRecord", <||>], variables], $Failed]], {}];
  If[coefficientField === "Multiquadratic" &&
      (! ListQ[algebraicRootRecords] || algebraicRootRecords === {}),
    Return[<|"Status" -> "MultiquadraticRootFrameUnavailable"|>, Module]
  ];
  If[! AllTrue[epsConnections, MatrixQ] && recordTransportReadyQ,
    letters = recordDLog["Letters"]
  ];
  If[! ListQ[ranges] || ! MatrixQ[tTotal] || ! MatrixQ[tInverse] ||
      (! recordTransportReadyQ && ! AllTrue[epsConnections, MatrixQ]) ||
      ! ListQ[letters],
    Return[<|"Status" -> "IncompleteFamilyEpsilonFormRecord"|>, Module]
  ];
  (* Some historical canonicalizers left Mathematica-generated integration
     constants C[i] as arbitrary nonzero row/column normalizations in TTotal.
     They are pure gauge and otherwise enlarge Q(x,y) by spurious parameters.
     Fix them deterministically before transport; record the choice so the
     associated boundary-coordinate convention is explicit. *)
  gaugeConstants = SortBy[DeleteDuplicates[Cases[
    {tTotal, tInverse,
      If[recordTransportReadyQ,
        {recordDLog["Letters"], recordDLog["Residues"]},
        epsConnections], letters},
    HoldPattern[System`C[_Integer]], Infinity]], ToString[#, InputForm] &];
  gaugeConstantRules = Replace[OptionValue["GaugeConstantRules"], {
    Automatic -> Thread[gaugeConstants -> Range[Length[gaugeConstants]]],
    None -> {}}];
  If[! MatchQ[gaugeConstantRules, {(_Rule) ...}] ||
      ! AllTrue[Last /@ gaugeConstantRules,
        MatchQ[#, _Integer | _Rational] && ! TrueQ[# === 0] &] ||
      Complement[First /@ gaugeConstantRules, gaugeConstants] =!= {},
    Return[<|"Status" -> "InvalidGaugeConstantRules",
      "GaugeConstants" -> gaugeConstants|>, Module]
  ];
  If[gaugeConstantRules =!= {},
    tTotal = tTotal /. gaugeConstantRules;
    tInverse = tInverse /. gaugeConstantRules;
    If[recordTransportReadyQ,
      recordDLog = Join[recordDLog, <|
        "Letters" -> (recordDLog["Letters"] /. gaugeConstantRules),
        "Residues" -> (recordDLog["Residues"] /.
          gaugeConstantRules)|>],
      epsConnections = epsConnections /. gaugeConstantRules];
    letters = letters /. gaugeConstantRules
  ];

  (* A constant-residue dlog record is already the computational form needed
     by transport.  Construct only the directional connection that a later
     closure actually consumes; never rematerialize both full two-variable
     epsilon-form matrices. *)
  compactDLogActiveIndices[direction_] := Select[
    Range[Length[recordDLog["Residues"]]],
    ! observableTransportStructuralZeroMatrixQ[
        recordDLog["Residues"][[#]]] &&
      ! observableTransportZeroQ[
        D[recordDLog["Letters"][[#]], direction]] &];
  compactDLogConnection[direction_, rules_, scale_] := Module[
    {indices, kernels},
    indices = compactDLogActiveIndices[direction];
    If[indices === {},
      Return[ConstantArray[0, {dimension, dimension}], Module]];
    (* Preserve declared radical representatives literally.  Cancel may
       extract square factors and thereby change the registered root frame. *)
    kernels = If[coefficientField === "Multiquadratic",
      (((D[#, direction]/# /. rules) scale) &) /@
        recordDLog["Letters"][[indices]],
      (observableTransportCancel[
          (D[#, direction]/# /. rules) scale] &) /@
        recordDLog["Letters"][[indices]]];
    Total[MapThread[#1 Normal[#2] &,
      {kernels, recordDLog["Residues"][[indices]]}]]
  ];
  compactResidueSupport[direction_] := Module[{indices, positions},
    indices = compactDLogActiveIndices[direction];
    positions = DeleteDuplicates@Flatten[
      (Position[Normal[#], value_ /; ! TrueQ[value === 0], {2},
          Heads -> False] &) /@
        recordDLog["Residues"][[indices]], 1];
    SparseArray[If[positions === {}, {}, Thread[positions -> 1]],
      {dimension, dimension}]
  ];
  If[verbose, Print["Observable transport input preparation: ",
    Round[AbsoluteTime[] - start, 0.1], " s"]];

  physicalDemandPairs = Lookup[demand, "PhysicalDemandPairs", Automatic];
  If[physicalDemandPairs === Automatic,
    physicalRows = Lookup[demand, "PhysicalRows", All];
    If[physicalRows === All, physicalRows = Range[dimension]];
    physicalOrders = Sort@DeleteDuplicates@Flatten@{
      Lookup[demand, "PhysicalOrders", Missing[]]};
    physicalDemandPairs = Flatten[
      Table[{order, row}, {order, physicalOrders}, {row, physicalRows}], 1],
    physicalDemandPairs = Sort@DeleteDuplicates[physicalDemandPairs];
    physicalRows = DeleteDuplicates[physicalDemandPairs[[All, 2]]];
    physicalOrders = Sort@DeleteDuplicates[physicalDemandPairs[[All, 1]]]
  ];
  valuation = Lookup[demand, "PhysicalValuation", 0];
  If[! MatchQ[physicalDemandPairs, {{_Integer, _Integer} ..}] ||
      ! VectorQ[physicalRows, IntegerQ] ||
      ! AllTrue[physicalRows, 1 <= # <= dimension &] ||
      ! VectorQ[physicalOrders, IntegerQ] || physicalOrders === {} ||
      ! IntegerQ[valuation],
    Return[<|"Status" -> "InvalidPhysicalDemand"|>, Module]
  ];

  path = Lookup[demand, "Path", Automatic];
  If[path === Automatic, path = FindObservableTransportPath[record]];
  If[AssociationQ[path] &&
      Lookup[path, "Status", None] === "ExactPathData",
    path = KeyDrop[path, "Status"]];
  If[! AssociationQ[path],
    Return[<|"Status" -> "PathDataRequired"|>, Module]
  ];
  firstVariable = Lookup[path, "FirstVariable", First[variables]];
  If[! MemberQ[variables, firstVariable],
    Return[<|"Status" -> "InvalidFirstPathVariable"|>, Module]
  ];
  secondVariable = First@DeleteCases[variables, firstVariable];
  firstBase = Lookup[path, "FirstBase", Missing[]];
  secondBase = Lookup[path, "SecondBase", Missing[]];
  firstTargetSample = Lookup[path, "FirstTargetSample", Missing[]];
  If[MemberQ[{firstBase, secondBase, firstTargetSample}, _Missing],
    Return[<|"Status" -> "PathDataRequired",
      "Required" -> {"FirstBase", "SecondBase", "FirstTargetSample"}|>,
      Module]
  ];
  tau = Unique["observablePath"];
  rankSamples = Replace[OptionValue["RankSamples"], Automatic -> {
      {tau -> 2/5, secondVariable -> 3/11},
      {tau -> 3/5, secondVariable -> 4/13},
      {tau -> 4/7, secondVariable -> 2/9}
    }];
  automatonRankSamples = {
    {firstVariable -> firstBase, secondVariable -> secondBase},
    Join[{firstVariable -> firstTargetSample}, First[rankSamples]],
    Join[{firstVariable -> (firstBase + firstTargetSample)/2},
      Last[rankSamples]]
  };
  residueSamples = Replace[OptionValue["ResidueSamples"], Automatic -> {
      {1/7, 1/11}, {2/7, 2/11}, {3/7, 3/11}, {4/7, 5/11},
      {5/7, 7/11}, {1/5, 2/9}, {2/5, 4/9}
    }];
  (* Round 4 (Codex review, correctness point 1): valuations carried by
     the record are used only when they are CERTIFIED -- bound to this
     record's TTotal, TTotalInverse and Ranges by the fingerprint of the
     modular certificate (observableTransportCertifyEpsilonValuations)
     and never above the observed minimum orders.  Uncertified,
     malformed or mismatched valuations are refused with the typed
     status of observableTransportEpsilonValuationStatus, and the accept
     predicate requires the certificate again on the result.  A record
     without valuations keeps the exact gauge scan (not a transport-ready
     record, which never materializes the full gauge). *)
  valuationRecord = Lookup[record, "TransportEpsilonValuations",
    Missing["NotAvailable"]];
  If[! MissingQ[valuationRecord],
    valuationStatus = observableTransportEpsilonValuationStatus[record];
    If[Lookup[valuationStatus, "Status", None] =!=
        "TransportEpsilonValuationsCertified",
      Return[Join[valuationStatus,
        <|"Family" -> Lookup[record, "Family", Missing[]]|>], Module]];
    tmin = valuationRecord["TMin"];
    blockLower = valuationRecord["BlockLower"];
    valuationSource = "FamilyRecord";
    valuationCertificate = Join[valuationStatus["Certificate"],
      <|"FingerprintVerified" -> True|>],
    If[recordTransportReadyQ,
      Return[<|"Status" -> "TransportEpsilonValuationsRequired"|>,
        Module]];
    tmin = Min[0, Sequence @@ DeleteCases[
        observableTransportEpsilonOrder[#, eps] & /@ Flatten[tTotal],
        Infinity]];
    blockLower = Table[
      With[{orders = DeleteCases[
          observableTransportEpsilonOrder[#, eps] & /@
            Flatten[tInverse[[ranges[[block]], All]]], Infinity]},
        If[orders === {}, 0, Min[orders]]],
      {block, Length[ranges]}];
    valuationSource = "ComputedFromGauge";
    valuationCertificate = <|"Status" -> "ExactGaugeValuationScan",
      "Accepted" -> True, "Exact" -> True, "Probabilistic" -> False,
      "TMin" -> tmin, "BlockLower" -> blockLower|>
  ];
  rowLower = ConstantArray[Missing["NotCovered"], dimension];
  blockOfRow = ConstantArray[0, dimension];
  Do[
    Do[rowLower[[row]] = blockLower[[block]];
       blockOfRow[[row]] = block, {row, ranges[[block]]}],
    {block, Length[ranges]}];
  If[! FreeQ[rowLower, _Missing] || MemberQ[blockOfRow, 0],
    Return[<|"Status" -> "BlockRangesDoNotCoverFamily"|>, Module]
  ];
  If[verbose, Print["Observable transport epsilon valuations: ",
    Round[AbsoluteTime[] - start, 0.1], " s cumulative; source ",
    valuationSource]];

  pathRules = {
    firstVariable -> firstBase + tau (firstTargetSample - firstBase)
  };
  tangent = firstTargetSample - firstBase;
  (* algebraic records: keep the default rank/residue samples only where
     every letter and root square is a nonzero rational; otherwise draw
     admissible ones from the fraction grid (observableTransportAdmissibleSamples).
     Round 4 (Codex review): when the grid cannot supply the full count,
     the run stops with a typed exhaustion status -- the former code kept
     the original samples, some of them proved inadmissible. *)
  sampleExhaustion = None;
  If[coefficientField === "Multiquadratic" && OptionValue["RankSamples"] === Automatic,
    Module[{rootSquaresHere = Lookup[algebraicRootRecords, "RootSquare", {}],
        lettersHere = Replace[letters, Except[_List] -> {}],
        rankPoint, admissibleRank, residueAdmissible, candidatesRank,
        candidatesResidue},
      rankPoint = Function[sample, Join[{firstVariable -> (firstBase + tau tangent) /. sample},
        Select[sample, First[#] === secondVariable &]]];
      admissibleRank = Select[rankSamples,
        observableTransportPointAdmissibleQ[lettersHere, rootSquaresHere, rankPoint[#]] &];
      If[Length[admissibleRank] < Length[rankSamples],
        candidatesRank = Flatten[Table[{tau -> t, secondVariable -> c},
          {t, $observableTransportSampleFractions}, {c, $observableTransportSampleFractions}], 1];
        admissibleRank = observableTransportAdmissibleSamples[lettersHere, rootSquaresHere,
          rankPoint, candidatesRank, Length[rankSamples]];
        If[verbose, Print["Observable transport rank samples replaced for the algebraic record: ",
          Length[admissibleRank], " admissible of ", Length[candidatesRank], " candidates"]];
        If[Length[admissibleRank] < Length[rankSamples],
          sampleExhaustion = <|"Status" -> "AdmissibleSamplesExhausted",
            "SampleKind" -> "Rank", "Requested" -> Length[rankSamples],
            "Available" -> Length[admissibleRank],
            "Candidates" -> Length[candidatesRank]|>,
          rankSamples = admissibleRank]];
      If[sampleExhaustion === None,
        automatonRankSamples = {
          {firstVariable -> firstBase, secondVariable -> secondBase},
          Join[{firstVariable -> firstTargetSample}, First[rankSamples]],
          Join[{firstVariable -> (firstBase + firstTargetSample)/2}, Last[rankSamples]]};
        residueAdmissible = Select[residueSamples,
          observableTransportPointAdmissibleQ[lettersHere, rootSquaresHere, Thread[variables -> #]] &];
        If[Length[residueAdmissible] < Length[residueSamples],
          candidatesResidue = Flatten[Table[{a, b},
            {a, $observableTransportSampleFractions}, {b, $observableTransportSampleFractions}], 1];
          residueAdmissible = observableTransportAdmissibleSamples[lettersHere, rootSquaresHere,
            Thread[variables -> #] &, candidatesResidue, Length[residueSamples]];
          If[verbose, Print["Observable transport residue samples replaced for the algebraic record: ",
            Length[residueAdmissible]]];
          If[Length[residueAdmissible] < Length[residueSamples],
            sampleExhaustion = <|"Status" -> "AdmissibleSamplesExhausted",
              "SampleKind" -> "Residue", "Requested" -> Length[residueSamples],
              "Available" -> Length[residueAdmissible],
              "Candidates" -> Length[candidatesResidue]|>,
            residueSamples = residueAdmissible]]]]];
  If[sampleExhaustion =!= None,
    Return[Join[sampleExhaustion, <|
      "Family" -> Lookup[record, "Family", Missing[]],
      "CoefficientField" -> coefficientField,
      "LetterCount" -> Length[Replace[letters, Except[_List] -> {}]],
      "RootSquareCount" -> Length[Lookup[algebraicRootRecords, "RootSquare", {}]]|>],
      Module]
  ];
  firstSupport = If[recordTransportReadyQ,
    compactResidueSupport[firstVariable],
    firstConnection = If[coefficientField === "Multiquadratic",
    (* The certified epsilon form is already an exact dlog connection.
       Specializing eps -> 1 extracts its epsilon-independent coefficient
       without first creating syntactically uncancelled expr/eps entries.
       Later kernel extraction still canonicalizes each used scalar. *)
    Normal[ReplaceAll[
        ReplaceAll[epsConnections[[
          FirstPosition[variables, firstVariable][[1]]]], eps -> 1],
        pathRules] tangent],
    observableTransportCancelMatrix[
      (epsConnections[[
          FirstPosition[variables, firstVariable][[1]]]]/eps /.
        pathRules) tangent]
    ]
  ];
  If[! FreeQ[firstSupport, eps],
    Return[<|"Status" -> "ConnectionIsNotEpsilonForm"|>, Module]
  ];

  propagatedLower = blockLower;
  Do[
    stabilized = False;
    Do[
      If[source < target && ! observableTransportStructuralZeroMatrixQ[
          firstSupport[[ranges[[target]], ranges[[source]]]]],
        propagatedLower[[target]] = Min[propagatedLower[[target]],
          propagatedLower[[source]] + 1]
      ],
      {source, 1, target - 1}],
    {target, Length[ranges]}];
  stateRowLower = propagatedLower[[blockOfRow]];
  flow = Min[propagatedLower];
  forbiddenFHigh = valuation - 1 - tmin;
  forbiddenPhysicalOrders = Range[flow + tmin, valuation - 1];
  slots = Flatten[Table[
    If[order >= stateRowLower[[component]], {{order, component}}, {}],
    {order, flow, forbiddenFHigh}, {component, dimension}], 2];
  positions = AssociationThread[
    observableTransportSlotKey /@ slots, Range[Length[slots]]];
  boundarySlots = Select[slots, #[[1]] >= rowLower[[#[[2]]]] &];
  boundaryPositions = AssociationThread[
    observableTransportSlotKey /@ boundarySlots,
    Range[Length[boundarySlots]]];
  embedding = SparseArray[
    Table[
      {positions[observableTransportSlotKey[slot]],
         boundaryPositions[observableTransportSlotKey[slot]]} -> 1,
      {slot, boundarySlots}],
    {Length[slots], Length[boundarySlots]}];
  If[verbose, Print["Observable transport structural support: ",
    Round[AbsoluteTime[] - start, 0.1], " s cumulative"]];
  (* Both physical maps use the same Laurent expansion of TTotal.  Build
     the union of their order ranges once; the former two-pass route could
     repeat the dominant symbolic series work almost verbatim. *)
  tLaurentHigh = Max[Max[0, valuation - 1 - flow],
    Max[physicalOrders] - flow];
  (* Round 4 (2026-09-02): each component is expanded only to the order
     the two consumers below read it at (observableTransportLaurentRowHighs);
     the placeholders above a row's cap are never read, and both consumers
     assert that (laurentOverrun). *)
  rowHighs = observableTransportLaurentRowHighs[dimension, valuation, flow,
    physicalDemandPairs];
  tLaurent = observableTransportLaurentMatrices[tTotal, eps,
    {tmin, tLaurentHigh}, rowHighs];
  If[AssociationQ[tLaurent] && KeyExistsQ[tLaurent, "Status"],
    Return[tLaurent, Module]];
  If[! AssociationQ[tLaurent],
    Return[<|"Status" -> "LaurentExtractionFailed"|>, Module]];
  If[Lookup[$observableTransportLaurentDiagnostics,
      "ValuationBelowRange", 0] > 0,
    (* the record's TMin is not the minimum valuation of TTotal: the
       transport would silently lose orders, so it is refused *)
    Return[<|"Status" -> "LaurentValuationBelowRecord",
      "TMin" -> tmin, "ValuationSource" -> valuationSource,
      "EntryCount" -> $observableTransportLaurentDiagnostics[
        "ValuationBelowRange"]|>, Module]];
  If[verbose, Print["Observable transport Laurent extraction: ",
    Round[AbsoluteTime[] - start, 0.1], " s cumulative; method ",
    $observableTransportLaurentMethod, "; orders ", {tmin, tLaurentHigh},
    "; row caps ", Counts[Clip[rowHighs, {tmin - 1, tLaurentHigh}]],
    "; SeriesCoefficient fallbacks ",
    Lookup[$observableTransportLaurentDiagnostics, "SeriesFallbackCount", 0]]];
  laurentOverrun = Missing["None"];
  forbiddenRows = {};
  forbiddenLabels = {};
  Do[
    With[{row = Table[
        laurentOrder = physicalOrder - slot[[1]];
        If[laurentOrder > rowHighs[[component]] && MissingQ[laurentOverrun],
          laurentOverrun = {physicalOrder, component, slot}];
        Lookup[tLaurent, laurentOrder,
          ConstantArray[0, {dimension, dimension}]][[component, slot[[2]]]],
        {slot, slots}]},
      If[! AllTrue[row, observableTransportZeroQ],
        AppendTo[forbiddenRows, row];
        AppendTo[forbiddenLabels, {physicalOrder, component}]
      ]],
    {physicalOrder, forbiddenPhysicalOrders}, {component, dimension}];
  If[! MissingQ[laurentOverrun],
    Return[<|"Status" -> "LaurentOrderNotExtracted",
      "Consumer" -> "ForbiddenMap", "Detail" -> laurentOverrun|>, Module]];
  (* The forbidden observable is propagated along the first path.  Keeping
     the target first variable here would make D[frontier,tau] vanish and
     would leave a target-dependent object mislabeled as a base constraint. *)
  forbiddenMap = If[forbiddenRows === {},
    SparseArray[{}, {0, Length[slots]}],
    Normal[forbiddenRows] /. pathRules];
  If[verbose, Print["Observable transport forbidden map: ",
    Dimensions[forbiddenMap], "; slots ", Length[slots],
    "; boundary slots ", Length[boundarySlots], "; ",
    Round[AbsoluteTime[] - start, 0.1], " s cumulative"]];
  If[forbiddenRows =!= {} &&
      (! MatrixQ[forbiddenMap] ||
       Dimensions[forbiddenMap][[2]] =!= Length[slots]),
    Return[<|"Status" -> "ForbiddenMapNotRectangular",
      "Dimensions" -> Dimensions[forbiddenMap],
      "SlotCount" -> Length[slots]|>, Module]
  ];

  If[forbiddenRows === {},
    constraintMatrix = SparseArray[{}, {0, Length[boundarySlots]}];
    constraintRank = 0;
    closureHistory = {0};
    closureInitialSpanCertificate = Missing["NotRequired"];
    closureInitialSpanMethod = "NoConstraints";
    closureStabilizationCertificate = Missing["NotRequired"];
    closureStabilizationMethod = "NoConstraints",
    firstConnection = If[recordTransportReadyQ,
      compactDLogConnection[firstVariable, pathRules, tangent],
      firstSupport];
    lifted = First@observableTransportLiftResidues[{firstConnection}, slots];
    closureSteps = Replace[OptionValue["ClosureSteps"],
      Automatic -> Length[slots]];
    closureRecord = observableTransportCovariantRowClosure[
      forbiddenMap, lifted, tau, {tau, secondVariable}, rankSamples,
      closureSteps, OptionValue["ValidationPrimeCount"],
      OptionValue["ValidationPointsPerPrime"], verbose,
      (Lookup[algebraicRootRecords, "RootSquare", {}] /. pathRules)];
    If[! AssociationQ[closureRecord] ||
        Lookup[closureRecord, "Status", None] =!=
          "CovariantRowClosureAccepted",
      Return[If[AssociationQ[closureRecord], closureRecord,
        <|"Status" -> "DualClosureFailed"|>], Module]
    ];
    basis = closureRecord["Basis"];
    closureHistory = closureRecord["RankHistory"];
    closureInitialSpanCertificate =
      closureRecord["InitialSpanCertificate"];
    closureInitialSpanMethod = closureRecord["InitialSpanMethod"];
    closureStabilizationCertificate =
      closureRecord["StabilizationCertificate"];
    closureStabilizationMethod =
      closureRecord["StabilizationMethod"];
    If[verbose, Print["Observable transport first covariant closure: ",
      closureHistory, "; ", Round[AbsoluteTime[] - start, 0.1],
      " s cumulative"]];
    constraintMatrix = observableTransportCancelMatrix[
      (basis /. tau -> 0) . embedding];
    constraintRank = Length[basis]
  ];
  If[! FreeQ[constraintMatrix, tau | firstVariable],
    Return[<|"Status" -> "BoundaryConstraintNotAtFirstBase"|>, Module]
  ];
  If[Length[constraintMatrix] > 0,
    constraintPivots = observableTransportMaximalIndependentRows[
      constraintMatrix,
      ({secondVariable -> (secondVariable /. #)} &) /@ rankSamples,
      (Lookup[algebraicRootRecords, "RootSquare", {}] /.
        firstVariable -> firstBase)];
    (* Overhaul 2026-09-02: a failed rank sampling reports WHY (per-sample
       rejection counts from the finite-field sampler) and, when
       "DiagnosticDirectory" names a directory, dumps the failing state so
       the step can be reproduced offline instead of by rerunning the
       whole transport (CF259 probe 1 spent 25 minutes reaching it). *)
    rankFailure[reason_] := Module[{directory = OptionValue["DiagnosticDirectory"], dump},
      dump = <|"Status" -> "ConstraintRankFailureDump",
        "Reason" -> reason, "Family" -> Lookup[record, "Family", None],
        "ConstraintMatrix" -> constraintMatrix, "Embedding" -> embedding,
        "RankSamples" -> rankSamples, "SecondVariable" -> secondVariable,
        "FirstVariable" -> firstVariable, "FirstBase" -> firstBase,
        "RootSquares" -> (Lookup[algebraicRootRecords, "RootSquare", {}] /.
          firstVariable -> firstBase),
        "Diagnostics" -> $observableTransportFFRankDiagnostics|>;
      If[StringQ[directory],
        Quiet[CreateDirectory[directory, CreateIntermediateDirectories -> True]];
        Put[dump, FileNameJoin[{directory, "constraint_rank_failure.wl"}]]];
      <|"Status" -> "SingularConstraintRankSample", "Reason" -> reason,
        "Diagnostics" -> $observableTransportFFRankDiagnostics,
        "RankSampleCount" -> Length[rankSamples],
        "DiagnosticDirectory" -> directory|>];
    If[constraintPivots === $Failed,
      Return[rankFailure["NoRankSampleAdmissible"], Module]
    ];
    constraintRank = Length[constraintPivots];
    If[constraintRank === 0 &&
        ! observableTransportZeroMatrixQ[constraintMatrix],
      Return[rankFailure["NonzeroConstraintVanishedAtAllRankSamples"],
        Module]]
  ];

  (* Small symbolic kernels are an efficient moving coordinate system.  For
     complicated constraints they can explode (CF230: a 25 KB constraint
     serialized as a 498 MB kernel).  Above a structural leaf threshold,
     evolve the sparse Laurent state itself and impose the kernel only at the
     constant base point. *)
  constraintLeafCount = Total[
    LeafCount /@ Flatten[Normal[constraintMatrix]]];
  movingKernelLeafLimit = OptionValue["MovingKernelLeafLimit"];
  If[! IntegerQ[movingKernelLeafLimit] || movingKernelLeafLimit < 0,
    Return[<|"Status" -> "InvalidMovingKernelLeafLimit"|>, Module]
  ];
  boundaryEvolution = Replace[OptionValue["BoundaryEvolution"],
    Automatic -> If[constraintRank === 0 ||
      constraintLeafCount <= movingKernelLeafLimit,
      "MovingKernel", "AmbientBasePoint"]];
  If[! MemberQ[{"MovingKernel", "AmbientBasePoint"}, boundaryEvolution],
    Return[<|"Status" -> "InvalidBoundaryEvolution"|>, Module]
  ];
  If[verbose, Print["Observable transport boundary evolution: ",
    boundaryEvolution, "; constraint leaves ", constraintLeafCount,
    "; moving-kernel limit ", movingKernelLeafLimit, "; constraint rank ",
    constraintRank, "; ", Round[AbsoluteTime[] - start, 0.1],
    " s cumulative"]];

  extendedFHigh = Max[physicalOrders] - tmin;
  extendedSlots = Flatten[Table[
    If[order >= stateRowLower[[component]], {{order, component}}, {}],
    {order, flow, extendedFHigh}, {component, dimension}], 2];
  extendedPositions = AssociationThread[
    observableTransportSlotKey /@ extendedSlots,
    Range[Length[extendedSlots]]];
  extendedBoundarySlots = Select[extendedSlots,
    #[[1]] >= rowLower[[#[[2]]]] &];
  newBoundarySlots = Complement[extendedBoundarySlots, boundarySlots];
  If[boundaryEvolution === "MovingKernel",
    secondClosureHistory = {};
    secondClosureInitialSpanCertificate = Missing["NotRequired"];
    secondClosureInitialSpanMethod = "NotRequired";
    secondClosureStabilizationCertificate = Missing["NotRequired"];
    secondClosureStabilizationMethod = "NotRequired";
    boundaryKernel = If[constraintRank === 0,
      IdentityMatrix[Length[boundarySlots]],
      observableTransportKernel[constraintMatrix]];
    If[Length[boundarySlots] > 0 &&
        (! MatrixQ[boundaryKernel] ||
         Dimensions[boundaryKernel][[1]] =!= Length[boundarySlots] ||
         (! observableTransportZeroMatrixQ[constraintMatrix] &&
           ! observableTransportZeroMatrixQ[
             constraintMatrix . boundaryKernel])),
      Return[<|"Status" -> "BoundaryKernelIdentityFailed"|>, Module]
    ];
    transportBoundary = observableTransportBoundaryEmbedding[
      boundaryKernel, boundarySlots, newBoundarySlots,
      extendedPositions, Length[extendedSlots]];
    baseBoundaryKernel = observableTransportCancelMatrix[
      boundaryKernel /. secondVariable -> secondBase];
    baseBoundaryEmbedding = observableTransportCancelMatrix[
      Normal[transportBoundary] /. secondVariable -> secondBase];
    terminalEmbedding = IdentityMatrix[
      Dimensions[transportBoundary][[2]]],

    transportBoundary = SparseArray[
      IdentityMatrix[Length[extendedSlots]]];
    boundarySelector = SparseArray[Table[
      {boundaryRow, extendedPositions[observableTransportSlotKey[
          boundarySlots[[boundaryRow]]]]} -> 1,
      {boundaryRow, Length[boundarySlots]}],
      {Length[boundarySlots], Length[extendedSlots]}];
    (* round 4 (2026-09-02): a record without forbidden constraints
       reaches this branch with an EMPTY constraint matrix ({}: a
       zero-row SparseArray is just {}), and Dot of {} with the selector
       fails (Dot::dotsh); the empty case is carried explicitly here,
       in the base constraint below and in the closure *)
    extendedConstraintMatrix = If[Length[constraintMatrix] === 0, {},
      constraintMatrix . boundarySelector];
    ambientSecondConnection = If[recordTransportReadyQ,
      compactDLogConnection[secondVariable,
        {firstVariable -> firstBase}, 1],
      epsConnections[[FirstPosition[
            variables, secondVariable][[1]]]] /.
        {eps -> 1, firstVariable -> firstBase}];
    ambientLiftedSecond = First@observableTransportLiftResidues[
      {ambientSecondConnection}, extendedSlots];
    secondRankSamples =
      ({secondVariable -> (secondVariable /. #)} &) /@ rankSamples;
    secondClosureRecord = observableTransportCovariantRowClosure[
      extendedConstraintMatrix, ambientLiftedSecond, secondVariable,
      {secondVariable}, secondRankSamples, Length[extendedSlots],
      OptionValue["ValidationPrimeCount"],
      OptionValue["ValidationPointsPerPrime"], verbose,
      (Lookup[algebraicRootRecords, "RootSquare", {}] /.
        firstVariable -> firstBase)];
    If[! AssociationQ[secondClosureRecord] ||
        Lookup[secondClosureRecord, "Status", None] =!=
          "CovariantRowClosureAccepted",
      Return[If[AssociationQ[secondClosureRecord], secondClosureRecord,
        <|"Status" -> "SecondBoundaryClosureFailed"|>], Module]
    ];
    extendedConstraintMatrix = secondClosureRecord["Basis"];
    secondClosureHistory = secondClosureRecord["RankHistory"];
    secondClosureInitialSpanCertificate =
      secondClosureRecord["InitialSpanCertificate"];
    secondClosureInitialSpanMethod =
      secondClosureRecord["InitialSpanMethod"];
    secondClosureStabilizationCertificate =
      secondClosureRecord["StabilizationCertificate"];
    secondClosureStabilizationMethod =
      secondClosureRecord["StabilizationMethod"];
    If[verbose, Print[
      "Observable transport base constraint cancellation start: ",
      Dimensions[extendedConstraintMatrix]]];
    baseStageStart = AbsoluteTime[];
    baseConstraintMatrix = If[Length[extendedConstraintMatrix] === 0, {},
      observableTransportCancelMatrix[
        Normal[extendedConstraintMatrix] /. secondVariable -> secondBase]];
    If[verbose, Print[
      "Observable transport base constraint cancellation: ",
      Round[AbsoluteTime[] - baseStageStart, 0.1], " s"]];
    baseStageStart = AbsoluteTime[];
    baseBoundaryKernel = If[Length[extendedConstraintMatrix] === 0,
      IdentityMatrix[Length[extendedSlots]],
      observableTransportKernel[baseConstraintMatrix]];
    If[verbose, Print["Observable transport base kernel: ",
      Round[AbsoluteTime[] - baseStageStart, 0.1], " s; dimensions ",
      Dimensions[baseBoundaryKernel]]];
    baseStageStart = AbsoluteTime[];
    If[! MatrixQ[baseBoundaryKernel] ||
        Dimensions[baseBoundaryKernel][[1]] =!= Length[extendedSlots] ||
        (Length[baseConstraintMatrix] > 0 &&
          ! observableTransportZeroMatrixQ[
            baseConstraintMatrix . baseBoundaryKernel]),
      Return[<|"Status" -> "BoundaryBaseKernelIdentityFailed"|>, Module]
    ];
    If[verbose, Print["Observable transport base kernel replay: ",
      Round[AbsoluteTime[] - baseStageStart, 0.1], " s"]];
    baseBoundaryEmbedding = baseBoundaryKernel;
    terminalEmbedding = baseBoundaryEmbedding
  ];
  If[! FreeQ[baseBoundaryKernel, variables] ||
      ! FreeQ[baseBoundaryEmbedding, variables],
    Return[<|"Status" -> "BoundaryBaseEmbeddingNotConstant"|>, Module]
  ];

  tDemandLaurent = tLaurent;
  demandedRows = {};
  physicalLabels = {};
  Do[
    {physicalOrder, component} = physicalDemand;
    With[{row = Table[
        laurentOrder = physicalOrder - slot[[1]];
        If[laurentOrder > rowHighs[[component]] && MissingQ[laurentOverrun],
          laurentOverrun = {physicalOrder, component, slot}];
        Lookup[tDemandLaurent, laurentOrder,
          ConstantArray[0, {dimension, dimension}]][[component, slot[[2]]]],
        {slot, extendedSlots}]},
      If[! AllTrue[row, observableTransportZeroQ],
        AppendTo[demandedRows, row];
        AppendTo[physicalLabels, {physicalOrder, component}]
      ]],
    {physicalDemand, physicalDemandPairs}];
  If[! MissingQ[laurentOverrun],
    Return[<|"Status" -> "LaurentOrderNotExtracted",
      "Consumer" -> "DemandedMap", "Detail" -> laurentOverrun|>, Module]];
  demandedMap = If[demandedRows === {},
    SparseArray[{}, {0, Length[extendedSlots]}], demandedRows];
  If[verbose, Print["Observable transport demanded map: ",
    Dimensions[demandedMap], "; extended slots ", Length[extendedSlots],
    "; transport boundary ", Dimensions[transportBoundary],
    "; base coordinates ", Dimensions[baseBoundaryEmbedding][[2]], "; ",
    Round[AbsoluteTime[] - start, 0.1], " s cumulative"]];
  If[! MatrixQ[demandedMap] ||
      Dimensions[demandedMap][[2]] =!= Length[extendedSlots],
    Return[<|"Status" -> "DemandedMapNotRectangular",
      "Dimensions" -> Dimensions[demandedMap],
      "SlotCount" -> Length[extendedSlots]|>, Module]
  ];

  familyCertificate = Lookup[record, "EpsilonFormCertificate", <||>];
  recordDLog = Lookup[record, "DLog", <||>];
  certificateDLog = Lookup[familyCertificate, "DLog", <||>];
  usableDLogQ[value_] := AssociationQ[value] &&
    TrueQ[Lookup[value, "Valid", False]] &&
    Lookup[value, "Variables", Missing[]] === variables &&
    Lookup[value, "Regulator", Missing[]] === eps &&
    Lookup[value, "Dimension", Missing[]] === dimension &&
    ListQ[Lookup[value, "Letters", None]] &&
    ListQ[Lookup[value, "Residues", None]] &&
    Length[value["Letters"]] === Length[value["Residues"]] &&
    AllTrue[value["Residues"],
      MatrixQ[#] && Dimensions[#] === {dimension, dimension} &] &&
    TrueQ[Lookup[value, "ConstantResidues", False]];
  residueDLogSource = None;
  residueProbabilistic = False;
  certifiedDLog = Which[
    recordTransportReadyQ && computedDLogQ[recordDLog] &&
        usableDLogQ[recordDLog],
      residueDLogSource = "ComputedFiniteFieldDLog";
      residueProbabilistic = True;
      recordDLog,
    recordExactQ && usableDLogQ[recordDLog],
      residueDLogSource = "ExactRecord";
      recordDLog,
    recordExactQ && usableDLogQ[certificateDLog],
      residueDLogSource = "ExactCertificate";
      certificateDLog,
    coefficientField === "Multiquadratic" && recordCertifiedQ &&
        ! recordExactQ && AssociationQ[familyCertificate] &&
        TrueQ[Lookup[familyCertificate, "Certified", False]] &&
        TrueQ[Lookup[familyCertificate, "Exact", True] === False] &&
        TrueQ[Lookup[familyCertificate, "Probabilistic", False]] &&
        Lookup[familyCertificate, "CertificationLevel", None] ===
          "HighConfidenceFiniteField" &&
        Lookup[familyCertificate, "CoefficientField", None] ===
          "Multiquadratic" &&
        Lookup[familyCertificate, "IdentityMethod", None] === "Modular" &&
        AssociationQ[Lookup[familyCertificate, "Modular", <||>]] &&
        Lookup[familyCertificate["Modular"], "Status", None] ===
          "CertifiedMultiquadraticFamily" &&
        Lookup[familyCertificate["Modular"], "Method", None] ===
          "AllSignSheetsAtFreshSplitPoints" &&
        TrueQ[Lookup[familyCertificate["Modular"],
          "AllRootSheetsChecked", False]] &&
        TrueQ[Lookup[familyCertificate["Modular"],
          "FreshLiftValidation", False]] &&
        TrueQ[Lookup[familyCertificate["Modular"],
          "ConstantResidues", False]] &&
        TrueQ[Lookup[familyCertificate["Modular"],
          "ResiduesVerifiedAtAllPrimes", False]] &&
        usableDLogQ[certificateDLog] &&
        TrueQ[Lookup[certificateDLog,
          "ResiduesVerifiedAtAllPrimes", False]],
      residueDLogSource = "HighConfidenceFiniteField";
      residueProbabilistic = True;
      certificateDLog,
    True,
      <||>
  ];
  residueRecordUsableQ[value_] := AssociationQ[value] &&
    MemberQ[{"Exact", "CertifiedFiniteField"},
      Lookup[value, "Status", None]];
  residueRecord = If[usableDLogQ[certifiedDLog],
      <|"Status" -> If[residueProbabilistic,
          "CertifiedFiniteField", "Exact"],
        "Letters" -> certifiedDLog["Letters"],
        "Residues" -> certifiedDLog["Residues"],
        "Identity" -> True,
        "IdentityExact" -> ! residueProbabilistic,
        "IdentityCertified" -> True,
        "Probabilistic" -> residueProbabilistic,
        "Method" -> residueDLogSource|>,
      $Failed
  ];
  (* Production transport has no symbolic residue or entry-kernel fallback.
     A missing dlog decomposition is an input/computation failure. *)
  If[! residueRecordUsableQ[residueRecord],
    Return[<|
      "Status" -> If[coefficientField === "Multiquadratic",
        "MultiquadraticDLogResiduesRequired", "DLogResiduesRequired"],
      "Reason" -> "NoProductionSymbolicFallback",
      "FamilyEpsilonFormCertified" -> recordCertifiedQ,
      "FamilyEpsilonFormExact" -> recordExactQ,
      "RecordDLogUsable" -> usableDLogQ[recordDLog],
      "CertificateDLogUsable" -> usableDLogQ[certificateDLog]|>, Module]
  ];
  pathActiveLetters = Select[Range[Length[residueRecord["Letters"]]],
    ! observableTransportZeroQ[
      D[residueRecord["Letters"][[#]], firstVariable]] &];
  firstKernelRecord = <|
    "Status" -> residueRecord["Status"],
    "Method" -> If[residueProbabilistic,
      "CertifiedDLogResidues", "DLogResidues"],
    "Kernels" -> (observableTransportCancel[
        (D[#, firstVariable]/# /. pathRules) tangent] & /@
      residueRecord["Letters"][[pathActiveLetters]]),
    "Matrices" -> residueRecord["Residues"][[pathActiveLetters]],
    "Identity" -> True,
    "IdentityExact" -> ! residueProbabilistic,
    "IdentityCertified" -> True,
    "Probabilistic" -> residueProbabilistic|>;
  firstKernelIndices = pathActiveLetters;
  firstKernelMethod = firstKernelRecord["Method"];
  liftedResidues = observableTransportLiftResidues[
    firstKernelRecord["Matrices"], extendedSlots];
  maximumWeight = Replace[OptionValue["MaximumWeight"],
    Automatic -> extendedFHigh - flow];
  If[! IntegerQ[maximumWeight] || maximumWeight < 0,
    Return[<|"Status" -> "InvalidMaximumWeight"|>, Module]
  ];

  If[boundaryEvolution === "AmbientBasePoint" &&
      residueRecordUsableQ[residueRecord],
    (* The certified residues supply the transport kernels below.  Retain the
       unsplit connection only for the finite-field invariance test; no
       entrywise Apart/Together decomposition is performed. *)
    secondConnection = ambientSecondConnection;
    liftedSecond = ambientLiftedSecond;
    secondEvolutionConnection = Missing["CertifiedDLogResiduesUsed"],

    secondConnection = If[boundaryEvolution === "AmbientBasePoint",
      ambientSecondConnection,
      observableTransportCancelMatrix[
        (epsConnections[[FirstPosition[
            variables, secondVariable][[1]]]]/eps) /.
          firstVariable -> firstBase]];
    liftedSecond = If[boundaryEvolution === "AmbientBasePoint",
      ambientLiftedSecond,
      First@observableTransportLiftResidues[
        {secondConnection}, extendedSlots]];
    If[boundaryEvolution === "MovingKernel",
    boundaryDerivative = D[Normal[transportBoundary], secondVariable];
    inducedRhs = observableTransportCancelMatrix[
      liftedSecond . transportBoundary - boundaryDerivative];
    pivotRows = observableTransportIndependentRows[
      Normal[transportBoundary], {secondVariable -> secondBase}];
    If[pivotRows === $Failed ||
        Length[pivotRows] =!= Dimensions[transportBoundary][[2]],
      Return[<|"Status" -> "BoundaryEmbeddingRankFailed"|>, Module]
    ];
    pivotSquare = Normal[transportBoundary][[pivotRows]];
    secondEvolutionConnection = observableTransportCancelMatrix[
      LinearSolve[pivotSquare, inducedRhs[[pivotRows]]]];
    inducedResidual = observableTransportCancelMatrix[
      transportBoundary . secondEvolutionConnection - inducedRhs];
    If[! observableTransportZeroMatrixQ[inducedResidual],
      Return[<|"Status" -> "BoundarySubspaceNotInvariant"|>, Module]
      ],
      secondEvolutionConnection = Normal[liftedSecond]
    ]
  ];
  secondActiveLetters = {};
  kernelRecord = Which[
    boundaryEvolution === "AmbientBasePoint" &&
        residueRecordUsableQ[residueRecord],
      secondActiveLetters = Select[
        Range[Length[residueRecord["Letters"]]],
        ! observableTransportZeroQ[
          D[residueRecord["Letters"][[#]], secondVariable]] &];
      <|"Status" -> residueRecord["Status"],
        "Method" -> If[residueProbabilistic,
          "CertifiedDLogResidues", "DLogResidues"],
        "Kernels" -> (observableTransportCancel[
            D[#, secondVariable]/# /.
              firstVariable -> firstBase] & /@
          residueRecord["Letters"][[secondActiveLetters]]),
        "Matrices" -> observableTransportLiftResidues[
          residueRecord["Residues"][[secondActiveLetters]],
          extendedSlots],
        "Identity" -> True,
        "IdentityExact" -> ! residueProbabilistic,
        "IdentityCertified" -> True,
        "Probabilistic" -> residueProbabilistic|>,
    coefficientField === "Multiquadratic",
      <|"Status" -> "MultiquadraticDLogResiduesRequired",
        "Reason" -> "NoProductionSymbolicFallback"|>,
    True,
      observableTransportKernelDecomposition[
        secondEvolutionConnection, secondVariable]
  ];
  If[! residueRecordUsableQ[kernelRecord],
    Return[kernelRecord, Module]
  ];
  ambientInvarianceCertificate = Missing["NotRequired"];
  If[boundaryEvolution === "AmbientBasePoint" && constraintRank > 0,
    ambientInvarianceCertificate = If[
      coefficientField === "Multiquadratic",
      observableTransportModularAlgebraicCovariantSubspaceInclusion[
        extendedConstraintMatrix, liftedSecond, secondVariable,
        {secondVariable},
        (Lookup[algebraicRootRecords, "RootSquare", {}] /.
          firstVariable -> firstBase),
        "ValidationPrimeCount" -> OptionValue["ValidationPrimeCount"],
        "ValidationPointsPerPrime" ->
          OptionValue["ValidationPointsPerPrime"]],
      ambientCovariant = D[Normal[extendedConstraintMatrix],
          secondVariable] +
        Normal[extendedConstraintMatrix] . Normal[liftedSecond];
      observableTransportModularSubspaceInclusion[
        extendedConstraintMatrix, ambientCovariant, {secondVariable},
        "ValidationPrimeCount" -> OptionValue["ValidationPrimeCount"],
        "ValidationPointsPerPrime" ->
          OptionValue["ValidationPointsPerPrime"]]];
    If[! AssociationQ[ambientInvarianceCertificate] ||
        Lookup[ambientInvarianceCertificate, "Status", None] =!=
          "FreshModularSubspaceInclusionAccepted",
      Return[If[AssociationQ[ambientInvarianceCertificate] &&
          Lookup[ambientInvarianceCertificate, "Status", None] ===
            "FreshModularSubspaceInclusionRejected",
        <|"Status" -> "BoundarySubspaceNotInvariant",
          "AmbientInvarianceFailure" ->
            ambientInvarianceCertificate|>,
        If[AssociationQ[ambientInvarianceCertificate],
          ambientInvarianceCertificate,
          <|"Status" -> "AmbientBoundaryInvarianceFailed"|>]], Module]
    ]
  ];
  structuralProbabilisticCertificates = <||>;
  If[AssociationQ[closureInitialSpanCertificate],
    AssociateTo[structuralProbabilisticCertificates,
      "DualClosureInitialSpan" ->
        closureInitialSpanCertificate]];
  If[AssociationQ[closureStabilizationCertificate],
    AssociateTo[structuralProbabilisticCertificates,
      "DualClosureStabilization" ->
        closureStabilizationCertificate]];
  If[AssociationQ[secondClosureInitialSpanCertificate],
    AssociateTo[structuralProbabilisticCertificates,
      "SecondBoundaryClosureInitialSpan" ->
        secondClosureInitialSpanCertificate]];
  If[AssociationQ[secondClosureStabilizationCertificate],
    AssociateTo[structuralProbabilisticCertificates,
      "SecondBoundaryClosureStabilization" ->
        secondClosureStabilizationCertificate]];
  If[AssociationQ[ambientInvarianceCertificate],
    AssociateTo[structuralProbabilisticCertificates,
      "AmbientBoundaryInvariance" ->
        ambientInvarianceCertificate]];
  If[residueProbabilistic,
    AssociateTo[structuralProbabilisticCertificates,
      "FamilyDLogResidues" -> If[
        residueDLogSource === "ComputedFiniteFieldDLog",
        <|"Status" -> "ComputedDLogResidues", "Accepted" -> True,
          "Exact" -> False, "Probabilistic" -> True,
          "Source" -> "DLogComputation",
          "CoefficientField" -> Lookup[certifiedDLog,
            "CoefficientField", Missing[]],
          "IdentityMethod" -> Lookup[certifiedDLog,
            "IdentityMethod", Missing[]],
          "Backend" -> Lookup[certifiedDLog, "Backend", Missing[]],
          "FreshPrimeValidation" -> TrueQ[Lookup[certifiedDLog,
            "FreshPrimeValidation", False]],
          "AllRootSheetsEvaluated" -> TrueQ[Lookup[certifiedDLog,
            "AllRootSheetsEvaluated", False]],
          "ConstantResidues" -> TrueQ[Lookup[certifiedDLog,
            "ConstantResidues", False]],
          "ResiduesVerifiedAtAllPrimes" -> TrueQ[Lookup[certifiedDLog,
            "ResiduesVerifiedAtAllPrimes", False]],
          "CRTPrimes" -> Lookup[certifiedDLog, "CRTPrimes", {}],
          "FreshValidationPrime" -> Lookup[certifiedDLog,
            "FreshValidationPrime", Missing[]],
          "LetterCount" -> Length[certifiedDLog["Letters"]],
          "ResidueCount" -> Length[certifiedDLog["Residues"]]|>,
        <|"Status" -> "CertifiedDLogResidues", "Accepted" -> True,
          "Exact" -> False, "Probabilistic" -> True,
          "Source" -> "EpsilonFormCertificate",
          "CertificationLevel" -> Lookup[familyCertificate,
            "CertificationLevel", Missing[]],
          "CoefficientField" -> Lookup[familyCertificate,
            "CoefficientField", Missing[]],
          "IdentityMethod" -> Lookup[familyCertificate,
            "IdentityMethod", Missing[]],
          "Method" -> Lookup[familyCertificate["Modular"],
            "Method", Missing[]],
          "FreshLiftValidation" -> TrueQ[Lookup[
            familyCertificate["Modular"], "FreshLiftValidation", False]],
          "AllRootSheetsChecked" -> TrueQ[Lookup[
            familyCertificate["Modular"], "AllRootSheetsChecked", False]],
          "ConstantResidues" -> TrueQ[Lookup[certifiedDLog,
            "ConstantResidues", False]],
          "ResiduesVerifiedAtAllPrimes" -> TrueQ[Lookup[
            certifiedDLog, "ResiduesVerifiedAtAllPrimes", False]],
          "LetterCount" -> Length[certifiedDLog["Letters"]],
          "ResidueCount" -> Length[certifiedDLog["Residues"]],
          "IdentityPoints" -> (KeyTake[#,
              {"Prime", "TrainingPoints", "ValidationPoints", "DLogRank",
               "AllSheetsPerPoint"}] & /@
            Lookup[familyCertificate, "IdentityPoints", {}])|>]]];
  materializedWordLimit = OptionValue["MaterializedWordLimit"];
  If[! IntegerQ[materializedWordLimit] || materializedWordLimit < 1,
    Return[<|"Status" -> "InvalidMaterializedWordLimit"|>, Module]
  ];
  wordCountBound = observableTransportWordCountBound[
    Length[liftedResidues], Length[kernelRecord["Matrices"]],
    maximumWeight, materializedWordLimit];
  wordRepresentation = Replace[OptionValue["WordRepresentation"],
    Automatic -> If[wordCountBound > materializedWordLimit,
      "OperatorAutomaton", "MaterializedWords"]];
  If[! MemberQ[{"MaterializedWords", "OperatorAutomaton",
      "CompactAutomaton"},
      wordRepresentation],
    Return[<|"Status" -> "InvalidWordRepresentation"|>, Module]
  ];
  If[wordRepresentation === "CompactAutomaton" &&
      coefficientField =!= "Rational",
    Return[<|"Status" -> "CompactAutomatonRequiresRationalField",
      "CoefficientField" -> coefficientField|>, Module]
  ];
  If[verbose, Print["Observable transport word representation: ",
    wordRepresentation, "; materialized upper bound ", wordCountBound,
    "; limit ", materializedWordLimit]];

  Which[
   wordRepresentation === "OperatorAutomaton",
    operatorAutomaton = <|
      "Status" -> "ExactOperatorAutomaton",
      "Orientation" -> "DemandedRowsActFromLeft",
      "RequestedMaximumWeight" -> maximumWeight,
      "InitialDemandMap" -> demandedMap,
      "FirstAlphabetIndices" -> firstKernelIndices,
      "FirstOperatorMatrices" -> liftedResidues,
      "FirstBoundaryOperator" -> transportBoundary,
      "SecondAlphabetIndices" ->
        Range[Length[kernelRecord["Matrices"]]],
      "SecondOperatorMatrices" -> kernelRecord["Matrices"],
      "FinalBoundaryEmbedding" -> terminalEmbedding|>;
    compactAutomaton = Missing["OperatorAutomatonRepresentation"];
    wordRecord = <|
      "Maps" -> Missing["OperatorAutomatonNotMaterialized"],
      "StateCountsByWeight" -> Missing["OperatorAutomatonNotEnumerated"],
      "MapCountsByWeight" -> Missing["OperatorAutomatonNotEnumerated"]|>;
    secondRecord = <|
      "Maps" -> Missing["OperatorAutomatonNotMaterialized"],
      "MapCountsByWeight" -> Missing["OperatorAutomatonNotEnumerated"]|>;
    resultStatus = If[structuralProbabilisticCertificates =!= <||>,
      "ModularlyVerifiedObservableTransport",
      "ExactObservableTransport"];
    probabilisticCertificates = structuralProbabilisticCertificates,

   wordRepresentation === "CompactAutomaton",
    operatorAutomaton = Missing["CompactAutomatonRepresentation"];
    coordinateOptions = <|
      "CoordinateBackend" -> OptionValue["CoordinateBackend"],
      "CoordinateCacheDirectory" ->
        OptionValue["CoordinateCacheDirectory"],
      "ReconstructionThreads" -> OptionValue["ReconstructionThreads"],
      "ValidationPrimeCount" -> OptionValue["ValidationPrimeCount"],
      "ValidationPointsPerPrime" ->
        OptionValue["ValidationPointsPerPrime"]|>;
    compactAutomaton = observableTransportCompactDualAutomaton[
      liftedResidues, demandedMap, transportBoundary, terminalEmbedding,
      maximumWeight, variables, automatonRankSamples, coordinateOptions,
      verbose];
    If[! AssociationQ[compactAutomaton] ||
        Lookup[compactAutomaton, "Status", None] =!=
          "ModularCompactAutomatonAccepted",
      Return[If[AssociationQ[compactAutomaton], compactAutomaton,
        <|"Status" -> "CompactAutomatonConstructionFailed"|>], Module]
    ];
    compactAutomaton = Join[compactAutomaton, <|
      "FirstAlphabetIndices" -> firstKernelIndices,
      "SecondAlphabetIndices" ->
        Range[Length[kernelRecord["Matrices"]]],
      "SecondKernelMatrices" -> kernelRecord["Matrices"]|>];
    wordRecord = <|
      "Maps" -> Missing["CompactAutomatonNotMaterialized"],
      "StateCountsByWeight" ->
        compactAutomaton["ObservableRankByExactWeight"],
      "MapCountsByWeight" -> Missing["CompactAutomatonNotEnumerated"]|>;
    secondRecord = <|
      "Maps" -> Missing["CompactAutomatonNotMaterialized"],
      "MapCountsByWeight" -> Missing["CompactAutomatonNotEnumerated"]|>;
    resultStatus = "ModularlyVerifiedObservableTransport";
    probabilisticCertificates = Join[
      structuralProbabilisticCertificates, <|
      "CoordinateReconstructionFreshModular" -> True,
      "CoordinateSystems" ->
        compactAutomaton["CoordinateCertificates"],
      "AmbientBoundaryInvariance" ->
        ambientInvarianceCertificate|>],

   True,
    operatorAutomaton = Missing["MaterializedWordRepresentation"];
    wordRecord = observableTransportWordMaps[
      liftedResidues, transportBoundary, demandedMap, maximumWeight];
    wordRecord["Maps"] = ({firstKernelIndices[[#[[1]]]], #[[2]]} &) /@
      wordRecord["Maps"];
    secondRecord = observableTransportSecondSegmentMaps[
      wordRecord["Maps"], kernelRecord["Matrices"], terminalEmbedding,
      maximumWeight];
    compactAutomaton = Missing["MaterializedWordRepresentation"];
    resultStatus = If[structuralProbabilisticCertificates =!= <||>,
      "ModularlyVerifiedObservableTransport",
      "ExactObservableTransport"];
    probabilisticCertificates = structuralProbabilisticCertificates
  ];

  <|
    "Status" -> resultStatus,
    "Family" -> Lookup[record, "Family", Missing[]],
    "Variables" -> variables,
    "Regulator" -> eps,
    "CoefficientField" -> coefficientField,
    "PhysicalRows" -> physicalLabels,
    "PhysicalDemandPairs" -> physicalDemandPairs,
    "PhysicalValuation" -> valuation,
    "Path" -> <|
      "FirstVariable" -> firstVariable,
      "SecondVariable" -> secondVariable,
      "FirstBase" -> firstBase,
      "SecondBase" -> secondBase,
      "FirstTargetSample" -> firstTargetSample|>,
    "BoundarySlots" -> boundarySlots,
    "BoundaryConstraintMatrix" -> constraintMatrix,
    "BoundaryAmbientSlots" -> extendedSlots,
    "BoundaryBasePoint" -> {firstVariable -> firstBase,
      secondVariable -> secondBase},
    "BoundaryKernelAtBase" -> baseBoundaryKernel,
    "BoundaryBaseEmbedding" -> baseBoundaryEmbedding,
    "BoundaryEvolutionMethod" -> boundaryEvolution,
    "BoundaryConstraintLeafCount" -> constraintLeafCount,
    "GaugeConstantRules" -> gaugeConstantRules,
    "TransportEpsilonValuationSource" -> valuationSource,
    "TransportEpsilonValuations" -> <|
      "TMin" -> tmin, "BlockLower" -> blockLower|>,
    "TransportEpsilonValuationCertificate" -> valuationCertificate,
    "BoundaryCoordinates" -> Dimensions[baseBoundaryEmbedding][[2]],
    "ConstraintRank" -> constraintRank,
    "DualClosureRankHistory" -> closureHistory,
    "DualClosureInitialSpanMethod" -> closureInitialSpanMethod,
    "DualClosureStabilizationMethod" -> closureStabilizationMethod,
    "SecondBoundaryClosureRankHistory" -> secondClosureHistory,
    "SecondBoundaryClosureInitialSpanMethod" ->
      secondClosureInitialSpanMethod,
    "SecondBoundaryClosureStabilizationMethod" ->
      secondClosureStabilizationMethod,
    "FirstSegmentKernelMethod" -> firstKernelMethod,
    "FirstSegmentKernels" -> firstKernelRecord["Kernels"],
    "FirstSegmentKernelMatrices" -> firstKernelRecord["Matrices"],
    "DLogLetters" -> If[AssociationQ[residueRecord],
      residueRecord["Letters"], {}],
    "DLogResidues" -> If[AssociationQ[residueRecord],
      residueRecord["Residues"], {}],
    "FirstSegmentActiveLetters" -> pathActiveLetters,
    "FirstSegmentStateSpace" -> If[
      boundaryEvolution === "MovingKernel",
      "MovingBoundaryCoordinates", "ExtendedLaurentSlots"],
    "WordRepresentation" -> wordRepresentation,
    "MaterializedWordCountUpperBound" -> wordCountBound,
    "ExactOperatorAutomaton" -> operatorAutomaton,
    "CompactTransportAutomaton" -> compactAutomaton,
    "FirstSegmentWordMaps" -> wordRecord["Maps"],
    "FirstSegmentStateCountsByWeight" -> wordRecord["StateCountsByWeight"],
    "FirstSegmentMapCountsByWeight" -> wordRecord["MapCountsByWeight"],
    "SecondSegmentKernels" -> kernelRecord["Kernels"],
    "SecondSegmentKernelMatrices" -> kernelRecord["Matrices"],
    "SecondSegmentActiveLetters" -> secondActiveLetters,
    "SecondSegmentKernelMethod" -> Lookup[kernelRecord, "Method",
      "RationalKernelDecomposition"],
    "SecondSegmentStateSpace" -> If[
      boundaryEvolution === "MovingKernel",
      "MovingBoundaryCoordinates", "ExtendedLaurentSlots"],
    "TwoSegmentWordMaps" -> secondRecord["Maps"],
    "TwoSegmentMapCountsByWeight" -> secondRecord["MapCountsByWeight"],
    "FamilyInputRoute" -> Which[
      recordExactQ, "Exact",
      recordCertifiedQ, "Certified",
      recordTransportReadyQ, "ComputedDLog",
      True, "Invalid"],
    "Certificates" -> <|
      "FamilyEpsilonFormCertified" -> recordCertifiedQ,
      "FamilyEpsilonFormExact" -> recordExactQ,
      "FamilyInputAccepted" ->
        (recordCertifiedQ || recordExactQ || recordTransportReadyQ),
      "TransportEpsilonValuationsBound" ->
        observableTransportEpsilonValuationCertificateBoundQ[
          valuationSource, valuationCertificate,
          <|"TMin" -> tmin, "BlockLower" -> blockLower|>],
      "BoundaryBaseKernel" -> True,
      "FirstKernelIdentity" ->
        TrueQ[Lookup[firstKernelRecord, "Identity", False]],
      "FirstKernelIdentityExact" -> TrueQ[Lookup[firstKernelRecord,
        "IdentityExact",
        Lookup[firstKernelRecord, "Status", None] === "Exact"]],
      "FirstKernelIdentityCertified" -> TrueQ[Lookup[firstKernelRecord,
        "IdentityCertified", Lookup[firstKernelRecord, "Identity", False]]],
      "BoundaryEvolution" -> True,
      "SecondKernelIdentity" ->
        TrueQ[Lookup[kernelRecord, "Identity", False]],
      "SecondKernelIdentityExact" -> TrueQ[Lookup[kernelRecord,
        "IdentityExact", Lookup[kernelRecord, "Status", None] === "Exact"]],
      "SecondKernelIdentityCertified" -> TrueQ[Lookup[kernelRecord,
        "IdentityCertified", Lookup[kernelRecord, "Identity", False]]]|>,
    "ProbabilisticCertificates" -> probabilisticCertificates,
    "MaximumWeight" -> maximumWeight,
    "Seconds" -> AbsoluteTime[] - start
  |>
];

(* Keep the formal and production acceptance predicates distinct.  An exact
   materialized record retains the historical status; a compact record is
   accepted only when every quotient system has fresh modular evidence. *)
AcceptedObservableTransportQ[result_] := Module[
  {status, certificates, probabilistic, systems, requiredExact,
   representation, boundaryMethod, constraintRank, coordinateRequired,
   ambientRequired, structuralRequired, coordinateAccepted, ambientAccepted,
   structuralAccepted, structuralRequirements, dlogRequired, dlogAccepted,
   firstKernelIdentityExact, secondKernelIdentityExact, automaton,
   coordinateCertificateQ, ambientCertificateQ, operatorAutomatonQ,
   dlogCertificateQ, compactAutomatonQ, materializedWordsQ},
  If[! AssociationQ[result], Return[False]];
  status = Lookup[result, "Status", None];
  certificates = Lookup[result, "Certificates", <||>];
  requiredExact = {"BoundaryBaseKernel", "FirstKernelIdentity",
    "BoundaryEvolution", "SecondKernelIdentity",
    "TransportEpsilonValuationsBound"};
  If[! AssociationQ[certificates] ||
      ! TrueQ[Lookup[certificates, "FamilyInputAccepted", False]] ||
      ! AllTrue[requiredExact,
        KeyExistsQ[certificates, #] && TrueQ[certificates[#]] &],
    Return[False]];
  (* round 4: the epsilon valuations the transport used must be the ones
     its certificate names -- the record's modular certificate (fingerprint
     verified) or the exact gauge scan; a result without the certificate
     is refused *)
  If[! observableTransportEpsilonValuationCertificateBoundQ[
      Lookup[result, "TransportEpsilonValuationSource", None],
      Lookup[result, "TransportEpsilonValuationCertificate", Missing[]],
      Lookup[result, "TransportEpsilonValuations", Missing[]]],
    Return[False]];
  representation = Lookup[result, "WordRepresentation", None];
  boundaryMethod = Lookup[result, "BoundaryEvolutionMethod", None];
  constraintRank = Lookup[result, "ConstraintRank", Missing[]];
  If[! MemberQ[{"MaterializedWords", "OperatorAutomaton",
        "CompactAutomaton"}, representation] ||
      ! MemberQ[{"MovingKernel", "AmbientBasePoint"}, boundaryMethod] ||
      ! IntegerQ[constraintRank] || constraintRank < 0 ||
      ! MemberQ[{"NoConstraints", "Structural", "FreshModular"},
        Lookup[result, "DualClosureInitialSpanMethod", None]] ||
      ! MemberQ[{"NoConstraints", "NoRows", "FullRank", "FreshModular"},
        Lookup[result, "DualClosureStabilizationMethod", None]] ||
      ! MemberQ[{"NotRequired", "Structural", "FreshModular"},
        Lookup[result, "SecondBoundaryClosureInitialSpanMethod", None]] ||
      ! MemberQ[{"NotRequired", "NoRows", "FullRank", "FreshModular"},
        Lookup[result, "SecondBoundaryClosureStabilizationMethod", None]],
    Return[False]];
  coordinateCertificateQ[certificate_] := AssociationQ[certificate] &&
    Lookup[certificate, "Status", None] ===
      "FreshModularIdentityAccepted" &&
    TrueQ[Lookup[certificate, "Accepted", False]] &&
    TrueQ[Lookup[certificate, "Probabilistic", False]] &&
    TrueQ[Lookup[certificate, "Exact", True] === False] &&
    ListQ[Lookup[certificate, "FreshTrials", None]] &&
    Lookup[certificate, "FreshTrials", {}] =!= {} &&
    TrueQ[Lookup[certificate, "AllComplementaryRowsChecked", False]];
  ambientCertificateQ[certificate_] := AssociationQ[certificate] &&
    Lookup[certificate, "Status", None] ===
      "FreshModularSubspaceInclusionAccepted" &&
    TrueQ[Lookup[certificate, "Accepted", False]] &&
    TrueQ[Lookup[certificate, "Probabilistic", False]] &&
    TrueQ[Lookup[certificate, "Exact", True] === False] &&
    ListQ[Lookup[certificate, "AcceptedTrials", None]] &&
    Lookup[certificate, "AcceptedTrials", {}] =!= {};
  dlogCertificateQ[certificate_] := AssociationQ[certificate] &&
    TrueQ[Lookup[certificate, "Accepted", False]] &&
    TrueQ[Lookup[certificate, "Probabilistic", False]] &&
    TrueQ[Lookup[certificate, "Exact", True] === False] &&
    Lookup[certificate, "CoefficientField", None] === "Multiquadratic" &&
    TrueQ[Lookup[certificate, "ConstantResidues", False]] &&
    TrueQ[Lookup[certificate, "ResiduesVerifiedAtAllPrimes", False]] &&
    IntegerQ[Lookup[certificate, "LetterCount", Missing[]]] &&
    Lookup[certificate, "LetterCount", -1] >= 0 &&
    Lookup[certificate, "LetterCount", 0] ===
      Lookup[certificate, "ResidueCount", -1] && Which[
      Lookup[certificate, "Status", None] === "ComputedDLogResidues",
        Lookup[certificate, "IdentityMethod", None] ===
          "FiniteFieldPointwise" &&
        TrueQ[Lookup[certificate, "FreshPrimeValidation", False]] &&
        TrueQ[Lookup[certificate, "AllRootSheetsEvaluated", False]] &&
        ListQ[Lookup[certificate, "CRTPrimes", None]] &&
        Lookup[certificate, "CRTPrimes", {}] =!= {} &&
        IntegerQ[Lookup[certificate, "FreshValidationPrime", Missing[]]],
      Lookup[certificate, "Status", None] === "CertifiedDLogResidues",
        Lookup[certificate, "CertificationLevel", None] ===
          "HighConfidenceFiniteField" &&
        Lookup[certificate, "IdentityMethod", None] === "Modular" &&
        Lookup[certificate, "Method", None] ===
          "AllSignSheetsAtFreshSplitPoints" &&
        TrueQ[Lookup[certificate, "FreshLiftValidation", False]] &&
        TrueQ[Lookup[certificate, "AllRootSheetsChecked", False]] &&
        ListQ[Lookup[certificate, "IdentityPoints", None]] &&
        Lookup[certificate, "IdentityPoints", {}] =!= {},
      True, False];
  operatorAutomatonQ[value_] := Module[
    {maximumWeight, initial, firstAlphabet, firstMatrices, firstBoundary,
     secondAlphabet, secondMatrices, finalEmbedding, firstDimension,
     secondDimension},
    If[! AssociationQ[value] ||
        Lookup[value, "Status", None] =!= "ExactOperatorAutomaton",
      Return[False, Module]];
    maximumWeight = Lookup[value, "RequestedMaximumWeight", Missing[]];
    initial = Lookup[value, "InitialDemandMap", Missing[]];
    firstAlphabet = Lookup[value, "FirstAlphabetIndices", Missing[]];
    firstMatrices = Lookup[value, "FirstOperatorMatrices", Missing[]];
    firstBoundary = Lookup[value, "FirstBoundaryOperator", Missing[]];
    secondAlphabet = Lookup[value, "SecondAlphabetIndices", Missing[]];
    secondMatrices = Lookup[value, "SecondOperatorMatrices", Missing[]];
    finalEmbedding = Lookup[value, "FinalBoundaryEmbedding", Missing[]];
    If[! IntegerQ[maximumWeight] || maximumWeight < 0 ||
        ! MatrixQ[initial] || ! MatrixQ[firstBoundary] ||
        ! MatrixQ[finalEmbedding] ||
        ! VectorQ[firstAlphabet, IntegerQ[#] && # > 0 &] ||
        ! VectorQ[secondAlphabet, IntegerQ[#] && # > 0 &] ||
        ! DuplicateFreeQ[firstAlphabet] ||
        ! DuplicateFreeQ[secondAlphabet] ||
        ! ListQ[firstMatrices] || ! AllTrue[firstMatrices, MatrixQ] ||
        ! ListQ[secondMatrices] || ! AllTrue[secondMatrices, MatrixQ] ||
        Length[firstAlphabet] =!= Length[firstMatrices] ||
        Length[secondAlphabet] =!= Length[secondMatrices],
      Return[False, Module]];
    firstDimension = Last[Dimensions[initial]];
    secondDimension = Last[Dimensions[firstBoundary]];
    Dimensions[firstBoundary][[1]] === firstDimension &&
      Dimensions[finalEmbedding][[1]] === secondDimension &&
      AllTrue[firstMatrices,
        Dimensions[#] === {firstDimension, firstDimension} &] &&
      AllTrue[secondMatrices,
        Dimensions[#] === {secondDimension, secondDimension} &]
  ];
  compactAutomatonQ[value_] := Module[
    {maximumWeight, ranks, initial, firstAlphabet, transitions, terminals,
     secondAlphabet, secondMatrices, finalEmbedding, boundaryDimension},
    If[! AssociationQ[value] ||
        Lookup[value, "Status", None] =!=
          "ModularCompactAutomatonAccepted" ||
        Lookup[value, "Orientation", None] =!= "DualObservableRows",
      Return[False, Module]];
    maximumWeight = Lookup[value, "RequestedMaximumWeight", Missing[]];
    ranks = Lookup[value, "ObservableRankByExactWeight", Missing[]];
    initial = Lookup[value, "InitialCoordinates", Missing[]];
    firstAlphabet = Lookup[value, "FirstAlphabetIndices", Missing[]];
    transitions = Lookup[value, "ObservableTransitionsByWeight", Missing[]];
    terminals = Lookup[value, "TerminalContractionsByExactWeight", Missing[]];
    secondAlphabet = Lookup[value, "SecondAlphabetIndices", Missing[]];
    secondMatrices = Lookup[value, "SecondKernelMatrices", Missing[]];
    finalEmbedding = Lookup[value, "FinalBoundaryEmbedding", Missing[]];
    If[! IntegerQ[maximumWeight] || maximumWeight < 0 ||
        ! VectorQ[ranks, IntegerQ[#] && # >= 0 &] ||
        Length[ranks] =!= maximumWeight + 1 || ! MatrixQ[initial] ||
        Last[Dimensions[initial]] =!= First[ranks] ||
        ! VectorQ[firstAlphabet, IntegerQ[#] && # > 0 &] ||
        ! DuplicateFreeQ[firstAlphabet] || ! ListQ[transitions] ||
        Length[transitions] =!= maximumWeight ||
        ! ListQ[terminals] || Length[terminals] =!= maximumWeight + 1 ||
        ! VectorQ[secondAlphabet, IntegerQ[#] && # > 0 &] ||
        ! DuplicateFreeQ[secondAlphabet] || ! ListQ[secondMatrices] ||
        Length[secondAlphabet] =!= Length[secondMatrices] ||
        ! MatrixQ[finalEmbedding], Return[False, Module]];
    boundaryDimension = First[Dimensions[finalEmbedding]];
    And @@ Join[
      Table[ListQ[transitions[[weight]]] &&
        Length[transitions[[weight]]] === Length[firstAlphabet] &&
        AllTrue[transitions[[weight]], MatrixQ[#] &&
          Dimensions[#] === {ranks[[weight]], ranks[[weight + 1]]} &],
        {weight, 1, maximumWeight}],
      Table[MatrixQ[terminals[[weight]]] &&
        Dimensions[terminals[[weight]]] ===
          {ranks[[weight]], boundaryDimension},
        {weight, 1, maximumWeight + 1}],
      {AllTrue[secondMatrices, MatrixQ[#] &&
          Dimensions[#] === {boundaryDimension, boundaryDimension} &]}]
  ];
  materializedWordsQ[value_] := ListQ[value] && AllTrue[value,
    MatchQ[#, {_List, _List, _?MatrixQ}] &];
  If[representation === "OperatorAutomaton",
    automaton = Lookup[result, "ExactOperatorAutomaton", Missing[]];
    If[! operatorAutomatonQ[automaton], Return[False]]
  ];
  If[representation === "CompactAutomaton",
    automaton = Lookup[result, "CompactTransportAutomaton", Missing[]];
    If[! compactAutomatonQ[automaton], Return[False]]
  ];
  If[representation === "MaterializedWords" &&
      ! materializedWordsQ[Lookup[result, "TwoSegmentWordMaps", Missing[]]],
    Return[False]];
  coordinateRequired = representation === "CompactAutomaton";
  ambientRequired = boundaryMethod === "AmbientBasePoint" &&
    IntegerQ[constraintRank] && constraintRank > 0;
  structuralRequirements = {
    {"DualClosureInitialSpanMethod", "DualClosureInitialSpan"},
    {"DualClosureStabilizationMethod", "DualClosureStabilization"},
    {"SecondBoundaryClosureInitialSpanMethod",
      "SecondBoundaryClosureInitialSpan"},
    {"SecondBoundaryClosureStabilizationMethod",
      "SecondBoundaryClosureStabilization"}};
  structuralRequired = AnyTrue[structuralRequirements,
    Lookup[result, First[#], None] === "FreshModular" &];
  firstKernelIdentityExact = TrueQ[Lookup[certificates,
    "FirstKernelIdentityExact",
    Lookup[certificates, "FirstKernelIdentity", False]]];
  secondKernelIdentityExact = TrueQ[Lookup[certificates,
    "SecondKernelIdentityExact",
    Lookup[certificates, "SecondKernelIdentity", False]]];
  dlogRequired = ! firstKernelIdentityExact || ! secondKernelIdentityExact;
  If[status === "ExactObservableTransport",
    Return[TrueQ[Lookup[certificates,
        "FamilyEpsilonFormExact", False]] &&
      ! coordinateRequired && ! ambientRequired &&
      ! structuralRequired && ! dlogRequired]];
  If[status =!= "ModularlyVerifiedObservableTransport", Return[False]];
  probabilistic = Lookup[result, "ProbabilisticCertificates", <||>];
  If[! AssociationQ[probabilistic], Return[False]];
  systems = Lookup[probabilistic, "CoordinateSystems", {}];
  coordinateAccepted = ! coordinateRequired ||
    (TrueQ[Lookup[probabilistic,
        "CoordinateReconstructionFreshModular", False]] &&
      ListQ[systems] && systems =!= {} &&
      systems === Lookup[automaton, "CoordinateCertificates", None] &&
      AllTrue[systems, coordinateCertificateQ]);
  ambientAccepted = ! ambientRequired ||
    ambientCertificateQ[Lookup[probabilistic,
      "AmbientBoundaryInvariance", Missing[]]];
  structuralAccepted = AllTrue[structuralRequirements,
    Lookup[result, First[#], None] =!= "FreshModular" ||
      ambientCertificateQ[Lookup[probabilistic,
        Last[#], Missing[]]] &];
  dlogAccepted = ! dlogRequired ||
    (TrueQ[Lookup[certificates,
        "FirstKernelIdentityCertified", False]] &&
      TrueQ[Lookup[certificates,
        "SecondKernelIdentityCertified", False]] &&
      dlogCertificateQ[Lookup[probabilistic,
        "FamilyDLogResidues", Missing[]]]);
  coordinateAccepted && ambientAccepted && structuralAccepted &&
    dlogAccepted &&
    (coordinateRequired || ambientRequired || structuralRequired ||
      dlogRequired)
];

ObservableTransportWordMap[result_Association, firstWord_List,
    secondWord_List] := Module[
  {representation, materialized, automaton, firstAlphabet, secondAlphabet,
   firstPositions, secondPositions, maximumWeight, initial, transitions,
   terminals, firstMatrices, firstBoundary, secondMatrices,
   finalEmbedding, map, position, wordStatus},
  representation = Lookup[result, "WordRepresentation",
    "MaterializedWords"];
  If[! AcceptedObservableTransportQ[result],
    Return[<|"Status" -> "ObservableTransportNotAccepted"|>]
  ];
  wordStatus = If[Lookup[result, "Status", None] ===
      "ExactObservableTransport", "ExactWordMap",
    "ModularlyVerifiedWordMap"];
  If[representation === "MaterializedWords",
    materialized = SelectFirst[
      Lookup[result, "TwoSegmentWordMaps", {}],
      MatchQ[#, {firstWord, secondWord, _?MatrixQ}] &,
      Missing["WordMapNotPresent"]];
    Return[If[MissingQ[materialized],
      <|"Status" -> "WordMapNotAvailable", "FirstWord" -> firstWord,
        "SecondWord" -> secondWord|>,
      <|"Status" -> wordStatus, "Source" -> "MaterializedWords",
        "MatrixArithmeticExact" -> True,
        "FirstWord" -> firstWord, "SecondWord" -> secondWord,
        "Map" -> materialized[[3]]|>]]
  ];

  If[representation === "OperatorAutomaton",
    automaton = Lookup[result, "ExactOperatorAutomaton", Missing[]];
    If[! AssociationQ[automaton] ||
        Lookup[automaton, "Status", None] =!=
          "ExactOperatorAutomaton",
      Return[<|"Status" -> "OperatorAutomatonNotAvailable"|>]
    ];
    maximumWeight = automaton["RequestedMaximumWeight"];
    If[Length[firstWord] + Length[secondWord] > maximumWeight,
      Return[<|"Status" -> "WordExceedsRequestedWeight",
        "RequestedMaximumWeight" -> maximumWeight|>]
    ];
    firstAlphabet = automaton["FirstAlphabetIndices"];
    secondAlphabet = automaton["SecondAlphabetIndices"];
    firstPositions = FirstPosition[firstAlphabet, #, Missing[]] & /@
      firstWord;
    secondPositions = FirstPosition[secondAlphabet, #, Missing[]] & /@
      secondWord;
    If[AnyTrue[Join[firstPositions, secondPositions], MissingQ],
      Return[<|"Status" -> "WordUsesUnknownKernel",
        "FirstWord" -> firstWord, "SecondWord" -> secondWord|>]
    ];
    firstPositions = First /@ firstPositions;
    secondPositions = First /@ secondPositions;
    map = automaton["InitialDemandMap"];
    firstMatrices = automaton["FirstOperatorMatrices"];
    Do[map = map . firstMatrices[[position]],
      {position, firstPositions}];
    firstBoundary = automaton["FirstBoundaryOperator"];
    map = map . firstBoundary;
    secondMatrices = automaton["SecondOperatorMatrices"];
    Do[map = map . secondMatrices[[position]],
      {position, secondPositions}];
    finalEmbedding = automaton["FinalBoundaryEmbedding"];
    map = map . finalEmbedding;
    Return[<|"Status" -> wordStatus,
      "Source" -> "OperatorAutomaton", "Canonicalized" -> False,
      "MatrixArithmeticExact" -> True,
      "FirstWord" -> firstWord, "SecondWord" -> secondWord,
      "Map" -> map|>]
  ];

  automaton = Lookup[result, "CompactTransportAutomaton", Missing[]];
  If[! AssociationQ[automaton] ||
      Lookup[automaton, "Status", None] =!=
        "ModularCompactAutomatonAccepted",
    Return[<|"Status" -> "CompactAutomatonNotAvailable"|>]
  ];
  maximumWeight = automaton["RequestedMaximumWeight"];
  If[Length[firstWord] + Length[secondWord] > maximumWeight,
    Return[<|"Status" -> "WordExceedsRequestedWeight",
      "RequestedMaximumWeight" -> maximumWeight|>]
  ];
  firstAlphabet = automaton["FirstAlphabetIndices"];
  secondAlphabet = automaton["SecondAlphabetIndices"];
  firstPositions = FirstPosition[firstAlphabet, #, Missing[]] & /@
    firstWord;
  secondPositions = FirstPosition[secondAlphabet, #, Missing[]] & /@
    secondWord;
  If[AnyTrue[Join[firstPositions, secondPositions], MissingQ],
    Return[<|"Status" -> "WordUsesUnknownKernel",
      "FirstWord" -> firstWord, "SecondWord" -> secondWord|>]
  ];
  firstPositions = First /@ firstPositions;
  secondPositions = First /@ secondPositions;
  initial = automaton["InitialCoordinates"];
  transitions = automaton["ObservableTransitionsByWeight"];
  terminals = automaton["TerminalContractionsByExactWeight"];
  If[Length[firstWord] + 1 > Length[terminals],
    Return[<|"Status" -> "WordMapNotAvailable"|>]
  ];
  map = initial;
  Do[
    map = map . transitions[[position, firstPositions[[position]]]],
    {position, Length[firstWord]}];
  map = map . terminals[[Length[firstWord] + 1]];
  secondMatrices = automaton["SecondKernelMatrices"];
  Do[map = map . secondMatrices[[position]], {position, secondPositions}];
  finalEmbedding = automaton["FinalBoundaryEmbedding"];
  map = map . finalEmbedding;
  <|"Status" -> "ModularlyVerifiedWordMap",
    "Source" -> "CompactAutomaton", "FirstWord" -> firstWord,
    "SecondWord" -> secondWord, "Map" -> map|>
];

ObservableTransportWordMap[___] :=
  <|"Status" -> "ObservableTransportWordInputsNotWellFormed"|>;

Options[ReconstructObservableTransportWordMaps] = {
  "CoordinateBackend" -> "Ratracer",
  "CoordinateCacheDirectory" -> Automatic,
  "CoordinateKey" -> Automatic,
  "ReconstructionThreads" -> Automatic,
  "ValidationPrimeCount" -> 2,
  "ValidationPointsPerPrime" -> 1,
  "RankSamples" -> Automatic,
  "RatracerExecutable" -> Automatic,
  "FLINTExecutable" -> Automatic,
  "ValidationSeed" -> Automatic,
  "Verbose" -> False
};

ReconstructObservableTransportWordMaps[result_Association,
    wordPairs_List, OptionsPattern[]] := Module[
  {variables, samples, words, matrices, dimensions, rowCount, joined,
   reconstruction, reconstructed, records, representation, automaton,
   maximumWeight, firstAlphabet, secondAlphabet, firstPositions,
   secondPositions, firstMatrices, secondMatrices, firstBoundary,
   finalEmbedding, firstState, secondState},
  If[! AcceptedObservableTransportQ[result],
    Return[<|"Status" -> "ObservableTransportNotAccepted"|>]];
  If[Lookup[result, "CoefficientField", "Rational"] =!= "Rational",
    Return[<|"Status" -> "RationalCoefficientFieldRequired"|>]];
  If[! MatchQ[wordPairs, {{_List, _List} ...}],
    Return[<|"Status" -> "ObservableWordBatchInvalid"|>]];
  If[wordPairs === {},
    Return[<|"Status" ->
      "ModularlyReconstructedObservableWordMaps",
      "Accepted" -> True, "WordMaps" -> {},
      "ModularCertificate" -> <|"Status" -> "StructuralEmptyBatch",
        "Accepted" -> True, "Probabilistic" -> False,
        "Exact" -> True|>|>]];
  variables = Lookup[result, "Variables", Missing[]];
  If[! MatchQ[variables, {_Symbol, _Symbol}],
    Return[<|"Status" -> "TwoVariableRecordRequired"|>]];
  representation = Lookup[result, "WordRepresentation", None];
  If[representation === "OperatorAutomaton",
    automaton = result["ExactOperatorAutomaton"];
    maximumWeight = automaton["RequestedMaximumWeight"];
    firstAlphabet = automaton["FirstAlphabetIndices"];
    secondAlphabet = automaton["SecondAlphabetIndices"];
    If[AnyTrue[wordPairs,
        Length[#[[1]]] + Length[#[[2]]] > maximumWeight ||
        ! AllTrue[#[[1]], MemberQ[firstAlphabet, #] &] ||
        ! AllTrue[#[[2]], MemberQ[secondAlphabet, #] &] &],
      Return[<|"Status" -> "ObservableWordBatchUsesUnknownKernel"|>]];
    firstPositions = AssociationThread[firstAlphabet,
      Range[Length[firstAlphabet]]];
    secondPositions = AssociationThread[secondAlphabet,
      Range[Length[secondAlphabet]]];
    firstMatrices = automaton["FirstOperatorMatrices"];
    secondMatrices = automaton["SecondOperatorMatrices"];
    firstBoundary = automaton["FirstBoundaryOperator"];
    finalEmbedding = automaton["FinalBoundaryEmbedding"];
    firstState[{}] = automaton["InitialDemandMap"];
    firstState[word_List] := firstState[word] =
      firstState[Most[word]] .
        firstMatrices[[firstPositions[Last[word]]]];
    secondState[firstWord_List, {}] :=
      secondState[firstWord, {}] = firstState[firstWord] . firstBoundary;
    secondState[firstWord_List, secondWord_List] /; secondWord =!= {} :=
      secondState[firstWord, secondWord] =
        secondState[firstWord, Most[secondWord]] .
          secondMatrices[[secondPositions[Last[secondWord]]]];
    matrices = (secondState[#[[1]], #[[2]]] . finalEmbedding) & /@
      wordPairs,
    words = FeynFacet`ObservableTransportWordMap[
        result, #[[1]], #[[2]]] & /@ wordPairs;
    If[! AllTrue[words, MemberQ[{"ExactWordMap",
            "ModularlyVerifiedWordMap"}, Lookup[#, "Status", None]] &],
      Return[<|"Status" -> "ObservableWordMaterializationFailed",
        "Failures" -> Select[words,
          ! MemberQ[{"ExactWordMap", "ModularlyVerifiedWordMap"},
            Lookup[#, "Status", None]] &]|>]];
    matrices = Lookup[words, "Map"]
  ];
  dimensions = Dimensions /@ matrices;
  If[Length[DeleteDuplicates[dimensions]] =!= 1 ||
      Length[First[dimensions]] =!= 2,
    Return[<|"Status" -> "ObservableWordMatrixShapesDiffer"|>]];
  rowCount = First[First[dimensions]];
  joined = Join @@ (Normal /@ matrices);
  samples = Replace[OptionValue["RankSamples"], Automatic ->
    (Thread[variables -> #] & /@
      {{1/5, 2/7}, {2/9, 3/8}, {4/11, 5/13}})];
  reconstruction = observableTransportModularMatrixReconstruction[
    joined, variables, samples,
    "CoordinateBackend" -> OptionValue["CoordinateBackend"],
    "CoordinateCacheDirectory" ->
      OptionValue["CoordinateCacheDirectory"],
    "CoordinateKey" -> OptionValue["CoordinateKey"],
    "ReconstructionThreads" -> OptionValue["ReconstructionThreads"],
    "ValidationPrimeCount" -> OptionValue["ValidationPrimeCount"],
    "ValidationPointsPerPrime" ->
      OptionValue["ValidationPointsPerPrime"],
    "RatracerExecutable" -> OptionValue["RatracerExecutable"],
    "FLINTExecutable" -> OptionValue["FLINTExecutable"],
    "ValidationSeed" -> OptionValue["ValidationSeed"],
    "Verbose" -> OptionValue["Verbose"]];
  If[! AssociationQ[reconstruction] ||
      Lookup[reconstruction, "Status", None] =!=
        "ModularMatrixReconstructionAccepted",
    Return[If[AssociationQ[reconstruction], reconstruction,
      <|"Status" -> "ObservableWordReconstructionFailed"|>]]];
  reconstructed = reconstruction["Matrix"];
  records = MapIndexed[
    {#1[[1]], #1[[2]], reconstructed[[
      (First[#2] - 1) rowCount + Range[rowCount], All]]} &,
    wordPairs];
  <|"Status" -> "ModularlyReconstructedObservableWordMaps",
    "Accepted" -> True,
    "Probabilistic" -> TrueQ[Lookup[
      reconstruction["ModularCertificate"], "Probabilistic", False]],
    "Canonicalized" -> True, "WordMaps" -> records,
    "ModularCertificate" -> reconstruction["ModularCertificate"]|>
];

ReconstructObservableTransportWordMaps[___] :=
  <|"Status" -> "ObservableWordBatchInputsNotWellFormed"|>;

(* Public entry to the epsilon-valuation certifier (round 4, 2026-09-02):
   one-line wrappers only; the machinery is observableTransportCertifyEpsilonValuations
   and its file variant above. *)
CertifyTransportEpsilonValuations[record_Association, opts___] := observableTransportCertifyEpsilonValuations[record, opts];
CertifyTransportEpsilonValuations[file_String, opts___] := observableTransportCertifyEpsilonValuationsFile[file, opts];
CertifyTransportEpsilonValuations[___] := <|"Status" -> "TransportEpsilonValuationInputNotWellFormed"|>;
