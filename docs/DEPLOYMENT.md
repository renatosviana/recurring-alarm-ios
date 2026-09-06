# Deployment and monitoring

Status: NOT DEPLOYED. This starter has no application target or CI workflow yet.

## Personal installation (T09)

1. Build the implemented Xcode project on a compatible Mac.
2. Configure the actual bundle identifier and signing team using the owner's account.
3. Select the connected iPhone and complete required device setup.
4. Build and run, grant alarm permissions, and execute the physical-device checklist.
5. Document the account's signing/installation expiry and renewal constraints. Do not describe a development-signed installation as permanent.

Exact project, scheme, deployment target, and commands must be added after implementation, not invented in this starter.

## CI (T10)

Add a GitHub Actions macOS workflow for the actual project and shared scheme. Run a build and meaningful unit tests on pull requests. Simulator CI does not verify haptics. Keep signing certificates, profiles, keys, and tokens out of git; use the appropriate secret store if distribution automation is added.

## TestFlight (T11, optional)

Check current Apple Developer Program and App Store Connect prerequisites. Prepare a signed archive, version/build number, release notes, and beta test instructions. Upload using the owner's authorized account; complete applicable Apple processing/review steps. Record any beta expiry and update needs. Public App Store release is a separate scope decision.

## Monitoring (T12)

Log scheduling/cancellation outcomes and errors with non-sensitive identifiers. Do not log alarm labels by default. Review available diagnostics and user feedback, reproduce failures, add relevant regression checks, then release a corrected version. An agent can inspect provided logs; it cannot continuously monitor an iPhone or prove the user felt a vibration. Avoid claiming delivery from scheduling success alone.
