# Rule 5: State Transition (Open → In Progress)

cloudId: `{{JIRA_CLOUD_ID}}`

## Scope
- Target only: `assignee = currentUser()`
- Exclude projects: TMRTM, TMRCR
- Exclude types: code review, PR (Patch), group common tasks

## Target
Open tickets (statusCategory = "To Do") where worklog count > 0 OR comment count > 0.

## Procedure
1. JQL: `assignee = currentUser() AND statusCategory = "To Do" AND project not in (TMRTM, TMRCR) AND type not in (Patch)`
2. For each ticket, check worklog and comment count (use fields: `worklog`, `comment`)
3. If worklog > 0 OR comment > 0 → get transition id via `getTransitionsForJiraIssue`, then `transitionJiraIssue`
4. Report results

## API
- transition: use `transitionJiraIssue`; transition id varies per project, always check via `getTransitionsForJiraIssue` first

## Output
```
[Rule 5: State Transition]
- Transitioned: N tickets
  - KEY-123: title (Open → In Progress)
- No target: N
```

Execute now.
