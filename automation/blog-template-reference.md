# Blog Post Template Reference

**IMPORTANT**: Always use this template structure when creating new blog posts. Reference the existing posts in `/blog/wgu-oa-exam-tips/` or `/blog/wgu-acceleration-guide/` for working examples.

## Pre-Writing Research Requirements

**CRITICAL**: Before writing ANY blog post, conduct thorough research:

1. **Web Search**: Use WebSearch to find current, accurate information about the topic
   - Search for official sources (university websites, accreditation bodies)
   - Find recent statistics, costs, and program details
   - Look for common questions students ask about the topic

2. **Verify Facts**: All statistics, costs, requirements, and dates MUST be verified
   - Tuition costs change - always search for current year pricing
   - Program requirements may have updated
   - Accreditation status should be confirmed

3. **Competitor Research**: Check what other sites cover on the same topic
   - Identify gaps in existing content you can fill
   - Find unique angles or information others miss
   - Ensure your content is more comprehensive

4. **Student Pain Points**: Research forums, Reddit, and Q&A sites
   - Understand what students actually struggle with
   - Address real concerns in your content
   - Include practical tips based on real student experiences

5. **Documentation**: Keep track of sources for accuracy
   - Note where key statistics come from
   - Be prepared to update content if information changes

## Required Template Structure

### 1. Head Section
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">

  <!-- SEO Meta -->
  <title>[Title] | Coursework Ninja</title>
  <meta name="description" content="[150-160 char description]">
  <meta name="keywords" content="[keyword1], [keyword2], [keyword3]">
  <link rel="canonical" href="https://coursework.ninja/blog/[slug]/">

  <!-- Open Graph -->
  <meta property="og:type" content="article">
  <meta property="og:url" content="https://coursework.ninja/blog/[slug]/">
  <meta property="og:title" content="[Title]">
  <meta property="og:description" content="[Description]">
  <meta property="og:image" content="https://coursework.ninja/images/blog/[slug]-cover.webp">
  <meta property="og:site_name" content="Coursework Ninja">
  <meta property="article:published_time" content="[YYYY-MM-DD]">
  <meta property="article:modified_time" content="[YYYY-MM-DD]">
  <meta property="article:author" content="Coursework Ninja Team">
  <meta property="article:section" content="[Category]">
  <meta property="article:tag" content="[Tag1]">
  <meta property="article:tag" content="[Tag2]">

  <!-- Twitter -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="[Title]">
  <meta name="twitter:description" content="[Short description]">
  <meta name="twitter:image" content="https://coursework.ninja/images/blog/[slug]-cover.webp">

  <meta name="theme-color" content="#0B1630">
  <link rel="icon" type="image/svg+xml" href="/images/favicon.svg">

  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="/css/styles.css">

  <!-- Article Schema (required) -->
  <!-- BreadcrumbList Schema (required) -->
  <!-- FAQPage Schema (if FAQ section exists) -->

  <style>
    /* Include full embedded styles - see existing posts */
  </style>
</head>
```

### 2. Header (EXACT copy from existing posts)
```html
<body>
  <a href="#main-content" class="skip-link">Skip to main content</a>

  <!-- HEADER - Use exact structure from wgu-oa-exam-tips/index.html -->
  <header class="header" id="header">
    <!-- ... full header with nav, WhatsApp CTA, mobile toggle -->
  </header>

  <div class="header__mobile-menu" id="mobile-menu">
    <!-- ... full mobile menu with close button, nav links, CTAs -->
  </div>
