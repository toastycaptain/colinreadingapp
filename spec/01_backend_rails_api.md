# Storytime Video Library — Backend (Ruby on Rails API) Spec
> **Goal:** Build the backend services for an iOS app that lets parents curate a child’s library of read‑aloud children’s books (video), while kids can only browse their assigned library and play/pause videos.  
> **Video hosting:** **S3 + CloudFront** with **HLS outputs produced by AWS MediaConvert**. The Rails backend must **not** self-host video bytes; it must manage metadata, entitlements, signed access, and reporting.

---

## 0) System Overview

### Core components
- **iOS App (single binary)**
  - **Parent Mode:** Search catalog, manage child library, settings.
  - **Child Mode:** Only Library + Player with Play/Pause + Return to Library.
- **Rails Backend (API-only)**
  - Auth, user/child profiles, catalog, library assignment, playback sessions, signed CloudFront access, usage events.
- **Admin Web Console (Rails)**
  - Manage publishers, partnerships/contracts, rights windows, catalog entries, uploads and MediaConvert jobs, reporting and statements.
- **AWS Video Pipeline**
  - Upload master video to S3 (private)
  - Trigger MediaConvert to produce HLS package to an output S3 bucket/prefix
  - Serve HLS via CloudFront
  - Access restricted using **CloudFront Signed Cookies** (recommended for HLS) or Signed URLs.

### Key design rules
- **Never** expose permanent S3 URLs to clients.
- **Only** return CloudFront playback endpoints + short-lived signing tokens/cookies.
- Child Mode endpoints must be **entitlement-checked** and **locked down**.
- Parent Mode requires a **Parent Gate** in iOS, but backend must still enforce permissions.

---

## 1) Tech Stack & Conventions

### Rails
- Ruby 3.3+ (or latest stable), Rails 7.1+
- API mode for JSON endpoints
- PostgreSQL
- Redis + Sidekiq for background jobs
- RSpec for tests (preferred), FactoryBot, Faker
- JSON serialization: Jbuilder or fast_jsonapi/Blueprinter (choose one)

### Auth
- Use **Devise + JWT** (recommended for iOS) OR pure JWT with has_secure_password.
- Support “Parent Account” login with email+password initially.
- Optional later: Sign in with Apple.

### API Conventions
- Base path: `/api/v1`
- All responses JSON
- Pagination: `page` + `per_page` (or cursor later)
- Standard error format:
  ```json
  { "error": { "code": "string", "message": "string", "details": {} } }
  ```

### Permissions
- Parent can access own children + manage library.
- Child mode requests are represented as a **Child Session** scoped to a child profile.
- Admin users are separate role(s) with strict access.

---

## 2) AWS Infrastructure Requirements (S3 / CloudFront / MediaConvert)

### 2.1 S3 Buckets
Create two buckets (names examples):
- `storytime-master-uploads` (private)
  - Stores original upload (MP4/MOV). Never public.
- `storytime-hls-outputs` (private)
  - Stores HLS renditions and manifests produced by MediaConvert.
  - Example output prefix: `books/{book_id}/hls/`

**Bucket policies**
- Deny public access (Block Public Access ON).
- Allow MediaConvert service role read from master bucket and write to output bucket.
- Allow CloudFront Origin Access Control (OAC) to read from output bucket.

### 2.2 CloudFront Distribution
- Origin: `storytime-hls-outputs` bucket via **OAC** (preferred over OAI).
- Behaviors:
  - Path pattern: `books/*`
  - Allowed methods: GET/HEAD
  - Cache policy optimized for HLS (respect query strings only if needed)
- Restrict access using **Signed Cookies** (recommended) because HLS fetches many segments.

**Why signed cookies over signed URLs?**
HLS playlists reference multiple `.ts` segments; cookies simplify authorization without resigning every segment URL.

### 2.3 MediaConvert
- Create a MediaConvert endpoint (account-specific).
- Create a MediaConvert IAM Role (service role) with S3 read/write.
- Presets/Job Template:
  - Input: MP4/MOV
  - Output Group: Apple HLS
  - Multiple renditions (e.g., 1080p, 720p, 480p)
  - Generate thumbnails (optional)
  - Audio: AAC
- Output destination: `s3://storytime-hls-outputs/books/{book_id}/hls/`
- Main manifest: `index.m3u8`

### 2.4 Signing Keys for CloudFront
- Create a CloudFront **Key Group** with a **public key**.
- Store the **private key** securely (e.g., AWS Secrets Manager).
- Rails uses this private key to generate signed cookies.

---

## 3) Data Model

