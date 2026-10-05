#!/bin/bash
# bs.sh - personal static site build pipeline
#
# usage:
#   ./bs.sh build <file>   process one dropped file
#   ./bs.sh watch          watch the folder and build files as they arrive
#   ./bs.sh install        run watch in the background via launchd, at every login
#   ./bs.sh uninstall      stop and remove the launchd agent

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

    # a page that's already in the repo is being edited, not added
    local verb=add
    if git -C "$SITE_DIR" ls-files --error-unmatch "$html_path" >/dev/null 2>&1; then
        verb=update
    fi

    if ! git -C "$SITE_DIR" add "$html_path" >>"$LOG_FILE" 2>&1; then
        log "ERROR git add failed: $file"
        return 1
    fi

    # unchanged page (e.g. re-saving after a failed push): skip the commit but
    # still push, so an earlier unpushed commit goes out. committing with a
    # pathspec keeps anything else staged in the site repo out of the commit.
    if git -C "$SITE_DIR" diff --cached --quiet -- "$html_path"; then
        log "page unchanged, nothing to commit: $name.html"
    elif ! git -C "$SITE_DIR" commit -m "$verb $name.html" -- "$html_path" >>"$LOG_FILE" 2>&1; then
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

# install() - run watch as a launchd agent: starts at login, restarts if it dies
install() {
    mkdir -p "$(dirname "$PLIST")"
    cat >"$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>$LABEL</string>
	<key>ProgramArguments</key>
	<array>
		<string>/bin/bash</string>
		<string>$BS_DIR/bs.sh</string>
		<string>watch</string>
	</array>
	<key>EnvironmentVariables</key>
	<dict>
		<key>PATH</key>
		<string>/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin</string>
	</dict>
	<key>RunAtLoad</key>
	<true/>
	<key>KeepAlive</key>
	<true/>
	<key>StandardOutPath</key>
	<string>/dev/null</string>
	<key>StandardErrorPath</key>
	<string>$LOG_FILE</string>
</dict>
</plist>
EOF
    # reload if already installed, so re-running install picks up changes
    launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null
    launchctl bootstrap "gui/$(id -u)" "$PLIST" && echo "installed: watching $WATCH_DIR"
}

# uninstall() - stop the launchd agent and remove it
uninstall() {
    launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null
    rm -f "$PLIST"
    echo "uninstalled"
}

LABEL=com.aaronkelly.build-system
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

case "${1:-}" in
    build)
        [ $# -eq 2 ] || { echo "usage: $0 build <file>" >&2; exit 1; }
        build "$2"
        ;;
    watch)
        watch
        ;;
    install)
        install
        ;;
    uninstall)
        uninstall
        ;;
    *)
        echo "usage: $0 build <file> | watch | install | uninstall" >&2
        exit 1
        ;;
esac
