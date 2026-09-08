#!/usr/bin/env wolframscript
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Get[root<>"/FeynFacet/Interfaces/AMFlowRuntime.wl"];
Internal`InheritedBlock[{Kernels,CloseKernels,AMFlow`RunCommand},
 Unprotect[Kernels,CloseKernels];Clear[Kernels,CloseKernels,AMFlow`RunCommand];
 fake={1};closed={};Kernels[]:=fake;
 CloseKernels[ks_List]:=(closed=Join[closed,ks];fake=Complement[fake,ks]);
 Options[AMFlow`RunCommand]={"log"->False,ProcessDirectory->Inherited};
 AMFlow`RunCommand[command_,OptionsPattern[]]:={Kernels[],OptionValue["log"]};
 original=DownValues[AMFlow`RunCommand];
 originalOptions=Options[AMFlow`RunCommand];
 result=FeynFacet`Private`withAMFlowKernelRelease[
  fake={1,2,3};AMFlow`RunCommand[{"/test/WolframKernel","-script","solution.wl"},"log"->"test.log"]];
 FTAssert["only invocation-owned workers are released before the Wolfram child",
  result==={{1},"test.log"}&&closed==={2,3}&&fake==={1}];
 FTAssert["AMFlow command implementation and options are restored",
  DownValues[AMFlow`RunCommand]===original&&Options[AMFlow`RunCommand]===originalOptions];
 closed={};
 result=FeynFacet`Private`withAMFlowKernelRelease[
  fake={1,4};AMFlow`RunCommand[{"/test/kira","jobs.yaml"}]];
 FTAssert["reduction workers remain available during Kira and are cleaned up afterwards",
  result==={{1,4},False}&&closed==={4}&&fake==={1}];
 closed={};
 result=Catch[FeynFacet`Private`withAMFlowKernelRelease[fake={1,5};Throw["interrupted"]]];
 FTAssert["cleanup also runs on an interrupted evaluation",
  result==="interrupted"&&fake==={1}&&closed==={5}&&DownValues[AMFlow`RunCommand]===original];
];FTReport[];
