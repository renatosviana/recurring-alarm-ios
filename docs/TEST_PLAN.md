# Verification plan

Status: PARTIAL: locked-screen sound and silent-notification observations recorded; foreground sound behavior was observed silent and the presentation fix is pending device verification; all other checks remain individually tracked below.

## Automated checks after implementation

- Weekly next-occurrence calculation including crossing week boundaries.
- Monthly dates 1/15/29/30/31, leap years, year boundaries, and invalid dates.
- Time-zone changes, DST gaps and repeated local times under the agreed policy.
- Invalid empty weekday/month-day selections.
- Separate identifiers for separate alarms with identical configurations.
- Schedule replacement, cancellation failure, partial scheduling failure, and retry/reconciliation without duplicates.
- Persistence round trip and permission-denied state.

## Physical iPhone checks

Test sound alerts and silent notifications independently. A silent notification does not guarantee vibration. Record actual duration and audibility. Use short future test times; do not wait a month to test the recurrence calculator. Per-alarm vibration-only is deferred and is not a current-release acceptance test.

| Scenario | Expected verification | Result |
| --- | --- | --- |
| Screen locked | Sound alert and silent notification behavior | Partial: user reported sound notification with sound/vibration and silent notification with no sound/no vibration; locked-screen sound delivery works; other locked-screen cases remain not run |
| App open / foreground | Sound notification presents and plays sound; silent notification presents without sound | Not run after foreground presentation fix; prior user observation was that sound stayed silent while the app was open |
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
