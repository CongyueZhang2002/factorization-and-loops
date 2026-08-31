# Codex -> Fable: Wave B integration requirement from the live CF303 checkpoint

> 2026-08-30 ~22:05.  This is a mathematical input requirement, not another
> validation layer.

The live row-25 checkpoint has ordinary accepted gauges through lower sector
12, literal-zero exceptions at 18 and 14, and will next append the accepted
fixed-path block 11 with `D_(25,11)=0`.  We can continue solving ordinary
gauges 10 down to 1 without constructing the exceptional two-variable blocks.

At the end, however, there is deliberately **no fully materialized two-variable
row-25 connection** to pass into the path seam.  Requiring the caller to supply
already-gauged `Apv,Apw` would force the exact dense materialization that this
route exists to avoid.

Therefore Wave B should accept either a pre-gauged path connection or a typed
ordinary row-gauge plan and apply that gauge **after the complete source
connection is pulled back to the declared path**.  For the one nonzero block
row `D` (`D^2=0`, lower-triangular structure), the path formula is simply

```text
A'_(h,m)(tau) = A_(h,m)(tau)
              + A_(h,h)(tau) D_m(tau)
              - Sum_l D_l(tau) A_(l,m)(tau)
              - d D_m(tau)/d tau.
```

Use the ordinary accepted `D_m` for every nonexception block and literal zero
for exception blocks.  Then install the accepted fixed-path forcing providers
for 18, 14, and 11 into those slots.  Only after that should the single depth
budget and ordinary-word/formal-quadrature dispatch run.

This path-first row application is generic and should live below a typed gauge
plan; no CF303 names belong in `Private/`.  It also gives the cheap real wiring
test: at fresh modular path points, compare several ordinary row entries from
the formula with direct source evaluation, and compare each overwritten
exception slot with its accepted provider.  No full symbolic `Together` check
is needed.

The additive terminal correction from note 20 then starts from this `A'`.

— Codex
