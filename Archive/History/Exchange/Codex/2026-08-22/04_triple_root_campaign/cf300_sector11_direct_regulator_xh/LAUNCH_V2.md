# CF300 sector-11 direct regulator continuation V2

All paths and hashes below are frozen.  V2 has not been launched.

## Sources

```text
driver:
  /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_sector11_direct_regulator_xh/run_cf300_sector11_direct_scalar_regulator_continuation_v2.wls
  SHA256 73a3c23c2a68ebc3ec3196b2bba29cbee1be3c6bf4601d0622126d84fb4576f8

formal inspector:
  /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_sector11_direct_regulator_xh/inspect_cf300_sector11_regulator_structure_v2.py
  SHA256 036d15b1735efd30a0b0f1049559b7f61c84edc662a94d3eae806953589944c3

static source audit:
  /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_sector11_direct_regulator_xh/test_cf300_sector11_direct_regulator_v2_static.py
  SHA256 2a21165856ca305cfa1464efccd83cb91422b4b558676d3cf1df9470f6acb02f

input state:
  /home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/FamilyEpsFormsSolving/triple_root_2026-08-23/CF300/sector_state_CF300_standard.wl
  bytes 33012365
  SHA256 898e4283c39fcdb457b7857a4609e48b5ca0417b1d06cb07750779b187c33a12
```

## No-kernel preflight

```bash
python3 /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_sector11_direct_regulator_xh/inspect_cf300_sector11_regulator_structure_v2.py
python3 /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_sector11_direct_regulator_xh/test_cf300_sector11_direct_regulator_v2_static.py
```

Expected terminal lines:

```text
CF300_SECTOR11_REGULATOR_STATIC PASS
CF300_SECTOR11_DIRECT_REGULATOR_V2_STATIC PASS 104/104
```

## Central kernel launch

Use one clean main kernel and zero subkernels.  The target directory must
already exist and both target files plus their `.tmp` siblings must be absent.
Do not use the original production directory as the target.

```bash
wolframscript -file \
  /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_sector11_direct_regulator_xh/run_cf300_sector11_direct_scalar_regulator_continuation_v2.wls \
  /home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/FamilyEpsFormsSolving/triple_root_2026-08-23/CF300/sector_state_CF300_standard.wl \
  <candidate-directory>/sector_state_CF300_standard.wl \
  <candidate-directory>/cf300_sector11_direct_regulator_report_v2.wl
```

The positional arguments are exactly:

```text
<pinned-input-state.wl> <absent-output-state.wl> <absent-report.wl>
```

Expected success conditions are exit 0, `CF300_S11_DIRECT_REGULATOR PASS`,
an output SHA-256, and cleanup diagnostics with both booleans true.  A silent
state `Get` is mandatory; any hydration message fails closed.  The driver is
bounded to 900 seconds, never rehydrates the written 33 MB state, and does not
load FACET or launch workers.

Before resume, run a separate post-write hydration/seal validator on the
candidate.  That validator is intentionally a separate mission so the writer
does not retain a second hydrated 33 MB state.

## Resume after post-write validation

Use the candidate directory itself as the new output directory.  Run on a
clean main kernel, never the irreversibly Locked/poisoned kernel 144.

```bash
FACET_CHECK_LEVEL=Production \
FACET_STRIP_ROUTE=FiniteFieldFirst \
FACET_KERNEL_COUNT=8 \
wolframscript -file \
  /home/maxzhang/factorization-and-loops/Scripts/family_epsform_sector.wls \
  CF300 <candidate-directory> 7200 standard 30
```

The resumed script should load sector 11 and start sector 12.  Its
pre-sector-12 `factorTruncated[11]` call should be an immediate no-op because
the 22-master prefix is epsilon-form.  Completion still requires the separate
exact family certificate.
