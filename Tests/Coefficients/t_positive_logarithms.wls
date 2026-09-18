Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
plA=FeynFacet`ExpandPositiveLogarithms[Log[plQ^2/plMu^2]+2Log[plMu]-2Log[plQ],plQ>0&&plMu>0];
FTTest`FTAssert["positive scale logarithms cancel before a regular endpoint is split",
 plA===0];
plB=FeynFacet`ExpandPositiveLogarithms[Log[-plQ/plZ],plQ>0&&0<plZ<1];
FTTest`FTAssert["a negative real argument retains its principal phase",
 Expand[plB-(I Pi+Log[plQ]-Log[plZ])]===0];
plC=FeynFacet`ExpandPositiveLogarithms[Log[plQ plUnknown],plQ>0];
FTTest`FTAssert["an unproved complex factor is kept on its original branch",
 plC===Log[plQ]+Log[plUnknown]&&
 Abs[N[(plC-Log[plQ plUnknown])/.{plQ->7/3,plUnknown->-2-I},30]]<10^-25];
plD=FeynFacet`ExpandPositiveLogarithms[Log[Abs[(plX-plZ)/(1-plZ)]],0<plX<1&&0<plZ<1];
FTTest`FTAssert["a logarithm on a removable kinematic divisor is retained without a global exclusion",
 FreeQ[plD,_Failure]&&Abs[N[(plD-Log[Abs[(plX-plZ)/(1-plZ)]])/.{plX->1/3,plZ->2/5},30]]<10^-25];
FTTest`FTAssert["positive numerical factors use a common prime logarithm basis",
 FeynFacet`ExpandPositiveLogarithms[Log[8plQ]-3Log[2]-Log[plQ],plQ>0]===0];
Print["POSITIVE LOGARITHM TEST COMPLETE"];
FTTest`FTReport[];
