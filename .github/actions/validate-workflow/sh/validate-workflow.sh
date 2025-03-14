#!/bin/sh
set -e

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

# Download the calling workflow file from the ref.
REPO=$(echo "$CALLING_WORKFLOW_REF" | cut -d "/" -f 1-2)
FILE_PATH=$(echo "$CALLING_WORKFLOW_REF" | cut -d "@" -f 1 | cut -d "/" -f 3-)
REF=$(echo "$CALLING_WORKFLOW_REF" | cut -d "@" -f 2)
CALLING_WORKFLOW=downloaded_workflow.yaml
URL="https://raw.githubusercontent.com/$REPO/$REF/$FILE_PATH"
curl -sSL -o $CALLING_WORKFLOW $URL
if [ ! -s "$CALLING_WORKFLOW" ]; then
    echo "::error::Failed to download workflow file from $URL"
    exit 1
fi

# Extract the final directory name from the called action path.
ACTION_NAME=$(basename "$CALLED_ACTION_PATH")

# Construct the expected file path in the repo for the calling workflow.
EXPECTED_FILE_PATH=".github/workflows/$ACTION_NAME.yaml"

# Ensure the calling workflow path matches the expected path.
if [ "$FILE_PATH" != "$EXPECTED_FILE_PATH" ]; then
	echo "::error::Workflow path is $FILE_PATH, expected $EXPECTED_FILE_PATH"
	exit 1
fi
echo "Calling workflow file path: $FILE_PATH"

# Ensure workflow file matches workflow template.
if ! diff -q "$CALLING_WORKFLOW" "$WORKFLOW_TEMPLATE_FILE" >/dev/null; then
	echo "::error::Calling workflow does not match workflow template"
	diff "$CALLING_WORKFLOW" "$WORKFLOW_TEMPLATE_FILE"
	exit 1
fi
