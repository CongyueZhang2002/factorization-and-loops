(* GiNaC invocation and evaluation of explicit GPL solution expressions. *)
gplNumericToken[z_]:=Module[{q=Rationalize[z,0]},ToString[Numerator[q],InputForm]<>" "<>ToString[Denominator[q],InputForm]];
gplComplexToken[z_]:=gplNumericToken[Re[z]]<>" "<>gplNumericToken[Im[z]];
gplParseReal[s_String,wp_]:=Module[{parts,mantissa,power,fraction,digits,sign=1},
 If[!StringMatchQ[s,RegularExpression["[+-]?[0-9]+(?:\\.[0-9]*)?(?:[Ee][+-]?[0-9]+)?"]],
  numericalFailure["MalformedGiNaCOutput"]];
 parts=StringSplit[ToLowerCase[s],"e"];mantissa=First[parts];
 power=If[Length[parts]===2,ToExpression[Last[parts]],0];
 If[StringStartsQ[mantissa,"-"],sign=-1;mantissa=StringDrop[mantissa,1],
  If[StringStartsQ[mantissa,"+"],mantissa=StringDrop[mantissa,1]]];
 parts=StringSplit[mantissa,".",All];
 fraction=If[Length[parts]===2,StringLength[Last[parts]],0];
 digits=FromDigits[StringJoin[parts]];
 N[sign digits 10^(power-fraction),wp]
];
gplEvaluateList[gs_List,rules_,wp_,time_,prescription_:None]:=Module[
 {numeric,lines,input,exe,process,rows,values,point,letters,ratios,tolerance=10^(-wp+8),parsed,endpointPole,interiorPole,endpointFinite},
 If[gs==={},Return[{}]];
 numeric=Map[Function[g,{N[g[[1]]/.rules,wp],N[g[[2]]/.rules,wp]}],gs];
 If[!AllTrue[numeric,VectorQ[#[[1]],finiteNumberQ]&&finiteNumberQ[#[[2]]]&],
  numericalFailure["GPLArgumentsNotNumeric"]];
 If[AnyTrue[Flatten[numeric],!TrueQ[Precision[#]===Infinity||Precision[#]>=wp-10]&],
  numericalFailure["GPLArgumentPrecisionInsufficient"]];
 Do[
  {letters,point}=args;
  If[point===0||TrueQ[point==0],numericalFailure["GPLZeroEndpointRequiresSymbolicLimit"]];
  ratios=DeleteCases[letters,z_/;TrueQ[z==0]]/point;
  interiorPole=AnyTrue[ratios,Abs[Im[#]]<tolerance&&-tolerance<=Re[#]<1-tolerance&];
  endpointPole=letters=!={}&&Abs[First[letters]/point-1]<tolerance;
  endpointFinite=TrueQ[point==1]&&Length[letters]>1&&AllTrue[Rest[letters],TrueQ[#==0]&];
  If[(interiorPole&&prescription===None)||(endpointPole&&!endpointFinite),
   numericalFailure["GPLLetterOnIntegrationContour",<|"Letters"->letters,"Endpoint"->point|>]],
 {args,numeric}];
 input="FFGPL2 "<>ToString[wp]<>" "<>ToString[Length[gs]]<>" "<>ToString[Replace[prescription,None->0]]<>"\n"<>
  StringRiffle[Map[ToString[Length[#[[1]]]]<>" "<>gplComplexToken[#[[2]]]<>" "<>
    StringRiffle[gplComplexToken /@ #[[1]]," "]&,numeric],"\n"]<>"\n";
 exe=FileNameJoin[{$finiteSolutionDirectory,"Backends","ginac","bin","evaluate_gpl"}];
 If[!FileExistsQ[exe],numericalFailure["GiNaCGPLBackendUnavailable"]];
 process=TimeConstrained[RunProcess[{exe},All,input],time,$Failed];
 If[process===$Failed,numericalFailure["GiNaCGPLEvaluationTimeLimit"]];
 If[process["ExitCode"]=!=0,numericalFailure["GiNaCGPLEvaluationFailed",<|"Message"->StringTake[process["StandardError"],UpTo[1000]]|>]];
 lines=StringSplit[StringTrim[process["StandardOutput"]],"\n"];
 If[Length[lines]=!=Length[gs]+1||First[lines]=!="FFGPL2 "<>ToString[Length[gs]],
  numericalFailure["MalformedGiNaCOutput"]];
 rows=StringSplit /@ Rest[lines];
 If[!AllTrue[rows,Length[#]===2&],numericalFailure["MalformedGiNaCOutput"]];
 (* Parse decimal strings as exact decimal values before attaching their
    documented output precision; never pass through machine precision. *)
 values=Map[Function[row,
   parsed=gplParseReal[row[[1]],wp]+I gplParseReal[row[[2]],wp];
   SetPrecision[parsed,Max[15,wp-5]]],rows];
 values
];
Options[FeynFacetSolution`EvaluateGPLExpression]={"WorkingPrecision"->60,"TimeLimit"->60,"RealLetterPrescription"->None};
FeynFacetSolution`EvaluateGPLExpression[expression_,rules_List:{},OptionsPattern[]]:=Catch[Module[
 {wp=OptionValue["WorkingPrecision"],gs,values,prescription=OptionValue["RealLetterPrescription"]},
 If[!IntegerQ[wp]||wp<20,numericalFailure["InvalidGPLWorkingPrecision"]];
 If[!NumericQ[OptionValue["TimeLimit"]]||!TrueQ[OptionValue["TimeLimit"]>0],
  numericalFailure["InvalidGPLTimeLimit"]];
 If[!VectorQ[rules,MatchQ[#,_Rule]&],numericalFailure["InvalidGPLSubstitutionRules"]];
 If[!FreeQ[{expression,Last/@rules},_Real],
  numericalFailure["GPLExactInputRequired"]];
 If[!MemberQ[{None,-1,1},prescription],numericalFailure["GPLRealLetterPrescriptionInvalid"]];
 gs=DeleteDuplicates[Cases[expression,_FeynFacetSolution`G,{0,Infinity}]];
 values=gplEvaluateList[gs,rules,wp,OptionValue["TimeLimit"],prescription];
 N[(expression/.Thread[gs->values])/.rules,wp]
],"NumericalSolution"];

gplSourceBranchCheck[data_,point_,seconds_]:=Module[
 {kd=data["KernelDefinitions"],fd=data["IntegralDefinitions"],rules,
  t=Unique["branchParameter"],kernel,source,logs,powers,checks,expr,q,num,den,im,re,roots,
  checked=0},
 rules=Thread[data["KinematicVariables"]->point];
 kernel[i_Integer]:=kernel[i]=Module[{v=kd[[i,"Expression"]]/.kd[[i,"Parameter"]]->t},
   v/.FeynFacetSolution`K[j_Integer,_]:>kernel[j]];
 source=Join[({#["Expression"],#["Parameter"]}& /@ kd),
   ({#["Integrand"],#["IntegrationVariable"]}& /@ fd)];
 logs=DeleteDuplicates[Flatten[Table[Cases[entry[[1]],Log[v_]:>
    (v/.entry[[2]]->t),{0,Infinity}],{entry,source}]]];
 powers=DeleteDuplicates[Flatten[Table[Cases[entry[[1]],
   Power[v_,p_Rational]/;Denominator[p]>1:>(v/.entry[[2]]->t),{0,Infinity}],{entry,source}]]];
 checks=TimeConstrained[
  Do[
   expr=(factor/.FeynFacetSolution`K[j_Integer,_]:>kernel[j])/.rules;
   If[FreeQ[expr,t],Continue[]];
   q=Together[expr];num=Numerator[q];den=Denominator[q];
   If[!PolynomialQ[num,t]||!PolynomialQ[den,t],
    numericalFailure["GPLSourceBranchCheckNotSupported"]];
   im=Chop[ComplexExpand[Im[N[num,60] Conjugate[N[den,60]]]],10^-55];
   re=ComplexExpand[Re[N[num,60] Conjugate[N[den,60]]]];
   If[im===0,
    If[TrueQ[(re/.t->1/2)<=0],numericalFailure["SourcePrincipalBranchCutOnPath"]],
    roots=Quiet[Check[t/.NSolve[im==0,t,WorkingPrecision->50],$Failed]];
    If[!ListQ[roots]||!VectorQ[roots,NumericQ],
     numericalFailure["GPLSourceBranchCheckNotConstructed"]];
    If[AnyTrue[roots,Abs[Im[#]]<10^-35&&0<=Re[#]<=1&&
      TrueQ[(re/.t->Re[#])<=0]&],numericalFailure["SourcePrincipalBranchCutOnPath"]]];
   checked++,
  {factor,Join[logs,powers]}];True,seconds,False];
 Clear[kernel];
 If[!TrueQ[checks],numericalFailure["GPLSourceBranchCheckTimeLimit"]];
 <|"CheckedBranchArguments"->checked,"Convention"->"No crossing of the source principal branch cuts"|>
];
gplZeroIntegralsAtBasePointQ[data_,point_,needed_]:=Module[
 {kd=data["KernelDefinitions"],fd=data["IntegralDefinitions"],rules,parameter=Unique["baseParameter"],
  kernel,values,answer},
 If[point=!=Lookup[data,"BasePoint",None],Return[False]];
 rules=Thread[data["KinematicVariables"]->point];
 kernel[i_Integer]:=kernel[i]=Module[{v=kd[[i,"Expression"]]/.rules/.kd[[i,"Parameter"]]->parameter},
  v/.FeynFacetSolution`K[j_Integer,_]:>kernel[j]];
 answer=TimeConstrained[And@@Table[
   values=fd[[i,"Integrand"]]/.rules/.fd[[i,"IntegrationVariable"]]->parameter;
   values=values/.{FeynFacetSolution`F[_,_]->0,FeynFacetSolution`K[j_Integer,_]:>kernel[j]};
   FreeQ[values,Indeterminate|_DirectedInfinity]&&TrueQ[Cancel[Together[values]]===0],
  {i,needed}],2,False];
 Clear[kernel];TrueQ[answer]
];
evaluateGPLMaster[data_,point_,options_]:=TimeConstrained[Catch[Module[
 {started=AbsoluteTime[],wp=options["WorkingPrecision"],ag=options["AccuracyGoal"],
  pg=options["PrecisionGoal"],guard=options["InputGuardDigits"],rules,supplied,closure,needed,
  rep=data["GPLRepresentation"],expressions,gs,ends,values,ready,pass,outputs={},vectors={},precision,
  result,ratio,inputs,pointRules,lookup,zeroAtBase,pathReport,branchReport},
 If[!IntegerQ[ag]||ag<1||!IntegerQ[pg]||pg<1||!IntegerQ[guard]||guard<0||
   !MemberQ[{True,False},options["CheckConvergence"]]||
   !IntegerQ[options["MaxWorkingPrecision"]]||
   !NumericQ[options["TimeLimit"]]||!TrueQ[options["TimeLimit"]>0]||
   !NumericQ[options["PathCheckTimeLimit"]]||!TrueQ[options["PathCheckTimeLimit"]>0],
  numericalFailure["InvalidNumericalParameters"]];
 If[!gplRepresentationCurrentQ[data],numericalFailure["GPLSourceDefinitionsChanged"]];
 If[!gplCanEvaluate[data],numericalFailure["RequiredIntegralsNotConvertedToGPL"]];
 If[wp===Automatic,wp=Max[50,ag+25,pg+25]];
 If[!IntegerQ[wp]||wp<Max[ag,pg]+10||wp+If[TrueQ[options["CheckConvergence"]],20,0]>options["MaxWorkingPrecision"],
  numericalFailure["InsufficientWorkingPrecision"]];
 If[Length[point]=!=Length[data["KinematicVariables"]]||!VectorQ[point,finiteNumericQ],
  numericalFailure["NumericKinematicPointRequired"]];
 If[!FreeQ[{point,rep["IntegralExpressions"],data["AlgebraicDefinitions"]},_Real],
  numericalFailure["GPLExactKinematicInputsRequired"]];
 rules=constantRules[data,options["InitialConstantValues"]];supplied=options["InitialConstantValues"]=!=Automatic;
 inputs=Cases[{point,Last/@rules,rep["IntegralExpressions"],data["AlgebraicDefinitions"]},_Real|_Complex,Infinity];
 If[inputs=!={}&&!TrueQ[roundoffRatio[inputs,ag+guard,pg+guard]<=1],
  numericalFailure["NumericalInputPrecisionInsufficient"]];
 pathReport=polynomialPathCheck[data,point,options["PathCheckTimeLimit"]];
 If[!TrueQ[pathReport["CompletedWithinTimeLimit"]]||pathReport["UnresolvedFactorCount"]>0,
  numericalFailure["GPLSourcePathNotVerified",<|"PathCheck"->pathReport|>]];
 branchReport=gplSourceBranchCheck[data,point,options["PathCheckTimeLimit"]];
 closure=gplDefinitionClosure[data];needed=closure["IntegralIndices"];
 zeroAtBase=gplZeroIntegralsAtBasePointQ[data,point,needed];
 expressions=If[zeroAtBase,ConstantArray[0,Length[needed]],
  Lookup[rep["IntegralExpressions"],needed]/.rep["Parameter"]->1];
 gs=DeleteDuplicates[Cases[expressions,_FeynFacetSolution`G,{0,Infinity}]];
 ready=Join[data,<|"AlgebraicDefinitions"->MapIndexed[
  If[MemberQ[closure["AlgebraicIndices"],First[#2]],#1,0]&,data["AlgebraicDefinitions"]]|>];
 pass=0;ratio=None;
 While[True,
  pass++;precision=wp+20(pass-1);
  If[precision>options["MaxWorkingPrecision"],
   numericalFailure["GPLNumericalAccuracyNotReached",<|"EstimatedErrorRatio"->ratio|>]];
  pointRules=Thread[data["KinematicVariables"]->N[point,precision]];
  values=gplEvaluateList[gs,pointRules,precision,options["TimeLimit"]];
  ends=ConstantArray[0,Length[data["IntegralDefinitions"]]];
  lookup=N[(expressions/.Thread[gs->values])/.pointRules,precision];
  If[!VectorQ[lookup,finiteNumberQ],numericalFailure["GPLIntegralValueNotFinite"]];
  Do[ends[[needed[[i]]]]=lookup[[i]],{i,Length[needed]}];
  result=applyConstants[assembleFiniteResult[ready,point,0,precision,{0,1},ends],rules];
  AppendTo[outputs,result];AppendTo[vectors,comparisonVector[data,result,supplied]];
  If[!TrueQ[options["CheckConvergence"]],Break[]];
  If[Length[vectors]>=2,
   ratio=Max[scaledDifference@@Join[Take[vectors,-2],{ag,pg}],roundoffRatio[Last[vectors],ag,pg]];
   If[TrueQ[ratio<=1],Break[]]]
 ];
 Join[KeyDrop[Last[outputs],{"QuadratureOrder","IntegrationBreakpoints"}],<|
  "Status"->If[Length[vectors]>=2,"NumericalConvergenceObserved","EvaluatedWithoutConvergenceCheck"],
  "NumericalBackend"->"GiNaC","Method"->"EvaluationOfStoredGPLExpressions",
  "UniqueGPLCount"->Length[gs],"EstimatedErrorRatio"->ratio,
  "WorkingPrecisions"->Table[wp+20(j-1),{j,Length[vectors]}],
  "AccuracyGoal"->ag,"PrecisionGoal"->pg,"ElapsedSeconds"->AbsoluteTime[]-started,
  "ErrorEstimateIsRigorousBound"->False,
  "PathCheck"->Join[pathReport,branchReport,<|"GPLLettersOffStraightContour"->True|>]|>]
],"NumericalSolution"],options["TimeLimit"],Failure["NumericalEvaluationTimeLimit",<||>]];
