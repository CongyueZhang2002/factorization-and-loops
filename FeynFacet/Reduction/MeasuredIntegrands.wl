(* Prepare scalar source products before partial fractions. Unit-cut
   substitutions are explicitly separate from off-shell family definitions. *)
BeginPackage["FeynFacet`"];
PrepareCutIntegrand::usage="PrepareCutIntegrand[expression,phaseSpaceDefinition,request] prepares a full-dimensional rational cut integrand with or without an explicit measurement cut. Ordinary prescriptions require the shared compact-cut certificate before removal; off-shell family definitions remain available for dotted cuts.";
PrepareMeasuredCutIntegrand::usage="PrepareMeasuredCutIntegrand[expression,phaseSpaceDefinition,request] collects ordinary denominators, certifies their whole-product prescription limit using the shared compact-cut proof, and returns explicit polynomial numerators on the unit cuts. Request supplies ExternalKinematicConditions independent of the measurement. Off-shell denominator definitions are retained for later dotted-cut IBP and DEs.";
DecomposeMeasuredCutIntegrand::usage="DecomposeMeasuredCutIntegrand[prepared,request] partial-fractions only the original ordinary denominator polynomials, completes each independent support to an off-shell scalar-product basis, and returns explicit GLI coefficient rules and typed families. Possible exceptional external divisors are retained. Unit-cut numerator identities are not used as dotted-cut identities.";
MergeCutIntegralDecompositions::usage="MergeCutIntegralDecompositions[contributions] shares exactly identical typed families between named scalar contributions and unions their reduction targets. Family equality includes the full ordered propagators, momenta, kinematics, directed cuts, measure and assumptions. It makes no momentum-routing or prescription-equivalence inference.";
CancelMeasuredCutIntegrandDenominators::usage="CancelMeasuredCutIntegrandDenominators[prepared,request] cancels the complete rational density on unit cuts before family decomposition. Independent coefficient monomials are simplified separately. Unrestricted propagators and their common prescription certificate are retained.";
SimplifyMeasuredIntegralDecomposition::usage="SimplifyMeasuredIntegralDecomposition[data,request] cancels common factors in collected external scalar-integral coefficients, removes exact zeros and updates their targets. It can finish a saved numerator decomposition without repeating polynomial coordinate conversion.";
UnitCutScalarProductRules::usage="UnitCutScalarProductRules[definition,preserved] solves the independent unit-cut equations as affine full-D scalar-product substitutions, preferentially retaining the declared scalar products. These identities apply to numerators on unit cuts, never to unrestricted dotted-cut families.";
PrepareFinalStateMeasurementIntegrands::usage="PrepareFinalStateMeasurementIntegrands[scalar,phaseSpace,measurement,request] applies the card-defined final-state tuple weights, retains contact constraints, and prepares each distinct native polynomial measurement through the shared cut-integrand path.";
Begin["`Private`"];
measuredIntegrandFail[tag_,data_:<||>]:=Throw[Failure[tag,data],"MeasuredIntegrand"];
UnitCutScalarProductRules[input_Association,preserved_List:{}]:=Catch[Module[
 {definition,top,basis,coordinates,polynomials,matrix,constant,order,pivots={},rank=0,free,solution},
 definition=FeynFacet`CreateCutIntegralDefinition[input];
 If[!AssociationQ[definition],measuredIntegrandFail["TypedUnitCutDefinitionRequired"]];
 top=definition["Topology"];basis=definition["LoopScalarProducts"];
 coordinates=Table[Unique["unitCutCoordinate$"],{Length[basis]}];
 polynomials=Expand[definition["InversePropagators"][[definition["CutIndices"]]]]/.Thread[basis->coordinates];
  polynomials=Select[polynomials,PolynomialQ[#,coordinates]&&AllTrue[First/@CoefficientRules[#,coordinates],Total[#]<=1&]&];
 If[!AllTrue[polynomials,PolynomialQ[#,coordinates]&&AllTrue[First/@CoefficientRules[#,coordinates],Total[#]<=1&]&],
  measuredIntegrandFail["AffineUnitCutScalarProductsRequired"]];
 matrix=Table[Coefficient[p,v],{p,polynomials},{v,coordinates}];constant=polynomials/.Thread[coordinates->0];
 order=SortBy[Range[Length[basis]],Boole[MemberQ[FeynCalc`FCI[preserved],basis[[#]]]]&];
 Do[If[MatrixRank[matrix[[All,Append[pivots,j]]]]>rank,AppendTo[pivots,j];rank++],{j,order}];
 If[rank=!=Length[polynomials],measuredIntegrandFail["IndependentUnitCutConstraintsRequired"]];
 free=Complement[Range[Length[basis]],pivots];
 solution=Factor/@LinearSolve[matrix[[All,pivots]],-constant-matrix[[All,free]].coordinates[[free]]];
 Thread[basis[[pivots]]->(solution/.Thread[coordinates->basis])]
],"MeasuredIntegrand"];
PrepareFinalStateMeasurementIntegrands[expression_,geometry_Association,specification_Association,request_Association:<||>]:=
  Catch[Module[{rows,result={},prepared,settings,inclusive,base,reduced,ordinary,index=0,seconds,started},
 rows=FeynFacet`CreateFinalStateMeasurementDefinitions[geometry,specification];
 If[!ListQ[rows],measuredIntegrandFail["FinalStateMeasurementDefinitionsRequired",<|"Cause"->rows|>]];
  settings=Join[<|"ExternalKinematicConditions"->geometry["Assumptions"]|>,request];
  (* The amplitude and its unit particle-cut relations do not depend on which
     tuple is measured. Cancel that common density once, before multiplying
     by the different measurement weights and Jacobians. The reconstructed
     rational expression is used only after its original causal product has
     passed the ordinary-prescription certificate. Each measured family still
     receives its own unrestricted off-shell definition. *)
  inclusive=FeynFacet`CreateMasslessPhaseSpaceDefinition[KeyDrop[geometry,"Measurements"]];
  If[!AssociationQ[inclusive],measuredIntegrandFail["UnmeasuredPhaseSpaceDefinitionRequired",<|"Cause"->inclusive|>]];
  If[TrueQ[Lookup[settings,"PrintTimings",False]],Print["PREPARING COMMON UNMEASURED DENSITY"]];
  started=facetElapsedClock[];
  base=FeynFacet`PrepareCutIntegrand[expression,inclusive,settings];
  If[!AssociationQ[base],measuredIntegrandFail["UnmeasuredSourcePreparationFailed",<|"Cause"->base|>]];
  ordinary=base["SourceDefinition"]["Topology"][[2,Complement[
    Range[Length[base["SourceDefinition"]["Topology"][[2]]]],base["SourceDefinition"]["CutIndices"]]]];
  reduced=Total[Map[#["Numerator"]Times@@MapThread[Power,
    {ordinary,#["Powers"]}]&,base["Terms"]]]/.base["ScalarProductVariables"];
  seconds=facetElapsedClock[]-started;
  If[TrueQ[Lookup[settings,"PrintTimings",False]],Print["COMMON UNMEASURED DENSITY SECONDS ",seconds," BYTES ",ByteCount[reduced]]];
  Do[
   index++;If[TrueQ[Lookup[settings,"PrintTimings",False]],Print["PREPARING MEASUREMENT ",index,"/",Length[rows]]];
   prepared=FeynFacet`PrepareCutIntegrand[reduced row["Weight"],row["Definition"],settings];
   If[!AssociationQ[prepared],measuredIntegrandFail["FinalStateMeasurementPreparationFailed",<|"Cause"->prepared|>]];
   AppendTo[result,Join[KeyDrop[row,"Definition"],<|"PreparedIntegrand"->prepared,
    "UnmeasuredPreparation"-><|"Seconds"->seconds,"OrdinaryPrescriptionCertificate"->base["OrdinaryPrescriptionCertificate"]|>,
   "ContactMeasurements"->row["Definition"]["ContactMeasurements"]|>]],{row,rows}];
 result
 ],"MeasuredIntegrand"];
PrepareCutIntegrand[expression_,input_Association,request_Association]:=PrepareMeasuredCutIntegrand[expression,input,request];
PrepareMeasuredCutIntegrand[expression_,input_Association,request_Association]:=Catch[Module[
 {definition,top,loops,kin,basis,coordinates,replace,internal,objects,records,cores={},units={},
  aliases={},registry=<||>,register,objectValue,objectRules,negative,negativeRules,formal,terms,
  ordinaryPowers,cutCount,fullTop,source,master,certificate,cutPolynomials,matrix,constant,
  pivots={},rank=0,free,solution,unitRules,values,coefficients,descriptors,result,unitNumerators},
 definition=FeynFacet`CreateCutIntegralDefinition[input];
 If[!AssociationQ[definition]||!KeyExistsQ[input,"MomentumConservationRules"]||
   (Lookup[definition,"MeasurementCutIndices",{}]=!={}&&!KeyExistsQ[input,"MeasurementDefinitions"]&&!ContainsAll[Keys[input],
    {"MeasurementVariable","ReferenceMomentum","TaggedMomentum"}]),
  measuredIntegrandFail["MeasuredPhaseSpaceDefinitionRequired"]];
 top=definition["Topology"];loops=top[[3]];kin=top[[5]];
 If[Complement[Range[Length[top[[2]]]],definition["CutIndices"]]=!={},
  measuredIntegrandFail["SourcePhaseSpaceDefinitionMustContainOnlyCuts"]];
 basis=definition["LoopScalarProducts"];coordinates=Table[Unique["scalarProduct$"],{Length[basis]}];
 replace=Thread[basis->coordinates];
 internal=FeynCalc`FCI[(expression Lookup[input,"MeasurementNumerator",1])/.input["MomentumConservationRules"]];
 If[!FreeQ[internal,_Real|_Failure|_Missing|$Failed|$Aborted|_FeynCalc`LorentzIndex|
   _FeynCalc`DiracGamma|_FeynCalc`DiracTrace|_FeynCalc`Eps],
  measuredIntegrandFail["ExactFullDimensionScalarIntegrandRequired"]];
 register[core_,unit_]:=Module[{key=Expand[core/.kin]},
  If[!FreeQ[key,_FeynCalc`Pair],
   If[!PolynomialQ[key/.replace,coordinates]||!FreeQ[key/.replace,_FeynCalc`Pair]||
     !AllTrue[First/@CoefficientRules[key/.replace,coordinates],Total[#]<=1&],
    measuredIntegrandFail["AffineLoopScalarProductDenominatorRequired"]]];
  If[KeyExistsQ[registry,key],Return[registry[key]]];
  AppendTo[cores,key];AppendTo[units,unit];AppendTo[aliases,Unique["inverseDenominator$"]];
  AssociateTo[registry,key->Last[aliases]];Last[aliases]];
 objectValue[object_]:=Module[{factors,data},
  factors=propagatorFactors[FeynCalc`ToSFAD[object]];data=propagatorDescriptor/@factors;
  If[MemberQ[data,$Failed],measuredIntegrandFail["SupportedPrescribedPropagatorsRequired"]];
  Times@@MapThread[Function[{factor,desc},With[{unit=factor/.
    FeynCalc`StandardPropagatorDenominator[q_,sp_,mass_,{_,eta_}]:>
     FeynCalc`StandardPropagatorDenominator[q,sp,mass,{1,eta}]},
    register[FeynCalc`ExpandScalarProduct[desc["UnitCore"]],unit]^desc["Power"]]],{factors,data}]];
 objects=DeleteDuplicates[Cases[internal,_FeynCalc`FeynAmpDenominator,{0,Infinity}]];
 objectRules=(#->objectValue[#])&/@objects;formal=internal/.Dispatch[objectRules];
 formal=FeynCalc`ExpandScalarProduct[formal]/.kin;
 negative=DeleteDuplicates[Cases[formal,object:Power[base_,n_Integer?Negative]/;
   !FreeQ[base,Alternatives@@loops]:>object,{0,Infinity}]];
 negativeRules=Map[Function[object,With[{base=Expand[object[[1]]]},
  object->register[base,FeynCalc`FeynAmpDenominator[
    FeynCalc`StandardPropagatorDenominator[0,base,0,{1,1}]]]^(-object[[2]])]],negative];
 formal=formal/.Dispatch[negativeRules];
 terms=If[aliases==={},{{}->formal},FeynFacet`PolynomialCoefficientRules[formal,aliases]];
 If[FailureQ[terms],measuredIntegrandFail["PolynomialNumeratorsAndIntegerDenominatorPowersRequired"]];
 coefficients=Last/@terms;
 If[!AllTrue[coefficients,PolynomialQ[#/.replace,coordinates]&&
    FreeQ[#/.replace,Alternatives@@Join[loops,{FeynCalc`Pair,FeynCalc`Momentum}]]&],
  measuredIntegrandFail["PolynomialFullDimensionLoopNumeratorsRequired"]];
 ordinaryPowers=If[aliases==={},{},Max/@Transpose[First/@terms]];
 cutCount=Length[top[[2]]];
 fullTop=ReplacePart[top,2->Join[top[[2]],units]];
 source=FeynFacet`CreateCutIntegralDefinition[Join[definition,<|"Topology"->fullTop|>]];
 If[!AssociationQ[source],measuredIntegrandFail["RawMeasuredDenominatorDefinitionFailed",<|"Cause"->source|>]];
 master=FeynCalc`GLI[top[[1]],Join[ConstantArray[1,cutCount],ordinaryPowers]];
 certificate=FeynFacet`CertifyOrdinaryPrescriptionRemoval[source,master,
   Join[KeyTake[input,{"MeasurementVariable","ReferenceMomentum","TaggedMomentum"}],request]];
 If[FailureQ[certificate]||FeynFacet`RequireOrdinaryPrescriptionCertificate[certificate,"GenericKinematics"]=!=True,
  measuredIntegrandFail["MeasuredSourcePrescriptionLimitRequired",<|"Cause"->certificate|>]];
 cutPolynomials=Expand[definition["InversePropagators"]/.replace];
  cutPolynomials=Select[cutPolynomials,PolynomialQ[#,coordinates]&&AllTrue[First/@CoefficientRules[#,coordinates],Total[#]<=1&]&];
 matrix=Table[Coefficient[poly,var],{poly,cutPolynomials},{var,coordinates}];
 constant=cutPolynomials/.Thread[coordinates->0];
 Do[If[MatrixRank[matrix[[All,Append[pivots,j]]]]>rank,AppendTo[pivots,j];rank++],{j,Length[coordinates]}];
 If[rank=!=Length[cutPolynomials],measuredIntegrandFail["IndependentAffineUnitCutConstraintsRequired"]];
 free=Complement[Range[Length[coordinates]],pivots];
 solution=Factor/@LinearSolve[matrix[[All,pivots]],-constant-matrix[[All,free]].coordinates[[free]]];
 unitRules=Thread[coordinates[[pivots]]->solution];
 values=Map[<|"Powers"->First[#],"Numerator"->((Last[#]/.replace)/.unitRules)|>&,terms];
 (* Cancel on the unit-cut surface before expanding in free scalar products.
    On-shell cancellations can remove most of a large physical numerator. *)
 unitNumerators=FeynFacet`CancelRationalCoefficients[Lookup[values,"Numerator",{}]];
 If[!ListQ[unitNumerators]||Length[unitNumerators]=!=Length[values],
  measuredIntegrandFail["UnitCutNumeratorCancellationFailed",<|"Cause"->unitNumerators|>]];
 values=MapThread[Join[#1,<|"Numerator"->#2|>]&,{values,unitNumerators}];
 result=<|"Format"->"FeynFacet-MeasuredCutIntegrand","FormatVersion"->1,
  "SourceDefinition"->source,"OrdinaryPrescriptionCertificate"->certificate,
  "ExternalKinematicConditions"->request["ExternalKinematicConditions"],
  "OriginalPrescribedPropagators"->objects,"OrdinaryPowerBounds"->ordinaryPowers,
  "OrdinaryInversePropagators"->cores,"OrdinaryUnitCutPolynomials"->((cores/.replace)/.unitRules),
  "ScalarProductVariables"->Thread[coordinates->basis],"UnitCutRules"->unitRules,
  "FreeScalarProductVariables"->coordinates[[free]],"Terms"->values,
  "CutPowers"->ConstantArray[1,cutCount],
  "RestrictionScope"->"The displayed numerators and denominator polynomials are restricted only to unit particle and measurement cuts. Dotted-cut derivatives use the unrestricted SourceDefinition.",
  "PhaseSpacePrefactorIncludedInTerms"->False,
   "MeasurementNumeratorIncludedInTerms"->True,
   "RetainedPolynomialMeasurementCuts"->Select[definition["MeasurementCutIndices"],definition["DenominatorDegrees"][[#]]>1&]|>;
 If[TrueQ[Lookup[request,"CancelDenominators",True]],
  FeynFacet`CancelMeasuredCutIntegrandDenominators[result,request],result]
],"MeasuredIntegrand"];

(* The operation is in the rational function field on the unit-cut surface.
   No resulting identity is substituted into off-shell dotted-cut definitions.
   Working coefficient by coefficient avoids a very large common numerator
   involving color and dimension variables that never occur in propagators. *)
CancelMeasuredCutIntegrandDenominators[prepared_Association,request_Association:<||>]:=Module[
 {started=facetElapsedClock[],result,limit=Lookup[request,"CancellationTimeLimit",300]},
 If[Lookup[prepared,"Format",None]=!="FeynFacet-MeasuredCutIntegrand",
  Return[Failure["PreparedMeasuredIntegrandRequired",<||>]]];
 If[!NumericQ[limit]||limit<=0,Return[Failure["PositiveCancellationTimeLimitRequired",<||>]]];
 result=TimeConstrained[Catch[Module[
  {terms=prepared["Terms"],variables=prepared["FreeScalarProductVariables"],polynomials,
   numerators,spectators,denominatorFactors,commonCoefficientDenominator,coefficientRules,
   monomials,sectorNumerators,expression,reduced,denominator,powers,numerator,variable,
    output={},inputPowers,outputPowers,cancelled,shiftedSymbols,coefficient,nonalgebraic},
  polynomials=Expand/@prepared["OrdinaryUnitCutPolynomials"];
  If[terms==={},Return[prepared,Module]];
  numerators=Lookup[terms,"Numerator"];
   (* Dimensional scale powers and Gamma factors are scalar coefficients,
      not polynomial indeterminates. Including their argument symbols in the
      coefficient ring makes an otherwise rational cancellation fail. *)
   nonalgebraic=Cases[numerators,item:h_[___]/;
     (!MemberQ[{List,Plus,Times,Power},h]||(h===Power&&!IntegerQ[item[[2]]])):>item,Infinity];
   spectators=Complement[DeleteDuplicates[Cases[numerators,_Symbol,Infinity]],
    DeleteDuplicates[Cases[polynomials,_Symbol,Infinity]],
    DeleteDuplicates[Cases[nonalgebraic,_Symbol,Infinity]]];
  If[TrueQ[Lookup[request,"PrintTimings",False]],Print["RATIONAL COEFFICIENT VARIABLES ",spectators]];
  coefficient=FeynFacet`RationalCoefficientRules[numerators,spectators];
  If[FailureQ[coefficient],Throw[coefficient,"MeasuredCancellation"]];
  commonCoefficientDenominator=coefficient["CommonDenominator"];
  coefficientRules=coefficient["NumeratorCoefficientRules"];
  shiftedSymbols=spectators;
  monomials=Union[Flatten[(First/@#)&/@coefficientRules,1]];
  If[TrueQ[Lookup[request,"PrintTimings",False]],
   Print["RATIONAL COEFFICIENT MONOMIALS ",Length[monomials]," SECONDS ",facetElapsedClock[]-started]];
  Do[
   sectorNumerators=Map[Lookup[Association[#],Key[monomial],0]&,coefficientRules];
   expression=Total[MapThread[#1 Times@@MapThread[If[#2===0,1,#1^-#2]&,
      {polynomials,#2}]&,{sectorNumerators,Lookup[terms,"Powers"]}]];
   reduced=Cancel[Together[expression]];
   If[TrueQ[Lookup[request,"PrintTimings",False]],
    Print["RATIONAL SECTOR ",monomial," SECONDS ",facetElapsedClock[]-started]];
   If[reduced===0,Continue[]];
   denominator=Denominator[reduced];powers=ConstantArray[0,Length[polynomials]];
   Do[
    If[FreeQ[polynomials[[j]],Alternatives@@variables],Continue[]];
    variable=SelectFirst[variables,Coefficient[polynomials[[j]],#]=!=0&];
    While[Cancel[PolynomialRemainder[denominator,polynomials[[j]],variable]]===0,
     denominator=Cancel[PolynomialQuotient[denominator,polynomials[[j]],variable]];powers[[j]]++],
   {j,Length[polynomials]}];
   numerator=Cancel[reduced Times@@MapThread[Power,{polynomials,powers}]];
   If[!PolynomialQ[numerator,variables],
    Throw[Failure["CancelledDenominatorOutsideDeclaredProduct",<||>],"MeasuredCancellation"]];
   numerator=numerator Times@@(shiftedSymbols^monomial)/commonCoefficientDenominator;
   AppendTo[output,<|"Powers"->powers,"Numerator"->numerator|>],
  {monomial,monomials}];
  inputPowers=Max/@Transpose[Lookup[terms,"Powers"]];
  outputPowers=If[output==={},ConstantArray[0,Length[polynomials]],Max/@Transpose[Lookup[output,"Powers"]]];
  cancelled=Select[Range[Length[polynomials]],inputPowers[[#]]>0&&outputPowers[[#]]===0&];
  (* A full common denominator can greatly enlarge partial fractions even
     when it shortens the numerator. Keep the original product decomposition
     unless a kinematic denominator has disappeared completely. *)
  If[!AnyTrue[cancelled,!FreeQ[polynomials[[#]],Alternatives@@variables]&],
   Return[Join[prepared,<|"RationalCancellation"-><|"Status"->"OriginalDensityRetained",
    "Reason"->"NoKinematicDenominatorEliminated","Seconds"->facetElapsedClock[]-started|>|>],Module]];
  Join[prepared,<|"Terms"->output,"OrdinaryPowerBounds"->outputPowers,
   "RationalCancellation"-><|"Status"->"Completed","Method"->"ExactRationalCancellationByCoefficientMonomials",
    "CoefficientVariables"->spectators,"CoefficientMonomialCount"->Length[monomials],
    "InputProductCount"->Length[terms],"OutputProductCount"->Length[output],
    "InputPowerBounds"->inputPowers,"OutputPowerBounds"->outputPowers,
    "CancelledOrdinaryFactorIndices"->cancelled,"Seconds"->facetElapsedClock[]-started,
    "Scope"->"Complete unit-cut density only. The unrestricted source definition and prescription certificate are preserved."|>|>]
 ],"MeasuredCancellation"],limit,Failure["RationalCancellationTimeLimit",<||>]];
 If[FailureQ[result],Join[prepared,<|"RationalCancellation"-><|"Status"->"OriginalDensityRetained",
   "Reason"->result[[1]],"Seconds"->facetElapsedClock[]-started|>|>],result]
];

DecomposeMeasuredCutIntegrand[prepared_Association,request_Association:<||>]:=Catch[Module[
 {source,top,cutCount,ordinary,variables,powers,partials,expanded,supports,families,registry,
  makeFamily,allSupports,terms,rows={},family,support,nu,numerator,coefficientRules,inverse,basisRules,
  base,indices,coefficients,divisors,postPowers,certificate,conditions,prefix,
  started=facetElapsedClock[],rowCount=0,progress,sourceRules,monomialImage,
  coordinateImages,originalPowers,originalCoefficient,rowTag=Unique["coefficientRows"],workers,raw,checkpoint,sourceCoefficientRules,familyNumeratorRules},
 If[Lookup[prepared,"Format",None]=!="FeynFacet-MeasuredCutIntegrand",
  measuredIntegrandFail["PreparedMeasuredIntegrandRequired"]];
 progress[label_]:=If[TrueQ[Lookup[request,"PrintTimings",False]],
  Print[label," SECONDS ",Round[facetElapsedClock[]-started,0.01]]];
 source=prepared["SourceDefinition"];top=source["Topology"];cutCount=Length[source["CutIndices"]];
 ordinary=prepared["OrdinaryUnitCutPolynomials"];variables=prepared["FreeScalarProductVariables"];
 If[variables==={},measuredIntegrandFail["PositiveDimensionalUnitCutSurfaceRequired"]];
 powers=DeleteDuplicates[Lookup[prepared["Terms"],"Powers"]];
 partials=Association[Map[Function[nu,nu->FeynFacet`PartialFractionAffineDenominators[
   ordinary,nu,variables,KeyTake[request,{"MaximumStates","Assumptions"}]]],powers]];
 If[AnyTrue[Values[partials],FailureQ],measuredIntegrandFail["AffinePartialFractionsFailed",
   <|"Cause"->SelectFirst[Values[partials],FailureQ]|>]];
 expanded=Flatten[MapIndexed[Function[{row,index},Map[<|"Powers"->#["Powers"],
   "SourceTermIndex"->First[index],"ScalarFactor"->#["Coefficient"]|>&,
   partials[row["Powers"]]["Terms"]]],prepared["Terms"]],1];
 progress["Partial fractions constructed"];
 allSupports=Sort[DeleteDuplicates[Flatten[Position[#["Powers"],n_Integer?Positive,{1}]]&/@expanded]];
 (* An absent ordinary denominator is an index zero in any containing basis.
    This is an exact embedding with the same directed cuts, not a guessed
    routing symmetry or a new identification of physical integration periods. *)
 supports=Select[allSupports,Function[active,!AnyTrue[allSupports,
   Length[#]>Length[active]&&ContainsAll[#,active]&]]];
 postPowers=If[expanded==={},ConstantArray[0,Length[ordinary]],Max/@Transpose[Lookup[expanded,"Powers"]]];
 conditions=Lookup[prepared["OrdinaryPrescriptionCertificate"],"KinematicConditions",
   Lookup[source,"Assumptions",True]];
 (* Reuse the original, measurement-independent source polynomials when
    checking the increased ordinary powers, before cut restriction. *)
 certificate=FeynFacet`CertifyOrdinaryPrescriptionRemoval[source,
   FeynCalc`GLI[top[[1]],Join[ConstantArray[1,cutCount],postPowers]],
   Join[KeyTake[source,{"MeasurementVariable","ReferenceMomentum","TaggedMomentum"}],
    <|"ExternalKinematicConditions"->Lookup[request,"ExternalKinematicConditions",
      Lookup[prepared,"ExternalKinematicConditions",True]]|>]];
 If[FailureQ[certificate]||FeynFacet`RequireOrdinaryPrescriptionCertificate[certificate,"GenericKinematics"]=!=True,
  measuredIntegrandFail["PartialFractionTermConvergenceRequired",<|"Cause"->certificate|>]];
 prefix=Lookup[request,"FamilyNamePrefix","MeasuredFamily"];
 If[!StringQ[prefix]||!StringMatchQ[prefix,LetterCharacter~~(LetterCharacter|DigitCharacter)...],
  measuredIntegrandFail["AlphanumericFamilyNamePrefixRequired"]];
 makeFamily[active_List,index_Integer]:=Module[
  {props,cores,coordinates,matrix,rank,aux,trial,name,newTop,value,candidates,coordinateRules},
  props=Join[top[[2,Range[cutCount]]],top[[2,cutCount+active]]];
  cores=Join[source["InversePropagators"][[Range[cutCount]]],
    source["InversePropagators"][[cutCount+active]]];
  coordinates=Table[Unique["basisScalarProduct$"],{Length[source["LoopScalarProducts"]]}];
  matrix=Table[Coefficient[core,v],
     {core,Select[Expand[cores/.Thread[source["LoopScalarProducts"]->coordinates]],
       AllTrue[First/@CoefficientRules[#,coordinates],Total[#]<=1&]&]},{v,coordinates}];rank=MatrixRank[matrix];
  coordinateRules=Thread[source["LoopScalarProducts"]->coordinates];
  candidates=DeleteDuplicates[Join[FeynCalc`FCI[Lookup[request,"AuxiliaryScalarProducts",{}]],source["LoopScalarProducts"]]];
  If[!AllTrue[candidates,With[{c=FeynCalc`ExpandScalarProduct[#]/.source["Topology"][[5]]/.coordinateRules},
    PolynomialQ[c,coordinates]&&FreeQ[c,_FeynCalc`Pair]&&
    AllTrue[First/@CoefficientRules[c,coordinates],Total[#]<=1&]]&],
   measuredIntegrandFail["AffineAuxiliaryScalarProductsRequired"]];
  Do[If[rank===Length[coordinates],Break[]];
   trial=Coefficient[FeynCalc`ExpandScalarProduct[aux]/.source["Topology"][[5]]/.coordinateRules,#]&/@coordinates;
   If[MatrixRank[Append[matrix,trial]]>rank,
    AppendTo[props,FeynCalc`FeynAmpDenominator[FeynCalc`StandardPropagatorDenominator[0,aux,0,{1,1}]]];
    AppendTo[matrix,trial];rank++],{aux,candidates}];
  If[rank=!=Length[coordinates],measuredIntegrandFail["CompleteMeasuredDenominatorBasisRequired"]];
  name=Symbol["FeynFacet`IntegralFamilies`"<>prefix<>ToString[index]];
  newTop=ReplacePart[top,{1->name,2->props}];
  value=FeynFacet`CreateCutIntegralFamily[Join[source,<|"Topology"->newTop|>]];
  If[!AssociationQ[value],measuredIntegrandFail["MeasuredIntegralFamilyConstructionFailed",<|"Cause"->value,"ActiveDenominators"->active,"Topology"->newTop|>]];
  Join[value,<|"SourceOrdinaryIndices"->active,"AuxiliaryIndices"->Range[cutCount+Length[active]+1,Length[props]]|>]];
 families=MapIndexed[makeFamily[#1,First[#2]]&,supports];
 progress["Integral families constructed"];
 registry=Association[Map[Function[active,active->First[FirstPosition[
   ContainsAll[#,active]&/@supports,True]]],allSupports]];
 (* Preparation stores coordinate -> physical scalar product. Apply that
    direction before converting products to this family's inverse propagators. *)
 basisRules=prepared["ScalarProductVariables"];
 workers=Lookup[request,"CoefficientWorkers",1];
 If[!IntegerQ[workers]||!Between[workers,{1,8}],measuredIntegrandFail["OneThroughEightCoefficientWorkersRequired"]];

 (* Expand each monomial of an affine coordinate change once per family.
    Keeping the original external coefficient outside this operation avoids
    repeatedly expanding a large color/dimension polynomial after substitution. *)
 coordinateImages[index_Integer]:=coordinateImages[index]=With[{ff=families[[index]]},
  ((variables/.basisRules)/.ff["ScalarProductRules"])/.
   Thread[Take[ff["DenominatorVariables"],cutCount]->0]];
 monomialImage[index_Integer,exponents_List]:=monomialImage[index,exponents]=
  FeynFacet`PolynomialCoefficientRules[Times@@MapThread[Power,
    {coordinateImages[index],exponents}],Drop[families[[index]]["DenominatorVariables"],cutCount]];
 (* Partial fractions change denominator powers and an external scalar
    factor, but not the polynomial numerator. Convert each original
    numerator once in each family, not once per partial-fraction term. *)
 sourceCoefficientRules[index_Integer]:=sourceCoefficientRules[index]=Module[{rr},
  rr=FeynFacet`PolynomialCoefficientRules[prepared["Terms"][[index]]["Numerator"],variables];
  If[FailureQ[rr],measuredIntegrandFail["PolynomialMeasuredSourceNumeratorRequired"]];
  If[!FreeQ[Last/@rr,Alternatives@@Join[First/@basisRules,
     {FeynCalc`Pair,FeynCalc`Momentum}]],
   measuredIntegrandFail["ExternalMeasuredSourceCoefficientsRequired"]];
  Thread[(First/@rr)->cancelCoefficientRow[Last/@rr]]
 ];
 familyNumeratorRules[sourceIndex_Integer,familyIndex_Integer]:=
  familyNumeratorRules[sourceIndex,familyIndex]=Module[{rr,ss,converted,external},
   ss=sourceCoefficientRules[sourceIndex];
   rr=Normal[Merge[Flatten[Map[Function[originalTerm,
    converted=monomialImage[familyIndex,First[originalTerm]];
    If[FailureQ[converted],measuredIntegrandFail["PolynomialMeasuredFamilyNumeratorRequired"]];
    (First[#]->Last[originalTerm] Last[#])&/@converted],ss],1],Total]];
   rr=Thread[(First/@rr)->cancelCoefficientRow[Last/@rr]];
   rr=Select[rr,Last[#]=!=0&];
   If[!FreeQ[Last/@rr,Alternatives@@Join[First/@basisRules,
      families[[familyIndex]]["DenominatorVariables"],{FeynCalc`Pair,FeynCalc`Momentum}]],
    measuredIntegrandFail["ExternalMeasuredIntegralCoefficientsRequired"]];
   rr
  ];
 rows=Reap[Do[
  support=Flatten[Position[row["Powers"],n_Integer?Positive,{1}]];
  family=families[[registry[support]]];inverse=family["DenominatorVariables"];
  If[!FreeQ[row["ScalarFactor"],Alternatives@@Join[First/@basisRules,
     inverse,{FeynCalc`Pair,FeynCalc`Momentum}]],
   measuredIntegrandFail["ExternalPartialFractionCoefficientRequired"]];
  coefficientRules=familyNumeratorRules[row["SourceTermIndex"],registry[support]];
  base=Join[ConstantArray[1,cutCount],row["Powers"][[family["SourceOrdinaryIndices"]]],
   ConstantArray[0,Length[inverse]-cutCount-Length[family["SourceOrdinaryIndices"]]]];
  Scan[Function[term,indices=base-Join[ConstantArray[0,cutCount],First[term]];
   Sow[FeynCalc`GLI[family["Topology"][[1]],indices]->row["ScalarFactor"] Last[term],rowTag] ],coefficientRules];
  rowCount++;If[rowCount<=3||Mod[rowCount,25]===0||rowCount===Length[expanded],
   progress["Converted numerator "<>ToString[rowCount]<>" of "<>ToString[Length[expanded]]]],
 {row,expanded}],rowTag][[2]];
 rows=If[rows==={},{},First[rows]];
 progress["Collecting "<>ToString[Length[rows]]<>" numerator monomials"];
 coefficients=If[rows==={},<||>,Merge[rows,Total]];
 Clear[coordinateImages,monomialImage,sourceCoefficientRules,familyNumeratorRules];
 divisors=DeleteDuplicates[Flatten[Lookup[Values[partials],"ExceptionalDivisors"],1]];
 raw=<|"Format"->"FeynFacet-MeasuredIntegralDecomposition","FormatVersion"->2,
  "ScalarCoefficientsExternal"->True,"CoefficientCancellationComplete"->False,
  "Families"->families,"Coefficients"->coefficients,"Targets"->Keys[coefficients],
  "ExceptionalDivisors"->divisors,"OrdinaryPowerBoundsAfterPartialFractions"->postPowers,
  "OrdinaryPrescriptionCertificate"->certificate,"PartialFractionProductCount"->Length[expanded],
  "Scope"->"Rational identities at generic interior kinematics; endpoint distributions must be expanded from the regulated complete sum. Every family retains unrestricted denominators for dotted-cut IBP.",
  "MeasurePrefactorIncludedInFamilies"->True,"FluxAndCouplingsApplied"->False|>;
 checkpoint=Lookup[request,"CoefficientCheckpointFunction",None];
 If[MatchQ[checkpoint,_Function],checkpoint[raw]];
 raw=FeynFacet`SimplifyMeasuredIntegralDecomposition[raw,<|"CoefficientWorkers"->workers|>];
 progress["Scalar integral coefficients cancelled"];
 raw
],"MeasuredIntegrand"];

SimplifyMeasuredIntegralDecomposition[data_Association,request_Association:<||>]:=Catch[Module[
 {values,families,workers=Lookup[request,"CoefficientWorkers",1]},
 If[Lookup[data,"Format",None]=!="FeynFacet-MeasuredIntegralDecomposition"||
  !TrueQ[Lookup[data,"ScalarCoefficientsExternal",False]]||
  !IntegerQ[workers]||!Between[workers,{1,8}],
  measuredIntegrandFail["ExternalScalarIntegralDecompositionRequired"]];
 values=data["Coefficients"];
 values=AssociationThread[Keys[values],cancelIndependentCoefficients[Values[values],workers]];
 values=Select[values,#=!=0&];
 families=Select[data["Families"],MemberQ[First/@Keys[values],#["Topology"][[1]]]&];
 Join[data,<|"Coefficients"->values,"Targets"->Keys[values],"Families"->families,
  "CoefficientCancellationComplete"->True|>]
],"MeasuredIntegrand"];

MergeCutIntegralDecompositions[contributions_Association]:=Catch[Module[
 {families={},registry=<||>,names=<||>,renaming=<||>,coefficients=<||>,signature,family,name,
  canonical,mapping,rows,normalized},
 If[contributions===<||>||!AllTrue[Values[contributions],
   AssociationQ[#]&&Lookup[#,"Format",None]==="FeynFacet-MeasuredIntegralDecomposition"&&
   TrueQ[Lookup[#,"ScalarCoefficientsExternal",False]]&&
   TrueQ[Lookup[#,"CoefficientCancellationComplete",False]]&],
  measuredIntegrandFail["CompletedExternalCoefficientDecompositionsRequired"]];
 Do[
  mapping=<||>;names=<||>;
  Do[
   name=family["Topology"][[1]];
   signature={Rest[List@@family["Topology"]],family["Cuts"],family["MeasurePrefactor"],
    family["TimeDirection"],family["Assumptions"],Lookup[family,"Dimension",D]};
   If[KeyExistsQ[names,name]&&names[name]=!=signature,
    measuredIntegrandFail["ConflictingCutFamilyName",<|"Name"->name|>]];
   AssociateTo[names,name->signature];
   If[KeyExistsQ[registry,signature],canonical=registry[signature],
    canonical=name;
    If[MemberQ[(#["Topology"][[1]]&/@families),canonical],
     canonical=Symbol[(Context@@{name})<>SymbolName[name]<>"Source"<>ToString[Length[families]+1]]];
    While[MemberQ[(#["Topology"][[1]]&/@families),canonical],
     canonical=Symbol[(Context@@{canonical})<>SymbolName[canonical]<>"Next"]];
    AppendTo[families,family/.name->canonical];AssociateTo[registry,signature->canonical]];
   AssociateTo[mapping,name->canonical],
  {family,contributions[label]["Families"]}];
  rows=KeyValueMap[Function[{integral,coefficient},
   If[!KeyExistsQ[mapping,integral[[1]]],measuredIntegrandFail["DeclaredIntegralFamilyRequired"]];
   FeynCalc`GLI[mapping[integral[[1]]],integral[[2]]]->coefficient],contributions[label]["Coefficients"]];
  normalized=If[rows==={},<||>,Merge[rows,Total]];
  AssociateTo[coefficients,label->normalized];AssociateTo[renaming,label->Normal[mapping]],
 {label,Keys[contributions]}];
 <|"Format"->"FeynFacet-CombinedCutIntegralDecompositions","FormatVersion"->1,
  "Families"->families,"Coefficients"->coefficients,
  "Targets"->Sort[DeleteDuplicates[Flatten[Keys/@Values[coefficients],1]]],
  "FamilyRenamingRules"->renaming,
  "SourcePrescriptionCertificates"->Map[#["OrdinaryPrescriptionCertificate"]&,contributions],
  "EquivalenceScope"->"Exact equality of the complete typed definitions; no momentum routing or period symmetry inferred."|>
],"MeasuredIntegrand"];
End[];EndPackage[];
