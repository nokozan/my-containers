# docker/stage1.base.Dockerfile
# Text -> Image (SD/SDXL) + 배경 제거 전용 Stage1 베이스

FROM ghcr.io/nokozan/aue-base-large:cuda118-py310

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    RUNPOD_VOLUME_ROOT=/runpod-volume \
    HF_HOME=/runpod-volume/hf \
    HF_HUB_CACHE=/runpod-volume/hf/cache \
    TRANSFORMERS_CACHE=/runpod-volume/hf/transformers \
    DIFFUSERS_CACHE=/runpod-volume/hf/diffusers \
    TORCH_HOME=/runpod-volume/torch \
    XDG_CACHE_HOME=/runpod-volume/.cache \
    TMPDIR=/runpod-volume/tmp

WORKDIR /app

# 1) Stage1 전용 torch (필요하면 여기 버전만 갈아끼우면 됨)
RUN pip install --no-cache-dir \
        torch torchvision --index-url https://download.pytorch.org/whl/cu117

# 2) Stable Diffusion / Text-to-Image 관련 스택
RUN pip install --no-cache-dir \
        diffusers \
        transformers \
        accelerate \
        safetensors \
        sentencepiece \
        einops \
        xformers \
        opencv-python-headless \
        pillow

# 3) 배경 제거 / segmentation / ControlNet 보조
RUN pip install --no-cache-dir \
        rembg \
        segment-anything \
        controlnet-aux \
        kornia \
        scikit-image

# 4) 기타 유틸 / 디버깅용
RUN pip install --no-cache-dir \
        tqdm \
        matplotlib \
        datasets

CMD ["bash"]
