#!/usr/bin/env python3
"""FableBridge Transport C: post a prompt into an actual claude.ai chat
conversation (user-authorized 2026-08-16), mirroring Codex's chatgpt.com
bridge.

Uses claude.ai's browser-session API (unofficial, may change). Requires a
one-time credential: your claude.ai sessionKey cookie, in
External/FableBridge/.session_key (gitignored; never committed).

  Get it once: claude.ai -> DevTools -> Application -> Cookies ->
  sessionKey value. Then, in a shell (do NOT paste the cookie into chat):
    printf %s 'sk-ant-sid...' > External/FableBridge/.session_key
    chmod 600 External/FableBridge/.session_key

Usage:
  send_to_chat.py prompts/foo.md                # new conversation
  send_to_chat.py prompts/foo.md --continue     # reuse last conversation
State -> chat_bridge_state.json ; response -> responses/<name>_chat_response.md
"""
import json, sys, time, hashlib, uuid, pathlib
import urllib.request

BASE = "https://claude.ai"
HERE = pathlib.Path(__file__).resolve().parent
STATE = HERE / "chat_bridge_state.json"
KEYFILE = HERE / ".session_key"


def req(path, payload=None, key=None, stream=False):
    headers = {
        "Cookie": f"sessionKey={key}",
        "Content-Type": "application/json",
        "User-Agent": "Mozilla/5.0 (FableBridge)",
        "Accept": "text/event-stream" if stream else "application/json",
    }
    data = json.dumps(payload).encode() if payload is not None else None
    r = urllib.request.Request(BASE + path, data=data, headers=headers,
                               method="POST" if data else "GET")
    return urllib.request.urlopen(r, timeout=900)


def main():
    if len(sys.argv) < 2:
        sys.exit("usage: send_to_chat.py <prompt.md> [--continue]")
    prompt_path = pathlib.Path(sys.argv[1])
    cont = "--continue" in sys.argv
    if not KEYFILE.exists():
        sys.exit("no .session_key — see header for one-time setup")
    key = KEYFILE.read_text().strip()
    text = prompt_path.read_text()
    sha = hashlib.sha256(text.encode()).hexdigest()

    org = json.load(req("/api/organizations", key=key))[0]["uuid"]
    state = json.loads(STATE.read_text()) if STATE.exists() else {}
    if cont and state.get("conversationId"):
        conv = state["conversationId"]
    else:
        conv = str(uuid.uuid4())
        req(f"/api/organizations/{org}/chat_conversations",
            {"uuid": conv, "name": prompt_path.stem[:60],
             "model": "claude-fable-5"}, key=key).read()
    resp = req(
        f"/api/organizations/{org}/chat_conversations/{conv}/completion",
        {"prompt": text, "parent_message_uuid": None,
         "timezone": "America/Los_Angeles",
         "paprika_mode": "extended",     # request max thinking if honored
         "model": "claude-fable-5"}, key=key, stream=True)
    out = []
    for raw in resp:
        line = raw.decode("utf-8", "ignore").strip()
        if line.startswith("data:"):
            try:
                j = json.loads(line[5:])
                if j.get("type") == "completion":
                    out.append(j.get("completion", ""))
            except json.JSONDecodeError:
                pass
    answer = "".join(out)
    rp = HERE / "responses" / (prompt_path.stem + "_chat_response.md")
    rp.write_text(answer)
    STATE.write_text(json.dumps({
        "version": 1, "conversationId": conv,
        "conversationUrl": f"{BASE}/chat/{conv}",
        "model": "claude-fable-5", "thinking": "extended-requested",
        "promptPath": str(prompt_path), "promptSha256": sha,
        "sentAt": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "responsePath": str(rp), "responseChars": len(answer)}, indent=1))
    print(f"response {len(answer)} chars -> {rp}")
    print(f"conversation: {BASE}/chat/{conv}")


if __name__ == "__main__":
    main()
