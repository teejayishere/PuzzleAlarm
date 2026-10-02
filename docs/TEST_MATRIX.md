# Evidence ledger

No gate has passed. No automated app/domain tests exist yet.

| Capability | Status | Evidence |
| --- | --- | --- |
| Repository/environment inspection | IMPLEMENTED | 2026-09-30: directory and command discovery; current starting folder was Investment Dashboard, not a git repository |
| Swift tooling | BLOCKED | Get-Command swift returned no command; common locations absent |
| Linux fallback | BLOCKED | wsl --list --quiet reported WSL not installed |
| Swift manifest parsing | BLOCKED | swift package dump-package cannot run without Swift |
| Core module compilation | BLOCKED | swift build cannot run without Swift |
| YAML structural validation | AUTOMATED PASS | 2026-09-30: Node + existing js-yaml parsed both YAML files; checked triggers, public-only guard, read-only permissions, iOS deployment setting and empty target boundary |
| Secret/dependency review | AUTOMATED PASS | 2026-09-30: 16 files reviewed; common secret-pattern and whitespace scans passed; Package.swift has no dependencies; this is not an exhaustive secret audit |
| Gate 0 | BLOCKED | Compiler evidence missing |
| Stage 1 domain/tests | NOT STARTED | Must follow Gate 0 |
| Xcode project / iOS app | NOT STARTED | project.yml has no targets; Stage 2 |
| macOS CI | BLOCKED | No remote / run observed |
| AlarmKit compile spike | NOT STARTED | Stage 3; no API signatures invented |
| Persistence / scheduling / challenges / UI | NOT STARTED | Later ordered gates |
| Physical alarm/camera/audio/provisioning | DEVICE REQUIRED | No device observations |

A future successful scaffold build is tooling evidence only.

Specification copy: byte-for-byte match; SHA256 5bcebc02bce9554c1fec468cbf12d4d55f4ca19d36853c08879a8f76b1636cf5.
Git repository initialized on main; no commits or remotes. No CI evidence.
