(* Numerical assembly checks using already retained physical master values. *)
BeginPackage["FeynFacet`"];
CheckFiniteDensityWithRetainedReferences::usage="CheckFiniteDensityWithRetainedReferences[density,bundles,request] contracts selected finite density orders with already retained AMFlow and physical-solution coefficients at one matching point. It never evaluates master integrals or changes symbolic coefficients.";
Begin["`Private`"];
Clear[densityReferenceFail,densityReferenceMasterID,densityReferenceContraction];
densityReferenceFail[tag_,data_:<||>] := Throw[Failure[tag,data],"DensityReference"];
densityReferenceMasterID[m_] := If[MatchQ[m,h_[_,{__Integer}]]&&SymbolName[Head[m]]==="GLI",
 {If[StringQ[m[[1]]],m[[1]],SymbolName[m[[1]]]],m[[2]]},
 densityReferenceFail["ReferenceMasterIdentifierInvalid"]];
densityReferenceContraction[d_,bundles_,request_] := Module[
 {orders,point,vars,parameters,wp,tolerance,expected,aa,coeffMap,selection,rows,weight,col,selected={},families,
 validated=<||>,bundle,ref,physical,spec,amRequest,comparison,position,sourceIDs,neededRows,
 values=<||>,definition,indices,expr,numeric,rules,numericCoefficient,readValue,reports={},terms,amTerms,physicalTerms,
 amSum,physicalSum,amScale,physicalScale,amResidual,physicalResidual,agreement,ratio,contributions,rem,relative,
 declaredPrecision,orderTerms,selectedIndices={},exactZero,am,ph,family},
 If[Lookup[d,"DataType",None]=!="FiniteMasterIntegralDensity"||
   !TrueQ[Lookup[d,"PhysicalBoundaryCoefficientsResolved",False]],densityReferenceFail["PhysicalFiniteDensityRequired"]];
 orders=Lookup[request,"Orders",None];point=Lookup[request,"Point",None];vars=d["KinematicVariables"];
 parameters=Lookup[request,"ParameterValuesByName",<||>];wp=Lookup[request,"WorkingPrecision",40];
 tolerance=Lookup[request,"RelativeTolerance",10^-12];expected=Lookup[request,"ExpectedZeroOrders",{}];
 If[!ListQ[orders]||orders==={}||!AllTrue[orders,IntegerQ]||!DuplicateFreeQ[orders]||
  !AllTrue[orders,KeyExistsQ[d["Coefficients"],#]&]||!ListQ[point]||Length[point]=!=Length[vars]||
  !AssociationQ[parameters]||!AllTrue[Keys[parameters],StringQ]||!IntegerQ[wp]||wp<15||
  !TrueQ[0<tolerance<1]||!ListQ[expected]||!SubsetQ[orders,expected],
  densityReferenceFail["ReferenceContractionRequestInvalid"]];
 aa=d["AlgebraicDefinitions"];coeffMap=Association@Table[
  {r["Master"],r["EpsilonOrder"]}->r["Expression"],{r,d["CoefficientFunctionIndex"]}];
 selection=Association@Table[q->Table[
   weight=Lookup[coeffMap,Key[{r["Master"],q-r["EpsilonOrder"]}],0];
   If[weight=!=0&&r["Expression"]=!=0,Join[r,<|"Weight"->weight|>],Nothing],
   {r,d["MasterCoefficientIndex"]}],{q,orders}];
 selected=Flatten[Values[selection],1];families=DeleteDuplicates[First[ #["Master"]]&/@selected];
 If[!AllTrue[families,KeyExistsQ[bundles,#]&],densityReferenceFail["RetainedReferenceBundlesMissing",
  <|"Families"->Select[families,!KeyExistsQ[bundles,#]&]|>]];
 Do[
  bundle=bundles[family];{ref,physical,spec,amRequest,comparison}=Lookup[bundle,
    {"AMFlow","PhysicalEvaluation","ValidationRequest","AMFlowRequest","Comparison"},None];
  If[!AllTrue[{ref,physical,spec,amRequest,comparison},AssociationQ],
   densityReferenceFail["RetainedReferenceBundleInvalid",<|"Family"->family|>]];
  If[Lookup[ref,"Status",None]=!="AMFlowMastersEvaluated"||Lookup[ref,"AMFlowOrderConvention",None]=!="OffsetFromMinusTwoLoops"||Lookup[comparison,"Status",None]=!="Passed"||
    !TrueQ[Lookup[comparison,"ReferenceNormalizationAndCutsMatched",False]]||
    !TrueQ[Lookup[physical,"PhysicalBoundaryValuesDetermined",False]]||
    ref["Point"]=!=point||physical["Point"]=!=point||spec["Point"]=!=point||amRequest["Point"]=!=point||
    ref["KinematicVariables"]=!=vars||spec["KinematicVariables"]=!=vars||
    ref["IntegralDefinition"]=!=amRequest["IntegralDefinition"]||
    ref["MasterIntegralPrefactors"]=!=amRequest["MasterIntegralPrefactors"],
   densityReferenceFail["ReferencePointNormalizationOrValidationMismatch",<|"Family"->family|>]];
  sourceIDs=AssociationThread[ref["RowIndices"],densityReferenceMasterID/@ref["OriginalMasterIntegralBasis"]];
  rows=Select[selected,First[#["Master"]]===family&];
  If[!AllTrue[rows,Lookup[sourceIDs,#["Row"],None]===#["Master"]&&MemberQ[comparison["SelectedRows"],#["Row"]]&],
   densityReferenceFail["ReferenceMasterRowsMismatch",<|"Family"->family|>]];
  AssociateTo[validated,family->bundle],{family,families}];
 numericCoefficient[0]:=0;
 numericCoefficient[r:FeynFacetSolution`a[i_Integer]] := Module[{found,expr,numeric},
  If[KeyExistsQ[values,i],Return[values[i]]];
  If[!TrueQ[1<=i<=Length[aa]],densityReferenceFail["CoefficientDefinitionIndexInvalid"]];
  expr=aa[[i]];
  If[!FreeQ[expr,_FeynFacetSolution`F|_FeynFacetSolution`K|_FeynFacetSolution`B|_FeynFacetSolution`C|
     _Series|_SeriesData|_SeriesCoefficient|d["DimensionalRegulator"]],
   densityReferenceFail["ExplicitCoefficientFunctionRequired",<|"AlgebraicIndex"->i|>]];
  expr=expr/.FeynFacetSolution`a[j_Integer]:>If[1<=j<i,numericCoefficient[FeynFacetSolution`a[j]],
    densityReferenceFail["CoefficientDefinitionDependencyInvalid",<|"AlgebraicIndex"->i,"Dependency"->j|>]];
  expr=expr/.Thread[vars->point];
  expr=expr/.s_Symbol/;With[{sym=s},Context[sym]]=!="System`"&&KeyExistsQ[parameters,SymbolName[s]]:>parameters[SymbolName[s]];
  numeric=TimeConstrained[N[expr,wp],30,$Aborted];
  If[!NumberQ[numeric]||!FreeQ[numeric,Indeterminate|_DirectedInfinity],
   found=DeleteDuplicates@Cases[expr,s_Symbol/;With[{sym=s},Context[sym]]=!="System`":>ToString[s,InputForm],{0,Infinity}];
   densityReferenceFail["NumericCoefficientParametersUnresolved",<|"AlgebraicIndex"->i,"Symbols"->found|>]];
  AssociateTo[values,i->numeric];AppendTo[selectedIndices,i];numeric];
 numericCoefficient[other_] := densityReferenceFail["ExplicitCoefficientReferenceRequired"];
 readValue[record_,row_,q_,family_] := Module[{table,value},
  table=Lookup[record,"MasterIntegralEpsilonCoefficients",<||>];
  If[!KeyExistsQ[table,q]||!KeyExistsQ[Association[table[q]],row],
   densityReferenceFail["RetainedMasterCoefficientMissing",<|"Family"->family,"Row"->row,"EpsilonOrder"->q|>]];
  value=Association[table[q]][row];
  If[!NumberQ[value],densityReferenceFail["RetainedNumericMasterCoefficientRequired",<|"Family"->family,"Row"->row,"EpsilonOrder"->q|>]];
  N[value,wp]];
 relative[value_,scale_] := If[TrueQ[scale==0],If[TrueQ[value==0],0,Infinity],Abs[value]/scale];
 Do[
  orderTerms=selection[q];amTerms={};physicalTerms={};contributions={};
  Do[
   family=First[row["Master"]];bundle=validated[family];weight=numericCoefficient[row["Weight"]];
   am=readValue[bundle["AMFlow"],row["Row"],row["EpsilonOrder"],family];
   ph=readValue[bundle["PhysicalEvaluation"],row["Row"],row["EpsilonOrder"],family];
   AppendTo[amTerms,weight am];AppendTo[physicalTerms,weight ph];
   AppendTo[contributions,<|"Master"->row["Master"],"Row"->row["Row"],"MasterEpsilonOrder"->row["EpsilonOrder"],
     "WeightReference"->row["Weight"],"WeightValue"->weight,"AMFlowMasterValue"->am,"PhysicalMasterValue"->ph,
     "AMFlowContribution"->weight am,"PhysicalContribution"->weight ph|>],{row,orderTerms}];
  rem=numericCoefficient[Lookup[d["ScalarRemainderCoefficients"],q,0]];
  amSum=Total[amTerms]+rem;physicalSum=Total[physicalTerms]+rem;
  amScale=Total[Abs/@amTerms]+Abs[rem];physicalScale=Total[Abs/@physicalTerms]+Abs[rem];
  amResidual=relative[amSum,amScale];physicalResidual=relative[physicalSum,physicalScale];
  agreement=relative[amSum-physicalSum,Max[amScale,physicalScale]];
  exactZero=TrueQ[d["Coefficients"][q]===0];
  AppendTo[reports,<|"EpsilonOrder"->q,"TermCount"->Length[orderTerms],"SymbolicCoefficientExactlyZero"->exactZero,
   "AMFlowSum"->amSum,"PhysicalSum"->physicalSum,"AMFlowAbsoluteContributionSum"->amScale,
   "PhysicalAbsoluteContributionSum"->physicalScale,"AMFlowNormalizedResidual"->amResidual,
   "PhysicalNormalizedResidual"->physicalResidual,"NormalizedReferenceDifference"->agreement,
   "AMFlowCancellationConditionNumber"->If[TrueQ[amSum==0],If[TrueQ[amScale==0],1,Infinity],amScale/Abs[amSum]],
   "PhysicalCancellationConditionNumber"->If[TrueQ[physicalSum==0],If[TrueQ[physicalScale==0],1,Infinity],physicalScale/Abs[physicalSum]],
   "ReferenceAgreementObserved"->TrueQ[agreement<=tolerance],
   "CancellationObserved"->TrueQ[amResidual<=tolerance&&physicalResidual<=tolerance&&agreement<=tolerance],
   "Contributions"->contributions|>],{q,orders}];
 <|"DataType"->"FiniteDensityRetainedReferenceCheck","Status"->If[AllTrue[reports,
   TrueQ[#["ReferenceAgreementObserved"]]&&(!MemberQ[expected,#["EpsilonOrder"]]||TrueQ[#["CancellationObserved"]])&],
   "Passed","Failed"],"Point"->point,"Orders"->orders,"ExpectedZeroOrders"->expected,
  "ParameterValuesByName"->parameters,"WorkingPrecision"->wp,"RelativeTolerance"->tolerance,
  "SelectedMasterCoefficientCount"->Length[DeleteDuplicates[Lookup[selected,"Column",{}]]],
  "SelectedCoefficientDefinitionIndices"->selectedIndices,"Families"->families,
  "ReferencePrecisionGoals"->Association@Table[family-><|"AMFlow"->validated[family]["AMFlow"]["PrecisionGoal"],
   "PhysicalEvaluation"->validated[family]["PhysicalEvaluation"]["PrecisionGoal"]|>,{family,families}],
  "EpsilonIndependentPrefactorIncluded"->False,"NewMasterEvaluationsPerformed"->False,
  "SymbolicCoefficientsChanged"->False,"Reports"->reports|>
];
FeynFacet`CheckFiniteDensityWithRetainedReferences[d_Association,bundles_Association,request_Association] :=
 Catch[densityReferenceContraction[d,bundles,request],"DensityReference"];
End[];
EndPackage[];
