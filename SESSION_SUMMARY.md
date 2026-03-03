# eSim Copilot Deployment – Session Summary

**Date:** March 3, 2025  
**Branch:** `Chatbot_Enhancements` (from `pr-434`)  
**Goal:** First deployment of eSim AI Copilot on Ubuntu VM

---

## 1. Project Context

- **eSim Copilot** – AI-assisted electronics simulation tool (FOSSEE/eSim)
- Based on Hariom's PR 434 (PyQt5, RAG, vision, voice, netlist analysis)
- Target: Ubuntu 22.04 (VM or WSL2)

---

## 2. Branch Setup

- Created branch `Chatbot_Enhancements` from `pr-434`
- All enhancements committed to this branch

---

## 3. Ubuntu VM Setup

| Step | Action |
|------|--------|
| 1 | Downloaded Ubuntu 22.04 Desktop ISO |
| 2 | Created VM in VirtualBox (4–8 GB RAM, 25 GB disk) |
| 3 | Installed Ubuntu; user: `harvi`, password: `bhavin` |
| 4 | Installed SSH: `sudo apt install openssh-server` |
| 5 | Configured Bridged Adapter for network (after fixing "No Bridged Adapter" – selected host NIC) |
| 6 | VM IP: `192.168.29.208` (static config via Netplan) |
| 7 | Connected via MobaXterm SSH |

---

## 4. Code Transfer to VM

- **Method:** SCP from Windows to VM
- **Path:** `C:\Users\91900\Downloads\eSIM-Software-AIChatBot\repos\eSim` → `harvi@192.168.29.208:~/work/eSim`
- **Script:** `scripts/zip_for_vm.ps1` for zipping; `scp -r` for direct copy

---

## 5. Code Fixes & Enhancements

### 5.1 Line endings (CRLF → LF)

- **Issue:** `bash\r: No such file or directory` when running setup script
- **Fix:** `sed -i 's/\r$//' scripts/setup_copilot_ubuntu.sh`
- **Prevention:** Added `.gitattributes` with `*.sh text eol=lf`

### 5.2 hdlparse build failure

- **Issue:** `use_2to3 is invalid` (setuptools ≥58 removed support)
- **Fix:** Install `setuptools==57.5.0` first; install `hdlparse==1.0.4 --no-build-isolation`; use `-c` constraint for remaining deps
- **Files:** `scripts/setup_copilot_ubuntu.sh`, `requirements.txt`

### 5.3 Workspace directory missing

- **Issue:** `FileNotFoundError: ~/.esim/workspace.txt` – `.esim` dir not created
- **Fix:** `Workspace.py` – add `os.makedirs(esim_dir, exist_ok=True)` before writing
- **Manual:** `mkdir -p ~/.esim`

### 5.4 Other enhancements (from earlier)

- Optional STT (graceful fallback if Vosk missing)
- ChromaDB path: `~/.local/share/esim-copilot/chroma`
- Split requirements: `requirements.txt` + `requirements-copilot.txt`
- `DEPLOY_UBUNTU.md` – deployment guide
- `scripts/setup_copilot_ubuntu.sh` – one-command setup

---

## 6. Setup Script Flow

```bash
./scripts/setup_copilot_ubuntu.sh
```

1. Install system packages (python3.10, ngspice, kicad, portaudio, xcb libs)
2. Create `.venv`
3. Install Python deps (with hdlparse workaround)
4. Install PaddlePaddle (CPU)
5. Install Ollama (`curl -fsSL https://ollama.com/install.sh | sh`)
6. Pull models: qwen2.5:3b, minicpm-v, nomic-embed-text
7. Download Vosk model to `~/.local/share/esim-copilot/`

---

## 7. Launch Flow

### Ollama

- Installed as systemd service (runs automatically)
- API: `127.0.0.1:11434`
- CPU-only mode (no GPU in VM)

### eSim

```bash
./scripts/launch_esim.sh
```

Or manually:

```bash
cd ~/work/eSim
source .venv/bin/activate
cd src/frontEnd
QT_QPA_PLATFORM=xcb python Application.py
```

---

## 8. Files Created/Modified

| File | Change |
|------|--------|
| `.gitattributes` | LF for `.sh` files |
| `DEPLOY_UBUNTU.md` | VM setup, SSH, deployment steps |
| `requirements.txt` | setuptools<58 for hdlparse |
| `requirements-copilot.txt` | AI deps (new) |
| `scripts/setup_copilot_ubuntu.sh` | Full setup, hdlparse fix |
| `scripts/launch_esim.sh` | Single launch script |
| `scripts/zip_for_vm.ps1` | Zip eSim for VM transfer |
| `src/frontEnd/Workspace.py` | Create `.esim` dir before write |
| `src/chatbot/chatbot_core.py` | Removed unused sklearn |
| `src/chatbot/stt_handler.py` | Optional STT |
| `src/chatbot/knowledge_base.py` | ChromaDB path |

---

## 9. Known Issues

- **PaddleOCR:** `No module named 'paddle'` – vision features may be limited; text chat works
- **Netlist contract:** Missing `manuals/esim_netlist_analysis_output_contract.txt` – optional
- **DeprecationWarnings:** PyQt5/sip – safe to ignore

---

## 10. Quick Reference

| Item | Value |
|------|-------|
| VM IP | 192.168.29.208 |
| SSH user | harvi |
| Repo path | ~/work/eSim |
| Branch | Chatbot_Enhancements |
| Launch | `./scripts/launch_esim.sh` |
