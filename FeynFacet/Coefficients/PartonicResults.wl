(* One persisted result format for every perturbative order and partonic channel. *)
BeginPackage["FeynFacet`"];
CreatePartonicResult::usage="CreatePartonicResult[epsilonCoefficients,metadata] creates the common delta/plus/regular result with explicit contiguous epsilon coverage.";
ReadPartonicResult::usage="ReadPartonicResult[file,requirements] reads the common result and checks identity, normalization and requested epsilon coverage.";
RequirePartonicEpsilonRange::usage="RequirePartonicEpsilonRange[result,{low,high}] rejects absent coefficients; a truncated series is never treated as an exact polynomial.";
CombinePartonicResults::usage="CombinePartonicResults[contributions,metadata] adds results in the same convention and records their contribution names.";
CreatePartonicResultFromEndpointExpansion::usage="CreatePartonicResultFromEndpointExpansion[expansion,metadata] stores explicit normal-crossing endpoint coefficients in the common recursive delta/plus/regular format. DistributionBasis[Axes] declares NormalVariable, Variable, Endpoint, Interval and Distance for each axis, with a unit absolute Jacobian.";
PartonicResultInteriorCoefficients::usage="PartonicResultInteriorCoefficients[result] restricts the common tensor-product delta/plus/regular Laurent result to the open physical domain: deltas vanish and plus distributions equal their ordinary densities. It retains all recorded epsilon orders and does not define an endpoint continuation.";
PartonicScalarCoefficientRules::usage="PartonicScalarCoefficientRules[result] flattens each epsilon coefficient into scalar rules indexed by epsilon order, one Delta/Plus/Regular label per axis and the structure-function index.";
Begin["`Private`"];
partonicResultFail[tag_,data_:<||>]:=Throw[Failure[tag,data],"PartonicResults"];
partonicDistribution[delta_,plus_,regular_]:=<|"DeltaCoefficient"->delta,"PlusCoefficients"->plus,"RegularCoefficient"->regular|>;
partonicCollect[expr_]:=Module[{value,words,atoms},
 value=If[FreeQ[expr,_Sin|_Cos],expr,TrigExpand[expr]];
 (* Keep GPLs outside the coefficient field, then separate scalar
    transcendental functions before rational factorization. Otherwise final
    result storage can repeat the integrator's former expression growth. *)
 words=DeleteDuplicates[Cases[value,_FeynFacetSolution`G,{0,Infinity}]];
 atoms=Join[words,DeleteDuplicates[Cases[value,
   _Log|_PolyLog|_PolyGamma|_Zeta|System`EulerGamma,{0,Infinity}]]];
 If[atoms==={},Factor[value],Collect[value,atoms,Factor]]];
