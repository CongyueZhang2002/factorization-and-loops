(* Physical setup, dimensional regulator and provenance conventions. *)
resultHeader[format_, version_Integer] := <|
  "Format" -> format,
  "FormatVersion" -> version,
  "Created" -> DateString[{"ISODate", "T", "Time"}]
|>;

resultContext[data_Association] := KeyTake[
  data,
  {"CardName", "ResultDirectory", "Pairs", "Setup", "AnalyticContext"}
];

reductionFingerprint[payload_] := Hash[payload, "SHA256", "HexString"];

artifactHeaderQ[data_, format_String, version_Integer] :=
  AssociationQ[data] &&
    Lookup[data, "Format", None] === format &&
    Lookup[data, "FormatVersion", None] === version;

(* The regulator a context is written in: its own "Regulator" entry when
   it carries one, the package symbol otherwise.  A context that names no
   regulator is read in the package's own, which is what every context
   this repository has stored does (generality pass 2026-08-23). *)
analyticContextRegulator[context_] := With[
  {declared = Lookup[context, "Regulator", Automatic]},
  If[MatchQ[declared, _Symbol] && declared =!= Automatic,
    declared, $feynFacetEpsilon]
];

(* The dimension rule is validated by SHAPE, not by identity with the
   package global.  What the package actually requires of a dimension
   rule is D -> a - 2 regulator with an INTEGER a and a SYMBOL
   regulator: that is the form every dimensional shift, expansion and
   pole-counting rule here is written for.  Testing identity with
   $dimensionRule additionally demanded a = 4 and the one global symbol
   Global`Epsilon, which is a property of this front end and not of the
   algebra; D -> 6 - 2 ep is an equally valid analytic context and used
   to be refused with no diagnosis. *)
analyticDimensionRuleQ[rule_, regulator_] := Module[{right},
  If[! MatchQ[rule, Rule[System`D, _]] || ! MatchQ[regulator, _Symbol],
    Return[False]];
  right = Last[rule];
  TrueQ[PolynomialQ[right, regulator]] &&
    TrueQ[Exponent[right, regulator] === 1] &&
    TrueQ[Coefficient[right, regulator, 1] === -2] &&
    IntegerQ[Coefficient[right, regulator, 0]]
];

analyticContextQ[context_] := Module[{required},
  required = {
    "Gamma5Scheme", "GlobalBasis", "GlobalBasisGram",
    "SetEvanescentZero", "SetMassZero", "SetDistributionZero",
    "CollinearRelations", "Assumptions", "CoefficientKinematics",
    "KinematicMassDimensions",
    "LoopDimension", "DimensionRule", "CutConvention",
    "DistributionConvention", "FeynFacetSourceHash", "Fingerprint"
  };
  AssociationQ[context] &&
    ContainsAll[Keys[context], required] &&
    (* the front end declares BMHV and nothing else: the evanescent
       bookkeeping downstream is written for that scheme *)
    context["Gamma5Scheme"] === "BMHV" &&
    analyticDimensionRuleQ[context["DimensionRule"],
      analyticContextRegulator[context]] &&
    StringQ[context["FeynFacetSourceHash"]] &&
    context["Fingerprint"] ===
      reductionFingerprint[KeyDrop[context, "Fingerprint"]] &&
    exactDataQ[context]
];
