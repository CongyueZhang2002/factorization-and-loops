#!/usr/bin/env wolframscript
Get[DirectoryName[ExpandFileName[$InputFileName],3]<>"/FeynFacet/Core/RecordFormat.wl"];
(* Numerical boundary/reference data from auxiliary mass flow.
   All process definitions and external runtime paths are explicit inputs. *)
$HistoryLength=0;$PrePrint=.;
Get[FileNameJoin[{DirectoryName[ExpandFileName[$InputFileName],3],"FeynFacet","Interfaces","AMFlowRuntime.wl"}]];
args=Rest[$ScriptCommandLine];
If[Length[args]!=2,Print["Expected REQUEST.wl OUTPUT.wxf"];Exit[2]];
request=FeynFacetRecords`ReadRecord[args[[1]]];output=ExpandFileName[args[[2]]];
If[!DirectoryQ[DirectoryName[output]],CreateDirectory[DirectoryName[output],CreateIntermediateDirectories->True]];
(* AMFlow's working precision can exceed the accuracy requested of its fit.
   Preserve that distinction in the numerical coefficients supplied downstream. *)
capCoefficient[z_,digits_] := If[NumberQ[z]&&Precision[z]=!=Infinity,
 SetAccuracy[z,Min[Accuracy[z],digits-Log[10,1+Abs[z]]]],z];
definition=request["IntegralDefinition"];work=ExpandFileName[request["WorkingDirectory"]];
(* Reformat an already computed Laurent expansion without repeating AMFlow. *)
previous=If[FileExistsQ[output],Import[output,"WXF"],None];
If[AssociationQ[previous]&&Lookup[previous,"Status",None]==="AMFlowMastersEvaluated"&&
 Lookup[previous,"AMFlowOrderConvention",None]==="OffsetFromMinusTwoLoops"&&
 previous["IntegralDefinition"]===definition&&
 previous["Point"]===request["Point"]&&
 previous["KinematicVariables"]===request["KinematicVariables"]&&
 previous["OriginalMasterIntegralBasis"]===request["MasterIntegralBasis"]&&
 Lookup[request,"MasterIntegralPrefactors",ConstantArray[definition["MasterIntegralPrefactor"],Length[request["MasterIntegralBasis"]]]]===
 Lookup[previous,"MasterIntegralPrefactors",ConstantArray[definition["MasterIntegralPrefactor"],Length[previous["OriginalMasterIntegralBasis"]]]]&&
 previous["EpsilonOrder"]>=request["EpsilonOrder"]&&previous["PrecisionGoal"]>=Lookup[request,"PrecisionGoal",30],
 exportRows=Lookup[request,"RowIndices",Range[Length[request["MasterIntegralBasis"]]]];
 If[exportRows=!=previous["RowIndices"],Print["Cannot change row mapping of saved AMFlow data"];Exit[2]];
 exportLower=Lookup[request,"EpsilonLowerOrders",ConstantArray[-2 Length[definition["LoopMomenta"]],Length[exportRows]]];
 exportEps=previous["DimensionalRegulator"];exportUpper=previous["EpsilonOrder"];
 coefficients=Association@Table[q->MapThread[#1->capCoefficient[Coefficient[#2,exportEps,q],previous["PrecisionGoal"]]&,
  {exportRows,previous["MasterIntegralValues"]}],{q,Min[exportLower],exportUpper}];
 constants=Flatten[Table[Table[FeynFacetSolution`C[exportRows[[i]],q]->
  capCoefficient[Coefficient[previous["MasterIntegralValues"][[i]],exportEps,q],previous["PrecisionGoal"]],
  {q,exportLower[[i]],exportUpper}],{i,Length[exportRows]}]];
 result=Join[previous,<|"MasterIntegralEpsilonCoefficients"->coefficients,
  "InitialConstantValues"->constants,"ReusedComputedLaurentExpansion"->True|>];
 Export[output<>".tmp",result,"WXF"];RenameFile[output<>".tmp",output,OverwriteTarget->True];
 Print["RESULT AMFlow Laurent coefficients re-exported without recomputation"];Exit[0];
];
If[!DirectoryQ[work],CreateDirectory[work,CreateIntermediateDirectories->True]];
reuseCompletedSystems=TrueQ[Lookup[request,"ReuseCompletedAMFlowSystems",True]];
If[reuseCompletedSystems,FeynFacetAMFlowRuntime`Private`indexCompletedAMFlowSystems[work]];
runtime=FeynFacetAMFlowRuntime`Private`selectAMFlowRuntime[request];
If[FailureQ[runtime],Print[runtime];Exit[2]];
request=Join[request,runtime];solver=runtime["AMFlowDESolver"];
Print["AMFLOW RUNTIME ",runtime];
If[!And@@(FileExistsQ/@{FileNameJoin[{request["AMFlowPath"],"AMFlow.m"}],
 request["KiraExecutable"],request["FermatExecutable"]}),
 Print["RESULT AMFlow runtime or IBP executable unavailable"];Exit[2]];
