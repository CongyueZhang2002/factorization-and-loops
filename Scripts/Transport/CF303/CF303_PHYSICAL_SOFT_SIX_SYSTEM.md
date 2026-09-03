# CF303 physical soft six-master system

Date: 2026-09-03

## Outcome

The missing tangential data can be obtained exactly and more cheaply from the
original rational physical differential equation than from the triple-root
canonical state.  The builder lexically extracts only physical rows `1..6`
of `Av` and `Aw`, then restricts them to the soft chart at fixed
`rho = 2 p - u`.  A full `45 x 45` connection is never loaded or formed.

The resulting artifact contains two distinct pieces:

- a closed `6 x 6` homogeneous physical system for the six CF303 masters;
- exact `6 x 39` inherited forcing decks, including their full Laurent
  principal parts and finite terms.

This supplies the target tangential information that flatness alone cannot
fix.  The deferred canonical circuit and its three radicals are unnecessary
for this stage; the compact physical endpoint map `W` is needed only later to
match these physical modes to the stored interior `G` transport.

## Exact normal structure

In physical master order `1..6`, the homogeneous normal residue is

```text
N = {{0,0,0,0,0,0},
     {0,0,0,0,0,0},
     {0,0,0,0,0,0},
     {0,0,(2+9 eps+10 eps^2)/p^2,-2(1+2 eps),0,0},
     {0,0,0,0,0,0},
     {0,0,(-2-9 eps-10 eps^2)/p^4,2(1+2 eps)/p^2,0,0}}.
```

It has generic rank one and obeys

```text
N^2 = -2 (1+2 eps) N.
```

Hence its spectrum is
`{-2(1+2 eps),0,0,0,0,0}`, its generic minimal polynomial is
`z (z+2(1+2 eps))`, and it is semisimple, with a five-dimensional zero
eigenspace.  The homogeneous normal system is already Fuchsian: it has four
nonzero simple-pole coordinates and no higher pole.

It is not an epsilon-form residue.  It is nonzero at `eps=0`, depends on `p`,
and its nonzero exponent is the integer-plus-regulator value `-2-4 eps`.
Consequently the current `BuildEndpointFrobenius`, which intentionally accepts
only `eps R` with constant `R`, cannot be applied directly in this physical
basis.  Physical-mode integration needs either a concise rational-epsilon
Levelt/shear step or a subsequent exact change to the canonical endpoint
basis.  No higher-pole shear is needed merely to make the homogeneous normal
system Fuchsian.

## Tangential system and letters

All 36 homogeneous tangential coordinates are regular at fixed `rho`:
18 have a nonzero finite value, two vanish linearly, and 16 are identically
zero.  Their exact matrix is stored in the artifact.  Factoring its rational
functions of `p` gives only

```text
p,  p-1,  p+1,  2 p^2-1,
```

with maximum denominator powers `{5,1,1,1}` respectively and polynomial part
of degree at most one.  Thus the singular/letter set is

```text
{0, 1, -1, 1/Sqrt[2], -1/Sqrt[2], Infinity}.
```

The powers `p^-2` through `p^-5` are rational prefactors in the unsheared
physical basis, not new function letters.  Coefficients are rational in
`eps` and include `(1+eps)^-1` and `(1+2 eps)^-1`; the suitable consumer is the
rational-epsilon transport layer rather than a pure constant-residue
epsilon-form word engine.

## Inherited forcing

The exact raw local counts over the `6 x 39` inherited block are:

| deck | `rho^-3` | `rho^-2` | `rho^-1` | regular | vanishes | zero |
|---|---:|---:|---:|---:|---:|---:|
| tangential | 2 | 13 | 27 | 97 | 10 | 85 |
| normal | 3 | 25 | 41 | 79 | 1 | 85 |

Therefore an unscaled finite product with lower-sector solutions can demand
their expansion through order `rho^3`.  This is an inherited-particular-data
requirement, not a failure of the six-master homogeneous system.  The artifact
keeps every principal coefficient so known lower-sector Frobenius valuations
can prune the actual jet demand before transport.

## Construction, evidence, and timing

Source:

```text
ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/
  DifferentialEquations/nnlo_de_CF303.wl
```

The source is 971,619 bytes.  The lexical `6 x 45` slice is 687,812 bytes.
The accepted exact build took:

| phase | seconds |
|---|---:|
| lexical extraction | 0.23 |
| compact slice load | 0.06 |
| exact tangential Laurent deck | 63.93 |
| exact normal Laurent deck | 59.39 |
| total | 123.60 |

Physical row 6, inherited column 7 is the sole expensive scalar: isolated
exact extraction took 12.40 seconds tangentially and 12.01 seconds normally;
all other coordinates completed under the original ten-second pilot bound.
Production uses a 30-second per-scalar cooperative bound, so there is no
open-ended symbolic step.

Before the exact build, a full point specialization at
`(p,eps)=(3,1/7)` produced both `6 x 45` decks in 2.92 seconds.  This remains a
cheap fallback for future projected reconstruction, but reconstruction is not
needed for the present characteristic-zero artifact.

The coordinate check is the exact scalar Jacobian identity between the
`(p,s)` chart, `s=1-v-w`, and the exact fixed-`rho` chart.  It proves the two
connection pullbacks agree entrywise even for second- and third-order inherited
poles, without duplicating a symbolic matrix certificate.  The focused control
is seven assertions, all green.

## Files and remaining integration

- Builder: `build_cf303_physical_soft_six_system.wls`
- Exact artifact: `Artifacts/CF303PhysicalSoftSixSystem.wl`
- Focused control: `Controls/t_physical_soft_six_system.wls`
- General lexical slicer: `../Utilities/extract_wl_matrix_slice.py`

Still required for the paper-facing CF303 boundary result:

1. contract the inherited principal decks with the already named lower-family
   Frobenius/period data, pruning unused jets;
2. implement or instantiate the rational-epsilon Levelt/shear action for the
   rank-one physical normal residue;
3. match the resulting six physical endpoint modes through the compact `W`
   map into the lazy interior `G` coordinates;
4. emit only the genuinely unevaluated period coefficients in the Stage-3
   needs ledger.

No boundary constants, period values, or physical completion are inferred by
this artifact alone.
