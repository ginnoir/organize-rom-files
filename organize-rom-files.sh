# organize_game_files.sh - Version 3.1
# Maintained Bash utility for disc and cartridge game organization

#!/bin/bash

set -e

# Flags
DRY_RUN=0
AUTO_YES=0
NORMALIZE_DISCS=0
PER_GAME_FOLDERS=0
MOVE_PLAYLISTS=0
CLEAN_NAMES=0
NORMALIZE_REGIONS=0
FIX_CUE_PATHS=0
SORT_M3U_BY_DISC=1
NO_BACKUPS=0
INCLUDE_SINGLE_DISC=0
INCLUDE_CARTRIDGES=0
LOG_OUTPUT=0
AGGRESSIVE_DETECTION=0
VERIFY_PLAYLISTS=0
GENERATE_ES_METADATA=0
GENERATE_RA_METADATA=0
LOG_FILE=organize-rom-files.log



show_help() {
cat <<'EOF'
}
Usage: $0 [options]

Organize video game disc files into structured folders with .m3u or .m3u8 playlists.
Supports CHD, CUE/BIN, CCD/IMG/SUB, ISO. Automatically groups multi-disc sets.

Options:
  --dry-run               Preview actions without making any changes
  --yes, -y               Automatically confirm all actions (no prompt)
  --normalize-discs       Rename all disc identifiers to "(Disc #)"
  --per-game-folders      Create a separate folder for each multi-disc game
  --move-playlists        Move the .m3u or .m3u8 file into the game folder
                          (only applies with --per-game-folders)
  --clean-names           Strip (Disc X), (vX.X), etc. from folder and playlist names
  --normalize-regions     Normalize region tags in names:
                          (US), (United States) → (USA)
                          (Europe) → (EU), (Japan) → (JP)
  --fix-cue-paths         Rewrites FILE entries in .cue files to just the local filename
  --no-backups            Do not create .cue.bak backups when rewriting .cue files
  --include-single-disc    Include single-disc games in folder/playlist generation
  --include-cartridges     Include cartridge-based ROMs in organization
  --log-output             Write a log file of all actions to generate_playlists.log
  --aggressive-detection   Use fuzzy matching for multi-disc grouping
  --verify-playlists       Attempt to launch each .m3u file in RetroArch to test validity
  --generate_es_metadata  Generate gamelist.xml files for use with EmulationStation
  --generate_ra_metadata  Generate .lpl playlists for use with RetroArch
  --help, -h              Show this help menu

Examples:
  organize-rom-file.sh
    Group multi-disc sets and move into 'gamedisk/', keeping .m3u in root

  organize-rom-file.sh --per-game-folders --move-playlists
    Place each game in its own folder with .m3u inside

  organize-rom-file.sh --fix-cue-paths --sort-m3u-by-disc --normalize-discs --yes
    Fully normalize, clean, and correct cue playlists with no prompt
EOF
}

# Parse args
for arg in "$@"; do
    case "$arg" in
        --auto-yes|-y) AUTO_YES=1 ;;
        --include-single-disc) INCLUDE_SINGLE_DISC=1 ;;
        --include-cartridges) INCLUDE_CARTRIDGES=1 ;;
        --log-output) LOG_OUTPUT=1 ;;
        --aggressive-detection) AGGRESSIVE_DETECTION=1 ;;
        --verify-playlists) VERIFY_PLAYLISTS=1 ;;
        --no-backups) NO_BACKUPS=1 ;;
        --dry-run) DRY_RUN=1 ;;
        --normalize-discs) NORMALIZE_DISCS=1 ;;
        --per-game-folders) PER_GAME_FOLDERS=1 ;;
        --move-playlists) MOVE_PLAYLISTS=1 ;;
        --clean-names) CLEAN_NAMES=1 ;;
        --normalize-regions) NORMALIZE_REGIONS=1 ;;
        --fix-cue-paths) FIX_CUE_PATHS=1 ;;
        --sort-m3u-by-disc) SORT_M3U_BY_DISC=1 ;;
		--generate_es_metadata) GENERATE_ES_METADATA=1 ;;
		--generate_ra_metadata) GENERATE_RA_METADATA=1 ;;
        --help|-h) show_help; exit 0 ;;
	esac
done

