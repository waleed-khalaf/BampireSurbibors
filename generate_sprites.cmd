@echo off
:: Draws the draft sprites into art/ (see art/README.md).
::
::   generate_sprites.cmd           create only the sheets that don't exist yet
::   generate_sprites.cmd --force   redraw every sheet, overwriting your edits
setlocal
cd /d "%~dp0"
call "%~dp0tools\find_godot.cmd" || exit /b 1

"%GODOT%" --headless --path . -s res://tools/sprite_generator/generate_sprites.gd -- %*
if errorlevel 1 (
    echo Sprite generation FAILED.
    exit /b 1
)

:: Let Godot import the new PNGs now, so F5 works without opening the editor.
"%GODOT%" --headless --path . --import >nul 2>&1
echo Sprites are in art\. Godot reimports them automatically when they change.
