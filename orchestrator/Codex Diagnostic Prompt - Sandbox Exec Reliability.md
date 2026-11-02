# Codex Diagnostic Prompt — Sandbox Exec Reliability

Paste this into Codex (its own app/CLI) to have it diagnose and fix the
reliability problems observed in its own sandboxed shell exec on this
machine.

---

I'm running codex-cli 0.166.0-alpha.5.1 on Windows 11 (installed via the
OpenAI Codex desktop app, binary at
`%LOCALAPPDATA%\OpenAI\Codex\bin\<version-hash>\codex.exe`). I need you to
diagnose and fix two reliability problems with your own sandboxed shell
exec on this machine, reproduced via `codex exec` with these flags:

```
codex exec "<prompt>" --sandbox read-only -C <repo-path> \
  --skip-git-repo-check --ephemeral \
  --output-last-message <file>
```

**Failure 1:** The very first shell command you (Codex) attempted — a
PowerShell invocation via your unified exec tool — failed immediately
with:

```
ERROR codex_core::tools::router: error=exec_command failed:
CreateProcess { message: "Rejected(\"Failed to create unified exec
process: CreateProcessWithLogonW failed: 267\")" }
```

Windows error 267 is `ERROR_DIRECTORY`. This looks like your sandboxed
process-spawn path (likely using `CreateProcessWithLogonW` for isolation/
impersonation on Windows) is failing outright in this environment —
possibly related to the working directory being a OneDrive-synced path,
a non-elevated/non-admin shell context, or how the sandbox token is being
constructed. Find the actual root cause of why `CreateProcessWithLogonW`
returns 267 here, and fix it — don't just catch/retry around it.

**Failure 2:** After recovering from Failure 1 by falling back to raw
PowerShell, your next attempt tried to invoke `rg` (ripgrep) directly,
which failed with:

```
rg : The term 'rg' is not recognized as the name of a cmdlet, function,
script file, or operable program.
```

Ripgrep *is* bundled with this Codex install — I found `rg.exe` at
`%LOCALAPPDATA%\OpenAI\Codex\bin\<another-version-hash>\rg.exe` — but it
is not on PATH inside the shell environment your sandbox spawns
subprocesses in. Diagnose why your own sandbox's child-process
environment doesn't include your bundled tools directory on PATH, and
fix it so `rg` (and anything else you bundle) is reliably callable from
inside your own exec sandbox without me having to fall back to
`Select-String`.

**After fixing both:** re-run an equivalent repro (any prompt that causes
you to inspect a real file via your exec tool, under
`--sandbox read-only -C <some-repo>`) and confirm the first shell
invocation succeeds cleanly, using `rg` if you choose to, with no
fallback retries required.
