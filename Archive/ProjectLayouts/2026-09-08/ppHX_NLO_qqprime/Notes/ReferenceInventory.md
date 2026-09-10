# Supplied references

The two originals are preserved in ../References without edits. The PDF labels the process as two longitudinally polarized incoming quarks, qq' -> qq'g. It does not define the distribution/logarithm basis associated with A0, B0, C0, etc., the overall normalization, or all scale conventions. The Mathematica file consists of assignments for A0, B0, C0, A1, B1, C1, A2, A, B, DD, EE, F, G, H, L, M, CC and does not supply a basis/convention header.

The rendered PDF and the Mathematica file disagree in signs for A0 and B, among other expressions. The PDF lists P0, P1 and P2 for EE but not P3 through P6. These are validation-input discrepancies, not grounds for changing generated production coefficients. Establish conventions and compare against the original analytic sources.

The user confirmed both incoming quarks polarized: LL uses g1(xa) g1(xb) D1(zh), and TT uses h1(xa) h1(xb) D1(zh). The old cards instead used beam-to-observed-hadron transfer and must not be copied unchanged for spin runs.

The general workflow now generates explicit LO+NLO UU, LL and TT hard functions.
The supplied Mathematica LL coefficients match **all 17 exact identities**.
With the physical invariant-density multiplier α_s³/(8 CA² π s²), the scale
coefficients A0/B0/C0 multiply log(muF²/s), A1/B1/C1 multiply log(muD²/s), and
A2 multiplies log(muR²/s). A, B and DD are the delta, plus0 and plus1 terms.
The regular basis is

```
EE log(w) + F log(v) + G log(1-v) + H log(1-w)
+ L [log(1-v)-log(1-vw)]/(1-w)
+ M log(1-v+vw)/(1-w) + CC.
```

The logarithmic combinations agree with Eq. (24) of
[Jäger et al., hep-ph/0211007](https://arxiv.org/pdf/hep-ph/0211007).
The attachment omitted its overall convention; the normalization was recovered
using the physical Born/leading-soft coefficient and checked by all independent
scale and finite identities. The supplied PDF sign discrepancies remain; the
Mathematica file is the matching reference, preserved unchanged.

UU independently agrees with the unmodified Aversa–Chiappetta–Greco–Guillet
INCNLO 1.4 code at eight physical points, for delta, plus0, plus1 and regular
coefficients. Sources are retained in References/INCNLO, obtained from the
[authors' distribution](https://lapth.cnrs.fr/PHOX_FAMILY/readme_inc.html).
JMAR=0, AL=1, CQ=0 includes that code's documented finite conversion to MSbar.
Its w-dependent plus multipliers are moved to constant endpoint coefficients
plus their regular differences before comparison. Production coefficients were
not corrected from either reference.

