Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];Get[root<>"/FeynFacet/Solution.m"];$PrePrint=.;
args=Rest[$ScriptCommandLine];
If[Length[args]=!=4,Print["Usage: construct_ordered_endpoint_profiles.wls COEFFICIENTS BOUNDARY BULK OUTPUT_DIRECTORY"];Exit[2]];
{coefficientFile,boundaryFile,bulkFile,out}=ExpandFileName/@args;
coefficient=FeynFacet`FamilyArtifactRead[coefficientFile];
ordered=FeynFacet`FamilyArtifactRead[boundaryFile];
bulk=FeynFacet`FamilyArtifactRead[bulkFile];
If[!DirectoryQ[out],CreateDirectory[out,CreateIntermediateDirectories->True]];
save[value_,name_]:=Module[{file=out<>"/"<>name<>".wl",written},
 written=FeynFacet`FamilyArtifactWrite[value,file,Compression->Automatic];
 If[written=!=file,Print["Required endpoint artifact write failed: ",file];Exit[1]];written];
check[value_,stage_]:=If[!AssociationQ[value],save[value,stage<>"Failure"];Print["FAILED ",stage," ",InputForm[value]];Exit[1]];
check[coefficient,"Coefficients"];check[ordered,"Boundary"];check[bulk,"Bulk"];
If[!TrueQ[coefficient["Complete"]]||bulk["EpsilonRemainderAudit"]["Status"]=!="Passed",Print["Complete audited coefficients required"];Exit[1]];
parentCards=coefficient["ParentContributionCards"];
If[!AssociationQ[parentCards]||parentCards===<||>,Print["Original source contribution cards required"];Exit[1]];
target=Max[Last[#["EpsilonRange"]]&/@Values[parentCards]];
lower=Min[First[#["EpsilonRange"]]&/@Values[parentCards]];
firstCard=First[Values[parentCards]];
boundaryRequest=firstCard["Assembly"]["MasterIntegration"]["Boundary"];
{rho,z,sigma,e}=Lookup[ordered,{"RecoilVariable","MeasurementVariable","MeasurementEndpointVariable","DimensionalRegulator"}];
rules=Join[boundaryRequest["RecoilSubstitution"],{z->1-sigma}];
axes=firstCard["Assembly"]["DistributionBasis"]["Axes"];
coordinateCheck=Catch[FeynFacet`Private`projectCheckUnitEndpointAxes[axes];True,"ProjectCards"];
If[coordinateCheck=!=True||Length[axes]=!=2||
 !And@@MapThread[Cancel[#1-#2]===0&,{Lookup[axes,"Distance"]/.rules,{rho,sigma}}],
 Print["The direct endpoint producer requires the declared independent unit distances in boundary order"];Exit[1]];

binding=FeynFacet`RequireMatchingEndpointDensity[coefficient,ordered,bulk["Result"],rules];
If[binding=!=True,Print[binding];Exit[1]];
Do[
 sourceAxes=sourceCard["Assembly"]["DistributionBasis"]["Axes"];
 sourceSupport=Lookup[Lookup[sourceCard["Assembly"],"EndpointExpansion",<||>],"TestFunctionSupport",<||>];
 excluded=Lookup[sourceSupport,"ExcludedFaces",{}]/.Thread[Lookup[sourceAxes,"NormalVariable"]->{rho,sigma}];
 If[!ContainsAll[excluded,{rho->1,sigma->1}],
  Print["Opposite endpoint profiles or explicit excluded support required"];Exit[1]],
{sourceCard,Values[parentCards]}];
request=<|"KinematicRules"->rules,"Assumptions"->(firstCard["Assembly"]["Assumptions"]/.rules),
 "TestFunctionSupport"-><|"ExcludedFaces"->{rho->1,sigma->1}|>|>;
request=Join[request,<|"ProgressFunction"->Function[stage,Print["ENDPOINT STEP ",stage]],
 "ArtifactFunction"->Function[{value,name},save[value,name]]|>];
(* Establish the same joint meromorphic continuation from every original
   prescribed source, before partial fractions. The typed source supplies
   measurement geometry; the declared recoil endpoint supplies the interval. *)
sourceCertificates=<||>;sourceVariable=boundaryRequest["RecoilSourceVariable"];
lowerLimit=Unique["externalLower"];
Do[
 sourceCard=parentCards[key];parts=StringSplit[key,"/"];
 directory=FileNameJoin[{root,"Projects",parts[[1]],"Raw",parts[[2]],parts[[3]]}];
 componentNames=Keys[Lookup[sourceCard,"Components",<||>]];
 contributionNames=If[componentNames==={}, {parts[[4]]},(parts[[4]]<>"."<>#)&/@componentNames];
 Do[
  componentCard=FeynFacet`ReadContributionCard[directory,componentName];
  sourceRecord=FeynFacet`FamilyArtifactRead[componentCard["WorkDirectory"]<>"/PreparedIntegrands.wl"];
  check[sourceRecord,"PrescribedSource"];
  sourceDefinitionKey=key<>StringDrop[componentName,StringLength[parts[[4]]]];
  If[Lookup[sourceRecord,"ProcessDefinition",None]=!=
    Lookup[coefficient["SourceProcessDefinitions"],sourceDefinitionKey,Missing["SourceDefinition"]],
   Print["Prepared source does not match the exact definition bound to the reduced density"];Exit[1]];
  Do[
   originalSource=sourceRecord["Values"][sourceLabel];definition=originalSource["SourceDefinition"];
   sourceGeometry=Join[KeyTake[definition,{"MeasurementVariable","ReferenceMomentum","TaggedMomentum"}],
    componentCard["Assembly"]["MeasuredPhaseSpace"]];
   certificate=FeynFacet`CertifyOrdinaryPrescriptionRemoval[originalSource,Automatic,
    Join[sourceGeometry,<|"JointExternalDomain"-><|
     "ExternalIntervals"-><|sourceVariable->{lowerLimit,1}|>,
     "Assumptions"->(firstCard["Assembly"]["Assumptions"]&&0<lowerLimit<1),
     "TimeDirection"->(definition["TimeDirection"]+sourceGeometry["ReferenceMomentum"])|>|>]];
   check[certificate,"JointSourceContinuation"];
   If[FeynFacet`RequireOrdinaryPrescriptionCertificate[certificate,"EndpointDistributions"]=!=True,
    Print["Joint prescribed source continuation required"];Exit[1]];
   AssociateTo[sourceCertificates,{key,componentName,sourceLabel}->certificate],
  {sourceLabel,Keys[sourceRecord["Values"]]}],
 {componentName,contributionNames}],
{key,Keys[parentCards]}];
save[sourceCertificates,"SourceContinuation"];
Print["JOINT SOURCE CONTINUATION ",Length[sourceCertificates]," STRUCTURE FUNCTIONS"];

{seconds,prepared}=AbsoluteTiming[
 result=FeynFacet`PrepareOrderedEndpointProfiles[ordered,coefficient["Coefficients"],request];
 If[FailureQ[result],
  Print["RESOLVING ENDPOINT GEOMETRY ",result[[1]]];
  result=FeynFacet`PrepareResolvedEndpointProfiles[ordered,coefficient["Coefficients"],request]];
 result];
check[prepared,"ProfilePreparation"];
prepared=Join[prepared,<|"ProjectionConditions"->Join[prepared["ProjectionConditions"],
 <|"OriginalPrescribedSourceContinuation"->sourceCertificates|>]|>];save[prepared,"Preparation"];
Print["ENDPOINT PREPARATION ",seconds," s"];
faces=<||>;labels=prepared["CoefficientRowLabels"];n=Length[labels];
Do[
 jets=prepared["CoefficientJets"][i];
 If[jets["Status"]==="NoRequestedNormalTerms"||jets["CoefficientMatrices"]===<||>,
  edge=FeynFacet`ExpandLaurentCoefficientVector[ConstantArray[0,n],e,ConstantArray[{lower,target+1},n]],
  {seconds,edge}=AbsoluteTiming[FeynFacet`SolvePhysicalEndpointCoefficientJets[jets,
   <|"IntegerNormalPower"->-1,"ThroughOrder"->target+1,"GPLTimeLimit"->Lookup[firstCard["Assembly"]["MasterIntegration"],"GPLTimeLimit",300],
    "ProgressFunction"->Function[stage,Print["FACE ",i," ",stage]]|>]];
  check[edge,"Face"<>ToString[i]];Print["ENDPOINT FACE ",i," ",seconds," s"]];
 check[edge,"Face"<>ToString[i]];save[edge,"Face"<>ToString[i]];
 AssociateTo[faces,{i}->KeyDrop[edge,{"OrderPreparation"}]],
{i,2}];
cornerValues=prepared["CornerCoefficientMatrix"].prepared["InitialConstantValues"];
cornerLower=FeynFacet`DetermineMeromorphicLaurentLowerBound[#,e]&/@cornerValues;
If[!AllTrue[cornerLower,IntegerQ[#]||#===Infinity&],Print["Finite corner Laurent bounds required"];Exit[1]];
corner=FeynFacet`ExpandLaurentCoefficientVector[cornerValues,e,
 ({Min[lower,#],target+2}&/@cornerLower)];
check[corner,"Corner"];save[corner,"Corner"];AssociateTo[faces,{1,2}->corner];
profiles=<|"DimensionalRegulator"->e,"NormalVariables"->{rho,sigma},"CoefficientRowLabels"->labels,
 "ProfileGroups"->{<|"Powers"->prepared["Powers"],"FaceSeries"->faces|>}|>;
save[profiles,"EndpointProfiles"];save[prepared["ProjectionConditions"],"ProjectionConditions"];
(* Keep all computed Laurent orders. These coefficients are finite expressions,
   so converting their storage representation does not recompute integrals. *)
bulkRows=bulk["Result"]["Rows"];range=bulk["Result"]["EpsilonOrderRange"];
If[Keys[bulkRows]=!=labels,Print["Bulk and boundary row order mismatch"];Exit[1]];
bulkVector=<|"DataType"->"LaurentCoefficientVector","DimensionalRegulator"->e,"Dimension"->n,"CoefficientRowLabels"->labels,
 "StoredOrderRanges"->ConstantArray[range,n],"KnownThroughOrders"->ConstantArray[Last[range],n],
 "LaurentLowerBounds"->Lookup[bulk["Result"]["LaurentLowerBounds"],labels],"ExactTails"->ConstantArray[False,n],
 "Coefficients"->Association@Flatten[Table[
  {i,k}->bulkRows[labels[[i]]]["Coefficients"][k],{i,n},{k,First[range],Last[range]}]]|>;
save[bulkVector,"BulkVector"];
Do[
 sourceCard=parentCards[key];parts=StringSplit[key,"/"];
 directory=FileNameJoin[{root,"Projects",parts[[1]],"Raw",parts[[2]],parts[[3]]}];
 card=FeynFacet`ReadContributionCard[directory,parts[[4]]];check[card,"CurrentContribution"];
 components=Keys[Lookup[sourceCard,"Components",<||>]];
 sourceKeys=If[components==={},{key},(key<>"."<>#)&/@components];
 definitions=AssociationThread[If[components==={}, {parts[[4]]},components],
  Lookup[coefficient["SourceProcessDefinitions"],sourceKeys]];
 sourceLabels=(StringRiffle[Join[Take[parts,3],{#}],"/"]&/@sourceCard["StructureFunctions"]);
 input=FeynFacet`CreateEndpointIntegrationInput[sourceCard,definitions,bulkVector,profiles,prepared["ProjectionConditions"],
  <|"SourceRowLabels"->sourceLabels,"BulkCoordinates"->"Physical","BulkToEndpointRules"->rules|>];
 check[input,"IntegrationInput"];inputFile=sourceCard["WorkDirectory"]<>"/IntegrationInput.wxf";
 If[FeynFacet`FamilyArtifactWrite[input,inputFile]=!=inputFile,
  Print["Required integration input write failed: ",inputFile];Exit[1]];
 plan=FeynFacet`CreateContributionIntegrationPlan[card,sourceCard,definitions,
  <|"Method"->"EndpointProfiles","IntegrationInputFile"->inputFile|>];
 check[plan,"IntegrationPlan"];planFile=card["WorkDirectory"]<>"/IntegrationPlan.wl";
 If[FeynFacet`FamilyArtifactWrite[plan,planFile]=!=planFile,
  Print["Required integration plan write failed: ",planFile];Exit[1]];
 Print["PREPARED ENDPOINT INPUT ",key],
{key,Keys[parentCards]}];
Print["COMPLETED ORDERED ENDPOINT PROFILES ",Length[parentCards]," RAW CONTRIBUTIONS"];
