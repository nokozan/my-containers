# trellis.base.Dockerfile
# 목적: GHCR에서 빌드(무거운 설치/컴파일) 완료 -> RunPod에서는 pull만.

FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# 1) OS deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    git ca-certificates curl wget \
    build-essential cmake ninja-build \
    python3 python3-pip python3-venv \
    && rm -rf /var/lib/apt/lists/*

# 2) venv
ENV VENV=/opt/venv
RUN python3 -m venv ${VENV}
ENV PATH="${VENV}/bin:${PATH}"
RUN pip install --upgrade pip setuptools wheel

# 3) PyTorch (CUDA 11.8)
# (PyTorch 설치 URL은 종종 바뀔 수 있어, 실제로는 torch 공식 가이드에 맞춰 조정 권장)
RUN pip install --no-cache-dir torch==2.4.0 torchvision==0.19.0 --index-url https://download.pytorch.org/whl/cu118

# 4) TRELLIS clone (submodule 포함)
WORKDIR /opt
RUN git clone --recurse-submodules https://github.com/microsoft/TRELLIS.git
WORKDIR /opt/TRELLIS

# 5) 기본 런타임 deps (xformers 우선)
# RUN pip install --no-cache-dir xformers
# reason: xformers 단독 설치가 torch==2.9.x + cu12 패키지까지 끌어와서 디스크 터짐을 방지
# (1) torch를 cu118로 먼저 고정 설치
RUN pip install --no-cache-dir \
  --index-url https://download.pytorch.org/whl/cu118 \
  torch==2.4.0 torchvision==0.19.0

# (2) 이후 xformers는 deps 해석 금지(= torch 업그레이드/쿠다12 끌어오기 차단)
RUN pip install --no-cache-dir --no-deps xformers==0.0.27.post2

# 6) TRELLIS setup.sh 기반 설치
# 공식은 conda 환경 생성도 지원하지만, 여기서는 venv에 설치하려고 --new-env 없이 필요한 것만 맞춘다.
# setup.sh는 내부적으로 여러 컴포넌트 설치를 관리함. :contentReference[oaicite:5]{index=5}
RUN bash -lc ". ./setup.sh --basic --xformers --diffoctreerast --spconv --mipgaussian --kaolin --nvdiffrast"

# 7) 런타임 편의 툴
RUN pip install --no-cache-dir huggingface_hub safetensors accelerate imageio pillow trimesh pygltflib

# 기본 엔트리포인트는 런타임 Dockerfile에서 교체
CMD ["bash"]
