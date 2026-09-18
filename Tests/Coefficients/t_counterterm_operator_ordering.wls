$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
otRow[value_]:=<|"Variable"->xx,"DeltaCoefficient"->value,"PlusCoefficients"-><||>,"RegularCoefficient"->0|>;
otQ={"q","u"};otParameters=<|"CA"->3,"CF"->4/3,"TR"->1/2,"FlavorCount"->1|>;
otBase=<|"Spin"->"L","Variable"->xx,"DimensionalRegulator"->ee,
 "KernelParameters"->otParameters,"OperatorScheme"->"Larin","OperatorRedefinition"->"HelicityMSbar"|>;
Do[
 otRaw=FeynFacet`FFCountertermDistribution[otQ,otQ,Join[otBase,<|"PerturbativeOrder"->order|>]];
 otFinite=FeynFacet`FFCountertermDistribution[otQ,otQ,
 Join[otBase,<|"PerturbativeOrder"->order,"Operation"->"FiniteSchemeChange"|>]];
 FTTest`FTAssert["polarized timelike raw and finite distributions are explicit at order "<>ToString[order],
 AssociationQ[otRaw]&&AssociationQ[otFinite]&&
 otRaw["SourceRenormalizationStage"]==="Bare"&&otFinite["SourceRenormalizationStage"]==="Renormalized"],{order,0,1}];
FTTest`FTAssert["unsupported polarized timelike order two cannot reuse spacelike raw or finite kernels",
 FailureQ[FeynFacet`FFCountertermDistribution[otQ,otQ,Join[otBase,<|"PerturbativeOrder"->2|>]]]&&
 FailureQ[FeynFacet`FFCountertermDistribution[otQ,otQ,
 Join[otBase,<|"PerturbativeOrder"->2,"Operation"->"FiniteSchemeChange"|>]]]];
otHiddenScheme=<|"FiniteKernelsByOrder"-><||>,"DefaultScheme"->"HelicityMSbar"|>;
FTTest`FTAssert["a finite matrix default cannot hide an unsupported polarized timelike order-two kernel",
 FailureQ[FeynFacet`FFCountertermDistribution[otQ,otQ,Join[otBase,
  <|"PerturbativeOrder"->2,"Operation"->"FiniteSchemeChange","OperatorRedefinition"->otHiddenScheme|>]]]];
otGivenScheme=<|"FiniteKernelsByOrder"-><|2-><|{otQ,otQ,"L"}->otRow[finiteTwo]|>|>,
 "DefaultScheme"->"MSbar"|>;
otGiven=FeynFacet`FFCountertermDistribution[otQ,otQ,Join[otBase,
 <|"PerturbativeOrder"->2,"Operation"->"FiniteSchemeChange","OperatorRedefinition"->otGivenScheme|>]];
FTTest`FTAssert["explicit polarized timelike order-two input remains supported with a declared finite first order",
 AssociationQ[otGiven]&&otGiven["DeltaCoefficient"]===-finiteTwo&&
 otGiven["RegularCoefficient"]===0&&otGiven["PlusCoefficients"]===<||>];
FTTest`FTAssert["NNLO raw subtraction and finite conversion require separate source stages",
 FailureQ[FeynFacet`PDFCountertermDistribution[otQ,otQ,
 Join[otBase,<|"PerturbativeOrder"->2,"Operation"->"Factorization"|>]]]];

(* A deliberately noncommuting two-species example: raw E21 and finite E12
   in species order {g,q}. Testing separate physical plans distinguishes
   right action on PDFs from left action on FFs. Kernel entries are delta
   distributions, so the answer is ordinary matrix multiplication. *)
otMeta=<|"Order"->"NLO","Contribution"->"RawSubtracted","Scale"->qs,
 "Variables"->{xx},"DimensionalRegulator"->ee,"CouplingPower"->1,
 "RenormalizationStage"->"Renormalized","FiniteSchemeConversionApplied"->False,
 "DistributionBasis"-><|"Axes"->{<|"Variable"->xx,"Endpoint"->1,"Interval"->{0,1},"Distance"->1-xx|>}|>|>;
otSource[r_,sp_,classes_,hi_]:=If[r=!=0,0,FeynFacet`CreatePartonicResult[
 <|0->KeyDrop[otRow[Which[First[sp]==="g",bornG,MatchQ[First[sp],{"q",_}],bornQ,True,0]],"Variable"]|>,
 Join[otMeta,<|"Order"->"LO","CouplingPower"->0,"RenormalizationStage"->"Bare"|>]]];
Internal`InheritedBlock[{FeynFacet`CollinearRenormalizationKernel,FeynFacet`InverseFactorizationSchemeKernel},
 Clear[FeynFacet`CollinearRenormalizationKernel,FeynFacet`InverseFactorizationSchemeKernel];
 FeynFacet`CollinearRenormalizationKernel[d_,p_,spin_,var_,reg_,parameters_,n_,request_]:=
 Join[otRow[If[n===1&&MatchQ[d,{"q",_}]&&p==="g",1,0]],<|"Variable"->var|>];
 FeynFacet`InverseFactorizationSchemeKernel[scheme_,d_,p_,spin_,var_,parameters_,n_,request_]:=
 Join[otRow[If[n===1&&d==="g"&&MatchQ[p,{"q",_}],-1,0]],<|"Variable"->var|>];
 Do[
  otRequest=<|"PerturbativeOrder"->1,"ThroughOrder"->0,"DimensionalRegulator"->ee,
   "PerturbativeParameter"->aa,"BornCouplingPower"->0,"KernelParameters"->otParameters,
   "FlavorClasses"-><|"Quarks"-><|"Members"->{"u"},"Multiplicity"->1|>|>,
   "Legs"->{<|"Role"->role,"Spin"->"U","Variable"->xx,"OperatorScheme"->"MSbar",
    "OperatorRedefinition"->"MatrixExample","ScaleLog"->0|>}|>;
  otRawValues=Association@Table[species->FeynFacet`ApplyPartonicRenormalization[
   FeynFacet`PlanCollinearRenormalization[{species},otRequest],otSource,otMeta],{species,{"g",otQ}}];
  otConvertedSource[r_,sp_,classes_,hi_]:=If[r===1,
   Which[First[sp]==="g",otRawValues["g"],MatchQ[First[sp],{"q",_}],otRawValues[[Key[otQ]]],True,0],0];
  otValues=Association@Table[species->FeynFacet`ApplyPartonicRenormalization[
   FeynFacet`PlanFiniteFactorizationSchemeChange[{species},Join[otRequest,<|"PerturbativeOrder"->2|>]],
   otConvertedSource,Join[otMeta,<|"Order"->"NNLO","CouplingPower"->2|>]],{species,{"g",otQ}}];
  otExpected=If[role==="PDF",{0,-aa^2 bornQ},{-aa^2 bornG,0}];
  FTTest`FTAssert[role<>" noncommuting mixed insertion has the required matrix order",
   AllTrue[Values[otValues],AssociationQ]&&
   Expand[(#["Coefficients"][0]["DeltaCoefficient"]&/@Values[otValues])-otExpected]==={0,0}],
 {role,{"PDF","FF"}}]
];
FTTest`FTReport[];
