# docker/stage2.trellis.base.fromtorch.Dockerfile
# 목적: 위 torch 베이스를 FROM으로 사용해서,
#       TRELLIS는 setup.sh를 --new-env 없이 돌리고 나머지 의존성만 설치한다.

FROM ghcr.io/nokozan/aue-stage2-torch-base-trellis:cuda118-py310

ARG DEBIAN_FRONTEND=noninteractive

# TRELLIS 빌드에 필요한 OS deps (setup.sh에서 쓰는 것들 최소)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git ca-certificates curl wget \
    build-essential cmake ninja-build pkg-config \
    && rm -rf /var/lib/apt/lists/*

# (선택) pip 업그레이드
RUN python -m pip install -U pip setuptools wheel

# TRELLIS clone
WORKDIR /opt
RUN git clone --recurse-submodules https://github.com/microsoft/TRELLIS.git
WORKDIR /opt/TRELLIS

# setup.sh는 conda env를 새로 만들지 말고(=--new-env 금지),
# 현재 env(=trellis)에 필요한 컴포넌트만 설치한다.
# NOTE: flags는 너가 지금 쓰는 조합 유지
RUN bash ./setup.sh --basic --xformers --diffoctreerast --spconv --mipgaussian --kaolin --nvdiffrast

# 설치 후 conda/pip 캐시 정리(이미 torch 베이스에서 대부분 정리됨)
RUN conda clean -a -y || true

# 빌드 검증(예제들이 요구하는 모듈)
RUN python -c "import torch; import rembg, open3d; print('ok: torch/rembg/open3d')"

CMD ["bash"]
