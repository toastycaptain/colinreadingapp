aws_region = "us-east-1"

project_name = "storytime"
environment  = "dev"

admin_allowed_origins = [
  "http://localhost:3000",
  "http://localhost:3001",
]

# Replace with your real public key PEM (do not include private key here).
cloudfront_public_key_pem = <<EOT
-----BEGIN PUBLIC KEY-----
REPLACE_ME_WITH_DEV_PUBLIC_KEY
-----END PUBLIC KEY-----
EOT

# Dev only: optionally let Terraform manage secret value.
manage_cloudfront_private_key_secret_value = false
cloudfront_private_key_pem                 = null

# Optional custom domain settings:
# domain_name         = "cdn-dev.example.com"
# acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
# route53_zone_id     = "Z1234567890ABC"
