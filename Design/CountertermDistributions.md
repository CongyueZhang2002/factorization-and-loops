# Counterterm PDF and fragmentation operators

## Contribution cards and generated sources

Counterterms have the same contribution status as real and virtual terms.
Every concrete card declares a source order/channel, an output epsilon range,
and a list of operator products. The source is a physical channel in the common
root catalog, not a path to another calculation.

The public scalar operators are `PDFCountertermDistribution` and
`FFCountertermDistribution` in `Physics/Distributions.wl`. They return explicit
delta/plus/regular coefficients at a specified perturbative order, with their
physical species, spin, source scheme and normalization. They contain no
unevaluated integral or delayed numerical generator.

`CompileBareSourceCard` compiles the common root's `BareSourceContributions`
at the epsilon order derived by the consumer. `GenerateBornPartonicSources`
and `GenerateBarePartonicSourceCatalog` invoke the existing amplitude and
integration methods. Sources are written under

```text
Projects/PROJECT/ORDER/CHANNEL/Results/Counterterm/Sources/
  LO/SOURCECHANNEL/Born/Result.wl
  NLO/SOURCECHANNEL/{Real,Virtual}/Result.wl
```

Standalone LO cards request `{0,0}` by default. Their files and output ranges
are never read when generating a counterterm. The common physical result
format is unchanged. No fitted hard coefficient enters this calculation.

Generate the standard concrete card list, then run the contributions:

```sh
wolframscript -file Scripts/prepare_counterterm_cards.wls PROJECT NLO CHANNEL
wolframscript -file Scripts/run_nlo_hard_function.wls PROJECT CHANNEL all
```

The preparation command writes the standard list implied by the common
physics and schemes; it replaces the counterterm card list. To preserve
intentional custom cards, execute them directly instead of regenerating that
list. A complete run checks that the concrete cards partition the full operator
sum implied by the common project schemes; missing or duplicate terms fail.
For a different complete finite-subtraction prescription, declare it in the
common card and regenerate its contribution list. A selected individual card
can also be evaluated as an explicitly partial contribution. `ReadCountertermCards` discovers contributions from their declaration,
not from a fixed filename.

## Physical index direction

All kernel arguments use physical daughter ← parent labels. In the PDF case,

\[
 \delta f_i=\sum_j K^{\rm PDF}_{i\leftarrow j}\otimes f_j.
\]

For fragmentation the density-action matrix has the parent first:

\[
 \delta D_j=\sum_i K^{\rm FF}_{i\leftarrow j}\otimes D_i.
\]

Consequently a hard-coefficient source species `src` and target `dst` select
`K(src,dst)` for a PDF and `K(dst,src)` for an FF. The public FF constructor
does not transpose again. Correlated flavor sums include each individual
quark, antiquark and gluon; a summed channel is not assigned to an individual
observed flavor by assumption.

At NNLO, products on different legs occur once. Two order-one insertions on
the same leg must not be added on top of the full order-two kernel. The UV
factor multiplying a relative-order-r source is \(Z_\alpha^{p+r}\), where p is
the Born coupling power. The generic perturbative planner supplies these
combinatorics.

## Normalization

Use \(D=4-2\epsilon\), \(a=\alpha_s(\mu_R)/(2\pi)\),
\(L=\log(\mu_F^2/\mu_R^2)\), and \(\eta=e^{-\epsilon L}\). Define

\[
 S_\epsilon=e^{\epsilon(\log4\pi-\gamma_E)},\qquad
 b_0=(11C_A-4T_Rn_f)/6.
\]

The generated current sources explicitly substitute
\(g_{s,B}^2=4\pi\alpha_s\mu_R^{2\epsilon}S_\epsilon^{-1}\)
before UV subtraction. Real phase space and virtual loops retain their
generated \(d^D\ell/(2\pi)^D\) normalization. The scattering sources instead
substitute \(g_s^2=4\pi\alpha_s\), retain one extra \(\mu_R^{2\epsilon}\) per
radiative order, and leave the common Born factor
\(\mu_R^{2p\epsilon}\) outside the coefficient record. This explains the
different exact pole factors in the stored conventions:

