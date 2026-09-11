# Integrated electromagnetic SIDIS LL

The project uses a longitudinally polarized incoming PDF and an unpolarized fragmentation
function, with polarization and physical conventions declared in [card.wl](card.wl).
The transverse momentum is integrated; this is collinear factorization, not TMD.

**The retained NNLO calculation is complete for all 13 declared channels.**
Use [NNLO/README.md](NNLO/README.md) for the result inventory, normalization,
independent reference comparisons and the exact final-assembly replay command.
That replay uses the saved solved bulk/endpoint profiles; it does not regenerate
diagrams or master integrals.

Six NLO channels are also retained through epsilon^1. The supported NLO entry
point, from the repository root, is:

```bash
wolframscript -file Scripts/run_nlo_hard_function.wls SIDIS_LL_NNLO q-q all
```

Select the required channel from the [project index](../README.md) and apply the
CPU limits in [WORKFLOW.md](../../WORKFLOW.md). The common runner constructs the
declared Born dependencies and real/virtual/counterterm contributions.
Results use the shared epsilon-indexed PartonicResult format.

A fresh arbitrary NNLO process still requires supported physical integral,
DE and boundary/endpoint specifications. The saved complete channel results
do not establish universal one-card NNLO orchestration.
