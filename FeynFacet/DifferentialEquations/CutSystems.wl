(* Differentiate the current spanning integrals and reduce their union until
   all requested derivatives close. No preferred process or family enters. *)
BeginPackage["FeynFacet`"];
ConstructCutDifferentialSystem::usage="ConstructCutDifferentialSystem[families,targets,parameters,request] builds a closed multivariable DE from typed cut families. It repeatedly reduces all original and derivative targets with explicit IBPs. Request supplies WorkingDirectory, optional MomentumDerivatives indexed by parameter, SeedExtension, GenerationKernels for independent symbolic equation generation, MaximumClosureIterations, rational ValidationPoints for a cheap flatness check, and InitialReduction to resume from compatible exact family reduction rules. EliminateKnownRules -> True substitutes accepted closed identities into subsequent systems before reconstruction in new workspaces. Only requested targets and their derivatives determine the evolving basis. No boundary value or master minimality is inferred.";
IntegralRelationsFromCutDifferentialSystem::usage="IntegralRelationsFromCutDifferentialSystem[system,request] differentiates the declared master integrals with the typed integral definitions and equates them to a known exact DE. It returns rational integral equations for reuse by reduction, not equations inferred from truncated master values. request may supply ScalarRules and MomentumDerivatives.";
ReduceMasterDifferentialSystem::usage="ReduceMasterDifferentialSystem[system,reduction] restricts an exact multivariable master DE to a subset spanning basis using closed integral identities. It verifies R_selected=Identity and every exact compatibility equation dR+R A_reduced-A_original R=0. With CloseDifferentialRelations -> True it closes differential consequences when the subset still contains dependent integrals. It preserves the generic-kinematic scope of the reduction and does not infer endpoint distribution identities.";

