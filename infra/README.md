# Storytime Infrastructure (Terraform)

This directory provisions AWS infrastructure for the Storytime video pipeline:

- Private S3 master uploads bucket
- Private S3 HLS outputs bucket
- CloudFront distribution with OAC
- CloudFront Public Key + Key Group (trusted for signed cookies)
- MediaConvert IAM service role
- Rails IAM policy
- Secrets Manager secret for CloudFront private key

## Structure

```text
infra/
  envs/
    dev/
    prod/
  modules/
    s3_bucket/
    cloudfront_hls/
    iam_roles/
    mediaconvert/
    secrets/
```

## Terraform State

Use a separate backend key per environment.

Example backend bootstrap (one-time, outside this stack):

- S3 bucket: `storytime-terraform-state`
- DynamoDB lock table: `storytime-terraform-locks`

Init `dev`:

```bash
cd infra/envs/dev
terraform init \
  -backend-config="bucket=storytime-terraform-state" \
  -backend-config="key=storytime/dev/infra.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="dynamodb_table=storytime-terraform-locks"
```

Init `prod` uses `key=storytime/prod/infra.tfstate`.

## Apply

```bash
cd infra/envs/dev
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

Repeat in `envs/prod` once production values are configured.

## Required Inputs

Populate these in each environment `terraform.tfvars`:

- `aws_region`
- `admin_allowed_origins`
- `cloudfront_public_key_pem`
- Optional: `domain_name`, `acm_certificate_arn`, `route53_zone_id`

For production, keep:

- `manage_cloudfront_private_key_secret_value = false`
- `cloudfront_private_key_pem = null`

This prevents private key material from entering Terraform state.

## Inject CloudFront Private Key (Prod)

After `terraform apply` creates the secret resource, inject value out-of-band:

```bash
aws secretsmanager put-secret-value \
  --secret-id storytime/prod/cloudfront_private_key \
  --secret-string "$(cat /secure/path/cloudfront_private_key.pem)"
```

If using JSON payloads in your org, adapt `--secret-string` accordingly.

## Outputs for Rails

The environment outputs map directly to Rails backend config:

- `master_uploads_bucket_name` -> `S3_MASTER_BUCKET`
- `hls_outputs_bucket_name` -> `S3_HLS_BUCKET`
- `cloudfront_domain_name` -> `CLOUDFRONT_DOMAIN`
- `cloudfront_public_key_id` (or `cloudfront_key_pair_id`) -> `CLOUDFRONT_KEY_PAIR_ID`
- `cloudfront_private_key_secret_arn` -> `CLOUDFRONT_PRIVATE_KEY_SECRET_ARN`
- `mediaconvert_role_arn` -> `MEDIACONVERT_ROLE_ARN`
- `aws_region` input -> `AWS_REGION`

Read all outputs:

```bash
terraform output
```

JSON output for automation:

```bash
terraform output -json
```

## CloudFront Key Rotation

1. Generate a new CloudFront key pair externally.
2. Update `cloudfront_public_key_pem` in the target `terraform.tfvars`.
3. Apply Terraform so a new public key ID and key group association are active.
4. Update the private key secret payload in Secrets Manager.
5. Deploy Rails with the new `CLOUDFRONT_KEY_PAIR_ID` and same secret ARN/name.
6. Wait until existing playback cookie TTLs expire before deleting old key material.

## Validation Checklist

1. Upload a test object to master bucket via presigned upload.
2. Start MediaConvert job using output `mediaconvert_role_arn`.
3. Verify HLS manifest exists at `books/<book_id>/hls/index.m3u8` in output bucket.
4. Verify CloudFront serves HLS objects when signed cookies are present.
5. Verify unsigned requests are denied for protected HLS paths.
