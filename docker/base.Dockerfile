# docker/Dockerfile.base
# 공용 CUDA + Python + torch 베이스
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_NO_CACHE_DIR=1 \
    PYTHONUNBUFFERED=1 \
    RUNPOD_VOLUME_ROOT=/runpod-volume \
    HF_HOME=/runpod-volume/hf \
    HF_HUB_CACHE=/runpod-volume/hf/cache \
    TRANSFORMERS_CACHE=/runpod-volume/hf/transformers \
    DIFFUSERS_CACHE=/runpod-volume/hf/diffusers \
    TORCH_HOME=/runpod-volume/torch \
    TMPDIR=/runpod-volume/tmp

# 기본 시스템 패키지
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 python3-pip python3-dev \
        git wget curl ca-certificates \
        build-essential \
        libgl1-mesa-glx libglib2.0-0 \
        libjpeg-dev zlib1g-dev \
        ffmpeg \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --upgrade pip

# PyTorch (CUDA 11.8용) + 기본 유틸
RUN pip install --no-cache-dir \
        torch torchvision --index-url https://download.pytorch.org/whl/cu118 && \
    pip install --no-cache-dir \
        numpy scipy tqdm pillow setuptools wheel \
        requests pyyaml

WORKDIR /app

CMD ["bash"]
