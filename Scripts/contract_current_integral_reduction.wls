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
weighted=<||>;requests=<||>;partsByRow=<||>;parts={};groups=<||>;
Do[
 pieces=StringSplit[label,"/"];If[Length[pieces]<5,Print["Structured current source label required"];Exit[1]];
 {project,order,channel,contribution}=Take[pieces,4];structure=StringRiffle[Drop[pieces,4],"/"];
 key=StringRiffle[Join[Take[pieces,3],{structure}],"/"];
 directory=FileNameJoin[{root,"Projects",project,order,channel}];
 card=FeynFacet`ReadContributionCard[directory,contribution];If[!AssociationQ[card],Print[card];Exit[1]];
 weight=card["Assembly"]["CurrentNormalization"]Lookup[card,"SymmetryFactor",1]Lookup[card,"FlavorMultiplicity",1];
 AssociateTo[weighted,label->Map[weight #&,input["Coefficients"][label]]];
 AssociateTo[groups,key->Append[Lookup[groups,key,{}],label]];
 AssociateTo[requests,key-><|"CouplingRules"->card["Assembly"]["BareCouplingRules"],
  "ColorRules"->Lookup[card,"ColorRules",{}],"DimensionalRegulator"->Global`Epsilon|>],
{label,Keys[input["Coefficients"]]}];
physical=<||>;timings=<||>;requirements=<||>;
Do[
 merged=Merge[Lookup[weighted,groups[key]],Total];
 Print["CONTRACTING ",key," TARGETS ",Length[merged]];
 {seconds,answer}=AbsoluteTiming[FeynFacet`ApplyIntegralReduction[<|key->merged|>,reduction]];
 If[!AssociationQ[answer],Print[answer];Exit[1]];
 coeff=answer[key];e=requests[key]["DimensionalRegulator"];
 coeff=Map[FeynFacet`SubstituteScalarPowers[#,requests[key]["CouplingRules"]]/.requests[key]["ColorRules"]/.D->4-2e&,coeff];
 AssociateTo[physical,key->coeff];AssociateTo[timings,key->seconds];
 AssociateTo[requirements,key->Map[FeynFacet`DetermineMeromorphicLaurentLowerBound[#,e]&,coeff]];
 output=<|"Format"->"FeynFacet-CurrentMasterIntegralCoefficients","Coefficients"->physical,
 "MasterIntegralBasis"->finalBasis,"DimensionalRegulator"->Global`Epsilon,
 "CoefficientLaurentLowerBounds"->Association[Normal[requirements]],"SourceGroups"->KeyTake[groups,Keys[physical]],
 "Normalization"->"Physical current normalization, component symmetry and flavor multiplicities, declared bare coupling conversion; phase-space measure remains in each typed master.",
 "Complete"->(Length[physical]===Length[groups]),"SourceIntegralDefinitions"->input["Families"],
 "ReductionFile"->reductionFile,"InputFile"->inputFile,"SecondsByRow"->timings,
 "ExternalEndpointUniformityEstablished"->False|>;
 FeynFacet`FamilyArtifactWrite[output,outputFile,Compression->Automatic];
 Print["CONTRACTED ",key," MASTERS ",Length[coeff]," SECONDS ",seconds],
{key,Keys[groups]}];
Print["COMPLETED ",outputFile];
