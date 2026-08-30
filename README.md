# Self-Hosted-Runner-HandsOn

ECW Hardware-in-the-Loop CI demo: a GitHub Actions pipeline that builds
firmware, books a real board through the ECW backend, flashes it, runs HIL
jobs, and collects the results.

## Session-trigger flow (branch `develop_2`)

Instead of a runner sitting idle polling the ECW backend until the booked
session becomes active, **the backend wakes GitHub** when it activates the
session. Two workflows:

### Stage 1 — Build & Reserve (`ci-job-smoke.yml`)

You start it manually (Actions tab → *Run workflow*). It:

1. builds the firmware and uploads it as an artifact,
2. selects a board type and auto-books it,
3. `PUT`s a session-activation trigger to
   `/v1/ci/bookings/{id}/activation-trigger` (repo + workflow + ref + the
   `ECW_DISPATCH_PAT` secret; ECW stores the PAT encrypted and single-use).

Then it **stops** — no wait job.

### Stage 2 — Active Session (`ci-job-active.yml`)

`workflow_dispatch` only. ECW fires it via the REST API the moment the booking
becomes active, passing the booking context (`booking_id`, `board_*`,
`starts_at`, `ends_at`) plus `run_id` / `sha` / `backend_url` that Stage 1
registered. It:

1. **flash** — downloads Stage 1's firmware artifact (by `run-id`), `POST`s it
   to `/upload`,
2. **test** — creates the wait / serial / camera CI jobs, polls them, downloads
   the artifact bundles,
3. **release** — cancels the booking.

> Without a physical board wired to the backend the flash / test steps fail —
> that's the hardware, not the trigger. Stage 1 and the dispatch always work.

## One-time setup

- **Repository secret `ECW_API_KEY`** — an ECW API key (`X-API-Key`) valid on
  the backend you point `backend_url` at.
- **Repository secret `ECW_DISPATCH_PAT`** — a *fine-grained* GitHub PAT scoped
  to this repository with **Actions: Read and write**. ECW stores it encrypted,
  uses it once to dispatch Stage 2, then wipes it.
- **`ci-job-active.yml` must exist on the repository's default branch** for the
  `workflow_dispatch` REST API to accept the call. It's merged to `main`;
  iterate on `develop_2` and set Stage 1's `active_ref` (or leave it — it
  defaults to the ref that started the run).
- The ECW backend must allow `api.github.com` in
  `CI_ACTIVATION_TRIGGER_ALLOWED_API_HOSTS` (the default).

## Local testing

`register_activation_trigger.py` honours `ECW_DISPATCH_API_BASE` to point the
dispatch at a mock GitHub server (see
`ECW_Backend/scripts/manual_ci_activation_trigger.sh`).
