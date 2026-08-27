# CF300 pair-chart V2 solve report — 2026-08-24

## Scope and status

This is an external, source-pinned proof-of-solution campaign for the immutable physical CF300 sector `12 -> 9` strip. It does not modify FeynFacet/Fable package source and it does not install a row gauge into a current family continuation state.

The pinned input is:

- `/home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_sector12_physical_rank3_xh/physical_sidecar_evidence_2026-08-23_xh_v3/CF300_12_9_input.wl`
- SHA-256 `274d5d0c4abf1c8ff7cafdf09367e4716b42b6721dc4ae294179d21a84d25af6`

The dependency-closed active-root census of this strip is exactly `{2,3}`:

\[
A=1-2x+x^2+2y+2xy+y^2=(1-x+y)^2+4xy,
\qquad B=1-4xy.
\]

The family has three roots, but this physical strip uses only this rationalizable two-root subcover.

Durable copies of the key chart, preparation, reconstructed solution, independent-oracle summaries, and source/transformation certificates are stored in this campaign's `artifacts/` directory. Their names preserve the version labels below and their SHA-256 hashes match the scratch artifacts exactly.

## Low-degree pair chart V2

Let

\[
k=p(1-p),\qquad d=q^2+4k,\qquad a=\frac{4k-2q}{d}.
\]

The forward chart is

\[
x=ap,\qquad y=-(1-a)(1-p),\qquad
\sqrt A=a-p,\qquad \sqrt B=1+qa.
\]

On the displayed generic sign sheet, the inverse is

\[
a=\frac{1+x+y+\sqrt A}{2},\qquad
p=\frac{1+x+y-\sqrt A}{2},\qquad
q=\frac{\sqrt B-1}{a}.
\]

Independent Singular identities and `TransportChartVerify` proved both radicand identities exactly. A fresh external probe also proved a nonzero exact Jacobian, exact inverse round trip, exact root classification `{2,3}`, no unrecognized radicals, and exact coordinate-map composition.

Chart artifact:

- `/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/probe_v4/chart_strip.wxf`
- SHA-256 `044a9b780cbd3f9e8f8d0e11d3fda744b07c9776a796df4ec4754a9f02ff7f2f`
- pullback wall `15.442773 s`
- source leaf count `76,840`; chart leaf count `392,857`
- maximum numerator degrees `(p,q,eps) = (40,30,7)`
- maximum denominator degrees `(p,q,eps) = (39,31,8)`

Generic exceptional loci include the forward denominator `d=0`, the inverse denominator `a=0`, the branch divisors `A=0` and `B=0`, and the usual original strip/gauge denominators. Modular point generation must reject them. Different source-root sign choices map to different chart coordinates; the chart does not collapse the four generic sheets.

An independent standard-library Python oracle evaluated six generic exact-rational chart points on all four source-root sign sheets. All `24/24` inverse/forward branch round trips passed. A deliberately wrong inverse formula `q=(sqrt(B)+1)/a` was rejected in all `24/24` cases. The oracle is `test_cf300_v2_all_branches_2026-08-24.py` in this campaign directory.

An independent Wolfram oracle then rebuilt the complete pulled strip using ordinary `D` and the one-form formula

\[
A_p=x_pA_x+y_pA_y,\qquad A_q=x_qA_x+y_qA_y,
\]

without calling the package pullback helper. It reduced every general half-integer root power, matched the persisted chart strip exactly in `13.144905 s`, and rejected a wrong-Jacobian-orientation mutant in `11.460085 s`. Status: `CF300PairChartDirectPullbackPassedV2`; driver SHA-256 `148703cdd007ca12558ce68c17eebc1ac0005d63da60afa9afdb17280cd63a16`.

The first version of this adversarial oracle replaced only literal square roots and therefore intentionally failed on negative half-powers. That was a test-harness defect, not a package defect; V2 is the corrected result.

## Natural support and the decisive finite-field screen

Fresh preparation in chart variables took `5.425 s` and found:

- rational alphabet length `14`, maximum letter degrees `(3,2)`;
- gauge denominator bidegrees `(21,17)`;
- `56` free residue coefficients;
- forcing infinity degree `0`;
- denominator total degree `25`;
- certified gauge-numerator total-degree bound `26`;
- every tested finite/projective logarithmic-pole condition passed.

At prime `1,000,003` and `eps=1/21`:

| support | result | rank / augmented rank | matrix | gauge monomials |
|---|---:|---:|---:|---:|
| projective simplex, total degree `<=26` | consistent | `1564 / 1564`, nullity `4` | `1576 x 1568` | `378` |
| conventional rectangle `<= (21,17)` | inconsistent | `1636 / 1637`, nullity `4` | `1648 x 1640` | `396` |

This is the concrete failure mode of the earlier rational/multiquadratic rectangle ansätze: the true gauge needs projective-support monomials outside the denominator bidegree rectangle, not more square-free denominator factors.

