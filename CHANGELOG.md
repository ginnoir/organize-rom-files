# Changelog

All notable changes to `organize_game_files.sh` are documented here.

## [3.1]
### Added
- Smart folder routing for disc files:
  - Multi-disc only → `gamediscs/` by default
  - All games → `gamediscs/` if `--include-single-disc` is enabled
  - All games → individual folders if `--per-game-folders` is enabled (overrides others)
- Updated README and script banner with version 3.1

## [3.0]
### Added
- Full support for cartridge ROMs via `--include-cartridges`
- Cartridge metadata for RetroArch (`.lpl`) and EmulationStation (`gamelist.xml`)

## [2.3]
- Fuzzy multi-disc detection with preview and prompt (`--aggressive-detection`)
...

(Full version history in README)
