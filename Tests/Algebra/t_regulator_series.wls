$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
rs=FeynFacet`Private`regulatorSeries;
FTTest`FTAssert["both coefficient interfaces reject an essential regulator singularity",
 FailureQ[rs[Exp[1/rsEps],rsEps,2]]&&FailureQ[rs[Exp[1/rsEps],rsEps,2,{-2,2}]]];
FTTest`FTAssert["logarithmic and fractional regulator dependence are not Laurent coefficients",
 FailureQ[rs[Log[rsEps],rsEps,2]]&&FailureQ[rs[Sqrt[rsEps],rsEps,2]]];
rsGamma=rs[Gamma[1+rsEps]/rsEps^2,rsEps,0];
FTTest`FTAssert["meromorphic Gamma factors retain their pole and finite coefficient",
 ListQ[rsGamma]&&First[rsGamma]===-2&&
 Expand[Last[rsGamma]-(rsEps^-2-EulerGamma/rsEps+EulerGamma^2/2+Pi^2/12)]===0];
rsRational=rs[(1+rsEps)/(rsEps^2(1-rsEps)),rsEps,1,{-3,1}];
FTTest`FTAssert["rational poles and known-zero prefixes remain exact",
 rsRational===<|-3->0,-2->1,-1->2,0->2,1->2|>];
rsBeyond=rs[rsEps^5 Exp[rsEps],rsEps,2];
FTTest`FTAssert["a regular omitted Taylor tail has an explicit finite lower bound",
 ListQ[rsBeyond]&&IntegerQ[First[rsBeyond]]&&First[rsBeyond]>=3&&Last[rsBeyond]===0];
rsCoefficient=PolyLog[2,rsX]+Log[rsY]^2;
FTTest`FTAssert["epsilon-independent special functions are restored unchanged",
 rs[rsCoefficient Exp[rsEps],rsEps,1] === {0,rsCoefficient(1+rsEps)}||
 Expand[Last[rs[rsCoefficient Exp[rsEps],rsEps,1]]-rsCoefficient(1+rsEps)]===0];
FTTest`FTReport[];
