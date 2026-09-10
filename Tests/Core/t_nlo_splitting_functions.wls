(* Universal P1 kernels: independent upstream C++ values and sum rules. *)
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
rows=Import[root<>"/Tests/Support/APFELNLOSplittingReferences.json","RawJSON"];
kernel[d_,p_,spin_,evolution_,n_,tr_:1/2]:=FeynFacet`NextToLeadingSplittingKernel[
 d,p,spin,sx,<|"CA"->3,"CF"->4/3,"TR"->tr,"FlavorCount"->n|>,evolution];
combine[a_,b_,s_:1]:=<|"DeltaCoefficient"->a["DeltaCoefficient"]+s b["DeltaCoefficient"],
 "PlusCoefficients"-><|0->Lookup[a["PlusCoefficients"],0,0]+s Lookup[b["PlusCoefficients"],0,0]|>,
 "RegularCoefficient"->a["RegularCoefficient"]+s b["RegularCoefficient"]|>;
rescale[a_,s_]:=<|"DeltaCoefficient"->s a["DeltaCoefficient"],
 "PlusCoefficients"->(s #&/@a["PlusCoefficients"]),"RegularCoefficient"->s a["RegularCoefficient"]|>;
errors=Table[
 evolution=If[StringStartsQ[row["Class"],"P1T"],"TimeLike","SpaceLike"];
 spin=If[StringStartsQ[row["Class"],"P1pol"],"L","U"];
 channel=StringReplace[row["Class"],StartOfString~~("P1pol"|"P1T"|"P1")->""];
 n=row["FlavorCount"];xx=row["X"];
 aa=kernel[{"q",1},{"q",1},spin,evolution,n];
 ab=kernel[{"qbar",1},{"q",1},spin,evolution,n];
 sea=kernel[{"q",2},{"q",1},spin,evolution,n];
 selected=Switch[channel,
  "nsp",combine[combine[aa,ab],sea,-2],
  "nsm",combine[aa,ab,-1],
  "ps",rescale[sea,2n],
  "qg",If[evolution==="SpaceLike",rescale[kernel[{"q",1},"g",spin,evolution,n],2n],
    rescale[kernel["g",{"q",1},spin,evolution,n],2n]],
  "gq",If[evolution==="SpaceLike",kernel["g",{"q",1},spin,evolution,n],
    kernel[{"q",1},"g",spin,evolution,n]],
  "gg",kernel["g","g",spin,evolution,n]];
 got=N[{selected["RegularCoefficient"],Lookup[selected["PlusCoefficients"],0,0]/(1-sx),
  selected["DeltaCoefficient"]+Lookup[selected["PlusCoefficients"],0,0]Log[1-sx]}/.sx->xx];
 expected=Lookup[row,{"Regular","Singular","Local"}]/4;
 Max[Abs[got-expected]/(1+Abs[expected])],
 {row,rows}];
FTTest`FTAssert["all 324 delta/soft/regular comparisons match upstream C++",Max[errors]<10^-11];
FTTest`FTAssert["all color and flavor expressions are exact",
 FreeQ[kernel[{"q",1},"g","U","TimeLike",nf,tf],_Real]];
FTTest`FTAssert["unsupported timelike helicity is explicit failure",
 FailureQ[kernel["g","g","L","TimeLike",3]]];
moment[row_,order_]:=Module[{regular=Factor[Expand[row["RegularCoefficient"]]],soft},
 soft=Lookup[row["PlusCoefficients"],0,0];
 row["DeltaCoefficient"]-soft HarmonicNumber[order]+
 NIntegrate[Evaluate[sx^order regular],{sx,0,1},Method->{"GlobalAdaptive","SymbolicProcessing"->0},
  AccuracyGoal->8,PrecisionGoal->8,MaxRecursion->16]];
sumRules=Flatten[Table[
 qq=kernel[{"q",1},{"q",1},"U",evolution,3,tt];
 qb=kernel[{"qbar",1},{"q",1},"U",evolution,3,tt];
 qs=kernel[{"q",2},{"q",1},"U",evolution,3,tt];
 gq=kernel["g",{"q",1},"U",evolution,3,tt];
 qg=kernel[{"q",1},"g","U",evolution,3,tt];
 gg=kernel["g","g","U",evolution,3,tt];
 {moment[combine[combine[combine[qq,qb],qs,4],gq],1],
  moment[combine[gg,qg,6],1]},
 {evolution,{"SpaceLike","TimeLike"}},{tt,{1/2,2/5}}]];
Print["Momentum-sum residuals ",sumRules];
FTTest`FTAssert["both parent momentum sum rules hold including restored TR",Max[Abs[sumRules]]<2 10^-7];
uu=combine[kernel[{"q",1},{"q",1},"U","SpaceLike",3],
 kernel[{"qbar",1},{"q",1},"U","SpaceLike",3],-1];
ll=combine[combine[kernel[{"q",1},{"q",1},"L","SpaceLike",3],
 kernel[{"qbar",1},{"q",1},"L","SpaceLike",3]],kernel[{"q",2},{"q",1},"L","SpaceLike",3],-2];
FTTest`FTAssert["valence number and nonsinglet axial charge are conserved",
 Max[Abs[{moment[uu,0],moment[ll,0]}]]<10^-7];
FTTest`FTReport[];
