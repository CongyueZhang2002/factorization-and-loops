# Transport depth ledger (per-master demands, per-block depth)

Generated 2026-08-16T23:37:42 by `Scripts/master_coefficient_valuations.py` (valuations) and `Scripts/transport_depth_ledger.wls` (per-family depth). Machine-readable companion: `TransportDepthLedger.wl`; per-master table: `MasterCoefficientValuations.wl`.

**Nothing here was transported.** Every family is entered through the existing `TransportFamily` / `TransportFamilyInChart` with `"MaxWeight" -> 0`, which returns the assembly and the depth arithmetic and stops before the backend.

## What is measured and what is assumed

MEASURED
- the eps-Laurent valuation of every canonical master's coefficient column in the hard
  function (345 exact rational columns + 2 eps^5 series columns, 2026-08-13 production
  reconstruction). Each rational column's valuation is pinned by a SANDWICH: a rigorous
  structural lower bound on ord_eps meets a rigorous evaluation upper bound obtained by
  substituting exact field elements for CA, CF, x, y in F_p, p = 2^61-1, with eps kept
  SYMBOLIC. Where the two meet the valuation is exact, with no probabilistic step. All
  343 non-zero rational columns closed at three independent random points.
- the per-block kmin, the coupling DAG, the FULL Laurent support of every coupling
  block, and both depth rules, computed on each family's own assembled connection.

ASSUMPTION / CONVENTION (stated, not measured)
- `N_a = 0 - valuation_a + 1`: the hard function is wanted through eps^0 and one extra
  order of safety is carried. The number without the +1 is tabulated everywhere.
- a family DE row that is not one of that family's OWN canonical masters carries no
  direct demand: it is a canonical master of another family and is solved there; inside
  this family it is only a source, so its depth comes from the coupling back-propagation.
- the couplings are dlog with constant Laurent-in-eps residues. The whole weight grading
  rests on this. It is part of the assembly certificate for the DIAGONAL blocks and is
  NOT separately re-certified for the off-diagonal couplings here (flagged by both
  2026-08-16 reviews).
- an overall eps-free normalization common to all columns does not shift the demands; a
  prefactor with nonzero eps valuation would shift them all uniformly.

## Master coefficient valuations (all 347)

| valuation | masters | demand N = -val + 1 |
|---|---|---|
| -4 | 1 | 5 |
| -3 | 1 | 4 |
| -2 | 7 | 3 |
| -1 | 131 | 2 |
| 0 | 203 | 1 |
| 1 | 2 | 0 |
| (identically zero column) | 2 | none |

The deepest column is eps^-4 (exactly one master), so the deepest demand anywhere in the hard function is eps^5. 203 of 347 columns start at eps^0 (demand eps^1) and 131 at eps^-1 (demand eps^2); only 9 columns are deeper than eps^-1. The earlier planning estimate "every master through roughly eps^4" is superseded.

Masters with a column valuation <= -2:

| master | valuation | route | N | N (no +1) |
|---|---|---|---|---|
| `GLI[CF1, {1, 1, 0, 0, 1, 0, 0, 0, 0}]` | -4 | SeriesReconstruction | 5 | 4 |
| `GLI[CF21, {1, 1, 0, 0, 0, 1, 0, 1, 0}]` | -3 | ExactSandwich | 4 | 3 |
| `GLI[CF1, {1, 1, 1, 0, 1, 0, 0, 0, 0}]` | -2 | SeriesReconstruction | 3 | 2 |
| `GLI[CF16, {1, 1, 0, 0, 1, 1, 1, 1, 0}]` | -2 | ExactSandwich | 3 | 2 |
| `GLI[CF16, {1, 1, 0, 0, 1, 1, 1, 2, 0}]` | -2 | ExactSandwich | 3 | 2 |
| `GLI[CF20, {1, 1, 0, 1, 0, 0, 0, 1, 0}]` | -2 | ExactSandwich | 3 | 2 |
| `GLI[CF248, {1, 1, 0, 1, 0, 1, 0, 2, 0}]` | -2 | ExactSandwich | 3 | 2 |
| `GLI[CF50, {1, 1, 0, 0, 1, 1, 0, 2, 0}]` | -2 | ExactSandwich | 3 | 2 |
| `GLI[CF53, {1, 1, 0, 1, 0, 1, 0, 2, 0}]` | -2 | ExactSandwich | 3 | 2 |

