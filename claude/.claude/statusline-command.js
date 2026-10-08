#!/usr/bin/env node
'use strict';

// Claude Code statusline — user-level (Catppuccin Mocha)
//
// Segments (left → right), joined by dim " │ ":
//   [⬆]         — update indicator (only if a bottega update is pending; opt-out via env)
//   ▼ 130K/1M   — context tokens used / window size (colored by token threshold)
//   project…    — git repo name (▸ subpath if inside a subfolder, ⎇ worktree if in a worktree)
//   Model name
//
// Tuning via env:
//   CLAUDE_STATUSLINE_NO_UPDATE — "1" to suppress the update arrow

const fs = require('fs');
const path = require('path');
const os = require('os');
const { execSync } = require('child_process');

// --- Catppuccin Mocha truecolor ---
const GREEN   = '\x1b[38;2;166;227;161m'; // #a6e3a1
const YELLOW  = '\x1b[38;2;249;226;175m'; // #f9e2af
const RED     = '\x1b[38;2;243;139;168m'; // #f38ba8
const BLUE    = '\x1b[38;2;137;180;250m'; // #89b4fa
const MAUVE   = '\x1b[38;2;203;166;247m'; // #cba6f7
const TEAL    = '\x1b[38;2;148;226;213m'; // #94e2d5
const DIM     = '\x1b[38;2;166;173;200m'; // #a6adc8
const RESET   = '\x1b[0m';

const HOME = os.homedir();
const CONTEXT_WARN_TOKENS = 100000;
const CONTEXT_HIGH_TOKENS = 130000;

// --- Stdin reader ---

function readStdin() {
  return new Promise((resolve) => {
    let data = '';
    const timeout = setTimeout(() => resolve(data), 2500);
    process.stdin.setEncoding('utf8');
    process.stdin.on('data', (c) => { data += c; });
    process.stdin.on('end', () => { clearTimeout(timeout); resolve(data); });
    process.stdin.on('error', () => { clearTimeout(timeout); resolve(data); });
  });
}

// --- Segment formatters ---

function formatTokens(n) {
  if (n >= 1000000) return `${+(n / 1000000).toFixed(1)}M`;
  if (n >= 1000) return `${Math.round(n / 1000)}K`;
  return `${n}`;
}

function contextTokensUsed(ctx) {
  const u = ctx.current_usage;
  if (u) return (u.input_tokens || 0) + (u.cache_creation_input_tokens || 0) + (u.cache_read_input_tokens || 0);
  if (ctx.used_percentage == null) return null;
  return Math.round((ctx.used_percentage / 100) * ctx.context_window_size);
}

function formatContext(ctx) {
  if (!ctx || ctx.context_window_size == null) return null;
  const usedTokens = contextTokensUsed(ctx);
  if (usedTokens == null) return null;
  const windowSize = ctx.context_window_size;
  let color, glyph;
  if (usedTokens < CONTEXT_WARN_TOKENS)      { color = GREEN;  glyph = '▼'; }
  else if (usedTokens < CONTEXT_HIGH_TOKENS) { color = YELLOW; glyph = '●'; }
  else                                       { color = RED;    glyph = '▲'; }
  return `${color}${glyph} ${formatTokens(usedTokens)}/${formatTokens(windowSize)}${RESET}`;
}

function safeGit(args, cwd) {
  try {
    return execSync(`git ${args}`, {
      cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'], timeout: 1500,
    }).trim();
  } catch { return null; }
}

function resolveGitPaths(cwd) {
  const gitDir = safeGit('rev-parse --git-dir', cwd);
  if (!gitDir) return null;
  const commonDir = safeGit('rev-parse --git-common-dir', cwd);
  const topLevel = safeGit('rev-parse --show-toplevel', cwd);
  if (!topLevel) return null;

  const absGitDir = path.resolve(cwd, gitDir);
  const absCommonDir = commonDir ? path.resolve(cwd, commonDir) : absGitDir;
  const isWorktree = path.resolve(absGitDir) !== path.resolve(absCommonDir);

  return { gitDir: absGitDir, commonDir: absCommonDir, topLevel, isWorktree };
}

function realpath(p) {
  try { return fs.realpathSync(p); } catch { return p; }
}

function formatProject(cwd) {
  const g = resolveGitPaths(cwd);
  if (!g) {
    if (cwd === HOME) return `${BLUE}~${RESET}`;
    return `${BLUE}${path.basename(cwd)}${RESET}`;
  }

  let repoName, worktreeName = null;
  if (g.isWorktree) {
    // commonDir points to <main-repo>/.git (or .../.bare). Repo name = basename of its parent.
    const mainRepoRoot = path.dirname(g.commonDir);
    repoName = path.basename(mainRepoRoot);
    worktreeName = path.basename(g.topLevel);
  } else {
    repoName = path.basename(g.topLevel);
  }

  let out = `${BLUE}${repoName}${RESET}`;
  if (worktreeName) {
    out += ` ${MAUVE}⎇ ${worktreeName}${RESET}`;
  }

  const rel = path.relative(realpath(g.topLevel), realpath(cwd));
  if (rel && !rel.startsWith('..')) {
    out += ` ${DIM}▸${RESET} ${TEAL}${rel}${RESET}`;
  }

  return out;
}

function formatUpdate() {
  if (process.env.CLAUDE_STATUSLINE_NO_UPDATE === '1') return null;
  const p = path.join(HOME, '.claude', 'cache', 'bottega-update-check.json');
  try {
    const raw = JSON.parse(fs.readFileSync(p, 'utf8'));
    if (raw.update_available) return `${YELLOW}⬆${RESET}`;
  } catch { /* ignore */ }
  return null;
}

// --- Main ---

async function main() {
  const input = await readStdin();
  let data;
  try { data = JSON.parse(input); } catch { data = {}; }

  const cwd = (data.workspace && data.workspace.current_dir) || data.cwd || process.cwd();
  const model = data.model && data.model.display_name;

  const segments = [];

  const ctx = formatContext(data.context_window);
  if (ctx) segments.push(ctx);

  segments.push(formatProject(cwd));

  if (model) segments.push(`${DIM}${model}${RESET}`);

  const sep = ` ${DIM}│${RESET} `;
  let line = segments.join(sep);
  const update = formatUpdate();
  if (update) line = `${update}${DIM}│${RESET} ${line}`;

  process.stdout.write(line);
}

main().catch(() => { /* never break the statusline */ });
