#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="software_test_result"
REPORT_DIR="General_test"

iso_ts()  { date -Iseconds; }
has_cmd() { command -v "$1" >/dev/null 2>&1; }

linux_version() {
  if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    echo "${PRETTY_NAME:-$(uname -srv)} (kernel $(uname -r))"
  else
    uname -srv
  fi
}
slurm_version() {
  local out=""
  if has_cmd sinfo; then out="$(sinfo --version 2>/dev/null | head -n1 || true)"; fi
  [[ -z "$out" && "$(has_cmd srun; echo $?)" -eq 0 ]] && out="$(srun --version 2>/dev/null | head -n1 || true)"
  echo "$out"
}
warewulf_version() {
  if has_cmd wwctl; then wwctl version 2>/dev/null | head -n1 || true; else echo ""; fi
}
module_list() {
  if has_cmd modulecmd || has_cmd module; then module list 2>&1 || true; else echo ""; fi
}

prompt_number() {
  local prompt="$1" max="$2" sel
  while true; do
    read -rp "$prompt " sel
    [[ "$sel" =~ ^[0-9]+$ ]] && (( sel>=1 && sel<=max )) && { echo "$sel"; return 0; }
    echo "Enter a number between 1 and $max."
  done
}

# 1) Pick software directory
if [[ ! -d "$ROOT_DIR" ]]; then
  echo "No '$ROOT_DIR' directory found."; exit 1
fi

mapfile -t subdirs < <(find "$ROOT_DIR" -maxdepth 1 -mindepth 1 -type d -name '*_testingResult' | sort)
if [[ ${#subdirs[@]} -eq 0 ]]; then
  echo "No '*_testingResult' subdirectories found in $ROOT_DIR."; exit 1
fi

echo "Which software do you want to check?"
declare -a names
i=1
for d in "${subdirs[@]}"; do
  base="$(basename "$d")"
  names+=("$base")
  # show the name of softwares: vscode / Rstudio / pycharm / Jupyter / Blender
  echo "$i) ${base%%_*}"
  ((i++))
done
choice=$(prompt_number "Type the number:" "${#subdirs[@]}")
sel_dir="${subdirs[$((choice-1))]}"
sel_name="${names[$((choice-1))]}"
sel_display="${sel_name%%_*}"
echo "Selected: ${sel_display}"
echo

# 2) output file selection (YYYY.MM.DD top to bottom)
mapfile -t files < <(find "$sel_dir" -maxdepth 1 -type f -printf "%f\n" | \
  awk -F'-' '
    function strip(s){ gsub(/\./,"",s); return s }
    NF>=2 { key=strip($NF); print key"\t"$0 }
  ' | sort -r | cut -f2-)

if [[ ${#files[@]} -eq 0 ]]; then
  echo "No result files found in $sel_dir."; exit 1
fi

echo "Which output files do you want to pick?"
for idx in "${!files[@]}"; do
  echo "$((idx+1)). ${files[$idx]}"
done
fchoice=$(prompt_number "Type the number:" "${#files[@]}")
sel_file="${files[$((fchoice-1))]}"
sel_path="${sel_dir}/${sel_file}"
echo "Selected file: $sel_file"
echo

# pass the version name as: {Name}_{Version}-{YYYY.MM.DD}
name_part="${sel_file%%_*}"
rest="${sel_file#*_}"          # Version-YYYY.MM.DD
version_part="${rest%-*}"      # Version
date_part="${rest##*-}"        # YYYY.MM.DD

# 3) import system info
linux_info="$(linux_version)"
slurm_info="$(slurm_version || true)"
ww_info="$(warewulf_version || true)"
mods_info="$(module_list || true)"

# 4)  create output file 
mkdir -p "$REPORT_DIR"
report_file="${REPORT_DIR}/${name_part}_${version_part}-${date_part}-report"

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
  sed -e 's/\r$//' "$sel_path"
} | sed -e 's/[[:space:]]\+$//' | tee "$report_file"

echo
echo "Saved report: $report_file"
