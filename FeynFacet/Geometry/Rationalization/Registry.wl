(* Explicit, verified mathematical catalog entries. No process data or
   external files are discovered as a side effect of loading geometry. *)
$additionalRationalizingParametrizations = <||>;
FeynFacet`RegisterRationalizingParametrizations[entries_Association] := Module[
 {names=Keys[entries], normalized, checks, existing, conflicts},
 If[!AllTrue[names,StringQ] || !AllTrue[Values[entries],AssociationQ],
  Return[Failure["InvalidParametrizationEntries",<||>]]];
 If[!AllTrue[names,Lookup[entries[#],"Name",None]===#&],
  Return[Failure["ParametrizationNameMismatch",<||>]]];
 normalized=Map[rationalizingParametrizationCatalogRecord,entries];
 checks=Map[FeynFacet`VerifyRationalizingParametrization,normalized];
 If[!AllTrue[Values[checks],TrueQ[Lookup[#,"Verified",False]]&],
  Return[Failure["ParametrizationVerificationFailed",<|"Checks"->checks|>]]];
 existing=FeynFacet`RationalizingParametrizationCatalog[];
 conflicts=Select[Intersection[names,Keys[existing]],existing[#]=!=normalized[#]&];
 If[conflicts=!={},Return[Failure["ParametrizationNameAlreadyUsed",<|"Names"->conflicts|>]]];
 $additionalRationalizingParametrizations=Join[$additionalRationalizingParametrizations,normalized];
 <|"RegisteredNames"->names,"Verification"->checks|>
];
FeynFacet`RegisterRationalizingParametrizations[___] :=
 Failure["InvalidParametrizationEntries",<||>];
