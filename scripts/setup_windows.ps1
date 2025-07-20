Write-Host "DevTest Windows Setup Script" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan
Write-Host ""

function Ask-Confirm($message) {
    $response = Read-Host "$message [y/N]"
    return $response -match '^[Yy]'
}

function Check-Winget {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "[ERROR] winget not found. Please install App Installer from Microsoft Store." -ForegroundColor Red
        return $false
    } else {
        Write-Host "[OK] winget is available" -ForegroundColor Green
        return $true
    }
}

function Check-Docker {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Host "Docker Docker not found." -ForegroundColor Yellow
        if (Ask-Confirm "Install Docker Desktop using winget?") {
            if (Check-Winget) {
                winget install -e --id Docker.DockerDesktop
                Write-Host "[OK] Docker Desktop installed. Please start Docker Desktop." -ForegroundColor Green
            }
        } else {
            Write-Host "[ERROR] Skipping Docker installation." -ForegroundColor Red
            Write-Host ""
            Write-Host "Info: Manual Docker Installation Instructions:" -ForegroundColor Cyan
            Write-Host "   You can install Docker Desktop manually using one of these methods:" -ForegroundColor White
            Write-Host ""
            Write-Host "   Method 1 - Using winget (recommended):" -ForegroundColor White
            Write-Host "   winget install -e --id Docker.DockerDesktop" -ForegroundColor Gray
            Write-Host ""
            Write-Host "   Method 2 - Download directly from Docker:" -ForegroundColor White
            Write-Host "   Visit: https://docs.docker.com/desktop/install/windows/" -ForegroundColor Blue
            Write-Host "   Download Docker Desktop for Windows installer" -ForegroundColor Gray
            Write-Host ""
            Write-Host "   Method 3 - Using Chocolatey (if you have it):" -ForegroundColor White
            Write-Host "   choco install docker-desktop" -ForegroundColor Gray
            Write-Host ""
            Write-Host "   Doc: After installation, start Docker Desktop from Start Menu" -ForegroundColor Yellow
            Write-Host ""
        }
    } else {
        Write-Host "[OK] Docker is already installed: $(docker --version)" -ForegroundColor Green
    }
}

function Check-Devcontainer {
    if (-not (Get-Command devcontainer -ErrorAction SilentlyContinue)) {
        Write-Host "Package Dev Containers CLI not found." -ForegroundColor Yellow
        if (Ask-Confirm "Install Dev Containers CLI using curl?") {
            if (Get-Command curl -ErrorAction SilentlyContinue) {
                $installScript = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/devcontainers/cli/main/install.sh" -UseBasicParsing
                $installScript.Content | bash
                Write-Host "[OK] Dev Containers CLI installed." -ForegroundColor Green
            } else {
                Write-Host "[ERROR] curl not found. Please install curl first." -ForegroundColor Red
                Write-Host ""
                Write-Host "Info: Install curl first:" -ForegroundColor Cyan
                Write-Host "   curl is available in Windows 10 version 1803+ and Windows 11" -ForegroundColor White
                Write-Host "   If not available, install it via:" -ForegroundColor White
                Write-Host "   winget install curl.curl" -ForegroundColor Gray
                Write-Host ""
            }
        } else {
            Write-Host "[ERROR] Skipping Dev Containers CLI installation." -ForegroundColor Red
            Write-Host ""
            Write-Host "Info: Manual Dev Containers CLI Installation Instructions:" -ForegroundColor Cyan
            Write-Host "   You can install Dev Containers CLI manually using one of these methods:" -ForegroundColor White
            Write-Host ""
            Write-Host "   Method 1 - Using curl (recommended):" -ForegroundColor White
            Write-Host "   curl -fsSL https://raw.githubusercontent.com/devcontainers/cli/main/install.sh | bash" -ForegroundColor Gray
            Write-Host ""
            Write-Host "   Method 2 - Using npm (if you have Node.js):" -ForegroundColor White
            Write-Host "   npm install -g @devcontainers/cli" -ForegroundColor Gray
            Write-Host ""
            Write-Host "   Method 3 - Download from GitHub:" -ForegroundColor White
            Write-Host "   Visit: https://github.com/devcontainers/cli/releases" -ForegroundColor Blue
            Write-Host "   Download the Windows binary for your architecture" -ForegroundColor Gray
            Write-Host ""
            Write-Host "   Doc: Documentation: https://containers.dev/supporting" -ForegroundColor Yellow
            Write-Host ""
        }
    } else {
        Write-Host "[OK] Dev Containers CLI is installed: $(devcontainer --version)" -ForegroundColor Green
    }
}

function Install-VSCodeExtension {
    if (Get-Command code -ErrorAction SilentlyContinue) {
        $extensions = code --list-extensions
        if ($extensions -notmatch 'ms-vscode-remote.remote-containers') {
            Write-Host "Plug VS Code detected without Dev Containers extension." -ForegroundColor Yellow
            if (Ask-Confirm "Install VS Code Dev Containers extension?") {
                code --install-extension ms-vscode-remote.remote-containers
                Write-Host "[OK] VS Code Dev Containers extension installed." -ForegroundColor Green
            } else {
                Write-Host "[ERROR] Skipping VS Code extension installation." -ForegroundColor Red
            }
        } else {
            Write-Host "[OK] VS Code Dev Containers extension is already installed." -ForegroundColor Green
        }
    } else {
        Write-Host "Info:  VS Code not found - skipping extension installation." -ForegroundColor Blue
    }
}

function Setup-Environment {
    $WorkspacePath = Resolve-Path "$PSScriptRoot\.."
    $EnvExample = "$WorkspacePath\.env.example"
    $EnvTarget = "$WorkspacePath\.devcontainer\.env"

    if (!(Test-Path $EnvTarget)) {
        if (Test-Path $EnvExample) {
            Copy-Item $EnvExample $EnvTarget
            Write-Host "[OK] Environment file copied from .env.example to .devcontainer\.env" -ForegroundColor Green
        } else {
            Write-Host "Warning:  Warning: .env.example not found - you may need to create .devcontainer\.env manually" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[OK] Environment file already exists at .devcontainer\.env" -ForegroundColor Green
    }
}

function Main {
    Write-Host "Checking: Checking required tools..." -ForegroundColor Cyan
    Write-Host ""

    Check-Docker
    Check-Devcontainer
    Install-VSCodeExtension
    Setup-Environment

    Write-Host ""
    Write-Host "Hooray! Setup completed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Make sure Docker Desktop is running" -ForegroundColor White
    Write-Host "2. Start development environment:" -ForegroundColor White
    Write-Host "   - DevContainer: devcontainer up --workspace-folder ." -ForegroundColor White
    Write-Host "   - Docker Compose: docker-compose up -d" -ForegroundColor White
    Write-Host "3. Access application at http://localhost:8001" -ForegroundColor White
}

Main
