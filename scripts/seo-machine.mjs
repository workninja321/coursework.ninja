/**
 * SEO Machine - Automated Page Generator for Coursework Ninja
 *
 * This script:
 * 1. Reads content tasks from a Google Sheet
 * 2. Writes tasks to automation/tasks.json
 * 3. Runs Claude Code headlessly to generate pages
 * 4. Commits and pushes changes to GitHub
 * 5. Updates the sheet with PUBLISHED/ERROR status
 *
 * Usage: npm run seo:run
 *
 * Required env vars:
 * - SEO_SHEET_ID: Google Sheet ID
 * - SEO_SHEET_NAME: Sheet tab name (default: "Queue")
 * - GOOGLE_APPLICATION_CREDENTIALS: Path to service account JSON
 * - CLAUDE_MODEL: Model to use (default: "opus")
 * - CLAUDE_MAX_TURNS: Max turns for Claude (default: "10")
 */

import fs from "fs";
import path from "path";
import { spawnSync } from "child_process";
import { google } from "googleapis";

// ============ Utility Functions ============

function die(msg) {
  console.error(`[seo-machine] ERROR: ${msg}`);
  process.exit(1);
}

function log(msg) {
  console.log(`[seo-machine] ${msg}`);
}

function sh(cmd, args, opts = {}) {
  const r = spawnSync(cmd, args, { encoding: "utf8", ...opts });
  if (r.status !== 0) {
    console.error(r.stdout || "");
    console.error(r.stderr || "");
    die(`Command failed: ${cmd} ${args.join(" ")}`);
  }
  return r.stdout.trim();
}

function isoTodayLocal() {
  const d = new Date();
  const yyyy = d.getFullYear();
  const mm = String(d.getMonth() + 1).padStart(2, "0");
  const dd = String(d.getDate()).padStart(2, "0");
  return `${yyyy}-${mm}-${dd}`;
}

function colLetter(n) {
  // Convert 1-based column number to letter (1 => A, 27 => AA)
  let s = "";
  while (n > 0) {
    const m = (n - 1) % 26;
    s = String.fromCharCode(65 + m) + s;
    n = Math.floor((n - 1) / 26);
  }
  return s;
}

// ============ Configuration ============

const SHEET_ID = process.env.SEO_SHEET_ID;
const SHEET_NAME = process.env.SEO_SHEET_NAME || "Queue";
const KEY_FILE =
  process.env.GOOGLE_APPLICATION_CREDENTIALS ||
  path.join(process.cwd(), "automation/secrets/service-account.json");

// Validation
if (!SHEET_ID) {
  die("Missing env: SEO_SHEET_ID\nSet it to your Google Sheet ID.");
}

if (!fs.existsSync(KEY_FILE)) {
  die(
    `Missing service account key file: ${KEY_FILE}\n` +
    `Set GOOGLE_APPLICATION_CREDENTIALS or place it at automation/secrets/service-account.json`
  );
}

// Prevent accidental API billing if user intended Max-plan auth
// Claude Code uses API key if ANTHROPIC_API_KEY is set
if (process.env.ANTHROPIC_API_KEY) {
  die(
    "ANTHROPIC_API_KEY is set.\n" +
    "Unset it if you want Claude Code to use your Max plan auth instead of API billing.\n" +
    "Run: unset ANTHROPIC_API_KEY"
  );
}

const TODAY = isoTodayLocal();
const ROOT = process.cwd();

log(`Starting SEO machine for ${TODAY}`);
log(`Working directory: ${ROOT}`);

// ============ Step 1: Ensure Clean Git Tree ============

log("Checking git status...");
const dirty = sh("git", ["status", "--porcelain"], { cwd: ROOT });
if (dirty) {
  die("Working tree is not clean. Commit or stash your changes first.\n" + dirty);
}

// ============ Step 2: Pull Latest ============

log("Pulling latest changes...");
try {
  sh("git", ["pull", "--rebase"], { cwd: ROOT });
} catch (e) {
  log("Warning: Could not pull (may be no remote or new repo). Continuing...");
}

// ============ Step 3: Read Google Sheet ============

