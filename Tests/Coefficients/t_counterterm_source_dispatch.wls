Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
Get[root<>"/Tests/Support/CountertermComparison.wl"];
temp=CreateDirectory[];passed=0;failed=0;report=<||>;
check[name_,v_]:=If[TrueQ[v],passed++;Print["PASS ",name],failed++;Print["FAIL ",name]];
Do[
 {project,name}=case;
 directory=FileNameJoin[{root,"Projects",project,"Raw","NNLO","q-q"}];
 card=FeynFacet`ReadContributionCard[directory,name,"q-q"];
 local=FileNameJoin[{temp,project,"Raw","NNLO","q-q",name}];CreateDirectory[local,CreateIntermediateDirectories->True];
 card=Join[card,<|"Directory"->DirectoryName[local],"ContributionDirectory"->local,
   "WorkDirectory"->local<>"/Work","ResultFile"->local<>"/Results.wl",
   "Execution"-><|"Kernels"->1,"KiraThreads"->1,"ReconstructionThreads"->1|>|>];
 {seconds,audit}=AbsoluteTiming[FeynFacet`WithEpsilonRemainderChecks[FeynFacet`ConstructCountertermContribution[card]]];
 value=If[AssociationQ[audit],audit["Result"],audit];
 Print["RESULT ",project," ",name," ",Head[value]," SECONDS ",seconds];
 If[!AssociationQ[value],Print[value]];
 check[name<>" result",AssociationQ[value]];
 If[AssociationQ[value],
  check[name<>" source owner",AllTrue[Values[value["GeneratedSources"]],StringStartsQ[#["File"],local<>"/Work/Sources/"]&]];
  check[name<>" no lower source directory",!DirectoryQ[FileNameJoin[{temp,project,"LO"}]]&&!DirectoryQ[FileNameJoin[{temp,project,"NLO"}]]];
  check[name<>" exact epsilon output",FreeQ[value["Coefficients"],_Integrate|_Inactive|_SeriesData|_Failure]];
  check[name<>" declared epsilon range",value["EpsilonRange"]===card["EpsilonRange"]];
  check[name<>" contribution card",value["ContributionCard"]["CardName"]===name];
  If[card["SourceRenormalizationStage"]==="Renormalized",
   changed=card;
   changed["OperatorInsertions"]={Join[First[card["OperatorInsertions"]],
     <|"Incoming"->Join[First[card["OperatorInsertions"]]["Incoming"],<|"ScaleLog"->1|>]|>]};
   alternate=FeynFacet`ConstructCountertermContribution[changed];
   check["finite per-insertion scale override applied",AssociationQ[alternate]&&alternate["Coefficients"]=!=value["Coefficients"]];
   axis=card["Assembly"]["FactorizationLegs"]["Incoming"]["Variable"];
   customScheme=<|"DefaultScheme"->"MSbar","FiniteKernelsByOrder"-><|2-><|
     {{"q","u"},{"q","u"},"L"}-><|"Variable"->axis,"DeltaCoefficient"->lambda,
       "PlusCoefficients"-><||>,"RegularCoefficient"->0|>|>|>|>;
   changed=card;changed["OperatorInsertions"]={<|"Incoming"->Join[
     First[card["OperatorInsertions"]]["Incoming"],<|"OperatorRedefinition"->customScheme|>]|>};
   alternate=FeynFacet`ConstructCountertermContribution[changed];
   born=FeynFacet`ReadPartonicResult[First[Values[value["GeneratedSources"]]]["File"]];
   expected=FeynFacet`CreatePartonicResult[
     Map[FeynFacet`Private`partonicMap[Function[s,-(card["Counterterms"]["Coupling"]/(2Pi))^2 lambda s],#]&,
       KeyTake[born["Coefficients"],{0}]],KeyDrop[alternate,{"Coefficients","EpsilonRange"}]];
   comparison=If[AssociationQ[alternate]&&AssociationQ[expected],
     FTCountertermComparison`CompareResults[expected,alternate,<|"EpsilonRange"->{0,0},
       "ParameterRules"->card["ColorRules"],"Assumptions"->card["Assembly"]["Assumptions"]|>],<|"Passed"->False|>];
   check["finite order-two custom delta equals minus a squared lambda Born",TrueQ[comparison["Passed"]]]]];


 AssociateTo[report,name-><|"Seconds"->seconds,"ResultHead"->Head[value],"Result"->value,"Audit"->audit|>],
{case,{{"SIDIS_UU","Counter-Born-PDF2"},{"SIDIS_LL","Counter-Born-PDF2-Finite"}}}];
out=Environment["FEYNFACET_TEST_OUTPUT"];
If[StringQ[out]&&out=!="",FeynFacet`FamilyArtifactWrite[report,out<>"/ConcreteNNLOChecks.wl",Compression->Automatic]];
Print["COMPLETED CONCRETE COUNTERTERM CHECKS ",passed," PASSED ",failed," FAILED"];
Print[passed+failed," assertions, ",failed," failed"];
Print["------------------------------------------------"];
DeleteDirectory[temp,DeleteContents->True];Exit[Boole[failed>0]];
