(* A conic with a nonzero basepoint admits a rational coordinate with
   unit tangent. GPLs are pulled back as differential forms, including poles
   of the rational map and the logarithmic basepoint normalization.
   Pro review 24: equations (5), (6), (9)-(14).
   Branches are continued from the original integration path; no new i0
   choices or finite-part subtraction prescriptions are introduced. *)
FeynFacetSolution`QuadraticRootChart::usage="QuadraticRootChart[q,t,v] gives the exact rational parametrization t=R(v), sqrt(q)=W(v), normalized by R(0)=0 and R'(0)=1, with W(0)=sqrt(q(0)). The inverse follows this branch. The basepoint must be nonzero; the chart is continued along the original path.";
FeynFacetSolution`PullbackGPL::usage="PullbackGPL[expression,{t->R(v),v}] expresses GPLs and rational logarithms under a rational map with R(0)=0 in standard GPLs of v. It includes map poles, multiplicities and all-zero-tail normalization. It preserves analytic continuation from the original path.";
Options[FeynFacetSolution`QuadraticRootChart]={"Assumptions"->True};
FeynFacetSolution`QuadraticRootChart[q_,t_Symbol,v_Symbol,OptionsPattern[]]:=Catch[Module[
 {polynomial=Cancel[q],a,b,c,delta,den,r,w,inverse,conditions},
 If[t===v||!FreeQ[polynomial,v]||!PolynomialQ[polynomial,t]||Exponent[polynomial,t]>2,
  gplFail["QuadraticRadicandRequired"]];
 {c,b,a}=Table[Coefficient[polynomial,t,i],{i,0,2}];
 If[!FreeQ[{a,b,c},Indeterminate|_DirectedInfinity],gplFail["FiniteRadicandCoefficientsRequired"]];
 If[TrueQ[Quiet[Refine[c==0,OptionValue["Assumptions"]]]],
  gplFail["NonzeroQuadraticRootBasePointRequired"]];
 conditions=Refine[Element[{a,b,c},Complexes]&&c!=0,OptionValue["Assumptions"]];
 If[a===0,
  (* A linear radicand needs a polynomial map. The general conic map
     introduces avoidable coordinate poles in this degenerate case. *)
  r=v+b v^2/(4c);w=Sqrt[c](1+b v/(2c));
  inverse=2c t/(c+Sqrt[c]Sqrt[polynomial]),
  delta=Factor[b^2-4a c];den=1-b v/(2c)+delta v^2/(16c^2);
  r=Cancel[v/den];w=Factor[Sqrt[c](1-delta v^2/(16c^2))/den];
  inverse=2c t/(c+b t/2+Sqrt[c]Sqrt[polynomial])
 ];
 If[Cancel[Together[w^2-(polynomial/.t->r)]]=!=0||Cancel[D[r,v]/.v->0]=!=1,
  gplFail["QuadraticChartIdentityFailed"]];
 <|"OriginalVariable"->t,"Parameter"->v,"Radicand"->polynomial,
  "OriginalVariableExpression"->r,"SquareRootExpression"->w,
  "ParameterExpression"->inverse,"Jacobian"->Factor[D[r,v]],
  "BasePointRoot"->Sqrt[c],"UnitTangent"->True,"ValidityConditions"->conditions,
  "BranchConvention"->"Continue W(0)=sqrt(q(0)) along the original path; chart poles and source singularities retain their original continuation.",
  "Scope"->"Nonzero root at the basepoint; ordinary convergent integrals, with no change of finite-part prescriptions."|>
],"GPLIntegration"];
gplRationalPrimitive[expression_,t_]:=Module[{normalized,words},
 normalized=gplEndpointScalars[gplNormalizeLogs[expression,t]];
 words=gplWords[normalized,t];gplBound[words];
 gplPrimitiveSum[KeyValueMap[gplIntegrateWord[#2,#1,t]&,words]]
];
gplRationalIntegral[expression_,t_,s_]:=Module[{primitive,lower},
 primitive=gplRationalPrimitive[expression,t];lower=gplAtZero[primitive,t];
 gplUpperValue[primitive,t,s]-lower
];
gplPullbackWord[word_List,r_,v_]:=gplPullbackWord[word,r,v]=Which[
 word==={},1,
 AllTrue[word,#===0&],gplNormalizeLogs[Log[r],v]^Length[word]/Factorial[Length[word]],
 True,gplRationalIntegral[Cancel[Together[D[r,v]/(r-First[word])]]*
   gplPullbackWord[Rest[word],r,v],v,v]
];
gplNormalizeArguments[expression_,v_]:=Module[{objects,rules,r,word,base,canonicalMap},
 canonicalMap[z_]:=canonicalMap[z]=Cancel[Together[z]];
 objects=DeleteDuplicates[Cases[expression,g_FeynFacetSolution`G/;!FreeQ[g,v],{0,Infinity}]];
 rules=Table[
  {word,r}=List@@object;r=canonicalMap[r];
  If[!FreeQ[word,v]||!gplRationalQ[r,v],gplFail["RationalGPLPullbackRequired"]];
  If[r===v,object->FeynFacetSolution`G[word,v],
   base=Quiet[r/.v->0];
   If[base=!=0,gplFail["GPLPullbackMustPreserveZeroBasePoint"]];
   object->gplPullbackWord[word,r,v]],{object,objects}];
 Clear[canonicalMap];expression/.rules
];
FeynFacetSolution`PullbackGPL[expression_,{Rule[t_Symbol,r_],v_Symbol},opts:OptionsPattern[FeynFacetSolution`IntegrateGPL]]:=
 Block[{$gplAssumptions=OptionValue["Assumptions"],$gplMaxLeaves=OptionValue["MaxExpressionLeaves"],$gplMaxTerms=OptionValue["MaxTerms"],
  $gplMaxWeight=OptionValue["MaxWeight"],$gplMaxDegree=OptionValue["MaxPoleDegree"],
  $gplMaxEndpointOrder=OptionValue["MaxEndpointExpansionOrder"]},
 gplWithMemoization[{$gplAssumptions,$gplMaxLeaves,$gplMaxTerms,$gplMaxWeight,$gplMaxDegree,$gplMaxEndpointOrder},
 TimeConstrained[Catch[gplNormalizeLogs[gplNormalizeArguments[expression/.t->r,v],v],
  "GPLIntegration"],OptionValue["TimeLimit"],Failure["GPLPullbackTimeLimit",<||>]]]];
(* Two affine radicands define a conic after rationalizing the first.
   Compose the two zero-preserving charts, keeping both original root
   branches. This does not assert rationalizability of a general root field. *)
gplLinearRootPairChart[radicands_List,t_,v_]:=Module[
 {c,b,aa,bb,eta,den,r,roots,inverse,normalizedRoots,jacobian,initialRoots},
 If[Length[radicands]=!=2||!AllTrue[radicands,PolynomialQ[#,t]&&Exponent[#,t]===1&],
  Return[Failure["TwoAffineRadicandsRequired",<||>]]];
 c=(#/.t->0)&/@radicands;b=Coefficient[#,t,1]&/@radicands;
 If[!FreeQ[{c,b},Indeterminate|_DirectedInfinity],
  Return[Failure["FiniteRadicandCoefficientsRequired",<||>]]];
 If[AnyTrue[c,TrueQ[Quiet[Refine[#==0,If[ValueQ[$gplAssumptions],$gplAssumptions,True]]]]&],
  Return[Failure["NonzeroQuadraticRootBasePointRequired",<||>]]];
 {aa,bb}=Cancel/@(b/c);eta=Factor[bb(bb-aa)/16];
 den=1-bb v/2+eta v^2;
 r=v(den+aa v/4)/den^2;initialRoots=Sqrt/@c;
 roots={initialRoots[[1]](den+aa v/2)/den,initialRoots[[2]](1-eta v^2)/den};
 normalizedRoots=(Sqrt/@radicands)/initialRoots;
 inverse=4t/((1+normalizedRoots[[2]])Total[normalizedRoots]);
 jacobian=(den+aa v/2)(1-eta v^2)/den^3;
 If[!And@@MapThread[Cancel[Together[#1^2-(#2/.t->r)]]===0&,{roots,radicands}]||
   !And@@MapThread[Cancel[(#1/.v->0)-#2]===0&,{roots,initialRoots}]||
   (r/.v->0)=!=0||Cancel[D[r,v]/.v->0]=!=1||
   Cancel[Together[D[r,v]-jacobian]]=!=0||
   Cancel[Together[4r/((1+roots[[2]]/initialRoots[[2]])Total[roots/initialRoots])-v]]=!=0,
  Return[Failure["LinearRootPairChartIdentityFailed",<||>]]];
 <|"OriginalVariableExpression"->r,"SquareRootExpressions"->roots,
   "ParameterExpression"->inverse,"Jacobian"->jacobian,
   "ValidityConditions"->Refine[Element[Join[c,b],Complexes]&&And@@(#!=0&/@c),
     If[ValueQ[$gplAssumptions],$gplAssumptions,True]]|>
];
gplPositiveRootScale[radicands_,t_]:=Module[{candidates},
 If[Length[radicands]=!=2||!ValueQ[$gplAssumptions],Return[1]];
 candidates=DeleteDuplicates[Flatten[
  ({#, -#}&[Cancel[Coefficient[#,t,1]/(#/.t->0)]])&/@radicands]];
 SelectFirst[SortBy[candidates,LeafCount],TrueQ[Quiet[Refine[#>0,$gplAssumptions]]]&,1]
];
gplIntegrateQuadraticRoot[expression_,t_,s_]:=Module[
 {radicands={},sourceRadicands,rootImages=<||>,q,v=Unique["conicParameter"],chart,r,roots,
  replaced,body,answer,scale,jacobian,inverse,ratio,matched},
 sourceRadicands=DeleteDuplicates[Cases[expression,
  Power[base_,power_Rational]/;Denominator[power]===2&&!FreeQ[base,t]:>Factor[base],{0,Infinity}]];
 (* Positive real constants do not define a new root extension and preserve
    the principal root and its continuation. Unproved or negative scales
    remain separate; never use PowerExpand to merge their branches. *)
 Do[
  matched=False;
  Do[
   ratio=Cancel[Together[q/radicands[[j]]]];
   If[FreeQ[ratio,t]&&TrueQ[Quiet[Refine[ratio>0,$gplAssumptions]]],
    AssociateTo[rootImages,q->{j,Sqrt[ratio]}];matched=True;Break[]],
   {j,Length[radicands]}];
  If[!matched,AppendTo[radicands,q];AssociateTo[rootImages,q->{Length[radicands],1}]],
 {q,sourceRadicands}];
 chart=Which[
  Length[radicands]===1,
   q=First[radicands];FeynFacetSolution`QuadraticRootChart[q,t,v,"Assumptions"->$gplAssumptions],
  Length[radicands]===2&&AllTrue[radicands,PolynomialQ[#,t]&&Exponent[#,t]===1&],
   gplLinearRootPairChart[radicands,t,v],
  True,gplFail["RationalSquareRootChartNotConstructed",<|"Radicands"->radicands|>]];
 If[FailureQ[chart],Throw[chart,"GPLIntegration"]];
 scale=gplPositiveRootScale[radicands,t];
 r=chart["OriginalVariableExpression"]/.v->v/scale;
 roots=If[Length[radicands]===1,{chart["SquareRootExpression"]},chart["SquareRootExpressions"]]/.v->v/scale;
 jacobian=(chart["Jacobian"]/.v->v/scale)/scale;
 inverse=scale chart["ParameterExpression"];
 replaced=expression/.Power[base_,power_Rational]/;Denominator[power]===2&&!FreeQ[base,t]:>
   Module[{image=Lookup[rootImages,Key[Factor[base]],Missing["Root"]]},
    If[MissingQ[image],gplFail["RootOutsideRationalizedField"],(image[[2]] roots[[image[[1]]]])^(2power)]];
 body=gplRefineConstantRadicals[(replaced/.t->r)jacobian,v];
 (* Use the same bound as the rational path: first collect each GPL word's
    rational coefficient, then bound that compact expression. A pullback may
    create large sums which cancel before any integration is necessary. *)
 body=gplNormalizeRationalIntegrand[body,v];
 answer=gplRationalIntegral[body,v,v];
 answer=gplCollectCoefficients[answer/.v->(inverse/.t->s)];
 gplBound[answer];answer
];
