# docker/Dockerfile.stage2-base
# cond.png -> 3D (ICON/ECON, PyTorch3D, SMPLX 등) 전용 베이스
# 코드용 Dockerfile에서 FROM ghcr.io/nokozan/aue-stage2-base:cuda118-py310 로 사용

FROM ghcr.io/nokozan/aue-base:cuda118-py310

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    HF_HOME=/runpod-volume/hf \
    TORCH_HOME=/runpod-volume/torch \
    TMPDIR=/runpod-volume/tmp

WORKDIR /app

# 공통 3D/수학 스택
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

# SMPL/ICON/ECON 계열 의존성
RUN pip install --no-cache-dir \
        smplx \
        chumpy \
        pytorch-lightning \
        einops \
        kornia \
        rembg

# PyTorch3D (무거움, 그래도 설치 시도)
# - 휠이 안 맞으면 여기서 빌드 시도할 수도 있음
RUN pip install --no-cache-dir "git+https://github.com/facebookresearch/pytorch3d.git"

# 기타 3D 렌더/뷰어 스택
RUN pip install --no-cache-dir \
        pyrender \
        PyOpenGL \
        open3d

CMD ["bash"]
