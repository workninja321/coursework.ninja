# Daily Blog Autopilot Instructions

You are running in **AUTOPILOT MODE**. Execute the following workflow autonomously without asking questions.

## Configuration
- **Posts per run**: 1 (ONE only)
- **Project path**: /Users/mx/Documents/WGU/Claude/coursework-ninja
- **Content plan**: /automation/content-plan.json
- **Blog template reference**: /automation/blog-template-reference.md
- **Image generation reference**: /automation/image-gen-reference.md
- **Telegram notifications**: /automation/telegram-notify.sh

---

## WORKFLOW

### Step 1: Select ONE Blog Post
1. Read `/automation/content-plan.json`
2. Filter items where `type: "blog"` AND `status: "pending"`
3. Sort by `priority` (1 = highest)
4. Select the FIRST (top 1) pending blog post
5. Send Telegram notification:
   ```bash
   /automation/telegram-notify.sh selected "[slug]" "[title]" "[priority]"
   ```

**CRITICAL: Only process ONE blog post per session. Only process `type: "blog"`. Never process `type: "landing"`.**

If no pending blog posts exist:
```bash
touch /automation/logs/NO_PENDING_POSTS
```
Then exit immediately.

---

### Step 2: Research Phase

Before writing, gather current information about the topic.

Send notification:
```bash
/automation/telegram-notify.sh researching "[slug]"
```

#### 2A. Web Research (REQUIRED)
Use web search to find:
- Current WGU program details (tuition, course counts, requirements)
- Recent Reddit r/WGU discussions about this topic (tips, common issues)
- Any recent changes to WGU policies or programs
- Statistics and data points to include

#### 2B. Research Queries by Topic Type

| Topic Type | Research Queries |
|------------|------------------|
| **Degree Guide** | "[program name] WGU 2025", "WGU [program] reddit tips", "[program] courses WGU" |
| **Course Guide** | "WGU [course code] reddit", "[course code] study guide", "[course code] pass tips" |
| **Certification** | "[cert name] WGU tips", "[cert] exam 2025 changes", "[cert] study resources" |
| **Comparison** | "WGU vs [competitor] reddit 2025", "[competitor] tuition 2025", "[competitor] reviews" |
| **Study Tips** | "WGU acceleration tips reddit", "WGU [topic] strategies" |

#### 2C. Compile Research Notes
Create a mental summary of:
- 3-5 key facts/statistics to include
- Common student pain points to address
- Recent tips from successful students
- Any outdated information to avoid

---

### Step 3: Generate Blog Post HTML

Send notification:
```bash
/automation/telegram-notify.sh writing "[slug]"
```

1. Read `/automation/blog-template-reference.md` for exact HTML structure
2. Read a similar existing blog post for reference patterns
3. Create directory: `/blog/[slug]/`
4. Write `/blog/[slug]/index.html` with:
   - Full SEO meta tags (title, description, keywords)
   - Open Graph tags for social sharing
   - Twitter card meta tags
   - Article schema JSON-LD
   - BreadcrumbList schema JSON-LD
   - FAQPage schema JSON-LD (5-7 real FAQs)
   - Complete HTML structure matching existing posts
   - **Research-backed content** (2500-4000 words)
   - Internal links to related published posts
   - Current statistics and data from research
   - CTA sections

---

### Step 4: Generate Cover Image

Send notification:
```bash
/automation/telegram-notify.sh image "[slug]"
```

1. Load environment: `source /Users/mx/Documents/WGU/Claude/coursework-ninja/.env`
2. Determine:
   - Short title (2-4 words max)
   - Scene description relevant to topic
3. Generate image via OpenRouter API:

