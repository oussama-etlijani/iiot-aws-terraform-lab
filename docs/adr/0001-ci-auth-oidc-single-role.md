# 0001 – CI authenticates to AWS via OIDC with a single role

- Status: accepted
- Date: 2026-10-25

## Problem

GitHub Actions has to run `terraform plan` on pull requests and `terraform apply` / `destroy`
after merge. Both need AWS credentials. How does the pipeline get them, and how much access
does each trigger get?

## Constraints

- Public repository. Nothing that grants access may be stored in it or in GitHub secrets.
- Solo project. I am the only person with write access.
- `plan` on PRs needs to read the remote state and query AWS, so PRs need some AWS access.
- `apply` must only happen after a manual approval.

## Options considered

1. **IAM user with access keys in GitHub secrets.** Simple, but the key never expires. If it
   leaks (logs, a compromised action, a misconfigured workflow), it works until someone notices
   and rotates it.
2. **OIDC, single role.** GitHub issues a signed, short-lived token per workflow run. AWS trusts
   GitHub's OIDC provider and exchanges the token for 1-hour credentials of one role. The role's
   trust policy allows exactly two subjects:
   - `repo:oussama-etlijani/iiot-aws-terraform-lab:pull_request` (plan)
   - `repo:oussama-etlijani/iiot-aws-terraform-lab:environment:dev` (apply/destroy, behind approval)
3. **OIDC, two roles.** A read-only "plan" role for PRs and an admin "apply" role that only the
   protected `dev` environment can assume.

## Decision

Option 2: OIDC with one role (`iiot-lab-github-ci`) with `AdministratorAccess`, trusted for PRs
and for the `dev` environment. Both conditions use `StringEquals` (no wildcards), and the token
audience must be `sts.amazonaws.com`.

## Trade-offs

- **No long-lived secrets.** Nothing to rotate or leak. The role ARN is not a secret, so it is
  stored as a repository variable.
- **PRs get admin rights.** A workflow running on a PR could, in principle, change infrastructure,
  not only plan it. This is acceptable here because:
  - only I can push branches to this repo, and
  - workflows triggered by `pull_request` from forks do not receive an OIDC token, so outside
    contributors cannot assume the role. (This holds only as long as no workflow uses
    `pull_request_target`, which must stay true.)
- **The environment subject alone is not enough.** Any branch could declare `environment: dev`.
  The `dev` environment must therefore be restricted to the `main` branch and require my approval
  (configured in GitHub, step 5). The AWS trust policy and the GitHub settings only together form
  the security boundary.
- **`AdministratorAccess` is broader than needed.** Terraform will create VPC, EC2 and IAM
  resources, so a least-privilege policy would need constant adjustment while the stack evolves.
  Accepted for a lab account with a budget alarm.

## What would change my mind

- A second contributor with write access, or any production account → split into plan/apply
  roles (option 3) and give the plan role read-only permissions plus state access.
- A stable stack → replace `AdministratorAccess` with a scoped policy for the services actually
  used.
