# CF231 sharp adjacent-strip calculation

This directory contains an isolated calculation for the CF231 adjacent block
pair `(8,7)` in the Kallen23 chart. It reads the exact audited strip from
`Codex/TwoRootCF231Audit` and does not modify any shared package or Fable file.

The first stage, `build_residue_space_cf231.wls`, reconstructs the complete
space of constant dlog residues. It determines the rank at two independent
finite-field samples, selects an independent row set, reconstructs its
rational nullspace, and substitutes every basis direction into the complete
two-variable compatibility identity. Equality of the finite-field and exact
dimensions together with exact symbolic closure certifies that no residue
direction was discarded. The result is rank 191 in 208 variables, hence 17
free residue matrices, with exact closure for all 17 basis directions.

`derive_pole_bounds_cf231.wls` finds forcing orders

```text
{f3,f4,f6,f8,f10,qeps} -> {2,2,2,3,2,2}
```

and therefore gauge orders `{1,1,1,2,1,1}`. Every local leading-pole
Sylvester operator has a nonzero determinant. The common-denominator gauge
has numerator bidegree at most `(7,10)`, giving 1408 gauge coefficients.

`sample_gauge_cf231.wls` constructs both gauge PDEs simultaneously. Together
with the 17 residue coordinates, the system has 1425 unknowns. Every sampled
system has coefficient rank 1409, augmented rank 1409, and nullity 16.

The epsilon reconstruction is complete. Ten 31-bit prime fields were needed
for rational reconstruction. For every prime, the 1425 coordinates have the
same degree census:

```text
(numerator degree, denominator degree)   coordinates
(3,8)                                    820
(2,7)                                    352
(1,6)                                     20
(0,5)                                      8
(1,7)                                      4
(0,6)                                      1
identically zero                         220
```

The exact reconstructed gauge satisfies all 32 entries of the two original
PDEs identically. The main artifacts are:

```text
CF231_8_7_lifted_candidate.wl
CF231_8_7_lifted_exact_check.wl
CF231_8_7_sharp_certificate.wl
CF231_8_7_modular_summary.wl
```

`STATUS.md` records the modular sample counts, reconstruction history, exact
acceptance criterion, and timings.
