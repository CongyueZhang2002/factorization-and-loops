
#!/usr/bin/env wolframscript
(* INPUT.wl supplies the campaign, topology registry, normalizations and
   physical boundary chart. No process or family is selected in this driver. *)
$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[FileNameJoin[{root,"Addon","Load","LoadFACET.wl"}]]];
args=Rest[$ScriptCommandLine];
If[Length[args]=!=2,Print["Expected INPUT.wl OUTPUT_DIRECTORY"];Exit[2]];
inputFile=ExpandFileName[args[[1]]];output=ExpandFileName[args[[2]]];
input=FamilyArtifactRead[inputFile];
resolve[p_]:=ExpandFileName[If[StringStartsQ[p,"/"],p,FileNameJoin[{DirectoryName[inputFile],p}]]];
save[data_,path_]:=Module[{temp=path<>".partial-"<>ToString[$ProcessID],stream},
 If[!DirectoryQ[DirectoryName[path]],CreateDirectory[DirectoryName[path],CreateIntermediateDirectories->True]];
 stream=OpenWrite[temp,BinaryFormat->True];
 BinaryWrite[stream,Normal[BinarySerialize[data,PerformanceGoal->"Size"]],"Byte"];Close[stream];
 RenameFile[temp,path,OverwriteTarget->True];path];
fail[tag_,data_:<||>]:=(Print["FAILED ",tag," ",data];Exit[1]);
campaign=resolve[input["CampaignDirectory"]];
registry=Import[resolve[input["CanonicalRegistryFile"]],"WXF"]["Registry"]["Families"];
manifest=FamilyArtifactRead[resolve[input["ReductionManifestFile"]]];
files=Sort@FileNames["solution.wxf",campaign,3];
solutions=<||>;destinations=<||>;
Do[sol=Import[file,"WXF"];family=ToString[sol["Family"]];
 AssociateTo[solutions,family->sol];AssociateTo[destinations,family->file],{file,files}];
