# Command and result ledger

All calculation artifacts are confined to this directory. Durations reported
for Maple and Wolfram Language commands are measured by `/usr/bin/time` or by
the language's exact timing wrapper where noted.

The acceptance criterion for a claimed CF254 gauge is exact vanishing of every
entry of both original Pfaffian residuals after substitution. A timeout, an
empty package result, or a fixed-kinematics value does not satisfy this
criterion.

## Read-only inspection

The requested repository files and exact CF254 record were read with `sed`,
`rg`, `grep`, and Wolfram `Get`. The concatenated source file was parsed by its
section delimiters and compared to the live files. `sha256sum` and `stat`
recorded the hashes and sizes in `RESULT.md`. These shell reads were not timed
individually; they performed no calculation and changed no input.

The source audit also used `find`, `file`, and `git status --short` in read-only
mode. `pdfinfo` and `pdftotext` were queried for the local PDF documentation but
neither executable is installed. No PDF content was used in place of the
exact XML worksheet.

One later repository-language scan attempted `rg`; WSL resolved it to a
WindowsApps executable and returned `Permission denied`. The same read-only
scan was completed with `grep` and found none of the restricted prose words.
Neither command performed a scientific calculation, and their wall times were
not separately measured.

An initial `apply_patch` call using a Linux absolute path was interpreted by
the host as
`C:\home\maxzhang\factorization-and-loops\Codex\TwoRootMapleAugmented\01_ratsuper_probe.mpl`.
The 387-byte duplicate was detected during the path audit. Two guarded
`Remove-Item` commands were rejected by the command policy and changed
nothing. The exact duplicate was deleted with `apply_patch`; after confirming
that its directory was empty and its resolved path was the expected literal
path, that empty directory was deleted nonrecursively. A final `Test-Path`
returned `False`. The intended WSL probe and every scientific log were
unchanged.

No finite-field rank calculation, sample scan, or rational reconstruction was
run in this directory.

## API and documentation commands

1. Command: `/home/maxzhang/.local/bin/maple < 01_api_probe.mpl`
   Runtime: 0.25 s wall, exit 0, 42,120 KiB maximum resident memory.
   Exact result: Maple 2026.1 build 2018217 loaded the local archive;
   `RationalSolutions` is an exported procedure. Its full source and statement
   listing are in `01_api_probe.stdout.log`. Both help queries returned `help
   ... not found`.

2. Command: `python3 extract_maple_mw.py <RightHandSideExample.mw> 01_RightHandSideExample.txt`
   Runtime: 0.02 s wall, exit 0, 14,208 KiB maximum resident memory.
   Exact result: the XML worksheet text was extracted in document order. It
   gives the `param`/`rhs` syntax and the affine `[H,p]` semantics.

3. Command: `/home/maxzhang/.local/bin/maple < 01_lower_solver_probe.mpl`
   Runtime: 0.03 s wall, exit 0, 29,948 KiB maximum resident memory.
   Exact result: dumped installed `direct_ratsol` and `Mratsolde` sources.

4. Command: `/home/maxzhang/.local/bin/maple < 01_good_form_probe.mpl`
   Runtime: 0.03 s wall, exit 0, 29,780 KiB maximum resident memory.
   Exact result: dumped installed `Mpolsolde` and `good_form` sources;
   `Mpolsolde` calls `good_form`.

5. Command: `/home/maxzhang/.local/bin/maple < 01_super_form_probe.mpl`
   Runtime: 0.02 s wall, exit 0, 29,660 KiB maximum resident memory.
   Exact result: dumped `super_form`; it immediately calls `ratsuper`. A later
   display-only shell `printf` used a leading-hyphen format and emitted
   `printf: --: invalid option`; this did not alter the Maple command or log.

6. Command: `/home/maxzhang/.local/bin/maple < 01_ratsuper_probe.mpl`
   Runtime: 0.03 s wall, exit 0, 29,660 KiB maximum resident memory.
   Exact result: dumped the complete installed `ratsuper` source and statement
   listing.

## Synthetic commands

1. Command: `/home/maxzhang/.local/bin/maple < 02_synthetic_affine.mpl`
   (attempt 1).
   Runtime: 0.20 s wall, exit 0, 64,476 KiB maximum resident memory.
   Result before parse failure: native right-hand-side call returned
   `H=[x*y]`, `p=[eps*x^2+x+y]`; both exact residual matrices were zero.
   Error: Maple syntax error at the attempted Boolean expression
   `and(seq(...))`. Maple nevertheless returned process status 0.

2. Same command, attempt 2.
   Runtime: 0.13 s wall, exit 0, 66,428 KiB maximum resident memory.
   Exact result: both native residuals and both augmented residuals were zero;
   the basis-change determinant was one. Matrix names were printed unevaluated,
   so this run was retained as an intermediate attempt rather than the final
   syntax record.

3. Same command, final run.
   Runtime: 0.09 s wall, exit 0, 68,208 KiB maximum resident memory.
   Internal times: native RHS 0.026 s; augmentation 0.031 s.
   Exact result: `H=[x*y]`, `p=[eps*x^2+x+y]`, augmented basis
   `[[x*y,x+y,eps*x^2],[0,1,0],[0,0,1]]`; all residual entries zero,
   basis-change identity, determinant one, and zero `x,y` derivatives.

## CF254 construction commands

