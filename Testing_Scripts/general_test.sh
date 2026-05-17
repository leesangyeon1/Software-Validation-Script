#!/usr/bin/env bash
set -euo pipefail

# Report will be saved in the 'General_test' directory.
REPORT_DIR="General_test"
REPORT_ABS_DIR="$(pwd -P)/$REPORT_DIR"

# --- Utility functions ---
iso_ts()  { date -Iseconds; }
has_cmd() { command -v "$1" >/dev/null 2>&1; }

linux_version() {
  if [[ -r /etc/os-release ]]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    echo "${PRETTY_NAME:-$(uname -srv)} (kernel $(uname -r))"
  else
    uname -srv
  fi
}

slurm_version() {
  local out=""
  if has_cmd sinfo; then out="$(sinfo --version 2>/dev/null | head -n1 || true)"; fi
  if [[ -z "$out" && "$(has_cmd srun; echo $?)" -eq 0 ]]; then
    out="$(srun --version 2>/dev/null | head -n1 || true)"
  fi
  echo "$out"
}

warewulf_version() {
  if has_cmd wwctl; then wwctl version 2>/dev/null | head -n1 || true; else echo ""; fi
}

module_list() {
  if has_cmd modulecmd || has_cmd module; then module list 2>&1 || true; else echo ""; fi
}

# --- Interactive directory navigation function  ---
navigate() {
  local current_path="$1"
  local abs_start_dir="$2"
    
  if [[ ! -d "$current_path" ]]; then
    # Information message is output to stderr(>&2).
    echo "Error: Directory not found: $current_path" >&2
    return 1
  fi
    
  # Information message is output to stderr(>&2).
  echo "" >&2
  echo "--- Current Directory: $current_path ---" >&2
    
  local -a items=()
  
  # 1. Add '..' option (if not the start directory)
  if [[ "$(cd "$current_path" && pwd -P)" != "$abs_start_dir" ]]; then
      items+=(".. (Go back)")
  fi
  
  local -a entries=()
  
  # 2. Collect directory list
  while IFS= read -r -d '' dir; do
    entries+=("$(basename "$dir")/")
  done < <(find "$current_path" -maxdepth 1 -mindepth 1 -type d -print0 2>/dev/null | sort -z)
  
  # 3. Collect file list
  while IFS= read -r -d '' file; do
    entries+=("$(basename "$file")")
  done < <(find "$current_path" -maxdepth 1 -mindepth 1 -type f -print0 2>/dev/null | sort -z)

  items+=("${entries[@]}")

  if [[ ${#items[@]} -eq 0 ]]; then
      echo "This directory is empty." >&2
      return 1
  fi

  # 'select' prompt (PS3) is output to stderr by default.
  PS3="Select an item (number): "
    
  select item in "${items[@]}"; do
    if [[ -z "$item" ]]; then
      echo "Invalid selection number. Please try again." >&2
      continue
    fi
      
    if [[ "$item" == ".. (Go back)" ]];
    then
      local new_path
      new_path=$(cd "$current_path/.." && pwd -P)
      # Pass $abs_start_dir to the recursive call.
      navigate "$new_path" "$abs_start_dir"
      return $?
    fi

    local clean_item="${item%/}"
    local selected_path="$current_path/$clean_item"
      
    if [[ -d "$selected_path" ]]; then
      local new_path
      new_path=$(cd "$selected_path" && pwd -P)
      navigate "$new_path" "$abs_start_dir"
      return $?
    elif [[ -f "$selected_path" ]]; then
      # Information message is output to stderr(>&2).
      echo "Selected output file: $selected_path" >&2
      # Only output the final file path to stdout to be stored in the sel_path variable.
      echo "$selected_path"
      return 0
    else
      echo "Error: Invalid selection: $clean_item" >&2
    fi
  done
}

# --- Main execution ---

echo "=== File Navigator for General Test Report ==="
echo "Navigate to the output file you want to process"

START_DIR="$(pwd -P)"
# Only the final path output by the navigate function is stored in sel_path.
sel_path=$(navigate "$START_DIR" "$START_DIR")

if [[ -z "$sel_path" ]]; then
  echo "No file selected. Exiting."
  exit 1
fi

echo ""
  # Now sel_path is a clean path string, so no errors occur.
echo "Selected file path (clean): $sel_path"
echo ""

# Check if the file exists and has read permissions.
if [[ ! -f "$sel_path" ]]; then
  echo "Error: File does not exist: $sel_path"
  exit 1
fi

# --- From here, it is the user's original script logic (report creation) ---

# Parse the file name: {Name}_{Version}-{YYYY.MM.DD}
sel_file="$(basename "$sel_path")"
if [[ "$sel_file" =~ ^([^_]+)_([^-]+)-(.+)$ ]]; then
  name_part="${BASH_REMATCH[1]}"
  version_part="${BASH_REMATCH[2]}"
  date_part="${BASH_REMATCH[3]}"
else
  # Fallback
  echo "Warning: Filename does not match expected format. Using fallback." >&2
  name_part="${sel_file%%.*}"
  version_part="unknown"
  date_part="$(date +%Y.%m.%d)"
fi

# 3) Collect system information
linux_info="$(linux_version)"
slurm_info="$(slurm_version || true)"
ww_info="$(warewulf_version || true)"
mods_info="$(module_list || true)"

# 4) Create report
mkdir -p "$REPORT_ABS_DIR"
report_file="${REPORT_ABS_DIR}/${name_part}_${version_part}-${date_part}-report"

{
  echo "=== General Test Report ==="
  echo "Generated: $(iso_ts)"
  echo
  echo "== System Information =="
  echo "Linux:   ${linux_info}"
  [[ -n "$slurm_info" ]] && echo "Slurm:   ${slurm_info}"
  [[ -n "$ww_info"    ]] && echo "Warewulf:${ww_info}"
  if [[ -n "$mods_info" ]]; then
    echo
    echo "-- Loaded modules --"
    echo "$mods_info"
  fi

  echo
  echo "== Application Test Results (${name_part}) =="
  echo "File:     ${sel_file}"
  echo "Version:  ${version_part}"
  echo "Test date:${date_part}"
  echo
  # Add the content of the input file ($sel_path) to the report
  sed -e 's/\r$//' "$sel_path"
} | sed -e 's/[[:space:]]\+$//' | tee "$report_file" # Create the output file ($report_file)

echo
echo "Saved report: $report_file"
