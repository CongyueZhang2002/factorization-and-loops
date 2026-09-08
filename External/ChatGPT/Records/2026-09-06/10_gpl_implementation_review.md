# GPL implementation review, 2026-09-06

Request: 5f4e81cf-4231-4c50-9bc4-af4b5d256361. Model: gpt-6-pro.

## Question

Please review the correctness of the first general GPL implementation (below), focusing only on material mathematical or numerical errors, not style. Roughly 700 words is enough. This implements the optional layer we discussed. No family-specific cases are in the library. The source finite expressions and their original paths remain stored. Current tests of higher-pole rational integration, shuffle products, nonzero finite lower-end terms, rejected logarithmic reciprocals, complex GPL letters and 50+ digits pass.

Important design choices:
- Scalar hyperlog integration uses rational Hermite reduction before splitting residual squarefree factors, then integration by parts on the word. Rational endpoint poles times vanishing GPLs use a power/log expansion to compute the complete finite limit at zero.
- A conversion is complete only for the source output's full dependency closure; unsupported definitions retain original finite integrals. It stores actual explicit GPL expressions, not a generator.
- GPL coefficients are evaluated through GiNaC using a batch of exact rationalized arbitrary-precision complex arguments; decimals are parsed back exactly before assigning conservative wp-5 precision. Evaluate at wp and wp+20 and compare the assembled coefficients AFTER boundary substitution when boundary values are supplied. Contour poles are refused; there is no automatic i0 or global continuation.
- Pullback changes the complete connection and supplied basis matrices. A verified forward rationalizing chart and exact base-point lift are required. Any square-root expression is rationalized algebraically; its sign is matched to the principal source value at that base, then interpreted as the continuous local branch.
- On a real CF254 prepared 13-dimensional closed subsystem with both Kallen1 and Kallen3 roots, rational Hermite reduction reduced conversion from 54 s with 5 unfinished functions to 16 s with only 1 unfinished function (an 8-second per-function budget). We are completing that function and then benchmarking at matched accuracy. No claim of all-family GPL conversion or physical boundary validation.
- Main current files follow. Please challenge lower endpoint handling, homogeneous/branch assumptions, hidden variable dependence, numerical precision and cache validity. Do you see a concrete counterexample the tests should include before trusting the bounded ordinary-domain implementation?


FILE FeynFacet/GPLIntegration.wl

(* Finite hyperlogarithmic integration. Loaded in FeynFacetSolution`Private`.
   GPL letters are constant with respect to the integration variable.
   The algorithms operate on explicit finite expressions, never a DE generator. *)
