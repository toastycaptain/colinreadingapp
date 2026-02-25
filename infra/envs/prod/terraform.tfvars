aws_region = "us-east-1"

project_name = "storytime"
environment  = "prod"

admin_allowed_origins = [
  "https://admin.storytime.example",
]

# Replace with your real public key PEM.
cloudfront_public_key_pem = <<EOT
-----BEGIN PUBLIC KEY-----
REPLACE_ME_WITH_PROD_PUBLIC_KEY
-----END PUBLIC KEY-----
EOT

# Keep false in production so private key payload is not stored in Terraform state.
manage_cloudfront_private_key_secret_value = false
cloudfront_private_key_pem                 = null

# Strongly recommended in prod.
# domain_name         = "cdn.storytime.example"
# acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
# route53_zone_id     = "Z1234567890ABC"
