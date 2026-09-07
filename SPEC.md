# Product specification

Status: current-release scope revised after T01/T02. Device-dependent behavior remains unverified where noted in the feasibility and verification records.

## Goal

Let the user configure separate alarms that alert at chosen times and recur on selected weekdays or days of the month. Recurrence means a new scheduled occurrence, not continuous vibration. Do not implement indefinite vibration or automatic repeated nagging within an occurrence.

## Requirements

- Create, edit, delete, enable, and disable alarms independently.
- Each alarm has an identifier, optional label, local hour/minute, desired alert mode (sound alert or silent notification), and a schedule.
- Schedule types: one time on a selected date; weekly on one or more weekdays; monthly on one or more dates from 1 to 31.
- Stopping the current occurrence preserves later recurring occurrences.
- Show the next occurrence, permission state, and scheduling failures. A saved preference is not proof that an alarm was scheduled.
- Operate offline with local storage and operating-system scheduling.
- Editing or deleting an alarm must remove its obsolete system schedules without affecting another alarm.
- Sound alerts and silent notifications are in the current release scope. A silent notification means no app-configured notification sound; it does not guarantee vibration.
- Vibration-only while locked, independently per alarm and without requiring phone-wide Silent Mode or an open app, is deferred as an unresolved future requirement. Do not represent silent notifications as satisfying it.

## Proposed first-version defaults

- One recurrence type per alarm; weekly and monthly are separate choices.
- Times follow the device's local time zone. Fixed-date schedules need reconciliation if used for recurring local times.
- Skip invalid monthly dates: a 31st alarm skips a month with no 31st.
- Weekly selection must be nonempty, as must monthly selection.
- For daylight-saving gaps, propose the next valid local time that day; for a repeated local time, propose the first occurrence only. Validate what the selected iOS API actually permits before accepting these defaults.
- No account, backend, synchronization, Android target, Mac desktop target, or snooze in the initial scope.

## Acceptance examples

1. Weekly 08:00 Monday/Wednesday/Friday has no Tuesday occurrence.
2. Monthly 09:00 on the 1st and 15th yields both dates each month.
3. Monthly on the 31st skips February and April under the proposed policy.
4. Disabling one alarm cancels only that alarm's future occurrences.
5. Editing 08:00 to 09:00 leaves no obsolete 08:00 schedule.
6. Reopening the app preserves configurations and reconciles them with OS schedules.
7. Permission denial or a scheduling error is visible; the UI does not report successful activation.
8. A sound-mode alarm requests a sound alert.
9. A silent-mode alarm requests a silent notification; vibration is not promised.
10. Vibration-only remains explicitly out of the current release acceptance criteria and unresolved for future investigation.

## Deferred future requirement

Per-alarm vibration-only delivery while locked remains unresolved. The current
release must not depend on it. A future investigation may test candidate
approaches on a physical iPhone, but a device result alone must not be promoted
to a supported API guarantee.

## Open decisions for later tasks

Supported minimum iOS version; exact alert duration behavior; monthly scheduling
without periodic app reopening; OS schedule capacity; time-zone/DST behavior;
restart and termination behavior. Record any requirement that cannot be met
and discuss the concrete tradeoff before claiming completion.
