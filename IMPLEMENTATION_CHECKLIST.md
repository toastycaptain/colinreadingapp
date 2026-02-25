# Storytime Implementation Checklist

## Step 1: AWS Infra (from `04_aws_infra_terraform.md`)
- [x] Terraform folder structure (`envs/dev`, `envs/prod`, `modules/*`)
- [x] S3 modules for master uploads + HLS output buckets
- [x] CloudFront module with OAC + public key + key group + trusted key groups
- [x] MediaConvert service role and Rails IAM policy module
- [x] Secrets Manager module with prod-safe payload handling toggle
- [x] Required outputs mapped for Rails
- [ ] `terraform init/plan/apply` in dev (blocked: terraform CLI not installed in local environment)

## Step 2: Backend API (from `01_backend_rails_api.md`)
- [x] Rails API app scaffold (`backend/`)
- [x] PostgreSQL models/migrations created for core domain
- [x] Devise + JWT auth endpoints (`/api/v1/auth/register`, `/api/v1/auth/login`, `/api/v1/auth/logout`)
- [x] Parent/child/catalog/library/playback/usage API endpoints scaffolded
- [x] CloudFront signed cookie service and private key resolver service
- [x] MediaConvert create/poll job scaffolding with Sidekiq adapter
- [x] Admin API scaffolding for upload presign + video asset registration
- [x] `.env.example` with required env vars
- [x] RSpec policy/signing/job tests completed
- [ ] End-to-end backend smoke test with migrated DB

## Step 3: Admin Console (from `02_admin_console.md`)
- [x] ActiveAdmin setup
- [x] CRUD pages for publisher/contracts/books/rights/video assets
- [x] Upload + transcode + retry workflows
- [x] Reporting + CSV export

## Step 4: iOS App (from `03_ios_app.md`)
- [x] SwiftUI app scaffold
- [x] Parent mode + child mode flows
- [x] Playback session + signed cookie install + AVPlayer playback
- [x] Usage event instrumentation
