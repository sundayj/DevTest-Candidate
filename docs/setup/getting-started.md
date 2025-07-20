# Getting Started with DevTest

This guide will help you set up the DevTest project for development using either DevContainer or Docker Compose.

## 🚀 Quick Setup (Recommended)

**The fastest way to get started is to run the setup script for your platform:**

```bash
# Linux (uses built-in Docker, NOT Docker Desktop)
./scripts/setup.sh

# macOS
./scripts/setup_mac.sh

# Windows
./scripts/setup_windows.ps1
```

> **⚠️ Important for Linux users**: Use the built-in Linux Docker engine (`docker.io` package) instead of Docker Desktop. The setup script will install the correct version for you.

The setup scripts will automatically:
- Install Docker (correct version for your platform)
- Install Docker Compose
- Install Dev Containers CLI
- Install VS Code extension (if VS Code is detected)
- Set up environment file (`.env.example` → `.devcontainer/.env`)

> **💡 Interactive Setup**: The scripts will ask for permission before installing each tool. If you decline automatic installation, they'll provide detailed manual installation instructions with links and alternative methods.

## Prerequisites

- **Git** configured on your system
- **Python 3.12** (if running locally without containers)
- **Docker** (will be installed by setup script if needed)

## Choose Your Development Environment

You have two main options for development:

### Option 1: DevContainer (Recommended)

The DevContainer provides a complete, pre-configured development environment with IDE integration.

**Supported IDEs:**
- **VS Code** with Dev Containers extension
- **PyCharm Professional** with Dev Containers plugin

**Benefits:**
- Zero-configuration setup
- Pre-installed extensions and tools
- Integrated debugging
- Consistent environment across team members

**Quick Start:**
1. Install Docker Desktop
2. Install your preferred IDE and DevContainer extension
3. Clone the repository
4. Open in DevContainer (see IDE-specific guides below)

### Option 2: Docker Compose

Use Docker Compose for a more traditional containerized development approach.

**Benefits:**
- Production-like environment
- Full control over services
- Good for testing deployment scenarios

**Quick Start:**
1. Run the setup script for your platform (handles Docker installation and environment setup)
2. Clone the repository
3. Run `docker-compose up -d`

## Initial Setup Steps

### 1. Clone the Repository

```bash
git clone <repository-url>
cd DevTest
```

### 2. Run Setup Script

Run the setup script for your platform (this handles all dependencies and configuration):

```bash
# Linux (uses built-in Docker, NOT Docker Desktop)
./scripts/setup.sh

# macOS
./scripts/setup_mac.sh

# Windows
./scripts/setup_windows.ps1
```

The setup script will automatically handle environment configuration by copying `.env.example` to `.devcontainer/.env`. You can edit `.devcontainer/.env` later if you need to customize any settings.

## Next Steps

### For DevContainer Users

Choose your IDE and follow the specific setup guide:
- **[VS Code DevContainer Setup](../development/devcontainer/vscode-guide.md)**
- **[PyCharm DevContainer Setup](../development/devcontainer/pycharm-guide.md)**

### For Docker Compose Users

Follow the **[Docker Compose Guide](../development/docker-compose.md)** for detailed usage instructions.

## Verification

After setup, verify everything is working:

1. **Database Connection**: Run migrations
   ```bash
   # DevContainer
   python manage.py migrate

   # Docker Compose
   docker-compose exec web python manage.py migrate
   ```

2. **Web Server**: Start the development server
   ```bash
   # DevContainer
   python manage.py runserver 0.0.0.0:8001

   # Docker Compose (automatic with override file)
   docker-compose up -d
   ```

3. **Access Application**: Visit http://localhost:8001

## Troubleshooting

### Common Issues

- **Port conflicts**: Ensure ports 8001, 5433, and 6380 are available
- **Docker not running**: Start Docker Desktop before proceeding
- **Permission issues**: Ensure your user has Docker permissions

### Getting Help

- Check the **[troubleshooting section](../README.md#troubleshooting)** in the main README
- Review IDE-specific guides for detailed setup instructions
- Check the **[technical solutions](../technical/)** for architecture-specific issues

## What's Next?

Once you have the basic setup working:

1. **Explore the Application**: The demo includes a library catalog with books, authors, and reviews
2. **Learn the Development Workflow**: See the DevContainer or Docker Compose guides
3. **Understand the Architecture**: Review the technical documentation
4. **Start Developing**: Create your first feature or fix

## Quick Reference

### Essential Commands

```bash
# Start development environment
docker-compose up -d                    # Docker Compose
# OR open in DevContainer via IDE

# Database operations
python manage.py migrate               # Apply migrations
python manage.py createsuperuser      # Create admin user
python manage.py shell               # Django shell

# Testing
uv run pytest                        # Run tests

# Stop services
docker-compose down                   # Docker Compose
```

### Important Files

- **`.devcontainer/`** - DevContainer configuration
- **`docker-compose.yml`** - Main service definitions
- **`docker-compose.override.yml`** - Development overrides
- **`.devcontainer/.env`** - Environment variables
- **`manage.py`** - Django management commands

For more detailed information, see the specific guides in the [development section](../development/).
