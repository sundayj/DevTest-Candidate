# Running the Project for Development

This guide explains how to start the DevTest application for development in three different ways. Pick whichever option fits your workflow and operating system. The steps below assume you have already cloned the repository and copied `.env.example` to `.devcontainer/.env`.

1. **DevContainer in VS Code or PyCharm Professional (Recommended)**
2. **Local Docker Compose**
3. **GitHub Codespaces**

See the [Getting Started guide](getting-started.md) for platform setup scripts.

## 1. DevContainer (VS Code or PyCharm)

1. **Open the project in your IDE.**
   - VS Code: click *Reopen in Container* when prompted.
   - PyCharm Professional: choose *Open in Container*.
2. The container builds and runs `uv sync` automatically. Initial migrations run as part of the build.
3. After the container starts, select the Python interpreter `./.venv/bin/python` named **Python 3.12.11 (devtest)** if your IDE does not pick it automatically.
4. Use the built‑in tasks to manage the project:
   - VS Code: <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd> → **Run Task** → choose from the list.
   - PyCharm: run configurations and *Tools → Run manage.py Task*.
5. To load seed data, run `python manage.py seed_data` inside the container terminal.

You do **not** need any `docker` or `devcontainer` CLI commands while the DevContainer is running.

## 2. Docker Compose

1. Ensure `.devcontainer/.env` exists (copy from `.env.example` if needed).
2. Install dependencies:
   ```bash
   docker-compose run web uv sync
   ```
3. Start all services:
   ```bash
   docker-compose up
   ```
4. Access the application at <http://localhost:8001>.
5. Load seed data if desired:
   ```bash
   docker-compose run web python manage.py seed_data
   ```

## 3. GitHub Codespaces

1. Clone this repository to your own GitHub account and set that copy to private.
2. On your private repository, click **Code → Codespaces → Create codespace on main**.
3. Wait for the container to build. It uses the same DevContainer configuration described above.
4. Inside the codespace, copy `.env.example` to `.devcontainer/.env` if it is missing.
5. Select the interpreter `./.venv/bin/python` if prompted.
6. Use the VS Code interface in the browser to run tasks and manage the server.
7. Seed data can be loaded in the terminal with `python manage.py seed_data`.

Codespaces requires no local Docker installation. Everything runs in the cloud.
