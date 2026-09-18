Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
card=FeynFacet`ReadContributionCard[root<>"/Projects/ppHX_TT_SpinTransfer/Raw/LO/qg-qg","Born"];
setup=FeynFacet`ReadProcessCard[card];
captured={};
DownValues[baselineFORM]=DownValues[FeynFacet`EvaluateFORMDiracExpression]/.
 FeynFacet`EvaluateFORMDiracExpression->baselineFORM;
{seconds,born}=AbsoluteTiming[Internal`InheritedBlock[{FeynFacet`EvaluateFORMDiracExpression},
 Clear[FeynFacet`EvaluateFORMDiracExpression];
 FeynFacet`EvaluateFORMDiracExpression[expression_,request_Association]:=Module[{answer},
  answer=baselineFORM[expression,request];
  AppendTo[captured,<|"Expression"->expression,"Request"->request,"Result"->answer|>];answer];
 FeynFacet`ConstructBornInvariantDensity[setup,<|"Scale"->s,"MandelstamVariables"->{s,t,u},
  "DimensionalRegulator"->Global`Epsilon|>]]];
Print["POLARIZED BORN SECONDS ",seconds," FORM CALLS ",Length[captured]];
FTAssert["the complete generated transverse-transfer quark-gluon Born density is nonzero",
 AssociationQ[born]&&born["Coefficient"]=!=0&&Length[captured]>0];
Do[
 item=captured[[i]];
 {referenceSeconds,reference}=AbsoluteTiming[baselineFORM[item["Expression"],
  Join[item["Request"],<|"Gamma5TraceMethod"->"FeynCalc"|>]]];
 residual=If[AssociationQ[reference]&&AssociationQ[item["Result"]],
  FeynFacet`CancelRationalCoefficients[{item["Result"]["Value"]-reference["Value"]}],$Failed];
 FTAssert["generated Born interference agrees exactly with independent FeynCalc BMHV traces "<>ToString[i],
  residual==={0}];
 Print["REFERENCE TRACE SECONDS ",referenceSeconds],
{i,Length[captured]}];
FTReport[];
