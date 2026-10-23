resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

# Trust policy: WHO may assume the role
data "aws_iam_policy_document" "github_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn] # the provider's ARN, via a reference
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"] # same audience as client_id_list
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = ["repo:oussama-etlijani/iiot-aws-terraform-lab:pull_request",
      "repo:oussama-etlijani/iiot-aws-terraform-lab:environment:dev"] # the two sub values from the table
    }
  }
}

resource "aws_iam_role" "github_ci" {
  name               = "iiot-lab-github-ci"
  assume_role_policy = data.aws_iam_policy_document.github_trust.json # the policy document's JSON, via a reference
}

# Permissions: WHAT the role may do
resource "aws_iam_role_policy_attachment" "github_ci_admin" {
  role       = aws_iam_role.github_ci.name # the role's name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}