import {
  to = aws_budgets_budget.monthly
  id = "${data.aws_caller_identity.current.account_id}:iiot-lab-monthly"
}

resource "aws_budgets_budget" "monthly" {
  name         = "iiot-lab-monthly"
  budget_type  = "COST"
  limit_amount = "10.0"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  lifecycle {
    # Set by AWS when the budget was created in the console ("UnblendedCost").
    # Can only be managed together with filter_expression, which this
    # account-wide budget doesn't use - so leave it as AWS set it.
    ignore_changes = [metrics]
  }



  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 50
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_alert_email]
  }
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_alert_email]
  }
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.budget_alert_email]
  }


}