partonicIntervalRowQ[row_]:=AssociationQ[row]&&KeyExistsQ[row,"DeltaCoefficients"];
partonicIntervalZero[]:=<|"DeltaCoefficients"-><|0->0,1->0|>,"PlusCoefficients"-><|0-><||>,1-><||>|>,"RegularCoefficient"->0|>;
partonicMap[f_,row_Association]/;partonicIntervalRowQ[row]:=<|
 "DeltaCoefficients"->Map[f,row["DeltaCoefficients"]],
 "PlusCoefficients"->Map[Map[f,#]&,row["PlusCoefficients"]],"RegularCoefficient"->f[row["RegularCoefficient"]]|>;
partonicMap[f_,row_Association]:=partonicDistribution[
 partonicMap[f,row["DeltaCoefficient"]],partonicMap[f,#]&/@row["PlusCoefficients"],
 partonicMap[f,row["RegularCoefficient"]]];
partonicMap[f_,value_]:=f[value];
(* A tensor product repeats the same delta/plus/regular fields for each
   successive axis. Coefficients at the final axis are scalar expressions. *)
partonicPhysicalDistributionBasis[basis_Association]:=If[KeyExistsQ[basis,"Axes"],
 Join[basis,<|"Axes"->(KeyDrop[#,"NormalVariable"]&/@basis["Axes"])|>],KeyDrop[basis,"NormalVariable"]];
partonicDistributionDepth[basis_Association]:=If[KeyExistsQ[basis,"Axes"],Length[basis["Axes"]],1];
partonicDistributionZero[1]:=partonicDistribution[0,<||>,0];
partonicDistributionZero[n_Integer?Positive]:=With[{zero=partonicDistributionZero[n-1]},partonicDistribution[zero,<||>,zero]];
partonicDistributionValidQ[row_,1]/;partonicIntervalRowQ[row]:=
 ContainsAll[Keys[row],{"DeltaCoefficients","PlusCoefficients","RegularCoefficient"}]&&
 AssociationQ[row["DeltaCoefficients"]]&&Sort[Keys[row["DeltaCoefficients"]]]==={0,1}&&
 AssociationQ[row["PlusCoefficients"]]&&Sort[Keys[row["PlusCoefficients"]]]==={0,1}&&
 AllTrue[Values[row["PlusCoefficients"]],AssociationQ[#]&&AllTrue[Keys[#],IntegerQ[#]&&#>=0&]&]&&
 FreeQ[Join[Values[row["DeltaCoefficients"]],Flatten[Values/@Values[row["PlusCoefficients"]]],{row["RegularCoefficient"]}],_Association];
partonicDistributionSum[rows_List,1]/;rows=!={}&&AllTrue[rows,partonicIntervalRowQ]:=<|
 "DeltaCoefficients"->Association@Table[p->Total[#["DeltaCoefficients"][p]&/@rows],{p,{0,1}}],
 "PlusCoefficients"->Association@Table[p->Merge[(#["PlusCoefficients"][p]&/@rows),Total],{p,{0,1}}],
 "RegularCoefficient"->Total[Lookup[rows,"RegularCoefficient"]]|>;
partonicDistributionValidQ[row_,n_Integer?Positive]:=Module[{values},
 If[!AssociationQ[row]||!ContainsAll[Keys[row],{"DeltaCoefficient","PlusCoefficients","RegularCoefficient"}]||
  !AssociationQ[row["PlusCoefficients"]]||
  !AllTrue[Keys[row["PlusCoefficients"]],IntegerQ[#]&&#>=0&],Return[False]];
 values=Join[{row["DeltaCoefficient"],row["RegularCoefficient"]},Values[row["PlusCoefficients"]]];
 If[n===1,AllTrue[values,!AssociationQ[#]&],AllTrue[values,partonicDistributionValidQ[#,n-1]&]]
];
partonicDistributionValidQ[_,_]:=False;
partonicDistributionSum[{},n_Integer?Positive]:=partonicDistributionZero[n];
partonicDistributionSum[rows_List,n_Integer?Positive]:=Module[{sum,keys,zero},
 sum[values_]:=If[n===1,Total[values],partonicDistributionSum[values,n-1]];
 keys=Union[Flatten[Keys/@Lookup[rows,"PlusCoefficients"]]];
 zero=If[n===1,0,partonicDistributionZero[n-1]];
 partonicDistribution[sum[Lookup[rows,"DeltaCoefficient"]],
  Association@Table[k->sum[Lookup[#["PlusCoefficients"],k,zero]&/@rows],{k,keys}],
  sum[Lookup[rows,"RegularCoefficient"]]]
];
(* Scalar zero represents a zero in every structure function; nonzero
   vectors must have exactly the declared length, at every endpoint leaf. *)
partonicDistributionComponentsQ[row_Association,1,n_Integer?Positive]/;partonicIntervalRowQ[row]:=
 AllTrue[Join[Values[row["DeltaCoefficients"]],Flatten[Values/@Values[row["PlusCoefficients"]]],{row["RegularCoefficient"]}],
  partonicDistributionComponentsQ[#,0,n]&];
partonicDistributionComponentsQ[row_Association,depth_Integer?Positive,n_Integer?Positive]:=
  AllTrue[Join[{row["DeltaCoefficient"],row["RegularCoefficient"]},Values[row["PlusCoefficients"]]],
    partonicDistributionComponentsQ[#,depth-1,n]&];
partonicDistributionComponentsQ[value_,0,n_]:=If[ListQ[value],
  Length[value]===n&&AllTrue[value,!ListQ[#]&&!AssociationQ[#]&],
  !AssociationQ[value]&&(n===1||value===0)];
partonicDistributionComponentsQ[___]:=False;
partonicZeroTreeQ[value_Association]:=AllTrue[Values[value],partonicZeroTreeQ];
partonicZeroTreeQ[value_List]:=AllTrue[value,partonicZeroTreeQ];
partonicZeroTreeQ[value_]:=TrueQ[value===0];

partonicResultValidQ[result_]:=Module[{range,e,cs,basis,depth,components},
 If[!AssociationQ[result]||Lookup[result,"Format",None]=!="FeynFacet-PartonicResult"||
   !ContainsAll[Keys[result],{"EpsilonRange","DimensionalRegulator","Coefficients","Scale","Variables","DensityConvention","DistributionBasis","DimensionalPrefactor","LaurentLowerBound","Order","Contribution"}],Return[False]];
 range=result["EpsilonRange"];e=result["DimensionalRegulator"];cs=result["Coefficients"];
 basis=result["DistributionBasis"];If[!AssociationQ[basis],Return[False]];
 If[KeyExistsQ[basis,"Axes"]&&(!MatchQ[basis["Axes"],{_Association..}]||
  !AllTrue[basis["Axes"],ContainsAll[Keys[#],{"Variable","Endpoint","Interval","Distance"}]&]||
  !DuplicateFreeQ[Lookup[basis["Axes"],"Variable"]]),Return[False]];
 depth=partonicDistributionDepth[basis];
 If[Lookup[basis,"Representation",None]==="UnitInterval",
  If[KeyExistsQ[basis,"Axes"]||Lookup[basis,"Endpoints",{}]=!={0,1}||Lookup[basis,"Interval",None]=!={0,1}||
    !MatchQ[Lookup[basis,"Variable",None],_Symbol]||!AllTrue[Values[cs],partonicIntervalRowQ],Return[False]],
  If[AnyTrue[Values[cs],partonicIntervalRowQ],Return[False]]];
  components=Lookup[result,"StructureFunctions",{"Scalar"}];
  If[!MatchQ[e,_Symbol]||!MatchQ[components,{__}]||!DuplicateFreeQ[components],Return[False]];
  If[!AssociationQ[cs]||!AllTrue[Values[cs],partonicDistributionValidQ[#,depth]&]||
    !AllTrue[Values[cs],partonicDistributionComponentsQ[#,depth,Length[components]]&],Return[False]];
 If[KeyExistsQ[result,"Polarization"]&&!MatchQ[result["Polarization"],_Association],Return[False]];
 TrueQ[MatchQ[range,{_Integer,_Integer}]&&First[range]<=Last[range]&&AssociationQ[cs]&&
  Sort[Keys[cs]]===(Range@@range)&&IntegerQ[result["LaurentLowerBound"]]&&result["LaurentLowerBound"]<=First[range]&&AllTrue[Values[cs],partonicDistributionValidQ[#,depth]&]&&
  FreeQ[cs,(symbol_Symbol/;SymbolName[symbol]===SymbolName[e])|_FeynFacet`EndpointDeltaDerivative|_FeynFacet`EndpointPlusDistribution|_Failure|_Missing|_SeriesData|_Series|_SeriesCoefficient|Indeterminate|_DirectedInfinity|$Failed|$Aborted]]
];
CreatePartonicResult[coefficients_Association,metadata_Association]:=Catch[Module[{record},
 If[Length[coefficients]===0,partonicResultFail["ExplicitEpsilonCoefficientsRequired"]];
 record=Join[KeyDrop[metadata,{"Coefficients","EpsilonRange","Format","FormatVersion"}],<|
  "Format"->"FeynFacet-PartonicResult","FormatVersion"->If[AllTrue[Values[coefficients],partonicIntervalRowQ],2,1],
  "EpsilonRange"->{Min[Keys[coefficients]],Max[Keys[coefficients]]},
  "LaurentLowerBound"->Lookup[metadata,"LaurentLowerBound",Min[Keys[coefficients]]],
  "DimensionalPrefactor"->Lookup[metadata,"DimensionalPrefactor",1],
  "Coefficients"->coefficients,"DensityConvention"->Lookup[metadata,"DensityConvention","E_c d sigma/d^(D-1)p_c"],
  "DistributionBasis"->Lookup[metadata,"DistributionBasis",<|"Variable"->Last[metadata["Variables"]],"Endpoint"->1,"Interval"->{0,1},"Distance"->1-Last[metadata["Variables"]]|>],
  "PlusConvention"->"At each axis, PlusCoefficients[k] multiplies [Log[Distance]^k/Distance]_+ on Interval, with subtraction at Endpoint. For DistributionBasis[Axes], delta/plus/regular values repeat recursively in the listed axis order."|>];
 record["DistributionBasis"]=partonicPhysicalDistributionBasis[record["DistributionBasis"]];
 If[record["FormatVersion"]===2,record["PlusConvention"]="One measured variable on [0,1]. DeltaCoefficients[p] multiplies the unit-mass delta at p. PlusCoefficients[p][k] multiplies [Log[distance]^k/distance]_+ subtracting f(p) over the full interval; distance is z or 1-z. The two endpoints are not tensor axes."];
 If[!partonicResultValidQ[record],partonicResultFail["PartonicResultIncompleteOrInvalid"]];
 record],"PartonicResults"];
RequirePartonicEpsilonRange[result_Association,range:{_Integer,_Integer}]:=If[
 partonicResultValidQ[result]&&First[range]<=Last[range]&&First[result["EpsilonRange"]]<=First[range]&&Last[result["EpsilonRange"]]>=Last[range],
 True,Failure["InsufficientResultEpsilonOrders",<|"Requested"->range,"Available"->Lookup[result,"EpsilonRange",Missing[]]|>]];
partonicConventionValue[value_Association]:=Association@KeyValueMap[#1->partonicConventionValue[#2]&,
 KeySortBy[value,ToString[#,InputForm]&]];
partonicConventionValue[value_List]:=partonicConventionValue/@value;
partonicConventionValue[value_]:=value;
ReadPartonicResult[file_String,requirements_Association:<||>]:=Catch[Module[{result},
 If[!FileExistsQ[file],partonicResultFail["PartonicResultFileMissing",<|"File"->file|>]];
 result=If[ToLowerCase[FileExtension[file]]==="wxf",Import[file,"WXF"],FamilyArtifactRead[file]];
 partonicReadResultRecord[result,requirements,file]],"PartonicResults"];
ReadPartonicResult[result_Association,requirements_Association:<||>]:=
 Catch[partonicReadResultRecord[result,requirements,"InMemory"],"PartonicResults"];
partonicReadResultRecord[result_,requirements_Association,file_]:=Module[{range},
 If[!partonicResultValidQ[result],partonicResultFail["CommonPartonicResultRequired",<|"File"->file|>]];
 KeyValueMap[Function[{key,value},If[key=!="EpsilonRange"&&
   If[key==="DistributionBasis"&&AssociationQ[value],
    partonicPhysicalDistributionBasis[result[key]]=!=partonicPhysicalDistributionBasis[value],
    partonicConventionValue[Lookup[result,key,Missing[]]]=!=partonicConventionValue[value]],
   partonicResultFail["PartonicResultIdentityMismatch",<|"File"->file,"Field"->key,"Expected"->value,"Actual"->Lookup[result,key,Missing[]]|>]]],requirements];
 If[KeyExistsQ[requirements,"EpsilonRange"],range=RequirePartonicEpsilonRange[result,requirements["EpsilonRange"]];
   If[FailureQ[range],Throw[range,"PartonicResults"]]];result];
partonicMergeAnalyticMetadata[base_Association,extra_Association]:=Module[{value=Join[base,extra]},
 Do[If[KeyExistsQ[base,key]||KeyExistsQ[extra,key],
  AssociateTo[value,key->(And@@DeleteDuplicates[Join@@(If[Head[#]===And,List@@#,{#}]&/@
   {Lookup[base,key,True],Lookup[extra,key,True]})])]],
 {key,{"Assumptions","Domain"}}];
 Do[
  If[KeyExistsQ[base,key]&&KeyExistsQ[extra,key]&&
    partonicConventionValue[base[key]]=!=partonicConventionValue[extra[key]],
   Return[Failure["AnalyticConventionTransformationRequired",<|"Field"->key|>],Module]],
 {key,{"RealLetterPrescription","GPLContinuation"}}];
 value
];
CombinePartonicResults[contributions_Association,metadata_Association]:=Catch[Module[{all,range,cs,rows,identityKeys,depth,analytic=<||>,merged},
 all=Values[contributions];If[all==={}||!AllTrue[all,partonicResultValidQ],partonicResultFail["CommonPartonicResultsRequired"]];
 Do[
  merged=partonicMergeAnalyticMetadata[analytic,KeyTake[entry,{"Assumptions","Domain","RealLetterPrescription","GPLContinuation"}]];
  If[FailureQ[merged],Throw[merged,"PartonicResults"]];analytic=merged,
 {entry,all}];
 merged=partonicMergeAnalyticMetadata[analytic,metadata];
 If[FailureQ[merged],Throw[merged,"PartonicResults"]];
 all=Map[Join[#,<|"DistributionBasis"->partonicPhysicalDistributionBasis[#["DistributionBasis"]]|>]&,all];
 identityKeys=Select[{"Order","Project","Channel","PhysicalChannel","Polarization","Coupling","CouplingPower","CouplingNormalization","StructureFunctions"},
  Function[key,AnyTrue[all,KeyExistsQ[#,key]&]]];
 If[!AllTrue[all,partonicConventionValue[KeyTake[#,identityKeys]]===partonicConventionValue[KeyTake[First[all],identityKeys]]&],
  partonicResultFail["PartonicResultIdentityMismatch"]];
 If[!AllTrue[all,KeyTake[#,{"Scale","Variables","DimensionalRegulator","DensityConvention","DistributionBasis","DimensionalPrefactor","CurrentNormalization"}]===
  KeyTake[First[all],{"Scale","Variables","DimensionalRegulator","DensityConvention","DistributionBasis","DimensionalPrefactor","CurrentNormalization"}]&],partonicResultFail["PartonicResultConventionMismatch"]];
 If[!AllTrue[all,First[#["EpsilonRange"]]===#["LaurentLowerBound"]&],partonicResultFail["UncomputedLowerEpsilonCoefficients"]];
 range={Min[First[#["EpsilonRange"]]& /@ all],Min[Last[#["EpsilonRange"]]& /@ all]};
 depth=partonicDistributionDepth[First[all]["DistributionBasis"]];
 cs=Association@Table[
  rows=Lookup[#["Coefficients"],j,If[Lookup[First[all]["DistributionBasis"],"Representation",None]==="UnitInterval",partonicIntervalZero[],partonicDistributionZero[depth]]]& /@ all;
  j->partonicDistributionSum[rows,depth],{j,First[range],Last[range]}];
 CreatePartonicResult[cs,Join[KeyTake[First[all],Union[identityKeys,{"Scale","Variables","DimensionalRegulator","Order","DensityConvention","DistributionBasis","DimensionalPrefactor","CurrentNormalization"}]],merged,
  <|"IncludedContributions"->Lookup[all,"Contribution"]|>]]],"PartonicResults"];

partonicEndpointRow[expression_,{}]:=expression;
partonicEndpointRow[expression_,axes_List]:=Module[
 {axis=First[axes],rest=Rest[axes],x,upper,objects,delta,pluses,terms,coefficients,coefficient,n},
 x=axis["NormalVariable"];upper=Last[axis["Interval"]];
 objects=DeleteDuplicates[Cases[expression,
  obj:(_FeynFacet`EndpointDeltaDerivative|_FeynFacet`EndpointPlusDistribution)/;First[obj]===x:>obj,{0,Infinity}]];
 delta=FeynFacet`EndpointDeltaDerivative[x,0,upper];n=Length[objects];
 If[!AllTrue[objects,#===delta||MatchQ[#,FeynFacet`EndpointPlusDistribution[x,-1,_Integer?NonNegative,1,upper]]&],
  partonicResultFail["SimpleDeltaAndPlusBasisRequired",<|"Variable"->x|>]];
 (* Distribution symbols form a tiny polynomial ring. Expanding the unrelated
    GPL coefficient functions here can cost minutes and multiply storage. *)
 terms=FeynFacet`PolynomialCoefficientRules[expression,objects];
 If[FailureQ[terms]||!AllTrue[First/@terms,Total[#]<=1&],
  partonicResultFail["OneDistributionPerAxisRequired"]];
 terms=Association[terms];
 coefficient[obj_]:=coefficient[obj]=Module[{value=If[MemberQ[objects,obj],
   Lookup[terms,Key[UnitVector[n,First@FirstPosition[objects,obj]]],0],0]},
  (* Extracting a coefficient from a factored sum of endpoint strata can
     introduce a common normal-variable denominator that cancels exactly.
     Establish that algebraic cancellation before testing independence;
     evaluating at the endpoint would conceal an unprojected coefficient. *)
  If[FreeQ[value,x],value,Factor[value]]];
 pluses=Select[objects,Head[#]===FeynFacet`EndpointPlusDistribution&];
 coefficients=coefficient/@objects;
 If[!FreeQ[coefficients,x],partonicResultFail["EndpointCoefficientsMustBeProjected",<|"Variable"->x|>]];
 partonicDistribution[partonicEndpointRow[coefficient[delta],rest],
  Association@Table[obj[[3]]->partonicEndpointRow[coefficient[obj],rest],{obj,Sort[pluses]}],
  partonicEndpointRow[Lookup[terms,Key[ConstantArray[0,n]],0],rest]]
];
CreatePartonicResultFromEndpointExpansion[expansion_Association,metadata_Association]:=Catch[Module[
 {axes,normal,intervals,e,coefficients,variable,distance,endpoint,upper,rules,basis,rawCoefficients,lower,components},
 If[Lookup[expansion,"DataType",None]=!="FiniteEndpointDistributions",
  partonicResultFail["FiniteEndpointExpansionRequired"]];
 axes=Lookup[Lookup[metadata,"DistributionBasis",<||>],"Axes",{}];
 If[!MatchQ[axes,{_Association..}]||!AllTrue[axes,
  ContainsAll[Keys[#],{"NormalVariable","Variable","Endpoint","Interval","Distance"}]&],
  partonicResultFail["ExplicitEndpointAxesRequired"]];
 e=expansion["DimensionalRegulator"];
 If[Lookup[expansion,"EndpointGeometry",None]==="NormalCrossings",
  {normal,intervals}=Lookup[expansion,{"NormalVariables","Intervals"}];
  rawCoefficients=expansion["Coefficients"];lower=expansion["LaurentLowerBound"],
  If[!ContainsAll[Keys[expansion],{"Variable","Interval","Components"}],
   partonicResultFail["ExplicitEndpointExpansionGeometryRequired"]];
  normal={expansion["Variable"]};intervals={expansion["Interval"]};components=expansion["Components"];
  If[Length[components]>1,partonicResultFail["OneScalarEndpointComponentRequired"]];
  If[components==={},lower=Min[First[metadata["EpsilonRange"]],expansion["ThroughOrder"]];
   rawCoefficients=Association@Table[j->0,{j,lower,expansion["ThroughOrder"]}],
   rawCoefficients=First[components]["Coefficients"];lower=First[components]["LaurentLowerBound"]]];
 If[Lookup[axes,"NormalVariable"]=!=normal||Lookup[axes,"Interval"]=!=intervals||
  Lookup[metadata,"DimensionalRegulator",e]=!=e,
  partonicResultFail["EndpointExpansionConventionMismatch"]];
 Do[
  {variable,distance,endpoint}=Lookup[axis,{"Variable","Distance","Endpoint"}];upper=Last[axis["Interval"]];
  If[!MatchQ[variable,_Symbol]||!MemberQ[{0,upper},endpoint]||
   !PolynomialQ[distance,variable]||Exponent[distance,variable]=!=1||
   !MemberQ[{1,-1},Coefficient[distance,variable]]||
   Cancel[distance/.variable->endpoint]=!=0||
   Cancel[(distance/.variable->(upper-endpoint))-upper]=!=0,
   partonicResultFail["UnitJacobianEndpointCoordinateRequired",<|"Axis"->axis|>]],
 {axis,axes}];
 coefficients=partonicEndpointRow[#,axes]&/@rawCoefficients;
 rules=Thread[normal->Lookup[axes,"Distance"]];coefficients=coefficients/.rules;
 If[!FreeQ[coefficients,_FeynFacet`EndpointDeltaDerivative|_FeynFacet`EndpointPlusDistribution],
  partonicResultFail["EndpointDistributionConversionIncomplete"]];
 basis=<|"Axes"->(KeyDrop[#,"NormalVariable"]&/@axes)|>;
 CreatePartonicResult[coefficients,Join[metadata,<|"DimensionalRegulator"->e,
  "DistributionBasis"->basis,"LaurentLowerBound"->lower|>]]
],"PartonicResults"];


PartonicResultInteriorCoefficients[result_Association]:=Catch[Module[{axes,interior,coefficients},
 If[!partonicResultValidQ[result],partonicResultFail["CommonPartonicResultRequired"]];
 axes=Lookup[result["DistributionBasis"],"Axes",{result["DistributionBasis"]}];
 If[Lookup[result["DistributionBasis"],"Representation",None]==="UnitInterval",
  With[{z=result["DistributionBasis"]["Variable"]},coefficients=Map[Function[row,
   row["RegularCoefficient"]+Total[KeyValueMap[Function[{point,terms},Total[KeyValueMap[
    #2 Log[If[point===0,z,1-z]]^#1/If[point===0,z,1-z]&,terms]]],row["PlusCoefficients"]]]],result["Coefficients"]]];
  Return[<|"Format"->"FeynFacet-PartonicInteriorCoefficients","Coefficients"->coefficients,
   "DimensionalRegulator"->result["DimensionalRegulator"],"EpsilonRange"->result["EpsilonRange"],
   "DimensionalPrefactor"->result["DimensionalPrefactor"],"Variables"->result["Variables"],
   "StructureFunctions"->result["StructureFunctions"],"Scope"->"Open interval only"|>,Module]];
 If[!AllTrue[axes,ContainsAll[Keys[#],{"Variable","Distance"}]&],
  partonicResultFail["ExplicitDistributionAxisDistancesRequired"]];
 interior[row_,remaining_List]:=If[remaining==={},row,Module[{d=First[remaining]["Distance"]},
  interior[row["RegularCoefficient"],Rest[remaining]]+
   Total[KeyValueMap[Function[{k,value},Log[d]^k/d interior[value,Rest[remaining]]],
    row["PlusCoefficients"]]]]];
 coefficients=interior[#,axes]&/@result["Coefficients"];
 <|"Format"->"FeynFacet-PartonicInteriorCoefficients","DimensionalRegulator"->result["DimensionalRegulator"],
  "EpsilonRange"->result["EpsilonRange"],"Coefficients"->coefficients,
  "DimensionalPrefactor"->result["DimensionalPrefactor"],"Variables"->result["Variables"],
  "StructureFunctions"->Lookup[result,"StructureFunctions",{}],
  "Scope"->"Restriction to the open physical domain; endpoint-supported terms are absent here."|>
 ],"PartonicResults"];

PartonicScalarCoefficientRules[result_Association]:=Module[{n,walk,depth},
 If[!partonicResultValidQ[result],Return[Failure["CommonPartonicResultRequired",<||>]]];
 n=Length[Lookup[result,"StructureFunctions",{"Scalar"}]];depth=partonicDistributionDepth[result["DistributionBasis"]];
 walk[row_,path_,0]:=Table[Append[path,i]->If[ListQ[row],row[[i]],row],{i,n}];
 walk[row_,path_,1]/;partonicIntervalRowQ[row]:=Join[
  Flatten[KeyValueMap[walk[#2,Append[path,{"Delta",#1}],0]&,row["DeltaCoefficients"]],1],
  Flatten[KeyValueMap[Function[{point,terms},Flatten[KeyValueMap[walk[#2,Append[path,{"Plus",point,#1}],0]&,terms],1]],row["PlusCoefficients"]],1],
  walk[row["RegularCoefficient"],Append[path,"Regular"],0]];
 walk[row_,path_,d_Integer?Positive]:=Join[
  walk[row["DeltaCoefficient"],Append[path,"Delta"],d-1],
  Flatten[KeyValueMap[walk[#2,Append[path,{"Plus",#1}],d-1]&,row["PlusCoefficients"]],1],
  walk[row["RegularCoefficient"],Append[path,"Regular"],d-1]];
 Association@Flatten[KeyValueMap[walk[#2,{#1},depth]&,result["Coefficients"]],1]
];

End[];EndPackage[];
