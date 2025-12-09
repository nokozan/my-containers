# docker/Dockerfile.stage1-base
# Text -> Image (SD) + 배경 제거 전용 베이스
# 코드용 Dockerfile에서 FROM ghcr.io/nokozan/aue-stage1-base:cuda118-py310 로 사용

FROM ghcr.io/nokozan/aue-base:cuda118-py310

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    HF_HOME=/runpod-volume/hf \
    TRANSFORMERS_CACHE=/runpod-volume/hf/transformers \
    DIFFUSERS_CACHE=/runpod-volume/hf/diffusers \
    TORCH_HOME=/runpod-volume/torch \
    TMPDIR=/runpod-volume/tmp

WORKDIR /app

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
        pillow \
        torchvision \
        # 배경 제거/segmentation
        rembg \
        segment-anything \
        # 유틸
        tqdm \
        matplotlib \
        scikit-image \
        datasets

# 선택: ControlNet / 이미지 유틸 추가
RUN pip install --no-cache-dir \
        controlnet-aux \
        kornia

CMD ["bash"]
