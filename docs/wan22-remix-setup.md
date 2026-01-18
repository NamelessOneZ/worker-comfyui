# WAN2.2 Remix I2V - RunPod Serverless Setup

This setup enables you to run the WAN2.2 Remix NSFW Image-to-Video model on RunPod Serverless infrastructure using this ComfyUI Worker.

## Overview

**WAN2.2 Remix** is an advanced AI model for generating high-quality, uncensored video content from images and text prompts. It specializes in:
- Image-to-Video (I2V) generation
- Human dynamics and realistic motion
- Cinematic scene consistency
- NSFW content generation without additional LoRAs

**Tutorial Reference:** [Creating Uncensored Videos with WAN2.2 Remix in ComfyUI](https://www.nextdiffusion.ai/tutorials/creating-uncensored-videos-with-wan22-remix-in-comfyui-i2v)

**RunPod Serverless Docs:** [Deploy ComfyUI with Serverless](https://docs.runpod.io/tutorials/serverless/comfyui)

## System Requirements

- **Recommended GPU:** NVIDIA RTX 4090 (24GB VRAM) or equivalent
- **Minimum VRAM:** 20GB+
- **Storage:** ~30GB for all models
- **RunPod:** Use GPU instances with sufficient VRAM

## Quick Start - Build & Deploy

### 1. Build the Docker Image

```bash
# Build for WAN2.2 Remix (default)
docker buildx bake wan22-i2v-remix

# Or with docker build
docker build -t your-registry/comfyui-wan22:latest --build-arg MODEL_TYPE=wan22-i2v-remix .
```

The Docker build will automatically:
- Install ComfyUI
- Install required custom nodes (ComfyUI-WanVideoWrapper, ComfyUI-Frame-Interpolation, etc.)
- Download all WAN2.2 models (~30GB)
- Install SageAttention for faster inference

### 2. Deploy to RunPod Serverless

1. Push the image to your container registry
2. Create a new Serverless endpoint in RunPod console
3. Configure with 24GB+ VRAM GPU
4. Set the container image URL

### 3. Test Your Endpoint

Send a request with your workflow:

```bash
curl -X POST https://api.runpod.ai/v2/YOUR_ENDPOINT_ID/run \
    -H 'Content-Type: application/json' \
    -H 'Authorization: Bearer YOUR_API_KEY' \
    -d @test_input.json
```

## Files Structure

```
worker-comfyui/
├── Dockerfile                             # Main build file (default: wan22-i2v-remix)
├── docker-bake.hcl                        # Build targets including wan22-i2v-remix
├── handler.py                             # RunPod handler (supports videos)
├── test_input.json                        # WAN2.2 workflow for testing
├── test_resources/
│   ├── workflows/
│   │   └── wan22_i2v_remix.json          # Full ComfyUI workflow file
│   ├── wan22_remix_snapshot.json          # Model download manifest
│   └── wan22_test_input.json              # Alternative input format
└── scripts/
    └── download_wan22_models.sh           # Manual model download script
```

## Required Models (Auto-Downloaded)

### Core Models (Required)

| Model File | Size | Destination | Purpose |
|------------|------|-------------|---------|
| `Wan2.2_Remix_NSFW_i2v_14b_high_lighting_v2.0.safetensors` | ~14GB | `diffusion_models/` | High lighting model |
| `Wan2.2_Remix_NSFW_i2v_14b_low_lighting_v2.0.safetensors` | ~14GB | `diffusion_models/` | Low lighting model |
| `nsfw_wan_umt5-xxl_fp8_scaled.safetensors` | ~4GB | `text_encoders/` | Text encoder |
| `wan_2.1_vae.safetensors` | ~200MB | `vae/` | Video VAE |

### Lightning LoRAs (Optional - Speed Enhancement)

| Model File | Size | Destination | Purpose |
|------------|------|-------------|---------|
| `Wan2.2-Lightning_I2V-A14B-4steps-lora_HIGH_fp16.safetensors` | ~100MB | `loras/` | 4-step generation (high) |
| `Wan2.2-Lightning_I2V-A14B-4steps-lora_LOW_fp16.safetensors` | ~100MB | `loras/` | 4-step generation (low) |

**Note:** Lightning LoRAs speed up generation significantly but may slightly reduce quality.

## Quick Start

### 1. Download Models

Use the provided download script:

```bash
bash scripts/download_wan22_models.sh
```

Or manually download from HuggingFace:
- https://huggingface.co/wanmodel/WAN2.2-Remix-I2V-NSFW
- https://huggingface.co/wanmodel/WAN2.1-I2V

### 2. Install Custom Nodes

Required ComfyUI custom nodes:
- **ComfyUI-WanVideoWrapper** - Main wrapper for WAN models
- **ComfyUI-KJNodes** - Additional utility nodes
- **ComfyUI-Manager** - Node management

```bash
cd /workspace/ComfyUI/custom_nodes
git clone https://github.com/Comfy-Org/ComfyUI-WanVideoWrapper
git clone https://github.com/kijai/ComfyUI-KJNodes
git clone https://github.com/ltdrdata/ComfyUI-Manager
```

### 3. Restore from Snapshot

Use the snapshot to automatically download models:

```bash
bash src/restore_snapshot.sh test_resources/wan22_remix_snapshot.json
```

### 4. Load the Workflow

The workflow is located at:
```
test_resources/workflows/wan22_i2v_remix.json
```

## RunPod Serverless Input Format

### Example Input

The workflow must be in ComfyUI API format (node IDs as keys with `inputs`, `class_type`, `_meta`). See `test_input.json` for a complete example.

```json
{
  "input": {
    "images": [
      {
        "name": "input_image.png",
        "image": "data:image/png;base64,iVBORw0KGgo..."
      }
    ],
    "workflow": {
      "117": {
        "inputs": {
          "filename_prefix": "video/ComfyUI",
          "format": "auto",
          "codec": "h264",
          "video": ["116", 0]
        },
        "class_type": "SaveVideo",
        "_meta": { "title": "SaveVideo" }
      },
      "131": {
        "inputs": {
          "model": "Wan2.2_Remix_NSFW_i2v_14b_high_lighting_v2.0.safetensors",
          "precision": "fp16_fast",
          "attention": "sageattn",
          "compile_args": ["127", 0],
          "block_swap_args": ["128", 0]
        },
        "class_type": "WanVideoModelLoader",
        "_meta": { "title": "Load WAN Video Model (High)" }
      },
      "134": {
        "inputs": {
          "text": "A cinematic shot with smooth motion, high quality",
          "clip": ["133", 0]
        },
        "class_type": "CLIPTextEncode",
        "_meta": { "title": "Positive Prompt" }
      },
      "148": {
        "inputs": {
          "image": "input_image.png",
          "upload": "image"
        },
        "class_type": "LoadImage",
        "_meta": { "title": "Load Image" }
      }
    }
  }
}
```

**Note:** The complete workflow JSON is in `test_input.json`. The above is abbreviated.

### Response Format

Videos are returned in the response:

```json
{
  "videos": [
    {
      "filename": "ComfyUI_00001_.mp4",
      "type": "base64",
      "data": "AAAAIGZ0eXBpc29..."
    }
  ]
}
```

### Input Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `workflow` | string | - | Workflow identifier |
| `images` | array | - | Input image(s) as URL or base64 |
| `prompt` | string | - | Text prompt for video generation |
| `negative_prompt` | string | - | Negative prompt to avoid unwanted elements |
| `lighting_model` | string | `"high"` | `"high"` or `"low"` lighting model |
| `steps` | int | `8` | Number of diffusion steps (4 with LoRA) |
| `split_step` | int | `4` | Split step value (2 with LoRA) |
| `cfg_scale` | float | `4.0` | Classifier-free guidance scale |
| `seed` | int | `-1` | Random seed (-1 for random) |
| `length` | int | `65` | Video length in frames (65 ≈ 4 seconds) |
| `fps` | int | `32` | Frames per second |
| `resolution` | int | `720` | Short side resolution |
| `use_lightning_lora` | bool | `false` | Enable Lightning LoRA for speed |

### Video Length Guide

- 4 seconds = 65 frames
- 5 seconds = 81 frames
- 6 seconds = 97 frames
- 7 seconds = 113 frames
- 8 seconds = 129 frames

### Lightning LoRA Settings

When `use_lightning_lora: true`:
- Set `steps: 4` (instead of 8)
- Set `split_step: 2` (instead of 4)
- Expect 2-3x faster generation
- Slightly reduced output quality

## Workflow Configuration

The workflow includes:

1. **WanVideoModelLoader** - Loads high/low lighting models
2. **CLIPLoader** - Loads text encoder
3. **WanVideoVAELoader** - Loads VAE for encoding/decoding
4. **WanVideoLoraSelect** - Optional Lightning LoRA support
5. **WanVideoSampler** - Main sampling/generation
6. **WanVideoVAEDecode** - Decodes latents to video frames
7. **CreateVideo** - Assembles frames into video
8. **SaveVideo** - Saves final output

### SageAttention (Optional)

For 10-20% speed improvement, enable SageAttention in the `WanVideoModelLoader` nodes:
- Requires SageAttention extension
- Set attention mode to `"sageattn"`

## Model Sources

All models are from HuggingFace:

- **Main Repository:** [wanmodel/WAN2.2-Remix-I2V-NSFW](https://huggingface.co/wanmodel/WAN2.2-Remix-I2V-NSFW)
- **VAE Repository:** [wanmodel/WAN2.1-I2V](https://huggingface.co/wanmodel/WAN2.1-I2V)

## Testing Locally

Test the workflow locally before deploying:

```bash
# Start ComfyUI
cd /workspace/ComfyUI
python main.py

# Load the workflow
# Drag and drop: test_resources/workflows/wan22_i2v_remix.json
```

## Deployment on RunPod

### Environment Variables

```bash
# Optional: Enable verbose websocket debugging
WEBSOCKET_TRACE=true

# Optional: Websocket reconnection settings
WEBSOCKET_RECONNECT_ATTEMPTS=5
WEBSOCKET_RECONNECT_DELAY_S=3

# Optional: Network volume diagnostics
NETWORK_VOLUME_DEBUG=true
```

### Build Docker Image

```bash
docker build -t your-registry/comfyui-wan22-worker:latest .
```

### Deploy to RunPod

1. Push Docker image to registry
2. Create RunPod Serverless endpoint
3. Configure GPU requirements (24GB+ VRAM)
4. Set environment variables
5. Test with example input

## Performance Tips

1. **Use Lightning LoRAs** - 2-3x faster with minimal quality loss
2. **Enable SageAttention** - 10-20% speed boost
3. **Optimize resolution** - Lower resolution = faster generation
4. **Use block swap** - Reduces VRAM usage
5. **Batch processing** - Process multiple requests efficiently

## Troubleshooting

### Out of Memory

- Reduce `resolution` (720 → 512)
- Enable block swap in workflow
- Use lower `length` (fewer frames)
- Enable VRAM offloading

### Slow Generation

- Enable Lightning LoRAs
- Enable SageAttention
- Reduce `steps` to 4-6
- Lower `resolution`

### Model Not Found

- Verify models are in correct directories
- Check model filenames match exactly
- Re-run download script
- Check network volume mount

### Poor Quality Output

- Disable Lightning LoRAs
- Increase `steps` to 10-12
- Increase `cfg_scale` to 5-6
- Use better input images
- Refine prompts

## Important Notes

⚠️ **Content Warning:** This model is designed for NSFW content generation. Use responsibly and ensure compliance with all applicable laws and platform policies.

⚠️ **Hardware Requirements:** This model requires significant VRAM. Ensure your RunPod instance has at least 20GB VRAM.

⚠️ **Generation Time:** Without Lightning LoRAs, generation can take 5-15 minutes depending on settings and hardware.

## Support & Resources

- **Tutorial:** https://www.nextdiffusion.ai/tutorials/creating-uncensored-videos-with-wan22-remix-in-comfyui-i2v
- **ComfyUI:** https://github.com/comfyanonymous/ComfyUI
- **WAN Video Wrapper:** https://github.com/Comfy-Org/ComfyUI-WanVideoWrapper
- **RunPod:** https://www.runpod.io/

## License

Please refer to the individual model licenses on HuggingFace and ensure compliance with all terms of use.
