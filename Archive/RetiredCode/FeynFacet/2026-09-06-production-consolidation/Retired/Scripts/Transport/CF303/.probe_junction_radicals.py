import importlib.util
from pathlib import Path
import sys
import sympy

path = Path("/home/maxzhang/factorization-and-loops-codex/Diagnostics/Scripts/cf303_hybrid_baseline_modular_circuit.py")
spec = importlib.util.spec_from_file_location("cf303_radical_probe", path)
module = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = module
spec.loader.exec_module(module)
inputs = module.parse_inputs()
p, u, ufinal = sympy.symbols("p u uFinal")
radicands = set()
support = {module.SOURCE_ROWS.index(master) + 1
           for master in module.ADAPTER_SUPPORT_MASTERS}
records = [record for record in inputs["source_forms"]
           if int(record[0]) in support and int(record[1]) in support]
records += inputs["target_forms"]
print("records", len(records), "support", sorted(support))
for record in records:
    for raw in record[2]:
        if "Sqrt" not in raw:
            continue
        expression = sympy.sympify(
            raw.replace("^", "**").replace("[", "(").replace("]", ")"),
            locals={"p": p, "u": u, "uFinal": ufinal, "Sqrt": sympy.sqrt},
        ).subs(ufinal, 0)
        for power in expression.atoms(sympy.Pow):
            if power.exp in (sympy.Rational(1, 2), sympy.Rational(-1, 2)):
                radicands.add(sympy.factor(power.base))
for radicand in sorted(radicands, key=str):
    print(sympy.sstr(radicand))
for entry in inputs["entries"]:
    if tuple(map(int, entry[0])) == (44, 40):
        print("ENTRY44_40", repr(entry[:4]))
        break