ReduceEquivalentMasterIntegrals::usage="ReduceEquivalentMasterIntegrals[system,request] identifies exactly equivalent typed cut integrals under allowed loop changes, closes their differential consequences with the existing subset reducer, and updates every original reduction and requested value. It does not claim master minimality.";
SelectMasterIntegralBasis::usage="SelectMasterIntegralBasis[system,reduction,request] selects a subset of exact candidate integral images as DE coordinates. It prefers nonnegative indices and smaller total denominator powers. Rational sampling chooses a candidate subset; exact inversion and differential compatibility certify its map. This makes no minimality or global nonsingularity claim.";
ExtendMasterValuesUsingDifferentialEquations::usage="ExtendMasterValuesUsingDifferentialEquations[system,known] derives further exact physical master functions when the derivative of a known master has exactly one still-unknown integral in a declared DE row. known maps basis integrals to exact functions with fixed physical constants. It iterates these algebraic consequences, reports unresolved integrals and retains closed-row compatibility residuals. It does not choose any integration constant, infer endpoint distributions, or claim that untested input functions satisfy the whole DE.";
ExtendMasterLaurentCoefficientsUsingDifferentialEquations::usage="ExtendMasterLaurentCoefficientsUsingDifferentialEquations[system,known,upperOrders] derives requested master Laurent coefficients from single-unknown DE rows. known maps basis integrals to contiguous coefficient records with lower bounds and known upper orders; upperOrders maps requested integrals to their required maximum order. Rational valuations and the shared omitted-tail audit determine whether the differentiated input orders suffice. Unavailable orders remain unresolved; finite polynomials are never treated as exact functions.";
Begin["`Private`"];
ExtendMasterValuesUsingDifferentialEquations[system_Association,known_Association]:=Catch[Module[
 {basis,variables,matrices,n,values=known,derived={},changed=True,indices,missing,j,value,closed,residuals={}},
 basis=system["MasterIntegralBasis"];variables=system["KinematicVariables"];
 matrices=cutConnectionMatrices[system]/.system["DimensionRule"];n=Length[basis];
 If[!ContainsAll[basis,Keys[known]]||!FreeQ[Values[known],_FeynCalc`GLI|_Integrate|_NIntegrate|_Inactive|_SeriesData|_Failure|_Missing],
  cutFamilyFail["ExplicitKnownPhysicalMasterFunctionsRequired"]];
 While[changed,changed=False;indices=Select[Range[n],KeyExistsQ[values,basis[[#]]]&];
  Do[
   missing=Select[Range[n],matrices[[axis,i,#]]=!=0&&!KeyExistsQ[values,basis[[#]]]&];
   If[Length[missing]=!=1,Continue[]];j=First[missing];
   value=(D[values[basis[[i]]],variables[[axis]]]-Sum[
     matrices[[axis,i,k]]Lookup[values,basis[[k]],0],{k,Complement[Range[n],{j}]}])/matrices[[axis,i,j]];
   If[!FreeQ[value,_Derivative|_Integrate|_Inactive|_Failure|_Missing|Indeterminate|_DirectedInfinity],
    cutFamilyFail["ExplicitDifferentiatedMasterValueRequired",<|"Integral"->basis[[j]]|>]];
   AssociateTo[values,basis[[j]]->value];changed=True;
   AppendTo[derived,<|"Integral"->basis[[j]],"DifferentiatedIntegral"->basis[[i]],
     "Variable"->variables[[axis]],"SolvedCoefficient"->matrices[[axis,i,j]]|>],
  {axis,Length[variables]},{i,indices}]];
 indices=Select[Range[n],KeyExistsQ[values,basis[[#]]]&];
 Do[
  closed=AllTrue[Range[n],matrices[[axis,i,#]]===0||KeyExistsQ[values,basis[[#]]]&];
  If[closed,AppendTo[residuals,<|"Integral"->basis[[i]],"Variable"->variables[[axis]],
   "Residual"->(D[values[basis[[i]]],variables[[axis]]]-Sum[
      matrices[[axis,i,k]]Lookup[values,basis[[k]],0],{k,n}])|>]],
 {axis,Length[variables]},{i,indices}];
 <|"Format"->"FeynFacet-DifferentialConsequencesOfMasterValues","Values"->values,
  "Derivations"->derived,"UnresolvedMasterIntegrals"->Complement[basis,Keys[values]],
  "KnownRowCompatibilityResiduals"->residuals,"AllBasisValuesKnown"->(Length[values]===n),
  "EndpointDistributionsSolved"->False,
  "Scope"->"Algebraic consequences of the exact DE and supplied physical functions. Every new value follows without integration. Closed-row compatibility residuals are retained for independent verification."|>
],"CutFamily"];
ExtendMasterLaurentCoefficientsUsingDifferentialEquations[system_Association,known_Association,upperOrders_Association]:=Catch[Module[
 {basis,variables,matrices,n,e,values=known,derived={},pending={},changed=True,indices,missing,j,
  ratios,records,derivative,low,high,lowers,uppers,vector,matrix,result,one,offset,derivativeFunction,valid},
 basis=system["MasterIntegralBasis"];variables=system["KinematicVariables"];e=system["DimensionalRegulator"];
 matrices=cutConnectionMatrices[system]/.system["DimensionRule"];n=Length[basis];
 valid[row_]:=AssociationQ[row]&&IntegerQ[Lookup[row,"LaurentLowerBound",None]]&&
  IntegerQ[Lookup[row,"KnownThroughOrder",None]]&&AssociationQ[Lookup[row,"Coefficients",None]]&&
  Sort[Keys[row["Coefficients"]]]===Range[row["LaurentLowerBound"],row["KnownThroughOrder"]]&&
  FreeQ[Values[row["Coefficients"]],e|_FeynCalc`GLI|_Integrate|_Inactive|_Failure|_Missing];
 If[!ContainsAll[basis,Join[Keys[known],Keys[upperOrders]]]||!AllTrue[Values[known],valid]||
   !VectorQ[Values[upperOrders],IntegerQ],cutFamilyFail["ContiguousKnownMasterOrdersRequired"]];
 If[DownValues[FeynFacetSolution`DifferentiateGPLExpression]==={},
  Block[{$ContextPath=$ContextPath},Get[FileNameJoin[{$feynFacetDirectory,"Solution.m"}]]]];
 derivativeFunction[value_,variable_]:=If[FreeQ[value,_FeynFacetSolution`G],D[value,variable],
   FeynFacetSolution`DifferentiateGPLExpression[value,variable]];
 While[changed,changed=False;indices=Select[Range[n],KeyExistsQ[values,basis[[#]]]&];
  Do[
   missing=Select[Range[n],matrices[[axis,i,#]]=!=0&&!KeyExistsQ[values,basis[[#]]]&];
   If[Length[missing]=!=1||!KeyExistsQ[upperOrders,basis[[First[missing]]]],Continue[]];
   j=First[missing];high=upperOrders[basis[[j]]];
   ratios=Prepend[(-matrices[[axis,i,#]]/matrices[[axis,i,j]]&/@indices),1/matrices[[axis,i,j]]];
   ratios=Cancel[Together[#]]&/@ratios;
   derivative=Join[values[basis[[i]]],<|"Coefficients"->Map[derivativeFunction[#,variables[[axis]]]&,values[basis[[i]]]["Coefficients"]]|>];
   If[!FreeQ[derivative,_Failure|_Derivative],cutFamilyFail["ExplicitMasterCoefficientDerivativeRequired",<|"Integral"->basis[[i]]|>]];
   records=Prepend[Lookup[values,basis[[indices]]],derivative];
   lowers=Lookup[records,"LaurentLowerBound"];uppers=Lookup[records,"KnownThroughOrder"];
   low=Min[high,Min[MapThread[#1+FeynFacet`DetermineLaurentValuation[#2,e]&,{lowers,ratios}]]];
   If[!IntegerQ[low],cutFamilyFail["RationalDifferentialCoefficientValuationsRequired"]];
   vector=<|"DimensionalRegulator"->e,"Dimension"->Length[records],
    "Coefficients"->Association@Flatten[Table[KeyValueMap[{k,#1}->#2&,records[[k]]["Coefficients"]],{k,Length[records]}],1],
    "LaurentLowerBounds"->lowers,"KnownThroughOrders"->uppers,
    "ExactTails"->(TrueQ[Lookup[#,"ExactTail",False]]&/@records)|>;
   matrix=FeynFacet`ExpandLaurentCoefficientMatrix[{ratios},e,high-lowers];
   result=If[AssociationQ[matrix],FeynFacet`MultiplyLaurentCoefficientMatrix[matrix,vector,{{low,high}}],matrix];
   If[!AssociationQ[result],AppendTo[pending,<|"Integral"->basis[[j]],"SourceIntegral"->basis[[i]],"Cause"->result|>];Continue[]];
   one=<|"Coefficients"->Association@Table[k->Lookup[result["Coefficients"],Key[{1,k}],0],{k,low,high}],
    "LaurentLowerBound"->low,"KnownThroughOrder"->high,"ExactTail"->False,
    "OrderCoverageVerified"->result["OrderCoverageVerified"],
    "Method"->"AuditedDifferentialConsequencesOfPhysicalLaurentCoefficients"|>;
   AssociateTo[values,basis[[j]]->one];changed=True;
   AppendTo[derived,<|"Integral"->basis[[j]],"DifferentiatedIntegral"->basis[[i]],
    "Variable"->variables[[axis]],"SolvedCoefficientValuation"->FeynFacet`DetermineLaurentValuation[matrices[[axis,i,j]],e],
    "StoredOrderRange"->{low,high},"OrderCoverageVerified"->result["OrderCoverageVerified"]|>],
  {axis,Length[variables]},{i,indices}]];
 <|"Format"->"FeynFacet-DifferentialConsequencesOfMasterCoefficients","Values"->values,
  "Derivations"->derived,"UnresolvedRequests"->KeySelect[upperOrders,
    !KeyExistsQ[values,#]||values[#]["KnownThroughOrder"]<upperOrders[#]&],
  "PendingOrderRequirements"->DeleteDuplicates[pending],"EndpointDistributionsSolved"->False|>
],"CutFamily"];
cutRetainedIntegralRuleEquations[rules_List]:=DeleteCases[Map[Function[rule,
  With[{parsed=linearIntegralSum[First[rule]-Last[rule]]},
   If[!linearIntegralSumQ[parsed]||Together[parsed["Remainder"]]=!=0,
    cutFamilyFail["LinearInitialIntegralReductionRequired"]];parsed["Terms"]]],rules],<||>];
(* Cumulative maps always express the earliest recorded integrals in the
   current basis. Immediate step maps may coexist as diagnostic provenance. *)
cutOriginalMasterEmbedding[system_Association] := Module[{stored},
 stored=Lookup[system,"OriginalMasterIntegralEmbedding",None];
 If[AssociationQ[stored],Return[stored]];
 stored=Lookup[system,"MasterBasisReduction",None];
 If[AssociationQ[stored],Return[<|
  "MasterIntegralBasis"->stored["OriginalMasterIntegralBasis"],
  "EmbeddingMatrix"->stored["EmbeddingMatrix"]|>]];
 <|"MasterIntegralBasis"->system["MasterIntegralBasis"],
   "EmbeddingMatrix"->IdentityMatrix[Length[system["MasterIntegralBasis"]]]|>
];
cutInverseDimensionRule[system_Association] := Module[{e,rule,value,constant,slope},
 e=system["DimensionalRegulator"];rule=Lookup[system,"DimensionRule",D->4-2e];
 If[!MatchQ[rule,_Rule]||First[rule]=!=D,
  cutFamilyFail["DeclaredAffineDimensionRuleRequired"]];
 value=Last[rule];
 If[!FreeQ[value,D]||!PolynomialQ[value,e]||Exponent[value,e]=!=1,
  cutFamilyFail["DeclaredAffineDimensionRuleRequired"]];
 constant=value/.e->0;slope=Coefficient[value,e];
 If[slope===0,cutFamilyFail["InvertibleDimensionRuleRequired"]];
 e->Cancel[(D-constant)/slope]
];

cutConnectionMatrices[system_Association]:=Module[
 {variables=system["KinematicVariables"],basis=system["MasterIntegralBasis"],matrices=system["ConnectionMatrices"]},
 If[AssociationQ[matrices],
  If[Sort[Keys[matrices]]=!=Sort[variables],cutFamilyFail["ConnectionAxesMustMatchKinematicVariables"]];
  matrices=Lookup[matrices,variables]];
 If[!ListQ[matrices]||Length[matrices]=!=Length[variables]||
  !AllTrue[matrices,Dimensions[#]==={Length[basis],Length[basis]}&],
  cutFamilyFail["CompleteMasterConnectionMatricesRequired"]];
 Normal/@matrices
];

ConstructCutDifferentialSystem[families:{__Association},targets:{__FeynCalc`GLI},
 parameters:{__Symbol},request_Association]:=Catch[Module[
 {records,names,byName,directory,iterations,moving,baseRequest,reduction,basis,nextBasis,
  allTargets,derivatives,newTargets,history={},matrices,images,iteration,closed=False,
  derivativeRequest,rows,residual,flatness,points,checks,unknown,coefficients,regulator,seconds,
  seedRefinement,seedPlans,seeds,frontier,local,extra,added,refinementHistory={},
  initial=Lookup[request,"InitialReduction",None],definition,initialRelations,restrictedTargets,restricted,
   eliminateKnown=Lookup[request,"EliminateKnownRules",False],knownRequest,suppliedKnown},
 If[!DuplicateFreeQ[parameters]||!StringQ[Lookup[request,"WorkingDirectory",None]],
  cutFamilyFail["DistinctDEParametersAndWorkingDirectoryRequired"]];
 records=FeynFacet`CreateCutIntegralFamily/@families;
 If[!AllTrue[records,AssociationQ],cutFamilyFail["ValidatedCutIntegralFamiliesRequired"]];
 names=First[#["Topology"]]&/@records;
 If[!DuplicateFreeQ[names],cutFamilyFail["DistinctCutFamiliesRequired"]];
 byName=AssociationThread[names,records];
 directory=ExpandFileName[request["WorkingDirectory"]];
 iterations=Lookup[request,"MaximumClosureIterations",8];
 If[!IntegerQ[iterations]||iterations<1,cutFamilyFail["PositiveClosureIterationLimitRequired"]];
 moving=Lookup[request,"MomentumDerivatives",<||>];
 If[!AssociationQ[moving]||!SubsetQ[parameters,Keys[moving]],
  cutFamilyFail["MomentumDerivativesIndexedByDEParameterRequired"]];
 baseRequest=KeyDrop[request,{"MomentumDerivatives","MaximumClosureIterations","ValidationPoints",
  "DimensionalRegulator","DimensionRule","RefineDerivativeSeeds","InitialReduction","EliminateKnownRules"}];
  If[!MemberQ[{True,False},eliminateKnown],cutFamilyFail["BooleanKnownRuleEliminationRequired"]];
  knownRequest[prior_]:=If[TrueQ[eliminateKnown],
    <|"KnownIntegralRules"->Select[prior["Rules"],First[#]=!=Last[#]&]|>,<||>];
  suppliedKnown=Lookup[request,"KnownIntegralRules",{}];
  If[suppliedKnown=!={},
   If[validateCutGLIs[suppliedKnown,records]=!=True||
     !AssociationQ[FeynFacet`EliminateKnownIntegralRules[{},targets,suppliedKnown]],
    cutFamilyFail["ExactCompatibleKnownIntegralRulesRequired"]];
   (* A later export may omit identities outside its target selection.
      Retain the original pool as equations independently of that export. *)
   AssociateTo[baseRequest,"ExtraEquations"->Join[Lookup[baseRequest,"ExtraEquations",{}],
     cutRetainedIntegralRuleEquations[suppliedKnown]]]];
 seedRefinement=Lookup[request,"RefineDerivativeSeeds",Lookup[request,"SeedPolicy","Rectangular"]==="TargetDownsets"];
 If[!MemberQ[{True,False},seedRefinement],cutFamilyFail["BooleanDerivativeSeedRefinementRequired"]];
 allTargets=Sort[DeleteDuplicates[targets]];
 If[initial===None,
  reduction=FeynFacet`KiraReduction[records,allTargets,Join[baseRequest,
   <|"WorkingDirectory"->FileNameJoin[{directory,"InitialReduction"}]|>]],
  definition[record_]:=Join[cutDefinitionConventions[record],KeyTake[record,{"Topology","Cuts"}]];
  If[!AssociationQ[initial]||Lookup[initial,"Format",None]=!="FeynFacet-CutFamilyReduction"||
    !ContainsAll[Keys[initial],{"Families","Targets","Rules","Masters"}]||
    (definition/@initial["Families"])=!=(definition/@records)||
    !ListQ[initial["Targets"]]||!ListQ[initial["Masters"]]||
    !MatchQ[initial["Rules"],{(_Rule)...}]||!ContainsAll[initial["Targets"],allTargets]||
    validateCutGLIs[{initial["Rules"],initial["Targets"],initial["Masters"]},records]=!=True,
   cutFamilyFail["CompatibleInitialCutReductionRequired"]];
  initialRelations=cutRetainedIntegralRuleEquations[initial["Rules"]];
  AssociateTo[baseRequest,"ExtraEquations"->Join[Lookup[baseRequest,"ExtraEquations",{}],initialRelations]];
  reduction=initial;
  Print["Resuming differential closure from ",Length[ibpCloseReductionRules[initial["Rules"],allTargets]["Masters"]]," spanning integrals and ",
   Length[initialRelations]," retained exact relations"]];
 If[!AssociationQ[reduction],cutFamilyFail["InitialCutReductionFailed",<|"Cause"->reduction|>]];
 basis=Sort[ibpCloseReductionRules[reduction["Rules"],allTargets]["Masters"]];
 If[basis==={},cutFamilyFail["NonzeroCutMasterBasisRequired"]];
 Do[
  {seconds,derivatives}=AbsoluteTiming[Table[
    derivativeRequest=If[KeyExistsQ[moving,parameter],
      <|"MomentumDerivatives"->moving[parameter]|>,<||>];
    FeynFacet`DifferentiateCutIntegral[byName[master[[1]]],master,parameter,derivativeRequest],
   {parameter,parameters},{master,basis}]];
  If[!FreeQ[derivatives,_Failure|$Failed|$Aborted],
   cutFamilyFail["CutMasterDifferentiationFailed",<|"Derivatives"->derivatives|>]];
  newTargets=Sort[DeleteDuplicates[Join[basis,Cases[derivatives,_FeynCalc`GLI,Infinity]]]];
  If[!SubsetQ[reduction["Targets"],newTargets],
   allTargets=Union[allTargets,newTargets];
   reduction=FeynFacet`KiraReduction[records,allTargets,Join[baseRequest,knownRequest[reduction],
    <|"WorkingDirectory"->FileNameJoin[{directory,"DerivativeClosure"<>ToString[iteration]}]|>]];
   If[!AssociationQ[reduction],cutFamilyFail["DerivativeCutReductionFailed",<|"Cause"->reduction|>]]];
  nextBasis=Sort[ibpCloseReductionRules[reduction["Rules"],Union[targets,newTargets]]["Masters"]];
  (* A target downset alone need not contain the harder equations needed to
     eliminate raised measurement cuts. Refine at the newly exposed masters,
     rather than repeatedly differentiating them to still higher cut powers.
     This chooses extra equations; it never restricts their integral columns. *)
  If[seedRefinement&&nextBasis=!=basis,
   seedPlans=Table[FeynFacet`PlanCutIBPSeeds[family,
     Select[allTargets,#[[1]]===family["Topology"][[1]]&]],{family,records}];
   If[!AllTrue[seedPlans,AssociationQ],cutFamilyFail["DerivativeTargetSeedPlansRequired"]];
   seeds=Union[Lookup[baseRequest,"SeedIntegrals",{}],Flatten[Lookup[seedPlans,"Seeds"],1]];
   frontier=Complement[nextBasis,basis];added={};
   Do[
    local=Select[frontier,#[[1]]===family["Topology"][[1]]&];If[local==={},Continue[]];
    extra=FeynFacet`FindCutIBPPredecessorSeeds[family,local,
      Select[seeds,#[[1]]===family["Topology"][[1]]&],<|"FrontierNeighborDepth"->1|>];
    If[!AssociationQ[extra],cutFamilyFail["DerivativePredecessorSeedSelectionFailed",<|"Cause"->extra|>]];
    added=Join[added,extra["Seeds"]],{family,records}];
   If[added=!={},
    AssociateTo[baseRequest,"SeedIntegrals"->Union[seeds,added]];
    Print["Refining derivative reduction with ",Length[added]," predecessor seeds"];
    reduction=FeynFacet`KiraReduction[records,allTargets,Join[baseRequest,knownRequest[reduction],
      <|"WorkingDirectory"->FileNameJoin[{directory,"DerivativeSeedRefinement"<>ToString[iteration]}]|>]];
    If[!AssociationQ[reduction],cutFamilyFail["RefinedDerivativeReductionFailed",<|"Cause"->reduction|>]];
    AppendTo[refinementHistory,<|"Iteration"->iteration,"FrontierCount"->Length[frontier],
      "AdditionalSeedCount"->Length[added],"SeedCount"->Length[baseRequest["SeedIntegrals"]]|>];
    nextBasis=Sort[ibpCloseReductionRules[reduction["Rules"],Union[targets,newTargets]]["Masters"]]]];
  AppendTo[history,<|"Iteration"->iteration,"InputBasisCount"->Length[basis],
   "ReducedBasisCount"->Length[nextBasis],"TargetCount"->Length[allTargets],
   "DifferentiationSeconds"->seconds|>];
  If[nextBasis===basis,closed=True;Break[]];
  basis=nextBasis,
 {iteration,iterations}];
 If[!closed,cutFamilyFail["CutDifferentialClosureIncomplete",<|"History"->history,
   "RemainingBasis"->basis,"Reduction"->reduction|>]];
 restrictedTargets=Union[targets,basis,Cases[derivatives,_FeynCalc`GLI,Infinity]];
 restricted=ibpCloseReductionRules[reduction["Rules"],restrictedTargets];
 If[Sort[restricted["Masters"]]=!=basis,cutFamilyFail["RestrictedCutReductionMustSpanDEBasis"]];
 reduction=Join[reduction,<|"Targets"->restrictedTargets,"Rules"->restricted["Rules"],"Masters"->basis,
   "Restriction"->"Requested source integrals and derivatives of the closed DE basis. The complete native solve remains in its recorded workspace."|>];
 images=Map[Factor,derivatives/.Dispatch[reduction["Rules"]],{2}];
 unknown=Complement[DeleteDuplicates[Cases[images,_FeynCalc`GLI,Infinity]],basis];
 If[unknown=!={},cutFamilyFail["UnreducedCutDerivatives",<|"Integrals"->unknown|>]];
 matrices=Table[
  rows=Table[coefficients=Coefficient[expression,#]&/@basis;
    If[Factor[expression-coefficients.basis]=!=0,cutFamilyFail["LinearCutDerivativeRequired"]];
    coefficients,{expression,images[[axis]]}];
  SparseArray[rows],{axis,Length[parameters]}];
 points=Lookup[request,"ValidationPoints",{}];
 If[!MatchQ[points,{{(_Rule)..}...}],cutFamilyFail["ExactRationalValidationPointsRequired"]];
 checks=cutDifferentialFlatnessCheck[matrices,parameters,points];
 regulator=Lookup[request,"DimensionalRegulator",Global`Epsilon];
 <|"DataType"->"CutMasterDifferentialSystem","SchemaVersion"->1,
  "KinematicVariables"->parameters,"DimensionalRegulator"->regulator,
  "DimensionRule"->Lookup[request,"DimensionRule",D->4-2regulator],
  "MasterIntegralBasis"->basis,"ConnectionMatrices"->matrices,
  "RequestedMasterIntegrals"->targets,"RequestedMasterValues"->(targets/.Dispatch[reduction["Rules"]]),
  "Families"->records,"Reduction"->reduction,"ClosureHistory"->history,
  "SeedRefinementHistory"->refinementHistory,"Validation"->checks,
  "InitialReductionReused"->(initial=!=None),
  "MomentumDerivatives"->moving,
  "PhysicalBoundaryConditionsApplied"->False,"MinimalMasterCountDetermined"->False|>
],"CutFamily"];

(* Differentiate before specialization, but multiply only after it when
   rational sample checks were requested. Constructing the full symbolic
   commutator first defeats the purpose of the inexpensive sampled check. *)
cutDifferentialFlatnessCheck[matrices_List,parameters_List,points_List] := Module[
 {derivatives,flatness,residual,sampled,derivativeValues},
 derivatives=Table[D[Normal[matrices[[j]]],parameters[[i]]],
   {i,Length[parameters]},{j,Length[parameters]}];
 If[points==={},
  residual=TimeConstrained[
   flatness=Flatten[Table[
    Normal[derivatives[[i,j]]-derivatives[[j,i]]+
     matrices[[j]].matrices[[i]]-matrices[[i]].matrices[[j]]],
    {i,Length[parameters]},{j,i+1,Length[parameters]}]];
   Factor/@flatness,10,$Aborted];
  If[residual===$Aborted,cutFamilyFail["FlatnessCheckNeedsRationalValidationPoints"]];
  If[!AllTrue[residual,#===0&],cutFamilyFail["CutDifferentialSystemNotFlat",<|"Residual"->residual|>]];
  Return[<|"Method"->"ExactRationalFunctions","FlatnessPassed"->True|>]];
 Do[
  sampled=Normal/@matrices/.point;derivativeValues=derivatives/.point;
  If[!AllTrue[Flatten[{sampled,derivativeValues}],MatchQ[#,_Integer|_Rational]&],
   cutFamilyFail["CutDifferentialFlatnessSampleFailed",<|"Point"->point,
    "Reason"->"The connection or its derivatives have an undefined or nonrational specialization."|>]];
  residual=Flatten[Table[derivativeValues[[i,j]]-derivativeValues[[j,i]]+
    sampled[[j]].sampled[[i]]-sampled[[i]].sampled[[j]],
   {i,Length[parameters]},{j,i+1,Length[parameters]}]];
  If[!AllTrue[residual,#===0&],
   cutFamilyFail["CutDifferentialFlatnessSampleFailed",<|"Point"->point,"Residual"->residual|>]],
 {point,points}];
 <|"Method"->"ExactRationalSpecializations","Points"->points,"FlatnessPassed"->True|>
];

IntegralRelationsFromCutDifferentialSystem[system_Association,request_Association:<||>]:=Catch[Module[
 {masters,matrices,parameters,families,byName,derivatives,relations,parsed,rows,extra,scalarRules,inverseDimension,moving},
 If[!ContainsAll[Keys[system],{"MasterIntegralBasis","ConnectionMatrices","KinematicVariables","Families"}],
  cutFamilyFail["ExactCutDifferentialSystemRequired"]];
 {masters,matrices,parameters,families}=Lookup[system,
  {"MasterIntegralBasis","ConnectionMatrices","KinematicVariables","Families"}];
 scalarRules=Lookup[request,"ScalarRules",{}];
 matrices=cutConnectionMatrices[system];
 inverseDimension=cutInverseDimensionRule[system];
 moving=Lookup[request,"MomentumDerivatives",Lookup[system,"MomentumDerivatives",<||>]];
 If[!AssociationQ[moving]||!SubsetQ[parameters,Keys[moving]],
  cutFamilyFail["MomentumDerivativesIndexedByDEParameterRequired"]];
 If[KeyExistsQ[system,"MomentumDerivatives"]&&moving=!=system["MomentumDerivatives"],
  cutFamilyFail["MatchingMomentumDerivativeOperatorsRequired"]];
 If[!MatchQ[masters,{__FeynCalc`GLI}]||Length[matrices]=!=Length[parameters]||
  !AllTrue[matrices,Dimensions[#]==={Length[masters],Length[masters]}&]||
  !MatchQ[scalarRules,{(_Rule)...}]||validateCutGLIs[masters,families]=!=True,
  cutFamilyFail["ExactTypedMasterDEDataRequired"]];
 byName=Association[(#["Topology"][[1]]->#)&/@families];
 rows=Flatten[Table[
  extra=Lookup[moving,parameters[[j]],None];
  derivatives=FeynFacet`DifferentiateCutIntegral[byName[master[[1]]],master,parameters[[j]],
   If[extra===None,<||>,<|"MomentumDerivatives"->extra|>]];
  If[FailureQ[derivatives],cutFamilyFail["KnownMasterDifferentiationFailed",<|"Cause"->derivatives|>]];
  relations=(((derivatives-Normal[matrices[[j]]][[i]].masters)/.inverseDimension)/.scalarRules)/.inverseDimension;
  parsed=linearIntegralSum[relations];
  If[!linearIntegralSumQ[parsed]||Cancel[Together[parsed["Remainder"]]]=!=0,
   cutFamilyFail["HomogeneousIntegralDifferentialRelationRequired"]];
  Select[Cancel[Together[#]]&/@parsed["Terms"],#=!=0&],
 {j,Length[parameters]},{i,Length[masters]},{master,{masters[[i]]}}],2];
 rows=DeleteCases[DeleteDuplicates[rows],<||>];
 <|"Format"->"FeynFacet-IBPEquations","Rows"->rows,
  "EquationSource"->"KnownExactDifferentialSystem",
  "MasterIntegralBasis"->masters,"KinematicVariables"->parameters,
  "DimensionConvention"->D,"MomentumDerivatives"->moving,
  "Scope"->"Assumes the supplied exact DE and typed definitions; no epsilon-truncated scalar values were used."|>
],"CutFamily"];
ReduceMasterDifferentialSystem[system_Association,reduction_Association,request_Association:<||>]:=Catch[Module[
 {old,basis,rules,variables,positions,images,allObjects,index,entries,map,matrices=<||>,
  checks=<||>,a,reduced,residual,values,cancel,families,relations={},close,restricted,inner,rows,newBasis,newMap,answer,preference,ordered,sampled,pivotRows,points,point,originalEmbedding,sourceMatrices,classMap,product,restrictionInput,newConnections,sourceInD},
 {old,variables}=Lookup[system,{"MasterIntegralBasis","KinematicVariables"},None];
 basis=Lookup[reduction,"Masters",None];rules=Lookup[reduction,"Rules",None];
 If[!ListQ[old]||!ListQ[basis]||!ListQ[rules]||!ListQ[variables]||
  !ContainsAll[old,basis],
  cutFamilyFail["MasterDifferentialSystemAndSubsetBasisReductionRequired"]];
 sourceMatrices=AssociationThread[variables,cutConnectionMatrices[system]];
 close=Lookup[request,"CloseDifferentialRelations",False];
 If[!MemberQ[{True,False},close],cutFamilyFail["ExplicitDifferentialRelationClosureChoiceRequired"]];
 positions=Flatten[FirstPosition[old,#,Missing[],{1},Heads->False]&/@basis];
 images=old/.Dispatch[rules];allObjects=Union[Cases[images,_FeynCalc`GLI,{0,Infinity}]];
 If[!ContainsAll[basis,allObjects],cutFamilyFail["EveryOldMasterMustReduceToTheRequestedSubset"]];
 index=AssociationThread[basis,Range[Length[basis]]];
 entries=Flatten[MapIndexed[Function[{expression,row},
   Map[Function[master,{First[row],index[master]}->Coefficient[expression,master]],
     DeleteDuplicates[Cases[expression,_FeynCalc`GLI,{0,Infinity}]]]],images],1];
 map=SparseArray[Select[entries,Last[#]=!=0&],{Length[old],Length[basis]}];
 classMap=If[AllTrue[images,MatchQ[#,_FeynCalc`GLI]&],(index[#]&/@images),None];
 If[!AllTrue[Expand[images-Normal[map].basis],#===0&],
  cutFamilyFail["LinearMasterBasisEmbeddingRequired"]];
 cancel[m_]:=Module[{flat=FeynFacet`CancelRationalCoefficients[Flatten[Normal[m]]]},
   If[!ListQ[flat],cutFamilyFail["ExactDifferentialMatrixCancellationFailed",<|"Cause"->flat|>]];
   Partition[flat,Last[Dimensions[m]]]];
 If[cancel[map[[positions,All]]-IdentityMatrix[Length[basis]]]=!=ConstantArray[0,{Length[basis],Length[basis]}],
  cutFamilyFail["SelectedMasterReductionMustBeTheIdentity"]];
 Do[
  a=sourceMatrices[variable];
  If[Dimensions[a]=!={Length[old],Length[old]},cutFamilyFail["CompleteOriginalMasterConnectionMatrixRequired"]];
  If[ListQ[classMap],
   (* An integral-class map has one unit per row. Its left product gathers
      representative rows; form the right product just once. *)
   product=Normal[SparseArray[a].map];
   reduced=cancel[product[[positions]]];
   residual=cancel[product[[positions[[classMap]]]]-product],
   reduced=cancel[Normal[SparseArray[a[[positions,All]]].map]];
   residual=cancel[D[Normal[map],variable]+
     Normal[map.SparseArray[reduced]-SparseArray[a].map]]];
  If[!AllTrue[Flatten[residual],#===0&],
   If[!close,cutFamilyFail["MasterReductionDifferentialCompatibilityFailed",<|"Variable"->variable,"Residual"->residual|>]];
   relations=Join[relations,Select[residual,!AllTrue[#, #===0&]&]]];
  AssociateTo[matrices,variable->SparseArray[reduced]];AssociateTo[checks,variable->True],
 {variable,variables}];
 If[relations=!={},
  (* A spanning set need not be independent. Differentiate its exact identities
     and close the resulting physical constraints before selecting a smaller
     subset. The final embedding is checked again against every original DE. *)
  restrictionInput=Join[KeyTake[system,{"KinematicVariables","DimensionalRegulator","DimensionRule"}],
    <|"MasterIntegralBasis"->basis,"OriginalMasterIntegralBasis"->basis,
      "Dimension"->Length[basis],"ConnectionMatrices"->Values[matrices]|>];
  restricted=FeynFacet`RestrictDifferentialSystemToRelations[
    restrictionInput,relations,
    Join[KeyTake[request,{"ValidationPoints"}],
     <|"RelationProvenance"->"Differentiation of supplied exact integral identities in the original differential system."|>]];
  If[!AssociationQ[restricted],cutFamilyFail["MasterDifferentialRelationClosureFailed",<|"Cause"->restricted|>]];
  inner=restricted["SolutionEmbedding"];rows=restricted["FreeColumns"];
  If[inner[[rows]]=!=IdentityMatrix[Length[rows]],cutFamilyFail["FreeCoordinateEmbeddingRequired"]];
  (* The closure routine uses epsilon; return the change of integral basis
     in the dimension convention used by the input reduction. *)
  sourceInD=!FreeQ[{Values[sourceMatrices],Normal[map]},D];
  newConnections=restricted["ConnectionMatrices"];
  If[sourceInD,
   inner=inner/.cutInverseDimensionRule[system];
   newConnections=newConnections/.cutInverseDimensionRule[system]];
  newBasis=basis[[rows]];newMap=cancel[Normal[map.SparseArray[inner]]];
  preference=Lookup[request,"PreferredMasterIntegrals",Automatic];
  If[preference===Automatic,
   (* C E=0 and dE+E Bnew-B E=0 certify d(RE)+(RE)Bnew-A(RE)=0.
      Free coordinates are already original integral rows; no nullspace
      normalization or repeated full original-system products are needed. *)
   residual=cancel[Normal[SparseArray[relations].SparseArray[inner]]];
   If[!AllTrue[Flatten[residual],#===0&],cutFamilyFail["ClosedIntegralRelationsFailed"]];
   newBasis=basis[[rows]];
   originalEmbedding=cutOriginalMasterEmbedding[system];
   answer=Join[system,
    If[KeyExistsQ[system,"RequestedMasterValues"],
     <|"RequestedMasterValues"->(system["RequestedMasterValues"]/.Dispatch[Thread[old->(newMap.newBasis)]])|>,<||>],
    <|"OriginalMasterIntegralEmbedding"->Join[originalEmbedding,
       <|"EmbeddingMatrix"->cancel[Normal[SparseArray[originalEmbedding["EmbeddingMatrix"]].SparseArray[newMap]]]|>],
      "MasterIntegralBasis"->newBasis,
      "Families"->Select[system["Families"],MemberQ[First/@newBasis,#["Topology"][[1]]]&],
      "ConnectionMatrices"->AssociationThread[variables,SparseArray/@newConnections],
      "MasterBasisReduction"-><|"OriginalMasterIntegralBasis"->old,"EmbeddingMatrix"->newMap,
       "SelectedOriginalRows"->positions[[rows]],"ExactDifferentialCompatibility"->checks,
       "SubsetIdentityVerified"->True,"VerificationMethod"->"FactoredExactDifferentialIdentities"|>,
      "ExternalEndpointUniformityEstablished"->False|>];
   answer=cutWithComposedReduction[answer,system,old,newBasis,newMap];
   Return[Join[answer,<|"AdditionalMasterRelations"-><|"SpanningBasis"->basis,
     "Relations"->relations,"DifferentialClosure"->restricted,"SpanningBasisEmbedding"->inner,
     "Provenance"->"Exact differential consequences of the supplied integral identities and original DE."|>|>],Module]];

  If[!ListQ[preference]||!DuplicateFreeQ[preference]||!ContainsAll[old,preference],
   cutFamilyFail["PreferredMasterIntegralsMustBelongToOriginalSystem"]];
  ordered=Join[(First@FirstPosition[old,#]&/@preference),
   Complement[Range[Length[old]],(First@FirstPosition[old,#]&/@preference)]];
  points=Lookup[request,"ValidationPoints",{}];
  If[points=!={},
   point=differentialDimensionPoint[First[points],system,"Both"];
   If[FailureQ[point],cutFamilyFail["ConsistentMasterBasisSelectionPointRequired",<|"Cause"->point|>]];
   sampled=newMap/.point;
   If[!MatrixQ[sampled,exactRationalQ],cutFamilyFail["CompleteRationalMasterBasisSelectionPointRequired"]];
   (* Sampling chooses a row subset only. The inversion and every subsequent
      identity are exact; an unlucky point never certifies a false relation. *)
   pivotRows=globalDEIndependentRows[sampled[[ordered]]];
   If[Length[pivotRows]===Length[newBasis],
    rows=ordered[[pivotRows]];newBasis=old[[rows]];
    newMap=cancel[newMap.globalDEExactInverse[newMap[[rows]]]];
    inner=newMap[[positions]]]];
  answer=FeynFacet`ReduceMasterDifferentialSystem[system,
    <|"Masters"->newBasis,"Rules"->Thread[old->(newMap.newBasis)]|>];
  If[!AssociationQ[answer],cutFamilyFail["ClosedMasterDifferentialEmbeddingFailed",<|"Cause"->answer|>]];
  Return[Join[answer,<|"AdditionalMasterRelations"-><|"SpanningBasis"->basis,
    "Relations"->relations,"DifferentialClosure"->restricted,
    "SpanningBasisEmbedding"->inner,
    "Provenance"->"Exact differential consequences; assumes the supplied physical integral reduction and original DE."|>|>],Module]];
 families=Select[system["Families"],MemberQ[First/@basis,#["Topology"][[1]]]&];
 originalEmbedding=cutOriginalMasterEmbedding[system];
 answer=Join[system,If[KeyExistsQ[system,"RequestedMasterValues"],
   <|"RequestedMasterValues"->(system["RequestedMasterValues"]/.Dispatch[rules])|>,<||>],
  <|"OriginalMasterIntegralEmbedding"->Join[originalEmbedding,
    <|"EmbeddingMatrix"->cancel[originalEmbedding["EmbeddingMatrix"].map]|>],
   "MasterIntegralBasis"->basis,"Families"->families,"ConnectionMatrices"->matrices,
  "MasterBasisReduction"-><|"OriginalMasterIntegralBasis"->old,"EmbeddingMatrix"->map,
    "SelectedOriginalRows"->positions,"ExactDifferentialCompatibility"->checks,
    "SubsetIdentityVerified"->True|>,
  "ExternalEndpointUniformityEstablished"->False|>];
 cutWithComposedReduction[answer,system,old,basis,Normal[map]]
],"CutFamily"];

(* A basis change must also retain rules for former masters, which native
   exporters may omit because they were identities in the previous basis. *)
cutComposeIntegralReduction[reduction_Association,mapping_List,masters_List]:=Module[
 {replacement=Dispatch[mapping],oldRules=reduction["Rules"],rules,images,required},
 images=Thread[reduction["Masters"]->(reduction["Masters"]/.replacement)];
 rules=Normal[Association[Join[
   (First[#]->(Last[#]/.replacement))&/@oldRules,images,mapping]]];
 rules=Select[rules,First[#]=!=Last[#]&];
 required=Union[Lookup[reduction,"Targets",{}],First/@oldRules,reduction["Masters"],First/@mapping];
 If[!ContainsAll[Join[First/@rules,masters],required]||
   !ContainsAll[masters,DeleteDuplicates[Cases[Last/@rules,_FeynCalc`GLI,{0,Infinity}]]],
  cutFamilyFail["CompleteComposedIntegralReductionRequired"]];
 Join[reduction,<|"Masters"->masters,"Rules"->rules|>]
];

cutWithComposedReduction[answer_Association,source_Association,old_List,basis_List,map_]:=Module[
 {reduction=Lookup[source,"Reduction",None]},
 If[reduction===None,Return[answer]];
 If[!AssociationQ[reduction],cutFamilyFail["ClosedSourceIntegralReductionRequired"]];
 Join[answer,<|"Reduction"->cutComposeIntegralReduction[
   reduction,Thread[old->(map.basis)],basis]|>]
];

ReduceEquivalentMasterIntegrals[system_Association,request_Association]:=Catch[Module[
 {old=system["MasterIntegralBasis"],sourceReduction=system["Reduction"],equivalences,representatives,
  rules,reduced},
 If[!AssociationQ[sourceReduction]||!ListQ[Lookup[sourceReduction,"Masters",None]]||
  Sort[sourceReduction["Masters"]]=!=Sort[old]||
  !ListQ[sourceReduction["Rules"]],cutFamilyFail["ReductionInCurrentMasterBasisRequired"]];
 equivalences=FeynFacet`FindCutIntegralEquivalences[old,system["Families"],
  "Normalization"->"Explicit typed integral definitions",
  "OrdinaryPrescriptionGeometry"->Lookup[request,"OrdinaryPrescriptionGeometry",None]];
 If[!AssociationQ[equivalences]||!AllTrue[equivalences["Mappings"],#["Factor"]===1&],
  cutFamilyFail["ExactNonzeroMasterIntegralEquivalencesRequired",<|"Cause"->equivalences|>]];
 representatives=equivalences["RepresentativeMasterIntegrals"];
 If[TrueQ[Lookup[request,"Verbose",False]],
  Print["EXACT AFFINE MASTER CLASSES ",Length[representatives]," / ",Length[old]]];
 If[Length[representatives]===Length[old],Return[Join[system,<|"IntegralEquivalences"->equivalences|>],Module]];
 rules=Select[(#["Source"]->#["Representative"])&/@equivalences["Mappings"],First[#]=!=Last[#]&];
 reduced=FeynFacet`ReduceMasterDifferentialSystem[system,<|"Masters"->representatives,"Rules"->rules|>,
  Join[KeyTake[request,{"ValidationPoints"}],<|"CloseDifferentialRelations"->True|>]];
 If[!AssociationQ[reduced],cutFamilyFail["EquivalentMasterDifferentialReductionFailed",<|"Cause"->reduced|>]];
 If[TrueQ[Lookup[request,"Verbose",False]],
  Print["EXACT DIFFERENTIAL MASTER RELATIONS CLOSED ",Length[reduced["MasterIntegralBasis"]]]];
 Join[reduced,<|"IntegralEquivalences"->equivalences|>]
],"CutFamily"];

SelectMasterIntegralBasis[system_Association,reduction_Association,request_Association]:=Catch[Module[
 {basis,variables,matrices,candidates,points,point,rules,sourceBasis,basisRules={},images,objects,
  matrix,cancel,ordered,sample,rows,selected,s,si,connections,residual,proof,families,n,rel,oldMap,answer,cutIndices,originalEmbedding,substitution,trialPoint,trialRows,samplingAttempts={},newReduction},
 basis=system["MasterIntegralBasis"];variables=system["KinematicVariables"];n=Length[basis];
 matrices=system["ConnectionMatrices"];
 If[AssociationQ[matrices],matrices=Lookup[matrices,variables]];
 matrices=Normal/@matrices;
 candidates=Lookup[request,"CandidateIntegrals",None];points=Lookup[request,"ValidationPoints",{}];
 If[!ListQ[candidates]||!AllTrue[candidates,MatchQ[#,_FeynCalc`GLI]&]||points==={}||
   !AllTrue[matrices,Dimensions[#]==={n,n}&],
  cutFamilyFail["ExactCandidateIntegralsAndRationalSelectionPointsRequired"]];
 sourceBasis=Lookup[reduction,"Masters",None];
 If[ListQ[sourceBasis]&&Sort[sourceBasis]===Sort[basis],sourceBasis=basis];
 If[sourceBasis=!=basis,
  rel=Lookup[system,"AdditionalMasterRelations",<||>];
  If[!ContainsAll[Keys[rel],{"SpanningBasis","SpanningBasisEmbedding"}]||
    sourceBasis=!=rel["SpanningBasis"],
   cutFamilyFail["ExactReductionToSystemBasisMapRequired"]];
  basisRules=Thread[sourceBasis->(rel["SpanningBasisEmbedding"].basis)]];
 rules=Association[reduction["Rules"]];
 Do[If[!KeyExistsQ[rules,master],AssociateTo[rules,master->master]],{master,sourceBasis}];
 candidates=DeleteDuplicates[Join[candidates,basis]];
 If[TrueQ[Lookup[request,"RequireUnitCutBasis",False]],
  cutIndices=Association[(#["Topology"][[1]]->#["CutIndices"])&/@reduction["Families"]];
  candidates=Select[candidates,With[{indices=Lookup[cutIndices,#[[1]],Missing["Family"]]},
    ListQ[indices]&&AllTrue[#[[2,indices]],#===1&]]&];
  If[candidates==={},cutFamilyFail["UnitCutBasisCandidatesRequired"]]];
 If[!AllTrue[candidates,KeyExistsQ[rules,#]&],
  cutFamilyFail["EveryBasisCandidateMustHaveAnExactIntegralReduction"]];
 substitution=Dispatch[basisRules];
 images=(Lookup[rules,Key[#]]/.substitution)&/@candidates;
 objects=Union[Cases[images,_FeynCalc`GLI,{0,Infinity}]];
 If[!ContainsAll[basis,objects],cutFamilyFail["CandidateIntegralImagesMustCloseOnSystemBasis"]];
 cancel[m_]:=Module[{values=FeynFacet`CancelRationalCoefficients[Flatten[Normal[m]]]},
  If[!ListQ[values],cutFamilyFail["ExactMasterBasisCancellationFailed",<|"Cause"->values|>]];
  Partition[values,Last[Dimensions[m]]]];
 matrix=Table[Coefficient[im,master],{im,images},{master,basis}];
 If[!AllTrue[Expand[images-matrix.basis],#===0&],cutFamilyFail["LinearCandidateIntegralImagesRequired"]];
 matrix=cancel[matrix];
 ordered=SortBy[Range[Length[candidates]],Function[j,
  {Total[Max[0,-#]&/@candidates[[j,2]]],Total[Max[0,#]&/@candidates[[j,2]]],j}]];
 point=None;
 Do[
  trialPoint=differentialDimensionPoint[p,system,"Both"];
  If[FailureQ[trialPoint],
   cutFamilyFail["ConsistentMasterBasisSelectionPointRequired",<|"Cause"->trialPoint|>]];
  sample=Quiet[matrix/.trialPoint,{Power::infy,Infinity::indet}];
  If[!MatrixQ[sample,exactRationalQ],
   AppendTo[samplingAttempts,<|"Point"->trialPoint,"Status"->"NonrationalOrSingular"|>];Continue[]];
  trialRows=globalDEIndependentRows[sample[[ordered]]];
  AppendTo[samplingAttempts,<|"Point"->trialPoint,"Rank"->Length[trialRows]|>];
  If[Length[trialRows]===n,point=trialPoint;rows=ordered[[trialRows]];Break[]],
 {p,points}];
 If[point===None,cutFamilyFail["NoFullRankMasterBasisSelectionSample",
  <|"Attempts"->samplingAttempts,"RequiredRank"->n,"ExactNonspanEstablished"->False|>]];
 selected=candidates[[rows]];s=matrix[[rows]];
 si=globalDEExactInverse[s];
 If[FailureQ[si],cutFamilyFail["ExactMasterBasisInverseFailed",<|"Cause"->si|>]];
 If[!AllTrue[Flatten[cancel[s.si-IdentityMatrix[n]]],#===0&],
  cutFamilyFail["ExactMasterBasisInverseFailed"]];
 connections=Table[cancel[(D[s,variables[[j]]]+s.matrices[[j]]).si],{j,Length[variables]}];
 proof=Table[residual=cancel[D[si,variables[[j]]]+si.connections[[j]]-matrices[[j]].si];
  If[!AllTrue[Flatten[residual],#===0&],cutFamilyFail["SelectedMasterDifferentialCompatibilityFailed"]];
  variables[[j]]->True,{j,Length[variables]}];
 families=Select[reduction["Families"],MemberQ[First/@selected,#["Topology"][[1]]]&];
 originalEmbedding=cutOriginalMasterEmbedding[system];
 oldMap=originalEmbedding["EmbeddingMatrix"];
 substitution=Dispatch[Thread[basis->(si.selected)]];
 newReduction=cutComposeIntegralReduction[reduction,
  Join[Thread[sourceBasis->((sourceBasis/.Dispatch[basisRules])/.substitution)],
    Thread[basis->(si.selected)]],selected];
 answer=Join[KeyDrop[system,{"AdditionalMasterRelations","MasterBasisReduction","OriginalMasterIntegralEmbedding"}],
  If[KeyExistsQ[system,"RequestedMasterValues"],
    <|"RequestedMasterValues"->(system["RequestedMasterValues"]/.substitution)|>,<||>],
  <|"MasterIntegralBasis"->selected,"Families"->families,"ConnectionMatrices"->connections,
   "Reduction"->newReduction,
   "IntegralBasisChange"-><|"SourceMasterIntegralBasis"->basis,"SourceToSelectedMatrix"->s,
    "SelectedToSourceMatrix"->si,"CandidateIntegrals"->candidates,"SelectionPoint"->point,"SelectionAttempts"->samplingAttempts,
    "ExactDifferentialCompatibility"->Association[proof],"GlobalNonsingularityClaimed"->False|>,
   "ExternalEndpointUniformityEstablished"->False|>];
 AssociateTo[answer,"OriginalMasterIntegralEmbedding"->Join[originalEmbedding,
   <|"EmbeddingMatrix"->cancel[oldMap.si]|>]];
 answer
],"CutFamily"];
End[];EndPackage[];
