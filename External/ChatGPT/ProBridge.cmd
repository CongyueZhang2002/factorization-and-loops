@echo off
setlocal
set "BRIDGE_DIR=%~dp0"
set "PYTHON=%LOCALAPPDATA%\Programs\Python\Python311\python.exe"
set "NODE=%APPDATA%\Python\Python311\site-packages\playwright\driver\node.exe"

if not exist "%PYTHON%" (
  echo Python executable not found: %PYTHON% 1>&2
  exit /b 1
)
if not exist "%NODE%" (
  echo Node executable not found: %NODE% 1>&2
  exit /b 1
)

"%PYTHON%" "%BRIDGE_DIR%ensure_pro_bridge.py"
if errorlevel 1 exit /b %errorlevel%
set "PRO_BRIDGE_HOST_GUARD=1"

pushd "%BRIDGE_DIR%..\.."
"%NODE%" "%BRIDGE_DIR%pro_bridge.mjs" %*
set "STATUS=%ERRORLEVEL%"
popd
exit /b %STATUS%
