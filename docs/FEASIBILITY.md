# T01 feasibility record

Status: T01 FEASIBILITY COMPLETE FOR REVISED CURRENT-RELEASE SCOPE: sound alerts and silent notifications are in scope; vibration-only is deferred as an unresolved future requirement. T02 is complete; T03 has not started. Physical delivery and recurrence checks remain untested where recorded below.

Timestamp: 2026-09-06 (America/New_York)

## TestFlight rejection 2026-09-07

Build `3414102912101` was rejected during App Store review with:

- `ITMS-90022`: the archive did not contain the required 120x120 iPhone PNG icon.
- `ITMS-90713`: the built Info.plist did not contain `CFBundleIconName`.
- `ITMS-90725`: the archive was built with the iOS 18.5 SDK, while the submission requires the iOS 26 SDK or later.

Fixes applied in this checkout:

- Added an opaque temporary `AppIcon.appiconset` with 120x120, 180x180, and 1024x1024 PNGs.
- Added the asset catalog to the app target Resources phase and set `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` plus the generated-plist icon name setting for Debug and Release.
- Updated both GitHub workflows to select an installed Xcode 26+ bundle explicitly, print `xcodebuild -version` and SDK versions, and fail before building if the selected iPhoneOS SDK is older than 26.
- Preserved the existing manual signing/export configuration in the TestFlight workflow and the unsigned simulator build flags in the simulator workflow.

These changes address packaging and toolchain rejection reasons only; they do not establish signed-upload or physical-device evidence required for release validation.

## TestFlight processing polling limitation

The `apple-actions/upload-testflight-build@v5` App Store API backend generates one JWT with a 600-second lifetime before upload and passes that same token to its visibility and processing polls. The action source does not refresh the token during polling. A 401 `NOT_AUTHORIZED` after approximately 13 minutes is therefore consistent with token expiry during polling; it is not evidence that the configured API key is invalid, so the API key was not replaced.

