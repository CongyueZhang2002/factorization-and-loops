(* Standard GPL representations and their optional GiNaC evaluation.
   The original finite solution is retained; the extra expressions are finite,
   explicit, and reusable without running the differential equation. *)
FeynFacetSolution`ConvertMasterIntegralSolutionToGPL::usage="ConvertMasterIntegralSolutionToGPL[data,opts] converts the required finite integral definitions to explicit GPL expressions. Exact rational higher poles are reduced before words are expanded. Unsupported definitions remain in the original format and are reported.";
FeynFacetSolution`EvaluateGPLExpression::usage="EvaluateGPLExpression[expression,rules,opts] evaluates explicit GPLs through GiNaC at arbitrary working precision. Arguments on the straight integration contour are refused; this routine does not choose an i0 prescription.";
gplSource[data_]:=KeyTake[data,{"KinematicVariables","BasePoint","Path","AnalyticDomain",
 "BranchPrescription","KernelDefinitions","IntegralDefinitions"}];
gplDefinitionClosure[data_]:=Module[{aa=Lookup[data,"AlgebraicDefinitions",{}],
 ff=Lookup[data,"IntegralDefinitions",{}],neededA={},neededF={},visitA,visitF,visit,out},
 visitF[i_Integer]:=If[!MemberQ[neededF,i],
  If[!Between[i,{1,Length[ff]}],numericalFailure["IntegralDependencyInvalid"]];
  AppendTo[neededF,i];Scan[visitF,DeleteDuplicates[Cases[ff[[i,"Integrand"]],FeynFacetSolution`F[j_Integer,_]:>j,{0,Infinity}]]]];
 visitA[i_Integer]:=If[!MemberQ[neededA,i],
  If[!Between[i,{1,Length[aa]}],numericalFailure["ArithmeticDependencyInvalid"]];
  AppendTo[neededA,i];visit[aa[[i]]]];
 visit[z_]:=(Scan[visitA,DeleteDuplicates[Cases[z,FeynFacetSolution`a[j_Integer]:>j,{0,Infinity}]]];
   Scan[visitF,DeleteDuplicates[Cases[z,FeynFacetSolution`F[j_Integer,_]:>j,{0,Infinity}]]]);
 out={Lookup[data,"Coefficients",<||>],Lookup[data,"MasterIntegralCoefficients",<||>]};
 visit[out];<|"AlgebraicIndices"->Sort[neededA],"IntegralIndices"->Sort[neededF]|>
];
gplAssumptionsImpliedQ[prior_,current_]:=prior===True||prior===current||
 TrueQ[Refine[prior,current]];
(* Positive rescaling preserves the original approach to the lower endpoint.
   For a one-dimensional straight path it removes the variable endpoint from
   the rational alphabet, without changing the stored finite definitions. *)
gplAffinePathScale[data_,assumptions_,mode_]:=Module[{vars,base,path,t,delta,scale},
 If[mode===False,Return[1]];
 vars=Lookup[data,"KinematicVariables",{}];base=Lookup[data,"BasePoint",{}];
 path=Lookup[data,"Path",None];
 If[Length[vars]=!=1||Length[base]=!=1||!AssociationQ[path],
  If[mode===True,numericalFailure["OneDimensionalAffineGPLPathRequired"],Return[1]]];
 t=Lookup[path,"Parameter",None];delta=First[vars]-First[base];
 If[!MatchQ[t,_Symbol]||Lookup[path,"Coordinates",None]=!={First[base]+t delta},
  If[mode===True,numericalFailure["OneDimensionalAffineGPLPathRequired"],Return[1]]];
 scale=Which[TrueQ[Refine[delta>0,assumptions]],delta,
   TrueQ[Refine[delta<0,assumptions]],-delta,True,None];
 If[scale===None,If[mode===True,numericalFailure["PositiveGPLPathScaleNotEstablished"],1],scale]
];
Options[FeynFacetSolution`ConvertMasterIntegralSolutionToGPL]=Join[
 Options[FeynFacetSolution`IntegrateGPL],{"FunctionTimeLimit"->15,"Verbose"->False,
  "RescalePathParameter"->Automatic}];
FeynFacetSolution`ConvertMasterIntegralSolutionToGPL[data_Association,OptionsPattern[]]:=
 Module[
 {started=AbsoluteTime[],limits,fnSeconds=OptionValue["FunctionTimeLimit"],verbose=OptionValue["Verbose"],
  kd=Lookup[data,"KernelDefinitions",{}],fd=Lookup[data,"IntegralDefinitions",{}],
  converted=<||>,reused=0,repeated=0,integrated=0,failures={},closure,needed,parameter=Unique["gplParameter"],
  upper=FeynFacetSolution`s,expandKernel,integrateBody,body,dependencies,value,options,result,
  assumptions=OptionValue["Assumptions"],memoSettings,functionStarted,
  rescale=OptionValue["RescalePathParameter"],pathScale},
 limits=OptionValue["TimeLimit"];
 options=FilterRules[{"Assumptions"->assumptions,"MaxExpressionLeaves"->OptionValue["MaxExpressionLeaves"],
  "MaxTerms"->OptionValue["MaxTerms"],"MaxWeight"->OptionValue["MaxWeight"],
  "MaxPoleDegree"->OptionValue["MaxPoleDegree"],
  "MaxEndpointExpansionOrder"->OptionValue["MaxEndpointExpansionOrder"]},Options[FeynFacetSolution`IntegrateGPL]];
 memoSettings={assumptions,OptionValue["MaxExpressionLeaves"],OptionValue["MaxTerms"],
  OptionValue["MaxWeight"],OptionValue["MaxPoleDegree"],OptionValue["MaxEndpointExpansionOrder"]};
 integrateBody[z_]:=Module[{v},integrated++;
  v=FeynFacetSolution`IntegrateGPL[(z/.parameter->parameter/pathScale)/pathScale,
    {parameter,0,pathScale upper},"TimeLimit"->fnSeconds,Sequence@@options];
  If[!FailureQ[v],With[{answer=v},integrateBody[z]:=(repeated++;answer)]];v];
 result=gplWithMemoization[memoSettings,Catch[
  If[!NumericQ[limits]||limits<=0||!NumericQ[fnSeconds]||fnSeconds<=0||
    !MemberQ[{True,False},verbose]||!MemberQ[{Automatic,True,False},rescale]||!ListQ[kd]||!ListQ[fd]||
    !ListQ[Lookup[data,"AlgebraicDefinitions",None]]||
    !AssociationQ[Lookup[data,"Coefficients",None]],
   numericalFailure["InvalidGPLConversionInputOrOptions"]];
  validateFiniteDependencies[data];closure=gplDefinitionClosure[data];needed=closure["IntegralIndices"];
  pathScale=gplAffinePathScale[data,assumptions,rescale];
  If[gplRepresentationCurrentQ[data]&&
    gplAssumptionsImpliedQ[Lookup[data["GPLRepresentation"],"Assumptions",True],assumptions],
   converted=KeyTake[data["GPLRepresentation"]["IntegralExpressions"],needed];
   reused=Length[converted]];
  expandKernel[i_Integer]:=expandKernel[i]=Module[{z},
   z=kd[[i,"Expression"]]/.kd[[i,"Parameter"]]->parameter;
   z/.FeynFacetSolution`K[j_Integer,_]:>expandKernel[j]];
  Do[
   If[KeyExistsQ[converted,i],Continue[]];
   If[AbsoluteTime[]-started>limits,AppendTo[failures,<|"Index"->i,"Reason"->"ConversionTimeLimit"|>];Continue[]];
   dependencies=DeleteDuplicates[Cases[fd[[i,"Integrand"]],FeynFacetSolution`F[j_Integer,_]:>j,{0,Infinity}]];
   If[!AllTrue[dependencies,KeyExistsQ[converted,#]&],
    AppendTo[failures,<|"Index"->i,"Reason"->"EarlierIntegralNotConverted","Dependencies"->dependencies|>];Continue[]];
   If[TrueQ[verbose],Print["GPL integral ",i," of ",Length[fd]]];
   functionStarted=AbsoluteTime[];
   value=TimeConstrained[
    body=fd[[i,"Integrand"]]/.fd[[i,"IntegrationVariable"]]->parameter;
    body=body/.{FeynFacetSolution`K[j_Integer,_]:>expandKernel[j],
      FeynFacetSolution`F[j_Integer,_]:>(converted[j]/.upper->parameter)};
    integrateBody[body],
    Min[fnSeconds,Max[0.01,limits-(AbsoluteTime[]-started)]],Failure["GPLIntegrationTimeLimit",<||>]];
   If[TrueQ[verbose],Print["GPL integral ",i,": ",AbsoluteTime[]-functionStarted," s; ",
    If[FailureQ[value],value[[1]],ToString[LeafCount[value]]<>" leaves"]]];
   If[FailureQ[value],AppendTo[failures,<|"Index"->i,"Reason"->value[[1]],"Details"->value[[2]]|>],
    AssociateTo[converted,i->value]],
  {i,needed}];
  Join[KeyDrop[data,{"NumericalPreparation","GPLRepresentation"}],<|"GPLRepresentation"-><|
   "DataType"->"FiniteGPLRepresentation","SchemaVersion"->1,
   "Status"->If[failures==={},"RequiredIntegralsConvertedToGPL","PartiallyConvertedToGPL"],
   "SourceDefinitions"->gplSource[data],"Parameter"->upper,"Assumptions"->assumptions,
   "PathParameterScale"->pathScale,
   "RequiredIntegralIndices"->needed,"IntegralExpressions"->converted,
   "UnconvertedIntegrals"->failures,
   "FunctionConvention"->"G[{a1,...,an},z] with kernels dt/(t-ai); letters are constant in t.",
   "BranchConvention"->"Continuous branches along the stored ordinary-point path, fixed by the lower-end logarithms. No independent deformation of auxiliary integrals.",
   "CoefficientPrefactors"->"Original explicit prefactors are retained; GPL integrals alone do not classify those prefactors.",
   "ConversionSeconds"->AbsoluteTime[]-started,"ReusedIntegralExpressions"->reused,
   "RepeatedIntegrandsReused"->repeated,"DistinctIntegrandsAttempted"->integrated,
   "GPLCount"->Length[DeleteDuplicates[Cases[Values[converted],_FeynFacetSolution`G,Infinity]]],
   "MaximumGPLWeight"->Max[Append[Cases[Values[converted],FeynFacetSolution`G[w_List,_]:>Length[w],Infinity],0]]
  |>|>],"NumericalSolution"]];
 Clear[expandKernel,integrateBody];result
];
gplRepresentationCurrentQ[data_]:=Module[{rep=Lookup[data,"GPLRepresentation",None]},
 AssociationQ[rep]&&Lookup[rep,"DataType",None]==="FiniteGPLRepresentation"&&
 Lookup[rep,"SchemaVersion",None]===1&&
 Lookup[rep,"FunctionConvention",None]==="G[{a1,...,an},z] with kernels dt/(t-ai); letters are constant in t."&&
 Lookup[rep,"SourceDefinitions",None]===gplSource[data]];
gplCanEvaluate[data_]:=TrueQ[Catch[Module[{needed},
 If[!gplRepresentationCurrentQ[data],Return[False]];
 needed=gplDefinitionClosure[data]["IntegralIndices"];
 AllTrue[needed,KeyExistsQ[data["GPLRepresentation"]["IntegralExpressions"],#]&]
],"NumericalSolution"]];


FeynFacetSolution`MaterializeGPLExpressions::usage =
 "MaterializeGPLExpressions[data,expressions] resolves the stored finite-expression references to the already constructed standard GPLs. It performs no integration and rejects missing conversions.";
FeynFacetSolution`MaterializeGPLExpressions[data_Association,expressions_] := Catch[Module[
 {representation=Lookup[data,"GPLRepresentation",None],parameter,converted,aa,kd,
  resolve,resolveA,resolveF,resolveK,result},
 If[!gplRepresentationCurrentQ[data],numericalFailure["CurrentStoredGPLRepresentationRequired"]];
 parameter=representation["Parameter"];converted=representation["IntegralExpressions"];
 aa=data["AlgebraicDefinitions"];kd=data["KernelDefinitions"];
 resolveA[i_Integer]:=resolveA[i]=If[1<=i<=Length[aa],resolve[aa[[i]]],
  numericalFailure["GPLArithmeticReferenceInvalid"]];
 resolveF[i_Integer,arg_]:=If[KeyExistsQ[converted,i],
  resolve[converted[i]/.parameter->arg],numericalFailure["GPLIntegralNotConverted",<|"Index"->i|>]];
 resolveK[i_Integer,arg_]:=If[1<=i<=Length[kd],
  resolve[kd[[i,"Expression"]]/.kd[[i,"Parameter"]]->arg],
  numericalFailure["GPLKernelReferenceInvalid"]];
 resolve[x_]:=replaceFiniteExpressionReferences[x,{
  FeynFacetSolution`a[i_Integer]:>resolveA[i],
  FeynFacetSolution`F[i_Integer,arg_]:>resolveF[i,arg],
  FeynFacetSolution`K[i_Integer,arg_]:>resolveK[i,arg]}];
 result=resolve[expressions];
 result=result/.FeynFacetSolution`G[word_List,arg_]/;word=!={}&&AllTrue[word,#===0&]:>
   Log[arg]^Length[word]/Factorial[Length[word]];
 If[!FreeQ[result,_FeynFacetSolution`a|_FeynFacetSolution`F|_FeynFacetSolution`K],
  numericalFailure["GPLReferencesRemainUnresolved"]];
 result
],"NumericalSolution"];
