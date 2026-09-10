(* Denominator independence is an affine linear-algebra question. Causal
   prescriptions are retained; they do not enter the rank calculation. *)
BeginPackage["FeynFacet`"];
CompleteAffineIntegralTopology::usage="CompleteAffineIntegralTopology[topology] appends independent quadratic auxiliary denominators until every loop scalar product is represented. It preserves every original propagator, including its causal sign, and rejects dependent original denominators. Auxiliary powers start at zero.";
Begin["`Private`"];
CompleteAffineIntegralTopology[top_FeynCalc`FCTopology]:=Catch[Module[
 {loops=top[[3]],external=top[[4]],kin=FeynCalc`FCI[top[[5]]],basis,vars,cores,matrix,
  candidates,props=top[[2]],row,rank,polynomials},
 basis=Join[Flatten[Table[FeynCalc`FCI[FeynCalc`SPD[loops[[i]],loops[[j]]]],
  {i,Length[loops]},{j,i,Length[loops]}]],
  Flatten[Table[FeynCalc`FCI[FeynCalc`SPD[l,p]],{l,loops},{p,external}]]];
 vars=Table[Unique["affineCoordinate"],{Length[basis]}];
 cores=FeynCalc`ExpandScalarProduct[propagatorDescriptor[#]["UnitCore"]]/.kin&/@props;
 polynomials=Expand[cores/.Thread[basis->vars]];
 If[!FreeQ[polynomials,_FeynCalc`Pair]||!AllTrue[polynomials,PolynomialQ[#,vars]&],
  cutFamilyFail["AffineLoopDenominatorsRequired"]];
 matrix=Table[Coefficient[poly,v],{poly,polynomials},{v,vars}];
 If[!AllTrue[MapThread[Expand[#1-#2.vars-(#1/.Thread[vars->0])]&, {polynomials,matrix}],#===0&],
  cutFamilyFail["AffineLoopDenominatorsRequired"]];
 rank=MatrixRank[matrix];
 If[rank=!=Length[props],cutFamilyFail["IndependentOriginalDenominatorsRequired"]];
 candidates=Join[loops,Total/@Subsets[loops,{2}],Flatten[Outer[Plus,loops,external]]];
 Do[
  If[rank===Length[basis],Break[]];
  row=FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[momentum]]]/.kin/.Thread[basis->vars];
  row=Coefficient[row,#]&/@vars;
  If[MatrixRank[Append[matrix,row]]>rank,
   AppendTo[props,FeynCalc`FCI[FeynCalc`SFAD[momentum]]];AppendTo[matrix,row];rank++],
 {momentum,candidates}];
 If[rank=!=Length[basis],cutFamilyFail["CompleteAffineLoopBasisNotFound"]];
 FeynCalc`FCTopology[top[[1]],props,loops,external,kin,top[[6]]]
],"CutFamily"];
End[];EndPackage[];
