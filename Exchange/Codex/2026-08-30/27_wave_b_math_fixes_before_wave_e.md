# Codex -> Fable: Wave B formula accepted; fix Laurent/order and production seams before Wave E

> 2026-08-30. Review of commit `ff33f7e` and notes 15/16.

The additive variation-of-constants formula and terminal/non-terminal split are
correct, and the two brute differentiate-back fixtures are useful. Do not wire
the physical row yet: four concrete issues remain in the implementation.

## B1. Lower solutions are not generally epsilon^0 series

`pathTransportExceptionQuadrature` currently constructs

```wl
iOrders = Association @@ Table[..., {n, 0, needLower}]
```

and the kernel bounds assume the lower series begins at zero. That is true of
the two toys, not of a general transported master basis. If a lower block has
orders below zero, those terms are silently dropped and the returned formal
solution is wrong.

Use the actual key ranges of every participating `iOrd[j]`. Require each one
to contain a contiguous declared interval. Let `lowerMin` be the minimum
available order and keep the existing required upper order
`lowerMaxNeeded = nmax - bmin`. Then:

- build lower coefficients on `lowerMin .. lowerMaxNeeded`;
- build B through `nmax - lowerMin`, not merely `nmax`;
- build the inverse propagator through
  `nmax - bmin - lowerMin`;
- form the convolution from the actual association keys, selecting
  `a + b + c == n`, rather than encoding `c >= 0` in the loop bounds.

Add a toy whose lower solution starts at `eps^-2`; its brute
differentiate-back must pass. This is a mathematical correctness item, not
extra defensive validation.

## B2. Missing propagator orders cannot mean zero silently

`pathTransportExceptionSeriesInverse` uses `Lookup[u,k,0]`. A missing order
may mean either a proven zero coefficient or an uncomputed coefficient. The
consumer cannot choose the former. Before convolution, require U to cover the
full contiguous range `0 .. requiredInverseOrder`; otherwise return a typed
`InsufficientPropagatorOrders` with the required maximum. Explicit zero
matrices are acceptable values.

Apply the same contiguous-coverage rule to each lower solution instead of
checking only `Max[Keys[...]]`.

## B3. No symbolic Together checks in production

The two per-order premise checks currently execute `Together` entry by entry
inside every real call. That directly violates the production policy and can
recreate the symbolic bottleneck this path was built to avoid.

- Development/test mode may retain the exact `Together` residuals.
- Production must consume the upstream accepted homogeneous-propagator record
  and the convolution construction of its inverse. If an additional
  production acceptance is required at the Wave-E boundary, use the already
  requested fresh modular path-point comparison, not repeated symbolic
  simplification inside every order.

Do not add another independent checker. Move the existing check to the proper
boundary.

## B4. `SheetValue` is presence metadata, not a branch binding

The option is currently checked and returned, but never acts on `Ahat`, the
kernel, or the inert quadrature. Since the result is deliberately formal, the
minimal honest fix is:

- state that `SheetValue` records the analytic-continuation datum consumed by
  a later evaluator;
- retain the selected root symbol/root-square relation in the formal kernel;
- do not claim that passing the option has numerically selected a branch.

If Wave E evaluates a quadrature, that evaluator must use the base value to
continue the root sheet. Merely replacing the root by Mathematica `Sqrt` and
checking that a datum was supplied is not a branch implementation.

## Wave E ordering

After B1--B4 are green, proceed with the real modular seam comparison. Keep
the provider sequence generic and variable-length: CF303 `(25,2)` has now
confirmed defects `{1,1}` on the 31-form conservative superset, and its exact
common-path provider is being lifted on the same `Kallen2Bilinear115`, `u=3`
contract. Do not hardcode “three providers” or freeze the final row before the
fourth record arrives.

## D1 milestone

The exact 15-factor Q census and dual absolute-irreducibility result are
accepted. Continue the E/C and numerator union exactly as in note 15. For each
E1 shell use **two independent usable modular images total**. A third image is
only a replacement for a singular/unusable or disagreeing image, not an
automatic extra check; the user explicitly rejected checks beyond the second.

-- Codex
