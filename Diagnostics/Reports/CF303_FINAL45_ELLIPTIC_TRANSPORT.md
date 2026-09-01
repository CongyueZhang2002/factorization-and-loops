# CF303 GPL/eMPL transport — provisional audit-blocked result

Date: 2026-08-31

## Audit status

Do not treat this report as a complete 45-master or physical result.  A final
pre-commit audit found that the 76-entry block-25 deck contains only the
`SolvedForms` blocks plus the diagonal.  It omits typed transport exceptions
for lower blocks `{1,2,11,14,18}`, corresponding to seven source masters.  The
explicit rows are also canonical rows 44--45 and have not yet been convolved
with the accepted source gauge `I_source_block25=T25.F_canonical_block25`.

The weighted-word construction and every numerical count below are correct
for the partial deck.  Completion is blocked on adding the seven authoritative
path forcings and applying `T25`.

The final function class is an iterated-integral algebra on the quartic curve

\[
Y^2=P_4(u),
\]

with ordinary GPL poles, marked elliptic poles, and the two holomorphic/
infinity elliptic kernels.  No second-kind `eta2` letter occurs in any of the
four algebraic layers on the chosen path.

## Layer census

| original block | rows | path entries | epsilon structure | primitives | eta2 | distinct letters | homogeneous constant generators |
|---|---:|---:|---|---:|---:|---:|---:|
| 15 | 23--25 | 39 | exactly epsilon-linear | 0 | 0 | 23 | 5 |
| 17 | 28 | 23 | exactly epsilon-linear | 0 | 0 | 27 | 1 |
| 21 | 37--38 | 48 | exactly epsilon-linear | 0 | 0 | 27 | 3 |
| 25 | 44--45 | 76 | 72 rational-in-epsilon incoming entries; four epsilon-linear diagonal entries | 0 | 0 | 33 | 3 |

The important correction is block 25: on the final accepted connection it is
not a genuinely non-dlog integration layer.  Its obstruction is only to a
single global epsilon form.  Every path one-form is dlog on the quartic curve;
the incoming residues are rational functions of epsilon with valuation `-2`.
Only orders `-2..4` are needed for the requested target window `-4..2`.

## Block-21 bounded projection

The original one-shot quadratic normalization was stopped after exceeding
15.7 GB before entry 10.  The replacement projects the raw expression into
`Q(u,p,eps)[rho]/(rho^2-Q)` termwise, combines 16 terms at a time in a balanced
tree, and keeps rho-free coefficients opaque.

- 48/48 entries accepted.
- Compile: 1,486.131 Maple CPU-seconds, about 16.8 minutes wall time.
- Hermite reduction: 2.620 seconds.
- Peak observed RSS: 2.79 GB.
- Seven diagonal forms have matrix span three; weight-five homogeneous
  prefixes reduce from `7^5 = 16,807` to `3^5 = 243`.

## Exact lazy operator

The first 43 masters form an epsilon-linear Chen operator.  Since block 25 is
the final lower-triangular layer, a word contributing to rows 44--45 has
exactly one of the forms

\[
D\cdots D,
\qquad
D\cdots D\,B_r\,S\cdots S,
\]

where `D` is a block-25 diagonal letter, `B_r` is one incoming residue at
epsilon order `r`, and `S` is a source-operator letter.  There can never be a
second incoming transition.  The coefficient accessor evaluates this grammar
directly with sparse matrices; it does not enumerate the 143-letter union
alphabet.

Final artifact:

- masters: 45;
- source masters: 43;
- boundary columns: 164;
- internal letters: 143;
- incoming residue matrices: 225;
- nonzero incoming residue coordinates: 5,990;
- block-25 diagonal generators: 3;
- construction time: 0.289 seconds.

An independent reference constructs the full weighted block residue matrices
and sums epsilon-order assignments.  It agrees exactly with the lazy accessor
for the empty word, one and two diagonal letters, one incoming letter, a
diagonal/incoming word, and an incoming/source word.

## Paper-facing standard letters

Construction keeps root-free `GPLFactor` and `E4Factor` labels.  Physical
materialization splits them only at output:

\[
\frac{u^i\,du}{f(u)}
=\sum_{f(c)=0}\frac{c^i}{f'(c)}\frac{du}{u-c},
\qquad
\frac{u^i\,du}{f(u)Y(u)}
=\sum_{f(c)=0}\frac{c^i}{f'(c)Y(c)}\,\omega_{-1}(c).
\]

`CF303Root[f,k]` denotes the kth root of `f`; this avoids printing enormous
nested radicals while defining every algebraic letter unambiguously.

Explicit materialization of rows 44--45 gives:

| epsilon order | internal words | standard GPL/eMPL terms |
|---:|---:|---:|
| -4 | 10 | 15 |
| -3 | 193 | 404 |
| -2 | 2,955 | 9,107 |

All three orders materialize in about 59 seconds together.  The output has no
`GPLFactor`, `E4Factor`, `CompositeEllipticLetter`, unevaluated `Integrate`, or
master-integral head.  Order `-1` exceeds the deliberately bounded 20,000-word
eager cap; it remains exactly accessible word-by-word from the lazy operator.

## Principal artifacts

- `Diagnostics/Scripts/census_cf303_remaining_elliptic_layers.mpl`
- `Diagnostics/Scripts/compress_cf303_diagonal_constant_generators.mpl`
- `Diagnostics/Scripts/build_cf303_pure_elliptic_layer_operator.mpl`
- `Diagnostics/Scripts/build_cf303_general_elliptic_layer_transfer.mpl`
- `Diagnostics/Scripts/cf303_lazy_final_elliptic_transport.wl`
- `Diagnostics/Scripts/build_cf303_final45_lazy_elliptic_operator.wls`
- `Diagnostics/Scripts/test_cf303_final_lazy_weighted_operator.wls`
- `Diagnostics/Scripts/materialize_cf303_final45_low_orders.wls`
- `Runtime/2026-08-31_cf303_native_dlog_residues/cf303_hybrid_elliptic_operator_15_17_21.wl`
- `Runtime/2026-08-31_cf303_native_dlog_residues/cf303_final45_lazy_elliptic_operator_15_17_21.wl`
- `Runtime/2026-08-31_cf303_native_dlog_residues/cf303_final45_low_order_materialization.wl`

This implementation remains in the Codex scratch worktree.  No new
family-specific transport code was added to `FeynFacet/Private` during this
stage.
