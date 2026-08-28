# Changelog

## 0.0.12

Feature release - richer per-field validation, on top of the 0.0.11 fixes.

### Added
- Field spec hash: any permitted value can now be `{ type:, required:, default:, in:, match:, min:,
  max:, of:, shape:, delimiter:, separator:, integer_precision: }` instead of just a bare type.
  Bare types keep working exactly as before.
- `required:` - raises `PermitParams::MissingParameterError` (missing) or
  `PermitParams::InvalidParameterError` (present but invalid) when unmet, independent of
  `strong_validation`.
- `default:` - fills in a value when the param is missing or fails validation.
- `in:` - enum / allow-list constraint.
- `match:` - Regexp format constraint for String values.
- `min:` / `max:` - numeric bounds, or length bounds for String/Array/Hash.
- `of:` - coerces every element of an `Array` field to a given type, including elements of an
  already-`Array` param (e.g. a JSON body), and drops individually-invalid elements rather than
  the whole array. Combines with `Shape` for arrays of nested objects.
- Per-field `shape:`/`delimiter:`/`separator:`/`integer_precision:` override the global 4th-argument
  `options` hash for that field only - e.g. two different `Shape` fields can now each have their own
  shape in a single call.
- `PermitParams::MissingParameterError`, a subclass of `PermitParams::InvalidParameterError`.

### Changed
- Nested coercion failures (e.g. one bad element inside an `of:` array) now propagate their precise
  original error message with `strong_validation: true`, instead of being replaced by a generic
  outer message.
- Added `rspec`/`rack-test`/`rake` as declared development dependencies, plus a `Gemfile`, so
  `bundle install && bundle exec rake` works for a fresh clone.
- Removed a stray `require 'test/unit'` from both spec files - it wasn't used by either, and loading
  it alongside rspec in the same process registered an `at_exit` hook that made `bundle exec rake`
  report a spurious failure even when every example passed.
- Removed the vestigial `Rake::TestTask` (there is no `test/` directory in this repo).
- Removed the deprecated `Gem::Specification#default_executable=` from the gemspec.

## 0.0.11

Security and reliability fixes - no public API changes.

### Fixed
- **Auth/logic-bypass bug**: the result hash used `Hash.new({})`, so a missing/rejected key
  returned a shared, truthy `{}` instead of `nil`. Code checking `if permitted[:some_key]` for
  presence would silently treat a filtered-out param as present. Now defaults to a plain `{}`.
- **Crash-on-attacker-input in `Shape` validation**: `has_shape?` indexed into `shape[k]` without
  checking `shape` was still a `Hash`, so an unexpected nested hash in untrusted input, a missing
  `shape:` option, or a malformed string param raised an unrescued `NoMethodError` instead of being
  rejected. Now guarded.
- **Regex anchor bug in `coerce_boolean`**: used `^`/`$`, which anchor to line boundaries in Ruby,
  not the whole string, so `"true\nanything"` passed as a clean boolean. Switched to `\A`/`\z`.
- **Unbounded input to `Date.parse`/`Time.parse`/`DateTime.parse`/`Integer`/`Float`**: capped at
  128 bytes (mirroring Ruby's own CVE-2021-41817 fix) as defense-in-depth against resource
  exhaustion, regardless of the host app's Ruby/date-gem patch level.
- Missing `require 'date'`/`require 'time'` - a bare Sinatra app that hadn't loaded those stdlib
  files elsewhere hit `NameError` the first time a `Date`/`Time`/`DateTime` permitted type was used.
- `coerce_shape` silently dropped the caller's `options` (delimiter/separator) instead of
  forwarding them.
- Broadened `coerce`'s rescue from `ArgumentError` to `StandardError` as a general safety net, on
  top of the fixes above.

## Earlier

No changelog was kept before 0.0.11.
