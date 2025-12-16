# ghcr.io/nokozan/aue-stage2-base-texpipe:cuda118-py310
# 목적: "텍스처 생성/베이크" 전용 베이스. TripoSR/Unique3D 절대 포함 금지.

FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu20.04

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

RUN apt-get update && apt-get install -y --no-install-recommends \
    git wget curl ca-certificates \
    python3 python3-pip python3-dev \
    build-essential pkg-config cmake ninja-build \
    ffmpeg \
    libgl1-mesa-glx libglib2.0-0 \
    libx11-6 libxcb1 libxext6 libxrender1 \
    libegl1 libegl1-mesa \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --upgrade pip setuptools wheel

# torch/cu118 (stage1과 동일 계열로 맞춤: diffusers 안정성)
RUN pip install --no-cache-dir \
    torch==2.3.1+cu118 torchvision==0.18.1+cu118 \
    --index-url https://download.pytorch.org/whl/cu118

# diffusers stack (stage1.base 버전과 동일하게 고정)
RUN pip install --no-cache-dir \
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

# 유틸 + 메쉬/UV 처리
RUN pip install --no-cache-dir \
    trimesh \
    xatlas==0.0.9 \
    imageio[ffmpeg]

# runpod + s3
RUN pip install --no-cache-dir runpod boto3

RUN mkdir -p \
    /runpod-volume/.cache/hf \
    /runpod-volume/.cache/torch \
    /runpod-volume/tmp

WORKDIR /app
CMD ["bash"]
