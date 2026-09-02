#!/usr/bin/env wolframscript
(* The 2026-08-25 HARDENING WAVE provenance work in
   FeynFacet/Private/MultiquadraticStripSolve.wl.  Every section here is
   one of Codex's P1 merge blockers from
   Exchange/Codex/2026-08-25/07_optimization_review_1430.md, and every one
   of them is ADVERSARIAL: it presents
   a mutant the pre-fix code accepts and requires the current code to
   refuse it.  None of these assertions inspects source text.

   ACCEPTANCE CRITERIA, stated before the run.

   A1  ROOT SIGN IN THE CORE KEY.  Two root declarations that differ
       only in a root SIGN are different bases of the same field: the
       same channel vector composes to different elements.  A compile
       core keyed for one must therefore MISS for the other.  The
       pre-fix key tuple (root squares only) is built explicitly here
       and must be shown to COLLIDE, so the assertion is a statement
       about behaviour, not about the source.

   A2  FORCING-CHANNEL CONTENT.  A seal must authenticate the channels
       it carries, not only the forcing they were derived from.  A
       same-shape mutation of one channel entry must be refused with a
       CONTENT-specific status; a mutation that also refreshes the
       content hash must still fail the seal fingerprint; and a V1
       record must be refused-typed, never upgraded.

   A3  COMPACT-DLOG ADMISSION.  The compact letter-channel route
       installs the channels of dlog(Letter) in place of the form it was
       asked to compile.  A record naming a CORRECT letter and a WRONG
       one-form -- self-consistent, so the pre-fix SameQ gate passed it
       -- must be refused the compact route, and the compiled channels
       must be those of the form actually requested.  A record this
       package built must be admitted by its certificate, and the same
       record with its certificate removed must be admitted by an exact
       dlog check.

   A4  BEHAVIOURAL TWO-CONSUMER REFUSAL.  A bare shape-compatible array
       supplied as "ForcingChannels" must be refused typed by BOTH
       prepare and compile, established by calling them, not by counting
       occurrences of a helper name in the source.

   K   ONE-FORM POOL KEY.  The compile pool key for a one-form must
       separate the requested route and the letter provenance, so a
       route flip can never serve the other route's entry.

   G   GRADE GATE.  With a declared grade set, the compact route must
       refuse typed a letter whose dlog occupies a mask outside it.

   R   RANK-3 TOWER INVERSION.  The recursive quadratic-tower inverse
       must be EXACTLY equal to the 2^r x 2^r linear-solve inverse on a
       rank-2 and a synthetic rank-3 element, and both must satisfy the
       exact product identity.

   B   BYTE-BOUNDED POOLS.  The pools must report measured Bytes, and a
       value above a pool's oversize allowance must BYPASS the pool --
       leaving every entry it already holds in place -- rather than
       evicting them. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "FeynFacet", "Private", "Core", "MultiquadraticAlgebra.wl"}]];
Get[FileNameJoin[{root, "FeynFacet", "Private", "EpsForm", "MultiquadraticStripSolve.wl"}]];

pass = 0; fail = 0;
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];
note[label_, value_] := Print["     ", label, ": ",
  ToString[Short[value, 8], InputForm]];
mq[name_String] := Symbol["FeynFacet`Private`" <> name];
dlogKernelText = Environment["FACET_MQ_TEST_DLOG_KERNELS"];
dlogKernels = If[StringQ[dlogKernelText] &&
    StringMatchQ[dlogKernelText, DigitCharacter ..],
  FromDigits[dlogKernelText], Automatic];

{prepare, compile, rootOrder, coreCanonicalData, coreKeyFromParts,
  coreRecord, intern, internProbe, internStatistics, internReset,
  clearCaches, channelRecord, channelAccept, contentHash,
  dlogCertificate, dlogCertificateValidQ, compactAdmission,
  gradeSupportOf, oneFormEntry, oneFormKeyOf, letterProvenance,
  fieldDecompose, fieldCompose, fieldInverse, inverseTower,
  inverseLinearSolve, multiply, letterOneForm, candidateLetters,
  canonicalRules, canonicalText, internValidQ} =
 mq /@ {"multiquadraticStripPrepare", "multiquadraticStripCompile",
   "multiquadraticStripRootOrder", "multiquadraticStripCoreCanonicalData",
   "multiquadraticStripCompileCoreKeyFromParts",
   "multiquadraticStripCompileCoreRecord", "multiquadraticStripIntern",
   "multiquadraticStripInternProbe", "multiquadraticStripInternStatistics",
   "multiquadraticStripInternReset", "multiquadraticStripCompileCacheClear",
   "multiquadraticStripForcingChannelRecord",
   "multiquadraticStripForcingChannelsAccept",
   "multiquadraticStripForcingChannelContentHash",
   "multiquadraticStripLetterDLogCertificate",
   "multiquadraticStripLetterDLogCertificateValidQ",
   "multiquadraticStripCompactDLogAdmission",
   "multiquadraticStripChannelGradeSupport",
   "multiquadraticStripCompileOneFormEntry",
   "multiquadraticStripCompileOneFormKey",
   "multiquadraticStripLetterProvenanceHash",
   "multiquadraticFieldDecompose", "multiquadraticFieldCompose",
   "multiquadraticFieldInverse", "multiquadraticFieldInverseTower",
   "multiquadraticFieldInverseLinearSolve", "multiquadraticMultiply",
   "multiquadraticStripLetterOneForm", "multiquadraticStripCandidateLetters",
   "multiquadraticStripCanonicalRules", "multiquadraticStripCanonicalText",
   "multiquadraticStripInternValidQ"};

