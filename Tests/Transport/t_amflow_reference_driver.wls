#!/usr/bin/env wolframscript
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
work=CreateDirectory[];
amf=CreateDirectory[work<>"/amflow"];
requestFile=work<>"/request.wl";outputFile=work<>"/result.wxf";
marker=work<>"/runtime_loads.txt";
(* Load the actual vendor Laurent fit, replacing only the costly integration.
   The shim also requires the restored q^2 form used to recognize cut lines. *)
shim="Get["<>ToString[InputForm[root<>"/Addon/Mathematica_Addon/AMFlow/AMFlow.m"]]<>"];
PutAppend[1,"<>ToString[InputForm[marker]]<>"];
Clear[AMFlow`BlackBoxAMFlow];
AMFlow`BlackBoxAMFlow[targets_,samples_] := Module[{p=AMFlow`AMFlowInfo[\"Propagator\"]},
 If[Expand[p[[3]]-(pp-kl-ll)^2]=!=0,Abort[]];
 Thread[targets->ConstantArray[(3/#^2+5/#+7+11#+13#^2& /@ samples),Length[targets]]]];
";
Export[amf<>"/AMFlow.m",shim,"Text"];
def=<|"DimensionalRegulator"->ee,"Dimension"->4-2ee,"LoopMomenta"->{kl,ll},
 "ExternalMomenta"->{pp},"KinematicRules"->{pp^2->ss},
 "InversePropagators"->{kl^2,ll^2,ss-2pp kl-2pp ll+kl^2+2kl ll+ll^2},
 "PropagatorMomenta"->{kl,ll,pp-kl-ll},"PropagatorTypes"->ConstantArray["QuadraticLorentzian",3],
 "CutIndices"->{1,2,3},"Prescription"->{0,0},"MomentumSpaceConvention"->"AMFlow",
 "MasterIntegralPrefactor"->1/ee|>;
request=<|"IntegralDefinition"->def,"WorkingDirectory"->work<>"/calculation",
 "Point"->{1/2},"KinematicVariables"->{ss},"MasterIntegralBasis"->{FeynCalc`GLI[testFamily,{1,1,1}]},
 "PrecisionGoal"->25,"EpsilonOrder"->1,"EpsilonLowerOrders"->{-3},
 "AMFlowPath"->amf,"KiraExecutable"->root<>"/Addon/Other_Addon/Kira/bin/kira",
 "FermatExecutable"->root<>"/Addon/Other_Addon/Kira/bin/fer64"|>;
Put[request,requestFile];
(* An old zero export with otherwise matching metadata must not be reused. *)
old=<|"Status"->"AMFlowMastersEvaluated","IntegralDefinition"->def,"Point"->{1/2},
 "KinematicVariables"->{ss},"OriginalMasterIntegralBasis"->request["MasterIntegralBasis"],
 "MasterIntegralPrefactors"->{1/ee},"EpsilonOrder"->1,"PrecisionGoal"->25,
 "RowIndices"->{1},"DimensionalRegulator"->ee,"MasterIntegralValues"->{0}|>;
Export[outputFile,old,"WXF"];
run[] := RunProcess[{"wolframscript","-file",root<>"/Scripts/Transport/evaluate_masters_with_amflow.wls",requestFile,outputFile}];
process=run[];
If[process["ExitCode"]=!=0,Print[process["StandardOutput"],process["StandardError"]]];
value=Import[outputFile,"WXF"];
FTAssert["old AMFlow exports without an order convention are recomputed",
 process["ExitCode"]===0 && value["AMFlowOrderConvention"]==="OffsetFromMinusTwoLoops" &&
 !TrueQ[Lookup[value,"ReusedComputedLaurentExpansion",False]] && FileExistsQ[marker]];
expected=3/ee^3+5/ee^2+7/ee+11+13ee;
FTAssert["master prefactor poles increase the native AMFlow upper power",
 value["NativeEpsilonUpperOrder"]===2 && value["AMFlowExpansionOrder"]===6 &&
 Max[Abs[Table[Coefficient[First[value["MasterIntegralValues"]]-expected,ee,k],{k,-3,1}]]]<10^-20];
markerBefore=Import[marker,"Text"];process=run[];value=Import[outputFile,"WXF"];
FTAssert["a corrected complete export is reused without loading AMFlow",
 process["ExitCode"]===0 && TrueQ[value["ReusedComputedLaurentExpansion"]] &&
 Import[marker,"Text"]===markerBefore];
(* A vendor abort must never exit successfully or overwrite a valid result. *)
Put[Join[request,<|"EpsilonOrder"->2|>],requestFile];
Export[amf<>"/AMFlow.m",shim<>"Clear[AMFlow`BlackBoxAMFlow];AMFlow`BlackBoxAMFlow[___]:=Abort[];","Text"];
process=run[];
FTAssert["a vendor abort returns a failure and preserves the prior result",
 process["ExitCode"]===1 && FileExistsQ[outputFile<>".failure.wxf"] &&
 MatchQ[Import[outputFile<>".failure.wxf","WXF"],Failure["AMFlowEvaluationAborted",_Association]] &&
 Import[outputFile,"WXF"]===value];
DeleteDirectory[work,DeleteContents->True];
FTReport[];
