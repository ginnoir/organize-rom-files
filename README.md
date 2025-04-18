# organize-rom-files.sh

A powerful Bash script to organize, validate, and generate playlists and metadata for disc-based and cartridge-based video game ROMs. Supports PlayStation, Sega CD, SNES, NES, GBA, and more.

---

## ✅ Feature Summary (v3.0)

### 🎮 Supported File Types

**Disc-based:**
- `.chd`, `.cue`, `.ccd`, `.iso`, `.bin`, `.img`, `.sub`

**Cartridge-based** (with `--include-cartridges`):
- `.sfc`, `.smc`, `.nes`, `.gb`, `.gbc`, `.gba`, `.gen`, `.md`, `.bin`, `.n64`, `.z64`, `.v64`, `.nds`

---

### 🧠 Core Behavior

- Groups multi-disc games into `.m3u` or `.m3u8` playlists
- Validates and rewrites `.cue` content
- Automatically detects UTF-8 encoding
- Moves companion files with `.cue` and `.ccd`
- Detects and confirms fuzzy multi-disc sets (`--aggressive-detection`)

---

### 📁 Folder Layout Options

| Flag                   | Description |
|------------------------|-------------|
| `--per-game-folders`   | Create a folder for each multi-disc game |
| `--move-playlists`     | Place `.m3u` inside game folders |
| `--include-single-disc`| Treat single-disc games like multi-disc for folder/playlist handling |
| `--include-cartridges` | Include ROMs like `.gba`, `.smc`, etc. for metadata and optional organization |
|                        |                                            |
| **Folder Routing Logic** |                                           |
| (Default)              | Only multi-disc games are moved to `gamediscs/` |
| `--include-single-disc` only | All games moved to `gamediscs/` |
| `--per-game-folders`   | All disc games get their own folder (overrides others) |

---

### 🧾 Naming Normalization

| Flag                   | Description |
|------------------------|-------------|
| `--clean-names`        | Strip `(Disc X)`, `(v1.1)`, `(Final)` from playlist/folder names |
| `--normalize-discs`    | Renames tags like `(Disk 1)` → `(Disc 1)` |
| `--normalize-regions`  | Renames tags like `(US)` → `(USA)`, `(Europe)` → `(EU)` |

---

### 📜 Playlist & Cue Support

| Feature                | Description |
|------------------------|-------------|
| `--fix-cue-paths`      | Rewrites `FILE` paths in `.cue` to use only basenames |
| `--sort-m3u-by-disc`   | Sorts playlist entries numerically by disc |
| `--duplicate-m3u8`     | Creates both `.m3u` and `.m3u8` files |
| `--no-backups`         | Disables `.cue.bak` creation when rewriting `.cue` |

---

### 🧪 Validation & Logging

| Feature                | Description |
|------------------------|-------------|
| Default `.cue` validation | Ensures all `FILE` entries exist |
| Multi-FILE `.cue` handling | Prompts to skip or merge if multiple `FILE` lines exist |
| `--verify-playlists`   | Launches `.m3u` in RetroArch (`--auto-load-core`, or prompt) |
| `--log-output`         | Logs all actions to `generate_playlists.log` |

---

### 📚 Metadata Generation

| Flag                     | Output |
|--------------------------|--------|
| `--generate-es-metadata` | `gamelist.xml` |
| `--generate-ra-metadata` | `.lpl` playlist |
| Cartridge support        | Adds to `.lpl` and `gamelist.xml` even without `.m3u` |

---

### 🧠 Advanced Grouping

| Flag                      | Description |
|---------------------------|-------------|
| `--aggressive-detection`  | Fuzzy grouping of multi-disc games |
|                           | Includes preview with confirmation |

---

## 🧾 Changelog

| Version | Features |
|---------|----------|
| **v1.0** | Initial support for `.chd` grouping and `.m3u` |
| **v1.1** | Multi-format disc support |
| **v1.2** | UTF-8 `.m3u8` detection |
| **v1.3** | Disc and region normalization |
| **v1.4** | Cue path rewriting |
| **v1.5** | Cue validation and multi-FILE handling |
| **v1.6** | Logging with `--log-output` |
| **v1.7** | Playlist verification via RetroArch |
| **v1.8** | Metadata output for EmulationStation and RetroArch |
| **v1.9** | `.m3u8` duplication support |
| **v2.0** | Script cleanup and refactoring |
| **v2.1** | Bash completion support |
| **v2.2** | Single-disc playlist option |
| **v2.3** | Fuzzy multi-disc detection |
| **v3.0** | Full cartridge ROM support with system-level metadata |
| **v3.1** | Smart folder routing: `per-game` vs `gamediscs` based on flags |

---

To use:
```bash
chmod +x organize_game_files.sh
./organize_game_files.sh --per-game-folders --generate-ra-metadata --include-cartridges
```
