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

# Remove interviewer references from candidate README
sed -i '/## What'\''s Different from Interviewer Versions/,/## Usage Instructions/{ /## Usage Instructions/!d; }' docs/candidate/README.md
sed -i '/### For Interviewers/,/## Getting Started/{ /## Getting Started/!d; }' docs/candidate/README.md
sed -i 's/Choose the task(s) assigned to you by your interviewer/Choose the task(s) assigned to you/' docs/candidate/README.md
sed -i 's/candidate-friendly versions of the DevTest interview tasks. These versions have been specifically designed for candidates and exclude implementation details, evaluation criteria, and other interviewer-specific content./the DevTest interview tasks designed for candidates./' docs/candidate/README.md

# Note: CANDIDATE_SETUP.md interviewer references are acceptable and left unchanged

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
