# Changelog

## v3.1 (2024-04)
- Added full support for cartridge-based ROMs via `--include-cartridges`
- Improved single-disc game handling: now requires `--include-single-disc`
- Prevents playlist generation for multiple single-disc versions (e.g., v1.0, v1.1)
- Added `--generate_es_metadata` and `--generate_ra_metadata` flags for EmulationStation and RetroArch
- Rewrites `.cue` FILE paths and validates presence of referenced files
- Improved fuzzy multi-disc detection with `--aggressive-detection`
- Auto-sorts playlist entries by disc number using extracted numeric values
- Added optional logging with `--log-output`
- Added `--duplicate-m3u8` to create both `.m3u` and `.m3u8` files
- Supports folder structure customization (`--per-game-folders`, `--move-playlists`)
- Fixed bugs in help menu and flag parser
- Enhanced dry-run preview formatting and clarity
