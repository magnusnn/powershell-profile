#!/bin/sh

TARGET="$HOME\Documents\PowerShell"
FILENAME="Microsoft.PowerShell_profile.ps1"
mkdir -p "$TARGET" && cp "$FILENAME" "$TARGET\\$FILENAME"
