# docker/stage2.base.Dockerfile
# cond.png -> 3D (ICON/ECON, SMPLX, PyTorch3D 등) 전용 Stage2 베이스

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

# 🔥 Stage2 전용 torch (ICON/ECON 요구 버전에 맞춰 여기만 바꾸면 됨)
RUN pip install --no-cache-dir \
        torch torchvision --index-url https://download.pytorch.org/whl/cu117

# 공통 3D / 수학 / 이미지 스택
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

# SMPL / ICON / ECON 계열
RUN pip install --no-cache-dir \
        smplx \
        chumpy \
        pytorch-lightning \
        einops \
        kornia \
        rembg

# PyTorch3D (무거움) - git에서 설치
RUN pip install --no-cache-dir \
        "git+https://github.com/facebookresearch/pytorch3d.git"

# 3D 렌더링 / 시각화
RUN pip install --no-cache-dir \
        pyrender \
        PyOpenGL \
        open3d

CMD ["bash"]
