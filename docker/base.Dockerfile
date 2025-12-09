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

# ✅ 여기에서 python3 / python3-pip / ca-certificates는 빼준다
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git wget curl \
        build-essential \
        libgl1-mesa-glx libglib2.0-0 \
        libjpeg-dev zlib1g-dev \
        ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# CUDA 베이스 이미지에 이미 python3/pip 들어있는 경우가 많아서
# 그냥 업그레이드만 해주면 됨
RUN python3 -m pip install --upgrade pip

# PyTorch (CUDA 11.8용) + 기본 유틸
RUN pip install --no-cache-dir \
        torch torchvision --index-url https://download.pytorch.org/whl/cu118 && \
    pip install --no-cache-dir \
        numpy scipy tqdm pillow setuptools wheel \
        requests pyyaml

WORKDIR /app

CMD ["bash"]
