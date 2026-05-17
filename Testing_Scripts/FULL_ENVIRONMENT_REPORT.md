# Full Validation Package Report

This report documents the imported folder `Testing_Scripts` and captures:
- environment snapshot (host + toolchain visibility)
- script settings and runtime behavior
- folder structure and generated outputs
- original script inventory with purpose descriptions

## 1) Imported Folder

Source folder imported into this repository:
- `/home/slee103/Testing_Scripts`

Imported destination in repo:
- `Testing_Scripts/`

Note:
- `README.save` in the source could not be read because of file permissions, so it is not included in this report content.

## 2) Host Environment Snapshot

Captured on this system while building this report:
- Kernel/OS: `Linux 5.14.0-611.54.3.el9_7.x86_64`
- Distribution: `AlmaLinux 9.7 (Moss Jungle Cat)`
- Shell: `GNU bash 5.1.8`
- Python: `Python 3.9.25`
- Environment Modules: `Lmod 8.7.63`

Scheduler/cluster tools at capture time:
- `sinfo` and `srun` are installed but failed DNS-based Slurm controller discovery in this session
- `wwctl` command was not found in this session

## 3) Validation Workflow Overview

The folder implements two connected flows:
- **Application-level testers** generate per-application result files under `software_test_result/*_testingResult/`
- **General aggregation scripts** read one chosen result file and produce combined reports in `General_test/`

The collected metadata format across scripts includes:
- software name/version
- start/end timestamps and duration
- runtime host details
- loaded modules (`LOADEDMODULES`)
- Slurm execution fields (`SLURM_JOB_ID`, `SLURM_JOB_PARTITION`, `SLURM_JOB_NODELIST`)

## 4) Folder Structure Summary

Top-level structure of `Testing_Scripts/`:
- `directory.sh`
- `general_test.sh`
- `general_test-copy.sh`
- `now_datestr.m`
- `general-mpi-test/`
- `General_test/`
- `pythonProject/`
- `software_test_result/`

Detailed substructure (important paths):
- `general-mpi-test/`
  - `mpi_connectivity_test.c`
  - `run_connectivity_test.sh`
  - `run_mpi_connectivity_test.sh`
  - `MPI_testing_result/` (generated MPI run outputs)
- `pythonProject/`
  - `pycharm_test.py`
  - `pycharm_testResult/` (PyCharm test outputs)
  - `.venv/` (Python virtual environment)
  - `.idea/` (IDE metadata)
- `software_test_result/`
  - `Jupyter_testingResult/`
  - `Rstudio_testingResult/`
  - `vscode_testingResult/`
  - `Octave_testingResult/`
  - `octave_test.m`
- `General_test/`
  - consolidated report files (example: `Jupyter_4.2.0-2025.11.10-report`)

## 5) Script Settings and Behavior

### `general_test.sh`
- Strict mode enabled (`set -euo pipefail`)
- Uses current working directory as navigation root
- Interactive recursive selector allows choosing any result file
- Parses naming format: `{Name}_{Version}-{YYYY.MM.DD}`
- Captures system info (`/etc/os-release`, Slurm version, Warewulf version, loaded modules)
- Writes consolidated report to `General_test/<name>_<version>-<date>-report`

### `general_test-copy.sh`
- Similar report generator but assumes fixed source root `software_test_result`
- Prompts software directory first, then result file (sorted newest-first by date token)
- Produces standardized consolidated report files in `General_test/`

### `directory.sh`
- Interactive directory navigator prototype
- Lets user descend into directories and process selected files
- Creates placeholder processed log files in `General_test/` (`processed_<name>.log`)

### `pythonProject/pycharm_test.py`
- Creates `pycharm_testResult/` automatically under script directory
- Detects PyCharm version using CLI probes and fallback scanning
- Captures hostname, Python version, Conda/Venv, plugins, modules, Slurm fields
- Output format: `PyCharm_<version>-YYYY.MM.DD.txt`

### `software_test_result/octave_test.m`
- Robust Octave function form (`function octave_test(varargin)`)
- Supports explicit version argument or auto-detection
- Supports `TEST_RESULT_ROOT` override for base output path
- Captures packages/modules/Slurm metadata and writes standardized output

### `software_test_result/Octave_testingResult/test_result.m`
- Earlier/alternate Octave script variant
- Similar metadata targets; uses direct `ROOT_DIR` pointing to `software_test_result`
- Writes `Octave_<version>-YYYY.MM.DD` formatted output files

### `now_datestr.m`
- Utility date-string function used for `YYYY.MM.DD` formatting behavior in Octave workflow

### `general-mpi-test/run_connectivity_test.sh`
- Slurm batch runner for full-cluster MPI connectivity validation
- Discovers available nodes using `sinfo`, compiles `mpi_connectivity_test.c`
- Runs `mpirun` all-to-all connectivity test and saves timestamped result file

### `general-mpi-test/run_mpi_connectivity_test.sh`
- Slurm batch script that can self-resubmit with full node count
- Loads OpenMPI, compiles/runs connectivity test, writes run summary

### `general-mpi-test/mpi_connectivity_test.c`
- MPI C program performing all-to-all communication validation
- Prints node/process mapping and summarizes pass/fail connectivity status
- Reports failed nodes when communications mismatch is detected

## 6) Existing Output Artifacts (Observed)

Observed software result families:
- Jupyter (`Jupyter_4.2.0-...`)
- RStudio (`Rstudio_4.5.0-...`)
- VS Code (`vscode_1.103.2-...`)
- PyCharm (`PyCharm_2024.1.6-...`)
- Octave (`Octave_10.1.0-...`)

Observed consolidated report pattern:
- `General_test/<Software>_<Version>-<Date>-report`

The existing outputs confirm that metadata capture includes:
- host/node identity
- module stacks (often extensive in HPC module environments)
- scheduler context and timing fields

## 7) Recommended Repository Organization

To keep this repository clean and reviewable:
- keep raw generated test outputs under `Testing_Scripts/software_test_result/` and `Testing_Scripts/General_test/`
- keep script sources under `Testing_Scripts/` and `Testing_Scripts/general-mpi-test/`
- consider adding `.gitignore` entries for transient files (job logs, compiled binaries, local virtualenv caches) if you do not need to version them all

## 8) How to Run (Current Scripts)

From `Testing_Scripts/`:
- interactive report generator: `bash general_test.sh`
- fixed-source report generator: `bash general_test-copy.sh`

From `Testing_Scripts/pythonProject/`:
- PyCharm test output script: `python3 pycharm_test.py`

From `Testing_Scripts/general-mpi-test/` (Slurm environment):
- `sbatch run_connectivity_test.sh`
- or `sbatch run_mpi_connectivity_test.sh`

## 9) Completion Statement

`Testing_Scripts` has been imported into this repository and documented with environment, settings, structure, and original script descriptions in this file.
