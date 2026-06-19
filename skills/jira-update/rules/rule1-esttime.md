# Rule 1: Est-time (Original Estimate) Setup

cloudId: `{{JIRA_CLOUD_ID}}`

## Scope
- Target only: `assignee = currentUser()`
- Exclude projects: TMRTM, TMRCR
- Exclude types: code review, PR (Patch), group common tasks

## Target
All unresolved tickets where `timeoriginalestimate is EMPTY`.
NEVER modify existing est-time.

## Estimation Priority
1. Reference similar tasks (resolved included) actual timespent in same project
2. Consider ticket description
3. For parent tickets: sum of subtask estimates
4. Fallback default: `1d` (8h) — and leave a comment (see below)

## Default Fallback Comment
When est-time cannot be estimated and the fallback default `1d` is used, add a comment:
> "This ticket requires a precise estimate before work begins. Setting to default value of 1 day."

Use `addCommentToJiraIssue` to post. Only add when fallback 1d is actually used.

## Procedure
1. JQL: `assignee = currentUser() AND resolution = Unresolved AND timeoriginalestimate is EMPTY AND project not in (TMRTM, TMRCR) AND type not in (Patch)`
2. Group by project
3. Search resolved similar tickets in each project for reference data
4. Set est-time via `editJiraIssue` (field: `timetracking.originalEstimate`)
5. If fallback 1d was used → add comment via `addCommentToJiraIssue`
6. Report results

## API
- est-time: `{"timetracking": {"originalEstimate": "2d"}}`
- comment: use `addCommentToJiraIssue` with `contentFormat: "markdown"`

## Output
```
[Rule 1: Est-time Setup]
- Set: N tickets
  - KEY-123: title → 2d (ref: similar task timespent)
  - KEY-456: title → 1d (default, comment added)
- Skipped: N (already set)
```

Execute now.
