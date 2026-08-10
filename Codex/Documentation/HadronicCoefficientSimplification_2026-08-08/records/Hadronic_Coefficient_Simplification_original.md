# Hadronic-variable reduction of hard coefficients

## Objective

The hadronic basis vectors are eliminated in favor of the partonic invariants
`s`, `t`, `u`, the momentum fractions `xa`, `xb`, `zh`, and the two transverse
spin angles.  After summing every contribution to a given master integral, the
coefficient must have the form

```text
f1[xa] f1[xb] D1[zh] / (xa xb zh^2) * H(s,t,u,Epsilon,...)
```

for the unpolarized channel.  The hard coefficient `H` must be independent of
`xa`, `xb`, `zh` and of the auxiliary hadronic vectors.  This statement is
checked as an exact algebraic identity, not by numerical sampling.

## Hadronic variables in the cards

The UU and TT cards contain exact light-cone coordinates for

```text
Pa, Pb, Ph, nh, nhb, STvec, SThvec
```

directly in terms of `s`, `t`, `u`, `xa`, `xb`, `zh`, `phi_a`, and `phi_h`.
No rapidity or transverse-momentum magnitude is introduced as an intermediate
symbol.  Positivity and reality assumptions also reside in the card.

## Algebra inherited from the original real-emission notebook

The original notebook did not rely on one global `Simplify`.  Before phase
space integration it collected in a kinematic basis and simplified each
coefficient with

```mathematica
FactorTerms[Cancel[Together[coefficient]]]
```

After inserting analytic angular integrals, it collected first in composite
`Beta[...] Hypergeometric2F1[...]` objects and then in the individual `Beta`
and `Hypergeometric2F1` objects.  Each rational coefficient was transformed by

```mathematica
Factor[Cancel[Together[coefficient]]]
```

before a final assumption-aware `Simplify`.

The scalable implementation preserves this ordering in a restricted form:

1. substitute the exact hadronic coordinates;
2. apply only the certified physical-branch rules;
3. freeze nonrational analytic objects;
4. merge the remaining rational expression with `Cancel`/`Together`;
5. reconstruct the analytic objects and collect the historical functional
   basis;
6. apply bounded assumption-aware simplification;
7. verify the transformed expression against the input exactly.

## NLO UU measurement

For the 5 by 5 diagram set:

| quantity | result |
|---|---:|
| pair construction | 13.35 s |
| Kira reduction | 50.18 s |
| targets | 77 |
| topology classes | 8 |
| masters | 6 |
| hadronic substitution | 2.01 s |
| complete-target cleanup | 6.65 s |
| complete-master cleanup | 9.04 s |
| complete coefficient stage | 48.55 s |
| final serialized size | 170,483 bytes |

The extracted common factor is

```mathematica
CF Pi^(3 + Epsilon) alpha_s^3 D1[zh] f1[xa] f1[xb]/(xa xb zh^2)
```

All six hard coefficients are exactly free of the three momentum fractions and
the hadronic basis vectors.

For the 10 by 10 set, the measured orderings were:

| ordering | time | final master size |
|---|---:|---:|
| pair first | 43.40 s for pair cleanup | 1.574 MB |
| target first | 23.72 s for target cleanup | 1.549 MB |
| target then master | 62.13 s total | 1.036 MB |
| master first | one coefficient exceeded 281 s | unfinished |

Thus the complete-target transformation is the efficient first nontrivial
algebraic step.  A bounded master-level transformation remains useful for the
final size but is not used as the first step.

## NLO TT measurement

The BMHV tensor reduction was corrected so that loop-free factors retain the
original dimension `D`, while the evanescent tensor monomial is reduced by the
appropriate Tarasov shift.  Exact tensor identities were evaluated before the
full TT run.

For the 5 by 5 set:

| quantity | result |
|---|---:|
| target input size | 139,298,664 bytes |
| target output size | 10,562,384 bytes |
| target time | 52.02 s on four kernels |
| master time | 30.36 s on four kernels |
| masters | 6 |
| final file size | 750,504 bytes |

The independent angular basis is

```mathematica
{Cos[phi_a] Cos[phi_h], Sin[phi_a] Sin[phi_h]}
```

The two mixed sine-cosine structures vanish exactly.  Every accepted final
transformation obeys an exact assumption-aware equality, and every hard
coefficient is free of `xa`, `xb`, and `zh`.

