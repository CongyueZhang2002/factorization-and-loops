(* Forward checks of the finite recurrence and the actually stored matrix cuts. *)
FeynFacet`CheckMasterIntegralSolutionEpsilonRemainders::usage="CheckMasterIntegralSolutionEpsilonRemainders[solution] audits the saved finite recurrence, basis convolutions and original boundary orders without solving the DE or evaluating any integral. It requires the original construction metadata.";
Begin["FeynFacet`Private`"];
SetAttributes[epsilonAuditFiniteEvolution,HoldAll];
epsilonAuditFiniteEvolution[connection_,expanded_,connectionCut_,left_,right_,leftSeries_,rightSeries_,
 leftCut_,rightCut_,intermediateCut_,entryLow_,entryHigh_,rows_,outputHigh_,maximumOutput_,e_,resolver_:Identity] := If[TrueQ[$epsilonRemainderChecks],Module[
 {a=connection,bc=expanded,cut=connectionCut,l=left,r=right,lc=leftSeries,rc=rightSeries,
  vl=entryLow,vu=entryHigh,selected=rows,ou=outputHigh,maximum=maximumOutput,ep=e,
  n,bl,ll,rl,lcut,rcut,exact,degree,be,le,re,seriesEntry,upper,inner,tail,refine,resolve=resolver},
 n=Length[l];lcut=leftCut;rcut=rightCut;
 seriesEntry[series_,i_,j_]:=Association@KeyValueMap[#1->#2[[i,j]]&,series];
 (* A sufficient syntactic polynomial test avoids expanding large kinematic
    expressions merely to decide whether their epsilon tail is exactly zero.
    Unrecognized cancellations keep a remainder and are conservative. *)
 degree[x_]:=Which[x===0,-Infinity,FreeQ[x,ep],0,x===ep,1,
   Head[x]===Plus,Max[degree/@List@@x],Head[x]===Times,Total[degree/@List@@x],
   Head[x]===Power&&IntegerQ[x[[2]]]&&x[[2]]>0,x[[2]] degree[x[[1]]],True,Infinity];
 exact[x_,high_]:=degree[x]<=high;
 be=Map[exact[#,cut]&,a,{3}];le=Map[exact[#,lcut]&,l,{2}];re=Map[exact[#,rcut]&,r,{2}];
 bl=Table[If[a[[d,i,j]]===0,Infinity,
   epsilonAuditSeriesLower[seriesEntry[bc[[d]],i,j],cut]],{d,Length[a]},{i,n},{j,n}];
 ll=Table[If[l[[i,j]]===0,Infinity,epsilonAuditSeriesLower[seriesEntry[lc,i,j],lcut]],{i,n},{j,n}];
 rl=Table[If[r[[i,j]]===0,Infinity,epsilonAuditSeriesLower[seriesEntry[rc,i,j],rcut]],{i,n},{j,n}];
 (* Only a potentially contributing omitted term warrants a zero proof.
    Shared kernel names are expanded by the saved-record resolver on demand.
    The planner's asserted valuation is never used as the zero proof. *)
 refine[d_,i_,k_,through_]:=Module[{q=bl[[d,i,k]],value,next},
  While[q<=Min[through,cut],
   value=Lookup[bc[[d]],q,ConstantArray[0,{n,n}]][[i,k]];
   If[!TrueQ[TimeConstrained[Cancel[Together[resolve[value]]]===0,$epsilonRemainderTimeLimit,False]],Break[]];
   epsilonAuditRecord["Stage2/ZeroCoefficientIdentity"];
   next=Select[Keys[bc[[d]]],#>q&&bc[[d]][#][[i,k]]=!=0&];
   q=If[next==={},cut+1,Min[next]]];bl[[d,i,k]]=q];
 (* Kinematic integration of the prepared regular connection preserves
    epsilon order. All recurrence products are checked before output cuts. *)
 Do[upper=vu[[i,j]];If[upper===-Infinity,Continue[]];
  Do[If[bl[[d,i,k]]===Infinity||vl[[k,j]]===Infinity,Continue[]];
   tail=If[vu[[k,j]]===-Infinity,vl[[k,j]],Max[vl[[k,j]],vu[[k,j]]+$epsilonRemainderShift+1]];
   If[bl[[d,i,k]]+tail<=upper,refine[d,i,k,upper-tail]];
   epsilonAuditProduct[{epsilonAuditSpec[{"Connection",d,i,k},bl[[d,i,k]],cut,be[[d,i,k]]],
     epsilonAuditSpec[{"Evolution",k,j},vl[[k,j]],vu[[k,j]]]},upper,"Stage2/DERecurrence",{i,j}],
   {d,Length[a]},{k,n}],{i,n},{j,n}];
 Do[upper=If[ou===None,maximum,ou[[i,j]]];If[upper===-Infinity,Continue[]];
  Do[If[MemberQ[{ll[[i,k]],vl[[k,b]],rl[[b,j]]},Infinity],Continue[]];
   epsilonAuditProduct[{epsilonAuditSpec[{"LeftBasis",i,k},ll[[i,k]],lcut,le[[i,k]]],
     epsilonAuditSpec[{"Evolution",k,b},vl[[k,b]],vu[[k,b]]],
     epsilonAuditSpec[{"RightBasis",b,j},rl[[b,j]],rcut,re[[b,j]]]},
    upper,"Stage2/BasisConvolution",{i,j}],{k,n},{b,n}];
  (* The intermediate V R matrix is also cut before multiplication by L. *)
  Do[If[ll[[i,k]]===Infinity,Continue[]];
   inner=Min[Table[If[MemberQ[{vl[[k,b]],rl[[b,j]]},Infinity],Infinity,vl[[k,b]]+rl[[b,j]]],{b,n}]];
   epsilonAuditProduct[{epsilonAuditSpec[{"LeftBasis",i,k},ll[[i,k]],lcut,le[[i,k]]],
     epsilonAuditSpec[{"RightConvolution",k,j},inner,intermediateCut]},
    upper,"Stage2/IntermediateConvolution",{i,j}],{k,n}],{i,selected},{j,n}]
]];
End[];
Options[FeynFacet`CheckMasterIntegralSolutionEpsilonRemainders]=Options[FeynFacet`WithEpsilonRemainderChecks];
FeynFacet`CheckMasterIntegralSolutionEpsilonRemainders[record_Association,opts:OptionsPattern[]]:=
 FeynFacet`WithEpsilonRemainderChecks[Module[{r=record,required,e,n,vars,t,base,path,a,g,gi,lc,rc,limits,
   maximum,upper,plan,ranges,cl,cu,ul,uu,kd,resolveKernel,resolve},
  required={"PreparedConnectionMatrices","BasisTransformationMatrix","HomogeneousFundamentalMatrix",
   "AdditionalBasisTransformationMatrix","InverseTotalBasisTransformationAtBasePoint",
   "BasisConvolutionCoefficients","TransformedCoefficientUpperOrders","EpsilonOrderRequirements",
   "KernelMatrices","KernelDefinitions","DimensionalRegulator","RequestedEpsilonOrders","RequestedRows",
   "KinematicVariables","BasePoint","BasisTransformationLaurentLowerBounds"};
  If[!AllTrue[required,KeyExistsQ[r,#]&],Return[Failure["SavedEpsilonOrderMetadataRequired",
    <|"MissingKeys"->Select[required,!KeyExistsQ[r,#]&]|>]]];
  e=r["DimensionalRegulator"];vars=r["KinematicVariables"];base=r["BasePoint"];t=Unique["pathParameter"];
  path=Thread[vars->base+t(vars-base)];
  a=Total[MapThread[(#1/.path)#2&,{r["PreparedConnectionMatrices"],vars-base}]];
  g=r["BasisTransformationMatrix"].r["HomogeneousFundamentalMatrix"].r["AdditionalBasisTransformationMatrix"];
  gi=r["InverseTotalBasisTransformationAtBasePoint"];
  lc=r["BasisConvolutionCoefficients"]["LeftCoefficients"];rc=r["BasisConvolutionCoefficients"]["RightCoefficients"];
  limits=r["BasisTransformationLaurentLowerBounds"];maximum=Max[r["RequestedEpsilonOrders"]];
  upper=Lookup[r,"OriginalFundamentalMatrixCoefficientUpperOrders",None];
  kd=r["KernelDefinitions"];
  resolveKernel[index_Integer,u_]:=resolveKernel[index,u]=
   (kd[[index,"Expression"]]/.kd[[index,"Parameter"]]->u)/.
     FeynFacetSolution`K[j_Integer,v_]:>resolveKernel[j,v];
  resolve[x_]:=x/.FeynFacetSolution`K[j_Integer,u_]:>resolveKernel[j,u];
  FeynFacet`Private`epsilonAuditFiniteEvolution[{a},{r["KernelMatrices"]},Max[Keys[r["KernelMatrices"]]],g,gi,lc,rc,
   maximum-limits[[2]],maximum-limits[[1]],maximum-limits[[1]],
   r["EpsilonOrderRequirements"]["TransformedCoefficientLowerBounds"],r["TransformedCoefficientUpperOrders"],
   r["RequestedRows"],upper,maximum,e,resolve];
  plan=Lookup[r,"ExpansionOrderDetermination",None];
  If[AssociationQ[plan],
   ranges=plan["RequestedMasterIntegralOrderRanges"];cl=plan["OrdinaryPointConstantLowerBounds"];
   cu=plan["OrdinaryPointConstantUpperOrders"];ul=plan["OriginalFundamentalMatrixEntryLowerBounds"];
   uu=plan["OriginalFundamentalMatrixCoefficientUpperOrders"];
   Do[FeynFacet`Private`epsilonAuditProduct[{
     FeynFacet`Private`epsilonAuditSpec[{"SavedFundamentalMatrix",i,j},ul[[i,j]],uu[[i,j]]],
     FeynFacet`Private`epsilonAuditSpec[{"SavedBoundary",j},cl[[j]],cu[[j]]]},Last[ranges[i]],
     "Stage2/SavedBoundaryConvolution",{i,j}],{i,Keys[ranges]},{j,Length[cl]}]];
  <|"Status"->"SavedOrdersChecked","Family"->Lookup[r,"Family",None],"NewIntegralEvaluations"->0|>
 ],opts];
