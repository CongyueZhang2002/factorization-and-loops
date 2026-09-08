(* Finite Frobenius counterterms after local Fuchsian normalization.
   Generic-regulator mode selection is an input. The regulator expansion is
   performed only after that selection. These are local counterterms, not
   a replacement for the exact residual integrals in the boundary solution. *)
Clear[ConstructFrobeniusBoundaryExpansion];
ClearAll[frobeniusSparseZeroQ,frobeniusRationalRectangle,
 frobeniusPolynomialAdd,frobeniusPolynomialLeft];
frobeniusSparseZeroQ[m_] := If[Head[m]===SparseArray,
 Length[ArrayRules[m]]===1&&Last[Last[ArrayRules[m]]]===0,
 AllTrue[Flatten[m],#===0&]];
frobeniusPolynomialAdd[p_,q_,zero_] := Module[{n=Max[Length[p],Length[q]]},
 Table[If[k<=Length[p],p[[k]],zero]+If[k<=Length[q],q[[k]],zero],{k,n}]];
frobeniusPolynomialLeft[a_,p_] := (SparseArray[a.#]&/@p);
frobeniusRationalRectangle[value_,z_,e_,nm_,ne_] := Module[
 {num,den,nrules,drules,d0,answer,terms,cv,i,j},
 {num,den}=NumeratorDenominator[Cancel[Together[value]]];
 d0=den/.{z->0,e->0};
 If[d0===0||!FreeQ[d0,z|e],Return[Failure["NonanalyticJointLocalCoefficient",<|"Expression"->value|>]]];
 nrules=Association[CoefficientRules[num,{z,e}]];
 drules=Select[CoefficientRules[den,{z,e}],First[#]=!={0,0}&];
 answer=ConstantArray[0,{nm+1,ne+1}];
 Do[
  cv=Lookup[nrules,Key[{i,j}],0];
  Do[If[term[[1,1]]<=i&&term[[1,2]]<=j,
    cv-=Last[term] answer[[i-term[[1,1]]+1,j-term[[1,2]]+1]]],{term,drules}];
  answer[[i+1,j+1]]=cv/d0,{i,0,nm},{j,0,ne}];
 answer];
Options[ConstructFrobeniusBoundaryExpansion]={"Verbose"->False};
ConstructFrobeniusBoundaryExpansion[system_Association,seed_?MatrixQ,
 request_Association,OptionsPattern[]] := Catch@Module[
 {z,e,a,r,n,c,normalOrder,range,low,high,width,zero,coefficients,
  positions,rect,value,key,cache=<||>,seedLow,seedCoefficients,
  r0,power,nilpotency=0,polys=<||>,previous,source,poly,next,logOrder,
  linearSolve,rhs,degree,m,q,j,k,p,sourceDegree,records,timing,
  sparseCoefficients,fail,progress,columnUpper,clip,processed=0},
 fail[tag_,data_:<||>]:=Throw[Failure[tag,data]];
 progress[text_]:=If[TrueQ[OptionValue["Verbose"]],Print[text]];
 z=Lookup[system,"Variable",None];e=Lookup[system,"DimensionalRegulator",None];
 a=Lookup[system,"ConnectionMatrix",{}];n=Length[a];c=Dimensions[seed][[2]];
 normalOrder=Lookup[request,"MaximumNormalOrder",None];
 range=Lookup[request,"EpsilonOrderRange",None];
 If[!MatchQ[z,_Symbol]||!MatchQ[e,_Symbol]||Dimensions[a]=!={n,n}||
   Dimensions[seed][[1]]=!=n||!IntegerQ[normalOrder]||normalOrder<0||
   !MatchQ[range,{_Integer,_Integer}]||First[range]>Last[range],
   fail["FrobeniusCountertermSpecificationInvalid"]];
 {low,high}=range;width=high-low;zero=SparseArray[{},{n,c}];
 columnUpper=Lookup[request,"ColumnUpperOrders",ConstantArray[high,c]];
 If[!VectorQ[columnUpper,IntegerQ]||Length[columnUpper]=!=c||
   Max[columnUpper]>high||Min[columnUpper]<low,fail["ColumnEpsilonOrdersInvalid"]];
 clip[mat_,order_]:=SparseArray[mat.SparseArray[Band[{1,1}]->(Boole[#>=order]&/@columnUpper),{c,c}]];
 seedLow=Min[Flatten[Map[solutionValuation[#,e]&,seed,{2}]]];
 If[seedLow<low,fail["SeedLaurentOrdersOmitted",<|"SeedLowerOrder"->seedLow|>]];
 progress["Expanding the regular-singular connection in the normal variable and epsilon."];
 coefficients=Table[{}, {normalOrder+1},{width+1}];
 positions=Position[Normal[a],v_/;v=!=0,{2},Heads->False];
 Do[
  processed++;If[Mod[processed,500]===0,progress["Expanded "<>ToString[processed]<>" connection entries of "<>ToString[Length[positions]]<>"."]];
  value=Cancel[Together[z Extract[a,pos]]];
  rect=If[KeyExistsQ[cache,value],cache[value],
   p=frobeniusRationalRectangle[value,z,e,normalOrder,width];
   If[FailureQ[p],Throw[p]];AssociateTo[cache,value->p];p];
  Do[If[rect[[m+1,q+1]]=!=0,
    AppendTo[coefficients[[m+1,q+1]],pos->rect[[m+1,q+1]]]],
    {m,0,normalOrder},{q,0,width}],{pos,positions}];
 sparseCoefficients=Map[SparseArray[#,{n,n}]&,coefficients,{2}];
 Clear[cache];r0=sparseCoefficients[[1,1]];power=IdentityMatrix[n,SparseArray];
 While[nilpotency<=n&&!frobeniusSparseZeroQ[power],power=SparseArray[power.r0];nilpotency++];
 If[nilpotency>n,fail["UnregulatedResidueNotNilpotent"]];
 progress["The unregulated residue has nilpotency index "<>ToString[nilpotency]<>"."];
 seedCoefficients=Association@Table[q->SparseArray[
  Map[SeriesCoefficient[#,{e,0,q}]&,seed,{2}]].SparseArray[Band[{1,1}]->(Boole[#>=q]&/@columnUpper),{c,c}],{q,low,high}];
 Do[
  source={};
  Do[source=frobeniusPolynomialAdd[source,
    frobeniusPolynomialLeft[sparseCoefficients[[1,q+1]],polys[[Key[{0,k-q}]]]],zero],
    {q,1,k-low}];
  sourceDegree=Length[source]-1;
  poly={seedCoefficients[k]};logOrder=0;
  While[True,
   next=SparseArray[(r0.Last[poly]+If[logOrder<=sourceDegree,source[[logOrder+1]],zero])/(logOrder+1)];
   If[logOrder>=sourceDegree&&frobeniusSparseZeroQ[next],Break[]];
   AppendTo[poly,next];logOrder++;
   If[logOrder>(k-low+1)nilpotency+1,fail["LeadingLogarithmRecurrenceDidNotTerminate"]]];
  AssociateTo[polys,{0,k}->(clip[#,k]&/@poly)],{k,low,high}];
 Do[
  progress["Frobenius counterterm normal order "<>ToString[m]<>" of "<>ToString[normalOrder]<>"."];
  linearSolve=LinearSolve[m IdentityMatrix[n,SparseArray]-r0];
  Do[
   rhs={};
   Do[rhs=frobeniusPolynomialAdd[rhs,
     frobeniusPolynomialLeft[sparseCoefficients[[1,q+1]],polys[[Key[{m,k-q}]]]],zero],
     {q,1,k-low}];
   Do[rhs=frobeniusPolynomialAdd[rhs,
     frobeniusPolynomialLeft[sparseCoefficients[[j+1,q+1]],polys[[Key[{m-j,k-q}]]]],zero],
     {j,1,m},{q,0,k-low}];
   If[rhs==={},rhs={zero}];
   poly=ConstantArray[zero,Length[rhs]];next=zero;
   Do[next=SparseArray[linearSolve[rhs[[p]]-p next]];poly[[p]]=next,
     {p,Length[rhs],1,-1}];
   While[Length[poly]>1&&frobeniusSparseZeroQ[Last[poly]],poly=Most[poly]];
   AssociateTo[polys,{m,k}->(clip[#,k]&/@poly)],{k,low,high}],
   {m,1,normalOrder}];
 <|"DataType"->"FrobeniusBoundaryExpansion","SchemaVersion"->1,
  "Variable"->z,"DimensionalRegulator"->e,"Dimension"->n,"ColumnCount"->c,
  "MaximumNormalOrder"->normalOrder,"EpsilonOrderRange"->range,
  "SeedMatrix"->seed,"UnregulatedResidueNilpotencyIndex"->nilpotency,
  "Coefficients"->polys,"ColumnUpperOrders"->columnUpper,
  "ConnectionTaylorCoefficients"->sparseCoefficients,
  "CoefficientConvention"->"Key {normal power, epsilon power}; list element l+1 is the matrix multiplying Log[z]^l.",
  "Scope"->"Finite endpoint counterterm. Exact residual integration is required for a solution at finite kinematics."|>
];
