# Repo Patch — Switch backend to Mux (toastycaptain/colinreadingapp)
This document is **repo-specific**. It assumes the current repo layout:

- `backend/` = Rails app (currently AWS S3 + CloudFront + MediaConvert)
- `ios/StorytimeApp/` = SwiftUI source (currently installs CloudFront cookies)
- `infra/` = Terraform for AWS video pipeline (will become optional / deprecated after Mux)

Your goal is to **replace only the video pipeline** with Mux, keeping everything else (auth, catalog, library, rights windows, usage reporting).

---

## A) Backend: what exists today (important anchors)
These files are the current AWS-based anchors in the repo and will be modified/removed:

- `backend/Gemfile` includes:
  - `aws-sdk-s3`, `aws-sdk-mediaconvert`, `aws-sdk-secretsmanager`
- `backend/app/models/video_asset.rb` stores `master_s3_key`, `hls_manifest_path`, `mediaconvert_job_id` etc.
- `backend/app/services/cloudfront_signed_cookie_service.rb`
- `backend/app/services/cloudfront_private_key_resolver.rb`
- `backend/app/controllers/api/v1/playback_sessions_controller.rb` issues CloudFront cookies and returns `playback_manifest_url`
- `backend/app/controllers/admin/api/v1/uploads_controller.rb` presigns S3 upload
- `backend/app/controllers/admin/api/v1/video_assets_controller.rb` registers S3 key + enqueues MediaConvert jobs
- `backend/config/routes.rb` has admin endpoints for uploads and video_assets (MediaConvert)

(You can confirm these in the repo right now.)

---

## B) Backend changes (Mux)

### B1) Gems
Edit `backend/Gemfile`:

1) **Remove** these gems (Mux will replace them):
- `aws-sdk-s3`
- `aws-sdk-mediaconvert`
- `aws-sdk-secretsmanager`

2) **Add** Mux + JWT signing support:
- Add `mux_ruby` (official Mux Ruby SDK)
- Add `jwt` (for signed playback tokens)

Then run in `backend/`:
```bash
bundle install
```

> If Codex had pinned Rails `~> 8.1.2`, keep it as-is. No change needed.

---

### B2) Environment variables (.env.example)
Edit `backend/.env.example` and **remove** the AWS video vars:
- `S3_MASTER_BUCKET`, `S3_HLS_BUCKET`
- `CLOUDFRONT_*`
- `MEDIACONVERT_*`

Add Mux vars:
- `MUX_TOKEN_ID`
- `MUX_TOKEN_SECRET`
- `MUX_SIGNING_KEY_ID`
- `MUX_SIGNING_KEY_PRIVATE_KEY`
- `MUX_WEBHOOK_SIGNING_SECRET`

Keep non-video vars as-is (DB, REDIS, JWT_SECRET, etc.).

---

### B3) Database: migrate VideoAsset to Mux fields
Current table contains AWS columns. Create a new migration to transition.

From `backend/`:
```bash
bin/rails g migration MuxifyVideoAssets   mux_asset_id:string mux_playback_id:string mux_upload_id:string   playback_policy:integer processing_status:integer mux_error_message:text
```

Then **edit the generated migration** to:
- Add columns above
- Add indexes:
  - unique index on `mux_asset_id`
  - index on `mux_upload_id`
- Set `processing_status` default to `0` (created) or keep existing default then update enum.
- **Drop AWS columns** (recommended once switched):
  - `master_s3_key`
  - `hls_base_path`
  - `hls_manifest_path`
  - `mediaconvert_job_id`
  - `error_message` (replaced by `mux_error_message`)  
  - (and any CloudFront-policy fields if present)

If you want a safer transition, keep old columns temporarily but stop using them in code; drop later.

Run:
```bash
bin/rails db:migrate
```

---

### B4) Model: update `backend/app/models/video_asset.rb`
Replace the AWS validations/enum with Mux equivalents.

Target shape:
- `processing_status` enum:
  - `created`, `uploading`, `processing`, `ready`, `failed`
- `playback_policy` enum:
  - `public`, `signed` (default signed)
- Validations:
  - `mux_upload_id` presence while uploading/processing
  - `mux_asset_id` presence when ready
  - `mux_playback_id` presence when ready

Remove:
- `validates :master_s3_key, presence: true`
- `validates :mediaconvert_job_id, uniqueness: true`

---

### B5) Remove AWS services and jobs
Delete (or leave but unused, then delete):
- `backend/app/services/cloudfront_signed_cookie_service.rb`
- `backend/app/services/cloudfront_private_key_resolver.rb`