Identically zero coefficient columns (no demand at all): `GLI[CF56, {1, 1, 1, 1, 1, 1, 0, 2, 0}]`, `GLI[CF57, {1, 1, 1, 1, 1, 1, 0, 2, 0}]`

## The chart families in detail

### CF230  (Chart frame, entry status `DepthExceedsCap`, 315.066465 s)

- dimension 13, block dims {1, 1, 1, 4, 2, 4}, classes {1, 2, 2, 8, 77, 49}
- block rows: {{5}, {7}, {6}, {8, 9, 10, 11}, {12, 13}, {1, 2, 3, 4}}
- kmin per block {0, 0, 0, -1, -1, -1}, lowest carried order {0, 0, 0, -2, -2, -3}

  | master | valuation | route | N (+1) | N (no +1) |
  |---|---|---|---|---|
  | `gli["CF230", {1, 1, 1, 0, 1, 0, 1, 1, 0}]` | -1 | ExactSandwich | 2 | 1 |
  | `gli["CF230", {1, 1, 1, 0, 1, 0, 1, 2, 0}]` | -1 | ExactSandwich | 2 | 1 |
  | `gli["CF230", {1, 1, 1, 0, 2, 0, 1, 1, 0}]` | -1 | ExactSandwich | 2 | 1 |
  | `gli["CF230", {1, 1, 2, 0, 1, 0, 1, 1, 0}]` | -1 | ExactSandwich | 2 | 1 |

- per-block demand N_i (Eq. 11, with +1): {-Infinity, -Infinity, -Infinity, -Infinity, -Infinity, 2}
- per-block demand N_i (Eq. 11, no +1):  {-Infinity, -Infinity, -Infinity, -Infinity, -Infinity, 1}
- module's own per-block need (all blocks at kmaxF): {4, 3, 2, 1, 1, 1}
- Bellman potentials pi_i: {0, 1, 1, 3, 3, 4}
- exact W_i(N_i), Eq. 11 demands: {-Infinity, -Infinity, -Infinity, -Infinity, -Infinity, 6}  -> **max 6**
- clamped per block, same demands: {-Infinity, -Infinity, -Infinity, -Infinity, -Infinity, 7}  -> **max 7**
- exact max_i W_i, module's own demands: 5
- the module's CURRENT requested weight (clamped jmax + D): 6
- deficit edges (ord <= 0): {{2, 1}, {3, 1}, {4, 1}, {4, 2}, {4, 3}, {5, 1}, {5, 3}, {6, 1}, {6, 2}, {6, 3}, {6, 4}, {6, 5}}
- slack edges (ord >= 2): {{6, 1}, {6, 2}, {6, 3}, {6, 4}, {6, 5}}
- **MIXED edges** (deficit AND slack in the same coupling block -- where the two rules differ): {{6, 1}, {6, 2}, {6, 3}, {6, 4}, {6, 5}}
- Laurent support cap used: 5

  full Laurent support of every coupling block (block i depends on block j):

  | edge (i,j) | eps-orders present | truncated at cap |
  |---|---|---|
  | (2,1) | {0, 1} | False |
  | (3,1) | {0, 1} | False |
  | (4,1) | {-2, -1, 0, 1} | False |
  | (4,2) | {-1, 0, 1} | False |
  | (4,3) | {-1, 0, 1} | False |
  | (5,1) | {-2, -1, 0, 1} | False |
  | (5,3) | {-1, 0, 1} | False |
  | (6,1) | {-3, -2, -1, 0, 1, 2, 3, 4, 5} | True |
  | (6,2) | {-2, -1, 0, 1, 2, 3, 4, 5} | True |
  | (6,3) | {-1, 0, 1, 2, 3, 4, 5} | True |
  | (6,4) | {0, 1, 2, 3, 4, 5} | True |
  | (6,5) | {0, 1, 2, 3, 4, 5} | True |

### CF258  (Chart frame, entry status `DepthExceedsCap`, 598.22536 s)

