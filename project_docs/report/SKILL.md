---
name: report-module-parity
description: Rebuild or extend a Flutter report and telemetry module so it matches this project's current rigor, including lifecycle-driven reporting, permission timing, native data collection, location caching fallback, deduplicated market and push-token reporting, encrypted device payload upload, and third-party attribution SDK initialization. Use when asked to generate or refactor a report module while keeping filenames flexible.
---

# Report Module Parity

Use this skill when the task is to generate, rebuild, refactor, or audit a Flutter report or telemetry module that must remain behaviorally equivalent to this repository's current report stack, even if names and file layout change.

## Outcome

Produce a report module with the same orchestration strictness as the current project:

- One lifecycle-aware manager that owns startup, resume, and login-success reporting entry points.
- Timed permission requests for notifications and tracking.
- First-launch ATT resolution listening.
- Google market reporting with deduplication and follow-up attribution SDK initialization.
- Native location fetch with pending-future reuse and cache fallback.
- Risk payload and device payload builders with fixed field semantics.
- Encrypted device-info upload.
- Push-token fetch, wait, stream-listen, dedupe, and auto-report flow.
- Face-recognition result reporting.

## First steps

1. Inspect the current workspace report module before writing code.
2. Identify the protocol and flow facts that must not drift:
   - startup-only trigger behavior
   - first-launch handling
   - login-success side effects
   - permission timing and throttling
   - market-report dedupe signature
   - attribution SDK init gate
   - location cache fallback behavior
   - push-token wait and stream behavior
   - encrypted device-info upload shape
   - uptime versus elapsed split
3. Separate invariant behavior from project-specific field names and SDK configuration.
4. Keep project-variant values configurable, but do not weaken the orchestration flow.

## Non-negotiable behavior rules

### Lifecycle ownership

- Keep one manager responsible for report orchestration.
- Startup work must be idempotent.
- Resume work must not re-run all startup work.
- Login-success work must refresh login-derived reporting state.

### Permission timing

- Notification permission and tracking permission must be separate flows.
- Permission requests should wait until the app is resumed and a frame is ready.
- Use throttling delays to avoid stacked system prompts.
- Protect startup and resume permission flows against reentry.

### First-launch ATT resolution

- On first launch, listen for ATT/IDFA permission changes.
- Ignore non-final statuses like empty, `not_supported`, and `not_determined`.
- Once a final state arrives, trigger market reporting and dispose the listener.

### Market reporting

- Build a dedupe signature from device identifiers.
- Skip reporting when the signature is empty, already reported, or currently reporting.
- Extract the attribution SDK token from the response and attempt initialization.

### Attribution SDK init

- Initialize only when the token is non-empty and local state says init has not happened.
- Reuse the project's current persistence mechanism for the initialized flag.
- Treat failures as non-blocking.

### Location behavior

- Reuse a pending native-location future to avoid duplicate parallel fetches.
- Cache successful location payloads for later fallback.
- If live location is unavailable, risk and device reporting may use cached location.

### Device payload semantics

- Build device payloads in one helper layer, not inline in UI code.
- Preserve separate fields for uptime and elapsed time.
- Do not mutate the old uptime field to satisfy the new elapsed field.
- Collect device, battery, network, Wi-Fi, storage, locale, carrier, and identifier data from native or approved Flutter fallbacks.

### Push-token reporting

- Try direct token fetch first.
- If empty, wait on the push-token stream with timeout.
- Keep a long-lived token-change listener for future auto-reports.
- Deduplicate by current-report token and last-success token.

### Failure policy

- Report-path failures should log and return.
- Do not let telemetry/report failures block startup, login, face flow, or page interactions.

## Implementation guidance

- Prefer a compact set of focused units:
  - report orchestration manager
  - payload helper
  - location model
  - native-bridge dependency
  - cache dependency
  - attribution SDK init helper
  - network-report dependency
- Keep pages and controllers free of protocol payload assembly.
- Normalize raw values once through helper methods instead of repeating ad hoc string cleanup everywhere.
- If the native side is missing a capability, provide stable fallback values instead of throwing.

## What may stay configurable or blank

These may stay as placeholders when scaffolding a reusable equivalent module:

- field-name mappings inside payloads
- network endpoint bindings
- attribution SDK vendor and token field name
- permission delay durations
- timeout durations for location and push token waits
- cache key names
- native bridge method names where the target project differs

Do not leave lifecycle flow, deduplication logic, cache fallback, or init gating unspecified.

## Verification checklist

Before finishing, verify:

- startup entry runs only once
- first-launch ATT listening is released after resolution
- resume only refreshes tracking-related flow
- login success refreshes login timestamp and follow-up reports
- market-report dedupe blocks duplicates correctly
- attribution SDK init is one-time and persisted
- location fetch reuses a pending future
- cached location can backfill risk or device reporting
- device payload keeps elapsed and uptime separate
- push token can be fetched directly, awaited from stream, and auto-reported on later changes
- failures remain non-blocking and are logged through the shared error adapter

## Reference

For the exact task decomposition and acceptance rules in this workspace, read:

- `project_docs/report_module_task_checklist.md`
