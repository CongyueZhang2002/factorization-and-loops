# Public polarized qg NLO reference

Model: verified outgoing `gpt-6-pro`; request HTTP 200.
Request: `d282f8a2-d142-488c-94a0-09363ef6bb82`.
Conversation: `6aa0f5dd-de10-83e8-b032-74f47d77da2a`.

## Question

The SIDIS NNLO UU/LL campaign is complete, with all 26 final files and full five-point distributional reference comparisons passing. One separate older NLO benchmark remains: independent full finite incoming longitudinal qg->qX and qg->gX single-inclusive identified-hadron hard coefficients (unpolarized fragmentation D1). Production is already explicit, helicity MSbar, all poles cancel. UU agrees with INCNLO. We must not claim UU or threshold-only checks validate LL.

Can you locate a concrete publicly downloadable primary reference implementation or complete analytic coefficient listing for polarized qg NLO, suitable for checking delta, both plus terms and the whole regular coefficient? Jager/Schafer/Stratmann/Vogelsang hep-ph/0211007 section 2.5 has the generic decomposition but not the coefficient values. De Florian's independent Monte Carlo calculation hep-ph/0210442 may be another route. Check specific public URLs/repositories or the Jager dissertation https://epub.uni-regensburg.de/10206/. QCDHUB public JAM repositories examined so far expose PDF grids/jet theory, not identified-hadron hard kernels. We have Werner's qq-prime Mathematica file only. Do not invent links or suggest matching to UU, a Born identity, or just threshold terms. If no public full reference can be located, say so and identify the smallest genuinely independent partial checks and exactly what cannot be concluded. No author contact is authorized. Please keep the response focused on executable reference access, not a new production computation.

## Pro response

I located a concrete public implementation containing the full polarized identified-hadron kernels: QCDLab/navis
, specifically navis-pol/src/mes.rs. It has separate delta, both plus-distribution, and regular functions for qg→q+X and qg→g+X. This is actual hard-kernel source, not merely PDF grids or jet tables. Its README cites both hep-ph/0211007 and hep-ph/0210442.

Qualification: I verified the public source and its channel/distribution structure. I have not compiled it, independently validated its NLO formulas, or established that it is an authenticated copy of either original author-distributed code.

1. Exact source and channel entry points

Pin the inspected version to commit

89dab06673c4b6d2a142236d5d0109642cfc3b57

rather than tracking a changing main branch. The repository identifies this source snapshot as version 0.2.0.

The principal file is:

Pinned polarized analytic kernels — navis-pol/src/mes.rs

Its public functions expose the required pieces:

Distribution component	Function
δ(1−w)	avdel(j0, v, s, ctx)
[1/(1−w)]
+
	​

	avwpl(j0, w, v, s, ctx)
[log(1−w)/(1−w)]
+
	​

	avlo(j0, w, v, s, ctx)
Full regular remainder	struv(j0, w, v, x3, s, ctx, pre)

These roles are explicitly documented in the source, and the integration driver implements the corresponding endpoint subtractions.

The one-based channel arguments are:

j0 = 13: q
i
	​

g→q
i
	​

+X, with regular function qg_compton_quark_frag.

j0 = 14: q
i
	​

g→g+X, with regular function qg_compton_gluon_frag.

Both are dispatched explicitly by struv. Channels 8, 9, and 10 are different tagged-flavor contributions—qg→q
′
, qg→
q
ˉ
	​

′
, and qg→
q
ˉ
	​

—not substitutes for channel 13. The PDG-channel definition
 independently confirms this mapping.

The polarized PDF/FF interface explicitly uses polarized incoming PDFs and unpolarized fragmentation functions, so this is the observable class you requested.

2. Executable access and the smallest comparison route

The repository documents a Cargo installation and provides navis-pol and navis-unpol executables. The inspected manifest requires Rust 1.91.0 or newer. A pinned source installation is:

Bash
git clone https://github.com/QCDLab/navis.git
cd navis
git checkout 89dab06673c4b6d2a142236d5d0109642cfc3b57
cargo install --locked --path navis-cli

The README also documents cargo install navis-cli, but the pinned checkout is preferable for a reproducible benchmark. I have not executed either installation here.

