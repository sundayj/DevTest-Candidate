# Agent Instructions Overview

This document provides an overview of the **[AGENTS.md](../AGENTS.md)** file located in the project root and explains its purpose for developers.

> **Note**: This is part of the [DevTest documentation](README.md). For the actual agent instructions, see **[AGENTS.md](../AGENTS.md)** in the project root.

## What is AGENTS.md?

The **[AGENTS.md](../AGENTS.md)** file in the project root contains comprehensive instructions specifically designed for:

- **Automated systems** (CI/CD pipelines, build servers)
- **AI assistants** and code analysis tools
- **Deployment scripts** and automation tools
- **Testing frameworks** and continuous integration systems

## Why is it in the Root Directory?

The AGENTS.md file is intentionally placed in the project root because:

1. **AI Assistant Convention**: Many AI assistants and automated tools expect to find agent instructions at the root level
2. **Easy Discovery**: Automated systems can quickly locate and parse the instructions without navigating subdirectories
3. **Standard Practice**: It follows emerging conventions for machine-readable project documentation
4. **Immediate Access**: CI/CD systems and deployment tools can access it directly from the repository root

## What Does AGENTS.md Contain?

The root AGENTS.md file provides:

### 🔧 **Technical Setup Instructions**
- Environment configuration steps
- Docker and Docker Compose setup
- DevContainer initialization procedures
- Database and Redis configuration

### 🚀 **Automated Deployment Workflows**
- Complete Docker Compose deployment steps
- DevContainer setup for automated environments
- Database migration and verification commands
- Service health checks and monitoring

### 🧪 **Testing and Validation**
- Automated test execution commands
- Application verification procedures
- Health check endpoints and commands
- Error recovery and troubleshooting steps

### 📋 **CI/CD Integration Examples**
- **GitHub Actions** workflow templates
- **Jenkins Pipeline** configuration examples
- Command-line interface for automated systems
- Best practices for continuous integration

### 🏗️ **Architecture Information**
- Service overview and port mappings
- Application structure and components
- Key features that need testing
- Performance and security considerations

## How Should Developers Use This Information?

### For Human Developers
- **Don't use AGENTS.md directly** - it's designed for automated systems
- **Refer to the [Getting Started Guide](setup/getting-started.md)** for human-friendly setup instructions
- **Use the [DevContainer Guide](development/devcontainer/README.md)** for development environment setup
- **Check the [Docker Compose Guide](development/docker-compose.md)** for manual deployment

### For DevOps and CI/CD Engineers
- **Use AGENTS.md as a reference** for setting up automated pipelines
- **Copy the provided examples** for GitHub Actions or Jenkins
- **Follow the command sequences** for reliable automated deployment
- **Implement the health checks** for monitoring and validation

### For AI Assistants and Tools
- **Parse AGENTS.md** for project structure and setup requirements
- **Use the command examples** for automated project interaction
- **Follow the troubleshooting guides** for error recovery
- **Reference the architecture section** for understanding project components

## Key Differences from Human Documentation

| Aspect | AGENTS.md | Human Documentation |
|--------|-----------|-------------------|
| **Audience** | Automated systems, CI/CD | Human developers |
| **Format** | Command sequences, scripts | Explanatory guides |
| **Focus** | Reliability, automation | Learning, understanding |
| **Examples** | Complete workflows | Step-by-step tutorials |
| **Error Handling** | Automated recovery | Troubleshooting guidance |

## When to Update AGENTS.md

The root AGENTS.md should be updated when:

- **New services** are added to the Docker Compose stack
- **Port configurations** change
- **Environment variables** are modified
- **Testing procedures** are updated
- **CI/CD requirements** change
- **Security configurations** are modified

## Integration with Development Workflow

The AGENTS.md file complements the human documentation by:

1. **Enabling Automation**: Provides machine-readable instructions for CI/CD
2. **Supporting AI Tools**: Allows AI assistants to understand and work with the project
3. **Standardizing Deployment**: Ensures consistent automated deployment procedures
4. **Facilitating Testing**: Provides reliable automated testing workflows

## Related Documentation

- **[AGENTS.md](../AGENTS.md)** - The actual agent instructions (root directory)
- **[Getting Started Guide](setup/getting-started.md)** - Human developer setup
- **[DevContainer Guide](development/devcontainer/README.md)** - Development environment
- **[Docker Compose Guide](development/docker-compose.md)** - Manual deployment
- **[Technical Solutions](technical/unified-database-solution.md)** - Architecture details

## Summary

The **AGENTS.md** file in the project root serves as a crucial bridge between human development and automated systems. While developers should use the comprehensive documentation in the `docs/` directory, the root AGENTS.md ensures that automated tools, CI/CD pipelines, and AI assistants can effectively work with the DevTest project.

This separation allows for:
- **Optimized human experience** through detailed, explanatory documentation
- **Reliable automation** through precise, command-focused instructions
- **Consistent deployment** across different automated environments
- **Future-proof integration** with emerging AI and automation tools
