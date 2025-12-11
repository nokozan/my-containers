# docker/stage2.tripo.base.Dockerfile
# TripoSR 전용 Stage2 베이스 (Python 3.10 + torchmcubes 가능 환경)

FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    RUNPOD_VOLUME_ROOT=/runpod-volume \
    HF_HOME=/runpod-volume/.cache/hf \
    HF_HUB_CACHE=/runpod-volume/.cache/hf \
    TRANSFORMERS_CACHE=/runpod-volume/.cache/hf \
    XDG_CACHE_HOME=/runpod-volume/.cache \
    TORCH_HOME=/runpod-volume/.cache/torch \
    TMPDIR=/runpod-volume/tmp \
    TRIPOSR_ROOT=/app/TripoSR \
    TRIPOSR_MODEL_DIR=/runpod-volume/models/triposr

RUN mkdir -p \
    /runpod-volume/.cache/hf \
    /runpod-volume/.cache/torch \
    /runpod-volume/tmp \
    /runpod-volume/models/triposr

# ------------------------------------------------------
# 1) Python 3.10 + 기본 도구
# ------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3.10 \
        python3.10-distutils \
        python3.10-venv \
        git \
        curl \
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

RUN ln -sf /usr/bin/python3.10 /usr/bin/python

RUN python -m ensurepip && \
    python -m pip install --upgrade pip setuptools wheel

WORKDIR /app

# ------------------------------------------------------
# 2) PyTorch (CUDA 11.8) - 공식 가이드대로 설치 :contentReference[oaicite:3]{index=3}
# ------------------------------------------------------
RUN pip install --no-cache-dir \
    "torch==2.1.0" "torchvision==0.16.0" "torchaudio==2.1.0" \
    --index-url https://download.pytorch.org/whl/cu118

# ------------------------------------------------------
# 3) TripoSR requirements.txt + torchmcubes
#    (공식 repo requirements 기준) :contentReference[oaicite:4]{index=4}
# ------------------------------------------------------
# 핵심 파이썬 의존성
RUN pip install --no-cache-dir \
    "omegaconf==2.3.0" \
    "Pillow==10.1.0" \
    "einops==0.7.0" \
    "transformers==4.35.0" \
    "trimesh==4.0.5" \
    "rembg" \
    "huggingface-hub" \
    "imageio[ffmpeg]" \
    "xatlas==0.0.9" \
    "moderngl==5.10.0" \
    "gradio"

# torchmcubes (이제 Py>=3.9라 설치 가능)
RUN pip install --no-cache-dir \
    "git+https://github.com/tatsy/torchmcubes.git"

# ------------------------------------------------------
# 4) TripoSR repo clone
# ------------------------------------------------------
RUN git clone --depth 1 https://github.com/VAST-AI-Research/TripoSR.git ${TRIPOSR_ROOT}

CMD ["bash"]
