# Adversarial review of branch `overhaul` (base 2d73f71f) -- 2026-09-02

Read-only. Work tree: `.../scratchpad/work`, baseline checkout `.../scratchpad/base`.
Ratings: DEFECT = concrete failing input; RISK = plausible, not demonstrated; NOTE.

---

## D1 DEFECT -- the new load order empties `Options[SolveEpsFormStripInFrame]`; the finite-field strip solver writes its artifacts to a relative `ScratchDirectory/Tag_finite_field`

`FeynFacet/Private/LoadOrder.wl:24-25` puts the whole **Geometry** layer
(`TransportCharts.wl`) *before* the **EpsForm** layer, which holds
`EpsFormStrip.wl`. In the baseline (`base/FeynFacet/FeynFacet.m:396-410`)
`EpsFormStrip.wl` was file 15 and `TransportCharts.wl` file ~29.

`FeynFacet/Private/Geometry/TransportCharts.wl:1747-1748`

```
Options[SolveEpsFormStripInFrame] = Join[
  Options[SolveEpsFormStrip], {...11 new options...}];
```

`Options[SolveEpsFormStrip]` is set at `FeynFacet/Private/EpsForm/EpsFormStrip.wl:1204-1220`
(15 options), i.e. **after** this line now runs. It therefore evaluates to `{}`
and all 15 inherited options are lost: `CANONICANumeratorDegrees`,
`CANONICADenominatorDegree`, `CANONICATimeLimit`, `CANONICAKernels`,
`MapleExecutable`, `MapleLibrary`, `MapleTimeLimit`, `MapleMethodTimeLimit`,
`MapleResidueKernels`, `MapleLetterDenominatorPowers`,
`MapleNumeratorDegreeOffsets`, `UseMaple`, `ScratchDirectory`, `Tag`, `Verbose`.

They are read on the **main path of every call** (after the ZeroForcing early
return at `TransportCharts.wl:2024-2033`):

- `:2034` `optionRules = FilterRules[{opts}, Options[SolveEpsFormStrip]]` -> always `{}`
- `:2041` `canonicalKernelCount = OptionValue["CANONICAKernels"]`
- `:2042` `scratchDirectory = OptionValue["ScratchDirectory"]`
- `:2043` `stripTag = OptionValue["Tag"]`
- `:2044` `verbose = OptionValue["Verbose"]`
- `:2446-2451` `MapleExecutable`, `MapleCanonicalCacheDirectory`, `MapleTimeLimit`

`OptionValue` on a name absent from `Options[f]` issues `OptionValue::nodef` and
returns the option *name*. So `scratchDirectory === "ScratchDirectory"` and
`stripTag === "Tag"`, and `:2069-2078`

```
directory = Replace[scratchDirectory, {
  Automatic  :> FileNameJoin[{$TemporaryDirectory,"FeynFacetFiniteField",stripTag}],
  value_String :> FileNameJoin[{value, stripTag <> "_finite_field"}]}];
... "ArtifactDirectory" -> directory, "ArtifactPrefix" -> stripTag,
    "KernelCount" -> canonicalKernelCount, "Verbose" -> verbose
```

takes the `value_String` branch: a **relative** directory
`ScratchDirectory/Tag_finite_field` under the kernel's cwd, prefix `"Tag"`,
`"KernelCount" -> "CANONICAKernels"`.

**Evidence already in the work tree** (base has none of it):

```
work/ScratchDirectory/Tag_finite_field/
work/Tests/Infrastructure/ScratchDirectory/Tag_finite_field/Tag_mod_1000003.wl
                                                           Tag_mod_2147483423.wl
                                                           Tag_mod_2147483477.wl
work/Tests/Multiquadratic/ScratchDirectory/Tag_finite_field/Tag_mod_1000003.wl
```

created 2026-09-02 06:07-06:21. The names match
`FeynFacet/Private/EpsForm/FiniteFieldStripSolve.wl:3428`
(`artifactPrefix <> "_mod_" <> ToString[prime] <> ".wl"`), which pins
`artifactPrefix === "Tag"` and `scratchDirectory === "ScratchDirectory"`.
The branch's response was to add `.gitignore:136-137`
(`Tests/**/ScratchDirectory/`) in this same diff -- the symptom is hidden, not fixed.

