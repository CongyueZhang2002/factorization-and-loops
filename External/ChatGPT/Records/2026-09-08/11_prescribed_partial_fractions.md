# Prescribed partial fractions review

Verified outgoing gpt-6-pro, HTTP 200.

## Question

Implemented your corrections. Direct amplitudes and reverse seed now explicitly flip SFAD eta exactly once (ComplexConjugate scalar option Conjugate; masks denominators; reverses integer eta and conjugates mass/eikonal fields). This exposed an old two-body evaluator bug: it inferred angular scale from momentum without checking actual inverse core; negative-polynomial sign was lost. Fixed coreScale = Qactual/(q^2), included in angular scale. Full regenerated UU NLO again cancels all poles exactly and matches saved file.
To avoid duplicate signed families, before real-radiation partial fractions I now certify the complete original *undotted* physical term using the Gram theorem, then replace ordinary eta metadata with the common placeholder required by FeynCalc while leaving inverse polynomials unchanged. Raw amplitude numerators are required polynomial in loop scalar products (adding explicit check), all active ordinary factors included, and all cuts verified unit. Original prescribed product and whole-term certificate persist in every resulting topology record. Partial fraction / Kira operations are then algebraic on this generic meromorphic identity, not an assertion of prescription-independent dotted masters. Dotted master definitions themselves remain uncertified and retain their chosen-family prescriptions. Partial-fraction terms with bad signs are already rejected. Unknown/virtual cases retain prescriptions, using FCLoopSwitchEtaSign (which flips core plus prefactor exactly) only where an algebra routine needs common eta signs.
Master definitions also attempt independent generic undotted certificates. Unsupported Baikov integrands retain explicit (z+i sigma eta)^-nu, positive-eta-limit metadata, original signs and cut delta derivatives. Explicit requests for PrescriptionScope=EndpointDistributions fail if all we have is generic certification. A public RequireOrdinaryPrescriptionCertificate enforces that distinction on stored records. Existing stage4 endpoint analyses do not thereby acquire a new causal endpoint proof; documents and final report explicitly retain that limitation. No dotted-cut or smeared-endpoint theorem claimed.
Physical guards: exact sum oriented cuts=beams-fixed finals; all fixed beam-final and final-final products >0; massless cuts; future timelike recoil; independent Lorentzian external frame; real affine full rank cut routing; constant nonsingular Jacobian of linear mass-shell constraints in scalar products; all principal minors PSD and nonnegative energies in closed domain. Full actual transverse Gram construction retains formal D-dimensional loops.
Any unsound step in the generic preIBP use (apart from the deliberately unresolved endpoint/dotted physical extension)? Please specifically distinguish generic algebraic reduction validity from prescription-independent masters; concise review desired. Current validation has exact UU/LL/TT reverse pair tests, complex coupling/two eta signs and loop-swap fixtures, and positive/negative certificate cases. No timing claims beyond n(n+1)/2 direct amplitude contractions.

## Pro response

The certified undotted normalization is sound, and it does not require prescription-independent dotted masters. I see one remaining potential causal error in the uncertified fallback: equalizing eta signs by an exact core-sign transformation does not make subsequent prescription-blind rational algebra valid.

1. Original-term equality and master definitions are different claims

Your intended chain is

I
original
σ
	​

(D,X)=I
original
τ
	​

(D,X)⟶
r
∑
	​

c
r
	​

(D,X)M
r
τ
	​

(D,X),

where τ denotes the chosen family prescriptions.

The first equality follows from the original undotted whole-term certificate. It does not require, or imply,

M
r
σ
	​

=M
r
τ
	​

.

Consequently, keeping dotted masters prescribed and uncertified is consistent. The source certificate retained in their topology records must remain a certificate about the source term, not become a property of every GLI in that topology.

The second step requires the usual fixed-prescription, oriented-cut partial-fraction/IBP identities. If your existing reverse-unitarity contract establishes those identities, this optimization introduces no new requirement to prove dotted-master prescription independence. If that fixed-cycle identity itself remains unestablished, the result is a formal reduction—not yet a certified physical integral identity, even at generic observed kinematics. The distinction matters because generalized contour cuts and positive-energy physical cuts are not automatically interchangeable. 
arXiv

For partial-fraction terms that remain undotted and satisfy the same geometry and sign hypotheses, the high-D theorem applies again. A finite collection has a common convergence half-plane, although its threshold can be higher than that of the original term.

2. Exact eta switching does not eliminate a pinch or contact term

FCLoopSwitchEtaSign does preserve the propagator by extracting the compensating minus sign. That operation is appropriate for your uncertified fallback. 
FeynCalc

But consider

x+iη
1
	​

−
x−iη
1
	​

=
x+iη
1
	​

+
−x+iη
1
	​

=−
x
2
+η
2
2iη
	​

.

Both denominators on the middle expression have the same eta metadata, yet

η↓0
lim
	​

(
x+iη
1
	​

+
−x+iη
1
	​

)=−2πiδ(x),

not zero. Cancelling the rational cores 1/x+1/(−x) would lose the contribution.

This becomes a bug only if a downstream routine forgets the signed-core/prescription pairing. Keeping explicit signs in the final Baikov representation cannot repair an earlier cancellation.

Therefore, outside the certified route, do not let common eta syntax authorize identification of opposite cores, denominator cancellations, or partial-fraction identities that ignore the regulator. Preserve the regulated identity, use an independently justified causal identity, or reject the operation. The displayed two-term expression is a decisive small regression fixture. Its zero surface can lie inside an integration domain, so this warning is not merely your deliberately excluded observed-endpoint issue.

3. One noncausal partial-fraction guard

If ApartFF still receives only the propagator product while the polynomial numerator is stored separately, require

Wolfram Language
FDS -> False, DropScaleless -> False

unless every resulting momentum transformation is also applied to the complete numerator, cuts, and measurement. ApartFF can perform momentum shifts and scaleless-integral removal; its documentation specifically advises disabling them when processing only part of an integrand. 
FeynCalc

For example, shifting only the denominators under ℓ↦ℓ+p while leaving a numerator ℓ⋅k unchanged loses the corresponding p⋅k term. Certifying the original numerator as polynomial does not prevent that error.

With these safeguards, I find no additional flaw in the generic undotted pre-IBP normalization you describe. The remaining distinction is exactly the intended one: a certified equality of source integrals, reduction into masters with fixed definitions, and no automatic promotion to prescription-independent dotted masters or endpoint distributions.