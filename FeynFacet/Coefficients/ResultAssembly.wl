(* One assembly path for exact and finite Laurent coefficient terms.
   Analytic signatures remain outside each rational coefficient. *)
finiteFieldAssembleResult[data_Association,metadata_Association,kiraFile_String,
 context_Association,traceData_Association,trace_Association,
 reconstruction_Association,executable_String,threads_Integer] := Catch[Module[
 {e=$feynFacetEpsilon,supportContext,directRules,columnTerms,outputs,grouped,
  terms,certifyTerm,signatureValue,recordsByName,equivalence,classByName,
  masterData,remainder,forbiddenMomenta,remainingMomenta,rootSubstitutions,
  remainingFractionObjects,cutCheck,reconstructionData,arithmetic},
 If[!TrueQ[traceData["CompleteTargetSet"]],Throw[$Failed,"CoefficientAssembly"]];
 supportContext=Join[context,<|"ExternalDistribution"->data["PhaseSpace"]|>];
 directRules=Normal[context["DimensionlessCoordinates"]];
 columnTerms=Lookup[reconstruction,"ColumnTerms",None];
 If[columnTerms===None,
  columnTerms=({<|"Representation"->"Exact","PreFactor"->1,"Coefficient"->#|>}&/@reconstruction["Expressions"])];
 If[!ListQ[columnTerms]||Length[columnTerms]=!=Length[traceData["OutputMetadata"]]||
   !AllTrue[columnTerms,MatchQ[#,{__Association}]&],Throw[$Failed,"CoefficientAssembly"]];
 If[!AllTrue[traceData["OutputMetadata"],IntegerQ[#["MasterIndex"]]&&
    0<=#["MasterIndex"]<=Length[traceData["Masters"]]&&
    IntegerQ[#["SignatureIndex"]]&&1<=#["SignatureIndex"]<=Length[traceData["Signatures"]]&],
  Throw[$Failed,"CoefficientAssembly"]];
 signatureValue[index_]:=signatureValue[index]=finiteFieldCertifyPhysicalVariables[
  coefficientRegulatorNormalize[ReleaseHold[traceData["Signatures"][index]],e],supportContext];
 certifyTerm[t_,signature_] := Module[{term,p,c,declared},
  declared=If[AssociationQ[Lookup[t,"Coefficient",None]],Lookup[t["Coefficient"],"SeriesVariable",None],None];
  term=coefficientTermRead[coefficientRegulatorNormalize[t,e,declared],e];
  p=finiteFieldCertifyPhysicalVariables[signature term["PreFactor"],supportContext];
  c=term["Coefficient"];
  c=If[term["Representation"]==="Exact",
    finiteFieldCertifyPhysicalVariables[c,supportContext],
    Append[c,"Orders"->(finiteFieldCertifyPhysicalVariables[#,supportContext]&/@c["Orders"])]];
  If[!FreeQ[{p,c},$Failed],Throw[$Failed,"CoefficientAssembly"]];
  Join[term,<|"PreFactor"->(p/.directRules),"Coefficient"->(c/.directRules)|>]
 ];
 outputs=MapThread[Function[{entry,values},
  <|"MasterIndex"->entry["MasterIndex"],
    "Terms"->(certifyTerm[#,signatureValue[entry["SignatureIndex"]]]&/@values)|>],
  {traceData["OutputMetadata"],columnTerms}];
 grouped=GroupBy[outputs,#["MasterIndex"]&];
 terms[index_]:=Flatten[Lookup[Lookup[grouped,index,{}],"Terms",{}],1];
 recordsByName=Association[#["Topology"][[1]]->#&/@metadata["Topologies"]];
 equivalence=metadata["TopologyEquivalence"];
 classByName=If[AssociationQ[equivalence]&&KeyExistsQ[equivalence,"Classes"],
  Association[#["Representative"]->#&/@equivalence["Classes"]],<||>];
 masterData=MapIndexed[Function[{master,position},Module[{record=recordsByName[master[[1]]],value},
  value=terms[First[position]];
  If[value==={},value={<|"Representation"->"Exact","PreFactor"->1,"Coefficient"->0|>}];
  <|"Master"->master,"Terms"->value,"TopologyName"->master[[1]],
    "CutMomenta"->record["CutMomenta"],"CutIndices"->record["CutIndices"],
    "CutDirections"->record["CutDirections"],
    "TopologyClass"->Lookup[classByName,master[[1]],Missing["NotFound"]]|>]],
  traceData["Masters"]];
 remainder=terms[0];
 forbiddenMomenta=coefficientForbiddenMomenta[data["Setup"]];
 arithmetic=Map[{#["PreFactor"],If[#["Representation"]==="Exact",
   #["Coefficient"],Values[#["Coefficient"]["Orders"]]]}&,
   Join[Flatten[Lookup[masterData,"Terms"],1],remainder]];
 remainingMomenta=remainingDeclaredMomenta[arithmetic,forbiddenMomenta];
 rootSubstitutions=Lookup[context,"RootSubstitutions",<||>];
 remainingFractionObjects=Select[Join[context["FractionVariables"],context["FractionRootVariables"],
   If[AssociationQ[rootSubstitutions],#["Root"]&/@Values[rootSubstitutions],{}]],
  !FreeQ[arithmetic,#]&];
 If[remainingMomenta=!={}||remainingFractionObjects=!={}||
   !FreeQ[{arithmetic,traceData["PhysicalFactor"]},System`D],Throw[$Failed,"CoefficientAssembly"]];
 cutCheck=validateCutGLIs[Lookup[masterData,"Master"],metadata["Topologies"]];
 If[cutCheck=!=True,Throw[$Failed,"CoefficientAssembly"]];
  reconstructionData = <|
    "Format" -> $finiteFieldReconstructionFormat,
    "FormatVersion" -> $finiteFieldReconstructionVersion,
    "Method" -> "SharedMultiOutputTrace",
    "CompleteTargetSet" -> traceData["CompleteTargetSet"],
    "ProcessedTargetCount" -> traceData["ProcessedTargetCount"],
    "TargetCount" -> traceData["TargetCount"],
    "OutputCount" -> Length[traceData["OutputOrder"]],
    "SignatureCount" -> Length[traceData["Signatures"]],
    "RationalVariableCount" -> Length[traceData["Variables"]],
    "TraceBytes" -> trace["TraceBytes"],
    "ReconstructedBytes" -> reconstruction["ResultBytes"],
    "TraceBuildSeconds" -> trace["BuildSeconds"],
    "ReconstructionSeconds" -> reconstruction["ReconstructionSeconds"],
    "Threads" -> threads,
    "RatracerExecutable" -> executable,
    "RatracerExecutableHash" -> coefficientFileHash[executable],
    "TraceFile" -> trace["TraceFile"],
    "TraceFileHash" -> coefficientFileHash[trace["TraceFile"]],
    "ResultFile" -> reconstruction["ResultFile"],
    "ResultFileHash" -> coefficientFileHash[reconstruction["ResultFile"]]
  |>;
  Join[
    <||>,
    resultContext[data],
    <|
      "FractionMeasure" -> data["FractionMeasure"],
      "PhaseSpace" -> data["PhaseSpace"],
      "PreFactor" -> traceData["PhysicalFactor"],
      "RemainderTerms" -> remainder,
      "Masters" -> masterData,
      "HadronicNormalization" -> <|
        "PreFactor" -> traceData["PhysicalFactor"],
        "DistributionFactor" -> context["ExpectedDistributionFactor"],
        "LaurentValuation" -> context["ExpectedLaurentValuation"],
        "DimensionlessCoordinates" -> context["DimensionlessCoordinates"],
        "CoordinateRestriction" -> <|"Equalities"->Lookup[context,"CoordinateEqualities",{}],
          "ExternalDistribution"->data["PhaseSpace"],"NormalDerivativeDataAvailable"->False|>,
        "BranchGrammar" -> context["BranchGrammar"],
        (* Provenance of the root treatment.  The root variables are no
           longer a representation of the result - they are the
           transient lift of the entrywise descend, and what the result
           records is which of them were eliminated, with the exact
           relation used, plus the descend telemetry. *)
        "RootDescend" -> <|
          "EliminatedRoots" -> If[
            AssociationQ[rootSubstitutions],
            Association @ KeyValueMap[
              Function[{quantity, substitutionData},
                quantity ->
                  substitutionData["Constant"] substitutionData["Root"]^2
              ],
              rootSubstitutions
            ],
            <||>
          ],
          "TraceVariables" -> traceData["Variables"],
          "ScalePowers" -> Lookup[traceData, "ScalePowers", {}],
          "Statistics" -> Lookup[traceData, "DescendStatistics", <||>]
        |>
      |>,
      "FiniteFieldReconstruction" -> reconstructionData,
      "Topologies" -> metadata["Topologies"],
      "KiraArtifact" -> ExpandFileName[kiraFile],
      "ReverseRules" -> metadata["ReverseRules"],
      "TopologyEquivalence" -> equivalence,
      "Assumptions" -> data["AnalyticContext", "Assumptions"],
      "AnalyticContext" -> data["AnalyticContext"],
      "MassDimensions" -> metadata["MassDimensions"],
      "KiraManifest" -> metadata["KiraManifest"],
      "DimensionRule" -> $dimensionRule,
      "ReductionInputFingerprint" -> metadata["ReductionInputFingerprint"],
      "SourceInputFingerprint" -> metadata["SourceInputFingerprint"]
    |>
  ]
], "CoefficientAssembly"];
