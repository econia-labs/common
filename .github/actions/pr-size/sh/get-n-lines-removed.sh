git fetch origin $BASE_BRANCH
DELETIONS=$(
    git diff --stat origin/$BASE_BRANCH | \
    tail -n1 | grep -oP '\d+(?= deletion)' || echo "0"
)
echo "Number of lines removed: $DELETIONS"
echo "deletions=$DELETIONS" >> $GITHUB_OUTPUT