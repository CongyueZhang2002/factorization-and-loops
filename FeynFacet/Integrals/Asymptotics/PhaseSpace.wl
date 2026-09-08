
(* A sufficient uniform recoil-mass bound for three future-directed,
   massless cut particles and tree propagators. This module owns the
   physical geometry; LocalLimits.wl owns the general DE mode count.
   See Design/ThreeParticlePhaseSpaceBoundaryScaling.md for the proof. *)
Clear[DetermineThreeParticlePhaseSpaceScaling];
ClearAll[phaseSpaceScalingDenominator];

phaseSpaceScalingDenominator[q_, cuts_, external_, dot_] := Module[
  {subsets, r, chosen = None},
  subsets = Subsets[Range[Length[cuts]], {1, Length[cuts]}];
  Do[
    r = Expand[Total[cuts[[set]]]];
    If[Length[set] >= 2 && (Expand[q - r] === 0 || Expand[q + r] === 0),
      chosen = <|"Type" -> "FinalStateInvariant", "Subset" -> set|>; Break[]],
    {set, subsets}];
  If[chosen =!= None, Return[chosen]];
  Do[
    r = Expand[Total[cuts[[set]]]];
    If[TrueQ[dot[p, Total[cuts]] > 0] &&
        AnyTrue[Tuples[{1, -1}, 2],
          Expand[q - #[[1]] p - #[[2]] r] === 0 &],
      chosen = <|"Type" -> "ExternalInvariant", "ExternalMomentum" -> p,
        "Subset" -> set, "ExternalProjectionAtBoundary" -> dot[p, Total[cuts]]|>;
      Break[]],
    {p, external}, {set, subsets}];
  chosen
];

DetermineThreeParticlePhaseSpaceScaling[system_Association, records_List,
    edgeKinematics_List, normalization_Association] := Module[
  {basis = system["MasterIntegralBasis"], byFamily, epsilon, dimension,
   eligible = {}, results = {}, rec, top, cuts, powers, ordinary, descriptors,
   q, loops, external, inverse, check, tests, reason, dot, total, slope, cutMatrix, raw},
  epsilon = system["DimensionalRegulator"];
  dimension = Lookup[normalization, "Dimension", None];
  If[Lookup[normalization, "Measure", None] =!= "StandardLorentzInvariantPhaseSpace" ||
      Lookup[normalization, "MasterIntegralPrefactor", None] =!= 1 ||
      ! PolynomialQ[dimension, epsilon] || Exponent[dimension, epsilon] =!= 1,
    Return[Failure["UnscaledPhaseSpaceNormalizationRequired", <||>]]];
  slope = Coefficient[dimension, epsilon, 1];
  If[! MatchQ[slope, _Integer | _Rational] || slope >= 0,
    Return[Failure["DimensionMustDecreaseWithEpsilon", <||>]]];
  byFamily = Association[(cutEquivalenceFamilyName[#["Topology"][[1]]] -> #) & /@ records];
  dot[u_, v_] := Cancel[FeynCalc`ExpandScalarProduct[
    FeynCalc`FCI[FeynCalc`SPD[u, v]]] /. edgeKinematics];
  Do[
    reason = None; tests = {};
    rec = Lookup[byFamily, basis[[row, 1]], None];
    If[! AssociationQ[rec], reason = "MissingTopology",
      top = rec["Topology"]; loops = top[[3]]; external = top[[4]];
      cuts = MapThread[Times, {rec["CutDirections"], rec["CutMomenta"]}];
      powers = basis[[row, 2]];
      total = Expand[Total[cuts]];
      cutMatrix = Table[Coefficient[cm,l],{cm,cuts},{l,loops}];
      raw = Cases[top[[2]], _FeynCalc`StandardPropagatorDenominator, Infinity];
      Which[
        Length[loops] =!= 2 || Length[cuts] =!= 3 ||
          !VectorQ[Flatten[cutMatrix], MatchQ[#, _Integer | _Rational] &] ||
          MatrixRank[cutMatrix] =!= 2 ||
          ! FreeQ[total, Alternatives@@loops] || total === 0,
          reason = "NotThreeParticlePhaseSpace",
        ! AllTrue[powers[[rec["CutIndices"]]], # === 1 &],
          reason = "RaisedCutRequiresAnObservedUnitCutCombination",
        Length[raw] =!= Length[top[[2]]] || !AllTrue[raw, #[[3]] === 0 &], reason = "MassivePropagator",
        ! AllTrue[external, dot[#, #] === 0 &],
          reason = "ExternalMomentumNotLightlike",
        dot[total, total] =!= 0, reason = "BoundaryIsNotZeroRecoilMass",
        True,
          descriptors = propagatorDescriptor[#, {}] & /@ top[[2]];
          If[MemberQ[descriptors, $Failed] ||
              !And@@Table[
                descriptors[[rec["CutIndices"][[j]]]]["Type"] === "QuadraticLorentzian" &&
                (Expand[descriptors[[rec["CutIndices"][[j]]]]["Momentum"] - cuts[[j]]] === 0 ||
                 Expand[descriptors[[rec["CutIndices"][[j]]]]["Momentum"] + cuts[[j]]] === 0),
                {j,3}],
            reason = "UnsupportedOrMismatchedCutPropagator",
            ordinary = Select[Complement[Range[Length[powers]], rec["CutIndices"]],
              powers[[#]] > 0 &];
            Do[
              If[descriptors[[j]]["Type"] =!= "QuadraticLorentzian",
                reason = "PositivePowerLinearDenominatorNotRecognized"; Break[]];
              q = descriptors[[j]]["Momentum"];
              check = phaseSpaceScalingDenominator[q, cuts, external, dot];
              If[check === None,
                reason = "DenominatorNotControlledByPositivePhaseSpaceMoments"; Break[]];
              AppendTo[tests, Join[check, <|"PropagatorIndex" -> j,
                "Power" -> powers[[j]]|>]],
              {j, ordinary}]]]];
    If[reason === None, AppendTo[eligible, row]];
    AppendTo[results, <|"Row" -> row, "MasterIntegral" -> basis[[row]],
      "Eligible" -> (reason === None),
      "Reason" -> If[reason === None, "UniformPositiveMeasureMomentBound", reason],
      "DenominatorChecks" -> tests|>],
    {row, Length[basis]}];
  <|"MasterRows" -> eligible, "MaximumEpsilonSlope" -> slope,
    "Justification" ->
      "For real D sufficiently large, positive three-particle phase space, uniform inverse-moment bounds and Holder's inequality give |I| <= C(D) (Q^2)^(D-3-M), with M independent of D. Exclude complete regular-singular components with larger epsilon slope, then continue their zero amplitudes meromorphically in D.",
    "Normalization" -> normalization,
    "BoundaryKinematicRules" -> edgeKinematics,
    "EligibleMasterCount" -> Length[eligible],
    "UniformInTangentialNeighborhood" -> True,
    "MasterChecks" -> results|>
];
