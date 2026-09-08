# Representative-family benchmark (2026-08-23 evening)

Package state: commit 52ce634 (generality pass + gauge-representative
fix: trailing gauge columns pinned first, residues as fallback).  Pool:
1 main + 8 subkernels on the P-cores, all families in flight at once
(FACET_MAX_FAMILIES=8), fresh subkernel per mission, Production check
level; the single exact statement per family is the modular family
certificate.  All certificates exact=True; certified records in
certified/ (not the inventory).

| family | situation                   | solve s | cert s | reference |
|--------|-----------------------------|---------|--------|-----------|
| CF299  | Bilinear115                 |    62.4 |    3.4 | -- |
| CF230  | Kallen1, class 77           |   207.3 |    3.4 | -- |
| CF97   | Kallen2                     |   224.6 |    4.8 | -- |
| CF264  | root-free, 18 masters       |   373.7 |    6.6 | 2282 s old route |
| CF385  | Kallen12, 44 masters        |   498.5 |   24.1 | 66 min 08-22; 776 s earlier today |
| CF258  | Kallen1, 24, deep sectors   |   530.5 |   10.7 | 3981 s old route |
| CF48   | Q4b, 27 masters             |   728.4 |   12.7 | -- |
| CF231  | Kallen23 hard pair, tall res|  2230.8 |   18.8 | ~45 min 08-22 (8 subkernels alone) |
| CF265  | Kallen13 hard pair (rerun,  |  2747.9 |   42.5 | 67.6 min this morning (inflated |
|        | 4 subkernels)               |         |        | representative); no clean         |
|        |                             |         |        | from-scratch baseline exists      |

CF265 representative fix, measured on the strip that carried the
morning blow-up, (15,11): certified degree bound 30 -> 25, support 4072
-> 2912 unknowns, per-prime sampling ~7186 s (the morning run's own
single-kernel estimate) -> 110-160 s single-kernel; early sectors 26%
leaner than even the 08-22-morning gauges.  The often-quoted "13 min"
for CF265 on 08-22 was a resumed segment on 8 subkernels after
checkpoints and recognition-era shortcuts, not a from-scratch wall
time; today's 2748 s at 4 subkernels is the first clean from-scratch
number, 32% below this morning under the same pool width.
