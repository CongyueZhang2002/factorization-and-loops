#!/usr/bin/env wolframscript
(* Legacy ABI records of the multiquadratic strip solver (U3, 2026-09-02;
   Codex review 2026-09-02: "test one real pre-overhaul checkpoint").

   Until 2026-09-02 every stored multiquadratic record carried
   "SourceSHA256" -> <SHA-256 of MultiquadraticOffDiagonalBlockSolve.wl at write
   time> as its implementation identity.  U3 replaced the key by the
   hand-maintained "ABIVersion" -> "MultiquadraticOffDiagonalBlockSolve-ABI-1" and
   ruled that pre-U3 records are the legacy lineage of ABI-1.  The
   validators, however, required the new key (a legacy record failed the
   KeyExistsQ list and the header seal), so the ruling was prose only.
   This test constructs legacy records EXACTLY as the pre-U3 writer did
   (commit 96be12e9: the same header keys in the same order with
   "SourceSHA256" where "ABIVersion" now stands, the seal over that
   header, the assembly fingerprint over that semantic payload) and
   drives them through every validator that gates a STORED record.  No
   real pre-U3 record of these schemas exists on disk (searched
   2026-09-02); the real legacy file used in D carries the key under a
   different schema and must stay refused as a multiquadratic record.

   Acceptance criteria, stated before the run:
     A  a prepare checkpoint in the current format is accepted with
        "ABILineage" -> "ABIVersion"; the same payload sealed the pre-U3
        way is accepted with "ABILineage" -> "LegacySourceSHA256" and
        yields the same payload, directly and after a write/read through
        the artifact layer prepare uses; a malformed legacy hash, a
        record carrying neither key, a mutated payload and a tampered
        seal are each refused with their own typed status, while a
        checkpoint sealed under another ABI version is still admitted
        (resume admission is blind to the implementation version,
        t_multiquadratic_persistence P5: the version is provenance);
     B  a letter dlog certificate (the V1 schema and the channel schema)
        validates in the current format and in the legacy format, and a
        legacy certificate with a changed content hash, a malformed
        hash, or checked against another letter does not;
     C  a compiled assembly of a real rank-2 strip validates and hydrates
        through multiquadraticOffDiagonalBlockReadPreparedArtifact in the current
        format (lineage "ABIVersion") and in the legacy format (lineage
        "LegacySourceSHA256"); a tampered content fingerprint, a
        malformed legacy hash, a foreign ABI version (resealed, so only
        the version differs) and a record with neither key are refused,
        the last one typed by the reader;
     D  the real on-disk fixture cf300_frozen_stripsolvers.wl (2026-08-25,
        carrying "SourceSHA256") loads through the raw artifact reader,
        its hash is a well-formed legacy hash, and the prepared-artifact
        reader refuses it typed (ArtifactSchemaUnknown): the alias admits
        the legacy KEY of a multiquadratic record, not every record that
        carries the key. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];

mq[name_String] := Symbol["FeynFacet`Private`" <> name];
{fingerprint, checkpointRecord, checkpointAccept, artifactWrite,
  artifactLoadRaw, readPrepared, compiledValidQ, semanticPayload,
  letterCertificate, letterCertificateValidQ, constructedEvidence,
  channelTextKey, expressionTextKey, lineage, legacyHashQ, prepare,
  compile, rootOrder, clearCaches} =
 mq /@ {"multiquadraticOffDiagonalBlockFingerprint",
   "multiquadraticOffDiagonalBlockPrepareCheckpointRecord",
   "multiquadraticOffDiagonalBlockPrepareCheckpointAccept",
   "multiquadraticOffDiagonalBlockArtifactWrite", "multiquadraticOffDiagonalBlockArtifactLoadRaw",
   "multiquadraticOffDiagonalBlockReadPreparedArtifact",
   "multiquadraticOffDiagonalBlockCompiledValidQ",
   "multiquadraticOffDiagonalBlockSemanticPayload",
   "multiquadraticOffDiagonalBlockLetterDLogCertificate",
   "multiquadraticOffDiagonalBlockLetterDLogCertificateValidQ",
   "multiquadraticOffDiagonalBlockConstructedDLogEvidence",
   "multiquadraticOffDiagonalBlockChannelTextKey",
   "multiquadraticOffDiagonalBlockExpressionTextKey",
   "multiquadraticOffDiagonalBlockABILineage",
   "multiquadraticOffDiagonalBlockLegacySourceSHA256Q",
   "multiquadraticOffDiagonalBlockPrepare", "multiquadraticOffDiagonalBlockCompile",
   "multiquadraticOffDiagonalBlockRootOrder", "multiquadraticOffDiagonalBlockClearCaches"};
