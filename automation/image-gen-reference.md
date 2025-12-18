# OpenRouter Image Generation API Reference

## Available Models
| Model ID | Nickname | Notes |
|----------|----------|-------|
| `google/gemini-3-pro-image-preview` | **Nano Banana Pro** | Best quality, recommended |
| `google/gemini-2.5-flash-image` | Nano Banana | Faster, good quality |
| `google/gemini-2.5-flash-image-preview` | Nano Banana Preview | Preview version |

## Current Model (use this)
```
google/gemini-3-pro-image-preview
```

## API Configuration
- **Endpoint**: `https://openrouter.ai/api/v1/chat/completions`
- **API Key**: Stored in `.env` as `OPENROUTER_API_KEY`
- **Model**: Stored in `.env` as `IMAGE_MODEL`

## Required Headers
```
Authorization: Bearer $OPENROUTER_API_KEY
Content-Type: application/json
```

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
Images returned as base64-encoded data URLs in the response:
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

## Supported Aspect Ratios
- `1:1` - Square
- `3:4` - Portrait
- `4:3` - Landscape
- `9:16` - Vertical/Story
- `16:9` - **Blog covers (USE THIS)**
- `21:9` - Ultra-wide

---

## BLOG COVER IMAGE STYLE (MANDATORY)

**All blog featured images MUST follow this exact style:**

### Required Elements
1. **Aspect Ratio**: 16:9 (1200x630 or similar)
2. **Background**: Photorealistic image relevant to the topic
3. **Overlay**: Navy blue (#0B1630) to gold (#F4A826) duotone gradient
4. **Text**: Short title (2-4 words) in white bold sans-serif, centered
5. **Style**: Premium, professional, corporate aesthetic

### What NOT to Do
- NO square aspect ratios (must be 16:9)
- NO numbered lists or bullet points in the image
- NO long titles (use short 2-4 word versions)
- NO dark-only or single-color overlays
- NO busy backgrounds without the duotone overlay

### Prompt Template
```
Generate a 16:9 banner image for a blog post.
Background: photorealistic [SCENE DESCRIPTION].
Apply a duotone overlay transitioning from navy blue (#0B1630) on the left to gold (#F4A826) on the right.
Add white bold text "[SHORT TITLE]" prominently centered.
Professional corporate style, clean and modern. No additional text or elements.
```

### Scene Description Examples
| Topic | Scene Description |
|-------|-------------------|
| Study Tips | student studying at a desk with laptop and books |
| Exams | person taking an exam on computer in quiet room |
| Time Management | desk with planner, clock, and organized workspace |
| Course Planning | calendar and laptop showing course schedule |
| Certifications | professional workspace with certificates on wall |
| Nursing | healthcare professional in modern medical setting |
| IT/Tech | modern tech workspace with multiple monitors |
| MBA/Business | corporate boardroom or executive office |

### Short Title Examples
| Full Article Title | Short Title for Image |
|--------------------|----------------------|
| "Best Free Study Resources for WGU Students" | "STUDY RESOURCES" |
| "WGU Course Order Strategy: Which Classes First" | "COURSE ORDER" |
| "WGU Time Management Tips for Working Adults" | "TIME MANAGEMENT" |
| "How to Pass WGU Objective Assessments" | "OA EXAM TIPS" |

---

## Shell Script for Generation

```bash
#!/bin/bash
# Save as: gen-blog-cover.sh
# Usage: ./gen-blog-cover.sh "SHORT TITLE" "scene description" "output-slug"

TITLE="$1"
SCENE="$2"
SLUG="$3"

PROMPT="Generate a 16:9 banner image for a blog post. Background: photorealistic ${SCENE}. Apply a duotone overlay transitioning from navy blue (#0B1630) on the left to gold (#F4A826) on the right. Add white bold text \"${TITLE}\" prominently centered. Professional corporate style, clean and modern. No additional text or elements."

RESPONSE=$(curl -s "https://openrouter.ai/api/v1/chat/completions" \
  -H "Authorization: Bearer ${OPENROUTER_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"google/gemini-3-pro-image-preview\",
    \"messages\": [{\"role\": \"user\", \"content\": \"${PROMPT}\"}],
    \"modalities\": [\"image\", \"text\"],
    \"image_config\": {\"aspect_ratio\": \"16:9\"}
  }")

# Extract base64 image and save
echo "$RESPONSE" | jq -r '.choices[0].message.images[0].image_url.url' | sed 's/data:image\/png;base64,//' | base64 -d > "/tmp/${SLUG}.png"

# Convert to WebP
cwebp -q 85 "/tmp/${SLUG}.png" -o "images/blog/${SLUG}-cover.webp"

echo "Generated: images/blog/${SLUG}-cover.webp"
```
