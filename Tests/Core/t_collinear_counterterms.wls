Print["FEYNFACET DRIVER ENTERED"];
root=DirectoryName[ExpandFileName[$InputFileName],3];$HistoryLength=0;$MaxExtraPrecision=50;
Get[root<>"/Tests/TestKit.wl"];Get[root<>"/FeynFacet/Coefficients/PartonicResults.wl"];Get[root<>"/FeynFacet/Physics/Counterterms.wl"];
Get[root<>"/Tests/Support/BornCollinearReference.wl"];
colors=<|"CA"->ca,"CF"->cf,"TR"->tr,"FlavorCount"->nf|>;
qq=FeynFacet`LeadingSplittingKernel[{"q",1},{"q",1},"U",xi,colors];
gq=FeynFacet`LeadingSplittingKernel["g",{"q",1},"U",xi,colors];
qg=FeynFacet`LeadingSplittingKernel[{"q",1},"g","U",xi,colors];
gg=FeynFacet`LeadingSplittingKernel["g","g","U",xi,colors];
moment[k_,power_]:=k["DeltaCoefficient"]+Total[KeyValueMap[#2 Integrate[Log[1-xi]^#1 (xi^power-1)/(1-xi),{xi,0,1}]&,k["PlusCoefficients"]]]+Integrate[xi^power k["RegularCoefficient"],{xi,0,1}];
FTTest`FTAssert["quark number conservation",Simplify[moment[qq,0]]===0];
FTTest`FTAssert["quark momentum conservation includes g daughter",Simplify[moment[qq,1]+moment[gq,1]]===0];
FTTest`FTAssert["gluon momentum conservation includes individual q and antiquark species",Simplify[moment[gg,1]+2nf moment[qg,1]]===0];
FTTest`FTAssert["helicity g from q uses polarized mixing",FeynFacet`LeadingSplittingKernel["g",{"q",1},"L",xi,colors]["RegularCoefficient"]===cf(2-xi)];
FTTest`FTAssert["no gluon transversity mixing",FeynFacet`LeadingSplittingKernel["g",{"q",1},"T",xi,colors]["RegularCoefficient"]===0];
FTTest`FTAssert["different quark flavors do not mix at LO",FeynFacet`LeadingSplittingKernel[{"q",2},{"q",1},"U",xi,colors]["RegularCoefficient"]===0];
restoration=FeynFacet`FactorizationSchemeKernel["HelicityMSbar",{"q",1},{"q",1},"L",xi,colors];
FTTest`FTAssert["BMHV finite redefinition has explicit convention",restoration["RegularCoefficient"]===-4cf(1-xi)];
FTTest`FTAssert["unpolarized FF gets no helicity restoration",FeynFacet`FactorizationSchemeKernel["HelicityMSbar",{"q",1},{"q",1},"U",xi,colors]["RegularCoefficient"]===0];
born=FeynFacet`CreatePartonicResult[<|0-><|"DeltaCoefficient"->1/(sb vb),"PlusCoefficients"-><||>,"RegularCoefficient"->0|>|>,
 <|"Order"->"LO","Contribution"->"Born","Scale"->sb,"Variables"->{vb,wb},"MandelstamVariables"->{sb,tb,ub},"DimensionalRegulator"->ep|>];
unit=<|"Variable"->xi,"DeltaCoefficient"->0,"PlusCoefficients"-><|0->1|>,"RegularCoefficient"->0|>;
requests=Association@Table[leg-><|"Leg"->leg,"Scale"->scale,"Variables"->{v,w}|>,{leg,{"IncomingA","IncomingB","Observed"}}];
outputs=FTBornCollinearReference`ConvolveBornCollinearKernel[born,unit,#]& /@ requests;
FTTest`FTAssert["all three rescalings return explicit output",FreeQ[outputs,_Failure|_Integrate|_SeriesData]];
FTTest`FTAssert["incoming A plus needs no extra delta",outputs["IncomingA"]["DeltaCoefficient"]===0];
FTTest`FTAssert["FF plus pullback includes finite interval delta",Simplify[outputs["Observed"]["DeltaCoefficient"]-Log[v]/(scale v)]===0];
FTTest`FTAssert["incoming B nonlinear pullback includes endpoint slope",Simplify[outputs["IncomingB"]["DeltaCoefficient"]-Log[v/(1-v)]/(scale v),0<v<1]===0];
FTTest`FTAssert["FF retains dimensional observed measure",Simplify[D[outputs["Observed"]["CollinearMap"]["MeasureWeight"],ep]/outputs["Observed"]["CollinearMap"]["MeasureWeight"]-2Log[1-v+v w]]===0];
logKernel=Join[unit,<|"PlusCoefficients"-><|1->1|>|>];
logOutput=FTBornCollinearReference`ConvolveBornCollinearKernel[born,logKernel,requests["Observed"]];
FTTest`FTAssert["log plus pullback carries delta log squared",Simplify[logOutput["DeltaCoefficient"]-Log[v]^2/(2scale v)]===0];
(* Independent test-function action: integrate in xi, eliminating the Born
   delta in w; compare with the returned distributions acting in w. *)
outputAction[out_,phi_]:=Module[{fixed=out/.{scale->1,v->1/4,ep->1/2}},
 fixed["DeltaCoefficient"](phi/.w->1)+Total[KeyValueMap[#2 Integrate[Log[1-w]^#1 (phi-(phi/.w->1))/(1-w),{w,0,1}]&,fixed["PlusCoefficients"]]]+
 Integrate[FullSimplify[fixed["RegularCoefficient"]]phi,{w,0,1}]];
Do[
 direct=Integrate[(4/xi ((xi-3/4)/(xi/4))^power-4)/(1-xi),{xi,3/4,1}]+4Log[1/4];
 FTTest`FTAssert["nonlinear map test function w^"<>ToString[power],FullSimplify[outputAction[outputs["IncomingB"],w^power]-direct]===0],{power,0,2}];
FTTest`FTAssert["unsupported scheme fails",FailureQ[FeynFacet`FactorizationSchemeKernel["Unknown",{"q",1},{"q",1},"U",xi,colors]]];
FTTest`FTReport[];
