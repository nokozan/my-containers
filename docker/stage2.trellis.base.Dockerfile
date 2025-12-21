# docker/stage2.trellis.base.Dockerfile
FROM ghcr.io/nokozan/aue-stage2-torch-base-trellis:cuda118-py310

SHELL ["/bin/bash", "-lc"]

# OS deps (setup.sh에서 빌드 필요한 것들 대비)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git ca-certificates curl wget \
    build-essential cmake ninja-build pkg-config \
    && rm -rf /var/lib/apt/lists/*

# TRELLIS 공식 repo
WORKDIR /opt
RUN git clone --recursive https://github.com/microsoft/TRELLIS.git /opt/TRELLIS
WORKDIR /opt/TRELLIS

# ✅ 로컬에서 만들어 둔 nvdiffrast wheel만 사용 (git clone 금지)
COPY wheels/nvdiffrast-*.whl /tmp/wheels/
RUN python -m pip install --no-cache-dir /tmp/wheels/nvdiffrast-*.whl && rm -rf /tmp/wheels

# ✅ setup.sh는 "공식 그대로" 실행
#    - --new-env ❌ (conda/torch 재설치 때문에 용량/ABI 터짐)
#    - --nvdiffrast ❌ (git clone 강제라서 wheel 전략과 충돌)
RUN chmod +x ./setup.sh && \
    . ./setup.sh \
      --basic \
      --xformers \
      --flash-attn \
      --diffoctreerast \
      --spconv \
      --mipgaussian \
      --kaolin

# 검증 (빌드 단계에서 터지게)
RUN python -c "import nvdiffrast.torch as dr; print('ok: nvdiffrast')" && \
    python -c "import rembg, open3d; print('ok: rembg/open3d')"

# RunPod 규칙
WORKDIR /opt
CMD ["python", "-u", "handler.py"]