log("Authenticating with Google Sheets...");
const auth = new google.auth.GoogleAuth({
  keyFile: KEY_FILE,
  scopes: ["https://www.googleapis.com/auth/spreadsheets"],
});
const sheets = google.sheets({ version: "v4", auth });

log(`Reading sheet: ${SHEET_NAME}`);
const range = `${SHEET_NAME}!A1:Z`;
const resp = await sheets.spreadsheets.values.get({
  spreadsheetId: SHEET_ID,
  range,
});

const values = resp.data.values || [];
if (values.length < 2) {
  log("Sheet has no data rows. Nothing to process.");
  process.exit(0);
}

// Parse headers and rows
const headers = values[0].map((h) => (h || "").trim().toLowerCase());
const rows = values.slice(1);

function idx(col) {
  const i = headers.findIndex((h) => h === col.toLowerCase());
  if (i === -1) die(`Sheet missing required column: ${col}`);
  return i;
}

function optIdx(col) {
  return headers.findIndex((h) => h === col.toLowerCase());
}

// Required columns
const COL = {
  id: idx("id"),
  type: idx("type"),
  slug: idx("slug"),
  title: idx("title"),
  primary_keyword: idx("primary_keyword"),
  secondary_keywords: idx("secondary_keywords"),
  publish_date: idx("publish_date"),
  status: idx("status"),
  // Optional columns
  tags: optIdx("tags"),
  category: optIdx("category"),
  internal_links: optIdx("internal_links"),
  notes: optIdx("notes"),
};

// Build task objects
const tasks = rows
  .map((r, i) => {
    const rowNumber = i + 2; // Header is row 1
    const get = (k) => (r[k] ?? "").toString().trim();
    return {
      rowNumber,
      id: get(COL.id),
      type: get(COL.type),
      slug: get(COL.slug),
      title: get(COL.title),
      primary_keyword: get(COL.primary_keyword),
      secondary_keywords: get(COL.secondary_keywords),
      publish_date: get(COL.publish_date),
      status: get(COL.status).toUpperCase(),
      tags: COL.tags === -1 ? "" : get(COL.tags),
      category: COL.category === -1 ? "" : get(COL.category),
      internal_links: COL.internal_links === -1 ? "" : get(COL.internal_links),
      notes: COL.notes === -1 ? "" : get(COL.notes),
    };
  })
  .filter(
    (t) =>
      t.status === "READY" &&
      t.publish_date &&
      t.publish_date <= TODAY &&
      t.slug &&
      t.type
  );

if (tasks.length === 0) {
  log(`No READY tasks due by ${TODAY}. Exiting.`);
  process.exit(0);
}

log(`Found ${tasks.length} task(s) to process:`);
tasks.forEach((t) => log(`  - [${t.type}] ${t.slug}: ${t.title}`));

// ============ Step 4: Write Tasks File ============

const taskFile = path.join(ROOT, "automation", "tasks.json");
fs.writeFileSync(taskFile, JSON.stringify({ today: TODAY, tasks }, null, 2));
log(`Wrote tasks to ${taskFile}`);

// ============ Step 5: Build Claude Prompt ============

const prompt = `
You are working in a static website repo for Coursework Ninja.

Read the JSON file: automation/tasks.json

For each task in the tasks array:

1. Create the page at the correct path:
   - If type is "blog" => create blog/<slug>/index.html
   - If type is "landing" => create landing/<slug>/index.html

2. Use the existing site's HTML/CSS/JS patterns from index.html:
   - Copy the header structure (navigation, logo)
   - Copy the footer structure (countries slider, crypto logos, copyright)
   - Use CSS variables defined in css/styles.css
   - Include the same font loading and meta tags

3. Add proper SEO elements:
   - <title>[title] | Coursework Ninja</title>
   - Meta description using primary_keyword naturally
   - Canonical URL
   - OpenGraph tags

4. Write compelling content:
   - Use the title as the H1
   - Incorporate primary_keyword and secondary_keywords naturally
   - Write at least 500 words of helpful, original content
   - Include clear CTAs linking to WhatsApp/Telegram

5. Add internal links:
   - Link to homepage
   - Link to /#contact
   - Link to any pages mentioned in internal_links field
   - If there are tags, mention them

6. After creating all pages, update these files:
   - If blog/index.html exists, add new blog posts to it
   - If blog/index.html doesn't exist and you created blog posts, create it
   - Update or create sitemap.xml with all new URLs

Important rules:
- Do NOT run any Bash commands
- Do NOT delete any existing files
- Do NOT modify index.html except the homepage #blog "Recent Blog Posts" cards (keep exactly 3, and update them when publishing new blog posts)
- Keep the visual design consistent with the existing site

When done, output a summary listing:
- Files created
- Files updated
- Any errors encountered
`.trim();

