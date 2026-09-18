# GPT-6 Pro — physical moments and endpoint contact order

18 September 2026. Actual ChatGPT 6 Pro in
https://chatgpt.com/c/6aace49d-0888-83e8-a5f1-a9277443ef84,
completed after 10 min 8 s. This was a mathematical review, not a review of
unpublished implementation. No published EEC coefficient was requested or used.

## Question

Can the generated interior and independently integrated inclusive raw rate
determine both ordinary endpoint contacts, using the zeroth and first moments
of the complete ordered EEC? What proves that delta derivatives are absent,
including evanescent regulated terms? Can inclusive moments also determine
four-body measured-master boundary constants?

## Conclusions adopted

The eventwise identities sum(w_ij)=1 and sum(w_ij*z_ij)=1/2 give meromorphic
identities <S,1>=T and <S,z>=T/2 for each complete raw contribution. They do not
apply to individual tuples or arbitrary masters. T must come from the same
generated amplitude, state factors, measures and Hermitian completion.

If an independent proof restricts the missing contact space to delta_0 and
delta_1, a fixed reference extension K gives

    c1 = T/2 - <K,z>
    c0 = T/2 - <K,1> + <K,z>.

The reconstructed c0 already contains self pairs if K omits them. Adding a
separate self contact afterward would double count. These two moments cease
to be independent checks when they are used to construct the contacts.

The finite interior does not prove the contact-order bound. For example the
analytic continuation of epsilon*z^(-3+epsilon) has finite coefficient
delta_0''/2 although its finite interior vanishes. Subtracting suitable endpoint
atoms makes its zeroth and first moments identically zero without removing
that finite second derivative. No finite-interior-only check excludes this.

A sufficient proof is either a complete regulated endpoint-region expansion
with controlled remainder and no uncancelled powers stronger than
t^(-1+b*epsilon), or a meromorphic L1-valued representation of the *physical*
weighted pushforward z*(1-z)*S near epsilon=0 after removing a finite overall
regulator pole. It must cover correlated phase-space and loop limits. Merely
observing an integrable weighted interior is insufficient. If higher contacts
are allowed, retain them and use enough independent weighted moments to fix
the corresponding Hermite interpolation problem.

The linear-subtraction extension

    E[f][phi] = Integral[f(z)*(phi(z)-(1-z)*phi(0)-z*phi(1)), {z,0,1}]

annihilates both moments. Under the proved bound the full distribution is
E[f]+T*(delta_0+delta_1)/2. Converting to the package's standard full-interval
plus basis produces generally unequal displayed delta coefficients.

## Universal inclusive inputs (not amplitude coefficients)

The conventional massless three-body one-loop scalar catalogue has integrated
bubbles V5a,V5b and an integrated one-mass box V8, with a further pair-invariant
denominator. Candidate definitions appear in hep-ph/0403057 Appendix A.2;
hep-ph/0311276 section 4.3 treats the box integral. Actual weighted generated
terms still require reduction: thirteen B0/C0/D0 occurrences are neither
thirteen inclusive masters nor evidence of a completed three-master reduction.
Virtual prescriptions must remain. Scalar epsilon demand includes valuations
of the complete rational reduction coefficients and normalization.

## Four-body boundary moments

For a unit measurement G=z*B-A with B>0, introduce an inserted measured
integral J=Integral[dPhi4*F*B^(N+1)*delta(z*B-A)]. Its r,s weighted moment is

    Integral[dPhi4*F*B^(N-r-s)*A^r*(B-A)^s].

Choosing N>=r+s avoids new inverse energy denominators. Reduce the left side
to measured masters and the right side to inclusive ones. Dotted measurement
cuts instead pair as w^(m-1)(A/B)/((m-1)!*B^m); do not use the unit-cut rule.
Choose weights with enough endpoint zeros or justify regulated pairing before
integrating an interior-only DE solution. Determine constants by generic-epsilon
rank or valuation-aware Laurent elimination, and reserve an unused moment or
physical evaluation as a check. No presumed catalogue size proves closure.

## Implementation status

This is an approved mathematical direction, not an implemented physical
contact-order proof or completed RR boundary determination. The current
campaign still lacks the complete alpha_s-squared EEC.
