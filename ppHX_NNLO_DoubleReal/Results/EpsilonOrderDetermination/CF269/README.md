# CF269: Laurent bounds and sufficient epsilon orders

These are complete finite records at (v,w)=(1/4,1/3), with the existing AMFlow
measure and original 23-master basis. They contain no unevaluated generator.

| File | Contents | Size |
|---|---|---:|
| `DimensionalRecurrence.wxf` | Rational raising/lowering matrices, complete integral definitions, IBP basis change and convergence arguments | 208,457 bytes |
| `IntegralLaurentBounds.wxf` | Finite downward product and all 23 sufficient Laurent bounds | 214,499 bytes |
| `MasterIntegralExpansionOrders.wxf` | Prepared DE, entrywise evolution/boundary orders and derivation inputs | 656,842 bytes |

Load a compressed WXF file with `Import[path,"WXF"]`. Serialization was checked
by exact equality after reloading.

The code proved at most triple poles for every master at this point.
Two masters are holomorphic. The lowering matrix has poles at D=4 and D=6
on the upward even grid; finite descent from eventual high-dimensional
holomorphy proves holomorphy at D=8. This does not claim convergence of each
original integral representation at D=8.

For all original masters requested through epsilon^0, the boundary constants
are needed through orders

```text
{0,0,0,0,3,2,0,1,0,1,1,0,0,0,0,1,0,0,0,0,1,0,1}.
```

The prepared DE evolution must reach epsilon^4. The lower bounds are sufficient
and need not be saturated. No boundary coefficient or global DE solution was
computed for these order records.

The general constructor reduced 1,028 Gram-insertion targets using Kira 3.1
at exact rational kinematics, with D symbolic. Reduction and export took
144.47 seconds with two Fermat workers, with zero unreduced integrals.
The `IBP` directory preserves the configuration, targets, exact table and log.
The record now points directly to the retained IBP directory and kira_targets.wl table.

Reproduce the order table without Kira:

```sh
wolframscript -file Scripts/Transport/determine_epsilon_orders.wls \
  Examples/Transport/cut_integral_expansion_orders.wl /tmp/cut-master-orders.wl
```

See [the general method](../../../../Design/CutIntegralLaurentBounds.md)
and [the reusable example](../../../../Examples/Transport/cut_integral_expansion_orders.wl).
The package implementation contains no CF269-specific branches.
