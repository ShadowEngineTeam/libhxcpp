#!/bin/bash
# traced.sh <program> [args...]
# Runs a test program so that a crash leaves a stack: on macOS under lldb,
# and on Linux under gdb when it is installed, each of which prints every
# thread's backtrace if the program crashes or traps. Exits with the
# program's own status, or 1 when it did not exit normally.

case "$RUNNER_OS" in
	macOS)
		log=$(mktemp)
		lldb --batch -o run -k "thread backtrace all" -k "quit 1" -- "$@" 2>&1 | tee "$log"
		status=$(sed -n 's/.*exited with status = \([0-9]*\).*/\1/p' "$log" | tail -n 1)
		rm -f "$log"
		exit "${status:-1}"
		;;
	Linux)
		if command -v gdb > /dev/null; then
			log=$(mktemp)
			gdb -q -batch -ex "handle SIGPIPE nostop noprint pass" -ex run -ex "thread apply all bt" \
				--args "$@" 2>&1 | tee "$log"
			if grep -q "exited normally" "$log"; then
				status=0
			else
				status=$(sed -n 's/.*exited with code \([0-9]*\).*/\1/p' "$log" | tail -n 1)
				# gdb prints the code in octal
				[ -n "$status" ] && status=$((8#$status))
			fi
			rm -f "$log"
			exit "${status:-1}"
		fi
		exec "$@"
		;;
	*)
		exec "$@"
		;;
esac
