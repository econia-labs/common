#!/bin/sh
set -e

# Get the syntax required to properly call `check-workflow` action.
CHECK_WORKFLOW_STEP=$(yq eval '.[0]' $ACTION_PATH/cfg/check-workflow-step.yaml)

# Function to print exemption instructions
print_exemption_instructions() {
	echo "If this action is not directly called by a workflow, you can skip "
	echo "this check by adding <# check-workflow: exempt> to action.yaml."
}

# Change location to GitHub actions directory.
cd .github/actions

# Iterate over all action directories.
for ACTION_DIR in */; do
	# Change location to action directory.
	cd "$ACTION_DIR"

	# Verify there are no sub-directories other than cfg and sh.
	for DIR in */; do
		if [ "$DIR" != "cfg/" ] && [ "$DIR" != "sh/" ]; then
            echo "::error::$ACTION_DIR"
			echo "::error::Unexpected directory $DIR"
			exit 1
		fi
	done

	# Verify there is an action.yaml file.
	if [ ! -f "action.yaml" ]; then
		echo "::error::Missing action.yaml"
		exit 1
	fi

	# Get the first element of the `runs.steps` array in `action.yaml`.
	FIRST_STEP=$(yq eval '.runs.steps[0]' action.yaml)

	# Ensure the first step in `action.yaml` is the `check-workflow` action
	# unless explicitly overridden, for example if the action is not designed
	# to be called by a workflow.
	if [ "$FIRST_STEP" != "$CHECK_WORKFLOW_STEP" ]; then

		# Check if the string `# check-workflow: exempt` is present in the
		# `action.yaml` file.
		if ! grep -q "# check-workflow: exempt" action.yaml; then
			ACTION="${ACTION_DIR}action.yaml"
			echo "::error::$ACTION missing check-workflow as first step"
			print_exemption_instructions
			exit 1
		fi
	fi

	# Ensure there is a template workflow file.
	if [ ! -f "workflow-template.yaml" ]; then

		# Check if the string `# check-workflow: exempt` is present in the
		# `action.yaml` file.
		if ! grep -q "# check-workflow: exempt" action.yaml; then
			echo "::error::${ACTION_DIR}workflow-template.yaml missing"
			print_exemption_instructions
			exit 1
		fi
	fi

	# Change location back to GitHub actions directory.
	cd ..
done

echo "✅ All actions valid"
