#!/bin/sh
set -e

# Use yq to parse
CHECK_WORKFLOW_STEP=$(yq eval '.[0]' $ACTION_PATH/cfg/check-workflow-step.yaml)
echo "Check workflow step: $CHECK_WORKFLOW_STEP"

# Change location to GitHub actions directory.
cd .github/actions

# Iterate over all action directories.
for ACTION_PATH in */; do
    # Change location to action directory.
    cd "$ACTION_PATH"

    # Verify there are no directories other than cfg and sh.
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

    # Use yq to get the first element of the runs.steps array.
    FIRST_STEP=$(yq eval '.runs.steps[0]' action.yaml)

    # If there is a workflow-template.yaml file, ensure check-workflow is the
    # first step.
    if [ -f "workflow-template.yaml" ]; then
        if [ "$FIRST_STEP" != "$CHECK_WORKFLOW_STEP" ]; then
            echo "::error::$ACTION_PATH first step is not check-workflow"
            exit 1
        fi
    fi

    # If the first step is check-workflow, ensure there is a
    # workflow-template.yaml file.
    if [ "$FIRST_STEP" = "$CHECK_WORKFLOW_STEP" ]; then
        if [ ! -f "workflow-template.yaml" ]; then
            echo "::error::Missing workflow-template.yaml"
            exit 1
        fi
    fi

    # Change location back to GitHub actions directory.
    cd ..
done