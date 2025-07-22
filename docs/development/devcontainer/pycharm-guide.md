# DevContainer with PyCharm: Complete Setup and Usage Guide

## Overview

This guide provides comprehensive instructions for using the DevContainer with PyCharm, covering setup, configuration, and daily development workflows. The DevContainer is pre-configured with PyCharm-specific settings, plugins, and optimizations.

> **Note**: This guide is part of the [DevContainer documentation](README.md). For VS Code setup, see the [VS Code guide](vscode-guide.md).

## Prerequisites

- PyCharm Professional (required for DevContainer support)
- Docker Desktop installed and running
- Git configured on your system

## Initial Setup

### 1. Opening the Project in DevContainer

1. **Launch PyCharm Professional**
2. **Open Project**: File → Open → Navigate to the project folder
3. **DevContainer Detection**: PyCharm will automatically detect the `.devcontainer/devcontainer.json` file
4. **Container Setup**: Click "Open in Container" when prompted, or go to Tools → DevContainers → Open in Container
5. **Wait for Setup**: PyCharm will build the container and install dependencies automatically

### 2. What Happens Automatically

When you open the project in the DevContainer, PyCharm automatically:

- ✅ Builds the Docker container with Python 3.12 and all dependencies
- ✅ Installs 7+ specialized plugins (Django, Docker, Redis, YAML, etc.)
- ✅ Configures Python interpreter and Django settings
- ✅ Sets up database connections (PostgreSQL on port 5433)
- ✅ Configures Redis connection (port 6380)
- ✅ Applies development environment variables
- ✅ Runs `uv sync` to install Python dependencies
- ✅ Executes database migrations automatically
- ✅ Sets up port forwarding for all services

## Pre-installed Plugins and Tools

The DevContainer comes with these PyCharm plugins pre-installed:

### Core Development Plugins
- **Django Support** (`com.intellij.python.django`): Full Django framework support
- **Docker** (`Docker`): Container management and integration
- **Redis** (`com.jetbrains.redis`): Redis browser and command execution
- **YAML** (`org.jetbrains.plugins.yaml`): YAML file support and validation
- **reStructuredText** (`org.jetbrains.plugins.rest`): Documentation support

### AI and Testing Plugins
- **ML/LLM Support** (`com.intellij.ml.llm`): AI-powered code assistance
- **JUnit** (`org.jetbrains.junie`): Testing framework integration
- **Docker Gateway** (`org.jetbrains.plugins.docker.gateway`): Advanced Docker features

## Development Workflows

### 1. Running the Django Server

#### Method 1: Using Run Configurations
1. Look for the pre-configured "Django Server" run configuration in the toolbar
2. Click the green play button or press **Shift+F10**
3. The server will start on `http://localhost:8001`

#### Method 2: Creating Custom Run Configuration
1. Go to **Run** → **Edit Configurations**
2. Click **+** → **Django Server**
3. Configure:
   - **Name**: Django Development Server
   - **Host**: 0.0.0.0
   - **Port**: 8001
   - **Environment variables**: DJANGO_DEBUG=True

### 2. Database Management

#### Built-in Database Tools
1. **Open Database Tool Window**: View → Tool Windows → Database
2. **Auto-detected Connection**: PyCharm automatically detects the PostgreSQL connection
3. **Connection Details**:
   - Host: localhost
   - Port: 5433
   - Database: postgres
   - User: postgres
   - Password: postgres

#### Database Operations
- **Browse Tables**: Expand the database connection to see all tables
- **Run Queries**: Right-click connection → New → Query Console
- **View Data**: Double-click any table to browse data
- **Edit Data**: Click the pencil icon to edit table data directly
- **Export Data**: Right-click table → Export Data

### 3. Redis Management

#### Using the Redis Plugin
1. **Open Redis Browser**: View → Tool Windows → Redis
2. **Connect to Redis**:
   - Host: localhost
   - Port: 6380
   - No authentication required
3. **Browse Keys**: Explore Redis keys and values visually
4. **Execute Commands**: Use the Redis console for direct command execution

### 4. Django Management Commands

#### Method 1: Tools Menu
1. Go to **Tools** → **Run manage.py Task**
2. Select from common commands:
   - `migrate` - Apply database migrations
   - `makemigrations` - Create new migrations
   - `createsuperuser` - Create admin user
   - `shell` - Open Django shell
   - `test` - Run tests

#### Method 2: Terminal Integration
1. Open the integrated terminal (**Alt+F12**)
2. Use smart command completion for Django commands
3. Example commands:
   ```bash
   python manage.py migrate
   python manage.py createsuperuser
   python manage.py test
   ```

### 5. Debugging

#### Setting Up Debugging
1. **Set Breakpoints**: Click in the gutter next to line numbers (or **Ctrl+F8**)
2. **Debug Server**: Click the debug button (bug icon) or press **Shift+F9**
3. **Debug Tests**: Right-click any test method → Debug

#### Advanced Debugging Features
- **Variable Inspection**: Hover over variables or use the Variables panel
- **Evaluate Expression**: **Alt+F8** to evaluate code during debugging
- **Debug Console**: Interactive Python console in debug context
- **Call Stack**: Navigate through the execution stack
- **Conditional Breakpoints**: Right-click breakpoint → Add condition
- **Variable Watches**: Monitor specific variables across sessions

