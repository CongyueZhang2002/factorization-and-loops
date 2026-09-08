# CF300 sector 11: direct two-dimensional regulator continuation

Date: 2026-08-23

Scope: pinned-state assessment and External-only continuation driver.  No
package source was changed and no Wolfram kernel was launched during this
work.

## Conclusion

CF300 does **not** need a general rank-three multiquadratic
evaluation/reconstruction solve at the current regulator stop.  The apparent
three-root problem is the union of:

- the already certified 20-master prefix, which contains roots 1 and 2; and
- the new two-master sector 11, whose lower-left row contains root 3.

All newly introduced regulator dependence is one scalar multiplying the
`2 x 20` lower-left block.  Let

```text
P(eps) = -2 + 13 eps - 27 eps^2 + 18 eps^3
       = (2 eps - 1) (3 eps - 1) (3 eps - 2),
q(eps) = P(eps)/eps^2,
t(eps) = q(eps)/eps = P(eps)/eps^3.
```

On the completed 22-master prefix the exact block form is

```text
A = [ eps B      0   ]
    [ q C      eps D ],
```

where `B`, `C`, and `D` are regulator-free (they may remain
multiquadratic).  Therefore the root-free constant transformation

```text
G = diag(I20, t I2)
```

gives

```text
G^-1 A G = [ eps B      0   ].
            [ eps C   eps D ]
```

No joint rational chart is needed.  The regulator-dependent invariant
subspace is exactly `span{e21,e22}` and the transformation on it is scalar.

## Pinned evidence

Input state:

`/home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/FamilyEpsFormsSolving/triple_root_2026-08-23/CF300/sector_state_CF300_standard.wl`

- bytes: `33,012,365`
- SHA-256:
  `898e4283c39fcdb457b7857a4609e48b5ca0417b1d06cb07750779b187c33a12`
- saved sector: `11`
- completed range: `{21,22}`, so the completed prefix is dimension 22
- next/future range: `{23,24}`
- typed stop: `NeedsMultiquadraticRegulatorFactorization`, roots `{1,2,3}`
- prior regulator factors: 9, ending at rows 10 / dimension 20 with
  `RationalChart/Kallen23/ExactRationalSamples`, roots `{1,2}`

The no-kernel structural audit classified every entry in both one-form
components of the `22 x 22` prefix after replacing the exact repeated
polynomial `P` by the formal homogeneous symbol `eps^2 q`.  It found:

| Region | zero | formal degree `(eps,q)` | nonzero |
|---|---:|---:|---:|
| old `20 x 20` | 516 | `(1,0)` | 284 |
| upper-right `20 x 2` | 80 | none | 0 |
| new lower-left `2 x 20` | 54 | `(0,1)` | 26 |
| new diagonal `2 x 2` | 0 | `(1,0)` | 8 |

There were no parse failures and no inhomogeneous entries.  Every radical in
the 26 nonzero lower-left channels is `Sqrt[1-4*x*y]`, i.e. root 3.  The
affected columns of `S` are only the two unit entries `(21,21)` and `(22,22)`.
The affected rows of `SInverse` have 14 nonzero entries total:

```text
row 21: {1,2,5,16,17,21}
row 22: {1,2,5,10,11,16,17,22}
```

The launchable V2 inspector is
`inspect_cf300_sector11_regulator_structure_v2.py`, SHA-256
`036d15b1735efd30a0b0f1049559b7f61c84edc662a94d3eae806953589944c3`.
It passed on the pinned state.

Package snapshot inspected, but not modified:

- `FeynFacet/Private/FamilyRegulatorFactor.wl`:
  `bef8ca27d92a76b6db0abb7cbccb1be2e4498471005fdfe8c40687d071d168c1`
- `Scripts/family_epsform_sector.wls`:
  `6786d5ee1ccefe101f6d70d1f8a977cd5de039b8673e20d54062f8b4915895f1`
- `Addon/Load/LoadFACET.wl`:
  `e324b5f6c30d34a70248b691183abb1904d1a27fd745e3c4b8b0b381122e6164`

## Why the current package stops

`FactorFamilyRegulatorDependenceInFrame` classifies roots over the entire
prefix.  Once the old prefix contributes `{1,2}` and sector 11 contributes
`{3}`, it asks `TransportRootSetChart` for a joint chart.  No catalogued chart
exists, so it returns `NoRationalChart` before inspecting the support or the
rank of the regulator-dependent part.

This is a safe package stop, not a mathematical obstruction.  The dispatcher
currently has only two paths: rationalize the entire prefix, or stop.  It lacks
the cheaper pre-pass used here: isolate the regulator-dependent residue
subspace and test scalar/block-diagonal factors there.

## Continuation driver

`run_cf300_sector11_direct_scalar_regulator_continuation_v2.wls`, SHA-256
`73a3c23c2a68ebc3ec3196b2bba29cbee1be3c6bf4601d0622126d84fb4576f8`,
is a self-contained, fail-closed state transformer.  It does not load FACET,
launch subkernels, or touch package files.

