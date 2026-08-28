# CF300 `(12,9)` aligned-Schur and quotient diagnostics

These files are an experimental, source-matched finite-field campaign for the
triple-root CF300 `(12,9)` off-diagonal block. They are intentionally kept out
of `FeynFacet/Private`: no family-specific dispatch has been added to the
package.

## What is reusable

- `flint_schur_reduce.c` eliminates a full-rank gauge core with multiple
  right-hand sides and returns the reduced residue Schur system.
- `flint_homogeneous_nullspace.c` computes only rank and a homogeneous
  nullspace. It omits the large inverse witnesses emitted by the production
  affine-plan protocol; this is appropriate for bounded diagnostics whose
  candidates are checked on disjoint fibres.
- `sample_aligned_schur_p31.wls` pins one accepted kinematic point set across
  regulator images and compares raw and known-denominator-scaled Schur data.
- `resume_aligned_schur_p31_to76.wls` appends new images to a checkpoint; it
  does not restart the first 42 images.
- `solve_reduced_residue_module_p31_degree64.wls` factors the 36-dimensional
  common residue kernel, isolates the 16-dimensional moving quotient, and
  binary-searches a common polynomial numerator/denominator bound with the
  narrow FLINT adapter.
- The two `test_*quotient*` scripts are adversarial discriminators for scalar
  projectivization and fixed-common-kernel normalization.

## Physical result recorded on 2026-08-28

After excluding one stale epsilon=1 pilot, 75 source-matched fibres agree
between independent affine and Schur routes. The quotient has dimensions
`160 x 17`. Exact homogeneous systems are full column rank through degree 64;
the degree-64 system is `11520 x 11505` with rank `11505`. Therefore no common
polynomial representative of uniform numerator/denominator degree at most 64
exists in that quotient frame.

The degree-64 native test took 41.3 seconds with eight FLINT threads. This
closes pointwise affine-section repair as the next route. The next experiment
must work with the original aligned equations after clearing their known row
denominators, before the 2,048- and 160-dimensional eliminations create large
determinant minors.

## Build

Both C files require the pinned 64-bit FLINT 3.0.1 installation used by the
package. Example:

```sh
gcc -O3 -DNDEBUG -std=c11 -Wall -Wextra -Werror \
  -I/usr/local/include SOURCE.c -L/usr/local/lib \
  -Wl,-rpath,/usr/local/lib -lflint -lgmp -lmpfr -lpthread -lm \
  -o OUTPUT
```

The WLS files refer to runtime captures under
`/home/maxzhang/factorization-and-loops-codex/Runtime`; those WXF artifacts and
compiled binaries are deliberately not committed.
