(* Finite Laurent coefficients with explicit coverage and forward tail checks. *)
BeginPackage["FeynFacet`"];
ExpandLaurentCoefficientVector::usage =
 "ExpandLaurentCoefficientVector[expressions,epsilon,ranges] stores explicit Laurent coefficients and proved lower bounds for a vector of exact expressions. Stored windows remain distinct from lower bounds.";
ExpandLaurentCoefficientMatrix::usage =
 "ExpandLaurentCoefficientMatrix[matrix,epsilon,columnUpperOrders] expands an exact meromorphic matrix with entry lower bounds, finite stored coverage, and exact-tail flags.";
MultiplyLaurentCoefficientMatrix::usage =
 "MultiplyLaurentCoefficientMatrix[matrixSeries,vectorSeries,targetRanges] convolves finite Laurent coefficients, rejects missing contributing orders, and supports the common omitted-coefficient audit.";
SelectLaurentCoefficientVector::usage="SelectLaurentCoefficientVector[vector,indices] selects and reindexes explicit finite components while retaining every Laurent lower bound, coverage window and tail flag.";
Begin["`Private`"];
laurentProductFail[tag_,data_:<||>]:=Throw[Failure[tag,data],"LaurentProduct"];
ExpandLaurentCoefficientVector[expressions_List,e_Symbol,ranges_List]:=Catch[Module[
 {n=Length[expressions],coefficients=<||>,bounds={},exact={},series,lower,polynomial,lo,hi,k},
 If[Length[ranges]=!=n||!AllTrue[ranges,MatchQ[#,{_Integer,_Integer}]&&First[#]<=Last[#]&],
  laurentProductFail["FiniteLaurentVectorRangesRequired"]];
 Do[
  {lo,hi}=ranges[[i]];series=regulatorSeries[expressions[[i]],e,hi];
  If[FailureQ[series],Throw[series,"LaurentProduct"]];lower=First[series];
  AppendTo[bounds,lower];polynomial=Last[series];
  AppendTo[exact,expressions[[i]]===0||IntegerQ[lower]&&
   PolynomialQ[Cancel[e^-lower expressions[[i]]],e]&&
   Exponent[Cancel[e^-lower expressions[[i]]],e]<=hi-lower];
  series=regulatorSeriesCoefficients[expressions[[i]],e,{lo,hi}];
  If[FailureQ[series],Throw[series,"LaurentProduct"]];
  KeyValueMap[AssociateTo[coefficients,{i,#1}->#2]&,series],
 {i,n}];
 <|"DataType"->"LaurentCoefficientVector","DimensionalRegulator"->e,"Dimension"->n,
  "Coefficients"->coefficients,"LaurentLowerBounds"->bounds,"StoredOrderRanges"->ranges,
  "KnownThroughOrders"->Last/@ranges,"ExactTails"->exact|>
],"LaurentProduct"];

ExpandLaurentCoefficientMatrix[input_?MatrixQ,e_Symbol,upper_List]:=Catch[Module[
 {a=Normal[input],rows,cols,lower,start,coefficients,cache=<||>,entry,exact,demands,series},
 {rows,cols}=Dimensions[a];
 If[Length[upper]=!=cols||!AllTrue[upper,IntegerQ],
  laurentProductFail["LaurentMatrixColumnOrdersRequired"]];
 lower=Map[Function[expression,With[{rational=Together[expression]},
  If[PolynomialQ[Numerator[rational],e]&&PolynomialQ[Denominator[rational],e],
   exactRationalLaurentValuation[rational,e],
   FeynFacet`DetermineMeromorphicLaurentLowerBound[expression,e]]]],a,{2}];
 If[!AllTrue[Flatten[lower],IntegerQ[#]||#===Infinity&],
  laurentProductFail["MeromorphicLaurentMatrixRequired"]];
 start=If[DeleteCases[Flatten[lower],Infinity]==={},0,Min[Flatten[lower]]];
 (* Expand each distinct matrix entry once through its largest column
    demand. Repeating Series for every single coefficient repeats the
    expensive Gamma/power expansion at all preceding orders. *)
 demands=Merge[Flatten[Table[a[[i,j]]->upper[[j]],{i,rows},{j,cols}],1],Max];
 KeyValueMap[Function[{expr,hi},
  series=If[hi<start,<||>,regulatorSeriesCoefficients[expr,e,{start,hi}]];
  If[FailureQ[series],Throw[series,"LaurentProduct"]];
  AssociateTo[cache,expr->series]],demands];
 entry[expr_,q_]:=cache[[Key[expr]]][q];
 coefficients=Association@Table[q->Table[If[q>upper[[j]],0,entry[a[[i,j]],q]],
  {i,rows},{j,cols}],{q,start,Max[upper]}];
 exact=Table[a[[i,j]]===0||IntegerQ[lower[[i,j]]]&&
  PolynomialQ[Cancel[e^-lower[[i,j]]a[[i,j]]],e]&&
  Exponent[Cancel[e^-lower[[i,j]]a[[i,j]]],e]<=upper[[j]]-lower[[i,j]],
  {i,rows},{j,cols}];
 <|"DataType"->"LaurentCoefficientMatrix","DimensionalRegulator"->e,
  "Dimensions"->{rows,cols},"CoefficientMatrices"->coefficients,
  "EntryLaurentLowerBounds"->lower,"ColumnUpperOrders"->upper,"ExactEntryTails"->exact|>
],"LaurentProduct"];

MultiplyLaurentCoefficientMatrix[matrix_Association,vector_Association,ranges_List]:=
 Catch[Module[
 {e,rows,cols,matrices,ml,mu,vl,vu,values,me,ve,output=<||>,lower,value,coefficient,order,q},
 {rows,cols}=Lookup[matrix,"Dimensions",{0,0}];e=Lookup[matrix,"DimensionalRegulator",None];
 {matrices,ml,mu}=Lookup[matrix,{"CoefficientMatrices","EntryLaurentLowerBounds","ColumnUpperOrders"}];
 {values,vl,vu}=Lookup[vector,{"Coefficients","LaurentLowerBounds","KnownThroughOrders"}];
 me=Lookup[matrix,"ExactEntryTails",ConstantArray[False,{rows,cols}]];
 ve=Lookup[vector,"ExactTails",ConstantArray[False,cols]];
 If[rows<1||cols<1||Lookup[vector,"DimensionalRegulator",None]=!=e||
   Length[vl]=!=cols||Length[ranges]=!=rows||!AssociationQ[values]||!AssociationQ[matrices]||
   Dimensions[ml]=!={rows,cols}||Length[mu]=!=cols||
   !AllTrue[ranges,MatchQ[#,{_Integer,_Integer}]&&First[#]<=Last[#]&],
  laurentProductFail["CompatibleFiniteLaurentCoefficientDataRequired"]];
 lower=Table[Min[Table[If[MemberQ[{ml[[i,j]],vl[[j]]},Infinity],Infinity,
   ml[[i,j]]+vl[[j]]],{j,cols}]],{i,rows}];
 Do[
  If[MemberQ[{ml[[i,j]],vl[[j]]},Infinity],Continue[]];
  epsilonAuditProduct[{epsilonAuditSpec[{"Matrix",i,j},ml[[i,j]],mu[[j]],TrueQ[me[[i,j]]]],
   epsilonAuditSpec[{"Vector",j},vl[[j]],vu[[j]],TrueQ[ve[[j]]]]},
   Last[ranges[[i]]],"LaurentMatrixProduct",{i,j}],
 {i,rows},{j,cols}];
 Do[
  value=0;
  Do[
   If[MemberQ[{ml[[i,j]],vl[[j]]},Infinity]||order<ml[[i,j]]+vl[[j]],Continue[]];
   Do[
    If[q>mu[[j]]&&!TrueQ[me[[i,j]]],
     laurentProductFail["LaurentMatrixOrdersInsufficient",<|"Row"->i,"Column"->j,"Order"->q|>]];
    coefficient=If[q>mu[[j]]&&TrueQ[me[[i,j]]],0,
     If[!KeyExistsQ[matrices,q],laurentProductFail["StoredLaurentMatrixOrderMissing",<|"Order"->q|>],
      matrices[q][[i,j]]]];
    If[coefficient===0,Continue[]];
    If[!KeyExistsQ[values,{j,order-q}],
     If[order-q>vu[[j]]&&TrueQ[ve[[j]]],Continue[]],
     value+=coefficient values[[Key[{j,order-q}]]];Continue[]];
    laurentProductFail["StoredLaurentVectorOrderMissing",<|"Component"->j,"Order"->order-q|>],
   {q,ml[[i,j]],order-vl[[j]]}],
  {j,cols}];
  AssociateTo[output,{i,order}->value],
 {i,rows},{order,First[ranges[[i]]],Last[ranges[[i]]]}];
 <|"DataType"->"LaurentCoefficientVector","DimensionalRegulator"->e,"Dimension"->rows,
  "Coefficients"->output,"LaurentLowerBounds"->lower,"StoredOrderRanges"->ranges,
  "KnownThroughOrders"->Last/@ranges,"ExactTails"->ConstantArray[False,rows],
  "OrderCoverageVerified"->True|>
],"LaurentProduct"];
SelectLaurentCoefficientVector[vector_Association,indices_List]:=Module[{n=Lookup[vector,"Dimension",0],cs},
 If[Lookup[vector,"DataType",None]=!="LaurentCoefficientVector"||indices==={}||
   !DuplicateFreeQ[indices]||!AllTrue[indices,IntegerQ[#]&&1<=#<=n&],
  Return[Failure["ExplicitLaurentVectorComponentIndicesRequired",<||>]]];
 cs=Association@Flatten@Table[With[{range=vector["StoredOrderRanges"][[indices[[i]]]]},
  Table[{i,k}->Lookup[vector["Coefficients"],Key[{indices[[i]],k}],0],{k,First[range],Last[range]}]],{i,Length[indices]}];
 Join[vector,Association@Table[key->vector[key][[indices]],{key,
   {"LaurentLowerBounds","StoredOrderRanges","KnownThroughOrders","ExactTails"}}],
  <|"Dimension"->Length[indices],"Coefficients"->cs|>,
  If[KeyExistsQ[vector,"CoefficientRowLabels"],<|"CoefficientRowLabels"->vector["CoefficientRowLabels"][[indices]]|>,<||>]]
];
(* Fail closed at public boundaries: malformed windows must not leave an
   unevaluated function that a driver could mistake for a completed result. *)
ExpandLaurentCoefficientVector[___]:=Failure["FiniteLaurentVectorInputRequired",<||>];
ExpandLaurentCoefficientMatrix[___]:=Failure["FiniteLaurentMatrixInputRequired",<||>];
MultiplyLaurentCoefficientMatrix[___]:=Failure["CompatibleFiniteLaurentCoefficientDataRequired",<||>];
End[];EndPackage[];
