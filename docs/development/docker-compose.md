# Docker Compose Development Guide

This guide covers using Docker Compose for development, including the override file system and how it integrates with DevContainer usage.

> **Note**: This is part of the [DevTest documentation](../README.md). For DevContainer usage, see the [DevContainer guide](devcontainer/README.md).

## Overview

Docker Compose provides a way to run the complete application stack with multiple services. This project uses Docker Compose both as a standalone development environment and as the infrastructure foundation for DevContainers.

## Quick Start

```bash
# Install project dependencies (required for docker-compose usage)
uv sync

# Start all services
docker-compose up -d

# Run migrations
docker-compose exec web python manage.py migrate

# Create superuser
docker-compose exec web python manage.py createsuperuser

# Access application at http://localhost:8001

# Stop services
docker-compose down
```

> **⚠️ Important**: When using Docker Compose (instead of DevContainer), you must run `uv sync` first to install all project dependencies. The DevContainer handles this automatically, but Docker Compose requires manual dependency installation.

## Service Architecture

The Docker Compose setup includes four main services:

### Services Overview

```yaml
services:
  web:      # Django application server
  db:       # PostgreSQL database
  redis:    # Redis cache and message broker
  worker:   # Celery background task worker
```

### Service Details

#### Web Service
- **Purpose**: Django application server
- **Port**: 8001
- **Command**: Configurable via override file
- **Dependencies**: db, redis

#### Database Service (db)
- **Purpose**: PostgreSQL database
- **Port**: 5433 (to avoid conflicts with local PostgreSQL)
- **Data**: Persisted in `.devcontainer/.data/postgres/`
- **Credentials**: postgres/postgres (development only)

#### Redis Service
- **Purpose**: Cache and Celery message broker
- **Port**: 6380 (to avoid conflicts with local Redis)
- **Data**: Persisted in `.devcontainer/.data/redis/`

#### Worker Service
- **Purpose**: Celery background task processing
- **Command**: `uv run celery -A devtest.config.celery_config worker --loglevel=info`
- **Dependencies**: db, redis

## Docker Compose Override System

### What is docker-compose.override.yml?

The `docker-compose.override.yml` file is a special Docker Compose file that automatically extends and overrides configurations from the main `docker-compose.yml` file. When you run `docker-compose up`, Docker Compose automatically looks for and applies this override file if it exists.

### How It Works

#### Automatic Merging
Docker Compose follows this order when loading configuration files:
1. `docker-compose.yml` (base configuration)
2. `docker-compose.override.yml` (automatic overrides)
3. Any additional files specified with `-f` flag

#### File Precedence
- Settings in `docker-compose.override.yml` **override** settings in `docker-compose.yml`
- Arrays (like `ports`, `volumes`) are **merged**
- Scalar values (like `command`, `image`) are **replaced**

### Purpose in This Project

This project needs to support two different usage patterns:

1. **DevContainer Usage**: Container should stay alive for interactive development
2. **Docker-Compose Usage**: Container should start the web server automatically

#### The Solution

**Base Configuration (`docker-compose.yml`)**
```yaml
services:
  web:
    command: sleep infinity  # Keeps container alive but doesn't start server
```

**Override Configuration (`docker-compose.override.yml`)**
```yaml
services:
  web:
    command: uv run uvicorn devtest.config.asgi:application --host 0.0.0.0 --port 8001
```

#### How It Works in Practice

**When Using Docker-Compose:**
```bash
docker-compose up -d
```
- Loads `docker-compose.yml`
- Automatically applies `docker-compose.override.yml`
- **Result**: Web server starts automatically on port 8001

**When Using DevContainer:**
- DevContainer uses only `docker-compose.yml` (ignores override file)
- **Result**: Container stays alive with `sleep infinity` for interactive development

## Common Use Cases

### 1. Development vs Production Differences
```yaml
# docker-compose.override.yml (development)
services:
  web:
    environment:
      - DEBUG=true
    volumes:
      - .:/app  # Mount source code for hot reload
    ports:
      - "8001:8001"  # Expose port for development
```

### 2. Local Environment Customization
```yaml
# docker-compose.override.yml (local developer preferences)
services:
  db:
    ports:
      - "5433:5432"  # Different port to avoid conflicts
  web:
    environment:
      - LOG_LEVEL=debug  # More verbose logging
```

### 3. Service Variations
```yaml
# docker-compose.override.yml
services:
  web:
    command: python manage.py runserver 0.0.0.0:8001  # Django dev server instead of uvicorn

  # Add additional services for development
  mailhog:
    image: mailhog/mailhog
    ports:
      - "8025:8025"
```

## Alternative Override Files

### Named Override Files
You can create specific override files for different environments:

```bash
# For staging environment
docker-compose -f docker-compose.yml -f docker-compose.staging.yml up

# For testing environment  
docker-compose -f docker-compose.yml -f docker-compose.test.yml up

# Multiple overrides
docker-compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose.local.yml up
```

### Common Override File Names
- `docker-compose.override.yml` - Automatic override
- `docker-compose.prod.yml` - Production overrides
- `docker-compose.dev.yml` - Development overrides
- `docker-compose.test.yml` - Testing overrides
- `docker-compose.local.yml` - Local developer overrides

## Development Workflows

### Daily Development
```bash
# Start services
docker-compose up -d

# Check service status
docker-compose ps

# View logs
docker-compose logs -f web

# Execute commands in containers
docker-compose exec web python manage.py shell
docker-compose exec web python manage.py test

# Stop services
docker-compose down
```

