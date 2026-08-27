# CF300 sector 11 V4 post-write validator V2

V1 is preserved as terminal evidence.  It failed closed at exit 67 on pool
kernel 24 before hydration because `RunProcess` did not return an Association in
that worker environment.  Cleanup was exact and no production artifact changed;
the frozen log is `cf300_s11_postwrite_validator_xh_v1_FAILED.log`.

V2 removes all subprocess use.  The exact-text Python formal inspector was run
centrally against the pinned input/output files, its single canonical JSON result
was frozen with SHA-256
`18dbe8754e2feffa58e022dd582e5910f5cea6b5f6af3595d01dda7993a40128`,
and V2 accepts that result only as an exact fourth argument.  V2 pins the JSON,
the inspector source, V4 driver, input, output, and report independently, imports
the JSON through `RawJSON`, requires silent telemetry, and rechecks all semantic
fields before performing the original exact Wolfram hydration, gauge, inverse,
and seal validations.

First run the no-argument read-only pool probe
`probe_cf300_postwrite_formal_result_import_v1.wls`.  It verifies that this pool
subkernel can import the pinned JSON without messages, subprocesses, nested
kernels, or writes.  This probe passed centrally on clean pool kernel 24 with
zero nested kernels, `Association` result, no messages, and normal pool status
in 0.0555 seconds; the frozen pool log is
`cf300_postwrite_formal_import_probe_xh_v1_OK.log`.  Launch V2 with one main and
zero helpers, passing:

1. `/home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/FamilyEpsFormsSolving/triple_root_2026-08-23/CF300/sector_state_CF300_standard.wl`
2. `/home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/FamilyEpsFormsSolving/triple_root_2026-08-23/CF300_direct_regulator_v4_candidate/sector_state_CF300_standard.wl`
3. `/home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/FamilyEpsFormsSolving/triple_root_2026-08-23/CF300_direct_regulator_v4_candidate/cf300_sector11_direct_regulator_report_v4.wl`
4. `/home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_sector11_direct_regulator_xh/cf300_sector11_postwrite_formal_inspector_v4_result.json`

Validator:
`/home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_sector11_direct_regulator_xh/validate_cf300_sector11_direct_regulator_v4_postwrite_v2.wls`
