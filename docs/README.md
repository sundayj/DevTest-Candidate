# DevTest Documentation

This directory contains comprehensive documentation for the DevTest project, organized by topic and use case.

## 🌐 Serve Documentation Locally

For the best reading experience, you can serve this documentation locally with a beautiful web interface:

### Quick Start
```bash
# Linux/macOS
./scripts/serve-docs.sh

# Windows
scripts\serve-docs.bat

# Or directly with Python
python scripts/serve_docs.py
```

The documentation will be available at **http://localhost:3000** with features like:
- 🔍 **Full-text search** across all documentation
- 📱 **Responsive design** for mobile and desktop
- 🎨 **Syntax highlighting** for code blocks
- 📋 **Copy code** buttons for easy copying
- 🔗 **Cross-references** between documents
- 🖼️ **Image zoom** functionality

### Options
```bash
# Serve on a different port
python scripts/serve_docs.py --port 8080

# Don't open browser automatically
python scripts/serve_docs.py --no-browser
```

### IDE Integration

For even easier access, you can use the built-in VS Code task:

#### VS Code
1. Open the Command Palette (`Ctrl+Shift+P` / `Cmd+Shift+P`)
2. Type "Tasks: Run Task"
3. Select "Serve Documentation"

The VS Code task will automatically start the documentation server and open your browser.

## Quick Start

- **[Project Overview](../README.md)** - Main project documentation and setup instructions
- **[Getting Started Guide](setup/getting-started.md)** - Step-by-step setup for new developers
- **[Running the Project](setup/running-project.md)** - DevContainer, Docker Compose, and Codespaces usage

## Documentation Structure

### 📚 Setup & Installation
- **[Getting Started](setup/getting-started.md)** - Complete setup guide for new developers
- **[Running the Project](setup/running-project.md)** - How to start the app for development

### 🛠️ Development
- **[DevContainer Guide](development/devcontainer/README.md)** - Complete DevContainer documentation
  - [PyCharm Setup](development/devcontainer/pycharm-guide.md)
  - [Value Proposition](development/devcontainer/value-proposition.md)
  - [Enhancements](development/devcontainer/enhancements.md)
- **[Docker Compose Guide](development/docker-compose.md)** - Docker Compose usage and override files

### 🔧 Technical Solutions
- **[Unified Database Solution](technical/unified-database-solution.md)** - How DevContainer and Docker-Compose share the same database

### 🤖 Automation
- **[Agent Instructions](AGENTS.md)** - Overview of automation instructions for CI/CD and AI systems

## Contributing to Documentation

When adding new documentation:
1. Place files in the appropriate category directory
2. Update the relevant README.md files
3. Add cross-references where helpful
4. Follow the existing documentation style

## Documentation Standards

- Use clear, descriptive headings
- Include code examples where appropriate
- Add cross-references to related documentation
- Keep content up-to-date with code changes
