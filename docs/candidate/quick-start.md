# Candidate Quick Start

Follow these steps to get DevTest running for your interview.

1. **Clone privately** – fork or clone the repository to a private location.
2. **Run the setup script** for your OS:
   ```bash
   ./scripts/setup.sh         # Linux
   ./scripts/setup_mac.sh     # macOS
   ./scripts/setup_windows.ps1  # Windows
   ```
   The script checks for Docker, Docker Compose, and the Dev Containers CLI,
   installing any missing tools. It also copies `.env.example` to
   `.devcontainer/.env`. You can perform these steps manually if you prefer.
3. **Start the environment**
   - `devcontainer up --workspace-folder .` *(recommended)*
   - or `docker-compose up -d` *(additional commands are required—see the full
     setup guide)*
4. **Open the app** at <http://localhost:8001> and log in at `/admin` after creating a
   superuser if needed. You can load sample data with `python manage.py seed_data`.

For full details see the [Candidate Setup Guide](../CANDIDATE_SETUP.md).

