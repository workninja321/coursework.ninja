/**
 * Sync Site Rollups
 * - Ensures Contact link exists in global nav (desktop + mobile)
 * - Syncs blog index cards + homepage "Recent Blog Posts" (exactly 3)
 * - Syncs sitemap.xml for blog posts + contact page
 *
 * Usage:
 *   node scripts/sync-site.mjs
 */

import fs from "fs";
import path from "path";
import { spawnSync } from "child_process";
import { syncNav } from "./sync-nav.mjs";

const ROOT = process.cwd();

const BLOG_INDEX_START = "          <!-- BLOG_INDEX_CARDS:START -->";
const BLOG_INDEX_END = "          <!-- BLOG_INDEX_CARDS:END -->";
const HOME_START = "          <!-- HOME_BLOG_CARDS:START -->";
const HOME_END = "          <!-- HOME_BLOG_CARDS:END -->";

const CLOCK_SVG = `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>`;

function die(msg) {
  console.error(`[sync-site] ERROR: ${msg}`);
  process.exit(1);
}

function readFile(relPath) {
  return fs.readFileSync(path.join(ROOT, relPath), "utf8");
}

function writeFile(relPath, content) {
  fs.writeFileSync(path.join(ROOT, relPath), content, "utf8");
}

function escapeHtml(str) {
  return (str || "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function extractFirst(html, re) {
  const m = html.match(re);
  return m ? (m[1] || "").trim() : "";
}

function parseDateYMD(ymd) {
  const m = (ymd || "").match(/^(\d{4})-(\d{2})-(\d{2})$/);
  if (!m) return null;
  const yyyy = Number(m[1]);
  const mm = Number(m[2]);
  const dd = Number(m[3]);
  return new Date(Date.UTC(yyyy, mm - 1, dd));
}

function formatDateShort(ymd) {
  const d = parseDateYMD(ymd);
  if (!d) return "";
  return new Intl.DateTimeFormat("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
    timeZone: "UTC",
  }).format(d);
}

function getGitTimestamp(relPath) {
  try {
    const r = spawnSync("git", ["log", "-1", "--format=%ct", "--", relPath], {
      cwd: ROOT,
      encoding: "utf8",
    });
    if (r.status !== 0) return 0;
    const n = Number((r.stdout || "").trim());
    return Number.isFinite(n) ? n : 0;
  } catch {
    return 0;
  }
}

function getGitCreatedTimestamp(relPath) {
  try {
    const r = spawnSync(
      "git",
      ["log", "--diff-filter=A", "--format=%ct", "--", relPath],
      { cwd: ROOT, encoding: "utf8" }
    );
    if (r.status !== 0) return 0;
    const lines = (r.stdout || "")
      .trim()
      .split(/\s+/)
      .map((s) => s.trim())
      .filter(Boolean);
    if (!lines.length) return 0;
    const n = Number(lines[lines.length - 1]);
    return Number.isFinite(n) ? n : 0;
  } catch {
    return 0;
  }
}

