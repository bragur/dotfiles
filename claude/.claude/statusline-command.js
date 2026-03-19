#!/usr/bin/env node
// Claude Code Statusline — Catppuccin Mocha theme
// Shows: folder | git branch + changes | context bar | model

const { execSync } = require('child_process');
const path = require('path');
const os = require('os');

// Catppuccin Mocha palette (truecolor)
const BLUE = '\x1b[38;2;137;180;250m';    // #89b4fa
const MAUVE = '\x1b[38;2;203;166;247m';   // #cba6f7
const GREEN = '\x1b[38;2;166;227;161m';   // #a6e3a1
const YELLOW = '\x1b[38;2;249;226;175m';  // #f9e2af
const PEACH = '\x1b[38;2;250;179;135m';   // #fab387
const RED = '\x1b[38;2;243;139;168m';     // #f38ba8
const SUBTEXT = '\x1b[38;2;166;173;200m'; // #a6adc8
const RESET = '\x1b[0m';

let input = '';
const stdinTimeout = setTimeout(() => process.exit(0), 3000);
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  clearTimeout(stdinTimeout);
  try {
    const data = JSON.parse(input);
    const model = data.model?.display_name || '';
    const dir = data.workspace?.current_dir || process.cwd();
    const remaining = data.context_window?.remaining_percentage;

    // Folder name (basename, ~ for home)
    const homeDir = os.homedir();
    let folder;
    if (dir === homeDir) {
      folder = '~';
    } else if (dir.startsWith(homeDir + '/')) {
      folder = '~/' + path.basename(dir);
    } else {
      folder = path.basename(dir);
    }

    // Git info
    let gitPart = '';
    try {
      execSync(`git -C "${dir}" rev-parse --git-dir`, { stdio: 'pipe', timeout: 2000 });
      let branch;
      try {
        branch = execSync(`git -C "${dir}" symbolic-ref --short HEAD`, {
          encoding: 'utf8', stdio: 'pipe', timeout: 2000
        }).trim();
      } catch {
        branch = execSync(`git -C "${dir}" rev-parse --short HEAD`, {
          encoding: 'utf8', stdio: 'pipe', timeout: 2000
        }).trim();
      }
      if (branch.length > 25) branch = branch.slice(0, 25) + '…';

      let statusFlags = '';
      try {
        const status = execSync(`git -C "${dir}" status --porcelain`, {
          encoding: 'utf8', stdio: 'pipe', timeout: 2000
        });
        const lines = status.split('\n').filter(Boolean);
        const staged = lines.filter(l => /^[MADRC]/.test(l)).length;
        const unstaged = lines.filter(l => /^.[MADRC?]/.test(l)).length;
        if (staged > 0) statusFlags += ` ~${staged}`;
        if (unstaged > 0) statusFlags += ` !${unstaged}`;
      } catch {}

      gitPart = ` ${MAUVE} ${branch}${statusFlags}${RESET}`;
    } catch {}

    // Context usage (normalized for autocompact buffer)
    // Claude Code reserves ~16.5% for autocompact, so we scale to usable range
    let ctxPart = '';
    if (remaining != null) {
      const AUTO_COMPACT_BUFFER_PCT = 16.5;
      const usableRemaining = Math.max(0,
        ((remaining - AUTO_COMPACT_BUFFER_PCT) / (100 - AUTO_COMPACT_BUFFER_PCT)) * 100
      );
      const used = Math.max(0, Math.min(100, Math.round(100 - usableRemaining)));

      const filled = Math.floor(used / 10);
      const bar = '█'.repeat(filled) + '░'.repeat(10 - filled);

      let color;
      let prefix = '';
      if (used < 50) {
        color = GREEN;
      } else if (used < 65) {
        color = YELLOW;
      } else if (used < 80) {
        color = PEACH;
      } else {
        color = RED;
        prefix = '\x1b[5m💀 ';
      }
      ctxPart = ` ${color}${prefix}${bar} ${used}%${RESET}`;
    }

    // Model
    let modelPart = '';
    if (model) modelPart = ` ${SUBTEXT}${model}${RESET}`;

    process.stdout.write(`${BLUE} ${folder}${RESET}${gitPart}${ctxPart}${modelPart}`);
  } catch {
    // Silent fail — don't break the statusline
  }
});
