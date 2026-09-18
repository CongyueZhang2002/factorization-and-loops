(* Independent C_epsilon^(p+r) covariance of the common bare-source executor.
   The virtual calculation reuses exact reduced amplitudes in its own consumer
   directory; original result and reduction files remain read-only. *)
Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
scRoot=DirectoryName[ExpandFileName[$InputFileName],3];Get[scRoot<>"/Tests/TestKit.wl"];
scLoad=First[AbsoluteTiming[Block[{Print},Get[scRoot<>"/Addon/Load/LoadFACET.wl"]]]];$PrePrint=.;
scOriginal=scRoot<>"/Projects/ppHX_UU";
scOutput=scOriginal<>"/Results/NLO/qqp-qqp/Validation/SourceOrders/SourceCouplingCovariance";
If[!DirectoryQ[scOutput],CreateDirectory[scOutput,CreateIntermediateDirectories->True]];
scRootCard=Get[scOriginal<>"/Common-Card.wl"];
scE=Global`Epsilon;
scConsumers=Association@Table[
 scDirectory=scOutput<>"/"<>scName;
 If[!DirectoryQ[scDirectory],CreateDirectory[scDirectory]];
 scC=If[scName==="Reference",1,Exp[scLambda scE]];
 scRaw=Join[scRootCard,<|"Counterterms"->Join[scRootCard["Counterterms"],<|"BareCouplingFactor"->scC|>]|>];
 FeynFacet`FamilyArtifactWrite[scRaw,scDirectory<>"/Common-Card.wl"];
 scName->FeynFacet`BuildCountertermProjectCard[scDirectory<>"/Raw/NNLO/qqp-qqp"],
 {scName,{"Reference","Deformed"}}];
scResults=<||>;scTiming=<||>;scReports=<||>;
Do[
 scOrder=If[scKind==="Born","LO","NLO"];scHigh=If[scKind==="Born",2,1];
 Do[
  scCard=FeynFacet`CompileBareSourceCard[scConsumers[scName],scOrder,"qqp-qqp",scKind,scHigh];
  If[!AssociationQ[scCard],Print["SOURCE CARD FAILURE ",scCard];Exit[2]];
  If[scKind==="Virtual",
   scReduced=FileNameJoin[{scCard["WorkDirectory"],"Reduction"}];
   If[!DirectoryQ[DirectoryName[scReduced]],CreateDirectory[DirectoryName[scReduced],CreateIntermediateDirectories->True]];
   If[!DirectoryQ[scReduced],CopyDirectory[scOriginal<>"/Raw/NLO/qqp-qqp/Virtual/Work/Reduction",scReduced]]];
  {scSeconds,scValue}=AbsoluteTiming[FeynFacet`EvaluateBareContribution[scCard,"assemble"]];
  FTTest`FTAssert[scName<>" "<>scKind<>" source executes at the requested epsilon range",
   AssociationQ[scValue]&&AssociationQ[scValue["Result"]]&&scValue["Result"]["EpsilonRange"]===scCard["EpsilonRange"]];
  If[!AssociationQ[scValue],Print["SOURCE EXECUTOR FAILURE ",System`Short[scValue,10]];
   FeynFacet`FamilyArtifactWrite[scValue,scOutput<>"/"<>scName<>scKind<>"Failure.wl"];FTTest`FTReport[]];
  AssociateTo[scResults,{scName,scKind}->scValue["Result"]];
  AssociateTo[scTiming,scName<>scKind-><|"Seconds"->scSeconds,"StageSeconds"->scValue["StageSeconds"]|>],
 {scName,{"Reference","Deformed"}}];
 scReference=scResults[[Key[{"Reference",scKind}]]];scDeformed=scResults[[Key[{"Deformed",scKind}]]];
 scReferenceScalars=FeynFacet`PartonicScalarCoefficientRules[scReference];
 scDeformedScalars=FeynFacet`PartonicScalarCoefficientRules[scDeformed];
 scPower=scRootCard["BornCouplingPower"]+If[scKind==="Born",0,1];
 scLow=First[scReference["EpsilonRange"]];
 scResiduals=Association@KeyValueMap[Function[{key,value},key->Cancel[Together[value-
   Sum[(scPower scLambda)^scK/Factorial[scK]*
     Lookup[scReferenceScalars,Key[ReplacePart[key,1->First[key]-scK]],0],
    {scK,0,First[key]-scLow}]]]],scDeformedScalars];
 FTTest`FTAssert[scKind<>" source has exactly C_epsilon^(BornCouplingPower+relativeOrder) covariance",
  Length[scResiduals]>0&&AllTrue[Values[scResiduals],#===0&]];
 AssociateTo[scReports,scKind-><|"Power"->scPower,"EpsilonRange"->scReference["EpsilonRange"],
  "ScalarResiduals"->scResiduals,"Passed"->AllTrue[Values[scResiduals],#===0&]|>],
 {scKind,{"Born","Virtual"}}];
FeynFacet`FamilyArtifactWrite[<|"PackageLoadSeconds"->scLoad,"Timing"->scTiming,
 "Covariance"->scReports,"CouplingFactor"->Exp[scLambda scE],
 "AcceptedResultsModified"->False,"UpstreamRegenerated"->False|>,scOutput<>"/Report.wl"];
Print["SOURCE COUPLING COVARIANCE TIMING ",scTiming];
FTTest`FTReport[];
