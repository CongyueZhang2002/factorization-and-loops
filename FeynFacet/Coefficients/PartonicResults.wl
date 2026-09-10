(* One persisted result format for every perturbative order and partonic channel. *)
BeginPackage["FeynFacet`"];
CreatePartonicResult::usage="CreatePartonicResult[epsilonCoefficients,metadata] creates the common delta/plus/regular result with explicit contiguous epsilon coverage.";
ReadPartonicResult::usage="ReadPartonicResult[file,requirements] reads the common result and checks identity, normalization and requested epsilon coverage.";
RequirePartonicEpsilonRange::usage="RequirePartonicEpsilonRange[result,{low,high}] rejects absent coefficients; a truncated series is never treated as an exact polynomial.";
CombinePartonicResults::usage="CombinePartonicResults[contributions,metadata] adds results in the same convention and records their contribution names.";
CreatePartonicResultFromEndpointExpansion::usage="CreatePartonicResultFromEndpointExpansion[expansion,metadata] stores explicit normal-crossing endpoint coefficients in the common recursive delta/plus/regular format. DistributionBasis[Axes] declares NormalVariable, Variable, Endpoint, Interval and Distance for each axis, with a unit absolute Jacobian.";
PartonicResultInteriorCoefficients::usage="PartonicResultInteriorCoefficients[result] restricts the common tensor-product delta/plus/regular Laurent result to the open physical domain: deltas vanish and plus distributions equal their ordinary densities. It retains all recorded epsilon orders and does not define an endpoint continuation.";
Begin["`Private`"];
partonicResultFail[tag_,data_:<||>]:=Throw[Failure[tag,data],"PartonicResults"];
partonicDistribution[delta_,plus_,regular_]:=<|"DeltaCoefficient"->delta,"PlusCoefficients"->plus,"RegularCoefficient"->regular|>;
partonicCollect[expr_]:=Module[{value,atoms},
 value=If[FreeQ[expr,_Sin|_Cos],expr,TrigExpand[expr]];
 atoms=DeleteDuplicates[Cases[value,_Log|_PolyLog,{0,Infinity}]];
 If[atoms==={},Factor[value],Collect[value,atoms,Factor]]];
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
partonicResultValidQ[result_]:=Module[{range,e,cs,basis,depth},
 If[!AssociationQ[result]||Lookup[result,"Format",None]=!="FeynFacet-PartonicResult"||
   !ContainsAll[Keys[result],{"EpsilonRange","DimensionalRegulator","Coefficients","Scale","Variables","DensityConvention","DistributionBasis","DimensionalPrefactor","LaurentLowerBound","Order","Contribution"}],Return[False]];
 range=result["EpsilonRange"];e=result["DimensionalRegulator"];cs=result["Coefficients"];
 basis=result["DistributionBasis"];If[!AssociationQ[basis],Return[False]];
 If[KeyExistsQ[basis,"Axes"]&&(!MatchQ[basis["Axes"],{_Association..}]||
  !AllTrue[basis["Axes"],ContainsAll[Keys[#],{"Variable","Endpoint","Interval","Distance"}]&]||
  !DuplicateFreeQ[Lookup[basis["Axes"],"Variable"]]),Return[False]];
 depth=partonicDistributionDepth[basis];
 If[KeyExistsQ[result,"Polarization"]&&!MatchQ[result["Polarization"],_Association],Return[False]];
 TrueQ[MatchQ[range,{_Integer,_Integer}]&&First[range]<=Last[range]&&AssociationQ[cs]&&
  Sort[Keys[cs]]===(Range@@range)&&IntegerQ[result["LaurentLowerBound"]]&&result["LaurentLowerBound"]<=First[range]&&AllTrue[Values[cs],partonicDistributionValidQ[#,depth]&]&&
  FreeQ[cs,e|_FeynFacet`EndpointDeltaDerivative|_FeynFacet`EndpointPlusDistribution|_Failure|_Missing|_SeriesData|_Series|_SeriesCoefficient|Indeterminate|_DirectedInfinity|$Failed|$Aborted]]
];
CreatePartonicResult[coefficients_Association,metadata_Association]:=Catch[Module[{record},
 If[Length[coefficients]===0,partonicResultFail["ExplicitEpsilonCoefficientsRequired"]];
 record=Join[KeyDrop[metadata,{"Coefficients","EpsilonRange","Format","FormatVersion"}],<|
  "Format"->"FeynFacet-PartonicResult","FormatVersion"->1,
  "EpsilonRange"->{Min[Keys[coefficients]],Max[Keys[coefficients]]},
  "LaurentLowerBound"->Lookup[metadata,"LaurentLowerBound",Min[Keys[coefficients]]],
  "DimensionalPrefactor"->Lookup[metadata,"DimensionalPrefactor",1],
  "Coefficients"->coefficients,"DensityConvention"->Lookup[metadata,"DensityConvention","E_c d sigma/d^(D-1)p_c"],
  "DistributionBasis"->Lookup[metadata,"DistributionBasis",<|"Variable"->Last[metadata["Variables"]],"Endpoint"->1,"Interval"->{0,1},"Distance"->1-Last[metadata["Variables"]]|>],
  "PlusConvention"->"At each axis, PlusCoefficients[k] multiplies [Log[Distance]^k/Distance]_+ on Interval, with subtraction at Endpoint. For DistributionBasis[Axes], delta/plus/regular values repeat recursively in the listed axis order."|>];
 record["DistributionBasis"]=partonicPhysicalDistributionBasis[record["DistributionBasis"]];
 If[!partonicResultValidQ[record],partonicResultFail["PartonicResultIncompleteOrInvalid"]];
 record],"PartonicResults"];
RequirePartonicEpsilonRange[result_Association,range:{_Integer,_Integer}]:=If[
 partonicResultValidQ[result]&&First[range]<=Last[range]&&First[result["EpsilonRange"]]<=First[range]&&Last[result["EpsilonRange"]]>=Last[range],
 True,Failure["InsufficientResultEpsilonOrders",<|"Requested"->range,"Available"->Lookup[result,"EpsilonRange",Missing[]]|>]];
ReadPartonicResult[file_String,requirements_Association:<||>]:=Catch[Module[{result,range},
 If[!FileExistsQ[file],partonicResultFail["PartonicResultFileMissing",<|"File"->file|>]];
 result=If[ToLowerCase[FileExtension[file]]==="wxf",Import[file,"WXF"],FamilyArtifactRead[file]];
 If[!partonicResultValidQ[result],partonicResultFail["CommonPartonicResultRequired",<|"File"->file|>]];
 KeyValueMap[Function[{key,value},If[key=!="EpsilonRange"&&
   If[key==="DistributionBasis"&&AssociationQ[value],
    partonicPhysicalDistributionBasis[result[key]]=!=partonicPhysicalDistributionBasis[value],
    Lookup[result,key,Missing[]]=!=value],
   partonicResultFail["PartonicResultIdentityMismatch",<|"File"->file,"Field"->key,"Expected"->value,"Actual"->Lookup[result,key,Missing[]]|>]]],requirements];
 If[KeyExistsQ[requirements,"EpsilonRange"],range=RequirePartonicEpsilonRange[result,requirements["EpsilonRange"]];
   If[FailureQ[range],Throw[range,"PartonicResults"]]];result],"PartonicResults"];
CombinePartonicResults[contributions_Association,metadata_Association]:=Catch[Module[{all,range,cs,rows,plus,identityKeys,depth},
 all=Values[contributions];If[all==={}||!AllTrue[all,partonicResultValidQ],partonicResultFail["CommonPartonicResultsRequired"]];
 all=Map[Join[#,<|"DistributionBasis"->partonicPhysicalDistributionBasis[#["DistributionBasis"]]|>]&,all];
 identityKeys=Select[{"Order","Project","Channel","PhysicalChannel","Polarization","Coupling","CouplingPower","StructureFunctions"},
  Function[key,AnyTrue[all,KeyExistsQ[#,key]&]]];
 If[!AllTrue[all,KeyTake[#,identityKeys]===KeyTake[First[all],identityKeys]&],
  partonicResultFail["PartonicResultIdentityMismatch"]];
 If[!AllTrue[all,KeyTake[#,{"Scale","Variables","DimensionalRegulator","DensityConvention","DistributionBasis","DimensionalPrefactor","CurrentNormalization"}]===
  KeyTake[First[all],{"Scale","Variables","DimensionalRegulator","DensityConvention","DistributionBasis","DimensionalPrefactor","CurrentNormalization"}]&],partonicResultFail["PartonicResultConventionMismatch"]];
 If[!AllTrue[all,First[#["EpsilonRange"]]===#["LaurentLowerBound"]&],partonicResultFail["UncomputedLowerEpsilonCoefficients"]];
 range={Min[First[#["EpsilonRange"]]& /@ all],Min[Last[#["EpsilonRange"]]& /@ all]};
 depth=partonicDistributionDepth[First[all]["DistributionBasis"]];
 cs=Association@Table[
  rows=Lookup[#["Coefficients"],j,partonicDistributionZero[depth]]& /@ all;
  j->partonicDistributionSum[rows,depth],{j,First[range],Last[range]}];
 CreatePartonicResult[cs,Join[KeyTake[First[all],Union[identityKeys,{"Scale","Variables","DimensionalRegulator","Order","DensityConvention","DistributionBasis","DimensionalPrefactor","CurrentNormalization"}]],metadata,
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
 coefficient[obj_]:=If[MemberQ[objects,obj],
  Lookup[terms,Key[UnitVector[n,First@FirstPosition[objects,obj]]],0],0];
 pluses=Select[objects,Head[#]===FeynFacet`EndpointPlusDistribution&];
 coefficients=coefficient/@objects;
 If[!FreeQ[coefficients,x],partonicResultFail["EndpointCoefficientsMustBeProjected",<|"Variable"->x|>]];
 partonicDistribution[partonicEndpointRow[coefficient[delta],rest],
  Association@Table[obj[[3]]->partonicEndpointRow[coefficient[obj],rest],{obj,Sort[pluses]}],
  partonicEndpointRow[Lookup[terms,Key[ConstantArray[0,n]],0],rest]]
];
CreatePartonicResultFromEndpointExpansion[expansion_Association,metadata_Association]:=Catch[Module[
 {axes,normal,intervals,e,coefficients,variable,distance,endpoint,upper,rules,basis},
 If[Lookup[expansion,"DataType",None]=!="FiniteEndpointDistributions"||
  Lookup[expansion,"EndpointGeometry",None]=!="NormalCrossings",
  partonicResultFail["NormalCrossingEndpointExpansionRequired"]];
 axes=Lookup[Lookup[metadata,"DistributionBasis",<||>],"Axes",{}];
 If[!MatchQ[axes,{_Association..}]||!AllTrue[axes,
  ContainsAll[Keys[#],{"NormalVariable","Variable","Endpoint","Interval","Distance"}]&],
  partonicResultFail["ExplicitEndpointAxesRequired"]];
 {normal,intervals,e}=Lookup[expansion,{"NormalVariables","Intervals","DimensionalRegulator"}];
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
 coefficients=partonicEndpointRow[#,axes]&/@expansion["Coefficients"];
 rules=Thread[normal->Lookup[axes,"Distance"]];coefficients=coefficients/.rules;
 If[!FreeQ[coefficients,_FeynFacet`EndpointDeltaDerivative|_FeynFacet`EndpointPlusDistribution],
  partonicResultFail["EndpointDistributionConversionIncomplete"]];
 basis=<|"Axes"->(KeyDrop[#,"NormalVariable"]&/@axes)|>;
 CreatePartonicResult[coefficients,Join[metadata,<|"DimensionalRegulator"->e,
  "DistributionBasis"->basis,"LaurentLowerBound"->expansion["LaurentLowerBound"]|>]]
],"PartonicResults"];


PartonicResultInteriorCoefficients[result_Association]:=Catch[Module[{axes,interior,coefficients},
 If[!partonicResultValidQ[result],partonicResultFail["CommonPartonicResultRequired"]];
 axes=Lookup[result["DistributionBasis"],"Axes",{result["DistributionBasis"]}];
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

End[];EndPackage[];
