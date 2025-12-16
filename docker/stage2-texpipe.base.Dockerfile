# stage2-texpipe.base.Dockerfile
# GH Actions: target: runtime 로 푸시

# -----------------------------------------
# STAGE A: build nvdiffrast (torch 포함 + CUDA toolkit)
# -----------------------------------------
FROM pytorch/pytorch:2.3.1-cuda11.8-cudnn8-devel AS build
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
      build-essential ninja-build cmake pkg-config; \
    update-ca-certificates; \
    rm -rf /var/lib/apt/lists/*

# nvdiffrast (torch는 이미 이미지에 포함되어 있음)
RUN set -eux; \
    python -m pip install --upgrade pip setuptools wheel; \
    pip install --no-cache-dir \
      git+https://github.com/NVlabs/nvdiffrast.git --no-build-isolation

# -----------------------------------------
# STAGE B: runtime (final)
# -----------------------------------------
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
      libegl1 libegl1-mesa; \
    update-ca-certificates; \
    rm -rf /var/lib/apt/lists/*

# nvdiffrast 복사 (conda site-packages)
COPY --from=build /opt/conda/lib/python3.10/site-packages /opt/conda/lib/python3.10/site-packages

# texpipe deps
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
    python -c "import scipy, diffusers, transformers, trimesh, xatlas; print('deps ok')"

WORKDIR /app
CMD ["bash"]
