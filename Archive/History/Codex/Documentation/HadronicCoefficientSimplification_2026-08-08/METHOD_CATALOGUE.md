# Complete method catalogue

## Algebraic position relative to IBP

For an amplitude and conjugate-amplitude pair `(p,q)`, write

```text
A_p A_q^* = Sum_T c_T^(pq) T,
T = Sum_m R_Tm M_m.
```

The final coefficient of master `M_m` is

```text
C_m = Sum_(p,q,T) c_T^(pq) R_Tm.
```

- **Pair first** simplifies each `c_T^(pq)` before equal targets are summed.
- **Target first** forms `c_T = Sum_(p,q) c_T^(pq)`, simplifies `c_T`, and
  then inserts the Kira rules `R_Tm`.
- **Master first** forms `C_m` and only then simplifies it.
- **Target then master** applies target first and subsequently one bounded
  cleanup to each composed `C_m`.

The Kira rules already exist for all these comparisons.  Target-first cleanup
is pre-substitution; final-master cleanup is post-substitution.  The NNLO
selected-column calculations are post-substitution: their entries are the
individual terms contributing to `C_m` after applying `R_Tm`.

## NLO UU orderings

### Pair first

Mathematical action: substitute hadronic coordinates and simplify every
amplitude-pair target coefficient separately.

Advantages:

- exposes malformed pair data early;
- distributes naturally over independent pairs;
- can prevent a bad pair from contaminating later sums.

Disadvantages:

- repeats the same algebra in many pairs;
- misses cancellations that occur only after equal targets are summed;
- measured slower than target first for the 10 by 10 sample.

Measurement: 89,111,000 to 2,694,944 Mathematica `ByteCount` bytes in
43.403 s on four kernels.  Composition then gave 1,574,064 `ByteCount` bytes
for the master coefficients.

### Target first

Mathematical action: sum equal Kira targets, substitute the card coordinates,
normalize certified roots, and simplify the resulting rational coefficient.

Advantages:

- removes repeated pair algebra before expensive work;
- captures pair-to-pair cancellations;
- was the fastest first nontrivial NLO route.

Disadvantages:

- does not exploit cancellations between different targets after they map to
  the same master;
- target coefficients can still carry awkward square-root representations if
  branch normalization is omitted.

Measurement: 46,940,920 to 1,362,792 `ByteCount` bytes in 23.715 s on four
kernels.  Composition gave 1,548,952 `ByteCount` bytes for the masters.

### Master first

Mathematical action: insert every Kira rule, sum all contributions to each
master, and simplify the complete master coefficient.

Advantage: exposes every cancellation contributing to one physical master.

Disadvantages:

- creates the largest intermediate expressions;
- one NLO 10 by 10 coefficient remained unfinished after 281 s;
- at NNLO, eight whole-master jobs each reached the 1,800 s and 4 GiB bounds.

No completed NLO output was obtained for this route.

### Target then master

Mathematical action: perform target first, compose the masters, then simplify
the eight master-level objects independently.

Advantages:

- combines early cancellation with a smaller final cleanup;
- produced the smallest complete NLO 10 by 10 master representation among the
  four orderings.

Disadvantages:

- the second stage gives only a further 1.589-fold `ByteCount` reduction;
- its measured 62.125 s is additional to the 23.715 s target stage.

Measurement: the second stage changed 1,646,272 to 1,036,008 `ByteCount`
bytes in 62.125 s on four kernels; the final master object occupied 1,041,912
`ByteCount` bytes.  The sequential target-plus-master wall time is 85.840 s.

## NLO UU algebraic variants

### Termwise `Simplify` on the largest target

The target was split at top-level addition and each term simplified.  It
changed 3,517,376 to 49,016 `ByteCount` bytes in 4.838 s.  The later isolated
whole-expression equality calculation reached its time bound, so this
particular file is evidence of compression and timing, not an independent
zero-difference certificate.

### Whole `Simplify`

The same target changed 3,517,376 to 327,568 `ByteCount` bytes in 86.378 s.
It was much slower and larger than termwise simplification.  Its isolated
equality calculation also reached its time bound.

