# CF303: adversarial review of the portable exact solution representation

We found a gap while converting the accepted CF303 construction into the new
`MasterIntegralSolution` data model. Please review the mathematical
completeness of the proposed repair, not its software style.

The 43-master source is an epsilon-linear GPL/eMPL Chen operator. The final
two rows obey

\[
F_{25}=G_{25}+H L,\qquad I_{25}=T_{25}F_{25},
\]

and their words contain at most one incoming transition. The accepted exact
definition of the difficult final layer is a finite arithmetic/Hermite DAG
over exact input one-forms, with `H(1/2)=0`. It is evaluated efficiently after
finite-field specialization. The global expanded rational functions are
pathological, but the exact DAG, its input expressions, and all operations are
finite and deterministic. The tangential boundary evolution is a separate
sequence-indexed operator `U(p,p0)` for the 13 boundary functions.

The first V2 projection was wrong: it discarded the only definitions of 112
inert H nodes and 180 deferred one-forms reachable on the four resonant source
modes. We have stopped that promotion.

Proposed repair:

1. Make the normal boundary-to-bulk coefficient factor portable by retaining
   the exact DAG, exact one-form inputs, all kernel definitions, and the
   normalization/branch conventions in repository-relative ancillary data.
   Modular images are validation evidence only, not the mathematical object.
2. Store the final solution as the ordered product of two sparse
   sequence-indexed coefficient operators: the normal boundary-to-bulk factor
   and the tangential base-point-to-boundary factor. Do not form the enormous
   Cartesian product of their letter sequences and do not claim it is one
   iterated integral on a concatenated path.
3. Give every path segment, alphabet/kernel definition, epsilon-order map,
   demand row, boundary-constant coordinate, and multiplication convention
   explicitly. Derive the Stage-3 boundary-constant worklist by sparse
   dependency reachability.
4. Call the resulting terminal record a `MasterIntegralSolution` with complete
   demand coverage and undetermined boundary constants. It is distinct from
   a physical-region solution, which additionally requires those constants
   and analytic continuation data.

Questions:

- Is an exact arithmetic/Hermite DAG over explicit rational/algebraic
  one-forms a mathematically complete exact coefficient representation for a
  publishable ancillary master-integral solution, even when its expanded
  rational functions are not printed?
- Is the factorized product of path-segment Chen/MPL/eMPL coefficient
  operators a complete solution representation, provided composition order
  and path orientation are explicit, or must Chen deconcatenation be expanded?
- What is the minimal acceptance needed to establish equivalence to the
  original differential equation and regularized boundary asymptotics without
  adding redundant layers of checks?
- Which omissions would still make this only an intermediate construction
  rather than a master-integral solution ready for boundary-constant
  determination?

Please be adversarial and use standard differential-equation/amplitude
terminology.
