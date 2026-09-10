(* Exact finite connection from singular-boundary amplitudes.
   The Frobenius polynomial is only a counterterm. Proper integrals of its
   complete DE residual restore all omitted normal-coordinate dependence. *)
Clear[DetermineBoundaryCountertermOrder];
ClearAll[boundaryLogarithmicPowerBound,boundaryCountertermDepthFromCoefficients];
boundaryLogarithmicPowerBound[0,z_]:=Infinity;
boundaryLogarithmicPowerBound[x_,z_] := Module[{base,power,value,order},
 Which[
  FreeQ[x,z],0,x===z,1,
  Head[x]===Times,Total[boundaryLogarithmicPowerBound[#,z]&/@List@@x],
  Head[x]===Plus,Min[boundaryLogarithmicPowerBound[#,z]&/@List@@x],
  Head[x]===Log,If[FreeQ[x[[1]],_Exp|_Sin|_Cos],0,Missing["NonmeromorphicLogArgument"]],
  Head[x]===Power&&NumberQ[x[[2]]],
   base=x[[1]];power=x[[2]];
   If[power>0,power boundaryLogarithmicPowerBound[base,z],
    If[PolynomialQ[base,z],power Exponent[base,z,Min],
     value=Quiet@Check[Limit[base,z->0],Indeterminate];
     If[FreeQ[value,Indeterminate|ComplexInfinity|DirectedInfinity[_]]&&
       TrueQ[Simplify[value!=0]],0,
       order=boundaryLocalOrder[base,z];
       If[IntegerQ[order],power order,Missing["DenominatorLocalOrderNotEstablished"]]]]],
  True,Missing["NormalPowerBoundNotEstablished"]]];
boundaryCountertermDepthFromCoefficients[b_,g_,z_] := Module[
 {n=Length[First[b]],gv,bv,poles,depth},
 gv=Table[Min[Flatten[boundaryLogarithmicPowerBound[#,z]&/@#[[i]]&/@g]],{i,n}];
 bv=Table[Min[boundaryLogarithmicPowerBound[#[[i,j]],z]&/@b],{i,n},{j,n}];
 If[!FreeQ[{gv,bv},_Missing],Return[Failure["JointEndpointPowerBoundsNotEstablished",<||>]]];
 poles=Map[If[#===Infinity,-Infinity,-#]&,bv,{2}];
 depth=Max[0,Ceiling[Max[-gv]],
  Ceiling[Max[Flatten[Table[If[poles[[i,j]]===-Infinity,-Infinity,poles[[i,j]]-1-gv[[j]]],{i,n},{j,n}]]]]];
 <|"DataType"->"FrobeniusCountertermOrder","MaximumNormalOrder"->depth,
  "GaugeRowNormalPowerLowerBounds"->gv,"ConnectionNormalPoleUpperBounds"->poles,
  "Criterion"->"N >= max(0, -g_i, p_ij-1-g_j), coefficientwise in epsilon.",
  "RemainderNormalPowerLowerBounds"->(depth+1+gv)|>
];
DetermineBoundaryCountertermOrder[b_?MatrixQ,g_?MatrixQ,{z_Symbol,e_Symbol},
 range:{_Integer,_Integer}] := Module[{bc,gc,result},
 bc=solutionLaurentCoefficients[b,e,Last[range],True];
 gc=solutionLaurentCoefficients[g,e,Last[range],True];
 result=boundaryCountertermDepthFromCoefficients[Values[bc],Values[gc],z];
 If[AssociationQ[result],Join[result,<|"EpsilonOrderRange"->range|>],result]
];

ClearAll[boundaryRationalTaylorRemainders];
boundaryRationalTaylorRemainders[mat_,coeffs_,depth_,z_] := Catch@Module[
 {n=Length[mat],result=Table[{}, {depth+1}],positions,value,cache=<||>,
  item,num,den,polynomial,remainder,known,remainders,p,coefficientList},
 positions=Position[Normal[mat],x_/;x=!=0,{2},Heads->False];
 Do[
  value=Extract[mat,pos];known=Lookup[cache,Key[value],None];
  If[known===None,
   {num,den}=NumeratorDenominator[Together[value]];
   If[!PolynomialQ[num,z]||!PolynomialQ[den,z],
    Throw[Failure["RationalNormalizedConnectionRequired",<||>]]];
   remainders=Table[
    polynomial=Expand[num-den Sum[z^j Extract[coeffs[[j+1]],pos],{j,0,p-1}]];
    remainder=Cancel[Together[PolynomialRemainder[polynomial,z^p,z]]];
    If[remainder=!=0,Throw[Failure["LocalConnectionTaylorCoefficientsInconsistent",<|"Position"->pos,"Power"->p,"Residual"->remainder|>]]];
    PolynomialQuotient[polynomial,z^p,z]/den,{p,1,depth+1}];
   AssociateTo[cache,value->remainders];known=remainders];
  Do[If[known[[p]]=!=0,AppendTo[result[[p]],pos->known[[p]]]],{p,1,depth+1}],
  {pos,positions}];
 SparseArray[#,{n,n}]&/@result
];

Clear[ConstructBoundaryConnection];
Options[ConstructBoundaryConnection]={"ContourDeformation"->1/4,"EndpointPower"->8,"Verbose"->False};
ConstructBoundaryConnection[data_Association,request_Association,
 OptionsPattern[]] := Catch@Module[
 {normal=data["NormalizedDifferentialSystem"],prepared=data["PreparedDifferentialSystem"],
  expansion=data["FrobeniusExpansion"],g=data["NormalizedToPreparedGauge"],
  originalGauge=data["NormalizedToOriginalGauge"],z,e,n,c,depth,low,high,upper,
  t=FeynFacetSolution`t,s=FeynFacetSolution`s,kappa=OptionValue["ContourDeformation"],
  path,pathDerivative,endpointPower=OptionValue["EndpointPower"],b,bc,gc,pc,oc,nc,taylor,zero,zeroSquare,kernels=<||>,integrals=<||>,algebra=<||>,
  kernelIndex=<||>,algebraIndex=<||>,internKernel,internAlgebra,shareK,shareA,
  bK,gK,remK=<||>,polynomialK=<||>,polynomialA=<||>,defectSource=<||>,errors=<||>,
  errorRows,current,integrand,u,index,expression,part,sum,rem,degree,q,m,k,j,i,
  finalCoefficients=<||>,counterterms,correction,value,clip,fail,progress,phase,
  normalConstantCoefficients,combined,poly,coefficient,known,columns,zeros,old,endpointOrders,remainderMatrices},
 fail[tag_,extra_:<||>]:=Throw[Failure[tag,extra]];
 progress[text_]:=If[TrueQ[OptionValue["Verbose"]],Print[text]];
 z=normal["Variable"];e=normal["DimensionalRegulator"];
 n=expansion["Dimension"];c=expansion["ColumnCount"];depth=expansion["MaximumNormalOrder"];
 {low,high}=expansion["EpsilonOrderRange"];upper=expansion["ColumnUpperOrders"];
 If[low<0,fail["RegularFrobeniusSeedRequired"]];
 zero=SparseArray[{},{n,c}];zeroSquare=SparseArray[{},{n,n}];
 If[!IntegerQ[endpointPower]||endpointPower<1,fail["PositiveEndpointPowerRequired"]];
 path=z(t^endpointPower+I kappa t^endpointPower(1-t^endpointPower));pathDerivative=D[path,t];
 b=First[prepared["ConnectionMatrices"]];
 progress["Expanding the exact gauges and connections in epsilon."];
 bc=solutionLaurentCoefficients[b,e,high,True];
 gc=solutionLaurentCoefficients[g,e,high,True];
 pc=solutionLaurentCoefficients[prepared["BasisTransformationMatrix"],e,high,True];
 oc=solutionLaurentCoefficients[originalGauge,e,high,True];
 nc=solutionLaurentCoefficients[z normal["ConnectionMatrix"],e,high,True];
 If[AnyTrue[{bc,gc,pc,oc,nc},AnyTrue[Keys[#],#<0&]&],
  fail["FurtherLaurentPaddingRequired"]];
 If[!AllTrue[Flatten[Table[Lookup[bc,0,Normal[zeroSquare]][[i,j]],{i,n},{j,i,n}]],solutionZero],
  fail["StrictlyTriangularUnregulatedConnectionRequired"]];
 endpointOrders=boundaryCountertermDepthFromCoefficients[Values[bc],Values[gc],z];
 If[FailureQ[endpointOrders],Throw[endpointOrders]];
 If[depth<endpointOrders["MaximumNormalOrder"],
  fail["FrobeniusCountertermTooShort",<|"Required"->endpointOrders["MaximumNormalOrder"],"Supplied"->depth|>]];
 taylor=expansion["ConnectionTaylorCoefficients"];
 coefficient[assoc_,q_]:=Lookup[assoc,q,zeroSquare];
 clip[mat_,q_]:=SparseArray[mat.SparseArray[Band[{1,1}]->(Boole[#>=q]&/@upper),{c,c}]];
 internKernel[x_] := Module[{body,hit,ref},
  If[AtomQ[x]||NumberQ[x]||MatchQ[x,_FeynFacetSolution`K],Return[x]];
  If[LeafCount[x]<=8,Return[x]];
  hit=Lookup[kernelIndex,Key[x],None];If[hit=!=None,Return[hit]];
  body=Map[internKernel,x];index=Length[kernels]+1;
  AssociateTo[kernels,index-><|"Index"->index,"Parameter"->t,"Expression"->body,"Kind"->"ScalarExpression"|>];
  ref=FeynFacetSolution`K[index,t];AssociateTo[kernelIndex,x->ref];ref];
 internAlgebra[x_] := Module[{body,hit,ref},
  If[AtomQ[x]||NumberQ[x]||MatchQ[x,_FeynFacetSolution`a|_FeynFacetSolution`F],Return[x]];
  If[LeafCount[x]<=8,Return[x]];
  hit=Lookup[algebraIndex,Key[x],None];If[hit=!=None,Return[hit]];
  body=Map[internAlgebra,x];AssociateTo[algebra,(Length[algebra]+1)->body];
  ref=FeynFacetSolution`a[Length[algebra]];AssociateTo[algebraIndex,x->ref];ref];
 shareK[mat_]:=SparseArray[Map[internKernel,Normal[mat],{2}]];
 shareA[mat_]:=SparseArray[Map[internAlgebra,Normal[mat],{2}]];
 progress["Storing scalar kernels with explicit endpoint subtractions."];
 bK=Association@KeyValueMap[Function[{q,mat},
   q->shareK[pathDerivative(mat/.z->path)]],bc];
 progress["Prepared-connection kernels: "<>ToString[Length[kernels]]<>" scalar definitions."];
 (* The product x^N G is formed before assigning scalar names. Its
    endpoint power is retained rather than split into singular pieces. *)
 gK=Association@KeyValueMap[Function[{q,mat},
   q->shareK[pathDerivative(Map[Cancel,z^depth mat,{2}]/.z->path)]],gc];
 progress["Gauge kernels: "<>ToString[Length[kernels]]<>" scalar definitions."];
 Do[
  remainderMatrices=boundaryRationalTaylorRemainders[coefficient[nc,q],
   taylor[[All,q+1]],depth,z];
  If[FailureQ[remainderMatrices],Throw[remainderMatrices]];
  Do[AssociateTo[remK,{m,q}->shareK[Normal[remainderMatrices[[depth-m+1]]]/.z->path]],{m,0,depth}];
  progress["Subtraction kernels through epsilon order "<>ToString[q]<>
    ": "<>ToString[Length[kernels]]<>" scalar definitions."],
  {q,0,high}];
 Do[
  poly=expansion["Coefficients"][[Key[{m,k}]]];
  expression=Sum[Log[z]^j poly[[j+1]],{j,0,Length[poly]-1}];
  AssociateTo[polynomialK,{m,k}->shareK[Normal[expression]/.z->path]];
  AssociateTo[polynomialA,{m,k}->shareA[z^m expression]],
  {m,0,depth},{k,0,high}];
 progress["Integrating the finite DE residual coefficient by coefficient."];
 Do[
  combined=zero;
  Do[
   part=zero;
   Do[part=part+remK[[Key[{m,q}]]].polynomialK[[Key[{m,k-q}]]],{q,0,k}];
   combined=combined+shareK[clip[part,k]],
   {m,0,depth}];
  AssociateTo[defectSource,k->shareK[clip[combined,k]]];
  sum=zero;
  Do[sum=sum+coefficient[gK,q].defectSource[k-q],{q,0,k}];
  sum=shareK[clip[sum,k]];
  current=ConstantArray[0,{n,c}];
  Do[
   If[k>upper[[j]],Continue[]];
   integrand=sum[[i,j]]+
    Total@Table[
      coefficient[bK,q][[i]].If[q===0,current[[All,j]],errors[k-q][[All,j]]],
      {q,0,k}];
   If[integrand===0,Continue[]];
   index=Length[integrals]+1;u=Symbol["FeynFacetSolution`t"<>ToString[index]];
   AssociateTo[integrals,index-><|"Index"->index,"IntegrationVariable"->u,
    "UpperLimitVariable"->s,"LowerLimit"->0,"Integrand"->(integrand/.t->u)|>];
   current[[i,j]]=FeynFacetSolution`F[index,t],
   {i,n},{j,c}];
  AssociateTo[errors,k->SparseArray[current]];
  progress["Boundary connection epsilon order "<>ToString[k]<>" of "<>ToString[high]<>
    ": "<>ToString[Length[integrals]]<>" proper integrals."],
  {k,0,high}];
 progress["Completing the original-master connection coefficients."];
 Do[
  counterterms=zero;correction=zero;
  Do[
   part=Sum[polynomialA[[Key[{m,k-q}]]],{m,0,depth}];
   counterterms=counterterms+shareA[coefficient[oc,q].part];
   correction=correction+shareA[coefficient[pc,q].(Normal[errors[k-q]]/.FeynFacetSolution`F[j_,t]:>FeynFacetSolution`F[j,1])],
   {q,0,k}];
  value=Normal[shareA[clip[counterterms+correction,k]]];
  AssociateTo[finalCoefficients,k->Thread[Range[n]->value]],
  {k,0,high}];
 <|"DataType"->"BoundaryConnection","SchemaVersion"->1,
  "SolutionRepresentation"->"FiniteNestedIntegrals",
  "KinematicVariables"->{z},"DimensionalRegulator"->e,"Dimension"->n,
  "BoundaryDimension"->c,"RequestedRows"->Range[n],"RequestedEpsilonOrders"->Range[0,high],
  "ColumnUpperOrders"->upper,"InitialConstants"-><|"Count"->c,"KinematicsIndependent"->True,
   "Definition"->"Coefficients of the explicitly selected singular-boundary solution columns."|>,
  "Path"-><|"Parameter"->t,"Coordinates"->{path},"ParameterInterval"->{0,1}|>,
  "ContourDeformation"->kappa,"EndpointPower"->endpointPower,"BranchPrescription"->Lookup[request,"BranchPrescription",
    "Principal branches continued along the explicitly stored path."],
  "KernelDefinitions"->Values[kernels],"IntegralDefinitions"->Values[integrals],
  "AlgebraicDefinitions"->Values[algebra],"Coefficients"->finalCoefficients,
  "CountertermNormalOrder"->depth,"EndpointOrderDetermination"->endpointOrders,"EndpointPrescription"->"Proper integrals of the complete DE residual; every error coefficient vanishes at the endpoint.",
  "FiniteNormalCoordinateSolution"->True,
  "BoundaryFeynmanContinuationIndependentlyChecked"->False|>
];
