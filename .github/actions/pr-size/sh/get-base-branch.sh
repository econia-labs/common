BASE=$(gh pr view "$PR_NUMBER" --json baseRefName -q '.baseRefName')
echo "Base branch: $BASE"
echo "base_branch=$BASE" >> $GITHUB_OUTPUT