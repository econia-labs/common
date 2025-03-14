#!/bin/sh
set -e

# Get the syntax required to properly call `check-workflow` action.
CHECK_WORKFLOW_STEP=$(yq eval '.[0]' $ACTION_PATH/cfg/check-workflow-step.yaml)

# Change location to GitHub actions directory.
cd .github/actions

# Iterate over all action directories.
for ACTION_PATH in */; do
	# Change location to action directory.
	cd "$ACTION_PATH"

	# Verify there are no sub-directories other than cfg and sh.
	for DIR in */; do
		if [ "$DIR" != "cfg/" ] && [ "$DIR" != "sh/" ]; then
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
            echo "::error::$ACTION_PATH first step is not check-workflow"
            echo "::error::If this action is not directly called by a workflow"
            echo "::error::you can silence this check by including the comment"
            echo "::error::<# check-workflow: exempt> in action.yaml"
            exit 1
        fi

        echo "::error::$ACTION_PATH first step is not check-workflow"
        exit 1
    fi

    # Ensure there is a template workflow file.
    if [ ! -f "workflow-template.yaml" ]; then
        echo "::error::$ACTION_PATH missing workflow-template.yaml"
        exit 1
    fi

	# Change location back to GitHub actions directory.
	cd ..
done

echo "✅ All actions valid"