### Database Operations
```bash
# Run migrations
docker-compose exec web python manage.py migrate

# Create migrations
docker-compose exec web python manage.py makemigrations

# Access database shell
docker-compose exec web python manage.py dbshell

# Direct PostgreSQL access
docker-compose exec db psql -U postgres -d postgres
```

### Testing and Debugging
```bash
# Run tests
docker-compose exec web python manage.py test

# Run specific test
docker-compose exec web python manage.py test myapp.tests.TestMyModel

# Debug with shell
docker-compose exec web python manage.py shell

# Check Celery worker
docker-compose logs worker
```

## Configuration Management

### Environment Variables

The project uses `.devcontainer/.env` for environment configuration:

```bash
# Database Configuration
DB_NAME=postgres
DB_USER=postgres
DB_PASSWORD=postgres
DB_PORT=5433
PGPORT=5433

# Redis Configuration
REDIS_PORT=6380

# PostgreSQL Service Configuration
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=postgres
```

### Volume Management

Data is persisted using bind mounts:

```yaml
volumes:
  - ./.devcontainer/.data/postgres:/var/lib/postgresql/data  # Database data
  - ./.devcontainer/.data/redis:/data                       # Redis data
  - .:/app                                                  # Source code
```

## Integration with DevContainer

The Docker Compose configuration serves dual purposes:

1. **Standalone Development**: Full application stack with automatic server startup
2. **DevContainer Infrastructure**: Provides services (db, redis) for DevContainer development

### Unified Database Solution

Both Docker Compose and DevContainer use the same database instance:
- Same PostgreSQL container service ('db')
- Same data volumes for persistence
- Same network for service communication
- Migrations applied in one environment are visible in the other

For technical details, see the [Unified Database Solution](../technical/unified-database-solution.md).

## Troubleshooting

### Common Issues

#### 1. Override Not Applied
```bash
# Check which files are being loaded
docker-compose config

# Verify override file syntax
docker-compose -f docker-compose.override.yml config
```

#### 2. Unexpected Behavior
```bash
# See the merged configuration
docker-compose config

# Use specific files to isolate issues
docker-compose -f docker-compose.yml up  # Base only
docker-compose up                         # Base + override
```

#### 3. Port Conflicts
```bash
# Check what's using the ports
lsof -i :8001
lsof -i :5433
lsof -i :6380

# Use different ports in override file
```

#### 4. Database Connection Issues
```bash
# Check database service
docker-compose logs db

# Test connection
docker-compose exec web python manage.py dbshell

# Verify network connectivity
docker-compose exec web ping db
```

### Debugging Commands

```bash
# View merged configuration
docker-compose config

# Check service status
docker-compose ps

# View service logs
docker-compose logs <service_name>

# Execute commands in services
docker-compose exec <service_name> <command>

# Restart specific service
docker-compose restart <service_name>

# Rebuild and restart
docker-compose up -d --build
```

## Best Practices

### 1. Keep Base Configuration Minimal
```yaml
# docker-compose.yml - Base configuration
services:
  web:
    build: .
    volumes:
      - .:/app
    depends_on:
      - db
```

### 2. Use Override for Environment-Specific Settings
```yaml
# docker-compose.override.yml - Development-specific
services:
  web:
    command: python manage.py runserver 0.0.0.0:8001
    environment:
      - DEBUG=true
    ports:
      - "8001:8001"
```

### 3. Document Override Purpose
Always include comments explaining why overrides are needed:

```yaml
# docker-compose.override.yml
# This file overrides the base configuration for local development
# - Starts the web server automatically (base uses 'sleep infinity' for devcontainer)
# - Enables debug mode
# - Exposes ports for local access

services:
  web:
    command: uv run uvicorn devtest.config.asgi:application --host 0.0.0.0 --port 8001
```

### 4. Version Control Considerations

#### Commit Override Files When:
- They contain standard development configuration
- They're needed for the project to work out-of-the-box
- They represent the "default" development environment

#### Don't Commit Override Files When:
- They contain personal/local preferences
- They include sensitive information
- They're specific to individual developer setups

## Performance Optimization

### Resource Allocation
```yaml
# docker-compose.override.yml
services:
  db:
    deploy:
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 512M
```

### Build Optimization
```bash
# Use build cache
docker-compose build

# Force rebuild without cache
docker-compose build --no-cache

# Build specific service
docker-compose build web
```

## Quick Reference

### Essential Commands
```bash
# View merged configuration
docker-compose config

# View base configuration only
docker-compose -f docker-compose.yml config

# Start with override (default)
docker-compose up

# Start without override
docker-compose -f docker-compose.yml up

# Use custom override file
docker-compose -f docker-compose.yml -f docker-compose.custom.yml up
```

### File Structure
```
project/
├── docker-compose.yml          # Base configuration
├── docker-compose.override.yml # Automatic overrides
├── docker-compose.prod.yml     # Production overrides (optional)
└── docker-compose.local.yml    # Personal overrides (optional)
```

## Related Documentation

- **[DevContainer Guide](devcontainer/README.md)** - DevContainer setup and usage
- **[Unified Database Solution](../technical/unified-database-solution.md)** - How DevContainer and Docker Compose share data
- **[Getting Started](../setup/getting-started.md)** - Initial setup instructions
- **[Database Management](database.md)** - Database operations and management

## Next Steps

After setting up Docker Compose:

1. **Try DevContainer**: Experience the enhanced development environment
2. **Customize Override**: Adapt the override file to your preferences
3. **Learn Debugging**: Master the debugging and troubleshooting techniques
4. **Explore Integration**: Understand how it works with DevContainer

The Docker Compose setup provides a solid foundation for both standalone development and as infrastructure for enhanced DevContainer development.
