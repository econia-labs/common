#!/bin/sh
set -e

# Get the name of the action that the workflow is calling.
ACTION_NAME=$(basename "$ACTION_PATH")

# Construct the expected workflow path.
EXPECTED_PATH=".github/workflows/$ACTION_NAME.yaml"

# Ensure the workflow path matches the expected path.
if [ "$WORKFLOW_PATH" != "$EXPECTED_PATH" ]; then
	echo "::error::Workflow at $WORKFLOW_PATH, expected $EXPECTED_PATH"
	exit 1
fi

# Construct the workflow template path.
WORKFLOW_TEMPLATE_PATH="$ACTION_PATH/workflow-template.yaml"

# Get the workflow path inside the GitHub workspace.
WORKFLOW_LOCAL_PATH="$GITHUB_WORKSPACE/$WORKFLOW_PATH"

# Ensure workflow matches workflow template.
if ! diff -q "$WORKFLOW_LOCAL_PATH" "$WORKFLOW_TEMPLATE_PATH" >/dev/null; then
	echo "::error::$WORKFLOW_PATH does not match template, see diff below:"
	diff "$WORKFLOW_LOCAL_PATH" "$WORKFLOW_TEMPLATE_PATH"
	exit 1
fi

echo "✅ Valid workflow"
