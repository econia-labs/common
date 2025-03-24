#!/bin/sh
if [ -z "$MAX_LINES_ADDED" ]; then
	echo "Error: max_lines_added is not set"
	exit 1
fi
if [ -z "$MAX_LINES_REMOVED" ]; then
	echo "Error: max_lines_removed is not set"
	exit 1
fi
if [ -z "$N_OVERRIDE_APPROVALS" ]; then
	echo "Error: n_override_approvals is not set"
	exit 1
fi
echo "All required inputs are properly set"
