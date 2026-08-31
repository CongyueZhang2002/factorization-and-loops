(* Scratch-only adapter for an exact path-reconstructed off-diagonal block.
   Loading this file performs no I/O and changes neither FeynFacet nor a
   checkpoint.  It deliberately does not build the rest of the connection. *)

BeginPackage["CodexDiagnostics`ExactPathTransportException`"];

ExactPathTransportExceptionRecordQ::usage =
  "ExactPathTransportExceptionRecordQ[record] checks the typed fixed-path record without loading its artifact.";

LoadExactPathTransportExceptionArtifact::usage =
  "LoadExactPathTransportExceptionArtifact[record] loads the referenced exact path artifact and checks its declared identity and dimensions.";

ExactPathTransportExceptionReparameterize::usage =
  "ExactPathTransportExceptionReparameterize[record,tau,eps,{p0,p1}] returns (p1-p0) Bp[p0+tau(p1-p0),eps].";

InstallExactPathTransportExceptionIntoAhat::usage =
  "InstallExactPathTransportExceptionIntoAhat[assembly,ahat,record,tau,eps,{p0,p1}] replaces exactly the recorded path subblock.  The caller must already have assembled every other block on the same path.";

Begin["`Private`"];

ClearAll[
  ExactPathTransportExceptionRecordQ,
  LoadExactPathTransportExceptionArtifact,
  ExactPathTransportExceptionReparameterize,
  InstallExactPathTransportExceptionIntoAhat,
  exactPathLocateBlock, exactPathExtensionRecordQ,
  exactPathArtifactExtensionQ
];

exactPathExtensionRecordQ[extension_] := AssociationQ[extension] && Switch[
  Lookup[extension, "Type", None],
  "None", True,
  "Quadratic",
    StringQ[Lookup[extension, "ArtifactRootField", None]] &&
      StringQ[Lookup[extension, "ArtifactRootSquareField", None]] &&
      Lookup[extension, "Representation", None] === "ExplicitSqrt" &&
      StringQ[Lookup[extension, "BranchConvention", None]],
  _, False
];
exactPathExtensionRecordQ[___] := False;

exactPathArtifactExtensionQ[artifact_Association,
    extension_Association] := Switch[Lookup[extension, "Type", None],
  "None", True,
  "Quadratic",
    MatchQ[Lookup[artifact, extension["ArtifactRootField"], None], _Symbol] &&
      ! MissingQ[Lookup[artifact,
        extension["ArtifactRootSquareField"], Missing["NoRootSquare"]]],
  _, False
];
exactPathArtifactExtensionQ[___] := False;

ExactPathTransportExceptionRecordQ[record_] :=
  AssociationQ[record] &&
    Lookup[record, "Status", None] ===
      "ExactPathTransportExceptionReadyV1" &&
    MemberQ[{"ExactRationalPathTransportException",
        "ExactQuadraticPathTransportException"},
      Lookup[record, "Method", None]] &&
    Lookup[record, "Gauge", None] === "LiteralZero" &&
    Lookup[record, "Installed", True] === False &&
    Lookup[record, "ExactDLog", True] === False &&
    StringQ[Lookup[record, "ArtifactFile", None]] &&
    MatchQ[Lookup[record, "RowRange", None], {__Integer?Positive}] &&
    MatchQ[Lookup[record, "ColumnRange", None], {__Integer?Positive}] &&
    MatchQ[Lookup[record, "RowBlockBasis", None], {__Integer?Positive}] &&
    MatchQ[Lookup[record, "ColumnBlockBasis", None],
      {__Integer?Positive}] &&
    Lookup[record, "PathDimensions", None] ===
      {Length[record["RowRange"]], Length[record["ColumnRange"]]} &&
    AssociationQ[Lookup[record, "Path", None]] &&
    StringQ[Lookup[record["Path"], "Chart", None]] &&
    AssociationQ[Lookup[record["Path"], "FrozenCoordinate", None]] &&
    AssociationQ[Lookup[record["Path"], "ArtifactIdentity", None]] &&
    ListQ[Lookup[record["Path"], "BranchRoots", None]] &&
    exactPathExtensionRecordQ[Lookup[record, "PathExtension",
      <|"Type" -> "None"|>]];
ExactPathTransportExceptionRecordQ[___] := False;

