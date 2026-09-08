# Explicit singular-boundary matching, 2026-09-07

The 91 finite solutions now use **83 unknown Frobenius amplitude series**,
with **565 Laurent coefficients** actually occurring in the requested answers.
One additional amplitude is fixed by the known phase-space volume.
These count free input series and requested coefficients, not the minimum
number of new limiting integrals.

The 345 requested masters still have 2,220 requested output coefficients.
The previous ordinary-point representation required 345 unknown shared series
and 2,192 Laurent coefficients. Earlier family-local copies required 1,556
series and 8,811 coefficients.

## Construction

The closed 346-dimensional system is restricted to the normal coordinate
v=1/4, w=3/4-z. Generic-epsilon rational gauges remove two apparent poles:

- z=-epsilon/(2+2 epsilon);
- z=2 epsilon/(3+5 epsilon).

Their final residues vanish exactly. Removing the coalescing poles is necessary
before interchanging local normal-coordinate and epsilon expansions.

The full system is made Fuchsian at z=0, with the integer parts of residue
eigenvalues removed by a rational gauge. Exact generalized eigenspaces retain
their full Jordan chains. The allowed negative residue slopes have dimensions
48, 3 and 32 for slopes -2, -3 and -4. One raised-cut direction, confined to
the CF248 row, remains conservatively unexcluded. This gives 84 amplitudes
before fixing the known normalization.

An epsilon-only rescaling makes the normalized connection epsilon-regular.
Laurent-lattice saturation gives a seed matrix regular and of full column
rank at epsilon=0. Its regular left inverse is not a commuting physical
projector. Saturated columns can mix generic residue exponents. The
epsilon-zero residue has nilpotency index three; generic primary Jordan
indices do not replace this index when expanding logarithms.

## Exact finite solution

Let J_N denote the finite Frobenius counterterm transformed to the prepared
basis, and B the prepared DE matrix. Define

    D = J_N' - B J_N,
    F = J_N + E,
    E' = B E - D.

The stored coefficients are the complete proper integrals

    E[k,i](z) = integral_0^z
      (sum_{q,j} B[q,i,j](x) E[k-q,j](x) - D[k,i](x)) dx.

The epsilon-zero matrix is strictly lower triangular, so this finite
recursion terminates in epsilon order and then row order. Each error
coefficient vanishes at the endpoint. Cancellation-dependent terms of the
complete integrand must stay together.

The sufficient counterterm order is determined coefficientwise by

    N >= max(0, -g_i, p_ij - 1 - g_j),

where g_i bounds a gauge row's normal power and p_ij bounds the prepared
connection pole. Here N=5 suffices. This polynomial is only a subtraction
counterterm: the proper integrals restore all omitted kinematic dependence.
The answer is exact in the normal coordinate through its finite epsilon orders.

The full connection contained 11,159 proper integrals. After selecting required
master/point coefficients, the retained shared file has 6,757 proper integrals,
475,104 scalar kernel expressions and 114,448 algebraic expressions. These
are expression definitions, not independent boundary integrals.

All sums, epsilon convolutions, coefficients, integrands and constant
substitutions are instantiated. Reading selects and renumbers existing
expressions; it runs no DE solver, Frobenius recurrence or coefficient generator.

## Orders, normalization and maps

Inverse gauges, a regular seed left inverse and dependency paths of the
epsilon-regular connection establish conservative amplitude pole bounds.
Forward bounds determine the required ordinary-point data.

The new coordinates weaken some conservative ordinary-point bounds.
Consequently 52 families needed additional transport coefficients. These
were regenerated from existing prepared DEs on eight subkernels; the
remaining 39 reused existing coefficients.

Each family is embedded in the global basis at its own base point. The
normal points z=7/12 and z=5/12 are treated separately. The 365 master/point
labels and 2,326 derived coefficient slots are explicit expressions in the
83 input series, not additional unknowns.

The known amplitude has an epsilon^-5 coordinate factor. This changes
boundary coordinates, not the loop measure or original AMFlow normalization.

## Storage and reusable code

Results belong to
ppHX_NNLO_DoubleReal/Results/BoundaryValues/SingularMatching_2026-09-07.
Family solutions remain in the actual Stage1And2 campaign directories.

The family solutions total approximately 49.7 MB; their shared finite
boundary definitions occupy 11.1 MB. Together they occupy approximately
60.8 MB, compared with 80.4 MB previously. Reproduction inputs and the
amplitude-basis definition are separate small records.

General interfaces:

- PrepareSingularBoundarySystem: remove supported coalescing apparent poles,
  normalize the singularity, retain generalized eigenspaces and prepare
  finite integration.
- SaturateLaurentColumnBasis: choose regular retained coordinates.
- DetermineBoundaryAmplitudeOrders: establish conservative Laurent bounds.
- ConstructSingularBoundaryConnection: determine the subtraction order and
  construct the explicit finite connection.
- ExtendMasterIntegralSolutionForBoundaryBounds: extend affected orders.
- ExpressFamilyBoundaryConstantsInGlobalBasis: form exact same-point maps.
- ConstructSharedBoundaryCoefficientDefinitions and
  ApplySharedBoundaryCoefficientDefinitions: store finite substitutions.

The general driver is Scripts/Boundary/match_singular_boundaries.wls.
It accepts physical subspace, normalization, path and known amplitudes as
mathematical inputs. It contains no process or family selection and does
not infer a physical scaling theorem from a process name.

## Verification and numerical limitation

- All 91 resolved files pass finite-format and coefficient-requirement checks.
- 144 exact rational residual samples check every retained Frobenius column
  through z^5 and the required epsilon orders, at two rational values of
  the formal logarithm. These are sampled checks, not a generic polynomial
  identity proof in the logarithm.
- Independent logarithm/dilogarithm examples check sourced Jordan blocks,
  cutoff independence and finite residual integration.
- Tests cover coalescing poles, saturation, gauge composition, order planning,
  dependency renumbering and the standalone reader.
- Three Pro consultations reviewed endpoint mathematics, Laurent bounds
  and numerical treatment.

**Direct unweighted endpoint collocation is not validated for this connection.**
A CF123 test with nonzero artificial amplitude coefficients failed refinement
even at 250-digit arithmetic. Its interpolants do not preserve the higher
vanishing powers required by the high-pole prepared connection. More precision
does not repair that approximation space.

The remaining numerical interface is a convergent local Frobenius expansion
that initializes every cumulative remainder at an ordinary point on the
contour, followed by ordinary continuation. The small remainder should be
evaluated as a tail directly, not by subtracting two large values. Numerical
truncation, panel/interpolation and arithmetic errors need separate control.
This changes numerical evaluation, not the exact stored answer. A simple
endpoint-power weight alone is insufficient when logarithms and
cancellation-dependent leading terms occur.

The prescribed upper complex contour is
z*(t^8+i*t^8*(1-t^8)/4), with stated continuation of principal branches.
Its identification with the physical Feynman prescription has not been
independently established. Physical amplitude values, limiting-integral
reduction and a nonzero physical AMFlow comparison were open at this point.
The subsequent physical boundary evaluation fixed all stored constants and
CF198 passed the corrected AMFlow comparison through epsilon^1; see
PhysicalBoundaryResults_2026-09-07.md.
No claim of complete numerical or physical stage 3 is made.
