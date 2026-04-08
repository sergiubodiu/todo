#!/usr/bin/env bash
# =============================================================================
# Modern plain-text todo manager
# Enhanced fzf integration
# =============================================================================

# Prevent accidental sourcing
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    echo "Error: This script should not be sourced. Run it directly with 'todo' or 't'" >&2
    return 1 2>/dev/null || exit 1
fi

set -o errexit
set -o nounset
set -o pipefail

TODO_DIR="${TODO_DIR:-$HOME/todo}"
TODO_FILE="${TODO_FILE:-$TODO_DIR/todo.txt}"
DONE_FILE="${DONE_FILE:-$TODO_DIR/done.txt}"
ARCHIVE_FILE="${ARCHIVE_FILE:-$TODO_DIR/archive.txt}"

mkdir -p "$TODO_DIR"
touch "$TODO_FILE" "$DONE_FILE" "$ARCHIVE_FILE" 2>/dev/null || true

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: todo [command]

Commands:
  ls                    List all tasks (with fzf preview)
  add, a <task>         Add new task
  do, d <number>        Mark task as done
  rm <number>           Delete task
  f, fzf                Interactive fuzzy finder (default when no args)
  pri <number> <A|B|C>  Set priority
  archive               Archive all done tasks
  edit, e               Open todo.txt in nano
  help                  Show help

Examples:
  todo                  → opens fzf interactively
  todo add "Finish report +work @computer due:2026-04-20"
  todo f +work          → fuzzy search only +work project
  todo f @errands       → fuzzy search only @errands context
EOF
}

# -----------------------------
# Interactive fzf mode (main feature)
# -----------------------------
fzf_mode() {
    local filter="$1"

    if ! command -v fzf >/dev/null 2>&1; then
        echo "fzf is not installed. Falling back to simple list."
        nl -w 2 -s '. ' "$TODO_FILE"
        return
    fi

    local preview_cmd="echo {} | sed 's/^[0-9]\+\. //' | fold -s -w 80"

    local selected
    selected=$(nl -w 2 -s '. ' "$TODO_FILE" \
        | fzf --height 70% \
              --reverse \
              --ansi \
              --prompt="todo > " \
              --header="ENTER=complete | CTRL-D=delete | CTRL-E=edit | ESC=quit" \
              --bind="enter:execute-silent($0 do {1})+reload(nl -w 2 -s '. ' $TODO_FILE)" \
              --bind="ctrl-d:execute-silent($0 rm {1})+reload(nl -w 2 -s '. ' $TODO_FILE)" \
              --bind="ctrl-e:execute($0 edit)+abort" \
              --preview="$preview_cmd" \
              --preview-window=right:50% \
              -q "$filter") || return 0
}

# -----------------------------
# Main dispatcher
# -----------------------------
case "${1:-}" in
    ""|f|fzf)
        shift
        fzf_mode "$*"
        ;;

    ls|list|l)
        if [[ -s "$TODO_FILE" ]]; then
            nl -w 2 -s '. ' "$TODO_FILE" | sed "s/+[^ ]*/${YELLOW}&${NC}/g; s/@[^ ]*/${BLUE}&${NC}/g"
        else
            echo "No active tasks. You're all caught up! 🎉"
        fi
        ;;

    add|a)
        shift
        [[ $# -eq 0 ]] && { echo "Usage: todo add \"Task +project @context\""; exit 1; }
        echo "$(date +%Y-%m-%d) $*" >> "$TODO_FILE"
        echo -e "${GREEN}✓ Task added${NC}"
        ;;

    do|d|done)
        [[ -z "${2:-}" ]] && { echo "Usage: todo do <number>"; exit 1; }
        local num=$2
        if sed -i.bak "${num}d" "$TODO_FILE" 2>/dev/null; then
            local task=$(sed -n "${num}p" "$TODO_FILE.bak" 2>/dev/null)
            echo "$(date +%Y-%m-%d) $task" >> "$DONE_FILE"
            rm -f "$TODO_FILE.bak"
            echo -e "${GREEN}✓ Task $num completed${NC}"
        else
            echo -e "${RED}✗ Invalid task number${NC}"
        fi
        ;;

    rm|del|remove)
        [[ -z "${2:-}" ]] && { echo "Usage: todo rm <number>"; exit 1; }
        sed -i.bak "${2}d" "$TODO_FILE" 2>/dev/null && rm -f "$TODO_FILE.bak"
        echo -e "${YELLOW}Task $2 deleted${NC}"
        ;;

    pri)
        [[ -z "${2:-}" || -z "${3:-}" ]] && { echo "Usage: todo pri <number> <A|B|C>"; exit 1; }
        sed -i.bak "${2}s/^/\(${3}\)/" "$TODO_FILE" 2>/dev/null && rm -f "$TODO_FILE.bak"
        echo -e "${YELLOW}Priority set to (${3}) for task $2${NC}"
        ;;

    archive|arc)
        if [[ ! -s "$DONE_FILE" ]]; then
            echo "No completed tasks to archive."
            exit 0
        fi
        cat "$DONE_FILE" >> "$ARCHIVE_FILE"
        local count=$(wc -l < "$DONE_FILE")
        > "$DONE_FILE"
        echo -e "${GREEN}✓ Archived $count task(s)${NC}"
        ;;

    edit|e)
        ${EDITOR:-nano} "$TODO_FILE"
        ;;

    help|-h|--help)
        usage
        ;;

    *)
        echo "Unknown command: $1"
        usage
        exit 1
        ;;
esac