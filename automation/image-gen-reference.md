# OpenRouter Image Generation API Reference

## Model
`google/gemini-2.5-flash-image-preview`

## Endpoint
`https://openrouter.ai/api/v1/chat/completions`

## Required Headers
- `Authorization: Bearer {API_KEY}`
- `Content-Type: application/json`

## Request Format
```json
{
  "model": "google/gemini-3-pro-image-preview",
  "messages": [{"role": "user", "content": "Your image prompt here"}],
  "modalities": ["image", "text"],
  "image_config": {
    "aspect_ratio": "16:9"
  }
}
```

## Response Format
Images returned as base64-encoded data URLs:
```json
{
  "choices": [{
    "message": {
      "role": "assistant",
      "content": "...",
      "images": [{
        "image_url": {"url": "data:image/png;base64,iVBORw0KGg..."}
      }]
    }
  }]
}
```

## Aspect Ratios (Gemini)
Supported: 1:1, 3:4, 4:3, 9:16, 16:9, 21:9

## Image Style for Blog Posts (REQUIRED STYLE)
All featured images MUST follow this format:
1. **Background Image**: Relevant photo/image related to the topic
2. **Duotone Overlay**: Blue and gold translucent overlay on top of the background image
3. **Text**: White bold text with the title placed on top of the overlay
4. **Aspect Ratio**: 16:9 banner style
5. **Quality**: Professional, premium corporate aesthetic

Example prompt format:
"Generate a 16:9 banner image with [relevant background photo]. Apply a duotone overlay with navy blue (#0B1630) and gold (#F4A826) translucent colors over the image. Add white bold text '[TITLE]' prominently centered on top. Professional corporate style."
