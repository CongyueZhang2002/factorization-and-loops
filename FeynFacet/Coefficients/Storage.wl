(* Bounded-memory reconstruction and exact simplification of IBP coefficients. *)

CoefficientSimplification::collect =
  "Bounded target collection failed at check `1`: `2`.";

$coefficientStoreFormat = "FeynFacet-CoefficientStore";
$coefficientStoreVersion = 2;

$coefficientLateSetupKeys = {
  "HadronicVariables",
  "CoefficientKinematics",
  "KinematicMassDimensions",
  "ColorRules"
};

coefficientAnalyticContextQ[context_] := Module[{required},
  required = {
    "Gamma5Scheme", "GlobalBasis", "GlobalBasisGram",
    "SetEvanescentZero", "SetMassZero", "SetDistributionZero",
    "CollinearRelations", "Assumptions", "KinematicMassDimensions",
    "LoopDimension", "DimensionRule", "CutConvention",
    "DistributionConvention", "FeynFacetSourceHash", "Fingerprint"
  };
  AssociationQ[context] &&
    ContainsAll[Keys[context], required] &&
    context["Gamma5Scheme"] === "BMHV" &&
    (* same shape validation as analyticContextQ (Core.wl): the rule must
       be D -> a - 2 regulator with integer a, not identity with the
       front end's own $dimensionRule *)
    analyticDimensionRuleQ[context["DimensionRule"],
      analyticContextRegulator[context]] &&
    StringQ[context["FeynFacetSourceHash"]] &&
    context["Fingerprint"] ===
      reductionFingerprint[KeyDrop[context, "Fingerprint"]] &&
    exactDataQ[context]
];

coefficientKiraReductionQ[kira_] := Block[
  {analyticContextQ = coefficientAnalyticContextQ},
  kiraReductionQ[kira]
];

(* Do a freshly read input set and a stored artifact describe the same
   diagram set?  This used to be answered by comparing the two stored
   ABSOLUTE result directories, so moving or renaming a result tree
   turned every stored artifact into "another diagram set".  The
   analytic-context fingerprint is the content identity of the inputs
   (scheme, basis, kinematics, dimension rule, source hash) and is what
   is compared now; an artifact that carries no fingerprint on either
   side falls back to the stored paths, exactly as before (generality
   pass 2026-08-23). *)
coefficientContextFingerprint[data_] := Lookup[
  Lookup[data, "AnalyticContext", <||>], "Fingerprint",
  Missing["NoFingerprint"]
];

coefficientSameInputsQ[data_, stored_] := Module[{left, right, a, b},
  left = coefficientContextFingerprint[data];
  right = coefficientContextFingerprint[stored];
  If[StringQ[left] && StringQ[right], Return[left === right]];
  a = Lookup[data, "ResultDirectory", Missing[]];
  b = Lookup[stored, "ResultDirectory", Missing[]];
  StringQ[a] && StringQ[b] && ExpandFileName[a] === ExpandFileName[b]
];

coefficientShardIndex[key_, count_Integer] :=
  1 + Mod[Hash[HoldComplete[key], "CRC32"], count];

coefficientShardFile[directory_, prefix_, index_Integer] := FileNameJoin[{
  directory,
  prefix <> "_" <> IntegerString[index, 10, 4] <> ".bin"
}];

(* Reconstruction work stays in the process coefficient working directory.
   The default deletion guard accepts only run directories inside this layout.
   An explicit-root guard remains available for isolated workspaces. *)
coefficientWorkspaceRoot[] := $feynFacetWorkspaceRoot;

coefficientSafeWorkPathQ[path_String] := Module[{parts,base},
  base=coefficientWorkspaceRoot[];
  If[!coefficientSafeWorkPathQ[path,base],Return[False]];
  parts=Drop[DeleteCases[FileNameSplit[ExpandFileName[path]],""],Length[DeleteCases[FileNameSplit[ExpandFileName[base]],""]]];
  Length[parts]>=4 && AnyTrue[Range[2,Length[parts]-2],MemberQ[{{"Work","CoefficientSimplification"},{"Results","CoefficientSimplification"}},Take[parts,{#,#+1}]]&]
];

coefficientSafeWorkPathQ[path_String, workspaceRoot_String] :=
  Module[{root, normalized},
    root = ExpandFileName[workspaceRoot];
    If[!StringEndsQ[root,$PathnameSeparator],root=root<>$PathnameSeparator];
    normalized = ExpandFileName[path];
    If[!StringEndsQ[normalized,$PathnameSeparator],normalized=normalized<>$PathnameSeparator];
    StringStartsQ[normalized, root] && normalized =!= root
  ];

coefficientWriteFinalResult[result_Association, file_String] := Module[
  {temporary = file <> ".tmp-" <> CreateUUID[],readback,differences},
  (* The binary companion preserves held signatures and order records while
     the text exposes the mathematical result. *)
  FeynFacet`FamilyArtifactWrite[result,temporary,"Compression"->True];
  If[!FileExistsQ[temporary],Print["Coefficient final write did not create ",temporary];Return[False]];
  readback=FeynFacet`FamilyArtifactRead[temporary];
  If[readback=!=result,
    differences=If[AssociationQ[readback],Select[Keys[result],result[#]=!=Lookup[readback,#,Missing["Key"]]&],{"UnreadableRecord"}];
    Export[temporary<>".expected.wxf",result,"WXF"];
    FeynFacet`FamilyArtifactWrite[<|"Status"->"ReadBackMismatch","DifferingTopLevelKeys"->differences,
      "ExpectedRecordFile"->temporary<>".expected.wxf","ActualRecordFile"->temporary|>,
      temporary<>".diagnostic.wl","Compression"->True];
    Print["Coefficient final read-back differs in ",differences,"; diagnostic ",temporary<>".diagnostic.wl"];
    Return[False]];
  FeynFacet`FamilyArtifactMove[temporary,file]===file
];

(* A final file must survive independently before its reconstruction
   workspace may be removed. Explicit files inside that workspace keep it. *)
coefficientRemoveWorkingFiles[kiraFile_String, resultFile_String] := Module[{work},
  work = coefficientWorkDirectory[kiraFile];
  If[! coefficientSafeWorkPathQ[work] || ! FileExistsQ[resultFile] ||
      coefficientSafeWorkPathQ[resultFile, work], Return[$Failed]];
  If[DirectoryQ[work], DeleteDirectory[work, DeleteContents -> True]];
  work
];

coefficientResetDirectory[path_String] := Module[{},
  If[! coefficientSafeWorkPathQ[path], Return[$Failed]];
  If[DirectoryQ[path], DeleteDirectory[path, DeleteContents -> True]];
  CreateDirectory[path, CreateIntermediateDirectories -> True];
  path
];

(* Follow the Results ancestor, retaining nested run names. Validation and
   production subdirectories must not create an unrelated root-level process. *)
$coefficientResultsFolderName = "Results";
coefficientResultLocation[kiraFile_String] := Module[{location},
 location=projectResultLocation[DirectoryName[ExpandFileName[kiraFile]],coefficientWorkspaceRoot[]];
 If[FailureQ[location],Return[location]];
 <|"Process"->FileNameJoin[location["OwnerParts"]],"Run"->location["RunParts"],"WorkDirectory"->location["WorkDirectory"]|>
];
coefficientWorkDirectory[kiraFile_String] := Module[{location=coefficientResultLocation[kiraFile]},
 If[FailureQ[location],Return[$Failed]];
 FileNameJoin[Join[{location["WorkDirectory"],"CoefficientSimplification"},location["Run"]]]
];

(* Hash file bytes in the native implementation when available. Wolfram's
   FileHash took about six seconds for the 84 MiB native executable; hashing
   hundreds of coefficient files must not dominate a reconstruction checkpoint. *)
coefficientFileHashes[files_List] := Module[{blocks, values, run, lines},
 If[files === {}, Return[{}]];
 If[!AllTrue[files, StringQ[#] && FileExistsQ[#] &], Return[$Failed]];
 blocks = Partition[files, UpTo[64]];
 values = Map[Function[block,
   run = If[$OperatingSystem === "Unix",
     Quiet[Check[RunProcess[Join[{"sha256sum", "--"}, block]], $Failed]], $Failed];
   lines = If[AssociationQ[run] && run["ExitCode"] === 0,
     StringSplit[StringTrim[run["StandardOutput"]], "\n"], {}];
   If[Length[lines] === Length[block] && AllTrue[lines,
       StringLength[#] >= 64 &&
       StringMatchQ[StringTake[#, 64], RegularExpression["[0-9a-f]{64}"]] &],
     StringTake[#, 64] & /@ lines,
     FileHash[#, "SHA256", "HexString"] & /@ block
   ]], blocks];
 Flatten[values]
];
coefficientFileHash[file_String] := Module[{hashes = coefficientFileHashes[{file}]},
 If[ListQ[hashes], First[hashes], $Failed]];

coefficientStoreManifestFile[directory_String] :=
  FileNameJoin[{directory, "Manifest.wl"}];

coefficientStoreMetadataFile[directory_String] :=
  FileNameJoin[{directory, "Metadata.bin"}];

coefficientStoreValidQ[directory_String, kiraFile_String] := Module[
  {manifest},
  If[
    ! DirectoryQ[directory] ||
      ! FileExistsQ[coefficientStoreManifestFile[directory]] ||
      ! FileExistsQ[coefficientStoreMetadataFile[directory]],
    Return[False]
  ];
  manifest = Quiet @ Check[FeynFacet`FamilyArtifactRead[coefficientStoreManifestFile[directory]], $Failed];
  AssociationQ[manifest] &&
    manifest["Format"] === $coefficientStoreFormat &&
    manifest["FormatVersion"] === $coefficientStoreVersion &&
    manifest["KiraFile"] === ExpandFileName[kiraFile] &&
    manifest["KiraFileBytes"] === FileByteCount[kiraFile] &&
    manifest["KiraFileHash"] === coefficientFileHash[kiraFile] &&
    IntegerQ[manifest["ShardCount"]] &&
    manifest["ShardCount"] > 0 &&
    AllTrue[
      Range[manifest["ShardCount"]],
      FileExistsQ[coefficientShardFile[directory, "Rules", #]] &
    ]
];

coefficientBuildKiraStore[kiraFile_String, directory_String] := Module[
  {
    kira, targetCount, shardCount, temporary, rules, ruleCount,
    chunkSize = 128, starts, chunk, groups, written = 0,
    metadata, manifest, result
  },
  If[! FileExistsQ[kiraFile], Return[$Failed]];
  Print["Loading the Kira artifact for one-time indexing"];
  kira = Quiet @ Check[FeynFacet`FamilyArtifactRead[kiraFile], $Failed];
  If[! coefficientKiraReductionQ[kira], Return[$Failed]];
  targetCount = Length[kira["Targets"]];
  shardCount = 2^Ceiling @ Log[
    2,
    Max[
      1,
      Min[targetCount, coefficientKernelLimit[targetCount]],
      Ceiling[targetCount/256]
    ]
  ];
  temporary = directory <> ".building-" <> StringTake[CreateUUID[], 8];
  If[coefficientResetDirectory[temporary] === $Failed, Return[$Failed]];
  Scan[
    coefficientWriteRecord[
      coefficientShardFile[temporary, "Rules", #],
      <||>
    ] &,
    Range[shardCount]
  ];
  rules = kira["KiraRules"];
  ruleCount = Length[rules];
  starts = Range[1, ruleCount, chunkSize];
  Scan[
    Function[start,
      chunk = Take[rules, {start, Min[ruleCount, start + chunkSize - 1]}];
      groups = GroupBy[
        chunk,
        coefficientShardIndex[First[#], shardCount] &
      ];
      KeyValueMap[
        Function[{shard, shardRules},
          If[
            coefficientAppendRecord[
              coefficientShardFile[temporary, "Rules", shard],
              Association[shardRules]
            ] === $Failed,
            Return[$Failed, Module]
          ]
        ],
        groups
      ];
      written += Length[chunk];
      If[Mod[written, 4096] < chunkSize || written === ruleCount,
        Print["Indexed ", written, " / ", ruleCount, " Kira rules"]
      ]
    ],
    starts
  ];
  metadata = KeyDrop[kira, "KiraRules"];
  If[
    coefficientWriteRecord[
      coefficientStoreMetadataFile[temporary],
      metadata
    ] === $Failed,
    Return[$Failed]
  ];
  manifest = <|
    "Format" -> $coefficientStoreFormat,
    "FormatVersion" -> $coefficientStoreVersion,
    "KiraFile" -> ExpandFileName[kiraFile],
    "KiraFileBytes" -> FileByteCount[kiraFile],
    "KiraFileHash" -> coefficientFileHash[kiraFile],
    "ReductionInputFingerprint" -> kira["ReductionInputFingerprint"],
    "TargetCount" -> targetCount,
    "RuleCount" -> ruleCount,
    "MasterCount" -> Length[kira["Masters"]],
    "ShardCount" -> shardCount
  |>;
  FeynFacet`FamilyArtifactWrite[manifest, coefficientStoreManifestFile[temporary]];
  Clear[kira, rules, metadata, chunk, groups];
  ClearSystemCache[];
  If[DirectoryQ[directory],
    If[! coefficientSafeWorkPathQ[directory], Return[$Failed]];
    DeleteDirectory[directory, DeleteContents -> True]
  ];
  RenameDirectory[temporary, directory];
  result = If[coefficientStoreValidQ[directory, kiraFile], directory, $Failed];
  result
];

coefficientEnsureKiraStore[kiraFile_String] := Module[{directory},
  directory = FileNameJoin[{coefficientWorkDirectory[kiraFile], "KiraStore"}];
  If[coefficientStoreValidQ[directory, kiraFile],
    directory,
    coefficientBuildKiraStore[kiraFile, directory]
  ]
];

coefficientInputFileFingerprint[sources_List] := Module[{digests=coefficientFileHashes[sources]},
 If[!ListQ[digests],Return[$Failed]];
 reductionFingerprint[{ExpandFileName/@sources,FromDigits[#,16]&/@digests}]
];

(* Diagram expressions are read once to obtain their shared definitions.
   A source summary can be reused only for the identical ordered file bytes. *)

coefficientInputCompanions[sources_List]:=If[!AllTrue[sources,StringQ],{},
 Map[Function[file,If[FileExistsQ[file<>".meta.wxf"],
   Quiet@Check[ByteArray[BinaryReadList[file<>".meta.wxf","Byte"]],$Failed],
   Missing["NoCompanion"]]],sources]];
coefficientCachedInputData[items_List,directory_String] := Module[
 {file=FileNameJoin[{directory,"SourceSummary.wl"}],fingerprint,saved},
 If[!AllTrue[items,StringQ]||!FileExistsQ[file],Return[$Failed]];
 fingerprint=coefficientInputFileFingerprint[items];
 If[fingerprint===$Failed,Return[$Failed]];
 saved=FeynFacet`FamilyArtifactRead[file];
 If[AssociationQ[saved]&&Lookup[saved,"Format",None]==="FeynFacet-CoefficientSourceSummary"&&
   Lookup[saved,"Version",None]===2&&Lookup[saved,"InputFileFingerprint",None]===fingerprint&&
    Lookup[saved,"InputCompanions",None]===coefficientInputCompanions[items]&&
   AssociationQ[Lookup[saved,"Data",None]]&&
   Lookup[saved["Data"],"Sources",None]===ExpandFileName/@items,saved["Data"],$Failed]
];
coefficientSaveInputSummary[data_Association,directory_String] := Module[{fingerprint},
 If[!AllTrue[data["Sources"],StringQ],Return[data]];
 fingerprint=coefficientInputFileFingerprint[data["Sources"]];
 If[!StringQ[fingerprint],Return[$Failed]];
 If[FeynFacet`FamilyArtifactWrite[<|"Format"->"FeynFacet-CoefficientSourceSummary",
   "Version"->2,"InputFileFingerprint"->fingerprint,
    "InputCompanions"->coefficientInputCompanions[data["Sources"]],"Data"->data|>,
   FileNameJoin[{directory,"SourceSummary.wl"}],"Compression"->True]=!=
     FileNameJoin[{directory,"SourceSummary.wl"}],Return[$Failed]];
 data
];
coefficientInputData[items_List,directory_String] := Module[{data},
 data=coefficientCachedInputData[items,directory];
 If[AssociationQ[data],Return[data]];
 data=Block[{analyticContextQ=coefficientAnalyticContextQ},ibpInputData[items,False]];
 If[AssociationQ[data],coefficientSaveInputSummary[data,directory],data]
];
(* A cold reconstruction reads each full pair exactly once: validation,
   shared-definition summaries and target coefficients come from that read.
   Only the small summaries and one coefficient batch are retained in memory. *)

coefficientInputMatchesReductionQ[data_,metadata_] := Module[{sortedPairs},
 If[!AssociationQ[data]||!AssociationQ[metadata]||
   !AllTrue[{data,metadata},ContainsAll[Keys[#],{"CardName","Pairs","AnalyticContext"}]&],
  Return[False]];
 sortedPairs[list_List]:=SortBy[list,{Lookup[#,"Forward"],Lookup[#,"Conjugate"]}&];
 data["CardName"]===metadata["CardName"]&&coefficientSameInputsQ[data,metadata]&&
  ListQ[data["Pairs"]]&&ListQ[metadata["Pairs"]]&&
  sortedPairs[data["Pairs"]]===sortedPairs[metadata["Pairs"]]
];
coefficientPromoteTargetRecords[temporary_String,directory_String] := Module[
 {backup=directory<>".previous-"<>CreateUUID[],hadPrevious=DirectoryQ[directory],moved},
 If[!coefficientSafeWorkPathQ[temporary]||!coefficientSafeWorkPathQ[directory]||
   !DirectoryQ[temporary],Return[$Failed]];
 If[hadPrevious&&Quiet[Check[RenameDirectory[directory,backup],$Failed]]===$Failed,Return[$Failed]];
 moved=Quiet[Check[RenameDirectory[temporary,directory],$Failed]];
 If[moved===$Failed,
  If[hadPrevious,Quiet[Check[RenameDirectory[backup,directory],Null]]];
  Return[$Failed]];
 If[hadPrevious,DeleteDirectory[backup,DeleteContents->True]];
 directory
];
coefficientPrepareInputRecords[items_List,metadata_Association,store_String,
    targetDirectory_String,shardCount_Integer] := Module[{data,collected,temporary},
 If[items==={}||!(AllTrue[items,StringQ]||AllTrue[items,AssociationQ]),
  Return[coefficientCollectFail["source inventory","expected nonempty files or records"]]];
 data=coefficientCachedInputData[items,store];
 If[AssociationQ[data],
  If[!coefficientInputMatchesReductionQ[data,metadata],
   Return[coefficientCollectFail["reduction compatibility","the sources describe another card or diagram set"]]];
  If[coefficientTargetStoreValidQ[data,metadata,targetDirectory,shardCount],Return[data]]];
 temporary=targetDirectory<>".building-"<>CreateUUID[];
 Internal`WithLocalSettings[Null,
  coefficientProgressStart["Collecting and validating diagram-pair coefficients",Length[items]];
  collected=Block[{analyticContextQ=coefficientAnalyticContextQ},
    coefficientCollectTargetRecords[
     If[AssociationQ[data],data,<|"Sources"->If[AllTrue[items,StringQ],ExpandFileName/@items,items]|>],
     metadata,temporary,shardCount,!AssociationQ[data]]];
  If[collected===$Failed,Return[$Failed]];
  If[!AssociationQ[data],data=collected];
  If[!coefficientInputMatchesReductionQ[data,metadata],
   Return[coefficientCollectFail["reduction compatibility","the sources describe another card or diagram set"]]];
  If[coefficientPromoteTargetRecords[temporary,targetDirectory]===$Failed,
   Return[coefficientCollectFail["target promotion",targetDirectory]]];
  coefficientSaveInputSummary[data,store],
  If[DirectoryQ[temporary]&&coefficientSafeWorkPathQ[temporary],DeleteDirectory[temporary,DeleteContents->True]]
 ]
];

coefficientTargetStoreValidQ[
    data_Association,
    metadata_Association,
    directory_String,
    shardCount_Integer
  ] := Module[{manifest, sources, inputFingerprint},
  sources = data["Sources"];
  If[
    ! DirectoryQ[directory] || ! AllTrue[sources, StringQ] ||
      ! FileExistsQ[FileNameJoin[{directory, "Manifest.wl"}]] ||
      ! FileExistsQ[FileNameJoin[{directory, "Remainder.bin"}]] ||
      ! AllTrue[
        Range[shardCount],
        FileExistsQ[coefficientShardFile[directory, "Targets", #]] &
      ],
    Return[False]
  ];
  manifest = Quiet @ Check[
    FeynFacet`FamilyArtifactRead[FileNameJoin[{directory, "Manifest.wl"}]],
    $Failed
  ];
  If[! AssociationQ[manifest], Return[False]];
  inputFingerprint = coefficientInputFileFingerprint[sources];
  manifest["SourceInputFingerprint"] === metadata["SourceInputFingerprint"] &&
    manifest["InputFileFingerprint"] === inputFingerprint &&
    Lookup[manifest,"InputCompanions",None]===coefficientInputCompanions[sources] &&
    manifest["PairCount"] === Length[sources] &&
    manifest["TargetCount"] === Length[metadata["Targets"]] &&
    Lookup[manifest,"Targets",None] === SortBy[metadata["Targets"],ToString[#,InputForm]&] &&
    Lookup[manifest,"TopologyEquivalence",None] === metadata["TopologyEquivalence"] &&
    manifest["ShardCount"] === shardCount
];

(* Every fail-closed exit of coefficientCollectTargetRecords names its check:
   a silent Return[$Failed] here cost a full diagnostic cycle on 2026-08-10. *)
coefficientCollectFail[check_String, detail_] := (
  Message[
    CoefficientSimplification::collect,
    check,
    If[StringQ[detail], detail, ToString[detail, InputForm]]
  ];
  $Failed
);

coefficientCollectSourceLabel[source_] := If[
  StringQ[source],
  source,
  "an in-memory pre-IBP result"
];

coefficientCollectTargetRecords[data_Association,metadata_Association,directory_String,
    shardCount_Integer,collectSummaries_:False]:=
 facetWithSymbolicWorkers[
  coefficientCollectTargetRecordsCore[data,metadata,directory,shardCount,collectSummaries],
  If[Length[data["Sources"]]>=32&&AllTrue[data["Sources"],StringQ],
   facetKernelCount[Automatic,Length[data["Sources"]]],1]
 ];
coefficientCollectTargetRecordsCore[
    data_Association,
    metadata_Association,
    directory_String,
    shardCount_Integer,
    collectSummaries_:False
  ] := Module[
  {
    sourceData=data,summaries={},
    equivalence, batches, rawTargets = {}, rawSeen = <||>,
    mappedSeen = <||>, batchTerms, batchRemainder, result,
    rawParts, sourceParts, sourceMomenta, offendingMomenta,
    groups, sourceFingerprint, targetSet, kiraTargetSet,
    remainderFile, completed = 0, inputFingerprint, manifest, loaded
  },
  If[coefficientResetDirectory[directory] === $Failed,
    Return[
      coefficientCollectFail[
        "target directory reset",
        "could not create the target record directory " <> directory
      ]
    ]
  ];
  If[MemberQ[Table[coefficientWriteRecord[
      coefficientShardFile[directory,"Targets",shard],<||>],{shard,shardCount}],$Failed],
    Return[coefficientCollectFail["target initialization",directory]]];
  remainderFile=FileNameJoin[{directory,"Remainder.bin"}];
  If[coefficientWriteRecord[remainderFile,0]===$Failed,
    Return[coefficientCollectFail["remainder initialization",remainderFile]]];
  equivalence = metadata["TopologyEquivalence"];
  batches = Partition[data["Sources"], UpTo[16]];
  Scan[
    Function[batch,
      batchTerms = <||>;
      batchRemainder = 0;
      loaded=If[AllTrue[batch,StringQ],facetSymbolicMap[FeynFacet`FamilyArtifactRead,batch],batch];
      If[!ListQ[loaded]||Length[loaded]=!=Length[batch],
        Return[coefficientCollectFail["source batch read",batch],Module]];
      Scan[
        Function[item,
          With[{source=First[item]},
          result = Last[item];
          If[! validPreIBPResultQ[result],
            Return[
              coefficientCollectFail[
                "pre-IBP source validation",
                "could not read a valid pre-IBP result from " <>
                  coefficientCollectSourceLabel[source]
              ],
              Module
            ]
          ];
          If[TrueQ[collectSummaries],
            AppendTo[summaries,ibpValidatedInputSummary[result,
              If[StringQ[source],ExpandFileName[source],Missing["InMemory"]],False]]];
          rawParts = linearIntegralSum[result["Integrand"]];
          If[FailureQ[rawParts],
            Return[
              coefficientCollectFail[
                "source integrand linearity",
                "the integrand of " <> coefficientCollectSourceLabel[source] <>
                  " is not a linear sum of explicit GLI objects"
              ],
              Module
            ]
          ];
          Scan[
            Function[target,
              If[! KeyExistsQ[rawSeen, target],
                AssociateTo[rawSeen, target -> True];
                AppendTo[rawTargets, target]
              ]
            ],
            Keys[rawParts["Terms"]]
          ];
          sourceParts = If[
            AssociationQ[equivalence] && KeyExistsQ[equivalence, "GLIRules"],
            linearMapIntegrals[rawParts, equivalence["GLIRules"]],
            rawParts
          ];
          If[FailureQ[sourceParts],
            Return[
              coefficientCollectFail[
                "canonical GLI mapping",
                "the verified topology rules did not map " <>
                  coefficientCollectSourceLabel[source] <>
                  " to a linear GLI sum"
              ],
              Module
            ]
          ];
          sourceMomenta = coefficientForbiddenMomenta[result["Setup"]];
          offendingMomenta = remainingDeclaredMomenta[
            {Values[sourceParts["Terms"]], sourceParts["Remainder"]},
            sourceMomenta
          ];
          If[offendingMomenta =!= {},
            Return[
              coefficientCollectFail[
                "integrated momenta in a source coefficient",
                coefficientCollectSourceLabel[source] <> " still contains " <>
                  ToString[offendingMomenta, InputForm]
              ],
              Module
            ]
          ];
          sourceParts = linearScale[sourceParts, result["PreFactor"]];
          KeyValueMap[
            Function[{integral, coefficient},
              AssociateTo[
                batchTerms,
                integral -> (Lookup[batchTerms, integral, 0] + coefficient)
              ];
              AssociateTo[mappedSeen, integral -> True]
            ],
            sourceParts["Terms"]
          ];
          batchRemainder += sourceParts["Remainder"]
          ]
        ],
        Transpose[{batch,loaded}]
      ];
      groups = GroupBy[
        Normal[batchTerms],
        coefficientShardIndex[First[#], shardCount] &
      ];
      KeyValueMap[
        Function[{shard, rules},
          If[
            coefficientAppendRecord[
              coefficientShardFile[directory, "Targets", shard],
              Association[rules]
            ] === $Failed,
            Return[
              coefficientCollectFail[
                "target shard write",
                "could not append a target record to " <>
                  coefficientShardFile[directory, "Targets", shard]
              ],
              Module
            ]
          ]
        ],
        groups
      ];
      If[batchRemainder=!=0&&coefficientAppendRecord[remainderFile,batchRemainder]===$Failed,
        Return[coefficientCollectFail["remainder write",remainderFile],Module]];
      completed += Length[batch];
      coefficientProgressUpdate[completed, Length[data["Sources"]]];
      If[$FrontEnd===Null&&(Mod[completed,64]===0||completed===Length[data["Sources"]]),
        Print["Collected ",completed," / ",Length[data["Sources"]]," coefficient input pairs"]];
      Clear[batchTerms, batchRemainder, result, rawParts, sourceParts, groups, loaded];
      ClearSystemCache[]
    ],
    batches
  ];
  If[TrueQ[collectSummaries],
    sourceData=ibpCombineInputSummaries[summaries,False]];
  If[!AssociationQ[sourceData],Return[$Failed]];
  sourceFingerprint = reductionFingerprint[
    sourceInputPayload[
      sourceData["Records"],
      rawTargets,
      sourceData["AnalyticContext"]
    ]
  ];
  If[sourceFingerprint =!= metadata["SourceInputFingerprint"],
    Return[
      coefficientCollectFail[
        "source input fingerprint",
        "the collected topology records and raw targets do not reproduce the " <>
          "fingerprint stored by the reduction (collected " <>
          ToString[sourceFingerprint] <> ", stored " <>
          ToString[metadata["SourceInputFingerprint"]] <> ")"
      ]
    ]
  ];
  targetSet = Keys[mappedSeen];
  kiraTargetSet = metadata["Targets"];
  If[
    Length[targetSet] =!= Length[kiraTargetSet] ||
      ! ContainsAll[targetSet, kiraTargetSet] ||
      ! ContainsAll[kiraTargetSet, targetSet],
    Return[
      coefficientCollectFail[
        "target set equality",
        "the collected targets differ from the targets reduced by Kira (" <>
          ToString[Length[targetSet]] <> " collected, " <>
          ToString[Length[kiraTargetSet]] <> " reduced, " <>
          ToString[Length[Complement[targetSet, kiraTargetSet, SameTest -> SameQ]]] <>
          " collected-only, " <>
          ToString[Length[Complement[kiraTargetSet, targetSet, SameTest -> SameQ]]] <>
          " reduced-only)"
      ]
    ]
  ];
  inputFingerprint = coefficientInputFileFingerprint[data["Sources"]];
  manifest = <|
    "SourceInputFingerprint" -> sourceFingerprint,
    "InputFileFingerprint" -> inputFingerprint,
    "InputCompanions" -> coefficientInputCompanions[data["Sources"]],
    "PairCount" -> Length[data["Sources"]],
    "TargetCount" -> Length[targetSet],
    "Targets" -> SortBy[targetSet,ToString[#,InputForm]&],
    "TopologyEquivalence" -> equivalence,
    "ShardCount" -> shardCount
  |>;
  If[FeynFacet`FamilyArtifactWrite[manifest,FileNameJoin[{directory,"Manifest.wl"}]] =!=
     FileNameJoin[{directory,"Manifest.wl"}],
    Return[coefficientCollectFail["target manifest write",directory]]];
  If[TrueQ[collectSummaries],sourceData,manifest]
];

coefficientKernelLimit[count_Integer] := Min[
  count,
  If[
    ValueQ[Global`$FACETKernelLimit] &&
      IntegerQ[Global`$FACETKernelLimit] && Global`$FACETKernelLimit > 0,
    Global`$FACETKernelLimit,
    $ProcessorCount
  ]
];

coefficientBalancedRecordTotal[file_String] := Module[
  {levels = <||>, count, add},
  add[value_] := Module[{level = 0, current = value},
    While[KeyExistsQ[levels, level],
      current = levels[level] + current;
      KeyDropFrom[levels, level];
      level++
    ];
    AssociateTo[levels, level -> current]
  ];
  count = coefficientScanRecords[file, (add[#]; True) &];
  If[count === $Failed, $Failed, Total[Values[levels]]]
];

coefficientSimplificationOptions[rules_List] :=
 Join[Association@Options[CoefficientSimplification],Association@Flatten[rules]];

CoefficientSimplification[
    inputs : ({__Association} | {__String}),
    kiraFile_String,
    opts:OptionsPattern[]
  ] := finiteFieldCoefficientSimplificationCore[
  inputs,
  ExpandFileName[kiraFile],
  coefficientSimplificationOptions[{opts}]
];

coefficientPairFileKey[file_String] := Module[{parts},
  parts = StringSplit[StringDrop[FileBaseName[file], 1], "_C"];
  If[
    Length[parts] === 2 && AllTrue[parts, StringMatchQ[DigitCharacter ..]],
    ToExpression /@ parts,
    {Infinity, Infinity}
  ]
];

coefficientResolveResultDirectory[
    projectDirectory_String,
    cardName_String,
    resultFolder_
  ] := Module[{project, card, candidate},
  project = ExpandFileName[projectDirectory];
  card = FeynFacet`ReadContributionCard[project,cardName];
  If[!AssociationQ[card],Return[$Failed]];
  candidate = Which[
    resultFolder === Automatic,
      FileNameJoin[{card["WorkDirectory"],"Reduction"}],
    StringQ[resultFolder] && DirectoryQ[resultFolder],
      ExpandFileName[resultFolder],
    StringQ[resultFolder],
      ExpandFileName[FileNameJoin[{project,resultFolder}]],
    True, $Failed
  ];
  If[
    ! StringQ[candidate] || ! DirectoryQ[candidate] ||
      ! FileExistsQ[FileNameJoin[{candidate, "KiraResult.wl"}]] ||
      ! DirectoryQ[FileNameJoin[{candidate, "Pairs"}]],
    $Failed,
    candidate
  ]
];

(* Computational dependencies belong to the contribution card; they do not
   alter diagram identities or the physical amplitude setup. *)
coefficientProjectReconstructionInputs[directory_String,name_String] := Module[{card,request,paths},
 card=FeynFacet`ReadContributionCard[directory,name];
 If[!AssociationQ[card],Return[card]];
 request=Lookup[card,"CoefficientReconstruction",None];
 If[request===None,Return[None]];
 If[!AssociationQ[request],Return[Failure["CoefficientReconstructionCardRequired",<||>]]];
 paths={"EndpointCatalog","PhysicalNormalization","PlanDirectory"};
 request=Association@KeyValueMap[Function[{key,value},
   key->If[MemberQ[paths,key]&&StringQ[value],
     projectAbsolutePath[If[StringStartsQ[value,"/"],value,FileNameJoin[{directory,value}]]],value]],request];
 If[!KeyExistsQ[request,"ThroughOrder"],request=Append[request,"ThroughOrder"->Last[card["EpsilonRange"]]]];
 request
];

coefficientRunProject[
    projectDirectory_String,
    cardName_String,
    resultFolder_,
    options_Association
  ] := Module[
  {
    project, cardFile, card, resultDirectory, pairDirectory,
    pairFiles, kiraFile, result, resultFile, orderInputs
  },
  coefficientProgressStart["Locating coefficient inputs", 1];
  project = ExpandFileName[projectDirectory];
  card = ReadProcessCard[project,cardName];
  resultDirectory = coefficientResolveResultDirectory[
    project,
    cardName,
    resultFolder
  ];
  If[! AssociationQ[card] || resultDirectory === $Failed,
    coefficientProgressFailure[
      "input discovery",
      "the card or result folder is missing"
    ];
    Message[
      CoefficientSimplification::project,
      projectDirectory,
      cardName,
      "the card or result folder is missing"
    ];
    Return[$Failed]
  ];
  pairDirectory = FileNameJoin[{resultDirectory, "Pairs"}];
  pairFiles = SortBy[
    FileNames["F*_C*.wl", pairDirectory],
    coefficientPairFileKey
  ];
  kiraFile = FileNameJoin[{resultDirectory, "KiraResult.wl"}];
  If[pairFiles === {} || ! FileExistsQ[kiraFile],
    coefficientProgressFailure[
      "input discovery",
      "the pair files or KiraResult.wl are missing"
    ];
    Message[
      CoefficientSimplification::project,
      projectDirectory,
      cardName,
      "the pair files or KiraResult.wl are missing"
    ];
    Return[$Failed]
  ];
  orderInputs=Lookup[options,"ReconstructionOrderInputs",Automatic];
  If[orderInputs===Automatic,orderInputs=coefficientProjectReconstructionInputs[project,cardName]];
  If[FailureQ[orderInputs],Return[orderInputs]];
  result = finiteFieldCoefficientSimplificationCore[
    pairFiles,
    kiraFile,
    Join[options, <|"CoefficientSetup" -> card,"ReconstructionOrderInputs"->orderInputs|>]
  ];
  If[result === $Failed, Return[$Failed]];
  coefficientProgressStage["Writing CoefficientResult.wl"];
  resultFile = FileNameJoin[{resultDirectory, "CoefficientResult.wl"}];
  result = Append[result, "CoefficientResultFile" -> resultFile];
  If[!TrueQ[coefficientWriteFinalResult[result,resultFile]],
    coefficientProgressFailure["result writing",resultFile];
    Message[CoefficientSimplification::project,projectDirectory,cardName,
      "CoefficientResult.wl could not be written and read back exactly"];
    Return[$Failed]];
  If[! TrueQ[options["KeepWorkingFiles"]] &&
      TrueQ[result["FiniteFieldReconstruction"]["CompleteTargetSet"]],
    coefficientRemoveWorkingFiles[kiraFile, resultFile]];
  coefficientProgressFinish[];
  Print @ Grid[
    {
      {"Card", cardName},
      {"Result folder", FileNameTake[resultDirectory]},
      {"Pair files", Length[pairFiles]},
      {"Coefficient file", resultFile},
      {"File size (MB)", Round[FileByteCount[resultFile]/2.^20, 0.01]}
    },
    Frame -> All
  ];
  result
];

CoefficientSimplification[
    projectDirectory_String,
    cardName_String,
    opts:OptionsPattern[]
  ] := coefficientRunProject[
  projectDirectory,
  cardName,
  Automatic,
  coefficientSimplificationOptions[{opts}]
];

CoefficientSimplification[
    projectDirectory_String,
    cardName_String,
    resultFolder : (Automatic | _String),
    opts:OptionsPattern[]
  ] := coefficientRunProject[
  projectDirectory,
  cardName,
  resultFolder,
  coefficientSimplificationOptions[{opts}]
];
