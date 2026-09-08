# CF303 (25,11): prospective transport-exception certificate completed

Timestamp: 2026-08-30 20:06 PDT

The gauge-eliminated integrability certificate required prospectively by Fable note 09 is complete for CF303 block `(25,11)` on its exact production 25-letter `Kallen23` alphabet.

## Exact evidence

All systems have dimensions `208 x 50`:

- configured `p=2147483423`, `epsilon=1`: `rank(A)=48`, `rank([A|b])=49`, defect 1, `w^T b=1354485127`;
- configured `p=2147483399`, `epsilon=3/17`: `rank(A)=48`, `rank([A|b])=49`, defect 1, `w^T b=100950297`;
- fresh `p=851021167`, `epsilon=7/5`: `rank(A)=48`, `rank([A|b])=49`, defect 1, `w^T b=118636336`.

Every witness has exact `w^T A=0` and support 49. The evidence classifier returns `ConfirmedObstruction`, with defects `{1,1,1}`. Under the user's promotion policy recorded in Fable note 09, this satisfies the minimum mathematical impossibility certificate and therefore **permits `(25,11)` transport-exception conversion**.

The alphabet binding contains 23 rational letters lifted with an exact modular roundtrip plus the two production conjugate factors

```text
(-1 +/- sqrt(2)) (1+s) + (1 -/+ 2 sqrt(2)) t + t s.
```

All three primes split `sqrt(2)`; the first image roundtrips byte-for-byte to the accepted 25-letter artifact.

## Performance

The three native screens took `89.05`, `89.80`, and `92.52` seconds. On the fresh image, native dual evaluation was `91.79 s`; matrix assembly, rank, and left-null work together were below `0.04 s`.

Artifacts:

- `/home/maxzhang/factorization-and-loops-codex/Diagnostics/Artifacts/cf303_25_11_integrability/cf303_25_11_pointwise_integrability_3images.wl`
- `/home/maxzhang/factorization-and-loops-codex/Diagnostics/Logs/cf303_25_11_integrability_pointwise.log`
- `/home/maxzhang/factorization-and-loops-codex/Diagnostics/Scripts/cf303_25_11_integrability_pointwise.wls`

Production PGID `2337823` remains live and was not altered. Its already-paid exact chart materialization should be allowed to finish; the certificate above is the authoritative discriminator if the ordinary route returns the expected typed obstruction.

