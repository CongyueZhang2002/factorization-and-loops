Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;

e=Global`Epsilon;
(* Zero-balanced logarithm, negative integer resonance, and a regular
   endpoint test the Gauss connection formula independently of EEC. *)
a=FeynFacet`GaussEndpointSingularTerms[(1-z)^(-1-e)Hypergeometric2F1[1+e,1+e,2+2e,z],{z,1},e];
FTTest`FTAssert["zero-balanced resonance retains its endpoint logarithm",AssociationQ[a]&&Sort[Lookup[a["Terms"],"LogPower"]]==={0,1}];
If[AssociationQ[a],p=Total[(#["Coefficient"]t^(#["Power"])Log[t]^#["LogPower"])&/@a["Terms"]];
 actual=(1-z)^(-1-e)Hypergeometric2F1[1+e,1+e,2+2e,z];
 FTTest`FTAssert["the logarithmic connection series matches the exact function",Abs[N[((actual/.z->1-t)-p)t^(1+e)/.e->-1/7/.t->10^-12,40]]<10^-9]];
b=FeynFacet`GaussEndpointSingularTerms[z^(-1-e)Hypergeometric2F1[1+e,1+e,2+2e,z],{z,0},e];
FTTest`FTAssert["the Taylor endpoint has its unaltered physical coefficient",b["Terms"]==={<|"Power"->-1-e,"LogPower"->0,"Coefficient"->1|>}];
c=FeynFacet`GaussEndpointSingularTerms[(1-z)^(-e)Hypergeometric2F1[2-e,2-e,2-2e,z],{z,1},e];
FTTest`FTAssert["stronger endpoint powers are exposed, never silently dropped",AssociationQ[c]&&c["MaxContactDerivativeOrder"]===1];
FTTest`FTAssert["the simple-pole distribution builder rejects stronger endpoint powers",FailureQ[FeynFacet`ExpandUnitIntervalDistribution[
 <|0->0|>,{b,c},<||>,{z,e},{0,0}]]];
FTTest`FTAssert["digamma endpoint coefficients have a justified regular bound",FeynFacet`DetermineMeromorphicLaurentLowerBound[HarmonicNumber[-2e],e]===0];
FTTest`FTAssert["polygamma pole order is included in epsilon planning",FeynFacet`DetermineMeromorphicLaurentLowerBound[PolyGamma[2,-1+e^2],e]===-6];
Print["GAUSS ENDPOINT SERIES TEST COMPLETE"];FTTest`FTReport[];
