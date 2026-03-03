#!/usr/bin/env bash
# Launch eSim with Copilot
# Usage: ./scripts/launch_esim.sh   or   bash scripts/launch_esim.sh

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Ensure .esim dir exists (avoids workspace error)
mkdir -p ~/.esim

# Activate venv and launch
source .venv/bin/activate
cd src/frontEnd
QT_QPA_PLATFORM=xcb python Application.py
