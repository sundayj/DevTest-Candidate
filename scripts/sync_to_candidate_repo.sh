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

GIT_URL="https://${GH_PAT}@github.com/sundayj/DevTest-Candidate.git"
BRANCH_NAME="sync-$(date +%Y%m%d-%H%M%S)"

# Check if git is already initialized
if [ ! -d ".git" ]; then
    git init
    git checkout -b "$BRANCH_NAME"
    git remote add origin "$GIT_URL"
else
    git remote set-url origin "$GIT_URL"
    git checkout -b "$BRANCH_NAME" || git checkout "$BRANCH_NAME"
fi

# Configure default Git user for commits
git config user.name "GitHub Actions Bot"
git config user.email "actions@github.com"

git add .
git commit -m "Sync from DevTest source"
git push -u origin "$BRANCH_NAME"

# Create pull request and request review
PR_RESPONSE=$(curl -s -H "Authorization: token ${GH_PAT}" \
    -H "Accept: application/vnd.github+json" \
    -d "{\"title\":\"Sync from DevTest\",\"head\":\"$BRANCH_NAME\",\"base\":\"main\"}" \
    https://api.github.com/repos/sundayj/DevTest-Candidate/pulls)

PR_NUMBER=$(echo "$PR_RESPONSE" | jq -r '.number')

curl -s -X POST -H "Authorization: token ${GH_PAT}" \
    -H "Accept: application/vnd.github+json" \
    -d "{\"reviewers\":[\"sundayj\"]}" \
    https://api.github.com/repos/sundayj/DevTest-Candidate/pulls/${PR_NUMBER}/requested_reviewers

echo "Pull request #$PR_NUMBER created."
