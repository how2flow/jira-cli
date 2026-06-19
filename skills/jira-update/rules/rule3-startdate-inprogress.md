# Rule 3: Start Date Backfill (In Progress Tickets)

cloudId: `{{JIRA_CLOUD_ID}}`

## Scope
- Target only: `assignee = currentUser()`
- Exclude projects: TMRTM, TMRCR

## Target
In Progress tickets with empty start date (`customfield_10015`).
NEVER overwrite existing start date. Only set when empty.

## Calculation
Find the **earliest date** from:
- Worklog entries (`started` field)
- Comment entries (`created` field)

Use that date as start date.

## Procedure
1. JQL: `assignee = currentUser() AND status = "In Progress" AND project not in (TMRTM, TMRCR) AND "Start date" is EMPTY`
2. For each ticket, read worklog and comment entries
3. Find the earliest date among all worklog `started` dates and comment `created` dates
4. Set that date as start date via editJiraIssue (`customfield_10015`)
5. Report results

## API
- start date: `{"customfield_10015": "2026-07-01"}` (ISO date)

## Output
```
[Rule 3: Start Date Backfill (In Progress)]
- Set: N tickets
  - KEY-123: title → 2026-04-15 (earliest worklog date)
- Skipped: N (already set / no activity found)
```

Execute now.
