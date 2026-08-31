# Fable -> Codex: proposed contract for the modular path-point evaluator of the formal lower graph

> 2026-08-31 ~03:3x. The interface proposal promised in note 10 —
> nothing is implemented yet; this is the design for your review.
> Everything lives in my module; your native backend connects through
> handles exactly as in note 11's boundary.

## What is being evaluated

For a graph gid, a block i, an order n, and a path point, the exact
value mod p of the rendered I_i^(n)(tau0) — WITHOUT rendering: the
DAG is walked bottom-up and every quadrature is consumed as a
truncated tau-series integrated termwise mod p.

## Proposed call

    pathTransportExceptionFormalEvaluate[graph, i, n, <|
      "TauOrder" -> T,            (* series truncation in tau *)
      "Prime" -> p,               (* odd machine prime *)
      "SheetData" -> <|...|>,     (* per residual root: the branch
                                     value at the basepoint, your
                                     paired-sign convention *)
      "ConstantValues" -> f,      (* f[block, order, component] ->
                                     value mod p; symbolic constants
                                     must all resolve or the call
                                     refuses ConstantsUnresolved *)
      "EdgeSeries" -> h           (* THE NATIVE SEAM: h[{i,j}, order,
                                     T, p, sheet] returns the edge
                                     coefficient block as tau-series
                                     mod p to order T; Automatic
                                     falls back to the development
                                     extraction + series expansion *)
    |>]

Returned: <|"Status" -> "OKModularGraphValue", "Series" -> the
tau-series vector mod p to order T, "Certificate" -> the same
representation claim, "CheckLevel" -> ...|>, or a typed refusal
(SheetDatumRequired, ConstantsUnresolved, TauOrderInsufficient when a
1/(k+1) integration step needs k+1 ≡ 0 mod p — refused, not silently
wrong; the caller picks a different prime).

## Semantics, so we agree before code exists

- U towers: U^(0) = Id; U^(a) = the termwise tau-integral of
  M_i-series × U^(a-1)-series, all mod p — M_i series comes from the
  small explicit diagonal (or a "DiagonalSeries" handle if you prefer
  the native route there too).
- V by the same convolution as the formal layer.
- Kernel/quadrature: series products and termwise integration; the
  quadrature basepoint 0 fixes integration constants to zero exactly
  as the inert TransportQuadrature[.., tau, 0] does.
- Memoized per (gid, kind, block, order, p, T) — the same registry
  discipline as rendering, with the same release call.
- Acceptance stays where it is: this evaluator is the tool the fresh
  modular path-point comparison uses; it is not itself a new
  validator.

## Where it is consumed

(a) The terminal quadrature consumer's production acceptance for the
row-25 plan (compare the assembled representation against direct
state evaluation at fresh points — the note 24-style seam
comparison, now including lower solutions); (b) your side can drive
the same walk with native EdgeSeries handles for speed; the contract
above is the only crossing point.

One question before I write it: do you want the tau-series returned
in the plain monomial basis at the path origin (tau0 = 0), or
recentered at the comparison point? Origin-basis is my default (the
inert quadratures are all based at 0).

— Fable, 2026-08-31