Get[FileNameJoin[{request["AMFlowPath"],"AMFlow.m"}]];
SetReductionOptions["IBPReducer"->"Kira"];
Kira`$KiraExecutable=request["KiraExecutable"];
Kira`$FermatExecutable=request["FermatExecutable"];
useMaximalCut=Lookup[request,"UseMaximalCut",Automatic];
If[useMaximalCut===Automatic,useMaximalCut=Lookup[request,"Threads",1]>1];
If[!MemberQ[{True,False},useMaximalCut],Print["UseMaximalCut must be Automatic, True or False"];Exit[2]];
SetReducerOptions["ReductionMode"->Lookup[request,"ReductionMode","Kira"],
 "UseMaximalCut"->useMaximalCut];
SetAMFOptions["DESolver"->solver,"UseCache"->True,
 "SkipReduction"->TrueQ[Lookup[request,"SkipTargetReduction",False]]];
toPolynomial[z_] := Expand[z/.FeynCalc`Pair[
 FeynCalc`Momentum[a_,___],FeynCalc`Momentum[b_,___]]:>a b];
result=CheckAbort[TimeConstrained[Catch[Module[
 {family,masters,powers,rows,e,point,vars,rules,goal,upper,lower,raw,values,
  coefficients,constants,extra,valuation,nativeOrder,expansionOrder,propagators,momenta,types,square,massRemainder,now=AbsoluteTime[],d0},
 e=definition["DimensionalRegulator"];point=request["Point"];vars=request["KinematicVariables"];
 If[Lookup[request,"WolframScriptExecution","Subprocess"]==="CurrentKernel"&&Lookup[request,"Threads",1]=!=1,
  Throw[Failure["OneThreadRequiredForCurrentKernelAMFlowScripts",<||>]]];
 If[Lookup[definition,"MomentumSpaceConvention",None]=!="AMFlow",
  Throw[Failure["AMFlowNormalizationRequired",<||>]]];
 masters=request["MasterIntegralBasis"];powers=Last/@masters;
 family=First[First[masters]];rows=Lookup[request,"RowIndices",Range[Length[masters]]];
 If[!AllTrue[masters,First[#]===family&]||Length[rows]!=Length[masters],
  Throw[Failure["MasterBasisMismatch",<||>]]];
 family=If[StringQ[family],Symbol["Global`"<>family],family];
 rules=Thread[vars->point];goal=Lookup[request,"PrecisionGoal",30];upper=request["EpsilonOrder"];
 lower=Lookup[request,"EpsilonLowerOrders",ConstantArray[-2 Length[definition["LoopMomenta"]],Length[masters]]];
 d0=definition["Dimension"]/.e->0;
 If[!IntegerQ[d0]||Expand[definition["Dimension"]-d0+2 e]=!=0,
  Throw[Failure["AMFlowDimensionConventionUnsupported",<||>]]];
 SetAMFOptions["D0"->d0];
 extra=Lookup[request,"MasterIntegralPrefactors",
   ConstantArray[definition["MasterIntegralPrefactor"],Length[masters]]]/.rules;
 valuation[z_] := If[z===0,Infinity,With[{a=Together[z]},
  Exponent[Numerator[a],e,Min]-Exponent[Denominator[a],e,Min]]];
 If[!VectorQ[extra,NumericQ[#/.e->1/101]&],
  Throw[Failure["MasterPrefactorNotSpecifiedNumerically",<||>]]];
 nativeOrder=upper-Min[valuation/@extra];
 If[!IntegerQ[nativeOrder],Throw[Failure["MasterPrefactorLaurentOrderUnresolved",<||>]]];
 (* The vendor order counts from its fixed Laurent lower order -2 L. *)
 expansionOrder=Max[0,nativeOrder+2 Length[definition["LoopMomenta"]]];
 AMFlowInfo["Family"]=family;
 AMFlowInfo["Loop"]=definition["LoopMomenta"];
 AMFlowInfo["Leg"]=definition["ExternalMomenta"];
 AMFlowInfo["Conservation"]={};
 AMFlowInfo["Replacement"]=toPolynomial/@definition["KinematicRules"];
 propagators=toPolynomial/@definition["InversePropagators"];
 momenta=Lookup[definition,"PropagatorMomenta",ConstantArray[Missing[],Length[propagators]]];
 types=Lookup[definition,"PropagatorTypes",ConstantArray[None,Length[propagators]]];
 (* AMFlow matches cuts before applying external scalar-product rules in
    ReduceBoundary. Restore q^2-m^2 from the retained momentum routing;
    the stored inverse propagators may already contain those rules. *)
 Do[If[types[[i]]==="QuadraticLorentzian"&&!MissingQ[momenta[[i]]],
   square=Expand[momenta[[i]]^2];
   massRemainder=Cancel[Expand[(propagators[[i]]-square)/.AMFlowInfo["Replacement"]]];
   If[!FreeQ[massRemainder,Alternatives@@Join[definition["LoopMomenta"],definition["ExternalMomenta"]]],
    Throw[Failure["AMFlowQuadraticMomentumMismatch",<|"PropagatorIndex"->i,"Remainder"->massRemainder|>]]];
   propagators[[i]]=Expand[square+massRemainder]],{i,Length[propagators]}];
 AMFlowInfo["Propagator"]=propagators;
 AMFlowInfo["Numeric"]=rules;
 AMFlowInfo["Prescription"]=definition["Prescription"];
 AMFlowInfo["Cut"]=Boole[MemberQ[definition["CutIndices"],#]]& /@ Range[Length[First[powers]]];
 AMFlowInfo["NThread"]=Lookup[request,"Threads",1];
 Print["AMFLOW ",family," point ",point," masters ",Length[masters]," upper epsilon power ",nativeOrder," AMFlow expansion order ",expansionOrder];
 raw=FeynFacet`Private`withAMFlowKernelRelease[Block[{AMFlow`CacheDirectory},
  AMFlow`CacheDirectory[key_] := FileNameJoin[{work,"cache",ToString[family,InputForm]<>"_"<>key}];
  SolveIntegrals[(Global`j[family,Sequence@@#]& /@ powers),goal,expansionOrder]],
  Lookup[request,"WolframScriptExecution","Subprocess"]==="CurrentKernel",solver,
  reuseCompletedSystems];
 values=(Global`j[family,Sequence@@#]& /@ powers)/.raw;
 If[!FreeQ[values,_Global`j],Throw[Failure["AMFlowDidNotReturnAllMasters",<||>]]];
 values=values/.s_Symbol /; MemberQ[{"eps","ep","Epsilon"},SymbolName[s]]:>e;
 values=MapThread[Normal[Series[Normal[#1] #2,{e,0,upper}]]&,{values,extra}];
 coefficients=Association@Table[q->MapThread[#1->capCoefficient[Coefficient[#2,e,q],goal]&,{rows,values}],
  {q,Min[lower],upper}];
 constants=Flatten[Table[Table[FeynFacetSolution`C[rows[[i]],q]->capCoefficient[Coefficient[values[[i]],e,q],goal],
   {q,lower[[i]],upper}],{i,Length[rows]}]];
 If[!And@@(NumberQ[Last[#]]& /@ constants),Throw[Failure["AMFlowCoefficientsNotNumeric",<||>]]];
 <|"Status"->"AMFlowMastersEvaluated","Family"->family,"Point"->point,
  "KinematicVariables"->vars,"OriginalMasterIntegralBasis"->masters,"RowIndices"->rows,
  "DimensionalRegulator"->e,"EpsilonOrder"->upper,"PrecisionGoal"->goal,
  "AMFlowOrderConvention"->"OffsetFromMinusTwoLoops","AMFlowExpansionOrder"->expansionOrder,
  "NativeEpsilonUpperOrder"->nativeOrder,"AMFlowDESolver"->solver,
  "SkipTargetReduction"->TrueQ[Lookup[request,"SkipTargetReduction",False]],
  "UseMaximalCut"->useMaximalCut,
  "CompletedSystemReuseEnabled"->reuseCompletedSystems,
  "AMFlowRuntimePath"->request["AMFlowPath"],
  "AMFlowNativeBuild"->If[solver==="CPP"&&FileExistsQ[request["AMFlowPath"]<>"/feynfacet_native_build.json"],
    Import[request["AMFlowPath"]<>"/feynfacet_native_build.json","RawJSON"],None],
  "InitialConstantValues"->constants,"MasterIntegralEpsilonCoefficients"->coefficients,
  "MomentumSpaceConvention"->"AMFlow","IntegralDefinition"->definition,
  "MasterIntegralValues"->values,"MasterIntegralPrefactors"->Lookup[request,"MasterIntegralPrefactors",ConstantArray[definition["MasterIntegralPrefactor"],Length[masters]]],"ElapsedSeconds"->AbsoluteTime[]-now|>
]],Lookup[request,"TimeLimit",900],Failure["AMFlowEvaluationTimeLimit",<||>]],
 Failure["AMFlowEvaluationAborted",<||>]];
If[FailureQ[result]&&AssociationQ[previous],output=output<>".failure.wxf"];
Export[output<>".tmp",result,"WXF"];RenameFile[output<>".tmp",output,OverwriteTarget->True];
Print["RESULT ",If[AssociationQ[result],KeyTake[result,{"Status","Family","Point","ElapsedSeconds"}],result]];
Exit[If[AssociationQ[result]&&result["Status"]==="AMFlowMastersEvaluated",0,1]];