function discoverBlogPosts() {
  const blogRoot = path.join(ROOT, "blog");
  if (!fs.existsSync(blogRoot)) return [];

  const dirs = fs
    .readdirSync(blogRoot, { withFileTypes: true })
    .filter((d) => d.isDirectory())
    .map((d) => d.name);

  const posts = [];
  for (const slug of dirs) {
    const relPath = path.join("blog", slug, "index.html");
    const absPath = path.join(ROOT, relPath);
    if (!fs.existsSync(absPath)) continue;

    const stat = fs.statSync(absPath);
    // Git timestamps are unavailable for untracked files, so fall back to filesystem timestamps.
    const fsMtime = Math.floor(stat.mtimeMs / 1000);
    const fsBirthtime = Math.floor((stat.birthtimeMs || stat.mtimeMs) / 1000);

    const html = fs.readFileSync(absPath, "utf8");
    const title =
      extractFirst(html, /<h1[^>]*class="blog-header__title"[^>]*>([\s\S]*?)<\/h1>/m) ||
      extractFirst(html, /<meta\s+property="og:title"\s+content="([^"]+)"\s*>/m) ||
      extractFirst(html, /<title>([\s\S]*?)<\/title>/m).replace(/\s*\|\s*Coursework Ninja\s*$/i, "");

    const description =
      extractFirst(html, /<meta\s+name="description"\s+content="([^"]+)"\s*>/m) ||
      extractFirst(html, /<meta\s+property="og:description"\s+content="([^"]+)"\s*>/m);

    const category =
      extractFirst(html, /<meta\s+property="article:section"\s+content="([^"]+)"\s*>/m) || "Blog";

    const publishedDate =
      extractFirst(html, /<meta\s+property="article:published_time"\s+content="([^"]+)"\s*>/m) || "";

    const modifiedDate =
      extractFirst(html, /<meta\s+property="article:modified_time"\s+content="([^"]+)"\s*>/m) ||
      publishedDate;

    const readTime = extractFirst(html, /(\d+)\s*min read/i) || "";

    const imageAlt =
      extractFirst(
        html,
        new RegExp(`<img\\s+[^>]*src="/images/blog/${slug}-cover\\.webp"[^>]*alt="([^"]*)"`, "m")
      ) ||
      extractFirst(html, /<meta\s+property="og:image:alt"\s+content="([^"]+)"\s*>/m) ||
      `${title} cover image`;

    posts.push({
      slug,
      title,
      description,
      category,
      publishedDate,
      modifiedDate,
      readTime: readTime ? Number(readTime) : null,
      imageAlt,
      gitTimestamp: getGitTimestamp(relPath) || fsMtime,
      createdTimestamp: getGitCreatedTimestamp(relPath) || fsBirthtime,
    });
  }

  posts.sort((a, b) => {
    const ad = a.publishedDate || "";
    const bd = b.publishedDate || "";
    if (ad !== bd) return bd.localeCompare(ad);
    const ac = a.createdTimestamp || 0;
    const bc = b.createdTimestamp || 0;
    if (ac !== bc) return bc - ac;
    return a.slug.localeCompare(b.slug);
  });

  return posts;
}

function clampText(text, maxLen) {
  const t = (text || "").trim().replace(/\s+/g, " ");
  if (t.length <= maxLen) return t;
  const clipped = t.slice(0, maxLen).replace(/\s+\S*$/, "");
  return `${clipped}…`;
}

function buildBlogIndexCards(posts) {
  return posts
    .map((p) => {
      const href = `/blog/${p.slug}/`;
      const dateLabel = formatDateShort(p.publishedDate) || "";
      const readLabel = p.readTime ? `${p.readTime} min read` : "";
      const excerpt = clampText(p.description, 165);
      return [
        `          <article class="blog-card">`,
        `            <a href="${href}" class="blog-card__image-link">`,
        `              <img src="/images/blog/${escapeHtml(p.slug)}-cover.webp" alt="${escapeHtml(p.imageAlt)}" class="blog-card__image" width="600" height="315" loading="lazy">`,
        `            </a>`,
        `            <div class="blog-card__content">`,
        `              <span class="blog-card__category">${escapeHtml(p.category)}</span>`,
        `              <h2 class="blog-card__title"><a href="${href}">${escapeHtml(p.title)}</a></h2>`,
        `              <p class="blog-card__excerpt">${escapeHtml(excerpt)}</p>`,
        `              <div class="blog-card__meta">`,
        `                <span>${escapeHtml(dateLabel)}</span>`,
        `                <span class="blog-card__read-time">`,
        `                  ${CLOCK_SVG}`,
        `                  ${escapeHtml(readLabel)}`,
        `                </span>`,
        `              </div>`,
        `            </div>`,
        `          </article>`,
      ].join("\n");
    })
    .join("\n\n");
}

