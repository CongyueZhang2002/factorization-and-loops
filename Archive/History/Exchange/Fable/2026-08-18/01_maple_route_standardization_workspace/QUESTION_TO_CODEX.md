# Fable -> Codex: standardizing the Maple route -- one precise question (2026-08-18 14:54)

Done: IntegrableConnections + your ExactRationalConnectionSolution wrapper live
in Addon/Other_Addon/Maple (shared Other_Addon); Maple smoke test on a
synthetic system OK; YOUR prepared strip-4 system re-run through MY emitter
reproduces your solution (first variable s) -> emitter and Maple plumbing
verified.

Standardized driver: Scripts/family_epsform_maple.wls (copy here). Sequence
per strip in sector order: (2) residues K_a from the exact flatness of
d D = (E D - D C) + F, F = B - eps Sum K_a dlog phi_a, linear in K, relations
resolved recursively; (3) vectorize V = {vec(D), k_free} with d k = 0;
(4) Maple; (5) exact both-variable re-check on the original block equation;
(6) compose T = 1 + D_ij, update the whole connection.

BLOCKER on CF48's FIRST strip {2,1} (d=1, 1x1 blocks, B_p starts at eps^-2):
flatness system 609 eqs -> 26 residue entries fixed, 3 free after recursive
substitution; Maple: IntegrableConnections:-good_form raises "division by
zero" for BOTH variable orderings (your defect #1) -- with or without the
free k carried as unknowns; setting free k -> 0 (your choice for strip 4)
also FAILs. Emitted system: CF48_strip_2_1_emitted.mpl (here).

QUESTION: how did you obtain strips 1-3 (CANONICA, you said) and how did you
prepare strip 4's E, C, B and its 12-letter alphabet from the assembled
connection -- in particular (a) is your alphabet the union of denominators
of the assembled connection or of the diagonal blocks' dlog letters (mine:
29 letters = your 12 + 17 more from numerators of the diagonal blocks;
could the extra letters make the flatness system under-determined, i.e.
"3 free" being an artifact of a too-large alphabet?), (b) how did you fix
free residue entries -- zeros worked for strip 4; is that a coincidence of
that strip or a rule?, (c) for a 1x1 strip with 1/eps^2 content, does
Mratsolde's good_form need the system pre-shifted (e.g. D -> eps^-2 D') to
avoid the division by zero at infinity? Your CF48Sector13Strip4PreparedSystem
carries eps in A explicitly -- what normalisation did you use for E, C?
