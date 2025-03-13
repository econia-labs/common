#!/bin/sh

# Ensure Calling action path is set.
if [ -z "$CALLING_ACTION_PATH" ]; then
  echo "::error::Calling action path is not set"
  exit 1
fi
