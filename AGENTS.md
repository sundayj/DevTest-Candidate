# Agent Instructions

This document provides instructions for automated systems, CI/CD pipelines, and other agents working with the DevTest project.

> **Note**: This is part of the [DevTest documentation](README.md). For human developers, see the [getting started guide](docs/setup/getting-started.md).

## Overview

This repository has no mandatory automated tests or linting. The project targets **Python 3.12** and can be run using either DevContainer or Docker Compose approaches.

## Prerequisites

- **Python 3.12** (if running locally)
- **Docker Desktop** installed and running
- **Docker Compose** with plugin support

## Quick Setup Verification

Before starting development or testing, verify that required tools are available using the platform-specific setup scripts:

- **Linux**: `scripts/setup.sh`
- **macOS**: `scripts/setup_mac.sh`
- **Windows**: `scripts/setup_windows.ps1`

These scripts check for Docker, Docker Compose, and Dev Containers CLI, offering to install missing components.

## Environment Configuration

Copy the example environment file before starting:

```bash
cp .env.example .devcontainer/.env
```

The `.devcontainer/.env` file contains database and Redis configuration that both Docker Compose and DevContainer environments use.

## Docker Compose Approach

### Starting Services

```bash
# Start all services in background
docker-compose up -d

# Verify services are running
docker-compose ps
```

### Database Setup

```bash
# Apply database migrations
docker-compose exec web python manage.py migrate

# Verify database connection
docker-compose exec web python manage.py check
```

### Running Tests

```bash
# Run the test suite
docker-compose exec web uv run pytest

# Run Django's built-in tests
docker-compose exec web python manage.py test
```

### Application Verification

```bash
# Check that the web server is accessible
curl -f http://localhost:8001 || echo "Web server not accessible"

# Create a superuser for admin access (interactive)
docker-compose exec web python manage.py createsuperuser
```

### Cleanup

```bash
# Stop and remove containers
docker-compose down

# Remove volumes (optional, removes data)
docker-compose down -v
```

## DevContainer Approach

### Prerequisites for Agents

- **Dev Containers CLI**: Install with `curl -fsSL https://raw.githubusercontent.com/devcontainers/cli/main/install.sh | sh`
- **Docker Desktop**: Must be running

### Starting DevContainer

```bash
# Start the devcontainer
devcontainer up --workspace-folder .

# Execute commands in the container
devcontainer exec --workspace-folder . python manage.py migrate
devcontainer exec --workspace-folder . python manage.py check
```

### Running Tests in DevContainer

```bash
# Run tests inside the devcontainer
devcontainer exec --workspace-folder . uv run pytest
devcontainer exec --workspace-folder . python manage.py test
```

## Essential Commands Reference

### Database Operations
```bash
# Docker Compose
docker-compose exec web python manage.py migrate
docker-compose exec web python manage.py check

# DevContainer
devcontainer exec --workspace-folder . python manage.py migrate
devcontainer exec --workspace-folder . python manage.py check
```

### Testing
```bash
# Docker Compose
docker-compose exec web uv run pytest
docker-compose exec web python manage.py test

# DevContainer
devcontainer exec --workspace-folder . uv run pytest
devcontainer exec --workspace-folder . python manage.py test
```

### Application Server
```bash
# Docker Compose (automatic via override file)
docker-compose up -d
# Server available at http://localhost:8001

# DevContainer (manual start)
devcontainer exec --workspace-folder . python manage.py runserver 0.0.0.0:8001
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Test DevTest Application

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Copy environment file
      run: cp .env.example .devcontainer/.env

    - name: Start services
      run: docker-compose up -d

    - name: Wait for services
      run: sleep 10

    - name: Run migrations
      run: docker-compose exec -T web python manage.py migrate

    - name: Run tests
      run: docker-compose exec -T web uv run pytest

    - name: Check application
      run: docker-compose exec -T web python manage.py check

    - name: Cleanup
      run: docker-compose down
```

### Jenkins Pipeline Example

