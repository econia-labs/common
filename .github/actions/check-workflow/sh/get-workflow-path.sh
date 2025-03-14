# Get the path of the workflow from the workflow ref.
WORKFLOW_PATH=$(echo "$WORKFLOW_REF" | cut -d "@" -f 1 | cut -d "/" -f 3-)
echo "Workflow path: $WORKFLOW_PATH"
echo "workflow_path=$WORKFLOW_PATH" >>$GITHUB_OUTPUT