A common-row adversarial rerun closed the only causal ambiguity in the separate screens. With `PointCount=206` and the same random seed, both supports used the identical accepted point set (SHA-256 `32ac1b93aedd017fa52c88675d0299d4f4ece2b3606fd97163dd94e1b958d847`) and therefore the same `1,648` equation rows:

- simplex: matrix `1648 x 1568`, rank/augmented rank `1564/1564`, nullity `4`, consistent;
- rectangle: matrix `1648 x 1640`, rank/augmented rank `1636/1637`, nullity `4`, inconsistent;
- support intersection `318`, simplex-only `60`, rectangle-only `78`.

Status `CF300PairChartCommonRowsPassedV1`; wall `20.6 s`; package dependencies unchanged. This directly certifies that the rectangle's extra high-total-degree corners do not replace the omitted projective-edge directions.

## Full finite-field reconstruction

Mission `fresh_cf300_pair_chart_solve_v4` completed successfully in `315.014359 s`.

The solver independently rederived the simplex, learned `263` of its `378` monomials, fixed four normalization freedoms, and used the flat KernelPool broker. It validated three construction primes and obtained an identically zero residual at the unseen prime `2147483399`.

Exact result:

- status `CF300PairChartRationalSolvePassedV1`;
- method `SimultaneousFiniteFieldAffinePDE`;
- certificate `ExactDLog`;
- `ExactDLog -> True`;
- `ExactPfaffianResidualsZero -> True`;
- gauge dimensions `2 x 2`, leaf count `59,611`;
- gauge numerator and denominator bidegrees `(21,17)`;
- alphabet/residue matrices `14 / 14`;
- construction primes `{1000003, 2147483423, 2147483477}`;
- package dependency hashes unchanged during the solve.

Solution artifact:

- `/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/solve_v4/solution.wxf`
- SHA-256 `15d8f53074826efd387b992eb76ddb7fa47e25ce8b82108bc68aaaff49539b7e`
- size `484,222` bytes

## Remaining third root after V2

For CF300/CF303 the root not used by this strip is

\[
C=(1+x-y)^2+4xy.
\]

Under V2,

\[
C=\frac{F(p,q)}{d^2},\qquad R=d\sqrt C,\quad R^2=F(p,q)
\]

with

\[
\begin{aligned}
F={}&16p^6-8p^4q^2+p^2q^4+16p^3q^2-4pq^4-32p^4+48p^3q\\
&-24p^2q^2-12pq^3+4q^4-64p^2q+16pq^2+8q^3\\
&+16p^2+16pq+4q^2.
\end{aligned}
\]

Independent Singular factorization finds `F` irreducible over `Q[p,q]`, `gcd(F,d)=1`, bidegree `(6,4)`, and total degree `6`. Therefore the complete three-root field is a single quadratic extension `Q(p,q)(sqrt(F))`, not an eight-grade extension over the chart base. Later CF300/CF303 strips should be attacked first with a rank-one/two-grade solver in this presentation.

The derivation script is `derive_cf300_v2_residual_root_2026-08-24.sing` in this campaign directory.

## Independent source-frame certificates

`fresh_cf300_pair_chart_birational_source_proof_v1` completed successfully in `0.235262 s`. It reloaded the pinned source strip, chart, reconstructed solution, independent ordinary-`D` pullback oracle, and common-row support oracle; checked all provenance hashes; and independently reverified the exact chart identities, nonzero Jacobian, and inverse/forward composition. Every logical condition passed:

- exact root identities and inverse composition;
- independent exact ordinary-`D` pullback and rejection of the wrong-Jacobian mutant;
- exact chart Pfaffian residual and exact dlog form;
- the common-row simplex-consistent / rectangle-inconsistent support certificate;
- unchanged package dependency hashes.

Because the chart has an exact rational inverse on a nonempty generic open set, pullback is an injective homomorphism of function fields. The independent identity `pullback(source strip) = chart strip` and the exact zero chart residual therefore imply an exact zero residual in the original algebraic source field. The chart dlog letters likewise pull back through the inverse to algebraic source-field dlogs. This is a non-materialized exact source proof, not a numerical inference.

Artifacts:

- summary `/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/birational_source_v1/summary.wl`, SHA-256 `c173663bd2312407c85405f145d4b449dcf827f07d0ca0eb853381776d9389eb`;
- certificate `/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/birational_source_v1/certificate.wxf`, SHA-256 `9f7b62b236b87f9dc871583a4ce1027f5523d9ae3abc33bcb2dfc1598a9a5117`;
- driver SHA-256 `a26c2b5c2e27ef35025742ea5c6a3fc9cc3f7f815f20b402892bd0b853c79f10`.

The follow-up transformation manifest closes the remaining invertibility/orientation bookkeeping. The reconstructed `2 x 2` object `G` is the off-diagonal row block, not the complete change-of-basis matrix. In the package convention,

\[
U=\begin{pmatrix}I_{\rm lower}&0\\G&I_{\rm upper}\end{pmatrix},\qquad
S_{\rm new}=S_{\rm old}U,\qquad
U^{-1}=\begin{pmatrix}I_{\rm lower}&0\\-G&I_{\rm upper}\end{pmatrix},
\]

