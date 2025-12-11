# docker/stage2.unique.base.Dockerfile
# Unique3D 전용 Stage2 베이스 (공식 스펙 맞춘 버전)

FROM nvcr.io/nvidia/pytorch:23.10-py3

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    RUNPOD_VOLUME_ROOT=/runpod-volume \
    HF_HOME=/runpod-volume/.cache/hf \
    HF_HUB_CACHE=/runpod-volume/.cache/hf \
    TRANSFORMERS_CACHE=/runpod-volume/.cache/hf \
    DIFFUSERS_CACHE=/runpod-volume/.cache/diffusers \
    TORCH_HOME=/runpod-volume/.cache/torch \
    XDG_CACHE_HOME=/runpod-volume/.cache \
    TMPDIR=/runpod-volume/tmp \
    UNIQUE3D_MODEL_DIR=/runpod-volume/models/unique3d

RUN mkdir -p \
    /runpod-volume/.cache/hf \
    /runpod-volume/.cache/diffusers \
    /runpod-volume/.cache/torch \
    /runpod-volume/tmp \
    /runpod-volume/models/unique3d

WORKDIR /app

# 시스템 패키지
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        ffmpeg \
        libgl1-mesa-glx \
        libglib2.0-0 \
        libx11-6 \
        libxcb1 \
        libxext6 \
        libxrender1 \
        build-essential \
        pkg-config \
    && rm -rf /var/lib/apt/lists/*

# 이 이미지 안에는 이미 torch 2.1.0+cu121 이 깔려 있으므로
# torch는 건드리지 말고 Unique3D requirements-detail.txt 기반 패키지만 설치
RUN pip install --no-cache-dir \
        "ninja" \
        "diffusers==0.27.2" \
        "transformers==4.39.3" \
        "accelerate==0.29.2" \
        "onnxruntime-gpu==1.17.0" \
        "pytorch3d==0.7.5" \
        "rembg==2.0.56" \
        "trimesh==4.3.0" \
        "Pillow==10.3.0" \
        "omegaconf==2.3.0" \
        "huggingface-hub==0.25.2"

# 필요하면 Unique3D쪽 나머지 패키지 추가
RUN pip install --no-cache-dir \
        "opencv-python" \
        "pymeshlab==2023.12.post1" \
        "pygltflib==1.16.2"

CMD ["bash"]
