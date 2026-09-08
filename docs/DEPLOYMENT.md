# Deployment and TestFlight preparation

Status: NOT DEPLOYED. The simulator build is green and T04 is complete for the
revised scope, but release deployment and remaining physical-iPhone checks are
still pending. Per-alarm vibration-only is deferred as an unresolved future
requirement. Do not begin T05 from a simulator result alone.

The release workflow is [`.github/workflows/t01-testflight.yml`](../.github/workflows/t01-testflight.yml).
It is separate from simulator validation and has only `workflow_dispatch`; it
does not run on pushes or pull requests.

## Account setup required before an upload can run

Complete these steps first. The workflow will intentionally fail before signing
if the bundle ID is still the placeholder `local.t01-alarm-probe` or any
required value is missing.

### 1. Choose the App ID and Team ID

Choose a globally unique reverse-DNS bundle identifier that you control, for
example `com.yourname.t01alarmprobe`. It must be explicit, not a wildcard.
Do not use the example literally.

In Apple Developer, open Certificates, Identifiers & Profiles → Identifiers,
register an App ID for that exact bundle identifier, and note the 10-character
Team ID shown for your membership. The bundle identifier used by the upload,
the App ID, the App Store record, and the provisioning profile must match
exactly.

The project currently contains a development placeholder. Do not commit a
personal identifier merely to configure CI. The release workflow supplies your
chosen values at build time using `PRODUCT_BUNDLE_IDENTIFIER` and
`DEVELOPMENT_TEAM`.

In GitHub, add these repository **variables** under Settings → Secrets and
variables → Actions → Variables:

| Variable | Value |
| --- | --- |
| `T01_BUNDLE_IDENTIFIER` | Your explicit App ID, such as `com.example.t01alarmprobe` |
| `T01_TEAM_ID` | Your Apple Developer Team ID |
| `APPSTORE_ISSUER_ID` | The App Store Connect API Issuer ID UUID |
| `APPSTORE_API_KEY_ID` | The App Store Connect API key ID |

These identifiers are not passwords, but do not print them unnecessarily in
workflow logs.

### 2. Create the App Store Connect app record

In App Store Connect → My Apps, click `+` → New App. Select iOS, enter the app
name, primary language, bundle ID matching the registered App ID, and a SKU of
your choice. The app record must exist before the first upload; the uploaded
binary is matched using its bundle identifier and version/build values.

Complete any required agreements and banking/tax prompts for the account. The
first upload may take time to process before it appears in TestFlight.

### 3. Create the Apple Distribution certificate

The workflow expects a PKCS#12 export containing the Apple Distribution
certificate and its private key. A `.cer` file alone is not sufficient.

On a Mac, create a Certificate Signing Request in Keychain Access, create an
Apple Distribution certificate in Apple Developer using that request, download
the certificate, install it into the login keychain, select the certificate and
private key under My Certificates, and export them as a password-protected
`.p12`.

From Windows, install OpenSSL from a trusted source and run these commands in
PowerShell (replace the subject email with yours):

```powershell
openssl req -new -newkey rsa:2048 -nodes `
  -keyout ios_distribution.key `
  -out ios_distribution.csr `
  -subj "/emailAddress=you@example.com/CN=T01 Apple Distribution"
```

In Apple Developer, create the Apple Distribution certificate, upload
`ios_distribution.csr`, and download the resulting `ios_distribution.cer`.
Then create the PKCS#12 file while the private key and certificate are still
in the same private Windows directory:

```powershell
openssl x509 -inform DER -in ios_distribution.cer -out ios_distribution.pem
openssl pkcs12 -export `
  -inkey ios_distribution.key `
  -in ios_distribution.pem `
  -out ios_distribution.p12 `
  -name "Apple Distribution"
