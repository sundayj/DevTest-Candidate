# DevTest

A minimal Django + Celery project that uses [uv](https://github.com/astral-sh/uv) for dependency management. It ships with [Requests](https://requests.readthedocs.io/) and [Bootstrap&nbsp;4](https://getbootstrap.com/docs/4.6/getting-started/introduction/) via `django-bootstrap4`. You can work either inside a dev container or by running the stack with Docker Compose.

This project targets **Python&nbsp;3.12**.

## 🚀 Quick Setup (Recommended)

**The QUICKEST way to get started is using GitHub Codespaces:**

### 🌟 GitHub Codespaces (Fastest - 2 minutes)

1. **Access GitHub Codespaces**:
   - If you have access to this repository directly: Click the green **"Code"** button → **"Codespaces"** tab → **"Create codespace on main"**
   - If you received a repository link: Create a PRIVATE fork or clone of the repository to your GitHub account, then create a codespace from your copy

2. **Handle the .env file error**:
   - You'll probably see an error mentioning a `.env` file couldn't be found
   - **Don't worry!** The codespace will still open and show the project folder

3. **Set up the environment file**:
   - In the codespace file explorer, locate `.env.example` in the root directory
   - Copy the `.env.example` file
   - Navigate to the `.devcontainer` directory
   - Paste the file and rename it to `.env`

4. **Rebuild the codespace**:
   - Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac) to open the Command Palette
   - Type "Codespaces: Rebuild Container" and select it
   - Wait for the rebuild to complete (usually 1-2 minutes)

5. **Access the application**: Visit <http://localhost:8001> once the rebuild is complete

### 🛠️ Alternative: Setup Scripts

If you prefer to work locally or don't have access to GitHub Codespaces, use the setup scripts:

```bash
# Linux (uses built-in Docker, NOT Docker Desktop)
./scripts/setup.sh

# macOS
./scripts/setup_mac.sh

# Windows
./scripts/setup_windows.ps1
```

> **⚠️ Important for Linux users**: Use the built-in Linux Docker engine (`docker.io` package) instead of Docker Desktop. The setup script will install the correct version for you.

#### What the setup scripts do:

- **Check and install Docker** (Linux: `docker.io`, macOS/Windows: Docker Desktop)
- **Install Docker Compose** (if not already available)
- **Install Dev Containers CLI** for DevContainer support
- **Install VS Code extension** (if VS Code is detected)
- **Set up environment file** (copies `.env.example` to `.devcontainer/.env` if needed)

> **💡 Interactive Setup**: The scripts ask for permission before installing each tool. If you decline, they provide detailed manual installation instructions with links and alternative methods.

#### After running setup scripts:

1. **Start the development environment** (see [Running the Project](docs/setup/running-project.md) for full instructions):
   - **DevContainer (recommended)**: open the project in VS Code or PyCharm Professional and allow it to reopen in the container—no command line needed.
   - **Docker Compose**: run `docker-compose up -d`.

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

# If using DevContainers/Codespaces
python manage.py seed_data

# Clear existing data and add fresh sample data
docker-compose exec web python manage.py seed_data --clear

# Or if using DevContainers/Codespaces
python manage.py seed_data --clear
```

See **[Database Seed Data Guide](docs/SEED_DATA.md)** for detailed information about the sample data and usage options.

## 🎯 Using DevTest for Technical Interviews

This project is designed to be an excellent foundation for technical interviews and coding assessments. It provides a realistic Django application with well-structured models but minimal frontend implementation, allowing candidates to demonstrate their skills across different areas.

### For Candidates

> **🔒 IMPORTANT - Privacy & Redistribution Restrictions**
> 
> **Your solution must remain private.** This repository and your work are provided solely for technical interview purposes. You agree to the following restrictions:
> 
> - **Do not share** your solutions, code, or any part of this repository with anyone other than your interviewer
> - **Do not redistribute** or publish this repository or derivative works in any form
> - **Do not create public repositories** or public forks containing this code
> - **Keep your work confidential** throughout and after the interview process
> 
> By using this repository, you agree to these terms as outlined in the [LICENSE.md](LICENSE.md). Violation of these terms may result in disqualification from the interview process.

1. If you're here for a technical interview, start with the **[Candidate Setup Guide](docs/CANDIDATE_SETUP.md)** to get the project running quickly.
2. **Work on Your Changes:**
   Complete the provided tasks in the repository. Make commits as you progress with your implementation.
3. **Submit Your Work:**
   - Push your changes to your private fork or create a new private GitHub repository.
   - Add [sundayj](https://github.com/sundayj) as a collaborator to your private repository.
   - Optionally, create a **Pull Request** in your private repository and add [sundayj](https://github.com/sundayj) as a reviewer.

### Key Features for Assessment

- **Backend Skills**: Django models, views, APIs, database optimization
- **Frontend Skills**: HTML/CSS, JavaScript, Bootstrap, responsive design  
- **Full-Stack**: Authentication, forms, AJAX, user experience
- **Debugging**: Intentional bugs for problem-solving assessment
- **System Design**: Scalability discussions and architecture planning
