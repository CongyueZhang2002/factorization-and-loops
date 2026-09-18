(* Standalone worker: vendor System definitions are isolated in this kernel. *)
$HistoryLength=0;$MaxExtraPrecision=50;$RecursionLimit=4096;$PrePrint=.;
args=Rest[$ScriptCommandLine];If[Length[args]=!=4,Exit[2]];
Get[DirectoryName[ExpandFileName[$InputFileName],2]<>"/Core/RecordFormat.wl"];
input=FeynFacetRecords`ReadRecord[args[[1]]];out=args[[2]];$HPLPath=args[[3]];$HypExpPath=args[[4]];
If[!AssociationQ[input],Exit[2]];
$Path=Join[{$HPLPath,$HypExpPath},$Path];
Block[{Print},Get[$HPLPath<>"/HPL.m"];Get[$HypExpPath<>"/HypExp.m"]];
e=input["DimensionalRegulator"];upper=input["UpperOrder"];expression=input["Expression"];
raw=TimeConstrained[
 functions=DeleteDuplicates[Cases[expression,f:(_HypergeometricPFQ|_Hypergeometric2F1)/;!FreeQ[f,e],{0,Infinity}]];
 symbols=Table[Unique["hypergeometricCoefficient"],{Length[functions]}];
 formal=expression/.Thread[functions->symbols];
 If[!PolynomialQ[formal,symbols],Print["FAILED POLYNOMIAL HYPERGEOMETRIC COMPOSITION"];Exit[1]];
 leading=HypExp`HypExp[#,e,0]&/@functions;
 lowerBounds=If[#===0,1,Exponent[#,e,Min]]&/@leading;
 If[!AllTrue[lowerBounds,IntegerQ],Print["FAILED HYPERGEOMETRIC LOWER ORDERS"];Exit[1]];
 weighted=formal/.Thread[symbols->MapThread[#1 e^#2&,{symbols,lowerBounds}]];
 weightedSeries=Series[weighted,{e,0,0}];
 totalLower=If[Head[weightedSeries]===SeriesData,weightedSeries[[4]],Exponent[weightedSeries,e,Min]];
 If[!IntegerQ[totalLower],Print["FAILED COMPOSED HYPERGEOMETRIC LOWER ORDER"];Exit[1]];
 functionUpper=Max[0,upper-totalLower+#]&/@lowerBounds;
 expanded=MapThread[HypExp`HypExp[#1,e,#2]&,{functions,functionUpper}];
 Series[expression/.Thread[functions->expanded],{e,0,upper}],180,$Failed];
If[raw===$Failed||!FreeQ[raw,$Aborted|_Series|Indeterminate|_DirectedInfinity],Print["FAILED HYPERGEOMETRIC SERIES"];Exit[1]];
lower=If[Head[raw]===SeriesData,raw[[4]],Exponent[raw,e,Min]];
polynomial=Normal[raw];
polynomial=polynomial/.{
 HPL`HPL[word_List,arg_]:>With[{letters=HPL`HPLMtoA[word]},
  (-1)^Count[letters,1]FeynFacetSolution`G[letters,arg]],
 HPL`MZV[word:{__Integer}]/;First[word]>1&&AllTrue[word,#>0&]:>
  (-1)^Length[word]FeynFacetSolution`G[Flatten[(Join[ConstantArray[0,#-1],{1}]&/@word)],1]};
If[Cases[polynomial,_Derivative,{0,Infinity},Heads->True]=!={}||
 !FreeQ[polynomial,_HypergeometricPFQ|_Hypergeometric2F1|_HPL`HPL|_HPL`MZV|_Integrate|
   _Inactive|_Series|_SeriesData|Indeterminate|_DirectedInfinity|HypExp`$HypExpFailed],
 Print["FAILED EXPLICIT HYPERGEOMETRIC COEFFICIENTS"];Exit[1]];
result=<|"Status"->"ExplicitHypergeometricSeries","DimensionalRegulator"->e,
 "LaurentLowerBound"->lower,"KnownThroughOrder"->upper,"Polynomial"->polynomial,
 "HypergeometricFunctionUpperOrders"->functionUpper,
 "Method"->"HypExp2.0 nested sums and critical unit-argument continuation in an isolated Wolfram kernel."|>;
FeynFacetRecords`WriteRecord[result,out];
Print["COMPLETED HYPERGEOMETRIC SERIES"];
