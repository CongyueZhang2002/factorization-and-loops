#!/usr/bin/env python3
"""Progress and time estimate for the two-root completion campaign.

Usage: tworoot_status.py <output-root> [family ...]

Work units are the sector script's own: sectors k = 2..nb and the count of
"non-eps-factored strips remaining (all sectors)" it prints after every
sector.  The time estimate is a calibrated per-sector model:
  small sector (diagonal block dim <= 2): measured mean of this campaign
      (prior 90 s, CF254 run of 2026-08-19);
  large sector (dim >= 3): measured large-sector seconds per lower sector of
      this campaign (prior 450 s per lower sector = 60 min for CF254's
      sector 9 with 8 lower sectors, the deep-rung sector), scaled by the
      number of lower sectors;
  assembly prior 25 min (CF254: 1445 s); finishing (TransformDlogToEpsForm
      of the last sector + family gate + certification) prior 15 min.
Estimates are labelled "prior" until the campaign has measured the kind.
"""
import os, re, sys, time, glob, subprocess
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
R = os.path.join(root, "ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical")
out = sys.argv[1]
families = sys.argv[2:] or ["CF231", "CF305", "CF265"]

# priors re-based 2026-08-22 on the production check level + task broker
# pipeline: assembly 98 s on CF254 (was 1445), hardest block (9,7) 187 s on
# one subkernel (sector 9 of CF254 has 8 lower sectors), easy blocks seconds;
# measured values replace them as the campaign reports each kind
PRIOR = {"assembly": 180.0, "small": 30.0, "large_per_lower": 60.0, "finish": 300.0}

def block_dims(fam):
    s = open(os.path.join(R, "BlockClasses/block_class_assign.wl")).read()
    return [int(d) for f, d in re.findall(r'"Family" -> "(CF\d+)",\s*"Rows" -> \{[^}]*\},\s*"Dim" -> (\d+)', s) if f == fam]

def alive(path):
    try:
        return subprocess.run(["fuser", path], capture_output=True).returncode == 0
    except Exception:
        return False

