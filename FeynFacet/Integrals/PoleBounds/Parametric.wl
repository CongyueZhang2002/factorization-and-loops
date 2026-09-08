(* Primary sectors and endpoint resolution for normalized parametric integrals.
   No coefficient integration or global differential equation is performed. *)
Begin["FeynFacet`Private`"];
Clear[epsOrderParametricBound,epsOrderPrimarySectors,epsOrderResolveSectors,
 epsOrderPositivePolynomialQ,epsOrderResolvedParametricBound,epsOrderExponentQ];

(* Tensor-product Bernstein coefficients give a cheap exact sufficient
   positivity test. Nonnegative coefficients and positive vertices imply
   positivity on the closed cube; a nonzero nonnegative polynomial is
   positive in its open cube. Failure means undecided, never nonpositive. *)
epsOrderBernsteinPositiveQ[p_,xs_,closed_:True] := Module[
 {poly=Expand[p],degrees,monomials,indices,basis,vertices,value},
 If[!PolynomialQ[poly,xs]||!FreeQ[poly,_Real],Return[False]];
 If[xs==={},Return[TrueQ[poly>0]]];
 degrees=Exponent[poly,#]&/@xs;
 If[!VectorQ[degrees,IntegerQ[#]&&#>=0&]||Times@@(degrees+1)>4096,Return[False]];
 If[closed,
  vertices=(poly/.Thread[xs->#])&/@Tuples[{0,1},Length[xs]];
  If[!AllTrue[vertices,TrueQ[#>0]&],Return[False]]];
 monomials=CoefficientRules[poly,xs];indices=Tuples[Range[0,#]&/@degrees];
 basis=Table[Total[Function[term,
   If[And@@Thread[First[term]<=index],
    Last[term] Times@@MapThread[Binomial[#1,#2]/Binomial[#3,#2]&,
      {index,First[term],degrees}],0]]/@monomials],{index,indices}];
 AllTrue[basis,TrueQ[#>=0]&]&&AnyTrue[basis,TrueQ[#>0]&]
];
epsOrderExponentQ[z_,e_] := With[{r=Together[z]},
 PolynomialQ[Numerator[r],e] && PolynomialQ[Denominator[r],e] &&
 MatchQ[Quiet[Limit[r,e->0]],_Integer|_Rational]];
epsOrderPositivePolynomialQ[p_,xs_,e_,seconds_] := Module[{coefficients,c},
 If[!PolynomialQ[p,xs] || !FreeQ[p,e] || !FreeQ[p,_Real],Return[False]];
 c=p/.Thread[xs->0];
 If[!TrueQ[c>0],Return[False]];
 coefficients=Last /@ CoefficientRules[Expand[p],xs];
 AllTrue[coefficients,TrueQ[#>=0]&] ||
   epsOrderBernsteinPositiveQ[p,xs,True] ||
   epsOrderRegularRationalQ[1/p,xs,e,seconds]
];

epsOrderPrimarySectors[d_,e_] := Module[{xs,nu,l,dim,u,f,pref,n,total,scale},
 xs=Lookup[d,"FeynmanParameters",{}];nu=Lookup[d,"PropagatorPowers",{}];
 l=Lookup[d,"LoopCount",None];dim=Lookup[d,"Dimension",4-2e];
 {u,f}=Lookup[d,"SymanzikPolynomials",{None,None}];n=Length[xs];
 If[n<1 || !VectorQ[xs,MatchQ[#,_Symbol]&] || !DuplicateFreeQ[xs] ||
   MemberQ[xs,e] || Length[nu]=!=n || !VectorQ[nu,IntegerQ[#]&&#>0&] ||
   !IntegerQ[l] || l<1 || !epsOrderExponentQ[dim,e] ||
   !FreeQ[{u,f},e] || !PolynomialQ[u,xs] || !PolynomialQ[f,xs] ||
   !KeyExistsQ[d,"NormalizationPrefactor"],
   epsOrderFail["NormalizedScalarFeynmanParameterRepresentationRequired"]];
 If[Lookup[d,"CutPropagators",{}]=!={},
   epsOrderFail["CutIntegralRequiresItsCutParametricRepresentation"]];
 scale=Unique["projectiveScale"];
 If[!epsOrderZero[(u/.Thread[xs->scale xs])-scale^l u] ||
   !epsOrderZero[(f/.Thread[xs->scale xs])-scale^(l+1) f],
   epsOrderFail["SymanzikHomogeneityMismatch"]];
 total=Total[nu];
 pref=d["NormalizationPrefactor"] Gamma[total-l dim/2]/Times@@(Gamma /@ nu);
 Table[<|"IntegrationVariables"->Delete[xs,pivot],
   "EndpointPowers"->Delete[nu-1,pivot],"Prefactor"->pref,"RegularFactor"->1,
   "PolynomialFactors"->{
    <|"Polynomial"->(u/.xs[[pivot]]->1),"Exponent"->total-(l+1) dim/2|>,
    <|"Polynomial"->(f/.xs[[pivot]]->1),"Exponent"->-total+l dim/2|>},
   "PrimarySector"->pivot|>,{pivot,n}]
];

epsOrderResolveSectors[s_,e_,seconds_,maxSectors_,maxDepth_] := Module[
 {xs,n,powers,upper,logs,pref,g,factors,logvars,initial,queue,leaves={},state,
  unresolved,poly,exponent,monomial,unit,rules,coefficients,subsets,chosen,
  child,map,alpha,newFactors,branches,next,lp,depth,limits,constant,gVal,splitUpper},
 xs=Lookup[s,"IntegrationVariables",{}];n=Length[xs];
 powers=Lookup[s,"EndpointPowers",ConstantArray[0,n]];
 upper=Lookup[s,"UpperEndpointPowers",ConstantArray[0,n]];
 logs=Lookup[s,"LogPowers",ConstantArray[0,n]];
 pref=Lookup[s,"Prefactor",1];g=Lookup[s,"RegularFactor",1];
 factors=Lookup[s,"PolynomialFactors",{}];
 If[!VectorQ[xs,MatchQ[#,_Symbol]&] || !DuplicateFreeQ[xs] || MemberQ[xs,e] ||
   Length[powers]=!=n || Length[upper]=!=n || Length[logs]=!=n ||
   !AllTrue[Join[powers,upper],epsOrderExponentQ[#,e]&] ||
   !VectorQ[logs,IntegerQ[#]&&#>=0&] || !ListQ[factors] ||
   !AllTrue[factors,AssociationQ[#] && KeyExistsQ[#,"Polynomial"] &&
     epsOrderExponentQ[Lookup[#,"Exponent",None],e]&] ||
   !FreeQ[pref,Alternatives@@xs],epsOrderFail["ParametricIntegralTermInvalid"]];
 If[epsOrderZero[g] || epsOrderZero[pref],
  Return[{<|"IntegrationVariables"->xs,"EndpointPowers"->powers,
    "LogPowers"->logs,"Prefactor"->0,"RegularFactor"->1,"PolynomialFactors"->{},
    "CoordinateMap"->xs|>}]];
 If[PolynomialQ[Numerator[Together[g]],Append[xs,e]] &&
   PolynomialQ[Denominator[Together[g]],Append[xs,e]],
  gVal=epsOrderValuation[g,e];pref=pref e^gVal;g=Cancel[g/e^gVal]];
 If[!epsOrderRegularRationalQ[g,xs,e,seconds] && n>0,
   (* Move a regulator-independent polynomial denominator into the factors. *)
   poly=Denominator[Together[g]];
   If[!PolynomialQ[poly,xs] || !FreeQ[poly,e],
     epsOrderFail["UniformRegularPartNotEstablished"]];
   factors=Append[factors,<|"Polynomial"->poly,"Exponent"->-1|>];
   g=Numerator[Together[g]]
 ];
 If[MemberQ[upper,Except[0]] && logs=!=ConstantArray[0,n],
   epsOrderFail["UpperEndpointWithLogarithmsRequiresExplicitSubdivision"]];
 logvars=Table[Unique["parameterLog"],{n}];
 initial=<|"IntegrationVariables"->xs,"EndpointPowers"->powers,"Prefactor"->pref,
   "RegularFactor"->g,"PolynomialFactors"->factors,"LogPolynomial"->Times@@(logvars^logs),
   "CoordinateMap"->xs,"Depth"->0|>;
 branches={initial};
 splitUpper=Table[!epsOrderZero[upper[[j]]]||AnyTrue[factors,
   !epsOrderZero[#["Exponent"]]&&!epsOrderPositivePolynomialQ[
     #["Polynomial"]/.xs[[j]]->1,Delete[xs,j],e,seconds]&],{j,n}];
 Do[If[!TrueQ[splitUpper[[j]]],Continue[]];
  next={};
  Do[
   (* Two half-cubes move both endpoints to zero. *)
   Do[
    map={xs[[j]]->If[side===0,xs[[j]]/2,1-xs[[j]]/2]};
    child=state;alpha=state["EndpointPowers"];
    child["RegularFactor"]=state["RegularFactor"]/.map;
    child["CoordinateMap"]=state["CoordinateMap"]/.map;
    newFactors=state["PolynomialFactors"]/.map;
    AppendTo[newFactors,<|"Polynomial"->1-xs[[j]]/2,
      "Exponent"->If[side===0,upper[[j]],alpha[[j]]]|>];
    child["PolynomialFactors"]=newFactors;
    child["Prefactor"]=state["Prefactor"] 2^(-1-If[side===0,alpha[[j]],upper[[j]]]);
    If[side===1,alpha[[j]]=upper[[j]]];
    child["EndpointPowers"]=alpha;AppendTo[next,child],
   {side,0,1}],{state,branches}];
  branches=next;
  If[Length[branches]>maxSectors,epsOrderFail["SectorCountLimitExceeded"]],
 {j,n}];
 queue=branches;
 While[queue=!={},
  state=First[queue];queue=Rest[queue];
  alpha=state["EndpointPowers"];pref=state["Prefactor"];
  newFactors={};unresolved={};
  Do[
   poly=Expand[factor["Polynomial"]];exponent=factor["Exponent"];
   If[epsOrderZero[exponent],Continue[]];
   If[!PolynomialQ[poly,xs] || !FreeQ[poly,e] || poly===0,
     epsOrderFail["RegulatorIndependentNonzeroPolynomialRequired"]];
   If[n===0,
    If[!TrueQ[poly>0],epsOrderFail["PositiveParametricPolynomialRequired"]];
    pref=pref poly^exponent;Continue[]];
   rules=CoefficientRules[poly,xs];
   monomial=Min /@ Transpose[First /@ rules];
   unit=Cancel[poly/Times@@(xs^monomial)];
   alpha=Map[Cancel,alpha+monomial exponent];
   If[FreeQ[unit,Alternatives@@xs],
    If[!TrueQ[unit>0],epsOrderFail["PositiveParametricPolynomialRequired"]];
    pref=pref unit^exponent;Continue[]];
   AppendTo[newFactors,<|"Polynomial"->unit,"Exponent"->exponent|>];
   If[!epsOrderPositivePolynomialQ[unit,xs,e,seconds],
    coefficients=Last /@ CoefficientRules[Expand[unit],xs];
    If[!AllTrue[coefficients,TrueQ[#>0]&] &&
       !epsOrderBernsteinPositiveQ[unit,xs,False] &&
       !TrueQ[With[{variables=xs,
          condition=And@@Join[Thread[xs>0],Thread[xs<=1],{unit<=0}]},
         TimeConstrained[Resolve[Exists[variables,condition],Reals],seconds,$Failed]]===False],
      epsOrderFail["PolynomialPositivityOrEndpointResolutionNotEstablished",
        <|"Polynomial"->unit|>]];
    (* Mixed coefficients are allowed only after an exact proof of strict
       positivity away from the lower coordinate faces. Resolution still
       accepts a final unit only when it is positive on the closed cube. *)
    AppendTo[unresolved,unit]],
  {factor,state["PolynomialFactors"]}];
  state["EndpointPowers"]=alpha;state["Prefactor"]=pref;
  state["PolynomialFactors"]=newFactors;
  If[unresolved==={},
   If[n===0,
    AppendTo[leaves,Join[KeyDrop[state,{"LogPolynomial","Depth"}],<|"LogPowers"->{}|>]],
    Do[AppendTo[leaves,Join[KeyDrop[state,{"LogPolynomial","Depth"}],
      <|"LogPowers"->First[term],"Prefactor"->pref Last[term]|>]],
      {term,CoefficientRules[Expand[state["LogPolynomial"]],logvars]}]];
   Continue[]
  ];
  depth=state["Depth"];
  If[depth>=maxDepth,epsOrderFail["SectorDepthLimitExceeded"]];
  poly=First[unresolved];chosen=None;
  Do[
   chosen=SelectFirst[Subsets[Range[n],{size}],
     epsOrderZero[poly/.Thread[xs[[#]]->0]]&,None];
   If[chosen=!=None,Break[]],
  {size,2,n}];
  If[chosen===None,epsOrderFail["EndpointBlowupNotFound"]];
  Do[
   map=Thread[xs[[DeleteCases[chosen,pivot]]]->
      xs[[pivot]] xs[[DeleteCases[chosen,pivot]]]];
   child=state;alpha=state["EndpointPowers"];
   alpha[[pivot]]=Total[alpha[[chosen]]]+Length[chosen]-1;
   child["EndpointPowers"]=Map[Cancel,alpha];
   child["RegularFactor"]=state["RegularFactor"]/.map;
   child["PolynomialFactors"]=state["PolynomialFactors"]/.map;
   child["CoordinateMap"]=state["CoordinateMap"]/.map;
   child["LogPolynomial"]=Expand[state["LogPolynomial"]/.
     Thread[logvars[[DeleteCases[chosen,pivot]]]->
       logvars[[DeleteCases[chosen,pivot]]]+logvars[[pivot]]]];
   child["Depth"]=depth+1;AppendTo[queue,child],
  {pivot,chosen}];
  If[Length[queue]+Length[leaves]>maxSectors,epsOrderFail["SectorCountLimitExceeded"]]
 ];
 leaves
];

epsOrderResolvedParametricBound[s_,e_,seconds_] := Module[
 {xs=s["IntegrationVariables"],g=s["RegularFactor"],pref=s["Prefactor"],
  powers=s["EndpointPowers"],logs=s["LogPowers"],smooth={},a,delta,loss,ev},
 Do[If[IntegerQ[factor["Exponent"]],
    g=g factor["Polynomial"]^factor["Exponent"],AppendTo[smooth,factor]],
 {factor,s["PolynomialFactors"]}];
 If[xs==={},Return[<|"LowerBound"->epsOrderValuation[pref g,e],
   "Method"->"ZeroDimensionalParameterIntegral"|>]];
 If[smooth==={},Return[epsOrderSectorBound[Join[s,<|"RegularFactor"->g|>],e,seconds]]];
 If[!epsOrderRegularRationalQ[g,xs,e,seconds],
   epsOrderFail["UniformRegularPartNotEstablished"]];
 If[epsOrderZero[g] || epsOrderZero[pref],
   Return[<|"LowerBound"->Infinity,"Method"->"ZeroIntegrand"|>]];
 (* Polynomial powers with nonzero positive units are holomorphic in epsilon
    and smooth on the cube. They cannot create additional endpoint poles. *)
 loss=Table[
  a=Limit[powers[[j]],e->0];
  If[IntegerQ[a] && a<=-1,
   delta=Cancel[powers[[j]]-a];
   If[epsOrderZero[delta],epsOrderFail["EndpointNotRegulated"]];
   (logs[[j]]+1) epsOrderValuation[delta,e],0],{j,Length[xs]}];
 <|"LowerBound"->epsOrderValuation[pref,e]-Total[loss],
   "Method"->"ResolvedPolynomialPowersAndTaylorSubtraction",
   "PotentialEndpointPoleOrders"->loss,"RegularPolynomialFactors"->smooth|>
];

epsOrderParametricBound[d_,e_,seconds_,maxSectors_,maxDepth_] := Module[
 {terms,resolved={},reports,part,type=Lookup[d,"Representation","UnitCube"],factorBounds},
 If[!IntegerQ[maxSectors] || maxSectors<1 || !IntegerQ[maxDepth] || maxDepth<0,
   epsOrderFail["SectorResolutionLimitsInvalid"]];
 If[type==="ProductOfIntegrals",
  If[!MatchQ[Lookup[d,"Factors",{}],{__Association}],epsOrderFail["IntegralFactorsRequired"]];
  reports=FeynFacet`DetermineIntegralLaurentBound[#,"RegularityProofTimeLimit"->seconds,
    "MaximumSectors"->maxSectors,"MaximumSectorDepth"->maxDepth]& /@ d["Factors"];
  If[AnyTrue[reports,FailureQ],epsOrderFail["IntegralFactorLaurentBoundNotEstablished",
    <|"FactorBounds"->reports|>]];
  factorBounds=Lookup[reports,"LowerBound"];
  Return[<|"DataType"->"IntegralLaurentBound","Status"->"BoundEstablishedForRepresentation",
    "LowerBound"->If[MemberQ[factorBounds,Infinity],Infinity,
      epsOrderValuation[Lookup[d,"Prefactor",1],e]+Total[factorBounds]],
    "Representation"->d,"Method"->"ProductOfIndependentIntegralBounds",
    "FactorBounds"->reports,"IntegralValuesEvaluatedNumerically"->False|>]
 ];
 If[type==="BaikovCut" && Sort[d["CutIndices"]]=!=Range[Length[d["IntegrationVariables"]]],
  Return[cutOrderPoleBound[d,e,seconds]]];
 terms=Switch[type,
  "FeynmanParameters",epsOrderPrimarySectors[d,e],
  "ProjectiveFeynmanParameters",miRepSimplexSectors[d,e],
  "BaikovCut",miRepClosedCutTerms[d,e],
  "MomentumSpace",epsOrderFail["ParameterRepresentationRequired",<|"MomentumSpaceDefinitionConstructed"->True|>],
  "UnitCube",Lookup[d,"Terms",{}],
  _,epsOrderFail["UnsupportedIntegralRepresentation",<|"Representation"->type|>]];
 If[terms==={} || !AllTrue[terms,AssociationQ],epsOrderFail["ParametricIntegralTermsRequired"]];
 Do[
  If[Length[resolved]>=maxSectors,epsOrderFail["SectorCountLimitExceeded"]];
  part=epsOrderResolveSectors[term,e,seconds,maxSectors-Length[resolved],maxDepth];
  resolved=Join[resolved,part],
 {term,terms}];
 reports=epsOrderResolvedParametricBound[#,e,seconds]& /@ resolved;
 <|"DataType"->"IntegralLaurentBound","Status"->"BoundEstablishedForRepresentation",
   "LowerBound"->Min[Lookup[reports,"LowerBound"]],"TermBounds"->reports,
   "Representation"->d,"ResolvedTerms"->resolved,"SectorCount"->Length[resolved],
   "IntegralValuesEvaluatedNumerically"->False,
   "Scope"->"The supplied normalized parameter integral at its supplied kinematics, continued meromorphically in epsilon.",
   "SectorResolution"->"Exact endpoint substitutions and monomial extraction; bounded subset selection. Failure to resolve within the limits returns no pole bound."|>
];
End[];
