# V6f adversarial runtime plan (prepared only; not executed)

Run in a fresh isolated V6f mission after held parse and source-hash freeze.
Every mutation below must fail before downstream sampling:

1. Change one exact channel leaf but keep its stored channel fingerprint.
2. Change one canonical numerator/denominator pair by a common factor, sign, or
   noncanonical expansion.
3. Force two unequal canonical pairs to share a fingerprint key.
4. Change a record one-form, forcing index, provenance count, or provenance.
5. Delete, duplicate, reorder, or swap record leaf seals in the handle.
6. Change the Merkle root, result fingerprint, target ABI, bridge ID, or compact
   bridge fingerprint.
7. Change the exact or compiled suffix in the immediate legacy result.
8. Pass a stale/deserialized legacy result instead of the immediate frozen-V6
   return; the promoted driver must structurally make this impossible and its
   static gate must reject any artifact-read path into the bridge builder.
9. Change any pinned source file after bridge creation; warm resolution fails.
10. Release the bridge, then resolve; resolution fails.  Releasing twice fails.
11. Construct a rational mutant selected to agree at all finite-field screen
    points; the screen may pass, but the exact channel/pair/oracle bridge fails.
12. Make the optional finite-field screen error or return indeterminate; the
    driver either proceeds to all exact gates or fails closed, never accepts.
13. Search helper and driver text for `TimeConstrained`, timeout catch/accept,
    validator fallback acceptance, kernel launch, or positive finite-field
    acceptance.  Any occurrence blocks promotion.
14. Verify the full driver never hands `screenAssembly` to public
    `DRCAAssembleSample` after bridge acceptance.  Attempt to forge a validated
    fingerprint with a mutated caller assembly; the bridge-owned sampling API
    must make this call shape impossible and must reject unknown/released
    handles and source drift.

Positive fixture requirements: bridge result is literally the semantic frozen
V6 result; CF300 counts are 72 records, 576 raw leaves, 336 unique compiled
leaves; all four downstream image ranks, accepted-point fingerprints, stable
plans, and the exact-lift prerequisite are identical to the frozen V6d gate.
