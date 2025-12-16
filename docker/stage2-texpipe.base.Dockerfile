# ghcr.io/nokozan/aue-stage2-base-texpipe:cuda118-py310
# 목적: 텍스처 생성/베이크 전용. TripoSR/Unique3D 절대 포함 금지.

FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    RUNPOD_VOLUME_ROOT=/runpod-volume \
    HF_HOME=/runpod-volume/.cache/hf \
    HF_HUB_CACHE=/runpod-volume/.cache/hf \
    TRANSFORMERS_CACHE=/runpod-volume/.cache/hf \
    DIFFUSERS_CACHE=/runpod-volume/.cache/hf \
    XDG_CACHE_HOME=/runpod-volume/.cache \
    TORCH_HOME=/runpod-volume/.cache/torch \
    TMPDIR=/runpod-volume/tmp

# ---- APT: dpkg 꼬임 복구 + CA 먼저 안정화 ----
RUN set -eux; \
    dpkg --configure -a || true; \
    apt-get update; \
    apt-get install -y --no-install-recommends openssl ca-certificates; \
    apt-get -f install -y; \
    dpkg --configure -a; \
    update-ca-certificates; \
    rm -rf /var/lib/apt/lists/*

# ---- 나머지 OS 패키지 (여기서 python3-pip 설치 금지) ----
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      git wget curl \
      python3 python3-dev python3-venv \
      build-essential pkg-config cmake ninja-build \
      ffmpeg \
      libgl1 libglib2.0-0 \
      libx11-6 libxcb1 libxext6 libxrender1 \
      libegl1 libegl1-mesa; \
    apt-get -f install -y; \
    dpkg --configure -a; \
    rm -rf /var/lib/apt/lists/*

# ---- pip은 apt가 아니라 get-pip로 설치 ----
RUN set -eux; \
    curl -sS https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py; \
    python3 /tmp/get-pip.py; \
    python3 -m pip install --upgrade pip setuptools wheel; \
    rm -f /tmp/get-pip.py

# ---- torch/cu118 (stage1 계열과 맞춤) ----
RUN set -eux; \
    pip install --no-cache-dir \
      torch==2.3.1+cu118 torchvision==0.18.1+cu118 \
      --index-url https://download.pytorch.org/whl/cu118

# ---- diffusers stack (stage1과 동일 계열 고정) ----
RUN set -eux; \
    pip install --no-cache-dir \
      diffusers==0.30.0 \
      transformers==4.40.0 \
      tokenizers==0.19.1 \
      accelerate==0.29.3 \
      safetensors==0.4.2 \
      einops \
      pillow \
      opencv-python-headless \
      numpy \
      tqdm

# ---- mesh/uv/io + runpod + s3 ----
RUN set -eux; \
    pip install --no-cache-dir \
      trimesh \
      xatlas==0.0.9 \
      imageio[ffmpeg] \
      runpod boto3

RUN mkdir -p \
    /runpod-volume/.cache/hf \
    /runpod-volume/.cache/torch \
    /runpod-volume/tmp

WORKDIR /app
CMD ["bash"]