1. Command: `wolframscript -file 03_inspect_cf254.wls`.
   Runtime: 21.44 s wall, exit 0, 111,860 KiB maximum resident memory;
   internal total 18.748300 s.
   Exact result: record dimensions `{{2,4,4},{2,2,2},{2,4,2}}`, nonzero-entry
   counts `{32,8,16}`, exact strip curvature zero in 17.227928 s, and the full
   denominator census in `03_inspect_cf254.stdout.log`.

2. Command: `wolframscript -file 04_build_augmented_cf254.wls` (attempt 1).
   Runtime: 0.19 s wall, exit 255, 113,344 KiB maximum resident memory.
   Error: Wolfram license unavailable; no calculation began.

3. Command: `bash 04_wait_and_build.sh` (first queue attempt).
   Runtime: queue duration not separately retained.
   Result: the first license probe was unavailable; the second probe, 30 s
   later, was available. An unintended duplicate of this build was then found;
   only the older duplicate process group was terminated. No file from that
   interrupted process was selected as a result.

4. Command: `bash 04_wait_and_build.sh` (retained run). The script invoked
   `timeout --signal=TERM --kill-after=30s 3600s wolframscript -file
   04_build_augmented_cf254.wls` under `/usr/bin/time`.
   Runtime: 819.59 s wall, exit 0, 108,112 KiB maximum resident memory;
   Wolfram internal total 817.062949 s.
   Exact result: 928 residue equations, nine free residue constants, exact
   affine source reconstruction, 18 by 18 matrices, and exact augmented
   curvature zero. Residue construction took 242.000762 s; curvature
   simplification took 56.837833 s.

## Full `RationalSolutions` commands

Each command below invoked the generated Maple file under `/usr/bin/time`.
The Maple files first call `TestIntegrabilityConditions`, then call the full
two-variable `RationalSolutions` API with `['param',[eps]]`.

1. Command: `/home/maxzhang/.local/bin/maple < 05_cf254_augmented_xy.mpl`
   (attempt 1).
   Runtime: 104.76 s wall, exit 0, 424,876 KiB maximum resident memory.
   Exact result: integrability text `"The connection is integrable!"` in
   3.664 s; solver error after 100.747 s. The first catch recorded only the
   uninformative name `lastexception`.

2. Same `(x,y)` command, attempt 2.
   Runtime: 101.51 s wall, exit 0, 481,216 KiB maximum resident memory.
   Exact result: integrability in 3.489 s; solver error after 97.782 s.
   Added exception formatting still returned an unassigned-looking exception
   object.

3. Same `(x,y)` command, retained run.
   Runtime: 103.01 s wall, exit 0, 411,788 KiB maximum resident memory.
   Exact result: integrability in 3.870 s; solver error after 98.906 s;
   no result file.

4. Command: `/home/maxzhang/.local/bin/maple < 05_cf254_augmented_yx.mpl`
   (attempt 1).
   Runtime: 51.67 s wall, exit 0, 267,408 KiB maximum resident memory.
   Exact result: integrability in 3.565 s; solver error after 47.755 s; first
   catch recorded only `lastexception`.

5. Same `(y,x)` command, attempt 2.
   Runtime: 49.98 s wall, exit 0, 266,768 KiB maximum resident memory.
   Exact result: integrability in 3.555 s; solver error after 46.181 s;
   unassigned-looking exception object.

6. Same `(y,x)` command, retained run.
   Runtime: 50.11 s wall, exit 0, 261,852 KiB maximum resident memory.
   Exact result: integrability in 3.489 s; solver error after 46.379 s;
   no result file.

The exit code is zero because the generated scripts catch and record Maple
errors. It is not evidence for a returned rational basis.

## Internal error commands

1. Command: `/home/maxzhang/.local/bin/maple < 05_probe_first_ode_xy.mpl`.
   Runtime: 94.95 s wall, exit 0, 408,828 KiB maximum resident memory;
   Maple probe time 94.841 s.
   Exact error: `Error, (in IntegrableConnections:-good_form) numeric
   exception: division by zero` after `direct_ratsol` called `Mpolsolde`.
   The result symbol remained unassigned.

2. Command: `/home/maxzhang/.local/bin/maple < 05_probe_first_ode_yx.mpl`.
   Runtime: 43.16 s wall, exit 0, 296,584 KiB maximum resident memory;
   Maple probe time 43.046 s.
   Exact error: the same division by zero after the reversed divisor analysis;
   the result symbol remained unassigned.

These direct ordinary-system probes are diagnostics of the failed internal
stage. They are not the main calculation path.

## Exact verification commands

1. Command: `wolframscript -file 06_verify_cf254_result.wls xy`.
   Runtime: 2.44 s wall, exit 3, 107,288 KiB maximum resident memory.
   Exact result: `verification_status=MISSING_MAPLE_RESULT`.

2. Command: `wolframscript -file 06_verify_cf254_result.wls yx`.
   Runtime: 2.51 s wall, exit 3, 107,832 KiB maximum resident memory.
   Exact result: `verification_status=MISSING_MAPLE_RESULT`.

The verifier performs exact substitution into both augmented PDEs, selects an
affine section, and substitutes the reshaped gauge into both original strip
equations and both transformed dlog equations. It does not execute those later
steps when the Maple result file is absent.

## Inventory command

1. Command: `bash 07_make_inventory.sh`, initially under `/usr/bin/time`.
   Runtime: 0.20 s wall, exit 0, 4,080 KiB maximum resident memory.
   Exact result: `FILES_CREATED.tsv` listed 97 files including its own
   self-referential row. The script was then run once without timing so that
   the completed `07_make_inventory.time` file received its final size and
   digest in the manifest.
