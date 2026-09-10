(* Exact coefficient decompositions before a joint endpoint/regulator expansion. *)
BeginPackage["FeynFacet`"];
SeparateMasterCoefficientPoles::usage =
 "SeparateMasterCoefficientPoles[entry,poles,request] subtracts explicitly certified simple pole parts from a finite master coefficient and returns its finite remainder together with exact pole entries. It preserves unknown Laurent tails and records the pieces which must be reunited in the final density.";
SimplifyMasterCoefficientEntries::usage =
 "SimplifyMasterCoefficientEntries[entries] cancels exact rational coefficients with FLINT, preserving analytic prefactors, master identities and unknown finite Laurent tails.";
VerifyMasterCoefficientDivisorCancellation::usage="VerifyMasterCoefficientDivisorCancellation[rows,system,divisorReduction,request] proves removable coefficient poles on Variable=DivisorLocation by exact Laurent principal parts, finite Taylor matrices from a regular closed DE, and independently supplied specialized integral identities. It uses no epsilon truncation and does not by itself certify joint endpoint extension.";
ConstructMasterCoefficientDivisorDerivatives::usage="ConstructMasterCoefficientDivisorDerivatives[rows,system,divisorReduction,request] verifies exact apparent-pole cancellation and constructs the finite DE derivative rows of the regularized numerator through the quotient order. The final derivative gives the exact diagonal limit and the Taylor-remainder bound when its physical integral representations are uniformly bounded.";
Begin["`Private`"];
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

