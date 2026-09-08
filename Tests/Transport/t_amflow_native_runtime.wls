$HistoryLength=0;
Get[DirectoryName[ExpandFileName[$InputFileName],3]<>"/FeynFacet/Interfaces/AMFlowRuntime.wl"];
Begin["FeynFacetNativeRuntimeTest`"];
args=Rest[$ScriptCommandLine];If[Length[args]!=1,Print["Expected native AMFlow directory"];Exit[2]];
native=ExpandFileName[First[args]];
folder=CreateDirectory[];script=folder<>"/native.wls";marker=folder<>"/result.wl";
before=Links[];pass=0;failed=0;
check[name_,condition_]:=If[TrueQ[condition],pass++;Print["PASS ",name],failed++;Print["FAIL ",name]];
DESolver`Private`regularexpansion[x___]:=preservedParentFunction;
Options[DESolver`Private`regularexpansion]={"Preserved"->17};
runtime=DirectoryName[ExpandFileName[$InputFileName],3]<>"/FeynFacet/Interfaces/AMFlowRuntime.wl";
body="Global`initialLinks={callerNameCollision};Global`execution=17;Get["<>ToString[runtime,InputForm]<>"];
Get["<>ToString[native<>"/diffeq_solver/DESolver.m",InputForm]<>"];
DESolver`SetDefaultOptions[];
DESolver`SetGlobalOptions[\"WorkingPre\"->40,\"Solver\"->\"CPP\",\"SilentMode\"->True];
DESolver`SetExpansionOptions[\"XOrder\"->5];
DESolver`LoadSystem[1,{{1/(1+DESolver`eta)}},{1},0];
DESolver`CalcRegExp[1];
Put[DESolver`RegExp[1],"<>ToString[marker,InputForm]<>"];";
Do[
 Export[script,body<>ending,"Text"];
 result=FeynFacet`Private`runIsolatedWolframScript[script,{},folder<>"/native.log"];
 coefficients=Flatten[Get[marker]];
 check[ending<>" native operation solves y'=y/(1+x)",Length[coefficients]===6&&
   Max[Abs[coefficients-{1,1,0,0,0,0}]]<10^-25&&TrueQ[result["NativeLinkUsed"]]];
 check[ending<>" native link disposed before restoring caller definitions",Links[]===before&&
  DESolver`Private`regularexpansion[1]===preservedParentFunction&&
  Options[DESolver`Private`regularexpansion]==={"Preserved"->17}];
 check[ending<>" exit status",result["ExitCode"]===If[ending==="Quit[0];",0,130]],
 {ending,{"Quit[0];","Abort[];"}}];
If[failed===0,DeleteDirectory[folder,DeleteContents->True],Print[Import[folder<>"/native.log","Text"]]];
Print["ASSERTIONS ",pass+failed," FAILED ",failed];Exit[Boole[failed>0]];
