FROM ghcr.io/nokozan/aue-base-large:cuda118-py310

ENV DEBIAN_FRONTEND=noninteractive

# 1) 기본 툴 (혹시 빠져 있으면)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git wget curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 2) torch/cu118 한 번만 설치
RUN pip install --no-cache-dir \
    "torch==2.3.1+cu118" \
    "torchvision==0.18.1+cu118" \
    --index-url https://download.pytorch.org/whl/cu118

# 3) SD / diffusers 스택 (의존성 포함, --no-deps 안 씀)
RUN pip install --no-cache-dir \
    diffusers \
    transformers \
    accelerate \
    huggingface-hub \
    safetensors \
    sentencepiece \
    opencv-python-headless \
    pillow \
    rembg \
    kornia \
    scikit-image

# 4) 기타 공용 유틸(필요하면)
RUN pip install --no-cache-dir \
    einops

WORKDIR /app
