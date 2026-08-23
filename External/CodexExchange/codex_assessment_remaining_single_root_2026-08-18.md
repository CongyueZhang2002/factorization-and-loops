# Assessment of the four remaining root-free/single-root families

Codex, 2026-08-18.

## Short conclusion

The count `69 of 73` is consistent with the current production records, but
the four families are not in the same state.

- The CF26/CF33 diagnosis is correct: the differential transport is fast;
  expanding the solved boundary-constant relations through a very large
  word-valued solution is the bottleneck.
- The CF299/CF407 description is stale. Their exact observable-only
  two-segment transport has already been constructed and checked. What is
  absent is its integration into the common FeynFacet result schema. Their
  relevant endpoint modes have also been matched; the remaining analytic
  quantities are four boundary periods.

Consequently, none of the four requires another full blockwise-transport run.

## CF26 and CF33

The current CF26 probe gives direct timing and size evidence:

1. Blockwise transport and its recursion certificates finished in 177 s.
2. The forbidden physical Laurent orders were formed in 1.2 s.
3. The code extracted 392 linear equations and solved them in 0.8 s.
4. It then began applying 25 constant rules to nine epsilon orders occupying
   136,167,224 bytes and made no further logged progress during the next
   several minutes.

This is exactly the expensive line in `masterTransportValuation`:

```wl
Map[Together[# /. rules] &, solution["F"]]
```

The same operation is still present in the sparse-word-map route in
`sweep_transport.wls`; that route forms the valuation equations more cheaply
but then expands the rules through the complete expression again.

The appropriate exact representation is

\[
  F=\sum_w w\,C_w c,
\]

where \(w\) is a Chen word, \(c\) is the vector of integration constants,
and \(C_w\) is a rational matrix. If the valuation equations give

\[
  c=N b,
\]

the constrained result is obtained by the small matrix products

\[
  C_w\longmapsto C_w N.
\]

No replacement through a 136 MB scalar expression and no whole-expression
`Together` is required. This is the same linear-algebra principle used by the
pre-transport valuation construction.

One qualification is needed: the existing `PreTransportValuation_CF26.json`
and `PreTransportValuation_CF33.json` contain the rank census, not the exact
Wolfram kernel matrices and not a package implementation. Thus the proposed
fix is mathematically identified, but it has not yet been integrated for
these two families.

## CF299 and CF407

The full-column blockwise calculation does show the stated word growth near
block 8 of 17, and the epsilon-depth explanation is consistent with the
stored timing records. However, that calculation is no longer the route that
should be used.

The exact observable-only construction already contains:

- the Laurent-valuation kernels over \(\mathbb Q(z_1,z_2)\);
- the induced spectator differential systems;
- complete two-segment sparse word maps;
- exact recurrence and induced-subspace identities;
- an independent exact comparison with the completed CF27 transport.

Measured records are:

| Family | Two-segment maps | Result above weight three |
|---|---:|---|
| CF299 | 249 | every requested physical map at weights four and five is zero |
| CF407 | 1187 | the constrained state is zero from weight four onward |

For CF27, all six symbolic differences for two requested masters through
\(\epsilon^2\) are exactly zero. Therefore the statement that CF27 validation
is still pending is false.

Endpoint matching has also been constructed for the modes entering these
maps. The remaining analytic inputs are

\[
  B_8(\epsilon),\quad B_9(\epsilon),\quad
  B_{25}(\epsilon),\quad B_{23}(\epsilon).
\]

These are boundary periods, not a transport obstruction. Once they are
evaluated, their substitution produces every requested physical master
without rerunning transport.

The accurate status is therefore:

- analytic observable transport: complete in the isolated Codex records;
- endpoint-mode matching: complete for the relevant modes;
- integration into FeynFacet's common artifact schema: not done;
- four boundary periods: not yet evaluated.

## Counting convention

The current directory contains 88 family status records:

- 69 marked `Transported`;
- 16 marked `Failed`;
- 3 marked `ChartNotCovered`.

The root-free/single-root subset has 73 families, so `69 of 73` is a correct
count of production transport records. It must not be read as 69 fully
evaluated master families: transport, endpoint matching, and boundary-period
evaluation are separate mathematical stages.

## Recommended order

1. Implement matrix-valued word coefficients and pre-transport valuation for
   CF26/CF33, then write their ordinary production records.
2. Convert the existing CF299/CF407 observable maps and endpoint substitutions
   into the same production schema; do not repeat the full 17-block word
   closure.
3. Track three separate statements for every family: transported map known,
   endpoint modes matched, and boundary periods evaluated.
