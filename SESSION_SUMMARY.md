# eSim Copilot Deployment – Complete Guide

**Date:** March 3, 2025  
**Branch:** `Chatbot_Enhancements` (from `pr-434`)  
**Goal:** First deployment of eSim AI Copilot on Ubuntu VM

This document explains every step, every file, every command, and every fix from this deployment session.

---

# Table of Contents

1. [Project Overview](#1-project-overview)
2. [Branch Setup](#2-branch-setup)
3. [Ubuntu VM Setup](#3-ubuntu-vm-setup)
4. [Networking & SSH](#4-networking--ssh)
5. [Code Transfer to VM](#5-code-transfer-to-vm)
6. [Code Fixes & Enhancements](#6-code-fixes--enhancements)
7. [Setup Script – Step by Step](#7-setup-script--step-by-step)
8. [Ollama](#8-ollama)
9. [Launch Flow](#9-launch-flow)
10. [Files Created/Modified – Full Details](#10-files-createdmodified--full-details)
11. [Known Issues](#11-known-issues)
12. [Troubleshooting](#12-troubleshooting)
13. [Push to GitHub](#13-push-to-github)
14. [Quick Reference](#14-quick-reference)

---

# 1. Project Overview

## What is eSim?

**eSim** is an open-source electronics simulation tool (FOSSEE/eSim) that uses:
- **ngspice** – SPICE circuit simulator
- **KiCad** – Schematic capture
- **PyQt5** – Desktop GUI

## What is eSim Copilot?

**eSim Copilot** is an AI assistant integrated into eSim, based on Hariom's PR 434. It provides:

| Feature | Technology |
|---------|------------|
| Text chat | Ollama (LLM) |
| RAG (Retrieval Augmented Generation) | ChromaDB |
| Vision (OCR, image analysis) | PaddleOCR, MiniCPM-V |
| Speech-to-text | Vosk |
| Netlist analysis | FACT-based contract |

## Why Ubuntu VM?

eSim is designed for Linux. Windows has issues with native dependencies (e.g. `contourpy` needs Visual Studio C++ build tools). Ubuntu VM or WSL2 provides a clean Linux environment.

---

# 2. Branch Setup

## Source

- **Base:** `pr-434` (Hariom's Copilot implementation)
- **New branch:** `Chatbot_Enhancements`

## Commands

```bash
cd ~/work/eSim
git fetch origin pull/434/head:pr-434
git checkout -b Chatbot_Enhancements pr-434
```

All enhancements from this session are committed to `Chatbot_Enhancements`.

---

# 3. Ubuntu VM Setup

## 3.1 Download Ubuntu

- **URL:** https://ubuntu.com/download/desktop
- **Version:** Ubuntu 22.04 LTS (64-bit)
- **Size:** ~4 GB ISO

## 3.2 Create VM in VirtualBox

| Setting | Value |
|---------|-------|
| Name | eSim-Ubuntu (or any name) |
| Type | Linux |
| Version | Ubuntu (64-bit) |
| RAM | 4096 MB minimum, 8192 MB recommended for Ollama |
| Disk | VDI, Dynamically allocated, 25 GB |
| ISO | Attach Ubuntu 22.04 ISO to optical drive |

## 3.3 Install Ubuntu

1. Start VM, boot from ISO
2. Choose "Install Ubuntu"
3. Normal install, minimal install optional
4. **Product key:** Leave empty (Ubuntu is free)
5. **User credentials:** e.g. `harvi` / `bhavin`
6. Host name: e.g. `harvi-VirtualBox`

## 3.4 Install Guest Additions (VirtualBox)

- If using shared folder: Devices → Insert Guest Additions CD
- Run the installer from the mounted CD
- Reboot if prompted

## 3.5 Network Adapter

- **Attached to:** Bridged Adapter
- **Name:** Select your host NIC (Wi-Fi or Ethernet)

- If "No Bridged Network Adapter" or "Host Interface Networking driver" error:
  - VirtualBox → Repair → ensure "VirtualBox NDIS6 Bridged Networking Driver" is installed
  - Or use NAT with port forwarding (Host 2222 → Guest 22)

---

# 4. Networking & SSH

## 4.1 Enable SSH on VM

```bash
sudo apt update
sudo apt install -y openssh-server
sudo systemctl enable ssh
sudo systemctl start ssh
```

## 4.2 Find VM IP

```bash
ip addr
```

- **Bridged:** Look for `inet` on `enp0s3` (e.g. `192.168.29.208`)
- **NAT:** `10.0.2.15` – use port forwarding for SSH from host

## 4.3 Static IP (optional)

```bash
sudo nano /etc/netplan/00-installer-config.yaml
```

```yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: no
      addresses:
        - 192.168.29.208/24
      routes:
        - to: default
          via: 192.168.29.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
```

```bash
sudo netplan apply
```

## 4.4 Connect via MobaXterm

1. Session → SSH
2. **Remote host:** `192.168.29.208` (or `localhost` for NAT port 2222)
3. **Port:** `22` (or `2222` for NAT)
4. **Username:** `harvi`
5. Click OK, enter password

## 4.5 X11 Forwarding (for GUI)

MobaXterm includes an X server. X11 forwarding is usually enabled by default. When you run `python Application.py` over SSH, the eSim window appears on your Windows desktop.

---

# 5. Code Transfer to VM

## 5.1 Method A: SCP (direct copy)

**On Windows (PowerShell):**

```powershell
scp -r C:\Users\91900\Downloads\eSIM-Software-AIChatBot\repos\eSim harvi@192.168.29.208:~/
```

Then on VM:

```bash
mkdir -p ~/work
mv ~/eSim ~/work/eSim
cd ~/work/eSim
git checkout Chatbot_Enhancements
```

## 5.2 Method B: Zip (no shared folder)

**On Windows (PowerShell):**

```powershell
cd C:\Users\91900\Downloads\eSIM-Software-AIChatBot
.\repos\eSim\scripts\zip_for_vm.ps1
```

Creates `eSim-for-VM.zip` in the workspace root. Copy into VM (drag-drop, USB, network share).

**On VM:**

```bash
mkdir -p ~/work
cd ~/work
unzip /path/to/eSim-for-VM.zip
cd eSim
git checkout Chatbot_Enhancements
```

## 5.3 Method C: Shared folder (VirtualBox)

1. VM Settings → Shared Folders → Add
2. Folder path: `C:\Users\91900\Downloads\eSIM-Software-AIChatBot\repos`
3. Folder name: `repos`
4. Auto-mount, Make permanent
5. Install Guest Additions, add user to `vboxsf` group
6. On VM: `cp -r /media/sf_repos/eSim ~/work/eSim`

---

# 6. Code Fixes & Enhancements

## 6.1 Line Endings (CRLF → LF)

**Problem:** When running `./scripts/setup_copilot_ubuntu.sh`:

```
/usr/bin/env: 'bash\r': No such file or directory
```

**Cause:** Script was created/edited on Windows. Lines end with `\r\n` (CRLF). Linux expects `\n` (LF). The `\r` is interpreted as part of the shebang, so the system looks for `bash\r` instead of `bash`.

**Fix (on VM):**

```bash
sed -i 's/\r$//' scripts/setup_copilot_ubuntu.sh
```

**Prevention:** Added `.gitattributes` with `*.sh text eol=lf` so Git always uses LF for shell scripts.

---

## 6.2 hdlparse Build Failure

**Problem:** When installing `requirements.txt`:

```
error in hdlparse setup command: use_2to3 is invalid.
ERROR: Failed to build 'hdlparse' when getting requirements to build wheel
```

**Cause:** `hdlparse==1.0.4` uses `use_2to3` in its setup.py. Setuptools 58+ removed support for `use_2to3` (deprecated Python 2→3 conversion).

**Fix:** Install `setuptools==57.5.0` first, then install hdlparse with `--no-build-isolation` (uses the environment's setuptools). Use a constraint file for remaining packages so setuptools stays < 58.

**Changes in `scripts/setup_copilot_ubuntu.sh`:**

```bash
python -m pip install setuptools==57.5.0
python -m pip install hdlparse==1.0.4 --no-build-isolation
echo "setuptools<58" > /tmp/pip-constraints.txt
python -m pip install -c /tmp/pip-constraints.txt -r requirements.txt
python -m pip install -c /tmp/pip-constraints.txt -r requirements-copilot.txt
```

**Changes in `requirements.txt`:** `setuptools>=57.5.0,<58`

---

## 6.3 Workspace Directory Missing

**Problem:** When launching eSim:

```
FileNotFoundError: [Errno 2] No such file or directory: '/home/harvi/.esim/workspace.txt'
```

**Cause:** `Workspace.py` tries to write `~/.esim/workspace.txt` but the `~/.esim` directory is never created. It assumes the directory exists.

**Fix in `src/frontEnd/Workspace.py`:**

```python
esim_dir = os.path.join(user_home, ".esim")
os.makedirs(esim_dir, exist_ok=True)
file = open(os.path.join(esim_dir, "workspace.txt"), 'w')
```

**Manual workaround (if you haven't updated the file):**

```bash
mkdir -p ~/.esim
```

---

## 6.4 Other Enhancements (from earlier)

| Enhancement | Description |
|-------------|-------------|
| Optional STT | `stt_handler.py` – graceful fallback if Vosk/sounddevice missing; app continues without voice |
| ChromaDB path | `knowledge_base.py` – uses `~/.local/share/esim-copilot/chroma` (user-writable) |
| Split requirements | `requirements.txt` (base) + `requirements-copilot.txt` (AI extras) |
| Unused import | `chatbot_core.py` – removed unused `sklearn` |

---

# 7. Setup Script – Step by Step

## Command

```bash
cd ~/work/eSim
chmod +x scripts/setup_copilot_ubuntu.sh
./scripts/setup_copilot_ubuntu.sh
```

## What Each Step Does

### [1/7] System packages

```bash
sudo apt-get install -y \
  python3.10 python3.10-venv python3-pip \
  curl wget unzip \
  ngspice kicad \
  portaudio19-dev \
  libgl1 libglib2.0-0 \
  libxcb-xinerama0 libxcb-cursor0 libxkbcommon-x11-0 \
  libxcb-icccm4 libxcb-image0 libxcb-keysyms1 libxcb-render-util0 \
  libxcb-xinput0 libxcb-shape0 libxcb-randr0 libxcb-util1
```

- **python3.10:** Python runtime
- **ngspice, kicad:** Circuit simulation and schematic capture
- **portaudio19-dev:** Audio for voice input
- **libxcb-*:** Qt/X11 display libraries

### [2/7] Virtualenv

Creates `.venv/` in the repo root. All Python packages are installed in this isolated environment.

### [3/7] Python dependencies

- Upgrades pip, wheel
- Installs setuptools 57.5.0, hdlparse (with workaround)
- Installs `requirements.txt` and `requirements-copilot.txt` with setuptools constraint

### [4/7] PaddlePaddle

Installs PaddlePaddle 2.5.2 (CPU) for PaddleOCR. If this fails, vision features may not work; text chat still works.

### [5/7] Ollama

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

Installs Ollama (LLM server). Runs as systemd service by default.

### [6/7] Ollama models

```bash
ollama pull qwen2.5:3b
ollama pull minicpm-v
ollama pull nomic-embed-text
```

- **qwen2.5:3b:** Main text model
- **minicpm-v:** Vision model

### [7/7] Vosk

Downloads Vosk small English model to `~/.local/share/esim-copilot/vosk-model-small-en-us-0.15` for offline speech-to-text.

---

# 8. Ollama

## Installation

Ollama install script installs it as a systemd service. It starts automatically.

## API

- **URL:** `http://127.0.0.1:11434`
- **Status:** `sudo systemctl status ollama`

## CPU-only mode

In a VM without GPU, Ollama runs in CPU-only mode. Responses may be slower but work.

## Manual start (if not using systemd)

```bash
ollama serve
```

Keep this terminal open while using eSim.

## Run as systemd service (always on)

```bash
sudo systemctl enable ollama
sudo systemctl start ollama
```

---

# 9. Launch Flow

## Launch script

```bash
cd ~/work/eSim
./scripts/launch_esim.sh
```

**What it does:**
1. Creates `~/.esim` if missing
2. Activates `.venv`
3. Runs `QT_QPA_PLATFORM=xcb python Application.py` from `src/frontEnd`

## Manual launch

```bash
cd ~/work/eSim
source .venv/bin/activate
cd src/frontEnd
QT_QPA_PLATFORM=xcb python Application.py
```

## Why `QT_QPA_PLATFORM=xcb`?

Sets Qt to use the XCB (X11) backend. Required for correct display when running over SSH with X11 forwarding.

## Using the Copilot

After eSim opens, click the **eSim Copilot** button in the toolbar to open the AI chat panel.

---

# 10. Files Created/Modified – Full Details

## `.gitattributes`

**Purpose:** Force all `.sh` files to use LF line endings in Git.

**Content:**
```
* text=auto
*.sh text eol=lf
```

---

## `DEPLOY_UBUNTU.md`

**Purpose:** Deployment guide for Ubuntu VM and WSL2.

**Contents:**
- VM setup checklist
- VirtualBox/Hyper-V/VMware instructions
- Shared folder and zip transfer methods
- Setup script steps
- Ollama, ingest, launch commands
- Troubleshooting table
- WSL2 option

---

## `SESSION_SUMMARY.md`

**Purpose:** This document – session summary and deployment guide.

---

## `requirements.txt`

**Changes:**
- `setuptools==65.5.0` → `setuptools>=57.5.0,<58` (for hdlparse compatibility)

---

## `requirements-copilot.txt`

**Purpose:** AI-related dependencies (Ollama client, ChromaDB, PaddleOCR, Vosk, etc.). Separate from base eSim requirements.

---

## `scripts/setup_copilot_ubuntu.sh`

**Purpose:** One-command setup for Ubuntu.

**Changes:**
- hdlparse workaround (setuptools 57.5.0, `--no-build-isolation`, constraint file)
- Full 7-step flow (system packages, venv, deps, PaddlePaddle, Ollama, models, Vosk)

---

## `scripts/launch_esim.sh`

**Purpose:** Single script to launch eSim.

**Contents:**
- Creates `~/.esim` if missing
- Activates venv
- Runs `QT_QPA_PLATFORM=xcb python Application.py` from `src/frontEnd`

**Usage:** `./scripts/launch_esim.sh`

---

## `scripts/zip_for_vm.ps1`

**Purpose:** PowerShell script to zip `eSim` for transfer to VM.

**Usage:**
```powershell
.\repos\eSim\scripts\zip_for_vm.ps1
```

**Output:** `eSim-for-VM.zip` in workspace root.

---

## `src/frontEnd/Workspace.py`

**Purpose:** Create workspace directory before writing.

**Change:** Added `os.makedirs(esim_dir, exist_ok=True)` before opening `workspace.txt` for writing.

---

## `src/chatbot/chatbot_core.py`

**Change:** Removed unused `sklearn` import.

---

## `src/chatbot/stt_handler.py`

**Change:** Made STT optional; graceful fallback if Vosk/sounddevice missing.

---

## `src/chatbot/knowledge_base.py`

**Change:** ChromaDB path set to `~/.local/share/esim-copilot/chroma` (user-writable).

---

# 11. Known Issues

| Issue | Impact | Workaround |
|-------|--------|------------|
| `No module named 'paddle'` (PaddleOCR) | Vision features may not work | Text chat works; install PaddlePaddle if needed |
| Missing `manuals/esim_netlist_analysis_output_contract.txt` | Netlist contract not loaded | Optional; add file if needed |
| `DeprecationWarning: sipPyTypeDict()` | PyQt5/sip deprecation | Safe to ignore |
| `Cannot access Modelica map file` | Modelica config missing | Optional; config.ini in ~/.esim |

---

# 12. Troubleshooting

| Problem | Solution |
|---------|----------|
| `bash\r: No such file or directory` | Run `sed -i 's/\r$//' scripts/setup_copilot_ubuntu.sh` |
| `use_2to3 is invalid` (hdlparse) | Ensure setup script has hdlparse workaround; or manually: `pip install setuptools==57.5.0` then `pip install hdlparse==1.0.4 --no-build-isolation` |
| `FileNotFoundError: ~/.esim/workspace.txt` | Run `mkdir -p ~/.esim` or use updated Workspace.py |
| `ollama: command not found` | Run `curl -fsSL https://ollama.com/install.sh \| sh` |
| Ollama not responding | Run `ollama serve` or ensure systemd service: `sudo systemctl start ollama` |
| GUI doesn't appear (MobaXterm) | Enable X11 forwarding; check `echo $DISPLAY` |
| No Bridged Adapter | Select host NIC in dropdown; or use NAT + port forwarding |
| Host Interface Networking driver | Reinstall VirtualBox; or use NAT |

---

# 13. Push to GitHub

## Fork FOSSEE/eSim

1. Go to https://github.com/FOSSEE/eSim
2. Click **Fork**
3. Fork to your account (e.g. harvi.bhavinpatel2024@gmail.com)

## Add remote and push

```powershell
cd C:\Users\91900\Downloads\eSIM-Software-AIChatBot\repos\eSim
git remote add myfork https://github.com/YOUR_GITHUB_USERNAME/eSim.git
git push myfork Chatbot_Enhancements
```

Replace `YOUR_GITHUB_USERNAME` with your GitHub username.

---

# 14. Quick Reference

| Item | Value |
|------|-------|
| VM IP | 192.168.29.208 |
| SSH user | harvi |
| Repo path | ~/work/eSim |
| Branch | Chatbot_Enhancements |
| Launch | `./scripts/launch_esim.sh` |
| Ollama API | http://127.0.0.1:11434 |
| SCP copy | `scp -r repos\eSim harvi@192.168.29.208:~/work/` |
