# Environment Configuration

Dotfiles and configuration for zsh, neovim, tmux, git, and ghostty.

## Quick Install

```bash
git clone <repo-url> ~/.config
cd ~/.config
./install.sh
```

Use `-f` flag to skip prompts:
```bash
./install.sh -f
```

## What Gets Installed

### Symlinks
- `~/.gitconfig` → `~/.config/git/.gitconfig`
- `~/.zshrc` → `~/.config/zsh/.zshrc`

### Auto-bootstrapped (no action needed)
- **Zinit** - cloned automatically on first zsh startup
- **Neovim plugins** - installed via lazy.nvim on first launch
- **Tmux** - reads from `~/.config/tmux/tmux.conf` (XDG compliant)
- **Ghostty** - reads from `~/.config/ghostty/config` (XDG compliant)

### Cloned by installer
- **TPM** (Tmux Plugin Manager) → `~/.tmux/plugins/tpm`

## Dependencies

The install script will offer to install these if missing:

| Tool | Purpose |
|------|---------|
| `git` | Version control |
| `zsh` | Shell |
| `fzf` | Fuzzy finder |
| `zoxide` | Smarter cd |
| `neovim` | Editor |
| `tmux` | Terminal multiplexer |
| JetBrains Mono Nerd Font | Terminal font |

## Post-Install

1. Restart terminal or `source ~/.zshrc`
2. In tmux, press `prefix + I` to install plugins
3. Optionally run `p10k configure` to customize prompt

## Configurations Included

| Tool | Location | Notes |
|------|----------|-------|
| Ghostty | `ghostty/config` | Catppuccin theme, transparency |
| Git | `git/.gitconfig` | Aliases, rebase workflow |
| Neovim | `nvim/` | LazyVim distribution |
| P10k | `p10k/.p10k.zsh` | Powerlevel10k theme |
| Tmux | `tmux/tmux.conf` | TPM, vim-navigator, catppuccin |
| Zsh | `zsh/.zshrc` | Zinit, p10k, completions |
