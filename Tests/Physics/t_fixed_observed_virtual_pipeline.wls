Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
card=FeynFacet`ReadContributionCard[root<>"/Projects/SIDIS_HighPT_TT_SpinTransfer/Raw/NLO/q-q","Virtual"];
referenceFile=card["WorkDirectory"]<>"/Validation/MetricPhotonVirtual.wl";
If[!FileExistsQ[referenceFile],CreateDirectory[DirectoryName[referenceFile],CreateIntermediateDirectories->True];
 FeynFacet`FamilyArtifactCopy[card["ResultFile"],referenceFile]];
reference=FeynFacet`FamilyArtifactRead[referenceFile];
{seconds,audit}=AbsoluteTiming[FeynFacet`WithEpsilonRemainderChecks[FeynFacet`EvaluateBareContribution[card,"resume"]]];
If[!AssociationQ[audit]||!AssociationQ[audit["Result"]],Print[InputForm[System`Short[audit,6]]];Exit[1]];
result=audit["Result"]["Result"];
FTTest`FTAssert["one raw virtual card completes generated amplitude, scalar projection, reduction and Laurent expansion",
 AssociationQ[result]&&audit["EpsilonRemainderAudit"]["Status"]==="Passed"];
index[record_,name_]:=First@FirstPosition[record["StructureFunctions"],name];
points={{Q2->3/2,x->2/7,z->3/8,muR2->5/7},{Q2->2,x->3/5,z->2/3,muR2->1}};
parameters={FeynCalc`CA->3,FeynCalc`CF->4/3,eU->2/3,nU->2,nD->3,FeynFacet`\[Alpha]s->1/7};
differences=Flatten@Table[
 N[(result["Coefficients"][n]["DeltaCoefficient"][[index[result,name]]]-
    reference["Coefficients"][n]["DeltaCoefficient"][[index[reference,name]]])/.parameters/.point,35],
 {n,-2,0},{name,{"TransversePhoton","LongitudinalPhoton"}},{point,points}];
Print["MAXIMUM REFERENCE DIFFERENCE ",Max[Abs[differences]]];
FTTest`FTAssert["new physical-polarization virtual result agrees with the independent metric-projector production",
 VectorQ[differences,NumericQ]&&Max[Abs[differences]]<10^-25];
FTTest`FTAssert["all stored virtual coefficients are explicit",
 FreeQ[result["Coefficients"],_Integrate|_FeynCalc`B0|_FeynCalc`C0|_FeynCalc`D0|_FeynCalc`Pair|_SeriesData]];
FeynFacet`FamilyArtifactWrite[<|"Seconds"->seconds,"MaximumDifference"->Max[Abs[differences]],
 "EpsilonRemainderAudit"->audit["EpsilonRemainderAudit"],"StageSeconds"->audit["Result"]["StageSeconds"]|>,
 card["WorkDirectory"]<>"/Validation/ProjectionComparison.wl"];
Print["FIXED OBSERVED VIRTUAL PIPELINE TEST COMPLETE"];FTTest`FTReport[];
