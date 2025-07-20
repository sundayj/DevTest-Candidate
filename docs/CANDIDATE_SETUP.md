# DevTest - Candidate Setup Guide

Welcome! This guide will help you quickly set up the DevTest project for your technical interview.

## What is DevTest?

DevTest is a Django web application for managing a book catalog. It includes:
- **Models**: Author, Book, Genre, and Review with relationships
- **Backend**: Django + Celery with PostgreSQL database
- **Frontend**: Bootstrap 4 ready (you'll be building the interface)
- **Tools**: Docker, DevContainer support, automated setup scripts

## Quick Setup (5 minutes)

### Step 1: Prerequisites Check

You'll need:
- **Git** (to clone the repository)
- **Docker** (will be installed by setup script if missing)
- **VS Code** (recommended, but not required)

### Step 2: Get the Code

- If you have a GitHub Pro account or higher, fork this repository and set it to private.
- If you cannot fork privately, clone the repository:

```bash
# Clone the repository (you should have received the URL)
git clone https://github.com/sundayj/DevTest-Candidate.git
cd DevTest
```

### Step 3: Run Setup Script

Choose the script for your operating system:

```bash
# Linux
./scripts/setup.sh

# macOS
./scripts/setup_mac.sh

# Windows (PowerShell)
./scripts/setup_windows.ps1
```

**What the script does:**
- Installs Docker if needed
- Installs Docker Compose
- Sets up development environment
- Creates necessary configuration files

### Step 4: Start the Application

Use one of the options in the [Running the Project guide](setup/running-project.md):

- **DevContainer (VS Code or PyCharm)**: open the project in your IDE and allow it to reopen in a container—no `devcontainer` command required.
- **Docker Compose**: run `docker-compose up -d` from a terminal.
- **GitHub Codespaces**: open the repository on GitHub and choose *Create codespace*. Once it starts, copy `.env.example` to `.devcontainer/.env`, select the `Python 3.12.11 (devtest)` interpreter, and (optionally) run `python manage.py seed_data`.

### Step 5: Verify Setup

1. **Check the application**: Visit http://localhost:8001
   - You should see a basic page or Django's default page

2. **Check the admin interface**: Visit http://localhost:8001/admin
   - You can create a superuser if needed (see below)

3. **Check the database**: The PostgreSQL database should be running
   - Sample data may or may not be present (depends on the task)
   - If needed, you can populate with sample data: `docker-compose exec web python manage.py seed_data`

## Creating a Superuser (if needed)

```bash
# If using DevContainer or Codespaces (from the IDE's terminal)
python manage.py createsuperuser

# If you're in a host terminal instead of the IDE
devcontainer exec --workspace-folder . python manage.py createsuperuser

# Docker Compose
docker-compose exec web python manage.py createsuperuser
```

## Project Structure Overview

```
DevTest/
├── devtest/                 # Main Django project
│   ├── app/                # Main application
│   │   ├── models.py       # Author, Book, Genre, Review models
│   │   ├── views.py        # Views (mostly empty - you'll build these)
│   │   ├── admin.py        # Django admin configuration
│   │   └── ...
│   └── config/             # Django settings and configuration
├── docs/                   # Documentation
├── scripts/                # Setup scripts
├── docker-compose.yml      # Docker configuration
└── manage.py              # Django management script
```

## Key Models You'll Work With

The application has these main models:

```python
# Author: name
# Book: title, author (ForeignKey), genres (ManyToMany)
# Genre: name
# Review: book (ForeignKey), rating (1-5), comment, created_at
```

The `Author` model includes a special `top_authors()` method that returns authors ranked by average review ratings.

## Common Commands

```bash
# Run Django commands

# DevContainer or Codespaces (IDE terminal):
python manage.py <command>

# If using a host terminal:
devcontainer exec --workspace-folder . python manage.py <command>

# Docker Compose:
docker-compose exec web python manage.py <command>

# Examples:
python manage.py migrate           # Apply database migrations
python manage.py shell            # Django shell
python manage.py runserver        # Start development server (usually not needed with Docker)
python manage.py collectstatic    # Collect static files
```

## Troubleshooting

### Port Already in Use
If port 8001 is busy:
```bash
# Stop the containers
docker-compose down

# Check what's using the port
lsof -i :8001  # Linux/macOS
netstat -ano | findstr :8001  # Windows

# Start again
docker-compose up -d
```

### Docker Issues
```bash
# Reset everything
docker-compose down -v  # Removes containers and volumes
docker-compose up -d    # Start fresh
```

### Permission Issues (Linux)
```bash
# Fix file permissions
sudo chown -R $USER:$USER .
```

### Can't Access Application
1. Check containers are running: `docker-compose ps`
2. Check logs: `docker-compose logs web`
3. Verify port mapping in `docker-compose.yml`

## Development Tips

### File Editing
- Files are synchronized between your host and the container
- Edit files with your preferred editor on your host machine
- Changes are reflected immediately in the running container

### Database Access
- PostgreSQL runs in a separate container
- Connection details are in `docker-compose.yml`
- Use Django's ORM or admin interface to interact with data

### Static Files
- CSS/JS files go in `devtest/app/static/app/`
- Templates go in `devtest/app/templates/app/`
- Bootstrap 4 is already included via `django-bootstrap4`

## What's Already Done

✅ **Models**: Complete database schema with relationships  
✅ **Admin Interface**: You can manage data via `/admin`  
✅ **Docker Setup**: Containerized development environment  
✅ **Dependencies**: All Python packages installed  
✅ **Bootstrap**: Frontend framework ready to use  

## What You'll Build

❌ **Views**: Web pages and API endpoints  
❌ **Templates**: HTML pages for the user interface  
❌ **URLs**: Route configuration  
❌ **Forms**: User input handling  
❌ **Authentication**: User login/registration (maybe)  

## Getting Help

During your interview:
- **Ask questions** - clarification is always welcome
- **Explain your thinking** - we want to understand your approach
- **Don't worry about perfection** - focus on working solutions
- **Use documentation** - Django docs, Bootstrap docs, etc. are fair game

## Ready to Start?

Once you can access http://localhost:8001 and the admin interface, you're ready to begin your interview task!

The interviewer will provide specific requirements for what to build. Good luck! 🚀

---

**Need help?** Let your interviewer know if you encounter any setup issues.
