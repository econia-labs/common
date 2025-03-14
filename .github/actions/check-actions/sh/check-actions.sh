#!/bin/sh
set -e

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

    # If there is a workflow-template.yaml file, print the dirname.
    if [ -f "workflow-template.yaml" ]; then
        echo "Workflow template found in $ACTION_PATH"
    fi

    # Change location back to GitHub actions directory.
    cd ..
done