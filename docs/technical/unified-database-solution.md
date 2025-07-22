# Unified Database Solution

This document explains how the DevTest project ensures that both DevContainer and Docker Compose environments use the same database instance, solving data synchronization issues.

> **Note**: This is part of the [DevTest documentation](../README.md). For setup guides, see the [development documentation](../development/).

## Problem

Previously, docker-compose and devcontainer were using different database instances:
- **Docker-compose**: Used a PostgreSQL container service named 'db'
- **DevContainer**: Used PostgreSQL installed directly inside the container via features

This caused the issue where:
- Migrations applied in docker-compose were not visible in devcontainer
- Data created in one environment was not accessible in the other
- Each environment had its own separate database instance

## Solution

Modified the devcontainer configuration to use the same docker-compose services instead of separate database instances.

### Key Changes

#### 1. Modified `.devcontainer/devcontainer.json`
- Removed `features` for postgres and redis
- Removed separate `mounts` for database data
- Added `dockerComposeFile` pointing to `../docker-compose.yml`
- Set `service` to `"web"` to use the same web service
- Updated `postAttachCommand` to remove database service management

**Before:**
```json
{
  "name": "DevTest",
  "build": {
    "dockerfile": "Dockerfile"
  },
  "features": {
    "./features/postgres": {},
    "./features/redis": {}
  },
  "mounts": [
    "source=./.devcontainer/.data/postgres,target=/var/lib/postgresql/data,type=bind",
    "source=./.devcontainer/.data/redis,target=/data,type=bind"
  ]
}
```

**After:**
```json
{
  "name": "DevTest",
  "dockerComposeFile": "../docker-compose.yml",
  "service": "web",
  "workspaceFolder": "/app"
}
```

#### 2. Modified `docker-compose.yml`
- Changed web service `command` from starting uvicorn to `sleep infinity`
- This allows the container to stay running for devcontainer use

**Before:**
```yaml
services:
  web:
    command: uv run uvicorn devtest.config.asgi:application --host 0.0.0.0 --port 8001
```

**After:**
```yaml
services:
  web:
    command: sleep infinity
```

#### 3. Created `docker-compose.override.yml`
- Overrides the web service command to start uvicorn when running docker-compose normally
- Ensures production behavior is preserved

```yaml
version: '3.9'

services:
  web:
    command: uv run uvicorn devtest.config.asgi:application --host 0.0.0.0 --port 8001
```

## How It Works

### Docker-Compose Usage
```bash
docker-compose up -d
```
- Loads `docker-compose.yml`
- Automatically applies `docker-compose.override.yml`
- **Result**: Web server starts automatically on port 8001
- All services (web, db, redis, worker) run as intended

### DevContainer Usage
- Opens the project in the `web` service container
- Uses only `docker-compose.yml` (ignores override file)
- **Result**: Container stays alive with `sleep infinity` for interactive development
- Has access to the same `db` and `redis` services
- Uses the same network and data volumes
- Can resolve 'db' and 'redis' hostnames correctly

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Compose Network                   │
│                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │     web     │    │     db      │    │    redis    │     │
│  │  (Django)   │◄──►│(PostgreSQL) │    │   (Cache)   │     │
│  │             │    │             │    │             │     │
│  └─────────────┘    └─────────────┘    └─────────────┘     │
│         ▲                   ▲                   ▲          │
│         │                   │                   │          │
│         │            ┌─────────────┐            │          │
│         │            │   worker    │            │          │
│         │            │  (Celery)   │◄───────────┘          │
│         │            │             │                       │
│         │            └─────────────┘                       │
│         │                                                  │
│  ┌─────────────────────────────────────────────────────────┤
│  │              Shared Data Volumes                       │
│  │  • postgres_data: /var/lib/postgresql/data             │
│  │  • redis_data: /data                                   │
│  └─────────────────────────────────────────────────────────┘
│                                                             │
└─────────────────────────────────────────────────────────────┘
         ▲                                        ▲
         │                                        │
