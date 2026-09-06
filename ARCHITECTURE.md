# Proposed architecture

Native Swift and SwiftUI app, with local persistence and an iOS scheduling adapter. AlarmKit is the first candidate, pending T01. No backend is needed for the initial scope.

## Components

| Component | Responsibility |
| --- | --- |
| SwiftUI screens | List/editor, recurrence selection, next occurrence, error display |
| Alarm model | User intent, stable ID, schedule, desired alert mode |
| Recurrence calculator | Deterministic date calculations with injected clock, calendar, and time zone |
| Alarm repository | Persist configurations and OS identifier mappings |
| Scheduler adapter | Request authorization; schedule, inspect, and cancel supported OS alarms |
| Coordinator | Reconcile desired configuration and actual scheduled state |
| Diagnostics | Record operations and failures without alarm labels or credentials |

Keep pure recurrence logic testable independently from iOS. Avoid extra frameworks until justified.

## Scheduling correctness

Separate desired enabled state from confirmed scheduled state. Persist stable user IDs and associated system IDs. Represent partial failures explicitly. After an interrupted edit, reconciliation must detect stale schedules, avoid duplicates, and report unresolved cancellation or scheduling failures.

AlarmKit documents fixed and weekly-relative schedules. Monthly recurrence requires a separately verified strategy. A finite queue of fixed alarms must expose its coverage horizon and cannot be described as indefinite recurrence. Do not rely on background tasks or dismissal callbacks being guaranteed. Alternative notification APIs must be evaluated against the actual sound/vibration and timing requirements rather than presented as equivalent automatically.

## Feasibility gate

Prefer the simplest supported implementation that satisfies SPEC.md. If brief vibration-only alerts or reliable monthly recurrence cannot be supported, document the observed behavior and available choices. Do not hide an unsupported requirement behind a nonfunctional UI option.
