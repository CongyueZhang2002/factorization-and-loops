import ctypes
import json
import subprocess
import sys
import time
import warnings
from ctypes import wintypes
from urllib.request import urlopen

from comtypes import COMMETHOD, GUID, HRESULT, IUnknown
from comtypes.client import CreateObject


sys.stdout.reconfigure(encoding="utf-8", errors="replace")

AUMID = r"OpenAI.ChatGPT-Desktop_2p2nqsd0c76g0!ChatGPT"
PORT = 9328
SW_SHOWMINNOACTIVE = 7


class IApplicationActivationManager(IUnknown):
    _iid_ = GUID("{2E941141-7F97-4756-BA1D-9DECDE894A3D}")
    _methods_ = [
        COMMETHOD(
            [],
            HRESULT,
            "ActivateApplication",
            (["in"], wintypes.LPCWSTR, "appUserModelId"),
            (["in"], wintypes.LPCWSTR, "arguments"),
            (["in"], wintypes.DWORD, "options"),
            (["out"], ctypes.POINTER(wintypes.DWORD), "processId"),
        )
    ]


def endpoint():
    try:
        with urlopen(f"http://127.0.0.1:{PORT}/json/version", timeout=1) as response:
            return json.load(response)
    except Exception:
        return None


def classic_window():
    warnings.filterwarnings(
        "ignore", message="Revert to STA COM threading mode", category=UserWarning
    )
    from pywinauto import Desktop

    return next(
        (
            window
            for window in Desktop(backend="uia").windows()
            if window.window_text() == "ChatGPT Classic"
        ),
        None,
    )


def composer_draft(window):
    if window is None:
        return ""
    composer = next(
        (
            control
            for control in window.descendants()
            if control.element_info.automation_id == "prompt-textarea"
        ),
        None,
    )
    if composer is None:
        return ""
    try:
        return composer.iface_value.CurrentValue
    except Exception:
        return ""


user32 = ctypes.windll.user32
ready = endpoint()
if ready is not None:
    window = classic_window()
    if window is not None and window.handle == user32.GetForegroundWindow():
        raise SystemExit("ChatGPT Classic is focused; refusing background control")
    print(f"status=READY browser={ready.get('Browser', '')}")
    raise SystemExit(0)

foreground = user32.GetForegroundWindow()
window = classic_window()
if window is not None and window.handle == foreground:
    raise SystemExit("ChatGPT Classic is focused; refusing to restart it")
draft = composer_draft(window)
if draft:
    raise SystemExit("ChatGPT Classic contains a draft; refusing to restart it")

subprocess.run(
    ["taskkill", "/F", "/T", "/IM", "ChatGPT Classic.exe"],
    check=False,
    stdout=subprocess.DEVNULL,
    stderr=subprocess.DEVNULL,
)

manager = CreateObject(
    GUID("{45BA127D-10A8-46EA-8AB7-56EA9078943C}"),
    interface=IApplicationActivationManager,
)
arguments = (
    f"--remote-debugging-port={PORT} "
    f"--remote-allow-origins=http://127.0.0.1:{PORT} "
    "--start-minimized --no-first-run"
)
process_id = manager.ActivateApplication(AUMID, arguments, 2 | 4)

deadline = time.monotonic() + 45
ready = None
window = None
while time.monotonic() < deadline:
    if user32.GetForegroundWindow() != foreground:
        user32.SetForegroundWindow(foreground)
    window = classic_window()
    if window is not None:
        user32.ShowWindowAsync(window.handle, SW_SHOWMINNOACTIVE)
    ready = endpoint()
    if ready is not None and window is not None:
        break
    time.sleep(0.15)

if user32.GetForegroundWindow() != foreground:
    user32.SetForegroundWindow(foreground)

if ready is None:
    raise SystemExit("ChatGPT Classic relaunched, but port 9328 did not become ready")
if window is None:
    raise SystemExit("ChatGPT Classic endpoint opened, but its window was not found")
if user32.GetForegroundWindow() != foreground:
    raise SystemExit("ChatGPT Classic changed the foreground window")

print(
    f"status=RELAUNCHED process_id={process_id} "
    f"browser={ready.get('Browser', '')} foreground_unchanged=true"
)