openssl pkcs12 -info -in ios_distribution.p12 -noout
```

The last command must report a private key and certificate; it should not print
the private key itself. Enter a strong export password and keep it available
only for the GitHub secret setup. Encode the `.p12` without adding line breaks:

```powershell
$bytes = [IO.File]::ReadAllBytes((Resolve-Path .\ios_distribution.p12))
[Convert]::ToBase64String($bytes) | Set-Clipboard
```

Paste the clipboard value into the GitHub secret and then securely delete the
local `.p12`, `.pem`, `.cer`, `.csr`, and `.key` copies when you have verified
the secret. Never commit any of them. If the private key is lost before the
`.p12` is created, revoke that certificate and create a replacement.

For either route, encode the `.p12` as one base64 value and put that value in
the GitHub secret `APPSTORE_CERTIFICATES_FILE_BASE64`; put only its password in
`APPSTORE_CERTIFICATES_PASSWORD`. GitHub documents base64 as a transport format,
not encryption; the GitHub secret is the protection boundary.

### 4. Create the App Store provisioning profile

In Apple Developer → Profiles, create an iOS App Store provisioning profile.
Choose the explicit App ID from step 1 and the Apple Distribution certificate
from step 3. Download the profile and inspect its name if desired, but do not
commit it.

This repository does not need a profile secret: the workflow uses the
App Store Connect API to download the matching `IOS_APP_STORE` profile into the
ephemeral macOS runner. This also avoids storing a profile copy in GitHub.
The profile must include the application identifier for the app to be eligible
for TestFlight.

If you prefer to use the cloud macOS workflow for the profile step, complete
the App ID and certificate setup first; the `download-provisioning-profiles`
step will retrieve and install the profile using the API credentials below.
The workflow deliberately does not generate a new private key on a hosted
runner and expose it for download. Create the certificate/private-key pair on
Windows or a trusted Mac, convert it to the protected `.p12`, and store it as
the GitHub secret before using cloud signing.

### 5. Create App Store Connect API credentials

An Account Holder or Admin must enable/request App Store Connect API access in
App Store Connect → Users and Access → Integrations. Create a team API key with
at least the App Manager role, then download the `.p8` private key immediately;
Apple provides that private key only at creation/download time. Record the Key
ID and Issuer ID.

Add the `.p8` file contents, including its BEGIN/END lines, as the GitHub
**secret** `APPSTORE_API_PRIVATE_KEY`. Add the Key ID and Issuer ID as the
repository variables listed above. Revoke the key in App Store Connect if it
is exposed or no longer needed.

## GitHub configuration checklist

Required variables:

- `T01_BUNDLE_IDENTIFIER`
- `T01_TEAM_ID`
- `APPSTORE_ISSUER_ID`
- `APPSTORE_API_KEY_ID`

Required secrets:

- `APPSTORE_API_PRIVATE_KEY` — contents of `AuthKey_<key-id>.p8`.
- `APPSTORE_CERTIFICATES_FILE_BASE64` — base64 of the password-protected `.p12` containing the Apple Distribution certificate and private key.
- `APPSTORE_CERTIFICATES_PASSWORD` — the `.p12` export password.

No certificate, `.p12`, `.cer`, `.p8`, private key, provisioning profile,
archive, or IPA belongs in Git. Do not use `echo`, `set -x`, debug tracing, or
diagnostic commands that print secret environment variables. The workflow does
not print the API key, certificate, private key, profile contents, archive, or
IPA. Its failure artifact contains only the archive/export command output;
review it before sharing because third-party tool output can vary.

## Run the cloud upload

After all account and GitHub setup above is complete:

1. Push this workflow to the repository's default branch.
2. Open GitHub → Actions → `T01 TestFlight upload` → Run workflow.
3. Enter the marketing version. Keep `0.1` for this prototype unless the app
   record requires another version. Optionally enter concise TestFlight release
   notes.
4. Start the run and wait for the archive, export, and App Store Connect upload
   steps to complete. The workflow derives a unique numeric build number from
   the GitHub run ID and attempt, so reruns do not reuse the same build number.
5. If it fails, download the `t01-testflight-diagnostics-<run-id>` artifact.
   It contains archive/export diagnostics, not signing materials. Fix the
   reported setup or signing issue and run again; do not paste secrets into an
   issue or log.
6. In App Store Connect → My Apps → the app → TestFlight, wait for Apple to
   finish processing the build. A successful GitHub upload is not the same as
   completed Apple processing.

The upload action uses the App Store Connect API and waits for processing. It
sets non-exempt encryption to false because this prototype does not implement
encryption beyond ordinary platform HTTPS; revisit that answer if the app adds
cryptography or third-party SDKs.

## Enable internal TestFlight testing

1. In App Store Connect → Users and Access, add each internal tester as an
   App Store Connect user, or use an existing user. Internal testers must have
   access to the app in App Store Connect; they are not just arbitrary email
   addresses.
2. In the app's TestFlight tab, create or select an internal testing group.
3. Add the processed build to that group and add the internal testers.
4. Complete the beta app information and export-compliance questions that
   App Store Connect presents. Wait until the build shows as available to the
   group.

## Install on the iPhone and perform T01 checks

1. On the iPhone, sign in to the App Store with an Apple ID that is an internal
   tester, and install TestFlight from the App Store.
2. Accept the TestFlight invitation from the email or the internal link shown
   by App Store Connect.
3. Install the T01 build in TestFlight, grant notification permission, and
   record the iPhone model, iOS version, app version/build, and timestamp.
4. Run the physical-device checklist in `docs/FEASIBILITY.md`: sound and
   no-sound behavior, lock screen, app background/termination, Silent Mode,
   Focus, haptics, weekly recurrence, finite monthly expansion, repeating day
   31 behavior, pending-request capacity, restart, and time-zone behavior.
5. Record observed results as pass, fail, or not run. TestFlight installation
   and notification scheduling do not by themselves prove audible or haptic
   delivery.

## Windows and cloud limitations

Windows can prepare the Apple portal objects, generate a CSR/private key, and
store the resulting encoded values in GitHub Secrets. Windows cannot run
`xcodebuild`, sign with the Apple SDK, create an IPA, or install the build
directly. The manually triggered GitHub-hosted macOS runner performs those
steps. A Mac with Xcode is an alternative for creating/exporting signing
materials and for direct device debugging, but is not required for the upload
workflow once the account setup and secrets are correct.

## T01 boundary

T01 feasibility is complete for the revised scope, but signed-build and
remaining physical checks are still open. Do not mark vibration-only behavior,
monthly indefinite recurrence, or any other open feasibility question as
supported based on the simulator build or TestFlight upload alone. T05 has not
started.