```groovy
pipeline {
    agent any

    stages {
        stage('Setup') {
            steps {
                sh 'cp .env.example .devcontainer/.env'
            }
        }

        stage('Start Services') {
            steps {
                sh 'docker-compose up -d'
                sh 'sleep 10'  // Wait for services to be ready
            }
        }

        stage('Database Setup') {
            steps {
                sh 'docker-compose exec -T web python manage.py migrate'
            }
        }

        stage('Test') {
            steps {
                sh 'docker-compose exec -T web uv run pytest'
                sh 'docker-compose exec -T web python manage.py test'
            }
        }

        stage('Health Check') {
            steps {
                sh 'docker-compose exec -T web python manage.py check'
            }
        }
    }

    post {
        always {
            sh 'docker-compose down'
        }
    }
}
```

## Application Architecture

### Services Overview

The application consists of four main services:

- **web**: Django application server (port 8001)
- **db**: PostgreSQL database (port 5433)
- **redis**: Redis cache and message broker (port 6380)
- **worker**: Celery background task worker

### Library Catalog Demo

The demo application includes:
- **Models**: `Author`, `Book`, `Genre`, `Review`
- **Admin Interface**: Available at `/admin/` after creating superuser
- **API**: Basic Django views and templates
- **Background Tasks**: Celery worker for async processing

### Key Features to Test

1. **Database Connectivity**: Ensure migrations apply successfully
2. **Redis Connectivity**: Verify caching and Celery functionality
3. **Web Server**: Confirm HTTP responses on port 8001
4. **Admin Interface**: Test Django admin functionality
5. **Background Tasks**: Verify Celery worker processes tasks

## Troubleshooting for Agents

### Common Issues

1. **Port Conflicts**: Ensure ports 8001, 5433, and 6380 are available
2. **Docker Not Running**: Verify Docker Desktop is started
3. **Environment File Missing**: Ensure `.devcontainer/.env` exists
4. **Service Startup Time**: Allow time for PostgreSQL and Redis to initialize

### Health Checks

```bash
# Check service status
docker-compose ps

# Test database connection
docker-compose exec web python manage.py dbshell --command="SELECT 1;"

# Test Redis connection
docker-compose exec redis redis-cli ping

# Test web server
curl -f http://localhost:8001/admin/

# Check logs for errors
docker-compose logs web
docker-compose logs db
docker-compose logs redis
```

### Error Recovery

```bash
# Restart all services
docker-compose restart

# Rebuild containers if needed
docker-compose up -d --build

# Reset database (removes all data)
docker-compose down -v
docker-compose up -d
docker-compose exec web python manage.py migrate
```

## Performance Considerations

### Resource Requirements

- **Memory**: Minimum 2GB available for Docker
- **CPU**: Multi-core recommended for parallel service startup
- **Disk**: ~1GB for images and data volumes
- **Network**: Internet access for image downloads

### Optimization Tips

1. **Use Docker BuildKit**: Set `DOCKER_BUILDKIT=1`
2. **Parallel Startup**: Services start concurrently
3. **Health Checks**: Wait for services before running tests
4. **Cleanup**: Remove containers and volumes after testing

## Security Considerations

### Development Environment

- Default credentials are `postgres/postgres` (development only)
- Redis has no authentication (development only)
- Django debug mode is enabled
- All services bind to localhost only

### Production Deployment

This configuration is for development only. For production:

1. Change all default passwords
2. Enable Redis authentication
3. Disable Django debug mode
4. Use proper SSL/TLS certificates
5. Implement proper secret management

## Related Documentation

- **[Getting Started Guide](docs/setup/getting-started.md)** - Human developer setup
- **[Docker Compose Guide](docs/development/docker-compose.md)** - Detailed Docker Compose usage
- **[DevContainer Guide](docs/development/devcontainer/README.md)** - DevContainer setup and usage
- **[Unified Database Solution](docs/technical/unified-database-solution.md)** - Architecture and implementation details

## Support

For issues with automated testing or CI/CD integration:

1. Check the [troubleshooting section](README.md#troubleshooting) in the main README
2. Review service logs using `docker-compose logs <service>`
3. Verify environment configuration in `.devcontainer/.env`
4. Ensure all prerequisites are installed and running

This configuration provides a reliable foundation for automated testing and deployment pipelines while maintaining compatibility with both Docker Compose and DevContainer development workflows.
