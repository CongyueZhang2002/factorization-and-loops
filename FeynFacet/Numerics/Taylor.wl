(* Optional ordinary-point Taylor evaluation of a closed epsilon-coefficient
   vector. This numerical cache leaves the explicit symbolic solution intact. *)
FeynFacetSolution`ConstructMasterIntegralTaylorExpansion::usage="ConstructMasterIntegralTaylorExpansion[data,direction,opts] constructs explicit numerical Taylor coefficients along Center+z direction (BasePoint by default), closes the raw-DE epsilon dependencies, and validates the local expansion against stored finite integrals. Missing center coefficients or unbounded order dependencies are failures.";
FeynFacetSolution`EvaluateMasterIntegralTaylorExpansion::usage="EvaluateMasterIntegralTaylorExpansion[expansion,z] evaluates the explicit numerical Taylor polynomial inside its validated parameter radius, with empirical tail and arithmetic-error checks.";

taylorOutput[data_,values_,indices_] := Module[{at=0},
 Map[Map[Function[row,at++;row->If[indices[[at]]===0,0,values[[indices[[at]]]]]],#]&,
  data["RequestedMasterIntegralRows"]]
];
taylorPolynomial[coefficients_,z_] := Fold[#1 z+#2&,0,Reverse[coefficients]];
taylorValues[expansion_,z_,all_:False] := Module[{coeff=expansion["TaylorCoefficients"],degree=expansion["TaylorOrder"],v,tail},
 v=taylorPolynomial[#,z]& /@ coeff;
 tail=2 (Total[Abs[Drop[#,degree+1]] Abs[z]^Range[degree+1,Length[#]-1]]& /@ coeff);
 {v,tail}
];
Options[FeynFacetSolution`EvaluateMasterIntegralTaylorExpansion]={"ReturnCoefficientStateValues"->False};
FeynFacetSolution`EvaluateMasterIntegralTaylorExpansion[expansion_Association,z_,OptionsPattern[]] := Catch[Module[
 {ag=expansion["AccuracyGoal"],pg=expansion["PrecisionGoal"],values,tails,indices,
  selected,errors,tolerance,ratio,result,uncertainty,all=OptionValue["ReturnCoefficientStateValues"],stateErrors,stateValues},
 If[Lookup[expansion,"Status",None]=!="TaylorExpansionValidated",
  numericalFailure["ValidatedTaylorExpansionRequired"]];
 If[!finiteNumericQ[z]||!TrueQ[Abs[z]<=expansion["ValidatedParameterRadius"]],
  numericalFailure["TaylorPointOutsideValidatedRegion"]];
 If[!TrueQ[roundoffRatio[{z},ag+5,pg+5]<=1],
  numericalFailure["TaylorParameterPrecisionInsufficient"]];
 If[!MemberQ[{True,False},all],numericalFailure["InvalidTaylorQueryOptions"]];
 {values,tails}=taylorValues[expansion,z,all];indices=expansion["OutputIndices"];
 selected=If[#===0,0,values[[#]]]& /@ indices;
 errors=If[#===0,0,tails[[#]]]& /@ indices;
 uncertainty=numericAbsoluteUncertainty /@ selected;
 tolerance=10^-ag+10^-pg Abs[selected];ratio=Max[(errors+uncertainty)/tolerance];
 If[!VectorQ[selected,finiteNumberQ]||!TrueQ[ratio<=1],
  numericalFailure["TaylorQueryAccuracyInsufficient",<|"EstimatedErrorRatio"->ratio|>]];
 result=taylorOutput[expansion,values,indices];
 If[all,
  stateErrors=tails+(numericAbsoluteUncertainty /@ values);
  If[!TrueQ[Max[stateErrors/(10^-ag+10^-pg Abs[values])]<=1],
   numericalFailure["TaylorInternalCoefficientAccuracyInsufficient"]];
  stateValues=MapThread[If[#2===0,#1,SetAccuracy[#1,Min[Accuracy[#1],-Log[10,N[#2,30]]-1]]]&, {values,stateErrors}]];
 Join[If[all,<|"CoefficientStateValues"->AssociationThread[expansion["CoefficientStates"],stateValues],
   "CoefficientStateErrorEstimates"->AssociationThread[expansion["CoefficientStates"],stateErrors],
   "InitialConstantValues"->expansion["InitialConstantValues"],
   "OriginalMasterIntegralBasis"->Lookup[expansion,"OriginalMasterIntegralBasis",None],
   "OriginalBasePoint"->Lookup[expansion,"OriginalBasePoint",expansion["Center"]]|>,<||>],
 <|"Status"->"TaylorEvaluationWithinValidatedRegion",
   "Point"->expansion["Center"]+z expansion["Direction"],
   "MasterIntegralEpsilonCoefficients"->result,
   "EstimatedErrorRatio"->ratio,"ErrorEstimateIsRigorousBound"->False,
   "Method"->"HornerEvaluationOfStoredTaylorCoefficients"|>]
],"NumericalSolution"];

Options[FeynFacetSolution`ConstructMasterIntegralTaylorExpansion]={
 "InitialConstantValues"->Automatic,"CenterData"->Automatic,"TaylorOrder"->32,"WorkingPrecision"->80,
 "AccuracyGoal"->20,"PrecisionGoal"->20,"ParameterRadius"->Automatic,
 "TimeLimit"->300,"MaxCoefficientStates"->5000,"ValidationPoints"->1};
FeynFacetSolution`ConstructMasterIntegralTaylorExpansion[data_Association,direction_List,OptionsPattern[]] :=
 Block[{$MinPrecision=0,$MaxPrecision=Infinity},TimeConstrained[Catch[Module[
 {constants=OptionValue["InitialConstantValues"],degree=OptionValue["TaylorOrder"],
  wp=OptionValue["WorkingPrecision"],ag=OptionValue["AccuracyGoal"],pg=OptionValue["PrecisionGoal"],
  radius=OptionValue["ParameterRadius"],maxStates=OptionValue["MaxCoefficientStates"],
  validationPoints=OptionValue["ValidationPoints"],
  started=AbsoluteTime[],prepared,a,ep=data["DimensionalRegulator"],vars=data["KinematicVariables"],
  center=data["BasePoint"],centerData=OptionValue["CenterData"],nn,connection,val,edges,upper,lower,bound,changed,
  outputStates,states,indices,index,entries={},poly,coefficients,constantMap,initial,missing,
  parameter=Unique["TaylorParameter"],pathRules,rational,nums,dens,denominators,poles,nearest,
  native,header,input,raw,tokens,series,fullDegree,cache,queries,reference,referenceValues,
  candidate,candidateValues,errors={},accepted=False,prepSeconds,recurrenceSeconds,validationStarted,
  exe,entry,seriesCache,orderLimit,outputIndices,uncertainty,tailValues,relativeError,queryRadius,
  instructions,found,rule,tail,values,validationSeconds,normalizeRational,centerMap,
  probeValues,probeDerivatives,probeMatrix,probeResiduals,probeEstimates,probeResults,directQueries},
 If[!MemberQ[{1,3},validationPoints]||!IntegerQ[degree]||!Between[degree,{4,128}]||!IntegerQ[wp]||wp<Max[ag,pg]+15||
   !IntegerQ[ag]||ag<1||!IntegerQ[pg]||pg<1||!IntegerQ[maxStates]||maxStates<1||
   Length[direction]!=Length[vars]||!VectorQ[direction,finiteNumericQ]||And@@(#===0& /@ direction),
  numericalFailure["InvalidTaylorParameters"]];
 If[constants===Automatic,numericalFailure["TaylorBoundaryValuesRequired"]];
 constants=constantRules[data,constants];
 If[centerData=!=Automatic,
  If[!AssociationQ[centerData]||!AssociationQ[Lookup[centerData,"CoefficientStateValues",None]]||
    Lookup[centerData,"OriginalMasterIntegralBasis",None]=!=Lookup[data,"OriginalMasterIntegralBasis",None]||
    Lookup[centerData,"OriginalBasePoint",None]=!=data["BasePoint"]||
    KeySort[Association[Lookup[centerData,"InitialConstantValues",{}]]]=!=KeySort[Association[constants]],
   numericalFailure["TaylorCenterDataMismatch"]];
  center=centerData["Point"];
  If[!VectorQ[center,finiteNumericQ]||Length[center]!=Length[vars],numericalFailure["InvalidTaylorCenter"]]];
 If[!TrueQ[roundoffRatio[Join[Last/@constants,direction,center],ag+5,pg+5]<=1],
  numericalFailure["TaylorInputPrecisionInsufficient"]];
 a=Normal/@data["OriginalConnectionMatrices"];nn=Length[First[a]];
 bound=Lookup[data,"InitialConstantLaurentLowerBounds",None];
 If[!VectorQ[bound,IntegerQ]||Length[bound]!=nn,
  numericalFailure["TaylorBoundaryLaurentLowerBoundsRequired"]];
 pathRules=Thread[vars->center+parameter direction];
 normalizeRational[z_] := normalizeRational[z]=Cancel[Together[z]];
 connection=Map[normalizeRational,Sum[direction[[i]] a[[i]],{i,Length[a]}]/.pathRules,{2}];
 val=Table[Min[Map[Function[m,With[{r=normalizeRational[m[[i,j]]]},
   If[!PolynomialQ[Numerator[r],ep]||!PolynomialQ[Denominator[r],ep],
    numericalFailure["TaylorRationalEpsilonConnectionRequired"]];
   If[r===0,Infinity,Exponent[Numerator[r],ep,Min]-Exponent[Denominator[r],ep,Min]]]],a]],{i,nn},{j,nn}];
 edges=Select[Tuples[Range[nn],2],val[[#[[1]],#[[2]]]]=!=Infinity&];
 outputStates=Flatten[KeyValueMap[Function[{order,rules},({First[#],order}& /@ rules)],
   data["MasterIntegralCoefficients"]],1];
 upper=ConstantArray[-Infinity,nn];
 Do[upper[[state[[1]]]]=Max[upper[[state[[1]]]],state[[2]]],{state,outputStates}];
 (* Exact valuation bounds close k -> k-r. A negative cycle would require an
    unbounded coefficient vector and is explicitly refused by this backend. *)
 Do[changed=False;
  Do[With[{i=edge[[1]],j=edge[[2]]},
   If[upper[[i]]>-Infinity&&upper[[j]]<upper[[i]]-val[[i,j]],
    upper[[j]]=upper[[i]]-val[[i,j]];changed=True]],{edge,edges}];
  If[!changed,Break[]],{nn}];
 If[changed,numericalFailure["TaylorEpsilonClosureUnbounded",
  <|"Meaning"->"The raw-DE coefficient-state recurrence is unavailable; the stored finite solution remains usable."|>]];
 edges=Select[edges,upper[[#[[1]]]]>-Infinity&];
 lower=bound;
 Do[changed=False;
  Do[With[{i=edge[[1]],j=edge[[2]]},
   If[lower[[i]]>val[[i,j]]+lower[[j]],lower[[i]]=val[[i,j]]+lower[[j]];changed=True]],{edge,edges}];
  If[!changed,Break[]],{nn}];
 If[changed,numericalFailure["TaylorEpsilonClosureUnbounded"]];
 pathRules=Thread[vars->center+parameter direction];
 seriesCache[i_,j_] := seriesCache[i,j]=Module[{maximum=upper[[i]]-lower[[j]]},
   If[maximum<val[[i,j]],{},With[{p=Normal[Series[connection[[i,j]],{ep,0,maximum}]]},
    Table[{r,normalizeRational[Coefficient[Expand[p],ep,r]]},{r,val[[i,j]],maximum}]]]];

 states=DeleteDuplicates[Select[outputStates,#[[2]]>=lower[[#[[1]]]]&]];
 found=AssociationThread[states,ConstantArray[True,Length[states]]];
 entry=1;instructions={};
 While[entry<=Length[states],
  If[Length[states]>maxStates,numericalFailure["TaylorCoefficientStateLimit",<|"RequiredCount"->Length[states]|>]];
  With[{state=states[[entry]],i=states[[entry,1]],k=states[[entry,2]]},
   Do[With[{j=edge[[2]]},
    Do[
     If[term[[2]]=!=0&&k-term[[1]]>=lower[[j]],
      With[{dependency={j,k-term[[1]]}},
       AppendTo[instructions,{state,dependency,term[[2]]}];
       If[!KeyExistsQ[found,dependency],AppendTo[states,dependency];AssociateTo[found,dependency->True]]]],
    {term,seriesCache[i,j]}]],{edge,Select[edges,First[#]===i&]}]];
  entry++];
 states=Sort[states];Clear[seriesCache];
 index=AssociationThread[states,Range[Length[states]]];
 outputIndices=If[#[[2]]<lower[[#[[1]]]],0,index[#]]& /@ outputStates;
 constantMap=Association[(List@@First[#])->Last[#]& /@ constants];
 If[AnyTrue[Normal[constantMap],1<=First[#][[1]]<=nn&&First[#][[2]]<bound[[First[#][[1]]]]&&!TrueQ[Last[#]==0]&],
  numericalFailure["TaylorBoundaryValuesContradictLaurentBounds"]];
 If[centerData===Automatic,
  missing=Select[states,#[[2]]>=bound[[#[[1]]]]&&!KeyExistsQ[constantMap,#]&];
  If[missing=!={},numericalFailure["TaylorCenterCoefficientsMissing",<|"RequiredAdditionalCoefficients"->missing|>]];
  initial=If[#[[2]]<bound[[#[[1]]]],0,constantMap[#]]& /@ states,
  centerMap=centerData["CoefficientStateValues"];
  missing=Select[states,!KeyExistsQ[centerMap,#]&];
  If[missing=!={},numericalFailure["TaylorCenterCoefficientsMissing",<|"RequiredAdditionalCoefficients"->missing|>]];
  initial=centerMap /@ states;
  If[!VectorQ[initial,finiteNumberQ]||!TrueQ[roundoffRatio[initial,ag+5,pg+5]<=1],
   numericalFailure["TaylorCenterDataPrecisionInsufficient"]]];
 entries=({index[#[[1]]],index[#[[2]]],#[[3]]}& /@ instructions);
 rational=normalizeRational /@ (Last/@entries);Clear[normalizeRational];
 nums=Numerator/@rational;dens=Denominator/@rational;
 If[!AllTrue[Join[nums,dens],PolynomialQ[#,parameter]&],
  numericalFailure["TaylorRationalConnectionRequired",<|"Expression"->Short[SelectFirst[Join[nums,dens],!PolynomialQ[#,parameter]&],3]|>]];
 denominators=DeleteDuplicates[Select[dens,!FreeQ[#,parameter]&]];
 denominators=DeleteDuplicates[Flatten[(First/@Rest[FactorList[#]])& /@ denominators]];
 If[AnyTrue[dens,TrueQ[(#/.parameter->0)==0]&],numericalFailure["TaylorCenterIsSingular"]];
 poles=Flatten[Table[parameter/.NSolve[p==0,parameter,WorkingPrecision->wp],{p,denominators}]];
 If[!VectorQ[poles,finiteNumericQ],numericalFailure["TaylorSingularitiesUnresolved"]];
 nearest=If[poles==={},Infinity,Min[Abs[poles]]];
 If[radius===Automatic,radius=If[nearest===Infinity,1,Min[1,2^Floor[Log[2,nearest/4]]]]];
 If[!finiteNumericQ[radius]||!TrueQ[0<radius<nearest/2],
  numericalFailure["TaylorRadiusMeetsSingularity",<|"NearestComplexPoleDistance"->nearest|>]];
 exe=FileNameJoin[{$finiteSolutionDirectory,"Backends","flint","bin","finite_taylor"}];
 If[!FileExistsQ[exe],numericalFailure["CompiledTaylorBackendUnavailable"]];
 fullDegree=degree+8;
 header=StringRiffle[ToString/@{"FFNT1",Ceiling[(wp+8) Log[2,10]],fullDegree,Length[states],Length[entries]}," "]<>"\n";
 instructions=Table[
  With[{num=CoefficientList[nums[[i]],parameter],den=CoefficientList[dens[[i]],parameter]},
   StringRiffle[ToString /@ {entries[[i,1]]-1,entries[[i,2]]-1,Length[num],Length[den]}," "]<>"\n"<>
   StringRiffle[complexBallToken /@ (If[NumberQ[#],#,N[#,wp+15]]& /@ Join[num,den]),"\n"]],
 {i,Length[entries]}];
 input=header<>StringRiffle[instructions,"\n"]<>"\n"<>StringRiffle[complexBallToken /@ initial,"\n"]<>"\n";
 prepSeconds=AbsoluteTime[]-started;
 recurrenceSeconds=First[AbsoluteTiming[native=If[states==={},
   <|"ExitCode"->0,"StandardOutput"->"FFTO1 0 "<>ToString[fullDegree]<>"\n"|>,
   RunProcess[{exe},All,input]];]];
 If[!AssociationQ[native]||native["ExitCode"]=!=0,
  numericalFailure["TaylorRecurrenceFailed",<|"Details"->Lookup[native,"StandardError",None]|>]];
 tokens=StringSplit[native["StandardOutput"]];
 If[Length[tokens]!=3+8 Length[states](fullDegree+1)||Take[tokens,3]=!={"FFTO1",ToString[Length[states]],ToString[fullDegree]}||
   !AllTrue[Drop[tokens,3],StringMatchQ[#,RegularExpression["-?[0-9]+"]]&],
  numericalFailure["TaylorOutputInvalid"]];
 raw=Partition[ToExpression /@ Drop[tokens,3],8];
 series=Partition[(realFromBall[Take[#,4],wp]+I realFromBall[Drop[#,4],wp])& /@ raw,fullDegree+1];
 cache=<|"DataType"->"MasterIntegralTaylorExpansion","Status"->"TaylorExpansionValidated",
  "Center"->center,"OriginalBasePoint"->data["BasePoint"],"Direction"->direction,"CoefficientStates"->states,"OutputIndices"->outputIndices,
  "Family"->Lookup[data,"Family",None],"KinematicVariables"->vars,
  "OriginalMasterIntegralBasis"->Lookup[data,"OriginalMasterIntegralBasis",None],
  "CoefficientConvention"->Lookup[data,"CoefficientConvention",None],
  "RequestedMasterIntegralRows"->Map[First/@#&,data["MasterIntegralCoefficients"]],
  "TaylorCoefficients"->series,"TaylorOrder"->degree,"StoredTaylorOrder"->fullDegree,
  "AccuracyGoal"->ag,"PrecisionGoal"->pg,"WorkingPrecision"->wp,
  "InitialConstantValues"->constants,"NearestComplexPoleDistance"->nearest,
  "BranchPrescription"->Lookup[data,"BranchPrescription",None],
  "ErrorEstimateIsRigorousBound"->False|>;
 validationStarted=AbsoluteTime[];
 prepared=FeynFacetSolution`PrepareMasterIntegralSolution[data];
 If[FailureQ[prepared],Throw[prepared,"NumericalSolution"]];
 Do[

  cache=Join[cache,<|"ValidatedParameterRadius"->radius|>];errors={};
  queries={radius,-radius,radius/3};
  probeResults=FeynFacetSolution`EvaluateMasterIntegralTaylorExpansion[cache,#]& /@ queries;
  If[AllTrue[probeResults,AssociationQ],
   probeEstimates=Lookup[probeResults,"EstimatedErrorRatio"];
   (* Fresh off-grid residuals of the finite coefficient DE are inexpensive.
      They are a consistency check, not a rigorous truncation error bound. *)
   probeResiduals=Table[
    If[states==={},0,
     probeValues=taylorPolynomial[#,z]& /@ series;
     probeDerivatives=taylorPolynomial[Rest[#] Range[1,fullDegree],z]& /@ series;
     probeMatrix=SparseArray[({#[[1]],#[[2]]}->N[#[[3]]/.parameter->z,wp]& /@ entries),
       {Length[states],Length[states]}];
     Max[radius Abs[probeDerivatives-probeMatrix.probeValues]/
       (10^-ag+10^-pg Abs[probeValues])]],
    {z,queries}];
   If[VectorQ[probeResiduals,finiteNumericQ]&&Max[probeResiduals]<=1,
    directQueries=If[validationPoints===3,queries,
      {queries[[First[Ordering[probeEstimates,-1]]]]}];
    Do[
     candidate=FeynFacetSolution`EvaluateMasterIntegralTaylorExpansion[cache,z];
     reference=FeynFacetSolution`EvaluateMasterIntegralSolution[prepared,center+z direction,
       "InitialConstantValues"->constants,"WorkingPrecision"->wp,
       "AccuracyGoal"->ag,"PrecisionGoal"->pg];
     If[FailureQ[reference],AppendTo[errors,Infinity];Break[]];
     candidateValues=Flatten[Last/@#& /@ Values[candidate["MasterIntegralEpsilonCoefficients"]]];
     referenceValues=Flatten[Last/@#& /@ Values[reference["MasterIntegralEpsilonCoefficients"]]];
     AppendTo[errors,scaledDifference[candidateValues,referenceValues,ag,pg]+
       roundoffRatio[referenceValues,ag,pg]+candidate["EstimatedErrorRatio"]],
    {z,directQueries}];
    If[Length[errors]===validationPoints&&Max[errors]<=1,accepted=True;Break[]]]];
  radius=radius/2,
 {4}];
 If[!accepted,numericalFailure["TaylorValidationFailed",<|"ComparisonRatios"->errors|>]];
 validationSeconds=AbsoluteTime[]-validationStarted;
 Join[cache,<|"ValidationParameters"->directQueries,"ValidationDifferenceRatios"->errors,
  "DirectComparisonCount"->validationPoints,"ResidualCheckParameters"->queries,
  "DifferentialEquationResidualRatios"->probeResiduals,"TaylorEstimateRatios"->probeEstimates,
  "PreparationSeconds"->prepSeconds,"RecurrenceSeconds"->recurrenceSeconds,
  "ValidationSeconds"->validationSeconds,"ConstructionSeconds"->AbsoluteTime[]-started,
  "Validation"->"Off-grid DE residuals and Taylor estimates at both outer endpoints and one interior point; "<>
     ToString[validationPoints]<>" direct finite-integral comparison(s). All error estimates are empirical.",
  "OriginalDifferentialEquationUsed"->True|>]
],"NumericalSolution"],OptionValue["TimeLimit"],Failure["TaylorConstructionTimeLimit",<||>]]];
