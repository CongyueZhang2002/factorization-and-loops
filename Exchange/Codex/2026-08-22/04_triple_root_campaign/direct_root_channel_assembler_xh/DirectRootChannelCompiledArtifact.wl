BeginPackage["CodexDirectRootChannelCompiledArtifact`", {
  "CodexDirectRootChannelAssembler`"}];

DRCACreateCompiledArtifact::usage =
  "DRCACreateCompiledArtifact[assembly,provenance] creates a source-bound immutable compiled direct-channel cache artifact.";
DRCACompiledArtifactValidQ::usage =
  "DRCACompiledArtifactValidQ[artifact] fully validates the artifact schema, source bindings, cache key, fingerprints and contained direct assembly.";
DRCAWriteCompiledArtifact::usage =
  "DRCAWriteCompiledArtifact[artifact,file] atomically writes a new artifact and validates an exact readback.";
DRCAReadCompiledArtifact::usage =
  "DRCAReadCompiledArtifact[file] reads and fully validates one compiled direct-channel cache artifact.";

Begin["`Private`"];

ClearAll[drcacFingerprint, drcacCacheKeyPayload, drcacArtifactPayload,
  drcacSourceStableQ, drcacDeleteIfPresent];

$drcacSourceFile = ExpandFileName[$InputFileName];
$drcacSourceSHA256 =
  FileHash[$drcacSourceFile, "SHA256", "HexString"];
$drcacFormatVersion = 1;

drcacFingerprint[value_] := Hash[
  ToString[InputForm[value]], "SHA256", "HexString"];

drcacCacheKeyPayload[assembly_Association, provenance_Association] := <|
  "FormatVersion" -> $drcacFormatVersion,
  "SourcePreparationABIFingerprint" ->
    assembly["SourceABIFingerprint"],
  "RootOrderingFingerprint" -> assembly["RootOrderingFingerprint"],
  "PreparationSHA256" -> Lookup[provenance,
    "PreparationSHA256", $Failed],
  "PrototypeSourceSHA256" -> assembly["PrototypeSourceSHA256"],
  "RuntimeSourceHashes" -> Lookup[provenance,
    "RuntimeSourceHashes", $Failed]|>;

drcacArtifactPayload[artifact_Association] := KeyTake[artifact, {
  "Status", "FormatVersion", "CacheKey", "CacheKeyPayload",
  "ArtifactHelperSourceFile", "ArtifactHelperSourceSHA256",
  "SourcePreparationABIFingerprint", "RootOrderingFingerprint",
  "DirectAssemblyFingerprint", "ExactChannelFormsFingerprint",
  "CompiledFormsFingerprint", "CompiledFormsShapeFingerprint",
  "PrototypeSourceFile", "PrototypeSourceSHA256",
  "BuilderProvenance"}];

drcacSourceStableQ[] := TrueQ[
  FileHash[$drcacSourceFile, "SHA256", "HexString"] ===
    $drcacSourceSHA256];

DRCACreateCompiledArtifact[assembly_Association,
    provenance_Association] := Module[
  {cacheKeyPayload, artifact},
  If[! drcacSourceStableQ[] ||
      ! CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
        assembly] ||
      ! StringQ[Lookup[provenance, "PreparationSHA256", None]] ||
      ! AssociationQ[Lookup[provenance, "RuntimeSourceHashes", None]],
    Return[$Failed]];
  cacheKeyPayload = drcacCacheKeyPayload[assembly, provenance];
  artifact = <|
    "Status" -> "DirectRootChannelCompiledArtifactV1",
    "FormatVersion" -> $drcacFormatVersion,
    "CacheKey" -> drcacFingerprint[cacheKeyPayload],
    "CacheKeyPayload" -> cacheKeyPayload,
    "ArtifactHelperSourceFile" -> $drcacSourceFile,
    "ArtifactHelperSourceSHA256" -> $drcacSourceSHA256,
    "SourcePreparationABIFingerprint" ->
      assembly["SourceABIFingerprint"],
    "RootOrderingFingerprint" -> assembly["RootOrderingFingerprint"],
    "DirectAssemblyFingerprint" -> assembly["AssemblyFingerprint"],
    "ExactChannelFormsFingerprint" ->
      assembly["ExactChannelFormsFingerprint"],
    "CompiledFormsFingerprint" ->
      assembly["CompiledFormsFingerprint"],
    "CompiledFormsShapeFingerprint" ->
      assembly["CompiledFormsShapeFingerprint"],
    "PrototypeSourceFile" -> assembly["PrototypeSourceFile"],
    "PrototypeSourceSHA256" -> assembly["PrototypeSourceSHA256"],
    "BuilderProvenance" -> provenance,
    "DirectAssembly" -> assembly|>;
  Append[artifact, "ArtifactFingerprint" ->
    drcacFingerprint[drcacArtifactPayload[artifact]]]
];

