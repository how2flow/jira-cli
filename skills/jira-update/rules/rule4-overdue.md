# Rule 4: Overdue Due Date Extension

cloudId: `{{JIRA_CLOUD_ID}}`

## Scope
- Target only: `assignee = currentUser()`
- Exclude projects: TMRTM, TMRCR
- Exclude types: code review, PR (Patch), group common tasks

## Target
Unresolved tickets where `duedate < now()`.

## Skip Conditions
- Comment explicitly says do not change due date
- Requirements-related ticket (summary contains "요구사항") <!-- Jira data value, do not translate -->
- Externally constrained tickets

## Calculation
- **New due date**: next Friday from today
- **Open tickets**: update both due date and start date (start = due - est; if est <= 1d then start = due)
- **In Progress tickets**: update due date only (preserve start date)

## Procedure
1. JQL: `assignee = currentUser() AND resolution = Unresolved AND duedate < now() AND project not in (TMRTM, TMRCR) AND type not in (Patch)`
2. Check each ticket's comments for "do not change due date" instructions
3. Check if summary contains "요구사항" (Korean for "requirements", actual Jira field value)
4. If not excluded → update due date; also update start date for Open tickets only
5. Report results

## API
- due date: `{"duedate": "2026-07-01"}` (ISO date)
- start date: `{"customfield_10015": "2026-07-01"}` (ISO date)

## Output
```
[Rule 4: Overdue Extension]
- Extended: N tickets
  - KEY-123: title (05-17 → 06-26, In Progress, due only)
  - KEY-456: title (05-15 → 06-26, Open, due+start)
- Skipped(requirements): N
- Skipped(comment restriction): N
```

Execute now.
