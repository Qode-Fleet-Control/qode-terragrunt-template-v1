# Terragrunt template

Provisioned from [`Qode-Fleet-Control/fleet-template-v1`](https://github.com/Qode-Fleet-Control/fleet-template-v1) — the fleet
lifecycle contract (`bin/`, `fleet.conf`, `compose.yaml`, deploy workflows) with a
[Terragrunt](https://terragrunt.com) live-infrastructure layout laid on top.

**This repo is a job, not a service.** Its container runs the format checks and
`terragrunt run --all validate` / `plan` over every unit, then exits — 0 when all of it
passes. Nothing listens on `$PORT`. Every module is credential-free (`random`, `null`,
`local` providers), so it plans with no cloud account.

## Layout

    root.hcl                     # included by every unit: env lookup, local backend, common inputs
    modules/
      name/                      # random_pet + random_id -> name, unique_name
      manifest/                  # null_resource + local_file manifest for a name
    live/
      dev/  env.hcl              # locals { environment = "dev" }
            name/terragrunt.hcl
            manifest/terragrunt.hcl   # dependency "name" (mock outputs for validate/plan)
      prod/ env.hcl
            name/terragrunt.hcl       # pet_length = 3
            manifest/terragrunt.hcl
    scripts/check.sh             # the job

Each unit commits its `.terraform.lock.hcl` (hashes for linux/darwin amd64+arm64 and
windows amd64). State goes to a local backend under `.state/` (git-ignored); swap the
`generate "backend"` block in `root.hcl` for `remote_state { backend = "s3" ... }` when
the units manage real infrastructure.

## Run it

**On the fleet:** `bin/run` builds the image (`docker compose build`) and stops there —
`DOCKER_START_CMD` is empty because there is no server. Run the job with
`docker compose run --rm app`.

**With docker:**

    docker compose build
    docker compose run --rm app        # exit 0 = fmt, hcl validate, run --all validate and plan passed

**Without docker** (needs `terragrunt` >= 1.0 and `terraform` >= 1.10 — or `tofu` — on `PATH`):

    sh scripts/check.sh
    terragrunt run --all --working-dir live -- apply     # optional: creates the names + out/<env>.json
    terragrunt run --all --working-dir live -- destroy

`FLEET_RUNTIME=process bin/run` runs `INSTALL_CMD` (`run --all init`) and `BUILD_CMD`
(`run --all validate`) and then stops at the start step, by design.

## Origin

Terragrunt's own generator, `terragrunt scaffold` (v1.1.6), wrote every unit's
`terragrunt.hcl` from its module (run inside each unit directory):

    terragrunt scaffold ../../../modules//name     --root-file-name root.hcl --non-interactive
    terragrunt scaffold ../../../modules//manifest --root-file-name root.hcl --non-interactive

`root.hcl`, `env.hcl` and `modules/` are hand-written to the layout Terragrunt's docs teach
(a root `root.hcl` included by every unit, one directory per environment and unit). Lock
files: `terraform providers lock -platform=...` in each module, copied into its units.

## Deviations, and why

- Scaffolded units: the generated `project` / `environment` placeholders (`""  # TODO`) were
  replaced by a pointer to `root.hcl`, which supplies them; `manifest` units gained a
  `dependency "name"` block with mock outputs so `validate`/`plan` run before anything is
  applied; prod sets `pet_length = 3`.
- Terragrunt has no official image: the `Dockerfile` downloads the v1.1.6 release binary onto
  `hashicorp/terraform:1.16.5` and checks it against the release's `SHA256SUMS`.
  `TG_TF_PATH=terraform` pins the engine (Terragrunt would prefer `tofu` if present).
- Every unit is initialised at build time (`--parallelism 1`, a shared plugin cache, lock
  files read-only), so the job needs no registry access when it runs. Runs as non-root
  `app` (uid 10001).
- `plan` runs with `-lock=false`: local state, nothing to lock, nothing written.

## Verified

2026-10-05, on the docker daemon of the build host:

    docker compose build                 # ok (init of all 4 units at build)
    docker compose run --rm app          # hcl fmt ok, terraform fmt ok, hcl validate ok,
                                         # run --all validate: 4x "Success!",
                                         # run --all plan: 4x "2 to add" -> exit 0
    docker compose down --rmi local -v

## Serving over HTTP

There is no HTTP surface. If you add one, listen on `0.0.0.0:$PORT`, serve at `/`, set
`PORT`, `HEALTH_PATH`, `START_CMD` and `DOCKER_START_CMD` in `fleet.conf`, and publish
`"${PORT}:${PORT}"` in `compose.yaml`. See `docs/fleet-lifecycle.md`.
