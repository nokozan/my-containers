# stage2-texpipe.base.Dockerfile
# Build target: runtime (GH Actions에서 target: runtime 으로 푸시)

# --------------------------
# STAGE A: build nvdiffrast
# --------------------------
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04 AS build
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    TMPDIR=/tmp \
    CUDA_HOME=/usr/local/cuda

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      ca-certificates openssl \
      git curl \
      python3 python3-dev python3-venv \
      build-essential ninja-build cmake pkg-config; \
    update-ca-certificates; \
    rm -rf /var/lib/apt/lists/*

# pip (apt python3-pip 금지)
RUN set -eux; \
    curl -sS https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py; \
    python3 /tmp/get-pip.py; \
    python3 -m pip install --upgrade pip setuptools wheel; \
    rm -f /tmp/get-pip.py

# torch/cu118 (nvdiffrast 빌드용)
RUN set -eux; \
    pip install --no-cache-dir \
      torch==2.3.1+cu118 torchvision==0.18.1+cu118 \
      --index-url https://download.pytorch.org/whl/cu118

# nvdiffrast
RUN set -eux; \
    pip install --no-cache-dir \
      git+https://github.com/NVlabs/nvdiffrast.git --no-build-isolation

# --------------------------
# STAGE B: runtime (final)
# --------------------------
FROM pytorch/pytorch:2.3.1-cuda11.8-cudnn8-runtime AS runtime
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    TMPDIR=/tmp

# OS deps (최소)
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      ca-certificates openssl \
      git curl wget \
      ffmpeg \
      libgl1 libglib2.0-0 \
      libx11-6 libxcb1 libxext6 libxrender1 \
      libegl1 libegl1-mesa; \
    update-ca-certificates; \
    rm -rf /var/lib/apt/lists/*

# build stage에서 nvdiffrast + 의존 python 패키지(컴파일 결과) 복사
# (build stage는 /usr/local/lib/python3.10/dist-packages 에 설치됨)
COPY --from=build /usr/local/lib/python3.10/dist-packages /opt/conda/lib/python3.10/site-packages
COPY --from=build /usr/local/lib /usr/local/lib

# runtime 파이프라인 패키지
RUN set -eux; \
    python -m pip install --upgrade pip setuptools wheel; \
    pip install --no-cache-dir \
      scipy \
      diffusers==0.30.0 \
      transformers==4.40.0 \
      tokenizers==0.19.1 \
      accelerate==0.29.3 \
      safetensors==0.4.2 \
      einops pillow opencv-python-headless numpy tqdm \
      trimesh xatlas==0.0.9 imageio[ffmpeg] \
      runpod boto3

# smoke test (빌드에서 여기 통과하면 런타임도 OK)
RUN set -eux; \
    python -c "import torch; print('torch', torch.__version__, 'cuda', torch.cuda.is_available())"; \
    python -c "import nvdiffrast; print('nvdiffrast ok')"; \
    python -c "import scipy, diffusers, transformers, trimesh, xatlas; print('deps ok')"

WORKDIR /app
CMD ["bash"]