┌─────────────────┐                    ┌─────────────────┐
│  Docker Compose │                    │   DevContainer  │
│                 │                    │                 │
│ • Uses override │                    │ • Uses base     │
│ • Starts server │                    │ • Interactive   │
│ • Production-   │                    │ • Development   │
│   like behavior │                    │   optimized     │
└─────────────────┘                    └─────────────────┘
```

## Benefits

✅ **Unified Database**: Both environments use the exact same PostgreSQL instance
✅ **Shared Migrations**: Migrations applied in one environment are visible in the other
✅ **Data Persistence**: Data created in either environment persists across both
✅ **No Configuration Conflicts**: No more separate database instances causing issues
✅ **Simplified Setup**: Single docker-compose configuration for both use cases
✅ **Network Integration**: Both environments can resolve service hostnames
✅ **Volume Sharing**: Same data volumes used by both environments

## Verification

Both environments now:
- Connect to the same database host ('db')
- See the same tables and applied migrations
- Share the same data and user accounts
- Use the same Redis instance for caching/queuing
- Can resolve service hostnames ('db', 'redis') correctly

### Testing the Solution

1. **Start with Docker Compose:**
   ```bash
   docker-compose up -d
   docker-compose exec web python manage.py migrate
   docker-compose exec web python manage.py createsuperuser
   ```

2. **Switch to DevContainer:**
   - Open project in DevContainer
   - Check that migrations are already applied
   - Verify that the superuser exists
   - Confirm database tables are visible

3. **Create data in DevContainer:**
   ```bash
   python manage.py shell
   # Create some test data
   ```

4. **Verify in Docker Compose:**
   ```bash
   docker-compose exec web python manage.py shell
   # Check that the test data exists
   ```

## Technical Implementation Details

### Database Host Resolution

The Django settings include auto-detection logic that works correctly in both environments:

```python
def get_db_host():
    """
    Auto-detect the environment and return the appropriate database host.
    """
    if os.path.exists('/.dockerenv'):
        # We're in a Docker container
        try:
            socket.gethostbyname('db')
            return 'db'  # docker-compose environment
        except socket.gaierror:
            return 'localhost'  # fallback
    else:
        return 'localhost'  # running locally
```

Since both environments now use the docker-compose network, both can resolve the 'db' hostname correctly.

### Volume Management

Both environments use the same volume configuration:

```yaml
volumes:
  postgres_data:
  redis_data:
```

This ensures data persistence across both usage patterns.

### Network Configuration

Both environments share the same Docker network:

```yaml
networks:
  backend:
    driver: bridge
```

This allows service-to-service communication using hostnames.

## Troubleshooting

### Common Issues

1. **Services not starting**: Ensure Docker Desktop is running
2. **Database connection refused**: Check that docker-compose services are up
3. **Migrations not visible**: Verify both environments use the same database host
4. **Port conflicts**: Ensure ports 8001, 5433, and 6380 are available

### Debugging Commands

```bash
# Check service status
docker-compose ps

# View service logs
docker-compose logs db
docker-compose logs redis

# Test database connection
docker-compose exec web python manage.py dbshell

# Check network connectivity
docker-compose exec web ping db
docker-compose exec web ping redis
```

## Related Documentation

- **[Docker Compose Guide](../development/docker-compose.md)** - Docker Compose usage and configuration
- **[DevContainer Overview](../development/devcontainer/README.md)** - DevContainer setup and usage
- **[Architecture Overview](architecture.md)** - Overall project architecture
- **[Database Management](../development/database.md)** - Database operations and management

## Migration Guide

If you're upgrading from the old separate database setup:

1. **Backup existing data** from both environments
2. **Stop all containers**: `docker-compose down`
3. **Update configuration** to use the unified approach
4. **Start services**: `docker-compose up -d`
5. **Restore data** if needed
6. **Test both environments** to ensure they share the same database

The unified database solution provides a much more reliable and consistent development experience across both Docker Compose and DevContainer usage patterns.
