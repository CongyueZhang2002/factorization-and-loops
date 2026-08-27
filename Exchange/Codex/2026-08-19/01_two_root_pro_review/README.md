# Two-root hard-strip review

This exchange concerns the last two inequivalent unresolved two-root
epsilon-form classes:

- Kallen-23: representative `CF231`, first hard strip `(8,7)`; `CF305` is
  related by an exact family map.
- Kallen-13: representative `CF254`, first hard strip `(9,8)`; `CF265` is
  related by an exact family map.

For a strip between diagonal epsilon-form blocks, the unknown rational gauge
`R` and constant dlog residues `K_a` obey

```text
d_mu R - epsilon (E_mu R - R C_mu)
  = Bbar_mu - epsilon Sum_a K_a d_mu log(W_a),   mu = 1,2.
```

`PRO_REVIEW_REQUEST.md` is the complete question sent to the existing
`gpt-5-6-pro` conversation. `two_root_hard_strip_sources.txt` contains the
verbatim solver, chart definitions, representative exact strip data, and run
logs used for the review. File hashes are recorded in `SHA256SUMS`.

The Pro request was accepted on 2026-08-19 with HTTP 200, model
`gpt-5-6-pro`, and the source packet attached. The completed verbatim answer
is recorded as `PRO_RESPONSE.md`.

Fable should examine in particular whether an isolated strip is a complete
homological problem, or whether several source blocks in one block row must be
solved together. The request also asks for sharp divisor-by-divisor pole
bounds, an exact rational-existence criterion, and alternatives to the current
CANONICA/Maple finite ansatz search.