### Whole `FullSimplify`

The same target did not finish within 120.045 s.  It produced no retained
result.

### Structural `FactorTerms[Cancel[Together[...]]]`

The same target expanded to 6,812,872 `ByteCount` bytes in 50.350 s.  The
method is exact rational algebra but is a poor representation for this input.

### Factor extraction before master composition

Target cleanup took 23.624 s; extracting the shared fraction/distribution
factor took 3.393 s and changed 1,362,792 to 684,744 `ByteCount` bytes.  Master
composition took 0.003 s, and final master simplification took 10.741 s,
changing 855,104 to 759,840 `ByteCount` bytes.  The full route took about
37.76 s from raw targets.  A second 9.426 s master sweep left the size exactly
759,840 bytes and was unnecessary.

### Direct target cleanup without prior factor extraction

This route changed 1,542,536 to 727,376 `ByteCount` bytes in 450.188 s.  It
was far slower than the factor-first route despite a similar final size.

### Certified division by the universal fraction monomial

After 33 explicit physical-branch identities were certified, direct division
and `Simplify` changed 1,035,984 to 283,144 `ByteCount` bytes in 9.437 s.  All
remaining coefficients were exactly independent of `xa`, `xb`, and `zh`.

The compact variant comparison found:

- divide only: 1,035,984 to 1,089,000 bytes in 0.800 s, with fractions still
  present;
- divide plus `Simplify`: 1,035,984 to 283,144 bytes in 5.877 s, fraction
  independent;
- divide plus `FactorTerms`: 1,035,984 to 1,090,008 bytes in 5.384 s, with
  fractions still present.

On the 283,144-byte result, a further `FullSimplify` took 32.352 s and reduced
it to 256,456 bytes.  `Factor` expanded it to 925,968 bytes and color
collection expanded it to 562,496 bytes.

### Signature, denominator-group, and color grouping

Freezing analytic signatures and grouping rational terms was exact but
expanded the NLO 10 by 10 master expression from 1,035,984 to 3,879,816 bytes
in 1.868 s.  Four lighter variants (`StripOnly`, term cleanup, denominator
groups, and color collection) each finished in 1.69--1.90 s but expanded the
same input to about 1.94 MB.  They are not useful final representations.

### Automatic common-factor search

The automatic search took 0.0067 s and found only
`alpha_s^3 D1[zh] f1[xa] f1[xb]/zh^2`.  It missed
`1/(xa xb)`, leaving fraction dependence.  A process-independent routine must
derive a Laurent monomial in the declared positive fractions, rather than rely
on a syntactic common factor.

## NLO TT methods and correction

TT introduces BMHV evanescent scalar products.  A rank-`2r` evanescent tensor
integral is first reduced in its tensor dimension and then related to scalar
integrals by a Tarasov shift.  The earlier implementation replaced `D` by
`D+2r` everywhere, including loop-independent factors already produced by the
original `D`-dimensional trace.  This was wrong.

The correction keeps every original loop-independent factor at dimension `D`
and applies `D -> D+2r` only inside the shifted tensor integral.  For the toy
rank-two identity, the transverse angular denominator is `D-3` before a shift
and `D-1` after one shift.  An existing factor `D-4` is unchanged.  Exact
tests checked rank one, rank two, cut projection, both denominators, and
rejection of the wrong shifted denominator.

The incorrect degree-zero tensor route reached 184,796,536 `ByteCount` bytes
with 39,036 GLI occurrences.  The corrected sparse cut route occupied
27,754,864 bytes with nine distinct GLIs.  A representative rank-two
absorption can still expand 253,968 input bytes to 16,465,224 bytes and 6,932
GLI occurrences, which explains why TT needs sparse tensor handling before
coefficient simplification.

For the TT 5 by 5 calculation, target cleanup changed 139,298,664 to
10,562,384 `ByteCount` bytes in 52.02 s on four kernels.  Final-master cleanup
took 30.36 s.  The six-master serialized result is 750,504 bytes.  The angular
basis reduces exactly to `cos(phi_a)cos(phi_h)` and
`sin(phi_a)sin(phi_h)`; the mixed sine-cosine coefficients vanish.

