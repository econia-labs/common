#!/bin/sh
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
echo "n_approvals=$APPROVALS" >>$GITHUB_OUTPUT
