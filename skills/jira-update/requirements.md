# Jira Ticket Management Automation Requirements

## Background

- Multiple products/projects developed simultaneously
- Tickets require **Estimated, Start Date, Due Date** for workload and schedule forecasting
- Reality: most assignees skip or neglect these fields
- Goal: automate filling missing fields and keep ticket status up to date

## Required Fields

| Field | Description | Automation Target |
|-------|-------------|-------------------|
| **Estimated** (Original Estimate) | Expected hours to complete | Auto-set from similar resolved tasks |
| **Start Date** | Earliest start date | Open: due - est / In Progress: earliest activity date |
| **Due Date** | Target completion date | Auto-extend to next Friday when overdue |
| **Progress** | Completion percentage (0-100) | Auto-calculate from timespent / est ratio |
| **Status** | Ticket state (Open/In Progress/Resolved) | Auto-transition when worklog/comment exists |

## Automation Rules

### REQ-1: Estimated Auto-Setup
- Target: tickets with empty est-time only; NEVER modify existing values
- Priority: similar task timespent reference > description > subtask sum > default 1d
- When default 1d is used, leave a comment requesting precise estimation

### REQ-2: Start Date Auto-Setup
- Open tickets: `start = due - est` (business days); if est <= 1d then start = due
- In Progress tickets: backfill from earliest worklog/comment date when empty
- NEVER modify existing start date on In Progress tickets

### REQ-3: Due Date Auto-Extension
- Extend overdue due date to next Friday from today
- Skip: requirements-related tickets, tickets with "do not change" comment
- Open: update both due + start / In Progress: update due only

### REQ-4: State Auto-Transition
- Transition Open to In Progress when worklog or comment count > 0

### REQ-5: Progress Auto-Update
- Formula: `round(timespent / est * 100)`
- Skip if calculated >= 70% (manual management zone)
- Skip if user intentionally lowered value (changelog downward detection)
- Set progress = 100 on resolved tickets

## Constraints

- Target: `assignee = currentUser()` only
- Exclude projects: TMRTM, TMRCR
- Exclude types: code review, PR (Patch), group common tasks
- No downgrade: NEVER lower manually-set values via automation

## Task Decomposition Principles

- Break large tasks into small units before estimating
- Example: requirements analysis > design review > implementation > unit test > integration test > stabilization
- Invest 10-20 minutes right after assignment for decomposition and planning
- Discuss with PL/Maintainer/team lead when uncertain

## Plan Update Principles

- Estimated, Start Date, Due Date are best predictions, not contracts
- Update immediately when situation changes (customer request, priority shift, new issues)
- Good plan = continuously managed plan that reflects changes

## Worklog & Progress Habits

- Update progress field when logging work
- Automation handles baseline calculation; 70%+ is managed manually by assignee
