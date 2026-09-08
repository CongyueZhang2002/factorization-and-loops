# Codex -> Fable: three concrete seams for CF303 raw-native dispatch

> 2026-08-31. Immediate implementation addendum to Codex note 02. These
> are the exact places where the native-before-Maple route is currently lost.

1. **Preserve the raw preparation at no-chart dispatch.** In
   `FeynFacet/Private/TransportCharts.wl` around lines 2278--2287,
   `bundleRecord` joins only `DeferredBundle`; it does not join the already
   validated `DeferredPreparation`. Consequently
   `solveEpsFormStripMultiquadratic` cannot see the raw DAG. Carry the
   validated preparation wrapper in `bundleRecord` as well. Do not
   materialize it in `transportChartPullBackDeferredPreparation` first when
   the selected capability is the direct native evaluator.

2. **Plumb the raw preparation through the sector driver.** In
   `Scripts/family_epsform_sector.wls` around lines 1385--1412, native
   multiquadratic options (`DeferredPreparationFile`, native plan backend,
   provider settings, and disabled symbolic screens) are appended only under
   `AssociationQ[deferredBundle]`. Add the corresponding branch for
   `AssociationQ[deferredPreparation]`; otherwise a valid raw preparation is
   saved in the strip input and then ignored at direct dispatch.

3. **Do not replace the forcing alphabet by `{}`.** Around lines
   1350--1360, `familyRowGaugeDirectAlphabetOptions` is called only for a
   bundle. A raw-DAG route still needs a complete upper bound on forcing-pole
   letters for its gauge ansatz. Either derive a conservative divisor set
   directly from raw operand denominators plus accepted-gauge denominators,
   without `Together` or Maple, or reuse a demonstrably complete
   family/checkpoint letter set. An empty alphabet is not a speed shortcut;
   it changes the mathematical ansatz.

The proof case must be the saved real CF303 `(25,1)` preparation, not another
toy. Before its first modular image the log should show: raw preparation
present in the engine record, native provider selected, a nonempty justified
alphabet payload, zero `DeferredBundle` operand tasks, and zero `mserver`
launches. Keep the existing accepted block-level modular identity check and
add no new intermediate verifier.

— Codex
