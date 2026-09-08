# CF300 direct regulator V2 exit 71: diagnosis and V3

Date: 2026-08-23

No Wolfram kernel was launched and no package source was modified in this
diagnosis.

## V2 runtime evidence

The central V2 mission ran on clean kernel 24.  In four seconds it reported:

- silent state `Get`;
- state association, exact schema, dedicated symbols, and Global-state gates
  all true;
- exit code 71;
- dedicated-context removal and Global-state restoration both true; and
- no candidate or report output.

Log:

```text
/tmp/codex-triple-root-20260823c.vx654S/pool/logs/cf300_s11_direct_regulator_v2.log
SHA256 9765cb75583fd72ef6f126f2c315871301d4d2623746bf03d968cd376c47222c
```

V2 used code 71 for the combined predicate

```text
FullTransformedAIdentityQ && FullSIdentityQ &&
FullSInverseIdentityQ && FullPrefixEpsFormQ &&
InheritedTogetherSpotProofQ.
```

It did not print the individual values.  The three entrywise scaling
identities follow directly from the sparse construction and the eight pinned
spot entries each contain a single explicit regulator factor.  The unsafe
predicate is the old full-prefix test:

```text
FreeQ[value/eps, eps]
```

That is a syntactic cancellation test, not an exact test that a rational
expression is homogeneous of regulator degree one.

## Exact static isolation

The pinned formal parser proves all 284 nonzero entries in the inherited
`20 x 20` block have regulator degree exactly one.  Of those entries:

```text
282 contain one syntactic eps occurrence;
1 contains seven occurrences:  component 1, row 18, column 6;
1 contains thirteen occurrences: component 2, row 18, column 6.
```

The two exceptional inherited expressions are homogeneous but store the
factor as a sum such as `-eps + eps*x - 2*eps*y + ...`; they do not have one
outer `Times[eps,...]` factor.  Their exact raw-expression fingerprints are:

```text
{1,18,6}: 6e11a172ec08c7aa334672ee16ea689b8de91e8b800e99bc4c211e9e98b2363c
{2,18,6}: aff23d324ced5da40b4ca8695b18343d6f1439084060549bd9abcc6ca5e0a293
```

Hence the predicted first failure of V2's row-major syntactic predicate is
`{1,18,6}`.  This is an acceptance-gate bug, not a failure of the scalar
regulator transformation.

The no-kernel diagnosis is
`diagnose_cf300_sector11_v2_exit71_static.py`, SHA-256
`cbcc4d56529bdb92597cc1ce71456825ff4b82e7742a6ff42d224d6bde126a63`.
It passes and prints the histogram and predicted first failure.

## V3 correction and telemetry

V3 preserves every V2 source/state pin and all exact sparse propagation,
determinant, seal, and source-stability gates.  It changes only the inherited
prefix acceptance:

1. the unchanged `20 x 20` block is bound to the exact input-state and formal
   inspector hashes plus the prior rows-10 regulator factor;
2. eight nonzero inherited entries are still checked independently with
   `Together`;
3. all changed lower-left and diagonal entries retain their exact
   `Together`/regulator-free proofs;
4. the complete transformed `A`, `S`, and `SInverse` scaling identities remain
   entrywise exact; and
5. the V2 syntactic predicate remains as non-blocking telemetry.

Before any validation exit, V3 prints bounded associations for:

- scalar/determinant and block-zero prechecks;
- lower-left/diagonal proofs and counts;
- propagation counts; and
- every exact acceptance predicate, the first failing A/S/SInverse index,
  all eight spot results, and the legacy syntactic first failure.

The final `Exit` is also lexically resolved through `With`, preventing the pool
wrapper from recording the literal symbol `finalCode`.

Frozen sources:

```text
run_cf300_sector11_direct_scalar_regulator_continuation_v3.wls
SHA256 7a49556d75cb95a82f7b771d40adeb0535e19440839419ae6de45190b0fa6150

inspect_cf300_sector11_regulator_structure_v2.py
SHA256 036d15b1735efd30a0b0f1049559b7f61c84edc662a94d3eae806953589944c3

diagnose_cf300_sector11_v2_exit71_static.py
SHA256 cbcc4d56529bdb92597cc1ce71456825ff4b82e7742a6ff42d224d6bde126a63

test_cf300_sector11_direct_regulator_v3_static.py
SHA256 eada7cc09c1ae079a333ca6178d941816dfed16ff4a40804b67f17347882cbd8
```

The V3 static audit passes `132/132`.

## Exact relaunch arguments

Create the following fresh directory first:

```text
/home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/FamilyEpsFormsSolving/triple_root_2026-08-23/CF300_direct_regulator_v3_candidate
```

Then launch V3 on one clean main kernel with zero helpers.  The three exact
arguments are:

```text
/home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/FamilyEpsFormsSolving/triple_root_2026-08-23/CF300/sector_state_CF300_standard.wl
/home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/FamilyEpsFormsSolving/triple_root_2026-08-23/CF300_direct_regulator_v3_candidate/sector_state_CF300_standard.wl
/home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/FamilyEpsFormsSolving/triple_root_2026-08-23/CF300_direct_regulator_v3_candidate/cf300_sector11_direct_regulator_report_v3.wl
```

The driver path is the frozen V3 path under this directory.  All output,
report, and `.tmp` targets must be absent.  Do not run on poisoned kernel 144.
A separate post-write hydration/seal validator remains required before the
sector-12 resume.
