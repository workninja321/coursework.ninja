/**
 * Sync Navigation
 * - Ensures the site-wide "Contact" link exists in both desktop + mobile navs.
 *
 * Usage:
 *   node scripts/sync-nav.mjs
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const ROOT = process.cwd();

function listHtmlFiles(root) {
  const candidates = [
    "index.html",
    path.join("blog", "index.html"),
    path.join("contact", "index.html"),
    path.join("roadmaps", "index.html"),
    path.join("templates", "blog-post.html"),
    path.join("templates", "landing-page.html"),
  ];

  const blogDirs = fs.existsSync(path.join(root, "blog"))
    ? fs
        .readdirSync(path.join(root, "blog"), { withFileTypes: true })
        .filter((d) => d.isDirectory())
        .map((d) => path.join("blog", d.name, "index.html"))
    : [];

  const roadmapDirs = fs.existsSync(path.join(root, "roadmaps"))
    ? fs
        .readdirSync(path.join(root, "roadmaps"), { withFileTypes: true })
        .filter((d) => d.isDirectory())
        .map((d) => path.join("roadmaps", d.name, "index.html"))
    : [];

  return [...candidates, ...blogDirs, ...roadmapDirs].filter((p) => fs.existsSync(path.join(root, p)));
}

function ensureRoadmapsLinkInMenu(html) {
  const menuRe = /<ul class="header__menu">([\s\S]*?)<\/ul>/m;
  const match = html.match(menuRe);
  if (!match) return html;
  if (match[0].includes('href="/roadmaps/"')) return html;

  const blogItemRe = /<li><a href="\/blog\/" class="header__link(?:\s+active)?">Blog<\/a><\/li>/;
  const injection = '\n          <li><a href="/roadmaps/" class="header__link">Roadmaps</a></li>';
  if (!blogItemRe.test(match[0])) return html;

  const replaced = match[0].replace(blogItemRe, (m) => `${m}${injection}`);
  return html.replace(match[0], replaced);
}

function ensureContactLinkInMenu(html) {
  const menuRe = /<ul class="header__menu">([\s\S]*?)<\/ul>/m;
  const match = html.match(menuRe);
  if (!match) return html;
  if (match[0].includes('href="/contact/"')) return html;

  const injection = `\n          <li><a href="/contact/" class="header__link">Contact</a></li>`;
  const replaced = match[0].replace("</ul>", `${injection}\n        </ul>`);
  return html.replace(match[0], replaced);
}

function ensureRoadmapsLinkInMobileMenu(html) {
  const menuRe = /<ul class="header__mobile-menu-list">([\s\S]*?)<\/ul>/m;
  const match = html.match(menuRe);
  if (!match) return html;
  if (match[0].includes('href="/roadmaps/"')) return html;

  const blogItemRe = /<li><a href="\/blog\/" class="header__mobile-link">Blog<\/a><\/li>/;
  const injection = '\n        <li><a href="/roadmaps/" class="header__mobile-link">Roadmaps</a></li>';
  if (!blogItemRe.test(match[0])) return html;

  const replaced = match[0].replace(blogItemRe, (m) => `${m}${injection}`);
  return html.replace(match[0], replaced);
}

function ensureContactLinkInMobileMenu(html) {
  const menuRe = /<ul class="header__mobile-menu-list">([\s\S]*?)<\/ul>/m;
  const match = html.match(menuRe);
  if (!match) return html;
  if (match[0].includes('href="/contact/"')) return html;

  const injection = `\n        <li><a href="/contact/" class="header__mobile-link">Contact</a></li>`;
  const replaced = match[0].replace("</ul>", `${injection}\n      </ul>`);
  return html.replace(match[0], replaced);
}

export function syncNav({ root = ROOT } = {}) {
  const files = listHtmlFiles(root).filter((p) => fs.existsSync(path.join(root, p)));
  let changedCount = 0;

  files.forEach((relPath) => {
    const absPath = path.join(root, relPath);
    const before = fs.readFileSync(absPath, "utf8");
    let after = before;

    after = ensureRoadmapsLinkInMenu(after);
    after = ensureContactLinkInMenu(after);
    after = ensureRoadmapsLinkInMobileMenu(after);
    after = ensureContactLinkInMobileMenu(after);

    if (after !== before) {
      fs.writeFileSync(absPath, after, "utf8");
      changedCount += 1;
      console.log(`[sync-nav] updated: ${relPath}`);
    }
  });

  console.log(`[sync-nav] done. files changed: ${changedCount}/${files.length}`);
}

function main() {
  syncNav({ root: ROOT });
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main();
}