## NNLO UU representation

There are 44,877 Kira targets and 342 masters.  A stratified sample of 125
complete targets, chosen by expression size, additive-term count, Kira fanout,
pair-batch count, and median size, changed from 52,630,888 bytes to 559,984
bytes in 30.45 s on four kernels.  No target timed out or returned an inexact
number.  The only noninteger fraction dependence consists of explicit
half-integer Laurent powers of `xa` and `xb`; no fraction-dependent logarithm,
Gamma function, or hypergeometric function was found.

The complete-master calculation uses the positive-root variables

```text
xa = ya^2,  xb = yb^2,  zh = yh^2,
```

so every allowed half-integer Laurent power becomes an integer Laurent
monomial.  After the distributions are stripped, a complete master column is
represented as

```text
F(y) = N(y) / L(y),   y = (ya,yb,yh),
```

where `N` and `L` are sparse polynomials in `y` over the field of expressions
in the partonic invariants, `Epsilon`, color factors, and inert analytic
objects.

The expected universal monomial is

```text
U(y) = ya^(-2) yb^(-2) yh^(-4).
```

To prove `F(y)=U(y) H`, form the coefficient maps of `N(y)` and `U(y)L(y)`.
After multiplying both by a common Laurent monomial so that all exponents are
nonnegative, choose a nonzero coefficient `v0` of `U L`.  The identity holds
if and only if

```text
n_v v0 - n0 v_v = 0
```

for every exponent vector `v`.  Each zero is tested by exact rational
reduction.  The resulting `H=n0/v0` must be free of `xa`, `xb`, `zh`,
`ya`, `yb`, and `yh`.

The complete target-to-master map was then examined without forming the sum of
all 342 master coefficients.  Three masters were selected by the number of
target leaves entering their coefficients: one small master, one median
master, and the largest master in the catalogue.  The coefficientwise
universal-factor identity was established independently for every selected
entry before any entries were added.

### Positive-root fraction algebra

The Kira image coefficients contain half-integer powers not only of one
momentum fraction, but also of positive monomials such as

```mathematica
Sqrt[xa/(s xb)]
(s/(xa xb))^(5/2)
(xb/(s xa))^(3/2)
```

For `s>0`, `xa>0`, and `xb>0`, each monomial is decomposed into a
fraction-independent positive coefficient and integer powers of the three
fractions.  Only the fraction monomial is replaced by integer powers of
`ya`, `yb`, and `yh`.  A non-monomial base such as `xa+xb` is rejected.  No
`PowerExpand` identity is used.

The exact test set contains 29 identities.  It checks integer and half-integer
leaves, positive monomial roots, rejection of non-monomial roots,
distribution-factor counting, sparse polynomial arithmetic, denominator
normalization, divisibility, and exact reconstruction.  All 29 results are
`True`.  The same code reconstructs all six real NLO UU master coefficients,
extracts

```mathematica
f1[xa] f1[xb] D1[zh]/(xa xb zh^2),
```

and proves the remaining coefficient independent of `xa`, `xb`, and `zh`.

### Kira closure conditions

For every physical target `T`, the Kira map must satisfy one of two mutually
exclusive conditions:

1. a stored rule `T -> R[T]` exists;
2. `T` is one of the declared master integrals, in which case `R[T]=T`.

A missing rule for a non-master aborts the shard.  Every integral remaining
in `R[T]` must also belong to the declared master set.  Repeated rules are
allowed only when their right-hand sides are structurally identical.  These
conditions prevent an absent reduction row from being mistaken for a zero
contribution.

### Exact entrywise cleanup at NNLO

The selected columns contain 38,460 target leaves arranged into 38,400
denominator entries.  Each entry is treated independently:

1. reconstruct its exact rational function in the positive fraction roots;
2. prove and divide out the universal fraction monomial;
3. write `s = rs^2`, with `rs > 0`, so every allowed half-integer power of the
   positive partonic invariant becomes an integer Laurent power of `rs`;
4. apply exact rational cancellation in `rs`;
5. descend back to the `s` ring only after checking invariance under
   `rs -> -rs`;
6. store the numerator and denominator separately.

No numerical reconstruction or `PowerExpand` identity is used.  The complete
entrywise calculation took 1,304.64 s on eight kernels.  Its serialized size
changed from 859,107,253 bytes to 131,787,741 bytes, a factor of 6.52.  An
independent audit checked every source hash, numerator hash, denominator hash,
entry count, and leaf count.  It also found exact data only, no momentum
fractions or auxiliary roots, nonzero denominators, and integer powers of `s`.