```bash
source /Users/mx/Documents/WGU/Claude/coursework-ninja/.env

SLUG="[the-post-slug]"
SHORT_TITLE="[2-4 WORD TITLE]"
SCENE="[photorealistic scene description]"

PROMPT="Generate a 16:9 banner image for a blog post. Background: photorealistic ${SCENE}. Apply a duotone overlay transitioning from navy blue (#0B1630) on the left to gold (#F4A826) on the right. Add white bold text \"${SHORT_TITLE}\" prominently centered. Professional corporate style, clean and modern. No additional text or elements."

RESPONSE=$(curl -s "https://openrouter.ai/api/v1/chat/completions" \
  -H "Authorization: Bearer ${OPENROUTER_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"google/gemini-3-pro-image-preview\",
    \"messages\": [{\"role\": \"user\", \"content\": \"${PROMPT}\"}],
    \"modalities\": [\"image\", \"text\"],
    \"image_config\": {\"aspect_ratio\": \"16:9\"}
  }")

echo "$RESPONSE" | jq -r '.choices[0].message.images[0].image_url.url' | sed 's/data:image\/png;base64,//' | base64 -d > /tmp/${SLUG}.png

cwebp -q 85 /tmp/${SLUG}.png -o /Users/mx/Documents/WGU/Claude/coursework-ninja/images/blog/${SLUG}-cover.webp
```

4. Verify image exists: `ls -la images/blog/${SLUG}-cover.webp`

---

### Step 5: Update Blog Index

1. Read `/blog/index.html`
2. Find the blog grid container
3. Add ONE new blog card at the TOP (after grid opening tag)
4. Follow exact card HTML structure from existing cards

---

### Step 6: Update Content Plan

1. Update the post entry in content-plan.json:
   - `"status": "published"`
   - `"publishedDate": "YYYY-MM-DD"` (today's date)
2. Update meta section:
   - Increment `publishedBlogs` by 1
   - Decrement `pendingBlogs` by 1
   - Update `lastUpdated` to today's date

---

### Step 7: Git Commit and Push

Send notification:
```bash
/automation/telegram-notify.sh pushing
```

```bash
cd /Users/mx/Documents/WGU/Claude/coursework-ninja
git add -A
git commit -m "Add blog: [slug]

[Full title of the post]

- Research-backed content
- Cover image generated
- Automated publish"
git push origin main
```

If git push fails:
```bash
echo "[slug]" > /automation/logs/GIT_PUSH_FAILED
/automation/telegram-notify.sh git_failed "[slug]"
```
Then exit immediately.

---

### Step 8: Signal Success

After successful push, create a success marker:
```bash
echo "[slug]" > /Users/mx/Documents/WGU/Claude/coursework-ninja/automation/logs/LAST_SUCCESS
date >> /Users/mx/Documents/WGU/Claude/coursework-ninja/automation/logs/LAST_SUCCESS
```

This signals the launcher to start a fresh session for the next post.

---

## ERROR HANDLING

| Error | Action |
|-------|--------|
| No pending posts | Create `logs/NO_PENDING_POSTS`, exit cleanly |
| Image generation fails | Log error, skip image, continue with post |
| Git push fails | Log error to `logs/GIT_PUSH_FAILED`, do NOT retry |
| content-plan.json malformed | Log error, STOP immediately |
| Web research fails | Continue with existing knowledge |

---

## QUALITY CHECKLIST (verify before git commit)

- [ ] HTML is valid (no unclosed tags)
- [ ] All internal links point to existing published posts
- [ ] Cover image exists at `/images/blog/[slug]-cover.webp`
- [ ] Schema JSON is valid (Article, Breadcrumb, FAQ)
- [ ] Blog index has new card at top
- [ ] content-plan.json updated (status + date + counts)
- [ ] Content includes researched facts/statistics
- [ ] Word count is 2500-4000 words

---

## DO NOT

- Process more than ONE blog post
- Process landing pages (`type: "landing"`)
- Create a `/landing/` directory
- Ask for confirmation or permission
- Stop to report progress mid-workflow
- Skip the research phase
- Create posts not in content-plan.json
- Modify already-published posts
- Push to any branch other than main
- Continue if git push fails

---

## START

Begin by reading `/automation/content-plan.json` and selecting the single highest-priority pending blog post.
