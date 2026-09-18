Print["FEYNFACET DRIVER ENTERED"];

$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
colors=<|"CA"->3,"CF"->4/3,"TR"->1/2,"FlavorCount"->1|>;
request=<|"Evolution"->"SpaceLike","OperatorScheme"->"MSbar"|>;
zker[d_,p_,order_,extra_:<||>,spin_:"U"]:=FeynFacet`CollinearRenormalizationKernel[
 d,p,spin,xx,ee,colors,order,Join[request,extra]];
rowSum[rows_]:=FeynFacet`Private`partonicDistributionSum[rows,1];
rowScale[row_,c_]:=FeynFacet`Private`partonicMap[Function[value,c value],row];
zeroRowQ[row_]:=AllTrue[Flatten[{row["DeltaCoefficient"],Values[row["PlusCoefficients"]],row["RegularCoefficient"]}],
 TrueQ[Simplify[#,0<xx<1&&ee!=0]===0]&];
p0=FeynFacet`LeadingSplittingKernel[{"q",1},{"q",1},"U",xx,colors];
z1=zker[{"q",1},{"q",1},1,<|"ScaleLog"->lf|>];
FTTest`FTAssert["the one-loop kernel includes the declared scale and pole",
 zeroRowQ[rowSum[{z1,rowScale[p0,-Exp[-ee lf]/ee]}]]];
z2=zker[{"q",1},{"q",1},2];
inverse=zker[{"q",1},{"q",1},2,<|"Inverse"->True|>];
matrixProduct=rowSum[Table[
 FeynFacet`MellinConvolveDistributions[zker[{"q",1},j,1],zker[j,{"q",1},1],xx],
 {j,{{"q",1},{"qb",1},"g"}}]];
FTTest`FTAssert["Z inverse cancels through a squared including gluon mixing",
 AssociationQ[z2]&&zeroRowQ[rowSum[{z2,inverse,rowScale[matrixProduct,-1]}]]];
z2scale=zker[{"q",1},{"q",1},2,<|"ScaleLog"->lf|>];
b0=(11colors["CA"]-4colors["TR"]colors["FlavorCount"])/6;
dscale=FeynFacet`Private`partonicMap[Function[value,D[value,lf]],z2scale];
FTTest`FTAssert["unequal scales include coupling running",
 zeroRowQ[rowSum[{dscale,rowScale[z2scale,2ee],rowScale[z1,b0]}]]];
raw=zker[{"q",1},"g",2,<|"OperatorScheme"->"Larin"|>,"L"];
ms=zker[{"q",1},"g",2,<|"OperatorScheme"->"HelicityMSbar"|>,"L"];
finite=FeynFacet`FactorizationSchemeKernel["HelicityMSbar",{"q",1},{"q",1},"L",xx,colors,1];
mix=FeynFacet`LeadingSplittingKernel[{"q",1},"g","L",xx,colors];
comm=FeynFacet`MellinConvolveDistributions[finite,mix,xx];
FTTest`FTAssert["raw helicity mixing contains the noncommuting finite transformation",
 zeroRowQ[rowSum[{rowScale[raw,2ee],rowScale[ms,-2ee],comm}]]];
gg=zker["g","g",2];
FTTest`FTAssert["all intermediate flavors are present even without a gluon Born coefficient",
 AssociationQ[gg]&&!FreeQ[gg["RegularCoefficient"],Log[xx]]];
FTTest`FTAssert["helicity pole kernels require an explicit operator scheme",
 FailureQ[zker[{"q",1},"g",2,<||>,"L"]]];
pdfDistribution=FeynFacet`PDFCountertermDistribution[{"q",1},{"q",1},
 <|"Spin"->"U","Variable"->xx,"DimensionalRegulator"->ee,"KernelParameters"->colors,
 "PerturbativeOrder"->2,"ScaleLog"->lf,"OperatorScheme"->"MSbar"|>];
FTTest`FTAssert["the PDF distribution exposes the complete NNLO operator counterterm",
 AssociationQ[pdfDistribution]&&pdfDistribution["Role"]==="PDF"&&
 pdfDistribution["Daughter"]==={"q",1}&&pdfDistribution["Parent"]==={"q",1}&&
 zeroRowQ[rowSum[{pdfDistribution,rowScale[z2scale,-1]}]]];
FTTest`FTReport[];
