(* Coefficients of physical masters at an explicitly declared reference scale.
   Finite Laurent records are never expanded or reclassified by this change. *)
FeynFacet`ConstructPhysicalMasterCoefficientDensity::usage =
 "ConstructPhysicalMasterCoefficientDensity[table,definitions,request] converts normalized-GLI coefficients to coefficients of physical masters at ReferenceScale. Definitions is keyed by GLI or {family,powers}. Request supplies Scale, ReferenceScale, positive-scale Assumptions and KinematicRules; FluxFactor, ObservedVariableJacobian and named AdditionalFactors are applied only when explicitly supplied.";

physicalDensityID[key_] := If[MatchQ[key,{_String,{__Integer}}],key,coefficientMasterID[key]];
physicalDensityExactQ[x_] := coefficientExactDataQ[x];
physicalDensityFactorRecord[request_,key_] := If[KeyExistsQ[request,key],
 If[!physicalDensityExactQ[request[key]]||MemberQ[{None,Automatic},request[key]],coefficientAssemblyFail["ExactDensityFactorRequired",<|"FactorName"->key|>]];
 <|"Status"->"Supplied","Factor"->request[key]|>,<|"Status"->"NotSupplied"|>];

FeynFacet`ConstructPhysicalMasterCoefficientDensity[input_,definitions_Association,request_Association] :=
 Catch[Module[{raw=input,table,e,scale,reference,assumptions,rules,additional,factorRecords,
  extra=1,byID=<||>,ids,definition,id,key,master,dim,powers,dimensions,loops,
  conversion,scaling,multiplier,normalizations={},entries={},terms,sourceVariables,inputSource,observable,req,
  transformed,change,flux,jacobian,remainders,record,sourcePhase},
 inputSource=If[StringQ[input],ExpandFileName[input],Lookup[request,"SourceCoefficientFile",None]];
 If[StringQ[raw],If[!FileExistsQ[raw],coefficientAssemblyFail["CoefficientFileMissing",<|"File"->raw|>]];
  raw=If[ToLowerCase[FileExtension[raw]]==="wxf",Import[raw,"WXF"],Get[raw]]];
 If[!AssociationQ[raw],coefficientAssemblyFail["CoefficientResultRequired"]];
 If[TrueQ[Lookup[raw,"PhysicalMasterNormalizationApplied",False]],
  coefficientAssemblyFail["PhysicalMasterNormalizationAlreadyApplied"]];
 table=FeynFacet`ReadMasterIntegralCoefficients[raw];
 If[FailureQ[table],coefficientAssemblyFail["CoefficientDensityInputInvalid",<|"Cause"->table|>]];
 e=table["DimensionalRegulator"];req=coefficientRegulatorNormalize[request,e];
 {scale,reference,assumptions,rules}=Lookup[req,{"Scale","ReferenceScale","Assumptions","KinematicRules"},None];
 If[MemberQ[{scale,reference,assumptions,rules},None] ||
   !physicalDensityExactQ[{scale,reference,assumptions,rules}] ||
   !FreeQ[{scale,reference},e] || !ListQ[rules] ||
   !AllTrue[rules,MatchQ[#,_Rule]&] || !DuplicateFreeQ[First/@rules] ||
   !FreeQ[rules,e] || !TrueQ[Quiet[FullSimplify[scale>0 && reference>0,assumptions]]],
  coefficientAssemblyFail["PositiveScaleAndExplicitKinematicRulesRequired"]];
 change[x_] := x/.rules;
 If[!TrueQ[Quiet[FullSimplify[change[scale]>0 && change[reference]>0,change[assumptions]]]],
  coefficientAssemblyFail["KinematicRulesDoNotPreservePositiveScales"]];
 sourceVariables=Lookup[req,"EliminatedKinematicVariables",{}];
 If[!ListQ[sourceVariables]||!AllTrue[sourceVariables,MatchQ[#,_Symbol]&],
  coefficientAssemblyFail["EliminatedKinematicVariablesMustBeSymbols"]];
 additional=Lookup[req,"AdditionalFactors",<||>];
 If[!AssociationQ[additional]||!AllTrue[Keys[additional],StringQ]||!physicalDensityExactQ[additional]||AnyTrue[Values[additional],MemberQ[{None,Automatic},#]&],
  coefficientAssemblyFail["NamedExactAdditionalDensityFactorsRequired"]];
 flux=physicalDensityFactorRecord[req,"FluxFactor"];
 jacobian=physicalDensityFactorRecord[req,"ObservedVariableJacobian"];
 factorRecords=<|"FluxFactor"->flux,"ObservedVariableJacobian"->jacobian,
  "AdditionalFactors"->Association@KeyValueMap[#1-><|"Status"->"Supplied","Factor"->#2|>&,additional]|>;
 extra=Times@@Join[Lookup[Select[{flux,jacobian},#["Status"]==="Supplied"&],"Factor",{}],Values[additional]];
 extra=coefficientRegulatorNormalize[extra,e];
 KeyValueMap[Function[{identity,value},
  id=physicalDensityID[identity];
  If[KeyExistsQ[byID,id],coefficientAssemblyFail["DuplicatePhysicalMasterDefinition",<|"Master"->id|>]];
  If[!AssociationQ[value]||!KeyExistsQ[value,"MasterIntegral"]||
    coefficientMasterID[value["MasterIntegral"]]=!=id,
   coefficientAssemblyFail["PhysicalDefinitionMasterMismatch",<|"Master"->id|>]];
  AssociateTo[byID,id->coefficientRegulatorNormalize[value,e,Lookup[value,"DimensionalRegulator",None]]]],definitions];
 ids=coefficientMasterID/@Lookup[table["Masters"],"Master"];
 If[Complement[ids,Keys[byID]]=!={},coefficientAssemblyFail["PhysicalMasterDefinitionsIncomplete",
  <|"MissingMasterIntegrals"->Complement[ids,Keys[byID]]|>]];
 Do[
  master=entry["Master"];id=coefficientMasterID[master];definition=byID[id];
  powers=Lookup[definition,"PropagatorPowers",None];dim=Lookup[definition,"Dimension",None];
  loops=Lookup[definition,"LoopMomenta",None];
  If[powers=!=Last[id]||!ListQ[loops]||!ListQ[Lookup[definition,"Prescription",None]]||
    Length[loops]=!=Length[definition["Prescription"]]||dim===None||!physicalDensityExactQ[KeyTake[definition,{"Dimension","LoopMomenta","Prescription","MeasurePrefactor","MasterIntegralPrefactor","PropagatorPowers"}]],
   coefficientAssemblyFail["PhysicalMasterScalingDefinitionIncomplete",<|"Master"->id|>]];
  dimensions=Lookup[definition,"PropagatorMassDimensions",Automatic];
  If[dimensions===Automatic,
   If[!ListQ[Lookup[definition,"PropagatorTypes",None]]||
     Length[definition["PropagatorTypes"]]=!=Length[powers]||
     !AllTrue[definition["PropagatorTypes"],MemberQ[{"QuadraticLorentzian","LinearLorentzian"},#]&],
    coefficientAssemblyFail["InversePropagatorMassDimensionsRequired",<|"Master"->id|>]];
   dimensions=ConstantArray[2,Length[powers]]];
  If[!VectorQ[dimensions,MatchQ[#,_Integer|_Rational]&]||Length[dimensions]=!=Length[powers],
   coefficientAssemblyFail["InversePropagatorMassDimensionsRequired",<|"Master"->id|>]];
  conversion=FeynFacet`MasterIntegralMeasureConversion[definition];
  If[FailureQ[conversion],coefficientAssemblyFail["PhysicalMasterMeasureConversionFailed",
    <|"Master"->id,"Cause"->conversion|>]];
  scaling=(scale/reference)^(Length[loops]dim/2-powers.dimensions/2);
  multiplier=conversion["Factor"]scaling;
  terms=(Join[#,<|"PreFactor"->change[extra multiplier #["PreFactor"]],
    "Coefficient"->change[#["Coefficient"]]|>]&/@entry["Terms"]);
  If[AnyTrue[sourceVariables,!FreeQ[terms,#]&],coefficientAssemblyFail["CoefficientKinematicsIncomplete",<|"Master"->id|>]];
  AppendTo[entries,Join[entry,<|"Terms"->terms|>]];
  AppendTo[normalizations,<|"MasterIntegral"->master,"IntegralDefinition"->definition,
   "MeasureConversion"->conversion,"PropagatorMassDimensions"->dimensions,
   "ScaleExponent"->Length[loops]dim/2-powers.dimensions/2,
   "ScaleFactor"->change[scaling],"PhysicalMasterCoefficientMultiplier"->change[multiplier]|>],
 {entry,table["Masters"]}];
 remainders=(Join[#,<|"PreFactor"->change[extra #["PreFactor"]],"Coefficient"->change[#["Coefficient"]]|>]&/@table["RemainderTerms"]);
 If[AnyTrue[sourceVariables,!FreeQ[{change[table["PreFactor"]],remainders},#]&],
  coefficientAssemblyFail["CoefficientKinematicsIncomplete"]];
 sourcePhase=table["PhaseSpace"];
 observable=If[KeyExistsQ[req,"ObservableMeasureConvention"],
  <|"Status"->"Supplied","Convention"->req["ObservableMeasureConvention"]|>,
  <|"Status"->"NotSupplied"|>];
 record=Join[raw,table,<|"Masters"->entries,"RemainderTerms"->remainders,
  "PreFactor"->change[table["PreFactor"]],"FractionMeasure"->change[table["FractionMeasure"]],
  "Variables"->DeleteDuplicates[Cases[change[table["Variables"]],var_Symbol,{0,Infinity}]],
  "PhaseSpace"->1,"SourcePhaseSpace"->sourcePhase,
  "CoefficientConvention"->"PhysicalMasterAtReferenceScale",
  "PhysicalMasterNormalizationApplied"->True,"Status"->"PhysicalMasterCoefficientDensityConstructed",
  "PhysicalDensityNormalization"-><|"Scale"->change[scale],"ReferenceScale"->change[reference],
    "Assumptions"->change[assumptions],"KinematicRules"->rules,
    "EliminatedKinematicVariables"->sourceVariables,"Masters"->normalizations,
    "SuppliedFactors"->factorRecords,"AdditionalFactorProduct"->change[extra],
    "ObservableMeasureConvention"->observable,"SourceCoefficientFile"->inputSource,
    "FactorDescriptions"->Lookup[req,"FactorDescriptions",<||>],
    "ScaleConvention"->"All inverse-propagator mass dimensions scale together; dimensionless mass and kinematic ratios are fixed.",
    "SourcePhaseSpace"->sourcePhase,"PhaseSpaceIncludedInPhysicalMasters"->True,
    "GlobalDistributionPrefactorPreserved"->True,
    "LaurentRepresentationsAndTruncationsPreserved"->True,
    "CompleteDifferentialCrossSectionClaimed"->False|>|>];
 transformed=FeynFacet`ReadMasterIntegralCoefficients[record,"DimensionalRegulator"->e];
 If[FailureQ[transformed],coefficientAssemblyFail["ConvertedDensityCoefficientDataInvalid",<|"Cause"->transformed|>]];
 transformed
 ],"CoefficientAssembly"];
FeynFacet`ConstructPhysicalMasterCoefficientDensity[___] :=
 Failure["CoefficientTablePhysicalDefinitionsAndRequestRequired",<||>];
