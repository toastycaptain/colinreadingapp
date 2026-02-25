# Storytime Video Library — Admin Web Console (Rails) Spec
> **Goal:** Provide an admin console for you (and optionally staff) to manage publishers, contracts/rights, catalog, uploads, MediaConvert processing, and reports for billing/partnerships.

---

## 0) Admin Console Scope

### Must-have (MVP)
- Admin authentication (separate from parent users)
- CRUD:
  - Publishers
  - Partnership Contracts
  - Books
  - Rights Windows
  - Video Assets (upload + status)
- Trigger upload flow (presigned S3 upload)
- Trigger MediaConvert processing job
- View processing status + errors
- Reporting:
  - Usage by Publisher / Book for a date range
  - CSV export

### Nice-to-have (phase 2)
- Publisher portal login (read-only statements)
- Automated monthly statements + invoice management
- Takedown workflows and content versioning

---

## 1) Implementation Approach

### Option A (recommended): Rails app with ActiveAdmin
- Quickest to build and iterate.
- Integrates with Rails models cleanly.
- Custom pages for upload workflow and reporting.

**Gems**
- `activeadmin`
- `devise` (for AdminUser)
- `pundit` or `cancancan` (optional; ActiveAdmin has its own authorization patterns)
- `aws-sdk-s3`, `aws-sdk-mediaconvert`
- `sidekiq`

### AdminUser model
- email, encrypted_password
- role enum: `super_admin`, `content_admin`, `finance_admin` (optional)

---

## 2) Admin UI Requirements (Screens)

### 2.1 Dashboard
Show:
- Total active books
- Processing queue: VideoAssets in `processing` / `failed`
- Recent usage totals (last 7 days)
- Upcoming RightsWindow expirations (next 30 days)

### 2.2 Publishers
Fields:
- name
- billing_email
- contact_name
- status

Actions:
- View contracts
- View books
- View usage report

### 2.3 Partnership Contracts
Fields:
- publisher
- contract_name
- start_date, end_date
- payment_model
- rev_share_bps
- minimum_guarantee_cents
- notes
- status

Validations:
- end_date >= start_date
- If payment_model includes rev_share, require rev_share_bps

### 2.4 Books
Fields:
- title, author, description
- age_min, age_max
- language
- publisher
- status
- cover image upload (optional)

Actions:
- Create/edit RightsWindow
- Upload master video
- Trigger MediaConvert
- Preview playback manifest URL (CloudFront)

### 2.5 Rights Windows
Fields:
- publisher
- book
- start_at, end_at
- territory

Validations:
- end_at > start_at

### 2.6 Video Assets
Fields:
- book
- master_s3_key
- processing_status
- mediaconvert_job_id
- hls_manifest_path
- error_message (store if job fails)

Actions:
- Create presigned upload
- Retry MediaConvert job
- Poll status now

---

## 3) Admin Upload Workflow (Detailed)

### 3.1 Create/Select Book
Admin creates a Book entry first.

### 3.2 Generate presigned upload
Admin clicks **“Upload Master Video”**.
Admin console calls backend endpoint:
`POST /admin/api/v1/uploads/master_video`
Request:
```json
{ "book_id": 123, "filename": "readaloud.mp4", "content_type": "video/mp4" }
```
Response (example presigned POST):
```json
{
  "url": "https://storytime-master-uploads.s3.amazonaws.com",
  "fields": {
    "key": "books/123/master/2026-02-25_readaloud.mp4",
    "policy": "...",
    "x-amz-signature": "...",
    "x-amz-algorithm": "AWS4-HMAC-SHA256",
    "x-amz-credential": "...",
    "x-amz-date": "..."
  }
}
```
The browser uploads directly to S3 using the returned form data.

### 3.3 Register upload with backend
After successful upload, admin console calls:
`POST /admin/api/v1/books/123/video_assets`
Body:
```json
{
  "master_s3_key": "books/123/master/2026-02-25_readaloud.mp4"
}
```
Backend creates VideoAsset with status `uploaded` and enqueues MediaConvert job.

### 3.4 MediaConvert processing
Sidekiq job:
- creates MediaConvert job
- updates status -> `processing`
- stores job id

### 3.5 Completion
Polling job checks MediaConvert job status:
- if complete: status -> `ready`, set manifest path
- if error: status -> `failed`, store error

---

## 4) Reporting & Exports

### 4.1 Usage report page
Filters:
- date range (start, end)
- publisher (optional)
- book (optional)

Display:
- Minutes watched
- Plays count
- Unique children count (optional)
- Breakdown by day (optional)

### 4.2 CSV export
Admin clicks Export CSV.
Endpoint:
`GET /admin/api/v1/reports/usage.csv?start=...&end=...&publisher_id=...`

Columns:
- date
- publisher_name
- book_id
- book_title
- minutes_watched
- play_starts
- play_ends

---

## 5) Authorization Rules (Admin)
- Only AdminUsers can access ActiveAdmin.
- Finance admin can view contracts + reports.
- Content admin can manage books + video assets.
- Super admin can do everything.

Implement with:
- ActiveAdmin authorization adapter or Pundit.

---

## 6) Deliverables for Codex (Admin)
Implement:
- ActiveAdmin setup with AdminUser auth
- Resources: Publisher, PartnershipContract, Book, RightsWindow, VideoAsset
- Custom actions/pages for S3 upload + MediaConvert trigger/status
- Report page + CSV export
- Background jobs wired (Sidekiq)
- Basic styling and usability improvements (progress states)