- dimension 24, block dims {1, 1, 1, 2, 1, 1, 4, 4, 2, 4, 1, 2}, classes {1, 2, 2, 56, 64, 64, 95, 8, 96, 49, 77, 97}
- block rows: {{3}, {22}, {5}, {16, 17}, {24}, {4}, {6, 7, 8, 9}, {18, 19, 20, 21}, {10, 11}, {12, 13, 14, 15}, {23}, {1, 2}}
- kmin per block {0, 0, 0, -1, 0, 0, -1, -1, -1, -1, 0, 0}, lowest carried order {0, -1, 0, -2, -2, 0, -2, -3, -2, -3, -1, -3}

  | master | valuation | route | N (+1) | N (no +1) |
  |---|---|---|---|---|
  | `gli["CF258", {1, 1, 0, 1, 1, 1, 0, 1, 1}]` | 0 | ExactSandwich | 1 | 0 |
  | `gli["CF258", {1, 1, 0, 1, 1, 1, 0, 1, 2}]` | 0 | ExactSandwich | 1 | 0 |

- per-block demand N_i (Eq. 11, with +1): {-Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, 1}
- per-block demand N_i (Eq. 11, no +1):  {-Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, 0}
- module's own per-block need (all blocks at kmaxF): {4, 1, 3, 1, 1, 2, 1, 1, 1, 1, 1, 1}
- Bellman potentials pi_i: {0, 2, 1, 3, 3, 1, 3, 4, 3, 4, 3, 5}
- exact W_i(N_i), Eq. 11 demands: {-Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, 6}  -> **max 6**
- clamped per block, same demands: {-Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, 6}  -> **max 6**
- exact max_i W_i, module's own demands: 6
- the module's CURRENT requested weight (clamped jmax + D): 7
- deficit edges (ord <= 0): {{2, 1}, {3, 1}, {4, 1}, {4, 3}, {5, 1}, {5, 2}, {5, 3}, {6, 1}, {7, 1}, {7, 3}, {7, 6}, {8, 1}, {8, 3}, {8, 6}, {8, 7}, {9, 1}, {9, 6}, {10, 1}, {10, 3}, {10, 6}, {10, 7}, {10, 9}, {11, 2}, {11, 6}, {12, 1}, {12, 2}, {12, 3}, {12, 6}, {12, 8}, {12, 10}}
- slack edges (ord >= 2): {{8, 1}, {8, 3}, {8, 4}, {8, 6}, {8, 7}, {10, 1}, {10, 3}, {10, 6}, {10, 7}, {10, 9}, {12, 1}, {12, 2}, {12, 3}, {12, 4}, {12, 5}, {12, 6}, {12, 7}, {12, 8}, {12, 9}, {12, 10}, {12, 11}}
- **MIXED edges** (deficit AND slack in the same coupling block -- where the two rules differ): {{8, 1}, {8, 3}, {8, 6}, {8, 7}, {10, 1}, {10, 3}, {10, 6}, {10, 7}, {10, 9}, {12, 1}, {12, 2}, {12, 3}, {12, 6}, {12, 8}, {12, 10}}
- Laurent support cap used: 4

  full Laurent support of every coupling block (block i depends on block j):

  | edge (i,j) | eps-orders present | truncated at cap |
  |---|---|---|
  | (2,1) | {-1, 0, 1} | False |
  | (3,1) | {0, 1} | False |
  | (4,1) | {-2, -1, 0, 1} | False |
  | (4,3) | {-1, 0, 1} | False |
  | (5,1) | {-2, -1, 0, 1} | False |
  | (5,2) | {0, 1} | False |
  | (5,3) | {-1, 0, 1} | False |
  | (5,4) | {1} | False |
  | (6,1) | {0, 1} | False |
  | (7,1) | {-2, -1, 0, 1} | False |
  | (7,3) | {-1, 0, 1} | False |
  | (7,6) | {-1, 0, 1} | False |
  | (8,1) | {-3, -2, -1, 0, 1, 2, 3, 4} | True |
  | (8,3) | {-2, -1, 0, 1, 2, 3, 4} | True |
  | (8,4) | {1, 2, 3, 4} | True |
  | (8,6) | {-1, 0, 1, 2, 3, 4} | True |
  | (8,7) | {0, 1, 2, 3, 4} | True |
  | (9,1) | {-2, -1, 0, 1} | False |
  | (9,6) | {-1, 0, 1} | False |
  | (10,1) | {-3, -2, -1, 0, 1, 2, 3, 4} | True |
  | (10,3) | {-2, -1, 0, 1, 2, 3, 4} | True |
  | (10,6) | {-1, 0, 1, 2, 3, 4} | True |
  | (10,7) | {0, 1, 2, 3, 4} | True |
  | (10,9) | {0, 1, 2, 3, 4} | True |
  | (11,2) | {0, 1} | False |
  | (11,6) | {-1, 0, 1} | False |
  | (11,9) | {1} | False |
  | (12,1) | {-2, -1, 0, 1, 2, 3, 4} | True |
  | (12,2) | {0, 1, 2, 3, 4} | True |
  | (12,3) | {-1, 0, 1, 2, 3, 4} | True |
  | (12,4) | {1, 2, 3, 4} | True |
  | (12,5) | {1, 2, 3, 4} | True |
  | (12,6) | {0, 1, 2, 3, 4} | True |
  | (12,7) | {1, 2, 3, 4} | True |
  | (12,8) | {0, 1, 2, 3, 4} | True |
  | (12,9) | {1, 2, 3, 4} | True |
  | (12,10) | {0, 1, 2, 3, 4} | True |
  | (12,11) | {1, 2, 3, 4} | True |

