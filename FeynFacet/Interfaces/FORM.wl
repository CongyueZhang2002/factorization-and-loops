(* FORM is an algebra backend only. Propagator objects and non-tensor scalar
   factors remain opaque. Nonchiral mode uses ordinary D-dimensional traces.
   BMHV mode lowers gamma5 to its physical epsilon definition and contracts
   explicit rank-four projectors in the ambient D-dimensional index space. *)
BeginPackage["FeynFacet`"];
EvaluateFORMDiracExpression::usage="EvaluateFORMDiracExpression[expression,request] evaluates exact Dirac and Lorentz algebra with FORM. Request declares Momenta and PhysicalMomenta. Gamma5Scheme defaults to Nonchiral; BMHV uses an explicit rank-four physical projector and the Minkowski gamma5 definition, retaining full-D and projected scalar products separately. The BMHV route requires FeynCalc BMHV and LeviCivitaSign -1. Propagators and scalar normalization factors are preserved exactly.";

Begin["`Private`"];
formAlgebraFail[tag_,data_:<||>]:=Throw[Failure[tag,data],"FORMAlgebra"];
(* Native threads use the process CPU allocation. Unmanaged Wolfram workers
   stay serial; managed amplitude workers share one exclusive native allocation
   so a long final trace can use all available cores without multiplying pools. *)
