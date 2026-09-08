$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
Clear[e,z,v,s];
x=s^(2+2e)*Pi^(3-2e)/(z^3*(1-v-z));
a=FeynFacet`Private`scalarEndpointNormalSeries[x,z,-4,-1];
FTAssert["normal rational recurrence retains analytic epsilon-dependent coefficient-field units",
 And@@Table[FullSimplify[a[k]-SeriesCoefficient[x,{z,0,k}]]===0,{k,-4,-1}]];
x=Sqrt[1-z]/z^2;
a=FeynFacet`Private`scalarEndpointNormalSeries[x,z,-2,-1];
FTAssert["a root depending on the normal coordinate uses its actual Taylor coefficients",
 Values[a]==={1,-1/2}];
x=FeynFacet`f1[xa]/(z*(1-v-z));
a=FeynFacet`Private`scalarEndpointNormalSeries[x,z,-1,-1];
FTAssert["external field functions remain explicit after rational expansion",
 Cancel[Together[a[-1]-FeynFacet`f1[xa]/(1-v)]]===0&&
 FreeQ[a,_Series|_SeriesCoefficient|_SeriesData]];
FTAssert["temporary field symbols do not remain in the coefficients",
 !AnyTrue[Cases[a,_Symbol,Infinity],StringStartsQ[SymbolName[#],"coefficientField$"]&]];
FTReport[];
