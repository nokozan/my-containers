FROM pytorch/pytorch:2.3.1-cuda11.8-cudnn8-runtime
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    TMPDIR=/tmp

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      ca-certificates openssl \
      ffmpeg \
      libgl1 libglib2.0-0 \
      libx11-6 libxcb1 libxext6 libxrender1 \
      libegl1 libegl1-mesa; \
    update-ca-certificates; \
    rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    python -m pip install --upgrade pip setuptools wheel; \
    pip install --no-cache-dir \
      scipy \
      diffusers==0.30.0 \
      transformers==4.40.0 \
      tokenizers==0.19.1 \
      accelerate==0.29.3 \
      safetensors==0.4.2 \
      einops pillow opencv-python-headless numpy tqdm \
      trimesh xatlas==0.0.9 imageio[ffmpeg] \
      runpod boto3

# wheel만 설치 (컴파일 없음)
# 빌드 컨텍스트에 wheels/nvdiffrast-*.whl 이 들어있어야 함
COPY wheels/nvdiffrast-*.whl /tmp/
RUN set -eux; \
    pip install --no-cache-dir /tmp/nvdiffrast-*.whl; \
    python -c "import torch; import nvdiffrast; import scipy; print('OK')"; \
    rm -f /tmp/nvdiffrast-*.whl

WORKDIR /app
CMD ["bash"]
