# Incoming-LL qg NLO external comparison completed

Updated 2026-09-10. The independent full finite comparison now passes for
both observed quark and observed gluon, including delta(1-w), both NLO plus
distributions and the entire regular coefficient.

The reference is [Navis](https://github.com/QCDLab/navis), commit
`89dab06673c4b6d2a142236d5d0109642cfc3b57`. Its original UU/LL Rust coefficient
files are compiled without modification; PDF and grid dependencies are unused.
All 320 comparisons pass: four channels, UU/LL, ten exact parameter points,
four distribution coefficients. The qg LL subset contains 80 comparisons and
has maximum relative error 2.17e-14. Unequal renormalization, incoming and
fragmentation scales, several flavors and CA=3,5 are covered; the two incoming
factorization scales are equal to each other in this reference.

Navis UU additionally agrees with original INCNLO in all 128 overlapping
checks. The qq-prime and annihilation LL control channels independently pass.
The common source-derived normalization is alpha_s^3/(8 CC pi s^2);
CC=CA(CA^2-1) for qg. No fitted factor or production correction was used.

This is agreement with the public Navis implementation. Its README cites the
original NLO papers; we have not established that its source is an authenticated
copy of an original author-distributed program. It is one reference implementation.
Numerical comparisons are not a global symbolic identity proof.

Reproduce from the repository:

```sh
wolframscript -file Scripts/Validation/check_nlo_navis_references.wls ppHX_UU_NNLO ppHX_LL_NLO
```

Reports are saved in each project/channel Results/Validation/NavisReferences.wl.
The aggregate and reference/INCNLO crosscheck are in this directory.
Reference point generation including compilation took 2.61 seconds.
Full finite coefficient evaluations took less than 0.2 seconds in total,
excluding loading and serialization. The only new compiler dependency is rustc.
Verified GPT-6 Pro independently located the same source and reviewed its
channel/normalization structure; record 37 retains that exchange.

The earlier search record below is superseded.

---

# Incoming-LL qg NLO external reference status

Updated 2026-09-10. Both qg -> qX and qg -> gX production results exist,
with incoming longitudinal polarization and unpolarized fragmentation.
The independent full finite external comparison remains incomplete.
This is separate from the completed SIDIS NNLO UU/LL calculation.

## Verified primary references

- [Jager, Schafer, Stratmann and Vogelsang, hep-ph/0211007](https://arxiv.org/html/hep-ph/0211007):
  equation (12) includes both observed tags; equation (24) gives the distributional
  form. Section 2.5 does not supply the functions multiplying those distributions
  and regular logarithms. Equations (22)-(23) specify the finite helicity-preserving
  quark subtraction. Equation (25), LL = -UU, concerns distinct-flavor
  annihilation and cannot validate qg.
- [Jager dissertation](https://epub.uni-regensburg.de/10206/1/main.pdf),
  printed page 59 / PDF page 65, says the single-inclusive coefficients are
  omitted and reside in the authors' computer codes. Appendix B supplies
  d-dimensional Born cross sections, not the complete NLO finite coefficients.
- [de Florian, hep-ph/0210442](https://arxiv.org/abs/hep-ph/0210442) reports the
  independent NLO single-hadron calculation. Its abstract/paper link is available;
  a public executable reference package has not yet been located.
- Public QCDHUB repository inventories checked: JAM22, jam22polJets, JAMpol25,
  fitpack2, jam3d, LDRD-JPAC. PDF/FF grids and jet or spin-asymmetry modules
  are not an identified-hadron incoming-LL hard-coefficient reference.

A published calculation exists. These searches do not establish that no public
implementation exists. They establish that none of the inspected inputs closes
the requested full finite comparison. No author contact has been made.

## Acceptance

The missing comparison must include delta(1-w), both NLO plus distributions,
and the complete regular coefficient, with normalization, observed tag, scales,
flavors, and helicity factorization scheme matched explicitly. UU/INCNLO,
Born, pole, scale-log or threshold-only checks must not be counted as a complete
LL finite-reference test. Published reference values must remain validation-only.

Verified GPT-6 Pro was asked to locate an executable primary reference:
request d282f8a2-d142-488c-94a0-09363ef6bb82, outgoing gpt-6-pro, HTTP 200.
Review retrieval is pending.
