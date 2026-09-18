# Physical transversity and dimensional fragmentation normalization

The reference h1 and H1 use physical components of the tensor light-ray operator
renormalized by minimal subtraction in D dimensions. The Wilson line is
Dirac-scalar. For g=(+---), epsilon^(0123)=+1 and gamma5=i gamma0 gamma1 gamma2
gamma3, BMHV implements the exact identity

    bar(sigma)^(mu nu) gamma5 = (i/2) epsilon4^(mu nu rho sigma) bar(sigma)_(rho sigma).

Thus the physical pseudotensor insertion and physical dual-tensor insertion
are equal before integration. The Hodge map is epsilon independent, so it
commutes with pole subtraction and recursive subtraction of subdivergences.
Their finite conversion is unity, for the PDF and for the cut FF separately.
This argument includes endpoint and Wilson-line terms; it never anticommutes
gamma5 through hatted gamma matrices. Evanescent structures must not be
projected away before subtraction. A different epsilon-dependent evanescent
basis or finite prescription requires its own conversion.

This tensor definition is used in the transversity literature, e.g.
https://arxiv.org/abs/1702.06558 section 4 before Eq. 35. The general evanescent
scheme caveat is https://arxiv.org/abs/hep-ph/9412375. The local rank-two tensor
check is https://arxiv.org/abs/hep-ph/0007171. These references do not turn this
hard-coefficient project into a TMD calculation.

The hard-side incoming density is gamma5 slash(S) slash(p)/2; the outgoing
analyzer is gamma5 slash(s) slash(k), dual to the scalar fragmentation operator.
The transverse antiquark insertion has the same sign. Align each external
physical spin and calibrate its partonic distribution to delta(1-v). The
published one-loop transversity kernel is CF[2/(1-v)_+ -2+3 delta(1-v)/2]. Its
unresolved angular average uses D-2, not the physical spin-pair average of two
orientations. The residual normal to three fixed external momenta instead
has dimension D-3; the package keeps these operations separate.

For the canonical amputated no-flux tensor, evaluated at physical observed
momentum with that momentum's measure excluded, incoming rescaling uses dxi/xi.
The [bare-operator derivation](FragmentationNormalization.md) fixes the outgoing
action as **dzeta/zeta^(2-2 epsilon)**: the longitudinal Jacobian supplies
zeta^-2 and scalar extraction relative to slash(k) supplies zeta^(2 epsilon).
No observed momentum integration is required. A stripped distribution/spin
projector can keep its familiar integer powers; its conversion to the full bare
cut matrix is specified separately. Physical d3k labels the final observable
and does not replace this regulated operator-to-density relation.

The extra zeta^(2 epsilon) produces finite 2 log(zeta) times the pole residue;
it is unrelated to gamma5 conversion. Born, real and virtual share the same
external insertion. An actual regulated density conversion instead transforms
all contributions and conjugates the counterterm action. This agrees with
https://arxiv.org/abs/hep-ph/9605323 Eqs. 6.14 and 6.17--6.19.

The generic ConvolvePartonicMappedKernel interface verifies the fraction map,
its endpoint and source rescaling, and propagates this exact dimensional
measure through the epsilon-order audit. Tests compare its Born delta pullback
and finite FF logarithm to independently integrated constraints, including
malformed-map rejection. A full new-process result still requires real/virtual
pole cancellation and scale checks; an operator identity is not a substitute
for those checks.
