FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    TMPDIR=/tmp

# ---- APT (여기서 절대 runpod-volume 같은 경로 쓰지 마라) ----
RUN set -eux; \
    dpkg --configure -a || true; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      openssl ca-certificates \
      git wget curl \
      python3 python3-dev python3-venv \
      build-essential pkg-config cmake ninja-build \
      ffmpeg \
      libgl1 libglib2.0-0 \
      libx11-6 libxcb1 libxext6 libxrender1 \
      libegl1 libegl1-mesa; \
    apt-get -f install -y; \
    dpkg --configure -a; \
    update-ca-certificates; \
    rm -rf /var/lib/apt/lists/*

# ---- pip은 apt python3-pip 쓰지 말고 get-pip로 ----
RUN set -eux; \
    curl -sS https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py; \
    python3 /tmp/get-pip.py; \
    python3 -m pip install --upgrade pip setuptools wheel; \
    rm -f /tmp/get-pip.py

# ---- torch/cu118 ----
RUN set -eux; \
    pip install --no-cache-dir \
      torch==2.3.1+cu118 torchvision==0.18.1+cu118 \
      --index-url https://download.pytorch.org/whl/cu118

# ---- diffusers stack ----
RUN set -eux; \
    pip install --no-cache-dir \
      diffusers==0.30.0 \
      transformers==4.40.0 \
      tokenizers==0.19.1 \
      accelerate==0.29.3 \
      safetensors==0.4.2 \
      einops pillow opencv-python-headless numpy tqdm

# ---- mesh/uv/io + runpod/s3 ----
RUN set -eux; \
    pip install --no-cache-dir \
      trimesh xatlas==0.0.9 imageio[ffmpeg] \
      runpod boto3

WORKDIR /app
CMD ["bash"]