FeynFacetSolution`G::usage="G[{a1,...,an},z] is the Goncharov polylogarithm with kernels dt/(t-ai) and the standard logarithmic regularization at zero. The empty word equals one.";
FeynFacetSolution`IntegrateGPL::usage="IntegrateGPL[expression,{t,0,s}] constructs an explicit primitive in rational functions and GPLs, with its finite ordinary-point lower-end value subtracted. Rational higher poles are reduced by integration by parts. Unsupported function dependence is reported.";
Clear[FeynFacetSolution`G];
FeynFacetSolution`G[{},z_]:=1;
FeynFacetSolution`G /: D[FeynFacetSolution`G[word_List,z_],v_Symbol] /; word=!={} && FreeQ[word,v] :=
 D[z,v] FeynFacetSolution`G[Rest[word],z]/(z-First[word]);
Derivative[orders_List,1][FeynFacetSolution`G] /; AllTrue[orders,#===0&] :=
 Function[{word,z},FeynFacetSolution`G[Rest[word],z]/(z-First[word])];
gplFail[tag_,details_:<||>]:=Throw[Failure[tag,details],"GPLIntegration"];
gplRationalQ[z_,t_]:=Module[{q=Together[z]},
 PolynomialQ[Numerator[q],t]&&PolynomialQ[Denominator[q],t]];
gplBound[z_]:=If[LeafCount[z]>$gplMaxLeaves,gplFail["GPLExpressionSizeLimit"]];
gplMake[{},t_]:=1;
gplMake[word_List,t_]:=FeynFacetSolution`G[word,t];
gplWords[z_,t_]:=Module[{gs,symbols,small,rules,terms,word,coefficient,shuffles},
 gs=DeleteDuplicates[Cases[z,_FeynFacetSolution`G,{0,Infinity}]];
 If[!AllTrue[gs,MatchQ[#,FeynFacetSolution`G[_List,t]]&&FreeQ[#[[1]],t]&],
  gplFail["GPLVariableOrLettersNotSupported"]];
 symbols=Table[Unique["gplPolynomial"],{Length[gs]}];
 small=z/.Thread[gs->symbols];
 If[symbols=!={}&&!PolynomialQ[small,symbols],gplFail["NonPolynomialDependenceOnGPL"]];
 rules=If[symbols==={},{ {}->small},CoefficientRules[small,symbols]];
 terms=Association[];
 Do[
  coefficient=Last[rule];
  If[!gplRationalQ[coefficient,t],gplFail["NonRationalGPLCoefficient",<|"Coefficient"->Short[coefficient]|>]];
  shuffles=<|{}->1|>;
  Do[Do[shuffles=gplShuffleMap[shuffles,gs[[i,1]]],{First[rule][[i]]}],{i,Length[gs]}];
  KeyValueMap[AssociateTo[terms,#1->(Lookup[terms,Key[#1],0]+coefficient #2)]&,shuffles],
 {rule,rules}];
 Select[Map[Cancel,terms],#=!=0&]
];
gplShuffle[a_List,b_List]:=gplShuffle[a,b]=Which[
 a==={},<|b->1|>,b==={},<|a->1|>,
 True,Module[{out=<||>,add},
  add[head_,tail_]:=KeyValueMap[Function[{w,c},With[{v=Prepend[w,head]},
    AssociateTo[out,v->(Lookup[out,Key[v],0]+c)]]],tail];
  add[First[a],gplShuffle[Rest[a],b]];add[First[b],gplShuffle[a,Rest[b]]];
  If[Length[out]>$gplMaxTerms,gplFail["GPLWordCountLimit"]];out]
];
gplShuffleMap[words_,word_]:=Module[{out=<||>},
 KeyValueMap[Function[{a,c},KeyValueMap[Function[{b,d},
  AssociateTo[out,b->(Lookup[out,Key[b],0]+c d)]],gplShuffle[a,word]]],words];
 If[Length[out]>$gplMaxTerms,gplFail["GPLWordCountLimit"]];out
];

(* Hermite reduction is done in the rational coefficient field before any
   algebraic roots are introduced. Exact differentials often remove all
   higher-degree factors, which is essential for prepared non-epsilon forms. *)
gplRationalDecomposition[r_,t_]:=gplRationalDecomposition[r,t]=Module[
 {q=Cancel[Together[r]],apart,terms,num,den,factors,variableFactors,fac,m,
  a,b,gcd,inverse,remainder,quotient,primitive=0,simple={},residues={},degree,
  roots,discriminant,leading,root,c,extended,integratePolynomial},
 integratePolynomial[poly_]:=Sum[Coefficient[poly,t,j] t^(j+1)/(j+1),
  {j,0,Max[0,Exponent[poly,t]]}];
 If[!gplRationalQ[q,t],gplFail["NonRationalIntegrationKernel"]];
 apart=Apart[q,t];terms=If[Head[apart]===Plus,List@@apart,{apart}];
 Do[
  num=Numerator[Together[term]];den=Denominator[Together[term]];
  If[FreeQ[den,t],primitive+=integratePolynomial[num/den];Continue[]];
  factors=Rest[FactorList[den]];
  variableFactors=Select[factors,!FreeQ[#[[1]],t]&];
  If[Length[variableFactors]=!=1,gplFail["RationalPartialFractionsNotSeparated"]];
  {fac,m}=First[variableFactors];a=Cancel[num/(den/fac^m)];
  If[m>1,
   extended=PolynomialExtendedGCD[fac,D[fac,t],t];
   If[!FreeQ[First[extended],t],gplFail["NonSquareFreeHermiteFactor"]];
   inverse=Cancel[extended[[2,2]]/First[extended]];
   While[m>1,
    b=Cancel[-PolynomialRemainder[a inverse,fac,t]/(m-1)];
    primitive+=b/fac^(m-1);
    remainder=Cancel[Together[a-D[b,t] fac+(m-1)b D[fac,t]]];
    quotient=PolynomialQuotient[remainder,fac,t];
    If[!TrueQ[Cancel[Together[remainder-quotient fac]]===0],
     gplFail["RationalHermiteDivisionFailed"]];
    a=Cancel[quotient];m--]
  ];
  quotient=PolynomialQuotient[a,fac,t];primitive+=integratePolynomial[quotient];
  a=Cancel[Together[a-quotient fac]];
  If[a=!=0,AppendTo[simple,{fac,a}]],
 {term,terms}];
 (* Cancellation between rational partial fractions can remove a residual
    pole. Group identical factors before splitting the square-free part. *)
 simple=GatherBy[simple,First];
 simple=({#[[1,1]],Cancel[Together[Total[#[[All,2]]]]]}& /@ simple);
 simple=Select[simple,Last[#]=!=0&];
 Do[
  {fac,a}=entry;degree=Exponent[fac,t];
  If[degree>$gplMaxDegree,gplFail["GPLPoleDegreeLimit",<|"Degree"->degree|>]];
  roots=Switch[degree,
   1,{-Coefficient[fac,t,0]/Coefficient[fac,t,1]},
   2,discriminant=Coefficient[fac,t,1]^2-4 Coefficient[fac,t,2] Coefficient[fac,t,0];
     Table[(-Coefficient[fac,t,1]+sign Sqrt[discriminant])/(2 Coefficient[fac,t,2]),{sign,{-1,1}}],
   _,Quiet[Check[t/.Solve[fac==0,t,Cubics->False,Quartics->False],$Failed]]];
  If[!ListQ[roots]||Length[roots]=!=degree||!FreeQ[roots,t]||!DuplicateFreeQ[roots],
   gplFail["GPLPolynomialRootsNotConstructed"]];
  Do[
   c=Cancel[(a/D[fac,t])/.t->root];
   If[!FreeQ[c,Indeterminate|_DirectedInfinity],gplFail["GPLDegenerateAlphabet"]];
   If[c=!=0,AppendTo[residues,{root,c}]],
  {root,roots}],
 {entry,simple}];
 {Cancel[Together[primitive]],residues}
];

gplIntegrateWord[r_,word_List,t_]:=gplIntegrateWord[r,word,t]=Module[{parts,primitive,residues,result},
 If[Length[word]+1>$gplMaxWeight,gplFail["GPLWeightLimit"]];
 If[r===0,Return[0]];
 parts=gplRationalDecomposition[Cancel[r],t];{primitive,residues}=parts;
 result=primitive gplMake[word,t]+Total[(#[[2]] gplMake[Prepend[word,#[[1]]],t])& /@ residues];
 If[word=!={}&&primitive=!=0,
  result-=gplIntegrateWord[Cancel[primitive/(t-First[word])],Rest[word],t]];
 gplBound[result];result
];

(* Local power/log series retain the finite endpoint contribution of a
   rational pole times a vanishing GPL. Setting every GPL(0) to zero is wrong. *)
gplIntegrateMonomial[n_Integer,k_Integer,t_]:=If[n===-1,Log[t]^(k+1)/(k+1),
 t^(n+1) Sum[(-1)^j Factorial[k]/Factorial[k-j] Log[t]^(k-j)/(n+1)^(j+1),{j,0,k}]];
gplSeries[word_List,n_Integer,t_]:=gplSeries[word,n,t]=Module[{rest,derivative,ell=Unique["logarithm"],out=0,cr},
 If[word==={},Return[1]];
 If[AllTrue[word,#===0&],Return[Log[t]^Length[word]/Factorial[Length[word]]]];
 If[n<=0,Return[0]];
 rest=gplSeries[Rest[word],n,t];
 derivative=If[First[word]===0,rest/t,
  rest (-Sum[t^j/First[word]^(j+1),{j,0,n-1}])];
 derivative=Expand[derivative/.Log[t]->ell];
 (* t*derivative is polynomial, including the first-letter-zero case. *)
 cr=CoefficientRules[Expand[t derivative],{t,ell}];
 Do[If[rule[[1,1]]<=n,
  out+=Last[rule] gplIntegrateMonomial[rule[[1,1]]-1,rule[[1,2]],t]],{rule,cr}];
 out
];
gplAtZero[expression_,t_]:=Module[{words,poles,order,expanded,ell=Unique["logarithm"],value},
 words=gplWords[expression,t];
 poles=Map[Function[q,Module[{v=Together[q]},
  Max[0,Exponent[Denominator[v],t,Min]-Exponent[Numerator[v],t,Min]]]],Values[words]];
 order=Max[Append[poles,0]];
 If[order>$gplMaxEndpointOrder,gplFail["GPLEndpointExpansionLimit"]];
 expanded=Total[KeyValueMap[#2 gplSeries[#1,order,t]&,words]]/.Log[t]->ell;
 value=Quiet[Check[Normal[Series[expanded,{t,0,0}]],$Failed]];
 If[value===$Failed,gplFail["GPLEndpointValueNotConstructed"]];
 value=Cancel[Together[value]];
 If[!FreeQ[value,t|ell|Indeterminate|_DirectedInfinity],
  gplFail["GPLLowerEndpointNotFinite",<|"EndpointExpansion"->Short[value]|>]];
 value
];
gplNormalizeLogs[expression_,t_]:=expression/.Log[r_]/;!FreeQ[r,t]:>Module[{v0,derivative,p},
 If[r===t,Return[gplMake[{0},t]]];
 If[!gplRationalQ[r,t],gplFail["NonRationalLogarithmArgument"]];
 v0=Cancel[r/.t->0];
 If[v0===0||!FreeQ[v0,Indeterminate|_DirectedInfinity],gplFail["SingularLogarithmBasePoint"]];
 derivative=Cancel[D[r,t]/r];
 p=gplIntegrateWord[derivative,{},t];
 p-gplAtZero[p,t]+Log[v0]
];
Options[FeynFacetSolution`IntegrateGPL]={
 "TimeLimit"->30,"MaxExpressionLeaves"->200000,"MaxTerms"->10000,
 "MaxWeight"->16,"MaxPoleDegree"->4,"MaxEndpointExpansionOrder"->32};
FeynFacetSolution`IntegrateGPL[expression_,{t_Symbol,0,s_},OptionsPattern[]]:=
 Block[{$gplMaxLeaves=OptionValue["MaxExpressionLeaves"],$gplMaxTerms=OptionValue["MaxTerms"],
  $gplMaxWeight=OptionValue["MaxWeight"],$gplMaxDegree=OptionValue["MaxPoleDegree"],
  $gplMaxEndpointOrder=OptionValue["MaxEndpointExpansionOrder"]},
 Internal`InheritedBlock[{gplShuffle,gplIntegrateWord,gplRationalDecomposition,gplSeries},
 TimeConstrained[Catch[Module[{normalized,words,primitive,lower,result},
  If[!AllTrue[{$gplMaxLeaves,$gplMaxTerms,$gplMaxWeight,$gplMaxDegree,$gplMaxEndpointOrder},
    IntegerQ[#]&&#>0&],gplFail["InvalidGPLIntegrationOptions"]];
  (* All memoization is confined to this conversion, with the current bounds. *)
  normalized=gplNormalizeLogs[expression,t];gplBound[normalized];
  words=gplWords[normalized,t];
  primitive=Total[KeyValueMap[gplIntegrateWord[#2,#1,t]&,words]];
  lower=gplAtZero[primitive,t];
  result=(primitive/.t->s)-lower;gplBound[result];result
 ],"GPLIntegration"],OptionValue["TimeLimit"],Failure["GPLIntegrationTimeLimit",<||>]]]];


FILE FeynFacet/FiniteSolutionGPL.wl

(* Standard GPL representations and their optional GiNaC evaluation.
   The original finite solution is retained; the extra expressions are finite,
   explicit, and reusable without running the differential equation. *)
FeynFacetSolution`ConvertMasterIntegralSolutionToGPL::usage="ConvertMasterIntegralSolutionToGPL[data,opts] converts the required finite integral definitions to explicit GPL expressions. Exact rational higher poles are reduced before words are expanded. Unsupported definitions remain in the original format and are reported.";
FeynFacetSolution`EvaluateGPLExpression::usage="EvaluateGPLExpression[expression,rules,opts] evaluates explicit GPLs through GiNaC at arbitrary working precision. Arguments on the straight integration contour are refused; this routine does not choose an i0 prescription.";
gplSource[data_]:=KeyTake[data,{"KinematicVariables","BasePoint","Path","AnalyticDomain",
 "BranchPrescription","KernelDefinitions","IntegralDefinitions"}];
gplDefinitionClosure[data_]:=Module[{aa=Lookup[data,"AlgebraicDefinitions",{}],
 ff=Lookup[data,"IntegralDefinitions",{}],neededA={},neededF={},visitA,visitF,visit,out},
 visitF[i_Integer]:=If[!MemberQ[neededF,i],
  If[!Between[i,{1,Length[ff]}],numericalFailure["IntegralDependencyInvalid"]];
  AppendTo[neededF,i];Scan[visitF,DeleteDuplicates[Cases[ff[[i,"Integrand"]],FeynFacetSolution`F[j_Integer,_]:>j,{0,Infinity}]]]];
 visitA[i_Integer]:=If[!MemberQ[neededA,i],
  If[!Between[i,{1,Length[aa]}],numericalFailure["ArithmeticDependencyInvalid"]];
  AppendTo[neededA,i];visit[aa[[i]]]];
 visit[z_]:=(Scan[visitA,DeleteDuplicates[Cases[z,FeynFacetSolution`a[j_Integer]:>j,{0,Infinity}]]];
   Scan[visitF,DeleteDuplicates[Cases[z,FeynFacetSolution`F[j_Integer,_]:>j,{0,Infinity}]]]);
 out={Lookup[data,"Coefficients",<||>],Lookup[data,"MasterIntegralCoefficients",<||>]};
 visit[out];<|"AlgebraicIndices"->Sort[neededA],"IntegralIndices"->Sort[neededF]|>
];
Options[FeynFacetSolution`ConvertMasterIntegralSolutionToGPL]=Join[
 Options[FeynFacetSolution`IntegrateGPL],{"FunctionTimeLimit"->15,"Verbose"->False}];
FeynFacetSolution`ConvertMasterIntegralSolutionToGPL[data_Association,OptionsPattern[]]:=Module[
 {started=AbsoluteTime[],limits,fnSeconds=OptionValue["FunctionTimeLimit"],verbose=OptionValue["Verbose"],
  kd=Lookup[data,"KernelDefinitions",{}],fd=Lookup[data,"IntegralDefinitions",{}],
  converted=<||>,reused=0,failures={},closure,needed,parameter=Unique["gplParameter"],
  upper=FeynFacetSolution`s,expandKernel,body,dependencies,value,options,result},
 limits=OptionValue["TimeLimit"];
 options=FilterRules[{ "MaxExpressionLeaves"->OptionValue["MaxExpressionLeaves"],
  "MaxTerms"->OptionValue["MaxTerms"],"MaxWeight"->OptionValue["MaxWeight"],
  "MaxPoleDegree"->OptionValue["MaxPoleDegree"],
  "MaxEndpointExpansionOrder"->OptionValue["MaxEndpointExpansionOrder"]},Options[FeynFacetSolution`IntegrateGPL]];
 result=Catch[
  If[!NumericQ[limits]||limits<=0||!NumericQ[fnSeconds]||fnSeconds<=0||
    !MemberQ[{True,False},verbose]||!ListQ[kd]||!ListQ[fd]||
    !ListQ[Lookup[data,"AlgebraicDefinitions",None]]||
    !AssociationQ[Lookup[data,"Coefficients",None]],
   numericalFailure["InvalidGPLConversionInputOrOptions"]];
  validateFiniteDependencies[data];closure=gplDefinitionClosure[data];needed=closure["IntegralIndices"];
  If[gplRepresentationCurrentQ[data],
   converted=KeyTake[data["GPLRepresentation"]["IntegralExpressions"],needed];
   reused=Length[converted]];
  expandKernel[i_Integer]:=expandKernel[i]=Module[{z},
   z=kd[[i,"Expression"]]/.kd[[i,"Parameter"]]->parameter;
   z/.FeynFacetSolution`K[j_Integer,_]:>expandKernel[j]];
  Do[
   If[KeyExistsQ[converted,i],Continue[]];
   If[AbsoluteTime[]-started>limits,AppendTo[failures,<|"Index"->i,"Reason"->"ConversionTimeLimit"|>];Continue[]];
   dependencies=DeleteDuplicates[Cases[fd[[i,"Integrand"]],FeynFacetSolution`F[j_Integer,_]:>j,{0,Infinity}]];
   If[!AllTrue[dependencies,KeyExistsQ[converted,#]&],
    AppendTo[failures,<|"Index"->i,"Reason"->"EarlierIntegralNotConverted","Dependencies"->dependencies|>];Continue[]];
   If[TrueQ[verbose],Print["GPL integral ",i," of ",Length[fd]]];
   value=TimeConstrained[
    body=fd[[i,"Integrand"]]/.fd[[i,"IntegrationVariable"]]->parameter;
    body=body/.{FeynFacetSolution`K[j_Integer,_]:>expandKernel[j],
      FeynFacetSolution`F[j_Integer,_]:>(converted[j]/.upper->parameter)};
    FeynFacetSolution`IntegrateGPL[body,{parameter,0,upper},
      "TimeLimit"->fnSeconds,Sequence@@options],
    Min[fnSeconds,Max[0.01,limits-(AbsoluteTime[]-started)]],Failure["GPLIntegrationTimeLimit",<||>]];
   If[FailureQ[value],AppendTo[failures,<|"Index"->i,"Reason"->value[[1]],"Details"->value[[2]]|>],
    AssociateTo[converted,i->value]],
  {i,needed}];
  Join[KeyDrop[data,{"NumericalPreparation","GPLRepresentation"}],<|"GPLRepresentation"-><|
   "DataType"->"FiniteGPLRepresentation","SchemaVersion"->1,
   "Status"->If[failures==={},"RequiredIntegralsConvertedToGPL","PartiallyConvertedToGPL"],
   "SourceDefinitions"->gplSource[data],"Parameter"->upper,
   "RequiredIntegralIndices"->needed,"IntegralExpressions"->converted,
   "UnconvertedIntegrals"->failures,
   "FunctionConvention"->"G[{a1,...,an},z] with kernels dt/(t-ai); letters are constant in t.",
   "BranchConvention"->"Continuous branches along the stored ordinary-point path, fixed by the lower-end logarithms. No independent deformation of auxiliary integrals.",
   "CoefficientPrefactors"->"Original explicit prefactors are retained; GPL integrals alone do not classify those prefactors.",
   "ConversionSeconds"->AbsoluteTime[]-started,"ReusedIntegralExpressions"->reused,
   "GPLCount"->Length[DeleteDuplicates[Cases[Values[converted],_FeynFacetSolution`G,Infinity]]],
   "MaximumGPLWeight"->Max[Append[Cases[Values[converted],FeynFacetSolution`G[w_List,_]:>Length[w],Infinity],0]]
  |>|>],"NumericalSolution"];
 Clear[expandKernel];result
];
gplRepresentationCurrentQ[data_]:=Module[{rep=Lookup[data,"GPLRepresentation",None]},
 AssociationQ[rep]&&Lookup[rep,"DataType",None]==="FiniteGPLRepresentation"&&
 Lookup[rep,"SourceDefinitions",None]===gplSource[data]];
gplCanEvaluate[data_]:=TrueQ[Catch[Module[{needed},
 If[!gplRepresentationCurrentQ[data],Return[False]];
 needed=gplDefinitionClosure[data]["IntegralIndices"];
 AllTrue[needed,KeyExistsQ[data["GPLRepresentation"]["IntegralExpressions"],#]&]
],"NumericalSolution"]];

gplNumericToken[z_]:=Module[{q=Rationalize[z,0]},ToString[Numerator[q],InputForm]<>" "<>ToString[Denominator[q],InputForm]];
gplComplexToken[z_]:=gplNumericToken[Re[z]]<>" "<>gplNumericToken[Im[z]];
gplParseReal[s_String,wp_]:=Module[{parts,mantissa,power,fraction,digits,sign=1},
 If[!StringMatchQ[s,RegularExpression["[+-]?[0-9]+(?:\\.[0-9]*)?(?:[Ee][+-]?[0-9]+)?"]],
  numericalFailure["MalformedGiNaCOutput"]];
 parts=StringSplit[ToLowerCase[s],"e"];mantissa=First[parts];
 power=If[Length[parts]===2,ToExpression[Last[parts]],0];
 If[StringStartsQ[mantissa,"-"],sign=-1;mantissa=StringDrop[mantissa,1],
  If[StringStartsQ[mantissa,"+"],mantissa=StringDrop[mantissa,1]]];
 parts=StringSplit[mantissa,".",All];
 fraction=If[Length[parts]===2,StringLength[Last[parts]],0];
 digits=FromDigits[StringJoin[parts]];
 N[sign digits 10^(power-fraction),wp]
];
gplEvaluateList[gs_List,rules_,wp_,time_]:=Module[
 {numeric,all,header,lines,input,exe,process,rows,values,point,letters,ratios,tolerance=10^(-wp+8),parsed},
 If[gs==={},Return[{}]];
 numeric=Map[Function[g,{N[g[[1]]/.rules,wp],N[g[[2]]/.rules,wp]}],gs];
 If[!AllTrue[numeric,VectorQ[#[[1]],finiteNumberQ]&&finiteNumberQ[#[[2]]]&],
  numericalFailure["GPLArgumentsNotNumeric"]];
 If[AnyTrue[Flatten[numeric],!TrueQ[Precision[#]===Infinity||Precision[#]>=wp-10]&],
  numericalFailure["GPLArgumentPrecisionInsufficient"]];
 Do[
  {letters,point}=args;
  If[point===0||TrueQ[point==0],numericalFailure["GPLZeroEndpointRequiresSymbolicLimit"]];
  ratios=DeleteCases[letters,z_/;TrueQ[z==0]]/point;
  If[AnyTrue[ratios,Abs[Im[#]]<tolerance&&-tolerance<=Re[#]<=1+tolerance&],
   numericalFailure["GPLLetterOnIntegrationContour",<|"Letters"->letters,"Endpoint"->point|>]],
 {args,numeric}];
 input="FFGPL1 "<>ToString[wp]<>" "<>ToString[Length[gs]]<>"\n"<>
  StringRiffle[Map[ToString[Length[#[[1]]]]<>" "<>gplComplexToken[#[[2]]]<>" "<>
    StringRiffle[gplComplexToken /@ #[[1]]," "]&,numeric],"\n"]<>"\n";
 exe=FileNameJoin[{$finiteSolutionDirectory,"Backends","ginac","bin","evaluate_gpl"}];
 If[!FileExistsQ[exe],numericalFailure["GiNaCGPLBackendUnavailable"]];
 process=TimeConstrained[RunProcess[{exe},All,input],time,$Failed];
 If[process===$Failed,numericalFailure["GiNaCGPLEvaluationTimeLimit"]];
 If[process["ExitCode"]=!=0,numericalFailure["GiNaCGPLEvaluationFailed",<|"Message"->StringTake[process["StandardError"],UpTo[1000]]|>]];
 lines=StringSplit[StringTrim[process["StandardOutput"]],"\n"];
 If[Length[lines]=!=Length[gs]+1||First[lines]=!="FFGPL1 "<>ToString[Length[gs]],
  numericalFailure["MalformedGiNaCOutput"]];
 rows=StringSplit /@ Rest[lines];
 If[!AllTrue[rows,Length[#]===2&],numericalFailure["MalformedGiNaCOutput"]];
 (* Parse decimal strings as exact decimal values before attaching their
    documented output precision; never pass through machine precision. *)
 values=Map[Function[row,
   parsed=gplParseReal[row[[1]],wp]+I gplParseReal[row[[2]],wp];
   SetPrecision[parsed,Max[15,wp-5]]],rows];
 values
];
Options[FeynFacetSolution`EvaluateGPLExpression]={"WorkingPrecision"->60,"TimeLimit"->60};
FeynFacetSolution`EvaluateGPLExpression[expression_,rules_List:{},OptionsPattern[]]:=Catch[Module[
 {wp=OptionValue["WorkingPrecision"],gs,values},
 If[!IntegerQ[wp]||wp<20,numericalFailure["InvalidGPLWorkingPrecision"]];
 If[!VectorQ[rules,MatchQ[#,_Rule]&],numericalFailure["InvalidGPLSubstitutionRules"]];
 If[AnyTrue[Cases[{expression,Last/@rules},_Real|_Complex,Infinity],
   !TrueQ[Precision[#]===Infinity||Precision[#]>=wp-10]&],
  numericalFailure["NumericalInputPrecisionInsufficient"]];
 gs=DeleteDuplicates[Cases[expression,_FeynFacetSolution`G,{0,Infinity}]];
 values=gplEvaluateList[gs,rules,wp,OptionValue["TimeLimit"]];
 N[(expression/.Thread[gs->values])/.rules,wp]
],"NumericalSolution"];

evaluateGPLMaster[data_,point_,options_]:=TimeConstrained[Catch[Module[
 {started=AbsoluteTime[],wp=options["WorkingPrecision"],ag=options["AccuracyGoal"],
  pg=options["PrecisionGoal"],guard=options["InputGuardDigits"],rules,supplied,closure,needed,
  rep=data["GPLRepresentation"],expressions,gs,ends,values,ready,pass,outputs={},vectors={},precision,
  result,ratio,inputs,pointRules,lookup},
 If[!IntegerQ[ag]||ag<1||!IntegerQ[pg]||pg<1||!IntegerQ[guard]||guard<0||
   !MemberQ[{True,False},options["CheckConvergence"]],
  numericalFailure["InvalidNumericalParameters"]];
 If[!gplRepresentationCurrentQ[data],numericalFailure["GPLSourceDefinitionsChanged"]];
 If[!gplCanEvaluate[data],numericalFailure["RequiredIntegralsNotConvertedToGPL"]];
 If[wp===Automatic,wp=Max[50,ag+25,pg+25]];
 If[!IntegerQ[wp]||wp<Max[ag,pg]+10||wp+20>options["MaxWorkingPrecision"],
  numericalFailure["InsufficientWorkingPrecision"]];
 If[Length[point]=!=Length[data["KinematicVariables"]]||!VectorQ[point,finiteNumericQ],
  numericalFailure["NumericKinematicPointRequired"]];
 rules=constantRules[data,options["InitialConstantValues"]];supplied=options["InitialConstantValues"]=!=Automatic;
 inputs=Cases[{point,Last/@rules,rep["IntegralExpressions"],data["AlgebraicDefinitions"]},_Real|_Complex,Infinity];
 If[inputs=!={}&&!TrueQ[roundoffRatio[inputs,ag+guard,pg+guard]<=1],
  numericalFailure["NumericalInputPrecisionInsufficient"]];
 closure=gplDefinitionClosure[data];needed=closure["IntegralIndices"];
 expressions=Lookup[rep["IntegralExpressions"],needed]/.rep["Parameter"]->1;
 gs=DeleteDuplicates[Cases[expressions,_FeynFacetSolution`G,{0,Infinity}]];
 ready=Join[data,<|"AlgebraicDefinitions"->MapIndexed[
  If[MemberQ[closure["AlgebraicIndices"],First[#2]],#1,0]&,data["AlgebraicDefinitions"]]|>];
 Do[
  precision=wp+20(pass-1);pointRules=Thread[data["KinematicVariables"]->N[point,precision]];
  values=gplEvaluateList[gs,pointRules,precision,options["TimeLimit"]];
  ends=ConstantArray[0,Length[data["IntegralDefinitions"]]];
  lookup=N[(expressions/.Thread[gs->values])/.pointRules,precision];
  If[!VectorQ[lookup,finiteNumberQ],numericalFailure["GPLIntegralValueNotFinite"]];
  Do[ends[[needed[[i]]]]=lookup[[i]],{i,Length[needed]}];
  result=applyConstants[assembleFiniteResult[ready,point,0,precision,{0,1},ends],rules];
  AppendTo[outputs,result];AppendTo[vectors,comparisonVector[data,result,supplied]],
 {pass,If[TrueQ[options["CheckConvergence"]],2,1]}];
 ratio=If[Length[vectors]===2,Max[scaledDifference@@Join[vectors,{ag,pg}],roundoffRatio[Last[vectors],ag,pg]],None];
 If[NumberQ[ratio]&&!TrueQ[ratio<=1],numericalFailure["GPLNumericalAccuracyNotReached",<|"EstimatedErrorRatio"->ratio|>]];
 Join[KeyDrop[Last[outputs],{"QuadratureOrder","IntegrationBreakpoints"}],<|
  "Status"->If[Length[vectors]===2,"NumericalConvergenceObserved","EvaluatedWithoutConvergenceCheck"],
  "NumericalBackend"->"GiNaC","Method"->"EvaluationOfStoredGPLExpressions",
  "UniqueGPLCount"->Length[gs],"EstimatedErrorRatio"->ratio,
  "WorkingPrecisions"->If[Length[vectors]===2,{wp,wp+20},{wp}],
  "AccuracyGoal"->ag,"PrecisionGoal"->pg,"ElapsedSeconds"->AbsoluteTime[]-started,
  "ErrorEstimateIsRigorousBound"->False,
  "PathCheck"-><|"Method"->"GPLLettersOffStraightContour","FullAnalyticContinuationVerified"->False|>|>]
],"NumericalSolution"],options["TimeLimit"],Failure["NumericalEvaluationTimeLimit",<||>]];


FILE FeynFacet/Private/Transport/Solutions/RationalizingCoordinates.wl

(* Pull back complete differential systems, not individual auxiliary
   integrals. Root signs are fixed at an explicit ordinary-point lift. *)
Begin["FeynFacet`Private`"];
FeynFacet`PullBackMasterIntegralDifferentialSystem::usage="PullBackMasterIntegralDifferentialSystem[system,parametrization,baseLift] pulls the connection and all supplied basis/homogeneous matrices to a verified rationalizing parametrization. Square-root signs are fixed by their principal values at the explicit lift, and tracked as continuous local branches. The result is input for the general finite constructor.";
Options[FeynFacet`PullBackMasterIntegralDifferentialSystem]={"TimeLimit"->120};
FeynFacet`PullBackMasterIntegralDifferentialSystem[system_Association,param_Association,lift_List,OptionsPattern[]]:=
 TimeConstrained[Catch[Module[
 {verification,source=system["KinematicVariables"],target,substitution,images,base,baseRules,sourceRules,
  determinant,eps=system["DimensionalRegulator"],rootRecords={},rootImage,pull,connection,fields,
  result,connectionSource,check},
 verification=FeynFacet`VerifyRationalizingParametrization[param];
 If[!TrueQ[Lookup[verification,"Verified",False]],solutionFail["RationalizingParametrizationNotVerified"]];
 target=param["ParametrizingVariables"];substitution=param["SourceVariableSubstitution"];
 If[Length[source]=!=Length[target]||First/@substitution=!=source||
    !DuplicateFreeQ[Join[source,target]]||Length[lift]=!=Length[target]||
    !VectorQ[lift,NumericQ]||!FreeQ[lift,_Real],
  solutionFail["InvalidRationalizingBasePointLift"]];
 images=source/.substitution;base=images/.Thread[target->lift];
 If[!VectorQ[base,NumericQ]||!FreeQ[base,Indeterminate|_DirectedInfinity],
  solutionFail["RationalizingBasePointNotFinite"]];
 baseRules=Thread[target->lift];sourceRules=Thread[source->base];
 determinant=Cancel[Det[Table[D[images[[i]],target[[j]]],{i,Length[source]},{j,Length[target]}]]];
 If[!TrueQ[Abs[N[determinant/.baseRules,50]]>10^-35],
  solutionFail["RationalizingBasePointJacobianSingular"]];
 rootImage[b_]:=rootImage[b]=Module[{q,candidate,fac,sign,value,reference,radicand},
  q=Cancel[Together[b/.substitution]];
  If[!PolynomialQ[Numerator[q],target]||!PolynomialQ[Denominator[q],target],
   solutionFail["RootRadicandNotRationalAfterPullback"]];
  fac=FactorList[Numerator[q]];candidate=Sqrt[First[fac][[1]]];
  Do[If[OddQ[f[[2]]],solutionFail["RootNotRationalized",<|"Radicand"->b|>]];
    candidate*=f[[1]]^(f[[2]]/2),{f,Rest[fac]}];
  fac=FactorList[Denominator[q]];candidate/=Sqrt[First[fac][[1]]];
  Do[If[OddQ[f[[2]]],solutionFail["RootNotRationalized",<|"Radicand"->b|>]];
    candidate/=f[[1]]^(f[[2]]/2),{f,Rest[fac]}];
  candidate=Cancel[candidate];
  If[!TrueQ[Cancel[Together[candidate^2-q]]===0],solutionFail["RationalizedRootIdentityFailed",<|"Radicand"->b,"Image"->q,"Candidate"->candidate|>]];
  reference=N[Sqrt[b/.sourceRules],60];value=N[candidate/.baseRules,60];
  If[!NumericQ[reference]||!NumericQ[value]||!TrueQ[Abs[reference]>10^-35],
   solutionFail["RootBranchNotRegularAtBasePoint"]];
  sign=Which[TrueQ[Abs[value-reference]<10^-40 Max[1,Abs[reference]]],1,
    TrueQ[Abs[value+reference]<10^-40 Max[1,Abs[reference]]],-1,
    True,solutionFail["RationalizedRootBasePointMismatch"]];
  AppendTo[rootRecords,<|"SourceRadicand"->b,"RationalRoot"->sign candidate,
   "SourceBasePointRoot"->Sqrt[b/.sourceRules],"RootIdentityVerified"->True|>];
  sign candidate
 ];
 pull[z_]:=pull[z]=Which[
  FreeQ[z,Alternatives@@source],z,
  MemberQ[source,z],z/.substitution,
  MatchQ[z,Power[_,_Rational]]&&Denominator[z[[2]]]===2,
   rootImage[z[[1]]]^Numerator[z[[2]]],
  AtomQ[z],z,
  True,Map[pull,z]
 ];
 connection[matrices_]:=Table[
  Map[Cancel,Total[Table[D[images[[j]],target[[i]]] pull[Normal[matrices[[j]]]],
   {j,Length[source]}]],{2}],{i,Length[target]}];
 fields=Association[];
 Do[If[KeyExistsQ[system,key],
   AssociateTo[fields,key->If[MemberQ[{"ConnectionMatrices","OriginalConnectionMatrices"},key],
    connection[system[key]],pull[system[key]]]]],
 {key,{"ConnectionMatrices","OriginalConnectionMatrices","BasisTransformationMatrix",
   "InverseBasisTransformationMatrix","HomogeneousFundamentalMatrix","InverseHomogeneousFundamentalMatrix"}}];
 If[AssociationQ[Lookup[system,"ConnectionCoefficientSource",None]],
  connectionSource=system["ConnectionCoefficientSource"];
  AssociateTo[fields,"ConnectionCoefficientSource"->Join[connectionSource,<|
   "ConnectionMatrices"->connection[connectionSource["ConnectionMatrices"]],
   "BasisTransformationMatrix"->pull[connectionSource["BasisTransformationMatrix"]],
   "InverseBasisTransformationMatrix"->pull[connectionSource["InverseBasisTransformationMatrix"]]|>]]];
 result=Join[KeyDrop[system,{"EpsilonZeroBlockReductions"}],fields,<|
  "KinematicVariables"->target,
  "RationalizingCoordinates"-><|"SourceVariables"->source,"SourceVariableSubstitution"->substitution,
    "SourceBasePoint"->base,"ParametrizingBasePoint"->lift,
    "RootBranches"->rootRecords,"JacobianAtBasePoint"->(determinant/.baseRules),
    "ParametrizationValidation"->verification,
    "DomainConvention"->"A nonsingular simply connected neighborhood of the chosen lift; continuous roots from their stated base values."|>|>];
 Clear[pull,rootImage];result
],"FiniteSolution"],OptionValue["TimeLimit"],Failure["RationalizingPullbackTimeLimit",<||>]];
End[];


## Pro response

The Hermite/integration-by-parts core and fixed-alphabet lower-end expansion are sound. The surrounding evaluator is not yet protected against every invalid specialization or path. The clearest problems are domain checks lost during reduction and arguments discarded during substitution. This is a static review; the validator helpers and C++ executable were not supplied.

1. Preserve domain restrictions through Hermite reduction and specialization

Unless an upstream source-domain check runs, the displayed contour test misses rational poles removed from the GPL alphabet. For example,

∫
0
1
	​

(t−
2
1
	​

)
2
dt
	​


is divergent, but Hermite reduction produces

[−
t−
2
1
	​

1
	​

]
0
1
	​

=−4.

There are no GPL letters left for gplEvaluateList to reject. Both numerical precisions can agree perfectly on this invalid ordinary-integral value.

There is also a concrete lower-end specialization trap:

∫
0
s
	​

t+a
dt
	​

=G[−a;s](a

=0).

Converting generically and then setting a=0,s=1 yields the regularized value G[0;1]=0, while the source integral diverges. Your evaluator deliberately exempts zero letters, so it cannot distinguish this newly singular specialization from legitimate logarithmic regularization.

Retain conversion exclusions and source-path singularities, or recompute the relevant limits after exceptional specialization. This includes base-point zeros and alphabet degeneracies. A formal primitive identity is not permission to cross a pole.

For fixed admissible parameters, expanding GPLs through the maximum rational pole order is sufficient to recover the complete finite lower limit. I see no defect in that principle.

2. Nested arguments are silently discarded

Both substitutions

Wolfram Language
K[j_Integer,_] :> expandKernel[j]
F[j_Integer,_] :> (converted[j] /. upper -> parameter)

ignore the actual argument.

A minimal counterexample is

F
1
	​

(s)=s,F
2
	​

(s)=∫
0
s
	​

F
1
	​

(t
2
)dt.

The correct result is s
3
/3; these replacements instead produce s
2
/2. The same issue affects nested kernel calls.

If validateFiniteDependencies explicitly requires every call’s argument to equal its enclosing integration parameter, this is already excluded. Otherwise, reject nonmatching arguments or perform their actual substitution. The subsequent constant-letter check cannot detect information already discarded.

3. Log normalization and pullback require consistent source branches and constants

gplNormalizeLogs constructs the logarithm continued from Log[r(0)]. That is locally correct, but not necessarily identical to pointwise principal evaluation of the original Log[r(t)].

For example, on 0≤t≤2,

r(t)=(1+it)
4
.

The normalized continuation is 4log(1+it). For t>1, the principal logr(t) differs by −2πi, although the only GPL pole, t=i, is off the contour. Principal logarithms have a cut along the negative real axis; checking GPL poles does not check its preimage under r. 
DLMF

This is acceptable only when the source also means the same continued branch. Otherwise refuse that path. Add this branch-crossing control.

The chain-rule pullback is correct locally. However, the routine does not verify that the computed SourceBasePoint equals any existing constant-normalization point. Any existing top-level BasePoint also survives unchanged despite replacing the variables. Check or rebind that metadata, and honor any existing nonprincipal source-sheet prescription rather than silently resetting it. These are prerequisites for reusing supplied homogeneous/boundary data.

4. Exact parsing is good; wp-5 is not an accuracy certificate

Rationalization converts the supplied approximation into an exact rational input; it does not recover missing information or preserve an uncertainty estimate. 
Wolfram Documentation

For example,

G[a;1]=log(1−1/a),∂
a
	​

G[a;1]=
a(a−1)
1
	​

.

Near a=1, argument uncertainty is strongly amplified. Counting argument digits alone therefore does not justify assigning wp-5 reliable output digits.

Keep the assembled two-precision comparison, but recognize that it cannot detect uncertainty shared by both rationalized inputs. Preserve a sensitivity/error allowance for approximate inputs, especially near poles. SetPrecision assigns precision—it does not establish it—and approximate zeros require absolute-accuracy handling rather than promotion to exact zeros. 
Wolfram Documentation
+1

5. Cache validity depends on an explicit dependency invariant

Excluding outer coefficients and boundary values from the primitive cache key is reasonable: you recompute closure and reassemble them.

However, visitF traverses only direct F references. If allowed a or K definitions can hide additional integral dependencies, closure is incomplete. Enforce the restricted grammar or traverse those dependencies. Also validate the representation schema/convention before reuse; currently gplRepresentationCurrentQ ignores SchemaVersion.

Before trusting accepted evaluations, prioritize the double-pole contour test, exceptional zero-letter specialization, nonidentity nested argument, and logarithmic branch-crossing control. None requires a broader symbolic verification campaign.

## Changes following this review

Source-integral poles and endpoint singularities are checked before numerical GPL evaluation, even if Hermite reduction removes them from the resulting alphabet. Source principal-log cut crossings are refused. Dependency arguments, hidden integral dependencies, and the saved schema are validated. Coordinate pullback binds the source and lifted normalization points and accepts explicit nonprincipal source-root values. Exact kinematic inputs are required by the first GiNaC adapter; supplied numerical boundary precision is retained and convergence is checked after boundary substitution. The tests include the counterexamples above. This paragraph records the implementation work; it is not a second Pro review or a rigorous numerical error proof.
