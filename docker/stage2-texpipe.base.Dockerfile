# --------------- STAGE A: build nvdiffrast with CUDA toolkit ---------------
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
      git curl wget \
      python3 python3-dev python3-venv \
      build-essential pkg-config cmake ninja-build \
      && update-ca-certificates; \
    rm -rf /var/lib/apt/lists/*

# pip (apt python3-pip 사용 안 함)
RUN set -eux; \
    curl -sS https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py; \
    python3 /tmp/get-pip.py; \
    python3 -m pip install --upgrade pip setuptools wheel; \
    rm -f /tmp/get-pip.py

# torch/cu118 (여기서 설치 — build stage는 디스크 큰 환경에서만 성공시키는 게 목적)
RUN set -eux; \
    pip install --no-cache-dir \
      torch==2.3.1+cu118 torchvision==0.18.1+cu118 \
      --index-url https://download.pytorch.org/whl/cu118

# build nvdiffrast
RUN set -eux; \
    pip install --no-cache-dir \
      git+https://github.com/NVlabs/nvdiffrast.git --no-build-isolation

# --------------- STAGE B: runtime image (small) ---------------
FROM pytorch/pytorch:2.3.1-cuda11.8-cudnn8-runtime AS runtime

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    TMPDIR=/tmp

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      ca-certificates openssl \
      git curl wget \
      ffmpeg \
      libgl1 libglib2.0-0 \
      libx11-6 libxcb1 libxext6 libxrender1 \
      libegl1 libegl1-mesa \
      && update-ca-certificates; \
    rm -rf /var/lib/apt/lists/*

# copy nvdiffrast from build stage (site-packages)
# NOTE: pytorch/pytorch uses conda python in /opt/conda
COPY --from=build /usr/local/lib/python3.10/dist-packages /opt/conda/lib/python3.10/site-packages
# some builds may put libs in /usr/local/lib; copy defensively
COPY --from=build /usr/local/lib /usr/local/lib

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

# smoke
RUN set -eux; \
    python -c "import torch; print('torch', torch.__version__, 'cuda', torch.cuda.is_available())"; \
    python -c "import nvdiffrast; print('nvdiffrast ok')"; \
    python -c "import scipy; print('scipy ok')"

WORKDIR /app
CMD ["bash"]