```

### 3. Main Content Structure
```html
<main id="main-content">
  <!-- BLOG HEADER with gradient background -->
  <section class="blog-header">
    <div class="container">
      <nav class="blog-header__breadcrumb" aria-label="Breadcrumb">
        <a href="/">Home</a>
        <span>/</span>
        <a href="/blog/">Blog</a>
        <span>/</span>
        <span>[Short Title]</span>
      </nav>
      <h1 class="blog-header__title">[Full Title]</h1>
      <div class="blog-header__meta">
        <span class="blog-header__meta-item">
          <svg><!-- calendar icon --></svg>
          [Month Day, Year]
        </span>
        <span class="blog-header__meta-item">
          <svg><!-- clock icon --></svg>
          [X] min read
        </span>
        <span class="blog-header__meta-item">
          <svg><!-- book icon --></svg>
          [Category]
        </span>
      </div>
    </div>
  </section>

  <!-- FEATURED IMAGE -->
  <section class="blog-featured-image">
    <div class="container">
      <img src="/images/blog/[slug]-cover.webp" alt="[Descriptive alt text]" class="blog-featured-image__img" width="1200" height="630" loading="eager">
    </div>
  </section>

  <!-- BLOG CONTENT with sidebar -->
  <section class="blog-content">
    <div class="container">
      <div class="blog-content__wrapper">
        <article class="blog-article">
          <!-- Article content with h2, h3, p, ul, ol -->

          <!-- In-article CTA box -->
          <div class="blog-cta">
            <h3 class="blog-cta__title">[CTA Title]</h3>
            <p class="blog-cta__text">[CTA Text]</p>
            <div class="blog-cta__buttons">
              <a href="https://wa.me/12512806919?text=[encoded message]" class="btn btn--primary" target="_blank" rel="noopener">
                <svg><!-- WhatsApp icon --></svg>
                [Button Text]
              </a>
              <a href="https://t.me/courseworkninja" class="btn btn--secondary" target="_blank" rel="noopener">Telegram</a>
            </div>
          </div>

          <!-- FAQ Section (if applicable) -->
          <section class="blog-faq">
            <h2 class="blog-faq__title">Frequently Asked Questions</h2>
            <div class="faq__items">
              <!-- FAQ items with accordion functionality -->
            </div>
          </section>

          <!-- Related Resources -->
          <section class="related-resources">
            <!-- Links to related posts -->
          </section>

          <!-- Tags -->
          <div class="blog-tags">
            <a href="/blog/tag/[tag]/" class="blog-tag">[Tag]</a>
          </div>
        </article>

        <!-- SIDEBAR with sticky TOC -->
        <aside class="blog-sidebar">
          <nav class="blog-toc" aria-label="Table of contents">
            <h2 class="blog-toc__title">Table of Contents</h2>
            <ul class="blog-toc__list">
              <li class="blog-toc__item"><a href="#section-id" class="blog-toc__link">[Section Title]</a></li>
            </ul>
          </nav>
        </aside>
      </div>
    </div>
  </section>

  <!-- CTA BANNER -->
  <section class="cta-banner">
    <div class="cta-banner__pattern"></div>
    <div class="cta-banner__glow"></div>
    <div class="container">
      <div class="cta-banner__content">
        <h2 class="cta-banner__title">Ready to Graduate Faster?</h2>
        <p class="cta-banner__tagline">No forms. No waiting. <span>Just results.</span></p>
        <div class="cta-banner__buttons">
          <!-- WhatsApp and Telegram buttons -->
        </div>
      </div>
    </div>
  </section>
</main>
```

### 4. Footer (EXACT copy from existing posts)
```html
<!-- FOOTER with countries slider and crypto logos -->
<footer class="footer">
  <!-- Use exact structure from wgu-oa-exam-tips/index.html -->
</footer>

<script src="/js/main.js" defer></script>
</body>
</html>
```

## Required Embedded CSS Styles
Copy the full `<style>` block from `/blog/wgu-oa-exam-tips/index.html` including:
- `.blog-featured-image` styles
- `.blog-header` and related styles
- `.blog-content` and wrapper grid styles
- `.blog-article` typography styles
- `.blog-toc` sidebar styles
- `.blog-cta` call-to-action styles
- `.blog-tags` styles
- `.blog-faq` accordion styles
- `.tip-box` and `.warning-box` styles

## Key Layout Features
1. **Two-column layout on desktop** (article + sidebar)
2. **Sticky table of contents** in sidebar
3. **Gradient header** with breadcrumb and meta info
4. **Full footer** with countries slider and crypto logos
5. **CTA banner** at bottom of content

## Cover Image Style (FIXED - DO NOT CHANGE)

**IMPORTANT**: All blog cover images MUST follow this premium style. This is the established brand style.

### Required Style Elements:
1. **Photorealistic Background**: High-quality photorealistic image relevant to the topic (education, technology, healthcare, etc.)
2. **Blue and Gold Overlay**: Translucent overlay using navy blue (#0B1630) and gold (#F4A826) colors creating depth and brand consistency
3. **White Bold Text**: Short, punchy title text (2-4 words max) prominently displayed on top of the overlay
4. **Premium/Corporate Feel**: Clean, professional, sophisticated look
5. **Aspect Ratio**: 1200x630px (OG image standard, approximately 1.9:1)
6. **Format**: WebP (convert from source using cwebp -q 85)

### Visual Reference:
- Photorealistic background image (e.g., student studying, laptop with books, professional setting)
- Navy blue and gold translucent overlay creating depth
- Bold white sans-serif text (Inter Bold or similar) on top
- Professional, corporate aesthetic

### Image Generation Method (REQUIRED)

**ALWAYS use OpenRouter API with google/gemini-3-pro-image-preview model:**

```bash
curl -s "https://openrouter.ai/api/v1/chat/completions" \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "google/gemini-3-pro-image-preview",
    "messages": [{"role": "user", "content": "Generate an image: Premium blog cover image, 1200x630px. Photorealistic background of [SCENE DESCRIPTION]. Navy blue and gold translucent overlay effect. Bold white text [SHORT TITLE] centered prominently. Corporate premium style, sophisticated and professional."}]
  }'
