# docker/stage2.trellis.base.Dockerfile
FROM ghcr.io/nokozan/aue-stage2-torch-base-trellis:cuda118-py310

SHELL ["/bin/bash", "-lc"]

# OS deps (setup.sh에서 빌드 필요한 것들 대비)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git ca-certificates curl wget \
    build-essential cmake ninja-build pkg-config \
    # FIX: open3d가 런타임에 필요로 하는 X11/GL 런타임 라이브러리
    libx11-6 libxext6 libxrender1 \
    libgl1 \
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
# RUN chmod +x ./setup.sh && \
#     . ./setup.sh \
#       --basic \
#       --xformers \
#       --flash-attn \
#       --diffoctreerast \
#       --spconv \
#       --mipgaussian \
#       --kaolin
RUN chmod +x ./setup.sh && \
    . ./setup.sh --basic

# (A) xformers: PyTorch 공식 cu118 wheel index 사용
RUN python -m pip install --no-cache-dir \
      xformers==0.0.27.post2 \
      --index-url https://download.pytorch.org/whl/cu118

# (B) spconv: cu118 전용 패키지 (PyPI에 별도 배포)
RUN python -m pip install --no-cache-dir spconv-cu118

# (C) kaolin: NVIDIA Kaolin wheel index(-f) 사용
# setup.sh도 torch 2.4.0에서 cu121 링크를 사용하고 있고, 커뮤니티 requirements도 같은 패턴을 씀.
RUN python -m pip install --no-cache-dir \
      kaolin==0.17.0 \
      -f https://nvidia-kaolin.s3.us-east-2.amazonaws.com/torch-2.4.0_cu121.html

# (D) flash-attn: 가능하면 버전 고정(커뮤니티에서 많이 쓰는 조합)
# devel 이미지라 nvcc 있어 빌드도 가능. 휠이 있으면 휠로 깔리고 없으면 소스빌드.
RUN python -c "import torch; print('torch ok', torch.__version__)"
RUN python -m pip install --no-cache-dir --no-build-isolation flash-attn==2.7.0.post2

# (E) diffoctreerast: 소스 설치(빌드 타임 1회, 이미지에 bake)
RUN rm -rf /tmp/extensions && mkdir -p /tmp/extensions && \
    git clone --recurse-submodules https://github.com/JeffreyXiang/diffoctreerast.git /tmp/extensions/diffoctreerast && \
    python -c "import torch; print('torch ok', torch.__version__)" && \
    python -m pip install --no-cache-dir --no-build-isolation /tmp/extensions/diffoctreerast


# (F) mipgaussian: 소스 설치(= setup.sh가 하던 방식 그대로, 단 조건문 없이)
RUN rm -rf /tmp/extensions && mkdir -p /tmp/extensions && \
    git clone https://github.com/autonomousvision/mip-splatting.git /tmp/extensions/mip-splatting && \
    python -m pip install --no-cache-dir /tmp/extensions/mip-splatting/submodules/diff-gaussian-rasterization/


# 검증 (빌드 단계에서 터지게)
RUN python -c "import nvdiffrast.torch as dr; print('ok: nvdiffrast')" && \
    python -c "import rembg, open3d; print('ok: rembg/open3d')"

# RunPod 규칙
WORKDIR /opt
CMD ["python", "-u", "handler.py"]
