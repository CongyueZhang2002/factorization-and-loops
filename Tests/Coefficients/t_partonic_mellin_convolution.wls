
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
row[d_,p_,r_]:=<|"DeltaCoefficient"->d,"PlusCoefficients"->p,"RegularCoefficient"->r|>;
sourceRow=row[row[0,<||>,{zz,2zz}],<|0->row[{2,3},<||>,0]|>,
 row[{xx,xx^2},<|0->{xx^2,0}|>,{xx zz,xx^2 zz}]];
meta=<|"Order"->"NLO","Contribution"->"Real","Scale"->q2,"Variables"->{xx,zz},
 "DimensionalRegulator"->ee,"StructureFunctions"->{"A","B"},
 "DistributionBasis"-><|"Axes"->{<|"Variable"->xx,"Endpoint"->1,"Interval"->{0,1},"Distance"->1-xx|>,
  <|"Variable"->zz,"Endpoint"->1,"Interval"->{0,1},"Distance"->1-zz|>}|>|>;
source=FeynFacet`CreatePartonicResult[<|0->sourceRow,1->sourceRow|>,meta];
plusX=Join[row[0,<|0->1|>,0],<|"Variable"->xx|>];
polyZ=Join[row[0,<||>,zz],<|"Variable"->zz|>];
result=FeynFacet`ConvolvePartonicMellinKernel[source,plusX,xx,{0,1}];
cx=1-xx-xx Log[xx]+xx Log[1-xx];
FTTest`FTAssert["the active coordinate in a vector coefficient is convoluted",
 AssociationQ[result]&&Simplify[result["Coefficients"][0]["RegularCoefficient"]["RegularCoefficient"][[1]]-zz cx,0<xx<1]===0];
FTTest`FTAssert["delta and plus terms from the convolution stay on their own axis",
 AssociationQ[result]&&result["Coefficients"][0]["PlusCoefficients"][1]["DeltaCoefficient"]==={4,6}&&
 Simplify[result["Coefficients"][0]["DeltaCoefficient"]["DeltaCoefficient"]+Zeta[2]{2,3}]==={0,0}];
xz=FeynFacet`ConvolvePartonicMellinKernel[result,polyZ,zz,{0,0}];
zx=FeynFacet`ConvolvePartonicMellinKernel[
 FeynFacet`ConvolvePartonicMellinKernel[source,polyZ,zz,{0,0}],plusX,xx,{0,0}];
difference=FeynFacet`Private`partonicDistributionSum[{
 xz["Coefficients"][0],FeynFacet`Private`partonicMap[Function[v,-v],zx["Coefficients"][0]]},2];
leaves=Last/@FeynFacet`Private`partonicDistributionTerms[difference,2];
FTTest`FTAssert["convolutions on independent axes commute with mixed coefficient dependence",
 AssociationQ[xz]&&AssociationQ[zx]&&And@@Flatten[Map[Simplify[#==0,0<xx<1&&0<zz<1]&,Flatten[leaves]]]];
FTTest`FTAssert["missing epsilon orders are rejected",
 FailureQ[FeynFacet`ConvolvePartonicMellinKernel[source,plusX,xx,{0,2}]]];
FTTest`FTReport[];
