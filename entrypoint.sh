#!/bin/bash
set -e

echo "========================================"
echo "TRELLIS.2 — Official Build for DGX Spark"
echo "========================================"

# Ensure CUDA env
export CUDA_HOME=${CUDA_HOME:-/usr/local/cuda-12.9}
export PATH="$CUDA_HOME/bin:${PATH}"
export LD_LIBRARY_PATH="$CUDA_HOME/lib64:${LD_LIBRARY_PATH}"

echo "Python: $(python --version)"
echo "PyTorch: $(python -c 'import torch; print(torch.__version__)')"
echo "CUDA available: $(python -c 'import torch; print(torch.cuda.is_available())')"
echo "flash-attn: $(python -c 'import flash_attn; print(flash_attn.__version__)')"
echo "========================================"

# Patch briaai/RMBG-2.0 birefnet.py for PyTorch nightly compatibility
# (meta tensors cannot be materialized in PyTorch >= 2.10, replace torch.linspace with numpy)
find "${HF_HOME:-/workspace/cache/huggingface}" -path "*/RMBG*2*/birefnet.py" -exec \
  sed -i 's/\[x\.item() for x in torch\.linspace(0, drop_path_rate, sum(depths))\]/[float(x) for x in __import__("numpy").linspace(0, drop_path_rate, sum(depths))]/g' {} + 2>/dev/null || true
find "${HF_HOME:-/workspace/cache/huggingface}" -path "*/RMBG*2*/birefnet.py" -exec \
  sed -i 's/torch\.linspace(0, drop_path_rate, sum(depths))\.tolist()/[float(x) for x in __import__("numpy").linspace(0, drop_path_rate, sum(depths))]/g' {} + 2>/dev/null || true

# Launch
if [ $# -eq 0 ]; then
  exec python app.py
else
  exec "$@"
fi
