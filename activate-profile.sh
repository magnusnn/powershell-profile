#!/bin/sh

TARGET="$HOME\Documents\PowerShell"
SOURCE="$HOME\git\powershell-profile"
FILENAME="Microsoft.PowerShell_profile.ps1"
MODULES="Modules"
mkdir -p "$TARGET" && cp "$SOURCE\\$FILENAME" "$TARGET\\$FILENAME" && cp -r "$SOURCE\\$MODULES" "$TARGET"
