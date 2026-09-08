(* Rational dimensional recurrences and Laurent bounds from eventual
   high-dimensional convergence of compact physical cut integrals. *)
Begin["FeynFacet`Private`"];
Clear[cutDrrDefinitions,cutDrrGeometry,cutDrrInsertions,cutDrrWriteProject,
 cutDrrImport,cutDrrAssemble,cutDrrConstruct,cutDrrCriticalDimensions,cutDrrBounds,
 cutDrrIntegralText,cutDrrSave,cutDrrKiraPropagator];

cutDrrSave[value_,path_] := Module[{temporary=path<>".tmp-"<>ToString[$ProcessID]},
 Block[{$Context="Global`",$ContextPath={"System`","Global`"}},Put[value,temporary]];
 RenameFile[temporary,path,OverwriteTarget->True];path
];
cutDrrDefinitions[reps_] := Table[Association[Table[key->miRepFC[rep[key]],
 {key,Keys[KeyTake[rep,{"MasterIntegral","LoopMomenta","ExternalMomenta","InversePropagators",
  "CutIndices","OrientedCutMomenta","Prescription","KinematicRules","TimeDirection"}]]}]],{rep,reps}];
cutDrrGeometry[reps_,seconds_] := Table[With[{g=cutOrderGeometry[rep]},
 <|"Geometry"->KeyDrop[g,"ConeBases"],
   "PropagatorBoundaryCertificates"->cutOrderSingularityCertificates[rep,g,seconds],
   "NonnegativeCutMassDeformation"->True,
   "EventualHighDimensionHolomorphy"->True|>],{rep,reps}];