DRCACompiledArtifactValidQ[artifact_Association] := Module[
  {requiredKeys, assembly, cacheKeyPayload},
  requiredKeys = {"Status", "FormatVersion", "CacheKey",
    "CacheKeyPayload", "ArtifactHelperSourceFile",
    "ArtifactHelperSourceSHA256", "SourcePreparationABIFingerprint",
    "RootOrderingFingerprint", "DirectAssemblyFingerprint",
    "ExactChannelFormsFingerprint", "CompiledFormsFingerprint",
    "CompiledFormsShapeFingerprint", "PrototypeSourceFile",
    "PrototypeSourceSHA256", "BuilderProvenance",
    "DirectAssembly", "ArtifactFingerprint"};
  If[Sort[Keys[artifact]] =!= Sort[requiredKeys] ||
      artifact["Status"] =!= "DirectRootChannelCompiledArtifactV1" ||
      artifact["FormatVersion"] =!= $drcacFormatVersion ||
      ! drcacSourceStableQ[] ||
      artifact["ArtifactHelperSourceFile"] =!= $drcacSourceFile ||
      artifact["ArtifactHelperSourceSHA256"] =!= $drcacSourceSHA256 ||
      ! AssociationQ[artifact["BuilderProvenance"]] ||
      ! AssociationQ[artifact["DirectAssembly"]],
    Return[False]];
  assembly = artifact["DirectAssembly"];
  cacheKeyPayload =
    drcacCacheKeyPayload[assembly, artifact["BuilderProvenance"]];
  TrueQ[
    CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
      assembly] &&
    artifact["CacheKeyPayload"] === cacheKeyPayload &&
    artifact["CacheKey"] === drcacFingerprint[cacheKeyPayload] &&
    artifact["SourcePreparationABIFingerprint"] ===
      assembly["SourceABIFingerprint"] &&
    artifact["RootOrderingFingerprint"] ===
      assembly["RootOrderingFingerprint"] &&
    artifact["DirectAssemblyFingerprint"] ===
      assembly["AssemblyFingerprint"] &&
    artifact["ExactChannelFormsFingerprint"] ===
      assembly["ExactChannelFormsFingerprint"] &&
    artifact["CompiledFormsFingerprint"] ===
      assembly["CompiledFormsFingerprint"] &&
    artifact["CompiledFormsShapeFingerprint"] ===
      assembly["CompiledFormsShapeFingerprint"] &&
    artifact["PrototypeSourceFile"] ===
      assembly["PrototypeSourceFile"] &&
    artifact["PrototypeSourceSHA256"] ===
      assembly["PrototypeSourceSHA256"] &&
    artifact["ArtifactFingerprint"] ===
      drcacFingerprint[drcacArtifactPayload[artifact]]]
];

DRCACompiledArtifactValidQ[___] := False;

drcacDeleteIfPresent[file_String] := Module[{},
  If[FileExistsQ[file], Quiet[Check[DeleteFile[file], $Failed]]];
  ! FileExistsQ[file]
];

DRCAWriteCompiledArtifact[artifact_Association, file_String] := Module[
  {target = ExpandFileName[file], temporary, written, renamed, reread},
  If[FileExistsQ[target] || ! DirectoryQ[DirectoryName[target]] ||
      ! DRCACompiledArtifactValidQ[artifact], Return[$Failed]];
  temporary = target <> ".tmp-" <>
    StringReplace[CreateUUID[], "-" -> ""];
  written = Quiet[Check[Put[artifact, temporary], $Failed]];
  If[written === $Failed || ! FileExistsQ[temporary],
    drcacDeleteIfPresent[temporary]; Return[$Failed]];
  renamed = Quiet[Check[RenameFile[temporary, target,
    OverwriteTarget -> False], $Failed]];
  If[renamed === $Failed || ! FileExistsQ[target] ||
      FileExistsQ[temporary],
    drcacDeleteIfPresent[temporary]; Return[$Failed]];
  reread = DRCAReadCompiledArtifact[target];
  If[! SameQ[reread, artifact],
    If[! drcacDeleteIfPresent[target], Return[$Failed]];
    Return[$Failed]];
  target
];

DRCAWriteCompiledArtifact[___] := $Failed;

DRCAReadCompiledArtifact[file_String] := Module[{target, artifact},
  target = ExpandFileName[file];
  If[! FileExistsQ[target], Return[$Failed]];
  artifact = Block[{$ContextPath = {"System`", "Global`"},
      $Context = "Global`"},
    Quiet[Check[Get[target], $Failed]]];
  If[AssociationQ[artifact] && DRCACompiledArtifactValidQ[artifact],
    artifact, $Failed]
];

DRCAReadCompiledArtifact[___] := $Failed;

End[];
EndPackage[];

