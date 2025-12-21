# Torch + CUDA 11.8 + cuDNN9 가 이미 들어있는 공식 이미지 사용
# (conda로 torch 설치하다가 iJIT_NotifyEvent 터지는 거 회피)
FROM ghcr.io/pytorch/pytorch:2.4.0-cuda11.8-cudnn9-devel

SHELL ["/bin/bash", "-lc"]

# 필수 OS deps만 (빌드/컴파일용)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git ca-certificates curl wget \
    build-essential cmake ninja-build pkg-config \
    && rm -rf /var/lib/apt/lists/*

# pip 최신화
RUN python -m pip install -U pip setuptools wheel

# torch 검증 (이 이미지에서 torch import가 반드시 성공해야 함)
RUN python -c "import torch; print('torch', torch.__version__, 'cuda', torch.version.cuda); print('cuda available', torch.cuda.is_available())"

# HF 캐시는 런타임에서 /runpod-volume 로 강제할 거라 여기선 기본만 둠
ENV HF_HOME=/root/.cache/huggingface
