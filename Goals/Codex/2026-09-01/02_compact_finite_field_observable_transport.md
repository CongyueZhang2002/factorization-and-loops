# Compact finite-field observable transport

## Remove the hard-family symbolic bottlenecks

- [x] 🟢 Record the stopped CF230 baseline: 2,989.48 s and a 509,279,040-byte artifact, of which 97.84% is the generic symbolic boundary kernel.
- [x] 🟢 Replace a large moving rational nullspace by ambient Laurent-state evolution with one constant base-point kernel; keep the moving kernel for small systems where it is cheaper.
- [x] 🟢 Reuse certified dlog residues directly for the ambient spectator segment instead of repeating entrywise `Apart`/`Together` decomposition.
- [x] 🟢 Reconstruct each optional rational quotient system `A X = B` as one traced multi-right-hand-side Ratracer problem; do not reconstruct the full gauge or boundary kernel.
- [x] 🟢 Accept reconstructed coordinates at fresh unused primes and points, including the complete complementary rows; use the existing FLINT multi-RHS solve as an independent pointwise oracle.

## Eliminate combinatorial word materialization

- [x] 🟢 Implement the general demand-dual recurrence `O_w R_a = C_(a,w) O_(w+1)` without building a full fundamental matrix or a Cartesian word inventory.
- [x] 🟢 Preserve the correct ambient two-segment order `A_0 C... O_w K... N_base`; apply the boundary embedding after, not before, the spectator word.
- [x] 🟢 Select materialized words automatically for small systems and the exact lazy `OperatorAutomaton` for large systems using a bounded word-count estimate; retain the reconstructed compact quotient only as an explicit option.
- [x] 🟢 Supersede lazy transition shards with the smaller exact operator chain: a word query multiplies only its requested first- and second-segment operators and never loads a Cartesian word inventory.

## Reconstruct only the final requested result

- [x] 🟢 Add `ReconstructObservableTransportWordMaps`, which batches only requested final rational word maps over an identity prefix and reconstructs no intermediate gauge, nullspace, or quotient basis.
- [x] 🟢 Share compiled expression trees and modular evaluation DAGs across the full matrix, and exploit the structural identity prefix instead of rediscovering its rank symbolically.
- [x] 🟢 Evaluate only the two fresh trials actually required for identity-prefix reconstruction; retain reserve trials for generic sampled-pivot solves.
- [x] 🟢 On CF230 weight at most two, reconstruct and validate 120 final maps in 15.16 s from cache or 37.10 s from a fresh trace, versus 88.43 s for the first implementation; all 120 maps agree with the corrected materialized reference.

## Correctness and coefficient-field coverage

- [x] 🟢 Preserve every prior constraint row while extending a covariant closure basis; an exceptional rank sample can no longer exchange away a forbidden observable.
- [x] 🟢 Refuse sampled rank zero when the symbolic boundary constraint is nonzero, and validate representation payload dimensions before public acceptance.
- [x] 🟢 Certify constrained multiquadratic closure at split finite-field points, filtering constant radicands at prime selection and checking every sign embedding; the three-root test checks all eight embeddings.
- [ ] 🟡 Reduce nested or multiplicatively dependent radical square classes to an independent grade basis before branch enumeration; current unsupported cases fail safely but may over-enumerate.

## Production and regression gate

- [x] 🟢 Pass corruption, omission, duplicate-output, singular-point, pivot-only false-positive, cache-reuse, closure-row-loss, sampled-zero-rank, malformed-payload, and constrained-radical tests.
- [ ] 🟡 Match operator and materialized maps across a broader catalog sample; current post-fix evidence is CF27 at 33/33 maps and CF230 at 120/120 maps, plus rational and three-root algebraic unit systems.
- [x] 🟢 Benchmark a formerly slow ordinary family: corrected CF230 `OperatorAutomaton` builds in 3.36 s and occupies about 2.16 MB in-kernel, versus the 2,989.48 s / 509,279,040-byte old artifact. The fresh final reconstruction takes 37.10 s, of which Ratracer tracing plus reconstruction is 4.15 s.
- [ ] 🟡 Run the ordinary family campaign only after the finite-field backend and automatic selector pass these gates.
