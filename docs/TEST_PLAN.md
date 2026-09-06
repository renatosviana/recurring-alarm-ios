# Verification plan

Status: NOT RUN.

## Automated checks after implementation

- Weekly next-occurrence calculation including crossing week boundaries.
- Monthly dates 1/15/29/30/31, leap years, year boundaries, and invalid dates.
- Time-zone changes, DST gaps and repeated local times under the agreed policy.
- Invalid empty weekday/month-day selections.
- Separate identifiers for separate alarms with identical configurations.
- Schedule replacement, cancellation failure, partial scheduling failure, and retry/reconciliation without duplicates.
- Persistence round trip and permission-denied state.

## Physical iPhone checks

Test sound and vibration-only independently. Record actual duration and audibility. Use short future test times; do not wait a month to test the recurrence calculator.

| Scenario | Expected verification | Result |
| --- | --- | --- |
| Screen locked | Configured supported alert behavior | Not run |
| App backgrounded / terminated | Record each state separately | Not run |
| Silent Mode / Focus / haptics settings | Record behavior, do not assume equivalence | Not run |
| Device restart | Observe retained schedule behavior | Not run |
| Permission denied or revoked | UI clearly reports inability to schedule | Not run |
| Edit or delete | No old alarm remains | Not run |
| Stop current occurrence | Future recurrence remains | Not run |
| Offline | Supported schedules still operate | Not run |
| Multiple simultaneous alarms | Record delivery and independent control | Not run |
| Time-zone change | Matches agreed local-time policy | Not run |

Use explicit pass/fail/not-run entries and note device/OS versions. Scheduling success alone does not prove the user heard or felt an alert.