| Stored source convention | `Counterterms["PoleNormalization"]` |
|---|---|
| Current sources with \(S_\epsilon^{-1}\) in the bare coupling | 1 |
| Existing invariant scattering sources without that factor | \(S_\epsilon\) |

The primitive project declaration is `Counterterms["BareCouplingFactor"]`,
not an independently chosen pole factor. `MSbarCouplingNormalization[epsilon,Cepsilon]`
derives \(N_\epsilon=S_\epsilon C_\epsilon\). The project reader checks the
current's declared bare-coupling substitution against \(C_\epsilon\). The shared
scalar-scattering executor inserts the exact \(C_\epsilon^{p+r}\) for a source
of relative order \(r\), after its standard coupling normalization. Both routes
retain the same derived convention. Fresh Born and virtual-source covariance
tests establish the powers \(C_\epsilon^2\) and \(C_\epsilon^3\) coefficientwise.
`MSbarCouplingRenormalization` supplies the shared UV coefficients to both
first-order cards and the general perturbative planner.

To derive the relation, define the reference MS-bar coupling \(\bar a\) by
\(a_B=\mu_R^{2\epsilon}S_\epsilon^{-1}\bar a Z_{\rm MS}(\bar a)\), and let
\(\bar a=N_\epsilon a\). Then
\(a_B=\mu_R^{2\epsilon}C_\epsilon a Z_{\rm MS}(N_\epsilon a)\). Hence

\[
 z_{\alpha,1}=-b_0N_\epsilon/\epsilon,\qquad
 z_{\alpha,2}=N_\epsilon^2
   \left(b_0^2/\epsilon^2-b_1/(2\epsilon)\right).
\]

The dimensional beta function in the generated coupling convention is
\(-\epsilon a-b_0N_\epsilon a^2-b_1N_\epsilon^2a^3+\cdots\);
its four-dimensional limit is unchanged. Raw leg kernels of order n are
likewise multiplied by \(N_\epsilon^n\). The formal perturbative parameter
remains regulator independent in the planner.

At NLO,

\[
 K^{(1)}=N_\epsilon\,\frac{\eta}{\epsilon}P^{(0)}-F^{(1)},
 \qquad
 \delta H_{\rm UV}^{(1)}
 =-p\,b_0\,a\,\frac{N_\epsilon}{\epsilon}H^{(0)}.
\]

The finite inverse kernel is **not** multiplied by \(N_\epsilon\eta\).
The common Born dimensional prefactor is also not inserted again for each
leg. Exact factors are retained until the Laurent product is expanded.
This record concerns the bare coupling; master-integral measures and their
conversion to the physical phase-space/loop measure remain separately defined.

For the reference NNLO convention \(N_\epsilon=1\),

\[
 Z^{(1)}=\frac{\eta}{\epsilon}P^{(0)},\qquad
 Z^{(2)}=
 \frac{\eta^2}{2\epsilon^2}P^{(0)}\otimes P^{(0)}
 +\frac{b_0(\eta^2-2\eta)}{2\epsilon^2}P^{(0)}
 +\frac{\eta^2}{2\epsilon}P^{(1)}.
\]

This follows by differentiating \(f_B=Z\otimes f\), with
\(\beta_D(a)=-\epsilon a-b_0a^2+\cdots\), and converting the coupling at the
factorization scale to that at the renormalization scale:
\(a_F=\eta a_R+b_0(\eta^2-\eta)a_R^2/\epsilon+\cdots\).
Thus the second term cannot be replaced by a uniform equal-scale expression
times \(\eta^2\).

For general declared \(C_\epsilon\), multiply the displayed \(Z^{(2)}\)
by \(N_\epsilon^2\) and use the matching UV coefficients above. The shared
normalization record prevents inconsistent independent leg and coupling
normalizations. It requires an analytic, invertible normalization with
\(C_0=1\), independent of scales, coupling and kinematics.

As a normalization check, a complete bare source of relative order r transforms
by \(N_\epsilon^{p+r}\), including any common dimensional prefactor. Its
insertions at target order n supply \(N_\epsilon^{n-r}\), so every raw assembly
term has the same \(N_\epsilon^{p+n}\). After complete pole cancellation the
finite result is unchanged. This also detects errors at order \(\epsilon^2\)
that an NLO pole comparison alone would miss.

## Raw subtraction and finite scheme conversion

