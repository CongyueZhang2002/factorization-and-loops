(* Exact coefficient decompositions before a joint endpoint/regulator expansion. *)
BeginPackage["FeynFacet`"];
SeparateMasterCoefficientPoles::usage =
 "SeparateMasterCoefficientPoles[entry,poles,request] subtracts explicitly certified simple pole parts from a finite master coefficient and returns its finite remainder together with exact pole entries. It preserves unknown Laurent tails and records the pieces which must be reunited in the final density.";
SimplifyMasterCoefficientEntries::usage =
 "SimplifyMasterCoefficientEntries[entries] cancels exact rational coefficients with FLINT, preserving analytic prefactors, master identities and unknown finite Laurent tails.";
Begin["`Private`"];
Clear[coefficientRationalFieldReduce];
coefficientRationalFieldReduce[expression_]:=Module[
 {atoms,constants=<||>,restore={},constant,power,termPower,rules},
 constant[x_]:=Module[{s=Lookup[constants,Key[x],None]},
   If[s===None,s=Unique["coefficientField"];AssociateTo[constants,x->s];AppendTo[restore,s->x]];s];
 termPower[b_,t_]:=Module[{n=1,rest=t,parts},
   If[MatchQ[t,_Integer|_Rational],n=t;rest=1,
    If[Head[t]===Times&&MatchQ[First[t],_Integer|_Rational],n=First[t];rest=Times@@Rest[t]]];
   If[rest===1&&IntegerQ[n],b^n,
    constant[b^(rest/Denominator[n])]^Numerator[n]]];
 (* Preserve additive exponent identities before introducing independent
    field symbols. For example 2^(3-4 epsilon)=8 (2^epsilon)^(-4).
    Only integer outer powers are used; no PowerExpand is involved. *)
 power[b_,p_]:=With[{expanded=Expand[p]},Times@@
   (termPower[b,#]&/@If[Head[expanded]===Plus,List@@expanded,{expanded}])];
 atoms=DeleteDuplicates@Join[
   Cases[expression,Power[_,p_]/;!IntegerQ[p],{0,Infinity}],
   Cases[expression,a:h_[___]/;!MemberQ[{Plus,Times,Power,Rational},h]:>a,{0,Infinity}]];
 rules=Map[Function[x,x->If[Head[x]===Power,power[x[[1]],x[[2]]],constant[x]]],atoms];
 {expression/.rules,restore}
];
Options[SimplifyMasterCoefficientEntries]={"Verbose"->False};
SimplifyMasterCoefficientEntries[entries_List,OptionsPattern[]]:=Catch[Module[
 {result=entries,reports={},terms,term,vars,value,seconds,before,reduced,restore},
 Do[
  terms=Lookup[result[[i]],"Terms",None];
  If[!ListQ[terms],Throw[Failure["CanonicalCoefficientEntriesRequired",<||>],"SimplifyCoefficients"]];
  Do[
   term=terms[[j]];If[Lookup[term,"Representation",None]=!="Exact",Continue[]];
   before=LeafCount[term["Coefficient"]];
   {reduced,restore}=coefficientRationalFieldReduce[term["Coefficient"]];
   vars=DeleteDuplicates[Cases[reduced,_Symbol,Infinity]];
   If[vars==={},terms[[j]]=Join[term,<|"Coefficient"->(reduced/.restore)|>];Continue[]];
   If[TrueQ[OptionValue["Verbose"]],Print["Cancelling rational coefficient row ",i," term ",j," (",before," leaves)."]];
   {seconds,value}=AbsoluteTiming[CancelRationalExpressions[{reduced},vars]];
   If[FailureQ[value],Throw[value,"SimplifyCoefficients"]];
   value=value/.restore;
   terms[[j]]=Join[term,<|"Coefficient"->First[value]|>];
   AppendTo[reports,<|"Row"->i,"TermIndex"->j,"InputLeafCount"->before,
     "OutputLeafCount"->LeafCount[First[value]],"Seconds"->seconds|>],
  {j,Length[terms]}];
  result[[i]]=Join[result[[i]],<|"Terms"->terms|>],
 {i,Length[result]}];
 <|"CoefficientEntries"->result,"RationalCancellationReport"->reports,
  "Method"->"Exact multivariate rational arithmetic over Q with all declared parameters symbolic."|>
],"SimplifyCoefficients"];
Clear[coefficientPoleFail,coefficientPoleRecordQ,coefficientPoleCoverage];
coefficientPoleFail[tag_,data_:<||>]:=Throw[Failure[tag,data],"CoefficientPoles"];
coefficientPoleRecordQ[r_]:=AssociationQ[r]&&
 StringQ[Lookup[r,"PoleLabel",None]]&&ListQ[Lookup[r,"Master",None]]&&
 IntegerQ[Lookup[r,"SourceTermIndex",None]]&&KeyExistsQ[r,"PoleExpression"];
(* A full coefficient is counted once; every removed piece must appear once
   with precisely the same master, source term and exact expression. *)
coefficientPoleCoverage[removed_List,added_List,owners_List]:=Module[{key,rs,as},
 If[!AllTrue[Join[removed,added],coefficientPoleRecordQ],Return[False]];
 key[r_]:=Lookup[r,{"Master","PoleLabel","SourceTermIndex"}];
 rs=key/@removed;as=key/@added;
 DuplicateFreeQ[rs]&&DuplicateFreeQ[as]&&Sort[rs]===Sort[as]&&
 AllTrue[removed,MemberQ[owners,#["Master"]]&]&&
 Sort[KeyTake[#,{"Master","PoleLabel","SourceTermIndex","PoleExpression"}]&/@removed]===
 Sort[KeyTake[#,{"Master","PoleLabel","SourceTermIndex","PoleExpression"}]&/@added]
];
SeparateMasterCoefficientPoles[entry_Association,poles_List,request_Association]:=Catch[Module[
 {e,z,upper,terms,master,classes,records={},parts={},byTerm,indices,t,known,hi,
  selected,expression,expansion,lower,orders,coefficient,remainderClass,pole,record},
 {e,z,upper}=Lookup[request,{"DimensionalRegulator","NormalVariable","ThroughOrder"},None];
 If[!MatchQ[{e,z},{_Symbol,_Symbol}]||e===z||MemberQ[{e,z},None]||!IntegerQ[upper]||
  poles==={}||!AllTrue[poles,AssociationQ]||!ListQ[Lookup[entry,"Terms",None]],
  coefficientPoleFail["FiniteCoefficientAndExplicitPoleDataRequired"]];
 terms=coefficientRegulatorNormalize[entry["Terms"],e];master=coefficientMasterID[entry["Master"]];
 classes=Lookup[request,"ResidualDivisorCertificate",<||>];
 If[Lookup[classes,"Status",None]=!="FixedResidualDivisorsEstablished"||
   !TrueQ[Lookup[classes,"UniformOnTangentialCompactSets",False]]||
   !IntegerQ[Lookup[classes,"NormalPoleOrderUpperBound",None]]||
   !TrueQ[classes["NormalPoleOrderUpperBound"]>=0]||
   Sort[Lookup[classes,"RemovedPoleLabels",{}]]=!=Sort[Lookup[poles,"PoleLabel",{}]],
  coefficientPoleFail["CompleteResidualDivisorCertificateRequired"]];
 indices=Lookup[poles,"SourceTermIndex",None];
 If[!AllTrue[indices,IntegerQ[#]&&1<=#<=Length[terms]&]||
  !DuplicateFreeQ[Lookup[poles,"PoleLabel",{}]],coefficientPoleFail["DistinctIdentifiedPolePartsRequired"]];
 Do[
  pole=coefficientRegulatorNormalize[p,e];
  If[!StringQ[Lookup[pole,"PoleLabel",None]]||
    !KeyExistsQ[pole,"Residue"]||!KeyExistsQ[pole,"DivisorLocation"]||
    !FreeQ[{pole["Residue"],pole["DivisorLocation"]},z]||
    Lookup[Lookup[pole,"SourceResidueCertificate",<||>],"Status",None]=!="ExactSourceResidueProportionalityEstablished",
   coefficientPoleFail["ExactSourcePoleResidueRequired"]];
  t=terms[[pole["SourceTermIndex"]]];
  expression=pole["Residue"]/(z-pole["DivisorLocation"]);
  record=<|"Master"->master,"PoleLabel"->pole["PoleLabel"],
    "SourceTermIndex"->pole["SourceTermIndex"],"PoleExpression"->t["PreFactor"] expression|>;
  AppendTo[records,record];
  AppendTo[parts,Join[KeyTake[entry,{"Master"}],<|
    "Terms"->{<|"Representation"->"Exact","PreFactor"->t["PreFactor"],"Coefficient"->expression|>},
    "PartialCoefficientContributions"->{record}|>]],
 {p,poles}];
 Do[
  t=terms[[i]];If[Lookup[t,"Representation",None]=!="LaurentSeries",
   coefficientPoleFail["FiniteSourceCoefficientRequired",<|"TermIndex"->i|>]];
  coefficient=t["Coefficient"];known=coefficient["SeriesTruncation"];hi=Min[known,upper];
  selected=Pick[parts,indices,i];
  expression=Total[#["Terms"][[1,"Coefficient"]]&/@selected];
  expansion=regulatorSeries[expression,e,hi];
  If[FailureQ[expansion],coefficientPoleFail["ExplicitPoleExpansionFailed",<|"Cause"->expansion|>]];
  lower=Min[Keys[coefficient["Orders"]],First[expansion]];
  orders=Association@Table[q->(Lookup[coefficient["Orders"],q,0]-
     Coefficient[Last[expansion],e,q]),{q,lower,hi}];
  remainderClass=<|"Status"->"EstablishedForSourceCoefficient","NormalDivisor"->z,
    "EpsilonOrderLowerBound"->hi+1,"NormalPoleOrderUpperBound"->classes["NormalPoleOrderUpperBound"],
    "UniformOnTangentialCompactSets"->True,"Justification"->classes|>;
  terms[[i]]=Join[t,<|"Coefficient"->Join[coefficient,<|"Orders"->orders,"SeriesTruncation"->hi|>],
    "LaurentRemainderClass"->remainderClass|>],
 {i,DeleteDuplicates[indices]}];
 <|"DataType"->"MasterCoefficientPoleDecomposition",
   "RemainderEntry"->Join[entry,<|"Terms"->terms,"SeparatedCoefficientPoles"->records|>],
   "PoleEntries"->AssociationThread[Lookup[poles,"PoleLabel"],parts],
   "ResidualDivisorCertificate"->classes,
   "Convention"->"Original coefficient = finite remainder with its declared unknown tail + all listed exact pole parts."|>
],"CoefficientPoles"];
SeparateMasterCoefficientPoles[___]:=Failure["FiniteCoefficientAndExplicitPoleDataRequired",<||>];
End[];
EndPackage[];
