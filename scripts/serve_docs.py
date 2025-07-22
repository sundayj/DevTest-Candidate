#!/usr/bin/env python3
"""
Simple documentation server for DevTest project.

This script serves the documentation locally using Python's built-in HTTP server.
The documentation is served using Docsify for a better user experience.
"""

import http.server
import socketserver
import webbrowser
import os
import sys
from pathlib import Path

def serve_docs(port=3000, open_browser=True):
    """
    Serve the documentation locally.

    Args:
        port (int): Port to serve on (default: 3000)
        open_browser (bool): Whether to open browser automatically (default: True)
    """
    # Get the project root directory
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    docs_dir = project_root / "docs"

    if not docs_dir.exists():
        print(f"Error: Documentation directory not found at {docs_dir}")
        sys.exit(1)

    # Change to docs directory
    os.chdir(docs_dir)

    # Create HTTP server
    handler = http.server.SimpleHTTPRequestHandler

    try:
        with socketserver.TCPServer(("0.0.0.0", port), handler) as httpd:
            print(f"📚 DevTest Documentation Server")
            print(f"🌐 Serving at: http://localhost:{port}")
            print(f"📁 Directory: {docs_dir}")
            print(f"🔍 Features: Search, Copy Code, Zoom Images")
            print(f"⏹️  Press Ctrl+C to stop")
            print("-" * 50)

            # Open browser if requested
            if open_browser:
                webbrowser.open(f"http://localhost:{port}")

            # Start serving
            httpd.serve_forever()

    except KeyboardInterrupt:
        print("\n👋 Documentation server stopped")
    except OSError as e:
        if e.errno == 48:  # Address already in use
            print(f"❌ Error: Port {port} is already in use")
            print(f"💡 Try a different port: python scripts/serve_docs.py --port {port + 1}")
        else:
            print(f"❌ Error starting server: {e}")
        sys.exit(1)

def main():
    """Main function with command line argument parsing."""
    import argparse

    parser = argparse.ArgumentParser(
        description="Serve DevTest documentation locally",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python scripts/serve_docs.py                    # Serve on port 3000
  python scripts/serve_docs.py --port 8080       # Serve on port 8080
  python scripts/serve_docs.py --no-browser      # Don't open browser
        """
    )

    parser.add_argument(
        "--port", "-p",
        type=int,
        default=3000,
        help="Port to serve on (default: 3000)"
    )

    parser.add_argument(
        "--no-browser",
        action="store_true",
        help="Don't open browser automatically"
    )

    args = parser.parse_args()

    serve_docs(port=args.port, open_browser=not args.no_browser)

if __name__ == "__main__":
    main()
