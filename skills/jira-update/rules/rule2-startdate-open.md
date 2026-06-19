# Rule 2: Start Date Setup (Open Tickets)

cloudId: `{{JIRA_CLOUD_ID}}`

## Scope
- Target only: `assignee = currentUser()`
- Exclude projects: TMRTM, TMRCR
- Exclude types: code review, PR (Patch), group common tasks

## Target
Open tickets (statusCategory = "To Do") with empty start date (`customfield_10015`).

## Calculation
- **Formula**: `start_date = due_date - est_time` (business days)
- **If est-time <= 1d**: start_date = due_date
- **If no due_date**: skip
- **If no est-time**: skip

## Procedure
1. JQL: `assignee = currentUser() AND statusCategory = "To Do" AND project not in (TMRTM, TMRCR) AND type not in (Patch) AND "Start date" is EMPTY AND duedate is not EMPTY AND timeoriginalestimate is not EMPTY`
2. Read duedate and timeoriginalestimate for each ticket
3. Calculate start_date, set via editJiraIssue (`customfield_10015`)
4. Report results

## API
- start date: `{"customfield_10015": "2026-07-01"}` (ISO date)

## Output
```
[Rule 2: Start Date Setup (Open)]
- Set: N tickets
  - KEY-123: title → 2026-07-01 (due:2026-07-15, est:2w)
- Skipped: N (already set / no due date)
```

Execute now.