### 3.1 Users & Roles
**User**
- id
- email (unique)
- password_digest (or devise fields)
- role: enum (`parent`, `admin`) — or separate AdminUser model
- created_at, updated_at

**ChildProfile**
- id
- user_id (parent owner)
- name
- avatar_url (optional)
- pin_hash (optional if you want per-child pin later)
- created_at, updated_at

### 3.2 Content Catalog
**Publisher**
- id
- name
- billing_email
- contact_name
- status (active/inactive)
- created_at, updated_at

**Book**
- id
- title
- author
- description
- age_min, age_max
- language
- cover_image_url (or ActiveStorage)
- publisher_id (nullable if self-owned)
- status enum (`draft`, `active`, `inactive`)
- created_at, updated_at

**VideoAsset**
- id
- book_id
- master_s3_key (uploads bucket key)
- hls_base_path (outputs prefix, e.g. `books/123/hls/`)
- hls_manifest_path (e.g. `books/123/hls/index.m3u8`)
- duration_seconds
- mediaconvert_job_id
- processing_status enum (`uploaded`, `processing`, `ready`, `failed`)
- created_at, updated_at

### 3.3 Library & Entitlements
**LibraryItem**
- id
- child_profile_id
- book_id
- added_by_user_id
- created_at

Unique index: `(child_profile_id, book_id)`

### 3.4 Rights & Partnerships
**PartnershipContract**
- id
- publisher_id
- contract_name
- start_date, end_date
- payment_model enum (`flat_fee`, `rev_share`, `hybrid`)
- rev_share_bps (integer basis points, e.g. 1500 = 15.00%)
- minimum_guarantee_cents (optional)
- notes (text)
- status (`draft`, `active`, `expired`, `terminated`)
- created_at, updated_at

**RightsWindow**
- id
- publisher_id
- book_id
- start_at, end_at
- territory (string, e.g. `US`, `GLOBAL`) — for MVP can default GLOBAL
- created_at, updated_at

### 3.5 Playback & Analytics
**PlaybackSession**
- id
- child_profile_id
- book_id
- issued_at
- expires_at
- cloudfront_policy (optional)
- created_at

**UsageEvent**
- id
- child_profile_id
- book_id
- event_type enum (`play_start`, `pause`, `resume`, `play_end`, `heartbeat`)
- position_seconds (optional)
- occurred_at (timestamp)
- metadata jsonb (device, app version)
- created_at

---

## 4) API Endpoints (iOS)

### 4.1 Auth
`POST /api/v1/auth/register`
- body: email, password
- returns: user + jwt

`POST /api/v1/auth/login`
- body: email, password
- returns: jwt + user

`POST /api/v1/auth/logout` (optional, stateless JWT)

### 4.2 Child Profiles
`GET /api/v1/children`
- parent only
- returns list of child profiles

`POST /api/v1/children`
- body: name
- returns child profile

`PATCH /api/v1/children/:id`
- update name/avatar

### 4.3 Catalog Search (Parent Mode)
`GET /api/v1/catalog/books?q=...&age=...&publisher=...&page=...`
- returns books (active only) with metadata and cover image

### 4.4 Child Library
`GET /api/v1/children/:child_id/library`
- returns books assigned to child, sorted by added_at desc

`POST /api/v1/children/:child_id/library_items`
- body: book_id
- adds to library

`DELETE /api/v1/children/:child_id/library_items/:book_id`
- removes

### 4.5 Playback (Child Mode)
`POST /api/v1/children/:child_id/playback_sessions`
- body: book_id
- checks: child belongs to parent account OR valid child session token (see below)
- checks: book in child library
- checks: rights window valid AND video asset ready
- returns:
  - `playback_manifest_url` (CloudFront URL to `index.m3u8`)
  - `signed_cookies` (3 values) OR `set-cookie` headers
  - `expires_at`

**Recommendation:** Return cookies via response headers for iOS to store in `HTTPCookieStorage`.
If you return JSON, provide:
```json
{
  "playback_manifest_url": "https://cdn.example.com/books/123/hls/index.m3u8",
  "cookies": [
    {"name":"CloudFront-Policy","value":"...","domain":".example.com","path":"/","expires":"..."},
    {"name":"CloudFront-Signature","value":"...","domain":".example.com","path":"/","expires":"..."},
    {"name":"CloudFront-Key-Pair-Id","value":"...","domain":".example.com","path":"/","expires":"..."}
  ],
  "expires_at": "2026-02-25T20:00:00Z"
}
```

