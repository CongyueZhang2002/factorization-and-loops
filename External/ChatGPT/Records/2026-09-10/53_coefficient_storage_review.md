# GPT-6 Pro: coefficient storage review

Review a persistent final coefficient read-back failure. All actual reconstruction jobs are finished and their 2,130 finite-field checks pass. The complete mixed result passes the result assembler and ReadMasterIntegralCoefficients before writing.

Plain Put/Get then SameQ failed. Replacing the writer with the shared neutral-context FamilyArtifactWrite[Compression->True] and FamilyArtifactRead also fails SameQ on the full record, though a small held-signature/context regression passes. Full assembled result is about 120 MB plain text/31.7 MB compressed text. The original in-memory values were not preserved from those first attempts; a new run now saves a binary WXF candidate and reports differing top-level keys. No failed writer output has been published.

Please inspect the attached four implementations for a concrete evaluation/scoping/read-back bug. In particular check whether coefficientWriteFinalResult's input pattern or FamilyArtifactRead can change a caller-owned global such as result; exact/Laurent proof metadata and held signatures; unevaluated metadata from dynamic reconstruction records; or context normalization. Do not suggest accepting an unchecked change in mathematical data. We will have actual differing-key diagnostics shortly. If needed recommend the minimal diagnostic that captures the original versus re-read structure without repeating assembly.

Separately, final physical-variable validation was bottlenecked in full Factor: one actual 1,977,278-leaf coefficient exceeded 45 s; exact CancelRationalCoefficients took 1.807 s. Production now uses exact cancellation and all 16 physical-variable tests pass. A failed imaginary-prefactor test was fixed by mapping all rational complex constants through one I generator; 12 rational arithmetic tests pass. Nine file-based cut/catalog producer-consumer tests pass.

The exact/Laurent source bindings, emitted contribution ownership, label-collision checks and accepted-frame correspondence from review 52 have been implemented. No new endpoint mathematics is requested. Working changes not pushed: https://github.com/CongyueZhang2002/factorization-and-loops .


There is no caller-aliasing bug in the displayed result_Association pattern. There are definite diagnostic and writer-path defects, but the source alone does not yet identify the expression causing the full-record mismatch. The next step should distinguish changed serialized structure from evaluation of faithfully recovered structure, using the candidate already saved—not another assembly.

1. The pattern does not assign to the caller; the recovered payload can execute

