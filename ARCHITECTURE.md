# Architecture

Native Swift and SwiftUI app, with local persistence and an iOS scheduling
adapter. The current-release scheduling contract is sound alerts or silent
notifications. AlarmKit remains a candidate for a later scheduling adapter;
the current probe uses UserNotifications. No backend is needed for the initial
scope.

## Components

| Component | Responsibility |
| --- | --- |
| SwiftUI screens | List/editor, recurrence selection, next occurrence, error display |
| Alarm model | User intent, stable ID, schedule, desired alert mode (sound alert or silent notification) |
| Recurrence calculator | Deterministic date calculations with injected clock, calendar, and time zone |
| Alarm repository | Persist configurations and OS identifier mappings |
| Scheduler adapter | Request authorization; schedule, inspect, and cancel supported OS alarms |
| Coordinator | Reconcile desired configuration and actual scheduled state |
| Diagnostics | Record operations and failures without alarm labels or credentials |

Keep pure recurrence logic testable independently from iOS. Avoid extra frameworks until justified.

## Dependency boundary

| Dependency | Role | Current-release decision |
| --- | --- | --- |
| Swift / Foundation | Domain types, calendars, dates, time zones, persistence primitives | Required platform dependency; inject calendar, clock, and time zone into recurrence logic. |
| SwiftUI | List/editor and scheduling state presentation | Required UI framework; no platform behavior is inferred from the UI. |
| UserNotifications | Local scheduling, notification authorization, sound or silent notification content, pending-request inspection, and cancellation | Current scheduling adapter for the probe and initial implementation. `sound = nil` means no configured audio; it does not guarantee vibration. |
| AlarmKit | Prominent system alarms and system-managed alarm lifecycle | Deferred adapter candidate; its documented sound configuration does not establish per-alarm vibration-only support. |
| Core Haptics | App-driven haptic playback while an app-owned engine is running | Not a dependency for scheduled locked-screen delivery; must not be used as a substitute for vibration-only. |
| Third-party packages / backend | Networking, sync, or additional scheduling behavior | None in the initial scope. |

The app must not request or imply a private Clock-app alarm capability. The
deferred vibration-only requirement is tracked separately and is not represented
by a current-release alert mode.

## Scheduling correctness

Separate desired enabled state from confirmed scheduled state. Persist stable user IDs and associated system IDs. Represent partial failures explicitly. After an interrupted edit, reconciliation must detect stale schedules, avoid duplicates, and report unresolved cancellation or scheduling failures.

### Recurrence

- One-time alarms use one nonrepeating calendar request.
- Weekly alarms use one repeating request per selected weekday. An empty weekday
  set is invalid, and no Tuesday occurrence is created for a Monday/Wednesday/
  Friday selection.
- Monthly alarms use one fixed-date request per valid selected day over an
  explicitly bounded horizon. Invalid dates, such as February 31, are skipped
  under the current specification. This is finite recurrence, not indefinite
  recurrence.
- A direct repeating day-of-month strategy remains an experiment until the
  behavior of day 31 and the system's request capacity are verified on a
  physical device. It is not the production monthly contract.

AlarmKit documents fixed and weekly-relative schedules. Monthly recurrence
requires the bounded strategy above until a separately verified alternative is
approved. Do not rely on background tasks, app-open execution, or dismissal
callbacks being guaranteed.

### Scheduling limits and identifiers

The current public UserNotifications documentation does not establish a
numeric pending-request limit. The scheduler must inspect pending requests and
report capacity or add failures rather than assuming unlimited capacity. A
finite monthly horizon must be visible to the caller and may need renewal in a
future reconciliation pass.

Every alarm has a stable app identifier. Every generated system request has a
derived identifier containing the alarm identifier and occurrence key. The
derived identifier is the ownership boundary for cancellation and replacement;
one alarm must never cancel another alarm's requests.

### Desired state, confirmed state, and partial failures

Persist desired configuration separately from confirmed scheduling state:

1. Validate the alarm and calculate its desired occurrences.
2. Compare desired owned request identifiers with the persisted/inspected
   system identifiers.
3. Add missing requests and remove obsolete requests, recording each result.
4. Mark the alarm `scheduled` only when all required operations succeed.
5. Mark it `partial` or `error` with an actionable failure when any add,
   remove, authorization, or capacity operation fails.

Edits and deletes are reconciliation operations, not blind replacement. A
failed removal must remain visible and must not be hidden by reporting the new
configuration as fully active. Retrying must be idempotent: existing owned
requests are reused or replaced deterministically, and duplicate requests are
not created.

### Permission and delivery policy

Request notification authorization before scheduling and persist the returned
authorization state. A denied or provisional/limited state must be visible to
the user; saving an alarm is not proof that an OS request exists. Sound-mode
alarms require sound authorization to be useful. Silent notifications require
alert authorization but make no haptic promise.

Focus, notification settings, Silent Mode, Haptics settings, lock-screen
presentation, app termination, restart, and iOS delivery policy remain
system-controlled. These are physical-device verification concerns, not
per-alarm controls. The current release must never report vibration-only
success.

## Feasibility gate

Prefer the simplest supported implementation that satisfies SPEC.md. If reliable monthly recurrence or other deferred behavior cannot be supported, document the observed behavior and available choices. Do not hide the deferred vibration-only requirement behind a silent-notification UI option.
