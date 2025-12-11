# docker/stage2.unique.base.Dockerfile
# Unique3D 전용 Stage2 베이스
# FROM: 기존 공통 베이스 유지
#   ghcr.io/nokozan/aue-base-large:cuda118-py310

FROM ghcr.io/nokozan/aue-base-large:cuda118-py310

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

# ------------------------------------------------------
# 1) 시스템 패키지 (Unique3D 요구사항에서 사용하는 애들만)
# ------------------------------------------------------
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

# ------------------------------------------------------
# 2) Unique3D 핵심 의존성 (requirements-detail.txt 기준 축약본)
#    Python 3.8 / CUDA 11.7 환경이라 정확히 같게는 못 맞추지만
#    버전은 공식 requirement를 최대한 따라간다.
# ------------------------------------------------------
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

# (필요시) Unique3D requirements-detail.txt 에 있는 나머지 패키지들
# 예: opencv-python, scipy, pymeshlab 등
# RUN pip install --no-cache-dir \
#         "opencv-python" \
#         "scipy" \
#         "pymeshlab==2023.12.post1"

CMD ["bash"]
