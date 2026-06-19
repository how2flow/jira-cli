# Jira Ticket Auto-Update Skill

Atlassian Cloud: {{JIRA_CLOUD_ID}}

## Scope

- Target only: `assignee = currentUser()`
- Exclude projects: TMRTM, TMRCR
- Exclude types: code review, PR (Patch), group common tasks

## General Principles

- **No downgrade**: NEVER lower manually-set values (progress, est-time, etc.)
- **No start date overwrite on In Progress**: NEVER modify an already-set start date on In Progress tickets (only set when empty)
- **No est-time overwrite**: NEVER modify already-set est-time

## Execution Order

Rule 1 → Rule 2 → Rule 3 → Rule 4 → Rule 5 → Rule 6

---

## Rule 1: Est-time (Original Estimate) Setup

**Target**: All unresolved tickets where `timeoriginalestimate is EMPTY`
**Important**: NEVER modify existing est-time

### Estimation Priority
1. Reference similar tasks (resolved included) actual timespent in same project
2. Consider ticket description
3. For parent tickets: sum of subtask estimates
4. Fallback default: `1d` (8h) — and leave a comment (see below)

### Default Fallback Comment
When est-time cannot be estimated and the fallback default `1d` is used, add a comment to the ticket:
> "This ticket requires a precise estimate before work begins. Setting to default value of 1 day."

Use `addCommentToJiraIssue` to post. Only add this comment when fallback 1d is actually used, not when est-time is derived from reference data.

### Procedure
1. JQL: `assignee = currentUser() AND resolution = Unresolved AND timeoriginalestimate is EMPTY AND project not in (TMRTM, TMRCR) AND type not in (Patch)`
2. Group by project
3. Search resolved similar tickets in each project for reference data
4. Set est-time via `editJiraIssue` (field: `timetracking.originalEstimate`)
5. If fallback 1d was used → add comment via `addCommentToJiraIssue`
6. Report results

---

## Rule 2: Start Date Setup (Open Tickets)

**Target**: Open tickets (statusCategory = "To Do") with empty start date (`customfield_10015`)

### Calculation
- **Formula**: `start_date = due_date - est_time` (business days)
- **If est-time <= 1d**: start_date = due_date
- **If no due_date**: skip
- **If no est-time**: skip (retry after Rule 1)

### Procedure
1. JQL: `assignee = currentUser() AND statusCategory = "To Do" AND project not in (TMRTM, TMRCR) AND type not in (Patch) AND "Start date" is EMPTY AND duedate is not EMPTY AND timeoriginalestimate is not EMPTY`
2. Read duedate and timeoriginalestimate for each ticket
3. Calculate start_date, set via editJiraIssue (`customfield_10015`)
4. Report results

---

## Rule 3: Start Date Backfill (In Progress Tickets)

**Target**: In Progress tickets with empty start date (`customfield_10015`)
**Important**: Only set when start date is empty. NEVER overwrite existing start date.

### Calculation
- Find the **earliest date** from worklog entries (`started` field) and comment entries (`created` field)
- Use that date as start date

### Procedure
1. JQL: `assignee = currentUser() AND status = "In Progress" AND project not in (TMRTM, TMRCR) AND "Start date" is EMPTY`
2. For each ticket, read worklog and comment entries
3. Find the earliest date among all worklog `started` dates and comment `created` dates
4. Set that date as start date via editJiraIssue (`customfield_10015`)
5. Report results

---

## Rule 4: Overdue Due Date Extension

**Target**: Unresolved tickets where `duedate < now()`
**Action**: Extend due date to next Friday from current date

### Skip Conditions
- Comment explicitly says do not change due date
- Requirements-related ticket (summary contains "요구사항") <!-- Jira data value, do not translate -->
- Externally constrained tickets

### Calculation
- **New due date**: next Friday from today
- **Open tickets**: update both due date and start date (start = due - est; if est <= 1d then start = due)
- **In Progress tickets**: update due date only (preserve start date)

### Procedure
1. JQL: `assignee = currentUser() AND resolution = Unresolved AND duedate < now() AND project not in (TMRTM, TMRCR) AND type not in (Patch)`
2. Check each ticket's comments for "do not change due date" instructions
3. Check if summary contains "요구사항" (Korean for "requirements", actual Jira field value)
4. If not excluded → update due date; also update start date for Open tickets only
5. Report results

---

## Rule 5: State Transition (Open → In Progress)

