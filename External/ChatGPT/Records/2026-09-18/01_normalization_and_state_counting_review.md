# GPT-6 Pro review: normalization and external-state counting

Conversation: https://chatgpt.com/c/6aac97de-ae14-83e8-b452-b6ebcfecd366

The signed-in browser selector was verified as **6 Pro**. Two completed answers
were read: the design review (displayed reasoning time 10m40s) and the focused
operator/measurement follow-up (9m30s). This file is an agent-written record of
the questions, conclusions and implementation decisions, not a verbatim transcript.

## Questions supplied

The first request covered replacing handwritten card factors with a shared
normalization layer: identical final states, inclusive tags versus explicit EEC
tuples, dummy flavor sums and their automorphisms, current tensor conventions,
bare coupling normalization, momentum-rescaling adjoints, projection closure
and endpoint regularity. It asked for counterexamples, inexpensive independent
tests and failure conditions rather than agreement with existing answers.

The follow-up supplied the precise dimensionally integrated tagged-current
definition, the proposed Mellin pushforward, existing hard-side gluon tensor
`-gT/(D-2)` and incoming color average. It requested the incoming bare gluon
extraction/reconstruction including both field-strength momentum factors, and
asked which measurement and polarization changes invalidate Mellin closure.

## Review conclusions adopted

1. Start from `1/product(N_species!)` and the complete measurement. Replacing an
   inclusive tag sum by a representative uses an orbit/stabilizer factor.
   EEC's full ordered pair sum keeps the full state factorial. Self pairs,
   ordered distinct pairs and unordered pairs have different orbit sizes.
   Incoming beams and Hermitian interference factors are separate.
2. Flavor falling factorials count labeled new flavor blocks. Divide by
   dummy-flavor automorphisms of the complete unobserved state only where the
   amplitude, measurement and domain respect that equivalence. Two indistinguishable
   new flavor pairs give a binomial coefficient. Do not sum independent PDFs/FFs
   or coherent internal-loop amplitudes by this external-state rule.
3. `W = cut sum/(4 pi)` is an observable convention, not a universal number
   deduced without choosing a tensor definition. Distinguish the cut sum from
   an imaginary part or discontinuity. A generated Born denominator needs a
   separate absolute-normalization anchor; our free-current Wick trace and
   canonical recoil delta supply that anchor.
4. For a stored density `h=N H`, the scalar operator adjoint has weight
   `W_source(xi y)/W_target(y) * N_target/N_source(mapped momenta)`.
   Derive coordinate maps and endpoint Jacobians, including support, rather
   than validating two independently supplied weights against each other.
5. For a full-dimensional tagged integral, FF sewing contributes `xi^(-(D-2))`,
   the tagged on-shell measure contributes `xi^(D-2)`, and the measurement delta
   contributes `1/xi`. This yields ordinary Mellin convolution only when the
   complete projector/measurement kernel obeys the rescaling identity.
   A physical-only tagged measure instead leaves `xi^(-1+2 epsilon)`.
   A hard tensor known only at `k_hat=0` cannot be dimensionally integrated by
   changing its measure: evanescent components must be calculated too.
6. Test projection covariance before reducing tensor information. An energy
   weight or a fixed transverse-momentum acceptance cut can invalidate closure.
   A larger tensor/observable basis can be needed; failure is preferable to
   silently treating the result as a scalar Mellin coefficient.
7. Incoming gluon normalization is color summed at the operator and color
   averaged once at the hard tensor. In dimensionful light-ray coordinates,
   with `m=D-2` and `Qg=-gT/m`, Pro obtained:
   `f_g = -gT.G_nn/(x Pplus)`, `G_nn = x Pplus Qg f_g`,
   `G_nn=(x Pplus)^2 C_A`, hence `C_A=Qg f_g/(x Pplus)`.
   Sewing `dpplus=Pplus dx` gives `dx/x`, without another spin/color divisor.
   Both a unit-delta external-state test and a nontrivial fraction moment are
   necessary; the delta alone cannot distinguish extra powers of x.
8. Keep exact epsilon-dependent coupling factors. Check endpoint faces jointly
   and include regulator-dependent denominators: `1/(r+t)` and `1/(r+epsilon)`
   cannot receive a smoothness certificate from separate finite interior samples.

The gluon operator and the field-strength derivative relation were checked
against [Altinoluk, Beuf and Jalilian-Marian, Eqs. (6)–(10)](https://arxiv.org/html/2305.11079v2#S2.SS2).
Pro also cited [Rein et al., Appendix A](https://arxiv.org/abs/2503.16119)
for the dimensional outgoing gluon convention and an Abelian incoming check.

## Implementation and evidence

See [Normalization/README.md](../../../../FeynFacet/Normalization/README.md)
and [the completed campaign report](../../../../Reports/2026-09-18/DerivedNormalizations.md).
Pro reviewed the mathematics and design; the local executable regressions,
not Pro's answer alone, establish the recorded implementation behavior.