#### Debugging Django Templates
- Set breakpoints in Django template files
- Inspect template context variables
- Step through template rendering process

### 6. Testing

#### Running Tests
1. **Individual Tests**: Right-click test method → Run/Debug
2. **Test Classes**: Right-click test class → Run/Debug
3. **All Tests**: Right-click test directory → Run/Debug
4. **With Coverage**: Right-click → Run with Coverage

#### Test Integration Features
- **Test Results**: Visual test runner with pass/fail indicators
- **Test Coverage**: Built-in coverage reporting
- **Test Debugging**: Full debugging support in test code
- **Test Templates**: Generate test boilerplate automatically

### 7. Version Control (Git)

#### Git Integration
- **VCS Menu**: Full Git operations available in VCS menu
- **Commit Tool Window**: **Alt+0** to open commit interface
- **Git Log**: View commit history and branches
- **Diff Viewer**: Compare file changes visually
- **Merge Conflicts**: Built-in merge conflict resolution

#### Git Operations
- **Commit**: **Ctrl+K** for commit dialog
- **Push**: **Ctrl+Shift+K** to push changes
- **Pull**: VCS → Git → Pull
- **Branch Management**: Git → Branches for branch operations

## Advanced Features

### 1. Code Quality Tools

#### Built-in Code Analysis
- **Real-time Inspection**: PyCharm highlights code issues as you type
- **Code Style**: Automatic PEP 8 compliance checking
- **Refactoring**: Advanced refactoring tools (**Ctrl+Alt+Shift+T**)
- **Code Generation**: **Alt+Insert** for code generation

### 2. Django-Specific Features

#### Django Support
- **Model Navigation**: Jump between models, views, and templates
- **URL Resolution**: Navigate from URLs to views
- **Template Language**: Full Django template syntax support
- **Admin Interface**: Integration with Django admin
- **ORM Support**: Query debugging and optimization

### 3. Docker Integration

#### Container Management
- **Docker Tool Window**: View → Tool Windows → Docker
- **Container Logs**: View real-time container logs
- **Exec into Container**: Open shell in running containers
- **Image Management**: Build and manage Docker images

## Troubleshooting

### Common Issues and Solutions

#### 1. Container Build Fails
- **Check Docker**: Ensure Docker Desktop is running
- **Rebuild Container**: Tools → DevContainers → Rebuild Container
- **Clear Cache**: File → Invalidate Caches and Restart

#### 2. Database Connection Issues
- **Check Services**: Ensure docker-compose services are running
- **Refresh Connection**: Database tool window → Refresh
- **Verify Ports**: Confirm port 5433 is not blocked

#### 3. Python Interpreter Issues
- **Reconfigure Interpreter**: File → Settings → Project → Python Interpreter
- **Select Container Interpreter**: Choose the interpreter from the container
- **Rebuild Index**: File → Invalidate Caches → Clear file system cache

#### 4. Plugin Issues
- **Check Plugin Status**: File → Settings → Plugins
- **Reinstall Plugins**: Disable and re-enable problematic plugins
- **Update Plugins**: Check for plugin updates

## Performance Tips

### 1. Optimize PyCharm Performance
- **Increase Memory**: Help → Change Memory Settings (recommend 4GB+)
- **Exclude Directories**: Mark `node_modules`, `.git` as excluded
- **Disable Unused Plugins**: File → Settings → Plugins

### 2. Container Performance
- **Use Docker Desktop**: Better performance than Docker Toolbox
- **Allocate Resources**: Give Docker adequate CPU and memory
- **Volume Optimization**: Use bind mounts for better file sync

## Keyboard Shortcuts Reference

### Essential PyCharm Shortcuts
- **Shift+F9**: Debug current configuration
- **Shift+F10**: Run current configuration
- **Ctrl+F8**: Toggle breakpoint
- **Alt+F8**: Evaluate expression (during debugging)
- **Ctrl+K**: Commit changes
- **Ctrl+Shift+K**: Push changes
- **Alt+F12**: Open terminal
- **Alt+0**: Open commit tool window
- **Ctrl+Alt+Shift+T**: Refactoring menu

### Django-Specific Shortcuts
- **Tools → Run manage.py Task**: Quick access to Django commands
- **Ctrl+Click**: Navigate to Django model/view definitions
- **Ctrl+B**: Go to declaration (works with Django URLs)

## Next Steps

After setting up PyCharm with DevContainer:

1. **Explore the Features**: Try the database tools, Redis browser, and debugging
2. **Customize Settings**: Adjust PyCharm settings to your preferences
3. **Learn Shortcuts**: Master the keyboard shortcuts for faster development
4. **Integrate with Team**: Share run configurations and settings with your team

## Related Documentation

- **[DevContainer Overview](README.md)** - General DevContainer information
- **[VS Code Guide](vscode-guide.md)** - Alternative IDE setup
- **[Value Proposition](value-proposition.md)** - Why use DevContainers?
- **[Technical Solutions](../../technical/)** - Architecture and troubleshooting

## Conclusion

The DevContainer provides a complete, professional Django development environment in PyCharm with:

- **Zero Configuration**: Everything works out of the box
- **Professional Tools**: Advanced debugging, database management, and testing
- **Team Consistency**: Same environment for all developers
- **Productivity**: Integrated workflows and intelligent code assistance

This setup eliminates the "works on my machine" problem and provides a superior development experience compared to manual environment setup or plain Docker usage.
