#!/bin/sh
if [ "$GITHUB_EVENT_NAME" = "merge_group" ]; then
	exit 1
fi