formAlgebraExecution[request_Association] := Module[
 {binary,parallel,threads,automatic,budgetText,budget,worker,shared},
 binary=Lookup[request,"Executable",FileNameJoin[{$feynFacetAddonRoot,"Addon","Other_Addon","FORM","bin","form"}]];
 If[!StringQ[binary]||!FileExistsQ[binary],
  formAlgebraFail["FORMExecutableMissing",<|"Installer"->"Scripts/Setup/install_form.py"|>]];
 worker=TrueQ[$KernelID>0];
 shared=If[worker&&AssociationQ[$formParallelExecution],$formParallelExecution,None];
 budgetText=Environment["FACET_CPU_COUNT"];
 budget=If[StringQ[budgetText]&&StringMatchQ[budgetText,DigitCharacter..],
   Min[8,Max[1,FromDigits[budgetText]]],1];
 If[worker,If[AssociationQ[shared],
   If[!IntegerQ[Lookup[shared,"Threads",None]]||!TrueQ[1<=shared["Threads"]<=budget]||
      !StringQ[Lookup[shared,"LockFile",None]],formAlgebraFail["ManagedFORMAllocationRequired"]];
   budget=shared["Threads"],budget=1]];
 threads=Lookup[request,"Threads",Automatic];automatic=threads===Automatic;
 If[automatic,threads=If[KeyExistsQ[request,"Executable"],1,budget]];
 If[!IntegerQ[threads]||!TrueQ[1<=threads<=budget],
  formAlgebraFail["FORMThreadsExceedAllocatedBudget",<|"Requested"->threads,"Available"->budget|>]];
 If[threads>1,
  parallel=FileNameJoin[{DirectoryName[binary],"tform"}];
  If[!FileExistsQ[parallel],
   If[automatic,threads=1,formAlgebraFail["ParallelFORMExecutableMissing"]],
   binary=parallel]];
 <|"Executable"->binary,"Threads"->threads,
  "LockFile"->If[AssociationQ[shared],shared["LockFile"],None],
  "Arguments"->Join[{binary},If[FileNameTake[binary]==="tform",{"-w"<>ToString[threads-1]},{}],{"-q","job.frm"}]|>
];
formAlgebraRun[execution_Association,directory_String] := Module[{locker=None,lock=execution["LockFile"]},
 Internal`WithLocalSettings[
  If[StringQ[lock],
   locker=StartProcess[{"python3",FileNameJoin[{$feynFacetWorkspaceRoot,"Scripts","raw_result_lock.py"}],lock}];
   If[!MatchQ[locker,_ProcessObject],formAlgebraFail["FORMAllocationLockProcessRequired"]]],
  If[locker=!=None&&ReadLine[locker]=!="LOCKED",formAlgebraFail["FORMAllocationLockFailed"]];
  RunProcess[execution["Arguments"],All,ProcessDirectory->directory,
   ProcessEnvironment-><|"OMP_NUM_THREADS"->"1"|>],
  If[MatchQ[locker,_ProcessObject],Quiet[KillProcess[locker]]]]
];
(* Index-set restrictions matter: an index wildcard can also match a vector.
   A repeated vector argument is not an Einstein index contraction. *)
formPhysicalTensorStatements[indexNames_,vectorNames_,barNames_,genericEpsilon_:True]:=Module[
 {full=Values[vectorNames],bar=Values[barNames],vectors,projected,permutations,determinant,slotA,slotB},
 vectors=DeleteDuplicates[Join[full,bar]];
 projected=AssociationThread[Join[full,bar],Join[bar,bar]];
 slotA={"fA1","fA2","fA3","fA4"};slotB={"fB1i","fB2i","fB3i","fB4i"};
 permutations=Permutations[Range[4]];
 determinant=StringRiffle[Table[
  If[Signature[permutation]===1,"-","+"]<>
   StringRiffle[MapThread["fP4("<>#1<>","<>#2<>")"&,{slotA,slotB[[permutation]]}],"*"],
 {permutation,permutations}],""];
 Join[
  {"repeat;",
   "id fE4(fA1?fIndices,fA2?fIndices,fA3?fIndices,fA4?fIndices)^2=-24;",
   "id fE4(fA1?fIndices,fA2?fIndices,fA3?fIndices,fA4?)*fE4(fA1?fIndices,fA2?fIndices,fA3?fIndices,fB1i?)=-6*fP4(fA4,fB1i);",
   "id fE4(fA1?fIndices,fA2?fIndices,fA3?,fA4?)*fE4(fA1?fIndices,fA2?fIndices,fB1i?,fB2i?)=-2*(fP4(fA3,fB1i)*fP4(fA4,fB2i)-fP4(fA3,fB2i)*fP4(fA4,fB1i));",
   "id fE4(fA1?fIndices,fA2?,fA3?,fA4?)*fE4(fA1?fIndices,fB1i?,fB2i?,fB3i?)=-(fP4(fA2,fB1i)*fP4(fA3,fB2i)*fP4(fA4,fB3i)+fP4(fA2,fB2i)*fP4(fA3,fB3i)*fP4(fA4,fB1i)+fP4(fA2,fB3i)*fP4(fA3,fB1i)*fP4(fA4,fB2i)-fP4(fA2,fB3i)*fP4(fA3,fB2i)*fP4(fA4,fB1i)-fP4(fA2,fB2i)*fP4(fA3,fB1i)*fP4(fA4,fB3i)-fP4(fA2,fB1i)*fP4(fA3,fB3i)*fP4(fA4,fB2i));",
   If[TrueQ[genericEpsilon],"id fE4(fA1?,fA2?,fA3?,fA4?)*fE4(fB1i?,fB2i?,fB3i?,fB4i?)="<>determinant<>";",Nothing],
   "id fP4(fA1?fIndices,fA1?fIndices)=4;",
   "id fP4(fA1?,fA2?fIndices)*fE4(fA2?fIndices,fA3?,fA4?,fB1i?)=fE4(fA1,fA3,fA4,fB1i);",
   "id fP4(fA1?,fA2?fIndices)*fP4(fA2?fIndices,fA3?)=fP4(fA1,fA3);",
   "endrepeat;"},
  Flatten[Table["id fP4("<>vectors[[i]]<>","<>vectors[[j]]<>")="<>projected[vectors[[i]]]<>"."<>projected[vectors[[j]]]<>";",
   {i,Length[vectors]},{j,i,Length[vectors]}]],
  Table["id fP4(fA1?fIndices,"<>v<>")="<>projected[v]<>"(fA1);",{v,vectors}],
  Table["id fE4("<>v<>",fA1?,fA2?,fA3?)=fE4("<>projected[v]<>",fA1,fA2,fA3);",
   {v,Select[vectors,projected[#]=!=#&]}],
  Flatten[Table[If[(MemberQ[bar,vectors[[i]]]||MemberQ[bar,vectors[[j]]])&&
    Sort[{vectors[[i]],vectors[[j]]}]=!=Sort[{projected[vectors[[i]]],projected[vectors[[j]]]}],
    "id "<>vectors[[i]]<>"."<>vectors[[j]]<>"="<>projected[vectors[[i]]]<>"."<>projected[vectors[[j]]]<>";",Nothing],
   {i,Length[vectors]},{j,i,Length[vectors]}]]]
];
(* Contract only a full-D Einstein pair inside the gamma5-last word.
   The interior interval never crosses gamma5. Physical projector links remain
   explicit and are not mistaken for full-D repeated indices. *)
formGammaPairStatements[]:=Module[{args,word,rules,pattern,rhs,terms},
 word[list_]:="fT5("<>StringRiffle[Join[{"?a"},list,{"?b"}],","]<>")";
 rules=Table[
  args=Table["fC"<>ToString[j],{j,n}];
  pattern="id fT5("<>StringRiffle[Join[{"?a","fA1?fIndices"},(#<>"?"&/@args),{"fA1?fIndices","?b"}],","]<>")=";
  rhs=Which[
   n===0,"fD*"<>word[{}],
   n===1,"(2-fD)*"<>word[args],
   n===2,"(fD-4)*"<>word[args]<>"+4*d_(fC1,fC2)*"<>word[{}],
   n===3,"(4-fD)*"<>word[args]<>"-2*"<>word[Reverse[args]],
   True,
    terms=Join[{If[EvenQ[n],"","-"]<>"(fD-2)*"<>word[args]},
     Table[If[OddQ[j],"+2*","-2*"]<>word[Append[Delete[args,j],args[[j]]]],{j,n-1}]];
    StringJoin[terms]];
  pattern<>rhs<>";",{n,0,10}];
 Join[{"repeat;"},rules,{"endrepeat;","id fT5()=0;","id fT5(fA1?)=0;",
   "id fT5(fA1?,fA2?)=0;","id fT5(fA1?,fA2?,fA3?)=0;"}]
];
EvaluateFORMDiracExpression[expression_,request_Association]:=Catch[Module[
 {momenta,physical,internal,indices,traces,scalarObjects={},scalarIndex=<||>,vectorNames,indexNames,
  traceNames,scalarName,number,vector,index,gamma,serialize,component,scalarProduct,sum,definitions,resultText,
  scalarNames,program,binary,execution,temporary,process,output,parsed,parseContext,vectorSymbols,indexSymbols,
  scalarSymbols,metricSymbol,dimensionSymbol,allowed,symbols,converted,seconds,atoms,conversionRules,
  massless,kinematics,kinematicStatements,bmhv,barNames,barVectorSymbols,freshIndex,
  epsilonTensor,epsilonArgument,physicalStatements,projectorSymbol,epsilonSymbol,
  tensorStatements,allVectorNames,slotNames,traceMethod,chiralTraces,chiralValues,traceSeconds=0,traceSerialize,words,wordProduct,gradeTrace,gammaArgumentTerms,linearStatements,linearVectors,registerVector,postTraceStatements,sharedPhysicalStatements,gradeStatements,tracePolynomial,traceVariables,inlineTraces,traceStatements,conjugateGamma,reduceGammaPairs,physicalGammaQ,gammaPairCost},
 momenta=Lookup[request,"Momenta",{}];physical=Lookup[request,"PhysicalMomenta",{}];
 If[!MatchQ[momenta,{_Symbol..}]||!DuplicateFreeQ[momenta]||
  !MatchQ[physical,{_Symbol...}]||!ContainsAll[momenta,physical],
  formAlgebraFail["DeclaredFORMMomentaRequired"]];
 bmhv=Lookup[request,"Gamma5Scheme","Nonchiral"]==="BMHV";
 If[!MemberQ[{"Nonchiral","BMHV"},Lookup[request,"Gamma5Scheme","Nonchiral"]],
  formAlgebraFail["FORMGamma5SchemeUnsupported"]];
 If[bmhv&&(FeynCalc`FCGetDiracGammaScheme[]=!="BMHV"||FeynCalc`$LeviCivitaSign=!=-1),
  formAlgebraFail["BMHVWithDeclaredMinkowskiEpsilonConventionRequired"]];
 internal=FeynCalc`FCI[expression];
 If[!FreeQ[internal,_Real|_Failure|$Failed|$Aborted]||
   (!bmhv&&!FreeQ[internal,FeynCalc`DiracGamma[5|6|7]|_FeynCalc`Eps]),
  formAlgebraFail["NonchiralExactDiracExpressionRequired"]];
 traceMethod=Lookup[request,"Gamma5TraceMethod","GradeFour"];
 If[!MemberQ[{"Definition","FeynCalc","GradeFour"},traceMethod],formAlgebraFail["FORMGamma5TraceMethodUnsupported"]];
 If[bmhv&&traceMethod==="FeynCalc",
  chiralTraces=Select[DeleteDuplicates[Cases[internal,_FeynCalc`DiracTrace,{0,Infinity}]],
   !FreeQ[#,FeynCalc`DiracGamma[5|6|7]]&];
  If[chiralTraces=!={},
   If[StringQ[Lookup[request,"DiagnosticDirectory",None]],
    If[!DirectoryQ[request["DiagnosticDirectory"]],CreateDirectory[request["DiagnosticDirectory"],CreateIntermediateDirectories->True]];
    Export[FileNameJoin[{request["DiagnosticDirectory"],"ChiralTraceInputs.wxf"}],chiralTraces,"WXF"]];
   {traceSeconds,chiralValues}=AbsoluteTiming[partonicTraceValues[chiralTraces,Lookup[request,"KernelCount",1]]];
   If[!ListQ[chiralValues]||Length[chiralValues]=!=Length[chiralTraces]||
      !FreeQ[chiralValues,_FeynCalc`DiracTrace|_Failure|$Failed|$Aborted],
    formAlgebraFail["BMHVChiralTraceEvaluationFailed"]];
   If[StringQ[Lookup[request,"DiagnosticDirectory",None]],
    Export[FileNameJoin[{request["DiagnosticDirectory"],"ChiralTraceValues.wxf"}],chiralValues,"WXF"]];
   internal=internal/.Dispatch[Thread[chiralTraces->chiralValues]];
   Print["FeynCalc BMHV trace evaluation: ",traceSeconds," s; ",Length[chiralTraces]," distinct traces"]]];
 indices=DeleteDuplicates[Cases[internal,FeynCalc`LorentzIndex[i_,___]:>i,Infinity]];
 If[!FreeQ[indices,_Real|_Failure|_Missing]||!AllTrue[Cases[internal,_FeynCalc`LorentzIndex,Infinity],
   MemberQ[If[bmhv,{D,4,D-4},{D,4}],If[Length[#]===1,4,Last[#]]]&],
  formAlgebraFail["FORMIndexDimensionUnsupported"]];
 vectorNames=AssociationThread[momenta,Table["fV"<>ToString[i],{i,Length[momenta]}]];
 indexNames=AssociationThread[indices,Table["fI"<>ToString[i],{i,Length[indices]}]];
 barNames=AssociationThread[momenta,MapIndexed[
  If[MemberQ[physical,#1],vectorNames[#1],"fB"<>ToString[First[#2]]]&,momenta]];
 freshIndex[]:=Module[{symbol=Unique["formPhysicalIndex$"],name},
  name="fI"<>ToString[Length[indexNames]+1];AssociateTo[indexNames,symbol->name];name];
 traces=DeleteDuplicates[Cases[internal,_FeynCalc`DiracTrace,{0,Infinity}]];
 traceNames=AssociationThread[traces,Table["T"<>ToString[i],{i,Length[traces]}]];
 number[n_Integer]:=ToString[n,InputForm];
 number[n_Rational]:="("<>ToString[Numerator[n]]<>"/"<>ToString[Denominator[n]]<>")";
 scalarName[value_]:=Module[{name},
  If[value===D,Return["fD"]];
  If[KeyExistsQ[scalarIndex,value],Return[scalarIndex[value]]];
  AppendTo[scalarObjects,value];name="fS"<>ToString[Length[scalarObjects]];
  AssociateTo[scalarIndex,value->name];name];
 registerVector[m_]:=Module[{name,isPhysical},
  If[KeyExistsQ[vectorNames,m],Return[Null]];
  name="fL"<>ToString[Length[vectorNames]+1];
  isPhysical=physical=!={}&&PolynomialQ[m,physical]&&TrueQ[(m/.Thread[physical->0])===0]&&
   AllTrue[First/@CoefficientRules[m,physical],Total[#]<=1&];
  AssociateTo[vectorNames,m->name];
  AssociateTo[barNames,m->If[isPhysical,name,"fBL"<>ToString[Length[vectorNames]]]]];
 vector[FeynCalc`Momentum[m_,dim_:4]]:=Module[{basis,coefficients,scale,canonical,names},
  If[bmhv&&dim===D-4,Return[Join[vector[FeynCalc`Momentum[m,D]],
    ({("-1*"<>#[[1]]),#[[2]]}&/@vector[FeynCalc`Momentum[m]])]]];
  basis=If[dim===D,momenta,If[dim===4,If[bmhv,momenta,physical],
    formAlgebraFail["FORMMomentumDimensionUnsupported"]]];
  If[basis==={}||!PolynomialQ[m,basis]||!TrueQ[(m/.Thread[basis->0])===0]||
   !AllTrue[First/@CoefficientRules[m,basis],Total[#]<=1&],
   formAlgebraFail["FORMMomentumOutsideDeclaredSpan",<|"Momentum"->m,"Dimension"->dim|>]];
  coefficients=Coefficient[m,#]&/@basis;
  scale=FirstCase[coefficients,value_/;value=!=0,1];
  If[!MatchQ[scale,_Integer|_Rational],scale=1];
  canonical=Expand[m/scale];If[canonical===0,Return[{}]];
  registerVector[canonical];names=If[bmhv&&dim===4,barNames,vectorNames];
  {{serialize[scale],names[canonical]}}];
 sum[terms_List]:="("<>StringRiffle[Prepend[terms,"0"],"+"]<>")";
 (* Pair automatically writes a physical vector component with a 4D
    index. It can use the D-dimensional index here because the vector itself
    is verified to lie in the declared physical span. A projected integrated
    vector or a free four-dimensional metric is not admitted. *)
 component[m_,i_]:=sum[(#[[1]]<>"*"<>#[[2]]<>"("<>index[i]<>")")&/@vector[
   If[Length[i]===1||Last[i]===4,FeynCalc`Momentum[First[m]],If[Last[i]===D-4,FeynCalc`Momentum[First[m],D-4],m]]]];
 scalarProduct[a_,b_]:=sum[(#[[1,1]]<>"*"<>#[[2,1]]<>"*("<>#[[1,2]]<>"."<>#[[2,2]]<>")")&/@Tuples[{vector[a],vector[b]}]];
 index[FeynCalc`LorentzIndex[i_,___]]:=indexNames[i];
 gamma[FeynCalc`DiracGamma[arg_,dim_:4]]:=Module[{slots,extra},
  Which[
   bmhv&&arg===5,slots=Table[freshIndex[],{4}];
    "(-i_/24)*fE4("<>StringRiffle[slots,","]<>")*g_(1,"<>StringRiffle[slots,","]<>")",
   bmhv&&MemberQ[{6,7},arg],
    "((gi_(1)"<>If[arg===6,"+","-"]<>gamma[FeynCalc`DiracGamma[5]]<>")/2)",
   !MemberQ[If[bmhv,{D,4,D-4},{D,4}],dim],formAlgebraFail["FORMGammaDimensionUnsupported"],
   MatchQ[arg,_FeynCalc`Momentum],
    sum[(#[[1]]<>"*g_(1,"<>#[[2]]<>")")&/@vector[FeynCalc`Momentum[First[arg],dim]]],
   bmhv&&MemberQ[{4,D-4},dim]&&MatchQ[arg,_FeynCalc`LorentzIndex],
    extra=freshIndex[];
    "(" <>If[dim===D-4,"g_(1,"<>index[arg]<>")-",""]<>
     "fP4("<>index[arg]<>","<>extra<>")*g_(1,"<>extra<>"))",
   dim===D&&MatchQ[arg,FeynCalc`LorentzIndex[_,D]],"g_(1,"<>index[arg]<>")",
   True,formAlgebraFail["FORMGammaArgumentUnsupported"]]];
 epsilonArgument[object_FeynCalc`Momentum]:=vector[object];
 epsilonArgument[object_FeynCalc`LorentzIndex]:={{"1",index[object]}};
 epsilonTensor[object_FeynCalc`Eps]:=Module[{terms=Tuples[epsilonArgument/@List@@object]},
  sum[(StringRiffle[#[[All,1]],"*"]<>"*fE4("<>StringRiffle[#[[All,2]],","]<>")")&/@terms]];
 serialize[value_]:=Which[
  IntegerQ[value]||Head[value]===Rational,number[value],
  Head[value]===FeynCalc`FeynAmpDenominator,scalarName[value],
  Head[value]===FeynCalc`DiracTrace,traceNames[value],
  Head[value]===FeynCalc`DiracGamma,gamma[value],
  bmhv&&Head[value]===FeynCalc`Eps,epsilonTensor[value],
  Head[value]===Plus,"("<>StringRiffle[serialize/@(List@@value),"+"]<>")",
  MemberQ[{Times,FeynCalc`DOT,Dot},Head[value]],"("<>StringRiffle[serialize/@(List@@value),"*"]<>")",
  Head[value]===Power&&IntegerQ[value[[2]]]&&value[[2]]<0&&
    FreeQ[value[[1]],_FeynCalc`LorentzIndex|_FeynCalc`DiracTrace|_FeynCalc`DiracGamma],
   scalarName[value],
  Head[value]===Power&&IntegerQ[value[[2]]],"("<>serialize[value[[1]]]<>")^"<>number[value[[2]]],
  MatchQ[value,FeynCalc`Pair[_FeynCalc`LorentzIndex,_FeynCalc`LorentzIndex]],
   Which[
    AllTrue[List@@value,MatchQ[#,FeynCalc`LorentzIndex[_,D]]&],
     "d_("<>index[value[[1]]]<>","<>index[value[[2]]]<>")",
    bmhv&&AllTrue[List@@value,MatchQ[#,FeynCalc`LorentzIndex[_,D-4]]&],
     "(d_("<>index[value[[1]]]<>","<>index[value[[2]]]<>")-fP4("<>index[value[[1]]]<>","<>index[value[[2]]]<>"))",
    bmhv,"fP4("<>index[value[[1]]]<>","<>index[value[[2]]]<>")",
    True,formAlgebraFail["UnrestrictedPhysicalProjectorRequiresBMHVBackend"]],
  MatchQ[value,FeynCalc`Pair[_FeynCalc`Momentum,_FeynCalc`Momentum]],
   scalarProduct[value[[1]],value[[2]]],
  MatchQ[value,FeynCalc`Pair[_FeynCalc`LorentzIndex,_FeynCalc`Momentum]],
   component[value[[2]],value[[1]]],
  MatchQ[value,FeynCalc`Pair[_FeynCalc`Momentum,_FeynCalc`LorentzIndex]],
   component[value[[1]],value[[2]]],
  FreeQ[value,_FeynCalc`LorentzIndex|_FeynCalc`Momentum|_FeynCalc`DiracGamma|_FeynCalc`DiracTrace],
   scalarName[value],
  True,formAlgebraFail["FORMTensorObjectUnsupported",<|"Object"->value|>]
 ];
 (* The grade-four part of an ordinary Clifford product is the only part
    pairing with gamma5. Selected slots enter the physical epsilon tensor;
    unselected slots remain an ordinary full-D trace. No gamma5 anticommutation
    is used. The explicit definition remains the short multiple-insertion case. *)
 wordProduct[left_,right_]:=Flatten[Table[{a[[1]]b[[1]],Join[a[[2]],b[[2]]]},
  {a,left},{b,right}],1];
 words[value_]:=Which[
  Head[value]===FeynCalc`DiracGamma,{{1,{value}}},
  FreeQ[value,_FeynCalc`DiracGamma|_FeynCalc`DiracTrace|_FeynCalc`DOT],{{value,{}}},
  Head[value]===Plus,Flatten[words/@(List@@value),1],
  MemberQ[{Times,FeynCalc`DOT,Dot},Head[value]],
   Fold[wordProduct,{{1,{}}},words/@(List@@value)],
  True,formAlgebraFail["OrderedGammaWordRequired"]];
 gammaArgumentTerms[FeynCalc`DiracGamma[arg_,dim_:4]]:=Module[{extra},
  Which[
   MatchQ[arg,_FeynCalc`Momentum],vector[FeynCalc`Momentum[First[arg],dim]],
   MatchQ[arg,_FeynCalc`LorentzIndex]&&dim===D,{{"1",index[arg]}},
   MatchQ[arg,_FeynCalc`LorentzIndex]&&MemberQ[{4,D-4},dim],
    extra=freshIndex[];
    If[dim===4,{{"fP4("<>index[arg]<>","<>extra<>")",extra}},
     {{"1",index[arg]},{"-fP4("<>index[arg]<>","<>extra<>")",extra}}],
   True,formAlgebraFail["OrdinaryGammaArgumentRequired"]]];
 gradeTrace[entry_]:=Module[{coefficient=entry[[1]],matrices=entry[[2]],positions,position,ordinary,argumentTuples},
  positions=Flatten[Position[matrices,FeynCalc`DiracGamma[5],{1}]];
  If[Length[positions]=!=1||!FreeQ[matrices,FeynCalc`DiracGamma[6|7]],
   Return[serialize[coefficient]<>"*"<>If[matrices==={},"gi_(1)",StringRiffle[gamma/@matrices,"*"]]]];
  position=First[positions];
  ordinary=Join[Drop[matrices,position],Take[matrices,position-1]];
  If[OddQ[Length[ordinary]]||Length[ordinary]<4,Return["0"]];
  argumentTuples=Tuples[gammaArgumentTerms/@ordinary];
  serialize[coefficient]<>"*"<>sum[(
   StringRiffle[#[[All,1]],"*"]<>"*fT5("<>StringRiffle[#[[All,2]],","]<>")")&/@argumentTuples]];
 (* In BMHV, gamma5 conjugation reverses the physical Clifford generators
    and preserves the evanescent ones: gamma5 gamma_D gamma5 =
    gamma_D - 2 gamma_4. Pair insertions can therefore be removed exactly
    before traces, without anticommuting gamma5 with a full-D generator. *)
 (* Avoid two cancelling copies when a D-labelled slash is physical. *)
 physicalGammaQ[g:FeynCalc`DiracGamma[arg_,dim_:4]]:=physicalGammaQ[g]=
  dim===4||(dim===D&&MatchQ[arg,_FeynCalc`Momentum]&&
   (MemberQ[physical,First[arg]]||TrueQ[Expand[First[arg]-
     (Coefficient[Expand[First[arg]],#]&/@physical).physical]===0]));
 gammaPairCost[segment_List]:={Count[segment,
  g_FeynCalc`DiracGamma/;Length[g]===2&&Last[g]===D&&!physicalGammaQ[g]],Length[segment]};
 conjugateGamma[g:FeynCalc`DiracGamma[arg_,dim_:4]]:=Which[
  physicalGammaQ[g],{{-1,{g}}},
  dim===D-4,{{1,{g}}},
  dim===D,{{1,{g}},{-2,{FeynCalc`DiracGamma[arg/.{
    FeynCalc`Momentum[m_,___]:>FeynCalc`Momentum[m],
    FeynCalc`LorentzIndex[i_,___]:>FeynCalc`LorentzIndex[i]}]}}},
  True,formAlgebraFail["FORMGammaDimensionUnsupported"]];
 reduceGammaPairs[entry_]:=Module[{coefficient=entry[[1]],matrices=entry[[2]],
  positions,pair,rotated,distance,segment,remaining,expanded},
  positions=Flatten[Position[matrices,FeynCalc`DiracGamma[5],{1}]];
  If[Length[positions]<2||!FreeQ[matrices,FeynCalc`DiracGamma[6|7]],Return[{entry}]];
  pair=First@SortBy[Partition[Append[positions,First[positions]+Length[matrices]],2,1],
   gammaPairCost[Take[Drop[RotateLeft[matrices,First[#]-1],1],Last[#]-First[#]-1]]&];
  rotated=RotateLeft[matrices,First[pair]-1];distance=Last[pair]-First[pair]-1;
  segment=Take[Drop[rotated,1],distance];remaining=Drop[rotated,distance+2];
  expanded=Fold[wordProduct,{{coefficient,{}}},conjugateGamma/@segment];
  Flatten[reduceGammaPairs[{#[[1]],Join[#[[2]],remaining]}]&/@expanded,1]];
 traceSerialize[value_]:=If[bmhv&&traceMethod==="GradeFour",
  sum[gradeTrace/@If[TrueQ[Lookup[request,"ReduceGamma5Pairs",True]],
    Flatten[reduceGammaPairs/@words[value],1],words[value]]],serialize[value]];
 definitions=Map["Local "<>traceNames[#]<>"=gi_(1)*("<>traceSerialize[First[#]]<>");"&,traces];
 resultText=serialize[internal];
 massless=Lookup[request,"MasslessMomenta",{}];
 If[!ListQ[massless]||!ContainsAll[momenta,massless],formAlgebraFail["DeclaredFORMMasslessMomentaRequired"]];
 kinematics=FeynCalc`FCI[Lookup[request,"KinematicRules",{}]];
 If[!MatchQ[kinematics,{(_Rule)...}]||!AllTrue[kinematics,
   MatchQ[First[#],FeynCalc`Pair[FeynCalc`Momentum[_Symbol,D],FeynCalc`Momentum[_Symbol,D]]]&&
   ContainsAll[momenta,First/@(List@@First[#])]&&
   FreeQ[Last[#],_FeynCalc`LorentzIndex|_FeynCalc`Momentum|_FeynCalc`DiracGamma|_FeynCalc`DiracTrace]&],
  formAlgebraFail["ScalarFORMKinematicRulesRequired"]];
 kinematicStatements=Join[
  ("id "<>vectorNames[#]<>"."<>vectorNames[#]<>"=0;"&/@massless),
  ("id "<>vectorNames[First[First[#][[1]]]]<>"."<>vectorNames[First[First[#][[2]]]]<>"="<>serialize[Last[#]]<>";"&/@kinematics)];
 linearVectors=Select[Keys[vectorNames],!MemberQ[momenta,#]&];
 linearStatements=Flatten[Table[
  With[{terms=MapThread[If[#1===0,Nothing,serialize[#1]<>"*"<>#2]&,
     {Coefficient[m,#]&/@momenta,Values[KeyTake[vectorNames,momenta]]}],
    barTerms=MapThread[If[#1===0,Nothing,serialize[#1]<>"*"<>#2]&,
     {Coefficient[m,#]&/@momenta,Values[KeyTake[barNames,momenta]]}]},
   Join[{"id "<>vectorNames[m]<>"="<>StringRiffle[terms,"+"]<>";"},
    If[bmhv&&barNames[m]=!=vectorNames[m],{"id "<>barNames[m]<>"="<>StringRiffle[barTerms,"+"]<>";"},{}]]],
  {m,linearVectors}]];
 scalarNames=Values[scalarIndex];
 allVectorNames=DeleteDuplicates[Join[Values[vectorNames],If[bmhv,Values[barNames],{}]]];
 physicalStatements=If[bmhv,formPhysicalTensorStatements[indexNames,vectorNames,barNames],{}];
 tensorStatements=If[bmhv,{"Tensors fP4(symmetric),fE4(antisymmetric);","Tensors fT5,fPick4,fRest;",
  "Indices fA1,fA2,fA3,fA4,fB1i,fB2i,fB3i,fB4i,fC1,fC2,fC3,fC4,fC5,fC6,fC7,fC8,fC9,fC10;",
  "Set fIndices:"<>StringRiffle[If[indexNames===<||>,{"fA1"},Values[indexNames]],","]<>";"},{}];
 postTraceStatements=Join[physicalStatements,kinematicStatements,{".sort"},linearStatements,physicalStatements,kinematicStatements];
 sharedPhysicalStatements=If[bmhv,formPhysicalTensorStatements[indexNames,vectorNames,barNames,False],{}];
 gradeStatements=If[bmhv&&traceMethod==="GradeFour",Join[
  {"id fT5(?v)=-i_*distrib_(-1,4,fPick4,fRest,?v);",
   "id fPick4(fA1?,fA2?,fA3?,fA4?)=fE4(fA1,fA2,fA3,fA4);"},
  sharedPhysicalStatements,{"id fRest()=gi_(1);","id fRest(?v)=g_(1,?v);",".sort"}],{}];
 traceVariables=Table[Unique["tracePolynomial$"],{Length[traces]}];
 tracePolynomial=internal/.Dispatch[Thread[traces->traceVariables]];
 inlineTraces=bmhv&&traceMethod==="GradeFour"&&traces=!={}&&
  PolynomialQ[tracePolynomial,traceVariables]&&
  AllTrue[First/@CoefficientRules[tracePolynomial,traceVariables],Total[#]<=1&];
 traceStatements=If[TrueQ[inlineTraces],
  Join[{".sort","Hide;","Local result="<>resultText<>";"},sharedPhysicalStatements,
   formGammaPairStatements[],{".sort"},gradeStatements,{"tracen,1;"},postTraceStatements],
  Join[If[traces==={},{},Join[gradeStatements,{"tracen,1;"},physicalStatements,{".sort","Hide;"}]],
   {"Local result="<>resultText<>";"},postTraceStatements]];
 execution=formAlgebraExecution[request];binary=execution["Executable"];
 program=StringRiffle[Join[
  {"Off Statistics;","Symbols "<>StringRiffle[Prepend[scalarNames,"fD"],","]<>";",
   "Dimension fD;","UnitTrace 4;","Vectors "<>StringRiffle[allVectorNames,","]<>";"},
  If[indexNames===<||>,{},{"Indices "<>StringRiffle[Values[indexNames],","]<>";"}],tensorStatements,
  definitions,traceStatements,
  If[scalarNames==={},{},{"Bracket "<>StringRiffle[scalarNames,","]<>";"}],
  {".sort","Format Mathematica;","#write <result.txt> \"%E\",result",".end"}],"\n"]<>"\n";
 temporary=CreateDirectory[FileNameJoin[{$TemporaryDirectory,"FeynFacetFORM-"<>CreateUUID[]}]];
 Internal`WithLocalSettings[Null,
  Export[FileNameJoin[{temporary,"job.frm"}],program,"String"];
  {seconds,process}=AbsoluteTiming[formAlgebraRun[execution,temporary]];
  If[process["ExitCode"]=!=0||!FileExistsQ[FileNameJoin[{temporary,"result.txt"}]],
   formAlgebraFail["FORMEvaluationFailed",<|"Log"->StringTake[
    process["StandardOutput"]<>process["StandardError"],UpTo[5000]]|>]];
  output=Import[FileNameJoin[{temporary,"result.txt"}],"Text"];
  If[StringQ[Lookup[request,"DiagnosticDirectory",None]],
   If[!DirectoryQ[request["DiagnosticDirectory"]],CreateDirectory[request["DiagnosticDirectory"],CreateIntermediateDirectories->True]];
   Export[FileNameJoin[{request["DiagnosticDirectory"],"job.frm"}],program,"String"];
   Export[FileNameJoin[{request["DiagnosticDirectory"],"result.txt"}],output,"String"]],
  DeleteDirectory[temporary,DeleteContents->True]];
 (* Read only the restricted mathematical expression emitted by our program.
    No arbitrary FORM output is executed as Wolfram Language code. *)
 parseContext="FeynFacet`FORMRead"<>StringReplace[CreateUUID[],"-"->""]<>"`";
 parsed=Block[{$Context=parseContext,$ContextPath={"System`"}},
  ToExpression["("<>StringReplace[StringReplace[output,{"\r"->" ","\n"->" "}],{RegularExpression["d_\\(([^()]*)\\)"]->"formMetric[$1]","i_"->"I","fE4"->"formEpsilon","fP4"->"formProjector",RegularExpression["fP4\\(([^()]*)\\)"]->"formProjector[$1]",RegularExpression["fE4\\(([^()]*)\\)"]->"formEpsilon[$1]"}]<>")",InputForm,HoldComplete]];
 If[!MatchQ[parsed,_HoldComplete],formAlgebraFail["FORMOutputParseFailed"]];
 vectorSymbols=AssociationThread[Symbol[parseContext<>#]&/@Values[vectorNames],Keys[vectorNames]];
 barVectorSymbols=If[bmhv,AssociationThread[Symbol[parseContext<>#]&/@Values[barNames],Keys[barNames]],<||>];
 indexSymbols=AssociationThread[Symbol[parseContext<>#]&/@Values[indexNames],Keys[indexNames]];
 scalarSymbols=AssociationThread[Symbol[parseContext<>#]&/@scalarNames,scalarObjects];
 metricSymbol=Symbol[parseContext<>"formMetric"];dimensionSymbol=Symbol[parseContext<>"fD"];
 projectorSymbol=Symbol[parseContext<>"formProjector"];epsilonSymbol=Symbol[parseContext<>"formEpsilon"];
 allowed=Join[{HoldComplete,Plus,Times,Power,Rational,Complex,Dot,I,metricSymbol,projectorSymbol,epsilonSymbol,dimensionSymbol},
  Keys[vectorSymbols],Keys[barVectorSymbols],Keys[indexSymbols],Keys[scalarSymbols]];
 symbols=DeleteDuplicates[Cases[parsed,_Symbol,Infinity,Heads->True]];
 If[!AllTrue[symbols,MemberQ[allowed,#]&],formAlgebraFail["UnexpectedFORMOutputSymbol",<|"Symbols"->Select[symbols,!MemberQ[allowed,#]&]|>]];
 (* Every FORM vector is either a full-D vector or an explicitly projected
    alias. Shared physical external aliases may occur in both maps. *)
 vectorSymbols=Join[vectorSymbols,barVectorSymbols];
 atoms=DeleteDuplicates[Cases[parsed,
  object:(Dot[a_Symbol,b_Symbol]/;KeyExistsQ[vectorSymbols,a]&&KeyExistsQ[vectorSymbols,b]):>object,Infinity]];
 conversionRules=(#->FeynCalc`FCI[If[
  bmhv&&(KeyExistsQ[barVectorSymbols,#[[1]]]||KeyExistsQ[barVectorSymbols,#[[2]]]),
  FeynCalc`SP[vectorSymbols[#[[1]]],vectorSymbols[#[[2]]]],
  FeynCalc`SPD[vectorSymbols[#[[1]]],vectorSymbols[#[[2]]]]]]&/@atoms);
 atoms=DeleteDuplicates[Cases[parsed,
  object:(h_Symbol[a_Symbol,b_Symbol]/;MemberQ[{metricSymbol,projectorSymbol},h]&&KeyExistsQ[indexSymbols,a]&&KeyExistsQ[indexSymbols,b]):>object,Infinity]];
 conversionRules=Join[conversionRules,
  (#->FeynCalc`FCI[If[Head[#]===projectorSymbol,
   FeynCalc`MT[indexSymbols[#[[1]]],indexSymbols[#[[2]]]],
   FeynCalc`MTD[indexSymbols[#[[1]]],indexSymbols[#[[2]]]]]]&/@atoms)];
 atoms=DeleteDuplicates[Cases[parsed,
  object:(h_Symbol[a_Symbol]/;KeyExistsQ[vectorSymbols,h]&&KeyExistsQ[indexSymbols,a]):>object,Infinity]];
 conversionRules=Join[conversionRules,
  (#->FeynCalc`FCI[If[KeyExistsQ[barVectorSymbols,Head[#]],
   FeynCalc`FV[vectorSymbols[Head[#]],indexSymbols[First[#]]],
   FeynCalc`FVD[vectorSymbols[Head[#]],indexSymbols[First[#]]]]]&/@atoms)];
 atoms=DeleteDuplicates[Cases[parsed,object:(h_Symbol[args__Symbol]/;h===epsilonSymbol):>object,Infinity]];
 conversionRules=Join[conversionRules,
  (#->Apply[FeynCalc`Eps,Map[If[KeyExistsQ[vectorSymbols,#],FeynCalc`Momentum[vectorSymbols[#]],
    FeynCalc`LorentzIndex[indexSymbols[#]]]&,List@@#]]&/@atoms)];
 (* Rules are materialized before traversing HoldComplete. Delayed
    association lookups would otherwise remain held in the returned data. *)
 converted=parsed/.Dispatch[conversionRules];
 converted=converted/.Normal[scalarSymbols]/.dimensionSymbol->D;
 If[!FreeQ[converted,s_Symbol/;Context[s]===parseContext],formAlgebraFail["UnconvertedFORMTensor"]];
 converted=ReleaseHold[converted];
 <|"Value"->converted,"Backend"->"FORM","TraceCount"->Length[traces],"Gamma5TraceMethod"->traceMethod,
  "Gamma5PairReduction"->(bmhv&&traceMethod==="GradeFour"&&TrueQ[Lookup[request,"ReduceGamma5Pairs",True]]),"ChiralTraceSeconds"->traceSeconds,"TensorContractionBeforeTrace"->inlineTraces,
   "Program"->FileNameTake[binary],"Threads"->execution["Threads"],
  "PreservedScalarFactorCount"->Length[scalarObjects],"Seconds"->seconds,
  "DiracAlgebra"->If[bmhv,"BMHV, explicit physical projector and gamma5 definition, Tr(1)=4","D-dimensional, nonchiral, Tr(1)=4"],"PrescriptionsChanged"->False|>
],"FORMAlgebra"];
End[];EndPackage[];
