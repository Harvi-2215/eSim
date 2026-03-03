# Deploy eSim Copilot on Ubuntu (VM or WSL2)

Use this guide for **first-time deployment** of the AI chatbot on a Linux environment.

---

## Option A: Ubuntu VM (recommended for full GUI)

### 1. Create Ubuntu VM

- **VirtualBox**: Download [Ubuntu 22.04 Desktop](https://ubuntu.com/download/desktop) and create a new VM (≥4 GB RAM, 20 GB disk).
- **Hyper-V** (Windows Pro): Create VM → Install Ubuntu 22.04 from ISO.
- **VMware**: Same steps as VirtualBox.

### 2. Get the code into Ubuntu

**Option 2a – Copy from Windows (if you have the repo locally):**

- Use a shared folder, or zip `repos/eSim` and copy into the VM.
- Unzip in `~/work/eSim` and `cd ~/work/eSim`.
- Ensure you're on branch `Chatbot_Enhancements`: `git checkout Chatbot_Enhancements`

**Option 2b – Clone from GitHub:**

Inside Ubuntu, open Terminal and run:

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Clone repo and switch to Chatbot_Enhancements (or pr-434)
mkdir -p ~/work && cd ~/work
git clone https://github.com/FOSSEE/eSim.git
cd eSim
git fetch origin pull/434/head:pr-434
git checkout -b Chatbot_Enhancements pr-434
# If Chatbot_Enhancements is on your fork: git fetch <your-remote> Chatbot_Enhancements && git checkout Chatbot_Enhancements
```

### 3. Run one-command setup (installs deps, venv, Ollama, models, Vosk)

```bash
chmod +x scripts/setup_copilot_ubuntu.sh
./scripts/setup_copilot_ubuntu.sh
```

### 4. Start Ollama (keep running in a separate terminal)

```bash
ollama serve
```

### 5. Ingest manuals for RAG (optional but recommended)

```bash
cd ~/work/eSim
source .venv/bin/activate
cd src
python ingest.py
```

### 6. Launch eSim with Copilot

```bash
cd ~/work/eSim
source .venv/bin/activate
cd src/frontEnd
QT_QPA_PLATFORM=xcb python Application.py
```

Click the **eSim Copilot** button in the toolbar to open the AI chat.

---

## Option B: WSL2 (Windows Subsystem for Linux)

### 1. Install WSL2 + Ubuntu

In **PowerShell (Admin)**:

```powershell
wsl --install
wsl --set-default-version 2
wsl --install -d Ubuntu-22.04
```

Reboot if prompted, then open **Ubuntu 22.04** from Start.

### 2. Follow steps 2–5 from Option A

All commands are the same inside the Ubuntu terminal.

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| "Ollama not responding" | Run `ollama serve` in a separate terminal before launching eSim |
| GUI doesn't appear (WSL) | Ensure you use the Ubuntu app (not SSH). WSLg provides display automatically |
| Voice input fails | Microphone passthrough in WSL can be unreliable; text + image + netlist still work |
| `python ingest.py` finds no files | Add `.txt` manuals to `src/manuals/` before running ingest |

---

## Branch: Chatbot_Enhancements

This deployment uses the `Chatbot_Enhancements` branch, based on Hariom's PR 434, with:

- Seamless install script for Ubuntu
- User-writable ChromaDB path
- Optional speech-to-text (graceful fallback if Vosk missing)
- Split requirements (base + copilot)
