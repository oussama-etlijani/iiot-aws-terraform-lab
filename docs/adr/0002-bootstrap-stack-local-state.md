# 0002 – Separate bootstrap stack with local state

- Status: accepted
- Date: 2026-10-25

## Problem

All application stacks (`envs/dev`, later `envs/prod`) keep their Terraform state in S3, and CI
authenticates through an OIDC role. The state bucket, the OIDC provider and the role must exist
before any of that works. Something has to create them, and that something needs a place for its
own state.

## Constraints

- Everything should be managed as code, so it can be reviewed and rebuilt.
- `envs/dev` is destroyed after every work session to save cost. The foundation must survive that.
- The state bucket cannot hold the state of the stack that creates it (chicken-and-egg).
- Solo project; the bootstrap stack changes rarely.

## Options considered

1. **Create the foundation by hand in the console.** Fast, but not reviewable, not reproducible,
   and contradicts "everything as code".
2. **Bootstrap stack with local state.** A small Terraform stack (`bootstrap/`) whose state stays
   in a git-ignored local file.
3. **Bootstrap stack, then migrate its state into the bucket it created.** Removes the local
   file, but the stack then depends on its own output; deleting or breaking the bucket also
   breaks access to the state describing it.

## Decision

Option 2. `bootstrap/` manages the state bucket (versioning, AES256 encryption, public access
blocked, `prevent_destroy`), the GitHub OIDC provider, the CI role and the AWS budget. Its state
is the local file `bootstrap/terraform.tfstate`. It is never destroyed as part of the normal
work cycle.

The budget was created in the console first (cost alerts had to exist before any resources)
and later brought under Terraform with an `import {}` block. The block was preferred over the
`terraform import` command because the import shows up in `plan` together with any drift. That
plan revealed one: AWS had set `metrics = ["UnblendedCost"]`, which the provider can only manage
together with `filter_expression`. The budget is account-wide with no filter, so `metrics` is
excluded via `ignore_changes`.

## Trade-offs

- **The local state exists only on my laptop.** If it is lost, the resources keep running but
  Terraform no longer knows about them. Recovery: re-import the 8 resources with `import {}`
  blocks. Annoying, but bounded.
- **No locking.** Irrelevant with one person running bootstrap occasionally; would matter in a team.
- **Not run in CI.** Bootstrap creates the role CI uses, so changes are applied locally with my
  SSO credentials.
- **`ignore_changes = [metrics]`** means a console change to that attribute would go unnoticed.
  Accepted for one attribute, documented in the code.

## What would change my mind

- More people working on the foundation, or bootstrap changing often → migrate its state to a
  separate, manually created bucket (or into the state bucket, option 3) to get locking and history.
- Several AWS accounts → move this into an account-vending / organization-level setup instead of
  a per-repo bootstrap.
