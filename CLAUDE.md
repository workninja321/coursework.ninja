# Project: Coursework Ninja - Static SEO Site Automation

## Site Overview
Academic support service landing page for WGU students. Single-page marketing site with potential for blog/landing page expansion.

## Goal
Generate new static pages (blog posts + landing pages) from automation/tasks.json.
Keep design consistent with existing HTML/CSS/JS. Reuse existing components and styles from index.html.

## Current Site Structure
```
coursework-ninja/
├── index.html              # Main landing page
├── CONTENT.md              # Editable content reference
├── css/
│   └── styles.css          # All styles (CSS custom properties defined)
├── js/
│   └── main.js             # Carousels, mobile menu, FAQ accordion
└── images/
    ├── logo-icon.png       # Site logo
    ├── favicon.svg
    └── ...
```

## Output Paths for New Content
- Blog posts: `blog/<slug>/index.html`
- Landing pages: `landing/<slug>/index.html`
- Blog index: `blog/index.html`
- Tag/category pages: `tags/<tag>/index.html`
- Sitemap: `sitemap.xml`

## Design System Reference
Use these CSS custom properties from styles.css:

### Colors
- `--color-navy: #0B1630` (primary dark)
- `--color-gold: #F4A826` (accent)
- `--color-gold-light: #FBC34A`
- `--color-teal: #0F766E` (secondary accent)
- `--color-white: #FFFFFF`
- `--color-offwhite: #F7F7FB`
- `--color-slate: #64748B` (body text)

### Typography
- Font: Inter (already loaded via Google Fonts)
- `--font-bold: 700`
- `--font-semibold: 600`
- `--font-medium: 500`

### Spacing
- Use `--space-*` variables (4, 5, 6, 8, 10, 12, 16, 20, 24, 32)

### Border Radius
- `--radius-lg`, `--radius-xl`, `--radius-2xl`, `--radius-full`

## Hard Rules
1. Do NOT change overall branding/colors/typography unless explicitly required
2. Do NOT delete existing pages or modify index.html structure
3. Keep URLs stable - use lowercase kebab-case slugs
4. Every new page must include:
   - `<title>` with format: "Page Title | Coursework Ninja"
   - Meta description (150-160 chars)
   - Canonical URL
   - OpenGraph tags (og:title, og:description, og:url, og:image)
   - Clear H1 + structured headings (H2, H3)
   - At least 3 internal links

## Internal Linking Strategy
Every new page should link to:
1. Homepage (`/` or `index.html`)
2. Blog index (`/blog/`)
3. At least one relevant existing page or tag page
4. Contact section (`/#contact`)

Hub pages (blog index, tag pages) aggregate content - this prevents rewriting old posts.

## Page Template Structure
New pages should follow this HTML structure:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>[Page Title] | Coursework Ninja</title>
  <meta name="description" content="[150-160 char description]">
  <link rel="canonical" href="https://courseworkninja.com/[path]/">

  <!-- Open Graph -->
  <meta property="og:type" content="article">
  <meta property="og:url" content="https://courseworkninja.com/[path]/">
  <meta property="og:title" content="[Page Title] | Coursework Ninja">
  <meta property="og:description" content="[Description]">
  <meta property="og:image" content="https://courseworkninja.com/images/og-image.jpg">

  <meta name="theme-color" content="#0B1630">
  <link rel="icon" type="image/svg+xml" href="/images/favicon.svg">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="/css/styles.css">
</head>
<body>
  <!-- Include consistent header -->
  <!-- Page content -->
  <!-- Include consistent footer -->
  <script src="/js/main.js" defer></script>
</body>
</html>
```

## Files to Update When Adding Content
When creating new blog posts:
1. Create `blog/<slug>/index.html`
2. Update `blog/index.html` (add post to listing)
3. Update `sitemap.xml` (add new URL)
4. Update relevant `tags/<tag>/index.html` if applicable

## CTA Buttons
Use WhatsApp/Telegram links consistently:
- WhatsApp: `https://wa.me/1234567890`
- Telegram: `https://t.me/courseworkninja`

## Safety
- Do NOT run Bash commands
- Only edit/create files
- The automation script handles git operations and validation

## Content Tone
- Professional but approachable
- Focus on student success and outcomes
- Emphasize: human experts, no AI, privacy, guarantees
- Target audience: busy working adults pursuing WGU degrees
