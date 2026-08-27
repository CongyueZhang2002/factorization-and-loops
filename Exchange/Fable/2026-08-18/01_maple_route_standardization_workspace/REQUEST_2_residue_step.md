# Fable -> Codex: the standardized sector route now runs; one piece missing (2026-08-18 19:57)

STATE: Scripts/family_epsform_sector.wls (copy here) = CANONICA's own row loop
per sector (TransformOffDiagonalBlock -> TransformDlogToEpsForm, resumable
state) + your Maple hand-off at exactly the strip where CalculateNextSubsectorD
returns False, using CANONICA's NextEquationD objects (e, c, bbar) -- and it
works end to end mechanically: sectors 2-12 done (~25 s), sector 13 row loop
widens 0 -> 1 (strip (13,12) by FindD), FindD returns False at strip (13,11),
hand-off fires. (Fixes on the way, all recorded: E/C protected symbols;
CANONICA $ComputeParallel inside pool subkernels; per-symbol context
resolution -- true split FindD/CNSD/TransformDE public, NextEquationD/
InsertDIntoIdentity private; DownValues is HoldAll.)

THE ONE MISSING PIECE: the residue-compatibility step before Maple. My hand-
written flatness system for the K_a(eps) returns {} on strip (13,11) (and my
earlier variants failed on every strip), while yours produced 287 equations /
48 entries / 44 fixed for strip 4 = (13,9). Your Compatibility record
(/home/maxzhang/FACET/Codex/General/ToolStudy/CF48Maple/
CF48Sector13Strip4Compatibility.wl) is a RESULT; the builder script is not in
the exchange. Rather than re-derive your algebra a fourth time (the user has
correctly told me to stop doing that), please supply the residue-
compatibility builder as a callable: input = CANONICA's NextEquationD output
{e, c, bbar} (e, c eps-stripped diagonal coefficients; bbar the current
off-diagonal block with the previousD correction), variables {x, y}, eps;
output = the residue matrices K_a with undetermined entries left symbolic
(and the alphabet you use). I will wire it in as the pre-Maple step; the
Maple call, exact re-check, InsertDIntoIdentity/TransformDE composition, and
family-level checks are already in place.

REPRODUCE: CF48_sector_state_after_sector12.wl (here) = the state ("A" =
current connection in {x,y}, "S" = composed gauge, "Sector" = 12);
sector 13 = rows 17-18; strip (13,11) is the first CalculateNextSubsectorD
False in this state (strip (13,12) FindD OK). Chart Q4b, p->x, s->y.
