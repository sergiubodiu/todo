# Fast and beautiful plain-text todo manager for the terminal.

Built for people who love **bat**, **fzf**, and keeping things simple.

## Features

- **Checkbox style**: `[ ]` = active, `[x]` = done, `[!]` = urgent
- Beautiful output powered by **bat** (respects your `BAT_THEME` and `BAT_STYLE`)
- Interactive fuzzy finder with **fzf** (default behavior)
- Effort estimation using stars (`*`, `**`, `***`)
- Clean project (`#project`) and context (`@context`) support
- macOS and Linux compatible

## Format

```txt
# todo.txt — YYYY-MM-DD [ ] [x]=done [!]=urgent *** Task #project @context
===============================================================================
2026-04-08 [ ] **  Finish setting up new dotfiles          #dotfiles @computer
2026-04-09 [ ] *   Review monthly budget                   #finance @home
2026-04-15 [!] *** Prepare presentation for team meeting   #work
```

## Installation

1. Clone or download the script:

```bash
mkdir -p ~/bin
curl -L -o ~/bin/todo https://raw.githubusercontent.com/sergiubodiu/todo/main/todo
chmod +x ~/bin/todo
```

2. Make sure `~/bin` is in your PATH (add to your `~/.zshrc` or `~/.exports` if needed):

```bash
export PATH="$HOME/bin:$PATH"
```

3. Reload your shell:

```bash
source ~/.zshrc
```

## Usage

```bash
todo                # Open interactive fzf interface (recommended)
todo ls             # List all tasks with bat
todo add "Task description #project @context ★★"
todo do 3           # Mark task 3 as done
todo rm 5           # Delete task 5
todo urgent 2       # Mark task 2 as urgent
todo edit           # Open todo.txt in nano
todo archive        # Archive all completed tasks
```

## Recommended Aliases

Add these to your `~/.aliases`:

```bash
alias t='todo'
alias ta='todo add'
alias td='todo do'
alias trm='todo rm'
alias tu='todo urgent'
alias te='todo edit'
alias tls='todo ls'
```

## Files

- `~/todo/todo.txt` — Your active tasks
- `~/todo/done.txt` — Completed tasks (with completion date)

## Philosophy

Keep it simple.  
No databases.  
No cloud sync.  
Just a text file you can edit with `nano`, view with `bat`, and search with `fzf`.

Made for terminal lovers.

---

**Author**: Sergiu Bodiu  
**License**: MIT
