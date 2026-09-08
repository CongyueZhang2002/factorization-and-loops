(* Sufficient orders from Laurent remainders and finite DE dependence. *)
Begin["FeynFacet`Private`"];
Clear[epsOrderCalculation,epsOrderMatrixPlan,epsOrderPlanFromValuations,epsOrderMin,
 epsOrderAdd,epsOrderCanonicalTerms];
epsOrderProductBounds[a_,b_] := Table[
 epsOrderMin[Table[epsOrderAdd[{a[[i,k]],b[[k,j]]}],{k,Length[b]}]],
 {i,Length[a]},{j,Length[First[b]]}];
epsOrderDistances[beta_] := Module[{d=beta,n=Length[beta]},
 Do[d[[i,i]]=0,{i,n}];
 Do[Do[If[d[[i,k]]=!=Infinity && d[[k,j]]=!=Infinity,
   d[[i,j]]=Min[d[[i,j]],d[[i,k]]+d[[k,j]]]],{i,n},{j,n}],{k,n}];d
];

epsOrderMin[xs_] := If[AnyTrue[xs,MissingQ],Missing["LaurentLowerBoundNotEstablished"],Min[xs]];
epsOrderAdd[xs_] := Which[MemberQ[xs,Infinity],Infinity,
 AnyTrue[xs,MissingQ],Missing["LaurentLowerBoundNotEstablished"],True,Total[xs]];
