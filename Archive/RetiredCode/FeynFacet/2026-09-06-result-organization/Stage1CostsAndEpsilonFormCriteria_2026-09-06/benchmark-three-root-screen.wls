
Block[{Print},Get["/home/maxzhang/factorization-and-loops/Addon/Load/LoadFACET.wl"]];
Clear[x,y,eps];roots=<|"Generator"->Sqrt[#],"QuadraticRadicand"->#|>& /@ {1+x,1+y,1+x+y};
letters={x,y,1+Sqrt[1+x],1+Sqrt[1+y],1+Sqrt[1+x+y],x+y+Sqrt[1+x+y]};
forms=Table[D[Log[l],v],{l,letters},{v,{x,y}}];
e=Table[DiagonalMatrix[Table[Sum[(i+k) forms[[k,mu]],{k,6}],{i,4}]],{mu,2}];
c=Table[DiagonalMatrix[Table[Sum[(2j-k) forms[[k,mu]],{k,6}],{j,2}]],{mu,2}];
g=Table[(i*x+j*y+Sqrt[1+x]Sqrt[1+y]Sqrt[1+x+y])/(1+x+y),{i,4},{j,2}];
res=Table[Table[i+j+k,{i,4},{j,2}],{k,6}];
b=Table[D[g,{x,y}[[mu]]]-eps(e[[mu]].g-g.c[[mu]])+eps Sum[res[[k]]forms[[k,mu]],{k,6}],{mu,2}];
record=<|"Variables"->{x,y},"Regulator"->eps,"OffDiagonalBlockEquation"->{e,c,b}|>;
lr=MapThread[<|"Letter"->#1,"OneForm"->#2|>&,{letters,forms}];
path="FeynFacet/Private/EpsForm/Multiquadratic/MultiquadraticOffDiagonalBlockScreens.wl";
results={};
Do[
 file=If[version==="Before","/tmp/feynfacet-stage1-20260906/before/","/home/maxzhang/factorization-and-loops/"]<>path;
 Block[{$Context="FeynFacet`Private`",$ContextPath={"System`","FeynFacet`"}},Get[file]];
 Do[
 FeynFacet`Private`multiquadraticOffDiagonalBlockScreenCompileCacheClear[];
 {seconds,answer}=AbsoluteTiming[
 FeynFacet`Private`multiquadraticOffDiagonalBlockIntegrabilityScreen[record,roots,lr,
 "PointCount"->12,"ScoreLetters"->score,"Prime"->1000003,"RegulatorValue"->1/13]];
 row=Join[<|"Version"->version,"ScoreLetters"->score,"MeasuredSeconds"->seconds|>,
 KeyTake[answer,{"Status","Reason","Rank","AugmentedRank","Defect","MatrixDimensions","PhaseTimings","PointCount","RootCount"}]];
 AppendTo[results,row];Print[row],{score,{True,False}}],
 {version,{"Before","After"}}];
Export["/tmp/feynfacet-stage1-20260906/three-root-screen-benchmark.wxf",results,"WXF"];
Export["/tmp/feynfacet-stage1-20260906/three-root-screen-benchmark.json",results,"RawJSON"];
Exit[If[AllTrue[results,Lookup[#,"Defect",1]===0&],0,1]];