check_dependencies() {
    local missing=0
    local deps=("awk" "sed" "grep" "basename" "dirname" "sort" "mv" "cp" "realpath")
    for bin in "${deps[@]}"; do
        if ! command -v "$bin" &>/dev/null; then
            echo "[!] Missing required command: $bin"
            missing=1
        fi
    done
    if [ "$VERIFY_PLAYLISTS" -eq 1 ] && ! command -v retroarch &>/dev/null; then
		echo "[!] Warning: --verify-playlists was set but RetroArch is not installed."
		fi
    if [ "$missing" -eq 1 ]; then
        echo "[!] Please install the missing dependencies and try again."
        exit 1
    fi
}
check_dependencies


if [ "$LOG_OUTPUT" -eq 1 ]; then
    exec > >(tee -a "$LOG_FILE") 2>&1
    echo "[*] Logging enabled: $LOG_FILE"
fi

normalize_region() {
    local name="$1"
    if [ "$NORMALIZE_REGIONS" -eq 1 ]; then
        name=$(echo "$name" | sed -E 's/\(United States\)|\(US\)/\(USA\)/Ig' \
                                | sed -E 's/\(Europe\)/\(EU\)/Ig' \
                                | sed -E 's/\(Japan\)/\(JP\)/Ig')
    fi
    echo "$name"
}

generate_clean_name() {
    local name="$1"
    name=$(echo "$name" | sed -E 's/ ?\((Disc|Disk|CD)[ ]?[0-9]+\)//I' \
                         | sed -E 's/ \(v[0-9]+\.[0-9]+\)//I' \
                         | sed -E 's/\.(chd|cue|ccd|iso|bin|img)$//I')
    echo "$(normalize_region "$name")"
}

requires_utf8() {
    for f in "$@"; do
        if [[ "$(basename "$f")" =~ [^[:ascii:]] ]]; then return 0; fi
    done
    return 1
}

get_companion_files() {
    local base="$1"
    local -n _result=$2
    _result=()
    for ext in bin img sub wav mp3; do
        [ -e "${base}.${ext}" ] && _result+=("${base}.${ext}")
    done
}

fix_cue_paths() {
    local cue="$1"
    local cue_dir
    cue_dir=$(dirname "$cue")

    local file_line
    file_line=$(grep -i '^file ' "$cue" | head -1)
    if [ -z "$file_line" ]; then
        return
    fi

    local original_target
    original_target=$(echo "$file_line" | cut -d'"' -f2)
    local basename_target
    basename_target=$(basename "$original_target")

    if [ ! -e "$cue_dir/$basename_target" ]; then
        echo "[!] Warning: '$basename_target' referenced in $cue does not exist in the same directory. Skipping rewrite."
        return
    fi

    if [ "$DRY_RUN" -eq 1 ]; then
        echo "[~] Would rewrite FILE line in $cue to: FILE \"$basename_target\""
        return
    fi

    if [ "$NO_BACKUPS" -ne 1 ]; then
        cp -n -- "$cue" "$cue.bak"
    fi

    awk -v bn="$basename_target" '
        BEGIN { OFS = "" }
        tolower($1) == "file" {
            print "FILE \"" bn "\""
            next
        }
        { print }
    ' "$cue" > "${cue}.fixed" && mv "${cue}.fixed" "$cue"
}

verify_playlist() {
    local playlist="$1"

    if command -v retroarch >/dev/null 2>&1; then
        echo "[*] Verifying with RetroArch (auto-detect core): $playlist"
        retroarch --verbose --auto-load-core "$playlist" >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "[✓] RetroArch auto-loaded playlist successfully: $playlist"
        else
            echo "[!] Auto-load failed for: $playlist"
            echo "    Please specify a platform. Available options:"
            echo "    - psx"
            echo "    - sega_cd"
            echo "    - saturn"
            echo "    - 3do"
            read -rp "    Enter platform: " platform

            case "$platform" in
                psx) core="/path/to/pcsx_rearmed_libretro.so" ;;
                sega_cd) core="/path/to/genesis_plus_gx_libretro.so" ;;
                saturn) core="/path/to/beetle_saturn_libretro.so" ;;
                3do) core="/path/to/opera_libretro.so" ;;
                *)
                    echo "[!] Unsupported platform: $platform"
                    return
                    ;;
            esac

            echo "    Using core: $core"
            retroarch -L "$core" "$playlist" >/dev/null 2>&1
            if [ $? -eq 0 ]; then
                echo "[✓] RetroArch verified with $core: $playlist"
            else
                echo "[!] RetroArch failed to load with $core: $playlist"
            fi
        fi
    fi
}


