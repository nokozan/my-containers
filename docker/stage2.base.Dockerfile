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

# 1) Stage2 전용 torch (ICON/ECON이 요구하는 버전에 맞춰 여기만 조정)
RUN pip install --no-cache-dir \
        torch torchvision --index-url https://download.pytorch.org/whl/cu117

# 2) 공통 3D / 수학 / 이미지 스택
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

# 3) SMPL / ICON / ECON 계열에서 자주 쓰는 것들
RUN pip install --no-cache-dir \
        smplx \
        chumpy \
        pytorch-lightning \
        einops \
        kornia \
        rembg

# 4) PyTorch3D (heavy) - git에서 설치
#    여기서 빌드/용량이 좀 무거울 수 있음. 그래도 "왠만하면 설치" 정책대로 넣어둔다.
RUN pip install --no-cache-dir \
        "git+https://github.com/facebookresearch/pytorch3d.git"

# 5) 3D 렌더링 / 시각화
RUN pip install --no-cache-dir \
        pyrender \
        PyOpenGL \
        open3d

CMD ["bash"]
