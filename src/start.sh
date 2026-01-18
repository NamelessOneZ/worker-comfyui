#!/usr/bin/env bash

# Use libtcmalloc for better memory management
TCMALLOC="$(ldconfig -p | grep -Po "libtcmalloc.so.\d" | head -n 1)"
export LD_PRELOAD="${TCMALLOC}"

# Ensure ComfyUI-Manager runs in offline network mode inside the container
comfy-manager-set-mode offline || echo "worker-comfyui - Could not set ComfyUI-Manager network_mode" >&2

echo "worker-comfyui: Checking for network volume models..."

# Check for models in different possible mount locations
if [ -d "/runpod-volume/ComfyUI/models" ]; then
    echo "worker-comfyui: Found models at /runpod-volume/ComfyUI/models"
    MODELS_PATH="/runpod-volume/ComfyUI/models"
elif [ -d "/workspace/ComfyUI/models" ]; then
    echo "worker-comfyui: Found models at /workspace/ComfyUI/models"
    MODELS_PATH="/workspace/ComfyUI/models"
    # Create symlink for compatibility
    ln -sf /workspace/ComfyUI /runpod-volume/ComfyUI 2>/dev/null || true
else
    echo "worker-comfyui: WARNING - No network volume models found!"
    echo "worker-comfyui: Expected models at /runpod-volume/ComfyUI/models or /workspace/ComfyUI/models"
fi

# List available models for debugging
if [ -n "$MODELS_PATH" ]; then
    echo "worker-comfyui: Available diffusion models:"
    ls -la "$MODELS_PATH/diffusion_models/" 2>/dev/null || echo "  (none)"
    echo "worker-comfyui: Available text encoders:"
    ls -la "$MODELS_PATH/text_encoders/" 2>/dev/null || echo "  (none)"
    echo "worker-comfyui: Available VAE:"
    ls -la "$MODELS_PATH/vae/" 2>/dev/null || echo "  (none)"
fi

echo "worker-comfyui: Starting ComfyUI"

# Allow operators to tweak verbosity; default is DEBUG.
: "${COMFY_LOG_LEVEL:=DEBUG}"

# Serve the API and don't shutdown the container
if [ "$SERVE_API_LOCALLY" == "true" ]; then
    python -u /comfyui/main.py --disable-auto-launch --disable-metadata --listen --verbose "${COMFY_LOG_LEVEL}" --log-stdout &

    echo "worker-comfyui: Starting RunPod Handler"
    python -u /handler.py --rp_serve_api --rp_api_host=0.0.0.0
else
    python -u /comfyui/main.py --disable-auto-launch --disable-metadata --verbose "${COMFY_LOG_LEVEL}" --log-stdout &

    echo "worker-comfyui: Starting RunPod Handler"
    python -u /handler.py
fi