algebraFingerprint = mq["multiquadraticAlgebraABIFingerprint"];

(* ------------------------------------------------------------------ *)
(* The fixture: a block BUILT from a known gauge and known residues,    *)
(* the same construction t_multiquadratic_prepare_core uses.            *)
(* ------------------------------------------------------------------ *)

Clear[x, y, eps, v, w, cx, cy];
frame = BuildAlgebraicTransportFrame[{v, w, 1 + v + w}, {v, w}, {cx, cy}];
check["the rank-three multiquadratic frame is exact",
  AssociationQ[frame] && frame["Status"] === "ExactFrame"];

dlog[letter_] := {D[Log[letter], x], D[Log[letter], y]};
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

buildGauge[coefficients_, dimensions_, roots_] := Table[
  Sum[coefficients[[i, j, grade + 1, monomial]]
      x^support[[monomial, 1]] y^support[[monomial, 2]] gradeFactor[grade, roots]/
      denominator,
    {grade, 0, 2^Length[roots] - 1}, {monomial, Length[support]}],
  {i, dimensions[[1]]}, {j, dimensions[[2]]}];

buildForcing[e_, c_, gauge_, residues_] := Table[
  Map[Together, Sum[residues[[a]] eps oneForms[[a, mu]], {a, Length[letters]}] +
    D[gauge, {x, y}[[mu]]] - eps (e[[mu]] . gauge - gauge . c[[mu]]), {2}],
  {mu, 2}];

buildRecord[indices_List, dimensions_List, seed_Integer] := Module[
  {rootRecords, roots, gradeCount, coefficients, residues, gauge, e, c, bbar},
  rootRecords = canonicalRootRecords[indices];
  roots = Lookup[rootRecords, "Root", {}];
  gradeCount = 2^Length[indices];
  coefficients = BlockRandom[SeedRandom[seed];
    Table[RandomInteger[{-6, 6}] + RandomChoice[{0, 1/2, 1/3, -2/5}],
      {dimensions[[1]]}, {dimensions[[2]]}, {gradeCount}, {Length[support]}]];
  residues = BlockRandom[SeedRandom[seed + 1];
    Table[RandomInteger[{-4, 4}] + RandomChoice[{0, 1/4, -1/7}],
      {Length[letters]}, {dimensions[[1]]}, {dimensions[[2]]}]];
  gauge = buildGauge[coefficients, dimensions, roots];
  e = BlockRandom[SeedRandom[seed + 2];
    diagonalForm[Table[RandomInteger[{-2, 2}, {dimensions[[1]],
      dimensions[[1]]}], {Length[letters]}]]];
  c = BlockRandom[SeedRandom[seed + 3];
    diagonalForm[Table[RandomInteger[{-2, 2}, {dimensions[[2]],
      dimensions[[2]]}], {Length[letters]}]]];
  bbar = buildForcing[e, c, gauge, residues];
  <|"Family" -> "TPROV", "Sector" -> 4, "LowerSector" -> 2,
    "Variables" -> {x, y}, "Regulator" -> eps,
    "Strip" -> {e, c, bbar}|>];

