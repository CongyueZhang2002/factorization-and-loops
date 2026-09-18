Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
card=FeynFacet`ReadContributionCard[root<>"/Projects/SIDIS_UU/Raw/NNLO/q-q","DoubleReal"];
definition=FeynFacet`ContributionIntegrationDefinition[card];
temp=CreateDirectory[];
labels=card["StructureFunctions"];
bulk=Join[FeynFacet`ExpandLaurentCoefficientVector[{11,22},ee,{{0,0},{0,0}}],
 <|"CoefficientRowLabels"->Reverse[labels]|>];
face=FeynFacet`ExpandLaurentCoefficientVector[{33,44},ee,{{0,0},{0,0}}];
profiles=<|"DimensionalRegulator"->ee,"NormalVariables"->{rx,rz},
 "CoefficientRowLabels"->labels,"ProfileGroups"->{<|"Powers"->{-1+ee,-1+ee},
 "FaceSeries"-><|{1}->face|>|>}|>;
selection=<|"SourceRowLabels"->labels,"BulkCoordinates"->"Endpoint","BulkToEndpointRules"->{}|>;
bundle=FeynFacet`CreateEndpointIntegrationInput[card,definition["Processes"],bulk,profiles,<||>,selection];
inputFile=temp<>"/Input.wxf";FeynFacet`FamilyArtifactWrite[bundle,inputFile];
inputs=<|"Method"->"EndpointProfiles","IntegrationInputFile"->inputFile|>;
bind[other_,defs_:Automatic]:=FeynFacet`CreateContributionIntegrationPlan[card,other,
 If[defs===Automatic,FeynFacet`ContributionIntegrationDefinition[other]["Processes"],defs],inputs];
FTTest`FTAssert["identical amplitude and integration inputs may be bound to solved coefficients",AssociationQ[bind[card]]];
moved=Join[card,<|"Project"->"Renamed","Directory"->"/different/location","Execution"-><|"Kernels"->1|>|>];
FTTest`FTAssert["project names, directories and CPU allocation do not change a solved integral",AssociationQ[bind[moved]]];
changed=Join[card,<|"Assembly"->Join[card["Assembly"],<|"CurrentNormalization"->2 card["Assembly"]["CurrentNormalization"]|>]|>];
FTTest`FTAssert["a changed current normalization invalidates the solved input binding",FailureQ[bind[changed]]];
changed=Join[card,<|"Assembly"->Join[card["Assembly"],<|"MeasuredPhaseSpace"->
 Join[card["Assembly"]["MeasuredPhaseSpace"],<|"MeasurementVariable"->differentMeasurement|>]|>]|>];
FTTest`FTAssert["a changed measurement cannot reuse the same solved integral coefficients",FailureQ[bind[changed]]];
changed=Join[card,<|"Components"->Join[card["Components"],<|"Gluons"->Join[card["Components"]["Gluons"],<|"SymmetryFactor"->1|>]|>]|>];
FTTest`FTAssert["a different component multiplicity invalidates the binding",FailureQ[bind[changed]]];
defs=definition["Processes"];
key=First[Keys[defs]];
defs[key]=Join[defs[key],<|"ForwardAmplitudes"->Join[defs[key]["ForwardAmplitudes"],<|"DiagramIndices"->{1}|>]|>];
FTTest`FTAssert["a selected diagram subset cannot masquerade as the complete source",FailureQ[bind[card,defs]]];
proc=definition["Processes"]["SameFlavor"];
renamed=proc/.{"qb","u"}->{"antiquark","u"};
species=Join[card["SpeciesMap"],<|{"antiquark","u"}->card["SpeciesMap"][{"qb","u"}]|>];
FTTest`FTAssert["species spellings compare through their declared model fields",
 FeynFacet`Private`projectIntegratedProcessIdentity[proc,card["SpeciesMap"]]===
 FeynFacet`Private`projectIntegratedProcessIdentity[renamed,species]];
species=Join[species,<|{"antiquark","u"}->card["SpeciesMap"][{"qb","d"}]|>];
FTTest`FTAssert["the same spelling mapped to a different physical flavor is rejected",
 FeynFacet`Private`projectIntegratedProcessIdentity[proc,card["SpeciesMap"]]=!=
 FeynFacet`Private`projectIntegratedProcessIdentity[renamed,species]];
