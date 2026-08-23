# Exact CF231/CF305 Kallen23 adjacent-strip audit

Date: 2026-08-19

## Scope and analytic status

This audit concerns the adjacent block pair `(8,7)` in the Kallen23 chart.
Every reported matrix, factor, degree, and identity was obtained from exact
rational expressions. No floating-point kinematic samples were used. The
Wolfram/CANONICA calls return analytic rational functions and polynomial
identities, not numerical values.

The retained family checkpoints were found before any reconstruction:

- CF231: `/home/maxzhang/FACET/Codex/General/LibraTwoRootBlockwise_20260819/blockwise_local_CF231.wl`, SHA256
  `6bd2983d35641b42c0965616869fd673b49331371bf97a1494122fe7f0aad1c1`.
- CF305: `/home/maxzhang/FACET/Codex/General/LibraTwoRootBlockwise_20260819/blockwise_local_CF305.wl`, SHA256
  `dac3485a36d6f80a60d1deea933ae0aaa4f80365d3f7a4b1eebfd3d2c7dbaa95`.

The exact strip was extracted from these checkpoints; no family differential
equation was regenerated. The exchange packet's concatenated source file names
the CF231 checkpoint in its manifest but does not contain a corresponding
`BEGIN FILE` body. The retained checkpoint above supplies the missing exact
record.

The older family ledger entries `CF231 -> ChartPullBackFailed` and
`CF305 -> AssemblyFailed` predate these retained 2026-08-19 records. The hard
class ledger establishes the exact class-79 diagonal epsilon form; it does not
contain the adjacent `(8,7)` rational gauge.

## Kinematics and strip

The chart variables are `(y,s)`. With

```text
x23 = (s - 3) (1 + s - 2 y)/(s^2 - 1),
v   = -x23 y,
w   = (1 - x23) (1 - y),
```

the signed rational roots retained by `TransportCharts.wl` are

```text
sqrt(lambda2) = x23 - y,
sqrt(lambda3) = (1 + y) + s (x23 - 1).
```

These signs specify the chart branches used in the records. No crossing or
additional analytic continuation was applied in this audit.

For `mu` equal to `y` or `s`, the recovered strip is

```text
d_mu J8 = epsilon E_mu J8 + Bbar_mu J7,
d_mu J7 = epsilon C_mu J7.
```

| representative | ambient matrices | blocks | target rows | source rows | E_mu | C_mu | Bbar_mu |
|---|---:|---:|---|---|---|---|---|
| CF231 | 23 x 23 | 12 | 12--15 | 8--11 | two 4 x 4 | two 4 x 4 | two 4 x 4 |
| CF305 | 32 x 32 | 19 | 12--15 | 8--11 | two 4 x 4 | two 4 x 4 | two 4 x 4 |

Both checkpoints record `<|Pair -> {8,7}, Axis -> 1, Reason -> "TimedOut"|>`.
That is the unresolved rational-gauge step, not a missing differential system.

The completeness criterion was: both directions are present with the stated
shapes; `E_mu` and `C_mu` are epsilon-independent; and every entry of

```text
d_y E_s - d_s E_y + epsilon (E_y E_s - E_s E_y),
d_y C_s - d_s C_y + epsilon (C_y C_s - C_s C_y),
d_y Bbar_s - d_s Bbar_y
  - epsilon (E_y Bbar_s - Bbar_s C_y)
  + epsilon (E_s Bbar_y - Bbar_y C_s)
```

vanishes after exact rational cancellation. The measured result is `True` for
all three identities in both representatives. Therefore each exact two-PDE
strip record is complete. This does not mean that the rational gauge has been
found.

## Finite denominator divisors

Factors are listed up to multiplication by a nonzero rational number. Define

```text
f1  = s - 1
f2  = s + 1
f3  = s - 3
f4  = y
f5  = y - 1
f6  = -1 - s + 2 y
f7  = 1 + s - 3 y + s y
f8  = -2 - 2 s + 5 y - 2 s y + s^2 y
f9  = -1 - 2 s - s^2 + 5 y - 2 s y + s^2 y
f10 = 3 + 2 s - s^2 - 7 y + 2 s y + s^2 y
f11 = -3 - 2 s + s^2 + 5 y - 2 s y + s^2 y
f12 = -3 - 2 s + s^2 + 8 y - 6 y^2 + 2 s y^2
qeps = (-9 - 6 s + 3 s^2 + 15 y - 6 s y + 3 s^2 y)
     + epsilon (-13 - 10 s + 3 s^2 + 25 y - 10 s y + 5 s^2 y).
```

In the tables, `(p_y,p_s)` is the maximal denominator power in the `y`- and
`s`-direction matrices. Because the CF231 and CF305 strips are exactly
entrywise equal, every row applies separately to both representatives.

### Upper diagonal E