def parse(fam):
    log = os.path.join(out, fam, "run.log")
    st = {"family": fam, "log": log, "state": "pending", "t": 0, "nb": None, "sector": None,
          "done_sectors": [], "sector_start": {}, "sector_end": {}, "strips_initial": None,
          "strips_remaining": None, "current_strip": None, "strip_start": None, "strip_stage": "",
          "strips_in_sector": 0, "strips_done_in_sector": 0, "assembled_at": None,
          "finished": None, "errors": [], "mtime": None, "kernels": None, "chart": None}
    if not os.path.exists(log):
        return st
    st["state"] = "running" if alive(log) else "stopped"
    st["mtime"] = os.path.getmtime(log)
    for raw in open(log, errors="replace"):
        # the pool writes Print output with InputForm quoting: strip it
        line = raw.replace('\\"', '').replace('"', '')
        m = re.search(r'\+(\d+)s\]\s*(.*)', line)
        if m:
            t = int(m.group(1)); body = m.group(2)
            st["t"] = max(st["t"], t)
        else:
            body = line.strip(); t = st["t"]
        if "worker-kernel limit" in body:
            st["kernels"] = body.split()[-1]
        if body.startswith("assembled"):
            mm = re.search(r'(\d+) sectors, chart (\S+)', body)
            if mm: st["nb"] = int(mm.group(1)); st["chart"] = mm.group(2)
            st["assembled_at"] = t
        elif body.startswith("initial:"):
            st["strips_initial"] = int(re.search(r'initial: (\d+)', body).group(1)); st["strips_remaining"] = st["strips_initial"]
        elif body.startswith("==== sector"):
            k = int(re.search(r'sector (\d+)', body).group(1))
            st["sector"] = k; st["sector_start"][k] = t; st["strips_in_sector"] = 0; st["strips_done_in_sector"] = 0
            st["current_strip"] = None; st["strip_stage"] = "complete-sector CANONICA"
        elif body.startswith("strip {"):
            st["current_strip"] = re.search(r'strip (\{[^}]*\})', body).group(1); st["strip_start"] = t
            st["strip_stage"] = "CANONICA degree ladder"; st["strips_in_sector"] += 1
        elif body.startswith("exact CANONICA/Maple routes found no gauge") or body.startswith("not already dlog; finite-field"):
            st["strip_stage"] = "finite-field deep rung"
        elif body.startswith("finite field found no gauge"):
            st["strip_stage"] = "CANONICA/Maple fallback"
        elif re.match(r'^(CANONICA|AlreadyDLog|Maple\w*|Simultaneous\w*|FiniteField\w*)', body) and st["current_strip"]:
            st["strips_done_in_sector"] += 1; st["strip_stage"] = "solved: " + body.split()[0]; st["current_strip"] = None
        elif "row completed" in body:
            st["strip_stage"] = "TransformDlogToEpsForm"
        elif re.search(r'sector (\d+) done; non-eps-factored strips remaining', body):
            # the pool wraps long Print lines: the count may sit on the next line
            mm = re.search(r'sector (\d+) done; non-eps-factored strips remaining \(all sectors\): (\d+)', body)
            k = int(re.search(r'sector (\d+) done', body).group(1))
            if mm: st["strips_remaining"] = int(mm.group(2))
            else: st["pending_remaining"] = True
            st["sector_end"][k] = t; st["done_sectors"].append(k)
        elif st.get("pending_remaining") and re.match(r'^\d+', body):
            st["strips_remaining"] = int(re.match(r'^(\d+)', body).group(1)); st["pending_remaining"] = False
        elif body.startswith("written family_epsform"):
            st["finished"] = t; st["state"] = "done"
        elif "!!" in body or "::" in body and "Exit" not in body:
            if "!!" in body: st["errors"].append(body[:120])
        if "Maple" in body and "produce" in body: st["strip_stage"] = "Maple failed -> finite field"
        if body.startswith("Prime ") and "held-out" in body: st["strip_stage"] = "finite-field: " + body[:60]
        if body.startswith("[broker]"): st["strip_stage"] = "finite-field on pool helpers: " + body[9:60]
        if body.startswith("Sample batches go to the KernelPool"): st["strip_stage"] = "finite-field: sampling on pool helpers"
        if body.startswith("Selected numerator-degree offset"): st["strip_stage"] = "finite-field: sampling"
    if st["state"] == "stopped" and st["finished"] is None:
        st["state"] = "failed" if st["errors"] else "stopped"
    return st

def fmt(s):
    s = int(round(s)); h, r = divmod(s, 3600); m, _ = divmod(r, 60)
    return f"{h}h{m:02d}m" if h else f"{m}m"

# ---- calibration across all parsed families ----
parsed = {f: parse(f) for f in families}
dims = {f: block_dims(f) for f in families}
small_times, large_rates, assembly_times = [], [], []
for f, st in parsed.items():
    if st["assembled_at"]: assembly_times.append(st["assembled_at"])
    for k in st["done_sectors"]:
        dur = st["sector_end"][k] - st["sector_start"].get(k, st["sector_end"][k])
        if dims[f][k-1] >= 3: large_rates.append(dur / max(1, k-1))
        else: small_times.append(dur)
cal = {"assembly": (sum(assembly_times)/len(assembly_times), "measured") if assembly_times else (PRIOR["assembly"], "prior"),
       "small": (sum(small_times)/len(small_times), "measured") if small_times else (PRIOR["small"], "prior"),
       "large_per_lower": (sum(large_rates)/len(large_rates), "measured") if large_rates else (PRIOR["large_per_lower"], "prior"),
       "finish": (PRIOR["finish"], "prior")}

