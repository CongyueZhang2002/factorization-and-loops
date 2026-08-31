# CF303: constructive path blocks and native block 11

**To Fable — 2026-08-30 18:46 PDT**

This note records the current constructive results and the routes still in flight. It does not promote any block on resource hardness.

## Constructive results

- `(25,18)` has an exact one-parameter forcing solution on the common `u=3` path. Eight 61-bit primes were sufficient for the coefficient lift. An entirely unseen prime passed 64 matrix comparisons and 32 differentiation-back components. The typed artifact is `factorization-and-loops-codex/Diagnostics/Artifacts/cf303_25_18_exact_path_exception_record.wl`.
- `(25,14)` is a genuine three-root case on the same path. Two roots become rational and the remaining cover is quadratic over a squarefree irreducible sextic (genus 2). Writing the forcing as `B0 + r2 B1` produced an exact lift after twelve 61-bit primes / 732 CRT bits. A completely unseen 61-bit prime then passed 256 grade-value comparisons, 64 grade-jet derivatives, 64 physical derivatives, 32 root-derivative identities, and 64 local variation-of-constants components, with zero failures. The typed artifact is `factorization-and-loops-codex/Diagnostics/Artifacts/cf303_25_14_exact_path_exception_record.wl`.
- These are constructive transport providers along a fixed path, not claims of a global two-variable rational gauge. Their family/path data remain in typed artifacts; the proposed package seam is family-free.

## Block 14 promotion audit

- The required production-alphabet audit uses exactly 23 letters (10 algebraic + 13 supplied) and the existing gauge-eliminated integrability classifier.
- The unspecialized symbolic screen was capped after 20 minutes of its screen phase because it had made no observable progress.
- The epsilon-specialized replacement is running on the same two configured images plus one seeded fresh image. Until that returns, `(25,14)` must not be described as impossibility-certified. Its constructive path solution remains valid independently of that classification.

## Block 11 native route

- The selected-sheet native evaluator established that the residual third-root odd channel cancels and reconstructed the full Kallen23 forcing modulo `2147483423`.
- Exact degrees are `Q(t,s)=(44,58)`, reduced numerators `(47,59,5)` in `(t,s,eps)`, and epsilon denominator degree 8. The earlier failed lift was caused by an omitted pure-`s` denominator of degree 8 that is invisible in fixed-`s` denominator fibres.
- The successful campaign used 15,552 denominator images plus 20,224 numerator/final images and took 197.90 seconds combined. It passed 256/256 fully disjoint held-out `(t,s,eps)` comparisons. Artifact: `factorization-and-loops-codex/Diagnostics/Artifacts/cf303_25_11_full_bbar_modp.json`.
- The old symbolic chart materialization has already exceeded 31 minutes. Its penultimate 5.9 MB operand alone took 3,180 seconds; one 5.5 MB operand remains. It is being left alive only as an independent fallback while the native solve becomes installable.
- The active route is now a generic rank-zero chart pointwise provider: target chart points are mapped to source variables/root sheets, the deferred DAG supplies `BBar`, the source one-form is contracted with the chart Jacobian, and the existing affine finite-field ansatz/held-out acceptance is reused. A one-prime production-style verdict is expected in about 45 minutes. No CF303 literal belongs in `Private`.

## Common-path integration

- A scratch-only generic provider/variation-of-constants seam is implemented in `factorization-and-loops-codex/Diagnostics/Scripts/exact_path_transport_bundle.wl`.
- It keys providers only by ordered block bases/ranges, restricts ordinary blocks to the same parametric path and branch, sums hard-row terms inside `Phi^-1 . Sum[B_hm I_m]`, and leaves the final constant entirely caller-supplied from complete `PrevD`.
- A bounded one-master/no-subkernel smoke is prepared and will run as soon as the block-14 audit releases the Wolfram seat.

Please flag any conflict you see with the current continuation-driver conventions. In particular, do not treat the path artifacts as a license to bypass the new impossibility standard.
