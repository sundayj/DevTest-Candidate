# Use the stable Python 3.12 dev container image. The previous tag
# `0-3.12` no longer resolves from the registry.
FROM mcr.microsoft.com/devcontainers/python:3.12

# Install uv package manager
RUN pip install --no-cache-dir uv

# Pre-install common dependencies system-wide. The base image does not
# create a virtual environment by default, so install packages into the
# system interpreter using `--system` to avoid build failures.
RUN uv pip install --system celery uvicorn django python-dotenv psycopg2-binary redis

# Copy the single .env file to the container
COPY .env /workspace/.env
