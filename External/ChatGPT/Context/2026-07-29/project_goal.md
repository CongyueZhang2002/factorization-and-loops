# FACET-NLO Project Goal

This file is the authoritative statement of the scientific objective. Tool and
workflow choices must be evaluated against it.

## Required scientific output

FACET-NLO must produce reproducible, exact analytic hard-scattering
coefficients for factorized collider observables. The immediate physics problem
is single-inclusive hadron production, `p p -> h X`, including its polarization
channels and the ingredients required for a complete fixed-order result.

The final output must retain symbolic dependence on the physical invariants,
convolution variables, and dimensional regulator. In particular, the workflow
must determine analytically:

- the required Laurent coefficients in `Epsilon`;
- endpoint factors such as `(1 - w)^(-1 - a Epsilon)`;
- the coefficients of `delta(1 - w)` and the plus distributions;
- the real, virtual, renormalization, and factorization contributions in a
  common convention;
- the physical branch and causal prescription of every contribution.

High-precision values at selected kinematic points are checks or auxiliary
boundary information. They are not the project deliverable and cannot replace
an analytic result.

## Current milestone

The current reverse-unitarity development must reproduce the established
analytic `UU` and `LL` real-emission results for `p p -> h X` without using
those results as input. It must then support the `TT` channel with the BMHV
evanescent structure treated consistently. The reconstructed result must retain
enough exact endpoint information to perform the distributional expansion.

The complete NLO calculation must combine this real contribution with the
virtual correction, ultraviolet renormalization, and collinear factorization
counterterms and pass exact comparisons wherever an independent analytic
benchmark exists.

## Intended calculation flow

1. Generate amplitudes and conjugate amplitudes from declared process data.
2. Apply the leading-twist collinear distribution and fragmentation projectors.
3. Encode the physical on-shell phase space and preserve the identity and
   energy flow of every cut line.
4. Derive partial fractions and integral families from the denominators that
   actually occur, rather than from a process-specific expected list.
5. Reduce the integrals exactly with cut-aware IBP identities.
6. Evaluate the required cut master integrals analytically as functions of the
   kinematic variables and `Epsilon`.
7. Reconstruct the hard contribution, analyze its endpoints, expand it into
   distributions, and combine all fixed-order terms.
8. Verify each stage against independent identities, limits, numerical points,
   and known results without using a benchmark to define the calculation.

The amplitude, factorization, fractioning, and IBP stages should remain
invariant and process-independent as far as possible. Process-specific
coordinates may be introduced after IBP when they are genuinely required to
obtain an analytic master integral; they must not be hidden assumptions of the
earlier stages.

## Method constraints

- A proposed main method must return analytic functions, not only values at
  fixed kinematic points.
- Standard AMFlow may be used for independent checks or boundary diagnostics.
  Its ordinary fixed-point output is not a substitute for analytic master
  integrals.
- SubTropica may be used when it produces an analytic Laurent expansion for the
  relevant integral. Taking one overall discontinuity of an ordinary integral
  is valid only after proving that it isolates exactly the required physical
  cut.
- When an analytic cut master is not directly integrable, the next route is an
  exact differential equation in the physical variables with analytically
  determined boundary data. Replacing the missing result by numerical samples
  does not complete the task.
- Cut identities, causal prescriptions, BMHV dimension shifts, branch choices,
  and normalization factors must remain explicit and testable.
- Automation must fail clearly when its assumptions are not satisfied. It must
  not silently discard a cut, choose a branch, infer a mass, or reuse a known
  answer.

## Longer-term scope

After the analytic NLO workflow is complete and independently validated, the
same design may be extended to additional factorized processes, measured event
shapes, and NNLO sectors. A successful numerical multiloop test demonstrates
feasibility only; it does not establish an analytic NNLO workflow.
