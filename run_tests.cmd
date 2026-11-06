@echo off
:: Runs the whole GdUnit4 test suite headless (no window).
::
::   run_tests.cmd                     run every test under tests/
::   run_tests.cmd -a res://tests/run  run only one folder (any GdUnit4 option works)
::
:: Finds Godot from the GODOT_BIN environment variable, then `godot` on PATH,
:: then the winget install folder. Exit code 0 means every test passed.
setlocal enabledelayedexpansion
cd /d "%~dp0"

set "GODOT=%GODOT_BIN%"
if "!GODOT!"=="" (
    for /f "delims=" %%G in ('where godot 2^>nul') do if "!GODOT!"=="" set "GODOT=%%G"
)
if "!GODOT!"=="" (
    for /d %%D in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine*") do (
        for %%G in ("%%D\Godot_v4.7*_win64_console.exe") do set "GODOT=%%~fG"
    )
)
if "!GODOT!"=="" (
    echo Could not find Godot 4.7. Set GODOT_BIN to the path of Godot_v4.7.x_win64_console.exe
    exit /b 1
)

set "TEST_ARGS=%*"
if "!TEST_ARGS!"=="" set "TEST_ARGS=-a res://tests"

:: Import first: on a fresh clone Godot has not yet built its class list
:: (.godot/ is gitignored), and tests would fail to find Run, RunConfig, ...
"!GODOT!" --headless --path . --import >nul 2>&1

:: --ignoreHeadlessMode: our tests never use UI input, so headless is fine.
:: --remote-debug to an unused port stops Godot dropping into its interactive
:: debugger on a script error (which would hang the command).
"!GODOT!" --headless --path . -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode !TEST_ARGS!
set "EXIT_CODE=!ERRORLEVEL!"

if "!EXIT_CODE!"=="0" (echo All tests passed.) else (echo Tests FAILED, exit code !EXIT_CODE!.)
exit /b !EXIT_CODE!
