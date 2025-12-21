# docker/stage2.trellis.torch.base.Dockerfile
# 목적: conda env 'trellis'에 torch/cu118을 정확히 설치하고,
#       이후 모든 RUN에서 그 env python만 사용하도록 강제한다.

FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget ca-certificates bzip2 git \
    && rm -rf /var/lib/apt/lists/*

ENV CONDA_DIR=/opt/conda
RUN wget -q https://repo.anaconda.com/miniconda/Miniconda3-py310_24.7.1-0-Linux-x86_64.sh -O /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p ${CONDA_DIR} && \
    rm -f /tmp/miniconda.sh
ENV PATH="${CONDA_DIR}/bin:${PATH}"

ENV CONDA_ALWAYS_YES=true
RUN conda config --system --set always_yes yes

# pkgs 캐시를 /tmp로 보내서 디스크 압박 줄이기
ENV CONDA_PKGS_DIRS=/tmp/conda-pkgs

# 중요한 고정:
# 1) 이후 RUN은 무조건 bash -lc 사용
# 2) conda activate trellis를 항상 통해서 env python만 쓰게 함
SHELL ["/bin/bash", "-lc"]

# env 생성 + torch 설치 (base python에 절대 설치하지 않음)
RUN conda create -n trellis python=3.10 -y && \
    source ${CONDA_DIR}/etc/profile.d/conda.sh && \
    conda activate trellis && \
    conda install -y pytorch==2.4.0 torchvision==0.19.0 pytorch-cuda=11.8 -c pytorch -c nvidia && \
    # iJIT 심볼 관련 런타임 충돌 방지용(필요시)
    conda install -y -c conda-forge intel-openmp && \
    conda clean -a -y && \
    rm -rf /tmp/conda-pkgs

# 여기서부터는 env python을 "절대 경로"로 고정 (PATH 꼬여도 안전)
ENV TRELLIS_PY=${CONDA_DIR}/envs/trellis/bin/python
ENV TRELLIS_PIP=${CONDA_DIR}/envs/trellis/bin/pip

# 검증도 절대 경로 python으로만 한다 (base conda import 절대 금지)
RUN ${TRELLIS_PY} -c "import torch; print('torch', torch.__version__, 'cuda', torch.version.cuda)"

CMD ["bash"]
