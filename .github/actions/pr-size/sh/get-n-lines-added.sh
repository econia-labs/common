#!/bin/sh
git fetch origin $BASE_BRANCH
INSERTIONS=$(
	git diff --stat origin/$BASE_BRANCH |
		tail -n1 | grep -oP '\d+(?= insertion)' || echo "0"
)
echo "Number of lines added: $INSERTIONS"
echo "insertions=$INSERTIONS" >>$GITHUB_OUTPUT
