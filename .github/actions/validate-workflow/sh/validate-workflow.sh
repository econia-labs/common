#!/bin/sh

# Ensure called action path is set.
if [ -z "$CALLED_ACTION_PATH" ]; then
  echo "::error::Called action path is not set"
  exit 1
fi

# Ensure the called action path is a directory containing a workflow template.
if [ ! -d "$CALLED_ACTION_PATH" ]; then
    echo "::error::Called action path not a directory: $CALLED_ACTION_PATH"
    exit 1
fi
if [ ! -f "$CALLED_ACTION_PATH/workflow-template.yaml" ]; then
    echo "::error::No `workflow-template.yaml` found in called action path"
    exit 1
fi

# Ensure calling workflow ref is set.
if [ -z "$CALLING_WORKFLOW_REF" ]; then
  echo "::error::Calling workflow ref is not set"
  exit 1
fi

# Extract the workflow path from the workflow ref.
WORKFLOW_PATH=$(echo "$CALLING_WORKFLOW_REF" | cut -d "@" -f 1)

# Extract the last three directories from the calling workflow path,
# representing the workflow's location in the repository.
PATH_IN_REPO=$(echo "$WORKFLOW_PATH" | grep -o '/[^/]*/[^/]*/[^/]*$')

# Extract the final directory name from the called action path.
ACTION_NAME=$(basename "$CALLING_ACTION_PATH")

# Construct the expected path in repo for the calling workflow.
EXPECTED_PATH_IN_REPO="/.github/workflows/$ACTION_NAME.yaml"

if [ "$PATH_IN_REPO" != "$EXPECTED_PATTERN" ]; then
  echo "::error::Workflow path is $PATH_IN_REPO, expected $EXPECTED_PATTERN"
  exit 1
fi