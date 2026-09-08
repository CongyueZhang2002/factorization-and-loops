# CF303 boundary-inheritance audit

Date: 2026-09-03

## Result

The accepted CF303 regular-path operator can reuse lower-family transport for
most of its source sector, but it cannot yet be turned into a physical solution
without a CF303 boundary realization.

- 39 of the 43 source rows are exact lower-sector images.
- The remaining source rows are CF303 rows `{1,2,3,4}`.
- The final block is CF303 rows `{5,6}`.
- The accepted 293 regular-base boundary coordinates therefore split into 263
  inherited lower-sector coordinates, 24 CF303-own source coordinates, and 6
  CF303-own final-block coordinates.

The 263 inherited coordinates may be precomposed with lower-family transport
operators. This produces a smaller *formal* boundary-coordinate system; it
does not evaluate a physical boundary condition. The remaining 30 CF303-own
coordinates need a CF303 endpoint/sheet/mode constraint record.

CF303's absence from `BoundaryPeriods/Certificates/NullityPeriods.wl` is not a
certificate that these 30 coordinates vanish or are already fixed. The design
requires every family count to carry a constraint-matrix rank certificate, and
no CF303 rank certificate, endpoint specification, Frobenius realization, or
boundary-mode map is present.

## Exact row inheritance

The order below is the CF303 original-master order carried by the assembly.
The maps are the exact sector maps in
`Kira/UU_08_12_derivatives/kira_1/sectormappings/CF303/relations` and
`sectorRelations`; the target rows were matched in the target family's
`nnlo_de_*.wl` basis. Every pair also has matching `(Dim, ClassID)` in
`Results/UU_08_10_canonical/BlockClasses/block_class_assign.wl`.

| CF303 rows | inherited family rows |
|---|---|
| `{7}` | CF1 `{1}` |
| `{39}` | CF12 `{4}` |
| `{35}` | CF12 `{3}` |
| `{26}` | CF48 `{5}` |
| `{44}` | CF48 `{8}` |
| `{9}` | CF1 `{2}` |
| `{14,15}` | CF16 `{3,4}` |
| `{28}` | CF48 `{6}` |
| `{31}` | CF13 `{2}` |
| `{45}` | CF86 `{1}` |
| `{8}` | CF21 `{1}` |
| `{10,11,12,13}` | CF21 `{7,8,9,11}` |
| `{16,17,18,19}` | CF231 `{1,2,3,4}` |
| `{29,30}` | CF199 `{1,2}` |
| `{32,33,34}` | CF226 `{1,2,3}` |
| `{36,37}` | CF199 `{5,6}` |
| `{38}` | CF231 `{5}` |
| `{20,21}` | CF53 `{4,5}` |
| `{22,23,24,25}` | CF91 `{1,2,3,4}` |
| `{40,41}` | CF299 `{1,2}` |
| `{42,43}` | CF300 `{1,2}` |
| `{27}` | CF57 `{1}` |

The six CF303-own masters are not removed by connection-class sharing. In
particular, CF303 rows `{3,4}` share class 116 with CF299 rows `{4,5}`, but a
shared differential-equation class does not identify their physical integration
constants. CF303 rows `{1,2}` and `{5,6}` are unique class representatives.

## Basis map and accepted operator

`Scripts/family_epsform_sector.wls` constructs the absolute canonical-to-source
map as `TTotal = TDiagonal . S` and its inverse as
`SInverse . TDiagonalInverse`. The saved CF303 sector state contains all four
45-by-45 matrices. Therefore the earlier statement that no 43-row source map
exists was too strong: the source restriction is available in the sector
state, subject to preserving the recorded block/row permutation.

The accepted lazy operator is
`/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_final45_hybrid_baseline_lazy_operator.wl`.
It records 287 source and 6 final homogeneous boundary columns. Its path has
regular base `1/2`; it is not a singular-boundary realization.

The exact reduced stream
`Results/UU_08_10_canonical/KiraStream/Reduced/CF303.wxf` confirms the direct
one-term sector images that are present as reduction keys. The sector-relation
files remain the authoritative map for the local canonical masters that are not
keys in the reduced stream.

## Why the existing transports do not close CF303

The ordinary-family artifacts in
`Results/UU_08_10_canonical/ObservableTransport_2026-09-01_codex/families/`
and the separate CF300 artifact expose `BoundarySlots`, a base embedding, and
arbitrary boundary coordinates. They are transport operators, not evaluated
physical-period vectors. All inherited target families above have such an
operator (CF300 through its separate triple-root artifact), so composing the
263 inherited coordinates is structurally possible. It cannot determine the
30 CF303-own coordinates or select a physical branch.

The generic soft stratum `1-v-w -> 0+` has two preimages in the accepted CF303
chart and opposite radical sheets. No CF303 record chooses the continued sheet
or supplies its local mode constraints. Guessing either would turn a formal
operator into an unjustified physical answer.

## Minimal next step

1. Reconstruct or rerun the CF303 nullity calculation against the accepted
   45-row assembly and write its endpoint, sheet, selected Frobenius modes,
   constraint matrix, rank, and realization map.
2. Once that record exists, precompose the 263 inherited coordinates with the
   lower-family operators and solve only the resulting equations for the 30
   CF303-own coordinates.
3. If the certified nullity is zero, report the explicit inhomogeneous solution
   for those 30 coordinates. “No new period” means fixed by constraints; it
   does not mean that a boundary-mode map may be omitted.

No adapter was added in this audit because the necessary CF303 physical
endpoint/sheet/mode data are absent. Adding one now would encode an invented
physical mapping.
