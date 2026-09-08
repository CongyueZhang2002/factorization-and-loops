# CF303 21->11 pointwise support checkpoint (2026-08-24)

## Decisive result

CF303 21->11 is not a three-root block.  A dependency-closed finite-field oracle, evaluated on every sheet of the three-root extension at four independent split primes, finds support only in grades `{0,1}` of the ordered basis

`{1,Lambda2,Lambda3,Lambda2 Lambda3,Bilinear115,Lambda2 Bilinear115,Lambda3 Bilinear115,Lambda2 Lambda3 Bilinear115}`.

Thus the only active radical is `Lambda2`; the complete 21->11 problem belongs in the ordinary one-root `Kallen2` chart.  The six grades involving `Lambda3` and/or `Bilinear115` vanish at every accepted point.  This result replaces the abandoned whole-symbolic Kallen23 residual route.

## Certification policy

Per the user-approved package convention, acceptance is based on fresh exact finite-field evaluations rather than construction of a global symbolic residual.  Four distinct primes, one admissible source/chart point per prime, and all eight conjugate sheets per point give 32 sheet evaluations.  The checks include the lower-row recurrence, an independently assembled local numeric matrix update, root-square identities, exact eight-sheet Hadamard projection/recomposition, both diagonal blocks, and forcing support.

The primes are `{1995583,1419839,1575239,1940423}`.  The observed forcing support is `{True,True,False,False,False,False,False,False}`; both diagonal blocks have grade-zero support only.  Every embedded gate is `True`.

Under the explicitly heuristic random-field-value model, the false-zero probability for any particular omitted grade is at most `1.1546470676e-25`; the union bound for all six omitted grades is `6.9278824057e-25`.  This is not presented as a symbolic degree theorem.  It is the intended high-confidence point-evaluation certificate.

## Sparse oracle

The oracle never materializes the exact source-frame 19->11 gauge, never transforms the full 45-by-45 connection, and never calls `Together` on a global residual.  It evaluates only the dependency-closed column `A_{bullet,11}`.  Rows 17, 19, and 20 are updated by the exact lower-row recurrence and row 21 by the certified left action.  The result is cross-checked against an independent 27-by-27 local numeric column-matrix construction before the eight Galois conjugates are projected to the root basis.

The inverse Kallen23 map is evaluated lazily through the exact root-linear formula

`p=(1-r1-x-y)/2`,

`q=(1+r1-r2-r1 r2-r1 x-r2 x-x^2+2 y-r1 y-r2 y-2 x y-y^2)/(2 y)`,

whose exact forward round trip is `{0,0}`.  This removes the symbolic source-pullback bottleneck while retaining all sign sheets.

The package prototype `FeynFacet/Private/FamilyRowGaugeFiniteField.wl` supplies the established modular evaluation, square-root, conjugate-projection, and round-trip conventions read-only.  No package source was modified.

## Immutable artifacts

- Oracle driver: `C:\Users\congyue zhang\Documents\ChatGPT\Agentic Loops\run_cf303_21_11_pointwise_forcing_oracle_pilot_v1_2026-08-24.wls`.
- Oracle driver SHA-256: `a35c1a7ce29005636281aaa8bce7d302a75a18cd1278fe94c456aaf612ffc887`.
- Aggregator driver: `C:\Users\congyue zhang\Documents\ChatGPT\Agentic Loops\run_cf303_21_11_pointwise_support_certificate_v1_2026-08-24.wls`.
- Aggregator driver SHA-256: `98367896da5e4f06445f607723713c711e68e15819b03779adf6a4e85414ede9`.
- Certificate: `/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/cf303_21_11_pointwise_support_certificate_v1/certificate.wxf`.
- Certificate SHA-256: `119b760406eab5edbf07a907e4f8a740ac1bc02b4ec24f35c755365b0f7d285a`.
- Certificate status: `CF303Sector2111PointwiseSupportCertifiedV1`.
- Sample payload SHA-256 values: `fb844f4fb01c61c2f86e873a52dc0beb4e061155d37dfffaf51c5cec6ef07f58`, `cc9e4a2e8d8fb43b2c136b0e796d512781427fff05b4d1f1a0e4cf17b7d6172b`, `63c2f656975ce15337c138f6dc20014d775761bb20e4c14a8489326562b94af4`, and `f7200bd80530b6b7c0f9397b41a89559f91f441ee757aa17913dce48b6f72808`.

## Next action

Do not spend more time on a global symbolic certificate for this block.  Solve 21->11 through `Kallen2`, using the sparse point oracle as the sampler backend (or reconstructing only the required 2-by-1 rational strip), and retain fresh-prime pointwise checks as the final acceptance gate.

## Scope and safety

Only scratch drivers, scratch artifacts, and this Exchange report were written.  The package source under `/home/maxzhang/factorization-and-loops` was not modified.  The seven inherited pool missions and all user processes were left untouched.