LoadExactPathTransportExceptionArtifact[record_] := Module[
  {artifact, artifactIdentity, extension},
  If[! ExactPathTransportExceptionRecordQ[record],
    Return[<|"Status" -> "InvalidExactPathTransportExceptionRecord"|>]];
  If[! FileExistsQ[record["ArtifactFile"]],
    Return[<|"Status" -> "ExactPathArtifactMissing",
      "File" -> record["ArtifactFile"]|>]];
  artifact = Quiet[Check[Get[record["ArtifactFile"]], $Failed]];
  If[! AssociationQ[artifact],
    Return[<|"Status" -> "ExactPathArtifactUnreadable",
      "File" -> record["ArtifactFile"]|>]];
  artifactIdentity = record["Path"]["ArtifactIdentity"];
  extension = Lookup[record, "PathExtension", <|"Type" -> "None"|>];
  If[Lookup[artifact, "Status", None] =!= record["ArtifactStatus"] ||
      Lookup[artifact, "Family", None] =!= record["Family"] ||
      Lookup[artifact, "HardSector", None] =!= record["HardSector"] ||
      Lookup[artifact, "LowerSector", None] =!= record["LowerSector"] ||
      ! AllTrue[Normal[artifactIdentity],
        Lookup[artifact, First[#], Missing["NoArtifactIdentityField"]] ===
          Last[#] &] ||
      Dimensions[Lookup[artifact, "PathForcing", None]] =!=
        record["PathDimensions"] ||
      ! exactPathArtifactExtensionQ[artifact, extension],
    Return[<|"Status" -> "ExactPathArtifactContractMismatch"|>]];
  artifact
];
LoadExactPathTransportExceptionArtifact[___] :=
  <|"Status" -> "InvalidExactPathTransportExceptionRecord"|>;

ExactPathTransportExceptionReparameterize[record_, tau_Symbol, eps_,
    endpoints : {_, _}] := Module[
  {artifact, p, artifactEps, p0, p1, forcing, rules, extension,
   extensionRules, extensionResult, root, rootSquare},
  artifact = LoadExactPathTransportExceptionArtifact[record];
  If[Lookup[artifact, "Status", None] =!= record["ArtifactStatus"],
    Return[artifact]];
  p = artifact["PathVariable"];
  artifactEps = artifact["Regulator"];
  {p0, p1} = endpoints;
  forcing = artifact["PathForcing"];
  rules = {p -> p0 + tau (p1 - p0), artifactEps -> eps};
  extension = Lookup[record, "PathExtension", <|"Type" -> "None"|>];
  {extensionRules, extensionResult} = Switch[extension["Type"],
    "None", {{}, <|"Type" -> "None"|>},
    "Quadratic",
      root = artifact[extension["ArtifactRootField"]];
      rootSquare = artifact[extension["ArtifactRootSquareField"]] /. rules;
      {{root -> Sqrt[rootSquare]},
       <|"Type" -> "Quadratic", "Root" -> Sqrt[rootSquare],
         "RootSquare" -> rootSquare,
         "BranchConvention" -> extension["BranchConvention"]|>}
  ];
  <|
    "Status" -> "ExactPathTransportExceptionReparameterizedV1",
    "PathBlock" ->
      Map[(p1 - p0) (# /. rules /. extensionRules) &, forcing, {2}],
    "PathRule" -> p -> p0 + tau (p1 - p0),
    "Endpoints" -> endpoints,
    "FrozenCoordinate" -> record["Path"]["FrozenCoordinate"],
    "BranchRoots" -> record["Path"]["BranchRoots"],
    "PathExtension" -> extensionResult
  |>
];
ExactPathTransportExceptionReparameterize[___] :=
  <|"Status" -> "InvalidExactPathReparameterizationInput"|>;

exactPathLocateBlock[assembly_Association, range_List, basis_List] := Module[
  {ranges, blocks, byRange, byBasis},
  ranges = Lookup[assembly, "Ranges", {}];
  blocks = Lookup[assembly, "Blocks", {}];
  byRange = FirstPosition[ranges, range, Missing["RangeNotFound"]];
  byBasis = FirstPosition[blocks, basis, Missing["BasisNotFound"]];
  If[MissingQ[byRange] || MissingQ[byBasis] || byRange =!= byBasis,
    Missing["AssemblyBlockIdentityMismatch"], First[byRange]]
];

InstallExactPathTransportExceptionIntoAhat[assembly_Association, ahat_List,
    record_, tau_Symbol, eps_, endpoints : {_, _}] := Module[
  {rowBlock, columnBlock, ranges, rowRange, columnRange, path,
   installed},
  If[! ExactPathTransportExceptionRecordQ[record],
    Return[<|"Status" -> "InvalidExactPathTransportExceptionRecord"|>]];
  ranges = Lookup[assembly, "Ranges", {}];
  rowRange = record["RowRange"];
  columnRange = record["ColumnRange"];
  rowBlock = exactPathLocateBlock[assembly, rowRange,
    record["RowBlockBasis"]];
  columnBlock = exactPathLocateBlock[assembly, columnRange,
    record["ColumnBlockBasis"]];
  If[MissingQ[rowBlock] || MissingQ[columnBlock],
    Return[<|"Status" -> "ExactPathAssemblyBlockIdentityMismatch",
      "RowBlock" -> rowBlock, "ColumnBlock" -> columnBlock|>]];
  If[Dimensions[ahat] =!= {Total[Length /@ ranges],
      Total[Length /@ ranges]},
    Return[<|"Status" -> "ExactPathConnectionDimensionMismatch"|>]];
  path = ExactPathTransportExceptionReparameterize[
    record, tau, eps, endpoints];
  If[Lookup[path, "Status", None] =!=
      "ExactPathTransportExceptionReparameterizedV1",
    Return[path]];
  installed = ahat;
  installed[[ranges[[rowBlock]], ranges[[columnBlock]]]] =
    path["PathBlock"];
  <|
    "Status" -> "ExactPathTransportExceptionInstalledV1",
    "Ahat" -> installed,
    "InstalledBlockPositions" -> {rowBlock, columnBlock},
    "InstalledRanges" -> {rowRange, columnRange},
    "Path" -> KeyDrop[path, "PathBlock"],
    "NextStage" ->
      "masterTransportDepthBudget followed by masterTransportBlockwiseSolve",
    "ClaimBoundary" -> record["ClaimBoundary"]
  |>
];
InstallExactPathTransportExceptionIntoAhat[___] :=
  <|"Status" -> "InvalidExactPathInstallationInput"|>;

End[];
EndPackage[];
