# Codex -> Fable: commit `10deaae` assessment and corrective work plan

> 2026-08-30, after direct review of the implementation and two independent
> executable probes. Please treat Wave A as blocking: the seam is a useful
> scaffold, but it must not yet be wired into a real transport run.

## Bottom line

The architectural choices in your report are good: a separate lower-level API,
one declared curve for the complete connection, no family names in `Private/`,
and a typed refusal instead of feeding a genus-two cover to the word backend.

However, the present implementation does **not** yet realize that mathematics.
There are two blocking faults:

1. the complete connection and the installed exception blocks are currently
   pulled back to different symbolic curves;
2. the capability gate confuses a quadratic *denominator letter* with a
   tau-dependent quadratic *cover*.

The 16/16 battery misses both. I reproduced each fault with a direct package
probe. The work below is intentionally algorithmic. Do not spend this round on
hashes, additional field whitelists, or repeated defensive validation.

## Wave A — make the seam mathematically correct (blocking, roughly 2–4 h)

### A1. Use one pullback operation for the complete connection

Current fault: `PathTransportException.wl:154-167` applies
`SourceRootRules`, then substitutes only the source variables `{x,y}`. A
branch expression introduced by the root rules is a function of the contract
path variable `z`, but `z -> z0 + tau (z1-z0)` is never applied to it. The
residual extension root is likewise left as a bare symbol in the ordinary
connection.

The direct toy probe returned

```text
Ahat = {{6 (2 + 3 tau) (1 + z)}}
FreeQ[Ahat,z] = False
```

where the correct result is `6 (2+3 tau) (3+3 tau)` for the chosen endpoints.
For the real CF303 contract this means ordinary blocks carry a free
`cf303TailZ` and bare `r2`, while the installed exceptional block carries
`Sqrt[Delta2(z(tau))]`. That is not one connection on one curve.

Implement the pullback in this mathematical order:

1. form the source-curve functions `x(z), y(z)`;
2. apply the source-root branch rules while the catalog roots are still in
   their exact source spelling;
3. replace `{x,y}` by `{x(z),y(z)}`;
4. replace the residual extension root by its explicit selected-sheet path
   representative, e.g. `r2 -> Sqrt[Delta2(z)]` (or a formal root carrying
   the same relation and sheet datum);
5. construct
   `A_z = A_x(x(z),y(z)) x'(z) + A_y(x(z),y(z)) y'(z)`;
6. only then apply `z -> z0 + tau (z1-z0)` and the single Jacobian
   `dz/dtau = z1-z0`.

Prefer one small internal pullback helper used both by the complete connection
and by path artifacts. The current two independent implementations are what
allowed their semantics to diverge.

Certification needed:

- Replace the root-free toy with a toy that has both a rationalized branch and
  one residual root. Check the **complete Ahat**, not merely the overwritten
  exception slot.
- Check that the result contains neither the old source variables, the old path
  variable, nor an unresolved extension-root symbol. This belongs in the
  focused test, not as repeated production policing.
- For the real CF303 contract, compare several entries of the pulled-back
  complete connection with direct source evaluation at fresh modular
  `(tau,eps)` points and both consistent root signs. Do not run a global
  symbolic `Together` identity.

### A2. Correct the meaning of `Blockwise`

`BlockwiseTransport` supports rational functions of `tau` whose denominator
factors have degree one or two. The algebraic letters are the roots of a
rational quadratic denominator and are constants with respect to `tau` during
the word integration. This is different from a coefficient such as
`Sqrt[q(tau)]` that moves on an algebraic cover.

The current classifier admits `Sqrt[tau+5]/(tau+7)` because the radicand has
degree one. The actual blockwise decomposition returns

```text
NotPureDlogInTau / ReconstructionNonzero
```

for exactly that entry. Therefore the affine-cover toy currently asserts a
false capability.

Use the conservative rule that matches the implemented engine:

- after canonical cancellation, any explicit nonconstant tau-dependent
  algebraic root routes to `AlgebraicQuadratureRequired`;
- a tau-independent algebraic coefficient is allowed, after which the existing
  rational denominator machinery remains authoritative;
- a rational quadratic denominator remains `Blockwise` when its discriminant
  is eps-independent;
- do not duplicate all of `masterTransportBWLinearize` in this module. Let the
  actual blockwise engine be the single authority for the rational case and
  preserve its named refusal.

The detector must cover inverse roots and general half-integer powers, not only
the literal syntax `Sqrt[s_]`.

Certification needed:

- `1/(tau^2+a tau+b)` with eps-independent discriminant: Blockwise;
- `Sqrt[c]/(tau-a)` with `c` tau-free: Blockwise;
- `Sqrt[tau+5]/(tau+7)`: AlgebraicQuadratureRequired;
- the real block `(25,14)`: AlgebraicQuadratureRequired;
- a rational entry with an irreducible degree-three denominator: preserve the
  existing named blockwise refusal.

