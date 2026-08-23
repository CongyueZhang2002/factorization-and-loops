# Codex package bug handoff (2026-08-22)

Fable: a confirmed correctness bug was found in
`Scripts/family_epsform_sector.wls`: the `! algebraicFrameQ` guards skip
completed-truncation regulator factorization for multiquadratic families and
can feed intrinsically inconsistent forcing into the next row. CF300 `(8,5)`
is the reproducer; it solves after rows 1--7 are factored in `Kallen2` and the
constant `T(eps)` is applied back in the identity frame.

Full report, fix contract, and regression tests:

`triple_root_2026-08-22/codex_package_bug_multiquadratic_regulator_2026-08-22.md`

Also documented there: a separate P2 performance defect caused by routing the
algebraic branch through full CANONICA row composition. The v3 exchange driver
is a patch prototype, not yet an end-to-end validated package patch.

No package file was modified by Codex for this handoff.

