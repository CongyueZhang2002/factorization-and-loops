(* Prepared numerical arithmetic and FLINT interface. Loaded in the reader's
   private context. The original symbolic definitions remain in the data. *)
FeynFacetSolution`PrepareMasterIntegralSolution::usage="PrepareMasterIntegralSolution[data,opts] validates stored dependencies and prepares reusable numerical arithmetic. The result retains all original symbolic solution data.";
Options[FeynFacetSolution`PrepareMasterIntegralSolution]={"NumericalBackend"->Automatic,"Threads"->1};
FeynFacetSolution`PrepareMasterIntegralSolution[data_Association,OptionsPattern[]] :=
 Catch[prepareFiniteNumerics[data,OptionValue["NumericalBackend"],OptionValue["Threads"]],"NumericalSolution"];

validateFiniteDependencies[data_] := Module[
 {kd=Lookup[data,"KernelDefinitions",{}],fd=data["IntegralDefinitions"],refs,variable},
 Do[
  If[!FreeQ[kd[[i,"Expression"]],_FeynFacetSolution`F|_FeynFacetSolution`a],
   numericalFailure["KernelDefinitionCannotDependOnIntegral"]];
  refs=Cases[kd[[i,"Expression"]],_FeynFacetSolution`K,{0,Infinity}];
  If[!And@@(MatchQ[#,FeynFacetSolution`K[_Integer,_]]&&1<=#[[1]]<i&&
     #[[2]]===kd[[i,"Parameter"]]& /@ refs),
    numericalFailure["KernelDependencyInvalid",<|"Index"->i|>]],
 {i,Length[kd]}];
 Do[
  variable=fd[[i,"IntegrationVariable"]];
  If[!FreeQ[fd[[i,"Integrand"]],_FeynFacetSolution`a],
   numericalFailure["ArithmeticReferenceInsideIntegralNotSupported"]];
  refs=Cases[fd[[i,"Integrand"]],FeynFacetSolution`F[j_,u_]:>{j,u},{0,Infinity}];
  If[!And@@(IntegerQ[#[[1]]]&&1<=#[[1]]<i&&#[[2]]===variable& /@ refs),
   numericalFailure["IntegralDependencyNotSupported",<|"Index"->i|>]];
  refs=Cases[fd[[i,"Integrand"]],FeynFacetSolution`K[j_,u_]:>{j,u},{0,Infinity}];
  If[!And@@(IntegerQ[#[[1]]]&&1<=#[[1]]<=Length[kd]&&#[[2]]===variable& /@ refs),
   numericalFailure["KernelDependencyInvalid",<|"IntegralIndex"->i|>]];
  If[Lookup[fd[[i]],"LowerLimit",0]=!=0,
   numericalFailure["IntegralLowerLimitNotSupported",<|"Index"->i|>]],
 {i,Length[fd]}];
];

rationalToken[z_] := ToString[Numerator[z],InputForm]<>"/"<>ToString[Denominator[z],InputForm];
realBallToken[z_] := rationalToken[Rationalize[z,0]]<>" "<>
 If[Precision[z]===Infinity,"exact",ToString[Ceiling[-Accuracy[z] Log[2,10]],InputForm]];
complexBallToken[z_] := realBallToken[Re[z]]<>" "<>realBallToken[Im[z]];

compileFiniteArithmetic[data_] := Module[
 {kd=Lookup[data,"KernelDefinitions",{}],fd=data["IntegralDefinitions"],
  vars=data["KinematicVariables"],program={},roots={},stops={},kernelRoots,counter=0,collected,
  compile,emit,parameter=Unique["parameter"],kernelEnd,body,result,tag},
 emit[line_] := (Sow[line,"NumericalInstructions"];counter++);
 kernelRoots=ConstantArray[-1,Length[kd]];
 compile[z_] := compile[z]=Which[
   NumberQ[z],emit["C "<>complexBallToken[z]],
   z===parameter,emit["T"],
   z===Pi,emit["P"],
   z===E,With[{one=compile[1]},emit["E 1 "<>ToString[one]]],
   MemberQ[vars,z],emit["X "<>ToString[First[FirstPosition[vars,z]]-1]],
   MatchQ[z,FeynFacetSolution`K[_Integer,parameter]],kernelRoots[[z[[1]]]],
   MatchQ[z,FeynFacetSolution`F[_Integer,parameter]],emit["F "<>ToString[z[[1]]-1]],
   MemberQ[{Plus,Times,Power,Log,Exp,Sin,Cos,ArcTanh,ArcTan,ArcSin,ArcCos,Sinh,Cosh,Tanh,ArcSinh,ArcCosh},Head[z]]&&
    (MemberQ[{Plus,Times},Head[z]]||Length[z]===If[Head[z]===Power,2,1]),
    With[{arguments=compile /@ (List@@z)},
     emit[Switch[Head[z],Plus,"+",Times,"*",Power,"^",Log,"L",Exp,"E",Sin,"S",Cos,"O",ArcTanh,"H",ArcTan,"A",ArcSin,"B",ArcCos,"D",Sinh,"U",Cosh,"V",Tanh,"W",ArcSinh,"J",ArcCosh,"Z"]<>
      " "<>ToString[Length[arguments]]<>" "<>StringRiffle[ToString/@arguments," "]]],
   True,Throw[Failure["CompiledNumericalExpressionNotSupported",<|"Expression"->Short[z]|>],"CompileFinite"]
 ];
 collected=Reap[result=Catch[
  Do[kernelRoots[[i]]=compile[kd[[i,"Expression"]]/.kd[[i,"Parameter"]]->parameter],{i,Length[kd]}];
  kernelEnd=counter;
  Do[
   AppendTo[roots,compile[fd[[i,"Integrand"]]/.fd[[i,"IntegrationVariable"]]->parameter]];
   AppendTo[stops,counter],
  {i,Length[fd]}];
  <|"InstructionCount"->counter,"KernelInstructionCount"->kernelEnd,
    "IntegralCount"->Length[fd],"VariableCount"->Length[vars]|>,
 "CompileFinite"],"NumericalInstructions"];
 Clear[compile];
 If[FailureQ[result],Return[result]];
 program=If[collected[[2]]==={},{},First[collected[[2]]]];
 Join[result,<|"Program"->StringRiffle[program,"\n"]<>"\n"<>
   StringRiffle[MapThread[ToString[#1]<>" "<>ToString[#2]&,{stops,roots}],"\n"]<>"\n"|>]
];

prepareFiniteNumerics[data_,requested_,threads_] := Module[
 {old=Lookup[data,"NumericalPreparation",None],backend=requested,compiled,exe,definitions},
 If[backend==="GiNaC",
  If[!gplCanEvaluate[data],numericalFailure["RequiredIntegralsNotConvertedToGPL"]];
  Return[Join[data,<|"NumericalPreparation"-><|"Backend"->"GiNaC","Threads"->1|>|>]]];
 If[!MemberQ[{Automatic,"FLINT","Wolfram"},backend]||!IntegerQ[threads]||!Between[threads,{1,8}],
  numericalFailure["InvalidNumericalBackendOptions"]];
 definitions=KeyTake[data,{"KinematicVariables","KernelDefinitions","IntegralDefinitions"}];
 exe=FileNameJoin[{$finiteSolutionDirectory,"Backends","flint","bin","finite_integrals"}];
 If[backend===Automatic,backend=If[FileExistsQ[exe],"FLINT","Wolfram"]];
 If[AssociationQ[old]&&Lookup[old,"Definitions",None]===definitions&&
   (Lookup[old,"Backend",None]===backend||Lookup[old,"RequestedBackend",None]===requested),
  Return[Join[data,<|"NumericalPreparation"->Join[old,<|"Threads"->threads|>]|>]]];
 validateFiniteDependencies[data];
 If[backend==="FLINT",
  If[!FileExistsQ[exe],numericalFailure["CompiledNumericalBackendUnavailable",<|"Executable"->exe|>]];
  compiled=compileFiniteArithmetic[data];
  If[FailureQ[compiled],
   If[requested==="FLINT",Throw[compiled,"NumericalSolution"],
    Return[Join[data,<|"NumericalPreparation"-><|"Backend"->"Wolfram","Threads"->threads,
      "FallbackReason"->compiled,"Definitions"->definitions,"RequestedBackend"->requested|>|>]]]];
  Join[data,<|"NumericalPreparation"->Join[compiled,<|"Backend"->"FLINT",
    "Executable"->exe,"Threads"->threads,"Definitions"->definitions,"RequestedBackend"->requested|>]|>],
  Join[data,<|"NumericalPreparation"-><|"Backend"->"Wolfram","Threads"->threads,"Definitions"->definitions,"RequestedBackend"->requested|>|>]]
];

realFromBall[{mantissa_,exponent_,radius_,radiusExponent_},digits_] := Module[{mid,accuracy},
 mid=mantissa 2^exponent;
 If[radius===0,Return[If[mid===0,0,N[mid,digits]]]];
 accuracy=Floor[-Log[10,N[radius 2^radiusExponent,20]]]-2;
 SetAccuracy[mid,Min[accuracy,If[mid===0,digits,digits-Log[10,Abs[N[mid,20]]]]]]
];

evaluateFinitePanelsFLINT[data_,point_,count_,precision_,breaks_] := Module[
 {prep=data["NumericalPreparation"],grid,header,numerics,input,process,tokens,raw,ends},
 grid=gaussIntegrationData[count,precision+15];
 header=StringRiffle[ToString /@ {"FFNI1",Ceiling[(precision+8) Log[2,10]],
    prep["Threads"],count,Length[breaks]-1,prep["InstructionCount"],
    prep["KernelInstructionCount"],prep["IntegralCount"],prep["VariableCount"]}," "]<>"\n";
 numerics=Join[point,grid["Nodes"],grid["Weights"],Flatten[grid["IndefiniteIntegrationMatrix"]],breaks];
 numerics=If[NumberQ[#],#,N[#,precision+15]]& /@ numerics;
 input=header<>prep["Program"]<>StringRiffle[complexBallToken /@ numerics,"\n"]<>"\n";
 process=RunProcess[{prep["Executable"]},All,input];
 If[!AssociationQ[process]||process["ExitCode"]=!=0,
  numericalFailure["CompiledNumericalEvaluationFailed",
   <|"Details"->If[AssociationQ[process],process["StandardError"],process]|>]];
 tokens=StringSplit[process["StandardOutput"]];
 If[Length[tokens]!=2+8 prep["IntegralCount"]||First[tokens]=!="FFNO1"||
   tokens[[2]]=!=ToString[prep["IntegralCount"]]||
   !AllTrue[Drop[tokens,2],StringMatchQ[#,RegularExpression["-?[0-9]+"]]&],
  numericalFailure["CompiledNumericalOutputInvalid"]];
 raw=Partition[ToExpression /@ Drop[tokens,2],8];
 ends=(realFromBall[Take[#,4],precision]+I realFromBall[Drop[#,4],precision])& /@ raw;
 assembleFiniteResult[data,point,count,precision,breaks,ends]
];

evaluateFinitePanels[data_,point_,count_,precision_,breaks_] :=
 If[data["NumericalPreparation"]["Backend"]==="FLINT",
  evaluateFinitePanelsFLINT[data,point,count,precision,breaks],
  evaluateFinitePanelsWolfram[data,point,count,precision,breaks]];