normalize_title_for_fuzzy_match() {
    local name="$1"
    name=$(echo "$name" | sed -E 's/ *\((Disc|Disk|CD|D|Part|Side)[ ]?[0-9]+\)//I')
    name=$(echo "$name" | sed -E 's/ *\((v[0-9]+\.[0-9]+|Final|Bonus|Special|Rev[0-9]+)\)//I')
    name=$(echo "$name" | sed -E 's/\.(chd|cue|ccd|iso|bin|img|sub)$//I')
    echo "$name"
}



get_system_for_rom() {
    local filename="$1"
    case "$filename" in
        *.sfc|*.smc) echo "Nintendo - SNES" ;;
        *.nes) echo "Nintendo - NES" ;;
        *.gb|*.gbc) echo "Nintendo - Game Boy" ;;
        *.gba) echo "Nintendo - Game Boy Advance" ;;
        *.gen|*.md|*.bin) echo "Sega - Genesis" ;;
        *.n64|*.z64|*.v64) echo "Nintendo - Nintendo 64" ;;
        *.nds) echo "Nintendo - DS" ;;
        *) echo "Other" ;;
    esac
}



# Determine destination for disc files
determine_target_folder() {
    local game_name="$1"

    if [ "$PER_GAME_FOLDERS" -eq 1 ]; then
        echo "./$game_name"
    elif [ "$INCLUDE_SINGLE_DISC" -eq 1 ] || [ "${#files[@]}" -gt 1 ]; then
        mkdir -p "./gamediscs"
        echo "./gamediscs"
    else
        echo "."
    fi
}


validate_cue_file() {
    local cue="$1"
    local cue_dir
    cue_dir=$(dirname "$cue")

    local file_refs
    mapfile -t file_refs < <(grep -i '^file ' "$cue" | cut -d'"' -f2)

    local count=${#file_refs[@]}
    if (( count == 0 )); then
        echo "[!] $cue has no FILE entries. Skipping."
        return 1
    fi

    if (( count > 1 )); then
        echo "[!] $cue has multiple FILE entries (${count})."
        echo "    This may not be supported by some emulators."

        while true; do
            read -rp "    Do you want to [i]gnore this .cue or [s]kip this game? (i/s): " choice
            case "$choice" in
                [iI]) echo "    → Ignoring this .cue"; return 1 ;;
                [sS]) echo "    → Skipping game"; return 2 ;;
                *) echo "    Please enter 'i' or 's'." ;;
            esac
        done
    fi

    # Validate the file exists
    local base_ref
    base_ref=$(basename "${file_refs[0]}")
    if [ ! -f "$cue_dir/$base_ref" ]; then
        echo "[!] Missing referenced file '$base_ref' in $cue"
        return 1
    fi

    return 0
}

generate_es_metadata() {
    local name="$1"
    local target_path="$2"
    local output_dir="$3"

    echo "[*] Generating EmulationStation metadata for: $name"
    mkdir -p "$output_dir"
    cat <<'EOF' > "$output_dir/gamelist.xml"
<gameList>
  <game>
    <path>./$target_path</path>
    <name>$name</name>
    <desc>Game file: $name</desc>
  </game>
</gameList>
EOF
}

generate_ra_metadata() {
    local name="$1"
    local target_path="$2"
    local output_dir="$3"
    local platform_hint="$4"

    echo "[*] Generating RetroArch .lpl metadata for: $name"
    local db_name="Sony - PlayStation.lpl"
    case "$platform_hint" in
        snes|sfc) db_name="Nintendo - Super Nintendo Entertainment System.lpl" ;;
        nes) db_name="Nintendo - Nintendo Entertainment System.lpl" ;;
        gb) db_name="Nintendo - Game Boy.lpl" ;;
        gbc) db_name="Nintendo - Game Boy Color.lpl" ;;
        gba) db_name="Nintendo - Game Boy Advance.lpl" ;;
        md|genesis) db_name="Sega - Mega Drive - Genesis.lpl" ;;
        *) db_name="Sony - PlayStation.lpl" ;;
    esac

    cat <<'EOF' > "$output_dir/$name.lpl"
{
  "version": "1.0",
  "items": [
    {
      "path": "./$target_path",
      "label": "$name",
      "core_path": "DETECT",
      "core_name": "DETECT",
      "crc32": "00000000|crc",
      "db_name": "$db_name"
    }
  ]
}
EOF
}

# Main file grouping
DISC_PATTERN='\((Disc|Disk|CD)[ ]?[0-9]+\)'
declare -A game_groups
echo "[*] Scanning for disc files..."

