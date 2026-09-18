Print["FEYNFACET DRIVER ENTERED"];$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
values=Flatten[ConstantArray[{0,(bx^2-1)/(bx-1),1},40001]];
result=FeynFacet`CancelRationalExpressions[values,{bx}];
FTTest`FTAssert["a repeated matrix larger than the native limit retains its order",
 ListQ[result]&&Length[result]===120003&&
 result===Flatten[ConstantArray[{0,1+bx,1},40001]]];
expressions=Table[(bx^(j+1)-1)/(bx-1),{j,1,8}];
batched=Block[{FeynFacet`Private`$rationalFunctionBatchSize=3},
 FeynFacet`CancelRationalExpressions[expressions,{bx}]];
FTTest`FTAssert["distinct inputs are processed in bounded exact batches",
 ListQ[batched]&&AllTrue[MapThread[Together[#1-#2]&,{batched,expressions}],#===0&]];
series=Block[{FeynFacet`Private`$rationalFunctionBatchSize=2},
 FeynFacet`RationalLaurentCoefficients[{1/be,1/(1-be),1/be,1/(1-2be)},{be},be,{-1,2}]];
FTTest`FTAssert["batching and deduplication preserve vector Laurent coefficients",
 series==={<|-1->1,0->0,1->0,2->0|>,<|-1->0,0->1,1->1,2->1|>,
  <|-1->1,0->0,1->0,2->0|>,<|-1->0,0->1,1->2,2->4|>}];
failure=Internal`InheritedBlock[{FeynFacet`Private`rationalFunctionRunChunk},
 Clear[FeynFacet`Private`rationalFunctionRunChunk];calls=0;
 FeynFacet`Private`rationalFunctionRunChunk[items_List,_List,_List]:=
  If[++calls===2,Failure["ExpectedSecondBatchFailure",<||>],items];
 Block[{FeynFacet`Private`$rationalFunctionBatchSize=2},
  FeynFacet`CancelRationalExpressions[{bx,bx^2,bx^3,bx^4,bx^5},{bx}]]];
FTTest`FTAssert["a failed later batch stops the whole exact operation",
 MatchQ[failure,Failure["ExpectedSecondBatchFailure",_]]&&calls===2];
FTTest`FTReport[];
