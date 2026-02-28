# Repo Patch — Admin Console updates for Mux (ActiveAdmin)
This document is **repo-specific** for `toastycaptain/colinreadingapp/backend`.

---

## A) Current state in repo
ActiveAdmin is already installed (see `backend/Gemfile` and `ActiveAdmin.routes(self)` in routes).

There is an **admin API** used by the UI:
- `Admin::Api::V1::UploadsController` (S3 presign)
- `Admin::Api::V1::VideoAssetsController` (register S3 key + MediaConvert)

These are AWS-specific and will be replaced with Mux direct upload flow.

---

## B) New admin API endpoint
Create a controller (example):

- `backend/app/controllers/admin/api/v1/mux_controller.rb`

Add action:
- `POST /admin/api/v1/mux/direct_uploads`

It should:
1) Validate content admin access (`require_content_admin!`)
2) Find book by `book_id`
3) Call Mux API to create Direct Upload (playback policy = signed)
4) Persist/Update book.video_asset:
   - `mux_upload_id`
   - `processing_status = uploading`
   - `playback_policy = signed`
5) Return `{ upload_id, upload_url }`

---

## C) ActiveAdmin UI changes
Update ActiveAdmin pages (files typically in `backend/app/admin/*`).

### Book show page
Add panel:
- Button: “Create Upload URL”
- File chooser + upload UI using the returned URL

**Recommended:** use Mux Uploader web component, embedded in ActiveAdmin page.
If you don’t want to add a web component, you can implement a minimal JS `fetch(upload_url, { method:"PUT", body:file })` upload.

### VideoAsset show/list
Replace columns:
- Remove AWS: `master_s3_key`, `mediaconvert_job_id`, `hls_manifest_path`, `error_message`
- Add Mux: `mux_upload_id`, `mux_asset_id`, `mux_playback_id`, `processing_status`, `mux_error_message`

### Retry behavior
“Retry” should:
- create a **new** direct upload (Mux upload URLs are one-time-ish)
- set status back to uploading
- clear `mux_error_message`

---

## D) Webhook visibility (optional but useful)
Add a lightweight page/table in ActiveAdmin listing recent webhook events:
- provider=mux
- event_id
- type
- processed_at
- status

This helps debugging during early testing.

