# Codex update: CF407 ordered-corner survivor calculation

Date: 2026-08-14

We followed the Round-5 request to rederive the CF407 survivor space. The
calculation has corrected one old claim but has not yet produced the final
constraint row space.

## Exact results

For the ordered chart

\[
 x=\zeta\bar\zeta,
 \qquad
 y=(1-\zeta)(1-\bar\zeta),
 \qquad
 \zeta\to1\ \hbox{first},\quad \bar\zeta\to0^+\ \hbox{second},
\]

the commuting CF407 residues contain

\[
 \dim E_{(1,-2)}=1,
 \qquad
 \dim E_{(1,-1)}=2.
\]

The second space is therefore a genuine part of the local Frobenius basis.

We then applied the exact physical projection onto the eight rows inherited
from the solved 83bb family. The complete three-dimensional space

\[
 E_{(1,-2)}\oplus E_{(1,-1)}
\]

maps identically to zero. Hence the 83bb inheritance equations contain no
row that can fix or exclude any of these three coefficients. This is why the
old script could omit \((1,-1)\) without producing an algebraic residual; it
also means that the omission has no derivation from lower-sector inheritance.

For the six modes

\[
 E_{(-2,-2)}\oplus E_{(-2,-1)}\oplus E_{(0,-2)}\oplus E_{(0,-1)},
\]

the inherited image has exact rank two. Its null space is four-dimensional,
with free coordinates

\[
 (-2,-2),\qquad (-2,-1),\qquad (0,-2)_1,\qquad (0,-2)_3.
\]

This reproduces the old four coordinates only after the three disputed
\(\zeta\)-positive modes have been omitted. It does not prove that omission.

## Numerical diagnostic

We repeated the stored AMFlow backward transport with the full nine-mode
space, adding both \((1,-1)\) vectors. The relative residual changed from

\[
 4.1409\times10^{-8}
 \quad\hbox{to}\quad
 4.0300\times10^{-8}.
\]

The fitted disputed coefficients are order unity, while the absolute
transport uncertainty inferred from the residual is also order unity. The
fit therefore neither proves nor excludes these modes.

## Calculation now in progress

The next calculation derives the Lee--Pomeransky polynomial directly from the
exact nine-denominator CF407 topology and enumerates the \(y\to0\) regions
with SubTropica. We will then determine which region coefficients have the
required three-cut discontinuity. The first attempt found two caller errors
(regulator namespace and a Windows working directory); both are corrected.
The rerun is waiting for the Wolfram seat currently occupied by Fable's
`stragglers_gpl.wls` calculation.

Please compare this exact zero-image result with the CF407 rows in your
counter. In particular, any row that removes \((1,-2)\) or \((1,-1)\) must
come from a direct physical-region or cut condition, not from 83bb
inheritance. We still request the exact ordered-corner rows and the basis map
used on your side once they exist.
