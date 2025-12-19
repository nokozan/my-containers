set -eux

# 런타임 torch와 "같은" 버전/쿠다로 wheel을 빌드해야 ABI 문제가 안 남
TORCH_IMAGE="${TORCH_IMAGE:-pytorch/pytorch:2.1.1-cuda11.8-cudnn8-devel}"
DIST_DIR="${DIST_DIR:-$PWD/dist}"
ARCH_LIST="${ARCH_LIST:-8.0+PTX}"   # A100이면 그대로

mkdir -p "$DIST_DIR"

docker run --rm -t \
  -v "$DIST_DIR:/dist" \
  "$TORCH_IMAGE" \
  bash -lc '
    set -eux
    export DEBIAN_FRONTEND=noninteractive
    export TZ=Etc/UTC

    # tzdata 프롬프트로 멈추는 케이스 방지
    apt-get update
    apt-get install -y --no-install-recommends tzdata
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime
    echo $TZ > /etc/timezone

    # 빌드 환경 확정 출력 (나중에 ABI 확인용)
    python -c "import sys, torch; print(\"python:\", sys.version); print(\"torch:\", torch.__version__); print(\"cuda:\", torch.version.cuda)"

    apt-get update && apt-get install -y --no-install-recommends \
      git build-essential ninja-build cmake pkg-config \
      && rm -rf /var/lib/apt/lists/*

    python -m pip install -U pip setuptools wheel
    python -m pip install -U packaging "pybind11<3"

    export TORCH_CUDA_ARCH_LIST="'"$ARCH_LIST"'"
    export CUDA_HOME=/usr/local/cuda
    export MAX_JOBS=1

    rm -rf /tmp/nvdiffrast
    git clone --depth 1 https://github.com/NVlabs/nvdiffrast.git /tmp/nvdiffrast
    cd /tmp/nvdiffrast

    # wheel 생성 (중요: --no-build-isolation)
    python -m pip wheel . -w /dist --no-build-isolation

    ls -lh /dist
  '

ls -lh "$DIST_DIR"