systems=FamilyArtifactRead/@Sort@FileNames["FamilyDifferentialSystem.wl",campaign,2];
If[Length[files]=!=Length[solutions]||Length[solutions]=!=Length[systems]||Length[solutions]===0,fail["FamilyCoverageMismatch"]];
If[AnyTrue[Values[solutions],KeyExistsQ[#,"BoundaryBasis"]&],fail["InputSolutionsAlreadyUseASharedBoundaryBasis"]];
allMasters=Flatten[Lookup[systems,"OriginalMasterIntegralBasis"]];
requested=DeleteDuplicates@Flatten[Map[Function[s,
 s["OriginalMasterIntegralBasis"][[s["RequestedRows"]]]],Values[solutions]]];
timings=<||>;
timings["IntegralEquivalences"]=First@AbsoluteTiming[
 equiv=FindCutIntegralEquivalences[allMasters,registry,
  "PreferredMasterIntegrals"->manifest["Masters"],"Normalization"->input["IntegralNormalization"]]];
If[FailureQ[equiv],fail["IntegralEquivalences",equiv]];
timings["GlobalDifferentialSystem"]=First@AbsoluteTiming[
 global=ConstructGlobalMasterDifferentialSystem[systems,equiv,
  "PreferredMasterIntegrals"->manifest["Masters"]]];
If[FailureQ[global],fail["GlobalDifferentialSystem",global]];
timings["RequestedDifferentialSystem"]=First@AbsoluteTiming[
 sub=ConstructRequestedMasterDifferentialSystem[global,requested]];
If[FailureQ[sub],fail["RequestedDifferentialSystem",sub]];
timings["ExplicitBoundarySubstitution"]=First@AbsoluteTiming[
 reduced=ReduceMasterIntegralSolutionConstants[solutions,global]];
If[FailureQ[reduced],fail["ExplicitBoundarySubstitution",reduced]];
Print["Finite boundary substitutions computed for ",Length[solutions]," families."];
timings["PhysicalBoundaryBound"]=First@AbsoluteTiming[
 limits=ConstructHomogeneousBlockLimits[sub,input["BoundaryChart"]];
 If[FailureQ[limits],fail["BoundaryLimits",limits]];
 condition=DetermineThreeParticlePhaseSpaceScaling[sub,registry,
  input["BoundaryKinematicRules"],input["PhaseSpaceNormalization"]];
 If[FailureQ[condition],fail["ScalingEligibility",condition]];
 bound=BoundBoundaryDataByScaling[limits,condition,input["ObservationPoint"]];
 If[FailureQ[bound],fail["BoundaryDimensionBound",bound]]];

(* Replace a counted one-dimensional source sector by its known exact value.
   Do not subtract a list of anchors without checking their block role. *)
anchors={};
Do[
 sourceRow=known["BoundaryIndex"];
 localRow=FirstPosition[sub["SourceMasterRows"],sourceRow,None];
 If[localRow===None,Continue[]];localRow=First[localRow];
 block=SelectFirst[bound["Blocks"],MemberQ[#["Rows"],localRow]&,None];
 If[block===None||block["Rows"]=!={localRow}||
   block["RetainedHomogeneousDimensionBound"]=!=1,Continue[]];
 independent=AllTrue[sub["ConnectionMatrices"],Function[m,
  AllTrue[Delete[Normal[m][[localRow]],localRow],FeynFacet`Private`globalDEZeroQ]]];
 value=Simplify[known["ExactValue"]/.known["DimensionalRegulator"]->0];
 If[TrueQ[independent]&&TrueQ[Abs[value]>0],
  AppendTo[anchors,<|"Row"->localRow,"MasterIntegral"->known["MasterIntegral"],
   "ExactValue"->known["ExactValue"],"NonzeroLeadingValue"->value,
   "Reason"->"Known scalar source sector with no lower-sector dependence."|>]],
 {known,reduced["KnownBoundaryValues"]}];
anchors=DeleteDuplicatesBy[anchors,#["Row"]&];
bound=Join[bound,<|"KnownScalarAnchors"->anchors,
 "KnownScalarAnchorCount"->Length[anchors],
 "UnknownBoundarySeriesUpperBound"->bound["RemainingDimensionUpperBound"]-Length[anchors]|>];
If[!DirectoryQ[output],CreateDirectory[output,CreateIntermediateDirectories->True]];
save[equiv,FileNameJoin[{output,"CutIntegralEquivalences.wxf"}]];
save[global,FileNameJoin[{output,"GlobalDifferentialSystem.wxf"}]];
save[sub,FileNameJoin[{output,"RequestedDifferentialSystem.wxf"}]];
save[limits,FileNameJoin[{output,"RecoilMassLimits.wxf"}]];
save[bound,FileNameJoin[{output,"BoundaryDimensionBound.wxf"}]];
requirements=Join[KeyDrop[reduced,"Solutions"],<|
 "SourceCampaign"->campaign,
 "UnknownBoundarySeriesUpperBound"->bound["UnknownBoundarySeriesUpperBound"],
 "SingularBoundaryMatchingApplied"->False,
 "MinimalNewBoundaryIntegralCount"->Missing["NotDetermined"]|>];
save[requirements,FileNameJoin[{output,"SharedBoundaryRequirements.wxf"}]];
counts={}; totalBytes=0;
Do[
 data=reduced["Solutions"][family];
 destination=If[TrueQ[Lookup[input,"ReplaceSourceSolutions",False]],
  destinations[family],FileNameJoin[{output,"Solutions",family,"solution.wxf"}]];
 save[data,destination];bytes=FileByteCount[destination];totalBytes+=bytes;
 AppendTo[counts,<|"Family"->family,"Path"->destination,
  "Bytes"->bytes,"RequiredSharedSeries"->Length[Union[First/@data["RequiredInitialConstantCoefficients"]]],
  "RequiredSharedCoefficients"->Length[data["RequiredInitialConstantCoefficients"]]|>],
 {family,Keys[solutions]}];
summary=<|"FamilyCount"->Length[solutions],"RequestedMasterCount"->Length[requested],
 "OriginalClosedMasterPositions"->Length[allMasters],
 "ExactIntegralEquivalenceClasses"->equiv["EquivalenceClassCount"],
 "OverlapRelations"->global["IndependentRelationCount"],
 "GlobalSpanningDimension"->global["GlobalSpanningMasterCount"],
 "RequestedClosedDimension"->sub["Dimension"],
 "SharedUnknownBoundarySeries"->reduced["RequiredBoundarySeriesCount"],
 "SharedUnknownLaurentCoefficients"->reduced["RequiredLaurentCoefficientCount"],
 "PhysicalSeriesUpperBoundBeforeKnownAnchors"->bound["RemainingDimensionUpperBound"],
 "KnownScalarAnchors"->Length[anchors],
 "PhysicalUnknownSeriesUpperBound"->bound["UnknownBoundarySeriesUpperBound"],
 "SingularMatchingAppliedToFiniteSolutions"->False,
 "FiniteSolutionBytes"->totalBytes,"TimingsSeconds"->timings,"Families"->counts|>;
Export[FileNameJoin[{output,"summary.json"}],summary,"RawJSON"];
Print["COMPLETE ",KeyDrop[summary,"Families"]];