record = buildRecord[{1, 2}, {2, 2}, 20260825];
rootRecords = canonicalRootRecords[{1, 2}];
check["the fixture record and its canonical root order are well formed",
  MatchQ[Lookup[record, "Strip", None], {_List, _List, _List}] &&
    MatchQ[rootRecords, {__Association}] &&
    AllTrue[rootRecords, KeyExistsQ[#, "Root"] && KeyExistsQ[#, "RootSquare"] &]];

prepareArgs = {"OneForms" -> oneForms, "GaugeDenominator" -> denominator,
  "Support" -> support, "RootIndices" -> {1, 2}};

(* ================================================================== *)
(* A1  THE ROOT SIGN IN THE COMPILE CORE KEY  (Codex P1, merge blocker) *)
(* ================================================================== *)

signMutantRoots = MapAt[Function[entry,
    Append[entry, "Root" -> -entry["Root"]]], rootRecords, 1];

check["A1 the mutant differs from the fixture ONLY in the sign of the \
first root",
  Lookup[signMutantRoots, "RootSquare", {}] ===
      Lookup[rootRecords, "RootSquare", {}] &&
    Lookup[signMutantRoots, "Root", {}] =!= Lookup[rootRecords, "Root", {}] &&
    Rest[Lookup[signMutantRoots, "Root", {}]] ===
      Rest[Lookup[rootRecords, "Root", {}]]];

(* WHY the two must not share a core: the same channel vector composes
   to different elements of the field in the two bases, so a cached core
   served across them is arithmetic in somebody else's basis *)
probeChannels = {1, 3, 0, 0};
check["A1 the two root declarations are DIFFERENT bases: one channel \
vector composes to two different elements",
  ! TrueQ[Together[fieldCompose[probeChannels, rootRecords] -
    fieldCompose[probeChannels, signMutantRoots]] === 0]];

canonicalOf[roots_] := coreCanonicalData[record, roots, {x, y}, eps];
canonicalPlain = canonicalOf[rootRecords];
canonicalMutant = canonicalOf[signMutantRoots];

check["A1 the canonical root EXPRESSIONS differ while the canonical root \
SQUARES agree",
  AssociationQ[canonicalPlain] && AssociationQ[canonicalMutant] &&
    canonicalPlain["RootCanonicalSquares"] ===
      canonicalMutant["RootCanonicalSquares"] &&
    canonicalPlain["RootCanonicalExpressions"] =!=
      canonicalMutant["RootCanonicalExpressions"]];

dimensionsOf = Dimensions[record["Strip"][[3, 1]]];
currentKey[canonical_] := coreKeyFromParts[algebraFingerprint[],
  Hash[canonical["EquationCanonical"], "SHA256", "HexString"],
  Hash[canonical["RootCanonicalSquares"], "SHA256", "HexString"],
  canonical["RootCanonicalSquares"], canonical["RootCanonicalExpressions"],
  dimensionsOf, {x, y}, eps];

(* the PRE-FIX tuple, reconstructed exactly as the 2026-08-25 morning
   source built it: source hash, algebra fingerprint, equation
   fingerprint, root-ordering fingerprint, root squares, dimensions,
   variables, regulator -- and no root expressions *)
preFixKey[canonical_] := {
  Symbol["FeynFacet`Private`$multiquadraticStripSourceSHA256"],
  algebraFingerprint[],
  Hash[canonical["EquationCanonical"], "SHA256", "HexString"],
  Hash[canonical["RootCanonicalSquares"], "SHA256", "HexString"],
  canonical["RootCanonicalSquares"], dimensionsOf, {x, y}, eps};

check["A1 the PRE-FIX key tuple COLLIDES on the sign mutant (this is the \
defect)",
  preFixKey[canonicalPlain] === preFixKey[canonicalMutant]];

check["A1 the current key tuple SEPARATES the sign mutant",
  currentKey[canonicalPlain] =!= currentKey[canonicalMutant]];

(* BEHAVIOURAL: build the core for the fixture, then probe the pool with
   the mutant's key.  The pool is the object under test, not the key. *)
clearCaches[];
coreBuilt = coreRecord[record["Strip"], rootRecords, {x, y}, eps,
  Missing["NotSupplied"], currentKey[canonicalPlain], True];
check["A1 the fixture core builds and is interned",
  AssociationQ[coreBuilt] &&
    ! MissingQ[internProbe["Core", currentKey[canonicalPlain]]]];
check["A1 the sign mutant MISSES the interned core (current key)",
  MissingQ[internProbe["Core", currentKey[canonicalMutant]]]];

clearCaches[];
intern["Core", preFixKey[canonicalPlain], Function[coreBuilt]];
check["A1 under the PRE-FIX key the sign mutant HITS the other basis' \
core -- the collision this closes",
  ! MissingQ[internProbe["Core", preFixKey[canonicalMutant]]] &&
    SameQ[internProbe["Core", preFixKey[canonicalMutant]], coreBuilt]];
clearCaches[];

(* ================================================================== *)
(* A2  FORCING-CHANNEL CONTENT AUTHENTICATION (Codex P1, merge blocker) *)
(* ================================================================== *)

Clear[fx, fy, fe];
sealForcing = {{{fx/(1 - fy), fx}}, {{fe fy, 1}}};
sealChannels = {{{{fx/(1 - fy)}, {fx}}}, {{{fe fy}, {1}}}};
sealRoots = {};
sealed = channelRecord[sealChannels, sealForcing, sealRoots, {fx, fy}, fe];

check["A2 the seal is schema V2 and carries an explicit ChannelsSHA256",
  AssociationQ[sealed] &&
    sealed["Schema"] === "MultiquadraticForcingChannelsV2" &&
    sealed["SchemaVersion"] === 2 &&
    StringQ[sealed["ChannelsSHA256"]] &&
    StringLength[sealed["ChannelsSHA256"]] === 64 &&
    StringQ[sealed["Fingerprint"]] &&
    StringLength[sealed["Fingerprint"]] === 64];

check["A2 its own forcing and its own channels accept it",
  Lookup[channelAccept[sealed, sealForcing, sealRoots, {fx, fy}, fe],
    "Status", None] === "Accepted"];

(* THE MUTANT: the same shape, one channel entry changed, every other
   field of the seal untouched.  The pre-fix V1 seal fingerprinted the
   forcing and the root squares only, so it accepted exactly this. *)
mutantChannels = ReplacePart[sealChannels, {1, 1, 1, 1} -> fx/(1 + fy)];
mutantSeal = Append[sealed, "Channels" -> mutantChannels];
check["A2 a same-shape CHANNEL-CONTENT mutant under an otherwise valid \
seal is refused, and the refusal names the content",
  Module[{verdict = channelAccept[mutantSeal, sealForcing, sealRoots,
      {fx, fy}, fe]},
    Lookup[verdict, "Status", None] === "ForcingChannelContentMismatch" &&
      StringQ[verdict["ExpectedChannelsSHA256"]] &&
      verdict["ExpectedChannelsSHA256"] =!=
        verdict["SuppliedChannelsSHA256"]]];

(* the harder mutant: the attacker also refreshes the content hash.  The
   seal fingerprint is taken OVER that hash, so it still fails. *)
refreshedSeal = Join[mutantSeal,
  <|"ChannelsSHA256" -> contentHash[mutantChannels, {fx, fy}, fe]|>];
check["A2 a mutant that also refreshes ChannelsSHA256 still fails the \
seal fingerprint",
  Lookup[channelAccept[refreshedSeal, sealForcing, sealRoots, {fx, fy}, fe],
    "Status", None] === "ForcingChannelProvenanceMismatch"];

check["A2 a V1 record is refused-typed and never silently upgraded",
  Module[{legacy = Join[KeyDrop[sealed, "ChannelsSHA256"],
      <|"Schema" -> "MultiquadraticForcingChannelsV1",
        "SchemaVersion" -> 1|>], verdict},
    verdict = channelAccept[legacy, sealForcing, sealRoots, {fx, fy}, fe];
    Lookup[verdict, "Status", None] === "ForcingChannelSealSuperseded" &&
      verdict["ExpectedSchema"] === "MultiquadraticForcingChannelsV2"]];

check["A2 a DIFFERENT forcing under a valid seal is still refused on \
provenance",
  Lookup[channelAccept[sealed, {{{fx/(1 + fy), fx}}, {{fe fy, 1}}}, sealRoots,
    {fx, fy}, fe], "Status", None] === "ForcingChannelProvenanceMismatch"];

check["A2 neither the seal fingerprint nor the content hash depends on \
the context the variables arrived in",
  Module[{inGlobal = channelRecord[{{{{Symbol["Global`sX"]}}}, {{{0}}}},
        {{{Symbol["Global`sX"]}}, {{0}}}, {},
        {Symbol["Global`sX"], Symbol["Global`sY"]}, Symbol["Global`sE"]],
      inPrivate = channelRecord[
        {{{{Symbol["FeynFacet`Private`sX"]}}}, {{{0}}}},
        {{{Symbol["FeynFacet`Private`sX"]}}, {{0}}}, {},
        {Symbol["FeynFacet`Private`sX"], Symbol["FeynFacet`Private`sY"]},
        Symbol["FeynFacet`Private`sE"]]},
    inGlobal["Fingerprint"] === inPrivate["Fingerprint"] &&
      inGlobal["ChannelsSHA256"] === inPrivate["ChannelsSHA256"] &&
      (* the CHANNELS themselves are the caller's own symbols, and stay
         so: the seal is context free, the payload is not rewritten *)
      ! SameQ[inGlobal["Channels"], inPrivate["Channels"]]]];

(* ================================================================== *)
(* A4  BEHAVIOURAL TWO-CONSUMER REFUSAL (replaces the S12 source grep)  *)
(* ================================================================== *)

bareArray = Map[Function[entry, {entry, 0, 0, 0}], record["Strip"][[3]], {3}];
check["A4 the bare array IS shape compatible (so shape alone would have \
accepted it)",
  ArrayQ[bareArray, 4] &&
    Dimensions[bareArray] === Append[Dimensions[record["Strip"][[3]]], 4]];

barePrepare = prepare[record, frame, Sequence @@ prepareArgs,
  "ForcingChannels" -> bareArray];
check["A4 PREPARE refuses a bare shape-compatible array, typed",
  AssociationQ[barePrepare] &&
    Lookup[barePrepare, "Status", None] === "ForcingChannelsUnsealed"];

goodPreparation = prepare[record, frame, Sequence @@ prepareArgs];
check["A4 the reference preparation succeeds",
  Lookup[goodPreparation, "Status", None] === "PreparedMultiquadraticStripV1"];

bareCompile = compile[goodPreparation, "PreparationValidated" -> True,
  "ForcingChannels" -> bareArray];
check["A4 COMPILE refuses the same bare array, typed",
  AssociationQ[bareCompile] &&
    Lookup[bareCompile, "Status", None] === "ForcingChannelsUnsealed"];

check["A4 compile refuses a CONTENT mutant of the preparation's own seal",
  Module[{seal = goodPreparation["ForcingChannels"], mutated},
    mutated = Append[seal, "Channels" ->
      ReplacePart[seal["Channels"], {1, 1, 1, 1} -> 12345]];
    Lookup[compile[goodPreparation, "PreparationValidated" -> True,
      "ForcingChannels" -> mutated], "Status", None] ===
      "ForcingChannelContentMismatch"]];

(* ================================================================== *)
(* A3  COMPACT-DLOG ADMISSION  (Codex P1, merge blocker)                *)
(* ================================================================== *)

goodLetter = 1 - x - y;
goodForm = letterOneForm[goodLetter, {x, y}];
wrongForm = letterOneForm[x y, {x, y}];

goodRecordWithTag = <|"Kind" -> "RationalFactor", "Letter" -> goodLetter,
  "OneForm" -> goodForm,
  "DLogCertificate" -> dlogCertificate[goodLetter, goodForm, {x, y}, eps]|>;
goodRecordNoTag = KeyDrop[goodRecordWithTag, "DLogCertificate"];
(* SELF-CONSISTENT AND WRONG: the record's stored one-form IS the form
   presented, so the pre-fix SameQ gate admitted it, and the compiler
   then installed dlog(1-x-y) where dlog(x y) was asked for *)
wrongRecord = <|"Kind" -> "RationalFactor", "Letter" -> goodLetter,
  "OneForm" -> wrongForm|>;

check["A3 the certificate this package mints validates for its own pair",
  dlogCertificateValidQ[goodRecordWithTag["DLogCertificate"], goodLetter,
    goodForm, {x, y}, eps]];
check["A3 the certificate does NOT validate for a different one-form",
  ! dlogCertificateValidQ[goodRecordWithTag["DLogCertificate"], goodLetter,
    wrongForm, {x, y}, eps]];
check["A3 the certificate does NOT validate for a different letter",
  ! dlogCertificateValidQ[goodRecordWithTag["DLogCertificate"], x y,
    goodForm, {x, y}, eps]];

check["A3 a tagged record is admitted by its certificate, with no algebra",
  Module[{verdict = compactAdmission[goodRecordWithTag, goodForm, {x, y},
      eps, "CertifiedOrExact"]},
    TrueQ[verdict["Admitted"]] && verdict["Method"] === "CertifiedTag"]];
check["A3 an untagged record is admitted by the EXACT dlog check",
  Module[{verdict = compactAdmission[goodRecordNoTag, goodForm, {x, y},
      eps, "CertifiedOrExact"]},
    TrueQ[verdict["Admitted"]] && verdict["Method"] === "ExactDLogCheck"]];
check["A3 an untagged record is REFUSED under CompactDLogAdmission -> \
Certified",
  Module[{verdict = compactAdmission[goodRecordNoTag, goodForm, {x, y},
      eps, "Certified"]},
    ! TrueQ[verdict["Admitted"]] &&
      verdict["Reason"] === "DLogCertificateMissing"]];
check["A3 THE MUTANT: a correct letter with a wrong one-form is refused \
the compact route",
  Module[{verdict = compactAdmission[wrongRecord, wrongForm, {x, y}, eps,
      "CertifiedOrExact"]},
    ! TrueQ[verdict["Admitted"]] &&
      verdict["Reason"] === "OneFormIsNotTheLetterDLog"]];
check["A3 a DIAGONAL record (closed one-form, no letter) is refused the \
compact route",
  Module[{verdict = compactAdmission[
      <|"Kind" -> "Diagonal", "Letter" -> Missing["NotADLog"],
        "OneForm" -> goodForm|>, goodForm, {x, y}, eps, "CertifiedOrExact"]},
    ! TrueQ[verdict["Admitted"]] && verdict["Reason"] === "NotADLog"]];
check["A3 a record with a TAMPERED certificate is refused, not admitted \
on the tag",
  Module[{tampered = Append[goodRecordWithTag, "DLogCertificate" ->
        Append[goodRecordWithTag["DLogCertificate"],
          "OneFormSHA256" -> StringRepeat["0", 64]]], verdict},
    verdict = compactAdmission[tampered, goodForm, {x, y}, eps, "Certified"];
    ! TrueQ[verdict["Admitted"]] &&
      verdict["Reason"] === "DLogCertificateMismatch"]];

(* BEHAVIOURAL, through the entry compiler: the wrong record must not
   produce the channels of dlog(Letter) *)
internReset["Scalar"]; internReset["Rational"];
wrongEntry = oneFormEntry[wrongForm, wrongRecord, rootRecords, {x, y}, eps,
  True];
rightEntry = oneFormEntry[goodForm, goodRecordWithTag, rootRecords, {x, y},
  eps, True];
decomposedWrong = fieldDecompose[#, rootRecords] & /@ wrongForm;
compactGood = mq["multiquadraticStripLetterChannelPair"][goodLetter,
  rootRecords, {x, y}];
check["A3 the refused record compiles the form it was ASKED for, by \
decomposition",
  AssociationQ[wrongEntry] && wrongEntry["Path"] === "DecomposedForm" &&
    wrongEntry["CompactAdmission"] === "OneFormIsNotTheLetterDLog" &&
    SameQ[wrongEntry["Channels"], decomposedWrong]];
check["A3 the admitted record takes the compact letter-channel route",
  AssociationQ[rightEntry] &&
    rightEntry["Path"] === "CompactLetterChannels" &&
    rightEntry["CompactAdmission"] === "CertifiedTag" &&
    SameQ[rightEntry["Channels"], compactGood]];
check["A3 exact retained dlog channels bypass duplicate construction",
  Module[{retainedRecord = Append[goodRecordWithTag,
       "DLogChannels" -> compactGood], entry},
    entry = Block[{
        FeynFacet`Private`multiquadraticStripLetterChannelPair =
          Function[Null, $Failed, HoldAll]},
      oneFormEntry[goodForm, retainedRecord, rootRecords, {x, y}, eps,
        True]];
    AssociationQ[entry] && SameQ[entry["Channels"], compactGood]]];
check["A3 stale retained channels fall back to exact reconstruction",
  Module[{stale = ReplacePart[compactGood, {1, 1} ->
        compactGood[[1, 1]] + 1], staleRecord, entry},
    staleRecord = Append[goodRecordWithTag, "DLogChannels" -> stale];
    entry = oneFormEntry[goodForm, staleRecord, rootRecords, {x, y}, eps,
      True];
    AssociationQ[entry] && SameQ[entry["Channels"], compactGood]]];
check["A3 the two routes would have produced DIFFERENT channels for the \
mutant (the substitution the gate prevents)",
  ! SameQ[decomposedWrong, compactGood]];

(* the letters this package builds all carry the certificate *)
kernelsBeforeCandidate = Kernels[];
letterData = candidateLetters[record["Strip"], rootRecords, {x, y}, eps,
  record, "RegulatorSampleCount" -> 2, "DLogKernels" -> dlogKernels];
kernelsAfterCandidate = Kernels[];
v2LetterRecords = Select[letterData["LetterRecords"],
  Lookup[Lookup[#, "DLogCertificate", <||>], "Schema", None] ===
      "MultiquadraticLetterDLogChannelsV2" &];
check["A3 every non-diagonal candidate letter is minted with a valid \
dlog certificate",
  Lookup[letterData, "Status", None] === "MultiquadraticCandidateLettersV1" &&
    AllTrue[Select[letterData["LetterRecords"],
        ! MissingQ[Lookup[#, "Letter", Missing[]]] &],
      If[Lookup[Lookup[#, "DLogCertificate", <||>], "Schema", None] ===
          "MultiquadraticLetterDLogChannelsV2",
        dlogCertificateValidQ[Lookup[#, "DLogCertificate", None],
          #["Letter"], #["OneForm"], {x, y}, eps,
          Lookup[#, "DLogLetterChannels", $Failed],
          Lookup[#, "DLogChannels", $Failed]],
        dlogCertificateValidQ[Lookup[#, "DLogCertificate", None],
          #["Letter"], #["OneForm"], {x, y}, eps]] &]];
check["A3 the channel certificate refuses a same-shape retained-channel \
mutation",
  v2LetterRecords =!= {} && Module[{rec = First[v2LetterRecords], mutant},
    mutant = ReplacePart[rec["DLogChannels"], {1, 1} ->
      rec["DLogChannels"][[1, 1]] + 1];
    ! dlogCertificateValidQ[rec["DLogCertificate"], rec["Letter"],
      rec["OneForm"], {x, y}, eps, rec["DLogLetterChannels"], mutant]]];
check["A3 the compile boundary refuses certified channels whose raw letter \
was mutated",
  v2LetterRecords =!= {} && Module[
    {rec = First[v2LetterRecords], mutant, entry, expected},
    mutant = Append[rec, "Letter" -> rec["Letter"] + 1];
    entry = oneFormEntry[rec["OneForm"], mutant, rootRecords, {x, y}, eps,
      True];
    expected = fieldDecompose[#, rootRecords] & /@ rec["OneForm"];
    AssociationQ[entry] && entry["Path"] === "DecomposedForm" &&
      SameQ[entry["Channels"], expected]]];
check["A3 every package-built channel certificate reaches the compact compile \
route",
  v2LetterRecords =!= {} && AllTrue[v2LetterRecords, Function[rec,
    Module[{entry = oneFormEntry[rec["OneForm"], rec, rootRecords, {x, y},
        eps, True]},
      AssociationQ[entry] && entry["Path"] === "CompactLetterChannels" &&
        SameQ[entry["Channels"], rec["DLogChannels"]]]]]];
check["A3 the dlog batch closes only the helper kernels it launched",
  SameQ[kernelsAfterCandidate, kernelsBeforeCandidate]];
letterDataSerial = candidateLetters[record["Strip"], rootRecords, {x, y}, eps,
  record, "RegulatorSampleCount" -> 2, "DLogKernels" -> 1];
check["A3 serial and selected dlog construction are byte-identical",
  SameQ[letterDataSerial, letterData]];
check["A3 invalid dlog kernel counts are refused before construction, typed",
  Lookup[candidateLetters[record["Strip"], rootRecords, {x, y}, eps, record,
      "DLogKernels" -> 0], "Status", None] === "InvalidDLogKernelCount" &&
    Lookup[candidateLetters[record["Strip"], rootRecords, {x, y}, eps, record,
      "DLogKernels" -> 9], "Status", None] === "InvalidDLogKernelCount"];
check["A3 a diagonal record carries no certificate (it is not a dlog)",
  AllTrue[Select[letterData["LetterRecords"],
      Lookup[#, "Kind", None] === "Diagonal" &],
    MissingQ[Lookup[#, "DLogCertificate", Missing[]]] &]];

(* ================================================================== *)
(* K  THE ONE-FORM POOL KEY: ROUTE AND LETTER PROVENANCE                *)
(* ================================================================== *)

keyPrefix = {Symbol["FeynFacet`Private`$multiquadraticStripSourceSHA256"],
  {x, y}, eps, Lookup[rootRecords, "Root", {}],
  Lookup[rootRecords, "RootSquare", {}]};
compactKey = oneFormKeyOf[keyPrefix, goodForm, goodRecordWithTag, True,
  Automatic, "CertifiedOrExact", {x, y}, eps];
decomposedKey = oneFormKeyOf[keyPrefix, goodForm, goodRecordWithTag, False,
  Automatic, "CertifiedOrExact", {x, y}, eps];
otherLetterKey = oneFormKeyOf[keyPrefix, goodForm, wrongRecord, True,
  Automatic, "CertifiedOrExact", {x, y}, eps];

check["K the SAME one-form under the two routes gets two different keys",
  compactKey =!= decomposedKey];
check["K the SAME one-form with a different letter provenance gets a \
different key",
  compactKey =!= otherLetterKey];
check["K the letter provenance hash is stable and record-specific",
  letterProvenance[goodRecordWithTag, {x, y}, eps] ===
      letterProvenance[goodRecordWithTag, {x, y}, eps] &&
    letterProvenance[goodRecordWithTag, {x, y}, eps] =!=
      letterProvenance[wrongRecord, {x, y}, eps] &&
    letterProvenance[None, {x, y}, eps] === "NoLetterRecord"];

clearCaches[];
compactEntry = intern["OneForm", compactKey,
  Function[oneFormEntry[goodForm, goodRecordWithTag, rootRecords, {x, y},
    eps, True]]];
check["K a route flip MISSES the other route's entry",
  ! MissingQ[internProbe["OneForm", compactKey]] &&
    MissingQ[internProbe["OneForm", decomposedKey]]];
decomposedEntry = intern["OneForm", decomposedKey,
  Function[oneFormEntry[goodForm, goodRecordWithTag, rootRecords, {x, y},
    eps, False]]];
check["K the two entries record the two different routes",
  compactEntry["Path"] === "CompactLetterChannels" &&
    decomposedEntry["Path"] === "DecomposedForm"];
clearCaches[];

(* ================================================================== *)
(* G  THE COMPACT-ROUTE GRADE GATE                                      *)
(* ================================================================== *)

(* A letter whose dlog occupies a grade the declared set excludes.  NOT
   the bare root: dlog(r_a) = (1/2) dlog(delta_a) is purely RATIONAL and
   sits in grade 0 alone, which would test nothing.  1 + r_2 has
   (1 + r_2)^-1 = (1 - r_2)/(1 - delta_2), so its dlog occupies the grade
   of r_2 as well. *)
gradeLetter = 1 + Lookup[rootRecords, "Root", {}][[2]];
gradeForm = letterOneForm[gradeLetter, {x, y}];
gradeRecord = <|"Kind" -> "Algebraic", "Letter" -> gradeLetter,
  "OneForm" -> gradeForm,
  "DLogCertificate" -> dlogCertificate[gradeLetter, gradeForm, {x, y}, eps]|>;
gradeChannels = mq["multiquadraticStripLetterChannelPair"][gradeLetter,
  rootRecords, {x, y}];
gradeOccupied = If[MatchQ[gradeChannels, {_List, _List}],
  gradeSupportOf[gradeChannels], $Failed];
note["G the letter's dlog occupies grade masks", gradeOccupied];
check["G the fixture letter's dlog really leaves the restricted set",
  ListQ[gradeOccupied] && ! SubsetQ[{0, 1}, gradeOccupied]];

check["G with the full grade set the letter compiles",
  Module[{entry = oneFormEntry[gradeForm, gradeRecord, rootRecords, {x, y},
      eps, True, Automatic, "CertifiedOrExact"]},
    AssociationQ[entry] && ! KeyExistsQ[entry, "Status"]]];

check["G with a RESTRICTED grade set the compact route refuses typed",
  Module[{entry = oneFormEntry[gradeForm, gradeRecord, rootRecords, {x, y},
      eps, True, {0, 1}, "CertifiedOrExact"]},
    AssociationQ[entry] &&
      Lookup[entry, "Status", None] === "CompactLetterGradeSupportExceeded" &&
      ListQ[entry["GradeSupport"]] &&
      entry["AdmissibleGradeSupport"] === {0, 1}]];

check["G the refusal reaches the compiler as a typed failure naming the \
letter",
  Module[{preparation = prepare[record, frame, "OneForms" -> {gradeForm},
      "LetterRecords" -> {gradeRecord}, "GaugeDenominator" -> denominator,
      "Support" -> support, "RootIndices" -> {1, 2}], assembly},
    If[Lookup[preparation, "Status", None] =!=
        "PreparedMultiquadraticStripV1", False,
      assembly = compile[preparation, "PreparationValidated" -> True,
        "LetterGradeSupport" -> {0, 1}];
      Lookup[assembly, "Status", None] ===
          "CompactLetterGradeSupportExceeded" &&
        assembly["LetterIndex"] === 1]]];

check["G an out-of-range grade set is a caller error, not a refusal",
  Lookup[compile[goodPreparation, "PreparationValidated" -> True,
    "LetterGradeSupport" -> {0, 99}], "Status", None] ===
    "InvalidLetterGradeSupport"];
check["G an unknown admission mode is a caller error",
  Lookup[compile[goodPreparation, "PreparationValidated" -> True,
    "CompactDLogAdmission" -> "Guess"], "Status", None] ===
    "InvalidCompactDLogAdmission"];
clearCaches[];

(* ================================================================== *)
(* R  RANK-3 RECURSIVE TOWER INVERSION                                  *)
(* ================================================================== *)

Clear[tx, ty];
deltas2 = {tx, 1 - ty};
deltas3 = {tx, 1 - ty, 1 + tx ty};

element2 = {1 + tx, 2 ty, 3, 1 - tx ty};
element3 = {1 + tx, 2 ty, 3, 1 - tx ty, ty, 1 + tx + ty, 2, tx - 3 ty};

towerCheck[element_, deltas_, label_String] := Module[
  {towerSeconds, tower, solveSeconds, solved, identity},
  {towerSeconds, tower} = AbsoluteTiming[inverseTower[element, deltas]];
  {solveSeconds, solved} = AbsoluteTiming[
    inverseLinearSolve[element, deltas]];
  identity = If[ListQ[tower],
    Together /@ (multiply[element, tower, deltas] -
      UnitVector[Length[element], 1]), $Failed];
  note[label <> " tower / linear-solve seconds",
    {Round[towerSeconds, 0.001], Round[solveSeconds, 0.001]}];
  check[label <> " the tower inverse satisfies the exact product identity",
    ListQ[tower] && ListQ[identity] && AllTrue[identity, TrueQ[# === 0] &]];
  check[label <> " the tower inverse is EXACTLY the linear-solve inverse",
    ListQ[tower] && ListQ[solved] &&
      AllTrue[Together /@ (tower - solved), TrueQ[# === 0] &]];
  {towerSeconds, solveSeconds}];

towerCheck[element2, deltas2, "R rank 2:"];
rank3Seconds = towerCheck[element3, deltas3, "R rank 3:"];
note["R rank-3 speedup (tower vs linear solve)",
  Round[Last[rank3Seconds]/Max[First[rank3Seconds], 10.^-6], 0.01]];

check["R the default inverse route is the recursive tower",
  Symbol["FeynFacet`Private`$multiquadraticFieldInverseMethod"] ===
    "RecursiveTower"];
check["R the public inverse agrees with both routes on the rank-3 element",
  AllTrue[Together /@ (fieldInverse[element3, deltas3] -
    inverseLinearSolve[element3, deltas3]), TrueQ[# === 0] &]];
(* tx + 1 . r with r^2 = tx^2 has norm tx^2 - tx^2 = 0: a genuine zero
   divisor of the quadratic ALGEBRA (which is not a field when the
   radicand is already a square) *)
check["R a zero divisor is refused by both routes",
  Module[{zeroDivisor = {tx, 1}, dd = {tx^2}},
    inverseTower[zeroDivisor, dd] === $Failed &&
      inverseLinearSolve[zeroDivisor, dd] === $Failed &&
      fieldInverse[zeroDivisor, dd] === $Failed]];
check["R a rank-0 element inverts in one division",
  inverseTower[{3 tx}, {}] === {1/(3 tx)}];

(* ================================================================== *)
(* B  BYTE-BOUNDED POOLS WITH AN OVERSIZE BYPASS                        *)
(* ================================================================== *)

clearCaches[];
intern["OneForm", {"probe", 1},
  Function[<|"Channels" -> {{1, 0, 0, 0}, {0, 1, 0, 0}},
    "Compiled" -> {1, 2}, "Path" -> "DecomposedForm"|>]];
poolStatistics = internStatistics[];
check["B the pool reports measured Bytes alongside its entry count",
  KeyExistsQ[poolStatistics, "OneForm"] &&
    NumericQ[poolStatistics["OneForm"]["Bytes"]] &&
    poolStatistics["OneForm"]["Bytes"] > 0 &&
    poolStatistics["OneForm"]["Entries"] === 1];

bigValue = <|"Channels" -> Table[k, {k, 20000}], "Compiled" -> {},
  "Path" -> "DecomposedForm"|>;
oversizeResult = Block[
  {FeynFacet`Private`$multiquadraticStripPoolOversizeBytes =
    <|"OneForm" -> 1000.|>},
  intern["OneForm", {"probe", 2}, Function[bigValue]]];
check["B an OVERSIZE value bypasses the pool: it is returned, not stored",
  SameQ[oversizeResult, bigValue] &&
    MissingQ[internProbe["OneForm", {"probe", 2}]]];
check["B the oversize bypass leaves the entry the pool already holds",
  ! MissingQ[internProbe["OneForm", {"probe", 1}]] &&
    internStatistics[]["OneForm"]["Entries"] === 1 &&
    internStatistics[]["OneForm"]["Oversize"] === 1 &&
    internStatistics[]["OneForm"]["Resets"] === 0];

(* the ceiling is set from the pool's MEASURED size, so the next value
   cannot fit whatever its own byte count turns out to be *)
byteCeiling = internStatistics[]["OneForm"]["Bytes"] + 1;
byteResetResult = Block[
  {FeynFacet`Private`$multiquadraticStripPoolByteLimit =
     <|"OneForm" -> byteCeiling|>,
   FeynFacet`Private`$multiquadraticStripPoolOversizeBytes =
     <|"OneForm" -> 10.^9|>},
  intern["OneForm", {"probe", 3},
    Function[<|"Channels" -> Table[k, {k, 40}], "Compiled" -> {},
      "Path" -> "DecomposedForm"|>]]];
note["B pool byte ceiling used", byteCeiling];
check["B the pool byte ceiling resets the pool rather than growing past it",
  AssociationQ[byteResetResult] &&
    internStatistics[]["OneForm"]["Resets"] === 1 &&
    MissingQ[internProbe["OneForm", {"probe", 1}]] &&
    ! MissingQ[internProbe["OneForm", {"probe", 3}]]];

check["B a typed REFUSAL is never interned (a refusal is a negative \
result)",
  Module[{before, after},
    clearCaches[];
    before = internStatistics[];
    intern["OneForm", {"probe", 4},
      Function[<|"Status" -> "CompactLetterGradeSupportExceeded"|>]];
    after = internStatistics[];
    MissingQ[internProbe["OneForm", {"probe", 4}]] &&
      after["OneForm"]["Rejected"] === 1 &&
      after["OneForm"]["Entries"] === 0]];
check["B the OneForm validity predicate demands the compiled schema",
  ! TrueQ[internValidQ["OneForm", <|"Channels" -> {}|>]] &&
    ! TrueQ[internValidQ["OneForm", $Failed]] &&
    TrueQ[internValidQ["OneForm",
      <|"Channels" -> {}, "Compiled" -> {}, "Path" -> "DecomposedForm"|>]]];
clearCaches[];

Print["t_multiquadratic_provenance: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
