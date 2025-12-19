FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /app

# OS deps (python + build toolchain)
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 python3.10-dev python3-pip \
    git ca-certificates curl \
    build-essential cmake ninja-build pkg-config \
    libgl1 libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

RUN python3.10 -m pip install --upgrade pip setuptools wheel

RUN python3.10 -m pip install --no-cache-dir \
  torch==2.1.1 torchvision==0.16.1 torchaudio==2.1.1 \
  --index-url https://download.pytorch.org/whl/cu118

# Your deps (필요한 것만 유지/추가)
RUN python3.10 -m pip install --no-cache-dir \
    numpy pillow opencv-python-headless \
    boto3 \
    pyrender
    
RUN python3.10 -m pip install --no-cache-dir \
  pytorch3d \
  -f https://dl.fbaipublicfiles.com/pytorch3d/packaging/wheels/py310_cu118_pyt211/download.html

# wheel만 설치 (컴파일 없음)
# 빌드 컨텍스트에 wheels/nvdiffrast-*.whl 이 들어있어야 함
COPY wheels/nvdiffrast-*.whl /tmp/
RUN set -eux; \
    pip install --no-cache-dir /tmp/nvdiffrast-*.whl; \
    python3.10 -c "import torch; import nvdiffrast; import scipy; print('OK')"; \
    rm -f /tmp/nvdiffrast-*.whl


RUN pip install --no-cache-dir nvdiffrast


ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    TMPDIR=/tmp

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      ca-certificates openssl \
      ffmpeg \
      libgl1 libglib2.0-0 \
      libx11-6 libxcb1 libxext6 libxrender1 \
      libegl1 libegl1-mesa; \
    update-ca-certificates; \
    rm -rf /var/lib/apt/lists/*

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





WORKDIR /app
CMD ["bash"]
