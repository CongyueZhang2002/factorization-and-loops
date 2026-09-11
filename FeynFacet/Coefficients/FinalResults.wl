(* One mathematical representation for retained coefficient results.
   Analytic prefactors remain outside finite Laurent coefficient records. *)
FeynFacet`ReadMasterIntegralCoefficients::usage =
 "ReadMasterIntegralCoefficients[fileOrRecord] reads the current final coefficient format, preserving explicit Laurent truncations and exact zero entries.";
FeynFacet`ExpandMasterIntegralCoefficient::usage =
 "ExpandMasterIntegralCoefficient[entry,epsilon,{low,high}] returns every requested coefficient of the sum of entry Terms, or fails if a stored Laurent truncation is insufficient. The table's global PreFactor remains separate.";
FeynFacet`MasterIntegralMeasureConversion::usage =
 "MasterIntegralMeasureConversion[definition] returns the factor converting the physical momentum-space master in definition to the normalized GLI measure used by the coefficient tables.";

coefficientAssemblyFail[tag_,data_:<||>] := Throw[Failure[tag,data],"CoefficientAssembly"];
coefficientExactDataQ[data_]:=exactDataQ[data]&&FreeQ[data,
 _Failure|_Missing|$Failed|$Aborted|Indeterminate|_DirectedInfinity|_SeriesData|_Series|_SeriesCoefficient];
(* Replacements can leave Association values in a noncanonical evaluated
   state: equal extracted rules then fail SameQ after serialization. Rebuild
   immediate data containers; held expressions and delayed rules stay held. *)
coefficientCanonicalContainers[data_Association] := Association@Map[
 Function[entry,If[Head[entry]===Rule,
   With[{key=First[entry],value=coefficientCanonicalContainers[Last[entry]]},Rule[key,value]],
   entry]],Normal[data]];
coefficientCanonicalContainers[data_List] := coefficientCanonicalContainers/@data;
coefficientCanonicalContainers[data_] := data;
coefficientRegulatorNormalize[x_,e_,declared_:None] := With[
 {names=DeleteDuplicates@Join[{"eps","ep","Epsilon"},
   If[MatchQ[declared,_Symbol]&&!MemberQ[{None,Automatic},declared],{SymbolName[declared]},{}]]},
 coefficientCanonicalContainers[x/.s_Symbol /; MemberQ[names,SymbolName[s]]:>e]];
coefficientMasterID[m_] := If[MatchQ[m,head_[_,{__Integer}]]&&SymbolName[Head[m]]==="GLI",
 {If[StringQ[m[[1]]],m[[1]],SymbolName[m[[1]]]],m[[2]]},
 coefficientAssemblyFail["ScalarMasterIntegralIdentifierRequired",<|"Master"->m|>]];
coefficientCanonicalMasterExpression[expr_] := expr/.m_/;
 MatchQ[m,head_[_,{__Integer}]]&&SymbolName[Head[m]]==="GLI":>
 FeynCalc`GLI[m[[1]],m[[2]]];

coefficientTermRead[term_Association,e_,defaultTruncation_:None] := Module[
 {p=Lookup[term,"PreFactor",1],c=Lookup[term,"Coefficient",Missing[]],
  rep=Lookup[term,"Representation",Automatic],orders,known,variable,keys},
 If[MissingQ[c],coefficientAssemblyFail["CoefficientTermMissing"]];
 If[rep===Automatic,rep=If[AssociationQ[c],"LaurentSeries","Exact"]];
 If[!coefficientExactDataQ[{p,c}],
  coefficientAssemblyFail["ExactCoefficientDataRequired"]];
 Which[
  rep==="Exact",
   If[AssociationQ[c]||!FreeQ[c,_SeriesData|_Series],
    coefficientAssemblyFail["ExactCoefficientExpressionRequired"]];
   <|"PreFactor"->p,"Representation"->"Exact","Coefficient"->c|>,
  rep==="LaurentSeries",
   If[!AssociationQ[c]||!AssociationQ[Lookup[c,"Orders",None]],
    coefficientAssemblyFail["FiniteLaurentCoefficientRecordRequired"]];
   variable=Lookup[c,"SeriesVariable",None];
   orders=KeySort[c["Orders"]];keys=Keys[orders];
   known=Lookup[c,"SeriesTruncation",defaultTruncation];
   If[!MatchQ[variable,_Symbol]||variable=!=e||keys==={}||
      !VectorQ[keys,IntegerQ]||!IntegerQ[known]||Last[keys]=!=known||
      keys=!=Range[First[keys],known]||!FreeQ[Values[orders],e],
    coefficientAssemblyFail["IncompleteLaurentCoefficientRecord",
      <|"AvailableOrders"->keys,"SeriesTruncation"->known|>]];
   Join[KeyTake[term,{"LaurentRemainderClass"}],
    <|"PreFactor"->p,"Representation"->"LaurentSeries",
     "Coefficient"-><|"SeriesVariable"->e,"Orders"->orders,"SeriesTruncation"->known|>|>],
  True,coefficientAssemblyFail["CoefficientRepresentationUnsupported",<|"Representation"->rep|>]]
];
coefficientTermRead[other_,e_,default_:None] :=
 coefficientAssemblyFail["CoefficientTermMustBeAnAssociation"];