while IFS= read -r file; do
    basefile=$(basename "$file")

    if [ "$NORMALIZE_DISCS" -eq 1 ]; then
        newname=$(echo "$basefile" | sed -E 's/\((Disc|Disk|CD)[ ]?([0-9]+)\)/\(Disc \2\)/I')
        if [ "$newname" != "$basefile" ]; then
            echo "[~] Renaming: $basefile → $newname"
            [ "$DRY_RUN" -eq 0 ] && mv -i -- "$basefile" "$newname"
            basefile="$newname"
        fi
    fi

    key=$(generate_clean_name "$basefile")
    game_groups["$key"]+=$'\n'"$basefile"
done < <(if [ "$INCLUDE_CARTRIDGES" -eq 1 ]; then
  find . -maxdepth 1 -type f \( -iname "*.chd" -o -iname "*.cue" -o -iname "*.ccd" -o -iname "*.iso" -o -iname "*.bin" -o -iname "*.img" -o \
                         -iname "*.sfc" -o -iname "*.smc" -o -iname "*.nes" -o -iname "*.gen" -o -iname "*.md" -o \
                         -iname "*.gba" -o -iname "*.gbc" -o -iname "*.gb" -o -iname "*.n64" -o -iname "*.z64" -o -iname "*.v64" -o -iname "*.nds" \)
else
  find . -maxdepth 1 -type f \( -iname "*.chd" -o -iname "*.cue" -o -iname "*.ccd" -o -iname "*.iso" -o -iname "*.bin" -o -iname "*.img" \)
fi | sed 's|^\./||')

# If aggressive detection is enabled, build fuzzy matches
if [ "$AGGRESSIVE_DETECTION" -eq 1 ]; then
    echo "[*] Running aggressive multi-disc grouping..."
    declare -A fuzzy_groups

    for file in "${!game_groups[@]}"; do
        IFS=$'\n' read -r -d '' -a grouped_files < <(printf '%s\0' "${game_groups[$file]}" | sort -Vz)
        for f in "${grouped_files[@]}"; do
            fuzzy_key=$(normalize_title_for_fuzzy_match "$f")
            fuzzy_groups["$fuzzy_key"]+=$'\n'"$f"
        done
    done

    # Show potential fuzzy matches with preview
    for fuzzy_key in "${!fuzzy_groups[@]}"; do
        IFS=$'\n' read -r -d '' -a match_files < <(printf '%s\0' "${fuzzy_groups[$fuzzy_key]}" | sort -Vz)
        [ "${#match_files[@]}" -lt 2 ] && continue
        echo
        echo "[?] Potential multi-disc group (fuzzy match): $fuzzy_key"
        for f in "${match_files[@]}"; do echo "    - $f"; done
        while true; do
            read -rp "    Accept this grouping? (y/n): " choice
            case "$choice" in
                [yY])
                    game_groups["$fuzzy_key"]+=$'\n'"${match_files[@]}"
                    break ;;
                [nN])
                    echo "    Skipping this fuzzy group."
                    break ;;
                *) echo "    Please enter 'y' or 'n'." ;;
            esac
        done
    done
fi

# Preview
echo "[*] Found ${#game_groups[@]} game sets:"
for key in "${!game_groups[@]}"; do

	IFS=$'\n' read -r -d '' -a files < <(printf '%s\0' "${game_groups[$key]}")
	# Skip single-disc games unless explicitly included
	if [ "${#files[@]}" -lt 2 ] && [ "$INCLUDE_SINGLE_DISC" -ne 1 ]; then
		continue
	fi


	# Check if this group has multiple single-disc versions (no (Disc #) in names)
	if [[ "${#files[@]}" -gt 1 ]]; then
		only_single_disc=1
		for f in "${files[@]}"; do
			if [[ "$f" =~ \(Disc[[:space:]]*[0-9]+\) ]]; then
				only_single_disc=0
				break
			fi
		done
		if [[ "$only_single_disc" -eq 1 ]]; then
			echo
			echo "[!] Multiple single-disc variants found for '$key'. Skipping playlist generation."
			continue
		fi
	fi


    name="$key"
    [ "$CLEAN_NAMES" -eq 1 ] && name=$(generate_clean_name "${files[0]}")
    target_dir=$( [ "$PER_GAME_FOLDERS" -eq 1 ] && echo "./$name" || echo "./gamedisk" )
    playlist_ext=$(requires_utf8 "${files[@]}" && echo "m3u8" || echo "m3u")
    playlist_path=$( [ "$MOVE_PLAYLISTS" -eq 1 ] && [ "$PER_GAME_FOLDERS" -eq 1 ] && echo "$target_dir/$name.$playlist_ext" || echo "./$name.$playlist_ext" )

    echo
    echo "========================================"
    echo "[Game:]        $key"
    echo "[Folder:]      $target_dir"
    echo "[Playlist:]    $playlist_path"
    echo "[Files (sorted for playlist):]"
	mapfile -t sorted_files < <(
		for f in "${files[@]}"; do
			disc=$(echo "$f" | grep -oiE 'Disc ?[0-9]+' | grep -oE '[0-9]+' || echo 0)
			printf "%02d|%s\n" "$disc" "$f"
		done | sort -n | cut -d'|' -f2-
	)
