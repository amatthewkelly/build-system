#!/bin/bash
# bs.sh - personal static site build pipeline
#
# usage:
#   ./bs.sh build <file>   process one dropped file
#   ./bs.sh watch          watch the folder and build files as they arrive
#
# run watch in the background yourself, e.g.:
#   nohup ./bs.sh watch &
#
# TODO: switch from nohup to launchd for boot persistence
# as of now bs.sh will need to be run after each boot for folder watching

set -u

BS_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BS_DIR/config.sh"

# log() - append a timestamped line to the log file, and echo it too
log() {
    local line
    line="$(date '+%Y-%m-%d %H:%M:%S') $1"
    echo "$line" >>"$LOG_FILE"
    echo "$line"
}

# build() - turn one dropped .txt file into a page, publish it, archive the source
build() {
    local file="$1"
    local base name html_path

    # not a real file, or already filed away in built/ - nothing to do
    [ -f "$file" ] || return 0
    case "$file" in
        */built/*) return 0 ;;
    esac

    base="${file##*/}"

    # skip hidden files (e.g. .DS_Store) quietly
    case "$base" in
        .*) return 0 ;;
    esac

    case "$file" in
        *.txt) ;;
        *)
            log "WARN ignoring non-text file: $file"
            return 0
            ;;
    esac

    name="${base%.txt}"

    if ! html_path="$(python3 "$BS_DIR/build.py" "$file" "$SITE_DIR/$PAGE_DIR" 2>>"$LOG_FILE")"; then
        log "ERROR build failed: $file"
        return 1
    fi

    if ! git -C "$SITE_DIR" add "$html_path" >>"$LOG_FILE" 2>&1; then
        log "ERROR git add failed: $file"
        return 1
    fi
    if ! git -C "$SITE_DIR" commit -m "add $name.html" >>"$LOG_FILE" 2>&1; then
        log "ERROR git commit failed: $file"
        return 1
    fi
    if ! git -C "$SITE_DIR" push >>"$LOG_FILE" 2>&1; then
        log "ERROR git push failed: $file"
        return 1
    fi

    mkdir -p "$WATCH_DIR/built"
    mv "$file" "$WATCH_DIR/built/"
    log "OK built $name.html"
}

# watch() - build whatever is already sitting in the folder, then keep watching
watch() {
    local f

    for f in "$WATCH_DIR"/*; do
        [ -e "$f" ] || continue
        build "$f"
    done

    log "watching $WATCH_DIR"

    fswatch -0 --event Created --event Updated --event Renamed "$WATCH_DIR" |
        while IFS= read -r -d '' path; do
            build "$path"
        done
}

case "${1:-}" in
    build)
        [ $# -eq 2 ] || { echo "usage: $0 build <file>" >&2; exit 1; }
        build "$2"
        ;;
    watch)
        watch
        ;;
    *)
        echo "usage: $0 build <file> | watch" >&2
        exit 1
        ;;
esac
