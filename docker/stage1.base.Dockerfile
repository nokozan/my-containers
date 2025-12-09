# docker/stage1.base.Dockerfile
# Text -> Image (SD/SDXL) + 배경 제거 전용 Stage1 베이스

FROM ghcr.io/nokozan/aue-base:cuda117-py310

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

# 🔥 Stage1 전용 torch (필요하면 여기서 버전 바꿈)
RUN pip install --no-cache-dir \
        torch torchvision --index-url https://download.pytorch.org/whl/cu117

# Stable Diffusion / Text-to-Image 스택
RUN pip install --no-cache-dir \
        diffusers[torch] \
        transformers \
        accelerate \
        safetensors \
        sentencepiece \
        einops \
        xformers \
        opencv-python-headless \
        pillow

# 배경 제거 / segmentation 계열
RUN pip install --no-cache-dir \
        rembg \
        segment-anything \
        controlnet-aux \
        kornia \
        scikit-image

# 기타 유틸/디버깅용
RUN pip install --no-cache-dir \
        tqdm \
        matplotlib \
        datasets

CMD ["bash"]
