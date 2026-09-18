Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
row[d_,p_,r_]:=<|"DeltaCoefficient"->d,"PlusCoefficients"->p,"RegularCoefficient"->r|>;
b=x/(Q2(1-x)(1-z));conditions=Q2>0&&0<x<1&&0<z<1&&0<w<1;
metadata=<|"Order"->"LO","Contribution"->"Born","RenormalizationStage"->"Bare", "Scale"->Q2,
 "Variables"->{x,z,w},"DimensionalRegulator"->ep,"DimensionalPrefactor"->1,"CouplingPower"->1,
 "DistributionBasis"-><|"Axes"->{<|"Variable"->w,"Endpoint"->1,"Interval"->{0,1},"Distance"->1-w|>}|>|>;
source=FeynFacet`CreatePartonicResult[<|0->row[b,<||>,0],1->row[0,<||>,0]|>,metadata];
kernel=<|"Variable"->u,"DeltaCoefficient"->3cf/(2ep),"PlusCoefficients"-><|0->2cf/ep|>,"RegularCoefficient"->-2cf/ep|>;
equal[a_,b_]:=TrueQ[Factor[FeynFacet`ExpandPositiveLogarithms[a-b,conditions]]===0];
geometry=<|"Coordinates"->{Q2,x,z,w},"EndpointVariable"->w,"DimensionalRegulator"->ep,
 "ExternalMomenta"->{pin,qcurrent,kout},"KinematicRules"->{FeynCalc`SPD[pin]->0,FeynCalc`SPD[qcurrent]->-Q2,FeynCalc`SPD[kout]->0,
 FeynCalc`SPD[pin,qcurrent]->Q2/(2x),FeynCalc`SPD[pin,kout]->Q2 z/(2x),
 FeynCalc`SPD[qcurrent,kout]->Q2(1-x-z-(1-x)(1-z)(1-w))/(2x)},
 "DensityPrefactor"->1,"Assumptions"->conditions|>;
Do[
  chi=If[leg==="Incoming",x+(1-x)u,z+(1-z)u];
  map=FeynFacet`ConstructCollinearMomentumMap[geometry,<|"Role"->If[leg==="Incoming","PDF","FF"],
    "Momentum"->If[leg==="Incoming",pin,kout],"Variable"->u|>];
 request=<|"Scale"->Q2,"Variables"->{x,z,w},"EpsilonRange"->{-1,0},"Assumptions"->conditions,"CollinearMap"->map|>;
 result=FeynFacet`ConvolvePartonicMappedKernel[source,kernel,request];
 If[!AssociationQ[result],Print[InputForm[result]];FTTest`FTAssert[leg<>" convolution completes",False];Continue[]];
 pole=result["Coefficients"][-1];finite=result["Coefficients"][0];
 parameter=If[leg==="Incoming",x,z];
 FTTest`FTAssert[leg<>" transversity subtraction obeys the independently integrated recoil delta",
  equal[pole["DeltaCoefficient"],cf b(3/2+2Log[1-parameter])]&&
  equal[pole["PlusCoefficients"][0],2cf b]&&equal[pole["RegularCoefficient"],0]];
 expected=If[leg==="Incoming",0,4cf b Log[z+(1-z)w]/(1-w)];
 FTTest`FTAssert[leg<>" finite part retains exactly the dimensional fragmentation Jacobian",
  equal[finite["RegularCoefficient"],expected]&&equal[finite["DeltaCoefficient"],0]&&
   AllTrue[Values[finite["PlusCoefficients"]],equal[#,0]&]];
  FTTest`FTAssert[leg<>" independent overall measure factor is rejected",
   FailureQ[FeynFacet`ConvolvePartonicMappedKernel[source,kernel,Join[request,<|"CollinearMap"->
     Join[map,<|"EndpointMeasure"->2map["EndpointMeasure"],"RegularMeasure"->2map["RegularMeasure"]|>]|>]]]];
 bad=Join[map,<|"Fraction"->2chi|>];
 FTTest`FTAssert[leg<>" malformed endpoint map is rejected even for a delta kernel",
  FailureQ[FeynFacet`ConvolvePartonicMappedKernel[source,Join[kernel,<|"PlusCoefficients"-><||>,"RegularCoefficient"->0|>],
   Join[request,<|"CollinearMap"->bad|>]]]],
 {leg,{"Incoming","Observed"}}];
Print["MAPPED COLLINEAR TEST COMPLETE"];
FTTest`FTReport[];
