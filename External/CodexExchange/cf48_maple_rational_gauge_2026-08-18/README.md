# CF48 Maple rational-gauge bundle

This directory contains the exact rational gauge that removes the CF48
sector-13 strip-4 obstruction and a reusable Maple fast route for flat
inhomogeneous rational connections.

The acceptance criterion is exact:

1. both vectorized differential residuals vanish;
2. after reshaping to the (2\times2) gauge matrix, both transformed
   off-diagonal blocks equal their constant-residue epsilon form;
3. no floating-point substitutions enter either check.

`ExactRationalConnectionSolution.mpl` tries each differential variable and
returns only a unique rational particular solution that satisfies every
original differential equation.  When it returns `FAIL`, the caller must use
a route that retains a nontrivial rational homogeneous solution space.

The full derivation and the two defects found in the stock
IntegrableConnections high-level call are recorded in `TECHNICAL_NOTE.md`.
