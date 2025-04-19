# organize_game_files.sh

This Bash script organizes disc-based video game ROMs into structured folders with optional playlist (`.m3u`/`.m3u8`) generation, metadata files, cue path rewriting, and more. It supports CHD, BIN/CUE, CCD/IMG/SUB, and ISO formats, and intelligently groups multi-disc games while optionally including single-disc and cartridge-based ROMs.

## Features

- Detect and group multi-disc games
- Optional support for single-disc and cartridge-based games
- Generate `.m3u` or `.m3u8` playlists
- Normalize region and disc naming
- Rewrites `.cue` file `FILE` paths
- Optional playlist and disc organization into per-game folders
- Create `gamelist.xml` for EmulationStation and `.lpl` for RetroArch
- Detect duplicate single-disc variants (e.g., v1.0 and v1.1) and skip playlist creation
- Dry-run mode with preview of actions
- Auto-disc number sorting in playlists
- Logging support with `--log-output`

## Supported Formats

- `.chd`
- `.cue` (with `.bin`, `.wav`, `.mp3`, etc.)
- `.ccd` (with `.img`, `.sub`)
- `.iso`

## Usage

```bash
bash organize_game_files.sh [options]
```

## Key Options

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
--aggressive-detection    Detect multi-disc games with inconsistent names
--generate_es_metadata    Generate `gamelist.xml` for EmulationStation
--generate_ra_metadata    Generate `.lpl` playlist files for RetroArch
```

## Example

```bash
bash organize_game_files.sh --include-single-disc --per-game-folders --normalize-discs --fix-cue-paths --generate_ra_metadata
```

---

## Dry Run Preview

Includes:
- Game title
- Target folder
- Playlist path
- Sorted disc filenames

---

## License

MIT
