(* Epsilon order shifts of scalar endpoint distributions and matrix moments. *)
Begin["FeynFacet`Private`"];
Clear[epsOrderEndpoints,epsOrderEndpointMatrices];
epsOrderEndpointMatrices[d_,r_] := Module[
 {m,e,n,ks,target,reports,inverse,vals,logPower,pref,left,right,contracted,moment,normalization},
 m=Normal[d["ExponentMatrix"]];e=d["DimensionalRegulator"];
 n=Length[m];ks=Lookup[d,"TaylorOrders",{0}];target=r["ThroughOrder"];
 logPower=Lookup[d,"LogPower",0];pref=Lookup[d,"Prefactor",1];
 left=Normal[Lookup[d,"LeftMap",IdentityMatrix[n]]];
 right=Normal[Lookup[d,"RightMap",IdentityMatrix[n]]];
 normalization=Lookup[d,"TaylorCoefficientConvention","PowerSeriesCoefficient"];
 If[e===None || !MatchQ[e,_Symbol] || n<1 || Dimensions[m]=!={n,n} ||
   !VectorQ[ks,IntegerQ[#]&&#>=0&] || !IntegerQ[target] ||
   !IntegerQ[logPower]||logPower<0||!MatrixQ[left]||!MatrixQ[right]||
   Last[Dimensions[left]]=!=n||First[Dimensions[right]]=!=n||
   !MemberQ[{"PowerSeriesCoefficient","Derivative"},normalization],
   epsOrderFail["EndpointMatrixRequestInvalid"]];
 reports=Table[
  If[epsOrderZero[Det[m+k IdentityMatrix[n]]],
    epsOrderFail["UnregulatedMatrixEndpointMoment",<|"TaylorOrder"->k|>]];
  inverse=Map[Cancel[Together[#]]&,Inverse[m+k IdentityMatrix[n]],{2}];
  moment=Map[Cancel[Together[#]]&,
   pref (-1)^logPower Factorial[logPower] MatrixPower[inverse,logPower+1]/
    If[normalization==="Derivative",Factorial[k],1],{2}];
  (* Contract the exact maps before assigning orders to boundary columns.
     Eigenvectors or entrywise bounds would miss cancellations here. *)
  contracted=Map[Cancel[Together[#]]&,left.moment.right,{2}];
  vals=Map[epsOrderValuation[#,e]&,contracted,{2}];
  <|"TaylorOrder"->k,"MomentMatrix"->moment,"ContractedMomentMatrix"->contracted,
    "EntryValuations"->vals,
    "CoefficientUpperOrders"->Map[If[#===Infinity,-Infinity,target-#]&,vals,{2}],
    "BoundaryCoefficientUpperOrders"->(If[#===Infinity,-Infinity,target-#]&/@(Min/@Transpose[vals]))|>,
 {k,ks}];
 <|"DataType"->"EndpointEpsilonOrderRequirements","Status"->"EndpointMomentOrdersDetermined",
  "MatrixMoments"->reports,"LogPower"->logPower,
  "TaylorCoefficientConvention"->normalization,"RegularRemainderThroughOrder"->target,
  "Scope"->"Specified matrix-power moments and Taylor orders, contracted with the supplied exact maps. A valid local expansion, its uniform remainder, and any other matching factors are separate inputs."|>
];
epsOrderEndpoints[d_,r_] := Module[
 {e,xs,powers,logs,pref,target,pv,limits,res={},moment,j,faces,loss,reports,lower,axisMoments,choices,choice,faceRecords},
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
  If[limits[[i]]<=-1,
   axisMoments=Table[
    moment=powers[[i]]+j+1;
    If[epsOrderZero[moment],epsOrderFail["EndpointNotRegulated",<|"Variable"->xs[[i]],"NormalDerivativeOrder"->j|>]];
    <|"Variable"->xs[[i]],"NormalDerivativeOrder"->j,
     "MomentCoefficient"->(-1)^logs[[i]] Factorial[logs[[i]]]/
       (Factorial[j] moment^(logs[[i]]+1))|>,
    {j,Reverse[Range[0,Floor[-limits[[i]]]-1]]}];
   AppendTo[res,axisMoments]],
 {i,Length[xs]}];
 faces=Subsets[Range[Length[res]]];
 reports=Flatten[Table[
  choices=If[face==={},{{}},Tuples[res[[face]]]];
  Table[
   moment=pref Times@@Lookup[choice,"MomentCoefficient",{}];
   loss=epsOrderValuation[moment,e];
   <|"BoundaryVariables"->Lookup[choice,"Variable",{}],
     "NormalDerivativeOrders"->Association[Map[#["Variable"]->#["NormalDerivativeOrder"]&,choice]],
     "Projection"->If[face==={},"RegularSubtractedDistribution","BoundaryTaylorCoefficient"],
     "CoefficientUpperOrder"->If[loss===Infinity,-Infinity,target-loss],"MapValuation"->loss,
     "MomentCoefficient"->moment,"OmittedTailLowerBound"->target+1|>,
   {choice,choices}],
 {face,faces}],1];
 <|"DataType"->"EndpointEpsilonOrderRequirements","Status"->"EndpointProjectionOrdersDetermined",
   "Requirements"->reports,"RequestedThroughOrder"->target,
   "Scope"->"Resolved normal factors acting on smooth coefficient functions. Orders apply separately to regular subtracted distributions, faces and corners, before any unspecified matching map.",
   "UnresolvedConditions"->{"A complete local expansion with a uniform subtracted remainder",
      "Joint control of intersecting endpoints","Valuations of all additional matching and basis factors"}|>
];
FeynFacet`DetermineEndpointEpsilonOrders[d_Association,r_Association] :=
 Catch[epsOrderEndpoints[epsOrderNormalize[d,Lookup[d,"DimensionalRegulator",None]],r],"EpsilonOrders"];
End[];
