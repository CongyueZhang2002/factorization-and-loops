# Change note for Codex: the family certificate (final check) — 2026-08-22

Author: Fable (Claude Fable 5), at the user's request ("write to external
your change to check").  Please review the mathematics and the failure
modes; nothing here is committed.

## What changed

`CertifyFamilyEpsilonForm` (FeynFacet/Private/FamilyEpsForm.wl) now
defaults to `"IdentityMethod" -> "Modular"`, implemented in the new
`FeynFacet/Private/FamilyCertificateModular.wl`.  The former symbolic
path (`"Symbolic"`: entrywise `Together` of the four matrix identities and
CANONICA's `ValidateCanonicalForm`) is still selectable; an intermediate
`"RandomPoints"` path (exact rational evaluation at random rational points)
exists as well.

Statement certified (unchanged): for the record's transformation T (TTotal
= T_diag . S), its stored inverse, the eps-form A' = (EpsFormX, EpsFormY)
and the source DE A pulled back to the chart,
  T T^-1 = 1,  T^-1 (A T - dT) = A',  dA' + A'^A' = 0,  dA + A^A = 0,
  A' = eps * (eps-free),  A' = eps Sum_a K_a dlog L_a with constant K_a,
  block-lower-triangular, chart identity.

How it is now computed:
1. every entry of T, T^-1, A', the source A (in the source variables), the
   chart map (f, g) and the letters L_a is compiled once into integer
   coefficient + exponent arrays (numerator and denominator polynomials;
   rational coefficients cleared by the LCM); ~1 s for 32x32;
2. for each of 3 random primes p in [2^23, 2^24] and 12 random points
   (x, y, eps) in F_p^3 (raised so that the residue solve below is
   overdetermined): power tables, all matrices by packed dot products,
   derivatives from the coefficient data as (N' D - N D')/D^2, the chart
   connection by the chain rule A_x = A_v d_x f + A_w d_x g at the mapped
   point (v, w) = (f, g)(x, y) — no symbolic pull-back;
3. identities checked mod p; eps-factorization as e2 A'(e1) = e1 A'(e2) at a
   second random regulator value; dlog form as the linear system
   A'_mu/eps = Sum_a K_a dlog_mu L_a over all points at once (2 rows per
   point, one unknown matrix per letter), consistency mod p = dlog with
   constant residues; the letters are the irreducible factors of the
   eps-form denominators (the one symbolic step: FactorList of products of
   low-degree polynomials);
4. source flatness dA + A^A = 0 at the mapped points in the source
   variables (it was checked in the chart before; it is an input property);
5. a failure at any point of any prime fails the check; too few accepted
   points at any prime fails every check ("Trouble").

Probability statement recorded in the certificate: a nonzero numerator
polynomial of total degree <= d vanishes at a uniformly random point of
F_p^3 with probability <= d/p (Schwartz-Zippel); d is a (loose) bound from
the compiled degrees (n_M + n^2 d_M per factor, products add); the
recorded `IdentityErrorBound` is 8 n^2 (d/p_min)^(points x primes):
CF231 4.6e-77, CF305 1.7e-65, CF265 6.8e-68.  Not covered by that bound:
a prime dividing every coefficient of a nonzero identity numerator (at most
log2(H) of the ~1e6 primes in the range, H the coefficient height;
`HeightBits` is recorded) — three independent random primes make this
negligible, but it is a separate term.  The residue matrices are
reconstructed rationally from one prime and verified at the others when
the reconstruction succeeds (for CF231 it did not: at least one residue
exceeds the single-prime bound sqrt(p/2); the verdict does not depend on
it).

## Measured

| family | symbolic certificate | modular certificate |
|---|---|---|
| CF231 (23x23) | 456 s, exact=True (12:00) | 10.1 s, exact=True, same verdict |
| CF305 (32x32) | killed after 67 min, no verdict | 17.8 s, exact=True |
| CF265 (32x32) | killed after 53 min, no verdict | 17.8 s, exact=True |

Corrupted inputs (`Tests/t_family_certificate_modular.wls`, 8/8): a
transformation with one entry changed by eps/7 fails TransformationInverse
and GaugeIdentity only; an eps-form with one entry changed by
eps^2/(1+x) fails EpsFactored, DLog, GaugeIdentity and Flatness.  Existing
tests t_certify_family_epsilon_form (incl. BrokenGaugeRejected),
t_exact_family_epsilon_form_q, t_family_epsform_module pass with the new
default.

## What I would like checked

1. The degree bound: is n^2 d_M per factor a valid bound for the
   numerator degree of an entry of a product of matrices over the common
   denominator (I use: a/b with deg a <= n_M, b | L, deg L <= n^2 d_M gives
   a (L/b)/L; products add; a derivative adds deg L once more)?  It is
   loose by design; what matters is that it is not an underestimate.
2. The dlog test: the solve is one linear system over all points and both
   variables with one unknown matrix per letter; rank = #letters is
   checked and recorded (`DlogRank`).  Is there a case where a non-dlog
   form passes because the letter set (denominator factors of A') misses
   a letter that only appears after cancellation?  I believe a dlog form's
   letters are exactly its pole factors, so a missing letter can only make
   the test fail, never pass.
3. The eps-factorization test e2 A'(e1) = e1 A'(e2): equivalent to A'/eps
   independent of eps as a rational function — any gap?
4. Source flatness moved to the source variables at the mapped point
   (chain rule) instead of the pulled-back chart connection: equivalent
   given the chain rule is an identity?

## Other changes today that the certificate now relies on

- The block order in the record: a resumed sector run wrote "Blocks" in
  class-assignment order against assembly-ordered "Ranges"/OriginalA;
  fixed (state caches the assembly's Blocks; old states recompute the
  assembly and verify it against the cached connection at random points).
  This was the reason CF305/CF265 first failed the gauge identity — the
  certificate caught a real defect.
- Regulator dependence of the residues is removed by
  `FactorFamilyRegulatorDependence` (Libra FactorDependence on exact
  rational samples; the unsampled symbolic identity is the acceptance
  test), per completed sector row and at the family end; the per-sector
  CANONICA steps are no longer in the production loop.

Files: FeynFacet/Private/FamilyCertificateModular.wl, FamilyEpsForm.wl,
FamilyRegulatorFactor.wl, Scripts/family_epsform_sector.wls,
Tests/t_family_certificate_modular.wls; certificates in
ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/FamilyEpsFormsCertified/.
