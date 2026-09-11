# Inclusive electromagnetic Drell–Yan, NLO UU

Execution and CPU policy: [WORKFLOW.md](../../WORKFLOW.md).
Available retained channels: [project index](../README.md).

The root card defines d sigma_hat/d Q2 = 4 pi alpha_em^2/(3 Nc Q2 s)
times C_DY(z), with z=Q2/s. Rapidity, pair transverse momentum and lepton
angles are integrated. C_DY includes the flavor charge squared. The complete
scalar leptonic tensor is factored out before epsilon expansion; the QCD
current and the real photon momentum remain D-dimensional.

Each incoming PDF has its own declared Mellin convolution. There is no FF.
The generated Born coefficient is e_q^2(1-epsilon) delta(1-z); retaining its
epsilon term is necessary for the finite collinear counterterms.

Production: Scripts/run_nlo_hard_function.wls DrellYan_UU_NLO CHANNEL all.
Independent reference files belong only to validation. All six NLO channels are complete through epsilon one. Fresh runs take
8–22 seconds per channel, including generated Born dependencies. The explicit
finite and epsilon-one coefficients agree exactly with the original
Höschele et al. ancillary file (arXiv:1307.6925) after its documented x and
coupling conventions are translated. All 18 checks pass; details are in
NLO/q-qbar/Results/Validation/LiteratureComparison.wl.
