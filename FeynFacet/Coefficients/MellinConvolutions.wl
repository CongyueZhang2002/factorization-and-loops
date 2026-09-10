(* Closed Mellin convolutions needed by LO pole matrices and finite PDF
   transformations. General HPL convolutions remain with the MT adapter.
   D_m=[log^m(1-x)/(1-x)]_+, with the standard [0,1] subtraction. *)
BeginPackage["FeynFacet`"];
ConvolvePartonicMellinKernel::usage="ConvolvePartonicMellinKernel[result,kernel,axis,range] convolves any axis of a common PartonicResult with an epsilon-independent delta/plus/regular kernel. Other distribution axes and structure-function vectors are retained; active-variable dependence in every coefficient is transformed. Missing epsilon orders are rejected.";
Begin["`Private`"];
mellinLaurentPolynomial[expr_,x_]:=Module[{polynomial,rows},
 polynomial=Cancel[x expr];
 If[!PolynomialQ[polynomial,x],Return[Missing["NonPolynomialRegularPart"]]];
 rows=CoefficientRules[polynomial,x];
 ({First[First[#]]-1,Last[#]}&/@rows)
];
(* J[k,m] = Integral_0^(1-x) log^m(t)/(1-t)^k dt.
   Integration by parts uses a primitive vanishing at t=0, so no divergent
   endpoint term is split off. The recurrence terminates in classical Li_n. *)
mellinLogIntegral[1,m_Integer?NonNegative,x_]:=
 Sum[(-1)^j Factorial[m]/Factorial[m-j]If[j===m,1,Log[1-x]^(m-j)]
  If[j===0,-Log[x],PolyLog[j+1,1-x]],{j,0,m}];
mellinLogIntegral[k_Integer,m_Integer?NonNegative,x_]/;k>=2:=
 ((x^(1-k)-1)If[m===0,1,Log[1-x]^m]-
 If[m===0,0,m Sum[mellinLogIntegral[j,m-1,x],{j,1,k-1}]])/(k-1);
mellinPlusMonomial[m_Integer?NonNegative,n_Integer,x_]/;n>=-1:=
 x^n(Log[1-x]^(m+1)/(m+1)+
  If[n===-1,0,Sum[mellinLogIntegral[k,m,x],{k,1,n+1}]]);
mellinMonomialPair[a_Integer,b_Integer,x_]:=
 If[a===b,-x^a Log[x],(x^b-x^a)/(a-b)];
nativeMellinConvolution[f_Association,g_Association,x_]:=Module[
 {left,right,fp=f["PlusCoefficients"],gp=g["PlusCoefficients"],delta,plus=<||>,
 regular,scale,m,k,c,addPlus},
 left=mellinLaurentPolynomial[f["RegularCoefficient"],x];
 right=mellinLaurentPolynomial[g["RegularCoefficient"],x];
 (* A delta needs no transform even when its partner has a general regular part. *)
 If[f["RegularCoefficient"]===0&&fp===<||>,
  Return[Join[partonicMap[Function[v,f["DeltaCoefficient"]v],g],<|"Variable"->x,"Interval"->{0,1}|>]]];
 If[g["RegularCoefficient"]===0&&gp===<||>,
  Return[Join[partonicMap[Function[v,g["DeltaCoefficient"]v],f],<|"Variable"->x,"Interval"->{0,1}|>]]];
 If[MissingQ[left]||MissingQ[right]||
  AnyTrue[Tuples[{Keys[fp],Keys[gp]}],Min[#]>0&],
  Return[Missing["GeneralMellinTransformRequired"]]];
 delta=f["DeltaCoefficient"]g["DeltaCoefficient"];
 regular=f["DeltaCoefficient"]g["RegularCoefficient"]+g["DeltaCoefficient"]f["RegularCoefficient"];
 addPlus[j_,value_]:=AssociateTo[plus,j->(Lookup[plus,j,0]+value)];
 KeyValueMap[addPlus[#1,g["DeltaCoefficient"]#2]&,fp];
 KeyValueMap[addPlus[#1,f["DeltaCoefficient"]#2]&,gp];
 Do[regular+=a[[2]]b[[2]]mellinMonomialPair[a[[1]],b[[1]],x],{a,left},{b,right}];
 KeyValueMap[Function[{j,value},
  Do[regular+=value a[[2]]mellinPlusMonomial[j,a[[1]],x],{a,right}]],fp];
 KeyValueMap[Function[{j,value},
  Do[regular+=value a[[2]]mellinPlusMonomial[j,a[[1]],x],{a,left}]],gp];
 Do[
  m=Max[pair];c=fp[First[pair]]gp[Last[pair]];
  delta+=c(-1)^(m+1)Factorial[m]Zeta[m+2];
  addPlus[m+1,c(m+2)/(m+1)];
  Do[addPlus[m-k,c(-1)^k Factorial[m]/Factorial[m-k]Zeta[k+1]],{k,1,m}];
  regular-=c Log[x]If[m===0,1,Log[1-x]^m]/(1-x),
 {pair,Tuples[{Keys[fp],Keys[gp]}]}];
 plus=Select[Factor/@plus,#=!=0&];
 Join[partonicDistribution[Factor[delta],plus,Factor[regular]],<|"Variable"->x,"Interval"->{0,1}|>]
];

partonicDistributionTerms[row_,0,prefix_List:{}]:=If[partonicZeroTreeQ[row],{},{{prefix,row}}];
partonicDistributionTerms[row_Association,n_Integer?Positive,prefix_List:{}]:=Join[
 partonicDistributionTerms[row["DeltaCoefficient"],n-1,Append[prefix,"Delta"]],
 Flatten[KeyValueMap[partonicDistributionTerms[#2,n-1,Append[prefix,{"Plus",#1}]]&,
  row["PlusCoefficients"]],1],
 partonicDistributionTerms[row["RegularCoefficient"],n-1,Append[prefix,"Regular"]]];
partonicDistributionFromTerms[terms_List,0]:=Total[Last/@terms];
partonicDistributionFromTerms[terms_List,n_Integer?Positive]:=Module[{select,orders},
 select[token_]:=({Rest[First[#]],Last[#]}&/@Select[terms,First[First[#]]===token&]);
 orders=Sort[DeleteDuplicates[Cases[First[First[#]]&/@terms,{"Plus",k_}:>k]]];
 partonicDistribution[
  partonicDistributionFromTerms[select["Delta"],n-1],
  Association@Table[k->partonicDistributionFromTerms[select[{"Plus",k}],n-1],{k,orders}],
  partonicDistributionFromTerms[select["Regular"],n-1]]
];
mellinConvolveStructureVector[row_,kernel_,x_]:=Module[{leaves,sizes,n,component,answers},
 leaves=Join[{row["DeltaCoefficient"],row["RegularCoefficient"]},Values[row["PlusCoefficients"]]];
 sizes=DeleteDuplicates[Length/@Select[leaves,ListQ]];
 If[sizes==={},Return[FeynFacet`MellinConvolveDistributions[row,kernel,x]]];
 If[Length[sizes]=!=1||!AllTrue[leaves,ListQ[#]||#===0&],
  collinearKernelFail["MatchingStructureFunctionVectorsRequired"]];
 n=First[sizes];
 answers=Table[
  component=partonicMap[Function[value,If[ListQ[value],value[[j]],0]],row];
  FeynFacet`MellinConvolveDistributions[component,kernel,x],{j,n}];
 If[AnyTrue[answers,FailureQ],Return[SelectFirst[answers,FailureQ]]];
 partonicDistributionVector[KeyTake[#,{"DeltaCoefficient","PlusCoefficients","RegularCoefficient"}]&/@answers]
];
convolvePartonicAxis[row_,kernel_,axes_,position_]:=Module[
 {terms,groups,output={},x=axes[[position]],active,result,newTerms},
 terms=partonicDistributionTerms[row,Length[axes]];
 groups=GroupBy[terms,Delete[First[#],position]&];
 KeyValueMap[Function[{other,rows},
  active=partonicDistributionFromTerms[({{First[#][[position]]},Last[#]}&/@rows),1];
  result=mellinConvolveStructureVector[active,kernel,x];
  If[FailureQ[result],collinearKernelFail["PartonicMellinConvolutionFailed",<|"Cause"->result,"Axis"->x|>]];
  newTerms=partonicDistributionTerms[result,1];
  output=Join[output,({Insert[other,First[First[#]],position],Last[#]}&/@newTerms)]
 ],groups];
 partonicDistributionFromTerms[output,Length[axes]]
];
ConvolvePartonicMellinKernel[result_Association,kernel_Association,axis_Symbol,
 range:{_Integer,_Integer}]:=Catch[Module[{axes,position,rows,check},
 If[!KeyExistsQ[result,"DistributionBasis"]||!KeyExistsQ[result["DistributionBasis"],"Axes"],
  collinearKernelFail["ExplicitPartonicDistributionAxesRequired"]];
 check=RequirePartonicEpsilonRange[result,range];
 If[FailureQ[check],collinearKernelFail["PartonicConvolutionEpsilonOrdersInsufficient",<|"Cause"->check|>]];
 axes=Lookup[result["DistributionBasis"]["Axes"],"Variable"];
 position=FirstPosition[axes,axis,Missing[]];
 If[MissingQ[position]||Lookup[kernel,"Variable",None]=!=axis||
  !FreeQ[kernel,result["DimensionalRegulator"]]||
  !AllTrue[result["DistributionBasis"]["Axes"],#["Endpoint"]===1&&#["Interval"]==={0,1}&],
  collinearKernelFail["UnitIntervalMellinAxisAndRegulatorIndependentKernelRequired"]];
 collinearKernelValidate[kernel];
 rows=Association@Table[j->convolvePartonicAxis[result["Coefficients"][j],kernel,axes,First[position]],
  {j,First[range],Last[range]}];
 CreatePartonicResult[rows,Join[KeyDrop[result,{"Coefficients","EpsilonRange","Coverage"}],
  <|"ConvolutionAxis"->axis|>]]
],"CollinearCounterterms"];
End[];EndPackage[];
