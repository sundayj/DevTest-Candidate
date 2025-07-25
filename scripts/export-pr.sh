#!/bin/bash

# ========= FUNCTION DEFINITIONS =========

function export_pr() {
  local PR=$1
  local OUT=$2
  local FORMAT=$3
  local REPO=$4

  case "$FORMAT" in
    json)
      gh pr view "$PR" --repo "$REPO" \
        --json number,title,author,createdAt,updatedAt,state,body,commits,comments,reviews > "$OUT"
      ;;
    txt)
      {
        echo "===== PR #$PR - TEXT EXPORT ====="
        gh pr view "$PR" --repo "$REPO" \
          --template 'PR #{{.number}} - {{.title}}
Author: {{.author.login}} | State: {{.state}}
Created: {{.createdAt}} | Updated: {{.updatedAt}}

--- BODY ---

{{.body}}

'
        echo "===== COMMITS ====="
        gh pr view "$PR" --repo "$REPO" --json commits \
          --template '{{range .commits}}{{.oid}} - {{.messageHeadline}} (by {{.author.name}})
{{end}}'
        echo "===== COMMENTS ====="
        gh pr view "$PR" --repo "$REPO" --json comments \
          --template '{{range .}}{{.author.login}}: {{.body}}
---{{end}}'
        echo "===== REVIEW THREADS ====="
        gh pr view "$PR" --repo "$REPO" --json reviews \
          --template '{{range .reviews}}
Review by {{.author.login}} - {{.state}} - Submitted at {{.submittedAt}}
{{.body}}
{{range .comments}}  [{{.path}} @ line {{.position}}] {{.body}} (by {{.author.login}})
{{end}}
---{{end}}'
      } > "$OUT"
      ;;
    md)
      {
        echo "# PR #$PR"
        gh pr view "$PR" --repo "$REPO" \
          --template '## {{.title}}
**Author**: {{.author.login}}
**State**: {{.state}}
**Created**: {{.createdAt}}
**Updated**: {{.updatedAt}}

---

### Body

{{.body}}

'
        echo -e "\n---\n\n### Commits\n"
        gh pr view "$PR" --repo "$REPO" --json commits \
          --template '{{range .commits}}- `{{.oid}}`: {{.messageHeadline}} (by {{.author.name}})
{{end}}'
        echo -e "\n---\n\n### Comments\n"
        gh pr view "$PR" --repo "$REPO" --json comments \
          --template '{{range .}}- **{{.author.login}}**: {{.body}}
{{end}}'
        echo -e "\n---\n\n### Review Threads\n"
        gh pr view "$PR" --repo "$REPO" --json reviews \
          --template '{{range .reviews}}
#### Review by {{.author.login}} — **{{.state}}** — _{{.submittedAt}}_

{{.body}}

{{range .comments}}> **File**: `{{.path}}`, **Line**: `{{.position}}`
> {{.body}} _(by {{.author.login}})_

{{end}}---{{end}}'
      } > "$OUT"
      ;;
  esac
}

# ========= MAIN SCRIPT LOGIC =========

FORMAT="${1:-json}"
STATE="${2:-open}"
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
EXPORT_DIR="pr_exports"

# Validate format
if [[ ! "$FORMAT" =~ ^(json|txt|md)$ ]]; then
  echo "❌ Unsupported format: $FORMAT"
  echo "Usage: $0 [json|txt|md] [open|closed|merged]"
  exit 1
fi

# Validate state
if [[ ! "$STATE" =~ ^(open|closed|merged)$ ]]; then
  echo "❌ Unsupported PR state: $STATE"
  echo "Usage: $0 [json|txt|md] [open|closed|merged]"
  exit 1
fi

# Ensure output directory exists
mkdir -p "$EXPORT_DIR"

# Fetch PRs
echo "🔍 Fetching $STATE PRs from $REPO..."
PR_JSON=$(gh pr list --repo "$REPO" --state "$STATE" --json number,title)

if [[ -z "$PR_JSON" || "$PR_JSON" == "[]" ]]; then
  echo "✅ No $STATE PRs found."
  exit 0
fi

PR_LIST=$(echo "$PR_JSON" | jq -r '.[].number')

# Open PRs: export all
if [[ "$STATE" == "open" ]]; then
  for PR in $PR_LIST; do
    OUT="$EXPORT_DIR/pr-$PR.$FORMAT"
    echo "➡ Exporting PR #$PR to $OUT..."
    export_pr "$PR" "$OUT" "$FORMAT" "$REPO"
    echo "✅ Done: $OUT"
  done
  echo "🎉 All open PRs exported to: $EXPORT_DIR/"
  exit 0
fi

# Closed/Merged: prompt user
echo -e "\n📋 Available $STATE PRs:\n"
INDEX=1
declare -A PR_MAP
while IFS=$'\n' read -r line; do
  PR_NUM=$(echo "$line" | jq -r '.number')
  PR_TITLE=$(echo "$line" | jq -r '.title')
  echo "  [$INDEX] #$PR_NUM - $PR_TITLE"
  PR_MAP[$INDEX]=$PR_NUM
  INDEX=$((INDEX+1))
done < <(echo "$PR_JSON" | jq -c '.[]')

echo -e "\nEnter the number of the PR you'd like to export:"
read -rp "> " SELECTED_INDEX

PR_NUMBER=${PR_MAP[$SELECTED_INDEX]}

if [[ -z "$PR_NUMBER" ]]; then
  echo "❌ Invalid selection."
  exit 1
fi

OUT="$EXPORT_DIR/pr-$PR_NUMBER.$FORMAT"
echo "➡ Exporting PR #$PR_NUMBER to $OUT..."
export_pr "$PR_NUMBER" "$OUT" "$FORMAT" "$REPO"
echo "✅ Done: $OUT"