For a finite operator redefinition
\(f_{\rm new}=(1+a_F F^{(1)}+a_F^2 F^{(2)})\otimes f_{\rm raw}\),
the inverse acting on the hard coefficient is

\[
 F^{-1}=1-a_R F^{(1)}
 +a_R^2\left(F^{(1)}\otimes F^{(1)}-F^{(2)}+b_0 L F^{(1)}\right).
\]

In particular the helicity provider's
\(F^{(1)}=-4C_F(1-x)\) enters the hard coefficient with the opposite sign.
The flavor-resolved finite transformation is documented in
[Bonino et al., Appendix A](https://arxiv.org/html/2510.00100v1#A1).
See also [Moch, Vermaseren and Vogt](https://arxiv.org/abs/1409.5131).

Execution keeps two mathematical stages:

1. Raw subtraction uses bare LO/NLO sources, retaining all required poles and
   positive epsilon coefficients.
2. Finite conversion uses the coefficient at epsilon zero after exact
   raw-scheme pole cancellation. Already converted sources are rejected using
   `FiniteSchemeConversionApplied` and the declared operator schemes.

The contribution runner generates the required raw-subtracted source itself.
No manual lower-order matching or extra finite-conversion run is required.
A combined `Factorization` operator is provided for an order-one insertion on
a regular Born source. Its positive-epsilon coefficients are not a definition
of a scheme-converted NLO source for NNLO.

Matrix order matters: in physical indices the mixed raw/finite PDF term is
\(-Z^{(1)}\otimes F^{(1)}\), while for an FF it is
\(-F^{(1)}\otimes Z^{(1)}\). Explicit stages preserve this without introducing
another combined NNLO operator.

## Epsilon demand and distributional action

An insertion with Laurent lower bound \(\nu_T\) and output through
\(\epsilon^m\) requires its source through \(\epsilon^{m-\nu_T}\).
Conversely a source beginning at \(\epsilon^{\nu_B}\) requires the insertion
through \(\epsilon^{m-\nu_B}\). Bounds of simultaneous insertions and UV
factors add. Exactly zero kernels do not create an artificial pole demand.
Existing omitted-tail checks remain active.

`ApplyCountertermDistribution` is the common coefficient-level action.
Mellin convolution uses tensor distribution algebra for any number of declared
axes. `ConvolvePartonicInvariantKernel` acts on an arbitrary single-inclusive
delta/plus/regular Laurent source. Rational charts rescale all source invariants,
retain the dimensional fragmentation weight \(\xi^{-2+2\epsilon}\), and produce
the complete endpoint terms. Its explicit GPL backend is shared across legs,
orders and channels; [the derivation](InvariantCollinearConvolutions.md) gives
the maps, subtractions and validation.

`EvaluateBareContribution` is the shared compiled-card executor for ordinary
and generated Born/real/virtual contributions. The root's integration method
declares its mathematical input contract; the convolution geometry is declared
separately. Scattering NLO sources are evaluated to the requested epsilon order,
including epsilon^1 for finite NNLO subtraction. Real endpoint expansion and
virtual-master evaluation derive their own additional epsilon demand.
Source-only QCD channels and their minimum orders are derived from allowed
recoil states. Explicit source-channel identity retains the recoil when
different channels have the same factorized external species.

Complete custom finite
schemes are supported for an explicit flavor catalog. Automatic massless-flavor
summation in the existing ppHX planner supports its built-in MSbar and
HelicityMSbar schemes. Arbitrary named-flavor matrices are rejected there;
their flavor covariance must be implemented before that summation is valid.

## Review and validation

The architecture and exact signs were reviewed by verified GPT-6 Pro in
[review 04](../External/ChatGPT/Records/2026-09-11/04_counterterm_distributions.md)
[normalization/card review 05](../External/ChatGPT/Records/2026-09-11/05_counterterm_cards_and_normalization.md),
and the [general invariant-convolution review](../External/ChatGPT/Records/2026-09-12/01_invariant_counterterm_unification.md).
These reviews were mathematical/static; the retained project reports separately
record executed unit tests and fresh-source coefficient comparisons.
The duplicate NLO collinear assemblers, Born-only Mellin special case,
lower-order result-path loader and separate manual finite-conversion drivers
have been removed from the active production path.
