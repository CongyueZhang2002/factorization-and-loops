(* A conic with a nonzero basepoint admits a rational coordinate with
   unit tangent. GPLs are pulled back as differential forms, including poles
   of the rational map and the logarithmic basepoint normalization.
   Pro review 24: equations (5), (6), (9)-(14).
   Branches are continued from the original integration path; no new i0
   choices or finite-part subtraction prescriptions are introduced. *)
FeynFacetSolution`QuadraticRootChart::usage="QuadraticRootChart[q,t,v] gives the exact rational parametrization t=R(v), sqrt(q)=W(v), normalized by R(0)=0 and R'(0)=1, with W(0)=sqrt(q(0)). The inverse follows this branch. The basepoint must be nonzero; the chart is continued along the original path.";
FeynFacetSolution`PullbackGPL::usage="PullbackGPL[expression,{t->R(v),v}] expresses GPLs and rational logarithms under a rational map with R(0)=0 in standard GPLs of v. It includes map poles, multiplicities and all-zero-tail normalization. It preserves analytic continuation from the original path.";
FeynFacetSolution`QuadraticRootChart[q_,t_Symbol,v_Symbol]:=Catch[Module[
 {polynomial=Cancel[q],a,b,c,delta,den,r,w,inverse},
 If[t===v||!FreeQ[polynomial,v]||!PolynomialQ[polynomial,t]||Exponent[polynomial,t]>2,
  gplFail["QuadraticRadicandRequired"]];
 {c,b,a}=Table[Coefficient[polynomial,t,i],{i,0,2}];
 If[TrueQ[c===0],gplFail["NonzeroQuadraticRootBasePointRequired"]];
 delta=Factor[b^2-4a c];den=1-b v/(2c)+delta v^2/(16c^2);
 r=Cancel[v/den];w=Factor[Sqrt[c](1-delta v^2/(16c^2))/den];
 inverse=2c t/(c+b t/2+Sqrt[c]Sqrt[polynomial]);
 If[Cancel[Together[w^2-(polynomial/.t->r)]]=!=0||Cancel[D[r,v]/.v->0]=!=1,
  gplFail["QuadraticChartIdentityFailed"]];
 <|"OriginalVariable"->t,"Parameter"->v,"Radicand"->polynomial,
  "OriginalVariableExpression"->r,"SquareRootExpression"->w,
  "ParameterExpression"->inverse,"Jacobian"->Factor[D[r,v]],
  "BasePointRoot"->Sqrt[c],"UnitTangent"->True,
  "BranchConvention"->"Continue W(0)=sqrt(q(0)) along the original path; chart poles and source singularities retain their original continuation.",
  "Scope"->"Nonzero root at the basepoint; ordinary convergent integrals, with no change of finite-part prescriptions."|>
],"GPLIntegration"];
gplRationalPrimitive[expression_,t_]:=Module[{normalized,words},
 normalized=gplNormalizeLogs[expression,t];gplBound[normalized];
 words=gplWords[normalized,t];
 Total[KeyValueMap[gplIntegrateWord[#2,#1,t]&,words]]
];
gplRationalIntegral[expression_,t_,s_]:=Module[{primitive,lower},
 primitive=gplRationalPrimitive[expression,t];lower=gplAtZero[primitive,t];
 (primitive/.t->s)-lower
];
gplPullbackWord[word_List,r_,v_]:=Module[{pull,answer},
 pull[{}]=1;
 pull[w_List]:=pull[w]=If[AllTrue[w,#===0&],
  gplNormalizeLogs[Log[r],v]^Length[w]/Factorial[Length[w]],
  gplRationalIntegral[Cancel[D[r,v]/(r-First[w])]pull[Rest[w]],v,v]];
 answer=pull[word];Clear[pull];answer
];
gplNormalizeArguments[expression_,v_]:=Module[{objects,rules,r,word,base,values=<||>},
 objects=DeleteDuplicates[Cases[expression,g_FeynFacetSolution`G/;!FreeQ[g,v],{0,Infinity}]];
 rules=Table[
  {word,r}=List@@object;
  If[!FreeQ[word,v]||!gplRationalQ[r,v],gplFail["RationalGPLPullbackRequired"]];
  If[r===v,object->object,
   base=Quiet[Cancel[r]/.v->0];
   If[base=!=0,gplFail["GPLPullbackMustPreserveZeroBasePoint"]];
   object->gplPullbackWord[word,Cancel[r],v]],{object,objects}];
 expression/.rules
];
FeynFacetSolution`PullbackGPL[expression_,{Rule[t_Symbol,r_],v_Symbol},opts:OptionsPattern[FeynFacetSolution`IntegrateGPL]]:=
 Block[{$gplMaxLeaves=OptionValue["MaxExpressionLeaves"],$gplMaxTerms=OptionValue["MaxTerms"],
  $gplMaxWeight=OptionValue["MaxWeight"],$gplMaxDegree=OptionValue["MaxPoleDegree"],
  $gplMaxEndpointOrder=OptionValue["MaxEndpointExpansionOrder"]},
 Internal`InheritedBlock[{gplShuffle,gplIntegrateWord,gplRationalDecomposition,gplSeries},
 TimeConstrained[Catch[gplNormalizeLogs[gplNormalizeArguments[expression/.t->r,v],v],
  "GPLIntegration"],OptionValue["TimeLimit"],Failure["GPLPullbackTimeLimit",<||>]]]];
gplIntegrateQuadraticRoot[expression_,t_,s_]:=Module[
 {radicands,q,v=Unique["conicParameter"],chart,r,w,replaced,rootRule,body,answer},
 radicands=DeleteDuplicates[Cases[expression,
  Power[base_,power_Rational]/;Denominator[power]===2&&!FreeQ[base,t]:>Factor[base],{0,Infinity}]];
 If[Length[radicands]=!=1,gplFail["SingleQuadraticRootRequired",
   <|"Radicands"->radicands|>]];
 q=First[radicands];chart=FeynFacetSolution`QuadraticRootChart[q,t,v];
 If[FailureQ[chart],Throw[chart,"GPLIntegration"]];
 r=chart["OriginalVariableExpression"];w=chart["SquareRootExpression"];
 replaced=expression/.Power[base_,power_Rational]/;Denominator[power]===2&&!FreeQ[base,t]:>
   If[Cancel[Together[base-q]]===0,w^(2power),gplFail["OneQuadraticRootFieldRequired"]];
 body=(replaced/.t->r)chart["Jacobian"];
 body=gplNormalizeArguments[body,v];
 answer=gplRationalIntegral[body,v,v];
 answer/.v->(chart["ParameterExpression"]/.t->s)
];
