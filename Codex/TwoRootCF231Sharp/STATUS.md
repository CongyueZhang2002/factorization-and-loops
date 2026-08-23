# CF231 `(8,7)` completion record

## Exact result

The sharp rational extension in the Kallen23 chart is complete. The exact
acceptance criterion was entrywise vanishing of both matrix PDEs,

```text
partial_mu R - epsilon (E_mu R - R C_mu)
  = Bbar_mu - epsilon Sum_a K_a partial_mu log(W_a),  mu=y,s.
```

All 32 rational entries vanish identically after reconstruction.

## Linear systems

- Constant-dlog residue variables: 208.
- Exact residue rank: 191.
- Exact residue nullity: 17.
- Gauge coefficients: 1408.
- Total affine unknowns: 1425.
- Sampled coefficient rank: 1409.
- Sampled augmented rank: 1409.
- Sampled affine nullity: 16.
- Every sampled affine system is consistent.
- Every stored particular and nullspace residual is zero modulo its prime.

## Prime and epsilon census

The rational reconstruction uses these ten primes:

```text
2147483423, 2147483477, 2147483489, 2147483497, 2147483543,
2147483549, 2147483563, 2147483587, 2147483629, 2147483647.
```

The largest prime has 40 affine epsilon samples: 30 for construction and 10
for independent interpolation tests. Each other reconstruction prime has 28
affine samples: 20 for construction and 8 for independent tests. Additional
rank calculations were made at primes 1000003, 1000033, and 1000037.

Each reconstruction prime gives the same degree census:

| numerator degree | denominator degree | coordinates |
|---:|---:|---:|
| 3 | 8 | 820 |
| 2 | 7 | 352 |
| 1 | 6 | 20 |
| 0 | 5 | 8 |
| 1 | 7 | 4 |
| 0 | 6 | 1 |
| identically zero | 0 | 220 |

No coordinate remains unresolved.

## Reconstruction history

Reconstructions with six, seven, eight, and nine 31-bit primes gave nonzero
residuals at exact rational chart points. The ten-prime reconstruction made
all three rational-point checks vanish, after which exact symbolic reduction
made all 32 PDE numerators zero. The bottleneck was therefore the height of
the rational coefficients, not the epsilon degree or the rank of the gauge
system.

## Timings

- Epsilon interpolation: 7.55--8.49 s for each 28-sample prime; 11.78 s for
  the 40-sample prime.
- Final rational lift: 0.36 s.
- Exact symbolic closure of all 32 entries: 9.43 s using four subkernels.

## Artifacts

- `CF231_8_7_residue_space.wl`: exact 17-dimensional residue space.
- `CF231_8_7_pole_bounds.wl`: divisor-specific forcing and gauge orders.
- `CF231_8_7_modular_summary.wl`: sample and interpolation census.
- `CF231_8_7_lifted_candidate.wl`: reconstructed gauge and residues.
- `CF231_8_7_lifted_exact_check.wl`: rational-point and symbolic checks.
- `CF231_8_7_sharp_certificate.wl`: hashes and final exact certificate.