The TestFlight workflow now sets `wait-for-processing: 'false'`. This avoids the unreliable long-lived poll and allows the upload handoff to complete, but the action skips release-note and encryption metadata updates when waiting is disabled. A successful workflow now means only that the IPA upload completed; Apple processing, review, and TestFlight acceptance must be checked separately in App Store Connect. No credential values were changed.

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
- `.vibrationOnly` maps to no configured sound (`sound = nil`) only. UserNotifications does not expose a public per-request haptic-only setting, so this is not a vibration-only implementation and does not satisfy the requirement.
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
the reviewed API does not expose a per-alarm vibration-only control. Supplying
no configured sound would still not document or guarantee haptic delivery.

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
- Apple's [Clock alarm documentation](https://support.apple.com/en-ie/guide/iphone/-iph2909d3a74/ios) documents choosing a vibration as an alarm's Sound and says Clock alarms sound through Silent Mode and Focus. This confirms system-app behavior, not third-party access to the same alarm implementation.
- [UNCalendarNotificationTrigger](https://developer.apple.com/documentation/usernotifications/uncalendarnotificationtrigger) supports date-component matching and repeating triggers. [The repeating initializer](https://developer.apple.com/documentation/usernotifications/uncalendarnotificationtrigger/init%28datematching%3Arepeats%3A%29) says `repeats: true` reschedules after delivery.
- [Local notification scheduling](https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app) documents alert/sound/badge content, delivery while the app is not running, and cancellation, but not a haptic-only request or app-selected alert duration.
- [Pending-request inspection](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter/getpendingnotificationrequests%28completionhandler%3A%29) documents how to inspect pending requests. The [deprecated local-notification documentation](https://developer.apple.com/documentation/uikit/uilocalnotification) is the source of the historical 64-request statement, not a current `UNUserNotificationCenter` limit.
- Apple's [Notifications HIG](https://developer.apple.com/design/human-interface-guidelines/notifications) explicitly says that an app cannot provide notification vibration programmatically. A request with `UNMutableNotificationContent.sound = nil` therefore means no configured notification audio; it is not a supported haptic-only request.
- [Core Haptics](https://developer.apple.com/documentation/corehaptics) can play app-driven haptic patterns, but it requires a running app-owned haptic engine. Apple documents that the engine can stop when the application is suspended ([application-suspended stop reason](https://developer.apple.com/documentation/corehaptics/chhapticengine/stoppedreason/applicationsuspended)); it is not a scheduler for locked-screen delivery.
- The current documentation review found no documented iOS API that exposes a scheduled, app-selected vibration-only alert while the iPhone is locked. This is not proof that every third-party approach is impossible. UserNotifications can deliver a notification while the app is not running, and AlarmKit can present a prominent scheduled alarm, but neither currently documents the required independent vibration-only control.
- The Clock app's vibration-only alarm behavior demonstrates that Apple can implement this product behavior in a system app; it does not establish that third-party apps receive the same private alarm mechanism.
- Revised conclusion: sound alerts and silent notifications are in the current release scope. Vibration-only remains unresolved and is deferred as a future requirement. It is not replaced by silent notifications, and no silent-audio experiment will be run for this release.

These are documentation findings, not device observations. AlarmKit authorization requires the app's `NSAlarmKitUsageDescription` key and user consent; this source-only probe has no Info.plist or entitlement.

## Physical-device result record 2026-09-07

The following physical-device observations were reported for the locked-screen sound and no-sound tests. Other items remain explicitly unrecorded rather than being inferred from simulator or documentation behavior:

| Question | Physical result |
| --- | --- |
| Sound alarm while locked | Notification, sound, and vibration |
| No-sound alarm while locked | Notification, no sound, and no vibration |
| Alert duration and repeat behavior | Not run / no observation supplied |
| Silent Mode, Focus, notification, and haptic settings | Not run / no observation supplied |
| App terminated or device restarted | Not run / no observation supplied |

The documentation conclusion above is sufficient to reject “reliable scheduled vibration-only alert while locked” as a supported API capability. The reported no-sound result confirms this test run but does not establish an app-controlled vibration-only capability. No full physical-device pass is claimed.

## Vibration-only requirement investigation

The requirement is per-alarm behavior: one scheduled alarm must produce haptics
without audio, independently of other alarms. The following system settings are
phone-wide or notification-policy controls; they are not per-alarm controls and
cannot make the app's request a supported haptic-only API.

| Mechanism | What Apple documents | Requirement status |
| --- | --- | --- |
| `UNMutableNotificationContent.sound = nil` | No notification sound is configured; the notification system controls presentation. | Not a haptic request; fails the per-alarm requirement. |
| AlarmKit `AlertSound` | AlarmKit accepts a sound value for a traditional alarm. | No documented vibration-only value; fails the per-alarm requirement. |
| Silent Mode | Suppresses many sounds; the iPhone may still vibrate. | Phone-wide behavior, not per-alarm control; cannot guarantee vibration. |
| Settings > Sounds & Haptics > Haptics | The user can choose Always Play, Play in Silent Mode, Don't Play in Silent Mode, or Never Play for alerts. | Phone-wide user preference; the app cannot select it for one alarm. |
| Focus / notification authorization | Focus can filter notifications; notification authorization and app notification settings can suppress delivery. | Phone-wide or app/system policy; not a per-alarm haptic mechanism. |
| Critical Alerts | With a separate entitlement, a critical notification can override Silent Mode and Focus. | Still a sound/notification policy exception, not a documented haptic-only channel; not a viable substitute. |
| Core Haptics | An app can play haptic patterns while its haptic engine is running. | Not a scheduled locked-screen delivery mechanism; the engine can stop when the app is suspended. |

The locked-screen result reported on 2026-09-07—notification, no sound, and no
vibration—demonstrates that the no-sound branch does not reliably produce the
required haptic. It is an experiment result, not an API contract. Device tests
can still characterize Silent Mode, Haptics settings, Focus, notification
authorization, app termination, restart, and iOS versions, but a passing result
under one configuration would not establish per-alarm control.

The silent-custom-sound experiment is deferred. No code or release behavior
should depend on it.

## Evidence to collect

| Question | Result |
| --- | --- |
| Can a configured occurrence alert briefly without continuous vibration? | Untested on device; duration/haptics are system-controlled |
| Is per-alarm vibration-only supported with no audible sound? | Deferred unresolved future requirement; no silent-audio experiment run |
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
- Physical iPhone check: partial; the locked-screen sound and no-sound alarm tests were observed, while recurrence, settings, and other device behaviors remain untested.

## TestFlight preparation

The separate manually triggered workflow is [`.github/workflows/t01-testflight.yml`](../.github/workflows/t01-testflight.yml).
It is preparation only until the account setup in [DEPLOYMENT.md](DEPLOYMENT.md) is complete.
The workflow uses a temporary macOS keychain, downloads the App Store provisioning
profile for the configured App ID, creates a unique build number from the GitHub
run, and uploads only the IPA to App Store Connect. It does not commit or upload
certificates, private keys, provisioning profiles, archives, or credentials as
repository files. Release diagnostics contain build/export output only.

## Setup and physical-device test procedure required before implementation/release validation

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