function buildHomeCards(posts) {
  const top = posts.slice(0, 3);
  return top
    .map((p) => {
      const href = `/blog/${p.slug}/`;
      const readLabel = p.readTime ? `${p.readTime} min read` : "";
      const excerpt = clampText(p.description, 120);
      return [
        `          <article class="blog-section__card">`,
        `            <a href="${href}" class="blog-section__card-image-link">`,
        `              <img src="/images/blog/${escapeHtml(p.slug)}-cover.webp" alt="${escapeHtml(p.imageAlt)}" class="blog-section__card-img" width="600" height="315" loading="lazy">`,
        `            </a>`,
        `            <div class="blog-section__card-content">`,
        `              <span class="blog-section__card-category">${escapeHtml(p.category)}</span>`,
        `              <h3 class="blog-section__card-title">`,
        `                <a href="${href}">${escapeHtml(p.title)}</a>`,
        `              </h3>`,
        `              <p class="blog-section__card-excerpt">${escapeHtml(excerpt)}</p>`,
        `              <div class="blog-section__card-meta">`,
        `                <span>${escapeHtml(readLabel)}</span>`,
        `              </div>`,
        `            </div>`,
        `          </article>`,
      ].join("\n");
    })
    .join("\n\n");
}

function replaceSection(html, startLine, endLine, body) {
  const startIdx = html.indexOf(startLine);
  const endIdx = html.indexOf(endLine);
  if (startIdx === -1) die(`Missing marker: ${startLine.trim()}`);
  if (endIdx === -1) die(`Missing marker: ${endLine.trim()}`);
  if (endIdx < startIdx) die(`Marker order invalid: ${startLine.trim()} -> ${endLine.trim()}`);

  const before = html.slice(0, startIdx + startLine.length);
  const after = html.slice(endIdx);
  return `${before}\n${body}\n${after}`;
}

function isoTodayLocal() {
  const d = new Date();
  const yyyy = d.getFullYear();
  const mm = String(d.getMonth() + 1).padStart(2, "0");
  const dd = String(d.getDate()).padStart(2, "0");
  return `${yyyy}-${mm}-${dd}`;
}

function syncSitemap(posts) {
  const today = isoTodayLocal();

  const urls = [
    {
      loc: "https://coursework.ninja/",
      lastmod: today,
      changefreq: "weekly",
      priority: "1.0",
    },
    {
      loc: "https://coursework.ninja/blog/",
      lastmod: today,
      changefreq: "daily",
      priority: "0.9",
    },
    {
      loc: "https://coursework.ninja/contact/",
      lastmod: today,
      changefreq: "monthly",
      priority: "0.7",
    },
    ...posts.map((p) => ({
      loc: `https://coursework.ninja/blog/${p.slug}/`,
      lastmod: p.modifiedDate || p.publishedDate || today,
      changefreq: "monthly",
      priority: "0.8",
    })),
  ];

  const xml = [
    `<?xml version="1.0" encoding="UTF-8"?>`,
    `<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">`,
    ...urls.map(
      (u) => [
        `  <url>`,
        `    <loc>${u.loc}</loc>`,
        `    <lastmod>${u.lastmod}</lastmod>`,
        `    <changefreq>${u.changefreq}</changefreq>`,
        `    <priority>${u.priority}</priority>`,
        `  </url>`,
      ].join("\n")
    ),
    `</urlset>`,
    ``,
  ].join("\n");

  writeFile("sitemap.xml", xml);
  console.log(`[sync-site] updated: sitemap.xml (${urls.length} urls)`);
}

function main() {
  syncNav({ root: ROOT });

  const posts = discoverBlogPosts();
  if (posts.length === 0) die("No blog posts found under blog/*/index.html");

  // Blog index rollup
  const blogIndexPath = path.join("blog", "index.html");
  if (fs.existsSync(path.join(ROOT, blogIndexPath))) {
    const blogIndex = readFile(blogIndexPath);
    const cards = buildBlogIndexCards(posts);
    const next = replaceSection(blogIndex, BLOG_INDEX_START, BLOG_INDEX_END, cards);
    if (next !== blogIndex) {
      writeFile(blogIndexPath, next);
      console.log(`[sync-site] updated: ${blogIndexPath}`);
    }
  }

  // Homepage "Recent Blog Posts" rollup (top 3)
  const home = readFile("index.html");
  const homeCards = buildHomeCards(posts);
  const nextHome = replaceSection(home, HOME_START, HOME_END, homeCards);
  if (nextHome !== home) {
    writeFile("index.html", nextHome);
    console.log(`[sync-site] updated: index.html (#blog cards)`);
  }

  syncSitemap(posts);

  console.log(`[sync-site] done.`);
}

main();
