
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
Get[root<>"/FeynFacet/Coefficients/PerturbativeRenormalization.wl"];
prRow[d_]:=<|"DeltaCoefficient"->d,"PlusCoefficients"-><||>,"RegularCoefficient"->0|>;
prTree[d_]:=<|"DeltaCoefficient"->prRow[d],"PlusCoefficients"-><||>,"RegularCoefficient"->prRow[0]|>;
prMeta=<|"Order"->"NNLO","Contribution"->"Total","Channel"->"test","Scale"->qs,
 "Variables"->{xx,zz},"DimensionalRegulator"->ee,"CouplingPower"->4,
 "DistributionBasis"-><|"Axes"->{
 <|"Variable"->xx,"Endpoint"->1,"Interval"->{0,1},"Distance"->1-xx|>,
 <|"Variable"->zz,"Endpoint"->1,"Interval"->{0,1},"Distance"->1-zz|>}|>|>;
prClasses=<|"Quarks"-><|"Members"->{"u","d"},"Multiplicity"->2|>|>;
prSpecies={"g",{"q","u"},{"qbar","u"},{"q","d"},{"qbar","d"}};
prIndex[sp_]:=If[sp==="g",1,If[First[sp]==="q",2,3]+If[Last[sp]==="u",0,2]];
prBorn[sp_List]:=If[sp[[1]]===sp[[2]]&&sp[[1]]=!="g",prIndex[sp[[1]]],0];
prValue[0,sp_]:=prBorn[sp];
prValue[1,sp_]:=prIndex[sp[[1]]]+2prIndex[sp[[2]]];
prValue[2,sp_]:=prIndex[sp[[1]]]^2-prIndex[sp[[2]]];
prKernelValue[j_,src_,dst_,n_]:=(j+prIndex[src]+2prIndex[dst])^n/(7ee)^n;
prProvider[j_,src_,dst_,n_]:=Join[prRow[prKernelValue[j,src,dst,n]],
 <|"Variable"->If[j===1,xx,zz]|>];
prRequest=<|"PerturbativeOrder"->2,"ThroughOrder"->0,"DimensionalRegulator"->ee,
 "PerturbativeParameter"->aa,"BornCouplingPower"->2,
 "Legs"->{<|"Variable"->xx|>,<|"Variable"->zz|>},"FlavorClasses"->prClasses,
 "TransitionKernel"->prProvider,
 "CouplingRenormalization"-><|1->-b0/ee,2->b0^2/ee^2-b1/(2ee)|>|>;
