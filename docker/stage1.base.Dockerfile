FROM ghcr.io/nokozan/aue-base-large:cuda118-py310

# torch/cu118
RUN pip install --no-cache-dir \
    "torch==2.3.1+cu118" \
    "torchvision==0.18.1+cu118" \
    --index-url https://download.pytorch.org/whl/cu118

# SD 스택 (의존성 포함)
RUN pip install --no-cache-dir \
    diffusers \
    transformers \
    accelerate \
    huggingface-hub \
    safetensors \
    sentencepiece \
    opencv-python-headless \
    pillow \
    rembg \
    kornia \
    scikit-image \
    einops

WORKDIR /app