### Exact denominator consolidation

For exact equal denominators `d`, the only addition used is

```text
Sum_i n_i/d = (Sum_i n_i)/d.
```

A SHA-256 hash indexes possible equal-denominator classes, but the hash is not
used as an equality proof.  Structural equality is checked within every hash
class.  Each resulting rational function is reduced by exact `Cancel`.

The measured results are:

| master | input entries | target leaves | final fractions | serialized output |
|---|---:|---:|---:|---:|
| small | 1 | 1 | 1 | 3,776 bytes |
| median | 93 | 93 | 8 | 55,047 bytes |
| largest | 38,306 | 38,366 | 6,290 | 488,886,853 bytes |

For the median master, 11 initial denominator classes reduce to 8 fractions;
the complete coefficient is 25,328 bytes and differs exactly by zero from the
eight-fraction representation.

For the largest master, three iterations give

```text
38306 -> 6625 -> 6298 -> 6290 fractions.
```

The exact calculation took 6,375.22 s.  Although the fraction count falls by
84 percent, the in-memory size grows from 422,282,520 bytes to
1,727,567,608 bytes because adding large numerators destroys repeated local
factorization.  The serialized result is 488,886,853 bytes.  Therefore this
consolidation is mathematically useful as an index of distinct denominators,
but it is not the preferred storage representation for a hard NNLO
coefficient.  The 131.8 MB entrywise store remains the compact exact source.

The independent assembled-coefficient audit took 54.05 s.  It found 6,290
distinct final denominator hashes for the largest master, exact data only,
no momentum-fraction roots, integer powers of `s`, and no failed or timed-out
cancellation.  The small and median whole coefficients both gave exact zero
differences from their stored fraction sums.

### Size-monotone denominator consolidation

The eager calculation above always retained `Cancel[numerator/denominator]`.
That choice is exact but need not be compact.  The improved calculation forms
both

```text
raw       = {Sum_i numerator_i, denominator},
cancelled = NumeratorDenominator[Cancel[(Sum_i numerator_i)/denominator]],
```

and retains the pair with smaller `ByteCount`.  A one-entry denominator class
is left unchanged.  Structural denominator equality is checked inside the
eight workers rather than in a serial preparation step.

For the largest selected master:

| quantity | eager cancellation | size-monotone cancellation |
|---|---:|---:|
| wall time | 6,375.22 s | 1,260.22 s |
| final fractions | 6,290 | 6,557 |
| in-memory fraction data | 1,727,567,608 bytes | 351,559,840 bytes |
| serialized result | 488,886,853 bytes | 99,892,985 bytes |

The first size-monotone iteration gives 230 exact zeros, selects 207 cancelled
forms and 3,694 raw sums, and leaves 2,739 singleton fractions unchanged.  The
second iteration removes one further exact zero and ends with 6,557 distinct
denominators.  The input has 38,306 fractions and occupies 422,282,520 bytes,
so the derived representation decreases both count and size.

An independent audit took 7.66 s and checked source coverage, file hashes,
exact arithmetic, distinct output denominators, absence of momentum fractions
and temporary roots, integer powers of `s`, and nonzero denominators.  The
small and median whole-coefficient differences are exactly zero.

The entrywise 131.8 MB store remains the provenance record for the three
selected masters.  The 99.9 MB size-monotone hard-master file is the preferred
derived representation for subsequent analytic work.  The larger eager file
is retained only as an independently checked comparison.

Pro independently recommended that a further compression study begin with
the rational change of variables

```text
x = -t/s,  y = -u/s,
```

followed by extraction of the exact integer power of `s`, denominator-only
factorization, and a shared denominator-factor dictionary.  The complete
measurements and exact reconstruction tests are given below.

### Exact scale separation

Define

```text
x = -t/s,  y = -u/s,
```

with inverse map `t=-s x`, `u=-s y`.  The physical chamber becomes

```text
s > 0,  x > 0,  y > 0,  x+y < 1.
```

For every stored numerator and denominator, a recursive homogeneity test
determines its integer degree in `s` after the substitution.  The test accepts
only sums whose terms have one common degree, products whose factor degrees
are all known, and integer powers of homogeneous expressions.  It therefore
establishes, rather than assumes,