// ============ Step 6: Run Claude Code Headlessly ============

const claudeArgs = [
  "-p", // Print mode (headless)
  "--model", process.env.CLAUDE_MODEL || "sonnet",
  "--max-turns", process.env.CLAUDE_MAX_TURNS || "15",
  "--permission-mode", "acceptEdits", // Auto-accept file edits
  "--disallowedTools", "Bash,WebFetch,WebSearch", // Safety: no shell, no web
];

log("Running Claude Code...");
log(`  Model: ${process.env.CLAUDE_MODEL || "sonnet"}`);
log(`  Max turns: ${process.env.CLAUDE_MAX_TURNS || "15"}`);

const claudeResult = spawnSync("claude", claudeArgs, {
  cwd: ROOT,
  input: prompt,
  encoding: "utf8",
  maxBuffer: 10 * 1024 * 1024, // 10MB buffer for large outputs
});

if (claudeResult.status !== 0) {
  console.error(claudeResult.stdout || "");
  console.error(claudeResult.stderr || "");
  die("Claude Code run failed.");
}

console.log("\n--- Claude Output ---");
console.log(claudeResult.stdout);
console.log("--- End Claude Output ---\n");

// ============ Step 7: Verify & Commit ============

log("Checking for changes...");
const changes = sh("git", ["status", "--porcelain"], { cwd: ROOT });

if (!changes) {
  log("No files were changed. Nothing to commit.");
  process.exit(0);
}

log("Changes detected:");
console.log(changes);

log("Staging all changes...");
sh("git", ["add", "-A"], { cwd: ROOT });

const commitMsg = `seo: publish ${tasks.length} page(s) - ${TODAY}

Pages generated:
${tasks.map((t) => `- [${t.type}] ${t.slug}`).join("\n")}

🤖 Generated with Claude Code SEO Machine`;

log("Committing...");
try {
  sh("git", ["commit", "-m", commitMsg], { cwd: ROOT });
} catch (e) {
  log("Nothing to commit (perhaps all changes were already staged).");
}

log("Pushing to origin...");
try {
  sh("git", ["push", "origin", "main"], { cwd: ROOT });
} catch (e) {
  log("Warning: Could not push. You may need to push manually.");
}

// ============ Step 8: Update Sheet Status ============

function expectedPath(t) {
  const type = t.type.toLowerCase();
  if (type === "blog") return `blog/${t.slug}/index.html`;
  if (type === "landing") return `landing/${t.slug}/index.html`;
  return null;
}

const statusColIndex = COL.status + 1; // 1-based for sheets API
const statusColLetter = colLetter(statusColIndex);

const updates = [];
for (const t of tasks) {
  const expectedFile = expectedPath(t);
  const fileExists = expectedFile && fs.existsSync(path.join(ROOT, expectedFile));
  const newStatus = fileExists ? "PUBLISHED" : "ERROR";

  updates.push({
    range: `${SHEET_NAME}!${statusColLetter}${t.rowNumber}`,
    values: [[newStatus]],
  });

  log(`Task ${t.id}: ${newStatus} (${expectedFile || "unknown path"})`);
}

log("Updating sheet statuses...");
await sheets.spreadsheets.values.batchUpdate({
  spreadsheetId: SHEET_ID,
  requestBody: {
    valueInputOption: "RAW",
    data: updates,
  },
});

// ============ Done ============

log(`\n✅ SEO Machine complete!`);
log(`   Processed: ${tasks.length} task(s)`);
log(`   Date: ${TODAY}`);
log(`\nGitHub Pages should update automatically within a few minutes.`);
