# CF300-root rank-3 multiquadratic reconstruction evidence

Date: 2026-08-23 PDT

## Scope and verdict

This is an External-only development certificate for the identity-frame
multiquadratic sampler/reconstructor.  It constructs a nonzero scalar
off-diagonal equation using all three CF300 root squares

- `lambda2 = (1+x-y)^2 + 4 x y`,
- `lambda3 = (1-x+y)^2 + 4 x y`, and
- `1 - 4 x y`,

with nonzero gauge and forcing in every one of the eight basis grades.  No
rationalizing chart is used.

The result is positive: the existing rank-2 finite-field reconstruction
machinery extends without a mathematical obstruction to genuine rank three.
The eight-channel algebra, modular sampling, CRT/rational reconstruction and
exact channel certificate all pass.  This does **not** certify the physical
CF300 family and nothing here is wired into `FeynFacet/`.

## Genuine rank-three gate

The smoke test factors every nonempty product of the three root squares.  All
seven products have an irreducible factor with odd valuation, so no nonempty
product is a square in `Q(x,y)`.  Thus the three square classes are independent
over `F2`, and the eight grades are a field basis rather than duplicated
syntactic radicals.

## Executed tests

### Compact smoke: `fresh_cf300_rank3_mq_smoke_xh_v2`

- 22/22 checks passed; mission wall 5.16 s.
- Exact eight-channel residual: zero; exact-certificate time 0.084 s.
- One modular sample: 65 x 25, rank 25, nullity 0; assembly 0.294 s and
  canonical solve 0.0039 s.
- Every one of 24 gauge coefficients, all eight forcing grades, and the
  nonzero residue are exercised.
- All eight sign-flip masks return the same modular solution.
- All six root-catalog permutations and all six support permutations produce
  the same recomputed canonical ABI.
- An out-of-range sign mask, a duplicate root square, and a stale equation ABI
  are rejected with typed statuses.

### Three-prime reconstruction: `fresh_cf300_rank3_mq_reconstruction_xh_v1`

- 22/22 checks passed; mission wall 10.73 s.
- Training primes `{10007,10039,10067}` and regulator samples
  `{1/2,2/3,3/5}` reconstruct the 25-component vector at rank 25/nullity 0.
- Reconstruction time: 2.94 s; reconstructed vector equals the exact oracle.
- Held-out prime `1000003` at unseen regulator values passes.
- All eight sign masks pass at the held-out prime; total time 5.26 s.
- A freshly prepared root/support reorder passes the held-out check.
- Gauge, residue, result-fingerprint, stale-equation and stale-support
  corruptions are all rejected.  A training prime is refused as non-held-out.

### Matched-support scaling: `fresh_cf300_rank3_mq_scaling_s16_xh_v1`

- 6/6 checks passed; mission wall 11.54 s.
- With support size `S=16`, matching the earlier rank-2 evidence, rank three
  has 129 unknowns versus 65 at rank two and twice the equation rows per
  accepted point.
- The 129-component three-prime reconstruction is exact at rank 129/nullity 0
  in 9.33 s; the held-out prime/regulator/sign check takes 1.99 s.
- The rank-2 compatibility rerun in the same pool reconstructs 65 components
  in 2.69 s.  The measured rank-3/rank-2 reconstruction ratio is 3.46, while
  the unknown-count ratio is 1.985.  The comparison includes different oracle
  expressions, so it is an engineering datum, not an asymptotic exponent.

The exact accounting is

`U_r = m n 2^r S + L m n`,  `E_point = 2 m n 2^r`.

At fixed matrix dimensions and support, rank three doubles both the gauge
columns and branch rows.  Requiring all three radicands to split also changes
random-point acceptance from about one point in four at rank two to about one
in eight at rank three.  Dense Wolfram row reduction therefore scales worse
than the raw factor of two.  For physical blocks, the next performance step
should be the existing sparse/FLINT multi-right-hand-side path with cached
root-square evaluation, support and pivot data—not a larger symbolic solve.

## ABI defect found and fixed in the External prototype

The previous ABI fingerprint covered root squares, ansatz support, one-forms
and normalizations, but omitted the actual `{E,C,Bbar}` differential equation.
The verifiers also trusted a stored preparation fingerprint without
recomputing it.  A mutated equation could therefore remain nominally ABI
compatible.

`TripleRootReconstructionPrototype.wl` now includes a canonical equation
fingerprint and recomputes the full payload plus derived counts before sample
assembly, reconstruction, unpacking, exact verification, modular verification
or ABI comparison.  Fresh catalog/support reorderings remain compatible;
in-place stale mutations fail closed.  After this hardening, the original
rank-2 smoke remains 23/23 and its three-prime test remains 18/18.

## Remaining production boundary

1. Extract a genuinely nonzero physical CF300 rank-3 off-diagonal equation in
   the identity frame; the current oracle is constructed from the exact CF300
   square classes.
2. Infer and certify its gauge support and boundary normalization instead of
   supplying them from an oracle.
3. Route its modular matrices through the package FLINT backend and benchmark
   row construction, solve and reconstruction separately.
4. Retain the gates used here: exact square-class rank, canonical ABI,
   all eight sign labels, unseen prime/regulator values, exact channel
   residual, and deliberate gauge/residue/equation corruption.

## Files

- `smoke_result.wl`, `smoke.log`, `smoke_mission.status`
- `multiprime_result.wl`, `multiprime.log`, `multiprime_mission.status`
- `scaling_s16_result.wl`, `scaling_s16.log`, `scaling_s16_mission.status`
- `rank2_compat_*`: post-hardening compatibility evidence
- `SHA256SUMS`: hashes of every evidence artifact other than itself

The source oracle and runners live one directory above this evidence folder:
`TripleRootRank3CF300Oracle.wl`,
`run_triple_root_rank3_reconstruction_smoke.wls`,
`run_triple_root_rank3_reconstruction_test.wls`, and
`run_triple_root_rank3_scaling_probe.wls`.
