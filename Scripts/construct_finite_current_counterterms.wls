$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
args=Rest[$ScriptCommandLine];
If[Length[args]=!=2,Print["Usage: construct_finite_current_counterterms.wls PROJECT SUBTRACTED_CATALOG"];Exit[2]];
project=args[[1]];catalog=FeynFacet`FamilyArtifactRead[ExpandFileName[args[[2]]]];
If[AssociationQ[catalog]&&KeyExistsQ[catalog,"EpsilonRemainderAudit"],
 If[catalog["EpsilonRemainderAudit"]["Status"]=!="Passed",Print["Source epsilon audit failed"];Exit[1]];
 catalog=catalog["Result"]];
projectCard=Get[root<>"/Projects/"<>project<>"/card.wl"];
If[!AssociationQ[catalog]||!AssociationQ[projectCard],Print["Explicit project and subtracted source catalog required"];Exit[1]];
report=<||>;
Do[
 directory=FileNameJoin[{root,"Projects",project,"NNLO",channel}];
 card=FeynFacet`ReadContributionCard[directory,"Counterterm"];out=directory<>"/Results/Counterterm/";
 If[!AssociationQ[card],Print[card];Exit[1]];
 Print["FINITE SCHEME ",channel];
 {seconds,audit}=AbsoluteTiming[FeynFacet`WithEpsilonRemainderChecks[
  FeynFacet`ConstructFiniteFactorizationCounterterm[card,catalog]]];
 FeynFacet`FamilyArtifactWrite[audit,out<>"FiniteSchemeAudit.wl",Compression->Automatic];
 exactZero=AssociationQ[audit]&&AssociationQ[audit["Result"]]&&
   Lookup[audit["Result"]["FiniteSchemePlan"],"Terms",None]==={}&&
   AllTrue[Values[audit["Result"]["Coefficients"]],FeynFacet`Private`partonicZeroTreeQ];
 If[!AssociationQ[audit]||!AssociationQ[audit["Result"]]||
   !(audit["EpsilonRemainderAudit"]["Status"]==="Passed"||
    (audit["EpsilonRemainderAudit"]["Status"]==="NoChecksExecuted"&&exactZero)),
  Print["FAILED ",channel," ",If[AssociationQ[audit],Head[audit["Result"]],Head[audit]]];Exit[1]];
 finite=audit["Result"];FeynFacet`FamilyArtifactWrite[finite,out<>"FiniteSchemeResult.wl",Compression->Automatic];
 pole=FeynFacet`FamilyArtifactRead[If[FileExistsQ[out<>"UVCollinearResult.wl"],out<>"UVCollinearResult.wl",out<>"Result.wl"]];
 If[!AssociationQ[pole]||TrueQ[Lookup[pole,"FiniteSchemeConversionApplied",False]]||
   pole["LowerOrderResults"]=!=card["LowerOrderResults"]||pole["BareOperatorSchemes"]=!=card["BareOperatorSchemes"],
  Print["Matching original UV/collinear counterterm required"];Exit[1]];
 FeynFacet`FamilyArtifactWrite[pole,out<>"UVCollinearResult.wl",Compression->Automatic];
 combined=FeynFacet`CombinePartonicResults[<|"UVCollinear"->pole,"FiniteScheme"->finite|>,
  <|"Contribution"->"Counterterm","RenormalizationStage"->"Counterterm",
    "FiniteSchemeConversionApplied"->True,"OperatorSchemes"->card["Counterterms"]["Schemes"],
    "SourceOperatorSchemes"->card["BareOperatorSchemes"]|>];
 If[!AssociationQ[combined],Print[combined];Exit[1]];
 FeynFacet`FamilyArtifactWrite[combined,out<>"Result.wl",Compression->Automatic];
 AssociateTo[report,channel-><|"Seconds"->seconds,"EpsilonAudit"->If[exactZero,"ExactZeroNoTruncation","Passed"]|>];
 Print["COMPLETED CHANNEL ",channel," SECONDS ",seconds],
 {channel,projectCard["Orders"]["NNLO"]}];
FeynFacet`FamilyArtifactWrite[report,root<>"/Projects/"<>project<>"/NNLO/q-q/Results/Validation/FiniteSchemeCountertermsReport.wl"];
Print["COMPLETED ALL FINITE SCHEME COUNTERTERMS ",Length[report]];
