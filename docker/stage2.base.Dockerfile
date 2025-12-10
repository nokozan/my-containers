FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC

# 기본 유틸 및 빌드 툴
RUN apt-get update && apt-get install -y \
    git wget curl ca-certificates \
    python3 python3-pip python3-dev python3-venv \
    build-essential \
    libgl1 libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# python 심볼릭 링크
RUN ln -sf /usr/bin/python3 /usr/bin/python \
 && python -m pip install --upgrade pip

# -----------------------------------------------------------------------------
# 1) PyTorch (CUDA 11.8) - 공식 설치 가이드 기반
# -----------------------------------------------------------------------------
# https://pytorch.org/get-started/previous-versions/ 기준으로 CUDA 11.8 조합 사용 :contentReference[oaicite:2]{index=2}
RUN pip install --no-cache-dir --extra-index-url https://download.pytorch.org/whl/cu118 \
    torch==2.1.1 torchvision==0.16.1 torchaudio==2.1.1

# -----------------------------------------------------------------------------
# 2) PyTorch3D - 공식 repo 설치 가이드
# -----------------------------------------------------------------------------
# https://github.com/facebookresearch/pytorch3d :contentReference[oaicite:3]{index=3}
RUN pip install --no-cache-dir "git+https://github.com/facebookresearch/pytorch3d.git@stable"

# -----------------------------------------------------------------------------
# 3) ECON 런타임 의존성 (공식 HF Space requirements 그대로)
#    https://huggingface.co/spaces/Yuliang/ECON/blob/main/requirements.txt :contentReference[oaicite:4]{index=4}
# -----------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------
# 4) 공통 유틸 (RunPod, 기타)
# -----------------------------------------------------------------------------
RUN pip install --no-cache-dir runpod

# -----------------------------------------------------------------------------
# 5) 캐시/임시 디렉토리 설정 (stage1과 패턴 맞춤)
# -----------------------------------------------------------------------------
ENV HF_HOME=/runpod-volume/.cache/huggingface \
    TRANSFORMERS_CACHE=/runpod-volume/.cache/huggingface \
    TORCH_HOME=/runpod-volume/.cache/torch \
    MPLCONFIGDIR=/tmp/matplotlib

RUN mkdir -p /runpod-volume/.cache/huggingface \
             /runpod-volume/.cache/torch \
             /tmp/outputs
CMD ["bash"]
