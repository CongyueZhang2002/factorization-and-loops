#!/usr/bin/env python3
"""Check the package's explicit load profiles, ownership and literal source paths.

This is a structural check; it does not infer a complete Wolfram call graph.
"""
from pathlib import Path
import json
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "FeynFacet"
REQUIRED = {"Public", "Symbolic", "EpsilonForm", "Solution", "SolutionData"}
ENTRY_FILES = {
    "FeynFacet.m", "EpsilonForm.m", "Solution.m", "Kernel/init.m",
    "Kernel/Loader.wl", "Kernel/Modules.wl", "Kernel/Formatting.wl",
}

# Executed in isolated kernels; these scripts must never enter a package load profile.
STANDALONE_WORKERS = {"Tools/hypergeometric_series_worker.wls"}

def check():
    errors = []
    text = (PACKAGE / "Kernel/Modules.wl").read_text()
    profiles = {
        name: json.loads("[" + body + "]")
        for name, body in re.findall(r'"(\w+)"\s*->\s*\{([^{}]*)\}', text)
    }
    if set(profiles) != REQUIRED:
        errors.append("Manifest profiles differ from the supported entry points.")
    paths = [path for members in profiles.values() for path in members]
    if len(paths) != len(set(paths)):
        errors.append("Each source must have one manifest owner.")
    for path in paths:
        target = PACKAGE / path
        if not target.resolve().is_relative_to(PACKAGE.resolve()):
            errors.append(f"Escaping module path: {path}")
        elif not target.is_file():
            errors.append(f"Missing module: {path}")
    actual = {
        str(path.relative_to(PACKAGE))
        for path in PACKAGE.rglob("*")
        if path.is_file() and path.suffix in {".m", ".wl", ".wls"}
    }
    for path in STANDALONE_WORKERS:
        if not (PACKAGE / path).is_file():
            errors.append(f"Missing standalone worker: {path}")
    if set(paths) & STANDALONE_WORKERS:
        errors.append("Standalone workers must not be loaded as package modules.")
    unlisted = actual - set(paths) - ENTRY_FILES - STANDALONE_WORKERS
    if unlisted:
        errors.append("Unlisted package sources: " + ", ".join(sorted(unlisted)))
    if any("/EpsilonForm/" in p or p == "Interfaces/Libra.wl"
           for p in profiles.get("Symbolic", [])):
        errors.append("The default symbolic profile includes epsilon-form code.")
    reader = profiles.get("SolutionData", []) + profiles.get("Solution", [])
    for path in reader:
        # The shared rational-function and analytic-limit primitives are usable by both
        # the standalone reader and symbolic construction; it has no FeynCalc dependency.
        if path not in {"Core/RecordFormat.wl", "Algebra/RationalFunctions.wl", "Algebra/RegularLimits.wl"} and not path.startswith(("Solutions/", "Functions/", "Numerics/")):
            errors.append(f"Reader imports another subsystem: {path}")
        body = (PACKAGE / path).read_text()
        if "FeynCalc" + chr(96) in body or re.search(r'Get\[.*(?:EpsilonForm|FeynFacet\.m)', body):
            errors.append(f"Reader source depends on symbolic construction: {path}")
    for old in ["Private", "Private_Backup", "Backends/native_postfix"]:
        if (PACKAGE / old).exists():
            errors.append(f"Removed package directory still exists: {old}")

    # Literal FileNameJoin and Python Path references starting at the
    # repository's FeynFacet folder. Variable-built paths are checked at load.
    checked = 0
    for base in ["FeynFacet", "Tests", "Scripts", "Examples"]:
        for source in (ROOT / base).rglob("*"):
            if not source.is_file() or source.suffix not in {".wl", ".wls", ".m", ".py", ".sh"}:
                continue
            body = source.read_text(errors="replace")
            for pattern, sep in [
                (r'"FeynFacet"(?:\s*,\s*"[^"]+")+', ","),
                (r'"FeynFacet"(?:\s*/\s*"[^"]+")+', "/"),
            ]:
                for match in re.finditer(pattern, body):
                    parts = re.findall(r'"([^"]+)"', match.group())
                    if not parts[-1].endswith((".m", ".wl", ".wls", ".py", ".sh", ".c", ".cpp")):
                        continue
                    if any("*" in p for p in parts):
                        continue
                    checked += 1
                    target = ROOT.joinpath(*parts)
                    if not target.is_file():
                        line = body[:match.start()].count("\n") + 1
                        errors.append(f"{source.relative_to(ROOT)}:{line}: missing {'/'.join(parts)}")
    print(json.dumps({
        "profiles": {k: len(v) for k, v in profiles.items()},
        "manifest_sources": len(paths),
        "standalone_workers": len(STANDALONE_WORKERS),
        "literal_source_references_checked": checked,
        "errors": errors,
    }, indent=2))
    return not errors

if __name__ == "__main__":
    sys.exit(0 if check() else 1)
