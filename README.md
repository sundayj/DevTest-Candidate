# DevTest

A minimal Django + Celery project that uses [uv](https://github.com/astral-sh/uv) for dependency management. It ships with [Requests](https://requests.readthedocs.io/) and [Bootstrap&nbsp;4](https://getbootstrap.com/docs/4.6/getting-started/introduction/) via `django-bootstrap4`. You can work either inside a dev container or by running the stack with Docker Compose.

This project targets **Python&nbsp;3.12**.

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

### What the setup scripts do:

- **Check and install Docker** (Linux: `docker.io`, macOS/Windows: Docker Desktop)
- **Install Docker Compose** (if not already available)
- **Install Dev Containers CLI** for DevContainer support
- **Install VS Code extension** (if VS Code is detected)
- **Set up environment file** (copies `.env.example` to `.devcontainer/.env` if needed)

> **💡 Interactive Setup**: The scripts ask for permission before installing each tool. If you decline, they provide detailed manual installation instructions with links and alternative methods.

### After running setup:

1. **Start the development environment** (see [Running the Project](docs/setup/running-project.md) for full instructions):
   - **DevContainer (recommended)**: open the project in VS Code or PyCharm Professional and allow it to reopen in the container—no command line needed.
   - **Docker Compose**: run `docker-compose up -d`.
   - **GitHub Codespaces**: clone this repository to your own account, set the clone to private, and open a codespace from that copy.

2. **Access the application**: Visit <http://localhost:8001>

## 📚 Documentation

For comprehensive documentation, guides, and detailed setup instructions, visit the **[docs/](docs/)** directory:

- **[Getting Started Guide](docs/setup/getting-started.md)** - Complete setup for new developers
- **[DevContainer Documentation](docs/development/devcontainer/)** - VS Code and PyCharm setup guides
- **[Docker Compose Guide](docs/development/docker-compose.md)** - Advanced Docker Compose usage
- **[Technical Documentation](docs/technical/)** - Architecture and technical solutions

For **automated systems and CI/CD**, see **[AGENTS.md](AGENTS.md)**.

### 🌐 Local Documentation Server

For the best reading experience, serve the documentation locally with search and navigation:

```bash
# Quick start
./scripts/serve-docs.sh        # Linux/macOS
scripts\serve-docs.bat         # Windows

# Available at http://localhost:3000
```

### Library catalog

The demo app contains a small catalog with `Author`, `Book`, `Genre` and
`Review` models. You can experiment with creating books, assigning genres and
leaving reviews via the Django admin interface. The `Author` model exposes a
`top_authors()` queryset method that returns the best rated authors based on the
average review score.

#### 📊 Sample Data

To quickly populate the database with realistic sample data for development or interviews:

```bash
# Add sample data (30 books, 30 authors, 20 genres, ~100 reviews)
docker-compose exec web python manage.py seed_data

# Clear existing data and add fresh sample data
docker-compose exec web python manage.py seed_data --clear
```

See **[Database Seed Data Guide](docs/SEED_DATA.md)** for detailed information about the sample data and usage options.

## 🎯 Using DevTest for Technical Interviews

This project is designed to be an excellent foundation for technical interviews and coding assessments. It provides a realistic Django application with well-structured models but minimal frontend implementation, allowing candidates to demonstrate their skills across different areas.

### For Interviewers

- **[Interview Tasks Guide](docs/INTERVIEW_TASKS.md)** - Comprehensive tasks for different skill levels (Junior, Mid, Senior)
- **[Interview Scenarios & Examples](docs/INTERVIEW_SCENARIOS.md)** - Practical bug scenarios, sample implementations, and evaluation rubrics
- **[Interview Distribution Guide](docs/INTERVIEW_DISTRIBUTION.md)** - Secure methods for sharing the project with candidates
- **[Candidate Setup Guide](docs/CANDIDATE_SETUP.md)** - Quick setup instructions to share with candidates

> **💡 Detailed Task Instructions**: Individual task instruction files with comprehensive implementation guidelines, code examples, and evaluation rubrics are available in the [`docs/interviewer/`](docs/interviewer/) directory. See the [Interviewer README](docs/interviewer/README.md) for the complete list.

#### 🔒 Secure Project Distribution

**Important**: Don't share your repository directly with candidates as they can see git history and potentially find solutions to debugging tasks.

**Quick Distribution Options**:
```bash
# Create clean package without git history
./scripts/create_interview_package.sh

# Or create zip archive
./scripts/create_interview_zip.sh
```

See the **[Interview Distribution Guide](docs/INTERVIEW_DISTRIBUTION.md)** for comprehensive security practices and multiple distribution methods.

### For Candidates

If you're here for a technical interview, start with the **[Candidate Setup Guide](docs/CANDIDATE_SETUP.md)** to get the project running quickly.

### Key Features for Assessment

- **Backend Skills**: Django models, views, APIs, database optimization
- **Frontend Skills**: HTML/CSS, JavaScript, Bootstrap, responsive design  
- **Full-Stack**: Authentication, forms, AJAX, user experience
- **Debugging**: Intentional bugs for problem-solving assessment
- **System Design**: Scalability discussions and architecture planning
