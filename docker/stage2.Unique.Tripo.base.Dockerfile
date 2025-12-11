# docker/stage2.base.unique3d_triposr.Dockerfile
# cond.png -> 3D (Unique3D + TripoSR) 전용 Stage2 베이스
# Unique3D 환경을 기준으로 고정하고, TripoSR은 "추가 의존성만" 설치
# FROM: 기존 공통 베이스 유지
#   ghcr.io/nokozan/aue-base-large:cuda118-py310

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

# ------------------------------------------------------
# 1) 시스템 패키지 (렌더링/빌드 공통)
# ------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        ffmpeg \
        libgl1-mesa-glx \
        libglib2.0-0 \
        libx11-6 \
        libxcb1 \
        libxext6 \
        libxrender1 \
        build-essential \
        pkg-config \
    && rm -rf /var/lib/apt/lists/*

# torch는 base 이미지(aue-base-large)에서 이미 설치되어 있다고 가정.
# 여기서 재설치해서 버전 꼬지 않도록 torch는 건드리지 않는다.
# (기대값: torch==2.1.0+cu118)

# ------------------------------------------------------
# 2) Unique3D 코어 의존성 (requirements-detail 기준)
#    -> 여기 버전이 "거의 진실"이므로 이쪽을 기준으로 잠근다.
# ------------------------------------------------------
RUN pip install --no-cache-dir \
        "ninja" \
        "diffusers==0.27.2" \
        "transformers==4.39.3" \
        "accelerate==0.29.2" \
        "onnxruntime-gpu==1.17.0" \
        "rembg==2.0.56" \
        "trimesh==4.3.0" \
        "Pillow==10.3.0" \
        "omegaconf==2.3.0" \
    && pip install --no-cache-dir \
        "git+https://github.com/facebookresearch/pytorch3d.git@v0.7.5"


# 필요 시 Unique3D에서 쓰는 기타 패키지(예: opencv-python 등)는
# requirements-detail과 맞춰서 여기에 추가하면 된다.
# 예:
# RUN pip install --no-cache-dir \
#         "opencv-python" \
#         "scipy"

# ------------------------------------------------------
# 3) TripoSR 전용 의존성 - Unique3D에 "없는 것만" 설치
#    TripoSR requirements.txt 기준으로, 겹치는 애들은 *절대* 다시 설치하지 않는다.
#    (transformers, Pillow, trimesh, rembg 등은 위에서 잠근 버전 사용)
# ------------------------------------------------------
RUN pip install --no-cache-dir \
        "einops==0.7.0" \
        "xatlas==0.0.9" \
        "moderngl==5.10.0" \
        "imageio[ffmpeg]" \
        "huggingface-hub" \
    && pip install --no-cache-dir \
        "git+https://github.com/tatsy/torchmcubes.git"

# gradio 같은 UI용은 Stage2 서비스 레벨에서 필요할 때만 얇게 추가
# (여기서는 공통 코어 환경만 유지)

# ------------------------------------------------------
# 4) (옵션) 시각화 / 렌더링 유틸
#    필요 없으면 주석 처리해도 됨.
# ------------------------------------------------------
RUN pip install --no-cache-dir \
        pyrender \
        PyOpenGL \
        open3d

CMD ["bash"]
