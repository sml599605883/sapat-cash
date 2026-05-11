---
name: json-helper-parity
description: Rebuild or extend a Flutter Json wrapper so it preserves this project's current dynamic JSON access semantics, including safe chained reads, tolerant parsing from string or bytes, scalar conversion rules, mutable map/list access, and raw JSON serialization. Use when asked to generate or refactor the project's Json helper while keeping filenames flexible.
---

# Json Helper Parity

Use this skill when the task is to generate, rebuild, refactor, or audit a Flutter JSON wrapper that must behave like the repository's current `Json` helper, even if the implementation name or file layout changes.

## Outcome

Produce a wrapper that:

- Accepts any dynamic object.
- Parses JSON strings and byte arrays safely.
- Supports chained access through `[]`.
- Supports safe accessors for map, list, bool, num, int, double, and string.
- Returns safe defaults instead of throwing on missing fields or type mismatch.
- Supports writable `[]=` and `remove`.
- Serializes back to JSON with `rawString()`.

## First steps

1. Inspect the current workspace `Json` helper before writing code.
2. Identify the exact conversion rules that must not drift:
   - map/list/scalar/null type detection
   - bool conversion from strings and numbers
   - numeric parsing from strings
   - string fallback behavior
   - null fallback behavior for mismatched reads
3. Separate helper behavior from business model logic.

## Non-negotiable behavior rules

### Construction and parsing

- Directly wrap dynamic objects.
- Parse JSON text safely.
- Parse byte arrays safely.
- On parse failure, degrade to a null state instead of throwing.

### Chained access

- `json['key']` must return another `Json` wrapper.
- `json[index]` must work for lists.
- Missing keys and out-of-range indexes must return a safe null wrapper.

### Conversion semantics

- `boolValue` should recognize `true`, `y`, `t`, `yes`, and `1`.
- `numValue` should parse numeric strings before falling back to zero.
- `stringValue` should stringify num and bool values.
- The `OrNull` accessors should preserve null when conversion is not valid.

### Mutability

- Allow `[]=` writes for both map and list cases.
- If a write happens against the wrong container type, rebuild into the matching container.
- Allow key/index removal with `remove`.

### Serialization

- `rawString()` must return a JSON string.
- `prettyPrint` must return indented JSON.
- `toString()` must delegate to `rawString()`.

## Implementation guidance

- Keep the helper small and deterministic.
- Do not add business-specific field names, schemas, or validation rules.
- Do not throw on missing fields; let the accessor defaults handle it.
- If a project needs stricter validation, that should live above this helper.

## What may stay configurable or blank

These may remain flexible across projects:

- file name
- class name
- encoding style for pretty print
- exact internal field names

Do not change the observable behavior of parsing, chained reads, conversion defaults, or serialization.

## Verification checklist

Before finishing, verify:

- map access works after parsing from object or text
- list access works and out-of-range indexes stay safe
- string/number/bool conversions match the current project rules
- parse failures degrade to null state
- `rawString()` round-trips expected payloads
- `remove` and `[]=` behave correctly for both map and list
- model code can keep using `json['field'].stringValue.trim()` patterns without breaking

## Reference

For the exact usage patterns in this workspace, read:

- `project_docs/json_helper_task_checklist.md`
