#!/bin/bash
# Convenience script to serve DevTest documentation locally

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🚀 Starting DevTest Documentation Server..."
echo "📁 Project: $PROJECT_ROOT"
echo ""

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: Python 3 is required but not found"
    echo "💡 Please install Python 3 and try again"
    exit 1
fi

# Run the documentation server
cd "$PROJECT_ROOT"
python3 scripts/serve_docs.py "$@"
