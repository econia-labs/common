#!/bin/sh

# Ensure calling action path is set.
if [ -z "$CALLING_ACTION_PATH" ]; then
  echo "::error::Calling action path is not set"
  exit 1
fi

# Ensure the calling action path is a directory containing a workflow template.
if [ ! -d "$CALLING_ACTION_PATH" ]; then
    echo "::error::Calling action path not a directory: $CALLING_ACTION_PATH"
    exit 1
fi
if [ ! -f "$CALLING_ACTION_PATH/workflow-template.yaml" ]; then
    echo "::error::No `workflow-template.yaml` file found in action path"
    exit 1
fi

# Ensure calling workflow ref is set.
if [ -z "$CALLING_WORKFLOW_REF" ]; then
  echo "::error::Calling workflow ref is not set"
  exit 1
fi
echo "$CALLING_WORKFLOW_REF"

