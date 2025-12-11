FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC

# ------------------------------------------------------------
# 1) 시스템 패키지
# ------------------------------------------------------------
RUN apt-get update && apt-get install -y \
    git wget curl ca-certificates \
    python3 python3-pip python3-dev python3-venv \
    build-essential \
    libgl1 libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

RUN ln -sf /usr/bin/python3 /usr/bin/python \
 && python -m pip install --upgrade pip

# ------------------------------------------------------------
# 2) PyTorch (CUDA 11.8 공식 가이드)
# ------------------------------------------------------------
RUN pip install --no-cache-dir --extra-index-url https://download.pytorch.org/whl/cu118 \
    torch==2.1.1 torchvision==0.16.1 torchaudio==2.1.1

# ------------------------------------------------------------
# 3) PyTorch3D-lite  ← 여기!!!
#    (전체 PyTorch3D는 Docker 빌드환경에서 절대 설치 불가)
# ------------------------------------------------------------
RUN pip install --no-cache-dir pytorch3d-lite

# ------------------------------------------------------------
# 4) ECON 요구 의존성 전체 (공식 requirements 기반)
# ------------------------------------------------------------
RUN pip install --no-cache-dir \
    matplotlib \
    scikit-image \
    trimesh \
    rtree \
    pytorch_lightning \
    kornia \
    chumpy \
    opencv-python \
    opencv-contrib-python \
    scikit-learn \
    protobuf \
    pymeshlab \
    dataclasses \
    mediapipe \
    einops \
    boto3 \
    tinyobjloader==2.0.0rc7 \
    "git+https://github.com/YuliangXiu/neural_voxelization_layer.git" \
    "git+https://github.com/YuliangXiu/rembg.git" \
    "git+https://github.com/mmolero/pypoisson.git"

# ------------------------------------------------------------
# 5) 공통 런타임 유틸
# ------------------------------------------------------------
RUN pip install --no-cache-dir runpod

# ------------------------------------------------------------
# 6) 캐시 디렉토리 설정 (stage1 스타일 유지)
# ------------------------------------------------------------
ENV HF_HOME=/runpod-volume/.cache/huggingface \
    HF_HUB_CACHE=/runpod-volume/.cache/huggingface \
    TRANSFORMERS_CACHE=/runpod-volume/.cache/huggingface \
    DIFFUSERS_CACHE=/runpod-volume/.cache/huggingface \
    XDG_CACHE_HOME=/runpod-volume/.cache \
    TORCH_HOME=/runpod-volume/.cache/torch \
    TMPDIR=/tmp

RUN mkdir -p /runpod-volume/.cache/huggingface \
             /runpod-volume/.cache/torch \
             /tmp/outputs

WORKDIR /app
