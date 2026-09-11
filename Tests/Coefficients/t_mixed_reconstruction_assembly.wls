Print["FEYNFACET DRIVER ENTERED"];
root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;$HistoryLength=0;
Clear[e,f,x];count=0;
check[label_,condition_]:=If[TrueQ[condition],count++,Print["FAIL ",label];Exit[1]];
master=FeynCalc`GLI[f,{1}];
data=<|"Setup"-><||>,"PhaseSpace"->1,"FractionMeasure"->1,
 "AnalyticContext"-><|"Assumptions"->True|>|>;
metadata=<|"Topologies"->{<|"Topology"->{f},"CutMomenta"->{},"CutIndices"->{1},"CutDirections"->{1}|>},
 "TopologyEquivalence"-><||>,"ReverseRules"->{},"MassDimensions"-><||>,"KiraManifest"->{},
 "ReductionInputFingerprint"->"input","SourceInputFingerprint"->"source"|>;
context=<|"DimensionlessCoordinates"-><||>,"FractionVariables"->{},"FractionRootVariables"->{},
 "ExpectedDistributionFactor"->1,"ExpectedLaurentValuation"->0,"BranchGrammar"-><||>|>;
traceData=<|"CompleteTargetSet"->True,"PhysicalFactor"->1,"Masters"->{master},
 "Signatures"-><|1->HoldComplete[Gamma[1+Global`Epsilon]]|>,
 "OutputMetadata"->{<|"MasterIndex"->1,"SignatureIndex"->1|>,<|"MasterIndex"->1,"SignatureIndex"->1|>},
 "OutputOrder"->{1,2},"Variables"->{x,Global`Epsilon},"ProcessedTargetCount"->1,"TargetCount"->1|>;
trace=<|"TraceFile"->"trace","TraceBytes"->0,"BuildSeconds"->0|>;
finite=<|"Representation"->"LaurentSeries","PreFactor"->1,
 "Coefficient"-><|"SeriesVariable"->Global`Epsilon,"Orders"-><|0->0,1->0|>,"SeriesTruncation"->1|>,
 "LaurentRemainderClass"-><|"Status"->"test-source-bound","Justification"-><|"SourceDimension"->System`D,"SourceMomentum"->pSource|>|>|>;
reconstruction=<|"ColumnTerms"->{{<|"Representation"->"Exact","PreFactor"->1,"Coefficient"->1/(x+Global`Epsilon)|>},{finite}},
 "ResultFile"->"result","ResultBytes"->0,"ReconstructionSeconds"->0|>;
assemble[td_,rr_]:=Block[{FeynFacet`Private`finiteFieldCertifyPhysicalVariables=Function[{a,b},a],
 FeynFacet`Private`remainingDeclaredMomenta=Function[{a,b},{}],
 FeynFacet`Private`coefficientForbiddenMomenta=Function[a,{}],
 FeynFacet`Private`validateCutGLIs=Function[{a,b},True],
 FeynFacet`Private`resultContext=Function[a,<|"Setup"-><||>,"CardName"->"test"|>],
 FeynFacet`Private`coefficientFileHash=Function[a,"test"]},
 FeynFacet`Private`finiteFieldAssembleResult[data,metadata,"kira",context,td,trace,rr,"native",1]];
raw=assemble[traceData,reconstruction];
check["assembled term groups",AssociationQ[raw]&&Length[raw["Masters"][[1,"Terms"]]]===2];
result=FeynFacet`Private`coefficientResultFromReconstruction[raw];
check["common final format",AssociationQ[result]&&result["Format"]==="FeynFacet-MasterIntegralCoefficients"];
terms=result["Masters"][[1,"Terms"]];e=result["DimensionalRegulator"];
check["analytic factor outside finite coefficients",terms[[2,"PreFactor"]]===Gamma[1+e]&&FreeQ[Values[terms[[2,"Coefficient","Orders"]]],_Gamma]];
check["moving pole remains exact",terms[[1,"Representation"]]==="Exact"&&terms[[1,"Coefficient"]]===1/(x+e)];
check["zero finite prefix remains unknown",Length[terms]===2&&terms[[2,"Representation"]]==="LaurentSeries"&&terms[[2,"Coefficient","SeriesTruncation"]]===1];
check["tail class survives",terms[[2,"LaurentRemainderClass","Status"]]==="test-source-bound"];
expanded=FeynFacet`ExpandMasterIntegralCoefficient[result["Masters"][[1]],e,{0,1}];
check["materialized requested coefficients",AssociationQ[expanded]&&
 Simplify[expanded["Coefficients"][0]-1/x]===0&&
 Simplify[expanded["Coefficients"][1]+1/x^2+EulerGamma/x]===0];
check["excess order rejected",FailureQ[FeynFacet`ExpandMasterIntegralCoefficient[result["Masters"][[1]],e,{0,2}]]];
check["proof dimensions stay out of arithmetic validation",
 terms[[2,"LaurentRemainderClass","Justification","SourceDimension"]]===System`D];
invalid=Append[traceData,"OutputMetadata"->ReplacePart[traceData["OutputMetadata"],{1,"MasterIndex"}->2]];
check["out of range master index rejected",assemble[invalid,reconstruction]===$Failed];
Print["MIXED RECONSTRUCTION ASSEMBLY TESTS PASS ",count];
