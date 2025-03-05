#!/bin/sh
if [ "$GITHUB_EVENT_NAME" = "pull_request" ]; then
  exit 1
fi