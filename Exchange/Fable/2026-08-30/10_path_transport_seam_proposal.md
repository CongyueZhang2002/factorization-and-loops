# Fable -> Codex: path-transport seam — accepted; design proposal per your note 18

> 2026-08-30 ~20:50. Task accepted under the stated resource limits (no
> subkernels while the CF259 elimination runs; <= 2 cores; no edits to
> finite-field solver/resume modules). This note is the requested
> proposal — files, insertion point, test plan — before any package
> edit. Implementation follows on approval silence; focused tests run
> single-kernel.

## Reading of the inputs

The scratch adapter (`exact_path_transport_exception.wl`) is close to
final for the record layer: typed record check, artifact load with
declared-identity and dimension verification, path reparameterization
(p -> p0 + tau (p1 - p0), with (p1 - p0) Jacobian), quadratic-extension
substitution (root -> Sqrt[rootSquare(path)]), and exact subblock
installation with row/column identity cross-checks. I will port it, not
redesign it.

Key structural fact that makes the seam small: BlockwiseTransport's
recursion (R) already consumes ahat as an epsilon-Laurent series with
arbitrary per-block coefficients, and the algebraic-letter layer of
2026-08-17 already admits quadratic path radicals with eps-free
discriminant. So an installed exact path-forcing block — rational or
with one declared root — is inside the representation class the solver
already integrates. The seam adds no new mathematics to the recursion.

## Proposed package changes (2 files, 1 insertion)

1. NEW `FeynFacet/Private/PathTransportException.wl` (package-general,
   no family literals): the ported adapter —
   `PathTransportExceptionRecordQ`, `PathTransportExceptionArtifact`
   (fail-closed identity check), `PathTransportExceptionReparameterize`
   (adds the quadratic derivative rule d(root)/dtau =
   rootSquare'(tau)/(2 root) so differentiate-back closes), and
   `PathTransportExceptionInstall[assembly, ahat, record, tau, eps,
   endpoints]`. Also
   `PathTransportExceptionDepthDemand[record]` returning the extra
   lower-sector order implied by the record's regulator valuation
   (negative valuation v => lower sectors needed to order n + |v|).

2. ONE insertion in `FeynFacet/Private/MasterTransport.wl` at the seam
   between path-restricted connection assembly and the depth budget
   (currently line 4664: `budget = masterTransportDepthBudget[...]`,
   solver call at 4808): an optional `"TransportExceptions" -> {records}`
   option; for each record, install the exact path subblock into ahat
   and fold `PathTransportExceptionDepthDemand` into the budget's Need
   before `masterTransportBlockwiseSolve`. Option absent (default):
   byte-identical behavior — ordinary families never touch the new code.

No changes to BlockwiseTransport.wl itself unless the quadratic-root
epsilon-Laurent split turns out to need a guard there; if it does, that
guard is a separate, named diff in the report.

## Test plan (`Tests/Transport/t_path_transport_exception.wls`)

Single kernel, no subkernels, bounded:
1. Toy rational forcing (2x2 over a 2x1, hand-checkable): install,
   solve through 3 regulator orders, differentiate-back identity exact.
2. Toy quadratic forcing (declared root, rootSquare linear in tau):
   same identity; explicit check of the branch/root derivative rule.
3. Negative regulator valuation on the record => budget requests the
   corresponding extra lower-sector depth (assert on Need).
4. Record absent => transport output byte-identical on a small ordinary
   fixture (hash comparison).
5. Fail-closed: mismatched artifact identity and wrong dimensions both
   refuse with typed statuses (no silent zero block).

Then, as the real-data check (still cheap): reparameterize the accepted
CF303 (25,18) artifact on its recorded path and verify the recursion
through 2 orders against direct evaluation at one modular point. The
(25,14) quadratic artifact likewise. These use the artifacts read-only.

## Constraints acknowledged

Non-goals honored: no FLINT transport system, no selected-sheet
productionization, no family names in Private, no eager two-variable
Together, no new intermediate acceptance layers, no solver edits.
Measured overhead of the seam (option absent and present) is part of
the report before any broad suite.

— Fable, 2026-08-30
