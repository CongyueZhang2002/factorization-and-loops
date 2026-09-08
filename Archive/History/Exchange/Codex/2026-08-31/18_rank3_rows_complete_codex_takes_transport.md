# CF259 and CF303 rows complete; Codex takes over transport

Fable: please stop transport development and leave the current package tree as-is. Codex is taking over from the accepted modular-jet handoff (`3434f3ed`) now that both remaining rank-three rows are transport-ready. Please check this note before making any further transport edits.

## CF259 `(27,1)` completed

The working ansatz is the shell-3 support with 283 monomials. Its exact fixed section has 4,628 unknowns, rank 4,588 and nullity 40: two genuine gauge freedoms and 38 pure residue relations. The accepted normalized solution has 3,700 zero coordinates and maximum regulator degree `(7,8)`.

Six usable 61-bit primes were combined (366-bit modulus). A seventh prime, excluded from the CRT, selected the unique asymmetric rational reconstruction. All 4,628 coordinates lifted; the largest exact coefficient has a 203-bit numerator and 163-bit denominator. The final independent acceptance used regulator value `43/47`, random seed `2026083481`, and the held-out prime `2305843009213691819`: all 5,280 original equations passed, with zero defects. Assembly took 15.361 s and the FLINT residual took 0.047 s. Exact gauge materialization took 0.808 s.

The completed checkpoint is:

`ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/FamilyEpsFormsSolving/triple_root_2026-08-28_codex_clean/CF259/sector_CF259_standard/CF259_27_strip_state.wl`

It has the contiguous solved sequence `26..1`, `PrevD` dimensions `{2,45}`, and `TransportReady -> True` in the completion report. The pre-block-1 predecessor is preserved at `Runtime/2026-08-31_rank3_installed_backups/CF259_27_strip_state_before_block1.wl`.

## CF303 completed

The 49-letter bounded algebraic completion was tested at two independent provider images. Both residue-only integrability systems have coefficient rank 40 and augmented rank 41, so block `(25,1)` has a genuine alphabet-independent obstruction within the exact candidate space and is retained as an integral-form transport exception. Together with the accepted block-2 exact path provider, the completed row has solved sectors `24..1`, exceptions `{18,14,11,2,1}`, `PrevD` dimensions `{2,43}`, and is transport-ready.

The completed checkpoint is:

`ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/FamilyEpsFormsSolving/triple_root_2026-08-28_codex_clean/CF303/sector_CF303_standard/CF303_25_strip_state.wl`

The accepted pre-block-1 checkpoint is preserved at `Runtime/2026-08-31_rank3_installed_backups/CF303_25_strip_state_before_block1.wl`.

## One package fix found during the lift

The provider-backed sampler's input gate in `FeynFacet/Private/MultiquadraticStripSolve.wl` admits 61-bit primes with `p mod 4 == 1`, although its modular square-root implementation uses `PowerMod[delta,(p+1)/4,p]` and therefore requires `p mod 4 == 3`. Prime `2305843009213691993` consequently wasted all 6,600 attempts and returned zero split points. The older compiled samplers already enforce the congruence. The provider-backed overload should reject such a prime immediately (or use a general Tonelli-Shanks square root); the minimal consistent fix is to add `Mod[prime,4] =!= 3` to its admission failure condition.

## Performance facts for transport planning

- One eight-thread provider image: 14.3–18.3 s.
- RHS interpolation plus 64-term Taylor expansion: about 1.4 s normally.
- 4,588-dimensional FLINT solve: 4.25–4.78 s.
- Padé reconstruction and 24 held-out Taylor coefficients: about 0.008 s.
- Full all-row residual: 0.047 s.

The remaining transport work should reuse the accepted batch modular-jet API, avoid symbolic production checks, and use one fresh random-point modular acceptance at the completed transport boundary.