`FeynFacet/FeynFacet.m:181` still asserts "Options[SolveEpsFormStrip] remains the
option set the in-frame solver filters"; that is now false.
`Scripts/family_epsform_sector.wls:1464-1473` passes `"MapleTimeLimit"`,
`"ScratchDirectory"`, `"Tag"`, `"Verbose"` explicitly to
`SolveEpsFormStripInFrame` -- every production call now also emits
`OptionValue::nodef` for undeclared options.

Concrete input: `Options[SolveEpsFormStripInFrame]` after loading the package
returns 11 entries instead of 26; any `SolveEpsFormStripInFrame[strip,{x,y},eps,frame]`
with nonzero `bbar` and no explicit `"ScratchDirectory"` writes to
`<cwd>/ScratchDirectory/Tag_finite_field/`.

A scan of every top-level `Options[X] = ... Options[Y] ...` in the manifest order
found exactly one such cross-file inheritance that now resolves late; every other
`Options` join (`FiniteFieldEpsForm.wl:55`, `DiagonalBlockEpsForm.wl:1476`,
`FiniteFieldGaugePullBack.wl:1232`, `FamilyRegulatorFactor.wl:270`,
`MultiquadraticStripSolve.wl:4106/4997/5210/16394`, `MasterTransport.wl:5374`,
`TaskBroker.wl:227`, `PathTransportNative.wl:1195`,
`ObservableTransportFiniteField.wl:73/76/96`) is intra-file or earlier-layer.

---

## D2 DEFECT -- KernelPool mission isolation unsets `poolRun`'s own locals `r` and `hadMessages`, destroying every mission's recorded result

