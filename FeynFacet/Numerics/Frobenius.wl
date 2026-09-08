
(* Numerical continuation of a normalized Fuchsian system. This module has
   no dependency on the symbolic constructor or the original integral basis. *)
FeynFacetSolution`PrepareFrobeniusNumerics::usage="PrepareFrobeniusNumerics[system,{low,high}] prepares a rational epsilon-regular system with nilpotent unregulated residue for numerical Frobenius initialization and Taylor continuation.";
FeynFacetSolution`EvaluateFrobeniusSolution::usage="EvaluateFrobeniusSolution[prepared,seedCoefficients,target,opts] evolves the complete Laurent seed coefficients in the normalized basis. Rows of seedCoefficients correspond to ascending epsilon powers. It returns numerical coefficients, not an analytic boundary evaluation.";
frobeniusNumericalFail[tag_,data_:<||>] := Throw[Failure[tag,data],"FrobeniusNumerics"];
FeynFacetSolution`PrepareFrobeniusNumerics[system_Association,range:{_Integer,_Integer}] := Catch[Module[
 {z=Lookup[system,"Variable",None],eps=Lookup[system,"DimensionalRegulator",None],
 matrix=Lookup[system,"ConnectionMatrix",{}],n,positions,entries,polynomials,residue,
 nil=0,power,denominators,poles,serializePolynomial,stream,body,poly,den,zero},
 n=Length[matrix];
 If[!MatchQ[z,_Symbol]||!MatchQ[eps,_Symbol]||z===eps||Dimensions[matrix]=!={n,n}||
   n<1||range[[1]]>range[[2]],frobeniusNumericalFail["FrobeniusSystemSpecificationInvalid"]];
 positions=Position[Normal[matrix],x_/;x=!=0,{2},Heads->False];
 polynomials=NumeratorDenominator[Cancel[Together[z Extract[matrix,#]]]]&/@positions;
 If[!AllTrue[Flatten[polynomials],PolynomialQ[#,{z,eps}]&]||
   !AllTrue[polynomials,TrueQ[(Last[#]/.{z->0,eps->0})=!=0]&],
   frobeniusNumericalFail["JointlyRegularFuchsianSystemRequired"]];
 residue=SparseArray[MapThread[#1->(#2[[1]]/#2[[2]]/.{z->0,eps->0})&,
   {positions,polynomials}],{n,n}];
 If[!FreeQ[Normal[residue],z|eps]||!MatrixQ[Normal[residue],NumberQ],
   frobeniusNumericalFail["FixedKinematicsRequired"]];
 power=IdentityMatrix[n,SparseArray];
 While[nil<=n&&Length[ArrayRules[power]]>1,power=SparseArray[power.residue];nil++];
 If[nil>n,frobeniusNumericalFail["UnregulatedResidueNotNilpotent"]];
 denominators=DeleteDuplicates[Flatten[(First/@Rest[FactorList[#]])&/@
   DeleteDuplicates[Last/@polynomials/.eps->0]]];
 denominators=Select[denominators,!FreeQ[#,z]&];
 poles=DeleteDuplicates[Flatten[Table[z/.NSolve[d==0,z,WorkingPrecision->60],{d,denominators}]]];
 If[!VectorQ[poles,finiteNumericQ],frobeniusNumericalFail["FrobeniusSingularitiesUnresolved"]];
 serializePolynomial[expr_]:=Module[{cr=CoefficientRules[expr,{z,eps}]},
   ToString[Length[cr]]<>"\n"<>StringRiffle[
   (StringRiffle[ToString/@First[#]," "]<>" "<>complexBallToken[Last[#]])&/@cr,"\n"]<>"\n"];
 body=StringJoin[MapThread[
   ToString[#1[[1]]-1]<>" "<>ToString[#1[[2]]-1]<>"\n"<>
    serializePolynomial[#2[[1]]]<>serializePolynomial[#2[[2]]]&,{positions,polynomials}]];
 <|"DataType"->"PreparedFrobeniusNumerics","Dimension"->n,"EpsilonOrderRange"->range,
   "EntryCount"->Length[positions],"MatrixProgram"->body,"UnregulatedResidueNilpotencyIndex"->nil,
   "SingularPoints"->Prepend[poles,0],"FrobeniusConvergenceRadius"->If[poles==={},Infinity,Min[Abs[poles]]],
   "NormalizedDifferentialSystem"->system|>
],"FrobeniusNumerics"];

frobeniusNativeStep[prepared_,seed_,center_,delta_,order_,wp_,threads_,mode_] := Module[
 {exe=FileNameJoin[{$finiteSolutionDirectory,"Backends","flint","bin","frobenius_taylor"}],
 n=prepared["Dimension"],width=Subtract@@Reverse[prepared["EpsilonOrderRange"]],
 input,process,tokens,raw,values,tail,header,nativeSeed=AssociationQ[seed],
 started=AbsoluteTime[],inputSeconds,nativeSeconds,conversionStarted},
 If[!FileExistsQ[exe],frobeniusNumericalFail["CompiledFrobeniusBackendUnavailable",<|"Executable"->exe|>]];
 header=StringRiffle[ToString/@{If[nativeSeed,"FFFR2","FFFR1"],Ceiling[(wp+8)Log[2,10]],threads,order,width,n,
   prepared["EntryCount"],prepared["UnregulatedResidueNilpotencyIndex"],mode}," "]<>"\n";
 input=header<>StringRiffle[complexBallToken/@{center,delta},"\n"]<>"\n"<>
   prepared["MatrixProgram"]<>If[nativeSeed,seed["CoefficientBallTokens"],
     StringRiffle[complexBallToken/@Flatten[seed],"\n"]<>"\n"];
 inputSeconds=AbsoluteTime[]-started;
 nativeSeconds=First[AbsoluteTiming[process=RunProcess[{exe},All,input]]];
 conversionStarted=AbsoluteTime[];
 If[process["ExitCode"]=!=0,$frobeniusLastFailedInput=input;frobeniusNumericalFail["FrobeniusNativeEvaluationFailed",
   <|"Details"->StringTake[process["StandardError"],-Min[3000,StringLength[process["StandardError"]]]]|>]];
 tokens=StringSplit[process["StandardOutput"]];
 If[Length[tokens]=!=4+16 n(width+1)||Take[tokens,4]=!={"FFFO1",ToString[n],ToString[width],ToString[order]}||
   !AllTrue[Drop[tokens,4],StringMatchQ[#,RegularExpression["-?[0-9]+"]]&],
   frobeniusNumericalFail["FrobeniusNativeOutputInvalid"]];
 raw=Partition[ToExpression/@Drop[tokens,4],16];
 values=Partition[(realFromBall[#[[1;;4]],wp]+I realFromBall[#[[5;;8]],wp])&/@raw,n];
 tail=Partition[(realFromBall[#[[9;;12]],wp]+I realFromBall[#[[13;;16]],wp])&/@raw,n];
 <|"Coefficients"->values,"TaylorTail"->tail,
   "CoefficientBallTokens"->StringRiffle[Flatten[Take[#,8]&/@Partition[Drop[tokens,4],16]]," "]<>"\n",
   "PhaseTimings"-><|"InputPreparationSeconds"->inputSeconds,"NativeProcessSeconds"->nativeSeconds,
     "OutputConversionSeconds"->AbsoluteTime[]-conversionStarted|>|>
];
Options[FeynFacetSolution`EvaluateFrobeniusSolution]={
 "WorkingPrecision"->80,"AccuracyGoal"->20,"PrecisionGoal"->20,
 "FrobeniusOrder"->40,"TaylorOrder"->48,"MaximumOrder"->128,
 "MatchingParameter"->Automatic,"ContourDeformation"->1/4,
 "StepRadiusFraction"->1/4,"Threads"->1,"TimeLimit"->3600,
 "MaximumSteps"->1000,"Verbose"->False};
