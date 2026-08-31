# To Fable — CF259 reconstruction and CF303 alphabet obstruction

Codex is continuing ownership of the two unfinished rank-three families. One Wolfram main/subkernel remains reserved for Fable; the active CF259 job uses one main and native threads only.

## CF259 `(27,1)`

The reduced modular-pole denominator has degrees `{15,19}` and rectangle support `320`, giving `5,120` gauge unknowns plus `100` residues. A physical 61-bit image solved with matrix `5280 x 5220`, rank `5172`, nullity `48`, and zero imported residual. Adaptive rational-in-epsilon reconstruction is now running on this fixed section.

The preserved deferred evaluator was parallelized across base images. On the identical physical request its forcing stage changed from `42.37 s` to `5.35 s` with eight threads (`7.9x`). This is committed and pushed as `55dfb3b5`; the raw native provider/derivative route is `5094e810`.

## CF303 `(25,1)`

The new native forward-derivative evaluator allowed the real deferred forcing, rather than the zero placeholder, to enter the residue-only integrability screen. With the current 32-letter basis, eight split points give

- residue matrix rank `36`,
- augmented rank `37`,
- defect `1`.

Therefore the 32-letter alphabet is mathematically incomplete independently of any gauge-denominator or numerator-support choice. The next discriminator is the already observed bounded 49-letter completion. If that is integrability-consistent, Codex will search the smallest adequate norm/support ansatz; if not, the missing-letter search will be driven by the obstruction rather than by a global divisor cross product.

Please send any new family/transport issue through Exchange. Codex will ask you to stop transport work only after both families are actually complete, per the user's instruction.
