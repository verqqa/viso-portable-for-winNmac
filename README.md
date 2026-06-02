# VisoMaster Aitotts Edition

A custom portable launcher for [VisoMaster Fusion](https://github.com/VisoMasterFusion/VisoMaster-Fusion) with additional fixes and improvements. Supports Windows and macOS.

> **This repo does not contain the VisoMaster Fusion source code.**
> All app code belongs to the original authors. See [VisoMaster Fusion](https://github.com/VisoMasterFusion/VisoMaster-Fusion) for the full source.

## What's New in This Edition

- **Background Changer** — swap or replace backgrounds in real time alongside face swapping
- **Webcam Fix** — resolved camera issues for smoother live webcam workflows
- **Mac Support** — fully working on macOS (Apple Silicon and Intel)
- **Optimized for RTX 3000, 4000, and 5000 series GPUs**

## How to Download & Use

### Option 1 — Portable (Easiest, No Setup)

**Windows:**
1. Download [`Start_Portable.bat`](https://github.com/verqqa/visomaster-aitotts-edition/raw/master/Start_Portable.bat)
2. Place it in a new empty folder
3. Run it — it downloads everything automatically (Python, FFmpeg, models, dependencies)
4. Always launch from that same file going forward

**Mac:**
1. Download [`Start_Portable.command`](https://github.com/verqqa/visomaster-aitotts-edition/raw/master/Start_Portable.command)
2. Place it in a new empty folder
3. Run it — it downloads everything automatically
4. Always launch from that same file going forward

### Option 2 — Clone the Source Code

If you want the full source code with all my changes:

```
git clone https://github.com/verqqa/VisoMaster-Fusion.git
cd VisoMaster-Fusion
```

Then follow the installation steps in the repo README.

## Requirements

**Windows**
- Windows 10 / 11 64-bit
- Nvidia RTX 3000, 4000, or 5000 series GPU
- 8 GB VRAM recommended (6 GB minimum)
- Nvidia driver `>=576.57`
- 20–30 GB free disk space
- Internet connection on first run

**Mac**
- macOS (Apple Silicon or Intel)
- 20–30 GB free disk space
- Internet connection on first run

## Credits

This project is built on top of [VisoMaster Fusion](https://github.com/VisoMasterFusion/VisoMaster-Fusion), originally created by [@argenspin](https://github.com/argenspin) and [@Alucard24](https://github.com/alucard24), with contributions from the wider community.

All credit for the core application goes to the original authors.

## Disclaimer

This project is for personal, ethical, and legal use only. Users are solely responsible for how they use this software. Do not use it to create content without the consent of the people involved. The author of this fork takes no responsibility for misuse.
