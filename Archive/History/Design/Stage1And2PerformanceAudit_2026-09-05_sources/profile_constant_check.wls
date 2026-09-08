
$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[FileNameJoin[{root,"Addon","Load","LoadFACET.wl"}]]];
data=Import[FileNameJoin[{root,"ppHX_NNLO_DoubleReal","Results","RequestedMasterIntegralSolutions","CF48","solution.wxf"}],"WXF"];
SpeedAudit`times=<||>;SpeedAudit`counts=<||>;
SetAttributes[SpeedAudit`timed,HoldRest];
SpeedAudit`timed[name_,expr_] := Module[{a=AbsoluteTime[],v,delta},
 v=expr;delta=N[AbsoluteTime[]-a];
 AssociateTo[SpeedAudit`times,name->Lookup[SpeedAudit`times,name,0.]+delta];
 AssociateTo[SpeedAudit`counts,name->Lookup[SpeedAudit`counts,name,0]+1];v];
SpeedAudit`poly[args___]:=SpeedAudit`timed["PolynomialQ",PolynomialQ[args]];
SpeedAudit`exponent[args___]:=SpeedAudit`timed["Exponent",Exponent[args]];
SpeedAudit`coefficient[args___]:=SpeedAudit`timed["Coefficient",Coefficient[args]];
SpeedAudit`explicit[args___]:=SpeedAudit`timed["ExplicitExpression",FeynFacet`Private`solutionExplicitExpressionQ[args]];
DownValues[FeynFacet`Private`solutionExpandedCoefficientsQ]=
 DownValues[FeynFacet`Private`solutionExpandedCoefficientsQ]/.{
 PolynomialQ->SpeedAudit`poly,Exponent->SpeedAudit`exponent,Coefficient->SpeedAudit`coefficient,
 FeynFacet`Private`solutionExplicitExpressionQ->SpeedAudit`explicit};
elapsed=First[AbsoluteTiming[ok=FeynFacet`Private`solutionExpandedCoefficientsQ[data]]];
report=<|"Family"->"CF48","Valid"->ok,"TotalSeconds"->elapsed,
 "InclusiveSeconds"->SpeedAudit`times,"Calls"->SpeedAudit`counts,
 "MasterCoefficientBytes"->ByteCount[data["MasterIntegralCoefficients"]]|>;
Export[DirectoryName[ExpandFileName[$InputFileName]]<>"/CF48-constant-check-profile.json",report,"RawJSON"];Print[InputForm[report]];
If[!TrueQ[ok],Exit[1]];
