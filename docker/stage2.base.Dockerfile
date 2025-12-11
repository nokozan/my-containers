FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC

RUN apt-get update && apt-get install -y \
    git wget curl ca-certificates \
    python3 python3-pip python3-dev python3-venv \
    build-essential \
    libgl1 libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

RUN ln -sf /usr/bin/python3 /usr/bin/python && python -m pip install --upgrade pip

# PyTorch cu118
RUN pip install --no-cache-dir --extra-index-url https://download.pytorch.org/whl/cu118 \
    torch==2.1.1 torchvision==0.16.1 torchaudio==2.1.1

# PyTorch3D
RUN pip install --no-cache-dir "git+https://github.com/facebookresearch/pytorch3d.git@stable"

# ECON deps (chumpy 제거)
RUN pip install --no-cache-dir \
    matplotlib \
    scikit-image \
    trimesh \
    rtree \
    pytorch_lightning \
    kornia \
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

# ECON custom deps
RUN pip install --no-cache-dir \
    "git+https://github.com/YuliangXiu/neural_voxelization_layer.git" \
    "git+https://github.com/YuliangXiu/rembg.git" \
    "git+https://github.com/mmolero/pypoisson.git"

ENV HF_HOME=/runpod-volume/.cache/huggingface \
    TRANSFORMERS_CACHE=/runpod-volume/.cache/huggingface \
    TORCH_HOME=/runpod-volume/.cache/torch

RUN mkdir -p /runpod-volume/.cache/huggingface \
    /runpod-volume/.cache/torch \
    /tmp/outputs

# WORKDIR /app
CMD ["bash"]