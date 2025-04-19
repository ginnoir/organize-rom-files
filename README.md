# 🎮 organize-rom-files.sh

A flexible and feature-rich Bash script to organize your retro game library!  
Supports disc-based and cartridge-based formats for PlayStation, Sega, Nintendo, and more.

---

## ✨ Features

- 📀 Auto-detect and group multi-disc games
- 💾 Optional support for single-disc and cartridge-based ROMs
- 🎵 Generate `.m3u` or `.m3u8` playlists for seamless disc switching
- 🧹 Normalize filenames and regions (e.g., `(United States)` → `(USA)`)
- 🛠️ Rewrites `.cue` `FILE` paths and validates existence
- 📁 Organize into per-game folders or a central folder
- 🗃️ Generate metadata:
  - `gamelist.xml` for **EmulationStation**
  - `.lpl` playlist for **RetroArch**
- 🧠 Fuzzy multi-disc detection with `--aggressive-detection`
- 📜 Dry-run support to preview all actions
- 🪵 Optional logging with `--log-output`

---

## 📂 Supported Formats

### 🕹️ Disc-Based
- `.chd`
- `.cue` + `.bin` / `.wav` / `.mp3`
- `.ccd` + `.img` / `.sub`
- `.iso`

### 🗃️ Cartridge-Based
- `.sfc` / `.smc` (SNES)
- `.nes` (NES)
- `.gb`, `.gbc`, `.gba` (Game Boy family)
- `.md`, `.gen` (Mega Drive / Genesis)

---

## 🚀 Usage

```bash
bash organize-rom-files.sh [options]
```

### 🧰 Example

```bash
bash organize-rom-files.sh --include-single-disc --per-game-folders --normalize-discs --fix-cue-paths --generate_ra_metadata
```

---

## ⚙️ Options

```
--dry-run                 Preview actions without making changes
--yes, -y                 Auto-confirm prompts
--include-single-disc     Include single-disc games in playlists
--include-cartridges      Include cartridge ROMs in organization
--normalize-discs         Normalize disc names to "(Disc #)"
--clean-names             Clean playlist and folder names (strip versions, etc.)
--normalize-regions       Standardize region names (e.g., "(United States)" → "(USA)")
--per-game-folders        Place each game in its own folder
--move-playlists          Place playlists inside game folders
--duplicate-m3u8          Create both .m3u and .m3u8 files
--log-output              Save log of actions to `generate_playlists.log`
--fix-cue-paths           Fix `.cue` internal FILE paths
--no-backups              Disable `.cue.bak` backups
--sort-m3u-by-disc        Sort playlist entries by disc number
--aggressive-detection    Use fuzzy matching to detect multi-disc sets
--generate_es_metadata    Generate `gamelist.xml` for EmulationStation
--generate_ra_metadata    Generate `.lpl` playlist files for RetroArch
--help, -h                Show this help menu
```

---

## 🧪 Dry Run Output

Preview mode shows:
- 🎮 Game name
- 📁 Target folder
- 📜 Playlist path
- 📀 Sorted disc files
- ⚠️ Warnings about skipped variant conflicts

---

## 📄 License

MIT

---

Happy organizing! 🕹️📚
