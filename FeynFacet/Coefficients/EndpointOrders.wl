(* Epsilon order shifts of scalar endpoint distributions and matrix moments. *)
Begin["FeynFacet`Private`"];
Clear[epsOrderEndpoints,epsOrderEndpointMatrices];
epsOrderEndpointMatrices[d_,r_] := Module[{m,e,n,ks,target,reports,inverse,vals},
 m=Normal[d["ExponentMatrix"]];e=d["DimensionalRegulator"];
 n=Length[m];ks=Lookup[d,"TaylorOrders",{0}];target=r["ThroughOrder"];
 If[e===None || !MatchQ[e,_Symbol] || n<1 || Dimensions[m]=!={n,n} || !VectorQ[ks,IntegerQ[#]&&#>=0&] ||
   !IntegerQ[target],epsOrderFail["EndpointMatrixRequestInvalid"]];
 reports=Table[
  If[epsOrderZero[Det[m+k IdentityMatrix[n]]],
    epsOrderFail["UnregulatedMatrixEndpointMoment",<|"TaylorOrder"->k|>]];
  inverse=Map[Cancel,Inverse[m+k IdentityMatrix[n]],{2}];
  vals=Map[epsOrderValuation[#,e]&,inverse,{2}];
  <|"TaylorOrder"->k,"MomentMatrix"->inverse,"EntryValuations"->vals,
    "CoefficientUpperOrders"->Map[If[#===Infinity,-Infinity,target-#]&,vals,{2}]|>,
 {k,ks}];
 <|"DataType"->"EndpointEpsilonOrderRequirements","Status"->"EndpointMomentOrdersDetermined",
  "MatrixMoments"->reports,"RegularRemainderThroughOrder"->target,
  "Scope"->"Specified matrix-power moments and Taylor orders. A valid local expansion, its uniform remainder, and any matching factors are separate inputs."|>
];
epsOrderEndpoints[d_,r_] := Module[
 {e,xs,powers,logs,pref,target,pv,limits,res={},moment,j,faces,loss,reports,lower},
 If[KeyExistsQ[d,"ExponentMatrix"],Return[epsOrderEndpointMatrices[d,r]]];
 e=Lookup[d,"DimensionalRegulator",None];xs=Lookup[d,"NormalVariables",{}];
 powers=Lookup[d,"EndpointPowers",{}];logs=Lookup[d,"LogPowers",ConstantArray[0,Length[xs]]];
 pref=Lookup[d,"Prefactor",1];target=Lookup[r,"ThroughOrder",None];
 If[e===None || !MatchQ[e,_Symbol] || xs==={} || !DuplicateFreeQ[xs] || MemberQ[xs,e] ||
   !VectorQ[xs,MatchQ[#,_Symbol]&] || Length[xs]=!=Length[powers] ||
   Length[logs]=!=Length[xs] || !VectorQ[logs,IntegerQ[#]&&#>=0&] || !IntegerQ[target] ||
   !FreeQ[pref,Alternatives@@xs],
   epsOrderFail["ResolvedEndpointExpansionRequired"]];
 pv=epsOrderValuation[pref,e];
 If[pv===Infinity,Return[<|"DataType"->"EndpointEpsilonOrderRequirements",
   "Status"->"ZeroPrefactor","Requirements"->{}|>]];
 If[!AllTrue[powers,With[{z=Together[#]},
   PolynomialQ[Numerator[z],e] && PolynomialQ[Denominator[z],e]]&],
   epsOrderFail["RationalEndpointExponentRequired"]];
 limits=Quiet[Limit[#,e->0]]& /@ powers;
 If[!VectorQ[limits,MatchQ[#,_Integer|_Rational]&],
   epsOrderFail["EndpointExponentLimitsNotEstablished"]];
 Do[
  If[IntegerQ[limits[[i]]] && limits[[i]]<=-1,
   j=-limits[[i]]-1;moment=powers[[i]]+j+1;
   If[epsOrderZero[moment],epsOrderFail["EndpointNotRegulated",<|"Variable"->xs[[i]]|>]];
   AppendTo[res,<|"Variable"->xs[[i]],"NormalDerivativeOrder"->j,
    "MomentCoefficient"->(-1)^logs[[i]] Factorial[logs[[i]]]/
       (Factorial[j] moment^(logs[[i]]+1))|>]],
 {i,Length[xs]}];
 faces=Subsets[Range[Length[res]]];
 reports=Table[
   moment=pref Times@@(res[[#,"MomentCoefficient"]]& /@ face);
   loss=epsOrderValuation[moment,e];
   <|"BoundaryVariables"->(res[[#,"Variable"]]& /@ face),
     "NormalDerivativeOrders"->Association@Table[res[[i,"Variable"]]->res[[i,"NormalDerivativeOrder"]],{i,face}],
     "Projection"->If[face==={},"RegularSubtractedDistribution","BoundaryTaylorCoefficient"],
     "CoefficientUpperOrder"->target-loss,"MapValuation"->loss,
     "MomentCoefficient"->moment,"OmittedTailLowerBound"->target+1|>,
 {face,faces}];
 <|"DataType"->"EndpointEpsilonOrderRequirements","Status"->"EndpointProjectionOrdersDetermined",
   "Requirements"->reports,"RequestedThroughOrder"->target,
   "Scope"->"Resolved normal factors acting on smooth coefficient functions. Orders apply separately to regular subtracted distributions, faces and corners, before any unspecified matching map.",
   "UnresolvedConditions"->{"A complete local expansion with a uniform subtracted remainder",
      "Joint control of intersecting endpoints","Valuations of all additional matching and basis factors"}|>
];
FeynFacet`DetermineEndpointEpsilonOrders[d_Association,r_Association] :=
 Catch[epsOrderEndpoints[epsOrderNormalize[d,Lookup[d,"DimensionalRegulator",None]],r],"EpsilonOrders"];
End[];
