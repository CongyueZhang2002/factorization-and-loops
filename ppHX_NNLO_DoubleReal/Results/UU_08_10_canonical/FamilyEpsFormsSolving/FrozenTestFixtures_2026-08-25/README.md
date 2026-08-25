# Frozen test fixtures, 2026-08-25

Immutable copies of two family sector-state artifacts, taken so that the
acceptance suite stops reading **live campaign state**.

## Why this directory exists

`Tests/t_kallen_q4_chart.wls` (block T) and `Tests/t_radical_denesting.wls`
(block d) read
`FamilyEpsFormsSolving/triple_root_2026-08-24_fable/<family>/sector_state_<family>_standard.wl`
directly. Those files are **rewritten by every campaign mission**: the solve
advances a sector, writes the state, and the tests' inputs change underneath
them. On 2026-08-25 that produced a red suite with no code change — the
CF259 state had advanced from a rows-1..16 stop to a rows-1..23 stop, and the
test asserting the earlier stop failed.

House rule (`CLAUDE.md`, *Verification*): a test never pins a defect's
current symptom, and evidence a result depends on is stored in the
repository, not read from mutating run state. These copies are the frozen
inputs; the tests now read only from here.

**Do not overwrite these files.** They are inputs to assertions with
measured expectations. A new campaign state that needs testing gets a new
`FrozenTestFixtures_<date>/` directory and its own measured expectations.

## Provenance

