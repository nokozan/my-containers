# docker/stage1.base.Dockerfile
# Text -> Image (SD/SDXL) + 배경 제거 전용 Stage1 베이스
# torch는 한 번만, diffusers/transformers는 --no-deps로

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

# 1) Stage1 전용 torch (CUDA 11.8용 cu118 휠) - 딱 한 번만 설치
#    버전은 Runpod / PyTorch 조합에 맞춰 핀 해두는 게 안전함.
RUN pip install --no-cache-dir \
        "torch==2.3.1+cu118" \
        "torchvision==0.18.1+cu118" \
        --index-url https://download.pytorch.org/whl/cu118

# 2) SD 핵심 스택 (의존성 자동 설치 막기 위해 --no-deps)
#    -> torch는 이미 있으니, 얘들이 건들지 못하게 만든다.
RUN pip install --no-cache-dir --no-deps \
        diffusers \
        transformers \
        accelerate
        
RUN pip install --no-cache-dir huggingface-hub

# 3) 나머지 필수 의존성들 (이쪽은 deps 켜도 됨)
RUN pip install --no-cache-dir \
        safetensors \
        sentencepiece \
        einops \
        opencv-python-headless \
        pillow \
        tqdm

# 4) 배경 제거 / 이미지 처리
RUN pip install --no-cache-dir \
        rembg \
        kornia \
        scikit-image

# (선택) 여유 생기면 아래를 나중에 추가해도 됨
# RUN pip install --no-cache-dir \
#         controlnet-aux \
#         segment-anything

CMD ["bash"]
