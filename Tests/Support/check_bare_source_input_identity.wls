(* Resolved source-request identity and actual scalar coupling rebinding.
   Every write is confined to this validation consumer, with exact scalar
   reductions copied from a previous validation consumer. *)
Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
siRoot=DirectoryName[ExpandFileName[$InputFileName],3];Get[siRoot<>"/Tests/TestKit.wl"];
Block[{Print},Get[siRoot<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
siBase=siRoot<>"/Projects/ppHX_UU/Results/NLO/qqp-qqp/Validation/SourceOrders";
siOutput=siBase<>"/SourceInputIdentity";
If[!DirectoryQ[siOutput],CreateDirectory[siOutput]];
siOriginal=FeynFacet`ReadContributionCard[siRoot<>"/Projects/SIDIS_UU/Raw/NLO/q-q","Virtual"];
siCard=Join[siOriginal,<|"WorkDirectory"->siOutput<>"/Current/NLO/q-q","Execution"->Map[1&,siOriginal["Execution"]]|>];
siValue=FeynFacet`EvaluateBareContribution[siCard,"all"];
FTTest`FTAssert["fresh projected current records its complete resolved mathematical request",
 AssociationQ[siValue]&&AssociationQ[siValue["Result"]["EvaluationDefinition"]]];
If[!AssociationQ[siValue],Print[siValue];FTTest`FTReport[]];
siReference=siValue["Result"];
siReuse=FeynFacet`EvaluateBareContribution[Join[siCard,<|"Execution"->Map[2&,siCard["Execution"]]|>],"assemble"];
FTTest`FTAssert["execution allocation does not invalidate exact current physics reuse",
 AssociationQ[siReuse]&&siReuse["StageSeconds"]===<||>];
siScale=siCard/.Global`muR2->2 Global`muR2;
siStale=FeynFacet`EvaluateBareContribution[siScale,"assemble"];
FTTest`FTAssert["changed current renormalization scale rejects stale projected output",
 MatchQ[siStale,Failure["MatchingProjectedContributionRequired",_Association]]];
siValue=FeynFacet`EvaluateBareContribution[siScale,"resume"];
FTTest`FTAssert["resume recomputes the changed current scale",
 AssociationQ[siValue]&&Length[siValue["StageSeconds"]]>0&&siValue["Result"]["Coefficients"]=!=siReference["Coefficients"]];
If[!AssociationQ[siValue],Print[siValue];FTTest`FTReport[]];
siScaled=siValue["Result"];
siAlpha=siCard["Counterterms"]["Coupling"];
siChanged=siScale/.siAlpha->siNewAlpha;
siStale=FeynFacet`EvaluateBareContribution[siChanged,"assemble"];
FTTest`FTAssert["changed current bare coupling rule rejects stale projected output",
 MatchQ[siStale,Failure["MatchingProjectedContributionRequired",_Association]]];
siValue=FeynFacet`EvaluateBareContribution[siChanged,"resume"];
siNew=If[AssociationQ[siValue],siValue["Result"],siValue];
FTTest`FTAssert["recomputed current coefficients contain the declared coupling with exact linear covariance",
 AssociationQ[siNew]&&siNew["Coupling"]===siNewAlpha&&FreeQ[siNew["Coefficients"],siAlpha]&&
 siNew["Coefficients"]===(siScaled["Coefficients"]/.siAlpha->siNewAlpha)];
siProjectorChange=Join[siChanged,<|"Assembly"->Join[siChanged["Assembly"],
 <|"CurrentNormalization"->2 siChanged["Assembly"]["CurrentNormalization"]|>]|>];
FTTest`FTAssert["changed current projection normalization rejects stale projected output",
 MatchQ[FeynFacet`EvaluateBareContribution[siProjectorChange,"assemble"],
 Failure["MatchingProjectedContributionRequired",_Association]]];
siDefinition=siNew["EvaluationDefinition"];
siNewC=Exp[siLambda Global`Epsilon] siChanged["Counterterms"]["BareCouplingFactor"];
siCChanged=Join[siChanged,<|"Counterterms"->Join[siChanged["Counterterms"],
 <|"BareCouplingFactor"->siNewC,"CouplingNormalization"->FeynFacet`MSbarCouplingNormalization[Global`Epsilon,siNewC]|>],
 "Assembly"->Join[siChanged["Assembly"],<|"BareCouplingRules"->(siChanged["Assembly"]["BareCouplingRules"]/.
  Rule[lhs_,rhs_]:>Rule[lhs,Exp[siLambda Global`Epsilon] rhs])|>]|>];
FTTest`FTAssert["changed dimensional coupling normalization rejects stale projected output",
 MatchQ[FeynFacet`EvaluateBareContribution[siCChanged,"assemble"],
 Failure["MatchingProjectedContributionRequired",_Association]]];
siRootCard=Get[siRoot<>"/Projects/ppHX_UU/Common-Card.wl"];
siScalarDirectory=siOutput<>"/Scalar";
If[!DirectoryQ[siScalarDirectory],CreateDirectory[siScalarDirectory]];
FeynFacet`FamilyArtifactWrite[siRootCard,siScalarDirectory<>"/Common-Card.wl"];
siConsumer=FeynFacet`BuildCountertermProjectCard[siScalarDirectory<>"/Raw/NNLO/qqp-qqp"];
siReport=<||>;
Do[
 siOrder=If[siKind==="Born","LO","NLO"];
 siCard=FeynFacet`CompileBareSourceCard[siConsumer,siOrder,"qqp-qqp",siKind,1];
 If[siKind==="Virtual",
  siReduction=FileNameJoin[{siCard["WorkDirectory"],"Reduction"}];
  If[!DirectoryQ[DirectoryName[siReduction]],CreateDirectory[DirectoryName[siReduction],CreateIntermediateDirectories->True]];
  If[!DirectoryQ[siReduction],CopyDirectory[
   siBase<>"/SourceCouplingCovariance/Reference/NNLO/qqp-qqp/Counterterm/Work/Sources/NLO/qqp-qqp/Virtual/Reduction",siReduction]]];
 siValue=FeynFacet`EvaluateBareContribution[siCard,"assemble"];
 FTTest`FTAssert[siKind<>" scalar source evaluates with canonical coupling",AssociationQ[siValue]];
 If[!AssociationQ[siValue],Print[siValue];FTTest`FTReport[]];
 siCanonical=siValue["Result"];siAlpha=siCard["Counterterms"]["Coupling"];
 siAltCard=Join[siCard,<|"Counterterms"->Join[siCard["Counterterms"],<|"Coupling"->siAltAlpha|>]|>];
 siValue=FeynFacet`EvaluateBareContribution[siAltCard,"assemble"];
 FTTest`FTAssert[siKind<>" scalar source rebinds its actual coefficients to an alternate card coupling",
 AssociationQ[siValue]&&siValue["Result"]["Coupling"]===siAltAlpha&&
 FreeQ[siValue["Result"]["Coefficients"],siAlpha]&&
 siValue["Result"]["Coefficients"]===(siCanonical["Coefficients"]/.siAlpha->siAltAlpha)];
 siWrong=FeynFacet`EvaluateBareContribution[Join[siCard,<|"BornCouplingPower"->siCard["BornCouplingPower"]+1|>],"assemble"];
 FTTest`FTAssert[siKind<>" scalar source rejects a metadata-only change of coupling power",
 MatchQ[siWrong,Failure["BareContributionCouplingPowerMismatch",_Association]]];
 AssociateTo[siReport,siKind-><|"CanonicalResult"->siCanonical,"DeclaredCouplingResult"->siValue["Result"]|>],
 {siKind,{"Born","Virtual"}}];
FeynFacet`FamilyArtifactWrite[<|"CurrentReference"->siReference,"CurrentScaled"->siScaled,
 "CurrentChangedCoupling"->siNew,"Scattering"->siReport,"AcceptedOutputsModified"->False|>,siOutput<>"/Report.wl"];
FTTest`FTReport[];
