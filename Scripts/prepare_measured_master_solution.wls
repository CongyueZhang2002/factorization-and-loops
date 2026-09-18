Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
args=Rest[$ScriptCommandLine];
If[Length[args]=!=1,Print["Usage: prepare_measured_master_solution.wls SHARED_REDUCTION_MANIFEST.json"];Exit[2]];
manifestFile=ExpandFileName[First[args]];manifest=Import[manifestFile,"RawJSON"];
path=ExpandFileName[FileNameJoin[{DirectoryName[manifestFile],manifest["OutputDirectory"]}]];
input=FeynFacet`FamilyArtifactRead[path<>"/ReductionInput.wl"];
system=FeynFacet`FamilyArtifactRead[path<>"/DifferentialSystem.wl"];
If[!AssociationQ[input]||!AssociationQ[system],Print["Fresh shared reduction and DE required"];Exit[1]];
first=First[manifest["Contributions"]];
directory=FileNameJoin[{root,"Projects",first["Project"],"Raw",first["Order"],first["Channel"]}];
card=FeynFacet`ReadContributionCard[directory,first["Contribution"]];
integration=Lookup[card["Assembly"],"MasterIntegration",None];
If[!AssociationQ[integration]||integration["Method"]=!="OrderedMeasuredBoundary",
 Print["Declare a supported physical boundary method"];Exit[1]];
e=system["DimensionalRegulator"];variables=system["KinematicVariables"];
points=FeynFacet`Private`differentialDimensionPoint[#,system,"Both"]&/@system["Validation"]["Points"];
If[AnyTrue[points,FailureQ],Print[points];Exit[1]];
Print["REDUCING EXACT MASTER EQUIVALENCES ",Length[system["MasterIntegralBasis"]]];
system=FeynFacet`ReduceEquivalentMasterIntegrals[system,<|"ValidationPoints"->points,"Verbose"->True|>];
If[!AssociationQ[system],Print[system];Exit[1]];
Print["MASTER EQUIVALENCES REDUCED ",Length[system["MasterIntegralBasis"]]];
(* Candidate integrals come from this calculation's unit-cut sources.
   Exact inversion and DE compatibility check the selected basis. *)
selected=FeynFacet`SelectMasterIntegralBasis[system,system["Reduction"],
 <|"CandidateIntegrals"->input["Targets"],"ValidationPoints"->points,"RequireUnitCutBasis"->True|>];
If[!AssociationQ[selected],Print[selected];Exit[1]];
(* The strict affine quotient leaves ordinary-prescription duplicates. Certify
   the selected unit-cut integrals individually, then close those identities
   under the DE. Their joint endpoint extension is proved later. *)
geometry=Lookup[card["Assembly"],"MeasuredPhaseSpace",None];
If[AssociationQ[geometry],
 Print["CERTIFYING PHYSICAL MASTER EQUIVALENCES ",Length[selected["MasterIntegralBasis"]]];
 selected=FeynFacet`ReduceEquivalentMasterIntegrals[selected,
  <|"OrdinaryPrescriptionGeometry"->geometry,"ValidationPoints"->points,"Verbose"->True|>];
 If[!AssociationQ[selected],Print[selected];Exit[1]]
];
basis=selected["MasterIntegralBasis"];
reduction=Join[selected["Reduction"],<|"AllTargetsInPreferredSpan"->True|>];
selected=Join[selected,<|"Reduction"->reduction|>];
Do[
 target=path<>"/"<>entry[[1]]<>".wl";
 If[FeynFacet`FamilyArtifactWrite[entry[[2]],target]=!=target,
  Print["Required physical-basis output could not be written: ",target];Exit[1]],
 {entry,{{"PhysicalDifferentialSystem",selected},{"PhysicalReduction",reduction},
   {"BoundaryRequest",integration["Boundary"]}}}];
(* Persist small, original-coordinate definitions for lookup before master
   integration. Family names and the owning project are not identity keys. *)
boundaryRequest=integration["Boundary"];
inverse=Solve[First[boundaryRequest["RecoilSubstitution"]][[1]]==
  First[boundaryRequest["RecoilSubstitution"]][[2]],boundaryRequest["RecoilVariable"]];
If[!MatchQ[inverse,{{_Rule}}],Print["Unique physical coordinate inverse required"];Exit[1]];
libraryDefinitions=FeynFacet`ConstructMasterIntegralDefinitions[
 Join[selected,<|"KinematicConditions"->(boundaryRequest["Assumptions"]/.First[inverse])|>]];
If[!AssociationQ[libraryDefinitions]||libraryDefinitions["UnresolvedIntegralDefinitions"]=!=<||>,
 Print["Complete physical master definitions required ",libraryDefinitions];Exit[1]];
libraryDefinitions=Join[libraryDefinitions,<|
 "MasterIntegralBasis"->basis,"SolutionToIntegralCoordinates"->First[inverse],
 "IntegralToSolutionCoordinates"->boundaryRequest["RecoilSubstitution"]|>];
definitionFile=path<>"/MasterIntegralDefinitions.wl";
If[FeynFacet`FamilyArtifactWrite[libraryDefinitions,definitionFile]=!=definitionFile,Exit[1]];
libraryLookup=FeynFacet`FindMasterIntegralValues[libraryDefinitions["MasterIntegralDefinitions"],
 AssociationThread[Range[Length[basis]],ConstantArray[{0,0},Length[basis]]]];
If[!AssociationQ[libraryLookup],Print[libraryLookup];Exit[1]];
lookupReport=Join[KeyDrop[libraryLookup,"Values"],<|"Matches"->Map[KeyTake[#,{"LibraryReuse"}]&,libraryLookup["Values"]]|>];
If[FeynFacet`FamilyArtifactWrite[lookupReport,path<>"/MasterLibraryLookup.wl"]=!=path<>"/MasterLibraryLookup.wl",Exit[1]];
Print["MASTER LIBRARY AVAILABLE AT EPSILON ZERO ",Length[libraryLookup["Values"]],"/",Length[basis]];
Print["COMPLETED PHYSICAL MASTER BASIS ",Length[basis]];
