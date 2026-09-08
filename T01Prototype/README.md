# T01 scheduling probe

`T01PrototypeApp.xcodeproj` is a minimal iOS app project containing a SwiftUI
test screen and `AlarmSchedulingProbe.swift`. It is intentionally not the
full application. The screen can request notification permission, schedule
short test alerts, inspect pending requests, and cancel probe requests.

The probe covers these T01 questions:

- one-time, selected-weekday, and selected-day-of-month occurrences;
- one independent notification identifier per alarm/occurrence;
- sound configured independently by setting `content.sound` to `.default` or
  `nil`;
- direct repeating monthly requests, one request per selected day, separately
  from the finite monthly expansion.

## Notification probe versus AlarmKit

This project uses `UserNotifications` only. Its alerts are ordinary local
notifications: the app supplies content and date components, and the system
delivers the notification. They are not AlarmKit alarms and do not establish
AlarmKit's prominent alarm UI, authorization, silent-mode behavior, or sound
configuration.

AlarmKit is a separate iOS/iPadOS 26 API. Apple documents fixed schedules and
weekly-relative recurrence for it, but not monthly recurrence. A later probe
must be added if the product chooses AlarmKit rather than local notifications.

The `requests` monthly branch expands a finite horizon (12 months by default)
and skips invalid dates. The `repeatingMonthlyRequests` branch creates one
`repeats: true` calendar trigger per day-of-month, so it does not use a finite
queue. Apple documents repeating date-component matching, but does not state
how an invalid day such as the 31st is handled by this trigger. Verify this on
an iPhone. The current Apple documentation also does not state a current
UserNotifications pending-request limit; older deprecated local-notification
documentation describes a 64-notification limit, so capacity remains an
explicit device check.

The `silentNotification` value configures no notification audio. It is not a
vibration-only mode: UserNotifications has no public API that requests haptics
while suppressing audio, and the probe does not claim that `sound = nil`
produces vibration. Per-alarm vibration-only remains a deferred future
requirement.

## Mac verification

Open `T01Prototype/T01PrototypeApp.xcodeproj` in Xcode 26 or later, choose an
iPhone simulator or physical iPhone, and run the `T01PrototypeApp` scheme.
Grant notification permission. The project is now self-contained; no manual
file integration is required. This Windows environment has no Xcode, Swift
compiler, simulator, or connected iPhone, so the project was not compiled or
run here.