cutDrrInsertions[reps_] := Module[{r,basis,z,cuts,n,polyRules,rows,targets,l,e,dimension},
 r=SelectFirst[reps,Lookup[#,"Representation",None]==="BaikovCut"&,None];
 If[r===None,r=Join[First[reps],miRepBaikov[First[reps]]]];
 If[!KeyExistsQ[r,"CoordinateInversePropagators"],
  r=Join[r,miRepBaikov[r]]];
 z=r["IntegrationVariables"];n=Length[z];cuts=r["CutIndices"];
 basis=miRepFC[Lookup[reps,"MasterIntegral"]];
 basis=FeynCalc`GLI[#[[1]],PadRight[#[[2]],n]]& /@ basis;
 If[Length[DeleteDuplicates[#[[1]]& /@ basis]]=!=1,
  epsOrderFail["OneFamilyPerDimensionalRecurrenceRequired"]];
 If[!AllTrue[reps,#[ "LoopMomenta"]===r["LoopMomenta"] &&
    #["ExternalMomenta"]===r["ExternalMomenta"] &&
    #["CutIndices"]===cuts && #["InversePropagators"]===r["InversePropagators"]&],
  epsOrderFail["CommonFamilyDefinitionRequired"]];
 polyRules=CoefficientRules[r["BaikovPolynomial"],z];
 rows=Table[Merge[Table[With[{indices=basis[[j,2]]-First[rule]},
   If[Min[indices[[cuts]]]<=0,Nothing,FeynCalc`GLI[basis[[j,1]],indices]->Last[rule]]],
  {rule,polyRules}],Total],{j,Length[basis]}];
 targets=DeleteDuplicates[Join[basis,Flatten[Keys /@ rows]]];
 l=Length[r["LoopMomenta"]];e=Length[r["ExternalMomenta"]];
 dimension=Unique["spaceTimeDimension"];
 <|"ReferenceRepresentation"->r,"MasterIntegralBasis"->basis,"Rows"->rows,
  "Targets"->targets,"Dimension"->dimension,
  "DimensionDenominator"->Product[dimension-e-j+1,{j,l}],
  "RaisingNormalizationFactor"->(2Pi)^(-l),
  "CoordinateInversePropagators"->r["CoordinateInversePropagators"]|>
];
cutDrrIntegralText[gli_] := miRepFamilyName[gli[[1]]]<>"["<>
 StringRiffle[ToString[#,InputForm]& /@ gli[[2]],","]<>"]";

(* Kira accepts quadratic momenta or bilinear momenta. Factor their commuting
   momentum polynomial to obtain the bilinear form; every coefficient is exact. *)
cutDrrKiraPropagator[core_,mom_,scale_] := Module[
 {poly,constant,factors,linear={},coefficient=1,powers,reconstructed},
 poly=masterIntegralPolynomial[core];
 constant=poly/.Thread[mom->0];
 If[!MatchQ[constant,_Integer|_Rational],epsOrderFail["RationalFixedKinematicsRequired"]];
 factors=FactorList[Expand[poly-constant]];
 Do[
  If[FreeQ[First[factor],Alternatives@@mom],coefficient*=First[factor]^Last[factor],
   If[!PolynomialQ[First[factor],mom] || Total[Exponent[First[factor],#]& /@ mom]<1 ||
     !And@@Flatten[Table[D[First[factor],a,b]===0,{a,mom},{b,mom}]],
    epsOrderFail["QuadraticOrBilinearKiraPropagatorRequired"]];
   linear=Join[linear,ConstantArray[First[factor],Last[factor]]]],
 {factor,factors}];
 If[Length[linear]=!=2,epsOrderFail["QuadraticOrBilinearKiraPropagatorRequired"]];
 linear[[1]]=Expand[coefficient linear[[1]]];
 If[linear[[1]]===linear[[2]],
  Return["      - [\""<>ToString[linear[[1]],InputForm]<>"\", "<>
    ToString[-constant scale,InputForm]<>"]"]];
 "      - {bilinear: [[\""<>ToString[linear[[1]],InputForm]<>"\", \""<>
 ToString[linear[[2]],InputForm]<>"\"], "<>ToString[-constant scale,InputForm]<>"]}"
];
cutDrrWriteProject[insertions_,directory_] := Module[
 {r=insertions["ReferenceRepresentation"],basis,targets,family,loops,ext,mom,scale,
  gram,propagators,maxr,maxs,sectors,config,kin,job,dimension,g,cores,q,mass,scaleName},
 basis=insertions["MasterIntegralBasis"];targets=insertions["Targets"];
 family=miRepFamilyName[basis[[1,1]]];loops=r["LoopMomenta"];ext=r["ExternalMomenta"];mom=Join[loops,ext];
 If[!AllTrue[Prepend[SymbolName /@ mom,family],
   StringMatchQ[#,RegularExpression["[A-Za-z][A-Za-z0-9]*"]]&],
  epsOrderFail["KiraCompatibleMomentumIdentifiersRequired"]];
 scaleName=SelectFirst[Table["sc"<>ToString[j],{j,0,99}],
   !MemberQ[SymbolName /@ mom,#]&];
 scale=Symbol["FeynFacet`Private`"<>scaleName];
 gram=Table[FeynCalc`FCI[FeynCalc`SPD[a,b]]/.r["KinematicRules"],{a,ext},{b,ext}];
 If[!MatrixQ[gram,MatchQ[#,_Integer|_Rational]&],epsOrderFail["RationalFixedKinematicsRequired"]];
 maxr=Max[Total[Select[#[[2]],#>0&]]& /@ targets];
 maxs=Max[Total[Abs[Select[#[[2]],#<0&]]]& /@ targets];
 sectors=DeleteDuplicates[Sum[If[#[[2,j]]>0,2^(j-1),0],{j,Length[#[[2]]]}]& /@ basis];
 sectors=Select[sectors,Function[s,!AnyTrue[DeleteCases[sectors,s],BitAnd[s,#]===s&]]];
 g=cutOrderGeometry[r];cores=insertions["CoordinateInversePropagators"];
 propagators=Table[
  If[j<=Length[r["PropagatorPowers"]] && g["PropagatorSigns"][[j]]===1,
   q=r["PropagatorMomenta"][[j]];mass=g["PropagatorMassSquared"][[j]];
   If[!MatchQ[mass,_Integer|_Rational],epsOrderFail["RationalFixedKinematicsRequired"]];
   "      - [\""<>ToString[q,InputForm]<>"\", "<>ToString[mass scale,InputForm]<>"]",
   cutDrrKiraPropagator[cores[[j]],mom,scale]],
 {j,Length[cores]}];
 (* Serialize the temporary scale without a Wolfram context prefix. *)
 propagators=StringReplace[propagators,ToString[scale,InputForm]->scaleName];
 config=StringRiffle[Join[{
  "integralfamilies:","  - name: "<>family,
  "    loop_momenta: ["<>StringRiffle[SymbolName /@ loops,", "]<>"]",
  "    top_level_sectors: ["<>StringRiffle[ToString /@ sectors,", "]<>"]",
  "    cut_propagators: ["<>StringRiffle[ToString /@ Sort[r["CutIndices"]],", "]<>"]",
  "    propagators:"},propagators],"\n"]<>"\n";
 kin=StringRiffle[Join[{
  "kinematics:","  incoming_momenta: ["<>StringRiffle[SymbolName /@ ext,", "]<>"]",
  "  outgoing_momenta: []","  momentum_conservation: []","  kinematic_invariants:",
  "    - ["<>scaleName<>", 2]","  symbol_to_replace_by_one: "<>scaleName,"  scalarproduct_rules:"},
  Flatten[Table["    - [["<>SymbolName[ext[[i]]]<>", "<>SymbolName[ext[[j]]]<>"], "<>
   If[gram[[i,j]]===0,"0","("<>ToString[gram[[i,j]],InputForm]<>")*"<>scaleName]<>"]",
   {i,Length[ext]},{j,i,Length[ext]}]]],"\n"]<>"\n";
 job=StringRiffle[{
  "jobs:","  - reduce_sectors:","      reduce:",
  "        - {topologies: ["<>family<>"], sectors: ["<>StringRiffle[ToString /@ sectors,","]<>
    "], r: "<>ToString[maxr+1]<>", s: "<>ToString[maxs+1]<>"}",
  "      select_integrals:","        select_mandatory_list:","          - ["<>family<>", targets]",
  "      run_initiate: true","      run_triangular: true",
  "      run_back_substitution: true","      integral_ordering: 2",
  "  - kira2math:","      target:","        - ["<>family<>", targets]"},"\n"]<>"\n";
 If[!DirectoryQ[FileNameJoin[{directory,"config"}]],CreateDirectory[FileNameJoin[{directory,"config"}]]];
 Export[FileNameJoin[{directory,"config","integralfamilies.yaml"}],config,"Text"];
 Export[FileNameJoin[{directory,"config","kinematics.yaml"}],kin,"Text"];
 Export[FileNameJoin[{directory,"jobs.yaml"}],job,"Text"];
 Export[FileNameJoin[{directory,"targets"}],StringRiffle[cutDrrIntegralText /@ targets,"\n"]<>"\n","Text"];
 <|"Family"->family,"MaximumDenominatorDegree"->maxr,"MaximumNumeratorDegree"->maxs,
  "TargetCount"->Length[targets],"RequestedSectorCount"->Length[sectors]|>
];

cutDrrImport[path_,family_,dimension_] := Module[{rules},
 If[!FileExistsQ[path],epsOrderFail["DimensionalRecurrenceReductionTableMissing",<|"Path"->path|>]];
 rules=Block[{$Context="Global`",$ContextPath={"System`","Global`"}},Get[path]];
 rules=rules/.HoldPattern[h_[a__Integer]]/;miRepFamilyName[h]===miRepFamilyName[family]:>
   FeynCalc`GLI[family,{a}];
 rules=rules/.s_Symbol /; MemberQ[{"d","D"},SymbolName[s]]:>dimension;
 If[!MatchQ[rules,{__Rule}] || !FreeQ[rules,_Real],
  epsOrderFail["ExactKiraReductionRulesRequired"]];
 rules
];
cutDrrAssemble[insertions_,rules_] := Module[
 {basis,vars,images,basisImages,reducedBasis,matrix,inverse,change,dim,n,coefficientMatrices},
 basis=insertions["MasterIntegralBasis"];dim=insertions["Dimension"];n=Length[basis];
 images=Table[Total[KeyValueMap[(#1/.Dispatch[rules]) #2&,row]]/
   insertions["DimensionDenominator"],{row,insertions["Rows"]}];
 basisImages=basis/.Dispatch[rules];
 reducedBasis=DeleteDuplicates[Cases[{images,basisImages},_FeynCalc`GLI,Infinity]];
 If[Length[reducedBasis]=!=n,epsOrderFail["MasterBasisNotClosedUnderDimensionShift",
   <|"ReducedBasis"->reducedBasis,"RequestedBasis"->basis|>]];
 vars=Table[Unique["masterCoefficient"],{n}];
 {images,basisImages}={images,basisImages}/.Thread[reducedBasis->vars];
 If[!And@@(epsOrderZero /@ (Join[images,basisImages]/.Thread[vars->0])),
  epsOrderFail["HomogeneousMasterIntegralReductionRequired"]];
 coefficientMatrices=Table[Table[Factor[Together[Coefficient[vector[[i]],vars[[j]]]]],
  {i,n},{j,n}],{vector,{images,basisImages}}];
 If[!AllTrue[Flatten[coefficientMatrices],Function[z,
   PolynomialQ[Numerator[z],dim] && PolynomialQ[Denominator[z],dim] &&
   AllTrue[Join[CoefficientList[Numerator[z],dim],CoefficientList[Denominator[z],dim]],
     MatchQ[#,_Integer|_Rational]&]]],epsOrderFail["RationalDimensionMatrixRequired"]];
 change=Quiet[Check[Inverse[coefficientMatrices[[2]]],$Failed]];
 If[!MatrixQ[change],epsOrderFail["RequestedMasterBasisNotIndependent"]];
 matrix=Map[Factor,coefficientMatrices[[1]].change,{2}];
 inverse=Quiet[Check[Map[Factor,Inverse[matrix],{2}],$Failed]];
 If[!MatrixQ[inverse] || Dimensions[inverse]=!={n,n},
  epsOrderFail["InvertibleDimensionalRecurrenceRequired"]];
 <|"RaisingMatrix"->matrix,"LoweringMatrix"->inverse,
   "IBPMasterIntegralBasis"->reducedBasis,
   "RequestedBasisFromIBPBasis"->coefficientMatrices[[2]]|>
];

Options[FeynFacet`ConstructMasterIntegralDimensionalRecurrence]={
 "WorkingDirectory"->Automatic,"KiraExecutable"->Automatic,"FermatExecutable"->Automatic,
 "Threads"->2,"RegularityProofTimeLimit"->5};
cutDrrConstruct[data_,directoryOption_,kiraOption_,fermatOption_,threads_,seconds_] := Module[
 {reps,definitions,proofs,insertions,directory,cache,inputFile,existing,project,kira,fermat,
  process,log,path,rules,matrices,result,timing,loaded},
 reps=Lookup[data,"MasterIntegralRepresentations",data];
 If[!AssociationQ[reps] || reps===<||> || !AllTrue[Values[reps],AssociationQ],
  epsOrderFail["MasterIntegralRepresentationsRequired"]];
 reps=Values[reps];definitions=cutDrrDefinitions[reps];
 If[!IntegerQ[threads] || threads<1,epsOrderFail["PositiveKiraThreadCountRequired"]];
 directory=If[directoryOption===Automatic,CreateDirectory[],
  ExpandFileName[directoryOption]];
 If[!DirectoryQ[directory],CreateDirectory[directory,CreateIntermediateDirectories->True]];
 cache=FileNameJoin[{directory,"DimensionalRecurrence.wl"}];
 inputFile=FileNameJoin[{directory,"IntegralDefinitions.wl"}];
 If[FileExistsQ[inputFile],
  existing=Get[inputFile];
  If[cutDrrDefinitions[existing]=!=definitions,epsOrderFail["DimensionalRecurrenceDirectoryInputMismatch",
    <|"WorkingDirectory"->directory|>]];
  If[FileExistsQ[cache],loaded=Get[cache];
   If[AssociationQ[loaded] && Lookup[loaded,"Status",None]==="DimensionalRecurrenceConstructed",
     Return[Join[loaded,<|"IntegralRepresentations"->reps,
       "OriginalMasterIntegralBasis"->Lookup[reps,"MasterIntegral"]|>]]]],
  If[FileNames["*",directory]=!={},epsOrderFail["EmptyDimensionalRecurrenceDirectoryRequired",
    <|"WorkingDirectory"->directory|>]];
  cutDrrSave[definitions,inputFile]
 ];
 proofs=cutDrrGeometry[reps,seconds];
 insertions=cutDrrInsertions[reps];
 If[Complement[insertions["Targets"],insertions["MasterIntegralBasis"]]==={},
  project=<|"Family"->miRepFamilyName[insertions["MasterIntegralBasis"][[1,1]]],
    "TargetCount"->Length[insertions["Targets"]],"IBPReductionRequired"->False|>;
  rules=Thread[insertions["MasterIntegralBasis"]->insertions["MasterIntegralBasis"]];
  timing=0;path=None,
 project=cutDrrWriteProject[insertions,directory];
 kira=masterIntegralAutomaticFile[kiraOption,{"Addon","Other_Addon","Kira","bin","kira"}];
 fermat=masterIntegralAutomaticFile[fermatOption,{"Addon","Other_Addon","Kira","bin","fer64"}];
 If[!AllTrue[{kira,fermat},FileExistsQ],epsOrderFail["KiraAndFermatExecutablesRequired"]];
 timing=First[AbsoluteTiming[
  process=RunProcess[{kira,"--parallel="<>ToString[threads],"jobs.yaml"},All,
   ProcessDirectory->directory,ProcessEnvironment-><|"FERMATPATH"->fermat|>]]];
 log=Lookup[process,"StandardOutput",""]<>Lookup[process,"StandardError",""];
 Export[FileNameJoin[{directory,"reduction.log"}],log,"Text"];
 If[Lookup[process,"ExitCode",1]=!=0 || !StringContainsQ[log,"unreduced integrals: 0."],
  epsOrderFail["DimensionalRecurrenceReductionFailed",<|"WorkingDirectory"->directory|>]];
 path=FileNameJoin[{directory,"results",project["Family"],"kira_targets.m"}];
 rules=cutDrrImport[path,insertions["MasterIntegralBasis"][[1,1]],insertions["Dimension"]];
  project=Join[project,<|"IBPReductionRequired"->True|>]
 ];
 matrices=cutDrrAssemble[insertions,rules];
 result=Join[matrices,<|"DataType"->"MasterIntegralDimensionalRecurrence",
  "Status"->"DimensionalRecurrenceConstructed","Dimension"->insertions["Dimension"],
  "OriginalMasterIntegralBasis"->Lookup[reps,"MasterIntegral"],
  "IntegralDefinitions"->definitions,"IntegralRepresentations"->reps,
  "ConvergenceCertificates"->proofs,
  "RaisingNormalizationFactor"->insertions["RaisingNormalizationFactor"],
  "Convention"->"Bare I(D+2)=RaisingNormalizationFactor RaisingMatrix(D) I(D); explicit master prefactors are applied after bounding bare integrals.",
  "Reduction"->Join[project,<|"WorkingDirectory"->directory,"ReductionSeconds"->timing,
    "UnreducedIntegrals"->0,"TablePath"->path|>]|>];
 cutDrrSave[result,cache];result
];
FeynFacet`ConstructMasterIntegralDimensionalRecurrence[data_Association,OptionsPattern[]] :=
 Catch[cutDrrConstruct[data,OptionValue["WorkingDirectory"],OptionValue["KiraExecutable"],
  OptionValue["FermatExecutable"],OptionValue["Threads"],OptionValue["RegularityProofTimeLimit"]],
 "EpsilonOrders"];

(* Every rational root of a polynomial over Q occurs in a linear factor.
   Thus this finite calculation finds every pole on the rational D0+2j grid,
   including poles at large j, without a bounded numerical search for roots. *)
cutDrrCriticalDimensions[matrix_,dim_,d0_] := Module[{denominators,roots={},root},
 denominators=DeleteDuplicates[Denominator[Cancel[#]]& /@ Flatten[matrix]];
 Do[
  If[!AllTrue[CoefficientList[den,dim],MatchQ[#,_Integer|_Rational]&],
   epsOrderFail["RationalDimensionDenominatorsRequired"]];
  Do[If[Exponent[First[factor],dim]===1,
   root=-Coefficient[First[factor],dim,0]/Coefficient[First[factor],dim,1];
   If[IntegerQ[(root-d0)/2] && root>=d0,AppendTo[roots,root]]],
  {factor,FactorList[den]}],
 {den,denominators}];
 Sort[DeleteDuplicates[roots]]
];

Options[FeynFacet`DetermineLaurentBoundsFromDimensionalRecurrence]={
 "MaximumDimensionSteps"->128,"RegularityProofTimeLimit"->5};
cutDrrBounds[record_,maxSteps_,seconds_] := Module[
 {reps,proofs,dim,e,d0,physicalDimension,inverse,raising,n,critical,steps,safe,product,
  valuations,lower,prefactors,records,checkPoints,check,normalization,checkDenominators},
 If[Lookup[record,"DataType",None]=!="MasterIntegralDimensionalRecurrence",
  epsOrderFail["MasterIntegralDimensionalRecurrenceRequired"]];
 reps=record["IntegralRepresentations"];n=Length[reps];dim=record["Dimension"];
 If[!ListQ[reps] || n===0 || !AllTrue[reps,AssociationQ],
  epsOrderFail["MasterIntegralRepresentationsRequired"]];
 If[!ListQ[Lookup[record,"IntegralDefinitions",None]] ||
    cutDrrDefinitions[record["IntegralDefinitions"]]=!=cutDrrDefinitions[reps] ||
    miRepFC[record["OriginalMasterIntegralBasis"]]=!=miRepFC[Lookup[reps,"MasterIntegral"]],
  epsOrderFail["DimensionalRecurrenceIntegralDefinitionMismatch"]];
 If[record["RaisingNormalizationFactor"]=!=(2Pi)^(-Length[First[reps]["LoopMomenta"]]),
  epsOrderFail["ConstantAMFlowPhaseSpaceShiftFactorRequired"]];
 e=First[reps]["DimensionalRegulator"];physicalDimension=First[reps]["Dimension"];
 If[!AllTrue[reps,#["Dimension"]===physicalDimension && #["DimensionalRegulator"]===e&] ||
   !MatchQ[dim,_Symbol] || dim===e,
  epsOrderFail["CommonDimensionConventionRequired"]];
 d0=Limit[physicalDimension,e->0];
 If[!MatchQ[d0,_Integer|_Rational] || !IntegerQ[maxSteps] || maxSteps<0,
  epsOrderFail["RationalDimensionExpansionPointRequired"]];
 proofs=cutDrrGeometry[reps,seconds];
 inverse=record["LoweringMatrix"];raising=record["RaisingMatrix"];
 If[Dimensions[inverse]=!={n,n} || Dimensions[raising]=!={n,n},
  epsOrderFail["DimensionalRecurrenceBasisMismatch"]];
 checkDenominators=DeleteDuplicates[Denominator[Cancel[#]]& /@ Flatten[{inverse,raising}]];
 checkPoints=Select[Table[d0+1/(j+2),{j,0,15}],
   Function[point,AllTrue[checkDenominators,!epsOrderZero[#/.dim->point]&]]];
 If[Length[checkPoints]<2,epsOrderFail["OrdinaryDimensionChecksRequired"]];
 check=And@@Table[And@@(epsOrderZero /@ Flatten[
   ((raising/.dim->point).(inverse/.dim->point))-IdentityMatrix[n]]),
  {point,Take[checkPoints,2]}];
 If[!check,epsOrderFail["InconsistentDimensionalRecurrenceInverse"]];
 critical=cutDrrCriticalDimensions[inverse,dim,d0];
 steps=If[critical==={},0,1+(Max[critical]-d0)/2];safe=d0+2steps;
 If[steps>maxSteps,epsOrderFail["DimensionRecurrenceStepLimitExceeded",
  <|"RequiredSteps"->steps|>]];
 product=IdentityMatrix[n];
 Do[product=Map[Factor,product.(inverse/.dim->physicalDimension+2j),{2}],
 {j,0,steps-1}];
 valuations=Map[epsOrderValuation[#,e]&,product,{2}];
 prefactors=Lookup[reps,"MasterIntegralPrefactor",1];
 lower=MapThread[Plus,{Min /@ valuations,epsOrderValuation[#,e]& /@ prefactors}];
 normalization=record["RaisingNormalizationFactor"]^-steps;
 If[epsOrderValuation[normalization,e]=!=0,
  epsOrderFail["NonzeroAnalyticRecurrenceNormalizationRequired"]];
 records=Association@Table[j-><|"DataType"->"IntegralLaurentBound",
   "Status"->"BoundEstablishedForRepresentation","LowerBound"->lower[[j]],
   "Representation"->reps[[j]],"Method"->"DimensionalRecurrenceAndEventualHolomorphy",
   "HolomorphicDimension"->safe,"LoweringMatrixPoleDimensions"->critical,
   "RecurrenceRowEntryLowerBounds"->valuations[[j]],
   "MasterPrefactorLaurentValuation"->epsOrderValuation[prefactors[[j]],e],
   "IntegralValuesEvaluatedNumerically"->False,
   "BoundIsSufficientNotNecessarilySharp"->True|>,{j,n}];
 <|"DataType"->"DimensionalRecurrenceLaurentBounds",
  "Status"->"LaurentBoundsEstablished","LaurentLowerBounds"->lower,
  "IntegralBoundRecords"->records,"OriginalMasterIntegralBasis"->record["OriginalMasterIntegralBasis"],
  "DimensionalRegulator"->e,"DimensionExpansionPoint"->d0,
  "HolomorphicDimension"->safe,"LoweringMatrixPoleDimensions"->critical,"DimensionSteps"->steps,
  "HolomorphicDimensionArgument"->"Analyticity point proved by recurrence; direct integral convergence there is not asserted.",
  "RationalMatchingMatrix"->product,"AnalyticMatchingFactor"->normalization,
  "MatchingMatrixEntryLowerBounds"->valuations,"ConvergenceCertificates"->proofs,
  "Argument"->"Compact mass-deformed phase space gives eventual holomorphy at large dimension. Beyond the last pole of the rational lowering matrix on D0+2j, every finite downward recurrence product is epsilon-regular. Thus the safe-dimension masters are holomorphic without computing a numerical convergence dimension; the displayed finite product supplies the lower bounds.",
  "InverseIdentityValidation"-><|"Method"->"ExactRationalSampling","SampleDimensions"->Take[checkPoints,2],
    "Passed"->check|>,"IntegralValuesEvaluatedNumerically"->False|>
];
FeynFacet`DetermineLaurentBoundsFromDimensionalRecurrence[record_Association,OptionsPattern[]] :=
 Catch[cutDrrBounds[record,OptionValue["MaximumDimensionSteps"],
  OptionValue["RegularityProofTimeLimit"]],"EpsilonOrders"];
End[];
