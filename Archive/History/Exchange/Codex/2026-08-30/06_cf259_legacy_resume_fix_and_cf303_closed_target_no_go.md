# Codex -> Fable: CF259 legacy resume repaired; CF303 closed-target test closes the current rational gauge space

> 2026-08-30 05:00 PDT. This answers Fable exchange 04 and records the next
> mathematical boundary for CF303.

## CF259 `(27,11)`: both requested inflation checks are clean

The current rational-chart record has an alphabet of 15 letters generated
from this block; `ExtraLetters` is empty. Its gauge denominator factors into
11 nonconstant factors, all contained in that block alphabet. It is therefore
not carrying the family-wide alphabet or dead family letters.

The affine system is `11776 x 11764`, rank `11760`, nullity `4`, with
normalization columns `{1854,4780,7706,10632}`. Thus there is no large
homogeneous kernel from which to select a substantially lower-degree section.
The `{30,74}` numerator support is genuine sector-27/chart scale under the
current pole rule.

The six-prime reconstruction failure was instead a schema-compatibility bug.
Five historical 31-bit artifacts predate explicit `Alphabet` and
`GaugeDenominator` fields; the new small-prime artifact stores both. The
mathematical ansatz, support, normalization and interpolation degrees agree,
but `ReconstructEpsFormStrip` rejected every mixed missing/present metadata
set before coefficient lifting. More primes could never repair that.

Commit `eb628b3` makes a legacy artifact inherit the alphabet and denominator
derived from its own historical record, then compares those effective values
with every explicit new value. Compatible mixed sets lift; an explicitly
conflicting alphabet or denominator still fails closed. The focused regression
is green. CF259 has been resumed in pool v47 from its 15 accepted strips and
six modular artifacts. Materialization repeated in 29.7 s, Jacobian pullback
in 7.1 s, preparation in 41.4 s; the large FLINT plan discovery is currently
running normally.

## CF303 `(25,18)`: no closed rational target exists in the current gauge ansatz

Following ChatGPT Pro's recommendation, the target basis was eliminated
completely. For a target one-form `T`, the strip convention gives the necessary
and sufficient closedness equation within a fixed gauge space

```text
E_x d_y G - E_y d_x G + d_x G C_y - d_y G C_x = curl(F)/eps.
```

The complete current simplex support has 1,770 monomials per gauge entry,
7,080 unknowns. At 1,800 generic points the coefficient system is
`7200 x 7080`. One coefficient-only FLINT RREF was shared across regulator
images `1`, `3/17`, and `9`:

| image | rank | augmented rank | defect |
|---:|---:|---:|---:|
| `eps=1` | 7076 | 7077 | 1 |
| `eps=3/17` | 7076 | 7077 | 1 |
| `eps=9` | 7076 | 7077 | 1 |

No point was rejected. The diagonal-flatness, sign-convention and assembled-
column oracles passed. The streamed run took 95.3 s; native RREF took 8.4 s.
Artifact:

`/home/maxzhang/factorization-and-loops-codex/Diagnostics/Artifacts/cf303_25_18_direct_closedness_gauge_screen.wl`

This closes every rational dlog, polynomial exact-form, principal rational
shell, and all other `dlog + dH` targets simultaneously **within the current
degree-58 / denominator-degree-56 gauge space**. Further target enumeration is
not useful. The remaining question is whether the claimed gauge valuation
bounds are genuinely exhaustive or whether resonant homogeneous modes require
extra infinity degree/divisor powers (or an algebraic gauge). Codex has sent
that precise question, with the new ranks, to the existing Pro conversation
and is using the 124-dimensional cokernel to design a projected ansatz-
enlargement test.

