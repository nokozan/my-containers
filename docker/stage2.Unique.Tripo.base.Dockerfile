# docker/stage2.base.Dockerfile
# cond.png -> 3D (ICON/ECON, SMPLX 등) 전용 Stage2 베이스
# torch는 한 번만, 나머지는 필요 최소 + no-deps 전략
# ghcr.io/nokozan/aue-stage2-base-icon-econ:cuda118-py310

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

# 1) Stage2 전용 torch (CUDA 11.8용) - 딱 한 번만
RUN pip install --no-cache-dir \
        "torch==2.3.1+cu118" \
        "torchvision==0.18.1+cu118" \
        --index-url https://download.pytorch.org/whl/cu118

# 2) 공통 수학 / 이미지 / 3D 베이스 스택
RUN pip install --no-cache-dir \
        numpy \
        scipy \
        pillow \
        opencv-python \
        tqdm \
        matplotlib \
        trimesh \
        shapely \
        scikit-image \
        scikit-learn
        
RUN pip install --no-cache-dir \
    boto3 \
    Pillow


# 3) SMPL / ICON / ECON 계열 (torch 의존성 있으니 no-deps로)
RUN pip install --no-cache-dir --no-deps \
    smplx \
    einops \
    kornia

RUN pip install --no-cache-dir \
    pytorch-lightning


# 4) 마스크/알파 작업용
RUN pip install --no-cache-dir \
        rembg

# 5) (옵션) PyTorch3D - 무겁고 CI 디스크 터질 수 있어서 마지막에 분리
#    일단은 주석 처리해두고, 필요해지면 이 줄만 살려서 빌드 시도.
# RUN pip install --no-cache-dir \
#         "git+https://github.com/facebookresearch/pytorch3d.git"

# 6) (옵션) 시각화/렌더링 - 필요하면 나중에 켜기
RUN pip install --no-cache-dir \
        pyrender \
        PyOpenGL \
        open3d

CMD ["bash"]
