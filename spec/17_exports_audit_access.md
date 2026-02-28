# Exports + Audit Logging + Partner Data Access Controls

This spec adds production-grade operational features:
- exports (CSV)
- audit logs for sensitive access
- data access controls for partner portal + admin

---

## 1) DataExport model + job

### 1.1 Model: DataExport
Table: `data_exports`
Columns:
- `id`
- `requested_by_type` (AdminUser, PublisherUser)
- `requested_by_id`
- `publisher_id` (nullable; set for publisher requests)
- `export_type` (enum: `usage_daily`, `analytics_daily`, `statement_breakdown`)
- `params` (jsonb)
- `status` (enum: pending, processing, ready, failed)
- `error_message` (string/text)
- `generated_at` (datetime)
- `file_url` (string) OR use ActiveStorage attachment
- timestamps

Indexes:
- requested_by
- publisher_id
- status

### 1.2 Storage strategy
Pick ONE:
A) ActiveStorage (simplest in Rails; needs a service configured)
B) Store file in S3 and store `file_url`

Given this repo already uses Mux (and may not have S3 set up anymore), ActiveStorage local in dev is fine; S3 in prod.

### 1.3 Job: GenerateDataExportJob
- queue: `maintenance` or `analytics`
- produces CSV based on export_type
- writes attachment / file_url
- updates status

### 1.4 UI hooks
- ActiveAdmin:
  - Add `DataExport` resource (read-only) and “Create export” page
- Publisher portal:
  - Exports index + create form + download links

---

## 2) AuditLog model

### 2.1 Model: AuditLog
Table: `audit_logs`
Columns:
- actor_type (AdminUser, PublisherUser)
- actor_id
- action (string enum-ish, e.g., `view_child_profile`, `download_export`, `view_statement`)
- subject_type (ChildProfile, PublisherStatement, DataExport, etc.)
- subject_id
- metadata (jsonb)
- occurred_at (datetime)

Indexes:
- actor
- subject
- action
- occurred_at

### 2.2 When to log
Internal admin:
- Viewing child profile
- Viewing raw usage events
- Downloading exports
- Marking payout periods paid

Publisher portal:
- Downloading exports
- Viewing statement detail

---

## 3) Access controls & privacy rules

### 3.1 Admin (internal)
- Child-level pages are restricted to `super_admin` + `support_admin` only.
- Finance admins should not see child names; finance pages should show only aggregates.
- Add a “Privacy mode” toggle later if desired.

### 3.2 Publisher portal
- Never expose child name, parent email.
- Use daily aggregates only.
- If “unique children” is shown, it’s a count, not identities.
- If you ever need to show “cohort retention” style breakdown, it must be anonymized.

---

## 4) Rate limiting
Add `rack-attack`:
- limit login attempts
- limit export generation
- limit report endpoints

---

## Acceptance criteria

- Admin can generate exports and download them.
- Publisher can generate exports only for their own publisher.
- Audit logs record sensitive access events.
