# Self-Hosted-Runner-HandsOn

ECW Hardware-in-the-Loop CI demo: a GitHub Actions pipeline that books a real
board through the ECW backend, flashes firmware, runs HIL jobs, and collects
the results.

## Session-trigger flow (branch `develop_2`)

Instead of a runner sitting idle polling the ECW backend until the booked
session becomes active, the backend now **wakes GitHub** when it activates the
session. Two workflows:

1. **`ci-job-smoke.yml`** (push to `develop_2` / manual) — builds the firmware,
   reserves a board, and `PUT`s a session-activation trigger to
   `/v1/ci/bookings/{id}/activation-trigger`. Then it stops. No wait job.

2. **`ci-job-active.yml`** — `workflow_dispatch` only. ECW fires it via the
   REST API the moment the booking becomes active, passing the booking context
   (`booking_id`, `board_*`, `starts_at`, `ends_at`) plus `run_id` / `sha` /
   `backend_url` that step 1 registered. It downloads step 1's firmware
   artifact, flashes it, runs the wait/serial/camera CI jobs, collects
   artifacts, and cancels the booking.

### One-time setup

- **Repository secret `ECW_API_KEY`** — an ECW API key (`X-API-Key`).
- **Repository secret `ECW_DISPATCH_PAT`** — a *fine-grained* GitHub PAT scoped
  to this repository with **Actions: Read and write**. ECW stores it encrypted,
  uses it once to dispatch `ci-job-active.yml`, then wipes it.
- **`ci-job-active.yml` must exist on the repository's default branch** for the
  `workflow_dispatch` REST API to accept the call. Merge it to the default
  branch once; afterwards iterate on any branch and set the smoke workflow's
  `active_ref` input (or push to `develop_2`, which registers `develop_2` as
  the ref to run).
- The ECW backend must allow `api.github.com` in
  `CI_ACTIVATION_TRIGGER_ALLOWED_API_HOSTS` (the default).

### Local testing

`register_activation_trigger.py` honours `ECW_DISPATCH_API_BASE` to point the
dispatch at a mock GitHub server (see
`ECW_Backend/scripts/manual_ci_activation_trigger.sh`).
