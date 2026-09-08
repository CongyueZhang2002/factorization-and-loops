# Codex -> Fable: current three-root slowdown and recovery work

Date: 2026-08-28 22:20 PDT  
Current HEAD: `75412bf`  
Status: campaign stopped cleanly; no family, Wolfram, FLINT, or Maple campaign job is running

Fable, this note records the physical bottlenecks from the last clean
three-family run.  The triple-root finite-field method did solve the two hard
off-diagonal systems.  The current block is downstream symbolic normalization,
plus one avoidable row-propagation normalization in CF259.

## 1. Measured slowdown, with numbers

### CF259: duplicate normalization after the strips were already solved

- Sector 21 resumed 9 checked strips and completed all 20 individually checked
  strips in about 257 s.
- The family then spent roughly 21 minutes in row-gauge propagation before the
  mission was stopped at 1531.9 s total.
- Sampling, modular solving, per-off-diagonal checking, and the new chart-first
  construction were not the bottleneck.  The hot expression was the entrywise
  `Together` of a multi-term `SInverse` update in `familyRowGaugeApply`.
- That same expression is immediately passed into the regulator
  factorization/canonicalization path.  The current candidate patch therefore
  preserves the exact raw sum and performs one canonicalization at its actual
  consumer instead of two consecutive canonicalizations.  The focused row
  gauge suite is 38/0.  This has not yet been re-profiled on CF259, so it is a
  measured diagnosis plus a tested candidate fix, not yet a claimed physical
  speedup.

Relevant code: `FeynFacet/Private/FamilyRowGauge.wl` around the
`DeferredNormalizationEntries` accounting.

### CF300 `(12,6)` and CF303 `(21,12)`: the finite-field solve succeeded

Both blocks reduced to the same Kallen23 rational-chart problem:

- deferred chart materialization: 121.1 s (CF300), 128.1 s (CF303);
- full support: 820 monomials / 6680 unknowns;
- first plan: rank 6672, nullity 8;
- learned support: 620/820, final rank 5080, nullity 0;
- support learning: 74.2 s (CF300), 73.8 s (CF303);
- five primes were required; each post-pilot prime took about 121--126 s with
  two pool helpers;
- exact unseen-prime residual at 2147483399: zero for both;
- complete inner solve: 1001.4 s (CF300), 1024.3 s (CF303).

The FLINT native RREF plan used three native cores and removed the earlier
20-plus-minute Wolfram plan bottleneck.  The remaining finite-field time is
mostly expression sampling, not elimination.

### The actual blocker: duplicated Maple canonicalization

After solving, both families entered canonicalization of a 2x4 gauge with
leaf count 332,578.  Their generated Maple payloads are byte-identical through
offset 2,621,208; the first difference is only the family-specific output path.
Nevertheless, two independent Maple jobs recomputed the same eight entries.

Each job used about 8--9 GiB RSS and roughly 2.3--2.5 CPU cores.  After about
18 minutes, each had completed only entry 1 of 8 and had begun entry 2.  At
that rate neither could finish the array within the 1800 s process limit.  We
stopped both around 20 minutes rather than spend another duplicated hour or
more.  The partial `.out` files contain one complete entry, and the original
`.mpl` inputs remain.

Thus the present hierarchy is:

1. Maple `evala(Normal)` of the pulled-back multiquadratic gauge is the dominant
   wall-time and memory bottleneck.
2. CF259's duplicate `SInverse` `Together` is the second concrete bottleneck.
3. The hard triple-root finite-field solve itself is functioning and is no
   longer the blocker.

Evidence:

- campaign logs:
  `factorization-and-loops-codex/Runtime/2026-08-28_triple_root_chart_first_campaign_v3_native/logs/fresh_sol_CF{259,300,303}.log`;
- retained family outputs:
  `ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/FamilyEpsFormsSolving/triple_root_2026-08-28_codex_clean`.

## 2. Recovery work currently in the uncommitted tree

The working tree contains a candidate response, not a production-approved
relaunch point:

1. `EpsFormStrip.wl` canonicalizes an array entry by entry, stores successful
   normal forms in a shared content cache, and coordinates identical entries
   with `flock`.  This lets CF300 and CF303 compute the common 2x4 gauge once,
   and makes completed entries resumable.
2. `TransportCharts.wl` and `family_epsform_sector.wls` pass a general shared
   cache directory and the actual sector Maple budget on the finite-field
   route.  The latter was previously omitted on that call, so the default
   1800 s was silently used.
3. `FiniteFieldStripSolve.wl` admits reuse of existing prime artifacts across
   volatile row-basis, nonce, transcript, and thread changes when the
   mathematical affine section is unchanged.  Five good prime records for
   each hard block remain on disk.
4. The CF259 `SInverse` path defers the redundant first `Together`, as described
   above.

Focused tests presently pass:

- family row gauge 38/0;
- affine native-backend/artifact tests 33/0;
- KallenQ4 chart tests 60/0;
- Maple entry cache and bounded partial-resume fake-runner cases all pass.

I am deliberately not adding another production acceptance layer.  The
existing per-off-diagonal block check after Maple simplification remains the
production check requested by the user.

## 3. Items that must be settled before relaunch

Please review these as algorithm/contract questions, not as requests for more
hashes or redundant verification:

1. **Best normalization object.**  Is generic Maple `evala(Normal)` necessary
   here, or should a pulled-back expression already known to lie in
   `Q(x,y)[r1,r2]/(r1^2-d1,r2^2-d2)` be reduced coefficient-wise in the four
   element basis `{1,r1,r2,r1 r2}` and have only its rational coefficients
   normalized?  This is the potential major speedup; cache sharing only avoids
   duplicate work.
2. **Cache contract.**  Content sharing between families is mathematically
   natural because the two Maple input expressions are identical, but the
   experimental legacy combined-output salvage and cross-process replacement
   logic should remain out of production unless it can be made both simple and
   unambiguous.  My current preference is to keep future per-entry caching and
   remove clever legacy migration if it complicates the contract.
3. **Deadline semantics.**  The per-entry Maple call should consume only the
   remaining outer block budget and translate a timeout into the existing
   resumable budget result.  The current candidate still needs this tightening.
4. **Artifact identity.**  Reuse must include the mathematical coordinate
   layout/support and affine normalization columns, while excluding only
   execution details such as row basis, nonce, transcript, and helper count.
   Rank plus normalization columns alone is too weak if a support layout
   changes.
5. **CF259 deferral.**  Please flag any consumer that observes the intermediate
   uncanonicalized `SInverse` rather than the immediately following regulator
   factorization.  I found none, and the focused suite is green.

I am also sending this exact profile and the normalization question to the
existing ChatGPT Pro conversation, **Assess Multiquadratic Pipeline**.  I will
not relaunch the three families until the candidate is simplified around the
answers and its focused gates are rerun.

— Codex
