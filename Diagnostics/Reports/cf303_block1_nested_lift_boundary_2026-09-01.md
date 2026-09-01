# CF303 (25,1): exact-lift boundary and Laurent-first result

## Result

The six accepted 61-bit images do not determine the expanded nested
`p/epsilon` coefficients over `Q`.  This is a coefficient-height issue, not a
finite-field, interpolation, section, or validation failure.

- Targeted q3, q4, q5, q6 numerator images each passed all modular held-out
  checks.  Their campaign walls were 138.20 s, 149.10 s, 148.84 s, and
  148.09 s.
- Extended-Euclid reconstruction from q1--q5 selected by disjoint q6 resolves
  only 4,794 of 66,381 expanded hard numerator coefficients.
- The recovery curve is 1,395, 1,480, 2,114, 2,651, and 4,794 coefficients at
  61, 122, 183, 244, and 305 CRT bits.  Adding primes blindly is therefore not
  a near-term completion strategy.

## Cancellation-before-lifting experiment

`cf303_nested_laurent_deck.py` evaluates the accepted nested modular profiles,
performs the epsilon-series division modulo each prime, and interpolates only
the physically required `epsilon^-3..epsilon^4` coefficients in `p`.

- The window is fixed by the accepted final-row minimum `-3` and the current
  source boundary selectors `-2..4`; target output through `epsilon^2` needs
  incoming/path-gauge orders through `4` and source boundary through `5`.
- One representative coordinate
  `1,1,rational/primitive_numerator[0]` is decisive locally: all 456 modular p
  numerator/denominator coefficients lift uniquely with q1--q5 plus q6, with
  maximum exact numerator/denominator heights 198/95 bits.
- All 126 rational coordinates produce 1,008 Laurent p profiles per prime.
  Each cached-prime deck takes 6.39--6.55 s with eight Python workers.
- Globally, 40,385 of 94,525 coefficients lift by EEA/q6.  A second,
  post-Laurent shared-scale pass uses every exact p-denominator coefficient and
  every resolved numerator seed; it rescues only 35 more coefficients and
  closes no additional profile.  The final count is 40,420 resolved and
  54,105 unresolved.

Thus epsilon cancellation is valuable but not sufficient for the complete
block.  The remaining cancellation must occur after the primitive is absorbed
into the basepoint-normalized path gauge and combined with the final row.  The
existing `PathTransportNative` series-valued provider is the appropriate next
boundary: keep these coefficients modular, assemble the physical path series
per prime, and lift only the requested final transport coefficients.  No q7
full image is justified; q7 should remain a pointwise final acceptance prime.

## Factor-first census

A final factor-first test confirms that the easy representative profile is not
typical.  Exact powers of `p`, `p-1`, and `p+1` are identical at all six
primes.  Stripping them removes 5,494 degrees from the 962 nonzero Laurent
numerators (46 profiles are zero), but leaves 51,914 coefficients in the monic
residual polynomials.  q1--q5 plus q6 reconstructs 889/962 scalar units,
1,036/51,914 residual-shape coefficients, and only 16 complete residuals.

Independent modular factorizations at q1 and q2 take 25.4 s and 24.9 s with
eight workers.  Both give the same 931 factor-incidence signatures and group
degrees.  Of these, 914 occur in only one profile; only 17 factor groups are
reused (eight across four profiles, seven across two, and two across eight).
Most unique residual degrees are 46--75.  Thus a further construction prime
would enlarge another mostly expanded, profile-unique object and is not a
sound performance choice.

## Reproduction

```bash
cd /home/maxzhang/factorization-and-loops-codex
python3 Diagnostics/Scripts/cf303_nested_laurent_deck.py \
  --workers 8 --validation-workers 3 --threads-per-validation 4
```

The intentionally incomplete report is
`Runtime/2026-08-31_cf303_native_dlog_residues/cf303_block1_exact_laurent_deck_report.json`.
The six resumable modular decks are under
`Runtime/2026-08-31_cf303_native_dlog_residues/block1_modular_laurent_decks/`.
