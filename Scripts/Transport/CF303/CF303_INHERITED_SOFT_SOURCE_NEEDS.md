# CF303 inherited soft-source projection

Date: 2026-09-03

## Result

The accepted physical endpoint map

```text
I25 = [T25 H, T25] . {F_source, G25}
```

does not require a reconstruction of its raw `2 x 43` source block.  Its
source support is exactly the seven **state rows**

```text
{1, 2, 12, 21, 22, 29, 30}.
```

The word “state” matters.  Applying the accepted CF303 `Ranges -> Blocks`
ordering before the Kira sector maps gives

| CF303 state row | CF303 original master | exact lower-family image | lower canonical row |
|---:|---:|---|---:|
| 1 | 7 | CF1 row 1 | 1 |
| 2 | 39 | CF12 row 4 | 6 |
| 12 | 8 | CF21 row 1 | 4 |
| 21 | 29 | CF199 row 1 | 8 |
| 22 | 30 | CF199 row 2 | 9 |
| 29 | 20 | CF53 row 4 | 11 |
| 30 | 21 | CF53 row 5 | 12 |

Reading only these seven rows from `SInverse` and `TDiagonalInverse` shows
that both are one-sparse on this support.  Thus there is no hidden 43-row
mixing to construct:

```text
F_support = E . diag(d1,...,d7) . I_lower,
```

where `E` selects the seven state rows and, in the accepted source `(x,y)`
frame,

```text
d = {
  1/(x+y-1),
  2 eps^3/P3,
  eps/(-2+3 eps),
  2 eps^3/P3,
  2 eps^2 (x-1)/P3,
  2 eps^3/P3,
  2 eps^2 (y-1)/P3
},
P3 = -2+13 eps-27 eps^2+18 eps^3.
```

At the selected soft sheet, physical `(v,w)=(p^2,1-p^2)` and the accepted
source frame has `(x,y)=(p^2,1-p^2)`.  The first factor is singular, but it
multiplies the phase-space volume, whose factor of
`s^(1-2 eps)` turns it into the expected canonical `s^(-2 eps)` mode.  It
must therefore be combined before taking the endpoint; it must not be
evaluated as `1/0` separately.

The complete machine-readable map is
`Artifacts/CF303InheritedSoftSourceNeeds.wl`.

## Minimal epsilon and local projection

The accepted source boundary ranges are

```text
state rows 1,2,12       : epsilon orders  0..5
state rows 21,22,29,30  : epsilon orders -1..5.
```

For final target orders `-4..2`, only

```text
W_q columns 1,2,12       with q=-3..2
W_q columns 21,22,29,30  with q=-3..3
```

can enter.  This is

```text
2 targets * (3*6 + 4*7) = 92
```

scalar W coordinates, versus the raw `2*43*10 = 860` grid.  A bounded
accepted point at `p=3` confirms all 92 selected coordinates are active,
that the maximum W pole is `rho^-2`, and that every coefficient is in the
rational/base channel.

For physical endpoint matching one needs the projected local powers
`rho^-2`, `rho^-1`, and `rho^0`.  The current endpoint ABI emits the first
two principal powers.  The remaining operation should be a pointwise
`rho^0` extraction **after projection**, followed by rational
reconstruction in `p`; it is not a reason to materialize W.  Canonical
source Frobenius jets through order `rho^2` suffice.  If the projection is
performed on lower physical masters before the `d` factors, CF1 row 1 needs
one extra jet because `d1` has a simple soft pole.

The epsilon shifts in `d` also make the regular-path transport gap small:

| lower physical master | orders required | orders in current observable artifact | missing |
|---|---|---|---|
| CF1 row 1 | `0..5` | `0..5` | none |
| CF12 row 4 | `0..2` | `0..1` | `2` |
| CF21 row 1 | `0..4` | `0..4` | none |
| CF199 row 1 | `0..2` | `0..1` | `2` |
| CF199 row 2 | `0..3` | `0..2` | `3` |
| CF53 row 4 | `0..2` | `0..1` | `2` |
| CF53 row 5 | `0..3` | `0..2` | `3` |

Therefore CF12, CF199 and CF53 each need only one additional targeted
physical epsilon order for the listed rows.  Their existing maximum Chen
weights are already 5, 5 and 6 respectively; this is a demand extension,
not a new transport backend.

## Function classes and boundary periods

Every one of the five lower-family observable transports has coefficient
field `Rational`.  The soft mode systems are GPL-only:

- class 1: exponent `-2 eps`, no tangential kernel;
- class 5: zero normal exponent and tangential kernel
  `eps[-4/p-2/(p-1)-2/(p+1)]`;
- class 17: zero normal exponent and no tangential kernel;
- class 44: normalized normal residue

  ```text
  {{0,0},{-6,-4}},
  ```

  with mode frame columns `(2,-3)` and `(0,1)`, exponents `0` and
  `-4 eps`, and diagonal tangential kernels

  ```text
  eps[-4/p-2/(p-1)-2/(p+1)],
  eps[-4/p+2/(p-1)+2/(p+1)].
  ```

Thus the tangential alphabet is only `{0,1,-1}`.  No eMPL kernel and no
elliptic period coefficient occurs in this inherited projection.

The period pruning is:

- CF1 row 1 is the phase-space-volume anchor, not PID 1.  PID 1 belongs to
  CF1 row 2.
- CF12 class 5 has no candidate in `NullityPeriods.wl`.
- CF21 class 17 carries PID 6, but the CF21 realization transfer is exact
  and its free coefficient is exactly zero.  Its nonzero volume-driven
  particular solution, including the exact soft ratio
  `(2-3 eps)/(1-2 eps)`, must still be retained.
- Class 44 is structural PID 9 in the full 33-period census.  PID 9 is a
  two-dimensional-block candidate and consequently is absent from the
  present scalar 20-entry `LEDGER.md`; there is no `period_09.wl`
  evaluation.  Its zero mode is `(2,-3)`.

There is no exact on-disk realization transfer identifying the CF199 and
CF53 physical constants.  Class equality is not enough.  The honest formal
Stage-3 inputs are therefore two separate coefficient series,

```text
BoundaryPeriodCoefficient[{"CF199",9}, n],  n=-1..5,
BoundaryPeriodCoefficient[{"CF53", 9}, n],  n=-1..5.
```

They enter only through

```text
2 W_q[:,21] - 3 W_q[:,22],
2 W_q[:,29] - 3 W_q[:,30],       q=-3..3.
```

At the bounded `p=3` point, each projected mode has 16 nonzero principal
Laurent coefficients, so neither may be pruned.  This point check is only a
support/timing control; it is not used as an identity certificate.

## What is still missing

1. Generate the soft Frobenius/particular jets for these five lower-family
   realizations through the depths above.  The current observable artifacts
   start at regular interior points and are not endpoint-mode maps.
2. Extend the three indicated observable demands by one epsilon order.
3. Extract the projected `rho^0` W coefficient pointwise.
4. Either evaluate the two realization-local PID-9 series or keep them as
   the formal Stage-3 ledger entries already recorded in the artifact.

The bounded control
`Controls/t_cf303_inherited_soft_source_needs.wls` reads the seven gauge
rows lexically, derives the class-44 normal/tangential system, checks the
actual lower-family canonical row and observable-order mappings, and runs
one accepted deferred endpoint point.  It passes 15/15 checks in about five
seconds; the endpoint point itself takes about 2.6 seconds.
