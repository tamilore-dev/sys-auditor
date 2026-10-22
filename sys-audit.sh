#!/usr/bin/env bash
#
# Name:        sys_audit.sh
# Description: Lightweight, read-only system audit for Linux.
#              Checks storage, failed services, listening sockets,
#              and critical errors from the current boot.
# Author:      Tamilore
# Version:     1.1
# Created:     2026-10-22
# Usage:       ./sys_audit.sh [-h | --help]
# Requires:    bash, systemd (systemctl, journalctl), ss, df, awk, sudo
# Exit codes:  0 = success, 2 = unknown option
# Notes:       Read-only. sudo is used only to read the journal.

set -Eeuo pipefail

# Colors (disabled when output is not a terminal)
if [[ -t 1 ]]; then
	readonly RED=$'\033[0;31m' GREEN=$'\033[0;32m' YELLOW=$'\033[1;33m' BLUE=$'\033[0;34m' NC=$'\033[0m'
else
	readonly RED='' GREEN='' YELLOW='' BLUE='' NC=''
fi

print_header() {
	printf '\n%s============================================================%s\n' "$BLUE" "$NC"
	printf '%s  %s%s\n' "$BLUE" "$1" "$NC"
	printf '%s============================================================%s\n' "$BLUE" "$NC"
}

usage() {
	printf '\n%sUsage:%s %s [OPTIONS]\n' "$BLUE" "$NC" "$(basename "$0")"
	echo "A lightweight, read-only system audit script for Linux."
	echo
	echo "Options:"
	echo "  -h, --help     Display this help message and exit"
	echo
}

audit_storage() {
	print_header "1. Storage & Partition Usage"
	df -hT --local -x tmpfs -x devtmpfs | awk 'NR==1 {print; next} {print | "sort -k 7,7"}'
}

audit_services() {
	print_header "2. Systemd Service Status"
	local failed_units
	failed_units=$(systemctl --failed --no-legend | sort)

	if [[ -z "$failed_units" ]]; then
		printf '%s[✔] All system services are running successfully (0 failed units).%s\n' "$GREEN" "$NC"
	else
		printf '%s[✖] Failed units detected:%s\n' "$RED" "$NC"
		printf '%s\n' "$failed_units"
	fi
}

audit_network() {
	print_header "3. Network Exposure (Listening Sockets)"
	ss -tulpn | awk 'NR==1 {print; next} {print | "sort -k 5,5"}'
}

audit_logs() {
	print_header "4. Critical Errors (Current Boot)"
	local crit_logs
	local -a cmd=(journalctl -p err..emerg -b --no-pager)

	if [[ $EUID -ne 0 ]]; then
		cmd=(sudo "${cmd[@]}")
	fi

	if ! crit_logs=$("${cmd[@]}" 2>/dev/null); then
		printf '%s[!] Could not read the journal (sudo failed or not permitted).%s\n' "$YELLOW" "$NC"
		return
	fi

	if [[ -z "$crit_logs" ]]; then
		printf '%s[✔] No critical errors logged this boot.%s\n' "$GREEN" "$NC"
	else
		printf '%s[!] Recent critical/error entries found:%s\n' "$YELLOW" "$NC"
		tail -n 15 <<<"$crit_logs"
	fi
}

main() {
	case "${1:-}" in
	-h | --help)
		usage
		exit 0
		;;
	-*)
		printf '%sError: Unknown option %s%s\n' "$RED" "$1" "$NC" >&2
		usage
		exit 2
		;;
	esac

	audit_storage
	audit_services
	audit_network
	audit_logs
	printf '\n%sAudit complete!%s\n' "$GREEN" "$NC"
}

# Only run main when executed, not when sourced
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	main "$@"
fi
