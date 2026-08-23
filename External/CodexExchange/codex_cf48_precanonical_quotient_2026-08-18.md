# Codex result: CF48 physical quotient before epsilon form

The proposed shortcut has been tested directly on the original 27-master CF48
connection. No Fable source or production record was modified.

The 14 master rows demanded by the hard contribution close under
\(\nabla_v q=\partial_vq+qA_v\) and
\(\nabla_w q=\partial_wq+qA_w\) to rank 27 after one derivative. This rank is
27 at three nonsingular exact rational points. Hence the demanded output sees
the complete differential module; canonicalizing an output quotient would not
reduce its dimension.

The original connection has minimum Laurent order \(\varepsilon^{-2}\).
Regularity gives rank 1 constraints on the 27 components of \(I^{(0)}\), and
rank 3 constraints on the 54 components of \((I^{(0)},I^{(1)})\), again at
three exact rational points. This right-side reduction is too small to offset
the full output closure.

There is also a structural obstruction to applying the finite CF27 lift before
epsilon factorization. In epsilon form, \(dF^{(n)}\) depends on
\(F^{(n-1)}\), so a finite Laurent window is invariant. In the original CF48
basis, \(dI^{(n)}\) depends on \(I^{(n+2)}\) through \(A_{-2}\). Repeated
differentiation therefore leaves every finite Laurent window. Eliminating that
upward coupling is part of constructing the epsilon form itself.

Conclusion: the CF27 observable-only method should be applied after CF48 has a
verified full-family epsilon form. It does not remove the present CF48/CF52
bottleneck. The correct next calculation remains the coupled block-distance
epsilon-factorization, beginning with all distance-one strips jointly.

Reproducible calculation and exact records:

- `Codex/CF48PrecanonicalQuotient/MeasurePhysicalClosure.wls`
- `Codex/CF48PrecanonicalQuotient/MeasureRegularityKernel.wls`
- `Codex/CF48PrecanonicalQuotient/PhysicalClosure_CF48.wl`
- `Codex/CF48PrecanonicalQuotient/RegularityKernel_CF48.wl`
- `Codex/CF48PrecanonicalQuotient/RESULT.md`

