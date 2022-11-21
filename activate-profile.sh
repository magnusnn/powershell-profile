#!/bin/sh

TARGET="$HOME\Documents\PowerShell"
SOURCE="$HOME\git\powershell-profile"
FILENAME="Microsoft.PowerShell_profile.ps1"
mkdir -p "$TARGET" && cp "$SOURCE\\$FILENAME" "$TARGET\\$FILENAME"
