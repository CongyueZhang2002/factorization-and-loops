# CF303 modular exception Hermite pilot

## Result

The multivariate symbolic compile/Hermite bottleneck is avoidable.  The saved
`BlockEquationDeferredV1` forcing can be sent directly to the existing packed
path-jet evaluator, reconstructed as rational functions of the direct path
variable over one 61-bit prime, and Hermite-reduced over the same finite field.

No package source was changed.  The implementation is scratch-only:

- `Diagnostics/Scripts/cf303_modular_hermite_pilot.py`: rational block-2 pilot
- `Diagnostics/Scripts/cf303_modular_algebraic_hermite_pilot.py`: residual-sheet
  projection plus rational/elliptic Hermite reduction

## Mathematics

For fixed modular images of `(p, eps)`, several local jets determine

`f(u) = N(u)/D(u)` in `F_q(u)`.

The reconstruction is a multipoint Hermite-Pade problem.  It solves the
homogeneous conditions

`N(c+t) - D(c+t) f_c(t) = 0 mod t^k`

at independent centers `c`.  A short jet at a new center is retained as the
acceptance image.  The degree box grows before a new center is promoted, so an
undersized ansatz cannot waste full-order images.

For the residual direct-u root `rho=Y/Dcurve`, two native evaluations give

- `even = (f(rho)+f(-rho))/2`,
- `odd_rho = (f(rho)-f(-rho))/(2 rho)`,
- elliptic form coefficient `R = P4 odd_rho/Dcurve`.

The ordinary channel is decomposed as

`f = d h + r`.

The elliptic channel is decomposed as

`R = P4 h' + P4' h/2 + r`,

with the remainder in the squarefree finite-pole part plus the quartic
cohomology basis `{1,u,u^2}`.  Both reductions clear denominators and verify
the polynomial identity in `F_q[u]`.

## Measurements

### Block (25,2)

- exact forcing degrees: `46/46` in both rows
- construction: two order-64 centers
- validation: one independent order-12 center
- wall: `3.20 s`
- peak RSS: `51.7 MB`
- native evaluation: `2.699 s`
- multipoint rational reconstruction: `0.216 s`
- Hermite reduction: `0.024 s`
- old symbolic census: `137.551 + 161.156 = 298.707 s`
- speedup: `93.3x`

At three additional modular points, the forcing primitive and remainder agree
exactly with the accepted Maple artifact for both rows.

### Block (25,1), genuine residual sheet

- rational degrees: row 1 `62/62`, row 2 `60/60`
- elliptic degrees: both rows `6/5`
- rational repeated/squarefree degrees: `39/23`, `37/23`
- elliptic repeated/squarefree degrees: `0/5`
- elliptic branch gcd degree: `0`
- adaptive accepted cap: `64/64`
- construction: two centers, both sheets, order 64
- validation: third center, both sheets, order 12
- all four fresh-center validations: true
- all four Hermite identities: true
- serial native work: `111.51 s`
- four-worker cold critical-path estimate: `28.82 s`
- reconstruction: `0.579 s`
- Hermite: `0.048 s`
- peak RSS in the sequential measurement: `52.9 MB`

The old symbolic route had already spent `2531.8 s` compiling one block-1
entry before reduction.  Even the sequential modular work is over twenty
times faster for the complete two-entry, two-channel block; the bounded
four-worker schedule raises the expected gain to roughly eighty-eight-fold.

## Production path

For each `(prime,p,eps)` image, normalize every recovered denominator monic in
`u`.  The resulting polynomial coefficients are stable scalar functions of
`(p,eps)` and can be sent to the package's existing two-variable modular
reconstruction/CRT machinery.  Exceptional images are rejected by degree or
fresh-center failure.  A final unused prime validates the lifted coefficient
tables.  The expensive sheet-pair jets are persisted independently of the
later interpolation and lift choices.

The next backend improvement is batching several epsilon images in one DAPJ
request.  DAPJ parallelizes over epsilon images; one-epsilon jobs correctly use
one native thread, while independent center/sheet jobs are distributed over a
bounded worker pool.  No symbolic fallback is required.
