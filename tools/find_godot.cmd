@echo off
:: Sets GODOT to the Godot 4.7 console executable for the calling script.
::
::   call "%~dp0tools\find_godot.cmd" || exit /b 1
::
:: Looks at the GODOT_BIN environment variable, then `godot` on PATH, then the
:: winget install folder. No setlocal here on purpose: GODOT has to survive
:: back into the caller.
set "GODOT=%GODOT_BIN%"
if not defined GODOT (
    for /f "delims=" %%G in ('where godot 2^>nul') do if not defined GODOT set "GODOT=%%G"
)
if not defined GODOT (
    for /d %%D in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine*") do (
        for %%G in ("%%D\Godot_v4.7*_win64_console.exe") do set "GODOT=%%~fG"
    )
)
if not defined GODOT (
    echo Could not find Godot 4.7. Set GODOT_BIN to the path of Godot_v4.7.x_win64_console.exe
    exit /b 1
)
if not exist "%GODOT%" (
    echo Godot not found at "%GODOT%". Check the GODOT_BIN environment variable.
    exit /b 1
)
exit /b 0
