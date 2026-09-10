(* Exact endpoint powers of linear massless one-loop scalar combinations.
   The two-scale triangle is kept analytic at coincident off-shell scales. *)
BeginPackage["FeynFacet`"];
ResolveOneLoopScalarEndpointPowers::usage="ResolveOneLoopScalarEndpointPowers[values,epsilon,variables,conditions] resolves normalized FeynCalc B0,C0,D0 combinations into coordinate powers and jointly analytic factors near a positive corner. Coefficients may include the physical measure. Causal phases are retained; no conjugate interference is added.";
VerifyResolvedEndpointCollars::usage="VerifyResolvedEndpointCollars[resolved,conditions] checks scalar denominator units and real Gauss branches on every open physical face in the declared tangential domain. The already verified joint corner supplies their intersections.";
ConstructResolvedEndpointFaceProfiles::usage="ConstructResolvedEndpointFaceProfiles[resolved] contracts all simple-pole face restrictions of a verified resolved density, grouping equal regulator exponents. Full complementary-coordinate powers are retained. These are exact profiles before epsilon expansion.";
Begin["`Private`"];
loopEndpointFail[tag_,details_:<||>]:=Throw[Failure[tag,details],"OneLoopEndpoint"];
loopEndpointSplit[expression_,e_,xs_,conditions_]:=Module[
 {split,zero=ConstantArray[0,Length[xs]],rational,expFactors,parts},
 rational[value_]:=Module[{q=Cancel[Together[value]],powers,unit,den0},
  If[!PolynomialQ[Numerator[q],xs]||!PolynomialQ[Denominator[q],xs],
   loopEndpointFail["RationalNormalCoordinateFactorRequired",<|"Factor"->value|>]];
  If[q===0,Return[{zero,0}]];
  powers=Table[Exponent[Numerator[q],x,Min]-Exponent[Denominator[q],x,Min],{x,xs}];
  unit=Cancel[q/Times@@MapThread[Power,{xs,powers}]];
  den0=Denominator[unit]/.Thread[xs->0];
  If[!TrueQ[FullSimplify[den0!=0,Assumptions->conditions]],
   loopEndpointFail["JointAnalyticCoefficientDenominatorRequired",<|"Denominator"->Denominator[unit],"Factor"->value|>]];
  {powers,unit}];
 expFactors[arg_]:=Times@@Map[Function[term,Module[{logs=Cases[term,_Log,{0,Infinity}],c},
  If[Length[logs]===1,c=Cancel[term/First[logs]];
   If[FreeQ[c,Alternatives@@xs],Return[First[logs][[1]]^c,Module]]];Exp[term]]],
  With[{a=Expand[arg]},If[Head[a]===Plus,List@@a,{a}]]];
 split[a_]:=Which[
  FreeQ[a,Alternatives@@xs],{zero,a},
  Head[a]===Times,With[{terms=split/@List@@a},{Total[First/@terms],Times@@Last/@terms}],
  MatchQ[a,Power[E,_]],With[{factored=expFactors[a[[2]]]},
   If[factored===a,loopEndpointFail["UnsupportedExponentialCoordinateDependence"]];split[factored]],
  Head[a]===Power&&!IntegerQ[a[[2]]],
   Module[{g=rational[a[[1]]],power=a[[2]],unit0},
    If[!FreeQ[power,Alternatives@@xs]||!PolynomialQ[power,e]||Exponent[power,e]>1,
      loopEndpointFail["AffineCoordinatePowerRequired",<|"Expression"->a,"Exponent"->power,"Regulator"->e|>]];
    unit0=g[[2]]/.Thread[xs->0];
    If[!TrueQ[FullSimplify[g[[2]]>0&&unit0>0,Assumptions->conditions]],
     loopEndpointFail["PositiveAnalyticPowerUnitRequired",<|"Unit"->g[[2]]|>]];
    {Expand[power g[[1]]],g[[2]]^power}],
  MatchQ[a,_Hypergeometric2F1|_AppellF1|Inactive[Hypergeometric2F1][___]],
   Module[{arguments=If[MatchQ[a,_Hypergeometric2F1|Inactive[Hypergeometric2F1][___]],{a[[4]]},Take[List@@a,-2]]},
    If[!AllTrue[arguments,boxAnalyticZeroAtCornerQ[#,xs,conditions]&],
     loopEndpointFail["AnalyticHypergeometricCornerArgumentsRequired",<|"Function"->a|>]];
    {zero,a}],
  True,rational[a]];
 split[expression]
];
loopEndpointScalarTerms[object_,e_,xs_,conditions_]:=Module[
 {active,mass,values,a,b,la,lb,ratio,gauss,rg,result,terms},
 If[object===1,Return[{1}]];
 If[MatchQ[object,FeynCalc`D0[_,_,_,_,_,_,0,0,0,0]],
  active=Select[Take[List@@object,4],!TrueQ[FullSimplify[#==0,Assumptions->conditions]]&];
  If[Length[active]>1,loopEndpointFail["OneOffShellBoxRequired"]];
  mass=If[active==={},0,First[active]];
  result=FeynFacet`ResolveMasslessBoxEndpointPowers[{object[[5]],object[[6]],mass},e,xs,conditions];
  If[FailureQ[result],loopEndpointFail["OneLoopBoxEndpointResolutionFailed",<|"Cause"->result|>]];
  Return[(Pi^-e Times@@MapThread[Power,{xs,#["Powers"]}]#["SmoothFactor"])&/@result["Terms"]]];
 If[MatchQ[object,FeynCalc`C0[_,_,_,0,0,0]],
  values=Take[List@@object,3];
  active=Select[values,!TrueQ[FullSimplify[#==0,Assumptions->conditions]]&];
  If[Length[active]===2,
   {a,b}=active;
   (* When both scales remain nonzero, preserve the analytic divided
      difference as a Gauss function if their ratio tends to one. *)
   ratio=Cancel[b/a];
   If[TrueQ[FullSimplify[(a/.Thread[xs->0])!=0,Assumptions->conditions]]&&
      boxAnalyticZeroAtCornerQ[1-ratio,xs,conditions],
    la=oneLoopCausalLog[a,1,conditions];lb=oneLoopCausalLog[b,1,conditions];
    If[!TrueQ[FullSimplify[a b>0,Assumptions->conditions]],loopEndpointFail["CommonTriangleCausalPhaseRequired"]];
    rg=Gamma[1+e]Gamma[1-e]^2/Gamma[1-2e];
    Return[{-Pi^-e rg Exp[-e la]/(e a) Hypergeometric2F1[1,1+e,2,1-ratio]}]
   ]
  ]
 ];
 result=FeynFacet`EvaluateOneLoopScalarFunctions[object,e,conditions];
 If[FailureQ[result],loopEndpointFail["SupportedScalarEndpointFunctionRequired",<|"Cause"->result|>]];
 (* Split the two finite Gamma-power terms of a divided difference, without
    expanding the large physical rational coefficient multiplying it. *)
 terms=Expand[result];If[Head[terms]===Plus,List@@terms,{terms}]
];
ResolveOneLoopScalarEndpointPowers[values_Association,e_Symbol,xs:{__Symbol},conditions_]:=
 Catch[Module[{objects,aliases,polynomials,basis,coefficientMatrix,terms={},scalar,split,expressions,
   labels=Keys[values],source,powers,factor,row,zero,bubbles,references={},reference,a,b,y,divisor,
   field,restore,den,order,depth,baseValue,comparison,coincident={},before},
 If[values===<||>||!DuplicateFreeQ[xs]||MemberQ[xs,e],loopEndpointFail["ScalarEndpointVariablesRequired"]];
 expressions=FeynFacet`ReduceMasslessScalarTriangles[#,e,conditions]&/@Values[values];
 If[AnyTrue[expressions,FailureQ],loopEndpointFail["MasslessTriangleEndpointReductionFailed"]];
 objects=DeleteDuplicates[Cases[expressions,_FeynCalc`B0|_FeynCalc`C0|_FeynCalc`D0,{0,Infinity}]];
 aliases=Unique["scalarEndpointIntegral"]&/@objects;basis=Prepend[objects,1];
 polynomials=FeynFacet`PolynomialCoefficientRules[#/.Thread[objects->aliases],aliases]&/@expressions;
 If[AnyTrue[polynomials,FailureQ]||!AllTrue[Flatten[First/@#&/@polynomials,1],Total[#]<=1&],
  loopEndpointFail["LinearScalarEndpointCombinationRequired"]];
 coefficientMatrix=Table[Lookup[Association[polynomials[[i]]],
  Key[If[j===1,ConstantArray[0,Length[objects]],UnitVector[Length[objects],j-1]]],0],
  {i,Length[labels]},{j,Length[basis]}];
 coefficientMatrix=Partition[FeynFacet`CancelRationalCoefficients[Flatten[coefficientMatrix]],Length[basis]];
 (* A coincident bubble pair is an exact binomial divided difference.
    Move its finite Taylor polynomial to the reference coefficient, and
    retain the analytic Gauss remainder. This removes only proved factors. *)
 bubbles=Select[Range[Length[basis]],MatchQ[basis[[#]],FeynCalc`B0[_,0,0]]&];
 Do[
  b=basis[[j,1]];
  reference=SelectFirst[references,Function[k,
   a=basis[[k,1]];
   TrueQ[FullSimplify[(a/.Thread[xs->0])!=0&&a b>0,Assumptions->conditions]]&&
    boxAnalyticZeroAtCornerQ[Cancel[1-b/a],xs,conditions]],None];
  If[reference===None,AppendTo[references,j];Continue[]];
  a=basis[[reference,1]];y=Cancel[1-b/a];divisor=Numerator[y];
  {field,restore}=coefficientRationalFieldReduce[coefficientMatrix[[All,j]]];
  depth=Max[Table[den=Denominator[Cancel[Together[c]]];order=0;
   While[order<16&&PolynomialQ[Cancel[den/divisor^(order+1)],xs],order++];order,{c,field}]];
  If[depth===0,Continue[]];
  If[depth>=16,loopEndpointFail["FiniteCoincidentBubblePoleOrderRequired"]];
  comparison=Sum[Pochhammer[e,k]y^k/Factorial[k],{k,0,depth-1}];
  before=coefficientMatrix[[All,j]];
  coefficientMatrix[[All,reference]]=FeynFacet`CancelRationalCoefficients[
   coefficientMatrix[[All,reference]]+before comparison];
  coefficientMatrix[[All,j]]=FeynFacet`CancelRationalCoefficients[before y^depth];
  basis[[j]]=basis[[reference]] Pochhammer[e,depth]/Factorial[depth]*
   Inactive[Hypergeometric2F1][1,e+depth,1+depth,y];
  AppendTo[coincident,<|"ReferenceInvariant"->a,"Invariant"->b,"CoincidenceVariable"->y,
    "TaylorSubtractionOrder"->depth,"Identity"->"Exact binomial Taylor polynomial plus Gauss remainder"|>],
 {j,bubbles}];
 Do[
  source=basis[[j]];scalar=loopEndpointScalarTerms[source,e,xs,conditions];
  Do[If[coefficientMatrix[[i,j]]===0,Continue[]];
   Do[
    split=Catch[loopEndpointSplit[Factor[coefficientMatrix[[i,j]]] value,e,xs,conditions],"OneLoopEndpoint"];
    If[FailureQ[split],loopEndpointFail["ScalarCombinationEndpointFactorizationFailed",<|"ScalarIntegral"->source,"Row"->i,"Cause"->split,"CoincidentBubbleSubtractions"->coincident|>]];
    If[split[[2]]=!=0,AppendTo[terms,<|"Row"->i,"ScalarIntegral"->source,
     "Powers"->split[[1]],"SmoothFactor"->split[[2]]|>]],
   {value,scalar}],
  {i,Length[labels]}],
 {j,Length[basis]}];
 <|"DataType"->"ResolvedOneLoopScalarEndpointPowers","DimensionalRegulator"->e,
  "NormalVariables"->xs,"CoefficientRowLabels"->labels,"Terms"->terms,
  "CausalPrescription"->1,"ConjugateInterferenceAdded"->False,
  "EndpointConditions"->conditions,"Normalization"->"FeynCalc scalar normalization including pi^(-epsilon)",
  "JointAnalyticFactorsVerified"->True,"CoincidentBubbleSubtractions"->coincident|>
],"OneLoopEndpoint"];

ConstructResolvedEndpointFaceProfiles[resolved_Association]:=Catch[Module[
 {terms,xs,e,labels,n,indices,slopes,classes,faces=<||>,profileGroups={},face,one,selected,values,rest,objects,profile},
 If[!TrueQ[Lookup[resolved,"JointAnalyticFactorsVerified",False]],
  loopEndpointFail["VerifiedAnalyticResolvedEndpointFactorsRequired"]];
 {terms,xs,e,labels}=Lookup[resolved,{"Terms","NormalVariables","DimensionalRegulator","CoefficientRowLabels"}];n=Length[xs];
 If[!AllTrue[Flatten[Lookup[terms,"Powers"]]/.e->0,IntegerQ[#]&&#>=-1&],
  loopEndpointFail["NoHigherThanSimpleResolvedCoordinatePolesRequired"]];
 slopes=Coefficient[#["Powers"],e]&/@terms;
 classes=DeleteDuplicates[slopes];
 Do[
  face=FeynFacet`ExpandAnalyticEndpointFaceJets[resolved,AssociationThread[xs[[s]],ConstantArray[0,Length[s]]]];
  If[FailureQ[face],loopEndpointFail["ExplicitResolvedFaceJetsRequired",<|"Cause"->face|>]];
  AssociateTo[faces,s->face],
 {s,Rest[Subsets[Range[n]]]}];
 Do[
  values=<||>;
  Do[
   one=ConstantArray[0,Length[labels]];rest=Complement[Range[n],s];
   Do[If[slopes[[j]]=!=class||!AllTrue[terms[[j]]["Powers"][[s]]/.e->0,#===-1&],Continue[]];
    profile=Lookup[faces[s]["Terms"][[j]]["NormalTaylorCoefficients"],Key[ConstantArray[0,Length[s]]]];
    one[[terms[[j]]["Row"]]]+=(Times@@MapThread[Power,{xs[[rest]],terms[[j]]["Powers"][[rest]]}])profile,
   {j,Length[terms]}];
   AssociateTo[values,s->AssociationThread[labels,one]],
  {s,Rest[Subsets[Range[n]]]}];
  AppendTo[profileGroups,<|"Powers"->(-1+e class),"FaceProfiles"->values|>],
 {class,classes}];
 <|"DataType"->"ResolvedEndpointFaceProfiles","DimensionalRegulator"->e,"NormalVariables"->xs,
  "CoefficientRowLabels"->labels,"ProfileGroups"->profileGroups,
  "EndpointConditions"->resolved["EndpointConditions"],"ConjugateInterferenceAdded"->False,
  "ExactInEpsilon"->True,"JointAnalyticFactorsVerified"->True|>
],"OneLoopEndpoint"];


VerifyResolvedEndpointCollars[resolved_Association,conditions_]:=Catch[Module[
 {xs,e,terms,faces,checks={},face,coefficients,field,restore,denominators,leading,power,rest,
  assumptions,units,arguments,analyticPowers,coefficient,value,normal,rank,factors,parameterConditions={}},
 If[!TrueQ[Lookup[resolved,"JointAnalyticFactorsVerified",False]],
  loopEndpointFail["VerifiedAnalyticResolvedEndpointFactorsRequired"]];
 {xs,e,terms}=Lookup[resolved,{"NormalVariables","DimensionalRegulator","Terms"}];
 Do[
  normal=xs[[i]];rest=Delete[xs,i];assumptions=(conditions/.normal->0)&&And@@(0<#<1&/@rest);
  face=FeynFacet`ExpandAnalyticEndpointFaceJets[resolved,<|normal->0|>];
  If[FailureQ[face],loopEndpointFail["CompleteResolvedFaceRestrictionRequired"]];
  coefficients=Flatten[Values[#["NormalTaylorCoefficients"]]&/@face["Terms"]];
  {field,restore}=coefficientRationalFieldReduce[coefficients];
  denominators=DeleteDuplicates[Denominator[Cancel[Together[#]]]&/@field];
  units=Table[power=Exponent[den,e,Min];If[!IntegerQ[power],loopEndpointFail["RationalRegulatorDenominatorRequired"]];
   Coefficient[den,e,power],{den,denominators}];
  factors=DeleteDuplicates[Flatten[First/@Rest[FactorList[#]]&/@units]];
  parameterConditions=Union[parameterConditions,
   (#!=0&/@Select[factors,FreeQ[#,Alternatives@@rest]&&!NumericQ[#]&])/.restore];
  units=Select[factors,!FreeQ[#,Alternatives@@rest]&];
  If[!AllTrue[units,TrueQ[TimeConstrained[FullSimplify[#!=0,Assumptions->assumptions],5,False]]&],
   loopEndpointFail["UniformOpenFaceDenominatorNotEstablished",<|"NormalVariable"->normal,"Factors"->units|>]];
  arguments=DeleteDuplicates[Cases[coefficients,Hypergeometric2F1[_,_,_,z_]:>z,{0,Infinity}]];
  If[!AllTrue[arguments,TrueQ[FullSimplify[#<1&&Element[#,Reals],Assumptions->assumptions]]&],
   loopEndpointFail["RealAnalyticGaussFaceBranchRequired",<|"NormalVariable"->normal,"Arguments"->arguments|>]];
  analyticPowers=DeleteDuplicates[Cases[coefficients,Power[b_,p_]/;!IntegerQ[p]&&!FreeQ[b,Alternatives@@rest]:>b,{0,Infinity}]];
  If[!AllTrue[analyticPowers,TrueQ[FullSimplify[#>0,Assumptions->assumptions]]&],
   loopEndpointFail["PositiveAnalyticOpenFacePowerBasesRequired",<|"NormalVariable"->normal|>]];
  AppendTo[checks,<|"NormalVariable"->normal,"NonzeroRationalUnits"->Length[units],
   "RealGaussArguments"->arguments,"PositivePowerBases"->analyticPowers,"Passed"->True|>],
 {i,Length[xs]}];
 <|"Status"->"AnalyticPhysicalEndpointCollarsVerified","JointCorner"->True,"OpenFaceChecks"->checks,
  "SimpleCoordinatePowers"->AllTrue[Flatten[Lookup[terms,"Powers"]]/.e->0,IntegerQ[#]&&#>=-1&],
  "ConvergenceArgument"->"Exact Gamma and analytically continued Gauss/Appell representations have finite meromorphic regulator poles. Analytic scalar factors on each corner and open-face collar admit ordinary tensor Taylor subtractions. Each subtracted coordinate contributes one positive integer power; complementary logarithms from regulator expansion remain locally integrable.",
  "Assumptions"->conditions,"NonzeroParameterConditions"->parameterConditions|>
],"OneLoopEndpoint"];

End[];EndPackage[];
