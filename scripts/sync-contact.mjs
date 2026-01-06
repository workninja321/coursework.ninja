/**
 * Sync Contact Links
 * - Applies contact values from site-config.json across HTML/MD files
 *
 * Usage:
 *   node scripts/sync-contact.mjs
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const ROOT = process.cwd();

function die(msg) {
  console.error(`[sync-contact] ERROR: ${msg}`);
  process.exit(1);
}

function readJson(filePath) {
  try {
    return JSON.parse(fs.readFileSync(filePath, "utf8"));
  } catch (err) {
    die(`Failed to read JSON: ${filePath} (${err.message})`);
  }
}

function normalizeNumber(value) {
  return String(value || "").replace(/\D/g, "");
}

function listIndexFiles(root, dir) {
  const base = path.join(root, dir);
  if (!fs.existsSync(base)) return [];
  const entries = fs
    .readdirSync(base, { withFileTypes: true })
    .filter((entry) => entry.isDirectory());

  return entries
    .map((entry) => path.join(dir, entry.name, "index.html"))
    .filter((relPath) => fs.existsSync(path.join(root, relPath)));
}

function replaceContactLinks(content, { whatsappUrl, telegramUrl, supportEmail }) {
  let next = content;

  if (whatsappUrl) {
    next = next.replace(/https:\/\/wa\.me\/\d+/g, whatsappUrl);
  }

  if (telegramUrl) {
    next = next.replace(/https:\/\/t\.me\/[A-Za-z0-9_]+/g, telegramUrl);
  }

  if (supportEmail) {
    next = next.replace(/[A-Z0-9._%+-]+@coursework\.ninja/gi, supportEmail);
  }

  return next;
}

export function syncContact({ root = ROOT } = {}) {
  const configPath = path.join(root, "site-config.json");
  if (!fs.existsSync(configPath)) {
    die(`Missing config: ${configPath}`);
  }

  const config = readJson(configPath);
  const contact = config.contact || {};
  const whatsappNumber = normalizeNumber(contact.whatsappNumber);

  if (!whatsappNumber) {
    die("Missing contact.whatsappNumber in site-config.json");
  }

  const replacements = {
    whatsappUrl: `https://wa.me/${whatsappNumber}`,
    telegramUrl: contact.telegramUrl || "https://t.me/courseworkninja",
    supportEmail: contact.supportEmail || "help@coursework.ninja",
  };

  const htmlFiles = [
    "index.html",
    path.join("blog", "index.html"),
    path.join("contact", "index.html"),
    path.join("services", "index.html"),
    path.join("roadmaps", "index.html"),
    path.join("templates", "blog-post.html"),
    path.join("templates", "landing-page.html"),
    ...listIndexFiles(root, "blog"),
    ...listIndexFiles(root, "services"),
    ...listIndexFiles(root, "roadmaps"),
  ].filter((relPath) => fs.existsSync(path.join(root, relPath)));

  const mdFiles = [
    "CLAUDE.md",
    "CONTENT.md",
    path.join("automation", "blog-template-reference.md"),
  ].filter((relPath) => fs.existsSync(path.join(root, relPath)));

  const allFiles = [...htmlFiles, ...mdFiles];
  let changed = 0;

  allFiles.forEach((relPath) => {
    const absPath = path.join(root, relPath);
    const before = fs.readFileSync(absPath, "utf8");
    const after = replaceContactLinks(before, replacements);

    if (after !== before) {
      fs.writeFileSync(absPath, after, "utf8");
      changed += 1;
      console.log(`[sync-contact] updated: ${relPath}`);
    }
  });

  console.log(`[sync-contact] done. files changed: ${changed}/${allFiles.length}`);
}

function main() {
  syncContact({ root: ROOT });
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main();
}
