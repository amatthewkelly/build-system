# config.sh - shared settings for the build system, sourced by bs.sh (which sets BS_DIR)
# every value is overridable from the environment (used by tests)

WATCH_DIR="${WATCH_DIR:-/Users/aaronkelly/Library/Mobile Documents/com~apple~CloudDocs/writing/build-system}"
SITE_DIR="${SITE_DIR:-/Users/aaronkelly/Projects/amatthew-website}"
PAGE_DIR="${PAGE_DIR:-writing/prose}"
LOG_FILE="${LOG_FILE:-$BS_DIR/logs.txt}"
