#!/usr/bin/env python3
"""Serve the saved design prototype on loopback; never launch the native app."""

import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


ROOT = Path(__file__).resolve().parent
REQUIRED = (
    "simplify-evidence.html", "prototype.js", "prototype.css", "inventory.js",
    "icon-comparison.html", "skillsbar-icon-concept.png",
    "skillsbar-menubar-template.svg", "tessl-wordmark.png",
)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=8769)
    parser.add_argument("--check", action="store_true", help="Check saved files only")
    args = parser.parse_args()
    missing = [name for name in REQUIRED if not (ROOT / name).is_file()]
    if missing:
        parser.error("Missing prototype assets: " + ", ".join(missing))
    if args.check:
        print(f"PASS: all {len(REQUIRED)} required prototype files are present")
        return
    handler = partial(SimpleHTTPRequestHandler, directory=str(ROOT))
    try:
        server = ThreadingHTTPServer(("127.0.0.1", args.port), handler)
    except OSError as error:
        parser.exit(1, f"Cannot start prototype server: {error}\n"
                    "A server may already be running. Try the saved URL, or use --port 8770.\n")
    print(f"Guided evidence: http://127.0.0.1:{args.port}/simplify-evidence.html?v=3", flush=True)
    print("Local prototype only. Press Control-C to stop.", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
