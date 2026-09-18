Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
ncTemp=CreateDirectory[];
CopyFile[root<>"/Projects/ppHX_TT/Common-Card.wl",ncTemp<>"/Common-Card.wl"];
CreateDirectory[ncTemp<>"/Raw/NLO/qqp-qqp",CreateIntermediateDirectories->True];
ncDirectory=ncTemp<>"/Raw/NLO/qqp-qqp";
ncFinite=<|"FiniteKernels"-><|{{"q","u"},{"q","u"},"T"}->
 <|"Variable"->xi,"DeltaCoefficient"->lambda,"PlusCoefficients"-><||>,"RegularCoefficient"->0|>|>|>;
ncDefinition=<|"Contribution"->"Counterterm","SourceOrder"->"LO","SourceChannel"->"qqp-qqp",
 "SourceRenormalizationStage"->"Renormalized","EpsilonRange"->{0,0},
 "OperatorInsertions"->{<|"IncomingA"-><|"Distribution"->"PDFCounterterm","PerturbativeOrder"->1,
 "Operation"->"FiniteSchemeChange","OperatorRedefinition"->ncFinite|>|>}|>;
ncCard=FeynFacet`CompileCountertermCard[ncDirectory,ncDefinition];
ncSource=FeynFacet`GenerateBornPartonicSources[ncCard,<|"qqp-qqp"->0|>];
ncResult=FeynFacet`ConstructNLOCountertermContribution[ncCard,ncSource["Results"]];
If[!AssociationQ[ncResult],Print[ncResult]];
FTTest`FTAssert["a concrete finite counterterm card uses only the generated epsilon-zero Born source",
 AssociationQ[ncResult]&&ncSource["Results"]["qqp-qqp"]["EpsilonRange"]==={0,0}&&
 ncResult["EpsilonRange"]==={0,0}&&!DirectoryQ[ncTemp<>"/Raw/LO"]];
ncExpected=-ncCard["Counterterms"]["Coupling"]lambda/(2Pi)*
 ncSource["Results"]["qqp-qqp"]["Coefficients"][0]["DeltaCoefficient"];
FTTest`FTAssert["a finite operator override in a concrete card acts with the inverse scheme sign",
 AssociationQ[ncResult]&&Factor[TrigExpand[ncResult["Coefficients"][0]["DeltaCoefficient"]-ncExpected]]===0&&
 ncResult["Coefficients"][0]["PlusCoefficients"]===<||>&&ncResult["Coefficients"][0]["RegularCoefficient"]===0];
If[AssociationQ[ncResult]&&Factor[TrigExpand[ncResult["Coefficients"][0]["DeltaCoefficient"]-ncExpected]]=!=0,Print["FINITE_CARD_RESIDUAL ",ncResult["Coefficients"][0]["DeltaCoefficient"]-ncExpected]];
ncWrong=Join[ncSource["Results"]["qqp-qqp"],<|"PhysicalChannel"-><|"Incoming"->{"g","g"},"Observed"->"g"|>|>];
FTTest`FTAssert["a supplied Born result must match the concrete card's physical source channel",
 FailureQ[FeynFacet`ConstructNLOCountertermContribution[ncCard,<|"qqp-qqp"->ncWrong|>]]];
ncConverted=Join[ncSource["Results"]["qqp-qqp"],<|"RenormalizationStage"->"Renormalized",
 "FiniteSchemeConversionApplied"->True|>];
FTTest`FTAssert["a concrete finite card refuses an already converted source",
 FailureQ[FeynFacet`ConstructNLOCountertermContribution[ncCard,<|"qqp-qqp"->ncConverted|>]]];
ncHigh=FeynFacet`CompileCountertermCard[ncDirectory,Join[ncDefinition,<|"EpsilonRange"->{0,1}|>]];
FTTest`FTAssert["finite counterterm cards do not invent a positive-epsilon scheme continuation",
 FailureQ[ncHigh]||FailureQ[FeynFacet`ConstructNLOCountertermContribution[ncHigh,ncSource["Results"]]]];

Do[
 {ncField,ncValue}=ncTest;
 ncMismatched=Join[ncSource["Results"]["qqp-qqp"],<|ncField->ncValue|>];
 FTTest`FTAssert["a supplied Born source must match the declared "<>ncField,
  MatchQ[FeynFacet`ConstructNLOCountertermContribution[ncCard,<|"qqp-qqp"->ncMismatched|>],
   Failure["CountertermBornSourceIdentityMismatch",_Association]]],
 {ncTest,{{"Coupling",ncOtherCoupling},{"CouplingNormalization",
   FeynFacet`MSbarCouplingNormalization[Global`Epsilon,Exp[ncLambda Global`Epsilon]]},
   {"DimensionalPrefactor",ncOtherScale^(ncCard["BornCouplingPower"] Global`Epsilon)}}}];
ncNoLegs=Join[ncCard,<|"Assembly"->KeyDrop[ncCard["Assembly"],"FactorizationLegs"]|>];
FTTest`FTAssert["counterterm operators require explicitly declared factorization legs",
 FailureQ[FeynFacet`ConstructNLOCountertermContribution[ncNoLegs,ncSource["Results"]]]];


FTTest`FTAssert["explicit TT and spin-transfer minima preserve complete NLO result plans",
 AllTrue[{"ppHX_TT","ppHX_TT_SpinTransfer","ppHX_LL_SpinTransfer"},
  AssociationQ[FeynFacet`PlanProjectResult[root<>"/Projects/"<>#<>"/Results/NLO/qqp-qqp/Result_Card.wl"]]&]];

DeleteDirectory[ncTemp,DeleteContents->True];
FTTest`FTReport[];
