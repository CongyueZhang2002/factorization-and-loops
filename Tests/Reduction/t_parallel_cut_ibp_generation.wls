Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
geometry=FeynFacet`CreateMeasuredPhaseSpaceDefinition[<|"Name"->parallelIBPSource,
 "FinalMomenta"->{pk1,pk2,pk3},"TotalMomentum"->pP+pQ,"ExternalMomenta"->{pP,pQ},
 "KinematicRules"->FeynCalc`FCI[{FeynCalc`SPD[pP]->0,FeynCalc`SPD[pQ]->-pS,
  FeynCalc`SPD[pP,pQ]->pS/(2pX)}],"ReferenceMomentum"->pP,"TaggedMomentum"->pk1,
 "MeasurementVariable"->pZ,"Assumptions"->pS>0&&0<pX<1&&0<pZ<1|>];
prepared=FeynFacet`PrepareMeasuredCutIntegrand[FeynCalc`FCI[FeynCalc`SFAD[pP-pk2]],geometry,
 <|"ExternalKinematicConditions"->pS>0&&0<pX<1|>];
family=First[FeynFacet`DecomposeMeasuredCutIntegrand[prepared]["Families"]];
name=family["Topology"][[1]];
plan=FeynFacet`PlanCutIBPSeeds[family,{FeynCalc`GLI[name,{1,1,1,1,2,-2,0}]}];
seeds=Take[plan["Seeds"],UpTo[18]];
jobs=Table[<|"Family"->family,"Plan"-><|"Seeds"->subset|>|>,
 {subset,{Take[seeds,UpTo[5]],seeds,{}}}];
reference=(If[#["Plan"]["Seeds"]==={},<|"Rows"->{},"Seeds"->{}|>,
 FeynFacet`GenerateCutIBPEquations[#["Family"],#["Plan"]["Seeds"]]]&/@jobs);
serial=FeynFacet`Private`cutGenerateIBPBatch[jobs,1];
parallel=FeynFacet`Private`cutGenerateIBPBatch[jobs,2];
math[result_]:=KeyTake[#,{"Rows","Seeds"}]&/@result;
FTTest`FTAssert["serial and parallel batches preserve exact equations and job order",
 ListQ[serial]&&ListQ[parallel]&&math[reference]===math[serial]===math[parallel]];
FTTest`FTAssert["empty families stay empty",parallel[[-1]]["Rows"]==={}&&parallel[[-1]]["Seeds"]==={}];
FTTest`FTAssert["owned pool closes after generation",Kernels[]==={}];
bad=ReplacePart[jobs,{1,"Plan","Seeds"}->{FeynCalc`GLI[name,{0,1,1,1,1,0,0}]}];
failed=FeynFacet`Private`cutGenerateIBPBatch[bad,2];
FTTest`FTAssert["worker failure propagates and still closes the pool",FailureQ[failed]&&Kernels[]==={}];
FTTest`FTAssert["invalid allocation fails",FailureQ[FeynFacet`Private`cutGenerateIBPBatch[jobs,9]]];
nested=FeynFacet`Private`facetWithSymbolicWorkers[
 Module[{before=Kernels[],answer},
  answer=FeynFacet`Private`cutGenerateIBPBatch[jobs,2];
  math[answer]===math[reference]&&Kernels[]===before],2];
FTTest`FTAssert["caller-owned pool survives nested serial fallback",TrueQ[nested]&&Kernels[]==={}];
streamDir=CreateDirectory[];
streamFile=streamDir<>"/equations.kira";
streamColumns=Table[FeynCalc`GLI[name,{1,1,1,1,i,0,0}],{i,1,3}];
streamRows={<|streamColumns[[1]]->1,streamColumns[[3]]->1/2|>,
 <|streamColumns[[2]]->-3,streamColumns[[1]]->5|>};
FeynFacet`Private`cutKiraWriteEquationRows[streamRows,AssociationThread[streamColumns,Range[3]],
 Function[value,ToString[value,InputForm]],streamFile];
expected=StringRiffle[{"FeynFacetIBP[2]*(-3)","FeynFacetIBP[1]*(5)","",
 "FeynFacetIBP[1]*(1)","FeynFacetIBP[3]*(1/2)","",""},FromCharacterCode[10]];
FTTest`FTAssert["streamed native equations preserve exact coefficients, row order and separators",
 System`ReadString[streamFile]===expected&&!FileExistsQ[streamFile<>".tmp"]];
If[StringStartsQ[ExpandFileName[streamDir],ExpandFileName[$TemporaryDirectory]<>"/"],
 DeleteDirectory[streamDir,DeleteContents->True]];
FTTest`FTReport[];