coefficientWriteFinalResult receives the evaluated association through a pattern substitution. It contains no assignment to that parameter. Naming it result does not create a reference to Global\result`; changing the parameter name would not fix this failure. WL delayed definitions scope their pattern variables independently of global variables. 

53_coefficient_storage

 
Wolfram Documentation Center

Likewise, FamilyArtifactRead assigns its result to Module-local value and messages. Its only explicit persistent assignment is $familyArtifactReadMessages. It does not explicitly assign to result. 

53_coefficient_storage

However, the compressed writer emits:

Wolfram Language
Uncompress["..."]

and the reader executes that expression. One-argument Uncompress evaluates the recovered expression. The neutral $Context/$ContextPath settings govern symbol resolution; they do not remove existing definitions or make the payload inert. Thus escaped runtime expressions or effectful metadata can change during reading, and could modify globals through their own evaluation. This is a possible mechanism, not yet a demonstrated cause in your result. 

53_coefficient_storage

 
Wolfram Documentation Center

2. The current mismatch diagnostic does not preserve both compared structures

Two concrete weaknesses:

“Expected” is saved too late. The writer exports .expected.wxf only after FamilyArtifactRead and the mismatch comparison. If reading changed definitions affecting the expected expression, that file is not a reliable pre-read snapshot. Your new driver’s .assembled.wxf, written before calling the writer, is the correct recovery point. 

53_coefficient_storage +1

The evaluated readback is not saved. The diagnostic points to the compressed text file, but rereading it executes it again. Preserve the actual evaluated association from the failing comparison under HoldComplete, immediately.

Also, the differing-key calculation scans only Keys[result]: it misses keys appearing only in the readback. Record both key lists and compare their union. Ordinary result[key]/Lookup can also evaluate delayed association values, so inspect differences with held extraction rather than repeatedly evaluating metadata. 

53_coefficient_storage

 
Wolfram Documentation Center

3. Minimal diagnostic using the existing files

Read the candidate WXF without evaluating its payload, and separately decompress the failed text artifact under a hold. Both BinaryDeserialize[...,HoldComplete] and Uncompress[...,HoldComplete] support this directly. Wrapping HoldComplete around an ordinary Get result afterward is too late to inspect the pre-evaluation payload. 
Wolfram Documentation Center
+1

The following diagnostic targets the exact compressed-wrapper format in the attachment. It performs no reconstruction or assembly:

Wolfram Language
Clear[coefficientReadbackDiagnostic];

coefficientReadbackDiagnostic[candidate_String, failed_String] :=
 Module[{expected, wrapper, stored, actual, before, after, messages},

  expected = BinaryDeserialize[ReadByteArray[candidate], HoldComplete];

  wrapper = Block[
    {$Context = "Global`", $ContextPath = {"System`", "Global`"}},
    ToExpression[ReadString[failed], InputForm, HoldComplete]
  ];

  If[!MatchQ[wrapper, HoldComplete[System`Uncompress[_String]]],
    Return[Failure["UnexpectedArtifactWrapper", <||>]]
  ];

  stored = Block[
    {$Context = "Global`", $ContextPath = {"System`", "Global`"}},
    Replace[wrapper,
      HoldComplete[System`Uncompress[s_String]] :>
        System`Uncompress[s, HoldComplete]]
  ];

  If[!MatchQ[expected, HoldComplete[_Association]] ||
     !MatchQ[stored, HoldComplete[_Association]],
    Return[Failure["HeldCoefficientRecordsRequired", <||>]]
  ];

  before = OwnValues[Global`result];
  actual = With[{v = FeynFacet`FamilyArtifactRead[failed]},
    HoldComplete[v]];
  messages = FeynFacet`Private`$familyArtifactReadMessages;
  after = OwnValues[Global`result];

  <|
    "CandidateMatchesStoredStructure" -> SameQ[expected, stored],
    "ReadingPreservesStoredStructure" -> SameQ[stored, actual],
    "CallerResultOwnValueUnchanged" -> SameQ[before, after],
    "ReadMessages" -> messages,
    "ExpectedHeld" -> expected,
    "StoredHeld" -> stored,
    "ActualHeld" -> actual
  |>
]

Save this returned diagnostic as WXF without releasing its held fields. I have not executed this code in a Wolfram kernel here.

Interpretation:

Candidate equals stored; stored differs from actual: the two artifacts agree structurally, and evaluation during reading changes the record.

Candidate differs from stored: investigate the first structural difference between the two encodings—or a change between their write times. Do not immediately blame evaluation or context.

Caller’s OwnValue changes: there is an actual assignment side effect. Locate it in the evaluated payload or invoked definitions, rather than changing the writer’s pattern name.

For a reported key, compare, for example,

Wolfram Language
Extract[expectedHeld, {1, Key["FiniteFieldReconstruction"]}, HoldComplete]

against the corresponding stored/actual subtree. Descend only through differing subtrees and print the smallest discrepancy with explicit contexts. Extract’s third argument prevents evaluation of extracted contents. 
Wolfram Documentation Center

4. Where to inspect metadata—and what not to “normalize away”

The constructor retains most non-core fields from the raw reconstruction record. The term reader checks the arithmetic coefficient representation and carries LaurentRemainderClass forward, but that does not establish evaluation stability of its entire justification. Therefore, passing ReadMasterIntegralCoefficients is compatible with a serialization problem confined to reconstruction/proof metadata. 

53_coefficient_storage +1

If the first discrepancy is there, inspect for an escaped local symbol, unresolved Lookup/Part, delayed association value, or helper expression that depended on a producing Block. These are diagnostic candidates, not defects established by the supplied code. Fix the identified producer to store its actual intended data; do not globally ReleaseHold, evaluate every proof record, or delete metadata to obtain equality.

The regulator normalizer is explicitly name-based and traverses the whole record. It can change symbols in held metadata, but it is not called by FamilyArtifactRead or this writer’s comparison, so it does not directly explain this raw round-trip failure. Similarly, comparing via the semantic reader would introduce its deliberate "Source" update; use the raw reader for serialization equality. 

53_coefficient_storage +2

5. Two remaining writer fixes, independent of the mismatch

The project entry point still bypasses the shared writer. coefficientRunProject uses plain Put/Get, deletes its failed diagnostic temporary, and deletes an existing published result before renaming the new file. Route it through the corrected shared publication path. This is present in the snapshot but does not explain the scheduled CLI’s compressed-read failure. 

53_coefficient_storage

FamilyArtifactWrite returns the requested filename regardless of intermediate write/rename failures. Check stream creation, writing/closing and rename results. The final coefficient wrapper’s existence and equality checks currently provide additional protection, but the shared writer’s return value alone does not indicate success. Also check the diagnostic candidate’s Export result before reporting it saved. 

53_coefficient_storage +1

Keep strict equality as the publication gate. The decisive next evidence is the first difference among the held candidate, held compressed payload and held evaluated readback—not another serializer substitution or another coefficient assembly.