| divisor | `(p_y,p_s)` | maximal order |
|---|---:|---:|
| `f1` | `(0,1)` | 1 |
| `f2` | `(0,1)` | 1 |
| `f3` | `(0,1)` | 1 |
| `f4` | `(1,0)` | 1 |
| `f5` | `(1,0)` | 1 |
| `f6` | `(1,1)` | 1 |
| `f7` | `(1,1)` | 1 |
| `f8` | `(1,1)` | 1 |
| `f9` | `(1,1)` | 1 |
| `f10` | `(1,1)` | 1 |

There are 10 irreducible divisors and the maximal finite pole order is 1.

### Lower diagonal C

| divisor | `(p_y,p_s)` | maximal order |
|---|---:|---:|
| `f1` | `(0,1)` | 1 |
| `f2` | `(0,1)` | 1 |
| `f3` | `(0,1)` | 1 |
| `f4` | `(1,0)` | 1 |
| `f5` | `(1,0)` | 1 |
| `f6` | `(1,1)` | 1 |
| `f7` | `(1,1)` | 1 |
| `f8` | `(1,1)` | 1 |
| `f10` | `(1,1)` | 1 |
| `f11` | `(1,1)` | 1 |
| `f12` | `(1,1)` | 1 |

There are 11 irreducible divisors and the maximal finite pole order is 1.

### Forcing Bbar

| divisor | class | `(p_y,p_s)` | maximal order |
|---|---|---:|---:|
| `f1` | kinematic, epsilon-free | `(0,1)` | 1 |
| `f2` | kinematic, epsilon-free | `(0,1)` | 1 |
| `f3` | kinematic, epsilon-free | `(1,2)` | 2 |
| `f4` | kinematic, epsilon-free | `(2,1)` | 2 |
| `f5` | kinematic, epsilon-free | `(1,0)` | 1 |
| `f6` | kinematic, epsilon-free | `(2,2)` | 2 |
| `f7` | kinematic, epsilon-free | `(1,1)` | 1 |
| `f8` | kinematic, epsilon-free | `(3,3)` | 3 |
| `f10` | kinematic, epsilon-free | `(2,2)` | 2 |
| `f11` | kinematic, epsilon-free | `(1,1)` | 1 |
| `f12` | kinematic, epsilon-free | `(1,1)` | 1 |
| `epsilon` | epsilon-only | `(1,1)` | 1 |
| `1 + epsilon` | epsilon-only | `(2,2)` | 2 |
| `1 + 2 epsilon` | epsilon-only | `(2,2)` | 2 |
| `1 + 4 epsilon` | epsilon-only | `(2,2)` | 2 |
| `3 + 5 epsilon` | epsilon-only | `(1,1)` | 1 |
| `qeps` | mixed kinematic--epsilon | `(2,2)` | 2 |

There are 17 irreducible divisors and the maximal finite pole order is 3.
The epsilon-dependent factors are present in the exact forcing and must not be
discarded when constructing a general rational ansatz.

## Bidegrees and infinity

Each bidegree is `(deg_y,deg_s)`. Entries in the numerator, denominator, and
growth columns are componentwise maxima over nonzero matrix entries. `Ntot` and
`Dtot` are maximal total degrees; `gtot` is the maximal total-degree
difference. The infinity pole is the pole order of the one-form in its own
axis, so coefficient growth zero gives a second-order one-form pole.

| object | direction | numerator | denominator | growth | `Ntot/Dtot/gtot` | own-axis growth | one-form pole at infinity | Fuchsian there |
|---|---|---|---|---|---|---:|---:|---|
| `E` | `y` | `(6,8)` | `(7,8)` | `(-1,0)` | `13/14/-1` | -1 | 1 | yes |
| `E` | `s` | `(5,10)` | `(5,11)` | `(0,-1)` | `14/15/-1` | -1 | 1 | yes |
| `C` | `y` | `(4,5)` | `(5,5)` | `(-1,0)` | `7/8/-1` | -1 | 1 | yes |
| `C` | `s` | `(4,6)` | `(4,8)` | `(0,-1)` | `9/10/-1` | -1 | 1 | yes |
| `Bbar` | `y` | `(15,22)` | `(16,22)` | `(0,0)` | `34/35/-1` | 0 | 2 | no |
| `Bbar` | `s` | `(14,24)` | `(14,25)` | `(1,-1)` | `35/36/-1` | -1 | 1 | yes |

Thus both diagonal connections are Fuchsian at infinity in both directions.
The forcing has a second-order one-form pole at `y = infinity` and a simple
one-form pole at `s = infinity`.

## Exact CF231 to CF305 transformation

Let `D_i^F` denote the Kira propagator with index `i` in family `F`. The loop
change of variables is simply

```text
ke <-> kf.
```

With generic independent external--loop scalar products, exact polynomial
expansion gives

```text
D_i^CF231(ke <-> kf) = D_sigma(i)^CF305,
sigma = (2,1,3,5,4,7,8,9),  i = 1,...,8.
```

