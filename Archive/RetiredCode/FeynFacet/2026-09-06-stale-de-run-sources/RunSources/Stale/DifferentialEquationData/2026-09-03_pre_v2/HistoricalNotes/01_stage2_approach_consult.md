# Consult (2026-08-17, 10:00 PDT): stage 2 of the NNLO double-real master evaluation — are we on the right approach?

Self-contained. Provenance tags: **[V]** verified by exact computation in this session (artifacts on disk), **[C]** claimed by an automated agent session and not independently re-derived by the coordinator, **[X]** external (Codex/other reviewer). No numerics enter any proof chain below; numerics are only mentioned as cost measurements.

## 1. The problem

NNLO hard function for pp → h+X via collinear factorization and reverse unitarity, double-real channel. 347 master integrals (cut phase-space integrals in d = 4−2ε), organized in 91 "families" (Kira integral families), each family a first-order linear system of differential equations in two dimensionless kinematic variables (v, w) with regulator ε: dI = A(v,w,ε) I, A rational. Physical region 0 < v, w, v+w < 1. Masters are finite at generic (v,w) (poles arise only from endpoint expansions; "physical valuation 0"). The consumer is the hard function through ε⁰; per master, the ε-depth actually required is measured from the exact ε-Laurent valuation of its coefficient column in the reconstructed hard function **[V]**: 203 masters need ε⁰, 131 ε⁻¹, 7 ε⁻², 1 ε⁻³, 1 ε⁻⁴ (plus one order of "safety" by our convention). Deliverable of stage 2: every master, symbolically, to that depth, up to integration constants (stage 3 fixes constants; stage 4 does endpoint / plus-distribution expansion, which needs the local Frobenius modes unexpanded in ε).

Compute: one shared Wolfram license, 1 main + 8 subkernels, shared with a parallel Codex assistant. Packages available: Libra, CANONICA, PolyLogTools, HPL, AMFlow, DiffExp (fetched), Kira, FireFly/Ratracer, asy, MB.m, HypExp, SubTropica.

## 2. Method as built

**Stage 1 (closed) [V].** Each family's system is decomposed into strongly connected blocks (1119 blocks); blocks are classified into 173 equivalence classes (basis permutation ∘ optional v↔w); every class has a certified ε-form dF = ε Σ_a R_a dlog φ_a F with constant residues (exact reconstruction gate, both variables). 149 classes are rational in (v,w); 20 are ε-forms only in a conic chart rationalizing ONE quadratic (λ₁ = (1−v−w)²−4vw, λ₂ = λ₁(−v,w), λ₃ = λ₁(v,−w), 4v+w², 1−4vw); 3 (the "hard" classes 97/77/79, order-4 irreducible) are ε-forms only in a two-variable Källén chart v = ±xy, w = (1−x)(1−y).

**Stage 2 design (built this week).** Per family:
1. *Assemb