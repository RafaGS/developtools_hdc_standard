#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STANDALONE_SCRIPT="$ROOT_DIR/scripts/build_standalone_linux_host.sh"
OHOS_TMP="/tmp/ohos_hdc_local_root"

require_cmd() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "[ERROR] Missing command: $cmd"
        exit 1
    fi
}

prepare_local_ohos_root() {
    rm -rf "$OHOS_TMP"
    mkdir -p "$OHOS_TMP/developtools" "$OHOS_TMP/third_party"

    # Copy current local repo as developtools/hdc source.
    cp -a "$ROOT_DIR" "$OHOS_TMP/developtools/hdc"

    # Keep staging dir clean to avoid recursive/self symlink states.
    rm -rf "$OHOS_TMP/developtools/hdc/ohos_hdc_build"

    # Fetch only required third-party repositories.
    git clone --depth 1 https://gitee.com/openharmony/third_party_libuv.git \
        "$OHOS_TMP/third_party/libuv"
    git clone --depth 1 https://gitee.com/openharmony/third_party_openssl.git \
        "$OHOS_TMP/third_party/openssl"
    git clone --depth 1 https://gitee.com/openharmony/third_party_bounds_checking_function.git \
        "$OHOS_TMP/third_party/bounds_checking_function"
    git clone --depth 1 https://gitee.com/openharmony/third_party_lz4.git \
        "$OHOS_TMP/third_party/lz4"
}

main() {
    require_cmd git
    require_cmd cmake
    require_cmd make
    require_cmd g++
    require_cmd perl

    if [[ ! -x "$STANDALONE_SCRIPT" ]]; then
        echo "[ERROR] Missing or non-executable: $STANDALONE_SCRIPT"
        exit 1
    fi

    echo "[1/3] Cleaning previous local build output"
    rm -rf "$ROOT_DIR/ohos_hdc_build"

    echo "[2/3] Preparing temporary OHOS-like root from local source"
    prepare_local_ohos_root

    echo "[3/3] Building hdc_std"
    bash "$STANDALONE_SCRIPT" "$OHOS_TMP"

    if [[ -x "$ROOT_DIR/hdc_std" ]]; then
        echo "[OK] Build complete: $ROOT_DIR/hdc_std"
        "$ROOT_DIR/hdc_std" -v || true
    else
        echo "[ERROR] Build finished but hdc_std was not found"
        exit 1
    fi
}

main "$@"
