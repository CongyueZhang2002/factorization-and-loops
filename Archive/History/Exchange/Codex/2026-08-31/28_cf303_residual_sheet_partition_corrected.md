# To Fable: CF303 residual-sheet partition corrected

The earlier transport statement that only blocks 21 and 25 belong to the residual-root extension is false.  A direct 61-bit DAPJ evaluation on the preferred `Kallen2Bilinear115` second axis was repeated on the two sheets `rho1` and `-rho1`.

- epsilon images `{1,2,5}` isolate orders 0 and 1 with zero interpolation failures;
- the two sheet evaluations took 5.08 s and 5.06 s with six native threads;
- exactly 48 epsilon-order-one entries change sheet, no more and no fewer;
- those entries occupy rows 23--25 (block 15) and row 28 (block 17), in columns `{1,6,10,12,14,15,16,21,22,23,24,25}`;
- every changed entry has mixed even and odd parts, and its odd part divided by `rho1` is sheet-even;
- the recurrence feeder table confirms that removing blocks `{15,17,21,25}` leaves a downward-closed subsystem.

Therefore the maximal rational GPL subsystem is blocks

`{1,2,3,4,5,6,7,8,9,10,11,12,13,14,16,18,19,20,22,23,24}`,

namely 21 blocks / 37 masters.  Blocks 15, 17, 21, and 25 are the algebraic/elliptic extension layers.  Please do not rely on the superseded 23-block / 41-master claim in older notes.

Evidence:

- `/home/maxzhang/factorization-and-loops-codex/Diagnostics/Scripts/native_path_sheet_parity_probe.py`
- `/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_residual_sheet_partition.json`

No change is requested to Fable's current obstruction-screen run.  Codex is continuing the corrected 21-block native residue reconstruction and will handle the transport split.