FTTest`FTAssert["NNLO amplitude coverage follows the channel's lowest nonzero order",
 Table[FeynFacet`Private`projectRequiredBareContributionTypes[
  <|"MinimumChannelOrders"-><|"c"->i|>|>,"NNLO","c"],{i,0,2}]===
 {{"DoubleReal","RealVirtual","DoubleVirtual"},{"DoubleReal","RealVirtual"},{"DoubleReal"}}];
FTTest`FTAssert["a solved-input plan must identify the explicit endpoint coefficients",
 FailureQ[FeynFacet`CreateContributionIntegrationPlan[card,card,definition["Processes"],KeyDrop[inputs,"IntegrationInputFile"]]]];
FTTest`FTAssert["coupling degree is obtained without combining the independent kinematic functions",
 FeynFacet`Private`projectCouplingDegree[a^2 (Log[u]/(1-v)+PolyLog[2,v])+a^2/(u-v)^2,a]===2];
FTTest`FTAssert["a wrong explicit coupling order is not accepted by the structural check",
 FeynFacet`Private`projectCouplingDegree[a^3 Log[u],a]=!=2];
FTTest`FTAssert["mixed coupling degrees require the exact rational fallback",
 !IntegerQ[FeynFacet`Private`projectCouplingDegree[(a^2+a^3)/(1+a),a]]&&
 FreeQ[Cancel[(a^2+a^3)/(1+a)/a^2],a]];

FTTest`FTAssert["bulk and endpoint rows are selected independently by their actual labels",
 AssociationQ[bundle]&&bundle["Bulk"]["Coefficients"][{1,0}]===22&&
 bundle["EndpointProfiles"]["ProfileGroups"][[1]]["FaceSeries"][{1}]["Coefficients"][{1,0}]===33];
FTTest`FTAssert["missing labels cannot be inferred from another coefficient file",
 FailureQ[FeynFacet`CreateEndpointIntegrationInput[card,definition["Processes"],
 KeyDrop[bulk,"CoefficientRowLabels"],profiles,<||>,selection]]];
wrongBundle=Join[bundle,<|"IntegrationDefinition"->Join[bundle["IntegrationDefinition"],<|"Order"->"NLO"|>]|>];
FeynFacet`FamilyArtifactWrite[wrongBundle,inputFile];
FTTest`FTAssert["a correct plan description cannot accept a different saved integration input",
 FailureQ[bind[card]]];
FeynFacet`FamilyArtifactWrite[bundle,inputFile];
wrongBundle=Join[bundle,<|"BulkCoordinates"->"Physical","BulkToEndpointRules"->{}|>];
FeynFacet`FamilyArtifactWrite[wrongBundle,inputFile];
FTTest`FTAssert["saved coordinate conventions are checked against the physical distribution axes",
 FailureQ[bind[card]]];

FeynFacet`FamilyArtifactWrite[bundle,inputFile];
relativeCard=Join[card,<|"WorkDirectory"->temp|>];
relativePlan=FeynFacet`CreateContributionIntegrationPlan[relativeCard,card,definition["Processes"],
 <|"Method"->"EndpointProfiles","IntegrationInputFile"->"Input.wxf"|>];
FTTest`FTAssert["relative input paths are resolved once against the contribution Work directory",
 AssociationQ[relativePlan]&&relativePlan["IntegrationInputFile"]===inputFile];
axes=definition["AssemblyRequest"]["DistributionBasis"]["Axes"];
badAxes=Prepend[Rest[axes],Join[First[axes],<|"Distance"->(1-First[axes]["Variable"])^2|>]];
FTTest`FTAssert["unsupported nonlinear endpoint charts are refused rather than assigned a branch",
 FailureQ[Catch[FeynFacet`Private`projectCheckUnitEndpointAxes[badAxes],"ProjectCards"]]];

DeleteDirectory[temp,DeleteContents->True];
FTTest`FTReport[];
