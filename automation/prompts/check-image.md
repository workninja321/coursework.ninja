# Image Coherence Check

Analyze the cover image for quality and text readability.

## Image Path
`{{IMAGE_PATH}}`

## Expected Text
`{{EXPECTED_TEXT}}`

## Check These Items

1. **Text Readability**: Can you read the text on the image? What does it say?
2. **Text Match**: Does the visible text match or closely match the expected text?
3. **Visual Quality**: Is the image clear, professional, not distorted?
4. **Brand Compliance**: Does it have the navy-blue to gold gradient overlay?

## Output

Write to: `{{WORK_DIR}}/image-check.json`

```json
{
  "readable": true|false,
  "textFound": "[text you can read on image]",
  "textMatch": true|false,
  "quality": "good"|"acceptable"|"poor",
  "brandCompliant": true|false,
  "issues": ["list of issues if any"],
  "pass": true|false
}
```

Set `pass: true` only if:
- Text is readable
- Text roughly matches expected (minor variations OK)
- Quality is good or acceptable
- Image has the brand gradient overlay
