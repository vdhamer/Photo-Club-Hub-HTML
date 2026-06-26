#!/bin/sh
# preview.sh — HTTP/1.1 keep-alive replacement for `ignite run --preview`.
#
# Why: `ignite run` serves the site with `python3 -m http.server`, which speaks
# HTTP/1.0 and closes the connection after every response. Safari pools/pre-opens
# connections and can reuse one the server has already closed, so a navigation
# request returns 0 bytes and Safari waits out a ~29s timeout before retrying.
# A keep-alive server keeps those pooled connections valid, eliminating the stall.
# (See the project memory note on the /clubs navigation delay.)
#
# Usage:
#   ./preview.sh [directory] [port]    # defaults: the sandbox container Build/, port 8000
# Lives in the Photo Club Hub HTML module; serves the published site in the app's
# sandbox container, so it works from any current directory. Press Ctrl-C to stop.

set -eu

# The app (sandboxed) publishes the site here; this is the same Build/ that
# `ignite run` serves when launched from the container's Data directory.
DEFAULT_DIR="$HOME/Library/Containers/com.vdHamer.Photo-Club-Hub-HTML/Data/Build"

DIR="${1:-$DEFAULT_DIR}"
PORT="${2:-8000}"

if [ ! -d "$DIR" ]; then
  echo "❌ No Build directory at:" >&2
  echo "   $DIR" >&2
  echo "   Generate the site first, or pass a path:  ./preview.sh path/to/Build" >&2
  exit 1
fi

# Free the port if a previous server (ignite run or a past preview.sh) still holds it.
lsof -ti "tcp:$PORT" | xargs kill 2>/dev/null || true

echo "✅ Serving '$DIR'"
echo "   at http://localhost:$PORT (HTTP/1.1 keep-alive). Press Ctrl-C to stop."

# Open the browser once the server is actually listening.
( sleep 1; open "http://localhost:$PORT" ) &

# Pass the absolute dir to the handler (don't cd): the handler resolves it per
# request, so a `generate website` that deletes and recreates Build/ won't leave
# the server stuck on a now-gone working directory (os.getcwd() FileNotFoundError).
exec python3 -c 'import sys, functools
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler as Handler
Handler.protocol_version = "HTTP/1.1"   # persistent connections — no close-after-each
handler = functools.partial(Handler, directory=sys.argv[2])
ThreadingHTTPServer(("", int(sys.argv[1])), handler).serve_forever()' "$PORT" "$DIR"