and

\[
\bar B_{\rm new}=\bar B+\epsilon(EG-GC)-dG
=\epsilon\sum_a R_a\,d\log L_a.
\]

`fresh_cf300_pair_chart_transformation_manifest_v1` verified both inverse products exactly, `(U-I)^2=0`, and `det U=1`; `G` itself need not be invertible. It also persisted the exact orientation, source/chart/solution/birational-proof hashes, and the declared chart, inverse-patch, branch, gauge, dlog-letter, and strip-denominator exclusions. Status `CF300PairChartTransformationManifestV1`; summary SHA-256 `7d9bf91492e6982869dfa9a5df5192376517110326461410506d942ae880e2dd`; certificate SHA-256 `e5a5c5ae26461a58f28a1185cbe6677785b9f39c819bb040d1e7e84d412af134`; driver SHA-256 `4b2330d71276c19359db40c882e776b2cc88c1a6700eae52b215d65d12d05bbd`.

`fresh_cf300_pair_chart_source_cert_v1` is separately composing the reconstructed 2-by-2 chart gauge with the exact inverse map and will then run `VerifyEpsFormStrip` directly on the original algebraic `x,y` strip. Its intended acceptance conditions are:

- exact chart reverification and inverse composition;
- exact gauge round trip on a declared source-root sign sheet;
- exact original-source Pfaffian residuals;
- exact source dlog/canonical-epsilon certification;
- unchanged package dependency hashes.

This materialized source-frame check is deliberately stronger as an implementation oracle, but it is not required for the function-field existence proof and is not on the reconstruction critical path.

## Pro consultation

All Pro consultation is pinned to the pre-existing ChatGPT Classic conversation **“Assess Multiquadratic Pipeline”**, conversation ID `6a8a4f28-4504-83e8-b794-f156372e1c85`, model `gpt-5-6-pro`. No new Pro conversation is to be created.

The old-context assessment validated chart-first solving, emphasized projective/infinity support and exact source back-certification, and agreed that rationalizing two roots reduces the full CF300/CF303 field to one residual quadratic extension.

The corrected V2-specific response also independently derived the same reduced `F`, accepted V2 as generically birational, identified the four chart base points `(0,0)`, `(1,0)`, and `((1 +/- sqrt(5))/2,-2)`, and recommended the same rank-one route. Its warning that the modular screen was then only one image was written before the completed reconstruction reported above; the completed solve subsequently supplied three construction primes, held-out regulator validation, an unseen-prime zero residual, and an exact characteristic-zero Pfaffian/dlog check.

Pro requested one additional causal certificate: assemble simplex and rectangle supports on the same accepted modular rows. The common-row result above subsequently passed and closes that caveat.

The final verdict and its transformation-manifest follow-up both completed in the same old conversation. Pro agreed that the function-field injectivity argument is already an exact source proof and that the materialized expansion is only a second implementation oracle. After the package convention was clarified, Pro confirmed that the unipotent certificate fully replaces the inapplicable `det G != 0` request: `G` may be rectangular, while the actual transformation `U` has exact determinant one. Pro's final conclusion was that no theorem-level gate remains for the immutable pinned strip, provided the claim remains distinct from later production installation and family propagation.

## What this proves and what remains

This campaign now proves that the immutable pinned physical CF300 `12 -> 9` algebraic strip is solved exactly by the certified unipotent off-diagonal transformation on the declared generic open set. The proof consists of the exact finite-field reconstruction, exact characteristic-zero chart residual/dlog checks, an independent ordinary-`D` pullback identity, injectivity of the explicitly birational function-field map, and the exact unipotent transformation/orientation manifest. The still-running materialized source expansion is an additional implementation oracle, not a condition on that conclusion.

It does not yet prove that the gauge is installed in Fable's latest CF300 continuation state. If sector-11 was subsequently rescaled, the future strip must be recaptured from that state, compared exactly with this pinned input, and either the gauge transported through an exact equivalence or the fast chart solve replayed. It also does not certify the remaining CF300 sectors or the CF303/CF259 families.

Recommended continuation order:

1. allow the optional materialized source-frame implementation oracle to finish without duplicating or interrupting it;
2. recapture the current post-rescaling CF300 `12 -> 9` strip and test exact equivalence;
3. install/replay this gauge externally and recapture the next dependency-closed strip;
4. use the rational solver for rank zero and the residual `sqrt(F)` two-grade solver for rank one;
5. repeat the same pair-chart/rank-one strategy for CF303; retain the full eight-grade machinery only as an oracle/fallback;
6. treat CF259 with its Källén-pair chart plus one residual root.

## Runtime and preservation

- One Wolfram main with exactly eight pool subkernels was used.
- Sampling was flat-brokered; native backend threads were fixed to one.
- No Fable/package source file was modified by the chart probe, preparation, solve, or certificate driver.
- Existing unrelated programs and Fable jobs were not terminated.