prPlan=FeynFacet`PlanPartonicRenormalization[{{"q","u"},{"q","u"}},prRequest];
FTTest`FTAssert["operator convolution plans demand Born epsilon squared and one-loop epsilon",
 AssociationQ[prPlan]&&Max[Lookup[Select[prPlan["Terms"],#["SourceOrder"]===0&],"RequiredSourceThroughOrder"]]===2&&
 Max[Lookup[Select[prPlan["Terms"],#["SourceOrder"]===1&],"RequiredSourceThroughOrder"]]===1];
prSource[r_,sp_,cl_,hi_]:=FeynFacet`CreatePartonicResult[
 Association@Table[k->prTree[(k+1)aa^(2+r)prValue[r,sp]],{k,0,Max[0,hi]}],
 Join[prMeta,<|"Order"->{"LO","NLO","NNLO"}[[r+1]],"Contribution"->"Bare","RenormalizationStage"->"Bare",
 "CouplingPower"->2+r|>]];
prResult=FeynFacet`WithEpsilonRemainderChecks[
 FeynFacet`ApplyPartonicRenormalization[prPlan,prSource,prMeta]];
If[!AssociationQ[prResult]||!AssociationQ[prResult["Result"]],Print[prResult]];
prTarget={{"q","u"},{"q","u"}};
prUV1[sp_]:=prValue[1,sp]-2b0/ee prValue[0,sp];
prUV2[sp_]:=prValue[2,sp]-3b0/ee prValue[1,sp]+(3b0^2/ee^2-b1/ee)prValue[0,sp];
prExpected=prUV2[prTarget]+Total[Table[
 prKernelValue[1,sp,prTarget[[1]],1]prUV1[{sp,prTarget[[2]]}]+
 prKernelValue[2,sp,prTarget[[2]],1]prUV1[{prTarget[[1]],sp}]+
 prKernelValue[1,sp,prTarget[[1]],2]prValue[0,{sp,prTarget[[2]]}]+
 prKernelValue[2,sp,prTarget[[2]],2]prValue[0,{prTarget[[1]],sp}],
 {sp,prSpecies}]]+Total[Flatten[Table[
 prKernelValue[1,sp1,prTarget[[1]],1]prKernelValue[2,sp2,prTarget[[2]],1]prValue[0,{sp1,sp2}],
 {sp1,prSpecies},{sp2,prSpecies}]]];
prExpected=Expand[aa^4(1+2ee+3ee^2)prExpected];
FTTest`FTAssert["NNLO UV and both flavor matrices agree with explicit five-species multiplication",
 AssociationQ[prResult["Result"]]&&And@@Table[
 Cancel[Together[prResult["Result"]["Coefficients"][k]["DeltaCoefficient"]["DeltaCoefficient"]-
 Coefficient[prExpected,ee,k]]]===0,{k,-2,0}]];
FTTest`FTAssert["all intermediate Laurent products pass the independent omitted-order audit",
 prResult["EpsilonRemainderAudit"]["Status"]==="Passed"];
prMissing[r_,sp_,cl_,hi_]:=Missing["Uncomputed"];
FTTest`FTAssert["missing bare channels are never treated as zero",
 FailureQ[FeynFacet`ApplyPartonicRenormalization[prPlan,prMissing,prMeta]]];
prShort[r_,sp_,cl_,hi_]:=prSource[r,sp,cl,0];
FTTest`FTAssert["insufficient positive epsilon coefficients fail before assembly",
 FailureQ[FeynFacet`ApplyPartonicRenormalization[prPlan,prShort,prMeta]]];

prPhysical=FeynFacet`PlanCollinearRenormalization[{"g","g"},Join[prRequest,
 <|"PerturbativeOrder"->1,"BornCouplingPower"->0,
 "KernelParameters"-><|"CA"->ca,"CF"->cf,"TR"->tr,"FlavorCount"->2|>,
 "Legs"->{<|"Role"->"PDF","Spin"->"U","Variable"->xx,"ScaleLog"->lf,"OperatorScheme"->"MSbar"|>,
  <|"Role"->"FF","Spin"->"U","Variable"->zz,"ScaleLog"->ld,"OperatorScheme"->"MSbar"|>}|>]];
prPDF=SelectFirst[prPhysical["Terms"],MatchQ[#["SourceSpecies"],{{"q",_String},"g"}]&];
prFF=SelectFirst[prPhysical["Terms"],MatchQ[#["SourceSpecies"],{"g",{"q",_String}}]&];
FTTest`FTAssert["PDF and FF transition orientations follow their physical roles",
 prPDF["Kernels"][[1,"Kernel","Daughter"]]===prPDF["SourceSpecies"][[1]]&&
 prPDF["Kernels"][[1,"Kernel","Parent"]]==="g"&&
 prFF["Kernels"][[1,"Kernel","Daughter"]]==="g"&&
 prFF["Kernels"][[1,"Kernel","Parent"]]===prFF["SourceSpecies"][[2]]];
prFiniteSource[r_,sp_,cl_,hi_]:=Join[prSource[r,sp,cl,hi],<|"RenormalizationStage"->"Renormalized"|>];
FTTest`FTAssert["a finite renormalized hard coefficient cannot replace a bare source",
 FailureQ[FeynFacet`ApplyPartonicRenormalization[prPlan,prFiniteSource,prMeta]]];
FTTest`FTReport[];
