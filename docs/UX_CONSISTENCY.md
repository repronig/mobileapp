# Mobile UX consistency (REPRONIG `mobile.repronig`)

Aligned with the web contract in `app.repronig/docs/UX_CONSISTENCY.md`. This is behavior and copy consistency, not a redesign.

## SnackBars (`MemberFeedback`)

- **API failures:** use `MemberFeedback.showError(context, error)` so [ApiException] messages and fallbacks are shown the same way everywhere. Prefer over ad-hoc `ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)))`.
- **Success after an action:** use `MemberFeedback.showSuccess(context, '…')` for a consistent display duration (`snackBarDisplay`).
- **File uploads:** when surfacing a server error after upload, pass `MemberFeedback.fileUploadFailed` as `fallback` if the API message is empty or generic, or show `MemberFeedback.showError` after mapping.

Global **SnackBar** styling (floating, colors) lives in `lib/app/theme.dart` — do not override `behavior` per-call unless necessary.

## Async screens (loading / empty / error + retry)

- Prefer **`MemberAsyncValueBody`** (`lib/widgets/member_async_value_body.dart`) for Riverpod **`AsyncValue`** flows: loading spinner, **`MemberAsyncErrorCard`** + retry, optional empty.
- For imperative lists (pagination), keep **RefreshIndicator** + **Try again** on error (same wording as web **`DashboardError`** default).

## Refresh

- Use **`RefreshIndicator`** on scrollable lists where data is remote (`member_works_screen`, activity tab patterns, etc.). Pull-to-refresh is the mobile analogue of web **`QueryRefreshButton`**.

## When to extend this doc

- New portals or major flows should add one bullet under the relevant section instead of inventing a third feedback pattern.
