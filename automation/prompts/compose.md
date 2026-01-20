# Blog Post Composer

You are writing a complete blog post for Coursework Ninja. Follow these instructions exactly.

## Input Variables (provided by caller)
- `SLUG`: {{SLUG}}
- `TITLE`: {{TITLE}}
- `CATEGORY`: {{CATEGORY}}
- `PRIMARY_KEYWORD`: {{PRIMARY_KEYWORD}}
- `SECONDARY_KEYWORDS`: {{SECONDARY_KEYWORDS}}
- `TAGS`: {{TAGS}}
- `INTERNAL_LINKS`: {{INTERNAL_LINKS}}
- `PUBLISH_DATE`: {{PUBLISH_DATE}}
- `RUN_ID`: {{RUN_ID}}
- `WORK_DIR`: {{WORK_DIR}}

## Reference Files (READ FIRST)
1. `automation/blog-template-reference.md` - Template structure
2. `{{REFERENCE_POST}}` - Example post in same category

## Output Location
Write ALL outputs to: `{{WORK_DIR}}/`

Do NOT create `blog/{{SLUG}}/` - that happens after validation.

---

## STEP 1: Research (research.md)

Use web search to gather:
- 5-8 key facts with citations
- 4-6 student insights/pain points
- Current statistics (tuition, requirements, dates)

Limit: 6 sources maximum. Keep summary 600-800 words.

Write to: `{{WORK_DIR}}/research.md`

Format:
```markdown
# Research: {{TITLE}}

## Key Facts
- [Fact 1] (Source)
- [Fact 2] (Source)
...

## Student Insights
- [Insight 1]
- [Insight 2]
...

## Sources
- [Title](URL) - brief note
...
```

---

## STEP 2: Write Blog HTML (post.html)

Using research.md and the reference post, write complete HTML.

Write to: `{{WORK_DIR}}/post.html`

### Required Elements (ALL must be present)

**Head Section:**
- `<title>{{TITLE}} | Coursework Ninja</title>`
- `<meta name="description" content="...">` (150-160 chars)
- `<link rel="canonical" href="https://coursework.ninja/blog/{{SLUG}}/">`
- `<meta property="og:image" content="https://coursework.ninja/images/blog/{{SLUG}}-cover.webp">`
- Article JSON-LD schema
- BreadcrumbList JSON-LD schema
- FAQPage JSON-LD schema (5-7 FAQs)

**Body Structure:**
- `.blog-header` section with breadcrumb, title, meta
- `.blog-featured-image` section with `<img src="/images/blog/{{SLUG}}-cover.webp">`
- `.blog-content` section with `.blog-article` wrapper
- `.blog-sidebar` with table of contents
- `.blog-cta` call-to-action boxes
- `.blog-faq` section with FAQ accordion
- `.cta-banner` section
- Full header (copy from reference)
- Full footer (copy from reference)

**Content Requirements:**
- Minimum 1000 words of article content
- 5-7 FAQ questions with real answers
- 3+ internal links to existing posts
- Proper heading hierarchy (H1 > H2 > H3)
- id attributes on H2s for TOC links

---

## STEP 3: Write Metadata (meta.json)

Write to: `{{WORK_DIR}}/meta.json`

```json
{
  "slug": "{{SLUG}}",
  "title": "{{TITLE}}",
  "category": "{{CATEGORY}}",
  "excerpt": "[150-160 char excerpt]",
  "readTime": [number],
  "featuredAlt": "[descriptive alt text for cover image]",
  "wordCount": [approximate word count],
  "publishDate": "{{PUBLISH_DATE}}"
}
```

---

## STEP 4: Signal Completion (DONE)

Only after ALL files are written successfully:

Write to: `{{WORK_DIR}}/DONE`

Content: `OK`

---

## Constraints

1. Write ONLY to `{{WORK_DIR}}/` - no other locations
2. Do NOT run shell commands
3. Do NOT modify existing files outside work dir
4. Do NOT create blog/{{SLUG}}/ directory
5. Complete ALL 4 steps in order
6. If any step fails, do NOT write DONE

---

## Quality Checklist (self-verify before DONE)

- [ ] research.md exists and has 5+ facts
- [ ] post.html exists and is valid HTML
- [ ] post.html has canonical URL with correct slug
- [ ] post.html has og:image with correct slug
- [ ] post.html has FAQPage JSON-LD with 5+ questions
- [ ] post.html has .blog-article wrapper
- [ ] post.html has .blog-featured-image__img
- [ ] post.html word count >= 1000
- [ ] meta.json exists and is valid JSON
- [ ] All files written to {{WORK_DIR}}/

Only write DONE if ALL checks pass.
