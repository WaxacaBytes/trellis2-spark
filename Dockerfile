FROM nvcr.io/nvidia/cuda:12.9.1-cudnn-devel-ubuntu24.04
ARG DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git ca-certificates curl wget build-essential \
    cmake ninja-build pkg-config \
    libssl-dev zlib1g-dev libbz2-dev libsqlite3-dev libffi-dev liblzma-dev \
    ffmpeg \
    python3 python3-pip python3-dev python3-venv \
    libx11-dev libxext-dev libxi-dev libxxf86vm-dev libxrender-dev libxfixes-dev \
    mesa-common-dev libgl1-mesa-dev libglu1-mesa-dev \
    libegl1-mesa-dev libgles2-mesa-dev \
    libjpeg-dev libtiff-dev libopenjp2-7-dev liblcms2-dev libwebp-dev libfreetype6-dev libpng-dev \
    sudo jq \
    && rm -rf /var/lib/apt/lists/*

# Create and activate Python virtual environment
RUN python3 -m venv /opt/venv \
    && /opt/venv/bin/python -m pip install --upgrade pip setuptools wheel
ENV PATH="/opt/venv/bin:${PATH}"

# Configure CUDA environment variables
ENV CUDA_HOME=/usr/local/cuda-12.9
ENV PATH="$CUDA_HOME/bin:${PATH}"
ENV LD_LIBRARY_PATH="$CUDA_HOME/lib64:${LD_LIBRARY_PATH}"
ENV TORCH_CUDA_ARCH_LIST="12.1+PTX"

# Triton settings
ENV TRITON_PTXAS_PATH="$CUDA_HOME/bin/ptxas"
ENV TRITON_CACHE_DIR="/workspace/cache/triton"

# Install PyTorch (nightly build for CUDA 12.9)
RUN pip install --no-cache-dir --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu129

# Install auxiliary tools
RUN pip install --no-cache-dir -U psutil packaging ninja

# Install flash-attn
ENV PIP_PREFER_BINARY=1
RUN pip install flash_attn==2.7.4.post1 --no-build-isolation

# Install requirements
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt \
    && pip install --no-cache-dir git+https://github.com/EasternJournalist/utils3d.git@9a4eb15e4021b67b12c460c7057d642626897ec8

# Clone repositories
ARG TRELLIS_REPO=https://github.com/microsoft/TRELLIS.2.git
ARG TRELLIS_REF=main

RUN mkdir -p /tmp/extensions \
    && git clone -b "$TRELLIS_REF" --recursive "$TRELLIS_REPO" /workspace/TRELLIS.2 \
    && git clone -b v0.4.0 https://github.com/NVlabs/nvdiffrast.git /tmp/extensions/nvdiffrast \
    && git clone -b renderutils https://github.com/JeffreyXiang/nvdiffrec.git /tmp/extensions/nvdiffrec \
    && git clone --recursive https://github.com/JeffreyXiang/CuMesh.git /tmp/extensions/CuMesh \
    && git clone --recursive https://github.com/JeffreyXiang/FlexGEMM.git /tmp/extensions/FlexGEMM

# Build and install extensions
RUN pip install /tmp/extensions/nvdiffrast --no-build-isolation
RUN pip install /tmp/extensions/nvdiffrec --no-build-isolation
RUN pip install /tmp/extensions/CuMesh --no-build-isolation
RUN pip install /tmp/extensions/FlexGEMM --no-build-isolation
RUN pip install /workspace/TRELLIS.2/o-voxel --no-build-isolation

WORKDIR /workspace/TRELLIS.2

COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

ENV ATTN_BACKEND=flash-attn
ENV GRADIO_SERVER_NAME="0.0.0.0"

ENTRYPOINT ["/app/entrypoint.sh"]