**Target**: Open tickets (statusCategory = "To Do")
**Condition**: worklog count > 0 OR comment count > 0
**Action**: Transition via transitionJiraIssue

### Procedure
1. JQL: `assignee = currentUser() AND statusCategory = "To Do" AND project not in (TMRTM, TMRCR) AND type not in (Patch)`
2. Check worklog and comment count for each ticket
3. If worklog > 0 OR comment > 0 → get transition id via getTransitionsForJiraIssue, then transition
4. Report results

---

## Rule 6: Progress Update

**Target**: In Progress tickets + recently resolved tickets
**Field**: `customfield_10377` (manual Progress field in UI, integer 0-100)
**Note**: This is NOT the auto-calculated `progress` field

### Calculation
- **Formula**: `round(timespent / timeoriginalestimate * 100)`
- **If calculated >= 70%**: DO NOT update (manual management zone)
- **If calculated < current value**: DO NOT update (no downgrade)
- **If user intentionally lowered progress**: DO NOT update (see Intentional Edit Detection below)
- **If ticket is resolved**: set progress = 100
- **If no timeoriginalestimate**: skip

### Intentional Edit Detection
Before updating, check the ticket's changelog (`expand=changelog`) for `customfield_10377` changes.
If there is a changelog entry where `toString < fromString` (value was lowered), it means the user intentionally reduced progress.
In this case, DO NOT update progress — respect the user's manual override.
Only reset this protection when a new worklog is added after the intentional edit (i.e., the latest worklog `created` date is more recent than the latest intentional-lowering changelog date).

### Procedure
1. In Progress tickets:
   - JQL: `assignee = currentUser() AND status = "In Progress" AND project not in (TMRTM, TMRCR)`
   - For each ticket, fetch with `expand=changelog`
   - Check changelog for intentional progress lowering (toString < fromString on customfield_10377)
   - If intentionally lowered and no newer worklog exists → skip
   - Otherwise, update only if: calculated < 70% AND calculated >= current value AND calculated != current value
2. Recently resolved tickets (progress != 100):
   - JQL: `assignee = currentUser() AND status in ("해결됨", "종료") AND resolved >= -7d AND project not in (TMRTM, TMRCR)` <!-- "해결됨"=Resolved, "종료"=Closed, actual Jira status names -->
   - If customfield_10377 != 100 → set to 100
3. Report results

---

## API Reference

- est-time: `{"timetracking": {"originalEstimate": "2d"}}` (`timeoriginalestimate` field cannot be set directly)
- progress: `{"customfield_10377": 50}` (integer 0-100)
- start date: `{"customfield_10015": "2026-07-01"}` (ISO date)
- due date: `{"duedate": "2026-07-01"}` (ISO date)
- transition: use `transitionJiraIssue`; transition id varies per project, always check via `getTransitionsForJiraIssue` first
- comment: use `addCommentToJiraIssue` with `contentFormat: "markdown"`
- cloudId: `{{JIRA_CLOUD_ID}}`
- JQL status: statusCategory = "To Do" (Open), status = "In Progress"

## Output Format

```
=== Jira Auto-Update Report (YYYY-MM-DD) ===

[Rule 1: Est-time Setup]
- Set: N tickets
  - KEY-123: title → 2d (ref: similar task timespent)
  - KEY-456: title → 1d (default, comment added)
- Skipped: N (already set)

[Rule 2: Start Date Setup (Open)]
- Set: N tickets
  - KEY-123: title → 2026-07-01 (due:2026-07-15, est:2w)
- Skipped: N (already set / no due date)

[Rule 3: Start Date Backfill (In Progress)]
- Set: N tickets
  - KEY-123: title → 2026-04-15 (earliest worklog date)
- Skipped: N (already set / no activity found)

[Rule 4: Overdue Extension]
- Extended: N tickets
  - KEY-123: title (05-17 → 06-26, In Progress, due only)
  - KEY-456: title (05-15 → 06-26, Open, due+start)
- Skipped(requirements): N
- Skipped(comment restriction): N

[Rule 5: State Transition]
- Transitioned: N tickets
  - KEY-123: title (Open → In Progress)
- No target: N

[Rule 6: Progress Update]
- Updated: N tickets
  - KEY-123: title (0% → 25%, spent:2h/est:1d)
- Resolved(→100%): N tickets
- Skipped(>=70%): N
- Skipped(downgrade): N
```
