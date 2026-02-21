#!/bin/bash
set -e

echo "========================================"
echo "TRELLIS.2 SparkForge Environment"
echo "========================================"

# Ensure CUDA env
export CUDA_HOME=${CUDA_HOME:-/usr/local/cuda-12.9}
export PATH="$CUDA_HOME/bin:${PATH}"
export LD_LIBRARY_PATH="$CUDA_HOME/lib64:${LD_LIBRARY_PATH}"

echo "Python: $(python --version)"
echo "PyTorch: $(python -c 'import torch; print(torch.__version__)')"
echo "CUDA available: $(python -c 'import torch; print(torch.cuda.is_available())')"

echo "========================================"

# Launch
if [ $# -eq 0 ]; then
  exec python app.py
else
  exec "$@"
fi
