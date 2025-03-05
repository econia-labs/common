APPROVALS=$(
	gh pr view $PR_NUMBER \
		--json reviews |
		jq '
        .reviews
        | group_by(.author.login)
        | map(last)
        | map(select(.state == "APPROVED"))
        | length
    '
)
echo "Number of approvals: $APPROVALS"
echo "approvals=$APPROVALS" >>$GITHUB_OUTPUT
