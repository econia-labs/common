#!/bin/sh
if [ -z "$PR_NUMBER" ] || [ "$PR_NUMBER" = "null" ]; then
    exit 1
fi
echo "PR number: $PR_NUMBER"
echo "number=$PR_NUMBER" >> $GITHUB_OUTPUT
