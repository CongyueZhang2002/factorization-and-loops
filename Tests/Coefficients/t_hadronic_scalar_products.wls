Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
setup=FeynFacet`ReadProcessCard[root<>"/Projects/ppHX_UU/Raw/NLO/qqp-qqp","Real"];
context=FeynFacet`BuildSimplificationContext[setup];data=context["HadronicVariables"];
a=FeynCalc`SPD[Global`ka,Global`kb];b=FeynCalc`SPD[Global`kc,Global`nhb];
expr=(a+b)^2/(1+a)+a*b+a^3;
old=FeynFacet`Private`applyHadronicVariables[expr,data];
new=FeynFacet`Private`finiteFieldHadronicVariables[expr,data];
FTTest`FTAssert["repeated scalar products have the exact original kinematic image",Cancel[new-old]===0];
expr=FeynCalc`FV[Global`ka,Global`mu]*a;
FTTest`FTAssert["other tensor structures use the original evaluator",
 FeynFacet`Private`finiteFieldHadronicVariables[expr,data]===FeynFacet`Private`applyHadronicVariables[expr,data]];
expr=Global`ka*a;
FTTest`FTAssert["a momentum outside scalar products uses the original evaluator",
 FeynFacet`Private`finiteFieldHadronicVariables[expr,data]===FeynFacet`Private`applyHadronicVariables[expr,data]];
expr=Gamma[1+e]*(1+x)/(1-y);
FTTest`FTAssert["scalar analytic functions are unchanged",FeynFacet`Private`finiteFieldHadronicVariables[expr,data]===expr];
degenerate=<|"Coordinates"-><|p->{1,1,0,0},r->{1,1,0,0},q->{1,-1,0,0}|>,
 "Assumptions"->True|>;
expr=FeynCalc`SPD[p,q]/FeynCalc`SPD[r,q];
FTTest`FTAssert["a singular intermediate image preserves whole-expression cancellation",
 FeynFacet`Private`applyHadronicVariables[expr,degenerate]===1&&
 FeynFacet`Private`finiteFieldHadronicVariables[expr,degenerate]===1];
FTTest`FTReport[];
