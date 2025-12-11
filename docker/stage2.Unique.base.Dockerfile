# ==========================================================
# Unique3D 전용 Stage2 Base (CUDA 11.7 / Python 3.8 / torch 2.4.1)
# ==========================================================

FROM ghcr.io/nokozan/aue-base-large:cuda118-py310

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
    TMPDIR=/runpod-volume/tmp \
    UNIQUE3D_MODEL_DIR=/runpod-volume/models/unique3d

RUN mkdir -p \
    /runpod-volume/hf/cache \
    /runpod-volume/hf/transformers \
    /runpod-volume/hf/diffusers \
    /runpod-volume/torch \
    /runpod-volume/tmp \
    /runpod-volume/models/unique3d

# ----------------------------------------------------------
# 1. 시스템 패키지
# ----------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        ffmpeg \
        libgl1-mesa-glx libglib2.0-0 \
        build-essential \
        cmake \
        pkg-config \
        wget \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app


# ----------------------------------------------------------
# 2. PyTorch 2.4.1 + cu118 설치  (이 베이스에 torch 없는 경우 필요)
#    이미 stage1 등에서 설치되어 있을 수 있으므로 무조건 재설치 허용
# ----------------------------------------------------------
RUN pip install --no-cache-dir \
    torch==2.4.1+cu118 \
    torchvision==0.19.1+cu118 \
    torchaudio==2.4.1 \
    --index-url https://download.pytorch.org/whl/cu118


# ----------------------------------------------------------
# 3. 기본 Python 패키지 — Unique3D 환경 기반 + 네가 요청한 목록 포함
# ----------------------------------------------------------
RUN pip install --no-cache-dir \
        accelerate==0.29.2 \
        datasets \
        "diffusers>=0.26.3" \
        fire \
        gradio \
        jaxtyping \
        numba \
        numpy \
        "omegaconf>=2.3.0" \
        onnxruntime-gpu \
        opencv-python \
        opencv-python-headless \
        ort_nightly_gpu \
        peft \
        Pillow \
        pygltflib \
        "pymeshlab>=2023.12" \
        "rembg[gpu]" \
        tqdm \
        transformers \
        trimesh \
        typeguard \
        wandb \
        xformers \
        ninja \
        huggingface-hub


# ----------------------------------------------------------
# 4. 확장 3D 모듈 (빌드 필요)
# ----------------------------------------------------------

# 4-1 nvdiffrast (NVLabs 공식 방식)
# 4-1 nvdiffrast (NVLabs 공식 방식, torch 이미 설치된 전역 env 사용)
RUN pip install --no-build-isolation --no-cache-dir \
    "git+https://github.com/NVlabs/nvdiffrast.git"


# 4-2 pytorch3d (v0.7.8: PyTorch 2.1~2.4 공식 지원)
RUN pip install --no-cache-dir \
    "git+https://github.com/facebookresearch/pytorch3d.git@v0.7.8"

# 4-3 torch_scatter (PyTorch 2.4.x + cu118 호환 wheel)
RUN pip install --no-cache-dir \
    torch_scatter \
    -f https://data.pyg.org/whl/torch-2.4.0+cu118.html


CMD ["bash"]
