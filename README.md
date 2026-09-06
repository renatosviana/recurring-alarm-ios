# Recurring Alarm for iPhone

An iPhone alarm project with per-alarm sound or vibration preferences and one-time, weekly, and monthly schedules.

**Status: planning starter. No Swift app, Xcode project, working alarms, or deployment is included yet.** Platform feasibility is the first task. Target iPhone initially; a Mac is the development computer, not an additional app target.

## Start here

1. Read [the specification](SPEC.md), [architecture](ARCHITECTURE.md), and [tasks](TASKS.md).
2. Open this repository in your coding agent and use [the starting prompt](docs/CODEX_START.md).
3. Begin T01. Record the iPhone model, iOS version, Mac/Xcode availability, and SDK version. Do not claim device checks passed when only simulator or code checks ran.
4. Complete tasks sequentially, reviewing changes and evidence after each task.

## GitHub setup

Suggested repository name: `recurring-alarm-ios`

Suggested description: `An iPhone alarm app with configurable sound or vibration and weekly and monthly schedules. Built step by step with coding agents.`

Extract the ZIP. Create an empty repository on GitHub with the name above. Do not initialize that remote with a README, license, or gitignore because this starter already contains files. In a terminal inside the extracted recurring-alarm-ios folder, run:

```sh
git init
git add .
git commit -m "Add alarm project specification and implementation plan"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/recurring-alarm-ios.git
git push -u origin main
```

Replace YOUR_USERNAME with your GitHub username. Use GitHub's normal authentication flow; never put tokens in project files. Push the extracted files, not just the ZIP. Review repository visibility before creating it.

## Build and deployment

Build instructions will be added when T01 creates the Xcode prototype. There is currently no build command or executable. See [deployment](docs/DEPLOYMENT.md) and [verification](docs/TEST_PLAN.md).

## Reference documentation

- https://developer.apple.com/documentation/alarmkit
- https://developer.apple.com/videos/play/wwdc2025/230/
- https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices
- https://developer.apple.com/testflight/

Consult the current SDK documentation during T01; these references do not establish vibration-only or brief-alert support.