### 4.6 Usage Events
`POST /api/v1/usage_events`
- body: child_id, book_id, event_type, position_seconds, occurred_at
- server validates user has access to child & book

Optional: heartbeat every 30–60s while playing.

---

## 5) Child Mode Auth / Sessions

### Simple MVP approach (recommended)
- Parent logs in and selects child profile.
- iOS stores parent JWT securely (Keychain).
- Child Mode uses parent JWT but UI is locked down via Parent Gate.
- Backend still enforces child ownership and library entitlements.

### Stronger approach (phase 2)
- Add `POST /children/:id/child_sessions` that issues a scoped token usable only for:
  - `GET library`
  - `POST playback_sessions`
  - `POST usage_events`
- Child token cannot call catalog search, cannot add/remove books, cannot edit profiles.

---

## 6) CloudFront Signed Cookies Implementation (Rails)

### 6.1 Inputs
- CloudFront distribution domain: `dxxxxx.cloudfront.net`
- Key pair ID: stored in env `CLOUDFRONT_KEY_PAIR_ID`
- Private key: stored in Secrets Manager or env `CLOUDFRONT_PRIVATE_KEY_PEM`
- Resource pattern:
  - Allow only paths: `https://dxxxxx.cloudfront.net/books/{book_id}/*`
- Expiration: 5 minutes (or 15 minutes)

### 6.2 Policy example (custom policy)
Policy JSON:
```json
{
  "Statement": [
    {
      "Resource": "https://dxxxxx.cloudfront.net/books/123/*",
      "Condition": {
        "DateLessThan": { "AWS:EpochTime": 1760000000 }
      }
    }
  ]
}
```

Rails must:
- Base64 encode policy (URL safe)
- Sign policy with RSA-SHA1 (CloudFront requirement)
- Produce cookies:
  - CloudFront-Policy
  - CloudFront-Signature
  - CloudFront-Key-Pair-Id

### 6.3 Where to set cookies
- In playback session response, set cookies on the CloudFront domain.
- iOS will include cookies automatically when requesting HLS segments.

---

## 7) Upload + MediaConvert Pipeline (Admin-triggered)

### 7.1 Direct upload (do not proxy through Rails)
Admin console calls:
`POST /admin/api/v1/uploads/master_video`
- returns a presigned POST (or presigned PUT) for S3 master bucket.
- client uploads directly to S3.

Then admin console calls:
`POST /admin/api/v1/books/:id/video_assets`
- body includes `master_s3_key`, filename, size, checksum
- server creates VideoAsset and enqueues MediaConvert job.

### 7.2 MediaConvert job creation
Sidekiq job:
- Creates job with input pointing to `s3://storytime-master-uploads/{master_s3_key}`
- Output group to `s3://storytime-hls-outputs/books/{book_id}/hls/`
- Save `mediaconvert_job_id` and set status to `processing`

### 7.3 Job completion notifications
Two options:
1) Poll MediaConvert status periodically (simpler)
2) Use EventBridge + SNS/HTTP webhook to notify Rails of job completion (better)

MVP: polling every few minutes for processing assets.

On completion:
- Update VideoAsset:
  - `processing_status = ready`
  - set `hls_manifest_path = books/{book_id}/hls/index.m3u8`
  - store duration if available

---

## 8) Reporting / Publisher Billing Support

### Usage aggregation jobs
Nightly job aggregates UsageEvents into summary tables:
- Minutes watched per book per publisher per day/month
- Unique plays per book

Generate monthly **PublisherStatement** records (phase 2 model) and export CSV/PDF.

For MVP, implement:
- Admin report endpoint: minutes watched by book/publisher for date range
- CSV export

---

## 9) Security & Compliance Checklist
- Enforce that **only entitled children** get playback cookies for that book.
- Use short-lived cookie expiration.
- Never allow `books/*` path outside entitlement scope.
- Rate-limit auth endpoints.
- Store secrets in AWS Secrets Manager / env vars.
- Log access attempts to playback sessions.

---

## 10) Testing Requirements
- Model validations (uniques, date ranges)
- Policy tests:
  - Parent cannot access other parent’s children
  - Child playback denied if book not in library
  - Playback denied if RightsWindow expired
- Signing tests (cookie format present)
- MediaConvert job creation job test (stub AWS SDK)

---

## 11) Deliverables for Codex (Backend)
Implement:
- Rails API app with the full models above
- Migrations with indexes
- JWT auth
- Endpoints in section 4
- CloudFront signing service object
- Sidekiq jobs for MediaConvert create + poll
- Admin API endpoints for upload presign and video asset creation
- RSpec test suite

