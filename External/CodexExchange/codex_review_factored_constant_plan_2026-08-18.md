# Review of the factored-constant plan

Codex, 2026-08-18.

The plan is valid with two qualifications.

## (a) Coefficient-wise substitution

The new `masterTransportSubstituteConstants` acts on the rational coefficient
of each Chen word separately. This is an exact short-term correction because
the valuation rules act only on integration constants and never on the word:

\[
  \left(\sum_w w\,c_w\right)\bigg|_{c\to Nb}
  =\sum_w w\,\left.c_w\right|_{c\to Nb}.
\]

It therefore avoids `Together` on a sum containing thousands of different
words. This is materially different from applying `Together` to each complete
master/epsilon coefficient, which would retain the original bottleneck.

Before using it for the production records, compare the old and new operations
exactly on a completed medium family, order by order, and require:

1. zero difference after collecting by `TransportWord`;
2. no eliminated integration constant remains;
3. the valuation assertion is unchanged;
4. the original differential-equation residual is unchanged wherever it can
   be evaluated.

The present implementation reconstructs the sum incrementally with
`out += c w`. For large word sets, construct a list and apply `Total` once, or
better, retain the association until a physical output is requested. Repeated
growth and sorting of a large `Plus` can become a second avoidable cost.

The currently running `probe_CF26` loaded `MasterTransport.wl` before this
edit and therefore cannot measure the new routine. A fresh kernel is required.

## (b) CF26 pre-transport analysis

The existing records already establish

\[
  35\ \hbox{boundary coefficients}
  \longrightarrow 25\ \hbox{allowed coefficients}
\]

for both CF26 and CF33. This is a 10-dimensional valuation constraint, but it
does **not** determine the reduction in transported words. A 29 percent
reduction in boundary dimension can remove nearly no words or nearly all high
weight words, depending on the matrices multiplying that subspace.

The useful measurement is the exact kernel \(c=N b\) together with the counts

\[
  \#\{w:\;P T R_w N\neq0\}
\]

at every required weight. The present CF26/CF33 JSON files contain a rank
census, not the exact kernel matrices or these word-survival counts.

## (c) One factored constant-space representation

This is the correct standardized design:

\[
  F=\sum_w w\,C_w c,
  \qquad c=N b,
  \qquad C_w\mapsto C_wN.
\]

Keep `word -> rational matrix` as the internal representation through
transport, valuation, and physical projection. Convert it to an ordinary
Wolfram expression only for requested master rows and epsilon orders. This
unifies the CF26/CF33 correction with the already completed CF299/CF407
observable transport.

## (d) Rational reconstruction

Deferring finite-field reconstruction until a measured rational entry becomes
large is correct. The matrix representation should first use exact sparse
rational arithmetic. Record entry size, numerator/denominator degrees, and
matrix sparsity; invoke reconstruction only for entries whose direct exact
arithmetic is demonstrably slower.

## Recommended order

1. Verify the coefficient-wise routine on a completed medium family.
2. Rerun CF26 and CF33 in fresh kernels to close their immediate records.
3. Construct the exact CF26/CF33 kernels and measure word survival by weight.
4. Replace scalar word expressions by the matrix-valued word map as the one
   package representation.
5. Add finite-field reconstruction only for measured exceptional entries.
