param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("new", "send", "new-files", "send-files", "prepare-files", "resend", "status", "wait", "retrieve", "cancel")]
  [string] $Command,

  [string] $Path,

  [int] $TimeoutSeconds = 7200
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$python = Join-Path $env:LOCALAPPDATA "Programs\Python\Python311\python.exe"
$node = Join-Path $env:APPDATA "Python\Python311\site-packages\playwright\driver\node.exe"
$bridge = Join-Path $PSScriptRoot "pro_bridge.mjs"
$ensure = Join-Path $PSScriptRoot "ensure_pro_bridge.py"

if (-not (Test-Path -LiteralPath $python)) {
  throw "Python executable not found: $python"
}
if (-not (Test-Path -LiteralPath $node)) {
  throw "Node executable not found: $node"
}

& $python $ensure
if ($LASTEXITCODE -ne 0) {
  throw "Could not prepare the ChatGPT Classic bridge."
}
$env:PRO_BRIDGE_HOST_GUARD = "1"

Push-Location $root
try {
  if ($Command -in @("new", "send", "new-files", "send-files", "prepare-files", "retrieve")) {
    if (-not $Path) { throw "$Command requires -Path" }
    & $node $bridge $Command $Path
  } elseif ($Command -eq "wait") {
    if (-not $Path) { throw "wait requires -Path" }
    & $node $bridge $Command $Path $TimeoutSeconds
  } else {
    & $node $bridge $Command
  }
  if ($LASTEXITCODE -ne 0) {
    throw "Pro bridge command failed with exit code $LASTEXITCODE"
  }
} finally {
  Pop-Location
}