def estimate(f, st):
    d = dims[f]; nb = len(d); rem = 0.0; labels = set()
    if st["state"] == "done": return 0.0, ""
    if st["assembled_at"] is None:
        rem += max(0.0, cal["assembly"][0] - st["t"]); labels.add(cal["assembly"][1])
        start_k = 2
    else:
        start_k = (st["sector"] or 1)
        if st["sector"] and st["sector"] not in st["sector_end"]:
            k = st["sector"]; spent = st["t"] - st["sector_start"][k]
            full = cal["large_per_lower"][0] * (k-1) if d[k-1] >= 3 else cal["small"][0]
            labels.add(cal["large_per_lower"][1] if d[k-1] >= 3 else cal["small"][1])
            rem += max(full - spent, 0.1 * full)
        start_k = (st["sector"] or 1) + 1
    for k in range(start_k, nb + 1):
        if d[k-1] >= 3: rem += cal["large_per_lower"][0] * (k-1); labels.add(cal["large_per_lower"][1])
        else: rem += cal["small"][0]; labels.add(cal["small"][1])
    rem += cal["finish"][0]; labels.add("prior")
    return rem, ("measured" if labels == {"measured"} else "prior-based")

now = time.time(); total_rem = 0.0; max_rem = 0.0
print(f"two-root campaign status  {time.strftime('%Y-%m-%d %H:%M')}   output {out}")
print(f"calibration: assembly {fmt(cal['assembly'][0])} ({cal['assembly'][1]}), small sector {cal['small'][0]:.0f}s ({cal['small'][1]}), "
      f"large sector {cal['large_per_lower'][0]:.0f}s/lower-sector ({cal['large_per_lower'][1]}), finish {fmt(cal['finish'][0])} (prior)")
for f in families:
    st = parsed[f]; d = dims[f]; nb = len(d)
    rem, kind = estimate(f, st); total_rem += rem; max_rem = max(max_rem, rem)
    large = [k for k in range(1, nb+1) if d[k-1] >= 3]
    line = f"{f:6s} {st['state']:8s} dim {sum(d)} sectors {nb} (large: {large})"
    if st["state"] == "pending":
        print(line + f"  estimate {fmt(rem)} (prior)"); continue
    el = st["t"]; phase = "assembly" if st["assembled_at"] is None else (f"sector {st['sector']}/{nb}" if st["finished"] is None else "finished")
    strips = f"strips remaining {st['strips_remaining']}/{st['strips_initial']}" if st["strips_initial"] is not None else ""
    print(line + f"  elapsed {fmt(el)}  {phase}  {strips}  kernels {st['kernels']} chart {st['chart']}")
    if st["state"] == "running" and st["assembled_at"] is not None and st["finished"] is None:
        cur = f"current strip {st['current_strip']} ({fmt(st['t']-st['strip_start'])} in strip) " if st["current_strip"] else ""
        print(f"       sector {st['sector']}: {st['strips_done_in_sector']} strips solved, {cur}stage: {st['strip_stage']}; "
              f"log idle {fmt(now - st['mtime'])}")
    if st["state"] == "done":
        print(f"       done in {fmt(st['finished'])}: {'; '.join(st['errors']) if st['errors'] else 'GateVerdict see log'}")
    elif st["state"] in ("failed", "stopped"):
        print(f"       {st['state']}: {'; '.join(st['errors'][-2:]) or 'no error line; see log'}")
    else:
        print(f"       estimated remaining {fmt(rem)} ({kind}), ETA {time.strftime('%H:%M', time.localtime(now + rem))}")
print(f"campaign (families in parallel): estimated remaining {fmt(max_rem)} -> ETA {time.strftime('%Y-%m-%d %H:%M', time.localtime(now + max_rem))}   (serial-equivalent work {fmt(total_rem)})")
cs = os.path.join(out, "campaign_status.tsv")
if os.path.exists(cs):
    print("--- driver status ---"); print(open(cs).read().strip())
