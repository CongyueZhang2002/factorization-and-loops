# Codex two-root update, 2026-08-20

This note distinguishes exact strip results from complete family epsilon forms.

## Exact results

1. **CF231 strip (8,7).** The rational gauge and affine dlog residues solve
   both Pfaffian equations exactly. All 32 scalar residuals vanish. This is
   an adjacent-strip result, not yet the complete CF231 family transformation.

2. **CF231 to CF305.** The complete solved (8,7) strip transfers to CF305.
   The source and target gauges satisfy the exact two-variable equations; the
   target check took 8.62 s.

3. **CF254 strips (9,8) and (9,7).** Both adjacent strips have exact rational
   gauges. For (9,7), the simultaneous modular system has 1953 unknowns,
   rank 1937, and affine nullity 16. Five primes and 161 finite-field samples
   reconstruct 11883 rational scalars. All 32 exact residuals vanish.

4. **CF254 to CF265.** The 23-master CF254 differential system embeds into a
   closed 23-dimensional subsector of the 32-master CF265 system. The exact
   mapped positions are

       {29,4,5,6,7,9,10,12,13,14,16,17,18,19,20,21,22,24,25,28,30,31,32}.

   The nine complementary CF265 masters are not determined by this map.

## Involution result

The cheap Kallen-13 to Kallen-12 test is negative. Against CF232, CF236,
CF240, CF319, CF321, CF385, and CF408, no candidate has the same exact block
classes after simultaneous within-block permutations and optional
`v <-> w`. Thus no whole-family identification of this restricted form
exists. This does not exclude a nonconstant rational basis map, but such a
search is no longer the cheapest next calculation.

## Method status

The sharp simultaneous modular method is the only method that has produced
exact production-strip gauges for the hard two-root records. It preserves
the complete affine residue freedom, reconstructs over several primes, and
ends with the full two-PDE symbolic identity.

The full Maple `IntegrableConnections` augmented-system construction is
mathematically valid and its synthetic affine test succeeds. For the exact
18-dimensional CF254 (9,8) augmented connection, however, both variable
orders terminate inside `good_form` with division by zero. Maple therefore
has neither solved that production strip nor proved that a rational gauge is
absent.

The next measured record is CF254 (9,6), a 4 by 1 strip. Its exact divisor
census is complete and its residue-compatibility construction is running.
After that result is written, the next calculation is a finite-field rank
test using the divisor-by-divisor pole bounds. The smaller augmented system
will also be a useful Maple diagnostic: if it fails at the same internal
routine, that points to the installed package rather than the (9,8) fixture.
