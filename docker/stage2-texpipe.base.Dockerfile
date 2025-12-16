# ghcr.io/nokozan/aue-stage2-base-texpipe:cuda118-py310
# 목적: "텍스처 생성/베이크" 전용 베이스. TripoSR/Unique3D 절대 포함 금지.
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

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
ENV DEBIAN_FRONTEND=noninteractive

# 0) dpkg 복구 안전장치
RUN dpkg --configure -a || true

# 1) openssl 먼저 (ca-certificates postinst가 여기서 자주 터짐)
RUN apt-get update && \
    apt-get install -y --no-install-recommends openssl && \
    rm -rf /var/lib/apt/lists/*

# 2) ca-certificates는 단독 설치 + 강제 구성
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates && \
    update-ca-certificates && \
    dpkg --configure -a && \
    rm -rf /var/lib/apt/lists/*

# 3) 나머지 설치: 여기서 python3-pip / python3-venv “패키지”는 설치하지만 pip는 설치하지 않는다
#    -> python3-venv는 필요(venv 생성), pip는 get-pip로 해결
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      git wget curl \
      python3 python3-dev python3-venv \
      build-essential pkg-config cmake ninja-build \
      ffmpeg \
      libgl1 libglib2.0-0 \
      libx11-6 libxcb1 libxext6 libxrender1 \
      libegl1 libegl1-mesa && \
    dpkg --configure -a && \
    rm -rf /var/lib/apt/lists/*

# 4) pip는 get-pip로 설치 (apt의 python3-pip / *-pip-whl 완전 배제)
RUN curl -sS https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py && \
    python3 /tmp/get-pip.py && \
    python3 -m pip install --upgrade pip setuptools wheel && \
    rm -f /tmp/get-pip.py


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
