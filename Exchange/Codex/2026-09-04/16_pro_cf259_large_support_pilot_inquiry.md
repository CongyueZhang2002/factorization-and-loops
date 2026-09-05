# CF259 large-support pilot: request for an algorithmic review

Please answer in the existing **Assess Multiquadratic Pipeline** conversation, using `gpt-6-pro`. Review this as a mathematical/algorithmic finite-field interpolation problem, not as a request for more defensive checks.

The current live CF259 production run has successfully solved and accepted the former triple-root blocker `(26,1)`. The next strip `(27,23)` is now spending minutes in FLINT plan discovery because the default `SimplexFirst` route selected the complete certified numerator simplex of total degree 75. The exact live dimensions are:

- affine system: `11,776 x 11,764` over `GF(1000003)`;
- dense CFFR1 request: 1.1 GiB;
- FLINT `nmod_mat` RREF: eight native threads, about 5.9 GiB RSS, still running after five minutes;
- Wolfram parent: waiting, about 8.2 GiB RSS.

The relevant live code is the `SupportStrategy`, support-ladder, degree-probe, and support-learning logic in:

`FeynFacet/Private/EpsForm/FiniteField/FiniteFieldOffDiagonalBlockSolve.wl`

Its current alternative `"SparseFirst"` tries rectangle-cut supports and an offset ladder before the full certified simplex. Any successful candidate is later checked at held-out epsilon images and by an unseen-prime residual; the family has a separate final mathematical certificate. A previous comment says a bare denominator-degree rectangle once gave a false negative because a true solution required x-degree 6 when the denominator x-degree was 3, but the offset ladder and terminal simplex were added for that reason.

Questions:

1. Is switching the production default from `SimplexFirst` to the existing `SparseFirst` mathematically sound under this validation contract, or is there a subtle way it can accept a wrong or gauge-incoherent support?
2. Can we infer a substantially smaller candidate support directly from the differential equation, denominator factorization, valuations, Newton polytopes/Minkowski sums, or the already computed deferred DAG, so that the degree-75 full simplex is only a no-go oracle?
3. Would a sparse modular linear algebra backend materially help, or does the structured PDE system admit a better elimination order or block decomposition that avoids a near-square 11.7k dense RREF?
4. What is the simplest major-gain intervention you would implement now, without adding layers of checks or complexity?

Please give a concrete recommendation and the minimum validation required. Do not propose symbolic fallback or extra exact certification in production.
