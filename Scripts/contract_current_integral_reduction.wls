Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
args=Rest[$ScriptCommandLine];
If[Length[args]=!=3,Print["Usage: contract_current_integral_reduction.wls INPUT.wl REDUCTION.wl OUTPUT.wl"];Exit[2]];
{inputFile,reductionFile,outputFile}=ExpandFileName/@args;
input=FeynFacet`FamilyArtifactRead[inputFile];reduction=FeynFacet`FamilyArtifactRead[reductionFile];
If[!AllTrue[{input,reduction},AssociationQ]||!TrueQ[Lookup[reduction,"AllTargetsInPreferredSpan",False]],
 Print["Complete source coefficients and exact closed reduction required"];Exit[1]];
finalBasis=Lookup[Lookup[reduction,"FinalBasisReduction",reduction],"Masters"];
weighted=<||>;requests=<||>;partsByRow=<||>;parts={};groups=<||>;sourceCards=<||>;parentCards=<||>;
Do[
 pieces=StringSplit[label,"/"];If[Length[pieces]<5,Print["Structured current source label required"];Exit[1]];
 {project,order,channel,contribution}=Take[pieces,4];structure=StringRiffle[Drop[pieces,4],"/"];
 key=StringRiffle[Join[Take[pieces,3],{structure}],"/"];
 directory=FileNameJoin[{root,"Projects",project,"Raw",order,channel}];
 card=FeynFacet`ReadContributionCard[directory,contribution];If[!AssociationQ[card],Print[card];Exit[1]];
 AssociateTo[sourceCards,StringRiffle[Take[pieces,4],"/"]->card];
 parentName=First[StringSplit[contribution,"."]];parentKey=StringRiffle[Join[Take[pieces,3],{parentName}],"/"];
 If[!KeyExistsQ[parentCards,parentKey],AssociateTo[parentCards,parentKey->FeynFacet`ReadContributionCard[directory,parentName]]];
 weight=card["Assembly"]["CurrentNormalization"]Lookup[card,"SymmetryFactor",1]Lookup[card,"FlavorMultiplicity",1];
 AssociateTo[weighted,label->Map[weight #&,input["Coefficients"][label]]];
 AssociateTo[groups,key->Append[Lookup[groups,key,{}],label]];
 AssociateTo[requests,key-><|"CouplingRules"->card["Assembly"]["BareCouplingRules"],
  "ColorRules"->Lookup[card,"ColorRules",{}],"DimensionalRegulator"->Global`Epsilon|>],
{label,Keys[input["Coefficients"]]}];
physical=<||>;timings=<||>;requirements=<||>;
mergedRows=AssociationMap[Merge[Lookup[weighted,groups[#]],Total]&,Keys[groups]];
Print["CONTRACTING SHARED REDUCTION FOR ",Length[mergedRows]," PHYSICAL ROWS"];
{contractionSeconds,answer}=AbsoluteTiming[FeynFacet`ApplyIntegralReduction[mergedRows,reduction]];
If[!AssociationQ[answer],Print[answer];Exit[1]];
Do[
 coeff=answer[key];e=requests[key]["DimensionalRegulator"];
 {seconds,coeff}=AbsoluteTiming[
  Map[FeynFacet`SubstituteScalarPowers[#,requests[key]["CouplingRules"]]/.requests[key]["ColorRules"]/.D->4-2e&,coeff]];
 AssociateTo[physical,key->coeff];AssociateTo[timings,key->seconds];
 AssociateTo[requirements,key->Map[FeynFacet`DetermineMeromorphicLaurentLowerBound[#,e]&,coeff]];
 Print["CONTRACTED ",key," MASTERS ",Length[coeff]," NORMALIZATION SECONDS ",seconds],
{key,Keys[groups]}];
output=<|"Format"->"FeynFacet-CurrentMasterIntegralCoefficients","Coefficients"->physical,
 "MasterIntegralBasis"->finalBasis,"DimensionalRegulator"->Global`Epsilon,
 "CoefficientLaurentLowerBounds"->Association[Normal[requirements]],"SourceGroups"->KeyTake[groups,Keys[physical]],
 "Normalization"->"Physical current normalization, component symmetry and flavor multiplicities, declared bare coupling conversion; phase-space measure remains in each typed master.",
 "Complete"->(Length[physical]===Length[groups]),"SourceIntegralDefinitions"->input["Families"],
 "SourceContributionCards"->sourceCards,"ParentContributionCards"->parentCards,"SourceProcessDefinitions"->input["SourceProcessDefinitions"],
 "ReductionFile"->reductionFile,"InputFile"->inputFile,"SharedReductionContractionSeconds"->contractionSeconds,
 "NormalizationSecondsByRow"->timings,
 "ExternalEndpointUniformityEstablished"->False|>;
If[FeynFacet`FamilyArtifactWrite[output,outputFile,Compression->Automatic]=!=outputFile,
 Print["Required physical coefficient output could not be written"];Exit[1]];
Print["COMPLETED ",outputFile];