## All families with a full depth record

38 of 91 families carry a full per-block depth record. `clamped` is the weight the module requests today (jmax + D on its own uniform demands). `exact(mod)` is the exact recursion on those same demands. The last comparison is the like-for-like one: both rules on the MEASURED Eq. (11) demands.

| family | dim | frame | blocks-demand N_i (Eq. 11) | clamped | exact(mod) | exact(Eq.11) | clamped(Eq.11) | mixed edges | s |
|---|---|---|---|---|---|---|---|---|---|
| CF1 | 2 | SourceVW | {5, 3} | 2 | 2 | **5** | 5 | 0 | 0.012957 |
| CF12 | 14 | Chart | {-Infinity, -Infinity, 1, 2, 1, 2, 2, 1, 1, 1} | 6 | 5 | **6** | 7 | 6 | 22.322679 |
| CF123 | 11 | SourceVW | {-Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, 1, 1} | 6 | 5 | **5** | 5 | 5 | 8.406543 |
| CF124 | 12 | SourceVW | {-Infinity, -Infinity, -Infinity, -Infinity, -Infinity, 2, -Infinity, -Infinity, 2, 2} | 7 | 6 | **7** | 7 | 13 | 17.749003 |
| CF198 | 11 | Chart | {-Infinity, -Infinity, -Infinity, -Infinity, 2, 1, 1, 1, 1, 1} | 7 | 6 | **6** | 6 | 4 | 1.782348 |
| CF2 | 4 | SourceVW | {-Infinity, -Infinity, 2} | 4 | 4 | **5** | 5 | 2 | 0.144427 |
| CF20 | 14 | Chart | {-Infinity, -Infinity, -Infinity, 3, 1, 2, 1, 1, 1, 2} | 6 | 5 | **6** | 7 | 5 | 4.052707 |
| CF204 | 9 | Chart | {-Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, 1} | 7 | 6 | **6** | 6 | 4 | 1.990807 |
| CF205 | 11 | SourceVW | {-Infinity, -Infinity, -Infinity, -Infinity, -Infinity, 1, -Infinity, -Infinity, -Infinity, 1} | 5 | 4 | **4** | 4 | 0 | 0.238311 |
| CF207 | 8 | Chart | {-Infinity, -Infinity, 2, -Infinity, -Infinity, 1} | 6 | 5 | **5** | 6 | 3 | 7.030069 |
| CF209 | 14 | Chart | {-Infinity, -Infinity, -Infinity, -Infinity, 1, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, 2, -Infinity, 1} | 7 | 6 | **6** | 7 | 9 | 2.888081 |
| CF210 | 9 | Chart | {-Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, 1} | 5 | 4 | **4** | 4 | 0 | 0.641918 |
| CF211 | 14 | Chart | {-Infinity, -Infinity, -Infinity, -Infinity, 1, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, 2, -Infinity, 1} | 7 | 6 | **6** | 7 | 9 | 2.80375 |
| CF212 | 9 | Chart | {-Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, 1} | 5 | 4 | **4** | 4 | 0 | 0.630445 |
| CF213 | 13 | Chart | {-Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, 1, -Infinity, -Infinity, 1} | 7 | 6 | **6** | 6 | 7 | 22.744351 |
| CF215 | 13 | Chart | {-Infinity, -Infinity, -Infinity, 1, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, 1} | 7 | 6 | **6** | 6 | 7 | 31.537817 |
| CF217 | 13 | Chart | {-Infinity, -Infinity, -Infinity, -Infinity, 1, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, 1} | 7 | 6 | **6** | 6 | 7 | 29.503123 |
| CF230 | 13 | Chart | {-Infinity, -Infinity, -Infinity, -Infinity, -Infinity, 2} | 6 | 5 | **6** | 7 | 5 | 315.066465 |
| CF258 | 24 | Chart | {-Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, 1} | 7 | 6 | **6** | 6 | 15 | 598.22536 |
| CF26 | 15 | Chart | {-Infinity, -Infinity, -Infinity, -Infinity, 1, -Infinity, -Infinity, -Infinity, 2, 1} | Missing["-"] | 8 | **8** | 9 | 23 | 31.256972 |
| CF262 | 10 | Chart | {-Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, 1, -Infinity, 1} | Missing["-"] | 4 | **4** | 4 | 0 | 1.114116 |
| CF263 | 18 | Chart | {-Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, 1} | Missing["-"] | 6 | **6** | 6 | 9 | 5.423599 |
| CF264 | 18 | Chart | {-Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, 1} | 7 | 6 | **6** | 6 | 9 | 490.602103 |
| CF267 | 16 | Chart | {-Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, 1, 1, 1} | Missing["-"] | 6 | **6** | 6 | 8 | 5.246182 |
| CF269 | 23 | Chart | {-Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, 1, -Infinity, -Infinity, -Infinity, 1} | Missing["-"] | 7 | **7** | 7 | 23 | 56.6428 |
| CF27 | 8 | Chart | {-Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, 2} | 6 | 5 | **6** | 7 | 5 | 3.879033 |
| CF301 | 18 | SourceVW | {-Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, 1, -Infinity, -Infinity, -Infinity, -Infinity, 1, 1} | Missing["-"] | 6 | **6** | 6 | 9 | 1.113927 |
| CF308 | 16 | Chart | {-Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, 1, -Infinity, -Infinity, -Infinity, -Infinity, 1, 1} | Missing["-"] | 6 | **6** | 6 | 8 | 4.142296 |
| CF360 | 4 | SourceVW | {-Infinity, -Infinity, 2} | 6 | 5 | **6** | 7 | 2 | 0.986684 |
| CF384 | 27 | Chart | {-Infinity, -Infinity, -Infinity, 2, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, 1, -Infinity, -Infinity, -Infinity, 1, -Infinity, -Infinity, 1, 1, 1} | Missing["-"] | 8 | **8** | 8 | 35 | 14.194039 |
| CF407 | 24 | Chart | {1, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, 2, -Infinity, -Infinity, -Infinity, -Infinity, 1, 1} | Missing["-"] | 8 | **8** | 8 | 35 | 22.584231 |
| CF415 | 16 | Chart | {-Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, 0, 1} | Missing["-"] | 6 | **6** | 6 | 9 | 5.330147 |
| CF429 | 2 | SourceVW | {1, -Infinity} | 1 | 1 | **1** | 1 | 0 | 0.009023 |
| CF50 | 22 | Chart | {-Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, 1, 2, 2, 2, -Infinity, 1, 2, 1} | Missing["-"] | 8 | **8** | 9 | 27 | 15.663686 |
| CF68 | 5 | Chart | {-Infinity, -Infinity, -Infinity, -Infinity, 2} | 3 | 3 | **4** | 4 | 0 | 0.195168 |
| CF69 | 5 | Chart | {-Infinity, -Infinity, -Infinity, -Infinity, 2} | 3 | 3 | **4** | 4 | 0 | 0.139682 |
| CF71 | 12 | Chart | {-Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, -Infinity, 1, 1} | Missing["-"] | 6 | **6** | 6 | 6 | 13.224 |
| CF88 | 13 | Chart | {-Infinity, -Infinity, -Infinity, -Infinity, -Infinity, 2} | 6 | 5 | **6** | 7 | 4 | 74.35584 |

