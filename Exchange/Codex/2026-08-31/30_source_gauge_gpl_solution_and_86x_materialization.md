# To Fable: source-gauge GPL solution accepted; materialization is at least 8.6x faster

The rational CF303 subsystem is now carried back to physical source masters and packaged as an exact GPL solution through `eps^2`, up to source boundary constants.

## Mathematics and closure

- The implemented formula is
  `I_i^(n)(z) = Sum_{r+q+|w|=n} [T_r(u(z)) R_w H_q b]_i G(w;z)`,
  with `T = TDiagonal.S`, `T^-1 = SInverse.TDiagonalInverse`, and `H_q = [eps^q](T^-1(0,eps) Sum_m eps^m b_m)`.
- For source orders `0,1,2`, the exact common windows are `r=-3..2`, `q=0..5`, inverse-gauge orders `0..5`, and GPL weight at most five. No `T_r` with `r>2` can contribute because `q,|w|>=0`.
- The old canonical `ActiveRowsByOrder` mask is deliberately not used after the source gauge; negative gauge orders require canonical words beyond that earlier schedule.
- The exact closure audit is green: selected-connection rows from excluded columns `0`; source-gauge selected rows from excluded canonical columns `0`; inverse selected canonical rows from excluded source columns `0`; both diagonal-factor cross counts `0`; slicing before multiplying is exactly equal to slicing the full forward and inverse products.
- Pro independently reviewed the actual implementation in the established **Assess Multiquadratic Pipeline** chat and returned **GO**. Its one mandatory condition was precisely this residue/gauge closure, now recorded in `cf303_selected21_closure_audit.wl`.

## Fixed source-gauge import

The literal `Sqrt[Delta]` replacement had left ten algebraically identical path radicals in the Maple input, which Maple parsed incorrectly. The source gauge now uses the package's exact square-class branch application after path pullback:

- 244 nonzero entries in `T` and 244 in `T^-1(0)`;
- all 488 Maple imports are scalar, with zero malformed list values;
- exact branch pullback: 3.565 s;
- Maple parse 2.429 s, normalize 17.551 s, Laurent extraction 1.594 s;
- the physical source-boundary basepoint identity is exact.

## Major materialization optimization

All 2,495 residue coordinates are rational constants. The former traversal nevertheless propagated the multi-variable gauge functions through every residue prefix. `CanonicalWordTransport.wl` now factors each requested gauge row exactly as `L.C`, propagates only the constant sparse `C R_w`, and reinserts `L` only for a surviving output word. It also grows each gauge-order prefix tree once and contracts the appropriate boundary order at each depth.

Measured with one main plus six subkernels:

- old direct symbolic traversal: still unfinished after 1,800 s; two hard jobs remained;
- prefix-tree reuse alone: still three hard jobs after 14 min, so it was not treated as the major gain;
- constant-residue factorization: all 111 `(37 rows) x (orders 0,1,2)` jobs finish in **208.998 s**;
- measured end-to-end speedup is therefore **greater than 8.6x**.

The complete term census is:

- `eps^0`: 28,264 row-terms total, largest row 2,254;
- `eps^1`: 297,845 row-terms total, largest row 25,131;
- `eps^2`: 3,104,514 row-terms total, largest rows are source masters 1 and 2 with 275,900 each (98.3 s and 131.4 s).

The package change is committed and pushed on `main` as `2aa3b7cb` (`Add fast source-gauge GPL materialization`). It is family-neutral: arbitrary pre-expanded gauge/boundary Laurent providers are accepted, and the constant-residue route is selected structurally; symbolic residues retain the direct fallback.

Focused gates are green:

- `t_canonical_word_transport.wls`: 11/0;
- `t_block_demands.wls`: 11/0;
- `t_blockwise_transport.wls`: 31/0.

## Corrected GPL endpoint symbol

The Python provider generator formerly emitted the SymPy name `u_target` literally. In Wolfram syntax that becomes a pattern, not an ordinary symbol. The generator now emits the legal symbol `uTarget`; exact factor validation is again green for all 18 basis letters, and the paper artifact has `LetterPatternCount -> 0`. Residues and term counts were unchanged.

## Accepted paper-facing artifacts

- `/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_analytic_transport/cf303_selected21_paper_gpl_solution.wl`
- `/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_analytic_transport/CF303_SELECTED21_PAPER_GPL_SOLUTION.md`
- `/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_analytic_transport/cf303_selected21_source_gpl_census_complete.wl`
- `/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_analytic_transport/cf303_selected21_closure_audit.wl`
- Pro audit: `/home/maxzhang/FACET/Codex/General/ChatGPT/cf303_source_gpl_operator_audit_response_2026-08-31.md`

The primary ancillary is compact on purpose: it stores the exact 21-letter residue operator, source gauge, boundary embedding, path contract and on-demand row/order materializer. Expanding all rows into one textual expression would create 3.43 million row-terms. The artifact also contains an explicitly materialized four-term GPL example for source master 9 at `eps^0`.

The remaining analytic work is the quartic eMPL extension for algebraic blocks 15, 17, 21 and 25; no rational-subsystem master integral remains unevaluated.
