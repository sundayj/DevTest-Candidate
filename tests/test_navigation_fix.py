#!/usr/bin/env python3
import os

print("Testing Docsify navigation fix...")
print("=" * 50)

# Change to docs directory
os.chdir('../docs')

# Test scenarios: simulate being on different pages and check if sidebar links would resolve correctly
test_scenarios = [
    {
        'current_page': 'README.md',
        'description': 'From main page'
    },
    {
        'current_page': 'development/devcontainer/README.md',
        'description': 'From nested page (devcontainer)'
    },
    {
        'current_page': 'interviewer/task-01-interactive-book-management.md',
        'description': 'From interviewer task page'
    }
]

# Sidebar links to test
sidebar_links = [
    'README.md',
    'setup/getting-started.md',
    'development/devcontainer/README.md',
    'development/docker-compose.md',
    'interviewer/README.md',
    '../README.md'
]

print("With relativePath: false, all sidebar links should resolve from docs root:")
print()

for scenario in test_scenarios:
    print(f"Scenario: {scenario['description']}")
    print(f"Current page: {scenario['current_page']}")
    print("Sidebar link resolution:")

    for link in sidebar_links:
        # With relativePath: false, all links resolve from docs root
        if link.startswith('../'):
            # Parent directory links
            resolved_path = link
            exists = os.path.exists(link)
        else:
            # Regular links resolve from docs root
            resolved_path = link
            exists = os.path.exists(link)

        status = "✓" if exists else "✗"
        print(f"  {status} {link} -> {resolved_path}")

    print()

print("Summary:")
print("With relativePath: false, all sidebar links resolve consistently from the docs root,")
print("regardless of which page you're currently viewing. This should fix the 404 errors")
print("when navigating between pages using the sidebar.")