```

**DO NOT use Pollinations AI or other free image generators.**

### Image Generation Prompt Template:
```
"Premium blog cover image, 1200x630px. Photorealistic background of [SCENE DESCRIPTION relevant to topic]. Navy blue (#0B1630) and gold (#F4A826) translucent overlay effect creating depth. Bold white text '[SHORT TITLE]' centered prominently on top. Corporate premium style, sophisticated and professional."
```

### Examples of Short Titles:
- "WGU CAPSTONE" (not the full article title)
- "NURSING GUIDE"
- "IT CERTS"
- "MBA GUIDE"
- "STUDY TIPS"

### Scene Description Examples by Topic:
- IT Certifications: "a professional workspace with laptop, certifications, and tech equipment"
- Nursing: "a healthcare professional in a modern medical setting"
- Business/MBA: "a corporate boardroom or professional business setting"
- Study Tips: "a student studying with books and laptop in a modern environment"
- Capstone: "graduation caps and academic achievement symbols"

### What NOT to Do:
- Do NOT use plain solid color backgrounds
- Do NOT use busy/cluttered designs without overlay
- Do NOT use the full article title (too long)
- Do NOT skip the blue/gold overlay effect

## SEO Checklist
- [ ] Title tag with " | Coursework Ninja" suffix
- [ ] Meta description 150-160 characters
- [ ] Canonical URL
- [ ] Open Graph tags (og:type, og:url, og:title, og:description, og:image)
- [ ] Twitter card tags
- [ ] Article schema JSON-LD
- [ ] BreadcrumbList schema JSON-LD
- [ ] FAQPage schema JSON-LD (if FAQ section exists)
- [ ] H1 matches title
- [ ] H2s for main sections with id attributes for TOC links
- [ ] Internal links to related posts
- [ ] Alt text on images
- [ ] WebP format for images

## Post-Creation Checklist

**IMPORTANT**: After creating or updating any blog post, complete these steps:

### 1. Update Homepage Blog Section
The homepage (`/index.html`) displays the **3 most recent blog posts** in the `#blog` section. After creating a new post:

1. Open `/index.html`
2. Find the `<section id="blog" class="blog-section">` section
3. Update the `blog-section__grid` to show the 3 most recent posts
4. Each blog card requires:
   - Image link and `<img>` tag pointing to cover image
   - Category badge (`blog-section__card-category`)
   - Title with link (`blog-section__card-title`)
   - Excerpt text (`blog-section__card-excerpt`)
   - Read time meta (`blog-section__card-meta`)

Example blog card structure:
```html
<article class="blog-section__card">
  <a href="/blog/[slug]/" class="blog-section__card-image-link">
    <img src="/images/blog/[slug]-cover.webp" alt="[descriptive alt]" class="blog-section__card-img" width="600" height="315" loading="lazy">
  </a>
  <div class="blog-section__card-content">
    <span class="blog-section__card-category">[Category]</span>
    <h3 class="blog-section__card-title">
      <a href="/blog/[slug]/">[Post Title]</a>
    </h3>
    <p class="blog-section__card-excerpt">[Brief excerpt]</p>
    <div class="blog-section__card-meta">
      <span>[X] min read</span>
    </div>
  </div>
</article>
```

### 2. Update Blog Index
Add the new post to `/blog/index.html` listing page.

### 3. Update Sitemap
Add the new URL to `/sitemap.xml`.

### 4. Internal Linking
- Add links TO the new post from 2-3 related existing posts
- Ensure the new post links to related existing content

### 5. Commit All Changes
Commit the blog post, homepage update, and any other modified files together.
