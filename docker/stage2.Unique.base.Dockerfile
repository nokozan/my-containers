FROM nvidia/cuda:12.2.2-cudnn8-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    CUDA_HOME=/usr/local/cuda \
    FORCE_CUDA=1 \
    # tensorrt pip이 추가 인덱스를 요구하는 경우가 있어 미리 고정
    PIP_EXTRA_INDEX_URL=https://pypi.nvidia.com

WORKDIR /opt

# ----------------------------------------------------------
# 1) OS deps (python3.10 + build/runtime)
# ----------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 python3.10-dev python3-pip \
    git curl ca-certificates \
    build-essential cmake pkg-config \
    ninja-build \
    libgl1 libglib2.0-0 \
    ffmpeg \
 && ln -sf /usr/bin/python3.10 /usr/bin/python \
 && python -m pip install --upgrade pip setuptools wheel \
 && rm -rf /var/lib/apt/lists/*

RUN python -V && pip -V && nvcc --version && echo "CUDA_HOME=${CUDA_HOME}"

# ----------------------------------------------------------
# 2) Torch (네가 준 고정 버전 그대로)
# ----------------------------------------------------------
RUN python -m pip install --no-cache-dir \
    "torch==2.1.0+cu121" \
    --index-url https://download.pytorch.org/whl/cu121

RUN python -c "import torch; print('torch', torch.__version__, 'cuda', torch.version.cuda)"

# ----------------------------------------------------------
# 3) 문서: ninja는 pip로도 설치 권장
# ----------------------------------------------------------
RUN python -m pip install --no-cache-dir ninja

# ----------------------------------------------------------
# 4) Unique3D pinned deps (onnxruntime*, torch_scatter, pytorch3d 제외)
# ----------------------------------------------------------
# (핀 deps 설치 블록에서 nvdiffrast 제거)
RUN python -m pip install --no-cache-dir \
    accelerate==0.29.2 \
    datasets==2.18.0 \
    diffusers==0.27.2 \
    fire==0.6.0 \
    gradio==4.32.0 \
    jaxtyping==0.2.29 \
    numba==0.59.1 \
    numpy==1.26.4 \
    omegaconf==2.3.0 \
    opencv_python==4.9.0.80 \
    opencv_python_headless==4.9.0.80 \
    peft==0.10.0 \
    Pillow==10.3.0 \
    pygltflib==1.16.2 \
    pymeshlab==2023.12.post1 \
    rembg==2.0.56 \
    tqdm==4.64.1 \
    transformers==4.39.3 \
    trimesh==4.3.0 \
    typeguard==2.13.3 \
    wandb==0.16.6

# nvdiffrast는 소스로 설치 (v0.3.1 고정)
RUN python -m pip install --no-cache-dir \
    "git+https://github.com/NVlabs/nvdiffrast.git@v0.3.1"


# ----------------------------------------------------------
# 5) ONNX Runtime (문서 그대로: CUDA12 인덱스 사용 / CPU onnxruntime 설치 금지)
# ----------------------------------------------------------
RUN python -m pip install --no-cache-dir \
    ort_nightly_gpu==1.17.0.dev20240118002 \
    --index-url https://aiinfra.pkgs.visualstudio.com/PublicPackages/_packaging/ort-cuda-12-nightly/pypi/simple/ \
 && python -m pip install --no-cache-dir \
    onnxruntime_gpu==1.17.0 \
    --index-url https://pkgs.dev.azure.com/onnxruntime/onnxruntime/_packaging/onnxruntime-cuda-12/pypi/simple/

# ----------------------------------------------------------
# 6) TensorRT (문서 그대로)
# ----------------------------------------------------------
RUN python -m pip install --no-cache-dir tensorrt==8.6.0

# 문서의 .bashrc 대신, 컨테이너 환경변수로 고정 (런타임 컨테이너에서도 상속되게)
# (site-packages 경로는 배포마다 달라질 수 있어 흔한 후보들을 같이 넣음)
ENV LD_LIBRARY_PATH=/usr/local/cuda/targets/x86_64-linux/lib/:/usr/local/lib/python3.10/dist-packages/tensorrt:/usr/lib/python3/dist-packages/tensorrt:${LD_LIBRARY_PATH}

# ----------------------------------------------------------
# 7) torch_scatter (prebuilt wheel)
# ----------------------------------------------------------
RUN python -m pip install --no-cache-dir \
    "torch_scatter==2.1.2" \
    -f https://data.pyg.org/whl/torch-2.1.0+cu121.html

# ----------------------------------------------------------
# 8) pytorch3d (문서 그대로: prebuilt wheel / 버전스트링 계산)
#    - heredoc 없이 안전하게: URL을 python으로 계산 → 쉘 변수로 받아 pip -f
# ----------------------------------------------------------
RUN python -m pip install --no-cache-dir fvcore iopath \
 && P3D_URL="$(python -c "import sys, torch; \
pyt=torch.__version__.split('+')[0].replace('.',''); \
v=''.join([f'py3{sys.version_info.minor}_cu', torch.version.cuda.replace('.',''), f'_pyt{pyt}']); \
print(f'https://dl.fbaipublicfiles.com/pytorch3d/packaging/wheels/{v}/download.html')")" \
 && echo "pytorch3d wheel url: ${P3D_URL}" \
 && python -m pip install --no-index --no-cache-dir pytorch3d==0.7.5 -f "${P3D_URL}"

# ----------------------------------------------------------
# 9) sanity
# ----------------------------------------------------------
RUN python -c "import diffusers, peft; print('diffusers', diffusers.__version__, 'peft', peft.__version__)" \
 && python -c "import onnxruntime as ort; print('onnxruntime', ort.__version__, 'providers', ort.get_available_providers())" || true
