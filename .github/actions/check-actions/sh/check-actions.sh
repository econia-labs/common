#!/bin/sh
set -e

# Function to print exemption instructions.
print_exemption_instructions() {
	echo "If this action is not directly called by a workflow, you can skip "
	echo "this check by adding <# check-workflow: exempt> to action.yaml."
}

# Set the escape pattern for exempting actions from the check-workflow step.
ESCAPE_PATTERN="# check-workflow: exempt"

# Get the syntax required to properly call `check-workflow` action as a step.
CHECK_WORKFLOW_STEP=$(yq eval '.[0]' $ACTION_PATH/cfg/check-workflow-step.yaml)

# Check if repository even has an actions directory.
ACTIONS_DIRECTORY=.github/actions
if [ ! -d "$ACTIONS_DIRECTORY" ]; then
	echo "::error::Missing $ACTIONS_DIRECTORY"
	exit 1
fi
cd "$ACTIONS_DIRECTORY"

# Check if there are any action directories.
if [ -z "$(ls -d */ 2>/dev/null)" ]; then
	echo "::error::No action directories found in $ACTIONS_DIRECTORY"
	exit 1
fi

# Iterate over all action directories.
for ACTION_DIR in */; do
	# Change location to action directory.
	cd "$ACTION_DIR"

	# Verify there is an action.yaml file.
	if [ ! -f "action.yaml" ]; then
		echo "::error::Missing ${ACTION_DIR}action.yaml"
		exit 1
	fi

	# If there are sub-directories, verify there are none besides cfg and sh.
	if [ -n "$(ls -d */ 2>/dev/null)" ]; then
		for SUBDIR in */; do
			if [ "$SUBDIR" != "cfg/" ] && [ "$SUBDIR" != "sh/" ]; then
				echo "::error::Unexpected directory ${ACTION_DIR}${SUBDIR}"
				exit 1
			fi
		done
	fi

	# Unless the action is exempt, verify the first step is check-workflow and
	# there is a workflow-template.yaml file.
	if ! grep -q -F "$ESCAPE_PATTERN" action.yaml; then

		# Get the first element of the `runs.steps` array in `action.yaml`.
		FIRST_STEP=$(yq eval '.runs.steps[0]' action.yaml)

		# Ensure the first step in `action.yaml` is the `check-workflow`.
		if [ "$FIRST_STEP" != "$CHECK_WORKFLOW_STEP" ]; then
			ACTION="${ACTION_DIR}action.yaml"
			echo "::error::$ACTION missing check-workflow as first step"
			print_exemption_instructions
			exit 1
		fi

		# Ensure there is a template workflow file.
		if [ ! -f "workflow-template.yaml" ]; then
			echo "::error::${ACTION_DIR}workflow-template.yaml missing"
			print_exemption_instructions
			exit 1
		fi

	fi

	# Change location back to GitHub actions directory.
	cd ..
done

echo "✅ All actions valid"
