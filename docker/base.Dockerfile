# docker/base.Dockerfile
# 공용 CUDA + Python 베이스 (torch 없음)

FROM nvidia/cuda:11.7.1-cudnn8-devel-ubuntu20.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    RUNPOD_VOLUME_ROOT=/runpod-volume \
    HF_HOME=/runpod-volume/hf \
    HF_HUB_CACHE=/runpod-volume/hf/cache \
    TRANSFORMERS_CACHE=/runpod-volume/hf/transformers \
    DIFFUSERS_CACHE=/runpod-volume/hf/diffusers \
    TORCH_HOME=/runpod-volume/torch \
    XDG_CACHE_HOME=/runpod-volume/.cache \
    TMPDIR=/runpod-volume/tmp

# 기본 패키지 (이미 있어도 그냥 깐다)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 python3-pip python3-dev \
        git wget curl ca-certificates \
        build-essential \
        cmake ninja-build \
        libgl1-mesa-glx libglib2.0-0 \
        libjpeg-dev zlib1g-dev \
        ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# python 심볼릭 링크
RUN ln -sf /usr/bin/python3 /usr/bin/python

RUN python3 -m pip install --upgrade pip && \
    pip install --no-cache-dir \
        setuptools wheel \
        requests pyyaml \
        tqdm

WORKDIR /app

CMD ["bash"]
