# DevTest - Candidate Setup Guide

Welcome! This guide will help you quickly set up the DevTest project for your technical interview.

## What is DevTest?

DevTest is a Django web application for managing a book catalog. It includes:
- **Models**: Author, Book, Genre, and Review with relationships
- **Backend**: Django + Celery with PostgreSQL database
- **Frontend**: Bootstrap 4 ready (you'll be building the interface)
- **Tools**: Docker, DevContainer support, automated setup scripts

## Quick Start

For the shortest path to a working environment see
[`candidate/quick-start.md`](candidate/quick-start.md).
The remainder of this guide provides additional background and troubleshooting
tips once you're up and running.

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
