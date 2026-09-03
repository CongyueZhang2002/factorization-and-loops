# Physical boundary-mode campaign

`build_boundary_mode_campaign.wls` constructs the exact local canonical
modes that replace regular-interior automaton constants by physical boundary
periods.  It is intentionally a process campaign outside `FeynFacet/Private`:
the reusable Frobenius and mode algorithms remain in
`Private/Transport/Boundary/PhysicalBoundary.wl`.

The campaign reads the 20 current period certificates, joins each period's
class to `BlockClasses/block_class_assign.wl`, and thereby recovers all 55
family/row realizations unambiguously.  It never reads the independently
deduplicated `Families` and `BlockRows` arrays positionally.

Every current period admits a rational physical edge point whose normal
coordinate is the second coordinate of its accepted transport chart.  The
chosen chart-level edge prescriptions are shared across families.  Mode
records are realization-local (`{family, ledgerPeriodID}`) unless an exact
transfer is separately supplied; the known-zero classes 1, 6 and 7 are
recorded without identifying any unevaluated realization.

Run, for example:

```text
Scripts/seat_run.sh 900 wolframscript -file \
  Scripts/Transport/PhysicalBoundary/build_boundary_mode_campaign.wls \
  ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/PhysicalBoundaryModes
```

Family names after the output directory restrict the campaign.  A family is
refused until its accepted observable transport exists, because the endpoint
mode must use the same gauge-constant binding as that transport.
