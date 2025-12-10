FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC

# 기본 패키지 + 빌드 툴
RUN apt-get update && apt-get install -y \
    git wget curl ca-certificates \
    python3 python3-pip python3-dev python3-venv \
    build-essential \
    ninja-build \
    libgl1 libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# python 심볼릭 링크 + pip 업그레이드
RUN ln -sf /usr/bin/python3 /usr/bin/python && \
    python -m pip install --upgrade pip

# -----------------------------------------------------------------------------
# 1) PyTorch (CUDA 11.8) - 공식 설치 가이드 조합
#    Torch 2.1.x + cu118
# -----------------------------------------------------------------------------
RUN pip install --no-cache-dir --extra-index-url https://download.pytorch.org/whl/cu118 \
    torch==2.1.1 torchvision==0.16.1 torchaudio==2.1.1

# -----------------------------------------------------------------------------
# 2) PyTorch3D - torch 선설치 후, build isolation 끄고 설치
#    (No module named 'torch' 에러 방지)
# -----------------------------------------------------------------------------
RUN pip install --no-cache-dir --no-build-isolation \
    "git+https://github.com/facebookresearch/pytorch3d.git@stable"

# -----------------------------------------------------------------------------
# 3) ICON/ECON 공통 의존성 (ECON requirements 기반)
# -----------------------------------------------------------------------------
# 1단계: 일반 PyPI 패키지 먼저
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
    tinyobjloader==2.0.0rc7

# 2단계: torch 의존하는 git 패키지들은 torch 설치 이후 + build isolation 끄고 설치
RUN pip install --no-cache-dir --no-build-isolation \
    "git+https://github.com/YuliangXiu/neural_voxelization_layer.git" \
    "git+https://github.com/YuliangXiu/rembg.git" \
    "git+https://github.com/mmolero/pypoisson.git"


# -----------------------------------------------------------------------------
# 4) RunPod 등 공통 유틸
# -----------------------------------------------------------------------------
RUN pip install --no-cache-dir runpod

# -----------------------------------------------------------------------------
# 5) 캐시 / 출력 디렉토리 (stage1 패턴 맞춤)
# -----------------------------------------------------------------------------
ENV HF_HOME=/runpod-volume/.cache/huggingface \
    TRANSFORMERS_CACHE=/runpod-volume/.cache/huggingface \
    TORCH_HOME=/runpod-volume/.cache/torch \
    MPLCONFIGDIR=/tmp/matplotlib

RUN mkdir -p /runpod-volume/.cache/huggingface \
             /runpod-volume/.cache/torch \
             /tmp/outputs


CMD ["bash"]