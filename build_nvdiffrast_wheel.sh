set -eux

# wheel 빌드용 컨테이너 (CUDA toolkit + torch 포함)
docker run --rm -t \
  -v "$PWD/dist:/dist" \
  pytorch/pytorch:2.3.1-cuda11.8-cudnn8-devel \
  bash -lc '
    set -eux
    apt-get update && apt-get install -y --no-install-recommends git build-essential ninja-build cmake pkg-config && rm -rf /var/lib/apt/lists/*
    python -m pip install -U pip setuptools wheel

    # (중요) 아키텍처 범위를 줄여서 빌드/용량 줄임
    # A100 계열이면 이게 가장 안전: 8.0+PTX (8.0 이상에서 동작)
    export TORCH_CUDA_ARCH_LIST="8.0+PTX"
    export CUDA_HOME=/usr/local/cuda

    git clone --depth 1 https://github.com/NVlabs/nvdiffrast.git /tmp/nvdiffrast
    cd /tmp/nvdiffrast
    python -m pip install -U pip setuptools wheel
    python -m pip install -U packaging "pybind11<3"

    export TORCH_CUDA_ARCH_LIST="8.0+PTX"
    export CUDA_HOME=/usr/local/cuda
    export MAX_JOBS=1
    # wheel 생성
    python -m pip wheel . -w /dist --no-build-isolation
  '

ls -lh dist
