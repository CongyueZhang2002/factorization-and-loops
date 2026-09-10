(* Epsilon rescaling and explicit homogeneous solutions for finite quadratures. *)
Begin["FeynFacet`Private`"];
Clear[solutionEpsilonRescaling, solutionHomogeneousBlock, solutionPrepareConnection,
 solutionAlgebraicHorizontalSections, solutionAlgebraicHorizontalSectionsAtPoleOrder, solutionReduceZeroOrderBlock, solutionConstantNilpotentBasis,
 solutionInvariantSubspaceReduction,solutionNormalizeHomogeneousFunctions,solutionCyclicReconstruction];

solutionEpsilonRescaling[a_, e_] := Module[
 {n=Length[First[a]], val, shifts, changed=False, edges, remaining, order={}, ready,
  zeroEdges, blocks, s, si},
 val=Table[Min[solutionValuation[#[[i,j]],e]& /@ a],{i,n},{j,n}];
 edges=Select[Tuples[Range[n],2],val[[#[[1]],#[[2]]]]=!=Infinity &];
 shifts=ConstantArray[0,n];
 (* Difference constraints s_i <= s_j+v_ij; Bellman-Ford detects a
    negative-weight cycle. No sample-point valuation is used. *)
 Do[changed=False;
   Do[With[{i=edge[[1]],j=edge[[2]]},
     If[shifts[[i]]>shifts[[j]]+val[[i,j]],
       shifts[[i]]=shifts[[j]]+val[[i,j]];changed=True]],{edge,edges}];
   If[!changed,Break[]],{n}];
 If[changed,solutionFail["EpsilonRescalingHasNegativeCycle",
   <|"EntryValuations"->val,
     "Meaning"->"Diagonal epsilon rescaling is insufficient; this does not prove that no Laurent solution exists."|>]];
 shifts=shifts-Min[shifts];
 zeroEdges=Select[edges,val[[#[[1]],#[[2]]]]+shifts[[#[[2]]]]-shifts[[#[[1]]]]===0 &];
 blocks=SortBy[Sort /@ ConnectedComponents[Graph[Range[n],DirectedEdge[#[[2]],#[[1]]]& /@ zeroEdges]],First];
 remaining=Range[n];
 While[remaining=!={},
  ready=Select[remaining,Function[i,!AnyTrue[zeroEdges,#[[1]]===i && MemberQ[remaining,#[[2]]] &]]];
  If[ready==={},Break[]];order=Join[order,ready];remaining=Complement[remaining,ready]];
 If[remaining=!={},order=Range[n]];
 s=DiagonalMatrix[e^shifts].IdentityMatrix[n][[All,order]];
 si=Transpose[IdentityMatrix[n][[All,order]]].DiagonalMatrix[e^(-shifts)];
 <|"Status"->"NonnegativeEpsilonValuationsConstructed","EpsilonShifts"->shifts,
   "RowOrder"->order,"ZeroOrderAcyclic"->(remaining==={}),
   "ZeroOrderBlocksBeforePermutation"->blocks,"EntryValuations"->val,
   "BasisTransformationMatrix"->s,"InverseBasisTransformationMatrix"->si|>
];

FeynFacet`FindEpsilonRescaling[a_List,e_Symbol] :=
 Catch[solutionEpsilonRescaling[Normal/@a,e],"FiniteSolution"];


(* Stored sparse matrices are atomic to several expression traversals.
   Apply a declared dimension rule to their explicit coefficients at every
   public finite-solution boundary, including saved source/gauge matrices.
   Integral definitions and geometric momentum dimensions remain untouched. *)
solutionNormalizeDifferentialSystem[system_Association]:=Module[
 {rule,dimension,e,matrixFields,connectionFields,result=system,convert,source},
 rule=Lookup[system,"DimensionRule",None];e=Lookup[system,"DimensionalRegulator",None];
 If[!MatchQ[e,_Symbol],Return[Failure["DimensionalRegulatorRequired",<||>]]];
 If[rule=!=None&&!MatchQ[rule,Rule[_Symbol,_]],
  Return[Failure["ExplicitDimensionRuleRequired",<||>]]];
 dimension=If[rule===None,None,First[rule]];
 If[dimension===e||(rule=!=None&&!FreeQ[Last[rule],dimension]),
  Return[Failure["IndependentRegulatorInDimensionRuleRequired",<||>]]];
 If[rule=!=None,rule=dimension->(Last[rule]/.
   symbol_Symbol/;MemberQ[{"eps","ep","Epsilon"},SymbolName[symbol]]:>e)];
 convert[matrix_]:=Module[{value=Normal[matrix]},
  If[rule=!=None,value=value/.rule];
  value=value/.symbol_Symbol/;MemberQ[{"eps","ep","Epsilon"},SymbolName[symbol]]:>e;
  If[dimension=!=None&&!FreeQ[value,dimension],
   Return[Failure["IncompleteConnectionDimensionSubstitution",<||>]]];
  value];
 connectionFields={"ConnectionMatrices","OriginalConnectionMatrices"};
 matrixFields={"BasisTransformationMatrix","InverseBasisTransformationMatrix",
  "HomogeneousFundamentalMatrix","InverseHomogeneousFundamentalMatrix"};
 Do[If[KeyExistsQ[result,key],
   If[AssociationQ[result[key]],
    If[!ListQ[Lookup[result,"KinematicVariables",None]]||
      Sort[Keys[result[key]]]=!=Sort[result["KinematicVariables"]],
     Return[Failure["ConnectionAxesMustMatchKinematicVariables",<|"Field"->key|>],Module]];
    AssociateTo[result,key->Lookup[result[key],result["KinematicVariables"]]]];
   If[ListQ[result[key]],AssociateTo[result,key->(convert/@result[key])]]],
  {key,connectionFields}];
 Do[If[KeyExistsQ[result,key]&&(ListQ[result[key]]||Head[result[key]]===SparseArray),
   AssociateTo[result,key->convert[result[key]]]],{key,matrixFields}];
 If[AssociationQ[Lookup[result,"ConnectionCoefficientSource",None]],
  source=Join[result["ConnectionCoefficientSource"],
   <|"DimensionRule"->rule,"DimensionalRegulator"->e|>];
  AssociateTo[result,"ConnectionCoefficientSource"->solutionNormalizeDifferentialSystem[source]]];
 If[!FreeQ[KeyTake[result,Join[connectionFields,matrixFields,{"ConnectionCoefficientSource"}]],_Failure],
  Return[Failure["DifferentialSystemDimensionConversionFailed",<||>]]];
 result
];

(* ArcTanh(z)=(Log(1+z)-Log(1-z))/2 in the principal-log convention.
   Split exponent sums using exp(a+b)=exp(a)exp(b). Never combine separate
   square roots or apply PowerExpand; their branches must be preserved. *)
solutionNormalizeHomogeneousFunctions[expression_] := Module[{r},
 r=expression/.Power[E,z_]:>With[
   {expanded=Expand[z/.ArcTanh[q_]:>(Log[1+q]-Log[1-q])/2]},
   Times@@(Exp/@If[Head[expanded]===Plus,List@@expanded,{expanded}])];
 r/.Power[p_,q_Rational]:>Power[Expand[p],q]
];

(* Reconstruct vector columns from one component and its derivatives using
   a cyclic-vector matrix. A proposed scalar solution is accepted only after
   verifying the full vector equation and nonsingularity. *)
solutionCyclicReconstruction[a_,step_,x_] := Module[
 {n=Length[a],observations,row,candidate},
 Do[
  observations={IdentityMatrix[n][[i]]};
  Do[row=Last[observations];
    AppendTo[observations,Map[Cancel,D[row,x]+row.a]],{n-1}];
  If[solutionZero[Det[observations]],Continue[]];
  candidate=Map[Cancel,Inverse[observations].
    Table[D[step[[i]],{x,k}],{k,0,n-1}],{2}];
  If[!solutionZero[Det[candidate]] &&
     solutionMatrixZero[D[candidate,x]-a.candidate],
    Return[candidate,Module]],{i,n}];
 step
];

solutionHomogeneousBlock[a_,vars_,seconds_] := Module[
 {n=Length[First[a]],h,hi,b=a,step,coordinateOrder,variable,functions,unknowns,
  sol,constants,zeroConstants,equations,primitive,remaining,checks},
 h=IdentityMatrix[n];
 coordinateOrder=SortBy[Range[Length[vars]],LeafCount[a[[#]]] &];
 Do[
  variable=vars[[coordinate]];
  If[solutionMatrixZero[b[[coordinate]]],Continue[]];
  If[n===1,
   primitive=TimeConstrained[Quiet[Integrate[b[[coordinate,1,1]],variable,
     GenerateConditions->False]],seconds,$Aborted];
   If[primitive===$Aborted || !solutionExplicitExpressionQ[primitive],
     solutionFail["ScalarHomogeneousPrimitiveNotFound",<|"Variable"->variable|>]];
   step={{Exp[primitive]}},
   functions=Table[Unique["homogeneousComponent"],{n}];
   unknowns=#[variable]& /@ functions;
   equations=Thread[D[unknowns,variable]==b[[coordinate]].unknowns];
   sol=TimeConstrained[Quiet[DSolveValue[equations,unknowns,variable]],seconds,$Aborted];
   If[sol===$Aborted || !ListQ[sol] || Length[sol]=!=n ||
       !FreeQ[sol,_DSolveValue | _DSolve | _Integrate],
     solutionFail["HomogeneousBlockNotSolved",<|"BlockSize"->n,"Variable"->variable|>]];
   constants=Sort[DeleteDuplicates[Cases[sol,System`C[_Integer],Infinity]]];
   If[Length[constants]=!=n,
     solutionFail["HomogeneousSolutionDimensionMismatch",<|"BlockSize"->n|>]];
   step=Table[Coefficient[sol[[i]],constants[[j]]],{i,n},{j,n}];
   If[!And@@(solutionExplicitExpressionQ /@ Flatten[step]) ||
      !solutionMatrixZero[Transpose[{sol-step.constants}]],
     solutionFail["HomogeneousBlockHasUndefinedFunctions",<|"BlockSize"->n,
      "Variable"->variable,"CandidateMatrix"->step,
      "LinearityResidual"->(sol-step.constants)|>]]
  ];
  step=Map[Cancel,solutionNormalizeHomogeneousFunctions[step],{2}];
  If[!solutionMatrixZero[D[step,variable]-b[[coordinate]].step],
   step=TimeConstrained[
     solutionCyclicReconstruction[b[[coordinate]],step,variable],seconds,step]];
  If[!solutionMatrixZero[D[step,variable]-b[[coordinate]].step] ||
     solutionZero[Det[step]],
    solutionFail["HomogeneousBlockIdentityFailed",<|"Variable"->variable|>]];
  hi=Inverse[step];
  b=MapThread[Map[Cancel,hi.#1.step-hi.D[step,#2],{2}] &,{b,vars}];
  h=Map[Cancel,h.step,{2}],
 {coordinate,coordinateOrder}];
 If[!And@@(solutionMatrixZero /@ b),
   solutionFail["HomogeneousBlockDoesNotSolveAllCoordinates"]];
 h
];

(* Search for explicit horizontal vectors h P/Q. Q incorporates exact
   Fuchsian pole bounds at linear divisor factors. The bounded polynomial
   and square-root searches are sufficient constructions, not nonexistence
   tests. All returned vectors are verified in every coordinate. *)
solutionAlgebraicHorizontalSections[a_,vars_,seconds_,coordinates_:All] := Module[
 {deadline=AbsoluteTime[]+seconds,remaining,result},
 Do[
  remaining=deadline-AbsoluteTime[];If[remaining<=0,Return[{},Module]];
  result=TimeConstrained[
    solutionAlgebraicHorizontalSectionsAtPoleOrder[a,vars,remaining,coordinates,increment],
    remaining,{}];
  If[result=!={},Return[result,Module]],{increment,{0,1}}];
 {}
];

solutionAlgebraicHorizontalSectionsAtPoleOrder[a_,vars_,seconds_,coordinates_,increment_Integer] := Module[
 {n=Length[First[a]],den,factors,variable,root,residue,eigen,bound,degree,
  monomials,unknowns,poly,rootPoly,eq,matrix,null,answer={},start,
  candidateFactors,subsets,polyMatrix,cols,axes},
 axes=If[coordinates===All,Range[Length[vars]],coordinates];
 If[!And@@(PolynomialQ[Numerator[Together[#]],vars] &&
   PolynomialQ[Denominator[Together[#]],vars] & /@ Flatten[a]),Return[{}]];
 den=Fold[PolynomialLCM,1,Denominator[Together[#]]& /@ Flatten[a]];
 factors=Rest[FactorList[den]];
 Do[
  variable=SelectFirst[vars,Exponent[factor[[1]],#]===1 &,None];
  If[variable===None || factor[[2]]>1,Continue[]];
  root=-Coefficient[factor[[1]],variable,0]/Coefficient[factor[[1]],variable,1];
  residue=Quiet[Map[Cancel[factor[[1]] #/D[factor[[1]],variable]] &,
    a[[First[FirstPosition[vars,variable]]]],{2}]/.variable->root];
  If[!FreeQ[residue,Indeterminate|ComplexInfinity|DirectedInfinity[_]],Continue[]];
  eigen=TimeConstrained[Eigenvalues[residue],2,{}];
  eigen=Select[eigen,MatchQ[#,_Integer|_Rational]&];
  If[eigen=!={},bound=Max[0,Ceiling[-Min[eigen]]];
    den=den factor[[1]]^Max[0,bound-factor[[2]]]],
 {factor,factors}];
 (* The simple linear-divisor residue bounds above do not cover quadratic
    divisors. A bounded second ansatz allows one additional pole power there,
    e.g. sqrt(Delta)/Delta^2 for a local exponent -3/2. This is a positive
    candidate search, never a nonexistence bound. *)
 If[increment>0,
   den=den (Times@@(First/@Select[factors,
     Max[Total/@(First/@CoefficientRules[First[#],vars])]>1&]))^increment];
 degree=Max[Total /@ (First /@ CoefficientRules[den,vars])]+1;
 If[n Binomial[degree+Length[vars],Length[vars]]>1200,Return[{}]];
 monomials=(Times@@MapThread[Power,{vars,#}])& /@
   Select[Tuples[Range[0,degree],Length[vars]],Total[#]<=degree&];
 unknowns=Table[Unique["horizontalCoefficient"],{n Length[monomials]}];
 poly=Partition[unknowns,Length[monomials]].monomials;
 candidateFactors=First /@ factors;
 subsets=Take[Subsets[candidateFactors],UpTo[64]];
 start=AbsoluteTime[];
 Do[
  If[AbsoluteTime[]-start>seconds,Break[]];
  rootPoly=Times@@subset;
  eq=Flatten[Table[
    polyMatrix=Map[Cancel,den a[[i]]+
      (D[den,vars[[i]]]-den D[rootPoly,vars[[i]]]/(2 rootPoly)) IdentityMatrix[n],{2}];
    Flatten[(Last /@ CoefficientRules[Expand[#],vars])& /@
      (den D[poly,vars[[i]]]-polyMatrix.poly)],
    {i,axes}]];
  matrix=Last[CoefficientArrays[eq,unknowns]];
  null=NullSpace[matrix];
  If[null==={},Continue[]];
  cols=Map[Cancel,Transpose[Table[Sqrt[rootPoly] poly/den/.Thread[unknowns->u],{u,null}]],{2}];
  If[And@@Table[solutionMatrixZero[D[cols,vars[[i]]]-a[[i]].cols],{i,axes}],
    answer=cols;Break[]],
 {subset,subsets}];
 answer
];

solutionInvariantSubspaceReduction[a_,vars_,seconds_] := Catch[Module[
 {n=Length[First[a]],sections,cols,rank,trial,g,gi,b,top,bottom,
  topReduction,bottomReduction,extension,answer},
 Do[
  If[solutionMatrixZero[a[[coordinate]]],Continue[]];
  sections=TimeConstrained[solutionAlgebraicHorizontalSections[a,vars,seconds,{coordinate}],seconds,{}];
  If[sections==={},Continue[]];
  cols={};
  Do[trial=Append[cols,v];
    If[MatrixRank[Transpose[trial]]>Length[cols],cols=trial];
    If[Length[cols]===n,Break[]],{v,Transpose[sections]}];
  rank=Length[cols];
  Do[If[Length[cols]===n,Break[]];trial=Append[cols,v];
    If[MatrixRank[Transpose[trial]]>Length[cols],cols=trial],{v,IdentityMatrix[n]}];
  g=Transpose[cols];gi=Inverse[g];
  b=MapThread[Map[Cancel,gi.#1.g-gi.D[g,#2],{2}] &,{a,vars}];
  top=Range[rank];bottom=Range[rank+1,n];
  If[!And@@(solutionMatrixZero[#[[bottom,top]]]& /@ b),Continue[]];
  If[!solutionMatrixZero[b[[coordinate,All,top]]],Continue[]];
  If[TrueQ[$finiteIntegrationVerbose],
    Print["Invariant subspace of dimension ",rank," in block of dimension ",n]];
  topReduction=solutionReduceZeroOrderBlock[#[[top,top]]& /@ b,vars,seconds];
  extension=IdentityMatrix[n];
  Do[extension[[i,j]]=topReduction[[i,j]],{i,rank},{j,rank}];
  If[bottom=!={},
    bottomReduction=solutionReduceZeroOrderBlock[#[[bottom,bottom]]& /@ b,vars,seconds];
    Do[extension[[bottom[[i]],bottom[[j]]]]=bottomReduction[[i,j]],
      {i,Length[bottom]},{j,Length[bottom]}]];
  answer=Map[Cancel,g.extension,{2}];
  Throw[answer,"InvariantReduction"],
 {coordinate,SortBy[Range[Length[vars]],LeafCount[a[[#]]]&]}];
 $Failed
],"InvariantReduction"];

solutionReduceZeroOrderBlock[a_,vars_,seconds_] := Module[
 {n=Length[First[a]],sections,cols,rank,g,gi,b,subRows,reduced,extension,result,trial},
 If[And@@(solutionMatrixZero /@ a),Return[IdentityMatrix[n]]];
 If[n===1,Return[solutionHomogeneousBlock[a,vars,seconds]]];
 sections=TimeConstrained[solutionAlgebraicHorizontalSections[a,vars,seconds],seconds,{}];
 If[sections==={},
  trial=solutionInvariantSubspaceReduction[a,vars,seconds];
  If[trial=!=$Failed,Return[trial]];
  Return[solutionHomogeneousBlock[a,vars,seconds]]];
 cols=Transpose[sections]; rank=Length[cols];
 (* Horizontal solutions are independent iff their values at an ordinary
    point are; exact symbolic rank is used here. *)
 If[MatrixRank[sections]=!=rank,solutionFail["DependentHorizontalSections"]];
 Do[If[Length[cols]===n,Break[]];
  trial=Append[cols,unit];
  If[MatrixRank[Transpose[trial]]>Length[cols],cols=trial],
 {unit,IdentityMatrix[n]}];
 g=Transpose[cols];gi=Inverse[g];
 b=MapThread[Map[Cancel,gi.#1.g-gi.D[g,#2],{2}] &,{a,vars}];
 If[!And@@(solutionMatrixZero[#[[All,Range[rank]]]] & /@ b),
   solutionFail["HorizontalSectionReductionIdentityFailed"]];
 If[rank===n,Return[g]];
 subRows=Range[rank+1,n];
 reduced=solutionReduceZeroOrderBlock[#[[subRows,subRows]] & /@ b,vars,seconds];
 extension=IdentityMatrix[n];
 Do[extension[[subRows[[i]],subRows[[j]]]]=reduced[[i,j]],{i,n-rank},{j,n-rank}];
 result=Map[Cancel,g.extension,{2}];
 result
];

solutionConstantNilpotentBasis[a_,vars_,e_] := Module[
 {coeffs,n=Length[First[a]],matrices={},den,poly,exponents,basis={},ann,
  next,rank=0,trial,value},
 coeffs=Flatten[Values[solutionLaurentCoefficients[#,e,-1]]& /@ a,1];
 Do[
  den=Fold[PolynomialLCM,1,Denominator[Together[#]]& /@ Flatten[c]];
  poly=Map[Cancel,den c,{2}];
  If[!And@@(PolynomialQ[#,vars]& /@ Flatten[poly]),Return[$Failed]];
  exponents=Union@@(First /@ CoefficientRules[#,vars]& /@ Flatten[poly]);
  Do[
   value=Map[Function[z,Fold[Coefficient[#1,vars[[#2]],exponent[[#2]]]&,z,Range[Length[vars]]]],poly,{2}];
   If[!solutionMatrixZero[value],AppendTo[matrices,value]],
   {exponent,exponents}],
 {c,coeffs}];
 If[matrices==={},Return[$Failed]];
 Do[
  ann=If[basis==={},IdentityMatrix[n],NullSpace[basis]];
  next=NullSpace[Join@@(ann.# & /@ matrices)];
  If[Length[next]<=rank,Return[$Failed]];
  Do[trial=Append[basis,v];
    If[MatrixRank[trial]>Length[basis],basis=trial],{v,next}];
  rank=Length[basis];If[rank===n,Break[]],
 {n}];
 If[rank===n,Transpose[basis],$Failed]
];

solutionPrepareConnection[a_,vars_,e_,seconds_,options_:<||>] := Module[
 {rescaling,s,si,b,a0,n=Length[First[a]],blocks,edges,h,hi,hb,mb,finalRescaling,
  m,mi,reports={},failure,zeroPattern,provided,record,reducedBlock,recordPath,tmp,constantBasis=IdentityMatrix[Length[First[a]]],work=a},
 rescaling=Catch[solutionEpsilonRescaling[a,e],"FiniteSolution"];
 If[FailureQ[rescaling],
  If[!MatchQ[rescaling,Failure["EpsilonRescalingHasNegativeCycle",_]],Throw[rescaling,"FiniteSolution"]];
  constantBasis=solutionConstantNilpotentBasis[a,vars,e];
  If[constantBasis===$Failed,Throw[rescaling,"FiniteSolution"]];
  work=Map[Cancel,Inverse[constantBasis].#.constantBasis,{2}]& /@ a;
  rescaling=solutionEpsilonRescaling[work,e]];
 s=constantBasis.rescaling["BasisTransformationMatrix"];
 si=rescaling["InverseBasisTransformationMatrix"].Inverse[constantBasis];
 b=Map[Cancel,si.#.s,{2}]& /@ a;
 If[TrueQ[rescaling["ZeroOrderAcyclic"]],
  Return[<|"ConnectionMatrices"->b,"BasisTransformationMatrix"->s,
    "InverseBasisTransformationMatrix"->si,
    "Validation"-><|"ConstantBasisTransformationMatrix"->constantBasis,
      "EpsilonRescaling"->KeyDrop[rescaling,{"BasisTransformationMatrix","InverseBasisTransformationMatrix"}],
      "EpsilonZeroBlockReductions"->{},"AllTransformationsVerified"->True|>|>]];
 a0=Table[solutionCoefficient[solutionLaurentCoefficients[c,e,0],0,n],{c,b}];
 edges=Flatten[Table[If[!And@@(solutionZero[#[[i,j]]] & /@ a0),
   DirectedEdge[j,i],Nothing],{i,n},{j,n}]];
 blocks=SortBy[Sort /@ ConnectedComponents[Graph[Range[n],edges]],First];
 h=IdentityMatrix[n];
 Do[
  If[TrueQ[$finiteIntegrationVerbose],Print["Homogeneous block ",block]];
  mb=#[[block,block]]& /@ a0;
  If[And@@(solutionMatrixZero /@ mb),Continue[]];
  provided=SelectFirst[Lookup[options,"BlockReductionData",{}],
    Lookup[#,"Rows",None]===block &,None];
  hb=If[AssociationQ[provided],
    If[!And@@MapThread[solutionMatrixZero[#1-#2] &,
      {mb,provided["InputConnectionMatrices"]}],
      solutionFail["ProvidedBlockReductionInputMismatch",<|"Rows"->block|>]];
    provided["BasisTransformationMatrix"],
    Catch[solutionReduceZeroOrderBlock[mb,vars,seconds],"FiniteSolution"]];

  If[FailureQ[hb],solutionFail["ExplicitHomogeneousBlockRequired",
    <|"RowsInRescaledBasis"->block,"Cause"->hb,
      "EpsilonRescaling"->KeyDrop[rescaling,{"BasisTransformationMatrix","InverseBasisTransformationMatrix"}]|>]];
  reducedBlock=MapThread[Map[Cancel,Inverse[hb].#1.hb-Inverse[hb].D[hb,#2],{2}] &,{mb,vars}];
  If[!TrueQ[solutionEpsilonRescaling[reducedBlock,e]["ZeroOrderAcyclic"]],
    solutionFail["ZeroOrderBlockReductionNotTriangular",<|"Rows"->block|>]];
  record=<|"DataType"->"EpsilonZeroBlockReduction","SchemaVersion"->3,
    "Rows"->block,"KinematicVariables"->vars,"InputConnectionMatrices"->mb,
    "BasisTransformationMatrix"->hb,"ReducedConnectionMatrices"->reducedBlock,
    "Status"->"ReductionVerifiedInAllCoordinates"|>;
  If[StringQ[Lookup[options,"IntermediateOutputDirectory",None]],
    If[!DirectoryQ[options["IntermediateOutputDirectory"]],
      CreateDirectory[options["IntermediateOutputDirectory"],CreateIntermediateDirectories->True]];
    recordPath=FileNameJoin[{options["IntermediateOutputDirectory"],
      "block_"<>StringRiffle[ToString/@block,"_"]<>".m"}];
    tmp=recordPath<>".tmp";
    Block[{$Context="Global`",$ContextPath={"System`","Global`"}},Put[record,tmp]];
    RenameFile[tmp,recordPath,OverwriteTarget->True]];
  Do[h[[block[[i]],block[[j]]]]=hb[[i,j]],{i,Length[block]},{j,Length[block]}];
  AppendTo[reports,<|"Rows"->block,"BasisTransformationMatrix"->hb,
    "AllCoordinateReductionIdentitiesVerified"->True|>],
 {block,blocks}];
 hi=Inverse[h];
 b=MapThread[Map[Cancel,hi.#1.h-hi.D[h,#2],{2}] &,{b,vars}];
 finalRescaling=solutionEpsilonRescaling[b,e];
 If[!TrueQ[finalRescaling["ZeroOrderAcyclic"]],
  solutionFail["HomogeneousReductionLeavesZeroOrderCycle"]];
 m=s.h.finalRescaling["BasisTransformationMatrix"];
 mi=finalRescaling["InverseBasisTransformationMatrix"].hi.si;
 b=Map[Cancel,finalRescaling["InverseBasisTransformationMatrix"].#.
   finalRescaling["BasisTransformationMatrix"],{2}]& /@ b;
 <|"ConnectionMatrices"->b,"BasisTransformationMatrix"->m,
   "InverseBasisTransformationMatrix"->mi,
   "Validation"-><|"ConstantBasisTransformationMatrix"->constantBasis,
      "EpsilonRescaling"->KeyDrop[rescaling,{"BasisTransformationMatrix","InverseBasisTransformationMatrix"}],
     "EpsilonZeroBlockReductions"->reports,"FinalEpsilonRescaling"->KeyDrop[finalRescaling,{"BasisTransformationMatrix","InverseBasisTransformationMatrix"}],
     "AllTransformationsVerified"->True|>|>
];

Options[FeynFacet`PrepareDifferentialSystemForFiniteIntegration]={"HomogeneousSolveTimeLimit"->30,"Verbose"->False,
  "BlockReductionData"->{},"IntermediateOutputDirectory"->None};
FeynFacet`PrepareDifferentialSystemForFiniteIntegration[input_Association,OptionsPattern[]] :=
 Module[{system=solutionNormalizeDifferentialSystem[input]},
 If[FailureQ[system],Return[system]];
 Block[{$finiteIntegrationVerbose=OptionValue["Verbose"]},Catch[solutionPrepareConnection[Normal/@system["ConnectionMatrices"],
   system["KinematicVariables"],system["DimensionalRegulator"],
   OptionValue["HomogeneousSolveTimeLimit"],
   <|"BlockReductionData"->OptionValue["BlockReductionData"],
     "IntermediateOutputDirectory"->OptionValue["IntermediateOutputDirectory"]|>],"FiniteSolution"]]];

FeynFacet`ApplyFiniteIntegrationPreparation[input_Association,prepared_Association] := Module[
 {system=solutionNormalizeDifferentialSystem[input],n,t,ti,source},
 If[FailureQ[system],Return[system]];n=Length[First[system["ConnectionMatrices"]]];
 t=Lookup[system,"BasisTransformationMatrix",IdentityMatrix[n]];
 ti=Lookup[system,"InverseBasisTransformationMatrix",Inverse[t]];
 source=Lookup[system,"OriginalConnectionMatrices",
   If[t===IdentityMatrix[n],system["ConnectionMatrices"],None]];
 Join[KeyDrop[system,{"HomogeneousFundamentalMatrix","InverseHomogeneousFundamentalMatrix",
    "EpsilonZeroBlockReductions"}],
  <|"ConnectionMatrices"->prepared["ConnectionMatrices"],
    "ConnectionCoefficientSource"-><|"ConnectionMatrices"->system["ConnectionMatrices"],
      "BasisTransformationMatrix"->prepared["BasisTransformationMatrix"],
      "InverseBasisTransformationMatrix"->prepared["InverseBasisTransformationMatrix"]|>,
    "BasisTransformationMatrix"->t.prepared["BasisTransformationMatrix"],
    "InverseBasisTransformationMatrix"->prepared["InverseBasisTransformationMatrix"].ti,
    "OriginalConnectionMatrices"->source,
    "InputValidation"->Join[Lookup[system,"InputValidation",Lookup[system,"Validation",<||>]],
      <|"FiniteIntegrationPreparation"->prepared["Validation"]|>]|>]
];

End[];
