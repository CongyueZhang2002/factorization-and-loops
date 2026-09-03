# CF303 own-source soft tangential system

Date: 2026-09-03

## Result

The four CF303-own source masters have a **rational GPL system** on the
physical soft branch. No elliptic kernel survives in this subsystem.

The rows are state canonical rows `{40,41,42,43}`, corresponding to accepted
source coordinates `34..37` and original CF303 masters `{3,4,1,2}`. Their
exact tangential equation at fixed

```text
rho = 2 p - u
```

has the sparse form

```text
d F_rows/dp = [ C0(eps)/p
               + C1(eps)/(1-p)
               + Cm1(eps)/(1+p)
               + Cq(eps) p/(1-2 p^2) ] F_dependency .
```

All four matrices are stored sparsely in
`Artifacts/CF303SoftRhoLazyKernels.wl`. Their nonzero coordinate counts are
respectively `{77,69,72,50}`. Every entry reconstructed exactly; there is no
polynomial remainder and every kinematic pole is simple. Coefficients are
rational functions of `eps`, with maximum numerator/denominator degrees
`4/3`.

Thus the exact singular set is

```text
p = 0, 1, -1, 1/Sqrt[2], -1/Sqrt[2].
```

The quadratic kernel is already a dlog kernel,
`p/(1-2 p^2) = -1/4 dlog(1-2 p^2)`. It may be retained as one quadratic
letter or split into the two GPL letters `+-1/Sqrt[2]`.

## Physical branch and normal coordinate

For `Kallen2Bilinear115`, write

```text
a = (4 p (1-p) - 2 u)/(u^2 + 4 p (1-p)),
x = -a p,
y = (1-a)(1-p).
```

At `u=2 p`, one has

```text
a=-p,  x=p^2,  y=1-p^2,
sqrt(lambda2)=-2p,
sqrt(1-4xy)=1-2p^2.
```

The extracted connection contains 4,100 occurrences of the lambda2 root and
76 occurrences of the bilinear root, but **zero occurrences of the remaining
Kallen root**. This is why the restriction is rational.

It is useful to first take the finite part with
`s=1-x-y` as normal coordinate. Near `rho=0`,

```text
s = ((1-2 p^2)/(2p)) rho + O(rho^2),
dlog((1-2 p^2)/(2p))/dp = (1+2 p^2)/(p(2 p^2-1)).
```

Therefore the fixed-rho tangential connection is obtained exactly from the
fixed-s finite part by

```text
B_rho = B_s + N_s dlog((1-2 p^2)/(2p)),
```

where `N_s = Res_(s=0) A_s`. The own-block normal residues and homogeneous
fixed-rho blocks are

```text
N_23 = eps {{0,2},{0,-4}},       N_24 = 0,

B_23 = {{-8 eps/p,
          -2 eps (-3+2p^2)/(p(-1+2p^2))},
         {0,
          -4 eps (1+2p^2)/(p(-1+2p^2))}},

B_24 = {{-2 eps/p,0},{0,2 eps/p}}.
```

The first own block and both homogeneous blocks are strict epsilon form. Forty
lower-source entries feeding rows 42--43 retain rational epsilon dependence;
this changes the Laurent bookkeeping but not the GPL function class.

## Exact dependencies

Direct lower-source dependencies after restriction are:

```text
row 40: {1,2,3,4,5,12,21,22,26,27,29,30,35,36,39,40,41}
row 41: {1,2,3,4,5,12,21,22,26,27,29,30,35,36,39,41}
row 42: {1,4,6,7,8,9,12,13,14,15,16,17,18,19,20,
         29,30,31,32,33,34,39,42}
row 43: {1,4,6,7,8,9,12,13,14,15,16,17,18,19,20,
         29,30,31,32,33,34,39,43}
```

Their recursive source closure is the 35 state positions

```text
{1,2,3,4,5,6,7,8,9,12,13,14,15,16,17,18,19,20,21,22,
 26,27,29,30,31,32,33,34,35,36,39,40,41,42,43}.
```

This excludes elliptic-extension blocks 15, 17, and 21 of the assembly.

## Construction and timings

The source is the accepted saved state
`ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/FamilyEpsFormsSolving/triple_root_2026-08-28_codex_clean/CF303/sector_state_CF303_standard.wl`,
whose `A` field has dimensions `{2,45,45}`. Loading or expanding that full
field is unnecessary.

`Scripts/Transport/Utilities/extract_wl_connection_rows.py` lexically extracts
only rows 40--43 of both connection components. On this state it reduced a
154 MB checkpoint to a 3.4 MB row slice in 11--12 seconds without starting a
Wolfram kernel. A single queued main kernel then:

1. retained a normal coordinate before substitution, so the soft-pole
   cancellation was not destroyed;
2. took the exact normal residue and tangential finite part entrywise;
3. imposed the two continued root sheets above;
4. changed from `s` to fixed `rho`; and
5. decomposed the result into the four sparse kernels.

The tangential extraction took 12 seconds, the normal/fixed-rho construction
11 seconds, and the sparse decomposition under 2 seconds. No subkernel and no
full 45-by-45 materialization was used.

For transport, pass the four kernel/coupling records from the artifact to the
lazy rational-epsilon word engine and Laurent-expand each `C_k(eps)` only to
the orders actually requested by the downstream rows. This avoids dense `H/K`
construction.

## Two correctness cautions

1. `cf303_selected21_residues_cheap_basis.json` is a constant-residue
   reconstruction on the historical regular second-axis paths. Its own claim
   is path-scoped. Directly restricting those residues to the soft curve gives
   a block-24 homogeneous matrix inconsistent with the saved state and the
   certified class-122 diagonal form. It must not be used as a global
   two-variable residue decomposition for this endpoint.
2. The historical normal-transport base `u=1/2` intersects the soft divisor at
   `p=1/4`. A fixed `u=1/2` base therefore cannot define one uniform soft
   continuation across the physical `p` interval. Use a nonintersecting base
   curve at fixed nonzero `rho`, or work directly with the local Frobenius
   realization.

This artifact supplies `Reg_(rho=0) A_parallel`. The final induced boundary
mode connection still has to apply the separately constructed normal
Frobenius factor/projector,

```text
Gamma_soft = Reg_(rho=0)[Phi^-1 (A_parallel Phi - d_p Phi)].
```

No physical mode or boundary constant is inferred here.
