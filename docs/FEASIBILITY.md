# T01 feasibility record

Status: T01 INCOMPLETE: simulator build passed; TestFlight upload and physical-device verification are pending.

Timestamp: 2026-09-06 (America/New_York)

The prototype is [T01Prototype/T01PrototypeApp.xcodeproj](../T01Prototype/T01PrototypeApp.xcodeproj),
with [AlarmSchedulingProbe.swift](../T01Prototype/AlarmSchedulingProbe.swift) and a simple SwiftUI
test screen. It is an investigation probe, not the application.

## Environment

- Development host: Windows NT 10.0.26200.0, PowerShell 5.1 (`JoshuasLaptop`)
- Mac and macOS: unavailable in this workspace
- Xcode / SDK: unavailable; `xcodebuild`, `xcrun`, `simctl`, `swift`, and `swiftc` were not found
- iPhone model / iOS: unknown
- Apple Developer Program: owner reports enrollment; Team ID, App ID, signing assets, and App Store Connect record still require setup below.
- Candidate API: AlarmKit, introduced for iOS/iPadOS 26; deployment target and final SDK unavailable

## Prototype findings

- `AlarmSchedulingProbe` models one-time, weekly selected-weekday, and monthly selected-day schedules.
- Weekly schedules create a separate repeating `UNCalendarNotificationTrigger` per selected weekday.
- Monthly schedules are expanded as one-time calendar requests over a finite 12-month horizon; invalid dates are skipped. This is not indefinite monthly recurrence and the pending-request capacity must be tested on-device.
- Each request has a stable alarm UUID plus an occurrence suffix, allowing cancellation/replacement without intentionally sharing another alarm's identifier.
- `.sound` maps to `UNMutableNotificationContent.sound = .default`.
- `.vibrationOnly` maps to no configured sound (`sound = nil`) only. UserNotifications does not expose a public per-request haptic-only setting, so vibration-only remains unsupported/unproven. Do not present this as satisfying the requirement.
- The probe does not request continuous vibration. Alert duration and haptic behavior remain system-controlled and must be observed on a physical iPhone.

## Notification behavior versus AlarmKit

The runnable prototype uses `UserNotifications`, not AlarmKit. A local
notification is a request containing content plus a calendar trigger. It can
show an alert, play configured sound, or update a badge; the system handles
delivery even when the app is not running. It does not prove AlarmKit's
prominent alarm presentation or behavior.

AlarmKit is a separate iOS/iPadOS 26 framework with its own authorization and
alarm manager. Apple documents fixed schedules and weekly-relative recurrence
for AlarmKit. Its traditional alarm configuration accepts an `AlertSound`, but
the reviewed API does not expose a per-alarm vibration-only control.

The two APIs must not be treated as interchangeable acceptance evidence.

## Non-finite monthly recurrence investigation

Apple's `UNCalendarNotificationTrigger` documentation says a repeating trigger
is rescheduled after delivery and that only the relevant `DateComponents`
should be supplied. Therefore, a separate trigger with `day = 1`, `day = 15`,
and `day = 31` can be constructed without a finite 12-month queue. The new
`repeatingMonthlyRequests` probe branch does exactly that.

Apple's current public documentation does not specify whether a repeating
day-of-month trigger for day 31 skips February/April/etc., rejects the request,
or applies another matching behavior. Foundation's separate recurrence-rule
documentation describes strict handling for invalid dates, but that is not a
documented promise for `UNCalendarNotificationTrigger`. The 31st behavior is
therefore unverified and must be tested on a device.

Apple's current `UNUserNotificationCenter` documentation exposes adding,
inspecting, and removing pending requests but does not state a current numeric
pending-request limit. Older deprecated `UILocalNotification` documentation
states that the system kept the soonest 64 notifications, with repeating
notifications counting as one. That historical limit cannot safely be claimed
as the current `UNNotificationRequest` contract; capacity remains an explicit
device test, especially for the finite monthly branch.

## Current Apple documentation review

