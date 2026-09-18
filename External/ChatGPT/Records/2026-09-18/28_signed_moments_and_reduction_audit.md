# Signed moments and reduction audit

Actual ChatGPT 6 Pro, 6m40s, inspected pushed revision
fb974069eb257c2f07286a281f5a1112169b89ac in
https://chatgpt.com/c/6aace49d-0888-83e8-a5f1-a9277443ef84.
Static source and mathematical review, not execution or inspection of the saved
physical constraints or active reconstruction. It read both MeasurementMoments
modules, AnalyticFactors, their tests, and the relevant shared normalization,
pair-chart, rational parser and reduction helpers.

The signed unit-cut construction is correct: for M=zF-G and fixed physical
sign sigma, set Fplus=sigma F=abs(F), Gplus=sigma G. The moment of
Fplus^(N+1) delta(M) against z^p(1-z)^q is
Fplus^(N-p-q) Gplus^p (Fplus-Gplus)^q, with no extra sign. The original cut
family remains unchanged. For higher normalized cut powers the sign law would
be C_m(-M)=(-1)^(m-1) C_m(M); the constructor's unit-cut restriction matters.
The earlier normalization, regulator, source-context and pair-label repairs
are correctly connected.

The selector implements exact outside-span cancellation correctly. Each
measured insertion receives its own z weight; a z-independent nullspace
combination cancels every polynomial coefficient of every uncovered GLI.
Clearing denominators is only a device for constructing this kernel. The same
combination multiplies the inclusive RHS without applying the weights again.
Treating uncovered integrals as independent may miss valid constraints but
does not create false cancellations for exact compatible input identities.

Two bounded interface repairs were requested:

1. Apply exact rational coefficient validation to all supplied rule RHSs,
   weighted measured images and inclusive images, not just outside-span terms.
   Otherwise approximate coefficients can pass when there are no outside columns.
2. Retain the validated reduction families, basis, rules and scope with the
   saved selector. Qualify its exactness as an algebraic consequence of those
   supplied identities, not an independent proof of them. No new hash or native
   solve is needed.

The generic nullspace may introduce regulator or external-parameter denominators.
Keep exceptional loci explicit before specialization, or clear row denominators
on both sides. Restore D=4-2epsilon before valuation/rank decisions. Collect the
inclusive combination exactly before requesting scalar orders. Moment integration
itself can introduce extra epsilon poles; pointwise coverage is insufficient.
Continue the complete physical row or use regulated endpoint subtraction before
expanding; singular z-dependent factors cannot be applied to independently
extended endpoint distributions without further justification.

The useful rank is the continued moment matrix acting on unresolved homogeneous
DE modes. The number of algebraically covered rows is not a fixed-constant count.
A moment used to fix a constant cannot also validate it independently.

Pro recommends the identical-quark physical interior as the next decision gate:
save every source-required Laurent coefficient through the requested order, fix
every homogeneous mode affecting it, audit reduction-induced epsilon demands,
and use an independent check. If a small unresolved block or rank deficit remains,
isolate that obstruction before broadening the machinery. Success would still
leave the measured gluon component and RR endpoint/contact proof unfinished.