`Scripts/KernelPool.wls:116-119` -- the `Module` local list is
`{s, r, t0, status, missionText, missionParseContext, missionGlobalBefore,
missionNewGlobal, missionParsed, missionParseFailed, missionParseCleanup,
nMsg0, hadMessages}`. `missionOwnValued`, `missionOwnBefore`, `missionLeaked`
are **not** in it (plain `Global`` symbols).

`:225-230` (before the mission)

```
missionOwnValued := Select[
  (If[StringContainsQ[#,"`"], #, "Global`"<>#]&) /@ System`Names["Global`*"],
  StringStartsQ[#,"Global`"] && ! StringStartsQ[#,"Global`$"] &&
    System`ToExpression[#, InputForm, System`OwnValues] =!= {} &];
missionOwnBefore = missionOwnValued;
```

`Module` interns **all** its locals (`Global`r$n`, `Global`hadMessages$n`, ...) at
entry, so `Names["Global`*"]` sees them in *both* scans -- that symmetry is what
makes the pre-existing parse gate at `:181-187` safe. The new `Select` breaks it:
the predicate is *has an own value*, and

- `r` gets its own value only at `:228` (`r = Block[...]`),
- `hadMessages` only at `:247`.

Both therefore appear in the after-scan and not in the before-scan, so
`:251-256`

```
missionLeaked = If[Environment["FACET_POOL_ISOLATION"]==="0", {},
  Complement[missionOwnValued, missionOwnBefore]];
If[missionLeaked =!= {},
  Scan[System`ToExpression[#, InputForm, System`Unset]&, missionLeaked]; ...]
```

unsets `Global`r$n` and `Global`hadMessages$n`. They are read afterwards at
`:274-279`:

```
Put[<|"Mission"->..., "Status"->status, "HadMessages"->hadMessages,
      "Wall"->..., "Kernel"->$KernelID,
      "Result"->If[ByteCount[r]<20000, r, Short[r]]|>, kernelFile<>".result"];
...
<|... "HadMessages"->hadMessages, ..., "Result"->If[ByteCount[r]<20000, r, Short[r]]|>
```

Concrete input: submit any mission whose file ends in a value, e.g.
`Print["hi"]; 42`. The `.result` sidecar and the collected record carry
`"Result" -> r$1234` and `"HadMessages" -> hadMessages$1234` (bare Temporary
symbols) instead of `42` and `False`, and the mission log prints
`MISSION isolation: unset 2 leaked Global` values r$1234, hadMessages$1234`
even when the mission leaked nothing. `"Status"`, `"Wall"`, `"Kernel"` survive
(`status`, `t0`, `s` already had own values at the before-scan), so the
DUPLICATE-recovery path at `:543-549` still reads the right verdict -- the loss is
the mission's return value and its message flag, plus permanent log noise.

This code has never run: none of `scratchpad/kernelpool*/poolrun_definition.m`
contains `missionOwnValued`.

Also note `missionOwnBefore` itself is leaked-and-unset on the first mission of
each kernel (harmless -- already consumed), which is only self-consistent by
accident.

Cheapest fixes: declare the three names as `Module` locals **and** compute
`missionLeaked` after the `Put`/return value are formed, or exclude names ending
in `$` + digits from the leak set.

---

## D3 DEFECT -- `Tests/Infrastructure/t_canonica_scheduler.wls` calls two symbols that were moved to `Private_Backup`

`Tests/Infrastructure/t_canonica_scheduler.wls:23`
`result = FeynFacet`Private`epsFormStripRunCanonica[strip, {testX,testY}, testEpsilon, alphabet, {0,1}, 1, 20, schedulerKernels]`
and `:32`
`TrueQ[FeynFacet`Private`epsFormStripExactDLogQ[#["Gauge"], strip, {testX,testY}, testEpsilon, alphabet]]`.

Both definitions now live only in `FeynFacet/Private_Backup/EpsFormStrip.wl:50`
and `:8`; `FeynFacet/Private/EpsForm/EpsFormStrip.wl` retains only the `ClearAll`
entries at `:25` and `:31-32` (`epsFormStripRunCanonicaOne` at `:1160` is a
*different* symbol and is still live). The call stays unevaluated, so
`AssociationQ[result]` is `False` and all three checks are `False`.

Concrete input: `wolframscript -f Tests/Infrastructure/t_canonica_scheduler.wls`
-> `<|"Association"->False,"ExactCandidate"->False,"MinimalDegree"->False|>`, exit 1.
The test is in the suite: `Scripts/run_tests_pool.sh:60` lists it under
`standalone_only`, i.e. it is run standalone after the pool drains.

`FeynFacet/Private_Backup/EVIDENCE.md` claims for this move only that
"`t_construction_budget` replaces it by a stand-in"; `t_canonica_scheduler` was
missed by the reference scan.

(Systematic scan: every `FeynFacet`Private`<name>` referenced from `Tests/` or
`Scripts/` was checked against the live definitions. These two are the only
overhaul-introduced breaks. `familyRowGaugeFF*` / `familyRowGaugeFiniteField*`
in `Tests/FiniteField/t_family_row_gauge_finite_field.wls` are undefined in the
**base** tree as well -- pre-existing, not this diff.)

---

## D4 DEFECT -- the adapter hash cache no longer detects a replaced binary

`FeynFacet/Private/EpsForm/FiniteFieldStripSolve.wl:172-190`

```
stamp = <|"AdapterBinary"->binary, "AdapterSource"->source,
  "BinaryBytes"->FileByteCount[binary], "BinaryDate"->FileDate[binary,"Modification"],
  "SourceBytes"->FileByteCount[source], "SourceDate"->FileDate[source,"Modification"]|>;
cached = Lookup[$finiteFieldStripCFFRAdapterHashCache, binary, None];
If[AssociationQ[cached] && Lookup[cached,"Stamp",None] === stamp,
  Return[Join[<|"Status"->"OK"|>, cached["Hashes"]]]];
```

The unchanged comment at `:152-156` still promises "computed once per session and
cached under the binary's path, **and re-checked on every discovery**: a binary
replaced mid-session is a typed failure". After this change nothing is re-hashed
when size and mtime match.

Concrete input: with `FeynFacet/Backends/flint/bin/flint_affine_rref` already
hashed once in a session,
`cp -p /elsewhere/flint_affine_rref FeynFacet/Backends/flint/bin/flint_affine_rref`
(equal byte count, preserved mtime), or any replacement followed by
`touch -r <old> <new>`, is accepted silently. `finiteFieldStripCFFRPlanBindingValidQ`
(`:385-408`) then validates sealed plans against the *old* hashes, which is
exactly the "plan that silently belongs to another executable" the check exists to
prevent. `FileDate` is second-resolution on Linux, so a same-size rebuild inside
one second also slips through.

The other two questions on this block are clean:

- **cache key relative vs absolute**: cannot diverge. `finiteFieldStripCFFRBinary[]`
  (`:139-141`) always returns `FileNameJoin[{$feynFacetDirectory, "Backends","flint","bin",...}]`,
  an absolute path from `ExpandFileName[$InputFileName]`.
- **source path from `feynFacetPrivateFile`** (`:272-274`): an improvement. The
  added `! StringQ[source]` guard means a standalone `Get` of the file (as
  `Tests/Infrastructure/t_broker_adaptive.wls:593` does), where
  `feynFacetPrivateFile` is undefined, returns the typed
  `<|"Status"->"BackendSourceUnavailable"|>` instead of the old `FileNameJoin`
  error on an undefined `$feynFacetPrivateDirectory`. A missing manifest cannot
  arise in a loaded package: `FeynFacet.m:414-417` aborts the load.
- The shape change of `$finiteFieldStripCFFRAdapterHashCache` (flat -> `<|"Stamp","Hashes"|>`)
  has exactly two readers, `:177` and `:393`, both updated.

---

## R1 RISK -- the prime/point filter ignores the numeric square classes `NormalizeRadicals` introduces

`FeynFacet/Private/Transport/ObservableTransportFiniteField.wl:530-535` and
`:731-736` accept a prime/point only when every **declared** root square is a
nonzero residue:

```
deltaValues = observableTransportFFEvaluateExpressions[rootCompiler, point, prime];
If[MemberQ[deltaValues, $Failed | 0] ||
   ! AllTrue[deltaValues, JacobiSymbol[#, prime] === 1 &], ... Continue[]];
```

The `{"SquareRootConstant", s}` nodes that `observableTransportFFNormalizeRadicals`
(`:389-402`) creates and the compiler emits (`:171-177`) are not in that test.
A non-residue `s` makes the evaluator return `$Failed` (`:220-221`), the matrix
value `$Failed`, and the attempt is charged to `rejections["MatrixPole"]`
(`:539`) or silently `Continue`d (`:739`). With `k` independent numeric classes
the per-attempt acceptance probability is `2^-k`, so the 128-attempt budget
(`:508`, `:710`) is exhausted for `k` around 8 and up, and the recorded reason
names a matrix pole instead of the real cause.

---

## R2 RISK -- `NormalizeRadicals` can re-route a declared radical onto a *different* root symbol, scrambling the sheet bookkeeping

`ObservableTransportFiniteField.wl:391-398`

```
scale[base_] := scale[base] = Module[{ratio, found = None},
  Do[If[! TrueQ[Together[q] === 0],
      ratio = Quiet[Check[Together[base/q], $Failed]];
      If[MatchQ[ratio,_Integer|_Rational] && TrueQ[ratio>0] && ratio =!= 1,
         found = {ratio, q}; Break[]]], {q, squares}];
  found];
```

When `ratio === 1` the loop does **not** stop; it keeps testing the remaining
declared squares. If the frame contains `q` and `q' = c q` with `c` a positive
**non-square** rational and `q'` earlier in `squares`, then `Sqrt[q]` is rewritten
as `Sqrt[1/c] Sqrt[q']` and `transportChartApplyRootBranches` binds it to root
symbol `q'`. Mathematically correct, but the entry now flips under the sheet sign
of `q'` instead of `q`, so the all-branch enumeration
(`:606-613`, `signs = Table[If[BitGet[mask,index-1]===1,-1,1], ...]`) tests the
wrong `2^k` family.

Reachable: `observableTransportFFAlgebraicRoots` (`:322-330`) de-duplicates with
`transportChartRootBranchScale`, which merges only **perfect-square** ratios
(`TransportCharts.wl:1545-1549`), so a declared set such as `{2 Delta, Delta}`
keeps both.

Related, lower severity: `observableTransportFFAlgebraicMatrixValue` (`:333-341`)
applies `transportChartApplyRootBranches` **without** `NormalizeRadicals`, so the
uncompiled path and the compiled path no longer accept the same matrices (the
uncompiled one degrades to `$Failed` rather than to a wrong number).

---

## R3 RISK -- unbounded `FactorInteger` inside the compiler

`ObservableTransportFiniteField.wl:383-388`

```
observableTransportFFSquareFreeSplit[c_] /; MatchQ[c,_Integer|_Rational] && c > 0 :=
 Module[{a = Numerator[c], b = Denominator[c], k = 1, sf = 1},
  Do[k *= f[[1]]^Quotient[f[[2]],2]; If[OddQ[f[[2]]], sf *= f[[1]]],
    {f, FactorInteger[a b]}]; {k/b, sf}];
```

The identity is right (`Sqrt[a/b] = (k/b) Sqrt[sf]`; `split[45]={3,5}`,
`split[8/9]={6/9,2}={2/3,2}`), but the rational whose square part is being
extracted is `Together[base/q]` from `:395`, i.e. whatever the specialization
leaves. A large rational makes `FactorInteger` run for an unbounded time inside a
compile step that has no deadline and no typed refusal.

---

## R4 RISK -- `epsFormFiniteFieldCombineLists` changed shape from "always a list" to "list or `$Failed`"

`FeynFacet/Private/EpsForm/FiniteFieldEpsForm.wl:111-112`

```
epsFormFiniteFieldCombineLists[lists_List, length_Integer, moduli_List] :=
  modularCRT[PadRight[#, length] & /@ lists, moduli];
```

`modularCRT` returns the **scalar** `$Failed`
(`FeynFacet/Private/Core/ModularArithmetic.wl:147`, `:141`, `:150`) on an
inconsistent system, a non-integer entry, a length mismatch, or a non-positive
modulus; the base body (`Table[ChineseRemainder[...], {index, length}]`) always
returned a list of `length`. `epsFormFiniteFieldCombineCoordinate` (`:114-127`)
stores the result under `"Numerator"` / `"Denominator"` without checking.

`FiniteFieldEpsForm.wl:363` catches it (`! FreeQ[liftedPairs, $Failed]`), but
`DiagonalBlockEpsForm.wl:955-960` then evaluates
`MapThread[Function[...], {$Failed, $Failed}]`, which emits `MapThread::list` and
leaves an unevaluated expression rather than a typed failure.

Not reachable with the callers' distinct primes: for coprime moduli the pairwise
pre-check at `ModularArithmetic.wl:128-132` is vacuous (`GCD` 1, `Mod[_,1]===0`)
and `ChineseRemainder` cannot fail. Latent only.

(The pre-check is also `O(k^2)` `Subsets`/`GCD` per coordinate -- 55 pairs for the
eleven-prime schedule, on coefficient lists that can be thousands long.)

---

## R5 RISK -- memoizing the multiquadratic ABI fingerprint defeats the guard it exists for

`FeynFacet/Private/Core/MultiquadraticAlgebra.wl:215-228`

```
$multiquadraticAlgebraABIFingerprintCache = None;
multiquadraticAlgebraABIFingerprint[] := Module[{probe, symbols, value},
  If[StringQ[$multiquadraticAlgebraABIFingerprintCache],
    Return[$multiquadraticAlgebraABIFingerprintCache]];
  ...
  If[! AllTrue[symbols, Context[#] === "System`" &], Return[$Failed]];
  value = Hash[ToString[InputForm[probe]], "SHA256", "HexString"]; ...]
```

The comment claims "A failed probe is not memoized, so a context problem stays
visible", but that holds only if the context problem exists at the **first** call.
The check exists precisely because `ToString[InputForm[...]]` depends on the
reader's `$ContextPath` ("package bug handoff 2026-08-23, pool defect 3"); after a
package that shadows a probe symbol is loaded later in the session -- the
documented `CANONICA`` hazard, `FeynFacet.m:225` -- the stale hash is returned and
the comparisons at `MultiquadraticStripSolve.wl:6732`, `:8179`, `:8331` pass on an
ABI text that has changed. This matters most on the reused pool subkernels, where
one mission's context changes persist into the next.

---

## R6 RISK -- `multiquadraticSquareRoots` lost its `p == 3 (mod 4)` condition; the ABI now rests entirely on the callers

`FeynFacet/Private/Core/MultiquadraticAlgebra.wl:172-173`

```
multiquadraticSquareRoots[values_List, p_Integer?Positive] := modularSquareRoots[values, p];
```

Base (`base/FeynFacet/Private/MultiquadraticAlgebra.wl`) carried
`/; Mod[p, 4] == 3`, so a prime `1 (mod 4)` left the call **unevaluated** and no
caller's `rootValues === $Failed` test fired -- equally broken, differently.
Now real roots come back with the Tonelli-Shanks representative
(`ModularArithmetic.wl:279-282`), which is a different sign convention from the
raw `(p+1)/4` exponentiation that the file's own comment (`:167-170`) calls "part
of the ABI". Every current caller still gates independently
(`MultiquadraticStripSolve.wl:3628, 4488, 8927, 9480, 9695`;
`ObservableTransportFiniteField.wl:517, 725, 940, 1079`;
`FamilyRegulatorFactor.wl:1246`), and the four call sites that do **not** re-check
locally (`MultiquadraticStripSolve.wl:8712, 9522, 13555, 13796/13834`) sit behind
those gates -- so nothing is broken today, but the guarantee moved out of the
primitive.

Strictness in the other direction improved: a composite `p == 3 (mod 4)` (e.g.
`p = 21`) used to be accepted whenever the square check happened to pass and is
now rejected by `PrimeQ`; `p = 2` and non-list arguments now return `$Failed`
instead of staying unevaluated.

---

## Answers to the remaining task-2 questions (no defect found)

`observableTransportFFCompileExpressions:169-177` guards the numeric-radical branch
with `MatchQ[value[[1]], _Integer|_Rational] && TrueQ[value[[1]] > 0] &&
MatchQ[value[[2]], _Rational] && Denominator[value[[2]]] === 2`.

- **negative radicand** (`Sqrt[-3]`), **symbolic radicand** (`Sqrt[x-1]`),
  **nested radical** (`Sqrt[a + Sqrt[b]]`): all fall through to `True, $Failed`
  (`:179`); `observableTransportFFCompileMatrix` returns `$Failed` and
  `$observableTransportFFCompileFailure` names the first offending subexpression
  (`:426-433`). Typed refusal, no silent wrong answer. Zero radicand cannot reach
  the compiler (`0^(1/2)` auto-evaluates to `0`).
- **`Power[c, 3/2]` and `Power[c, -1/2]`**: handled correctly --
  `exponent = Numerator[value[[2]]]` becomes the outer integer power of
  `k * Sqrt[s]` (`:173-177`), and `evaluateRaw[{"Power", ...}]` (`:236-238`)
  refuses `base === 0` with a negative exponent.
- **rational radicand with a non-square-free denominator**: split correctly
  (`Sqrt[a/b] = (k/b) Sqrt[sf]`, `:383-388`). In practice WL's auto-simplification
  of `Sqrt` on rational literals means the branch usually already sees a
  square-free `c`.
- **k*Sqrt[s] vs the declared branch bookkeeping**: consistent.
  `observableTransportFFNormalizeRadicals` runs *first* (`:412-413`), so the
  declared square reaches `transportChartApplyRootBranches` as an exact match
  (scale 1) and the numeric factor carries **no** sheet sign -- multiplying the
  two roots of a declared square by one fixed nonzero constant still permutes
  them, so the `2^k` sheet enumeration stays complete. (The exception is R2.)
- **`modularSquareRoot` returning `$Failed` for a non-residue**: propagates as a
  **typed** failure, never as an unevaluated expression.
  `evaluateRaw[{"SquareRootConstant", s}]` returns `$Failed` (`:220-221`, `:256-258`),
  `Plus`/`Times`/`Power` short-circuit on `MemberQ[values,$Failed]` (`:226-238`),
  and `observableTransportFFMatrixValue` ends with `If[FreeQ[value,$Failed], value, $Failed]`
  (`:299-300`). The forward-mode evaluator is also correct: `Total` on the list of
  `{value, derivative}` pairs sums componentwise and `Mod` threads over the pair.

---

## NOTES

**N1** `multiquadraticSplitPointQ` (`MultiquadraticAlgebra.wl:161-162`) now delegates
to `modularSplitPointQ`, which reduces rational coefficients properly instead of
taking `Mod` of a `Rational` (a rational remainder). This changes which points are
accepted on inputs the old version accepted: `vars = {x,y}`, `radicands = {x}`,
`point = {1/2, 3}`, `p = 7` -- old: `JacobiSymbol[1/2,7]` unevaluated, `AllTrue`
`False`; new: `1/2 -> 4`, `JacobiSymbol[4,7] === 1`, `True`. It is a fix, but
`TrueQ[...]` also collapses `$Failed` (unevaluable radicand, bad modulus) to
`False`, indistinguishable from a genuine non-split point. No live caller: the
symbol appears only in its own `ClearAll` (`:34`) and in tests.

**N2 The consolidation is mostly unwired.** `ModularArithmetic.wl:4-12` lists as
"Consumers today" `epsFormFiniteFieldCombineCoordinate`, `epsFormFiniteFieldImageQ`,
`pathTransportNativeSplitPoints`, `diagonalBlockLiftFunction` and "the prime
schedules of FiniteFieldStripSolve.wl". `diff` against base shows
`PathTransportNative.wl` and `DiagonalBlockEpsForm.wl` are **byte-identical** to
the baseline; `epsFormFiniteFieldImageQ` still has its own body
(`FiniteFieldEpsForm.wl:129-134`); `FiniteFieldStripSolve.wl` has no
prime-schedule change. Of the twelve primitives, only
`modularRationalReconstruct`, `modularCRT`, `modularSquareRoot(s)` and
`modularSplitPointQ` have a live caller; `modularLift`, `modularImageQ`,
`modularEvaluateAt` (except via `modularSplitPointQ`), `modularResidueQ`,
`modularTonelliShanks` (except via `modularSquareRoot`), `modularSplitPoints` and
`modularPrimes` have **none** outside `Tests/FiniteField/t_modular_arithmetic.wls`.
Net today: +490 lines of new core with the old bodies still in place in two files.

**N3 `EVIDENCE.md` is stale on TaskBroker.** The moves table records
`taskBrokerCanonicaLadder` as moved ("only caller was the moved ladder"), but it
was restored to `FeynFacet/Private/Infrastructure/TaskBroker.wl:417` at 06:08
(see the note at `:410-414` and the placeholder
`FeynFacet/Private_Backup/TaskBroker.wl`) because
`Tests/Infrastructure/t_task_broker_limit.wls:77,89` drives it directly. The table
was not updated.

**N4 Dangling `ClearAll` entries for moved symbols** make them look live to a grep:
`EpsFormStrip.wl:25-26,32`; `CanonicalBlocks.wl:78`;
`FamilyCertificateModular.wl:34` (`familyCertMQEvaluateMatrix`);
`FiniteFieldStripSolve.wl:66` (`finiteFieldStripArtifactTag`);
`LibraEpsForm.wl:16-25` plus `SetAttributes[libraEpsFormTimed, HoldFirst]` at `:50`;
`MultiquadraticStripSolve.wl:164,317`; `ObservableTransport.wl:43-44`;
`PathTransportException.wl:33`.

**N5** `Scripts/Libra/LibraFamilyEpsFormWorker.wl:46` decides whether to load the
package with `Length[DownValues[FeynFacet`LibraFamilyEpsForm]] === 0`. The new
`RouteRetired` stub (`LibraEpsForm.wl:102`) **is** a `DownValue`, so the guard no
longer fires and the worker proceeds to call the retired route at `:140`.
(The `Get[FileNameJoin[{root,"Scripts","LibraFamilyEpsFormWorker.wl"}]]` in
`Scripts/Libra/libra_family_epsform.wls:11` is also wrong -- the worker is under
`Scripts/Libra/` and `root` is `DirectoryName[..., 3]` -- but that predates this diff.)

**N6 Mission isolation is partial and does not restore context.**
`Scripts/KernelPool.wls:225-256` clears only **own** values, so a mission's
`f[x_] := ...` down values, up values, attributes and `$`-prefixed `Global`
variables persist into the next mission on the same subkernel. A mission that
leaves `$Context` / `$ContextPath` changed is not restored either, so the next
mission's assignments land outside `Global`` entirely and the scan sees nothing.
`ToExpression[name, InputForm, OwnValues]` itself is safe (both `ToExpression`'s
third argument and `OwnValues` hold the expression, so a large own value is never
evaluated) and the `Unset` cannot reach another context (every entry is
`Global`-qualified by `:226`). Cost is `Names["Global`*"]` plus one `ToExpression`
parse per name, **twice** per mission. `Environment["FACET_POOL_ISOLATION"]` is read
on the subkernel, so it only takes effect for kernels launched after the variable
was set.