coefficientExactZeroTermQ[t_] := t["PreFactor"]===0||
 (t["Representation"]==="Exact"&&t["Coefficient"]===0);

coefficientMeasures[setup_] := Catch[Module[{process,phase,loops,external,
   partons,counts,columns,makeLegs,phaseMomenta,integrated},
 (* A retained sum of diagrams has no SelectedIndex. Its integration measure
    depends only on external legs and loop momenta, not on a selected diagram. *)
 partons=Lookup[setup,"Partons",None];
 If[!MatchQ[partons,_Rule]||!AllTrue[List@@partons,ListQ],
  coefficientAssemblyFail["CoefficientMeasurePartonsRequired"]];
 counts=Length/@(List@@partons);
 columns=AssociationThread[legFields,
   normalizeSides[#,Lookup[setup,#,None],counts]&/@legInputKeys];
 makeLegs[side_]:=AssociationThread[legFields,#]&/@
   Transpose[Lookup[columns,legFields][[All,side]]];
 phaseMomenta=Lookup[setup,"PhaseSpaceMomentum",None];
 integrated=Lookup[setup,"PartonIntegrated",None];
 If[!MatchQ[phaseMomenta,{_Symbol..}]||!MatchQ[integrated,{_Symbol}]||
   !SubsetQ[columns["Momentum"][[2]],phaseMomenta]||
   !SubsetQ[phaseMomenta,integrated],
  coefficientAssemblyFail["CoefficientMeasurePhaseSpaceRequired"]];
 loops=loopSectorsFromSetup[setup]["LoopMomenta"];
 process=<|"Incoming"->makeLegs[1],"Outgoing"->makeLegs[2],
   "PhaseSpaceMomenta"->phaseMomenta,"IntegratedMomentum"->First[integrated]|>;
 phase=buildPhaseData[process,momentumEliminationRule[process]];
 external=First[splitFactorsByMomentum[phase["Cuts"],loops]];
 <|"FractionMeasure"->fractionMeasure[process],
   "PhaseSpace"->phase["Measure"] external/(I Pi^(D/2))^Length[remainingPhaseSpaceMomenta[process]]|>
 ],$collinearFailure];

(* The reconstruction algorithms return columns and metadata in memory.
   This is the sole constructor of their persisted coefficient table. *)
coefficientResultFromReconstruction[raw_Association]:=Module[{e=$feynFacetEpsilon,defs,terms,record},
 defs=KeyTake[raw,{"CardName","Setup","Pairs","AnalyticContext","Topologies",
  "TopologyEquivalence","ReverseRules","MassDimensions","DimensionRule"}];
 terms[x_]:=If[KeyExistsQ[x,"Terms"],x["Terms"],{Join[KeyTake[x,{"PreFactor","Coefficient"}],<|
  "Representation"->If[AssociationQ[x["Coefficient"]],"LaurentSeries","Exact"]|>]}];
 record=Join[KeyDrop[raw,Join[Keys[defs],{"Expression","Remainder","Masters","Format","FormatVersion"}]],
  <|"Format"->"FeynFacet-MasterIntegralCoefficients","FormatVersion"->1,
   "DimensionalRegulator"->e,"Definitions"->defs,"CompleteTargetSet"->True,
   "Masters"->(Join[KeyDrop[#,{"PreFactor","Coefficient"}],<|"Terms"->terms[#]|>]& /@ raw["Masters"]),
   "RemainderTerms"->If[KeyExistsQ[raw,"RemainderTerms"],raw["RemainderTerms"],terms[<|"PreFactor"->1,"Coefficient"->raw["Remainder"]|>]]|>];
 FeynFacet`ReadMasterIntegralCoefficients[coefficientRegulatorNormalize[record,e,Lookup[raw,"SeriesVariable",None]],"DimensionalRegulator"->e]
];
Options[FeynFacet`ReadMasterIntegralCoefficients]={"DimensionalRegulator"->Automatic};
FeynFacet`ReadMasterIntegralCoefficients[input_,OptionsPattern[]] := Catch[Module[
 {data=input,e=OptionValue["DimensionalRegulator"],defs,entries,terms,remainder,
  format,zeros={},masters={},m,measures,storedMeasures,source=None,truncation,declared,dimensionRule,regulators},
 If[StringQ[input],
  source=ExpandFileName[input];
  If[!FileExistsQ[source],coefficientAssemblyFail["CoefficientFileMissing",<|"File"->source|>]];
  data=If[ToLowerCase[FileExtension[source]]==="wxf",Import[source,"WXF"],Get[source]]];
 If[!AssociationQ[data],coefficientAssemblyFail["CoefficientResultRequired"]];
 format={Lookup[data,"Format",None],Lookup[data,"FormatVersion",None]};
 If[format=!={"FeynFacet-MasterIntegralCoefficients",1},
  coefficientAssemblyFail["CoefficientFormatUnsupported",<|"Format"->format|>]];
 If[e===Automatic,e=$feynFacetEpsilon];
 If[!MatchQ[e,_Symbol],coefficientAssemblyFail["DimensionalRegulatorRequired"]];
 declared=Lookup[data,"DimensionalRegulator",Lookup[data,"SeriesVariable",None]];
 If[declared===None,
  dimensionRule=Lookup[Lookup[data,"Definitions",<||>],"DimensionRule",Lookup[data,"DimensionRule",None]];
  If[MatchQ[dimensionRule,_Rule],
   regulators=DeleteDuplicates@Cases[Last[dimensionRule],s_Symbol/;Context[s]=!="System`",{0,Infinity}];
   If[Length[regulators]===1&&TrueQ[Coefficient[Last[dimensionRule],First[regulators]]===-2]&&
     IntegerQ[Expand[Last[dimensionRule]+2First[regulators]]],declared=First[regulators]]]];
 data=coefficientRegulatorNormalize[data,e,declared];
 defs=Lookup[data,"Definitions",<||>];
 If[!AssociationQ[defs]||!AssociationQ[Lookup[defs,"Setup",None]],
  coefficientAssemblyFail["CoefficientProcessDefinitionsRequired"]];
 entries=Lookup[data,"Masters",None];
 If[!ListQ[entries]||!AllTrue[entries,AssociationQ],
  coefficientAssemblyFail["CoefficientMasterEntriesRequired"]];
 truncation=Lookup[data,"SeriesTruncation",None];
 Do[
  m=Lookup[entry,"Master",Missing[]];coefficientMasterID[m];
  m=coefficientCanonicalMasterExpression[m];
  terms=coefficientTermRead[#,e,truncation]&/@Lookup[entry,"Terms",{}];
  If[terms==={},coefficientAssemblyFail["EmptyCoefficientTerms",<|"Master"->m|>]];
  terms=Select[terms,!coefficientExactZeroTermQ[#]&];
  If[terms==={},AppendTo[zeros,m],
   AppendTo[masters,Join[KeyDrop[entry,{"Coefficient","PreFactor","Terms"}],<|"Master"->m,"Terms"->terms|>]]],
 {entry,entries}];
 If[!DuplicateFreeQ[coefficientMasterID/@Lookup[entries,"Master"]],
  coefficientAssemblyFail["DuplicateCoefficientMasterEntries"]];
 remainder=coefficientTermRead[#,e,truncation]&/@Lookup[data,"RemainderTerms",{}];
 remainder=Select[remainder,!coefficientExactZeroTermQ[#]&];
 storedMeasures=KeyTake[data,{"FractionMeasure","PhaseSpace"}];
 measures=If[Length[storedMeasures]===2,storedMeasures,coefficientMeasures[defs["Setup"]]];
 If[!AssociationQ[measures]||Length[KeyTake[measures,{"FractionMeasure","PhaseSpace"}]]=!=2,
  coefficientAssemblyFail["CoefficientMeasureCouldNotBeDerived"]];
 If[Lookup[data,"CompleteTargetSet",True]===False,
  coefficientAssemblyFail["IncompleteCoefficientTargetSet"]];
 coefficientCanonicalContainers@Join[data,
  <|"Format"->"FeynFacet-MasterIntegralCoefficients","FormatVersion"->1,
   "PreFactor"->Lookup[data,"PreFactor",1],"DimensionalRegulator"->e,
   "Variables"->Lookup[data,"Variables",{}],"Masters"->masters,
   "RemainderTerms"->remainder,"Definitions"->defs,"CompleteTargetSet"->True,
   "ExactZeroMasterIntegrals"->Join[Lookup[data,"ExactZeroMasterIntegrals",{}],zeros],
   "Source"->If[source===None,Lookup[data,"Source",None],source],"InputFormat"->format|>,measures]
 ],"CoefficientAssembly"];

(* Materialize epsilon coefficients without expanding their kinematic
   rational factors. This is shared by ordinary and endpoint assembly. *)
coefficientFiniteSeriesCoefficients[x_,e_,lo_,hi_] := Module[
 {coefs},
 coefs=regulatorSeriesCoefficients[x,e,{lo,hi}];
 If[FailureQ[coefs],coefficientAssemblyFail["CoefficientSeriesExpansionFailed",<|"Cause"->coefs,"RequestedRange"->{lo,hi}|>]];
 If[!AssociationQ[coefs]||Keys[coefs]=!=Range[lo,hi],coefficientAssemblyFail["RegulatorSeriesArithmeticNotLoaded"]];
 If[!FreeQ[Values[coefs],e|_Series|_SeriesData|_SeriesCoefficient|_Missing|_Failure|Indeterminate|_DirectedInfinity],
  coefficientAssemblyFail["EpsilonDependentLaurentCoefficient"]];
 coefs
];

FeynFacet`ExpandMasterIntegralCoefficient[entry_Association,e_Symbol,
 range:{lo_Integer,hi_Integer}] := Catch[Module[
 {result,term,p,c,pv,required,declared,part,pcoeff,cmin},
 If[lo>hi||!ListQ[Lookup[entry,"Terms",None]],
  coefficientAssemblyFail["CoefficientExpansionRequestInvalid"]];
 result=Association@Table[k->0,{k,lo,hi}];
 Do[
  declared=If[AssociationQ[Lookup[t,"Coefficient",None]],
    Lookup[t["Coefficient"],"SeriesVariable",e],Lookup[entry,"DimensionalRegulator",e]];
  term=coefficientTermRead[coefficientRegulatorNormalize[t,e,declared],e];
  If[coefficientExactZeroTermQ[term],Continue[]];
  p=term["PreFactor"];c=term["Coefficient"];
  pv=FeynFacet`DetermineMeromorphicLaurentLowerBound[p,e];
  If[pv===Infinity,Continue[]];
  If[!IntegerQ[pv],coefficientAssemblyFail["AnalyticPrefactorLaurentBoundRequired",<|"Cause"->pv|>]];
  If[term["Representation"]==="LaurentSeries",
   epsilonAuditMultiplier[p,e,First[Keys[c["Orders"]]],c["SeriesTruncation"],hi,
     "Stage4/FiniteCoefficientPrefactor",Lookup[entry,"Master",None]];
   required=hi-pv;
   If[required>c["SeriesTruncation"],
    coefficientAssemblyFail["CoefficientEpsilonOrdersInsufficient",
     <|"Master"->Lookup[entry,"Master",None],"RequiredCoefficientUpperOrder"->required,
       "KnownCoefficientUpperOrder"->c["SeriesTruncation"],
       "PrefactorLaurentLowerBound"->pv|>]];
   cmin=First[Keys[c["Orders"]]];
   pcoeff=If[hi-cmin<pv,<||>,coefficientFiniteSeriesCoefficients[p,e,pv,hi-cmin]];
   epsilonAuditProduct[{epsilonAuditSpec["Prefactor",pv,hi-cmin,
      PolynomialQ[p,e]&&Exponent[p,e]<=hi-cmin],
     epsilonAuditSpec["FiniteCoefficient",cmin,c["SeriesTruncation"]]},hi,
     "Stage4/CoefficientConvolution",Lookup[entry,"Master",None]];
   part=Association@Table[k->Total[Table[
      Lookup[pcoeff,j,0] Lookup[c["Orders"],k-j,0],
      {j,pv,k-cmin}]],{k,lo,hi}],
   part=coefficientFiniteSeriesCoefficients[p c,e,lo,hi]];
  result=Association@Table[k->(result[k]+part[k]),{k,lo,hi}],
 {t,entry["Terms"]}];
 <|"DimensionalRegulator"->e,"EpsilonOrderRange"->range,"Coefficients"->result,
   "GlobalPrefactorIncluded"->False|>
 ],"CoefficientAssembly"];

FeynFacet`MasterIntegralMeasureConversion[definition_Association] := Catch[Module[
 {dim=Lookup[definition,"Dimension",None],phase=Lookup[definition,"PhaseSpaceLoopCount",None],
  prescription=Lookup[definition,"Prescription",None],measure=Lookup[definition,"MeasurePrefactor",None],
  extra=Lookup[definition,"MasterIntegralPrefactor",1],negative},
 If[!IntegerQ[phase]||phase<0||!ListQ[prescription]||
   !AllTrue[prescription,MemberQ[{-1,0,1},#]&]||Count[prescription,0]=!=phase||
   dim===None||measure===None||measure===0||extra===0,
  coefficientAssemblyFail["MasterMeasureDefinitionIncomplete"]];
 negative=Count[prescription,-1];
 <|"Factor"->1/(I Pi^(dim/2))^Length[prescription]/measure/extra,
   "FromConvention"->"PhysicalMomentumSpaceMaster",
   "ToConvention"->"NormalizedGLICoefficientIntegral",
   "PhaseSpaceLoopCount"->phase,"NegativePrescriptionLoopCount"->negative|>
 ],"CoefficientAssembly"];