Representative target tests show that `Together` is fastest but leaves an
expression roughly three times larger than `Simplify`.  `Together` followed
by `Simplify`, or the historical collect routine, reaches the same small form
in 0.10--0.84 s for 2.37--6.44 MB inputs.  Applying `Simplify` before
`Together` throws away the compact factored form and returns the larger
`Together` representation.

## NNLO methods before the hadronic root-ring route

### Target-level termwise simplification

For the 64 largest target coefficients, termwise `Simplify` changed
83,386,848 to 28,279,424 `ByteCount` bytes in 75.643 s on four kernels, a
2.949-fold reduction.  The largest isolated target changed 2,434,656 to
701,328 bytes in 6.92 s with exact zero difference; whole `Simplify` needed
15.30 s and gave 811,576 bytes.

### Rational normalization on an isolated target

`Cancel[Together[...]]` took 0.37 s but expanded 2,434,656 to 3,748,912
`ByteCount` bytes.  Adding `FactorTerms` took 0.83 s and expanded it further
to 5,316,312 bytes.

### Whole-master simplification

Eight master coefficients were assigned independently with a 1,800 s and
4 GiB bound per job.  None produced a retained output; aggregate memory was
about 34 GiB.  This route is unsuitable for the measured NNLO grammar.

### Termwise final-master simplification

For master 8, 377 additive terms were simplified on eight kernels.  The
serialized file changed from 4,655,210 to 3,082,976 bytes in 175.070 s.  The
existing fast rational result for the same master was 7,978,901 bytes, so the
termwise route avoided a substantial expansion but gave only a 1.510-fold
reduction from its input.

### Rational/signature modules

Each term was split into a rational coefficient and an inert signature
containing branch-sensitive powers, Gamma functions, logarithms, and BMHV
objects.  Rational algebra was performed only within identical signatures.
The serialized measurements were:

- master 1: 1,607,146,927 to 920,945,177 bytes in about 19.5 min;
- master 2: 903,734,615 to 464,281,765 bytes in about 15 min;
- master 4: 83,696,010 to 47,987,161 bytes in 68.55 s.

For master 4, all 2,591 additive terms had different signatures, so no
cross-term rational merge was possible.  The reduction came from normalizing
each rational term separately.  Chunking bounded memory but did not reveal
enough repeated signatures for a several-fold final-master reduction.

### Global all-master cleanup

The serialized post-IBP coefficients entering the old final-master routine
occupied 3,960,695,102 bytes.  Its stored output occupied 3,597,827,125 bytes,
only a 1.101-fold reduction.  This exact artifact is retained as a comparison,
not as the preferred route.

### Symbolica, FORM, and SymPy

For the measured coefficient, direct Mathematica cleanup took 5.91 s and
produced 0.70 MB.  Symbolica preprocessing followed by Mathematica took
12.16 s and produced 0.81 MB before counting preprocessing time.  FORM and
SymPy can manipulate rational polynomials, but no exact end-to-end converter
was established for this grammar of roots, Gamma functions, BMHV tensors, and
FeynCalc objects.

## NNLO exact positive-root and denominator route

### Entrywise positive-root cleanup

For three selected post-IBP master columns, the source contains 38,460 target
leaves arranged into 38,400 denominator entries.  It occupies 859,107,253
serialized bytes.  The substitutions `xa=ya^2`, `xb=yb^2`, `zh=yh^2` are made
only in certified positive monomials.  The positive invariant is written
`s=rs^2`; a result is returned to `s` only after exact invariance under
`rs -> -rs` is established.

The entrywise calculation took 1,304.639 s on eight kernels and produced
131,787,741 serialized bytes, a 6.52-fold reduction.  Every entry was checked
for exact arithmetic, absence of fractions and temporary roots, nonzero
denominator, and integer powers of `s`.

### Eager equal-denominator cancellation

For the largest selected master, exact equal denominators were merged and
`Cancel` was always retained.  The fraction count fell from 38,306 to 6,290,
but Mathematica `ByteCount` grew from 422,282,520 to 1,727,567,608 and the
serialized result occupied 488,886,853 bytes.  Runtime was 6,375.22 s.  The
method destroys local factorization and is a poor storage form.