for f in "${sorted_files[@]}"; do echo "    - $f"; done

done

[ "$DRY_RUN" -eq 1 ] && echo && echo "[✓] Dry run complete." && exit 0
[ "$AUTO_YES" -ne 1 ] && read -rp "Proceed with these changes? [y/N] " confirm && [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }

[ "$PER_GAME_FOLDERS" -eq 0 ] && mkdir -p "./gamedisk"
echo; echo "[*] Processing..."

for key in "${!game_groups[@]}"; do
    IFS=$'\n' read -r -d '' -a all_files < <(printf '%s\0' "${game_groups[$key]}" | sort -Vz)
    [ "${#all_files[@]}" -lt 2 ] && continue

    name="$key"
    [ "$CLEAN_NAMES" -eq 1 ] && name=$(generate_clean_name "${all_files[0]}")
    target_dir=$( [ "$PER_GAME_FOLDERS" -eq 1 ] && echo "./$name" || echo "./gamedisk" )
    mkdir -p "$target_dir"

    # Prefer .cue/.ccd, fall back to .bin/.img/.iso/.chd
    playlist_files=()
    for ext in cue ccd iso chd bin img; do
        for f in "${all_files[@]}"; do
            [[ "$f" == *.$ext ]] && playlist_files+=("$f")
        done
        [ "${#playlist_files[@]}" -gt 0 ] && break
    done

    if [ "$SORT_M3U_BY_DISC" -eq 1 ]; then
		mapfile -t playlist_files < <(
			for f in "${playlist_files[@]}"; do
				disc=$(echo "$f" | grep -oiE 'Disc ?[0-9]+' | grep -oE '[0-9]+' || echo 0)
				printf "%02d|%s\n" "$disc" "$f"
			done | sort -n | cut -d'|' -f2-
		)
	fi

    playlist_ext=$(requires_utf8 "${playlist_files[@]}" && echo "m3u8" || echo "m3u")
    playlist_path=$( [ "$MOVE_PLAYLISTS" -eq 1 ] && [ "$PER_GAME_FOLDERS" -eq 1 ] && echo "$target_dir/$name.$playlist_ext" || echo "./$name.$playlist_ext" )

    echo "[+] Writing playlist: $playlist_path"
    > "$playlist_path"
    for f in "${playlist_files[@]}"; do
        rel_path=$(realpath --relative-to="$(dirname "$playlist_path")" "$target_dir/$f")
echo "$rel_path" >> "$playlist_path"
    if [ "$DUPLICATE_M3U8" -eq 1 ]; then
        duplicate_path="${playlist_path%.m3u}.m3u8"
        echo "$rel_path" >> "$duplicate_path"
    fi
    [ "${VERIFY_PLAYLISTS:-0}" -eq 1 ] && verify_playlist "$playlist_path"
    [ "$GENERATE_ES_METADATA" -eq 1 ] && generate_es_metadata "$name" "$playlist_path" "$target_dir"
    [ "$GENERATE_RA_METADATA" -eq 1 ] && generate_ra_metadata "$name" "$playlist_path" "$target_dir"
    done

    for f in "${all_files[@]}"; do
        echo "    - Moving: $f → $target_dir/"
        mv -i -- "$f" "$target_dir/"
        base="${f%.*}"
        ext="${f##*.}"
        if [[ "$ext" == "cue" && "$FIX_CUE_PATHS" -eq 1 ]]; then
            fix_cue_paths "$target_dir/$f"
        fi
        if [[ "$ext" == "cue" || "$ext" == "ccd" ]]; then
            get_companion_files "$base" companions
            for comp in "${companions[@]}"; do
                [ -e "$comp" ] && echo "    - Moving companion: $comp → $target_dir/" && mv -i -- "$comp" "$target_dir/"
            done
        fi
    done
done

echo "[✓] Done."