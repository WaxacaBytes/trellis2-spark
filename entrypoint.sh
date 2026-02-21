#!/bin/bash
set -e

echo "========================================"
echo "TRELLIS.2 SparkForge Environment"
echo "========================================"

# Ensure CUDA env
export CUDA_HOME=${CUDA_HOME:-/usr/local/cuda-12.9}
export PATH="$CUDA_HOME/bin:${PATH}"
export LD_LIBRARY_PATH="$CUDA_HOME/lib64:${LD_LIBRARY_PATH}"
export TORCH_CUDA_ARCH_LIST="12.1+PTX"

echo "Python: $(python --version)"
echo "PyTorch: $(python -c 'import torch; print(torch.__version__)')"
echo "CUDA available: $(python -c 'import torch; print(torch.cuda.is_available())')"
echo "========================================"

# --- Build native extensions on first run (DGX Spark native build) ---

mkdir -p /workspace/build_cache

# flash-attn
if ! python -c "import flash_attn" 2>/dev/null; then
    echo "[trellis2-spark] Building flash-attn (this may take 30+ minutes on first run)..."
    pip install flash_attn==2.7.4.post1 --no-build-isolation
else
    echo "[trellis2-spark] flash-attn already installed."
fi

# utils3d
if ! python -c "import utils3d" 2>/dev/null; then
    echo "[trellis2-spark] Installing utils3d..."
    pip install --no-cache-dir git+https://github.com/EasternJournalist/utils3d.git@9a4eb15e4021b67b12c460c7057d642626897ec8
fi

# nvdiffrast
if ! python -c "import nvdiffrast" 2>/dev/null; then
    echo "[trellis2-spark] Building nvdiffrast..."
    pip install /tmp/extensions/nvdiffrast --no-build-isolation
fi

# nvdiffrec
if [ ! -f "/workspace/build_cache/nvdiffrec.built" ]; then
    echo "[trellis2-spark] Building nvdiffrec..."
    pip install /tmp/extensions/nvdiffrec --no-build-isolation
    touch /workspace/build_cache/nvdiffrec.built
fi

# CuMesh
if [ ! -f "/workspace/build_cache/cumesh.built" ]; then
    echo "[trellis2-spark] Building CuMesh..."
    pip install /tmp/extensions/CuMesh --no-build-isolation
    touch /workspace/build_cache/cumesh.built
fi

# FlexGEMM
if [ ! -f "/workspace/build_cache/flexgemm.built" ]; then
    echo "[trellis2-spark] Building FlexGEMM..."
    pip install /tmp/extensions/FlexGEMM --no-build-isolation
    touch /workspace/build_cache/flexgemm.built
fi

# o-voxel
if [ ! -f "/workspace/build_cache/ovoxel.built" ]; then
    echo "[trellis2-spark] Building o-voxel..."
    pip install /workspace/TRELLIS.2/o-voxel --no-build-isolation
    touch /workspace/build_cache/ovoxel.built
fi

echo "========================================"
echo "Extensions ready! Launching app..."
echo "========================================"

# Launch
if [ $# -eq 0 ]; then
  exec python app.py
else
  exec "$@"
fi