Also remove MediaConvert jobs and any AWS video pipeline jobs (file names may vary in repo; search for):
- `MediaConvertCreateJob`
- `MediaConvertPollJob`

Command to locate:
```bash
rg "MediaConvert" backend/app
rg "Cloudfront" backend/app
rg "aws-sdk-mediaconvert" backend
```

---

### B6) Add new Mux service objects
Create:

#### `backend/app/services/mux_client.rb`
Responsibilities:
- Create Direct Upload (playback_policy = signed)
- Fetch upload/asset details (optional for reconciliation)

#### `backend/app/services/mux_signing.rb`
Responsibilities:
- Generate JWT for a playback id using `MUX_SIGNING_KEY_PRIVATE_KEY`
- Expiration: 5 minutes

Return token string.

#### `backend/app/services/mux_webhook_verifier.rb`
Responsibilities:
- Verify `Mux-Signature` using `MUX_WEBHOOK_SIGNING_SECRET`
- Require raw body; reject stale timestamps

---

### B7) Webhook endpoint
Add controller, e.g.:
- `backend/app/controllers/webhooks/mux_controller.rb`

Route:
- `POST /webhooks/mux`

Controller responsibilities:
- Verify signature (reject if invalid)
- Parse event payload
- Handle events:
  - asset ready → set `mux_asset_id`, `mux_playback_id`, `duration_seconds`, status `ready`
  - asset errored → set status `failed`, set `mux_error_message`
  - upload→asset mapping: link `mux_upload_id` to `mux_asset_id`

Add idempotency:
- Create a simple `WebhookEvent` model/table (recommended) storing `provider` + `event_id` unique.
- If event already processed, return 200.

---

### B8) Update existing API playback session endpoint (repo-specific)
Modify **existing** controller:

`backend/app/controllers/api/v1/playback_sessions_controller.rb`

Today it returns:
- `playback_manifest_url` and `cookies`

Change it to return:
```json
{
  "playback_hls_url": "https://stream.mux.com/<PLAYBACK_ID>.m3u8",
  "playback_token": "<JWT>",
  "expires_at": "ISO8601"
}
```

Implementation details:
- Keep all existing checks:
  - child owns book in library
  - rights window active
  - video asset ready
- Replace CloudFront signer with:
  - `playback_id = video_asset.mux_playback_id`
  - `token = MuxSigning.new(...).token_for(playback_id, exp: expires_at)`
  - `hls_url = "https://stream.mux.com/#{playback_id}.m3u8"`

Keep the endpoint path the same (it’s already used by iOS):
- `POST /api/v1/children/:child_id/playback_sessions` (from routes)

---

### B9) Replace admin upload endpoints with Mux direct upload endpoints
Current admin API routes:
- `POST /admin/api/v1/uploads/master_video`
- `POST /admin/api/v1/books/:book_id/video_assets` (register S3 key + enqueue MediaConvert)

Replace with:
- `POST /admin/api/v1/mux/direct_uploads`

Behavior:
- Create a direct upload via Mux API
- Create/update `VideoAsset` row for the book:
  - set `mux_upload_id`
  - set `processing_status = uploading`
  - set `playback_policy = signed`
- Return `{ upload_id, upload_url }`

You can keep existing endpoints temporarily but they should be unused after UI changes.

---

### B10) Routes update (backend/config/routes.rb)
Edit `backend/config/routes.rb`:

1) Under `namespace :admin do namespace :api do namespace :v1 do ... end end end`:
- Remove/ignore:
  - `post "uploads/master_video"`
  - `resources :books do resources :video_assets` (AWS-specific)
  - retry/poll MediaConvert endpoints
- Add:
  - `post "mux/direct_uploads", to: "mux#direct_upload"` (or controller name you choose)

2) Add at top-level:
- `post "/webhooks/mux", to: "webhooks/mux#receive"`

---

### B11) Smoke test checklist (backend)
After wiring env vars:
1) Start Rails:
```bash
cd backend
bin/rails s
```
2) Create a book + rights window + assign to child
3) Call admin endpoint to create upload URL → upload video via curl/browser
4) Ensure webhook updates `VideoAsset` → status ready and playback_id present
5) Call playback session endpoint and verify response includes `playback_hls_url` and `playback_token`

---

## C) Notes about infra folder
After switching to Mux:
- `infra/` Terraform for S3/CloudFront/MediaConvert is **no longer required for video**.
- You can leave it in the repo (historical), but Codex should stop treating it as required for MVP.

