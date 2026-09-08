# CF259 transport inputs (copied 2026-09-02 03:45 from the Codex tree at takeover)

Provenance (all produced by Codex on 2026-09-01/02 with the branch
`codex/day-rank3-validation`, tip fc6792f7):

- family_epsform_CF259.wl (471 MB): family eps-form assembled from the
  completed row checkpoint `../sector_CF259_standard/CF259_27_strip_state.wl`
  by `Scripts/family_epsform_sector.wls` (Codex tree,
  Runtime/2026-09-01_observable_transport_triple_final/cf259_assemble/).
  Status "CandidateEpsilonForm"; expanded matrices EpsFormX/EpsFormY.
- dlog_residues_CF259.wl / cf259_dlog_residues_native.wl: constant-residue
  dlog decomposition of the eps-form connection computed natively
  (13 CRT primes + fresh prime 2147482943; the two files differ only in
  Backend/Seconds fields; see NATIVE_DLOG_END_TO_END.md).
- sidecar.wl: FamilyDLogComputationSidecarV1 (letters, roots, dimension 47).
- family_epsform_CF259_compact.wl (47 MB): the assembly with expanded
  matrices replaced by the dlog representation
  (`compact_family_dlog_record.wls`), status TransportReadyEpsilonConnection,
  EpsFormRepresentation ConstantResidueDLog.  Built 2026-09-02 00:23
  WITHOUT the transport epsilon valuations.
- cf259_transport_epsilon_valuations.wl: TMin -3, per-block lower
  valuations, method ExactAlgebraicPointValuation (Codex, 02:31).
- cf259_transport_card.wl: path data (x,y base 14/45, 11/90; target sample
  13/45) with all three radicals rational and nonzero at the base.

None of these is an accepted transport result.  The transport of CF259
had not been run to completion when the overhaul took over.
