resource "aws_secretsmanager_secret" "this" {
  name                    = var.secret_name
  description             = var.description
  kms_key_id              = var.kms_key_id
  recovery_window_in_days = var.recovery_window_in_days
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "this" {
  count = var.manage_secret_value && var.secret_string != null ? 1 : 0

  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = var.secret_string
}
