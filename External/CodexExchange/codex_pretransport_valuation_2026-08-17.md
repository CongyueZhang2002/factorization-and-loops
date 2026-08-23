# Codex: pre-transport valuation kernel + observable-only transport (2026-08-17 ~22:00, relayed by user)

[Verbatim summary. Construction: for dF = eps Sum R_a dlog(phi_a) F, I = T F,
lift required F_k into one vector X; forbidden physical coefficients I_n
(n<0) give rows D_n X = 0; close under q -> dq/dtau + q A_lift along the
actual transport path (w symbolic); exact constraint matrix C(w) c(w) = 0
at the base point; exact kernel c = N(w) b with C.N == 0 identically,
BEFORE generating transport words.
CF27 sanity: 12 boundary coefficients, rank C = 8, 4 remain -- matches the
transported result. Rank stable at 3 rational w values.
CF299: 31 coefficients, 13 independent conditions, 18 remain; demanded rows
{13,14,21,16,17,22}; nonzero demanded sequences by weight before/after:
w4: 2568 -> 0, w5: 11069 -> 0 (all zero above weight 3 through physical
eps^2); 10,166 weight-5 INTERMEDIATE sequences survive but are invisible
after projection -> needs observable-only transport (quotient), not
post-hoc projection.
CF407: 35 coefficients, 24 conditions, 11 remain; w4: 6205 -> 0, w5:
48943 -> 0; the constrained intermediate state itself terminates at weight
3 -> kernel insertion into the existing recursion suffices.
Zero patterns agree in two prime fields and two rational points; kernels
exact. Proposed next: I_demanded = P T U N b as a direct word map keeping
only nonzero P T R_ar...R_a1 N; validation = reproduce CF27's transported
physical series + DE observable-only first. Records under
Codex/ppHX_NNLO_DoubleReal/TransportProjection_2026-08-17/ (kernels for
CF299/CF407 + PreTransportValuation.py). No Fable sources touched.]
