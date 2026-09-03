# CF303 deferred soft-residue point ABI

`cf303_deferred_soft_residue_point.py` computes the normal residue of the
accepted path-gauge `G25` final layer at

```text
u = 2 p,  rho = 2 p - u.
```

It does not form a symbolic connection. At one modular `p` point it combines
the four mathematically distinct parts of the accepted circuit:

1. the ordinary accepted `K` terms in the 76-entry deck;
2. all twelve exact exception `K` leaves;
3. all 98 recurrence-generated cross-`K` records; and
4. both block-1 rows from the accepted point resolver.

Only letters with a pole at `u=2p` cause their coefficient to be parsed. In
the original deck these are the 38 `GPLPole[2p]` terms; the other 1,112 terms
are skipped. Cross-`K` and block 1 are reduced directly from their ascending
numerator/denominator arrays. A net pole of order greater than one is a typed
failure.

The result is a Laurent deck indexed by epsilon order, target master, and
source master. Every value retains two coefficient-field components in each
of the rational and elliptic channels. The latter means the coefficient of
`du/Y`; it is not divided by an arbitrary square root. The endpoint curve is

```text
P4(2p) = 64 p^2 (1-p^2),
```

and the physical sheet remains explicit in the ABI even though it drops out
at both accepted control points.

The same payload contains the compact physical endpoint map

```text
W = [T25 H, T25],   I25 = T25 (G25 + H F_source).
```

It records the valuation, leading coefficient, and negative-power Laurent
terms for each nonzero coordinate, rather than expanding a matrix-valued
symbolic expression. Before multiplication all 112 nonzero `H` coordinates
have a double pole. After the exact epsilon convolution and `T25` left
multiplication, the source block has 61 double-pole, 58 simple-pole, and 14
regular coordinates; seven of the 140 possible coordinates vanish. Its
principal deck has 61 `rho^-2` and 119 `rho^-1` terms. The final `T25` block
has ten regular nonzero coordinates and two zeros. Thus real cancellations
occur, especially in physical row 44, but 61 double poles survive and cannot
be replaced by a finite endpoint value. All these coefficients are also
rational/base-only at both controls.

## Bounded controls

The committed control uses the two independently accepted point payloads:

| `(p, epsilon)` | base | exceptions | cross-K | block 1 | combined | field |
|---|---:|---:|---:|---:|---:|---|
| `(3, 1/7)` | 182 | 84 | 98 | 14 | 280 | rational/base only |
| `(239/47, 5/17)` | 182 | 84 | 98 | 14 | 280 | rational/base only |

There are 40 nonzero coordinates at each order `-2..4` and none at order
`-3`. After epsilon specialization, the `2 x 43` incoming block has 40/86
nonzero entries and rank 2 at both points. Against the independently
extracted 43-row source residue, `rank(Rs)=7`, the incoming block adds two
independent directions on `ker(Rs)`, and the full 45-row residue has rank 9.
The nullities of its first four powers are `{36,38,38,38}`, establishing two
length-2 zero Jordan chains at both controls.

The independently extracted source residue used by this bounded rank control
is stored repo-relatively as 180 one-based sparse triples in
`Artifacts/CF303SoftSourceResidueQ7.json`; the same exact source matrix occurs
at both accepted points. The control has no dependency on a user-specific
filesystem path.

The residue deck alone takes approximately 0.64--0.76 seconds per point;
parsing the accepted deck takes about 0.59 seconds, while the actual cross-`K`
plus block-1 endpoint reduction takes about 0.002 seconds. Constructing the
additional physical endpoint map takes 1.75--1.79 seconds, for a complete ABI
time of 2.39--2.49 seconds per point. The control stays below 100 MiB RSS.

Run it with

```bash
python3 Scripts/Transport/CF303/cf303_deferred_soft_residue_point.py \
  --p 3 --output /tmp/cf303_soft_residue_p3.json
```

## Why the raw-connection shortcut is not the primary route

For the pre-path-gauge system, `Res(dH)=0`, so its raw incoming residue can be
obtained from the ordinary and exception `K` leaves plus block 1, without the
98 cross-`K` terms. This is useful as an independent comparison.

It does not by itself rebase physical endpoint modes into the stored lazy
`G` transport. In both accepted point payloads every one of the 112 nonzero
`H` components has a double pole at `u=2p`. Consequently `F25=G25+H L`
requires its full `rho^-2` and `rho^-1` action on source Frobenius modes;
there is no finite endpoint matrix `H(0)` to apply. The complete `G` residue
above avoids silently dropping that singular mode mixing.

This ABI is modular point data, not a characteristic-zero reconstruction.
It is designed to feed adaptive reconstruction or independent point checks
without assigning finite-field representatives the meaning of rational
numbers.