```text
H_m(s,t,u,Epsilon) = s^p_m Hhat_m(x,y,Epsilon).
```

The three selected masters have `p_m = 4, 2, -2`, respectively.  A scale power
is derived separately for each master and is never copied from another master.
No logarithm, square root, or noninteger power is transformed, and no
`PowerExpand` identity is used.

For the largest selected master, scale separation changes

| quantity | physical variables `s,t,u` | dimensionless variables `x,y` |
|---|---:|---:|
| fractions | 6,557 | 6,557 |
| distinct denominator hashes | 6,557 | 5,974 |
| in-memory fraction data | 351,559,840 bytes | 296,802,344 bytes |
| serialized data | 99,892,985 bytes | 92,385,524 bytes |

The normalization took 430.91 s on eight kernels.  A second size-monotone
equal-denominator calculation reduced the dimensionless result to 5,973
fractions and 296,275,768 in-memory bytes; its serialized file is 92,241,826
bytes.  That calculation took 904.57 s.

An independent complete replay took 943.22 s.  It rebuilt all three selected
coefficients from the dimensionless source, repeated every exact
equal-denominator replacement, and compared the complete saved fraction
multisets structurally.  All master labels and scale powers were identical,
all final denominators were distinct and nonzero, and every saved fraction was
identical to the independently rebuilt fraction.  Thus the largest selected
coefficient is certified in the form

```text
H_m(s,t,u,Epsilon) = s^(-2) Sum_j N_j(x,y,Epsilon)/D_j(x,y,Epsilon),
                     j = 1,...,5973.
```

The 6,557-fraction `s,t,u` form remains the independent physical-variable
reconstruction source.  The 5,973-fraction `x,y` form is the preferred working
form for differential equations, boundary limits, and singular-locus analysis.

### Exact denominator-factor inventory

Every one of the 5,973 dimensionless denominators is a polynomial in `x,y`
over the coefficient field `Q(Epsilon)`.  Each denominator was factored over
that field by first separating the part independent of `x,y`, factoring each
remaining polynomial, and normalizing every factor to be monic in a fixed
`x,y` monomial order.  Exact reconstruction was checked for all 5,973
denominators.

The complete calculation took 27.94 s on eight kernels and found only 30
distinct `x,y`-dependent factors.  The most frequent factors are

| factor | number of denominators containing it |
|---|---:|
| `x` | 5,703 |
| `1-x-y` | 4,437 |
| `1-y` | 4,313 |
| `y` | 2,297 |
| `x+y` | 1,711 |
| `1-x` | 1,216 |
| `1+x-y` | 527 |

The remaining 23 factors and their exact recurrence counts are stored in
`FactorInventory.wl`.  This small alphabet is useful for constructing the
candidate singular set of the differential equations.  It does not justify a
separate denominator-dictionary storage format: the complete dictionary file
is 91,385,453 bytes, only 0.93 percent smaller than the direct 92,241,826-byte
dimensionless coefficient.  The direct fraction list therefore remains the
working coefficient, while the factor inventory is retained as analytic
metadata.

## Recommended ordering

For NLO UU and TT, transform complete targets first, then compose the master
coefficients and apply a bounded final coefficient cleanup.  This order is
both faster and smaller than beginning with complete master coefficients.

For NNLO UU, first remove the hadronic variables entry by entry and reduce in
the positive-`s` root ring.  Keep that entrywise form on disk.  For a chosen
master, merge exact equal-denominator classes with the size-monotone rule,
derive its integer scale power, and work with the dimensionless `x,y`
coefficient after the complete replay audit.  A global `Together` of the
largest master is not attempted: the eager 6,290-fraction result shows that
count reduction alone does not imply a smaller analytic expression.  No
further coefficient-level simplification is recommended after the audited
5,973-fraction form.

## Exact acceptance criteria

A transformed result is retained only when all of the following hold:

1. no machine-precision number appears;
2. no hadronic basis vector remains after the card substitution;
3. no fraction-dependent analytic object appears outside the allowed explicit
   half-integer Laurent powers;
4. every local reconstruction equals its input exactly;
5. each final complete master satisfies the coefficientwise universal-factor
   identity;
6. the extracted hard coefficient is independent of all momentum fractions;
7. every extracted scale power follows from an exact homogeneity test;
8. a bounded final `Simplify` is retained only when exact equality is checked
   and its byte count does not increase.
