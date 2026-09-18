Print["FEYNFACET DRIVER ENTERED"];$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
a=FeynCalc`GLI[ClosureFixture,{1}];b=FeynCalc`GLI[ClosureFixture,{2}];
c=FeynCalc`GLI[ClosureFixture,{3}];d=FeynCalc`GLI[ClosureFixture,{4}];
r=FeynFacet`Private`ibpCloseReductionRules[
 {a->b/(x-1)-c*(x+1)/(x^2-1)+d,b->c},{a}];
FTTest`FTAssert["transitive rational zero coefficients do not become masters",
 r["Masters"]==={d}&&r["Rules"]==={a->d}];
r=FeynFacet`Private`ibpCloseReductionRules[
 {a->b/(x-1)-c*(x+1)/(x^2-1),b->c},{a}];
FTTest`FTAssert["exactly vanishing target has an empty terminal basis",
 r["Masters"]==={}&&r["Rules"]==={a->0}];
r=FeynFacet`Private`ibpCloseReductionRules[{a->(x-y)c},{a}];
FTTest`FTAssert["generic nonzero coefficients survive even if a sample vanishes",
 r["Masters"]==={c}&&Cancel[Last[First[r["Rules"]]]-(x-y)c]===0];
composed=FeynFacet`Private`cutComposeIntegralReduction[
 <|"Targets"->{a,b},"Masters"->{b},"Rules"->{a->(x+1)b}|>,
 {b->(x-1)/(x^2-1)a,c->y a},{a}];
FTTest`FTAssert["a previously reduced source can become the new master without a rewrite cycle",
 AssociationQ[composed]&&composed["Masters"]==={a}&&
 !MemberQ[First/@composed["Rules"],a]&&
 FeynFacet`Private`ibpCloseReductionRules[composed["Rules"],{a,b,c}]["Masters"]==={a}];
Print["RATIONAL REDUCTION CLOSURE TEST COMPLETE"];FTTest`FTReport[];