FeynFacetSolution`EvaluateFrobeniusSolution[prepared_Association,seed_List,target_,OptionsPattern[]] :=
 Block[{$MinPrecision=0,$MaxPrecision=Infinity},TimeConstrained[Catch[Module[
 {wp=OptionValue["WorkingPrecision"],ag=OptionValue["AccuracyGoal"],pg=OptionValue["PrecisionGoal"],
 m=OptionValue["FrobeniusOrder"],degree=OptionValue["TaylorOrder"],max=OptionValue["MaximumOrder"],
 u=OptionValue["MatchingParameter"],deform=OptionValue["ContourDeformation"],
 fraction=OptionValue["StepRadiusFraction"],threads=OptionValue["Threads"],
 verbose=OptionValue["Verbose"],z,point,derivative,native,values,next,du,trial,dist,
 radius=prepared["FrobeniusConvergenceRadius"],poles=prepared["SingularPoints"],
 ratio,ratios={},tailBudget,steps=0,rejected=0,started=AbsoluteTime[],initialOrder,
 initialPoint,initialRatio,low,high,n=prepared["Dimension"],roundoff,nativeState,
 initializationSeconds,nativeTimings={},phaseTotals,stepFraction,growth,stepRejected},
 {low,high}=prepared["EpsilonOrderRange"];
 If[Dimensions[seed]=!={high-low+1,n}||!MatrixQ[seed,finiteNumericQ]||
   !finiteNumericQ[target]||target==0,
   frobeniusNumericalFail["CompleteNormalizedLaurentSeedRequired"]];
 If[!And@@(IntegerQ[#]&&#>0&/@{wp,ag,pg,m,degree,max,threads})||
   wp<Max[ag,pg]+15||m<8||degree<8||Max[m,degree]>max||max>256||threads>8||
   !TrueQ[0<fraction<=1/3]||!finiteNumericQ[deform]||!TrueQ[deform>=0],
   frobeniusNumericalFail["FrobeniusNumericalOptionsInvalid"]];
 stepFraction=fraction;
 point[s_]:=N[target(s+I deform s(1-s)),wp+10];
 derivative[s_]:=N[target(1+I deform(1-2s)),wp+10];
 If[u===Automatic,u=If[radius===Infinity,1/4,Min[1/4,Rationalize[N[radius/(4 Abs[target](1+deform)),20],0]]]];
 If[!TrueQ[0<u<1]||!TrueQ[Abs[point[u]]<radius],
   frobeniusNumericalFail["MatchingPointOutsideFrobeniusDisk"]];
 If[roundoffRatio[Flatten[seed],ag+10,pg+10]>1,
   frobeniusNumericalFail["FrobeniusSeedPrecisionInsufficient"]];
 z=point[u];initialPoint=z;
 While[True,
   native=frobeniusNativeStep[prepared,seed,0,z,m,wp,threads,0];
   AppendTo[nativeTimings,native["PhaseTimings"]];
   values=native["Coefficients"];
   ratio=Max[Flatten[Abs[native["TaylorTail"]]/(10^-ag+10^-pg Abs[values])]];
   roundoff=roundoffRatio[Flatten[values],ag,pg];
   If[!TrueQ[roundoff<1/10],frobeniusNumericalFail["FrobeniusArithmeticPrecisionInsufficient",<|"RoundoffRatio"->roundoff|>]];
   If[TrueQ[ratio<1/1000],Break[]];
   If[m+8>max,frobeniusNumericalFail["FrobeniusExpansionDidNotConverge",<|"TailRatio"->ratio,"Order"->m|>]];m+=8];
 initialOrder=m;initialRatio=ratio;
 initializationSeconds=AbsoluteTime[]-started;
 nativeState=KeyTake[native,"CoefficientBallTokens"];
 If[TrueQ[verbose],Print["Frobenius initialization: order ",m,", point ",N[z,6],", tail ratio ",N[ratio,4]]];
 While[TrueQ[u<1],
   If[steps>=OptionValue["MaximumSteps"],frobeniusNumericalFail["TaylorStepLimit"]];
   dist=Min[Abs[z-#]&/@poles];
   du=Min[1-u,Rationalize[N[2stepFraction dist/(Abs[derivative[u]]+
     Sqrt[Abs[derivative[u]]^2+4Abs[target deform]stepFraction dist]),20],0]];
   (* The bound |z'| du + |target deformation| du^2 covers the entire
      quadratic arc and its chord inside the pole-free Taylor disk. *)
   stepRejected=False;
   While[True,
    trial=Min[1,u+du];next=point[trial];
    native=frobeniusNativeStep[prepared,nativeState,z,next-z,degree,wp,threads,1];
    AppendTo[nativeTimings,native["PhaseTimings"]];
    roundoff=roundoffRatio[Flatten[native["Coefficients"]],ag,pg];
    If[!TrueQ[roundoff<1/10],frobeniusNumericalFail["TaylorArithmeticPrecisionInsufficient",
      <|"RoundoffRatio"->roundoff,"Step"->steps+1|>]];
    ratio=Max[Flatten[Abs[native["TaylorTail"]]/(10^-ag+10^-pg Abs[native["Coefficients"]])]];
    If[TrueQ[ratio<1/1000],Break[]];
    du=du/2;stepFraction=stepFraction/2;stepRejected=True;rejected++;
    If[Abs[du]<10^-12,frobeniusNumericalFail["TaylorStepTooSmall",<|"TailRatio"->ratio|>]]];
   values=native["Coefficients"];nativeState=KeyTake[native,"CoefficientBallTokens"];
   u=trial;z=next;steps++;AppendTo[ratios,ratio];
   (* Predict a smaller-cost next trial from the first retained tail power.
      This changes only the proposal: every trial still obeys the original
      pole-disk, tail and arithmetic checks. Remember failed step sizes. *)
   growth=If[TrueQ[ratio>0],Clip[N[(10^-5/ratio)^(1/(degree-7)),20],{1/2,5/4}],5/4];
   If[stepRejected,growth=Min[1,growth]];
   stepFraction=Min[fraction,Rationalize[stepFraction growth,0]];
   If[TrueQ[verbose],Print["Taylor step ",steps,": u=",N[u,6],", tail ratio ",N[ratio,4]]]];
 roundoff=roundoffRatio[Flatten[values],ag,pg];
 If[!TrueQ[roundoff<1/10],frobeniusNumericalFail["TaylorArithmeticPrecisionInsufficient",<|"RoundoffRatio"->roundoff|>]];
 phaseTotals=Merge[nativeTimings,Total];
 <|"DataType"->"NumericalFrobeniusSolution","Status"->"NumericalContinuationComputed",
   "NormalizedEpsilonCoefficients"->AssociationThread[Range[low,high],values],
   "Target"->target,"EpsilonOrderRange"->{low,high},"WorkingPrecision"->wp,
   "FrobeniusOrder"->initialOrder,"MatchingPoint"->initialPoint,
   "FrobeniusTailRatio"->initialRatio,"TaylorOrder"->degree,"TaylorStepCount"->steps,
   "RejectedTaylorSteps"->rejected,"MaximumTaylorTailRatio"->If[ratios==={},0,Max[ratios]],
   "RoundoffRatio"->roundoff,"ElapsedSeconds"->AbsoluteTime[]-started,
   "PhaseTimings"->Join[phaseTotals,<|"FrobeniusInitializationSeconds"->initializationSeconds,
     "TaylorContinuationSeconds"->AbsoluteTime[]-started-initializationSeconds|>],
   "IntermediateArithmetic"->"NativeComplexBalls",
   "StepSizeControl"->"TailEstimatePrediction",
   "ErrorEstimateIsRigorousBound"->False,
   "Validation"->"Last-eight-order tails and arithmetic precision monitored. Independent matching-point and precision comparisons remain separate checks.",
   "BranchPrescription"->"Principal logarithm at the matching point, continued along z(u)=target*(u+i*deformation*u*(1-u)).",
   "PhysicalBoundaryValuesDetermined"->False|>
],"FrobeniusNumerics"],OptionValue["TimeLimit"],Failure["FrobeniusNumericalTimeLimit",<||>]]];
