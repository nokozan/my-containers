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

# FIX(한 줄 근거): setup.sh의 --new-env는 conda 전제(공식 플로우). conda를 이미지에 추가해서 setup.sh가 의도대로 동작하게 함 :contentReference[oaicite:1]{index=1}
# 2) Miniconda 설치
ENV CONDA_DIR=/opt/conda
RUN wget -q https://repo.anaconda.com/miniconda/Miniconda3-py310_24.7.1-0-Linux-x86_64.sh -O /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p ${CONDA_DIR} && \
    rm -f /tmp/miniconda.sh
ENV PATH="${CONDA_DIR}/bin:${PATH}"

# conda activate가 동작하도록 bash login shell 사용
SHELL ["/bin/bash", "-lc"]
# 4) TRELLIS clone (submodule 포함)
WORKDIR /opt
RUN git clone --recurse-submodules https://github.com/microsoft/TRELLIS.git
WORKDIR /opt/TRELLIS

# FIX(한 줄 근거): setup.sh 공식 옵션(--new-env)이 conda env  torch/cu118  basic(rembg/open3d 포함)까지 책임지도록 함 :contentReference[oaicite:3]{index=3}
# FIX(한 줄 근거): conda가 업데이트/프롬프트를 띄우면서 빌드가 멈추는 걸 방지 (non-interactive)
ENV CONDA_ALWAYS_YES=true
RUN conda config --system --set always_yes yes

# FIX(한 줄 근거): pip 진행상태를 강제로 출력해서 "멈춤/진행"을 로그에서 확실히 구분
ENV PIP_DEFAULT_TIMEOUT=300
ENV PIP_PROGRESS_BAR=on

RUN source ${CONDA_DIR}/etc/profile.d/conda.sh && \
    bash ./setup.sh --new-env --basic --xformers --flash-attn --diffoctreerast --spconv --mipgaussian --kaolin --nvdiffrast

# setup.sh가 만든 conda env를 런타임 기본 python/pip로 고정
ENV PATH="${CONDA_DIR}/envs/trellis/bin:${PATH}"

# FIX(한 줄 근거): 빌드 시점에 바로 검증해서 런타임에서 터지지 않게 함
RUN python -c "import rembg, open3d; print('ok: rembg/open3d')"
 
# 7) 런타임 편의 툴
RUN pip install --no-cache-dir huggingface_hub safetensors accelerate imageio pillow trimesh pygltflib

# 기본 엔트리포인트는 런타임 Dockerfile에서 교체
CMD ["bash"]