### Size-monotone equal-denominator cancellation

For each equal-denominator class, both the raw numerator sum and the cancelled
rational form were computed; the smaller exact representation was retained.
The largest master changed from 38,306 to 6,557 fractions in 1,260.216 s.
Its fraction-list `ByteCount` changed from 422,282,520 to 351,559,840 and its
serialized result occupied 99,892,985 bytes.  This is faster and much smaller
than eager cancellation while preserving exact equality.

### Dimensionless scale separation

With `x=-t/s`, `y=-u/s` and physical chamber
`s>0`, `x>0`, `y>0`, `x+y<1`, an exact homogeneity calculation extracts an
integer power `s^p` separately for every master.  The three selected powers
are 4, 2, and -2.  For the largest master, this changed 351,559,840 to
296,802,344 `ByteCount` bytes and 99,892,985 to 92,385,524 serialized bytes in
430.914 s on eight kernels.

A second size-monotone merge changed 6,557 to 5,973 fractions and
296,802,344 to 296,275,768 `ByteCount` bytes in 904.575 s.  The serialized
result is 92,241,826 bytes.  A complete independent replay took 943.22 s.

### Denominator-factor inventory

Factoring the 5,973 dimensionless denominators over `Q(Epsilon)` took 27.94 s
on eight kernels and found 30 distinct `x,y`-dependent factors.  A dictionary
representation occupied 91,385,453 serialized bytes, only 0.93 percent less
than the direct 92,241,826-byte fraction list.  The factor inventory is useful
for singular-locus analysis but not as a separate storage grammar.

## Branch treatment

The physical card gives `s>0`, `t<0`, `u<0`, positive momentum fractions, and
the remaining reality conditions.  Mathematica does not automatically use
these facts to replace products of roots, and identities such as
`Sqrt[a b]=Sqrt[a]Sqrt[b]` are false outside a declared positive chamber.
Therefore `PowerExpand` is never used.

The algorithm accepts only Laurent monomials in declared positive variables.
It lifts those variables to positive roots, performs exact rational algebra,
and descends only after parity under root-sign reversal is checked.  Logs,
Gamma functions, noninteger invariant powers, hypergeometric functions, and
BMHV structures remain inert during rational merging.  A nonmonomial root
base is rejected.  This turns physical sign knowledge into an explicit
algebraic certificate rather than an implicit simplifier assumption.

## Generality boundary

The card-driven core obtains hadronic coordinates, assumptions, momenta, spin
vectors, and non-NA momentum fractions from the card.  It automatically adds
`0 < xi < 1` for each declared momentum fraction.

The August NNLO study drivers are not process independent.  They explicitly
name `{xa,xb,zh}`, `{f1[xa],f1[xb],D1[zh]}`, the universal exponent vector
`{-2,-2,-4}` in positive-root variables, `s` as the positive scale, and
`x=-t/s`, `y=-u/s`.  They also name selected master labels and study
directories.  A general implementation must read from the card:

1. fraction variables and their physical domain;
2. distribution factors and expected Laurent valuation;
3. invariant coordinates and their chamber;
4. admissible branch transformations;
5. variables forbidden in the extracted hard coefficient.

If any item is absent or an expression lies outside the certified grammar,
the calculation must stop with the offending coefficient.

## Time estimate

The three selected NNLO columns contain 859,107,253 serialized source bytes,
whereas all post-IBP coefficients occupy 3,960,695,102 bytes, a ratio of 4.61.
Scaling measured eight-kernel times by this ratio gives about 1.67 h for
entrywise root cleanup and about 3.3 h for equal-denominator assembly plus
dimensionless normalization.  Allowing I/O, uneven master sizes, audits, and
the remaining small columns gives a planning interval of 6--10 h for the full
post-IBP coefficient stage on eight kernels.

This is not an estimate for the complete exact NNLO hard function.  The 342
cut masters still require analytic evaluation, followed by endpoint analysis,
distribution expansion, and combination with the other NNLO sectors.  The
one-day simplification data do not determine how long those physics steps
will take.

