#!/usr/bin/env bash
set -e

# Script to sync repository content with DevTest-Candidate repository
# Excludes specified files and creates a clean copy

# Create a temporary folder to clean content
mkdir -p /tmp/DevTest-Candidate
rsync -av --exclude-from='.syncignore' . /tmp/DevTest-Candidate

# Navigate to the temp directory
cd /tmp/DevTest-Candidate

# Remove original LICENSE.md and rename DEVTEST_CANDIDATE_LICENSE.md
rm LICENSE.md
mv DEVTEST_CANDIDATE_LICENSE.md LICENSE.md

# Check if git is already initialized
if [ ! -d ".git" ]; then
    git init
    git remote set-url origin git@github.com:sundayj/DevTest-Candidate.git
else
    git remote set-url origin git@github.com:sundayj/DevTest-Candidate.git
fi

git add .
git commit -m "Initial commit for DevTest-Candidate"
git branch -M main
git push -uf origin main
