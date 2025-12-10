# ghcr.io/nokozan/aue-stage1-base-sd:cuda118-py310

FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    git wget curl ca-certificates python3 python3-pip python3-dev \
    libgl1-mesa-glx libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --upgrade pip setuptools wheel

# torch/cu118
RUN pip install --no-cache-dir \
    torch==2.3.1+cu118 torchvision==0.18.1+cu118 \
    --index-url https://download.pytorch.org/whl/cu118

# diffusers + transformers + tokenizers (필수)
# RUN pip install --no-cache-dir \
#     diffusers==0.30.0 \
#     transformers==4.40.0 \
#     tokenizers==0.19.1 \
#     accelerate==0.29.3 \
#     safetensors==0.4.2

RUN pip install --no-cache-dir \
    diffusers==0.30.0 \
    transformers==4.40.0 \
    tokenizers==0.19.1 \
    accelerate==0.29.3 \
    safetensors==0.4.2 \
    regex \
    sentencepiece \
    opencv-python-headless \
    pillow \
    rembg \
    kornia \
    scikit-image \
    einops


# stage1 유틸
RUN pip install --no-cache-dir \
    rembg \
    opencv-python \
    pillow

# runpod + boto3
RUN pip install --no-cache-dir runpod boto3

# 캐시/모델 경로
ENV HF_HOME=/runpod-volume/.cache/hf
ENV TORCH_HOME=/runpod-volume/.cache/torch
ENV MODEL_DIR=/runpod-volume/models/sd
ENV TMPDIR=/runpod-volume/tmp

RUN mkdir -p $HF_HOME $TORCH_HOME $MODEL_DIR $TMPDIR

WORKDIR /app
