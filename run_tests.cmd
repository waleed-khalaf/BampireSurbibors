@echo off
:: Runs the whole GdUnit4 test suite headless (no window).
::
::   run_tests.cmd                     run every test under tests/
::   run_tests.cmd -a res://tests/run  run only one folder (any GdUnit4 option works)
::
:: Finds Godot through tools\find_godot.cmd. Exit code 0 means every test
:: passed.
::
:: Several runs can go at once (for example agents working in separate git
:: worktrees). Everything a run writes stays inside its own checkout, so runs
:: in different checkouts never touch each other's files. Runs in the same
:: checkout would share its .godot\ import cache and reports\ folder, so they
:: take turns: a run waits while another holds reports\run_tests.lock.
setlocal enabledelayedexpansion
cd /d "%~dp0"

call "%~dp0tools\find_godot.cmd" || exit /b 1

set "TEST_ARGS=%*"
if "!TEST_ARGS!"=="" set "TEST_ARGS=-a res://tests"

if not exist reports mkdir reports
set "LOCK_FILE=%~dp0reports\run_tests.lock"
set "EXIT_CODE="
set "SAID_WAITING="

:: Windows keeps a file open for writing locked against other writers. The
:: redirect "9>file" holds that lock for as long as the block runs, and fails
:: at once if another run holds it. The lock goes away when the run ends, even
:: if it crashes, so a leftover lock file never blocks anything.
:: The 2>nul hides the "file is being used by another process" message while
:: waiting. It covers the whole block, so the suite sends its own error output
:: to the console explicitly (2>&1 below). The wait between tries is a ping of
:: about a second, because "timeout" refuses to run without a keyboard.
:wait_for_lock
2>nul (
    9>"!LOCK_FILE!" (
        call :run_suite
    )
)
if not defined EXIT_CODE (
    if not defined SAID_WAITING (
        echo Another test run is using this folder. Waiting for it to finish...
        set "SAID_WAITING=1"
    )
    ping -n 2 127.0.0.1 >nul
    goto wait_for_lock
)

if "!EXIT_CODE!"=="0" (echo All tests passed.) else (echo Tests FAILED, exit code !EXIT_CODE!.)
exit /b !EXIT_CODE!


:run_suite
:: Import first: on a fresh clone Godot has not yet built its class list
:: (.godot/ is gitignored), and tests would fail to find Run, RunConfig, ...
:: The import is noisy, so its output goes to a log in this checkout's
:: reports\ folder and is only shown if it fails.
set "IMPORT_LOG=%~dp0reports\godot_import.log"
"!GODOT!" --headless --path . --import >"!IMPORT_LOG!" 2>&1
if errorlevel 1 (
    type "!IMPORT_LOG!"
    echo Godot import FAILED, see the output above.
    set "EXIT_CODE=1"
    exit /b 1
)

:: --ignoreHeadlessMode: our tests never use UI input, so headless is fine.
:: No -d (debug) flag: with it, a script error drops Godot into its
:: interactive debugger. Without it, GdUnit4 still reports script errors as
:: failed tests and returns a non-zero exit code.
"!GODOT!" --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode !TEST_ARGS! 2>&1
set "EXIT_CODE=!ERRORLEVEL!"
exit /b !EXIT_CODE!
