#!/usr/bin/env bash
# =============================================================================
# Modern plain-text todo manager
# Enhanced with fzf and bat
# =============================================================================

# Prevent accidental sourcing
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    echo "Error: This script should be executed, not sourced. Use 'todo' or 't'." >&2
    return 1 2>/dev/null || exit 1
fi

set -o errexit
set -o nounset
set -o pipefail

TODO_DIR="${TODO_DIR:-$HOME/todo}"
TODO_FILE="${TODO_FILE:-$TODO_DIR/todo.txt}"
DONE_FILE="${DONE_FILE:-$TODO_DIR/done.txt}"

mkdir -p "$TODO_DIR"
touch "$DONE_FILE" 2>/dev/null || true

# Create todo.txt with header if empty
if [[ ! -s "$TODO_FILE" ]]; then
    cat > "$TODO_FILE" << 'EOF'
# todo.txt — YYYY-MM-DD [ ] [x]=done [!]=urgent *** Task #project @context
===============================================================================
2026-04-08 [ ] **  Finish setting up new dotfiles          #dotfiles @computer
2026-04-09 [ ] *   Review monthly budget                   #finance @home
2026-04-15 [!] *** Prepare presentation for team meeting   #work
2026-04-10 [ ] *   Buy groceries                           #errands @supermarket
2026-04-08 [ ] **  Backup important documents              #backup
EOF
    echo -e "\033[0;32m✓ Created todo.txt with header and examples\033[0m"
fi

# =============================================================================
# Functions
# =============================================================================

add_task() {
    # Remove the first argument ("add" or "a") if present
    if [[ "$1" == "add" || "$1" == "a" ]]; then
        shift
    fi

    if [[ $# -eq 0 ]]; then
        echo "Usage: todo add \"Task #project @context ★\""
        return 1
    fi

    local task="$*"
    local complexity="  "   # default padding (for no stars)

    # Detect complexity stars only if they are at the very end
    if [[ "$task" =~ \*\*\*$ ]]; then
        complexity="***"
        task="${task%\*\*\*}"
    elif [[ "$task" =~ \*\*$ ]]; then
        complexity=" **"
        task="${task%\*\*}"
    elif [[ "$task" =~ \*[[:space:]]*$ || "$task" =~ \*$ ]]; then
        complexity="  *"
        task="${task%\*}"
    fi

    # Trim trailing whitespace
    task="${task%"${task##*[![:space:]]}"}"

    # Add the task with proper formatting: date [ ]   complexity   Task ...
    echo "$(date +%Y-%m-%d) [ ] $complexity  $task" >> "$TODO_FILE"
    echo -e "\033[0;32m✓ Task added\033[0m"
}

# Mark task as done ([ ] or [!] → [x]) — only marks, does not move
do_task() {
    local num="$1"

    if [[ -z "$num" ]]; then
        echo "Usage: todo do <number>"
        return 1
    fi

    if ! [[ "$num" =~ ^[0-9]+$ ]]; then
        echo -e "\033[0;31m✗ Task number must be a positive integer\033[0m"
        return 1
    fi

    # Skip 2 header lines
    local real_line=$((num + 2))

    if sed -i '' "${real_line}s/\[.\]/[x]/" "$TODO_FILE" 2>/dev/null; then
        echo -e "\033[0;32m✓ Task $num marked as done\033[0m"
    else
        echo -e "\033[0;31m✗ Failed to mark task $num as done\033[0m"
        return 1
    fi
}

rm_task() {
    local num="$1"
    if [[ -z "$num" ]]; then
        echo "Usage: todo rm <number>"
        return 1
    fi

    if ! [[ "$num" =~ ^[0-9]+$ ]]; then
        echo -e "\033[0;31m✗ Task number must be a positive integer\033[0m"
        return 1
    fi

    local real_line=$((num + 2))

    if sed -i '' "${real_line}d" "$TODO_FILE" 2>/dev/null; then
        echo -e "\033[0;33mTask $num deleted\033[0m"
    else
        echo -e "\033[0;31m✗ Failed to delete task $num\033[0m"
        return 1
    fi
}

usage() {
    cat <<EOF
Usage: todo [command]

  ls         List tasks using bat
  add <task> Add new task
  do <num>   Mark task as done
  rm <num>   Delete task
  urgent <num> Mark as urgent
  edit       Open todo.txt in nano
  help       Show help

No arguments = open fzf interactively
EOF
}

case "${1:-}" in
    "")
        # Default: fzf
        if command -v fzf >/dev/null 2>&1; then
            tail -n +3 "$TODO_FILE" | nl -w 3 -s '  ' \
                | fzf --height 75% --reverse --ansi \
                    --prompt="todo > " \
                    --header="ENTER=mark done  CTRL-D=delete  CTRL-E=edit" \
                    --bind="enter:execute-silent(todo do {1})+reload(tail -n +3 $TODO_FILE | nl -w 3 -s '  ')" \
                    --bind="ctrl-d:execute-silent(todo rm {1})+reload(tail -n +3 $TODO_FILE | nl -w 3 -s '  ')" \
                    --bind="ctrl-e:execute(todo edit)+abort" \
                    --preview="echo {} | sed 's/^[0-9 ]\+//' | bat " \
                    --preview-window=right:60%
        else
            bat "$TODO_FILE"
        fi
        ;;

    ls|list|l)
        bat "$TODO_FILE"
        ;;

    add|a)
        add_task "$@"
        ;;

    do|d|done)
        do_task "$2"
        ;;

    rm|del)
        rm_task "$2"
        ;;

    urgent|!)
        [[ -z "${2:-}" ]] && { echo "Usage: todo urgent <number>"; exit 1; }
        local real_line=$((2 + 2))
        sed -i '' "${real_line}s/\[ \]/[!]/" "$TODO_FILE" 2>/dev/null
        echo -e "\033[0;31m[!] Task $2 marked as urgent\033[0m"
        ;;

    edit|e)
        ${EDITOR:-nano} "$TODO_FILE"
        ;;

    archive|arc)
        if ! grep -q '^\[x\]' "$TODO_FILE" 2>/dev/null; then
            echo "No completed tasks to archive."
            exit 0
        fi
        grep '^\[x\]' "$TODO_FILE" >> "$DONE_FILE"
        sed -i '' '/^\[x\]/d' "$TODO_FILE"
        echo -e "\033[0;32m✓ Archived all completed tasks\033[0m"
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