VerifyMasterCoefficientDivisorCancellation[rows_Association,input_Association,
 diagonalReduction_Association,request_Association]:=Catch[Module[
 {system,basis,parameters,e,variable,location,distance,axis,n,coefficientRows,field,restore,
  variables,shifted,poleOrders,maximum,series,a,jets,diagonalJets,diagBasis,diagRules,
  diagImages,embedding,principal,residuals={},labels={},i,k,j,orders,values,cancel,dimRule},
 system=solutionNormalizeDifferentialSystem[input];
 If[!AssociationQ[system],coefficientPoleFail["NormalizedClosedDifferentialSystemRequired"]];
 {basis,parameters,e}=Lookup[system,{"MasterIntegralBasis","KinematicVariables","DimensionalRegulator"}];
 {variable,location}=Lookup[request,{"Variable","DivisorLocation"},None];
 n=Length[basis];
 If[!MemberQ[parameters,variable]||location===None||!FreeQ[location,variable]||
   !AllTrue[Values[rows],AssociationQ[#]&&ContainsAll[basis,Keys[#]]&]||
   !ContainsAll[diagonalReduction["Targets"],basis],
  coefficientPoleFail["MatchingCoefficientRowsAndSpecializedIntegralIdentitiesRequired"]];
 coefficientRows=Table[Lookup[rows[name],Key[master],0],{name,Keys[rows]},{master,basis}];
 {field,restore}=coefficientRationalFieldReduce[coefficientRows];
 If[!FreeQ[Last/@restore,variable],
  coefficientPoleFail["CoordinateDependentAnalyticCoefficientFactorRequiresTaylorExpansion"]];
 distance=Unique["divisorDistance"];shifted=field/.variable->location+distance;
 variables=DeleteDuplicates[Cases[shifted,_Symbol,{0,Infinity}]];
 If[!MemberQ[variables,distance],Return[<|"Status"->"NoDivisorPoles","MaximumPoleOrder"->0|>,Module]];
 values=FeynFacet`CancelRationalExpressions[Flatten[shifted],variables];
 If[!ListQ[values],coefficientPoleFail["RationalDivisorExpansionFailed",<|"Cause"->values|>]];
 shifted=Partition[values,n];
 poleOrders=Map[If[#===0,0,Max[0,Exponent[Denominator[#],distance,Min]-
   Exponent[Numerator[#],distance,Min]]]&,shifted,{2}];
 maximum=Max[Flatten[poleOrders]];
 If[maximum===0,Return[<|"Status"->"NoDivisorPoles","MaximumPoleOrder"->0|>,Module]];
 series=FeynFacet`RationalLaurentCoefficients[Flatten[shifted],variables,distance,{-maximum,-1}];
 If[!ListQ[series],coefficientPoleFail["ExactDivisorPrincipalPartsRequired",<|"Cause"->series|>]];
 series=Partition[series,n];axis=First@FirstPosition[parameters,variable];
 a=Normal[system["ConnectionMatrices"][[axis]]];
 If[Dimensions[a]=!={n,n}||!FreeQ[Quiet[a/.variable->location],Indeterminate|_DirectedInfinity],
  coefficientPoleFail["ClosedDifferentialConnectionRegularOnDivisorRequired"]];
 cancel[m_]:=Module[{v=FeynFacet`CancelRationalCoefficients[Flatten[Normal[m]]]},
   If[!ListQ[v],coefficientPoleFail["ExactDivisorMatrixCancellationFailed"]];
   Partition[v,Last[Dimensions[m]]]];
 jets={IdentityMatrix[n]};
 Do[AppendTo[jets,cancel[(D[Last[jets],variable]+Last[jets].a)/j]],{j,1,maximum-1}];
 diagonalJets=jets/.variable->location;
 diagBasis=diagonalReduction["Masters"];diagRules=diagonalReduction["Rules"];
 dimRule=Lookup[system,"DimensionRule",None];If[dimRule=!=None,diagRules=diagRules/.dimRule];
 diagImages=basis/.Dispatch[diagRules];
 If[!ContainsAll[diagBasis,Union[Cases[diagImages,_FeynCalc`GLI,{0,Infinity}]]],
  coefficientPoleFail["SpecializedIntegralReductionMustBeClosed"]];
 embedding=Table[Coefficient[im,m],{im,diagImages},{m,diagBasis}];
 If[!AllTrue[Expand[diagImages-embedding.diagBasis],#===0&]||!FreeQ[embedding,variable],
  coefficientPoleFail["LinearSpecializedIntegralImagesRequired"]];
 Do[
  Do[
   principal=Total[Table[
     (Lookup[series[[i]],power-j,0]).diagonalJets[[j+1]],{j,0,maximum+power}]];
   AppendTo[residuals,principal.embedding];AppendTo[labels,{Keys[rows][[i]],power}],
  {power,-maximum,-1}],
 {i,Length[rows]}];
 residuals=cancel[residuals];
 If[!AllTrue[Flatten[residuals],#===0&],
  coefficientPoleFail["MasterCoefficientDivisorPrincipalPartNonzero",<|
   "ResidualLabels"->labels,"Residuals"->(residuals/.restore),"DivisorMasterBasis"->diagBasis|>]];
 <|"Status"->"ExactDivisorPoleCancellationVerified","Variable"->variable,
  "DivisorLocation"->location,"MaximumPoleOrder"->maximum,
  "CoefficientPoleOrders"->AssociationThread[Keys[rows],poleOrders],
  "MasterIntegralBasis"->basis,"DivisorMasterBasis"->diagBasis,
  "DivisorIntegralEmbedding"->embedding,"NormalTaylorMatrices"->diagonalJets,
  "PrincipalPartsChecked"->labels,"EpsilonExpansionUsed"->False,
  "ConnectionRegularOnDivisor"->True,"ExternalEndpointUniformityEstablished"->False,
  "Scope"->"The supplied closed subsystem and specialized physical integral identities. Joint high-dimension derivative bounds remain separate."|>
],"CoefficientPoles"];

ConstructMasterCoefficientDivisorDerivatives[rows_Association,input_Association,
 diagonalReduction_Association,request_Association]:=Catch[Module[
 {verified,system,basis,variable,location,e,axis,a,distance,n,c,regular,jets,derivatives,
  labels,orders,k,values,limits,cancel},
 verified=FeynFacet`VerifyMasterCoefficientDivisorCancellation[rows,input,diagonalReduction,request];
 If[FailureQ[verified],Throw[verified,"CoefficientPoles"]];
 system=solutionNormalizeDifferentialSystem[input];basis=system["MasterIntegralBasis"];
 {variable,location}=Lookup[request,{"Variable","DivisorLocation"}];e=system["DimensionalRegulator"];
 n=Length[basis];axis=First@FirstPosition[system["KinematicVariables"],variable];
 a=Normal[system["ConnectionMatrices"][[axis]]];distance=variable-location;labels=Keys[rows];
 cancel[m_]:=Module[{v=FeynFacet`CancelRationalCoefficients[Flatten[m]]},
  If[!ListQ[v],coefficientPoleFail["ExactDivisorDerivativeCancellationFailed"]];
  Partition[v,n]];
 c=Table[Lookup[rows[label],Key[master],0],{label,labels},{master,basis}];
 orders=If[verified["Status"]==="NoDivisorPoles",ConstantArray[0,Length[rows]],
   Max/@Values[verified["CoefficientPoleOrders"]]];
 regular=cancel[MapThread[#1^#2 #3&,{ConstantArray[distance,Length[rows]],orders,c}]];
 jets={regular};
 Do[AppendTo[jets,cancel[D[Last[jets],variable]+Last[jets].a]],{j,Max[orders]}];
 derivatives=Association@Table[labels[[i]]->Take[jets[[All,i]],orders[[i]]+1],{i,Length[labels]}];
 (* Each row already contains its common analytic normalization; the exact
    cancellation check refuses omitted coordinate-dependent analytic factors. *)
 limits=Association@Table[labels[[i]]->
   (Last[derivatives[labels[[i]]]]/.variable->location)/Factorial[orders[[i]]],
   {i,Length[labels]}];
 If[!FreeQ[{derivatives,limits},Indeterminate|_DirectedInfinity],
  coefficientPoleFail["RegularDivisorDerivativeRowsRequired"]];
 <|"DataType"->"MasterCoefficientDivisorDerivatives",
  "Status"->"ExactDivisorDerivativeRowsConstructed","Variable"->variable,
  "DivisorLocation"->location,"MasterIntegralBasis"->basis,
  "DivisorCancellation"->verified,"QuotientOrders"->AssociationThread[labels,orders],
  "RegularNumeratorDerivativeRows"->derivatives,"DiagonalValueRows"->limits,
  "UniformBoundEstablished"->False,
  "TaylorRemainderConvention"->"For k>0 the quotient is 1/(k-1)! times the integral from 0 to 1 of (1-t)^(k-1) times the kth derivative along x'=location+t(x-location). A uniform derivative bound B gives B/k!.",
  "Scope"->"Exact finite derivatives on the ordinary physical interior. Uniform physical-integral bounds and valid specialization of the supplied identities are separate."|>
],"CoefficientPoles"];

End[];
EndPackage[];