Before any expensive `Get`, it requires the exact input byte count and hash,
distinct absent output/report/temp paths, and existing target directories.
The state is hydrated under a dedicated context with `Global`` absent from
`$ContextPath`; exact snapshots prove that `Global`x`, `Global`y`, and
`Global`eps` are unchanged.  It then requires the exact sector, ranges, stop,
root squares, dimensions, prior factor, and certificate history.

The 900-second bounded core:

1. checks the `20 x 2` upper-right block and the full `22 x 2`
   prefix-to-future block (88 channels) are exactly zero;
2. computes `Together[entry/q]` for all 26 nonzero lower-left channels,
   requires every quotient to be regulator-free, and proves the exact
   reconstruction identity;
3. checks all 8 nonzero `2 x 2` diagonal channels are `eps` times a
   regulator-free coefficient;
4. replaces only the 26 lower-left channels by `eps C`;
5. propagates `G` to the eight future `A` entries in rows 23--24 / columns
   21--22, the two affected `S` entries, and the 14 affected `SInverse`
   entries;
6. certifies every entry of the full transformed `A`, `S`, and `SInverse`
   against the corresponding row/column scale identity, without a dense
   product; proves all `22 x 22` prefix entries are epsilon-form, and applies
   independent `Together` proofs to eight pinned inherited entries;
7. proves `det(G)=t^2` is a nonzero rational function and records the only
   exceptional evaluation values `{0,1/3,1/2,2/3}` (a pole or zero at an
   isolated regulator value does not invalidate invertibility over
   `Q(eps)`);
8. creates and independently recomputes a propagation seal binding the input
   state/prefix, output prefix, `t`, and `t^-1`;
9. removes the typed stop and appends a Fable-compatible regulator-factor
   history record; and
10. rechecks source hashes immediately before writing a separate candidate
   state and report through absent temporary files and non-overwriting atomic
   renames.

The unchanged `20 x 20` block inherits its exact factorization from the pinned
rows-10 record; the driver does not spend time re-simplifying its 284 large
algebraic entries.  This inheritance is sound because the complete state file
is hash-pinned and those entries are not changed.

The V2 static driver audit
`test_cf300_sector11_direct_regulator_v2_static.py`, SHA-256
`2a21165856ca305cfa1464efccd83cb91422b4b558676d3cf1df9470f6acb02f`,
passes `104/104` checks.  It
also forbids package loads, Wolfram parallelism, process control, hard-coded
Global artifact hydration, overwriting renames, and package factorizer calls.

## Exact complexity reduction

For the fixed numerator support `{1,eps,eps^2,eps^3}/eps^3`:

- a dense `22 x 22` transformation has `22^2 x 4 = 1,936` numerator
  coefficients before normalization;
- a general transformation on the two-dimensional active subspace has
  `2^2 x 4 = 16` coefficients; and
- the observed scalar transformation has `1 x 4 = 4` coefficients.

The repeated polynomial fixes all four scalar coefficients directly from one
nonzero exact channel, so the actual driver has one scalar unknown and uses
zero finite-field samples.  It certifies that scalar against all 26 nonzero
lower-left channels and both differential components.

If the exact common factor had not been visible, the economical modular
fallback would be: evaluate only those 26 channels at one split kinematic
point, interpolate the four coefficients from four regulator values, then
gate at two fresh regulator values and all eight Galois branches.  A full
prefix sampler or root-basis reconstruction would be unnecessary.  For more
general families, compute the smallest common invariant closure of the images
of `B(eps)-B(eps0)` under sampled residue matrices before choosing a `d x d`
intertwiner ansatz; selecting entries by textual epsilon occurrence alone is
not invariant and is not sufficient.

## Launch and resume sequence

Run the no-kernel gates first:

```bash
python3 /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_sector11_direct_regulator_xh/inspect_cf300_sector11_regulator_structure_v2.py
python3 /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_sector11_direct_regulator_xh/test_cf300_sector11_direct_regulator_v2_static.py
```

Then centrally launch the driver on one clean main kernel with zero
subkernels.  Its arguments are exactly:

```text
<pinned-input-state.wl> <absent-output-state.wl> <absent-report.wl>
```

Recommended concrete candidate targets are in a new, otherwise empty
directory, with the output state named `sector_state_CF300_standard.wl` so it
can be consumed directly by the sector script.  Do not target the original
state file.  Success requires process exit 0, a `PASS` line, report status
`OK`, the printed output SHA-256, and cleanup booleans both true.

After review, resume `Scripts/family_epsform_sector.wls` with family `CF300`,
the fresh candidate directory as `outdir`, sector budget `7200`, tag
`standard`, and direct-sector budget `30`, using the same Production /
FiniteFieldFirst environment as the stopped run.  The package must run on a
clean main kernel: its startup currently clears `Global`x/y/eps`, so the
irreversibly Locked poisoned kernel 144 is not a valid target.  On resume the
pre-sector-12 `factorTruncated[11]` call should now return immediately because
the 22-master prefix is already epsilon-factored.

Do not call this optimization complete until the resumed sector 12 finishes
and the separate exact family certificate passes.