- [AlarmKit](https://developer.apple.com/documentation/alarmkit) is available for iOS/iPadOS 26 and provides authorized, prominent alarms with one-time and repeating support.
- [Scheduling an alarm with AlarmKit](https://developer.apple.com/documentation/alarmkit/scheduling-an-alarm-with-alarmkit) documents fixed alarms and weekly-relative recurrence. It does not document monthly recurrence.
- AlarmKit's [traditional alarm configuration](https://developer.apple.com/documentation/alarmkit/alarmmanager/alarmconfiguration/alarm%28schedule%3Aattributes%3Astopintent%3Asecondaryintent%3Asound%3A%29) accepts an `AlertSound` value per configuration, but no independent vibration-only option is documented.
- [UNCalendarNotificationTrigger](https://developer.apple.com/documentation/usernotifications/uncalendarnotificationtrigger) supports date-component matching and repeating triggers. [The repeating initializer](https://developer.apple.com/documentation/usernotifications/uncalendarnotificationtrigger/init%28datematching%3Arepeats%3A%29) says `repeats: true` reschedules after delivery.
- [Local notification scheduling](https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app) documents alert/sound/badge content, delivery while the app is not running, and cancellation, but not a haptic-only request or app-selected alert duration.
- [Pending-request inspection](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter/getpendingnotificationrequests%28completionhandler%3A%29) documents how to inspect pending requests. The [deprecated local-notification documentation](https://developer.apple.com/documentation/uikit/uilocalnotification) is the source of the historical 64-request statement, not a current `UNUserNotificationCenter` limit.

These are documentation findings, not device observations. AlarmKit authorization requires the app's `NSAlarmKitUsageDescription` key and user consent; this source-only probe has no Info.plist or entitlement.

## Evidence to collect

| Question | Result |
| --- | --- |
| Can a configured occurrence alert briefly without continuous vibration? | Untested on device; duration/haptics are system-controlled |
| Is per-alarm vibration-only supported with no audible sound? | Not established; no documented per-alarm haptic-only API |
| What changes with Silent Mode, Focus, and haptic settings? | Untested |
| Does weekly recurrence behave correctly while locked and app terminated? | Untested |
| Can monthly recurrence persist without reopening the app? | Not established; AlarmKit docs cover weekly recurrence, probe uses finite local-notification expansion |
| What scheduling limits and time-zone behavior apply? | Untested; monthly probe uses autoupdating local calendar |
| What survives restart, and when? | Untested |

## Checks run

- Repository inspection: passed; no pre-existing app target or build configuration.
- Environment inspection: passed; Windows host identified, Apple build tools unavailable.
- Xcode project parse/build: passed in the first GitHub Actions simulator workflow run, `T01 iOS simulator validation` (reported green by the owner; run ID was not recorded here).
- Simulator check: passed in GitHub Actions on the cloud macOS runner; this validates compilation for the iOS Simulator only.
- Signed archive/TestFlight upload: not run; Apple identifiers, signing materials, App Store Connect credentials, and the app record must be configured.
- Physical iPhone check: pending; no device delivery, audibility, haptics, lock-screen, recurrence, or notification behavior has been verified.

## TestFlight preparation

The separate manually triggered workflow is [`.github/workflows/t01-testflight.yml`](../.github/workflows/t01-testflight.yml).
It is preparation only until the account setup in [DEPLOYMENT.md](DEPLOYMENT.md) is complete.
The workflow uses a temporary macOS keychain, downloads the App Store provisioning
profile for the configured App ID, creates a unique build number from the GitHub
run, and uploads only the IPA to App Store Connect. It does not commit or upload
certificates, private keys, provisioning profiles, archives, or credentials as
repository files. Release diagnostics contain build/export output only.

## Setup and physical-device test procedure required before T02

On a Mac with Xcode 26 or later:

1. Open `T01Prototype/T01PrototypeApp.xcodeproj`.
2. Select the `T01PrototypeApp` scheme and an iPhone simulator or connected iPhone.
3. Set a unique bundle identifier and select a signing team for a physical iPhone.
4. Build and run. Grant notification permission.
5. Tap the sound and no-sound buttons using times two minutes ahead.
6. Tap both monthly buttons. Inspect pending requests and compare the finite
   and repeating branches.
7. Repeat with the screen locked, app backgrounded, app terminated, Silent
   Mode, Focus, and haptics enabled/disabled.
8. For the repeating monthly branch, test across a month without day 31 and
   record whether the 31st request skips, shifts, fails, or behaves otherwise.
9. Record audio, haptic behavior, alert duration, lock-screen presentation,
   pending-request count, and next occurrence.

The simulator cannot establish physical audibility or haptic behavior. Do not
mark vibration-only supported merely because the no-sound test is silent.

Do not mark vibration-only or monthly indefinite recurrence supported unless
the physical observations and the current SDK behavior support them.

For each check, record the device/OS, setup, expected result, observed result, timestamp, and documentation link if applicable. Distinguish documentation claims from physical observations. Capture unsupported requirements and concrete alternatives before updating scope.