abiVersion = mq["$multiquadraticOffDiagonalBlockABIVersion"];
artifactContext = "FeynFacet`MultiquadraticArtifact`";

scratch = FileNameJoin[{$TemporaryDirectory,
  "feynfacet-legacy-abi-" <> CreateUUID[]}];
CreateDirectory[scratch, CreateIntermediateDirectories -> True];

(* the hash a pre-U3 writer stored: 64 hex digits of the source file *)
legacyHash = Hash["MultiquadraticOffDiagonalBlockSolve.wl before U3", "SHA256", "HexString"];
otherHash = Hash["another pre-U3 source", "SHA256", "HexString"];
foreignVersion = "MultiquadraticOffDiagonalBlockSolve-ABI-0";

(* re-key an association from "ABIVersion" to the legacy key IN PLACE *)
legacyKeyed[record_Association, hash_: legacyHash] := Association[KeyValueMap[
  If[#1 === "ABIVersion", "SourceSHA256" -> hash, #1 -> #2] &, record]];

FTAssert["the ABI version is the U3 string and a legacy hash is 64 hex digits",
  abiVersion === "MultiquadraticOffDiagonalBlockSolve-ABI-1" &&
   StringLength[legacyHash] === 64 && legacyHashQ[legacyHash] === True &&
   legacyHashQ["deadbeef"] === False && legacyHashQ[None] === False &&
   legacyHashQ[abiVersion] === False];

Clear[x, y, eps, v, w, cx, cy];

(* ==================================================================
   A. prepare checkpoints
   ================================================================== *)

payload = {x + y, 1 - x, (x - y)/(1 + eps)};
current = checkpointRecord["CandidateLetters", "input-fp-1", payload, {x, y}, eps];
FTAssert["A1 the current-format checkpoint is sealed with ABIVersion and no legacy key",
  AssociationQ[current] && current["ABIVersion"] === abiVersion &&
   ! KeyExistsQ[current, "SourceSHA256"]];

statusOf[record_] := Lookup[checkpointAccept[record, "CandidateLetters",
   "input-fp-1", {x, y}, eps], "Status", None];
verdict = checkpointAccept[current, "CandidateLetters", "input-fp-1", {x, y}, eps];
FTAssert["A2 the current-format checkpoint is accepted with lineage ABIVersion and its payload",
  verdict["Status"] === "Accepted" && verdict["ABILineage"] === "ABIVersion" &&
   verdict["Payload"] === payload];

(* the pre-U3 writer, verbatim (commit 96be12e9, lines 787-806): the
   header carries "SourceSHA256" where the current one carries
   "ABIVersion", and the seal is the fingerprint of THAT header *)
legacyHeaderKeys = {"Schema", "SchemaVersion", "Substage", "SourceSHA256",
  "AlgebraABIFingerprint", "InputFingerprint", "PayloadSHA256"};
legacyCheckpoint[hash_] := Module[{header},
  header = Association[Table[
     key -> If[key === "SourceSHA256", hash, current[key]],
     {key, legacyHeaderKeys}]];
  Join[header, <|"Fingerprint" -> fingerprint[header],
    "Payload" -> current["Payload"]|>]];
legacy = legacyCheckpoint[legacyHash];
FTAssert["A3 the legacy checkpoint differs from the current one only in the identity key and its seal",
  Keys[legacy] === (Keys[current] /. "ABIVersion" -> "SourceSHA256") &&
   legacy["Fingerprint"] =!= current["Fingerprint"] &&
   legacy["Payload"] === current["Payload"]];
legacyVerdict = checkpointAccept[legacy, "CandidateLetters", "input-fp-1", {x, y}, eps];
FTAssert["A4 the legacy checkpoint is accepted with the typed legacy lineage and the same payload",
  legacyVerdict["Status"] === "Accepted" &&
   legacyVerdict["ABILineage"] === "LegacySourceSHA256" &&
   legacyVerdict["Payload"] === payload];

legacyFile = FileNameJoin[{scratch, "legacy_prepare_candidateletters.wl"}];
written = artifactWrite[legacy, legacyFile];
raw = artifactLoadRaw[legacyFile, artifactContext];
FTAssert["A5 the legacy checkpoint survives the artifact write/read of the prepare route and is still accepted",
  Lookup[written, "Status", None] === "MultiquadraticArtifactWritten" &&
   Lookup[raw, "Status", None] === "RawMultiquadraticArtifact" &&
   With[{v = checkpointAccept[raw["Value"], "CandidateLetters", "input-fp-1",
      {x, y}, eps]},
    v["Status"] === "Accepted" && v["ABILineage"] === "LegacySourceSHA256" &&
     v["Payload"] === payload]];

FTAssert["A6 a malformed legacy hash is refused typed",
  statusOf[legacyCheckpoint["deadbeef"]] === "PrepareCheckpointABIUnknown"];
neither = Module[{header = KeyDrop[legacy, {"SourceSHA256", "Fingerprint", "Payload"}]},
  Join[header, <|"Fingerprint" -> fingerprint[header], "Payload" -> legacy["Payload"]|>]];
FTAssert["A7 a record carrying neither identity key is refused typed",
  statusOf[neither] === "PrepareCheckpointABIUnknown"];
foreign = Module[{header = Association[Table[
     key -> If[key === "ABIVersion", foreignVersion, current[key]],
     {key, legacyHeaderKeys /. "SourceSHA256" -> "ABIVersion"}]]},
  Join[header, <|"Fingerprint" -> fingerprint[header], "Payload" -> current["Payload"]|>]];
(* resume admission is blind to the implementation VERSION
   (t_multiquadratic_persistence P5): the seal, the input fingerprint and
   the payload hash bind a checkpoint, the version is provenance *)
FTAssert["A8 a checkpoint sealed under another ABI version is still admitted, with lineage ABIVersion",
  With[{v = checkpointAccept[foreign, "CandidateLetters", "input-fp-1", {x, y}, eps]},
   v["Status"] === "Accepted" && v["ABILineage"] === "ABIVersion"]];
FTAssert["A9 a mutated legacy payload is refused on content",
  statusOf[Append[legacy, "Payload" -> (legacy["Payload"] /.
      \[FormalX] -> 2 \[FormalX])]] === "PrepareCheckpointContentMismatch"];
FTAssert["A10 a legacy hash changed without resealing is refused on the seal (the hash stays bound)",
  statusOf[Append[legacy, "SourceSHA256" -> otherHash]] ===
   "PrepareCheckpointSealMismatch"];

(* ==================================================================
   B. letter dlog certificates
   ================================================================== *)

letter = 1 - x - y;
form = {D[Log[letter], x], D[Log[letter], y]};
certificate = letterCertificate[letter, form, {x, y}, eps];
FTAssert["B1 the current V1 certificate carries ABIVersion and validates",
  AssociationQ[certificate] && certificate["ABIVersion"] === abiVersion &&
   letterCertificateValidQ[certificate, letter, form, {x, y}, eps] === True];
legacyCertificate = legacyKeyed[certificate];
FTAssert["B2 the legacy V1 certificate validates",
  KeyExistsQ[legacyCertificate, "SourceSHA256"] &&
   ! KeyExistsQ[legacyCertificate, "ABIVersion"] &&
   letterCertificateValidQ[legacyCertificate, letter, form, {x, y}, eps] === True];
FTAssert["B3 a legacy V1 certificate with a changed letter hash, a malformed hash, or checked against another letter fails",
  letterCertificateValidQ[Append[legacyCertificate,
     "LetterSHA256" -> StringReverse[legacyCertificate["LetterSHA256"]]],
    letter, form, {x, y}, eps] === False &&
   letterCertificateValidQ[legacyKeyed[certificate, "deadbeef"],
     letter, form, {x, y}, eps] === False &&
   letterCertificateValidQ[legacyCertificate, x + y, form, {x, y}, eps] === False];

letterChannels = {letter};
formChannels = {{form[[1]]}, {form[[2]]}};
channelCertificate = constructedEvidence[
   channelTextKey[letterChannels, {x, y}, eps],
   channelTextKey[formChannels, {x, y}, eps],
   expressionTextKey[letter, {x, y}], "pair-key"]["DLogCertificate"];
FTAssert["B4 the current channel certificate validates through the seven-argument validator",
  AssociationQ[channelCertificate] &&
   channelCertificate["ABIVersion"] === abiVersion &&
   letterCertificateValidQ[channelCertificate, letter, form, {x, y}, eps,
     letterChannels, formChannels] === True];
legacyChannel = legacyKeyed[channelCertificate];
FTAssert["B5 the legacy channel certificate validates",
  letterCertificateValidQ[legacyChannel, letter, form, {x, y}, eps,
    letterChannels, formChannels] === True];
FTAssert["B6 a legacy channel certificate with a changed channel hash or a malformed hash fails",
  letterCertificateValidQ[Append[legacyChannel, "LetterChannelSHA256" ->
      StringReverse[legacyChannel["LetterChannelSHA256"]]],
    letter, form, {x, y}, eps, letterChannels, formChannels] === False &&
   letterCertificateValidQ[legacyKeyed[channelCertificate, "deadbeef"],
     letter, form, {x, y}, eps, letterChannels, formChannels] === False];

(* ==================================================================
   C. compiled assemblies (the fixture of t_multiquadratic_persistence)
   ================================================================== *)

frame = BuildSquareRootGeneratorsAndQuadraticRelations[{v, w, 1 + v + w}, {v, w}, {cx, cy}];
FTAssert["C0a the rank-three multiquadratic frame is exact",
  AssociationQ[frame] && frame["Status"] === "ExactFrame"];

dlog[l_] := {D[Log[l], x], D[Log[l], y]};
letters = {x, y, 1 - x - y};
oneForms = dlog /@ letters;
denominator = 1 - x - y;
support = Sort[{{0, 0}, {0, 1}, {1, 0}}];
diagonalForm[residues_List] := Table[
  Sum[residues[[a]] oneForms[[a, mu]], {a, Length[letters]}], {mu, 2}];
canonicalRootRecords[indices_] := Module[
  {order = rootOrder[frame, {x, y}, indices, eps]},
  If[Lookup[order, "Status", None] =!= "StableRootOrder", $Failed,
    order["Roots"]]];
gradeFactor[grade_, roots_] :=
  Product[If[BitGet[grade, k - 1] === 1, roots[[k]], 1], {k, Length[roots]}];
buildOffDiagonalBasisTransformationBlock[coefficients_, dimensions_, roots_] := Table[
  Sum[coefficients[[i, j, grade + 1, monomial]]
      x^support[[monomial, 1]] y^support[[monomial, 2]] gradeFactor[grade, roots]/
      denominator,
    {grade, 0, 2^Length[roots] - 1}, {monomial, Length[support]}],
  {i, dimensions[[1]]}, {j, dimensions[[2]]}];
buildInhomogeneity[e_, c_, gauge_, residues_] := Table[
  Map[Together, Sum[residues[[a]] eps oneForms[[a, mu]], {a, Length[letters]}] +
    D[gauge, {x, y}[[mu]]] - eps (e[[mu]] . gauge - gauge . c[[mu]]), {2}],
  {mu, 2}];
buildRecord[indices_List, dimensions_List, seed_Integer] := Module[
  {rootRecords, roots, gradeCount, coefficients, residues, gauge, e, c, inhomogeneity},
  rootRecords = canonicalRootRecords[indices];
  roots = Lookup[rootRecords, "Root", {}];
  gradeCount = 2^Length[indices];
  coefficients = BlockRandom[SeedRandom[seed];
    Table[RandomInteger[{-6, 6}] + RandomChoice[{0, 1/2, 1/3, -2/5}],
      {dimensions[[1]]}, {dimensions[[2]]}, {gradeCount}, {Length[support]}]];
  residues = BlockRandom[SeedRandom[seed + 1];
    Table[RandomInteger[{-4, 4}] + RandomChoice[{0, 1/4, -1/7}],
      {Length[letters]}, {dimensions[[1]]}, {dimensions[[2]]}]];
  gauge = buildOffDiagonalBasisTransformationBlock[coefficients, dimensions, roots];
  e = BlockRandom[SeedRandom[seed + 2];
    diagonalForm[Table[RandomInteger[{-2, 2}, {dimensions[[1]],
      dimensions[[1]]}], {Length[letters]}]]];
  c = BlockRandom[SeedRandom[seed + 3];
    diagonalForm[Table[RandomInteger[{-2, 2}, {dimensions[[2]],
      dimensions[[2]]}], {Length[letters]}]]];
  inhomogeneity = buildInhomogeneity[e, c, gauge, residues];
  <|"Family" -> "TLEGACY", "Sector" -> 4, "LowerSector" -> 2,
    "Variables" -> {x, y}, "Regulator" -> eps,
    "OffDiagonalBlockEquation" -> {e, c, inhomogeneity}|>];
record = buildRecord[{1, 2}, {2, 2}, 20260825];

clearCaches[];
preparation = prepare[record, frame, "OneForms" -> oneForms,
  "OffDiagonalBasisTransformationDenominator" -> denominator, "Support" -> support,
  "RootIndices" -> {1, 2}];
FTAssert["C0b the reference preparation succeeds",
  Lookup[preparation, "Status", None] === "PreparedMultiquadraticOffDiagonalBlockV1"];
{compileSeconds, assembly} = AbsoluteTiming[
  compile[preparation]];
Print["     compile seconds: ", Round[compileSeconds, 0.01]];
FTAssert["C1 the assembly compiles, carries ABIVersion and validates",
  Lookup[assembly, "Status", None] === "CompiledMultiquadraticOffDiagonalBlockV1" &&
   assembly["ABIVersion"] === abiVersion && compiledValidQ[assembly] === True];

currentAssemblyFile = FileNameJoin[{scratch, "assembly_current.wl"}];
artifactWrite[assembly, currentAssemblyFile];
hydrated = readPrepared[currentAssemblyFile];
FTAssert["C2 the current assembly hydrates with lineage ABIVersion",
  Lookup[hydrated, "Status", None] === "HydratedMultiquadraticAssembly" &&
   hydrated["ABILineage"] === "ABIVersion" &&
   hydrated["AssemblyFingerprint"] === assembly["AssemblyFingerprint"]];

(* the pre-U3 writer: "SourceSHA256" in place of "ABIVersion", the
   AssemblyFingerprint over the pre-U3 semantic payload (commit 96be12e9,
   lines 7755-7762: the same key list with "SourceSHA256" last) *)
legacySemanticKeys = {"ABIFingerprint", "AlgebraABIFingerprint",
  "RootOrderingFingerprint", "RootCount", "GradeCount", "Dimensions",
  "OffDiagonalBasisTransformationNumeratorSupport", "OffDiagonalBasisTransformationUnknownCount", "ResidueUnknownCount", "UnknownCount",
  "EquationsPerPoint", "ColumnOrder", "RowOrder",
  "ExactChannelFormsFingerprint", "CompiledFormsFingerprint",
  "CompiledFormsShapeFingerprint", "SourceSHA256"};
legacyAssemblyWith[hash_] := Module[{a},
  a = Append[KeyDrop[assembly, {"ABIVersion", "AssemblyFingerprint"}],
    "SourceSHA256" -> hash];
  Append[a, "AssemblyFingerprint" -> fingerprint[KeyTake[a, legacySemanticKeys]]]];
legacyAssembly = legacyAssemblyWith[legacyHash];
FTAssert["C3 the legacy assembly is sealed differently and validates",
  legacyAssembly["AssemblyFingerprint"] =!= assembly["AssemblyFingerprint"] &&
   ! KeyExistsQ[legacyAssembly, "ABIVersion"] &&
   compiledValidQ[legacyAssembly] === True];
legacyAssemblyFile = FileNameJoin[{scratch, "assembly_legacy.wl"}];
artifactWrite[legacyAssembly, legacyAssemblyFile];
hydratedLegacy = readPrepared[legacyAssemblyFile];
FTAssert["C4 the legacy assembly hydrates with lineage LegacySourceSHA256",
  Lookup[hydratedLegacy, "Status", None] === "HydratedMultiquadraticAssembly" &&
   hydratedLegacy["ABILineage"] === "LegacySourceSHA256" &&
   hydratedLegacy["AssemblyFingerprint"] === legacyAssembly["AssemblyFingerprint"]];

reseal[a_Association] := Append[a, "AssemblyFingerprint" ->
   fingerprint[semanticPayload[a]]];
neitherAssembly = reseal[KeyDrop[assembly, "ABIVersion"]];
neitherFile = FileNameJoin[{scratch, "assembly_neither.wl"}];
artifactWrite[neitherAssembly, neitherFile];
FTAssert["C5 refusals: a tampered content fingerprint under the legacy key, a malformed legacy hash, a resealed foreign ABI version, and a record with neither key (typed by the reader)",
  compiledValidQ[Append[legacyAssembly, "CompiledFormsFingerprint" ->
      StringReverse[legacyAssembly["CompiledFormsFingerprint"]]]] === False &&
   compiledValidQ[legacyAssemblyWith["deadbeef"]] === False &&
   compiledValidQ[reseal[Append[assembly, "ABIVersion" -> foreignVersion]]] === False &&
   compiledValidQ[neitherAssembly] === False &&
   Lookup[readPrepared[neitherFile], "Status", None] === "ArtifactAssemblyABIInvalid"];

(* ==================================================================
   D. the real 2026-08-25 fixture that carries "SourceSHA256"
   ================================================================== *)

frozen = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical", "FamilyEpsFormsSolving", "FrozenTestFixtures_2026-08-25",
  "cf300_frozen_stripsolvers.wl"}];
rawFrozen = artifactLoadRaw[frozen, artifactContext];
FTAssert["D1 the 2026-08-25 fixture loads raw and carries a well-formed legacy SourceSHA256",
  Lookup[rawFrozen, "Status", None] === "RawMultiquadraticArtifact" &&
   AssociationQ[rawFrozen["Value"]] &&
   rawFrozen["Value"]["Schema"] === "FrozenCF300OffDiagonalBlockSolutionsV1" &&
   legacyHashQ[rawFrozen["Value"]["SourceSHA256"]] === True &&
   lineage[rawFrozen["Value"]] === "LegacySourceSHA256"];
FTAssert["D2 the prepared-artifact reader refuses the foreign schema typed: the alias admits a KEY, not a schema",
  Lookup[readPrepared[frozen], "Status", None] === "ArtifactSchemaUnknown"];
FTAssert["D3 its strip-solver entries name primes",
  With[{primes = DeleteDuplicates[Flatten[Lookup[
      rawFrozen["Value"]["OffDiagonalBlockSolutions"], "Primes", {}]]]},
   primes =!= {} && AllTrue[primes, PrimeQ]]];

DeleteDirectory[scratch, DeleteContents -> True];
FTReport[];