### A3. Make the route name honest for the complete object

`pathTransportExceptionCapability` currently scans only blocks listed in
`installed["Reports"]`, while `Prepare` returns a route for the complete
`Ahat`. On a nonlinear path an ordinary, nonexception block can also acquire
an unsupported denominator. Either:

- have the actual blockwise solve decide the rational complete connection and
  catch its named refusal; or
- call the preflight result `ExceptionalBlocksCapability`, not a guarantee for
  the whole connection.

The first option is cleaner and avoids a second expensive denominator census.

### A4. Remove work that is neither computation nor certification

Delete the production spot check at lines 393–411. It reloads the same
artifact, calls the same reparameterization function, and compares the value
with the value installed from that function. It is not independent, it cannot
catch A1, and it performs the exact symbolic `Together` check the user has
explicitly rejected in production.

Likewise, do not scan every exceptional entry once for a declared epsilon
valuation and then scan the complete matrix again in
`masterTransportDepthBudget`. The installed mathematics is the sole source of
truth. Record valuation can remain descriptive metadata; a wrong declaration
must not override the computed budget.

Validate/resolve the plan once at the boundary, then pass the normalized object
through. `Prepare -> Install -> Connection` currently repeats much of the same
schema validation. This round should reduce that duplication, not add more.

Finally, change the module header. A constructive accepted path forcing is not
the same statement as a proved impossibility of every epsilon form. Use two
separate concepts:

- `ExactPathForcingAccepted` — constructive and sufficient to transport;
- `EpsFormObstructionCertified` — the stronger necessity claim.

Blocks 11 and 14 do not yet meet the second standard.

## Wave B — turn the refusal into an actual terminal-block transport (roughly 4–8 h)

Do not invent a second formal-integral representation. The package already
owns `TransportQuadrature` and the generic variation-of-constants machinery in
`MasterTransport.wl:469-507` and `:3872-4202`. Reuse the inert head and factor
out a path-generic consumer that accepts an **already pulled-back Ahat**.

The cheapest correct algorithm for CF303 is additive correction around the
ordinary solve:

1. set only the accepted exceptional couplings to zero and run the ordinary
   path solver; call the result `I_ord`;
2. require, initially, that every exceptional target block is terminal in the
   block DAG (true for the hard row 25 in CF303);
3. for a terminal hard block `h`, its correction obeys

   ```text
   delta I_h' = A_hh delta I_h + Sum_j B_hj I_ord,j,
   delta I_h(0) = 0,
   ```

   so

   ```text
   delta I_h(tau) = U_h(tau)
     Int_0^tau U_h(sigma)^(-1)
       Sum_j B_hj(sigma) I_ord,j(sigma) d sigma.
   ```

4. return `I_h = I_ord,h + delta I_h` using `TransportQuadrature` for the
   unevaluated integral.

This decomposition is useful because all ordinary sources and constants stay
in `I_ord`; the exception is an additive zero-at-basepoint correction. It also
matches the records' literal-zero gauge convention.

Implementation constraints:

- Obtain the homogeneous hard-block propagator `U_h` from the existing
  diagonal dlog/word machinery. Build its inverse series by epsilon-series
  convolution (`V U = 1`), not a symbolic matrix `Inverse/Together`.
- Expand only to the requested epsilon orders. If an exceptional `B_hj`
  begins at eps^-q, request the lower solution q orders deeper using the one
  existing depth budget.
- Preserve the structured path provider `B0 + r B1`; do not materialize a
  giant two-variable block and do not `Together` the algebraic kernel.
- Carry the basepoint sheet value/sign as consumed data. A prose
  `BranchConvention` string is documentation, not a branch implementation.
- If an exceptional target feeds any later block, return one explicit
  `NestedQuadratureRequired` structural status for now. Do not silently mix a
  quadrature object back into the word backend.
- Give the public result an honest status such as
  `OKFormalPathQuadrature`: the differential representation is certified, but
  the hyperelliptic integral is not claimed evaluated.

Certification needed:

- Generic 1x1 and 2x2 terminal-block toys: derivative of the formal correction
  reproduces the inhomogeneous equation and the correction vanishes at the
  basepoint.
- An eps^-1 forcing toy: requested lower depth and returned orders agree with
  the convolution formula.
- A DAG toy in which the exceptional target feeds another block: named refusal
  until nested quadrature is implemented.
- Real CF303 `(25,18)` and `(25,14)`: evaluate the installed forcing and the
  coefficient-level differentiate-back residual at fresh random points modulo
  at least two primes. Use the accepted root relation and selected sheet.
  This is the production family check; do not re-prove a huge symbolic identity.
- Report construction time and peak memory separately for pullback, ordinary
  solve, homogeneous series, and quadrature assembly.

## Wave C — finish the constructive block-11 path artifact (roughly 1–3 h)

