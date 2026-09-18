#!/usr/bin/env wolframscript
root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
If[Length[$ScriptCommandLine]<2,Print["Usage: construct_physical_boundary_relations.wls input.wxf"];Exit[1]];
file=ExpandFileName[Last[$ScriptCommandLine]];base=DirectoryName[file];
read[path_]:=If[FileExtension[path]==="wxf",Import[path,"WXF"],FeynFacetRecords`ReadRecord[path]];
resolve[path_]:=ExpandFileName[If[StringStartsQ[path,"/"],path,FileNameJoin[{base,path}]]];
materialize[x_String]:=read[resolve[x]];materialize[x_]:=x;
spec=read[file];input=materialize[spec["SingularBoundaryConstruction"]];
system=input["PreparedBoundarySystem"]["NormalizedDifferentialSystem"];
eps=system["DimensionalRegulator"];z=system["Variable"];
g=input["PreparedBoundarySystem"]["NormalizedToOriginalGauge"];
output=resolve[spec["OutputDirectory"]];If[!DirectoryQ[output],CreateDirectory[output,CreateIntermediateDirectories->True]];
atomic[value_,path_]:=(Export[path<>".tmp",BinarySerialize[value,PerformanceGoal->"Size"],"Byte"];RenameFile[path<>".tmp",path,OverwriteTarget->True]);
definitions=materialize[Lookup[spec,"OriginalIntegralDefinitions",<||>]];
physical=materialize[Lookup[spec,"PhysicalBoundaryIntegralDefinitions",<||>]];
rejected=<||>;
constructor=Lookup[spec,"BoundaryIntegralConstructor",FeynFacet`ConstructCoalescingNullBoundaryIntegral];
Do[
 definition=definitions[row];
 result=constructor[definition,<|"NormalVariable"->z,
   "BoundaryKinematicRules"->(definition["KinematicRules"]/.z->0)|>];
 If[FailureQ[result],AssociateTo[rejected,row->result],AssociateTo[physical,row->result]],
 {row,Keys[definitions]}];
atomic[<|"OriginalIntegralDefinitions"->definitions,"PhysicalBoundaryIntegralDefinitions"->physical,
 "UnresolvedIntegralLimits"->rejected|>,output<>"/physical_coefficient_definitions.wxf"];
If[physical===<||>,Print["FAILED No physical coefficient definitions."];Exit[1]];
primary=materialize[Lookup[spec,"PrimaryExpansion",None]];
If[primary===None,
 primary=FeynFacet`ConstructPrimaryFrobeniusExpansion[system,input["BoundarySeed"],spec["PrimaryExpansionRequest"],"Verbose"->True]];
If[FailureQ[primary],Print["FAILED ",primary];Exit[1]];
normalValuation[value_]:=If[value===0,Infinity,With[{nd=NumeratorDenominator[Cancel[Together[value]]]},
 Exponent[nd[[1]],z,Min]-Exponent[nd[[2]],z,Min]]];
needed=Max[0,Sequence@@Table[
 physical[row]["NormalExponent"]-primary["ResidueEigenvalue"]-Min[normalValuation/@g[[row]]],
 {row,Keys[physical]}]];
If[IntegerQ[needed]&&needed>primary["MaximumNormalOrder"],
 Print["EXTENDING PRIMARY NORMAL ORDER ",primary["MaximumNormalOrder"]," -> ",needed];
 primary=FeynFacet`ConstructPrimaryFrobeniusExpansion[system,input["BoundarySeed"],<|
  "ResidueEigenvalue"->primary["ResidueEigenvalue"],"SpectralVariable"->primary["SpectralVariable"],
  "ResidueAnnihilatingPolynomial"->primary["ResidueAnnihilatingPolynomial"],
  "MaximumNormalOrder"->needed|>,"Verbose"->True];
 If[FailureQ[primary],Print["FAILED ",primary];Exit[1]];
 atomic[primary,output<>"/primary_expansion.wxf"]];

n=Length[input["BoundarySeed"]["Basis"][[1]]];
knownRows=Lookup[spec,"KnownAmplitudeRows",{}];
match=FeynFacet`MatchPhysicalBoundaryCoefficients[primary,g,physical,
 "KnownAmplitudeRows"->knownRows,"GenericRankWitness"->Lookup[spec,"GenericRankWitness",eps->1/97]];
If[FailureQ[match],Print["FAILED ",match];Exit[1]];
initial=Join[knownRows,Lookup[match["HomogeneousAmplitudeRelations"],"AmplitudeRow",{}]];
identities=FeynFacet`ReduceIdenticalBoundaryIntegrals[match,physical,eps,
 "InitialAmplitudeRows"->initial,"GenericRankWitness"->Lookup[spec,"GenericRankWitness",eps->1/97]];
If[FailureQ[identities],Print["FAILED ",identities];Exit[1]];
atomic[<|"OriginalIntegralDefinitions"->definitions,"PhysicalBoundaryIntegralDefinitions"->physical,
 "UnresolvedIntegralLimits"->rejected|>,output<>"/physical_coefficient_definitions.wxf"];
atomic[match,output<>"/physical_coefficient_equations.wxf"];
atomic[identities,output<>"/identical_integral_relations.wxf"];
report=<|"ConstructedPhysicalCoefficients"->Length[physical],"UnresolvedIntegralLimits"->Length[rejected],
 "HomogeneousRelationCount"->Length[match["HomogeneousAmplitudeRelations"]],
 "IdenticalIntegralRelationCount"->Length[identities["AmplitudeRelations"]],
 "EquationRankIncludingKnownRows"->identities["RankIncludingInitialRows"],
 "Scope"->"Constructed physical coefficients only; region completeness and all boundary values are not asserted."|>;
atomic[report,output<>"/physical_coefficient_report.wxf"];
Print["PASS PHYSICAL COEFFICIENT CONSTRUCTION ",report];Exit[0];
