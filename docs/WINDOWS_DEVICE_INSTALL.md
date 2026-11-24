# Free Windows device-install route

Owner device: iPhone16, reported iOS27.2.1. No existing sideload setup or Mac.
Candidate route: Sideloadly on Windows using a free Apple account and the unsigned
IPA from CI. Sideloadly currently advertises Windows/iOS27+ support and free Apple
IDs; this is vendor-documented compatibility, not a verified install on this phone.
https://sideloadly.io/

1. Use the official Sideloadly page and its Apple iTunes/iCloud prerequisite links.
   Review the installed driver versions before changing an existing installation.
2. Connect and pair the iPhone by USB. The owner handles device trust/developer-mode
   prompts and enters Apple account credentials/2FA directly in the signing tool.
3. Load PuzzleAlarm-Unsigned.ipa and sign/install with the free account. Do not use
   the Simulator Appetize ZIP. Keep bundle identifier and app contents unchanged.
4. Free provisioning expires after7days; Sideloadly documents automatic refreshing.
   The owner must verify refreshing actually works before relying on the alarm.
   Apple also documents Personal Team limits and7day provisioning expiry:
   https://developer.apple.com/help/account/basics/about-your-developer-account
5. Test real permission denial/allow, foreground/background/locked alarm firing,
   primary Stop versus remaining backups, Solve routing, all challenges, wrong and
   matching camera QR, bundled/default sound, cleanup failure/retry and relaunch.

No paid plan, jailbreak, credentials in CI, private APIs or automatic system changes.
The unsigned IPA cannot run until signed. Device install/capability support remains
NOT VERIFIED until the owner completes the actual installation and test checklist.