epsOrderCanonicalTerms[terms_,e_] := Module[{groups,result,coefficient,vals,supplied},
 If[!ListQ[terms] || !AllTrue[terms,AssociationQ[#] && StringQ[Lookup[#,"Input",None]]&],
   epsOrderFail["LinearCombinationTermsRequired"]];
 groups=GatherBy[terms,#["Input"]&];
 result=Table[
  supplied=Select[group,!KeyExistsQ[#,"Coefficient"] && KeyExistsQ[#,"CoefficientLaurentLowerBound"]&];
  If[supplied==={},
   coefficient=Together[Total[Lookup[group,"Coefficient",1]]];
   vals=epsOrderValuation[coefficient,e],
   vals=Table[If[KeyExistsQ[t,"Coefficient"],epsOrderValuation[t["Coefficient"],e],
     Lookup[t,"CoefficientLaurentLowerBound",0]],{t,group}];
   If[!AllTrue[vals,IntegerQ[#] || #===Infinity&],
     epsOrderFail["IntegerCoefficientLaurentBoundRequired"]];
   vals=Min[vals];coefficient=Missing["ExplicitCoefficientNotSupplied"]
  ];
  <|"Input"->group[[1,"Input"]],"Coefficient"->coefficient,
    "LaurentLowerBound"->vals,"SuppliedCoefficientBounds"->supplied|>,
 {group,groups}];
 result
];

epsOrderCalculation[c_] := Module[
 {e,inputs,ops,requests,lower=<||>,assumptions={},nodes=<||>,demands=<||>,
  coefficientOrders={},coefficientAssumptions={},proofs={},unresolved={},id,op,terms,refs,vals,bound,target,
  n,other,need,known,missing,outputRanges,require,coefficientCut,source},
 e=Lookup[c,"DimensionalRegulator",None];inputs=Lookup[c,"Inputs",<||>];
 ops=Lookup[c,"Operations",{}];requests=Lookup[c,"RequestedOrders",<||>];
 If[e===None || !MatchQ[e,_Symbol] || !AssociationQ[inputs] || !AllTrue[Keys[inputs],StringQ] ||
   !ListQ[ops] || !AssociationQ[requests] || requests===<||>,
   epsOrderFail["CalculationAndOutputRequestsRequired"]];
 require[name_,k_] := If[k=!=-Infinity &&
   !(IntegerQ[lower[name]] && k<lower[name]) && lower[name]=!=Infinity,
   AssociateTo[demands,name->Max[Lookup[demands,name,-Infinity],k]]];
 Do[
  source=inputs[id];
  bound=epsOrderBound[If[AssociationQ[source] && !epsOrderKnownBoundQ[source],
     Lookup[source,"LaurentLowerBound",Missing[]],source]];
  AssociateTo[lower,id->bound];AssociateTo[nodes,id-><|"Operation"->"Input"|>];
  If[!epsOrderKnownBoundQ[source] &&
    !epsOrderKnownBoundQ[If[AssociationQ[source],Lookup[source,"LaurentLowerBound",None],None]],
    If[MissingQ[bound],AppendTo[unresolved,id],AppendTo[assumptions,id]]],
 {id,Keys[inputs]}];
 Do[
  id=Lookup[item,"Id",None];op=Lookup[item,"Operation",None];
  If[!StringQ[id] || KeyExistsQ[nodes,id],epsOrderFail["OperationIdentifierInvalid"]];
  Switch[op,
   "LinearCombination",
    terms=epsOrderCanonicalTerms[Lookup[item,"Terms",{}],e];
    coefficientAssumptions=Join[coefficientAssumptions,Flatten[#["SuppliedCoefficientBounds"]& /@ terms]];
    terms=Select[terms,#["LaurentLowerBound"]=!=Infinity&];
    refs=Lookup[terms,"Input",{}];If[terms==={},refs={}];
    If[!AllTrue[refs,KeyExistsQ[nodes,#]&],epsOrderFail["OperationsMustBeInDependencyOrder"]];
    vals=(#["LaurentLowerBound"]& /@ terms);
    bound=epsOrderMin[MapThread[epsOrderAdd[{#1,lower[#2]}]&,{vals,refs}]];
    AssociateTo[nodes,id-><|"Operation"->op,"Terms"->terms,"Valuations"->vals|>],
   "Product"|"Convolution",
    refs=Lookup[item,"Inputs",{}];
    If[Length[refs]<2 || !AllTrue[refs,StringQ[#]&&KeyExistsQ[nodes,#]&],
      epsOrderFail["ProductInputsRequired"]];
    bound=epsOrderAdd[lower /@ refs];
    AssociateTo[nodes,id-><|"Operation"->op,"Inputs"->refs|>],
   _,epsOrderFail["UnsupportedEpsilonOrderOperation",<|"Operation"->op|>]
  ];
  AssociateTo[lower,id->bound],
 {item,ops}];
 Do[
  If[!KeyExistsQ[nodes,id],epsOrderFail["RequestedOutputNotDefined"]];
  target=requests[id];If[ListQ[target] && target=!={},target=Max[target]];
  If[!IntegerQ[target],epsOrderFail["IntegerOutputOrderRequired"]];
  require[id,target],
 {id,Keys[requests]}];
 Do[
  target=Lookup[demands,id,-Infinity];If[target===-Infinity,Continue[]];
  op=nodes[id]["Operation"];If[op==="Input",Continue[]];
  If[op==="LinearCombination",
   terms=nodes[id]["Terms"];vals=nodes[id]["Valuations"];
   Do[
    source=terms[[j,"Input"]];need=target-vals[[j]];require[source,need];
    coefficientCut=If[MissingQ[lower[source]],Missing["InputLaurentBoundRequired"],target-lower[source]];
    AppendTo[coefficientOrders,<|"Output"->id,"Input"->source,
      "Coefficient"->terms[[j,"Coefficient"]],"ThroughOrder"->coefficientCut|>];
    AppendTo[proofs,<|"Output"->id,"Input"->source,"RequiredThroughOrder"->need,
      "DownstreamValuation"->vals[[j]],"OmittedTailLowerBound"->need+1+vals[[j]],
      "RequestedRemainderLowerBound"->target+1|>],
   {j,Length[terms]}],
   refs=nodes[id]["Inputs"];
   Do[
    other=epsOrderAdd[lower /@ Delete[refs,j]];
    If[MissingQ[other],AppendTo[unresolved,<|"Operation"->id,
       "MissingBoundsFor"->Select[Delete[refs,j],MissingQ[lower[#]]&]|>];Continue[]];
    If[other===Infinity,Continue[]];
    need=target-other;require[refs[[j]],need];
    AppendTo[proofs,<|"Output"->id,"Input"->refs[[j]],"RequiredThroughOrder"->need,
      "DownstreamValuation"->other,"OmittedTailLowerBound"->need+1+other,
      "RequestedRemainderLowerBound"->target+1|>],
   {j,Length[refs]}]
  ],
 {id,Reverse[Keys[nodes]]}];
 (* Unused unknown inputs do not obstruct a requested result. *)
 unresolved=DeleteDuplicates[Select[unresolved,
   If[StringQ[#],KeyExistsQ[demands,#],True]&]];
 (* Even a bound used to prune a zero contribution remains an assumption. *)
 outputRanges=Association@Table[id->If[!KeyExistsQ[demands,id],{},
   If[MissingQ[lower[id]],Missing["LaurentLowerBoundRequired"],Range[lower[id],demands[id]]]],
   {id,Keys[inputs]}];
 <|"DataType"->"SufficientEpsilonOrders",
  "Status"->Which[unresolved=!={},"AdditionalLaurentBoundsRequired",
    assumptions=!={} || coefficientAssumptions=!={},"SufficientForAssumedInputBounds",True,"SufficientForInputRepresentations"],
  "RequiredInputUpperOrders"->KeyTake[demands,Keys[inputs]],"RequiredInputOrders"->outputRanges,
  "RequiredIntermediateUpperOrders"->KeyDrop[demands,Keys[inputs]],
  "CoefficientExpansionOrders"->coefficientOrders,
  "LaurentLowerBounds"->lower,"AssumedInputBounds"->assumptions,
  "SuppliedCoefficientBounds"->coefficientAssumptions,
  "MissingLaurentBounds"->unresolved,"RemainderInequalities"->proofs,
  "RequestedOrders"->requests,
  "Scope"->Lookup[c,"Scope","The declared calculation and its function/distribution spaces."],
  "ConvolutionConvention"->"Declared convolutions are well-defined epsilon-independent bilinear operations; any regulator-dependent factors must be explicit.",
  "PhysicalNNLOCoverageInferred"->False|>
];
FeynFacet`DetermineEpsilonOrders[c_Association] := Catch[epsOrderCalculation[epsOrderNormalize[c,Lookup[c,"DimensionalRegulator",None]]],"EpsilonOrders"];

(* Import an existing coefficient-valuation table without inventing the
   coefficient functions or silently supplying master-integral pole bounds. *)
epsOrderMasterCoefficientCalculation[d_,r_] := Module[
 {entries,e,upper,bounds,ids,terms,inputs,result,indices,valuation},
 entries=Lookup[d,"Entries",{}];e=Lookup[d,"DimensionalRegulator",None];
 upper=Lookup[r,"ThroughOrder",None];
 bounds=Lookup[r,"MasterIntegralLaurentLowerBounds",<||>];
 If[entries==={} || !AllTrue[entries,AssociationQ] || !IntegerQ[upper] ||
   !AssociationQ[bounds],epsOrderFail["MasterCoefficientValuationRequestRequired"]];
 indices=Lookup[entries,"MasterIntegralIndex"];
 If[!VectorQ[indices,IntegerQ] || !DuplicateFreeQ[indices],
   epsOrderFail["DistinctMasterIntegralIndicesRequired"]];
 ids=("I"<>ToString[#]& /@ indices);
 inputs=Association@MapThread[#1->Lookup[bounds,#2,Missing["IntegralLaurentBoundRequired"]]&,{ids,indices}];
 terms=MapThread[Function[{entry,id},
   valuation=Lookup[entry,"HardFunctionCoefficientEpsilonValuation",Missing[]];
   If[valuation===Missing["ZeroColumn"],valuation=Infinity];
   If[!IntegerQ[valuation] && valuation=!=Infinity,
     epsOrderFail["CoefficientLaurentBoundNotEstablished",<|"Input"->id|>]];
   <|"Input"->id,"CoefficientLaurentLowerBound"->valuation,
     "DeterminationMethod"->Lookup[entry,"DeterminationMethod","SuppliedValuation"]|>],
   {entries,ids}];
 result=epsOrderCalculation[<|"DimensionalRegulator"->e,"Inputs"->inputs,
   "Operations"->{<|"Id"->"hardFunction","Operation"->"LinearCombination","Terms"->terms|>},
   "RequestedOrders"-><|"hardFunction"->upper|>,
   "Scope"->"The supplied hard-function master coefficients before any unspecified endpoint integration, renormalization, or PDF convolution."|>];
 Join[result,<|"MasterIntegralInputMap"->AssociationThread[ids,entries],
   "SourceDataType"->Lookup[d,"DataType",None]|>]
];
FeynFacet`DetermineEpsilonOrders[d_Association,r_Association] :=
 Catch[epsOrderMasterCoefficientCalculation[epsOrderNormalize[d,Lookup[d,"DimensionalRegulator",None]],r],"EpsilonOrders"];

epsOrderPlanFromValuations[beta_,lv_,rv_,requests_] := Module[
 {n=Length[beta],distance=beta,vu,lu,ru,bu,queue={},entry,i,j,k,a,b,s,
  cutoff,new,counts,rawCount},
 vu=ConstantArray[-Infinity,{n,n}];lu=ConstantArray[-Infinity,Dimensions[lv]];
 ru=ConstantArray[-Infinity,Dimensions[rv]];bu=ConstantArray[-Infinity,{n,n}];
 Do[distance[[i,i]]=0;vu[[i,i]]=0,{i,n}];
 Do[Do[If[distance[[i,s]]=!=Infinity && distance[[s,j]]=!=Infinity,
   distance[[i,j]]=Min[distance[[i,j]],distance[[i,s]]+distance[[s,j]]]],
   {i,n},{j,n}],{s,n}];
 Do[
  {i,j,k}=entry;
  Do[
   If[MemberQ[{lv[[i,a]],rv[[b,j]],distance[[a,b]]},Infinity] ||
     k<lv[[i,a]]+distance[[a,b]]+rv[[b,j]],Continue[]];
   cutoff=k-lv[[i,a]]-rv[[b,j]];
   If[cutoff>vu[[a,b]],vu[[a,b]]=cutoff;AppendTo[queue,{a,b}]];
   lu[[i,a]]=Max[lu[[i,a]],k-distance[[a,b]]-rv[[b,j]]];
   ru[[b,j]]=Max[ru[[b,j]],k-lv[[i,a]]-distance[[a,b]]],
  {a,n},{b,n}],
 {entry,requests}];
 While[queue=!={},
  {a,b}=First[queue];queue=Rest[queue];cutoff=vu[[a,b]];
  Do[
   If[beta[[a,s]]===Infinity || distance[[s,b]]===Infinity ||
       beta[[a,s]]+distance[[s,b]]>cutoff,Continue[]];
   bu[[a,s]]=Max[bu[[a,s]],cutoff-distance[[s,b]]];
   new=cutoff-beta[[a,s]];
   If[new>vu[[s,b]],vu[[s,b]]=new;AppendTo[queue,{s,b}]],
  {s,n}]
 ];
 counts=Total[Flatten[Table[
   If[vu[[a,b]]===-Infinity,0,vu[[a,b]]-distance[[a,b]]+1],{a,n},{b,n}]]];
 <|"DataType"->"FundamentalMatrixEpsilonOrderRequirements",
  "Status"->"SufficientOrdersDetermined","RequestedCoefficients"->requests,
  "ConnectionEntryLaurentLowerBounds"->beta,"TransformedCoefficientLowerBounds"->distance,
  "TransformedCoefficientUpperOrders"->vu,"ConnectionCoefficientUpperOrders"->bu,
  "LeftBasisCoefficientUpperOrders"->lu,"RightBasisCoefficientUpperOrders"->ru,
  "MaximumTransformedOrder"->Max[Flatten[vu]],
  "RequiredTransformedCoefficientCount"->counts,
  "RemainderArgument"->"Every omitted L[i,a] V[a,b] R[b,j] term starts above its requested order; all potentially contributing DE dependencies are included.",
  "PhysicalNNLOCoverageInferred"->False|>
];
epsOrderMatrixPlan[system_,request_] := Module[{e,a,n,vars,left,right,beta,lv,rv,req},
 e=Lookup[system,"DimensionalRegulator",None];a=Lookup[system,"ConnectionMatrices",{}];
 If[e===None || !MatchQ[e,_Symbol] || a==={},epsOrderFail["PreparedDifferentialSystemRequired"]];
 n=Length[First[a]];
 If[n<1 || !AllTrue[a,Dimensions[Normal[#]]==={n,n}&],epsOrderFail["ConnectionDimensionsInvalid"]];
 left=Normal[Lookup[system,"LeftBasisMatrix",IdentityMatrix[n]]];
 right=Normal[Lookup[system,"RightBasisMatrix",IdentityMatrix[n]]];
 If[!MatrixQ[left] || !MatrixQ[right] || Dimensions[left][[2]]=!=n ||
    Dimensions[right][[1]]=!=n,epsOrderFail["BasisDimensionsInvalid"]];
 beta=Table[Min[epsOrderValuation[#[[i,j]],e]& /@ a],{i,n},{j,n}];
 If[AnyTrue[Flatten[beta],#<0&],epsOrderFail["EpsilonRegularConnectionRequired"]];
 If[!And@@Flatten[Table[beta[[i,j]]>0,{i,n},{j,i,n}]],
   epsOrderFail["TriangularEpsilonZeroConnectionRequired"]];
 lv=Map[epsOrderValuation[#,e]&,left,{2}];rv=Map[epsOrderValuation[#,e]&,right,{2}];
 req=Lookup[request,"RequestedCoefficients",{}];
 If[!ListQ[req] || !AllTrue[req,MatchQ[#,{_Integer,_Integer,_Integer}] &&
   1<=#[[1]]<=Length[left] && 1<=#[[2]]<=Dimensions[right][[2]]&],
   epsOrderFail["RequestedCoefficientTriplesRequired"]];
 epsOrderPlanFromValuations[beta,lv,rv,req]
];
FeynFacet`DetermineFundamentalMatrixEpsilonOrders[system_Association,request_Association] :=
 Catch[epsOrderMatrixPlan[epsOrderNormalize[system,Lookup[system,"DimensionalRegulator",None]],request],"EpsilonOrders"];
End[];
