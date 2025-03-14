#!/bin/sh

# Ensure called action path is set.
if [ -z "$CALLED_ACTION_PATH" ]; then
	echo "::error::Called action path is not set"
	exit 1
fi

# Ensure the called action path is a directory.
if [ ! -d "$CALLED_ACTION_PATH" ]; then
	echo "::error::Called action path not a directory: $CALLED_ACTION_PATH"
	exit 1
fi
echo "Called action path: $CALLED_ACTION_PATH"

# Ensure the called action path contains a workflow template.
WORKFLOW_TEMPLATE_FILE="$CALLED_ACTION_PATH/workflow-template.yaml"
if [ ! -f "$WORKFLOW_TEMPLATE_FILE" ]; then
	echo "::error::No workflow-template.yaml file in called action path"
	exit 1
fi
echo "Workflow template file: $WORKFLOW_TEMPLATE_FILE"

# Ensure calling workflow ref is set.
if [ -z "$CALLING_WORKFLOW_REF" ]; then
	echo "::error::Calling workflow ref is not set"
	exit 1
fi
echo "Calling workflow ref: $CALLING_WORKFLOW_REF"

# Extract the full calling workflow path from the workflow ref.
CALLING_WORKFLOW_PATH=$(echo "$CALLING_WORKFLOW_REF" | cut -d "@" -f 1)
echo "Calling workflow path: $CALLING_WORKFLOW_PATH"

# Extract the last three directories from the calling workflow path,
# representing the workflow's location in the repository.
REPO_PATH=$(echo "$CALLING_WORKFLOW_PATH" | grep -o '/[^/]*/[^/]*/[^/]*$')

# Extract the final directory name from the called action path.
ACTION_NAME=$(basename "$CALLED_ACTION_PATH")

# Construct the expected path in the repo for the calling workflow.
EXPECTED_REPO_PATH="/.github/workflows/$ACTION_NAME.yaml"

# Ensure the calling workflow path matches the expected path.
if [ "$REPO_PATH" != "$EXPECTED_REPO_PATH" ]; then
	echo "::error::Workflow path is $REPO_PATH, expected $EXPECTED_REPO_PATH"
	exit 1
fi
echo "Calling workflow repo path: $REPO_PATH"

# Ensure GitHub workspace is set.
if [ -z "$GITHUB_WORKSPACE" ]; then
	echo "::error::GitHub workspace is not set"
	exit 1
fi
echo "GitHub workspace: $GITHUB_WORKSPACE"
echo "GitHub workspace contents:"
ls -l "$GITHUB_WORKSPACE"

# Construct the full path to the calling workflow on the runner.
WORKFLOW_FILE="${GITHUB_WORKSPACE}${REPO_PATH}"

# Ensure the workflow file exists.
if [ ! -f "$WORKFLOW_FILE" ]; then
	echo "::error::Workflow file not found: $WORKFLOW_FILE"
	exit 1
fi

# Ensure workflow file matches workflow template.
if !diff -q "$WORKFLOW_FILE" "$WORKFLOW_TEMPLATE_FILE" >/dev/null; then
	echo "::error::Calling workflow does not match workflow template"
	diff "$WORKFLOW_FILE" "$WORKFLOW_TEMPLATE_FILE"
	exit 1
fi
