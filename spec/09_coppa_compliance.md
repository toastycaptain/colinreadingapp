# Storytime Video Library — COPPA Compliance & Privacy Spec
> **Goal:** Ensure the app fully complies with the Children's Online Privacy Protection Act (COPPA) before US launch. COPPA applies because the app is directed at children under 13. Non-compliance carries FTC enforcement risk including fines up to $50,120 per violation.
> **Scope:** This spec covers data collection practices, parental consent, privacy policy, analytics restrictions, and implementation changes needed across backend, iOS app, and admin console.

---

## 0) COPPA Applicability

### Why COPPA applies
- The app is **directed at children under 13** (read-aloud video library for kids)
- The app collects **persistent identifiers** (device model, usage data tied to child profiles)
- The app collects **personal information from children** indirectly (viewing habits, preferences)

### Key COPPA requirements
1. **Verifiable Parental Consent (VPC)** before collecting data from children
2. **Privacy policy** that is clear, prominent, and COPPA-compliant
3. **Data minimization** — collect only what's necessary
4. **Data retention limits** — don't keep children's data indefinitely
5. **Parental access and deletion** — parents can review and delete their child's data
6. **No behavioral advertising** to children
7. **Reasonable security** for children's data

---

## 1) Verifiable Parental Consent (VPC)

### 1.1 Consent mechanism
Since the parent creates the account and explicitly creates child profiles, the existing flow provides **implicit consent** through the parent account structure. However, to strengthen compliance:

**Add a consent acknowledgment during child profile creation:**

When a parent creates a child profile (`POST /api/v1/children`):
- iOS must present a consent screen **before** the API call
- Consent text must clearly state:
  - What data is collected about the child (viewing history, playback events)
  - How that data is used (content recommendations, publisher reporting in aggregate)
  - That the parent can review and delete this data at any time
  - That no data is shared with third parties for advertising
- Parent must affirmatively agree (tap "I Agree" button, not pre-checked)
- Store consent timestamp on the child profile

### 1.2 Backend changes
Add to `child_profiles` table:
- `parental_consent_at` (datetime, nullable)
- `consent_version` (string, nullable) — tracks which version of consent was agreed to

Update `POST /api/v1/children`:
- Require `consent_given: true` in request body
- Set `parental_consent_at` to current time
- Set `consent_version` to current consent version string (e.g., `"v1.0"`)
- Reject child creation if `consent_given` is not true

### 1.3 iOS consent view
New view: `ParentalConsentView`
- Presented as a sheet during child creation flow
- Scrollable text with consent disclosures
- "I Agree" button at bottom (disabled until user scrolls to bottom)
- "Cancel" button to abort child creation

### 1.4 Consent version management
- Store current consent version in `AppConfig` or backend config
- When consent version changes, re-prompt parents for existing children on next login
- Track consent history (which version each child was consented under)

---

## 2) Privacy Policy

### 2.1 Requirements
The privacy policy must be:
- **Accessible** from the app (Settings → Privacy Policy)
- **Accessible** from the App Store listing (Privacy Policy URL)
- **Accessible** from the website (linked from app and marketing site)
- Written in **plain language** (not legalese)
- **COPPA-specific** disclosures clearly identified

### 2.2 Required content
The privacy policy must include:

**Operator information:**
- Company name, address, email, phone number
- Name and contact of person responsible for children's privacy

**Data collection disclosures:**
- Types of personal information collected from children:
  - Child profile name (entered by parent, not the child)
  - Viewing history (which books watched, duration, timestamps)
  - Device information (device model, app version — from usage event metadata)
- Types of personal information collected from parents:
  - Email address, password (hashed)
  - Account activity

**How data is used:**
- To provide the service (manage library, track viewing progress)
- To generate aggregate publisher reports (no individual child data shared)
- To improve the service

**Data sharing:**
- State that **no personal information from children is shared with third parties**
- Publisher reports contain **only aggregate data** (total minutes, total plays — never individual child identifiers)
- No data is sold
- No behavioral advertising

**Parental rights:**
- Right to review child's personal information
- Right to delete child's data
- Right to refuse further collection
- How to exercise these rights (email, in-app)

**Data retention:**
- How long data is kept
- What happens when account is deleted

**Security:**
- Measures taken to protect children's data

### 2.3 Implementation
- Host privacy policy as a static HTML page (e.g., `https://storytime.com/privacy`)
- Link from:
  - iOS app: `ParentSettingsView` → opens in SFSafariViewController
  - App Store Connect: Privacy Policy URL field
  - Login/registration screen: small link at bottom

---

## 3) Data Minimization

### 3.1 Review current data collection
Audit all data collected about children and remove anything unnecessary:

**Keep (necessary for service):**
- Child profile name
- Library assignments (which books assigned)
- Usage events: event_type, book_id, position_seconds, occurred_at
- Playback sessions (for entitlement enforcement)

**Remove or anonymize:**
- Device model from usage event metadata — **remove**. Not necessary for service operation
- App version from usage event metadata — **keep** (needed for debugging, not PII)

### 3.2 Metadata cleanup
Update `UsageEventLogger` in iOS:
- Remove `device_model` from metadata
- Keep only `app_version`