Codex's first exact common-path wave is complete and preserved at

```text
/home/maxzhang/factorization-and-loops-codex/Runtime/
  2026-08-30_cf303_25_11_exact_common_path
```

Four 61-bit primes finished in 25.1 s wall time (about 21 s native per prime),
with 526 coefficients still above the 244-bit CRT reconstruction range. This
is healthy incompleteness, not an interpolation failure. Continue the same
campaign with four more primes and `--include-existing-primes`; do not restart
the first four and do not return to the 66,136-coefficient two-variable lift.

Driver:

```text
/home/maxzhang/factorization-and-loops-codex/Diagnostics/Scripts/
  cf303_25_11_exact_quadratic_path_campaign.py
```

Existing primes:

```text
2305843009213693951,2305843009213693907,
2305843009213693723,2305843009213693487
```

Next candidates:

```text
2305843009213693123,2305843009213692967,
2305843009213692799,2305843009213692671
```

After exact lift, adapt
`cf303_block14_unseen_path_validation.py` for one entirely unseen prime and
fresh points. Then emit the block-11 artifact and constructive exception
record on the same `u=3` contract. This establishes exact path forcing; it
does not by itself establish that every two-variable epsilon form is impossible.

## Wave D — upgrade the two obstruction claims without reconstructing huge functions (4–12 h)

The current rank defects are valid but alphabet-relative:

- `(25,11)`: 208x50, rank 48 / augmented rank 49 at three images;
- `(25,14)`: 1664x92, rank 56 / augmented rank 57 at three images.

Do not repeat the same systems at more primes. More primes cannot repair an
incomplete admissible space.

### D1. Block `(25,11)`: divisor-only lift plus pointwise E1 ladder

Avoid the expensive full Bbar lift. Only the divisor geometry is needed for
alphabet completeness:

1. reconstruct and match the common denominator factors and their pole orders
   across several primes, normalized by leading monomial;
2. CRT/lift only those low-height factor coefficients, then verify the factor
   product and valuations at an unseen prime;
3. homogenize the 15 finite polar components and include the line at infinity;
4. build pointwise E1 columns directly from the provider:
   regular monomial forms `m dt`, `m ds`, and `m dlog(f_i)` by total-degree
   shell, without materializing Bbar symbolically;
5. let closure/flatness select admissible combinations and run the
   gauge-eliminated rank test with FLINT multi-RHS;
6. use two configured plus one fresh modular image per refusal shell.

If no theorem-level infinity bound is derived, label the result honestly as a
bounded E1 obstruction through degree d, exactly as for block 18.

### D2. Block `(25,14)`: actual divisors on the multiquadratic cover

The present 23-letter source is a pre-cancellation operand upper bound, not the
prime-divisor table of the assembled forcing. Build the missing geometry with
the multiquadratic evaluator, not with a giant symbolic expression:

1. evaluate every assembled grade on all eight root-sign sheets and determine
   which candidate denominator factors survive, with their actual valuations;
2. reduce powers and associates and group surviving prime divisors into full
   sign orbits; lift only divisor equations/valuations;
3. add branch and infinity components of the normalized/projective cover;
4. state the allowed E1 coefficient field. If coefficients may lie in the
   multiquadratic field, include all eight root grades in the pointwise basis;
5. run nested degree shells of regular and polar polynomial-residue forms with
   FLINT multi-RHS at two configured plus one fresh image;
6. promote `EpsFormObstructionCertified` only after both the divisor space and
   the declared degree bound are complete. Otherwise retain the constructive
   path fallback with a bounded/alphabet-relative obstruction label.

The detailed audit to use as the checklist is:

```text
/home/maxzhang/factorization-and-loops-codex/Diagnostics/Reports/
  cf303_25_11_25_14_alphabet_completeness_audit_2026-08-30.md
```

## Wave E — package integration and concise final gate (roughly 2–4 h)

After A–C are green:

1. expose a separate generic entry point for transport on a typed path plan;
   do not add CF303 logic or family names under `Private/`;
2. assemble the complete path connection once, install accepted providers,
   compute one depth budget, then dispatch to ordinary words or terminal-block
   formal quadrature;
3. keep artifact/acceptance files in `Results/` once CF303 closes; keep only
   small family-neutral fixtures in `Tests/`;
4. run the focused path/quadrature tests, then the existing transport suites;
5. benchmark the real CF303 plan and report phase times and peak memory.

Do not broaden this round into more record hashes or duplicate acceptance
checks. The deliverables are mathematical: one correct pullback, honest
capability routing, a working formal quadrature consumer, the block-11 path
artifact, and stronger obstruction spaces.

## Requested reporting cadence

Please report after Wave A before wiring anything, then after the first real
`OKFormalPathQuadrature` result. Codex will keep the live CF259 solve untouched
and will not edit these package files while you work.

— Codex
