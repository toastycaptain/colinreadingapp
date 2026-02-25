# Storytime Video Library — MASTER GUIDE for Codex
> **Purpose:** This file tells Codex (and any developer) **how to use the other Markdown specs** to build the complete system:  
> **Rails API backend → Admin web console → AWS infra → iOS app.**  
> The other files are the source of truth for requirements and should be followed in order.

---

## 0) Files in this spec set (read order)

Codex should process these files **in order**:

1. `01_backend_rails_api.md` — Rails API backend: data model, endpoints, auth, signing, jobs  
2. `02_admin_console.md` — Rails Admin console: ActiveAdmin pages + workflows  
3. `04_aws_infra_terraform.md` — AWS infra as code: S3, CloudFront OAC, Key Group, IAM, Secrets  
4. `03_ios_app.md` — iOS app: SwiftUI screens, networking, cookie install, playback UX

**Important:** Some items are cross-dependent (e.g., CloudFront domain + Key Group ID are outputs needed by Rails). Codex must implement integration points exactly as described.

---

## 1) Output expectation (what Codex should produce)

Codex should produce **three deliverables** (repositories or top-level folders):

### A) Backend repo (Rails)
- Rails 7.1+ API app with:
  - PostgreSQL
  - Redis + Sidekiq
  - JWT auth
  - Models + migrations + validations + indexes
  - API endpoints under `/api/v1`
  - CloudFront signed cookie generation service
  - MediaConvert job creation + polling jobs
  - RSpec tests

### B) Admin console (Rails / ActiveAdmin)
- Can be:
  - **Same Rails repo** as backend (preferred), or
  - Separate Rails app (acceptable but slower)
- ActiveAdmin configured with AdminUser auth
- Upload workflow + MediaConvert status
- Usage reporting + CSV export

### C) iOS app (Swift/SwiftUI)
- SwiftUI app implementing Parent Mode and Child Mode
- AVPlayer HLS playback from CloudFront
- Signed cookie installation into HTTPCookieStorage
- Parent Gate for mode switching
- Usage events sent to backend

### D) Infra (Terraform)
- Terraform code that provisions:
  - S3 master uploads bucket (private + CORS for admin uploads)
  - S3 HLS output bucket (private)
  - CloudFront distribution with **OAC**
  - CloudFront public key + key group (trusted key groups on behavior)
  - MediaConvert service role (read master, write output)
  - Secrets Manager secret for CloudFront private key (resource; avoid payload in prod)
  - Outputs needed by Rails

---

## 2) Recommended build sequence (do this, in this order)

### Step 1 — AWS infra first (minimum viable infra)
Even though infra is file #3 in the read order, implement the **minimum infra early** so backend can be wired correctly.

Codex should:
1. Implement Terraform per `04_aws_infra_terraform.md`
2. Apply in `dev` environment
3. Capture outputs:
   - buckets, CloudFront domain, key group/public key IDs, MediaConvert role ARN, secret ARN/name

**Deliverable at end of Step 1:** CloudFront domain exists, output bucket accessible by CloudFront via OAC, IAM role exists.

### Step 2 — Backend Rails API
Using `01_backend_rails_api.md`, Codex should:
1. Create Rails API app + Postgres + Sidekiq
2. Implement models/migrations exactly as specified
3. Implement auth and permissions
4. Implement API endpoints:
   - catalog search, library assignment, playback sessions, usage events
5. Implement CloudFront signed cookie service
6. Implement upload presign endpoints for admin
7. Implement MediaConvert create job + poll jobs
8. Add tests

**Deliverable at end of Step 2:** Backend can issue playback sessions that return signed cookies for a book with a ready VideoAsset.

### Step 3 — Admin console
Using `02_admin_console.md`, Codex should:
1. Add ActiveAdmin + AdminUser auth
2. CRUD pages for publishers/contracts/books/rights/video assets
3. Upload workflow:
   - generate presigned upload
   - register master key
   - trigger MediaConvert
   - show status + retry
4. Reporting + CSV export

**Deliverable at end of Step 3:** Admin can upload a master video → MediaConvert processes → VideoAsset becomes `ready` → playback works via CloudFront.

### Step 4 — iOS app
Using `03_ios_app.md`, Codex should:
1. Implement login + child selection
2. Implement Child Mode library + player (locked down)
3. Implement Parent Mode catalog search + add to library
4. Implement playback session request + cookie install + AVPlayer playback
5. Implement usage events

**Deliverable at end of Step 4:** End-to-end: Parent adds a book → Child plays it with only play/pause/back controls.

---

## 3) Environment variables and config contract (must match)

Codex must standardize environment variables used by Rails and populate them from Terraform outputs.

### Rails backend required env vars (minimum)
- `DATABASE_URL`
- `REDIS_URL`
- `JWT_SECRET`
- `AWS_REGION`
- `S3_MASTER_BUCKET`
- `S3_HLS_BUCKET`
- `CLOUDFRONT_DOMAIN` (e.g., `dxxxx.cloudfront.net` or `cdn.example.com`)
- `CLOUDFRONT_KEY_PAIR_ID` (or public key id, depending on signing implementation — be consistent)
- `CLOUDFRONT_PRIVATE_KEY_SECRET_ARN` (or name)
- `MEDIACONVERT_ROLE_ARN`

Codex must include a `.env.example` documenting all required vars.

---

## 4) Definition of Done (DoD) — MVP end-to-end tests

Codex should ensure these scenarios pass in dev:

### Content pipeline
1. Admin creates publisher + book + rights window
2. Admin uploads master video to S3 via presigned upload
3. Admin triggers MediaConvert job
4. VideoAsset becomes `ready` and manifest exists at:
   - `s3://<hls_bucket>/books/<book_id>/hls/index.m3u8`
5. CloudFront serves the manifest/segments when signed cookies are present

### Parent flow
1. Parent logs in
2. Parent searches catalog
3. Parent adds book to child library
4. Child library shows the book

### Child flow
1. Child taps book
2. App requests playback session
3. Backend validates:
   - child belongs to parent
   - book in library
   - rights window active
   - asset ready
4. Backend returns manifest URL + signed cookies
5. App installs cookies and playback starts
6. App sends usage events

### Security checks
- Parent cannot access another parent’s child
- Playback session denied if book not in child library
- Playback session denied if rights expired

---

## 5) Implementation guidance for Codex (how to work through specs)

When implementing each file:
1. **Create a checklist** from that file’s “Deliverables for Codex” section.
2. Implement one vertical slice at a time:
   - models → endpoint → tests
3. Keep interfaces stable:
   - Do not rename fields/endpoints unless updating all files consistently.
4. Use explicit TODO markers for phase-2 features (child session tokens, publisher portal, offline).

---

## 6) Where each file is authoritative

- Data model + endpoints + signing logic: `01_backend_rails_api.md`
- Admin workflows + UI actions: `02_admin_console.md`
- AWS resources + policies + outputs: `04_aws_infra_terraform.md`
- iOS UI restrictions + cookie handling + playback flow: `03_ios_app.md`

If there is a conflict, resolve it by:
1. Prioritizing **security constraints** (child mode lock-down, signed access)
2. Prioritizing **backend contract** (API shapes)
3. Updating the conflicting section and keeping changes consistent across files

---

## 7) File links (for humans)
This master file accompanies:
- `01_backend_rails_api.md`
- `02_admin_console.md`
- `03_ios_app.md`
- `04_aws_infra_terraform.md`

