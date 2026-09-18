#!/usr/bin/env python3
"""Check maintained repository paths without scanning generated or vendor trees.

This checks organization and local Markdown links. It does not infer whether
a mathematical routine is unused or whether a physics calculation is complete.
"""
from pathlib import Path
import json
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
HISTORY = {"Archive", "External", "Codex", "Reports"}
LINK = re.compile(r"(?<!!)\[([^\]]*)\]\(([^)]+)\)")


def maintained_files():
    names = subprocess.check_output(
        ["git", "ls-files", "-co", "--exclude-standard", "-z"],
        cwd=ROOT).decode().split(chr(0))
    for name in sorted(set(names) - {""}):
        path = ROOT / name
        if not path.is_file() or path.is_symlink():
            continue
        parts = Path(name).parts
        if parts[0] in HISTORY:
            if parts[0] != "Reports" or path.name != "README.md":
                continue
        if parts[0] == "Projects" and any(
                part in {"Results", "Work", "Kira", "InputData"} for part in parts[2:]):
            continue
        yield path


def check():
    errors = []
    guides = links = 0
    for path in maintained_files():
        if path.suffix != ".md":
            continue
        guides += 1
        content = path.read_text()
        # Code blocks can contain bracketed mathematical functions.
        content = re.sub(r"```.*?```|~~~.*?~~~", "", content, flags=re.S)
        for _, target in LINK.findall(content):
            if "://" in target or target.startswith(("#", "mailto:")):
                continue
            target = target.partition("#")[0].strip("<>")
            if not target or ("/" not in target and "." not in target):
                continue
            links += 1
            if not (path.parent / target).exists():
                errors.append(f"{path.relative_to(ROOT)}: missing link {target}")
    projects = sorted(path for path in (ROOT / "Projects").iterdir() if path.is_dir())
    for path in projects:
        if not (path / "Common-Card.wl").is_file():
            errors.append(f"{path.relative_to(ROOT)}: common project card missing")
        if re.search(r"_(?:LO|NLO|NNLO)$", path.name):
            errors.append(f"{path.relative_to(ROOT)}: perturbative order in project name")
    if (ROOT / "reports").exists():
        errors.append("Lowercase reports conflicts with the maintained Reports directory.")
    for path in (ROOT / "Reports").iterdir():
        if path.is_dir() and not re.fullmatch(r"\d{4}-\d{2}-\d{2}", path.name):
            errors.append(f"{path.relative_to(ROOT)}: reports need dated directories")
    for root in ("FeynFacet", "Scripts", "Tests", "Examples"):
        if (ROOT / root / "Results").exists():
            errors.append(f"{root}/Results: calculation output belongs in Projects")
    return {"Projects": len(projects), "MaintainedGuides": guides,
            "LocalLinks": links, "Errors": errors}


if __name__ == "__main__":
    result = check()
    print(json.dumps(result, indent=2))
    raise SystemExit(bool(result["Errors"]))
