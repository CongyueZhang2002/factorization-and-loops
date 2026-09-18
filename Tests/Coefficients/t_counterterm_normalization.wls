Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
nxN=Exp[cc ee+dd ee^2];nxS=Exp[ee(Log[4Pi]-EulerGamma)];
nxNormalization=FeynFacet`MSbarCouplingNormalization[ee,nxN/nxS];
FTTest`FTAssert["the exact bare-coupling convention determines the common MSbar pole normalization",
 AssociationQ[nxNormalization]&&FullSimplify[nxNormalization["PoleNormalization"]/nxN]===1];
nxRow[c_]:=<|"DeltaCoefficient"->c,"PlusCoefficients"-><||>,"RegularCoefficient"->0|>;
nxTree[c_]:=<|"DeltaCoefficient"->nxRow[c],"PlusCoefficients"-><||>,"RegularCoefficient"->nxRow[0]|>;
nxTarget={{"q","u"},{"q","u"}};
nxValue[r_,sp_]:=If[r===0,If[sp===nxTarget,1,0],r+Total[If[#==="g",1,If[First[#]==="q",2,3]]&/@sp]];
nxMeta=<|"Order"->"NNLO","Contribution"->"Total","Scale"->qs,"Variables"->{xx,zz},
 "DimensionalRegulator"->ee,"DimensionalPrefactor"->1,
 "DistributionBasis"-><|"Axes"->{<|"Variable"->xx,"Endpoint"->1,"Interval"->{0,1},"Distance"->1-xx|>,
 <|"Variable"->zz,"Endpoint"->1,"Interval"->{0,1},"Distance"->1-zz|>}|>|>;
nxRequest=<|"PerturbativeOrder"->2,"ThroughOrder"->0,"DimensionalRegulator"->ee,
 "PerturbativeParameter"->aa,"KernelParameters"-><|"CA"->3,"CF"->4/3,"TR"->1/2,"FlavorCount"->1|>,
 "FlavorClasses"-><|"Quarks"-><|"Members"->{"u"},"Multiplicity"->1|>|>,
 "Legs"->{<|"Role"->"PDF","Spin"->"U","Variable"->xx,"ScaleLog"->lf,"OperatorScheme"->"MSbar"|>,
 <|"Role"->"FF","Spin"->"U","Variable"->zz,"ScaleLog"->ld,"OperatorScheme"->"MSbar"|>}|>;
nxSource[normalization_,r_,sp_,classes_,hi_]:=If[nxValue[r,sp]===0,0,Module[{polynomial},
 polynomial=Normal[Series[normalization^(nxPower+r),{ee,0,hi}]];
 FeynFacet`CreatePartonicResult[Association@Table[k->nxTree[aa^(nxPower+r)nxValue[r,sp]
   Coefficient[polynomial,ee,k]],{k,0,hi}],Join[nxMeta,<|"Order"->{"LO","NLO","NNLO"}[[r+1]],
   "CouplingPower"->nxPower+r,"RenormalizationStage"->"Bare"|>]]]];
nxCanonicalSource[r_,sp_,classes_,hi_]:=nxSource[1,r,sp,classes,hi];
nxChangedSource[r_,sp_,classes_,hi_]:=nxSource[nxN,r,sp,classes,hi];
Do[
 nxCanonicalPlan=FeynFacet`PlanCollinearRenormalization[nxTarget,Join[nxRequest,<|"BornCouplingPower"->nxPower|>]];
 nxChangedPlan=FeynFacet`PlanCollinearRenormalization[nxTarget,Join[nxRequest,
  <|"BornCouplingPower"->nxPower,"CouplingNormalization"->nxNormalization|>]];
 nxCanonical=FeynFacet`ApplyPartonicRenormalization[nxCanonicalPlan,nxCanonicalSource,
  Join[nxMeta,<|"CouplingPower"->nxPower+2|>]];
 nxChanged=FeynFacet`ApplyPartonicRenormalization[nxChangedPlan,nxChangedSource,
  Join[nxMeta,<|"CouplingPower"->nxPower+2|>]];
 If[!AssociationQ[nxCanonical]||!AssociationQ[nxChanged],Print[{nxCanonical,nxChanged}]];
 nxLeft=FeynFacet`PartonicScalarCoefficientRules[nxChanged];nxRight=FeynFacet`PartonicScalarCoefficientRules[nxCanonical];
 nxKeys=Union[Keys[nxLeft],Keys[nxRight]];
 nxCheck[key_]:=Module[{series,expected},
  series=Sum[Lookup[nxRight,Key[ReplacePart[key,1->j]],0]ee^j,{j,-2,0}];
  expected=Coefficient[Expand[Normal[Series[nxN^(nxPower+2)series,{ee,0,0}]]],ee,First[key]];
  Cancel[Together[Lookup[nxLeft,Key[key],0]-expected]]===0];
 FTTest`FTAssert["NNLO normalization covariance at Born coupling power "<>ToString[nxPower]<>" includes both unequal-scale legs",
  AssociationQ[nxCanonical]&&AssociationQ[nxChanged]&&nxKeys=!={}&&AllTrue[nxKeys,nxCheck]];
 FTTest`FTAssert["the formal perturbative parameter remains regulator independent at Born power "<>ToString[nxPower],
  AssociationQ[nxChangedPlan]&&nxChangedPlan["PerturbativeParameter"]===aa&&
  nxChangedPlan["CouplingNormalization"]===nxNormalization],
 {nxPower,{0,2}}];
nxMismatch=Join[nxRequest,<|"BornCouplingPower"->0,"Legs"->
 (Join[#,<|"PoleNormalization"->nxN|>]&/@nxRequest["Legs"])|>];
FTTest`FTAssert["noncanonical leg poles require the same declared coupling normalization",
 FailureQ[FeynFacet`PlanCollinearRenormalization[nxTarget,nxMismatch]]];
FTTest`FTReport[];
