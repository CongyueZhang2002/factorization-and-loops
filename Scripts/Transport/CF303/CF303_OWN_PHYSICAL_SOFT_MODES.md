# CF303 own physical soft modes

Date: 2026-09-03

## Result

The four genuinely new CF303 source modes are now represented by an exact,
compact endpoint record.  In the accepted 43-source ordering their embedding
is

```text
V_own(34,1) = 1
V_own(34,2) = 1,  V_own(35,2) = -2
V_own(36,3) = 1
V_own(37,4) = 1.
```

Accepted source coordinates `{34,35,36,37}` are state rows
`{40,41,42,43}` and original CF303 masters `{3,4,1,2}`.  The normalized
normal-residue eigenvalues are `{0,-4,0,0}`; the corresponding connection
exponents are `{0,-4 eps,0,0}`.  The exact formulas, ordering, and sparse
embedding are in `Artifacts/CF303OwnPhysicalSoftModes.wl`.

The physical transformation is

```text
I_source = (TDiagonal.S) F_canonical.
```

Its own 4-by-4 soft leading map has eight nonzero entries.  Their Laurent
valuations in `rho=2p-u` are five at order zero, two at order `-1`, and one
at order `-2`.  After applying `V_own`, the nonzero physical-mode valuations
are

| canonical mode | physical master(s) | valuation(s) |
|---|---|---|
| block 23, lambda 0 | 3, 4 | `0, -1` |
| block 23, lambda -4 | 3, 4 | `-1, -2` |
| block 24, `e42` | 1, 2 | `0, 0` |
| block 24, `e43` | 1, 2 | `0, 0` |

These are basis-normalization powers, not extra boundary modes.  In the
complete accepted final-layer deck, only state source column 41 (accepted
source coordinate 35) couples to the two final rows.  Therefore the three
zero modes `e40`, `e42`, and `e43` are killed by the final incoming block;
only the block-23 lambda-minus-4 mode needs a new homogeneous target
contraction.  Inherited source periods remain a separate inhomogeneous
particular contribution.

## Exact construction

Only four rows of each saved transformation were read lexically from
`sector_state_CF303_standard.wl`:

```text
TDiagonal rows 40--43: 5,107 bytes
S rows 40--43:         563,315 bytes
```

No full 154 MB connection was loaded.  The exact continued chart was used
before taking Laurent orders:

```text
u = 2p-rho
a = (4p(1-p)-2u)/(u^2+4p(1-p))
x = -ap
y = (1-a)(1-p)
sqrt(lambda2) = a-p
sqrt(1-4xy) = 1+ua.
```

Every half-integer power of a discriminant, including inverse powers such as
`Delta^(-1/2)` and `Delta^(-3/2)`, must be replaced by its continued chart
value before substituting `x,y`.  With that rule the exact 4-by-4
construction took approximately 0.05 seconds in one Wolfram main kernel and
had no unresolved radical or timed-out coordinate.

## Bounded control

`Controls/t_cf303_own_physical_soft_modes.wls` reads the committed modular
source residue `Artifacts/CF303SoftSourceResidueQ7.json`, constructs the
43-by-4 sparse `V_own`, and checks

```text
R_source V_own = V_own diag(0,-4,0,0)  (mod q).
```

The four columns have respectively `{0,2,0,0}` nonzero images.  This is the
expected two-entry image of the lambda-minus-4 vector and three exact kernel
vectors.  It also checks the state/accepted ordering and both leading-map
valuation censuses.

## Retraction of the provisional canonical tangential artifact

The earlier `CF303SoftRhoLazyKernels.wl` artifact is removed.  Its extraction
replaced positive `Sqrt[Delta]` syntax but failed to replace inverse and other
odd half-integer powers of the same discriminants.  A decisive symptom was
18 nonzero entries in `[N_soft,B_soft]`, all in state rows 42--43, despite a
`p`-independent residue; this violates the flatness relation for a regular
tangential finite part.  The provisional full-source Gamma and its claimed
kernel census must not be used.

The 35-row recursive source closure itself was sound and exactly invariant,
but it is unnecessary for the homogeneous own-mode map.  Full canonical
Gamma reconstruction was therefore abandoned in favor of the direct
physical six-master route and projection before reconstruction.