**The exact rule is strictly below the clamped rule on the same demands in 11 of 38 families** (CF12, CF20, CF207, CF209, CF211, CF230, CF26, CF27, CF360, CF50, CF88), normally by one weight -- which at 6-14 letters is roughly a factor 10 in word count. A coupling block carrying BOTH a deficit order and a slack order (a MIXED edge) occurs in 30 of 38 families. This corrects the 2026-08-16 night reading "no coupling of order >= 2 (no slack)", which was taken from the MINIMUM eps-order per coupling block rather than from its full Laurent support.

## Families with no per-block record, and why

The per-master half of this ledger covers all 347 masters in all 91 families. The per-block half needs the family ASSEMBLY, and that is where families are lost: the plain (v,w) entry point correctly REFUSES a class whose certified form lives in a chart (`ClassFormNotEpsForm`, `ClassFormTwoVariableChartNeedsChartTransport`) -- using such a form in the (v,w) frame would differentiate it with respect to symbols it does not contain. The chart route (v = xy, w = (1-x)(1-y)) recovers many of them; the rest carry a conic class that does not pull back to THIS chart (`ClassFormChartNotPullable`).

| family | status |
|---|---|
| CF13 | `AssemblyFailed` |
| CF18 | `ChartPullBackFailed` |
| CF226 | `ChartPullBackFailed` |
| CF23 | `ChartPullBackFailed` |
| CF232 | `ChartPullBackFailed` |
| CF236 | `AssemblyFailed` |
| CF240 | `AssemblyFailed` |
| CF248 | `ChartPullBackFailed` |
| CF253 | `ChartPullBackFailed` |
| CF254 | `AssemblyFailed` |
| CF259 | `ChartPullBackFailed` |
| CF299 | `AssemblyFailed` |
| CF303 | `AssemblyFailed` |
| CF305 | `AssemblyFailed` |
| CF319 | `ChartPullBackFailed` |
| CF321 | `ChartPullBackFailed` |
| CF408 | `ChartPullBackFailed` |
| CF413 | `AssemblyFailed` |
| CF416 | `ChartPullBackFailed` |
| CF420 | `AssemblyFailed` |
| CF53 | `ChartPullBackFailed` |
| CF56 | `AssemblyFailed` |
| CF91 | `ChartPullBackFailed` |
| CF97 | `ChartPullBackFailed` |

