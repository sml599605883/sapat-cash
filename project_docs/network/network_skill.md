---
name: network-module-parity
description: Rebuild or extend a Flutter network request module so its behavior matches this project's current protocol rigor, including unified response shell, auth-expiry handling, GET/POST/upload parameter placement, dynamic common params, sign generation, optional encrypted reporting, and dynamic base URL bootstrap. Use when asked to generate or refactor a network layer with parity to the existing module while keeping filenames flexible.
---

# Network Module Parity

Use this skill when the task is to generate, rebuild, refactor, or audit a Flutter network request module that must stay behaviorally equivalent to this repository's existing network layer, even if the implementation names or file names change.

## Outcome

Produce a network module with the same protocol strictness as the current project:

- Unified response shell with business code, message, and payload.
- Unified response handling with business success checks and auth-expiry branch.
- Shared GET, POST, and multipart upload helpers with the same query/body placement rules.
- Dynamic common-parameter provider support.
- Central key mapping for common parameters.
- Stable signature generation based on mapped common parameters plus request path.
- Fixed-format numeric random suffix fields where required.
- Optional AES-based encrypted reporting support.
- Startup base-URL bootstrap with default probe, remote fallback, and Base64-tolerant config parsing.

## First steps

1. Inspect the current workspace network module before writing code.
2. Identify the existing protocol facts that must not drift:
   - success code set
   - auth-expiry code
   - common parameter semantics
   - common-parameter key mapping
   - signature algorithm and sort order
   - request path participation in the signature
   - query/body/form-data placement rules
   - random field requirements
   - encrypted-reporting behavior
   - base-URL bootstrap behavior
3. Separate protocol-invariant behavior from project-variant configuration.
4. If a value is likely to change across projects, keep it configurable instead of hardcoding it.

## Non-negotiable behavior rules

### Response shell

- Always normalize raw responses into one unified response object.
- The response object must carry:
  - business code
  - business message
  - payload node
- If the server payload is not in the expected object shape, return a fallback error response instead of crashing.

### Success and failure

- Success must be driven by the project's business success codes, not HTTP status alone.
- All request helpers must route through one unified response handler.
- Business failures must throw a business exception with a user-readable message.

### Auth expiry

- Handle the auth-expiry business code in one place only.
- The auth-expiry handler must be idempotent under concurrency.
- It must clear login state and redirect to login using the project's shared flow, not page-local hacks.

### Request placement rules

- GET: signable common params and business params go in query.
- POST: signable common params go in query; business params go in body.
- Upload: signable common params go in query; business params and file go in multipart body.
- Do not silently change this placement model.

### Common params and mapping

- Support async provider, sync provider, and static fallback for common params.
- Keep key mapping centralized.
- Unknown keys must pass through unchanged.
- Time-based values must be generated at runtime.

### Signature

- Build the signature from mapped common params plus the request path field required by the protocol.
- Sort keys lexicographically.
- Concatenate as `key + value` with no separators.
- Use HMAC-SHA256.
- Output lowercase hex.
- Write the signature back into the outgoing query parameters.

### Random fields

- Preserve both protocol-level random fields and endpoint-level random fields where required.
- Random values should be generated per request.
- Unless the protocol says otherwise, keep them fixed-length numeric strings.

### Base URL bootstrap

- Probe the default API base URL first.
- If unavailable, fetch a remote config document.
- Accept plain JSON or Base64-wrapped JSON.
- Apply remote API and web base URLs if present.
- Fail closed without crashing the app.

### Encryption

- Keep encrypted reporting as an explicit capability.
- Centralize crypto config and helper logic.
- Allow endpoints that accept pre-encrypted payloads or raw payloads to be normalized into the required outgoing shape.

## Implementation guidance

- Prefer a small set of focused units:
  - request client
  - request manager/config manager
  - response parser
  - response shell
  - business exception and error-message adapter
  - signature helper
  - crypto helper
  - endpoint aggregator
  - common-param provider
- Avoid pushing protocol logic into pages, widgets, or controllers.
- Keep endpoint declarations centralized so the UI never manually constructs protocol paths or obfuscated keys.
- When an endpoint can optionally upload a file, support both branches:
  - file present: multipart upload
  - file absent: normal form post

## What may stay configurable or blank

These can be left as placeholders when the task is to scaffold a reusable equivalent module:

- API base URL
- web base URL
- remote config URL
- common-parameter mapping table
- success code set
- auth-expiry code
- signature secret
- crypto key and IV
- protocol field names for path, signature, and random suffix

Do not leave the processing flow blank. Only the values may be placeholders.

## Verification checklist

Before finishing, verify:

- GET, POST, and upload helpers place parameters in the correct locations.
- unified response handling catches auth expiry and business failures.
- the auth-expiry handler is concurrency-safe.
- non-standard response shapes degrade into a controlled error response.
- signature generation is deterministic for the same input.
- common params can be supplied asynchronously.
- base-URL bootstrap tolerates both reachable-default and remote-fallback paths.
- encrypted-reporting support exists where the module requires it.
- UI-facing code only consumes the unified error-message adapter, not raw transport exceptions.

## Reference

For the exact task decomposition and acceptance rules in this workspace, read:

- `project_docs/network_request_module_task_checklist.md`
