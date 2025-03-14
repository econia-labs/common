<!-- markdownlint-disable-file MD025 -->

# Description

To ensure consistency across CI, I've added two related GitHub actions:

## `check-workflow`

This action is designed to be used as the first step in other actions, and
verifies that when the including action is called by a workflow, the calling
workflow matches a `workflow-template.yaml` file. This makes it so that there
is no confusion when re-using actions across repos.

## `check-actions`

This action checks all the actions in a repository to ensure that they:

1. Have only `cfg/` and `sh/` sub-directories.
1. Contain an `action.yaml` file.
1. Contain a `workflow-template.yaml` file.
1. Call the `check-workflow` action as the first action step.

Note the last two of these can be skipped by simply adding
`# check-workflow: exempt` to an action, when the action is only designed to
be called by other actions and never directly by a workflow (analogous to a
`public fun` in Move). For example `check-workflow/action.yaml` contains such
an escape because the action is only meant to be called in other actions.

# Testing

## In this repo

This PR concludes with a commit sequence that demonstrates the assorted failure
modes from `sh` files in the order they are listed in the
[changed files manifest]. Note that branch references start as `ECO-3009`,
and are changed at the end to prepare for a final merge to `main`. All checks
pass as of 26b9da8, then the sequence begins:

## `check-actions` failures

1. a4562c3 [Error: unexpected directory]
1. 4a14bbc [Error: missing action.yaml]

## In a calling repo

# Checklist

- [ ] Did you check all checkboxes from the linked Linear task?

[changed files manifest]: https://github.com/econia-labs/common/pull/27/files
[Error: unexpected directory]: https://github.com/econia-labs/common/actions/runs/13866417699/job/38806346151?pr=27
[Error: missing action.yaml]: https://github.com/econia-labs/common/actions/runs/13866438699/job/38806404093?pr=27
