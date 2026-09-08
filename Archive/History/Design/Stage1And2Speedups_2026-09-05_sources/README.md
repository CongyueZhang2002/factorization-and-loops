# Measurement sources

The before/ directory contains pre-change functions for these comparisons,
not alternative production implementations. The package loader never reads
this directory. The benchmark reloads explicitly select the private context.

The complete saved-input stage-2 comparisons use the same Data, Request and
Options records. Only CF48 and CF303 have matched pre-change timings in this
record; the other three families have fresh successful post-change timings.

Use the commands and interpretation in ../Stage1And2Speedups_2026-09-05.md.
The current compact solutions are under
../../ppHX_NNLO_DoubleReal/Results/RequestedMasterIntegralSolutions.
