#!/bin/bash
# WAN2.2 Remix I2V Model Download Script
# This script downloads all required models for the WAN2.2 Remix NSFW I2V workflow

set -e

echo "Starting WAN2.2 Remix I2V model downloads..."

# Create directories
mkdir -p /workspace/ComfyUI/models/diffusion_models
mkdir -p /workspace/ComfyUI/models/text_encoders
mkdir -p /workspace/ComfyUI/models/vae
mkdir -p /workspace/ComfyUI/models/loras

# Function to download file with progress
download_model() {
    local url=$1
    local output_path=$2
    local model_name=$(basename "$output_path")
    
    if [ -f "$output_path" ]; then
        echo "✓ $model_name already exists, skipping..."
        return 0
    fi
    
    echo "Downloading $model_name..."
    wget -q --show-progress -O "$output_path" "$url" || {
        echo "✗ Failed to download $model_name"
        rm -f "$output_path"
        return 1
    }
    echo "✓ $model_name downloaded successfully"
}

# Download diffusion models (required)
echo ""
echo "==> Downloading diffusion models..."
download_model \
    "https://huggingface.co/wanmodel/WAN2.2-Remix-I2V-NSFW/resolve/main/Wan2.2_Remix_NSFW_i2v_14b_high_lighting_v2.0.safetensors" \
    "/workspace/ComfyUI/models/diffusion_models/Wan2.2_Remix_NSFW_i2v_14b_high_lighting_v2.0.safetensors"

download_model \
    "https://huggingface.co/wanmodel/WAN2.2-Remix-I2V-NSFW/resolve/main/Wan2.2_Remix_NSFW_i2v_14b_low_lighting_v2.0.safetensors" \
    "/workspace/ComfyUI/models/diffusion_models/Wan2.2_Remix_NSFW_i2v_14b_low_lighting_v2.0.safetensors"

# Download text encoder (required)
echo ""
echo "==> Downloading text encoder..."
download_model \
    "https://huggingface.co/wanmodel/WAN2.2-Remix-I2V-NSFW/resolve/main/nsfw_wan_umt5-xxl_fp8_scaled.safetensors" \
    "/workspace/ComfyUI/models/text_encoders/nsfw_wan_umt5-xxl_fp8_scaled.safetensors"

# Download VAE (required)
echo ""
echo "==> Downloading VAE..."
download_model \
    "https://huggingface.co/wanmodel/WAN2.1-I2V/resolve/main/wan_2.1_vae.safetensors" \
    "/workspace/ComfyUI/models/vae/wan_2.1_vae.safetensors"

# Download Lightning LoRAs (optional but recommended for faster generation)
echo ""
echo "==> Downloading Lightning LoRAs (optional)..."
download_model \
    "https://huggingface.co/wanmodel/WAN2.2-Remix-I2V-NSFW/resolve/main/Wan2.2-Lightning_I2V-A14B-4steps-lora_HIGH_fp16.safetensors" \
    "/workspace/ComfyUI/models/loras/Wan2.2-Lightning_I2V-A14B-4steps-lora_HIGH_fp16.safetensors" || echo "⚠ Lightning HIGH LoRA download failed (optional)"

download_model \
    "https://huggingface.co/wanmodel/WAN2.2-Remix-I2V-NSFW/resolve/main/Wan2.2-Lightning_I2V-A14B-4steps-lora_LOW_fp16.safetensors" \
    "/workspace/ComfyUI/models/loras/Wan2.2-Lightning_I2V-A14B-4steps-lora_LOW_fp16.safetensors" || echo "⚠ Lightning LOW LoRA download failed (optional)"

echo ""
echo "==> Model download complete!"
echo ""
echo "Directory structure:"
echo "├── diffusion_models/"
echo "│   ├── Wan2.2_Remix_NSFW_i2v_14b_high_lighting_v2.0.safetensors"
echo "│   └── Wan2.2_Remix_NSFW_i2v_14b_low_lighting_v2.0.safetensors"
echo "├── text_encoders/"
echo "│   └── nsfw_wan_umt5-xxl_fp8_scaled.safetensors"
echo "├── vae/"
echo "│   └── wan_2.1_vae.safetensors"
echo "└── loras/"
echo "    ├── Wan2.2-Lightning_I2V-A14B-4steps-lora_HIGH_fp16.safetensors"
echo "    └── Wan2.2-Lightning_I2V-A14B-4steps-lora_LOW_fp16.safetensors"
echo ""
echo "✓ All required models are ready!"
