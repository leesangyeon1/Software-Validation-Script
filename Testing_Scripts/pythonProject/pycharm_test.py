#!/usr/bin/env python3
"""
PyCharm 테스트 결과 기록 스크립트
- 출력: /home/slee103/Testing_Scripts/pycharm_testResult (자동 생성)
- Zero Error: PyCharm/Jupyter/터미널 모두 동작 보장
"""

import os
import sys
import subprocess
import time
import re
import socket
from datetime import datetime
from pathlib import Path
import glob

# =============================================================================
# 설정 (Jupyter 스타일: 상대 경로)
# =============================================================================
SOFTWARE_DIR = "pycharm_testResult"  # 요청된 폴더명
SOFTWARE_FILE_PREFIX = "PyCharm"
ROOT_DIR = "."  # 현재 작업 디렉토리 (스크립트 위치 기반)

# 스크립트 위치를 작업 디렉토리로 설정 (PyCharm 오류 방지)
SCRIPT_DIR = Path(__file__).parent
os.chdir(SCRIPT_DIR)  # 작업 디렉토리를 스크립트 폴더로 고정

OUTPUT_DIR = Path(ROOT_DIR) / SOFTWARE_DIR

# =============================================================================
# 유틸리티 함수
# =============================================================================
def now_datestr(): return datetime.now().strftime("%Y.%m.%d")

def iso_ts(): return datetime.now().isoformat(timespec="seconds")

def env(k, d=""): return os.environ.get(k, d)

def first_nonflag_arg(argv):
    """명령행에서 버전처럼 보이는 첫 번째 인자 찾기"""
    skip_next = False
    for a in argv[1:]:
        if skip_next:
            skip_next = False
            continue
        if a.startswith("-"):
            continue
        if re.match(r'^\d+\.\d+', a):
            return a
    return None

# =============================================================================
# PyCharm 버전 탐지
# =============================================================================
def _cli_parse_pycharm_version():
    """pycharm --version에서 버전 추출"""
    for cmd in ("pycharm", "pycharm.sh", "pycharm-community", "charm"):
        try:
            out = subprocess.check_output([cmd, "--version"], stderr=subprocess.STDOUT, text=True, timeout=5)
            m = re.search(r'PyCharm\s+(\d+\.\d+(?:\.\d+)?)', out, re.IGNORECASE)
            if m:
                return m.group(1)
            m = re.search(r'(\d+\.\d+\.\d+)', out)
            if m:
                return m.group(1)
        except Exception:
            continue
    return ""

def _find_pycharm_buildtxt():
    """build.txt에서 빌드 번호 찾기"""
    possible_paths = [
        f"{str(Path.home())}/.local/share/JetBrains/PyCharm*/build.txt",
        "/opt/pycharm*/build.txt",
        "/usr/local/pycharm*/build.txt",
        "/Applications/PyCharm*.app/Contents/Resources/build.txt",
    ]
    for pattern in possible_paths:
        for path in glob.glob(pattern):
            try:
                with open(path, 'r') as f:
                    content = f.read().strip()
                    m = re.search(r'PY-(\d+)', content)
                    if m:
                        return m.group(1)
            except Exception:
                continue
    return ""

def detect_version():
    v = _cli_parse_pycharm_version()
    if v: return v
    v = _find_pycharm_buildtxt()
    if v: return v
    explicit = first_nonflag_arg(sys.argv)
    if explicit:
        return explicit
    return "unknown"

# =============================================================================
# 플러그인 탐지
# =============================================================================
def get_pycharm_plugins():
    """설치된 플러그인 정보"""
    plugin_dirs = [
        f"{str(Path.home())}/.local/share/JetBrains/PyCharm*/plugins",
        f"{str(Path.home())}/Library/Application Support/JetBrains/PyCharm*/plugins",
    ]
    plugins = []
    for pattern in plugin_dirs:
        for plugin_dir in glob.glob(pattern):
            try:
                for item in os.listdir(plugin_dir):
                    if os.path.isdir(os.path.join(plugin_dir, item)):
                        plugins.append(item)
            except Exception:
                continue
    return plugins[:20]

# =============================================================================
# 메인 함수 (Jupyter 스타일: 간단하고 직관적)
# =============================================================================
def main():
    version = detect_version()
    date_str = now_datestr()
    start = time.time()
    start_ts = iso_ts()

    # 환경 정보
    custom_tools = []
    pycharm_jdk = env("PYCHARM_JDK", "")
    if pycharm_jdk:
        custom_tools.append(f"JDK: {pycharm_jdk}")

    plugins = get_pycharm_plugins()

    loaded_modules = [m for m in env("LOADEDMODULES", "").split(":") if m]
    partition = env("SLURM_JOB_PARTITION", "")
    nodelist = env("SLURM_JOB_NODELIST", "")
    slurm_id = env("SLURM_JOB_ID", "")

    # 추가 진단
    hostname = socket.gethostname()
    py_ver = "{}.{}.{}".format(sys.version_info.major, sys.version_info.minor, sys.version_info.micro)
    conda_env = env("CONDA_DEFAULT_ENV", "")
    venv_dir = env("VIRTUAL_ENV", "")

    # 출력 디렉토리 생성 (Jupyter처럼 상대 경로, 자동 생성)
    try:
        OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    except Exception as e:
        print(f"Error creating directory {OUTPUT_DIR}: {e}", file=sys.stderr)
        sys.exit(1)

    safe_version = re.sub(r'[^\w\.\-]', '_', version)[:50]
    outfile = OUTPUT_DIR / f"{SOFTWARE_FILE_PREFIX}_{safe_version}-{date_str}.txt"

    try:
        with outfile.open("w", encoding="utf-8") as f:
            f.write("=== PyCharm Test Result ===\n")
            f.write("Software: PyCharm\n")
            f.write(f"Version:  {version}\n")
            f.write(f"Timestamp Start: {start_ts}\n")

            env_lines = []
            if hostname:  env_lines.append(f"Hostname: {hostname}")
            if py_ver:    env_lines.append(f"Python:   {py_ver}")
            if conda_env: env_lines.append(f"Conda env: {conda_env}")
            if venv_dir:  env_lines.append(f"Venv:     {venv_dir}")
            if env_lines:
                f.write("\n--- Runtime environment ---\n")
                f.write("\n".join(env_lines) + "\n")

            if custom_tools:
                f.write(f"\nCustom tools used: {', '.join(custom_tools)}\n")

            if plugins:
                f.write("\n--- Installed plugins ---\n")
                f.write("\n".join(plugins) + "\n")

            if loaded_modules:
                f.write("\n--- Loaded modules ---\n")
                f.write("\n".join(loaded_modules) + "\n")

            if partition or nodelist or slurm_id:
                f.write("\n--- Slurm execution info ---\n")
                if slurm_id:  f.write(f"JobID:    {slurm_id}\n")
                if partition: f.write(f"Partition:{partition}\n")
                if nodelist:  f.write(f"NodeList: {nodelist}\n")

            end_ts = iso_ts()
            duration = int(time.time() - start)
            f.write(f"\nTimestamp End:    {end_ts}\n")
            f.write(f"Duration (sec):  {duration}\n")

        print(f"Saved: {outfile}")

    except Exception as e:
        print(f"Error writing to file {outfile}: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()