## Addendum 2026-08-17: the coupling assumption, measured (reviewer item)

Both 2026-08-16 reviews asked that "the couplings are dlog with constant
Laurent residues" be stated as a certificate part or measured. It is now
MEASURED per family by `Scripts/family_epsform.wls` (records in
`FamilyEpsForms/`, README there): the assembled class-form basis has
couplings that are pure dlog with constant residues in 10 of 28 measured
families and NOT in the other 18 (tau-poles up to order 3 and polynomial
parts, from eps-deformed apparent loci in the class forms' det T). Two
conditions are needed for the weight grading of this ledger to hold
exactly: (i) pure dlog with constant residues AND (ii) eps-graded (no
coupling at eps^0) -- 10 families satisfy (i) but not (ii). Where the
family eps-form has been completed and gated (16 families so far), the
family connection is eps * (constant residues) * dlog(eps-free letters)
and the grading is exact by construction. Where it has not, the
block-wise engine integrates the non-pure couplings exactly (integration
by parts over the extension) and the recursion certificate, not this
ledger's grading, is the statement of correctness; the exact per-block
depth recursion `masterTransportExactDepth` uses the FULL Laurent
support of every coupling and is therefore correct for mixed couplings.
The "+1" in the clamped jmax rule is the constants' 1/eps valuation
(measured: the class-97 block at Orders {0,0} passes the eps^0 DE check at
weight 1 and returns RegradingIncomplete at forced weight 0); the exact
per-block rule supersedes it.