For your coefficient-level comparison, call or translate the kernel functions directly rather than running the hadronic Monte Carlo. That avoids dependence on PDF/FF choices, VEGAS statistics, and interpolation grids. The necessary scalar context is explicit:

MeContext {
    ca, cf, nf, pi,
    q2fac, q2mu, q2frag
}

precalc(v,w,s,ctx) supplies the common logarithms and powers for the regular functions.

Two accompanying source files are essential for interpreting the returned quantities:

Polarized assembly and plus subtractions — integrand.rs

Channel normalization factors — constants.rs

Do not identify an avdel or struv return value directly with your normalized coefficient. The wrapper supplies channel factors, powers of the partonic energy, v,w factors, coupling powers, and phase-space Jacobians. For channels 13 and 14, the documented channel factor divided out by the driver is

CC=8N
c
	​

(N
c
2
	​

−1).

Those are source-defined conversion factors, not factors to fit to your result.

The beam-exchanged wrappers also mix endpoint coefficients: fdel2, for example, contains logarithms multiplying avwpl and avlo. Therefore, map the exact incoming ordering and observed leg; do not implement crossing as only v↦1−v on each distribution coefficient separately.

The formulas are written as f64 expressions. For symbolic comparison, translate the written rational arithmetic and logarithms, not numerically evaluated doubles. Keep the pure-QCD channel routines separate from the repository’s later QED additions.

3. Provenance and validation limitations

The source is a direct, publicly accessible implementation whose README declares the two original hadron calculations as its basis. Its routine comments preserve Fortran-style names such as AVDEL, AVWPL, AVLO, and STRUV. I did not establish which original code supplied each polarized expression or whether the translation was checked term by term against the original author files. It should not be presented as two independent implementations merely because it cites two papers.

The inspected public regression file
 tests polarized/unpolarized LO fixtures and consistency with grid output disabled. It does not document a full NLO coefficient-level validation. Consequently, this discovery establishes access to the full candidate reference, not that the port is an infallible benchmark.

This distinction need not block your comparison. It means the defensible resulting claim would be:

The generated polarized qg coefficients were independently compared against the publicly archived navis-pol implementation at the specified commit, after an explicit convention conversion.

Claiming direct agreement with the original Jäger/Vogelsang or de Florian code would require establishing that additional provenance.

4. What the dissertation and original-paper checks found

Jäger dissertation: the verified downloadable PDF
 does not provide the missing analytic listing. On printed page 59, immediately after equation (4.16), it explains that the lengthy coefficient expressions are omitted and reside in the authors’ computer codes. Appendix B contains leading-order cross sections, not the NLO qg coefficients. The repository landing page exposes the thesis PDF, not a corresponding code archive. 
Regensburg PubServer
+2
Regensburg PubServer
+2

De Florian: hep-ph/0210442
 describes an independent subtraction-based Monte Carlo for identified-hadron production, including polarization. I did not locate a public standalone release of that original implementation through the paper record or the searches performed. The paper’s numerical results are not a downloadable channel-resolved listing of all four distribution components. 
arXiv

Bottom line: the search did find a usable public full-kernel source, QCDLab/navis, channels 13 and 14. That is the concrete next reference-access route. An authenticated original 2002/2003 author-code archive remains unlocated; no UU, Born, or threshold comparison should be used to replace the full LL comparison now made possible by this source.

## Subsequent local validation

Independently located and pinned the same Navis commit. Compiled the unmodified
UU/LL `mes.rs` sources directly with rustc 1.75, using plain flavor containers
only to satisfy unused PDF function signatures. No Cargo/PDF/grid dependencies
or coefficient translation were needed. All 320 full coefficient comparisons
pass: four channels, two polarizations, ten points, four distribution components.
The largest relative error is below 3e-13. The UU subset also passes all 128
comparisons against original INCNLO. Full incoming-LL qg checks comprise 80
values across observed quark/gluon. These validate against public Navis,
not an authenticated original Jager/Vogelsang or de Florian source archive.
See `Projects/ppHX_LL_NLO/NLO/qg-qg/Results/Validation/NavisReferences.log`
and the per-channel `NavisReferences.wl` reports.
