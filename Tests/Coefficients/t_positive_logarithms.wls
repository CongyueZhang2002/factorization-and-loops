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
FTTest`FTReport[];