Update `UsageEvent` model:
- Add a note/comment that metadata must not contain PII

### 3.3 No third-party tracking
- **Do not** integrate any third-party analytics SDKs (Google Analytics, Firebase Analytics, Mixpanel, etc.) for the child-facing portion of the app
- First-party analytics only (existing usage_events system)
- If analytics SDKs are needed for the parent-facing portion, ensure they are **disabled** when in Child Mode

---

## 4) Data Retention & Deletion

### 4.1 Retention policy
Define and document retention periods:
- **Usage events:** Retain for 24 months, then auto-delete or anonymize
- **Playback sessions:** Retain for 12 months, then delete
- **Child profiles:** Retain until parent deletes or account is deleted
- **Account data:** Retain until account deletion requested

### 4.2 Automated cleanup job
Create a Sidekiq job: `DataRetentionCleanupJob`
- Runs weekly
- Deletes usage_events older than 24 months
- Deletes playback_sessions older than 12 months
- Logs count of records deleted

### 4.3 Parental data review
Add to parent-facing API:
`GET /api/v1/children/:child_id/data_summary`
- Returns:
  - Total usage events count
  - Date range of data (earliest to latest)
  - Total minutes watched
  - Number of unique books watched
  - List of data types stored
- Does NOT return raw events (too large, not useful to parents)

### 4.4 Parental data deletion
The account deletion endpoint in `08_ios_launch_readiness.md` covers full account deletion. Add per-child data deletion:

`DELETE /api/v1/children/:child_id/data`
- Deletes all usage_events for the child
- Deletes all playback_sessions for the child
- Resets `last_position_seconds` on all library_items
- Does NOT delete the child profile itself (parent can do that separately)
- Returns 204 No Content

### 4.5 iOS — parental data controls
Add to `ParentChildrenManagementView` for each child:
- "View Data Summary" — shows data summary from endpoint above
- "Delete [Child]'s Viewing Data" — calls data deletion endpoint with confirmation dialog
- "Delete [Child]'s Profile" — existing functionality, add confirmation that this also deletes all data

---

## 5) Publisher Report Anonymization

### 5.1 Current state
The `UsageReportQuery` service aggregates data by publisher/book/date. Verify that:
- Reports **never** include `child_profile_id` or child names
- Reports only show aggregate metrics: minutes_watched, play_starts, play_ends, unique_children (count only)

### 5.2 Safeguard
Add a check to `UsageReportQuery` and any report endpoints:
- **Never** include child-level identifiers in report output
- The `unique_children` metric must be a **count**, not a list
- Publisher CSV exports must not contain any child PII

### 5.3 Admin access restriction
Admin users should only see aggregate child metrics. Individual child profiles should only be viewable in the context of their parent account for support purposes.

---

## 6) App Store Privacy Labels

### 6.1 Data types to declare
In App Store Connect, declare these data collection categories:

**Contact Info (collected from parents only):**
- Email Address — Used for: App Functionality (account login)
- Not linked to identity for tracking purposes

**Identifiers:**
- User ID — Used for: App Functionality
- Not used for tracking

**Usage Data:**
- Product Interaction — Used for: App Functionality, Analytics
- Linked to identity (child profile, but managed by parent)

### 6.2 Data NOT collected
Explicitly mark as NOT collected:
- Location
- Financial Info
- Health & Fitness
- Contacts
- Browsing History
- Search History (catalog searches are parent-only and not stored)
- Diagnostics
- Sensitive Info

---

## 7) Additional iOS Requirements

### 7.1 Age gate (if app allows browsing before login)
- Not currently applicable — app requires login before any content access
- If this changes, add an age gate per Apple's guidelines

### 7.2 No external links in Child Mode
Already enforced — verify:
- No URLs opened from Child Mode
- No web views in Child Mode
- No App Store links in Child Mode
- No social media links in Child Mode

### 7.3 No user-generated content from children
- Children cannot input text, upload images, or create content
- Child profile names are entered by parents
- No comments, ratings, or reviews from children

---

## 8) Testing Requirements

### Backend tests
- Child creation: verify consent fields required
- Child creation: rejected when `consent_given` is false
- Data summary endpoint: returns correct aggregate data
- Data deletion endpoint: removes all child events
- Usage reports: verify no child PII in output
- Data retention job: verify old records deleted

### iOS tests
- Consent view: verify "I Agree" button disabled until scroll
- Metadata: verify device_model not included in usage events

---

## 9) Deliverables for Codex (COPPA Compliance)
Implement:
- Migration: add `parental_consent_at`, `consent_version` to child_profiles
- Update child creation endpoint to require consent
- iOS: ParentalConsentView with scrollable disclosures and agree button
- Remove device_model from usage event metadata (iOS)
- Data summary endpoint: GET /api/v1/children/:child_id/data_summary
- Per-child data deletion endpoint: DELETE /api/v1/children/:child_id/data
- DataRetentionCleanupJob (Sidekiq weekly job)
- iOS: data review and deletion controls in ParentChildrenManagementView
- Privacy policy HTML page template with all required COPPA disclosures
- Audit UsageReportQuery to confirm no child PII in outputs
- App Store privacy label configuration documentation
