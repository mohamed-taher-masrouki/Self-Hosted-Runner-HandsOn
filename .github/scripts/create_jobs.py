"""Creates the wait, serial, and camera CI jobs for the smoke test."""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from ecw_client import request_json, write_github_env  # noqa: E402

# Registry keys from _COMMAND_REGISTRY in api/ci_jobs.py -- these are the
# only public command names the API accepts. There is no nested
# do/wait/expect/on_failure schema; commands are flat and keyed by name.
JOB_SPECS = {
    "wait": {
        "request_id": "gha-wait-001",
        "name": "GitHub Actions wait job",
        "duration_seconds": 15,
        "commands": [
            {
                "id": "wait-10s",
                "name": "Wait 10 seconds",
                "command": "delay",
                "attempts": 1,
                "timeout_ms": 10000,
            }
        ],
    },
    "serial": {
        "request_id": "gha-serial-001",
        "name": "GitHub Actions serial job",
        "duration_seconds": 10,
        "commands": [
            {
                "id": "mcu-serial",
                "name": "MCU serial capture",
                "command": "mcu.serial_log",
                "attempts": 1,
                "timeout_ms": 2000,
                "parameters": {"filename": "gha-mcu.log"},
            },
            {
                "id": "mpu-serial",
                "name": "MPU serial capture",
                "command": "mpu.serial_log",
                "attempts": 1,
                "timeout_ms": 2000,
                "parameters": {"filename": "gha-mpu.log"},
            },
        ],
    },
    "camera": {
        "request_id": "gha-camera-001",
        "name": "GitHub Actions camera job",
        "duration_seconds": 10,
        "commands": [
            {
                "id": "camera-shot",
                "name": "Capture camera screenshot",
                "command": "camera.screenshot",
                "attempts": 1,
                "timeout_ms": 5000,
                "parameters": {"filename": "gha-frame.jpg"},
            }
        ],
    },
}


def main() -> None:
    backend_url = os.environ["ECW_BACKEND_URL"].rstrip("/")
    api_key = os.environ["ECW_API_KEY"]
    booking_id = int(os.environ["ECW_BOOKING_ID"])

    artifact_dir = Path("artifacts")
    artifact_dir.mkdir(exist_ok=True)

    job_ids: dict[str, int] = {}
    for label, spec in JOB_SPECS.items():
        payload = {"booking_id": booking_id, **spec}
        job = request_json(
            f"{backend_url}/v1/ci/jobs",
            api_key,
            method="POST",
            body=payload,
            timeout=30,
        )

        (artifact_dir / f"ci-job-{label}-created.json").write_text(
            json.dumps(job, indent=2) + "\n", encoding="utf-8"
        )

        job_id = job.get("id")
        if not job_id:
            raise SystemExit(f"{label} job creation response is missing id.")

        job_ids[label] = job_id
        print(f"Created {label} CI job: {job_id}")

    write_github_env("ECW_CI_JOB_IDS", json.dumps(job_ids))


if __name__ == "__main__":
    main()
