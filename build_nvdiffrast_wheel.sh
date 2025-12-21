#!/usr/bin/env bash
set -euxo pipefail

# ✅ 네가 이미 빌드 완료한 torch base 이미지 태그로 고정
TORCH_BASE_IMAGE="${TORCH_BASE_IMAGE:-ghcr.io/nokozan/aue-stage2-torch-base-trellis:cuda118-py310}"
OUT_DIR="${OUT_DIR:-$PWD/wheels}"
ARCH_LIST="${ARCH_LIST:-8.0+PTX}"

mkdir -p "$OUT_DIR"

docker run --rm -t \
  -e TORCH_CUDA_ARCH_LIST="$ARCH_LIST" \
  -e MAX_JOBS=1 \
  -e CMAKE_BUILD_PARALLEL_LEVEL=1 \
  -e Ninja_EXECUTABLE=/usr/bin/ninja \
  -v "$OUT_DIR:/wheels" \
  "$TORCH_BASE_IMAGE" \
  bash -lc '
    set -euxo pipefail

    python -c "import sys, torch; print(sys.version); print(torch.__version__, torch.version.cuda)"

    apt-get update && apt-get install -y --no-install-recommends \
      git build-essential ninja-build cmake pkg-config \
      && rm -rf /var/lib/apt/lists/*

    python -m pip install -U pip setuptools wheel packaging "pybind11<3"

    # TMP를 /tmp 말고 넉넉한 곳으로(컨테이너 내부는 보통 /가 작음)
    export TMPDIR=/var/tmp
    mkdir -p "$TMPDIR"

    rm -rf /tmp/nvdiffrast
    git clone --depth 1 https://github.com/NVlabs/nvdiffrast.git /tmp/nvdiffrast
    cd /tmp/nvdiffrast

    # OOM 방지: 컴파일 옵션 낮춤
    export CFLAGS="-O2 -g0"
    export CXXFLAGS="-O2 -g0"
    export NVCC_FLAGS="-O2"
    export MAKEFLAGS="-j1"

    # 1) 먼저 install로 한번 빌드(빌드 산출물 생성)
    python -m pip install . --no-build-isolation --no-cache-dir

    # 2) 그 다음 wheel 생성(대부분 재사용)
    python -m pip wheel . -w /wheels --no-build-isolation --no-deps

    ls -lah /wheels | sed -n "1,200p"
  '

echo "[OK] wheel saved to: $OUT_DIR"
