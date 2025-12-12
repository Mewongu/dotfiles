#Requires -Version 5.1
<#
.SYNOPSIS
    Configuration Installation Script for Windows
.DESCRIPTION
    Installs and configures Alacritty terminal emulator with Catppuccin theme
.PARAMETER Force
    Skip confirmation prompts
.EXAMPLE
    .\install.ps1
    .\install.ps1 -Force
#>

param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# Colors for output
function Write-Info { Write-Host "[INFO] " -ForegroundColor Blue -NoNewline; Write-Host $args }
function Write-Success { Write-Host "[OK] " -ForegroundColor Green -NoNewline; Write-Host $args }
function Write-Warn { Write-Host "[WARN] " -ForegroundColor Yellow -NoNewline; Write-Host $args }
function Write-Err { Write-Host "[ERROR] " -ForegroundColor Red -NoNewline; Write-Host $args }

function Confirm-Action {
    param([string]$Message)
    if ($Force) { return $true }
    $response = Read-Host "$Message [y/N]"
    return $response -match '^[yY]'
}

function Test-Command {
    param([string]$Command)
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

# Get script directory (where config files are)
$ConfigDir = $PSScriptRoot

# Windows config paths
$AlacrittyConfigDir = "$env:APPDATA\alacritty"

function Install-Scoop {
    if (-not (Test-Command "scoop")) {
        Write-Info "Installing Scoop package manager..."
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
        Write-Success "Scoop installed"
    } else {
        Write-Success "Scoop already installed"
    }
}

function Install-Package {
    param([string]$Package)

    if (Test-Command $Package) {
        Write-Success "$Package already installed"
        return
    }

    Write-Info "Installing $Package..."
    scoop install $Package
    Write-Success "$Package installed"
}

function Install-Alacritty {
    if (Test-Command "alacritty") {
        Write-Success "Alacritty already installed"
        return
    }

    if (Confirm-Action "Install Alacritty?") {
        if (Test-Command "scoop") {
            scoop bucket add extras
            scoop install alacritty
        } elseif (Test-Command "winget") {
            winget install Alacritty.Alacritty
        } else {
            Write-Err "No package manager found. Install Alacritty manually from https://alacritty.org"
            return
        }
        Write-Success "Alacritty installed"
    }
}

function Install-Neovim {
    if (Test-Command "nvim") {
        Write-Success "Neovim already installed"
        return
    }

    if (Confirm-Action "Install Neovim?") {
        if (Test-Command "scoop") {
            scoop install neovim
        } elseif (Test-Command "winget") {
            winget install Neovim.Neovim
        } else {
            Write-Err "No package manager found. Install Neovim manually from https://neovim.io"
            return
        }
        Write-Success "Neovim installed"
    }
}

function Show-TmuxAlternatives {
    Write-Host ""
    Write-Warn "tmux is not natively available on Windows"
    Write-Info "Alternatives for terminal multiplexing:"
    Write-Host "  1. WSL (Windows Subsystem for Linux) - Full tmux support"
    Write-Host "  2. Windows Terminal tabs/panes - Built-in splitting"
    Write-Host "  3. MSYS2 - pacman -S tmux (limited compatibility)"
    Write-Host ""
}

function Install-Fonts {
    if (-not (Confirm-Action "Install JetBrains Mono Nerd Font?")) { return }

    Write-Info "Installing JetBrains Mono Nerd Font..."

    if (Test-Command "scoop") {
        scoop bucket add nerd-fonts
        scoop install JetBrainsMono-NF
        Write-Success "JetBrains Mono Nerd Font installed"
    } else {
        Write-Warn "Install font manually from: https://github.com/ryanoasis/nerd-fonts/releases"
    }
}

function Deploy-AlacrittyConfig {
    Write-Info "Deploying Alacritty configuration..."

    # Create config directory
    if (-not (Test-Path $AlacrittyConfigDir)) {
        New-Item -ItemType Directory -Path $AlacrittyConfigDir -Force | Out-Null
        Write-Success "Created Alacritty config directory"
    }

    # Create themes directory
    $ThemesDir = "$AlacrittyConfigDir\themes"
    if (-not (Test-Path $ThemesDir)) {
        New-Item -ItemType Directory -Path $ThemesDir -Force | Out-Null
    }

    # Copy theme file
    $ThemeSrc = "$ConfigDir\alacritty\themes\catppuccin-mocha.toml"
    $ThemeDest = "$ThemesDir\catppuccin-mocha.toml"

    if (Test-Path $ThemeSrc) {
        Copy-Item -Path $ThemeSrc -Destination $ThemeDest -Force
        Write-Success "Copied Catppuccin Mocha theme"
    } else {
        Write-Warn "Theme file not found, downloading..."
        $ThemeUrl = "https://raw.githubusercontent.com/catppuccin/alacritty/main/catppuccin-mocha.toml"
        Invoke-WebRequest -Uri $ThemeUrl -OutFile $ThemeDest
        Write-Success "Downloaded Catppuccin Mocha theme"
    }

    # Create main config with Windows-adjusted paths
    $ConfigContent = @"
# Import catppuccin theme
import = ["$($AlacrittyConfigDir -replace '\\', '/')/themes/catppuccin-mocha.toml"]

[font]
size = 16

[font.normal]
family = "JetBrainsMono Nerd Font"

[mouse]
hide_when_typing = true

[window]
decorations = "Full"
opacity = 0.9

[keyboard]
bindings = [
  { key = "Return", mods = "Shift", chars = "\u001b\r" }
]
"@

    $ConfigDest = "$AlacrittyConfigDir\alacritty.toml"

    if (Test-Path $ConfigDest) {
        if (Confirm-Action "Alacritty config exists. Overwrite?") {
            $BackupPath = "$ConfigDest.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
            Move-Item -Path $ConfigDest -Destination $BackupPath
            Write-Info "Backed up existing config to $BackupPath"
        } else {
            Write-Warn "Skipping config deployment"
            return
        }
    }

    $ConfigContent | Out-File -FilePath $ConfigDest -Encoding UTF8
    Write-Success "Deployed Alacritty configuration"
}

function Main {
    Write-Host ""
    Write-Host "======================================"
    Write-Host "  Windows Configuration Installation"
    Write-Host "======================================"
    Write-Host ""

    # Check for package manager
    $hasScoop = Test-Command "scoop"
    $hasWinget = Test-Command "winget"

    if (-not $hasScoop -and -not $hasWinget) {
        Write-Warn "No package manager found"
        if (Confirm-Action "Install Scoop package manager?") {
            Install-Scoop
        }
    } else {
        if ($hasScoop) { Write-Success "Scoop detected" }
        if ($hasWinget) { Write-Success "Winget detected" }
    }

    Write-Host ""

    # Install Alacritty
    Install-Alacritty

    Write-Host ""

    # Install Neovim
    Install-Neovim

    Write-Host ""

    # Show tmux alternatives
    Show-TmuxAlternatives

    # Install fonts
    Install-Fonts

    Write-Host ""

    # Deploy config
    if (Confirm-Action "Deploy Alacritty configuration?") {
        Deploy-AlacrittyConfig
    }

    Write-Host ""
    Write-Host "======================================"
    Write-Host "  Installation Complete!"
    Write-Host "======================================"
    Write-Host ""
    Write-Info "Alacritty config location: $AlacrittyConfigDir"
    Write-Host ""
}

Main
