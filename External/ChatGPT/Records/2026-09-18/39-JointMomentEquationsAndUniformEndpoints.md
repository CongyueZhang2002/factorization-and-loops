# Pro review 39: joint moment equations and uniform endpoints

Actual ChatGPT 6 Pro, retained EEC conversation,8m32s. Inspected exact revision
1f6b21e2dcba4664175c39894e915d23357f921e: ClosedSubsystems.wl,
PrimaryExpansion.wl, Preparation.wl, the four closed-subsystem tests and the
report. Static inspection; no execution, saved rank-artifact inspection,
recomputation of the64/27 minor or production-connection verification.

Accepted the closed-subsystem construction: the rational middle-gauge pole
order sets sufficient normal depth; after all negative normal powers vanish,
H_K inverse=I+O(rho) does not change the constant coefficient. Exact generic
nonresonance and residue intertwining justify the map, including complete
Jordan chains and the meromorphic amplitude change.

Accepted the reported rank argument conditional on its exact data: the
opposite known-output restriction has rank2 on10 forbidden slope-zero
amplitudes. Distinct regulator slopes cannot cancel under its intertwiner,
so at most8 constraints act on the10 invisible directions. A minor with
leading64/27 epsilon proves rank8 and leaves2 series. In regular saturated
coordinates the nonzero invariant-factor valuations are seven zeros and one
one. Missing donor tails remain separate unknown coefficients.

Accepted dimensional moment formula in fixed inward endpoint coordinates:

    [epsilon^k] MC integral(f) = FP integral(f_k)
      + [epsilon^k] sum_endpoints,beta!=0,p
          (-1)^p p! h_{-1,beta,p}(epsilon)/(beta epsilon)^(p+1).

For integer powers other than-1 the coefficientwise Hadamard finite part
already equals dimensional continuation. Only resonant t^-1 terms supply
the correction. Both endpoints add after the correct inward-coordinate
Jacobian. The h coefficient includes the moment weight and full density.
Higher rational poles increase the required normal jet; a log degree p
requires h through k+p+1. If h=H c with c starting at b, H can be needed
through k+p+1-b.

Essential qualification: the endpoint expansion must be regulator-uniform
after fixed finite powers are extracted. The counterexample
epsilon/(t+epsilon)^2 integrates to1/(1+epsilon), although its fixed-t finite
coefficient and generic-epsilon resonant coefficient vanish. An unresolved
moving endpoint divisor invalidates the formula. Check the complete rational
moment rows, gauges and connection, not the residue alone. An epsilon-uniform
Fuchsian remainder and equally uniform rational multipliers suffice. Ordinary
interior singularities need their own existing path checks.

An all-orders projected fundamental matrix is unnecessary. Keep20 columns,
form the finite-part plus nonzero-slope corrections, and jointly impose the
full forbidden-amplitude equations B c=0 and moment equations M c=U.
Off-constraint moment values are auxiliary; on ker(B) the entire forbidden
modes and their descendants vanish. Moment rows are defined modulo L B.
Do not impose only the orders that established rank: if val(L)=nu, output
through k needs B c=O(epsilon^(k-nu+1)), hence potentially B through k-nu-b.
Extend demanded rows and coefficients; keep missing donor tails explicit.
