#!/bin/sh
echo "$N_LINES_ADDED lines added (max $MAX_LINES_ADDED)"
echo "$N_LINES_REMOVED lines removed (max $MAX_LINES_REMOVED)"
NEEDS_OVERRIDE="false"
if [ "$N_LINES_ADDED" -gt "$MAX_LINES_ADDED" ]; then
	NEEDS_OVERRIDE="true"
fi
if [ "$N_LINES_REMOVED" -gt "$MAX_LINES_REMOVED" ]; then
	NEEDS_OVERRIDE="true"
fi
if [ "$NEEDS_OVERRIDE" = "true" ]; then
	if [ "$N_APPROVALS" -ge "$N_OVERRIDE_APPROVALS" ]; then
		echo "✅ Changes exceeded limits but have required approvals"
	else
		echo "❌ Too many changes. Need $N_OVERRIDE_APPROVALS approvals"
		echo ""
		echo "⚠️ IMPORTANT: GitHub counts comments and resolved discussions as"
		echo "  reviews. If a reviewer approved but later added comments or"
		echo "  resolved discussions, their last action counts as their"
		echo "  current review state. This can cause the approval count to"
		echo "  drop below the required number of approvals."
		echo ""
		echo "  For this check to pass, ensure $N_OVERRIDE_APPROVALS reviewers"
		echo "  have explicitly approved and have not since left comments or"
		echo "  resolved discussions since approving. Note they can always"
		echo "  just re-approve to fix this."
		echo ""
		if [ "$GITHUB_EVENT_NAME" = "pull_request" ]; then
			echo "If the PR author hasn't updated this PR since enough"
			echo "approvals were left, you must manually trigger a re-run"
		fi
		exit 1
	fi
else
	echo "✅ Changes within limits"
fi
