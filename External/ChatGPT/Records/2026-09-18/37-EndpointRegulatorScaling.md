# Pro review 37: physical endpoint scaling

Actual ChatGPT 6 Pro, existing EEC conversation:
https://chatgpt.com/c/6aace49d-0888-83e8-a5f1-a9277443ef84

Prompt supplied pushed revision b969001c42f170c6375c1fd72803a9084c88f9d9,
the exact reported endpoint spectra and the complete original Gram-majorant
derivation. Pro worked for 5m21s. This was a mathematical review; Pro explicitly
did **not** inspect that revision, execute calculations or verify the residues.
No measured NLO EEC literature coefficient was supplied or consulted.

For the canonical pair chart, P=C r(1-r)W/(1-rx)^2, where
W=x^2(1-x)^3 y^2(1-y)a(1-a)b(1-b). The inherited bound includes the
complete original ordinary product and 1/|F| with a finite regulator-independent
loss M. Put kappa=Re(epsilon)+M. Pro accepted the density exponents and improved
the two-endpoint argument to the global inequality 1-rx>=1-x. For kappa<1/2,
the four-variable integral is bounded by

    [r(1-r)]^(-kappa)
    Beta[2-2 kappa,1-kappa]^2 Beta[1-kappa,1-kappa]
    Beta[1/2-kappa,1/2-kappa],

times a finite epsilon-dependent constant. The original angular normalization
stays at epsilon, not kappa. Every beta argument is positive. M is fixed by
integer propagator powers and the semialgebraic domination problem; polynomial
epsilon coefficients affect the prefactor, not M. For a finite master vector
take the maximum loss. No bound uniform in epsilon as epsilon tends to minus
infinity is needed: fix a generic negative epsilon, then take the endpoint.

For z=(1-u^2)^2/(1+u^2)^2, both inward endpoint coordinates have ramification
two. The scalar bound is O(rho^(-2 epsilon-2M)), without a dz/du density
Jacobian. At u=1 the local DE must use -A(1-rho); our normalization does.
An exact rational gauge changes the integer power only. In an exact generic
Fuchsian system, a nonzero mode rho^(beta epsilon) times a nonzero logarithmic
polynomial contradicts the bound for sufficiently negative epsilon if beta>-2.
Spectral projectors isolate generic sectors; the complete Jordan chain must
be retained. Vanishing on an open generic regulator interval gives identical
vanishing by the original meromorphic continuation. Discrete resonances and
gauge/normalization poles are excluded while proving that identity.

Accepted retained dimensions from the reported spectra: 32 at u=0
(slopes -2,-4,-8), 20 at u=1 (slopes -2,-4). Their common-point intersection
has dimension between 10 and20, before known physical values and moments.
The local restrictions cannot simply be added as independent equations.

Crucial qualification: delete forbidden columns of a **local fundamental
solution**, not finite-point residue-coordinate components. The example
J1'=-2 epsilon J1/rho, J2'=J1 has J2=d+c rho^(1-2 epsilon)/(1-2 epsilon).
The forbidden slope-zero amplitude is d=0; J2 itself need not vanish.

Recommended next step: construct the u=1 admissible local connection, combine
the other endpoint and available physical Laurent coefficients, then evaluate
the 43 global moment responses only on the remaining directions. The bound
does not determine retained amplitudes, epsilon-zero weighted L1 behavior,
endpoint contacts or the full EEC distribution.
