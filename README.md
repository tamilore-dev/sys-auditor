# sys-auditor

A lightweight, read-only system audit script for Linux, written in Bash.

It makes no changes to your system. It only reads and reports.

## What it checks

| # | Check | Tool used |
|---|---|---|
| 1 | Storage and partition usage | `df` |
| 2 | Failed systemd services | `systemctl` |
| 3 | Listening network sockets (TCP and UDP) | `ss` |
| 4 | Critical errors from the current boot | `journalctl` |

Output is color-coded in the terminal: green for healthy, yellow for warnings, red for failures. Colors turn off automatically when you redirect output to a file.

## Requirements

- A systemd-based Linux distro (Fedora, Ubuntu, Debian, Rocky, Arch, etc.)
- Bash 4+
- GNU coreutils (`df`) and `iproute2` (`ss`), preinstalled on most distros
- `sudo` access (only used to read the system journal)

Not supported: distros without systemd (e.g. Alpine).

## Installation

```bash
git clone https://github.com/tamilore-dev/sys-auditor.git
cd sys-auditor
chmod +x sys_audit.sh
```

## Usage

```bash
./sys_audit.sh                 # run the full audit
./sys_audit.sh --help          # show help
./sys_audit.sh > report.txt    # save a plain-text report
```

## Exit codes

| Code | Meaning |
|---|---|
| 0 | Success |
| 2 | Unknown option |

## How it works

- `set -Eeuo pipefail` makes the script stop on errors and unset variables.
- Each check is its own function, so checks are easy to add or remove.
- `main` only runs when the script is executed, not when it is sourced.
- If the journal can't be read, the script warns instead of reporting a false "all clear".

## Testing

```bash
shellcheck sys_audit.sh
```

## License

MIT License. See the [LICENSE](LICENSE) file.

## Author

Tamilore, [@tamilore-dev](https://github.com/tamilore-dev)
