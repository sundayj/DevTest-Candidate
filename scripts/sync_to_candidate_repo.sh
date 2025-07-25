#!/usr/bin/env bash
set -e

# Script to sync repository content with DevTest-Candidate repository
# Excludes specified files and creates a clean copy

# Create a temporary folder to clean content
mkdir -p /tmp/DevTest-Candidate
rsync -av --exclude-from='.syncignore' . /tmp/DevTest-Candidate

# Navigate to the temp directory
cd /tmp/DevTest-Candidate

# Remove interviewer-specific content from documentation files
echo "🔧 Removing interviewer-specific content..."

# Remove interviewer section from README.md
sed -i '/### For Interviewers/,/### For Candidates/{ /### For Candidates/!d; }' README.md

# Remove interviewer section from sidebar
sed -i '/\* 👨‍💼 \*\*Interviewer Resources\*\*/,/^$/d' docs/_sidebar.md

# Candidate README already contains the same instructions as interviewer docs

# Note: CANDIDATE_SETUP.md interviewer references are acceptable and left unchanged

# Remove original LICENSE.md and rename DEVTEST_CANDIDATE_LICENSE.md
rm LICENSE.md
mv DEVTEST_CANDIDATE_LICENSE.md LICENSE.md

GIT_URL="https://${GH_PAT}@github.com/sundayj/DevTest-Candidate.git"

# Check if git is already initialized
if [ ! -d ".git" ]; then
    git init
    git branch -M main
    git remote add origin "$GIT_URL"
else
    git remote set-url origin "$GIT_URL"
fi

# Configure default Git user for commits
git config user.name "GitHub Actions Bot"
git config user.email "actions@github.com"

git add .
git commit -m "Initial commit for DevTest-Candidate"
git push -uf origin main
