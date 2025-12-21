# docker/base.torch24-cu118.setupsh.Dockerfile
# 목적: torch 설치를 conda install이 아니라 TRELLIS 공식 setup.sh(--new-env)로 통일

FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    git ca-certificates curl wget bzip2 \
    build-essential cmake ninja-build pkg-config \
    && rm -rf /var/lib/apt/lists/*

ENV CONDA_DIR=/opt/conda
RUN wget -q https://repo.anaconda.com/miniconda/Miniconda3-py310_24.7.1-0-Linux-x86_64.sh -O /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p ${CONDA_DIR} && rm -f /tmp/miniconda.sh
ENV PATH="${CONDA_DIR}/bin:${PATH}"

ENV CONDA_ALWAYS_YES=true
RUN conda config --system --set always_yes yes

# conda pkgs 캐시 폭발 방지
ENV CONDA_PKGS_DIRS=/tmp/conda-pkgs
SHELL ["/bin/bash", "-lc"]

WORKDIR /opt
RUN git clone --recurse-submodules https://github.com/microsoft/TRELLIS.git
WORKDIR /opt/TRELLIS

# 공식 플로우로 env+torch까지 생성
RUN source ${CONDA_DIR}/etc/profile.d/conda.sh && \
    bash ./setup.sh --new-env && \
    conda clean -a -y && \
    rm -rf /tmp/conda-pkgs

# setup.sh가 만든 env를 기본 python으로 고정 (env 이름이 trellis라는 가정)
ENV PATH="${CONDA_DIR}/envs/trellis/bin:${PATH}"

RUN python -c "import torch; print('torch', torch.__version__, 'cuda', torch.version.cuda)"
CMD ["bash"]
