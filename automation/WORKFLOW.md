# Content Automation Workflow (Blog Posts + Cover Images)

This document is the “source of truth” workflow for publishing new Coursework Ninja content so that future runs (human or Claude Code) are consistent.

## Inputs

- Topic queue: `automation/content-plan.json`
  - Each item has: `type`, `slug`, `title`, keywords, `status`, `internalLinks`, etc.
- Site templates (reference only):
  - Blog template conventions: `automation/blog-template-reference.md`
  - Landing template conventions: `templates/landing-page.html`

## Output Files (Blog)

For a blog item with slug `<slug>`:

- Page: `blog/<slug>/index.html`
- Cover image: `images/blog/<slug>-cover.webp`
- Blog index: `blog/index.html`
- Sitemap: `sitemap.xml`
- Homepage “Recent Blog Posts” section: `index.html` (`#blog`) **must show ONLY 3 posts**
- Content plan bookkeeping: `automation/content-plan.json` (mark published)

## Site-Wide Pages

- Contact hub page: `contact/index.html` (WhatsApp + Telegram + `help@coursework.ninja`)
  - Must be linked in the header on every page (desktop + mobile nav)

## Required Page Elements (Blog)

Each blog post must include:

- `<title>` ending with `| Coursework Ninja`
- Meta description ~150–160 chars
- Canonical URL: `https://coursework.ninja/blog/<slug>/`
- OpenGraph + Twitter card tags
- JSON-LD:
  - `Article`
  - `BreadcrumbList`
  - `FAQPage` if FAQ section exists
- Consistent header + mobile menu + footer (copy from existing posts)
- Featured image:
  - `src="/images/blog/<slug>-cover.webp"`
  - 16:9 (1200×630-ish)
- Internal links (minimum 3):
  - `/` (home)
  - `/blog/`
  - `/contact/`
  - plus relevant related posts
- Visible bullets/numbering:
  - Global CSS resets `ul { list-style: none; }`, but blog articles are overridden in `css/styles.css` (see the `.blog-article ul/ol` rules) so list markers are visible site-wide.
  - Still ensure blog content uses the `.blog-article` wrapper (and keep the embedded bullet styles if you’re copying from an existing post template).
- CTA card consistency:
  - Use the same `.blog-cta` structure and button format as existing posts (WhatsApp + Telegram).

## Cover Image Generation (OpenRouter “Nano Banana”)

### Model + Endpoint

- Endpoint: `https://openrouter.ai/api/v1/chat/completions`
- Model: `google/gemini-3-pro-image-preview`
- Auth: `OPENROUTER_API_KEY` stored in `.env` (never commit)

### Prompt Template (brand style)

Use a short 2–4 word title overlay (NOT the full article title).

```
Generate a 16:9 banner image for a blog post.
Background: photorealistic [SCENE DESCRIPTION].
Apply a duotone overlay transitioning from navy blue (#0B1630) on the left to gold (#F4A826) on the right.
Add white bold text "[SHORT TITLE]" prominently centered.
Professional corporate style, clean and modern. No additional text or elements.
```

### Save + Convert

1. Extract base64 image data URL from OpenRouter response JSON:
   - `.choices[0].message.images[0].image_url.url`
2. Decode to PNG (temporary file under `/tmp`)
3. Convert to WebP:
   - `cwebp -q 85 /tmp/<slug>.png -o images/blog/<slug>-cover.webp`
4. Delete temporary files after the image is saved.

## Publishing Checklist (Every Post)

1. Pick the next `pending` blog item from `automation/content-plan.json`
2. Create `blog/<slug>/index.html` using existing blog post structure + styles
3. Generate `images/blog/<slug>-cover.webp` with OpenRouter (Nano Banana Pro)
4. Run `node scripts/sync-site.mjs`:
   - updates nav links (adds Contact everywhere)
   - updates `blog/index.html` cards
   - updates `index.html` homepage blog section (ONLY latest 3 posts)
   - updates `sitemap.xml`
5. Sanity-check the generated changes
6. Update `automation/content-plan.json`:
   - set `status` → `published`
   - set `publishedDate` (YYYY-MM-DD)
   - bump `meta.publishedCount`
   - set `meta.lastUpdated`
7. `git add -A`
8. Commit with a clear message, then `git push origin main`

## Safety Rules

- Never commit API keys or secrets:
  - `.env` stays local (gitignored)
  - never paste keys into docs
- If a key is ever committed or pasted publicly:
  - rotate it immediately
  - purge from git history (history rewrite) before continuing