**N7 `FamilyCertificateModular.wl` aliases are behaviour-preserving.**
`familyCertRationalReconstruct` (`:536`) is identical to the base body on every
`Integer, Integer` input: the added `Abs[num] > bound` and
`Mod[num - a den, m] === 0` checks are loop invariants of the same extended
Euclidean scheme (`r_k <= bound` on exit, `r_k == t_k a (mod m)` throughout), and
the sign normalization does not change the `Rational` value. The only new refusal
is `modulus < 1`. `familyCertMQSquareRoot` (`:538-539`) now admits every odd
prime instead of only `p == 3 (mod 4)`, but all four sampling loops
(`:1141-1142, 1174-1175, 1203-1204, 1240-1241`) still do
`If[Mod[p,4] =!= 3 || ..., Continue[]]`, so no behaviour changes; zero is still
refused, as before. `p = 2` and composite moduli are refused by both versions.

**N8 Manifest hygiene is clean.** `LoadOrder.wl` lists 41 modules;
`FeynFacet/Private/*/` holds exactly those 41; no duplicates, no name in two
layers, nothing on disk unlisted. A scan of `FeynFacet/`, `Scripts/` and `Tests/`
found **no** remaining two-element `{"Private", "<file>.wl"}` path -- every
`FileNameJoin` hit carries its layer. Only stale prose remains
(`Tests/Multiquadratic/t_multiquadratic_strip_solve.wls:3`,
`t_multiquadratic_letters.wls:3`, `t_multiquadratic_gauge_ladder.wls:3`,
`t_multiquadratic_provenance.wls:3`, `t_construction_dag.wls:3`,
`t_multiquadratic_algebra.wls:3`, `t_multiquadratic_prepare_core.wls:3`,
`Tests/Transport/t_blockwise_transport.wls:3`,
`Tests/Core/t_family_artifact_read.wls:3`,
`FeynFacet/Private/Transport/MasterTransport.wl:4472`). Apart from D1, no
load-time forward reference exists: a scan of every top-level statement that is
not a `SetDelayed` found no use of a symbol defined in a later manifest file.

**N9** `modularPrimes` (`ModularArithmetic.wl:449-486`) behaves as documented on
the questions asked: `"Exclude"` and `"Residue3Mod4"` are applied in `acceptQ`
(`:466-468`), the descending walk stops at `2^(bits-1)`, and exhausting the
`200 count + 1000` candidate budget is a typed `$Failed`, never a short list
(`:485`). It has no production caller (N2).
