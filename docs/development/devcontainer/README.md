# DevContainer Development Guide

This section contains comprehensive documentation for using DevContainers with the DevTest project.

## What is a DevContainer?

A DevContainer provides a complete, containerized development environment that includes:
- Pre-configured development tools and extensions
- Consistent Python environment across team members
- Integrated debugging and testing capabilities
- Automatic dependency management
- Database and Redis connections pre-configured

## Quick Start

1. **Install Prerequisites**:
   - Docker Desktop
   - VS Code with Dev Containers extension OR PyCharm Professional

2. **Open Project**:
   - VS Code: "Reopen in Container"
   - PyCharm: "Open in Container"

3. **Start Developing**: Everything is pre-configured and ready to use!

## Documentation

### Setup Guides
- **[VS Code Setup Guide](vscode-guide.md)** - Complete VS Code DevContainer setup and usage
- **[PyCharm Setup Guide](pycharm-guide.md)** - Complete PyCharm DevContainer setup and usage

### Understanding DevContainers
- **[Value Proposition](value-proposition.md)** - Why use DevContainers vs Docker Compose?
- **[Enhanced Features](enhancements.md)** - Advanced DevContainer features and customizations

## Key Features

### 🚀 Zero-Configuration Setup
- Automatic dependency installation with `uv sync`
- Database migrations applied automatically
- Development environment variables pre-configured

### 🛠️ IDE Integration
- **VS Code**: 16+ pre-installed extensions, debugging configurations, tasks
- **PyCharm**: 7+ specialized plugins, database tools, Redis browser

### 🔧 Development Tools
- Integrated debugging with breakpoints
- Database management tools
- Redis inspection and management
- Git integration
- Testing framework integration

### 📊 Port Management
- Automatic port forwarding with labels:
  - **8001**: Django Web Server (with notifications)
  - **5433**: PostgreSQL Database (silent)
  - **6380**: Redis Cache (silent)

## Comparison with Docker Compose

| Feature | Docker Compose | DevContainer |
|---------|----------------|--------------|
| **Service Orchestration** | ✅ Full | ✅ Full (uses docker-compose) |
| **IDE Integration** | ❌ None | ✅ Complete |
| **Extension Management** | ❌ Manual | ✅ Automatic |
| **Development Tools** | ❌ Manual setup | ✅ Pre-configured |
| **Port Forwarding** | ❌ Manual | ✅ Automatic |
| **Debugging** | ❌ Complex setup | ✅ Integrated |

## Common Workflows

### Daily Development
1. Open project in DevContainer
2. Start coding immediately (no setup required)
3. Use integrated debugging and testing
4. Commit changes with integrated Git tools

### Database Operations
- Migrations are applied automatically
- Use IDE database tools for data inspection
- Query console available in both VS Code and PyCharm

### Testing and Debugging
- Set breakpoints directly in IDE
- Run tests with integrated test runners
- Debug Django server, tests, and Celery workers

## Technical Details

### Architecture
The DevContainer uses the same Docker Compose services as the standalone setup:
- **Unified Database**: Same PostgreSQL instance as Docker Compose
- **Shared Data**: Data persists between DevContainer and Docker Compose usage
- **Network Integration**: Can resolve service hostnames ('db', 'redis')

### Configuration Files
- **`.devcontainer/devcontainer.json`** - Main DevContainer configuration
- **`.devcontainer/Dockerfile`** - Container image definition
- **`.devcontainer/.env`** - Environment variables
- **`.vscode/`** - VS Code specific configurations
- **Docker Compose files** - Service definitions

## Troubleshooting

### Common Issues
- **Container build fails**: Ensure Docker Desktop is running
- **Extensions not loading**: Rebuild container or clear cache
- **Database connection issues**: Verify services are running
- **Port conflicts**: Check that required ports are available

### Getting Help
- Check IDE-specific guides for detailed troubleshooting
- Review the [technical solutions](../../technical/) for architecture issues
- See the main [troubleshooting guide](../../README.md#troubleshooting)

## Advanced Usage

For advanced DevContainer customization and enhancements, see:
- **[Enhancement Recommendations](enhancements.md)** - Additional features and optimizations
- **[Technical Architecture](../../technical/)** - Understanding the underlying implementation

## Contributing

When modifying DevContainer configuration:
1. Test changes with both VS Code and PyCharm
2. Update relevant documentation
3. Verify compatibility with Docker Compose workflow
4. Test with fresh container builds
