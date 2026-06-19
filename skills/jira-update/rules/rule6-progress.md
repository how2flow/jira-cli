# Rule 6: Progress Update

cloudId: `{{JIRA_CLOUD_ID}}`

## Scope
- Target only: `assignee = currentUser()`
- Exclude projects: TMRTM, TMRCR

## Target
- In Progress tickets
- Recently resolved tickets (within 7 days)

## Field
`customfield_10377` (manual Progress field in UI, integer 0-100).
This is NOT the auto-calculated `progress` field.

## Calculation
- **Formula**: `round(timespent / timeoriginalestimate * 100)`
- **If calculated >= 70%**: DO NOT update (manual management zone)
- **If calculated < current value**: DO NOT update (no downgrade)
- **If user intentionally lowered progress**: DO NOT update (see detection below)
- **If ticket is resolved**: set progress = 100
- **If no timeoriginalestimate**: skip

## Intentional Edit Detection
Before updating, fetch the ticket with `expand=changelog` and check `customfield_10377` changes.
If there is a changelog entry where `toString < fromString` (value was lowered), the user intentionally reduced progress.
In this case, DO NOT update — respect the user's manual override.
**Exception**: If the latest worklog `created` date is more recent than the latest intentional-lowering changelog date, the protection resets and normal update logic applies.

## Procedure
1. In Progress tickets:
   - JQL: `assignee = currentUser() AND status = "In Progress" AND project not in (TMRTM, TMRCR)`
   - For each ticket, fetch with `expand=changelog`
   - Check changelog for intentional progress lowering (toString < fromString on customfield_10377)
   - If intentionally lowered and no newer worklog exists → skip
   - Otherwise, update only if: calculated < 70% AND calculated >= current value AND calculated != current value
2. Recently resolved tickets (progress != 100):
   - JQL: `assignee = currentUser() AND status in ("해결됨", "종료") AND resolved >= -7d AND project not in (TMRTM, TMRCR)` <!-- "해결됨"=Resolved, "종료"=Closed -->
   - If customfield_10377 != 100 → set to 100
3. Report results

## API
- progress: `{"customfield_10377": 50}` (integer 0-100)

## Output
```
[Rule 6: Progress Update]
- Updated: N tickets
  - KEY-123: title (0% → 25%, spent:2h/est:1d)
- Resolved(→100%): N tickets
- Skipped(>=70%): N
- Skipped(downgrade): N
- Skipped(intentional edit): N
```

Execute now.