The cut indices map as `{1,2,8} -> {2,1,9}`. Since no quadratic denominator is
multiplied by a negative constant, the inherited causal prescriptions and cut
orientations are unchanged. CF305 denominator 6 is absent from this quadratic
image.

The CF231 ninth entry is the irreducible scalar product `kb.ke`. After the loop
swap,

```text
2 kb.kf = D4^CF305 - D6^CF305 + ffecfp1 - ffecfp3,
```

where `ffecfp1 = 2 ka.kb` and `ffecfp3 = 2 kb.kc`. Consequently this is an
exact denominator-set embedding, not denominator-set equality for arbitrary
powers of the CF231 scalar product.

Every retained CF231 master has `a9 = 0`. On that restricted powered-integral
family the exact map is

```text
(a1,a2,a3,a4,a5,a6,a7,a8,0)_CF231
  -> (a2,a1,a3,a5,a4,0,a6,a7,a8)_CF305.
```

All 23 mapped indices occur in the 32-master CF305 basis. Their positions in
CF231 order are

```text
{17,18,19,20,32,6,7,10,11,12,13,21,15,16,22,23,28,29,30,31,25,26,27}.
```

For this exact position list `P`, both identities

```text
A_v^CF231 = A_v^CF305[[P,P]],
A_w^CF231 = A_w^CF305[[P,P]]
```

hold entrywise, and the `P` rows into the 9-master complement vanish in both
directions. This proves exact differential-equation closure and the displayed
powered-master equivalence. It is stronger than a comparison at selected
kinematics and weaker than equality of the unrestricted denominator sets.

## Rational-gauge comparison

After symbol normalization,

```text
E_CF231    == E_CF305,
C_CF231    == C_CF305,
Bbar_CF231 == Bbar_CF305
```

entrywise as exact rational functions in `(y,s,epsilon)`. Therefore neither
representative has a smaller local rational-gauge problem: dimensions,
divisors, maximal pole orders, bidegrees, infinity behavior, and residue system
are identical.

The current `EpsFormStrip.wl` residue alphabet is exactly

```text
{s-3, s-1, s, s+1, 1+s-2y, y-1, y, 1+s-3y+s y,
 f8, f9, f11, f10, f12},
```

so it has 13 letters and 208 raw constant residue entries (`13 x 4 x 4`). The
routine intentionally removes epsilon-dependent factors from this alphabet;
in particular, it omits the five epsilon-only forcing factors and `qeps`.

Acceptance criterion for the residue run: construct the exact affine residue
solution and verify its two-variable compatibility entrywise within 1200 s.
Measured result: the calculation reached the bound after 1200.139552 s. Hence
the free residue-parameter count is unavailable; neither zero nor any numerical
rank estimate is substituted for it.

CF231 should be solved first. There is no smaller local strip, but CF231 has the
smaller ambient record (23 masters and 12 blocks rather than 32 masters and 19
blocks). An exact CF231 gauge can then be carried to the closed CF305 subsystem
by the displayed master permutation and checked against the independent CF305
checkpoint.

## Provenance and artifacts

Principal shared inputs, read without modification:

- `FeynFacet/Private/EpsFormStrip.wl`, SHA256
  `8568b49375e812445e1572f8692997ab7710a53bafdbea38e9b25659ff2063a1`.
- `FeynFacet/Private/TransportCharts.wl`, SHA256
  `5dcac93dfb15dfec8c6e89f7110d39eff3c647143bd4d32ef962ce34fd196361`.
- Kira `integralfamilies.yaml`, SHA256
  `3afbb5e6bbc331bad30f9c0a639bd4c4c0c681d9f7a8c39ef8ec203967b8b713`.
- `nnlo_de_CF231.wl`, SHA256
  `a3b5c9aa6462a0aee6d68c112679ba8e870af2f56495237e0a9a64bad60860cc`.
- `nnlo_de_CF305.wl`, SHA256
  `421ad82ef9620b2d4ccf1cc3a9d2706f2da8afdf21c47a4c7d4ed1c18e3e8c4e`.

Created only under `/home/maxzhang/factorization-and-loops/Codex/TwoRootCF231Audit/`:

- `audit_cf231_cf305.wls`: reproducible exact extraction, divisor census,
  infinity census, family-map identities, subsystem identities, and bounded
  residue calculation.
- `CF231_8_7_exact_strip.wl`: full exact CF231 `(8,7)` two-PDE strip.
- `CF305_8_7_exact_strip.wl`: full exact CF305 `(8,7)` two-PDE strip.
- `CF231_CF305_exact_audit.wl`: machine-readable census, identities, source
  hashes, and residue status.
- `residue_compatibility_summary.wl`: bounded residue result and exact pre-solve
  alphabet counts.
- `AUDIT.md`: this report.

No shared package, ledger, script, result, or notebook was modified.
