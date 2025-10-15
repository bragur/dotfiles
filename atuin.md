# Atuin - Shell History Management

Atuin replaces your default shell history with a SQLite database, providing advanced search, sync, and statistics.

## Key Benefits

- **Encrypted sync across machines**: Your shell history follows you everywhere
- **Advanced search**: Fuzzy search, regex support, context-aware filtering
- **Never lose history**: SQLite database vs traditional text files that can be truncated
- **Rich context**: Stores command, exit code, duration, working directory, and timestamp
- **Privacy-focused**: End-to-end encrypted sync, local-first design

## Best Use Cases

### 1. Multi-Machine Workflows
Work seamlessly across personal laptop, work machine, and servers. That command you ran last week on your work machine? Available instantly on your laptop.

### 2. Team Knowledge Sharing
Share common command patterns with your team (opt-in). Great for onboarding and discovering "how did Sarah solve that again?"

### 3. Command Archaeology
Find that complex one-liner you ran 6 months ago by searching for any fragment of it - the tool name, a flag, or even the directory you were in.

### 4. Learning from Yourself
Statistics show your most-used commands, helping identify automation opportunities and understand your own workflows.

## Hidden Gems

### Filter by Context
After opening search with `Ctrl+r`:
- **Cycle filter modes**: `Ctrl+r` (cycles: global → host → session → directory → workspace)
- **Cycle search modes**: `Ctrl+s` (cycles: fuzzy → prefix → fulltext → skim)
- Navigate through these modes to filter commands by where/when they were run

### Exit Code Filtering
Search only for failed commands: `atuin search --exit 1`
Perfect for debugging: "What were those npm commands that failed yesterday?"

### Command Statistics
```bash
atuin stats           # Your top 10 most-used commands
atuin stats -c 20     # Top 20 commands
atuin stats today     # What you ran today
atuin stats 1d        # Last 24 hours
atuin stats 1w        # Last week
```

### Import History
```bash
atuin import auto     # Import from zsh/bash/fish history
```
Preserves years of shell history instead of starting fresh.

### Command-Line Search
Search your history from scripts or the command line:
```bash
atuin search <query> --cmd-only          # Show only commands (no metadata)
atuin search <query> --limit 5           # Limit results
atuin search <query> --exit 0            # Only successful commands
atuin search --cwd /path/to/dir git      # Git commands in specific directory
```
Perfect for scripting and automation!

### Prevent Sensitive Commands from Being Saved
Built-in secrets detection prevents AWS keys, GitHub tokens, etc. from being saved.

Manually exclude patterns in config:
```toml
history_filter = [
  "^secret-cmd",
  "password",
]
```

### Offline-First
Sync is optional - works perfectly without an account. Great for air-gapped systems or privacy-conscious users.

## Quick Reference

- `Ctrl+r` - Interactive search (replaces default shell history search)
- `atuin stats` - View command statistics
- `atuin search <query>` - Search from command line
- `atuin sync` - Manually trigger sync
- `atuin account` - Manage sync account

## Configuration

Config location: `~/.config/atuin/config.toml`

Current setup:
- Auto-sync every 30 minutes
- Fuzzy search enabled
- Enter immediately executes command (tab to edit first)
- Sync v2 enabled for better performance