Repository HEAD when the snapshot was taken: **5a8cf88** ("Canonicalize
joint-chart coordinate maps into the declared field; exact algebraic
round-trip zero test").

| | `sector_state_CF259_standard.wl` | `sector_state_CF303_standard.wl` |
|---|---|---|
| family | CF259 | CF303 |
| producing run | `triple_root_2026-08-24_fable`, **campaign round 4**, pool `cf300_pool4` | `triple_root_2026-08-24_fable`, **campaign round 4**, pool `cf300_pool4` |
| producing mission | `fresh_sol_CF259` | `fresh_sol_CF303` |
| HEAD the producing mission ran on | f85999a | f85999a |
| file written (mtime of the source) | 2026-08-25T07:50:16-07:00 | 2026-08-25T06:52:46-07:00 |
| snapshot taken | 2026-08-25T08:04-07:00 | 2026-08-25T08:04-07:00 |
| bytes | 76 165 895 | 61 233 991 |
| md5 | `937169c34e30b3a1a340aaa79e944ac1` | `c2120b8b91d518f952400cf43a7e2bd9` |
| `"Sector"` | 23 | 16 |
| `Dimensions["A"]` | {2, 47, 47} | {2, 45, 45} |
| `Length["Ranges"]` | 27 | 25 |
| `"Stop"` | `NeedsMultiquadraticRegulatorFactorization`, Rows 23, RootIndices {1,2,3} | absent (the state completed sector 16) |
| `"ChartFingerprint"` | `b23c6ac6…e184928` | `59642b48…0d60f0bf48` |

Both files are the **terminal** states of campaign round 4. The CF303 file
is additionally the exact sector-16 state that the round-5 mission
(`fresh_sol_CF303`, dispatched 2026-08-25T07:59:34 on HEAD 5a8cf88) resumes
from; it was still untouched by that mission when the snapshot was taken.

## How the snapshot was taken

Both source files can be rewritten by a live mission mid-copy, so each copy
was taken as a **consistent snapshot**:

1. record the source's mtime and size;
2. copy;
3. re-record mtime and size and require both unchanged — a changed value
   means the copy may be torn and is retried.

Both copies passed unchanged on the first attempt. Each copy was then read
back through `FeynFacet`FamilyArtifactRead` (the mandatory context-guarded
reader) and checked to be an Association carrying `"Sector"`, `"Ranges"`,
`"A"`, `"Blocks"`, `"ChartFingerprint"` and the per-family `"Stop"` record
where one exists. The `"ChartFingerprint"` of each state equals the SHA-256
of its family's registered frame in
`Results/UU_08_10_canonical/TransportFamilyCharts.wl`, so the fixtures and
the in-repository chart inventory agree.

## What the tests assert on them

Stable mathematical statements about the frozen matrices — never the stop
status of a campaign run:

- `t_kallen_q4_chart.wls` block T: the rows-1..16 truncation of the frozen
  CF259 state (the 24x24 leading block, row bound read from the state's own
  `"Ranges"`) carries exactly the frame roots {1, 3} with no undeclared
  radical, and that pair resolves to the chart `KallenQ4a` — the resolution
  that was `Missing["NoRationalChart"]` before the chart existed, which is
  what stopped the solve. `FactorFamilyRegulatorDependenceInFrame` returns
  `"AlreadyEpsFactored"` on it (measured, 0.2 s).
- `t_radical_denesting.wls` block (d): the 27x27 truncation of the frozen
  CF303 state classifies with **zero** unclassified radical bases and root
  indices {1, 2}; that pair resolves to the catalogued chart `Kallen23`;
  canonicalization is a verified no-op; and the factorization returns
  `"AlreadyEpsFactored"` (measured, 11.1 s).

### Why `"AlreadyEpsFactored"`, and what it costs the tests

Both fixtures are **terminal** states: `"A"` holds the rows the producing run
had already banked, so their regulator dependence is factored and the
factorizer has nothing left to do. That is a permanent property of the frozen
matrices — the tests assert the status *and* re-derive the claim behind it
directly, with `familyRegulatorFactoredQ` on the truncation itself, rather
than trusting the verdict.

Two consequences, stated plainly rather than papered over:

- The frozen CF303 truncation contains **no nested and no numeric radicand**
  (its radicands are the declared squares q1 and q2 themselves). Block (d)
  therefore no longer supplies real-data coverage of the *denesting rewrite*;
  it certifies that the classifier is clean on real data. The denesting
  machinery itself is exercised on constructed data in blocks (a), (b), (c)
  of that file.
- The pre-factorization connection is preserved in the same fixtures as
  `"OriginalA"`. Measured 2026-08-25: the CF259 `"OriginalA"` rows-1..16
  truncation classifies identically (frame roots {1, 3}, no undeclared
  radical), and it is the object that drives a full `KallenQ4a`
  factorization. That call costs minutes on a 24x24 truncation, so it is
  deliberately kept out of the acceptance suite; it is available here for
  anyone who wants to exercise that path.

## Caveat: "frozen" is a convention, not a git guarantee

`Results/UU_08_10_canonical/*` is gitignored except for four named
directories (`ClassForms`, `BlockClasses`, `BoundaryPeriods`, `HardClasses`),
whose comment in `.gitignore` reserves the exemption for *small*,
load-bearing test inputs. These two fixtures are 137 MB together, far past
that bar, so they are **not tracked**. Nothing but this README and the
absence of a writer keeps them fixed. If the suite is to be reproducible on
a fresh clone, the fixtures should be reduced to just the truncations the
tests read (a few hundred KB) and tracked — that is a separate decision, not
made here.

---

## Reduction and tracking (2026-08-25, answering the caveat above)

The caveat at the end of the previous section is now resolved. The two
full sector states remain **untracked** local run data (they are the
archive); what the acceptance suite reads are **tracked reductions** to
exactly the leading truncations the assertions consume:

| | `cf259_frozen_rows24.wl` | `cf303_frozen_rows27.wl` |
|---|---|---|
| reduced from | `sector_state_CF259_standard.wl` | `sector_state_CF303_standard.wl` |
| source bytes | 76 165 895 | 61 233 991 |
| tracked bytes | 104 310 (102 KiB) | 3 205 973 (3.1 MiB) |
| reduction | 730x | 19x |
| `Dimensions["A"]` | {2, 24, 24} | {2, 27, 27} |
| `"OriginalA"` | kept, {2, 24, 24} | dropped (no test reads it) |
| `Length["Ranges"]` | 16 (those ending at or before the kept row bound) | 16 |
| SHA-256 | `e6b3e357c526925ca41f718ee447b28a63adf8d5e54dedfa47d77165151e1a35` | `a5983c6c5f6fa5dd4d38803a352ad67566405e8144d3ffa696ed13da1579be2b` |

Each reduction is an Association carrying its own provenance —
`"Schema" -> "FeynFacetFrozenTestFixture"`, `"ReducedFrom"`,
`"SourceSHA256"`, `"SourceBytes"`, `"SourceDimensions"`,
`"SourceRangeCount"`, `"ReducedRows"` — alongside `"A"`, `"Ranges"`,
`"ChartFingerprint"` and (CF259 only) `"OriginalA"`. `SHA256SUMS` in this
directory is the manifest; `sha256sum -c SHA256SUMS` verifies it, and both
tests re-check their own file against that manifest before using it, so a
silently edited fixture is a red assertion rather than a wrong result.

`.gitignore` re-includes only this directory's `README.md`, `SHA256SUMS`
and the two reduced `.wl` files, together with
`Results/UU_08_10_canonical/TransportFamilyCharts.wl` (3 KiB) which both
tests also read. `Tests/t_radical_denesting.wls` block (d) and
`Tests/t_kallen_q4_chart.wls` block T therefore run on a fresh clone; the
skip-with-message path in the latter remains, but it now fires only if
the tracked file is genuinely absent.

Nothing about the mathematics changed: the reduced `"A"` is the identical
leading truncation the previous assertions extracted from the full state,
so the measured expectations recorded above are unchanged. Only the
schema-shape assertions moved from the full matrix (2x47x47 / 2x45x45 in
27 / 25 ranges) to the truncation (2x24x24 / 2x27x27 in 16 ranges), and
each test additionally asserts the recorded source dimensions, so the
provenance of the truncation is checked rather than assumed.
